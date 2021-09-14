/***************************************************************************************************
    1. Design Name:             shift_registers
    2. Preparation Date:        June 02, 2021
    3. Initial designed by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/


/*-----------------------------------------------------------------------------------------

-- OLD LOGIC

------------------------------------------------------------------------------------------*/
// `timescale 1ns / 1ps

// module shift_registers(
                        // clk1, rst, 
                        // addr, din, 
                        // LAD1, LAD2,
                        // data_from_RF_to_chip_output,
                        // addr_reg, din_reg, dout_for_chip
                       // );

// input clk1;
// input rst;
// input addr;
// input din;
// input LAD1;
// input LAD2;
// input [63:0] data_from_RF_to_chip_output;

// output reg [9:0] addr_reg;
// output reg [63:0] din_reg;
// output reg dout_for_chip;
    
//-------------------------------------------------------------------------------------------------
//-- Control logic when loading signals from/to outside on/from the chip design (externally)
//--   addr_reg holds the 10 bit address for ComputeCore3
//--   din_reg holds the 64 bit data loaded from outside to store on register files (memories) that used inside the ComputeCore3
//--   dout_for_chip is responsible to provide a 1-bit data on the chip output
//-------------------------------------------------------------------------------------------------

//reg [5:0] count;
// reg [63:0] dout_reg_shift;

// /*
// LAD2     LAD1
// 00 means NOP
// 01 means Load address on the chip
// 10 means Load data_in from outside on the chip
// 11 means we signal to update memory contents (data_in) on the corresponding address
// */

// always @(posedge clk1 or posedge rst) begin
    // if(rst) begin
	   // dout_reg_shift   <= 64'd0;
	   // addr_reg         <= 10'd0;
	   // din_reg          <= 64'd0;
	   // dout_for_chip    <= 1'b0;
	// end
	
	// else begin 
		// if(LAD1 == 1'b0 & LAD2 == 1'b1) 
			// din_reg    <= {din, din_reg[63:1]};
		// else if(LAD1 == 1'b1 & LAD2 == 1'b0)
			// addr_reg <= {addr, addr_reg[9:1]};
		// else if(LAD1 == 1'b1 & LAD2 == 1'b1) begin
			// dout_for_chip  <= dout_reg_shift[0];
			// dout_reg_shift <= {1'b0, data_from_RF_to_chip_output[63:1]};
		// end	
		// dout_reg_shift <= data_from_RF_to_chip_output;
    // end	
// end    
// endmodule


/*-----------------------------------------------------------------------------------------

-- NEW LOGIC

------------------------------------------------------------------------------------------*/


`timescale 1ns / 1ps

module shift_registers(
                        clk1, rst, 
                        addr, din, 
                        LAD1, LAD2,
                        data_from_RF_to_chip_output,
                        addr_reg, din_reg, dout_for_chip
                       );

input clk1;
input rst;
input addr;
input din;
input LAD1;
input LAD2;
input [63:0] data_from_RF_to_chip_output;

output reg [9:0] addr_reg;
output reg [63:0] din_reg;
output reg dout_for_chip;
    
//-------------------------------------------------------------------------------------------------
// -- Control logic when loading signals from/to outside on/from the chip design (externally)
// --   addr_reg holds the 10 bit address for ComputeCore3
// --   din_reg holds the 64 bit data loaded from outside to store on register files (memories) that used inside the ComputeCore3
// --   dout_for_chip is responsible to provide a 1-bit data on the chip output
//-------------------------------------------------------------------------------------------------

reg [6:0] count;
reg [6:0] index_n;

/*
LAD2     LAD1
00 means NOP
01 means Load address on the chip
10 means Load data_in from outside on the chip
11 means we signal to update memory contents (data_in) on the corresponding address
*/

always @(posedge clk1 or posedge rst) begin
    if(rst) begin
	   addr_reg         <= 10'd0;
	   din_reg          <= 64'd0;
	   dout_for_chip    <= 1'b0;
	   count            <= 7'd0;
	   index_n          <= 7'b0;
	end
	
	else begin 
		if(LAD1 == 1'b0 & LAD2 == 1'b0)
			count <= 7'd0;  
		else if(LAD1 == 1'b0 & LAD2 == 1'b1) 
			din_reg    <= {din, din_reg[63:1]};
		else if(LAD1 == 1'b1 & LAD2 == 1'b0)
			addr_reg <= {addr, addr_reg[9:1]};
			
	   else if(LAD1 == 1'b1 & LAD2 == 1'b1) begin
			if(count == 7'b0 || count == 7'b1)begin
			 index_n <= 7'b0;
			end
			else begin
			 index_n <= count-2;
			end
			  
			if(count <= 7'd66) begin
			     dout_for_chip  <= data_from_RF_to_chip_output[index_n];
			     count <= count + 1;
			end 
			else begin
			     count <= 7'd0;  
			     dout_for_chip    <= 1'b0;
			     index_n <= 7'd0;
			end
		
		/*else if(LAD1 == 1'b1 & LAD2 == 1'b1) begin
		    dout_for_chip <= data_from_RF_to_chip_output[count];
			count <= count + 1;	 */  
//			if(count == -2)
//			     dout_for_chip    <= 1'b0;
//			else if(count == -1)
//			     dout_for_chip    <= 1'b0;
//			else if(count == 7'd67) begin
//			     count <= 7'd0;
//			     dout_for_chip    <= 1'b0;
//			end
		end	
    end	
end 
endmodule