`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             vector_sampler
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module vector_sampler(clk, rst, rd_address, data_in,
						sample_pack, wt_address, wen, done);
input clk, rst;
output reg [8:0] rd_address;
input [63:0] data_in;

output reg [63:0] sample_pack;
output reg [8:0] wt_address;	// Address for writing 16 samples in BRAM
output reg wen;
output done;

reg [1:0] wen_sample_pack;
reg [3:0] state, nextstate;
reg rd_inc, wt_inc;

wire [4:0] temp_s0 = (data_in[0]+data_in[1]+data_in[2]+data_in[3]) - (data_in[4]+data_in[5]+data_in[6]+data_in[7]);
wire [3:0] s0;
assign s0[0] = temp_s0[0];
assign s0[1] = (temp_s0[4]&temp_s0[0])^temp_s0[1];
assign s0[2] = (temp_s0[4]&(temp_s0[0]|temp_s0[1]))^temp_s0[2];
assign s0[3] = temp_s0[4];

wire [4:0] temp_s1 = (data_in[8]+data_in[9]+data_in[10]+data_in[11]) - (data_in[12]+data_in[13]+data_in[14]+data_in[15]);
wire [3:0] s1;
assign s1[0] = temp_s1[0];
assign s1[1] = (temp_s1[4]&temp_s1[0])^temp_s1[1];
assign s1[2] = (temp_s1[4]&(temp_s1[0]|temp_s1[1]))^temp_s1[2];
assign s1[3] = temp_s1[4];

wire [4:0] temp_s2 = (data_in[16]+data_in[17]+data_in[18]+data_in[19]) - (data_in[20]+data_in[21]+data_in[22]+data_in[23]);
wire [3:0] s2;
assign s2[0] = temp_s2[0];
assign s2[1] = (temp_s2[4]&temp_s2[0])^temp_s2[1];
assign s2[2] = (temp_s2[4]&(temp_s2[0]|temp_s2[1]))^temp_s2[2];
assign s2[3] = temp_s2[4];

wire [4:0] temp_s3 = (data_in[24]+data_in[25]+data_in[26]+data_in[27]) - (data_in[28]+data_in[29]+data_in[30]+data_in[31]);
wire [3:0] s3;
assign s3[0] = temp_s3[0];
assign s3[1] = (temp_s3[4]&temp_s3[0])^temp_s3[1];
assign s3[2] = (temp_s3[4]&(temp_s3[0]|temp_s3[1]))^temp_s3[2];
assign s3[3] = temp_s3[4];

wire [4:0] temp_s4 = (data_in[32]+data_in[33]+data_in[34]+data_in[35]) - (data_in[36]+data_in[37]+data_in[38]+data_in[39]);
wire [3:0] s4;
assign s4[0] = temp_s4[0];
assign s4[1] = (temp_s4[4]&temp_s4[0])^temp_s4[1];
assign s4[2] = (temp_s4[4]&(temp_s4[0]|temp_s4[1]))^temp_s4[2];
assign s4[3] = temp_s4[4];

wire [4:0] temp_s5 = (data_in[40]+data_in[41]+data_in[42]+data_in[43]) - (data_in[44]+data_in[45]+data_in[46]+data_in[47]);
wire [3:0] s5;
assign s5[0] = temp_s5[0];
assign s5[1] = (temp_s5[4]&temp_s5[0])^temp_s5[1];
assign s5[2] = (temp_s5[4]&(temp_s5[0]|temp_s5[1]))^temp_s5[2];
assign s5[3] = temp_s5[4];

wire [4:0] temp_s6 = (data_in[48]+data_in[49]+data_in[50]+data_in[51]) - (data_in[52]+data_in[53]+data_in[54]+data_in[55]);
wire [3:0] s6;
assign s6[0] = temp_s6[0];
assign s6[1] = (temp_s6[4]&temp_s6[0])^temp_s6[1];
assign s6[2] = (temp_s6[4]&(temp_s6[0]|temp_s6[1]))^temp_s6[2];
assign s6[3] = temp_s6[4];

wire [4:0] temp_s7 = (data_in[56]+data_in[57]+data_in[58]+data_in[59]) - (data_in[60]+data_in[61]+data_in[62]+data_in[63]);
wire [3:0] s7;
assign s7[0] = temp_s7[0];
assign s7[1] = (temp_s7[4]&temp_s7[0])^temp_s7[1];
assign s7[2] = (temp_s7[4]&(temp_s7[0]|temp_s7[1]))^temp_s7[2];
assign s7[3] = temp_s7[4];

always @(posedge clk)
begin
	if(wen_sample_pack==2'd1)
		sample_pack[31:00] <= {s7, s6, s5, s4, s3, s2, s1, s0};
	else if(wen_sample_pack==2'd2)
		sample_pack[63:32] <= {s7, s6, s5, s4, s3, s2, s1, s0};
	else
		sample_pack <= sample_pack;
end

always @(posedge clk or posedge rst)
begin
	if(rst)
		state <= 3'd0;
	else
		state <= nextstate;
end

always@(posedge clk or posedge rst)
begin
	if(rst)
		rd_address <= 9'd0;
	else if(rd_inc)
		rd_address <= rd_address + 1'b1;
	else
		rd_address <= rd_address;
end

always@(posedge clk or posedge rst)
begin
	if(rst)
		wt_address <= 9'd0;
	else if(wt_inc)
		wt_address <= wt_address + 1'b1;
	else
		wt_address <= wt_address;
end

// 3 polynomials take 3*16=48 words
wire sampling_done = (wt_address==9'd48) ? 1'b1 : 1'b0;

always @(*)
begin
	case(state)
	4'd0: begin	rd_inc=1'b0; wen_sample_pack=2'd0; wen=1'b0; wt_inc=1'b0; end // its an idle state
	4'd1: begin	rd_inc=1'b1; wen_sample_pack=2'd0; wen=1'b0; wt_inc=1'b0; end // read 1st word
	4'd2: begin	rd_inc=1'b0; wen_sample_pack=2'd0; wen=1'b0; wt_inc=1'b0; end // 1 cycle delay due to 1-pipeline register
	4'd3: begin	rd_inc=1'b1; wen_sample_pack=2'd1; wen=1'b0; wt_inc=1'b0; end // read 2nd word & write 1st word (it will write first 8 results)
	4'd4: begin	rd_inc=1'b0; wen_sample_pack=2'd0; wen=1'b0; wt_inc=1'b0; end // 1 cycle delay due to 1-pipeline register
	4'd5: begin	rd_inc=1'b0; wen_sample_pack=2'd2; wen=1'b0; wt_inc=1'b0; end // write 2nd word (it will write second 8 results)
	
	// Inc rd_addr for next read
	// Now, write the 16 samples to BRAM; 
	// Increment BRAM write address
	4'd6: begin	rd_inc=1'b1; wen_sample_pack=2'd0; wen=1'b1; wt_inc=1'b1; end // it only reads
	4'd7: begin	rd_inc=1'b0; wen_sample_pack=2'd0; wen=1'b0; wt_inc=1'b0; end // 1 cycle delay due to 1-pipeline register & set write associated signals
		
	4'd8: begin rd_inc=1'b0; wen_sample_pack=2'd0; wen=1'b0; wt_inc=1'b0; end		
	default: begin rd_inc=1'b0; wen_sample_pack=2'd0; wen=1'b0; wt_inc=1'b0; end		
	endcase
end

always @(*)
begin
	case(state)
	4'd0: nextstate = 4'd1;
	4'd1: nextstate = 4'd2;
	4'd2: nextstate = 4'd3;
	4'd3: begin
			if(sampling_done)
				nextstate = 4'd8;
			else
				nextstate = 4'd4;
		end	
	4'd4: nextstate = 4'd5;
	4'd5: nextstate = 4'd6;
	4'd6: nextstate = 4'd7;
	4'd7: nextstate = 4'd3;
	4'd8: nextstate = 4'd8;
	default: nextstate = 4'd8;
	endcase
end

assign done = (state==4'd8) ? 1'b1 : 1'b0;
endmodule
