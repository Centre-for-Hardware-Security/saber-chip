
`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             BS2POLVECp
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/


module BS2POLVECp(clk, rst, read_address, read_data, write_address, write_data, write_en, done, buffer40_en, buffer64_en, buffer64_data, buffer);
input clk, rst;
output reg [8:0] read_address;
input [63:0] read_data;

output reg [8:0] write_address;
output [63:0] write_data;
output write_en;

output done;

output reg buffer40_en, buffer64_en;
output [63:0] buffer64_data;
input [319:0] buffer;

assign buffer64_data = read_data;

reg inc_write_address, inc_read_address;
reg [4:0] state, nextstate;

/* moved to shared_buffer
//reg [319:0] buffer;
always @(posedge clk)
begin
	if(buffer40_en)
		buffer <= {40'd0, buffer[319:40]};
	else if(buffer64_en)
		buffer <= {read_data, buffer[319:64]};
end
*/


assign write_data = {6'd0,buffer[39:30],6'd0,buffer[29:20],6'd0,buffer[19:10],6'd0,buffer[9:0]};
assign write_en = inc_write_address;

always @(posedge clk or posedge rst)
begin
	if(rst)
		read_address <= 9'd0;
	else if(inc_read_address)
		read_address <= read_address + 1'b1;
end
wire read_address_120 = (read_address==9'd120);

always @(posedge clk or posedge rst)
begin
	if(rst)
		write_address <= 9'd0;
	else if(inc_write_address)
		write_address <= write_address + 1'b1;
end

always @(posedge clk or posedge rst)
begin
	if(rst)
		state <= 5'd0;
	else
		state <= nextstate;
end		


always @(*)
begin
	case(state)
	5'd0: begin inc_read_address=0; buffer40_en=0; buffer64_en=0; inc_write_address=0; end
	
	// Read 5 64 bit words and store in buffer
	5'd1: begin inc_read_address=1; buffer40_en=0; buffer64_en=0; inc_write_address=0; end
	5'd2: begin inc_read_address=1; buffer40_en=0; buffer64_en=1; inc_write_address=0; end
	5'd3: begin inc_read_address=1; buffer40_en=0; buffer64_en=1; inc_write_address=0; end
	5'd4: begin inc_read_address=1; buffer40_en=0; buffer64_en=1; inc_write_address=0; end
	5'd5: begin inc_read_address=1; buffer40_en=0; buffer64_en=1; inc_write_address=0; end
	5'd6: begin inc_read_address=0; buffer40_en=0; buffer64_en=1; inc_write_address=0; end
	
	// Read 40 bit chunks; write 4 coeff in uint16_t 
	5'd7: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end	
	5'd8: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end
	5'd9: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end	
	5'd10: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end
	5'd11: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end	
	5'd12: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end	
	5'd13: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end
	5'd14: begin inc_read_address=0; buffer40_en=1; buffer64_en=0; inc_write_address=1; end	

	5'd15: begin inc_read_address=0; buffer40_en=0; buffer64_en=0; inc_write_address=0; end		
	default: begin inc_read_address=0; buffer40_en=0; buffer64_en=0; inc_write_address=0; end		
	endcase
end

always @(*)
begin
	case(state)
	5'd0: nextstate = 5'd1;
	5'd1: nextstate = 5'd2;
	5'd2: nextstate = 5'd3;
	5'd3: nextstate = 5'd4;
	5'd4: nextstate = 5'd5;
	5'd5: nextstate = 5'd6;
	5'd6: nextstate = 5'd7;
	5'd7: nextstate = 5'd8;
	5'd8: nextstate = 5'd9;
	5'd9: nextstate = 5'd10;
	5'd10: nextstate = 5'd11;
	5'd11: nextstate = 5'd12;
	5'd12: nextstate = 5'd13;
	5'd13: nextstate = 5'd14;
	5'd14: begin
				if(read_address_120)
					nextstate = 5'd15;
				else
					nextstate = 5'd1;
			end			
	5'd15: nextstate = 5'd15;
	default: nextstate = 5'd0;
	endcase
end

assign done = (state==5'd15);
	
endmodule



/*`timescale 1ns / 1ps

module BS2POLVECp(clk, rst, read_address, read_data,
								 write_address, write_data, write_en,
								 done);
input clk, rst;
output reg [8:0] read_address;
input [63:0] read_data;

output reg [8:0] write_address;
output [63:0] write_data;
output write_en;

output done;

reg [319:0] buffer;
reg inc_write_address, inc_read_address, buffer40_en, buffer64_en;
reg [4:0] state, nextstate;

always @(posedge clk)
begin
	if(buffer40_en)
		buffer <= {40'd0, buffer[319:40]};
	else if(buffer64_en)
		buffer <= {read_data, buffer[319:64]};
end

assign write_data = {6'd0,buffer[39:30],6'd0,buffer[29:20],6'd0,buffer[19:10],6'd0,buffer[9:0]};
assign write_en = inc_write_address;

always @(posedge clk)
begin
	if(rst)
		read_address <= 9'd0;
	else if(inc_read_address)
		read_address <= read_address + 1'b1;
end

wire read_address_120 = (read_address==9'd120);

always @(posedge clk)
begin
	if(rst)
		write_address <= 9'd0;
	else if(inc_write_address)
		write_address <= write_address + 1'b1;
end

always @(posedge clk)
begin
	if(rst)
		state <= 5'd0;
	else
	    state <= nextstate;
end		

always @(state)
begin
	case(state)
	5'd0: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end
	
	// Read 5 64 bit words and store in buffer
	5'd1:  begin inc_read_address<=1; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end
	5'd2:  begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=1; inc_write_address<=0; end
	5'd3:  begin inc_read_address<=1; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end
	5'd4:  begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=1; inc_write_address<=0; end
	5'd5:  begin inc_read_address<=1; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end
	5'd6:  begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=1; inc_write_address<=0; end
	5'd7:  begin inc_read_address<=1; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end
	5'd8:  begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=1; inc_write_address<=0; end
	5'd9:  begin inc_read_address<=1; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end
	5'd10: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=1; inc_write_address<=0; end
	
	// Read 40 bit chunks; write 4 coeff in uint16_t 
	5'd11: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd12: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end
	5'd13: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd14: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end
	5'd15: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd16: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end
	5'd17: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd18: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end
	5'd19: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd20: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end
	5'd21: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd22: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end	
	5'd23: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd24: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end	
	5'd25: begin inc_read_address<=0; buffer40_en<=1; buffer64_en<=0; inc_write_address<=0; end
	5'd26: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=1; end
	5'd27: begin  inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end	
	5'd28: begin  inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end
	default: begin inc_read_address<=0; buffer40_en<=0; buffer64_en<=0; inc_write_address<=0; end		
	endcase
end

always @(state or read_address_120)
begin
	case(state)
	5'd0:  nextstate <= 5'd1; 
	5'd1:  nextstate <= 5'd2; 
	5'd2:  nextstate <= 5'd3; 
	5'd3:  nextstate <= 5'd4; 
	5'd4:  nextstate <= 5'd5; 	
	5'd5:  nextstate <= 5'd6; 	
	5'd6:  nextstate <= 5'd7; 
	5'd7:  nextstate <= 5'd8; 
	5'd8:  nextstate <= 5'd9; 
	5'd9:  nextstate <= 5'd10; 
	5'd10: nextstate <= 5'd11; 
	5'd11: nextstate <= 5'd12; 
	5'd12: nextstate <= 5'd13; 
	5'd13: nextstate <= 5'd14;
	5'd14: nextstate <= 5'd15;
	5'd15: nextstate <= 5'd16;
	5'd16: nextstate <= 5'd17;
	5'd17: nextstate <= 5'd18; 
	5'd18: nextstate <= 5'd19; 
	5'd19: nextstate <= 5'd20; 
	5'd20: nextstate <= 5'd21;
	5'd21: nextstate <= 5'd22;
	5'd22: nextstate <= 5'd23;
	5'd23: nextstate <= 5'd24;
	5'd24: nextstate <= 5'd25;
	5'd25: nextstate <= 5'd26; 
	5'd26: begin
	           //if(read_address==9'd55)
	           //    nextstate <= 5'd2;
	           if(read_address_120)
	               nextstate <= 5'd27;
	           else
	               nextstate <= 5'd1;
			end
	5'd27: nextstate <= 5'd28;
	5'd28: nextstate <= 5'd28; 
	default: nextstate <= 5'd0;
	endcase
end

assign done = (state==5'd28);
	
endmodule
*/
