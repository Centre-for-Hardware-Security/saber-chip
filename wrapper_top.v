
`timescale 1ns / 1ps

/***************************************************************************************************
    1. Design Name:             wrapper_top
    2. Preparation Date:        June 02, 2021
    3. Initial designed by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module wrapper_top(clk1, clk2, rst, addr, din, addr_ready, LAD1, LAD2, we, CONT, start, crypto_op_1, crypto_op_2, crypto_op_3, dout, done);

// Inputs to the wrapper (14-pins)
input clk1;
input clk2;
input rst; 
input addr;
input din;
input addr_ready;
input LAD1; // load_address_data
input LAD2; //load_address_data
input we; 
input crypto_op_1;
input crypto_op_2;
input crypto_op_3;
input CONT;
input start;
	
// Outputs from the wrapper (2-pins)
output dout;
output done;

// done signals for the corresponding crypto_operations
reg done_kem_keygen;
reg done_kem_encapsulation;
reg done_kem_decapsulation;
reg done_pke_keygen;
reg done_pke_encapsulation;
reg done_pke_decapsulation;
reg done_CONT;

// To generate 1-bit done signal on the chip
assign done = (done_kem_keygen || done_kem_encapsulation || done_kem_decapsulation);

// signals to keep status of the SABER operations (used inside the FSM) 
wire done_shake;
wire done_vmul;
wire done_addround; 
wire done_addpack; 
wire done_bs2polvecp;
wire done_unpack;
wire done_copy;
wire done_sampler;
wire done_verify;
wire done_cmov;

// initializatios of signals to drive PKE and KEM operations
reg [34:0] command_in;
reg command_we0;
reg command_we1;

// routing wires 
wire [9:0]  addr_for_RF;
wire [63:0] din_for_RF;
wire [63:0] doutb_ext_from_ComputeCore3;

// A 10 bit signal to enable command_in port of ComputeCore3  
reg [9:0] state, nextstate;

// signals to hold external address and data for RF
reg [9:0]  addr_for_RF_reg;
reg [63:0] din_for_RF_reg;
reg [63:0] doutb_ext_from_ComputeCore3_reg;

// Starting FSM states to run required crypto operation (KEM_KEYGEN, KEM_ENCAPS, KEM_DECAPS, PKE_KEYGEN, PKE_ENC, PKE_DEC) 
parameter CONDITIONAL = 10'd0;
//parameter IDLE        = 10'd1023;
parameter PKE_KEYGEN  = 10'd0;
parameter PKE_ENC     = 10'd0;
parameter PKE_DEC     = 10'd0;
parameter KEM_KEYGEN  = 10'd1;
parameter KEM_ENCAPS  = 10'd100;
parameter KEM_DECAPS  = 10'd199;

// Truthtable for the execution of crypto operations (i.e., KEM_KEYGEN, KEM_ENCAPS, KEM_DECAPS, PKE_KEYGEN, PKE_ENC, and PKE_DEC)
/*
crypto_op_3     crypto_op_2     crypto_op_1
000 means NOP
001 means Execute PKE_KEYGEN
010 means Execute PKE_ENC
011 means Execute PKE_DEC
100 means NOP
101 means Execute KEM_KEYGEN
110 means Execute KEM_ENCAPS
111 means Execute KEM_DECAPS
*/

// Encoding signal to execute the crypto operation
wire [2:0] OP;
assign OP[0] = crypto_op_1;
assign OP[1] = crypto_op_2;
assign OP[2] = crypto_op_3;

// Truthtable to load the address, data and corresponding we from outside on chip
/*
LAD2     LAD1
00 means NOP
01 means Load address on the chip
10 means Load data_in from outside on the chip
11 means we signal to update memory contents (data_in) on the corresponding address
*/

wire internal_done_to_read_data_for_chip_op = (done) ? 1'b1 : 1'b0;

ComputeCore3 ComputeCore3_uut(
                               .clk(clk2), 
                               .rst(rst), 
                               .addr(addr_for_RF_reg), 
                               .din(din_for_RF_reg), 
                               .we(we),
                               .command_in(command_in), 
                               .command_we0(command_we0), 
                               .command_we1(command_we1),
                               .doutb_ext(doutb_ext_from_ComputeCore3),
                               .done_shake(done_shake), 
                               .done_vmul(done_vmul), 
                               .done_addround(done_addround),
                               .done_addpack(done_addpack),
                               .done_bs2polvecp(done_bs2polvecp),
                               .done_unpack(done_unpack), 
                               .done_copy(done_copy), 
                               .done_sampler(done_sampler), 
                               .done_verify(done_verify), 
                               .done_cmov(done_cmov),
                               .done(internal_done_to_read_data_for_chip_op)
                              );
                              
shift_registers shift_registers_uut(
                                .clk1(clk1), 
                                .rst(rst), 
                                .addr(addr), 
                                .din(din), 
                                .LAD1(LAD1),
                                .LAD2(LAD2), 
                                .data_from_RF_to_chip_output(doutb_ext_from_ComputeCore3_reg),
                                .addr_reg(addr_for_RF), 
                                .din_reg(din_for_RF),
                                .dout_for_chip(dout)
                              );

//-------------------------------------------------------------------------------------------------
// -- The right data and address for ComputeCore3 block
//-------------------------------------------------------------------------------------------------
always @(posedge clk1 or posedge rst) begin
	if(rst) begin
	   addr_for_RF_reg <= 10'd0;
	   din_for_RF_reg <= 64'd0;
	end
	else if(addr_ready) begin
	   addr_for_RF_reg <= addr_for_RF;
	   din_for_RF_reg <= din_for_RF;
    end
end 

//-------------------------------------------------------------------------------------------------
// -- Logic for the Read data from RF block to chip output
//-------------------------------------------------------------------------------------------------
always @(posedge clk2 or posedge rst) begin
	if(rst) begin
	   doutb_ext_from_ComputeCore3_reg <= 64'd0;
	end
	else if(addr_ready) begin //To do check
	   doutb_ext_from_ComputeCore3_reg <= doutb_ext_from_ComputeCore3;
    end
end 

//-------------------------------------------------------------------------------------------------
// -- FSM (sequential logic)
//-------------------------------------------------------------------------------------------------
always @(posedge clk2 or posedge rst) begin
	if(rst)
	   state <= CONDITIONAL;
	else
	   state <= nextstate;
end 

//-------------------------------------------------------------------------------------------------
// -- FSM (combinational logic)
//-------------------------------------------------------------------------------------------------
always @(*) begin

done_kem_keygen = 1'b0;
done_kem_encapsulation = 1'b0;
done_kem_decapsulation = 1'b0;
done_pke_keygen = 1'b0;
done_pke_encapsulation = 1'b0;
done_pke_decapsulation = 1'b0;
done_CONT = 1'b0;
command_in = 35'd0;
command_we0 = 1'd0;
command_we1 = 1'd0;


    case(state)
        CONDITIONAL: begin        // conditional state ensures which operation user want to execute
            if(start) begin
                if(OP == 3'd0 || 3'd4)
                    nextstate = CONDITIONAL; // NOP
                if(OP == 3'd1)
                    nextstate = PKE_KEYGEN; // Set, state to start PKE_KEYGEN
                if(OP == 3'd2)
                    nextstate = PKE_ENC; // Set, state to start PKE_ENC 
                if(OP == 3'd3)
                    nextstate = PKE_DEC; // Set, state to start PKE_DEC
                if(OP === 3'd5)
                    nextstate = KEM_KEYGEN; // Set, state to start KEM_KEYGEN
                if(OP === 3'd6)
                    nextstate = KEM_ENCAPS; // Set, state to start KEM_ENCAPS
                if(OP === 3'd7)
                    nextstate = KEM_DECAPS; // Set, state to start KEM_DECAPS    
            end // end if
            else
                nextstate = CONDITIONAL;  
        end        
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      KEM_KeyGen states starts from here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
        
        KEM_KEYGEN: begin command_in = {3'd0,16'd32,16'd32};  command_we0 = 0; command_we1 = 1; nextstate = 10'd2; end
        10'd2: begin command_in = {10'd0,10'd0,10'd0,5'd0};   command_we0 = 1; command_we1 = 0; nextstate = 10'd3; end
        10'd3: begin command_in = {10'd896,10'd0,10'd0,5'd3}; command_we0 = 1; command_we1 = 0; nextstate = 10'd4; end
        10'd4: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd5;
                    else
                        nextstate = 10'd4;   
               end
        10'd5: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd6; end
        
        // Call SHAKE to write 3744 bytes.
        10'd6: begin command_in = {3'd0,16'd3744,16'd32};   command_we0 = 0; command_we1 = 1; nextstate = 10'd7; end
        10'd7: begin command_in = {10'd100,10'd0,10'd896,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd8; end
        10'd8: begin command_in = {10'd100,10'd0,10'd896,5'd3}; command_we0 = 1; command_we1 = 0; nextstate = 10'd9; end
        10'd9: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd10;
                    else
                        nextstate = 10'd9;   
               end
        10'd10: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd11; end
        //// Matrix [A] generated.
        
        //////////////////////// Computation of Transpose A //////////////////////
        
        // Copy A[0][1] to #568, after A
        
        10'd11: begin command_in = {10'd568,10'd52,10'd152,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd12; end
        10'd12: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd13;
                    else
                        nextstate = 10'd12;   
                end
        10'd13: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd14; end
        10'd14: begin
                    if(!done_copy)
                        nextstate = 10'd15;
                    else
                        nextstate = 10'd14;   
                end

        // Copy A[1][0] to A[0][1]
        10'd15: begin command_in = {10'd152,10'd52,10'd256,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd16; end
        10'd16: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd17;
                    else
                        nextstate = 10'd16;   
               end
        
        10'd17: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd18; end
        10'd18: begin
                    if(!done_copy)
                        nextstate = 10'd19;
                    else
                        nextstate = 10'd18;   
                end

        // Copy #568 (old A[0][1]) to A[1][0]
        10'd19: begin command_in = {10'd256,10'd52,10'd568,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd20; end
        10'd20: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd21;
                    else
                        nextstate = 10'd20;   
               end
        
        10'd21: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd22; end
        10'd22: begin
                    if(!done_copy)
                        nextstate = 10'd23;
                    else
                        nextstate = 10'd22;   
                end
                
        // Copy A[0][2] to #568, after A
        10'd23: begin command_in = {10'd568,10'd52,10'd204,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd24; end
        10'd24: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd25;
                    else
                        nextstate = 10'd24;   
        end
        10'd25: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd26; end
        10'd26: begin
                    if(!done_copy)
                        nextstate = 10'd27;
                    else
                        nextstate = 10'd26;   
        end
        
        // Copy A[2][0] to A[0][2]
        10'd27: begin command_in = {10'd204,10'd52,10'd412,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd28; end
        10'd28: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd29;
                    else
                        nextstate = 10'd28;   
        end
        10'd29: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd30; end
        10'd30: begin
                    if(!done_copy)
                        nextstate = 10'd31;
                    else
                        nextstate = 10'd30;   
        end
               
        // Copy #568 (old A[0][2]) to A[2][0]
        10'd31: begin command_in = {10'd412,10'd52,10'd568,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd32; end
        10'd32: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd33;
                    else
                        nextstate = 10'd32;   
        end
        10'd33: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd34; end
        10'd34: begin
                    if(!done_copy)
                        nextstate = 10'd35;
                    else
                        nextstate = 10'd34;   
        end
        
        // Copy A[1][2] to #568, after A
        10'd35: begin command_in = {10'd568,10'd52,10'd360,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd36; end
        10'd36: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd37;
                    else
                        nextstate = 10'd36;   
        end
        10'd37: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd38; end
        10'd38: begin
                    if(!done_copy)
                        nextstate = 10'd39;
                    else
                        nextstate = 10'd38;   
        end
        
        // Copy A[2][1] to A[1][2]
        10'd39: begin command_in = {10'd360,10'd52,10'd464,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd40; end
        10'd40: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd41;
                    else
                        nextstate = 10'd40;   
        end
        10'd41: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd42; end
        10'd42: begin
                    if(!done_copy)
                        nextstate = 10'd43;
                    else
                        nextstate = 10'd42;   
        end
        
        // Copy #568 (old A[1][2]) to A[2][1]
        10'd43: begin command_in = {10'd464,10'd52,10'd568,5'd12}; command_we0 = 1; command_we1 = 0; nextstate = 10'd44; end
        10'd44: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_copy)
                        nextstate = 10'd45;
                    else
                        nextstate = 10'd44;   
        end
        10'd45: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd46; end
        10'd46: begin
                    if(!done_copy)
                        nextstate = 10'd47;
                    else
                        nextstate = 10'd46;   
        end
        
        /////////////// End of Transposing //////////////////////
        
        
        //#900 <-- SHAKE(#0-#3).
        10'd47: begin command_in = {3'd0,16'd768,16'd32};      command_we0 = 0; command_we1 = 1; nextstate = 10'd48; end
        10'd48: begin command_in = {10'd0,10'd0,10'd0,5'd0};   command_we0 = 1; command_we1 = 0; nextstate = 10'd49; end
        10'd49: begin command_in = {10'd900,10'd0,10'd4,5'd3}; command_we0 = 1; command_we1 = 0; nextstate = 10'd50; end
        10'd50: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd51;
                    else
                        nextstate = 10'd50;   
        end
        10'd51: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd52; end
        
        // #900-#947 <--SAMPLING(#900-#...)
        10'd52: begin command_in = {10'd900,10'd0,10'd900,5'd13}; command_we0 = 1; command_we1 = 0; nextstate = 10'd53; end
        10'd53: begin 
                    if(done_sampler)
                        nextstate = 10'd54;
                    else
                        nextstate = 10'd53;   
        end
        10'd54: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd55; end
        10'd55: begin 
                    if(!done_sampler)
                        nextstate = 10'd56;
                    else
                        nextstate = 10'd55;   
        end
        
        // CPA_ENC_INS4: #200-#391 <--[A][s]
		// Matrix multiplication [res] <-- [A]*[s]
		// [A] is from #200-#667.
		// [s] is from #668-#715

		// #100 <-- A[row0]*[s]	where row0 starts from address 100
        10'd56: begin command_in = {10'd100,10'd900,10'd100,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd57; end
        10'd57: begin 
                    if(done_vmul)
                        nextstate = 10'd58;
                    else
                        nextstate = 10'd57;   
        end
        10'd58: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd59; end
        10'd59: begin 
                    if(!done_vmul)
                        nextstate = 10'd60;
                    else
                        nextstate = 10'd59;   
        end
        
        // #100+64 <-- A[row1]*[s]	where row1 starts from address 100+52*3=256
        10'd60: begin command_in = {10'd164,10'd900,10'd256,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd61; end
        10'd61: begin 
                    if(done_vmul)
                        nextstate = 10'd62;
                    else
                        nextstate = 10'd61;   
        end
        10'd62: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd63; end
        10'd63: begin 
                    if(!done_vmul)
                        nextstate = 10'd64;
                    else
                        nextstate = 10'd63;   
        end
        
        // #100+64+64 <-- A[row2]*[s]	where row2 starts from address 100+52*6=412
        10'd64: begin command_in = {10'd228,10'd900,10'd412,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd65; end
        10'd65: begin 
                    if(done_vmul)
                        nextstate = 10'd66;
                    else
                        nextstate = 10'd65;   
        end
        10'd66: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd67; end
        10'd67: begin 
                    if(!done_vmul)
                        nextstate = 10'd68;
                    else
                        nextstate = 10'd67;   
        end 
        
        // #776-#895 <--POLVEC2BS(#100-#291);
        10'd68: begin command_in = {10'd776,10'd0,10'd100,5'd7}; command_we0 = 1; command_we1 = 0; nextstate = 10'd69; end
        10'd69: begin 
                    if(done_addround)
                        nextstate = 10'd70;
                    else
                        nextstate = 10'd69;   
        end
        10'd70: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd71; end
        10'd71: begin 
                    if(!done_addround)
                        nextstate = 10'd72;
                    else
                        nextstate = 10'd71;   
        end 
        
        // hash_pk #772 - #775 <- sha3_256(pk);
        10'd72: begin command_in = {3'd0,16'd32,16'd992}; command_we0 = 0; command_we1 = 1; nextstate = 10'd73; end
        10'd73: begin command_in = {10'd772,10'd0,10'd776,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd74; end
        10'd74: begin command_in = {10'd772,10'd0,10'd776,5'd1}; command_we0 = 1; command_we1 = 0; nextstate = 10'd75; end
        10'd75: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd76;
                    else
                        nextstate = 10'd75;   
        end
        10'd76: begin command_in = 35'd0; command_we0 = 1; command_we1 = 0; done_kem_keygen = 1; nextstate = 10'd77; end
        10'd77: begin  
                    if(CONT)
                        nextstate = CONDITIONAL;
                    else begin
                        nextstate = 10'd77; // Samuel fixed it
						done_kem_keygen = 1;
					end
        end

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      KEM_KeyGen states ends here
%%      KEM_Encapsulation states starts from here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/	
        KEM_ENCAPS: begin command_in = 35'd0; command_we0 = 1; command_we1 = 0; nextstate = 10'd101; end
        // INS1: #124-#127 <-- HASH(#124-#127)
        10'd101: begin command_in = {3'd0,16'd32,16'd32};         command_we0 = 0; command_we1 = 1; nextstate = 10'd102; end
        10'd102: begin command_in = {10'd0,10'd0,10'd0,5'd0}; 	  command_we0 = 1; command_we1 = 0; nextstate = 10'd103; end
        10'd103: begin command_in = {10'd124,10'd0,10'd140,5'd1}; command_we0 = 1; command_we1 = 0; nextstate = 10'd104; end
        10'd104: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd105;
                    else
                        nextstate = 10'd104;   
        end
        10'd105: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd106; end
        
        // INS2: #128-#131 <-- HASH(#0-#119)
		// sha3_256(buf+32, pk, SABER_INDCPA_PUBLICKEYBYTES);
		10'd106: begin command_in = {3'd0,16'd32,16'd992};        command_we0 = 0; command_we1 = 1; nextstate = 10'd107; end
        10'd107: begin command_in = {10'd128,10'd0,10'd0,5'd0};   command_we0 = 1; command_we1 = 0; nextstate = 10'd108; end
        10'd108: begin command_in = {10'd128,10'd0,10'd0,5'd1};   command_we0 = 1; command_we1 = 0; nextstate = 10'd109; end
        10'd109: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd110;
                    else
                        nextstate = 10'd109;   
        end
        10'd110: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd111; end
        
        // INS3: #132-#139 <-- SHA512(#124-#131)		
		// sha3_512(kr, buf, 64);
		10'd111: begin command_in = {3'd0,16'd64,16'd64};         command_we0 = 0; command_we1 = 1; nextstate = 10'd112; end
        10'd112: begin command_in = {10'd132,10'd0,10'd124,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd113; end
        10'd113: begin command_in = {10'd132,10'd0,10'd124,5'd2}; command_we0 = 1; command_we1 = 0; nextstate = 10'd114; end
        10'd114: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd115;
                    else
                        nextstate = 10'd114;   
        end
        10'd115: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd116; end
        
        // NOW we have: buf[] is from #124-#131
		// NOW we have: kr[] is from #132-#139
		// buf[0:31] contains 32-byte message; kr[32:63] contains 32-byte randomness r;

		// CPA_ENC_INS2: #200-#667 <--SHAKE(#120-#123): Total k*k*13*256/64 = 468 words.
		// Call SHAKE to write 3744 bytes.
		10'd116: begin command_in = {3'd0,16'd3744,16'd32};       command_we0 = 0; command_we1 = 1; nextstate = 10'd117; end
        10'd117: begin command_in = {10'd200,10'd0,10'd120,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd118; end
        10'd118: begin command_in = {10'd200,10'd0,10'd120,5'd3}; command_we0 = 1; command_we1 = 0; nextstate = 10'd119; end
        10'd119: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd120;
                    else
                        nextstate = 10'd119;   
        end
        10'd120: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd121; end
        //// Matrix [A] generated.
        
        // CPA_ENC_INS3: STEP1: #668-#763 <-- SHAKE(#136-#139).
        10'd121: begin command_in = {3'd0,16'd768,16'd32};        command_we0 = 0; command_we1 = 1; nextstate = 10'd122; end
        10'd122: begin command_in = {10'd0,10'd0,10'd0,5'd0};     command_we0 = 1; command_we1 = 0; nextstate = 10'd123; end
        10'd123: begin command_in = {10'd668,10'd0,10'd136,5'd3}; command_we0 = 1; command_we1 = 0; nextstate = 10'd124; end
        10'd124: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd125;
                    else
                        nextstate = 10'd124;   
        end
        10'd125: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd126; end
        
        // CPA_ENC_INS3: STEP2: #668-#715 <--SAMPLING(#668-#763))
        10'd126: begin command_in = {10'd668,10'd0,10'd668,5'd13}; command_we0 = 1; command_we1 = 0; nextstate = 10'd127; end
        10'd127: begin 
                    if(done_sampler)
                        nextstate = 10'd128;
                    else
                        nextstate = 10'd127;   
        end
        10'd128: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd129; end
        10'd129: begin 
                    if(!done_sampler)
                        nextstate = 10'd130;
                    else
                        nextstate = 10'd129;   
        end
        // CPA_ENC_INS4: #200-#391 <--[A][s]
		// Matrix multiplication [res] <-- [A]*[s]
		// [A] is from #200-#667.
		// [s] is from #668-#715

		// #200 <-- A[row0]*[s]	where row0 starts from address 200
		10'd130: begin command_in = {10'd200,10'd668,10'd200,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd131; end
        10'd131: begin 
                    if(done_vmul)
                        nextstate = 10'd132;
                    else
                        nextstate = 10'd131;   
        end
        10'd132: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd133; end
        10'd133: begin 
                    if(!done_vmul)
                        nextstate = 10'd134;
                    else
                        nextstate = 10'd133;   
        end       
        
        // #200+64 <-- A[row1]*[s]	where row1 starts from address 200+52*3=356
        10'd134: begin command_in = {10'd264,10'd668,10'd356,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd135; end
        10'd135: begin 
                    if(done_vmul)
                        nextstate = 10'd136;
                    else
                        nextstate = 10'd135;   
        end
        10'd136: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd137; end
        10'd137: begin 
                    if(!done_vmul)
                        nextstate = 10'd138;
                    else
                        nextstate = 10'd137;   
        end
        
        // #200+64+64 <-- A[row2]*[s]	where row2 starts from address 200+52*6=512
        10'd138: begin command_in = {10'd328,10'd668,10'd512,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd139; end
        10'd139: begin 
                    if(done_vmul)
                        nextstate = 10'd140;
                    else
                        nextstate = 10'd139;   
        end
        10'd140: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd141; end
        10'd141: begin 
                    if(!done_vmul)
                        nextstate = 10'd142;
                    else
                        nextstate = 10'd141;   
        end
        
        // CPA_ENC_INS5: #800-#919 <--POLVEC2BS(#200-#391);
		// Next few words will be used to store additional ciphertext info.
		/*
			for(i=0;i<SABER_K;i++){ //shift right 3 bits
				for(j=0;j<SABER_N;j++){
					res[i][j]=( res[i][j]+ h1 ) & mod_q;
					res[i][j]=(res[i][j]>> (SABER_EQ-SABER_EP) );
				}
			}
			POLVEC2BS(ciphertext, res, SABER_P);
		*/
        10'd142: begin command_in = {10'd800,10'd0,10'd200,5'd7}; command_we0 = 1; command_we1 = 0; nextstate = 10'd143; end
        10'd143: begin 
                    if(done_addround)
                        nextstate = 10'd144;
                    else
                        nextstate = 10'd143;   
        end
        10'd144: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd145; end
        10'd145: begin 
                    if(!done_addround)
                        nextstate = 10'd146;
                    else
                        nextstate = 10'd145;   
        end
        //**********client matrix-vector multiplication ends*******************//
		// Ciphertext is now in #800-#919


		// CPA_ENC_INS6: #200-#391 <-- BS2POLVEC(#0-#119);
		// BS2POLVEC(pk,pkcl,SABER_P);
		10'd146: begin command_in = {10'd200,10'd0,10'd0,5'd9}; command_we0 = 1; command_we1 = 0; nextstate = 10'd147; end
        10'd147: begin 
                    if(done_bs2polvecp)
                        nextstate = 10'd148;
                    else
                        nextstate = 10'd147;   
        end
        10'd148: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd149; end
        10'd149: begin 
                    if(!done_bs2polvecp)
                        nextstate = 10'd150;
                    else
                        nextstate = 10'd149;   
        end
		// CPA_ENC_INS7: #200-#263 <-- InnerProd(#200-#391, #668-#715);
		// vector-vector scalar multiplication with mod p
		// InnerProd(pkcl,skpv1,mod_p,vprime);
		// #200 <-- [pkcl]*[s]	where row0 starts from address 4
        10'd150: begin command_in = {10'd200,10'd668,10'd200,5'd10}; command_we0 = 1; command_we1 = 0; nextstate = 10'd151; end
        10'd151: begin 
                    if(done_vmul)
                        nextstate = 10'd152;
                    else
                        nextstate = 10'd151;   
        end
        10'd152: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd153; end
        10'd153: begin 
                    if(!done_vmul)
                        nextstate = 10'd154;
                    else
                        nextstate = 10'd153;   
        end
        
        // Large Instruction
		// CPA_ENC_INS8: #920-#935 <-- (#200-#263);	
		10'd154: begin command_in = {10'd920,10'd124,10'd200,5'd8}; command_we0 = 1; command_we1 = 0; nextstate = 10'd155; end
        10'd155: begin 
                    if(done_addpack)
                        nextstate = 10'd156;
                    else
                        nextstate = 10'd155;   
        end
        10'd156: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd157; end
        10'd157: begin 
                    if(!done_addpack)
                        nextstate = 10'd158;
                    else
                        nextstate = 10'd157;   
        end
        
        // INS9: #136-#139 <-- SHA256(#800-#935)
		// sha3_256(kr+32, c, SABER_BYTES_CCA_DEC); 
        10'd158: begin command_in = {3'd0,16'd32,16'd1088};       command_we0 = 0; command_we1 = 1; nextstate = 10'd159; end
        10'd159: begin command_in = {10'd136,10'd0,10'd800,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd160; end
        10'd160: begin command_in = {10'd136,10'd0,10'd800,5'd1}; command_we0 = 1; command_we1 = 0; nextstate = 10'd161; end
        10'd161: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd162;
                    else
                        nextstate = 10'd161;   
        end
        10'd162: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd163; end
        
        // INS10: #936-#939 <-- SHA256(#132-#139)
		// sha3_256(k, kr, 64);                          					// hash concatenation of pre-k and h(c) to k 
		10'd163: begin command_in = {3'd0,16'd32,16'd64};         command_we0 = 0; command_we1 = 1; nextstate = 10'd164; end
        10'd164: begin command_in = {10'd936,10'd0,10'd132,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd165; end
        10'd165: begin command_in = {10'd936,10'd0,10'd132,5'd1}; command_we0 = 1; command_we1 = 0; nextstate = 10'd166; end
        10'd166: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd167;
                    else
                        nextstate = 10'd166;   
        end
        10'd167: begin command_in = 35'd0; command_we0 = 1; command_we1 = 0; done_kem_encapsulation = 1; nextstate = 10'd168; end
        
        10'd168: begin  
                    if(CONT)
                        nextstate = CONDITIONAL;
                    else begin
                        nextstate = 10'd168; // Samuel fixed it
						done_kem_encapsulation = 1;
					end
        end      
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      KEM_KeyGen and KEM_ENCAPS states ends here
%%      KEM_DECAPS states starts from here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/	       
        	
        KEM_DECAPS: begin command_in = 35'd0; command_we0 = 1; command_we1 = 0; nextstate = 10'd200; end
        // Call BS2POLVECp: Unpack ciphertext to mod_p pol
        10'd200: begin command_in = {10'd512,10'd200,10'd200,5'd9}; command_we0 = 1; command_we1 = 0; nextstate = 10'd201; end
        10'd201: begin 
                    if(done_bs2polvecp)
                        nextstate = 10'd202;
                    else
                        nextstate = 10'd201;   
        end
        10'd202: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd203; end
        10'd203: begin 
                    if(!done_bs2polvecp)
                        nextstate = 10'd204;
                    else
                        nextstate = 10'd203;   
        end
        
        // NOTE: output coeff contains 13-bit info. Actually, doesn't need to set the top bits to 000.
		// #512 <-- InnerProd(pksv,sksv,mod_p,v);
		10'd204: begin command_in = {10'd512,10'd128,10'd512,5'd10}; command_we0 = 1; command_we1 = 0; nextstate = 10'd205; end
        10'd205: begin 
                    if(done_vmul)
                        nextstate = 10'd206;
                    else
                        nextstate = 10'd205;   
        end
        10'd206: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd207; end
        10'd207: begin 
                    if(!done_vmul)
                        nextstate = 10'd208;
                    else
                        nextstate = 10'd207;   
        end
        
        
		10'd208: begin command_in = {10'd336,10'd320,10'd512,5'd11}; command_we0 = 1; command_we1 = 0; nextstate = 10'd209; end
        10'd209: begin 
                    if(done_unpack)
                        nextstate = 10'd210;
                    else
                        nextstate = 10'd209;   
        end
        10'd210: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd211; end
        10'd211: begin 
                    if(!done_unpack)
                        nextstate = 10'd212;
                    else
                        nextstate = 10'd211;   
        end 
        
        ////////////////////////////////////////////////////////////////////////////
        ////////// END of CPA DECRYPTION    ////////////////////////////////////////
        ////////// Message is #336-#339     ////////////////////////////////////////
        
//            // Copy hash_pk from #120 to #340 
//            @(posedge clk)
//            command_in = {10'd340,10'd4,10'd120,5'd12};
//            command_we0 = 1; command_we1 = 0;
//            wait(done_copy);
//                @(posedge clk);
//            @(posedge clk)
//            command_in = {10'd0,10'd0,10'd0,5'd0};
//            command_we0 = 1; command_we1 = 0;
//            @(posedge clk);
//            wait(!done_copy);
//            @(posedge clk);
        
        // sha3_512(kr, buf, 64);
        10'd212: begin command_in = {3'd0,16'd64,16'd64}; command_we0 = 0; command_we1 = 1; nextstate = 10'd213; end
        10'd213: begin command_in = {10'd344,10'd0,10'd336,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd214; end
        10'd214: begin command_in = {10'd344,10'd0,10'd336,5'd2}; command_we0 = 1; command_we1 = 0; nextstate = 10'd215; end
        10'd215: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd216;
                    else
                        nextstate = 10'd215;   
               end
        10'd216: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd217; end
        
        ////////////////////////////////////////////////////////////////////////////////////
        ////        START:   indcpa_kem_enc(buf, kr+32, pk, cmp);           ////////////////
        ////        buf: #336-#339;     kr+32: #348-#351                    ////////////////
        ////////////////////////////////////////////////////////////////////////////////////
            
       	// CPA_ENC_INS2: #352-#819 <--SHAKE(#120-#123): Total k*k*13*256/64 = 468 words.
        // Call SHAKE to write 3744 bytes.
        10'd217: begin command_in = {3'd0,16'd3744,16'd32}; command_we0 = 0; command_we1 = 1; nextstate = 10'd218; end
        10'd218: begin command_in = {10'd352,10'd0,10'd120,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd219; end
        10'd219: begin command_in = {10'd352,10'd0,10'd120,5'd3}; command_we0 = 1; command_we1 = 0; nextstate = 10'd220; end
        10'd220: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd221;
                    else
                        nextstate = 10'd220;   
               end
        10'd221: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd222; end
        
        // CPA_ENC_INS3: STEP1: #820-#915 <-- SHAKE(#348-#351).
        10'd222: begin command_in = {3'd0,16'd768,16'd32}; command_we0 = 0; command_we1 = 1; nextstate = 10'd223; end
        10'd223: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd224; end
        10'd224: begin command_in = {10'd820,10'd0,10'd348,5'd3}; command_we0 = 1; command_we1 = 0; nextstate = 10'd225; end
        10'd225: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd226;
                    else
                        nextstate = 10'd225;   
               end
        10'd226: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd227; end
        
        // sk is residing at #820-#867     
        // CPA_ENC_INS3: STEP2: #820-#867 <--SAMPLING(#820-#915))
        10'd227: begin command_in = {10'd820,10'd0,10'd820,5'd13}; command_we0 = 1; command_we1 = 0; nextstate = 10'd228; end
        10'd228: begin 
                    if(done_sampler)
                        nextstate = 10'd229;
                    else
                        nextstate = 10'd228;   
        end
        10'd229: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd230; end
        10'd230: begin 
                    if(!done_sampler)
                        nextstate = 10'd231;
                    else
                        nextstate = 10'd230;   
        end
        
        // CPA_ENC_INS4: #200-#391 <--[A][s]
        // Matrix multiplication [res] <-- [A]*[s]
        // [A] is from #352-#819  (old #200-#667).
        // [s] is from #820-#867  (old #668-#715).
        
        // #352 <-- A[row0]*[s]    where row0 starts from address 352
        10'd231: begin command_in = {10'd352,10'd820,10'd352,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd232; end
        10'd232: begin 
                    if(done_vmul)
                        nextstate = 10'd233;
                    else
                        nextstate = 10'd232;   
        end
        10'd233: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd234; end
        10'd234: begin 
                    if(!done_vmul)
                        nextstate = 10'd235;
                    else
                        nextstate = 10'd234;   
        end
        
        // #352+64 <-- A[row1]*[s]    where row1 starts from address 352+52*3=508
        10'd235: begin command_in = {10'd416,10'd820,10'd508,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd236; end
        10'd236: begin 
                    if(done_vmul)
                        nextstate = 10'd237;
                    else
                        nextstate = 10'd236;   
        end
        10'd237: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd238; end
        10'd238: begin 
                    if(!done_vmul)
                        nextstate = 10'd239;
                    else
                        nextstate = 10'd238;   
        end
        
        // #352+64+64 <-- A[row2]*[s]    where row2 starts from address 352+52*6=664
        10'd239: begin command_in = {10'd480,10'd820,10'd664,5'd6}; command_we0 = 1; command_we1 = 0; nextstate = 10'd240; end
        10'd240: begin 
                    if(done_vmul)
                        nextstate = 10'd241;
                    else
                        nextstate = 10'd240;   
        end
        10'd241: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd242; end
        10'd242: begin 
                    if(!done_vmul)
                        nextstate = 10'd243;
                    else
                        nextstate = 10'd242;   
        end
        
        // CPA_ENC_INS5: #868-#987 <--POLVEC2BS(#352-#543);
        // Next few words will be used to store additional ciphertext info.
//      for(i=0;i<SABER_K;i++){ //shift right 3 bits
//          for(j=0;j<SABER_N;j++){
//              res[i][j]=( res[i][j]+ h1 ) & mod_q;
//              res[i][j]=(res[i][j]>> (SABER_EQ-SABER_EP) );
//          }
//      }

//      POLVEC2BS(ciphertext, res, SABER_P);
        10'd243: begin command_in = {10'd868,10'd0,10'd352,5'd7}; command_we0 = 1; command_we1 = 0; nextstate = 10'd244; end
        10'd244: begin 
                    if(done_addround)
                        nextstate = 10'd245;
                    else
                        nextstate = 10'd244;   
        end
        10'd245: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd246; end
        10'd246: begin 
                    if(!done_addround)
                        nextstate = 10'd247;
                    else
                        nextstate = 10'd246;   
        end
        
        //client matrix-vector multiplication ends//
        // Ciphertext is now in #868-#987


        // CPA_ENC_INS6: #352-#543 <-- BS2POLVEC(#0-#119);
        // BS2POLVEC(pk,pkcl,SABER_P);
        10'd247: begin command_in = {10'd352,10'd0,10'd0,5'd9}; command_we0 = 1; command_we1 = 0; nextstate = 10'd248; end
        10'd248: begin 
                    if(done_bs2polvecp)
                        nextstate = 10'd249;
                    else
                        nextstate = 10'd248;   
        end
        10'd249: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd250; end
        10'd250: begin 
                    if(!done_bs2polvecp)
                        nextstate = 10'd251;
                    else
                        nextstate = 10'd250;   
        end
        
        // CPA_ENC_INS7: #352-#415 <-- InnerProd(#352-#543, #820-#867);
        // vector-vector scalar multiplication with mod p
        // InnerProd(pkcl,skpv1,mod_p,vprime);
        // #352 <-- [pkcl]*[s]	where row0 starts from address 4
        
        
        10'd251: begin command_in = {10'd352,10'd820,10'd352,5'd10}; command_we0 = 1; command_we1 = 0; nextstate = 10'd252; end
        10'd252: begin 
                    if(done_vmul)
                        nextstate = 10'd253;
                    else
                        nextstate = 10'd252;   
        end
        10'd253: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd254; end
        10'd254: begin 
                    if(!done_vmul)
                        nextstate = 10'd255;
                    else
                        nextstate = 10'd254;   
        end
        
        
        10'd255: begin command_in = {10'd988,10'd336,10'd352,5'd8}; command_we0 = 1; command_we1 = 0; nextstate = 10'd256; end
        10'd256: begin 
                    if(done_addpack)
                        nextstate = 10'd257;
                    else
                        nextstate = 10'd256;   
        end
        10'd257: begin command_in = {10'd0,10'd0,10'd0,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd258; end
        10'd258: begin 
                    if(!done_addpack)
                        nextstate = 10'd259;
                    else
                        nextstate = 10'd258;   
        end
        
        // INS9: #348-#351 <-- SHA256(#200-#335)
		// sha3_256(kr+32, c, SABER_BYTES_CCA_DEC); 
		10'd259: begin command_in = {3'd0,16'd32,16'd1088}; command_we0 = 0; command_we1 = 1; nextstate = 10'd260; end
        10'd260: begin command_in = {10'd348,10'd0,10'd200,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd261; end
        10'd261: begin command_in = {10'd348,10'd0,10'd200,5'd1}; command_we0 = 1; command_we1 = 0; nextstate = 10'd262; end
        10'd262: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd263;
                    else
                        nextstate = 10'd262;   
               end
        10'd263: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd264; end
        
        // INS10: #1004-#1007 <-- SHA256(#344-#351)
		// sha3_256(k, kr, 64);                          					// hash concatenation of pre-k and h(c) to k 
		10'd264: begin command_in = {3'd0,16'd32,16'd64}; command_we0 = 0; command_we1 = 1; nextstate = 10'd265; end
        10'd265: begin command_in = {10'd1004,10'd0,10'd344,5'd0}; command_we0 = 1; command_we1 = 0; nextstate = 10'd266; end
        10'd266: begin command_in = {10'd1004,10'd0,10'd344,5'd1}; command_we0 = 1; command_we1 = 0; nextstate = 10'd267; end
        10'd267: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_shake)
                        nextstate = 10'd268;
                    else
                        nextstate = 10'd267;   
               end
        10'd268: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd269; end
        
        // verify;
		//verify_true = verify(c, cmp, SABER_BYTES_CCA_DEC); 
		// c is 136 words long and is from #200
		// cmp is 136 words long and is from #868
        10'd269: begin command_in = {3'd0,16'd0,16'd136}; command_we0 = 0; command_we1 = 1; nextstate = 10'd270; end
        10'd270: begin command_in = {10'd0,10'd868,10'd200,5'd14}; command_we0 = 1; command_we1 = 0; nextstate = 10'd271; end
        10'd271: begin 
                    command_we0 = 0; command_we1 = 0;
                    if(done_verify)
                        nextstate = 10'd272;
                    else
                        nextstate = 10'd271;   
        end
        10'd272: begin command_in = 35'd0;                    command_we0 = 1; command_we1 = 0; nextstate = 10'd273; end
        
        // cmov(kr, sk+SABER_SECRETKEYBYTES-SABER_KEYBYTES, SABER_KEYBYTES, fail); 
        10'd273: begin command_in = {10'd1008,10'd1004,10'd124,5'd15}; command_we0 = 1; command_we1 = 0; nextstate = 10'd274; end
        10'd274: begin 
                    command_we0 = 0; command_we1 = 0; 
                    if(done_cmov)
                        nextstate = 10'd275;
                    else
                        nextstate = 10'd274;   
               end
        10'd275: begin command_in = 35'd0; command_we0 = 0; command_we1 = 0; done_kem_decapsulation = 1; nextstate = 10'd276; end
        10'd276: begin  
                    if(CONT)
                        nextstate = CONDITIONAL;
                    else begin
						nextstate = 10'd276; // Samuel fixed this bug
						done_kem_decapsulation = 1;
					end						
        end    
        
        //IDLE: begin nextstate = CONDITIONAL; end // I have considered this as a default state 

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      KeyGen, Encapsulation and Decapsulation states ends here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/        
        
        default: begin nextstate = CONDITIONAL; end
	endcase
end 
endmodule