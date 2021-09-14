`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             verify
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module verify(clk, rst, ilen,
			 rd_address, rd_base_sel, din,
			 verify_true,
			 done);

input clk, rst;
input [9:0] ilen;	// input length for comparison; output len for writing result

output reg [8:0] rd_address;
output rd_base_sel;
input [63:0] din;

output verify_true;
output done;


reg [63:0] acc, din0, din1;
reg din0_en, din1_en, acc_en;
reg verify_true;
reg rd_base_sel, inc_rd_address;

reg [3:0] state, nextstate;
wire rd_address_last;



always @(posedge clk)
begin
	if(din0_en)
		din0 <= din;
	if(din1_en)
		din1 <= din;
end

always @(posedge clk or posedge rst)
begin
	if(rst)
		acc <= 64'b0;
	else if(acc_en)
		acc <= acc | (din0 ^ din1);
	else
		acc <= acc;
end

always @(posedge clk)
begin
		verify_true <= (acc==64'd0);
end

always @(posedge clk or posedge rst)
begin
	if(rst)	
		rd_address <= 9'd0;
	else if(inc_rd_address)
		rd_address <= rd_address + 1'b1;
	else if(rd_address == 9'd56)
	   rd_address <= rd_address+1; 
	else
		rd_address <= rd_address;
end		

assign rd_address_last = (rd_address == ilen) ? 1'b1 : 1'b0;

// Sequential Logic		
always @(posedge clk or posedge rst)
begin
	if(rst)
		state <= 4'd0;
	else	
		state <= nextstate;
end

// Combinational Logic
always @(*)
begin
	case(state)
	4'd0:    begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=0; end
	4'd1:    begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=0; end
	4'd2:    begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=1; inc_rd_address=0; end // set rd_base_sel
	4'd3:    begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=1; end // increment read address
	4'd4:    begin din0_en=1; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=0; end // set din0_en
	4'd5:    begin din0_en=0; din1_en=1; acc_en=0; rd_base_sel=0; inc_rd_address=0; end // set din1_en	
    4'd6:    begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=1; inc_rd_address=0; end // set rd_base_sel	
	4'd7:    begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=1; end // increment read address	
	4'd8:    begin din0_en=1; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=0; end // set din0_en	
	4'd9:    begin din0_en=0; din1_en=0; acc_en=1; rd_base_sel=0; inc_rd_address=0; end // set acc_en
	//4'd10:   begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=1; inc_rd_address=1; end // set rd_base_sel; increment read address
	//4'd11:   begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=0; end // NOP
	4'd12:   begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=0; end
	default: begin din0_en=0; din1_en=0; acc_en=0; rd_base_sel=0; inc_rd_address=0; end				
	endcase
end
		
always @(*)
begin
	case(state)
	4'd0: nextstate = 4'd1;
	4'd1: nextstate = 4'd2;
	4'd2: nextstate = 4'd3;
	4'd3: nextstate = 4'd4;	
	4'd4: nextstate = 4'd5;
	4'd5: nextstate = 4'd6;
	4'd6: nextstate = 4'd7;
	4'd7: nextstate = 4'd8;
	4'd8: nextstate = 4'd9;
	//4'd9: nextstate = 4'd11;
	//4'd10: nextstate = 4'd11;
	4'd9: begin
					if(rd_address_last)
						nextstate =4'd12;
					else
						nextstate = 4'd5;
				end
	4'd12: nextstate = 4'd12;
	default: nextstate = 4'd0;	
	endcase
end

assign done = (state==4'd12) ? 1'b1 : 1'b0;
		
endmodule
		