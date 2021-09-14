/***************************************************************************************************
    1. Design Name:             shared_buffer
    2. Preparation Date:        June 02, 2021
    3. Initial designed by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module shared_buffer(clk, AR_buffer40_en, AR_buffer40_data, AR_buffer64_en, BS_buffer40_en, BS_buffer64_en, BS_buffer64_data, AM_buffer16_en, AM_buffer16_data, PO_pol_load_coeff4x, PO_poly_load, PO_poly_load_data, PO_poly_shift, buffer);
input clk;
input AR_buffer40_en; // from add_round
input [39:0] AR_buffer40_data; // from add_round
input AR_buffer64_en; // from add_round
input BS_buffer40_en; // from BS2POLVECp
input BS_buffer64_en; // from BS2POLVECp
input [63:0] BS_buffer64_data; // from BS2POLVECp
input AM_buffer16_en; // from Add_m_pack
input [15:0] AM_buffer16_data; // from Add_m_pack
input PO_pol_load_coeff4x; // from pol_mul
input PO_poly_load; // from pol_mul
input [63:0] PO_poly_load_data; // from pol_mul
input PO_poly_shift; // from pol_mul

output reg [675:0] buffer;

always @(posedge clk)
begin
	if(AR_buffer40_en)
		buffer <= {AR_buffer40_data, buffer[319:40]};
	else if(AR_buffer64_en)
		buffer <= {64'd0, buffer[319:64]};
	else if (BS_buffer40_en)
		buffer <= {40'd0, buffer[319:40]};
	else if (BS_buffer64_en)
		buffer <= {BS_buffer64_data, buffer[319:64]};
	else if (AM_buffer16_en) 
		buffer <= {AM_buffer16_data, buffer[63:16]};
	else if (PO_pol_load_coeff4x == 0)	begin
		if (PO_poly_load) 
			buffer <= {PO_poly_load_data, buffer[675:64]};
		else if (PO_poly_shift)
			buffer <= {13'b0, buffer[675:13]};
	end
	else begin 
		if (PO_poly_load)
			buffer[111:0] <= {PO_poly_load_data, buffer[111:64]}; // 112 = 128 - 16
		else if (PO_poly_shift) 
			buffer[111:0] <= {16'b0, buffer[111:16]};
	end
end

endmodule
