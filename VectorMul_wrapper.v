`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             VectorMul_wrapper
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module VectorMul_wrapper(clk, rst, pol_load_coeff4x, s_load_happens_now, read_address, ram_data_out, write_address, coeff4x_out, PolMem_wen, vector_mul_done, 
			PO_pol_load_coeff4x, PO_poly_load, PO_poly_load_data, PO_poly_shift, buffer); // added for shared buffer support
input clk, rst;
input pol_load_coeff4x;			 // If 1 then input data contains 4 uint16_t coefficients
output s_load_happens_now;  // 1 when s is read from mem. 0 when pol is read from mem.    
output [8:0] read_address;	// Virtual address starts from 0
input [63:0] ram_data_out;

output [8:0] write_address;	// Virtual address starts from 0
output [63:0] coeff4x_out;
output PolMem_wen;
output vector_mul_done;

output PO_pol_load_coeff4x; // these IOs are not even touched here, they are passed to the multiplier and handled there
output PO_poly_load;
output [63:0] PO_poly_load_data;
output PO_poly_shift;
input [675:0] buffer;
								
wire rst_pol_mul, pol_acc_clear;
wire [1:0] pol_base_sel;	// selects one of the three s polynomials
wire pol_mul_done;	 
wire result_pol_read;
wire [63:0] coeff4x_out; // pack of 4 coefficients in uint16_t
wire result_pol_read64;
wire [63:0] result_coeff_out64;
wire [7:0] s_address;
wire [6:0] pol_64bit_address;
wire [5:0] PolMem_address;
wire [8:0] read_address1, read_address2;	// Virtual address starts from 0
wire [63:0] pol_64bit_in, s_vec_64;


wire [8:0] vec1_pol_base, vec1_pol_base_coeff4x, vec1_pol_base_64bit, vec2_pol_base;

assign vec1_pol_base_64bit = (pol_base_sel==2'd0) ? 9'd0 : (pol_base_sel==2'd1) ? 9'd52 : 9'd104; 
assign vec1_pol_base_coeff4x = (pol_base_sel==2'd0) ? 9'd0 : (pol_base_sel==2'd1) ? 9'd64 : 9'd128; 
assign vec1_pol_base = (pol_load_coeff4x) ? vec1_pol_base_coeff4x : vec1_pol_base_64bit;

assign vec2_pol_base = (pol_base_sel==2'd0) ? 9'd0 : (pol_base_sel==2'd1) ? 9'd16 : 9'd32;
//assign vec2_pol_base = 9'd0; // for the moment assume only one s pol

assign read_address1 = vec1_pol_base + pol_64bit_address;
assign read_address2 = vec2_pol_base + s_address;
assign read_address = (s_load_happens_now) ? read_address2 : read_address1;
assign write_address = {3'd0,PolMem_address};

VectorMul	VMUL(clk, rst, 
						rst_pol_mul, pol_acc_clear, pol_base_sel, 
						pol_mul_done, result_pol_read,
						PolMem_address, PolMem_wen, vector_mul_done);

assign pol_64bit_in = ram_data_out;
assign s_vec_64 = ram_data_out;

poly_mul256_parallel_in2 PMUL0(clk, rst_pol_mul, pol_acc_clear, pol_load_coeff4x,
								pol_64bit_address, pol_64bit_in,  
								s_address, s_vec_64, s_load_happens_now,
								result_pol_read, coeff4x_out, pol_mul_done, PO_pol_load_coeff4x, PO_poly_load, PO_poly_load_data, PO_poly_shift, buffer);

								
endmodule
