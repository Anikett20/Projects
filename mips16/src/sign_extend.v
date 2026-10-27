`timescale 1ns / 1ps
`default_nettype none

module sign_extend (
    input  wire [5:0]  imm_in,
    output wire [15:0] imm_out
);
    assign imm_out = {{10{imm_in[5]}}, imm_in};
endmodule
`default_nettype wire
