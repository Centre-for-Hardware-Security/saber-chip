`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             poly_load_control_BRAM1
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/


module poly_load_control_BRAM1(clk, rst, s_address, poly_load_delayed, poly_load_done);
input clk, rst;
output [7:0] s_address;
output reg poly_load_delayed;
output poly_load_done;

reg [4:0] poly_word_counter;
reg [1:0] state, nextstate;

always @(posedge clk or posedge rst) begin
	if (rst)
		poly_load_delayed <= 0;
	else
		poly_load_delayed <= poly_word_counter < 16;
end

assign s_address = poly_word_counter;
	
always @(posedge clk or posedge rst) begin
	if (rst)
		poly_word_counter <= 5'd0;
	else if (poly_word_counter < 16)
		poly_word_counter <= poly_word_counter + 5'd1;
	else
		poly_word_counter <= poly_word_counter;
end

always @(posedge clk or posedge rst) begin
	if (rst)
		state <= 0;
	else
		state <= nextstate;
end

always @(*)
begin
	case(state)
		0: begin // 
				if(poly_word_counter == 5'd16)
				    nextstate = 2'd1;
				else
				    nextstate = 2'd0;
		   end
		1: begin  nextstate = 2'd1;  end		
		default: nextstate = 2'd0;	
    endcase
end	

assign poly_load_done = state == 2'd1 ? 1'b1 : 1'b0;

endmodule