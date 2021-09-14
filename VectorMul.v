/***************************************************************************************************
    1. Design Name:             VectorMul
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/
/*
module VectorMul(clk, rst, 
						rst_pol_mul, pol_acc_clear, pol_base_sel, 
						pol_mul_done, result_read,
						PolMem_address, PolMem_wen, done);
input clk, rst;
output reg rst_pol_mul, pol_acc_clear;
output reg [1:0] pol_base_sel;	// selects one of the three s polynomials

input pol_mul_done;
output reg result_read;
// Assumes the other operand polynomial comes from FIFO. 
// The fifo is accessed by pol_multiplier

output [5:0] PolMem_address;
output PolMem_wen;
output done;

reg [5:0] PolMem_address;
reg PolMem_wen;
reg [3:0] state, nextstate;
wire PolMem_write_complete;

always @(posedge clk)
begin
	if(rst)
		PolMem_address <= 6'd0;
	else if(PolMem_wen)
		PolMem_address <= PolMem_address + 1'b1;
	else
		PolMem_address <= PolMem_address;
end		

assign PolMem_write_complete = (PolMem_address==6'd63) ? 1'b1 : 1'b0;	
	
always @(posedge clk)
begin
	if(rst)
		state <= 4'd0;
	else
		state <= nextstate;
end
		
always @(state)
begin
	case(state)
	4'd0: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b1; pol_base_sel<=2'd0; result_read<=1'b0; PolMem_wen<=1'b0; end
	// acc<--a[0]*s[0]
	4'd1: begin rst_pol_mul<=1'b0; pol_acc_clear<=1'b0; pol_base_sel<=2'd0; result_read<=1'b0; PolMem_wen<=1'b0; end
	4'd2: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b0; pol_base_sel<=2'd1; result_read<=1'b0; PolMem_wen<=1'b0; end

	// acc<--acc+a[1]*s[1]
	4'd3: begin rst_pol_mul<=1'b0; pol_acc_clear<=1'b0; pol_base_sel<=2'd1; result_read<=1'b0; PolMem_wen<=1'b0; end
	4'd4: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b0; pol_base_sel<=2'd2; result_read<=1'b0; PolMem_wen<=1'b0; end

	// acc<--acc+a[2]*s[2]
	4'd5: begin rst_pol_mul<=1'b0; pol_acc_clear<=1'b0; pol_base_sel<=2'd2; result_read<=1'b0; PolMem_wen<=1'b0; end
	
	// Store acc[] in BRAM
	4'd6: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b0; pol_base_sel<=2'd2; result_read<=1'b1; PolMem_wen<=1'b1; end
	4'd7: begin end

	4'd8: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b1; pol_base_sel<=2'd2; result_read<=1'b0; PolMem_wen<=1'b0; end
	//4'd8: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b1; pol_base_sel<=2'd2; result_read<=1'b0; PolMem_wen<=1'b0; end // NOP
	default: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b1; pol_base_sel<=2'd2; result_read<=1'b0; PolMem_wen<=1'b0; end
	endcase
end	

always @(state or pol_mul_done or PolMem_write_complete)
begin
	case(state)
	4'd0: nextstate<=4'd1;

	// acc <-- a[0]*s[0]
	4'd1: begin
				if(pol_mul_done)
					nextstate<=4'd2;
				else	
					nextstate<=4'd1;
			end		
	4'd2: nextstate<=3'd3;

	// acc <-- acc+a[1]*s[1]
	4'd3: begin
				if(pol_mul_done)
					nextstate<=4'd4;
				else	
					nextstate<=4'd3;
			end		
	4'd4: nextstate<=4'd5;

	// acc <-- acc+a[2]*s[2]
	4'd5: begin
				if(pol_mul_done)
					nextstate<=4'd6;
				else	
					nextstate<=4'd5;
			end		
	4'd6: nextstate<= 4'd7;
	4'd7: begin
				if(PolMem_write_complete)
					nextstate<=4'd8;
				else
					nextstate<=4'd6;
			end		
	4'd8: nextstate<=4'd8;
    //4'd8: nextstate<=4'd8;
	default: nextstate<=4'd0;
	endcase
end
	
assign done = (state==4'd8) ? 1'b1 : 1'b0;
	
endmodule
*/

`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             ComputeCore3 (top)
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Mr. Malik Imran (Tallinn University of Technology, Estonia)
    5. Optimizations in under   Prof. Dr. Samuel Pagliarini
       Supervision:              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module VectorMul(clk, rst, 
						rst_pol_mul, pol_acc_clear, pol_base_sel, 
						pol_mul_done, result_read,
						PolMem_address, PolMem_wen, done);
input clk, rst;
output reg rst_pol_mul, pol_acc_clear;
output reg [1:0] pol_base_sel;	// selects one of the three s polynomials

input pol_mul_done;
output reg result_read;
// Assumes the other operand polynomial comes from FIFO. 
// The fifo is accessed by pol_multiplier

output [5:0] PolMem_address;
output PolMem_wen;
output done;

reg [5:0] PolMem_address;
reg PolMem_wen;
reg [3:0] state, nextstate;
wire PolMem_write_complete;

always @(posedge clk or posedge rst)
begin
	if(rst)
		PolMem_address <= 6'd0;
	else if(PolMem_wen)
		PolMem_address <= PolMem_address + 1'b1;
	else
		PolMem_address <= PolMem_address;
end		

assign PolMem_write_complete = (PolMem_address==6'd63) ? 1'b1 : 1'b0;	
	
//SEQ	
always @(posedge clk or posedge rst)
begin
	if(rst)
		state <= 4'd0;
	else
		state <= nextstate;
end

//SEQ		
always @(*)
begin
	//rst_pol_mul=1'b1; pol_acc_clear=1'b1; pol_base_sel=2'd2; result_read=1'b0; PolMem_wen=1'b0;
	case(state)
	4'd0: begin rst_pol_mul=1'b1; pol_acc_clear=1'b1; pol_base_sel=2'd0; result_read=1'b0; PolMem_wen=1'b0; end
	// acc<--a[0]*s[0]
	4'd1: begin rst_pol_mul=1'b0; pol_acc_clear=1'b0; pol_base_sel=2'd0; result_read=1'b0; PolMem_wen=1'b0; end
	4'd2: begin rst_pol_mul=1'b1; pol_acc_clear=1'b0; pol_base_sel=2'd1; result_read=1'b0; PolMem_wen=1'b0; end

	// acc<--acc+a[1]*s[1]
	4'd3: begin rst_pol_mul=1'b0; pol_acc_clear=1'b0; pol_base_sel=2'd1; result_read=1'b0; PolMem_wen=1'b0; end
	4'd4: begin rst_pol_mul=1'b1; pol_acc_clear=1'b0; pol_base_sel=2'd2; result_read=1'b0; PolMem_wen=1'b0; end

	// acc<--acc+a[2]*s[2]
	4'd5: begin rst_pol_mul=1'b0; pol_acc_clear=1'b0; pol_base_sel=2'd2; result_read=1'b0; PolMem_wen=1'b0; end
	
	// Store acc[] in BRAM
	4'd6: begin rst_pol_mul=1'b1; pol_acc_clear=1'b0; pol_base_sel=2'd2; result_read=1'b0; PolMem_wen=1'b0; end
	4'd7: begin rst_pol_mul=1'b1; pol_acc_clear=1'b0; pol_base_sel=2'd2; result_read=1'b1; PolMem_wen=1'b1; end

	4'd8: begin rst_pol_mul=1'b1; pol_acc_clear=1'b1; pol_base_sel=2'd2; result_read=1'b0; PolMem_wen=1'b0; end
	//4'd8: begin rst_pol_mul<=1'b1; pol_acc_clear<=1'b1; pol_base_sel<=2'd2; result_read<=1'b0; PolMem_wen<=1'b0; end // NOP
    default: begin rst_pol_mul=1'b1; pol_acc_clear=1'b1; pol_base_sel=2'd2; result_read=1'b0; PolMem_wen=1'b0; end	
	endcase
 end

// COMB
always @(*)
begin
	case(state)
	4'd0: nextstate=4'd1;

	// acc <-- a[0]*s[0]
	4'd1: begin
				if(pol_mul_done)
					nextstate=4'd2;
				else	
					nextstate=4'd1;
			end		
	4'd2: nextstate=3'd3;

	// acc <-- acc+a[1]*s[1]
	4'd3: begin
				if(pol_mul_done)
					nextstate=4'd4;
				else	
					nextstate=4'd3;
			end		
	4'd4: nextstate=4'd5;

	// acc <-- acc+a[2]*s[2]
	4'd5: begin
				if(pol_mul_done)
					nextstate=4'd6;
				else	
					nextstate=4'd5;
			end		
	4'd6: nextstate= 4'd7;
	4'd7: begin
				if(PolMem_write_complete)
					nextstate=4'd8;
				else
					nextstate=4'd6;
			end		
	4'd8: nextstate=4'd8;
    //4'd8: nextstate<=4'd8;
	default: nextstate=4'd0;
	endcase
end
	
assign done = (state==4'd8) ? 1'b1 : 1'b0;
	
endmodule
