`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             copy_words
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/
/* -- --*/
/*
	Copies n words from addr1 to addr2
*/

module copy_words(clk, rst, number_words, read_address, read_data, write_address, write_data, write_en, done);
input clk, rst;
input [8:0] number_words;
output reg [8:0] read_address;
input [63:0] read_data;

output reg [8:0] write_address;
output [63:0] write_data;
output reg write_en;
output done;

reg [63:0] temp;
reg [2:0] state, nextstate;
reg [8:0] write_address_r;
reg write_en_r;
reg read_address_en;
wire all_words_copied;

always @(posedge clk or posedge rst)
begin
	if(rst)
		read_address <= 9'd0;
	else if(read_address_en)
		read_address <= read_address + 1'b1;
	else	
		read_address <= read_address;
end

assign all_words_copied = (read_address == number_words) ? 1'b1 : 1'b0;

always @(posedge clk or posedge rst)
begin
	if(rst)
		write_address <= 9'd0;
	else if(write_en)
		write_address <= write_address + 1'b1;
	else	
		write_address <= write_address;
end
 
always @(posedge clk)
begin
	//write_address_r <= read_address;
	//write_address <= write_address_r;
	temp <= read_data;
end

assign write_data = temp;


//always @(posedge clk)
//begin
//	if(rst)
//		begin write_en <= 1'b0; write_en_r <= 1'b0; end
//	else	
//		begin write_en_r <= read_address_en; write_en <= write_en_r; end
//end

		
always @(posedge clk or posedge rst)
begin
	if(rst)
		state <= 3'd0;
	else
		state <= nextstate;
end

always @(*)
begin
	case(state)
	3'd0: begin 
	       read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd1;
	      end
	3'd1: begin
		      if(all_words_copied!=1'b1)begin
		          read_address_en = 1'b1; write_en =1'b0; nextstate = 3'd2;
		      end else begin
		          read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd2;
		      end
		   end
	3'd2: begin read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd3; end
	3'd3: begin read_address_en = 1'b0; write_en =1'b1; nextstate = 3'd4; end 	
	3'd4: begin 
	       if(all_words_copied!=1'b1) begin
		          read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd1;
		      end else begin
		          read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd5;
		      end
		  end
	3'd5: begin read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd6; end
	3'd6: begin read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd6; end // included by Malik
	default: begin read_address_en = 1'b0; write_en =1'b0; nextstate = 3'd0; end		
	endcase					
end		

assign done = (state==3'd6) ? 1'b1 : 1'b0;

endmodule

