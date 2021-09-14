`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////

// High-speed instruction set coprocessor architecture for lattice-based cryptography. 
// Saber is implemented as a case study.
// The designers are Sujoy Sinha Roy and Andrea Basso. 

// Implementation by the designers, hereby denoted as "the implementer".

// To the extent possible under law, the implementer has waived all copyright
// and related or neighboring rights to the source code in this file.
// http://creativecommons.org/publicdomain/zero/1.0/

// The codes are for academic research use only and does not come with any support or any responsibility.

//////////////////////////////////////////////////////////////////////////////////

module parallel_Mults1(acc, secret, a_coeff, result);
input [3327:0] acc;
input [1023:0] secret;
input [12:0] a_coeff;
output [3327:0] result;

wire [12:0] ax2 = {a_coeff[11:0], 1'b0};
wire [12:0] ax3 = a_coeff + {a_coeff[11:0], 1'b0};
wire [12:0] ax4 = {a_coeff[10:0], 2'b00};

genvar i;
generate
    for (i=0; i<256; i=i+1) begin : MAC_units
    small_alu1 sa0(
             acc[i*13 + 12 : i*13],
             secret[i*4+3:i*4],
             a_coeff, ax2, ax3, ax4,
             result[i*13 + 12 : i*13]);
end 
endgenerate

endmodule
