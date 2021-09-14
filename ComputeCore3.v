
`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             ComputeCore3
    2. Preparation Date:        May 04, 2021
    3. Initial designed by:     Dr. Sujoy Sinha Roy and Andrea Basso
    4. Design optimized by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module ComputeCore3(clk, rst, addr, din, we,
					command_in, command_we0, command_we1, done, 
					doutb_ext,
					done_shake, done_vmul, done_addround, 
					done_addpack, done_bs2polvecp, done_unpack, done_copy, done_sampler, done_verify, done_cmov, done_timer);

input clk, rst; 
input [9:0] addr;
input [63:0] din;
input we;

input [34:0] command_in;
input command_we0, command_we1, done;
output [63:0] doutb_ext;
output done_shake, done_vmul, done_addround, done_addpack, done_bs2polvecp, done_unpack, done_copy, done_sampler, done_verify, done_cmov, done_timer;

    // signals to drive data to/from RF Units
    wire [7:0] write_or_read_addr_A, write_or_read_addr_B, write_or_read_addr_C, write_or_read_addr_D;
    wire wea1, wea2, wea3, wea4;
    wire [63:0] dina_A, dina_B, dina_C, dina_D;
    wire [63:0] dout1, dout2, dout3, dout4;
    
    
    reg [34:0] command_reg0, command_reg1;
    reg [63:0] doutb_reg;
    wire [63:0] dina;
    wire [4:0] INS;
    wire [9:0] OP1, OP2, OP3;
    wire [63:0] doutb;
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            command_reg0 <= 35'd0;
        else if(command_we0)
            command_reg0 <= command_in;
        else
           command_reg0 <= command_reg0;	
    end
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            command_reg1 <= 35'd0;
        else if(command_we1)
            command_reg1 <= command_in;
        else
           command_reg1 <= command_reg1;	
    end
    
    /*---------------------------------------------------
    -- Inclusion of pipeline register
    ----------------------------------------------------*/
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            doutb_reg <= 64'd0;
        else
            doutb_reg <= doutb;
    end
    
    assign INS = command_reg0[4:0];
    assign OP1 = command_reg0[14:5];
    assign OP2 = command_reg0[24:15];
    assign OP3 = command_reg0[34:25];	
    
    wire clear_sha, enable_sha, shake_intermediate_rst, shake_next_extract;
    wire [1:0] rate_type;
    wire [31:0] mlen, olen;
    wire [8:0] rd_address_shake, wt_address_shake;
    wire [63:0] din_shake, dout_shake;
    wire sample_dout, done_shake;
    
    wire rst_sampler, wea_sampler, done_sampler;
    wire [8:0] rd_address_sampler, wt_address_sampler;
    wire [63:0] dout_sampler;
    
    wire rst_vmul, pol_load_coeff4x, s_load_happens_now, wea_vmul, done_vmul;
    wire [8:0] rd_address_vmul, s_address, wt_address_vmul;
    wire [2:0] s;
    wire s_sign;
    wire [63:0] dout_vmul;
    
    wire rst_addround, wea_addround, done_addround;
    wire [8:0] rd_address_addround, wt_address_addround;
    wire [63:0] dout_addround;
    
    wire rst_addpack, wea_addpack, done_addpack;
    wire rd_base_sel_addpack;
    wire [8:0] rd_address_addpack, wt_address_addpack;
    wire [63:0] dout_addpack;
    
    wire rst_unpack, wea_unpack, done_unpack;
    wire rd_base_sel_unpack;
    wire [8:0] rd_address_unpack, wt_address_unpack;
    wire [63:0] dout_unpack;
    
    wire rst_bs2polvecp, wea_bs2polvecp, done_bs2polvecp;
    wire [8:0] rd_address_bs2polvecp, wt_address_bs2polvecp;
    wire [63:0] dout_bs2polvecp;
    
    wire rst_copy, wea_copy, done_copy; 
    wire [8:0] number_words_copy, rd_address_copy, wt_address_copy;
    wire [63:0] dout_copy;
                           
    wire [9:0] rd_address, wt_address;
    wire [9:0] addra, addrb;
    wire wea;
    
    wire [9:0] ilen;
    wire rst_verify, rd_base_sel_verify, verify_true_wire, done_verify;
    wire [8:0] rd_address_verify;
    reg verify_true;
    
    wire rst_cmov, rd_base_sel_cmov, wea_cmov, done_cmov;
    wire [8:0] rd_address_cmov, wt_address_cmov;
    wire [63:0] dout_cmov;
    
    wire rst_timer;
    wire [8:0] rd_address_timer;
    wire done_timer;
    
    assign rst_vmul = (INS==5'd6||INS==5'd10) ? 1'b0 : 1'b1;
    assign pol_load_coeff4x = (INS==5'd10) ? 1'b1 : 1'b0;   ////// CHECK to update
    assign rst_addround = (INS==5'd7) ? 1'b0 : 1'b1;
    assign rst_addpack = (INS==5'd8) ? 1'b0 : 1'b1;
    assign rst_bs2polvecp = (INS==5'd9) ? 1'b0 : 1'b1;
    assign rst_unpack = (INS==5'd11) ? 1'b0 : 1'b1;
    assign rst_copy = (INS==5'd12) ? 1'b0 : 1'b1;
    assign rst_sampler = (INS==5'd13) ? 1'b0 : 1'b1;
    assign rst_verify = (INS==5'd14) ? 1'b0 : 1'b1;
    assign rst_cmov = (INS==5'd15) ? 1'b0 : 1'b1;
    assign rst_timer = (INS==5'd17) ? 1'b0 : 1'b1;
     
    //assign rd_address = (enable_sha) ? {1'b0,rd_address_shake} : (rst_vmul==1'b0) ? {1'b0,rd_address_vmul} : (rst_addround==1'b0) ? {1'b0,rd_address_addround} : (rst_addpack==1'b0) ? {1'b0,rd_address_addpack} : (rst_bs2polvecp==1'b0) ? {1'b0,rd_address_bs2polvecp} : (rst_unpack==1'b0) ? {1'b0,rd_address_unpack} : (rst_copy==1'b0) ? {1'b0,rd_address_copy} : (rst_sampler==1'b0) ? {1'b0,rd_address_sampler} : (rst_verify==1'b0) ? {1'b0,rd_address_verify} : (rst_cmov==1'b0) ? {1'b0,rd_address_cmov} : (rst_timer==1'b0) ? {1'b0,rd_address_timer} : addr;
    assign rd_address = (enable_sha) ? {1'b0,rd_address_shake} : (rst_vmul==1'b0) ? {1'b0,rd_address_vmul} : (rst_addround==1'b0) ? {1'b0,rd_address_addround} : (rst_addpack==1'b0) ? {1'b0,rd_address_addpack} : (rst_bs2polvecp==1'b0) ? {1'b0,rd_address_bs2polvecp} : (rst_unpack==1'b0) ? {1'b0,rd_address_unpack} : (rst_copy==1'b0) ? {1'b0,rd_address_copy} : (rst_sampler==1'b0) ? {1'b0,rd_address_sampler} : (rst_verify==1'b0) ? {1'b0,rd_address_verify} : (rst_cmov==1'b0) ? {1'b0,rd_address_cmov} : addr;
    assign wt_address = (enable_sha) ? {1'b0,wt_address_shake} : (rst_vmul==1'b0) ? {1'b0,wt_address_vmul} : (rst_addround==1'b0) ? {1'b0,wt_address_addround} : (rst_addpack==1'b0) ? {1'b0,wt_address_addpack} : (rst_bs2polvecp==1'b0) ? {1'b0,wt_address_bs2polvecp} : (rst_unpack==1'b0) ? {1'b0,wt_address_unpack} : (rst_copy==1'b0) ? {1'b0,wt_address_copy} : (rst_sampler==1'b0) ? {1'b0,wt_address_sampler} : (rst_cmov==1'b0) ? {1'b0,wt_address_cmov} : addr;
    assign wea = (enable_sha) ? sample_dout : (rst_vmul==1'b0) ? wea_vmul : (rst_addround==1'b0) ? wea_addround : (rst_addpack==1'b0) ? wea_addpack : (rst_bs2polvecp==1'b0) ? wea_bs2polvecp : (rst_unpack==1'b0) ? wea_unpack : (rst_copy==1'b0) ? wea_copy : (rst_sampler==1'b0) ? wea_sampler : (rst_cmov==1'b0) ? wea_cmov : we;
    assign dina = (enable_sha) ? dout_shake : (rst_vmul==1'b0) ? dout_vmul : (rst_addround==1'b0) ? dout_addround : (rst_addpack==1'b0) ? dout_addpack : (rst_bs2polvecp==1'b0) ? dout_bs2polvecp : (rst_unpack==1'b0) ? dout_unpack : (rst_copy==1'b0) ? dout_copy : (rst_sampler==1'b0) ? dout_sampler :  (rst_cmov==1'b0) ? dout_cmov : din;
    wire op2_sel = (rst_addpack==1'b0) ? rd_base_sel_addpack : (rst_unpack==1'b0) ? rd_base_sel_unpack : (rst_vmul==1'b0) ? s_load_happens_now : (rst_verify==1'b0) ? rd_base_sel_verify : (rst_cmov==1'b0) ? rd_base_sel_cmov : 1'b0;
    
    wire [9:0] OP1_or_OP2 = (op2_sel) ? OP2 : OP1;
    assign addra = OP3 + wt_address;
    assign addrb = OP1_or_OP2 + rd_address;
    
    assign doutb_ext = doutb;
    
    wire [63:0] s_vec_64;
    
    /*I have captured read address in signal read_for_chip_output*/
    wire [63:0] read_for_chip_output = (done) ? addr : addrb;
    
    
// here starts the shared buffer connections
wire [675:0] buffer; // from shared_buffer

wire AR_buffer40_en; // from add_round
wire [39:0] AR_buffer40_data; // from add_round
wire AR_buffer64_en; // from add_round

wire BS_buffer40_en; // from BS2POLVECp
wire BS_buffer64_en; // from BS2POLVECp
wire [63:0] BS_buffer64_data; // from BS2POLVECp

wire AM_buffer16_en; // from add_m_pack
wire [15:0] AM_buffer16_data; // from add_m_pack

wire PO_pol_load_coeff4x; // from pol_mul
wire PO_poly_load; // from pol_mul
wire [63:0] PO_poly_load_data; // from pol_mul
wire PO_poly_shift; // from pol_mul

shared_buffer shared_buffer (
	.clk (clk),
	.AR_buffer40_en (AR_buffer40_en), 
	.AR_buffer40_data (AR_buffer40_data), 
	.AR_buffer64_en (AR_buffer64_en), 
	.BS_buffer40_en (BS_buffer40_en),
	.BS_buffer64_en (BS_buffer64_en),
	.BS_buffer64_data (BS_buffer64_data),
	.AM_buffer16_en (AM_buffer16_en),
	.AM_buffer16_data (AM_buffer16_data),
	.PO_pol_load_coeff4x (PO_pol_load_coeff4x),
	.PO_poly_load (PO_poly_load),
	.PO_poly_load_data (PO_poly_load_data),
	.PO_poly_shift (PO_poly_shift),
	.buffer (buffer)
);

    
    SHA_SHAKE_wrapper SH(clk, clear_sha, shake_intermediate_rst, shake_next_extract, 
                                rate_type, mlen, 
                                rd_address_shake, din_shake,
                                olen, dout_shake, wt_address_shake, sample_dout, 
                                done_shake);
    
    assign enable_sha = (INS==5'd1||INS==5'd2||INS==5'd3||INS==5'd4||INS==5'd5) ? 1'b1 : 1'b0;
    assign clear_sha = (INS==5'd0 || enable_sha==1'b0) ? 1'b1 : 1'b0;
    assign shake_intermediate_rst	= (INS==5'd4) ? 1'b1 : 1'b0;
    assign shake_next_extract = (INS==5'd5) ? 1'b1 : 1'b0;
    assign rate_type = (INS==5'd1) ? 2'd1 : (INS==5'd2) ? 2'd0 : 2'd2;
    assign mlen = {16'd0, command_reg1[15:0]};
    assign din_shake = doutb;
    assign olen = {16'd0, command_reg1[31:16]};
    
    VectorMul_wrapper	VMUL0(clk, rst_vmul, pol_load_coeff4x,
                                    s_load_happens_now, rd_address_vmul, doutb,
                                    //s_address, s_vec_64,	// s_address will be merged later
                                    wt_address_vmul, dout_vmul, wea_vmul, 
                                    done_vmul, PO_pol_load_coeff4x, PO_poly_load, PO_poly_load_data, PO_poly_shift, buffer);
                                    
    Add_Round	AddRound0(clk, rst_addround, rd_address_addround, doutb,
                                        wt_address_addround, dout_addround, wea_addround,
                                        done_addround,
					AR_buffer40_en, AR_buffer40_data, AR_buffer64_en, buffer[319:0]);
                                        
    Add_m_pack	AddPack0(clk, rst_addpack, rd_base_sel_addpack, rd_address_addpack, doutb,
                                        wt_address_addpack, dout_addpack, wea_addpack,
                                        done_addpack, AM_buffer16_en, AM_buffer16_data, buffer[63:0]);
    
    BS2POLVECp	BC2PVEC(clk, rst_bs2polvecp, rd_address_bs2polvecp, doutb,
                                     wt_address_bs2polvecp, dout_bs2polvecp, wea_bs2polvecp,
                                     done_bs2polvecp, BS_buffer40_en, BS_buffer64_en, BS_buffer64_data, buffer[319:0]);
    
    unpack		unpack0(clk, rst_unpack, rd_base_sel_unpack, rd_address_unpack, doutb,
                                        wt_address_unpack, dout_unpack, wea_unpack,
                                        done_unpack);
    
    // Copy from OP1 to OP3 where the number of words is specified in OP2								
    copy_words        copy(clk, rst_copy, number_words_copy, 
                                rd_address_copy, doutb,
                                wt_address_copy, dout_copy, wea_copy,
                                done_copy);
    assign number_words_copy = OP2[8:0];                          
    
                                        
    vector_sampler      Sampler(clk, rst_sampler, rd_address_sampler, doutb_reg,
                                  dout_sampler, wt_address_sampler, wea_sampler, done_sampler);
    
    assign ilen = command_reg1[9:0];
                            
    verify              VERIFY1(clk, rst_verify, ilen, rd_address_verify, rd_base_sel_verify, doutb,
                               verify_true_wire, done_verify);
    
    cmov                CMOV1(clk, rst_cmov, verify_true,
                            rd_base_sel_cmov, rd_address_cmov, doutb,
                            wt_address_cmov, dout_cmov, wea_cmov,
                            done_cmov);

    assign done_timer = 1'b0;
    
    always @(posedge clk)
    begin
        if(done_verify)
            verify_true <= verify_true_wire;
        else
            verify_true <= verify_true;
     end
    
    // selects an appropriate read or write operation for RF units
    wire [9:0] write_or_read_addr = (wea) ? addra : read_for_chip_output;
    
    /*---------------------------------------------------
    -- Read/Write addresses for the RF units
    ----------------------------------------------------*/                   
    assign write_or_read_addr_A = (write_or_read_addr[9:8]==2'd1 && write_or_read_addr[8:0] == 9'd256) ? write_or_read_addr :
                                  (write_or_read_addr[9:8]==2'd0 && write_or_read_addr[7:0] ==8'd255) ? write_or_read_addr :
                                  (write_or_read_addr[9:8]==2'd0) ? write_or_read_addr :
                                   64'd0;
                                  
    assign write_or_read_addr_B = (write_or_read_addr[9:8]==2'd2 && write_or_read_addr[8:0] == 9'd256) ? write_or_read_addr :
                                  (write_or_read_addr[9:8]==2'd1 && write_or_read_addr[7:0] == 8'd255) ? write_or_read_addr :
                                  (write_or_read_addr[9:8]==2'd1) ? write_or_read_addr : 
                                  64'd0;
                                   
    assign write_or_read_addr_C = (write_or_read_addr[9:8]==2'd3 && write_or_read_addr[8:0] == 9'd256) ? write_or_read_addr :
                                  (write_or_read_addr[9:8]==2'd2 && write_or_read_addr[7:0] == 8'd255) ? write_or_read_addr :
                                  (write_or_read_addr[9:8]==2'd2) ? write_or_read_addr : 
                                   64'd0;
                                   
    assign write_or_read_addr_D = (write_or_read_addr[9:8]==2'd3 && write_or_read_addr[7:0] == 8'd255) ? write_or_read_addr : 
                                  (write_or_read_addr[9:8]==2'd3) ? write_or_read_addr :
                                   64'd0;
    
    
    /*---------------------------------------------------
    -- read/write enable signals for Read/Write operations
    ----------------------------------------------------*/                                
    assign wea1 = (write_or_read_addr[9:8]==2'd0) ? wea :
                  (write_or_read_addr[9:8]==2'd0 && write_or_read_addr[7:0] == 8'd255) ? wea :
                  1'd0;
                  
    assign wea2 = (write_or_read_addr[9:8]==2'd1) ? wea :
                  (write_or_read_addr[9:8]==2'd1 && write_or_read_addr[7:0] == 8'd255) ? wea :
                  (write_or_read_addr[9:8]==2'd2 && write_or_read_addr[8:0] == 9'd256) ? wea :
                  1'd0;
                  
    assign wea3 = (write_or_read_addr[9:8]==2'd2) ? wea :
                  (write_or_read_addr[9:8]==2'd2 && write_or_read_addr[7:0] == 8'd255) ? wea :
                  (write_or_read_addr[9:8]==2'd3 && write_or_read_addr[8:0] == 9'd256) ? wea :
                  1'd0;
                  
    assign wea4 = (write_or_read_addr[9:8]==2'd3) ? wea :
                  (write_or_read_addr[9:8]==2'd3 && write_or_read_addr[7:0] == 8'd255) ? wea :
                  1'd0;
    
    
    /*---------------------------------------------------
    -- Data write logic
    ----------------------------------------------------*/
    assign dina_A = (write_or_read_addr[9:8]==2'd0) ? dina : 
                    (write_or_read_addr[9:8]==2'd0 && write_or_read_addr[7:0] == 8'd255) ? dina :
                    (write_or_read_addr[9:8]==2'd1 && write_or_read_addr[8:0] == 9'd256) ? dina :
                    64'd0;
                    
    assign dina_B = (write_or_read_addr[9:8]==2'd1) ? dina : 
                    (write_or_read_addr[9:8]==2'd1 && write_or_read_addr[7:0] == 8'd255) ? dina :
                    (write_or_read_addr[9:8]==2'd2 && write_or_read_addr[8:0] == 9'd256) ? dina :
                    64'd0;
                    
    assign dina_C = (write_or_read_addr[9:8]==2'd2) ? dina : 
                    (write_or_read_addr[9:8]==2'd2 && write_or_read_addr[7:0] == 8'd255) ? dina :
                    (write_or_read_addr[9:8]==2'd3 && write_or_read_addr[8:0] == 9'd256) ? dina :
                    64'd0;
                    
    assign dina_D = (write_or_read_addr[9:8]==2'd3) ? dina : 
                    (write_or_read_addr[9:8]==2'd3 && write_or_read_addr[7:0] == 8'd255) ? dina :
                    64'd0;
                    
    /*---------------------------------------------------
    -- Data read logic
    ----------------------------------------------------*/
    assign doutb = (write_or_read_addr >= 10'd0 && write_or_read_addr <= 10'd255) ? dout1 :
                   (write_or_read_addr==10'd256) ? dout1 :
                   (write_or_read_addr >= 10'd257 && write_or_read_addr <= 10'd511) ? dout2 :
                   (write_or_read_addr==10'd512) ? dout2 :
                   (write_or_read_addr >= 10'd513 && write_or_read_addr <= 10'd767) ? dout3 :
                   (write_or_read_addr==10'd768) ? dout3 :
                   (write_or_read_addr >= 10'd769 && write_or_read_addr <= 10'd1023) ? dout4 :
                   64'd0;
    
    /*---------------------------------------------------
    -- Instantiations of employed RF Units
    ----------------------------------------------------*/
    RF_256_64 RF_A(
        .CLK(clk),
        .CEB(1'b0), 
        .WEB(~wea1),
        .A(write_or_read_addr_A), 
        .D(dina_A), 
        .BWEB(64'b0), 
        .Q(dout1)
    );


    RF_256_64 RF_B(
        .CLK(clk),
        .CEB(1'b0), 
        .WEB(~wea2),
        .A(write_or_read_addr_B), 
        .D(dina_B), 
        .BWEB(64'b0), 
        .Q(dout2)
    );
    
    RF_256_64 RF_C(
        .CLK(clk),
        .CEB(1'b0), 
        .WEB(~wea3),
        .A(write_or_read_addr_C), 
        .D(dina_C), 
        .BWEB(64'b0), 
        .Q(dout3)
    );
    
    RF_256_64 RF_D(
        .CLK(clk),
        .CEB(1'b0), 
        .WEB(~wea4),
        .A(write_or_read_addr_D), 
        .D(dina_D), 
        .BWEB(64'b0), 
        .Q(dout4)
    );
endmodule
