#!/usr/bin/env python3
"""Compile the supplied examples and check their observable simulation results."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def run(command: list[str], cwd: Path) -> str:
    completed = subprocess.run(command, cwd=cwd, capture_output=True, text=True,
                               timeout=60, check=False)
    output = completed.stdout + completed.stderr
    if completed.returncode:
        raise RuntimeError(f"Command failed ({completed.returncode}): {command[0]}\n{output}")
    return output


def simulate(project: str, top: str, sources: list[Path]) -> tuple[str, Path]:
    directory = ROOT / project
    build = directory / "sim_build"
    build.mkdir(exist_ok=True)
    binary = build / f"{top}.vvp"
    compile_output = run(["iverilog", "-g2012", "-s", top, "-I",
                          str(directory / "src"), "-o", str(binary),
                          *map(str, sources)], build)
    output = run(["vvp", str(binary)], build)
    (build / f"{top}.log").write_text(compile_output + output, encoding="utf-8")
    if re.search(r"\b(?:ERROR|FATAL)\b|timed out", output, re.IGNORECASE):
        raise AssertionError(output)
    return output, build


def check_alu4() -> dict:
    project = ROOT / "alu-4bit"
    output, build = simulate("alu-4bit", "tb_alu_4bit",
        [project / "rtl/alu_4bit.v", project / "tb/tb_alu_4bit.v"])
    if "Simulation Complete." not in output:
        raise AssertionError("4-bit testbench did not complete")

    # VCD observations are sampled after NBA updates, away from stimulus changes.
    scope: list[str] = []
    symbols: dict[str, str] = {}
    values: dict[str, str] = {}
    definitions = True
    previous_clock = "x"
    samples = 0
    operations: set[int] = set()

    def sample() -> None:
        nonlocal previous_clock, samples
        clock = values.get("clk", "x")
        if previous_clock == "1" and clock == "0" and values.get("rst") == "0":
            needed = ("a", "b", "opcode", "result", "carry_out", "zero")
            if any(name not in values or re.search("[xz]", values[name]) for name in needed):
                raise AssertionError("Unknown value in 4-bit ALU observation")
            a, b, op, result, carry, zero = (int(values[name], 2) for name in needed)
            expected = ((a + b) & 31, (a - b) & 31, a & b, a | b,
                        a ^ b, (~a) & 15, (a << 1) & 15, a >> 1)[op]
            wanted = (expected & 15, expected >> 4, int((expected & 15) == 0))
            if (result, carry, zero) != wanted:
                raise AssertionError(f"ALU4 op={op} a={a} b={b}: "
                                     f"{(result, carry, zero)} != {wanted}")
            samples += 1
            operations.add(op)
        previous_clock = clock

    for raw_line in (build / "alu_4bit.vcd").read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if definitions:
            parts = line.split()
            if line.startswith("$scope"):
                scope.append(parts[2])
            elif line.startswith("$upscope"):
                scope.pop()
            elif line.startswith("$var") and scope == ["tb_alu_4bit"]:
                symbols[parts[3]] = parts[4]
            elif line.startswith("$enddefinitions"):
                definitions = False
        elif line.startswith("#"):
            sample()
        elif line.startswith("b"):
            bits, symbol = line[1:].split()
            if symbol in symbols:
                values[symbols[symbol]] = bits.lower()
        elif line and line[0] in "01xXzZ" and line[1:] in symbols:
            values[symbols[line[1:]]] = line[0].lower()
    sample()
    if samples != 9 or operations != set(range(7)):
        raise AssertionError(f"Unexpected ALU4 coverage: {samples} samples, {operations}")
    return {"project": "alu-4bit", "status": "passed", "checked_vectors": samples,
            "covered_opcodes": sorted(operations)}


def check_alu8() -> dict:
    project = ROOT / "alu-8bit-datapath"
    rtl = project / "rtl"
    output, _ = simulate("alu-8bit-datapath", "alu_tb",
                         [rtl / "alu.v", project / "tb/alu_tb.v"])
    rows = re.findall(r"A=0x([0-9a-fx]+).*?B=0x([0-9a-fx]+).*?Result=0x([0-9a-f]+)"
                      r".*?Zero=(\d).*?Carry=(\d)", output, re.IGNORECASE)
    expected = [(0x20, 0, 0), (0, 1, 1), (0x0b, 0, 0), (0xff, 0, 1),
                (0xa0, 0, 0), (0xff, 0, 0), (0, 1, 0), (0x55, 0, 0),
                (0x02, 0, 1), (0x40, 0, 1), (0, 1, 0)]
    observed = [(int(row[2], 16), int(row[3]), int(row[4])) for row in rows]
    if observed != expected:
        raise AssertionError(f"ALU8 vectors differ: {observed}")

    output, _ = simulate("alu-8bit-datapath", "soc_top_tb",
        [rtl / name for name in ("alu.v", "reg_file.v", "control_unit.v", "soc_top.v")]
        + [project / "tb/soc_top_tb.v"])
    rows = re.findall(r"PC=(\d+).*?instr=0x([0-9a-f]+).*?result=0x([0-9a-f]+)"
                      r".*?zero=(\d) carry=(\d) halt=(\d)", output, re.IGNORECASE)
    expected_results = [0x0f, 0x05, 0x14, 0x0f, 0x05, 0x1e, 0, 0]
    if [int(row[0]) for row in rows] != list(range(8)):
        raise AssertionError("Incomplete 8-bit integration trace")
    if [int(row[2], 16) for row in rows] != expected_results:
        raise AssertionError(f"8-bit integration results differ: {rows}")
    if [int(row[1], 16) for row in rows[:2]] != [0x820f, 0x8405]:
        raise AssertionError("LOAD encodings differ")
    if any(row[5] != "0" for row in rows[:-1]) or rows[-1][5] != "1" or rows[6][3] != "1":
        raise AssertionError("8-bit halt/zero results differ")
    return {"project": "alu-8bit-datapath", "status": "passed",
            "checked_alu_vectors": 11, "checked_program_instructions": 8}


def check_riscv() -> dict:
    project = ROOT / "riscv-rv32im-soc"
    output, _ = simulate("riscv-rv32im-soc", "rv32im_soc_tb",
        [project / "tb/rv32im_soc_tb.v", *sorted((project / "src").glob("*.v"))])
    match = re.search(r"SELF-CHECK PASSED at Cycle (\d+)", output)
    if not match:
        raise AssertionError("RISC-V firmware did not complete")
    expected = {"0x00": 0x006ae9bc, "0x04": 0x162e, "0x08": 0x28c,
                "0x0C": 0x80000007, "0x10": 0x5a, "0x100": 0xcafebabe}
    for address, wanted in expected.items():
        row = re.search(r"DMEM\[" + address + r"\].*?=\s*0x([0-9a-f]+)", output,
                        re.IGNORECASE)
        if not row or int(row[1], 16) != wanted:
            raise AssertionError(f"RISC-V DMEM[{address}] differs from {wanted:#x}")
    gpio = re.search(r"GPIO_OUT.*?=\s*0x([0-9a-f]+)", output, re.IGNORECASE)
    if not gpio or int(gpio[1], 16) != 0x006ae9bc:
        raise AssertionError("RISC-V GPIO differs")
    for event in ("WFI SLEEP ENTERED", "TIMER IRQ WAKE PENDING",
                  "SPI MASTER TRANSACTION ACTIVE", "Sleep Tested", "SPI Tested"):
        if event not in output:
            raise AssertionError(f"RISC-V event missing: {event}")
    if len(re.findall(r"Tested.*?:\s*YES", output)) != 2:
        raise AssertionError("RISC-V sleep/SPI flags differ")
    return {"project": "riscv-rv32im-soc", "status": "passed",
            "completion_cycle": int(match[1]), "checked_memory_values": len(expected),
            "gpio": "passed", "wfi_timer_wake": "observed", "spi_loopback": "passed"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", choices=("all", "alu4", "alu8", "riscv"), default="all")
    args = parser.parse_args()
    for executable in ("iverilog", "vvp"):
        if not shutil.which(executable):
            raise SystemExit(f"Required executable not found: {executable}")
    checks = {"alu4": check_alu4, "alu8": check_alu8, "riscv": check_riscv}
    results = []
    for name, check in checks.items():
        if args.project in ("all", name):
            result = check()
            results.append(result)
            print(f"PASS {result['project']}")
    summary = {"checked_at_utc": datetime.now(timezone.utc).isoformat(),
               "scope": "Supplied directed simulations; no physical-design rerun",
               "results": results}
    destination = ROOT / "verification/results.json"
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print("Saved verification/results.json")


if __name__ == "__main__":
    main()
