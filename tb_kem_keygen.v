`timescale 1ns / 1ps

/************************************************************************************************
    1. Design Name:             tb_kem_keygen
    2. Preparation Date:        June 02, 2021
    3. Initial designed by:     Malik Imran and Samuel Pagliarini (Tallinn University of Technology, Estonia)              
    
    Note! The codes are for academic research use only and does not come with any support or any responsibility. 
****************************************************************************************************/

module tb_kem_keygen;

	// Inputs to the core
	reg clk1;
	reg clk2;
	reg rst;
	reg addr;
	reg din;
	reg addr_ready;
	reg LAD1;
	reg LAD2;
	reg we;
    reg CONT;
    reg start;	
    reg crypto_op_1;
    reg crypto_op_2;
    reg crypto_op_3;
    	
	// Outputs from the core
	wire dout;
	wire done;
    
	// Registers declaration to hold the test values and signals (i.e., i and count) to drive loops (i.e., for) to read values
	reg [63:0] random_seed[3:0];
	reg [63:0] random_noiseseed[3:0];
	reg [63:0] pseudo_random[3:0];
	reg [10:0] i;
	reg [9:0] j, count;
	reg [63:0] set_memory;
	

	// Instantiate the Unit Under Test (UUT)	
	wrapper_top uut (
		.clk1(clk1),
		.clk2(clk2), 
		.rst(rst),
		.addr(addr), 
		.din(din), 
		.addr_ready(addr_ready),
		.LAD1(LAD1),
	    .LAD2(LAD2),
	    .we(we),
	    .CONT(CONT),
	    .start(start),
	    .crypto_op_1(crypto_op_1),
	    .crypto_op_2(crypto_op_2), 
	    .crypto_op_3(crypto_op_3),
		.dout(dout),
		.done(done)     		
	);

	initial begin
		// Initialize Inputs
		clk1 = 0;
		clk2 = 0;
		rst = 1;
		addr = 0;
		din = 0;
		addr_ready = 0;
		LAD1 = 0;
		LAD2 = 0;
		we = 0;
		CONT = 0;
		start = 0;
		crypto_op_1 = 0;
	    crypto_op_2 = 0;
	    crypto_op_3 = 0;
	    
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      Test vectors for the KeyGen 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/	
		random_seed[0] = 64'b0101111010001100000101010100110100100011010100000001010100000110; //h5e8c154d23501506;
        random_seed[1] = 64'b0010010101111010111011110000010011111110100101010101010111001001; //h257aef04fe9555c9;
        random_seed[2] = 64'b0111100111000100001010111100110000100100001011100111111101110110; //h79c42bcc242e7f76;
        random_seed[3] = 64'b1110011111111101101111001001101011011100100001101001110111010000; //he7fdbc9adc869dd0;
        
        random_noiseseed[0] = 64'b1111111101101101101000111000110110111100101111001001111100011010; //hff6da38dbcbc9f1a;
        random_noiseseed[1] = 64'b1101101100001111000101111001011000110010001000001011111000101010; //hdb0f17963220be2a;
        random_noiseseed[2] = 64'b0111100110110110111111000110011101111111001010011100001110010111; //h79b6fc677f29c397;
        random_noiseseed[3] = 64'b1011000001010011000000101101000010011111100111000111000110101100; //hb05302d09f9c71ac;
        
        pseudo_random[0] = 64'b1100010000010000010111110100001111110101000001001111000010110010; //hc4105f43f504f0b2;
		pseudo_random[1] = 64'b1001101111111101011110100100010001001000000100010100010111001101; //h9bfd7a44481145cd;
		pseudo_random[2] = 64'b0011101011010000111000000000110101110111000010011011001010011001; //h3ad0e00d7709b299;
		pseudo_random[3] = 64'b1000110001101000011100011110010101101011101111001011011111001101; //h8c6871e56bbcb7cd;
        
        set_memory       = 64'b0000000000000000000000000000000000000000000000000000000000000000;
        
		// Wait 100 ns for global reset to finish
		#10000000;
        rst = 0;
        
        @(negedge clk1)
        count = 10'd0;
        
        @(negedge clk1)
        crypto_op_1 = 1; crypto_op_2 = 0; crypto_op_3 = 1; // 101 means Execute KEM_KEYGEN
        
 /* ------------------------------------------------------------------------------------------------
-- initialize with all memory contents to 0
--------------------------------------------------------------------------------------------------*/      
        
        // Load a 64-bit of 0's to initialize memory contents on all addresses
		for(i=0; i<1024; i=i+1)
		begin
            for(j=0; j<64; j=j+1)
            begin
                LAD1 = 0; LAD2 = 1;
                @(negedge clk1) 
                din = set_memory[j];
            end
            
            @(negedge clk1)
                LAD1 = 0; LAD2 = 0; count = i;
            
            // Load a 10-bit corresponding address
            for(j=0; j<10; j=j+1)
            begin
                LAD1 = 1; LAD2 = 0;
                @(negedge clk1) 
                addr = count[j];
            end
            
            // Now set write_enable signal to store the loaded data onto a RegFile address inside the ComputeCore3 block
            @(negedge clk1)
            LAD1 = 0; LAD2 = 0;
            
            @(negedge clk1)
            @(negedge clk1)
                we = 1;
                addr_ready = 1;
                
            @(negedge clk1)
            we = 0; addr_ready = 0;
            
            $display("i=%d\n", i);
        end    
        
        $display("starting random seed now");
        
        @(negedge clk1)
        count = 10'd0;
       
/* ------------------------------------------------------------------------------------------------
-- LOAD RANDOM_SEED[i]
--------------------------------------------------------------------------------------------------*/		

// Load a 64-bit random_seed[i]
		for(i=0; i<4; i=i+1)
		begin
            for(j=0; j<64; j=j+1)
            begin
                LAD1 = 0; LAD2 = 1;
                @(negedge clk1) 
                din = random_seed[i][j];
            end
            
            @(negedge clk1)
                LAD1 = 0; LAD2 = 0;
            
            // Load a 10-bit corresponding address
            for(j=0; j<10; j=j+1)
            begin
                LAD1 = 1; LAD2 = 0;
                @(negedge clk1) 
                addr = count[j];
            end
            
            // Now set write_enable signal to store the loaded data onto a RegFile address inside the ComputeCore3 block
            @(negedge clk1)
            LAD1 = 0; LAD2 = 0;
            
            @(negedge clk1)
            @(negedge clk1)
                we = 1;
                addr_ready = 1;
                
            @(negedge clk1)
            count = count + 10'd1; we = 0; addr_ready = 0;
        end    

// ************************************************************************************************		
/* ------------------------------------------------------------------------------------------------
-- LOAD random_noiseseed[i] at memory location [4-7]
--------------------------------------------------------------------------------------------------*/		
        
// Load a 64-bit random_noiseseed[i]
		for(i=0; i<4; i=i+1)
		begin
            for(j=0; j<64; j=j+1)
            begin
                LAD1 = 0; LAD2 = 1;
                @(negedge clk1) 
                din = random_noiseseed[i][j];
            end
            
            @(negedge clk1)
                LAD1 = 0; LAD2 = 0;
            
            // Load a 10-bit corresponding address
            for(j=0; j<10; j=j+1)
            begin
                LAD1 = 1; LAD2 = 0;
                @(negedge clk1) 
                addr = count[j];
            end
            
            // Now set write_enable signal to store the loaded data onto a RegFile address inside the ComputeCore3 block
            @(negedge clk1)
            LAD1 = 0; LAD2 = 0;
            
            @(negedge clk1)
            @(negedge clk1)
                we = 1;
                addr_ready = 1;
                
            @(negedge clk1)
            count = count+1; we = 0; addr_ready = 0;
        end 
		
// ************************************************************************************************		
/* ------------------------------------------------------------------------------------------------
-- LOAD pseudo_random[i] at memory location [768-771] (part of sk_CCA)
--------------------------------------------------------------------------------------------------*/		
        @(negedge clk1)
        count = 10'd768;
        
// Load a 64-bit pseudo_random[i]
		for(i=0; i<4; i=i+1)
		begin
            for(j=0; j<64; j=j+1)
            begin
                LAD1 = 0; LAD2 = 1;
                @(negedge clk1) 
                din = pseudo_random[i][j];
            end
            
            @(negedge clk1)
                LAD1 = 0; LAD2 = 0;
            
            // Load a 10-bit corresponding address
            for(j=0; j<10; j=j+1)
            begin
                LAD1 = 1; LAD2 = 0;
                @(negedge clk1) 
                addr = count[j];
            end
            
            // Now set write_enable signal to store the loaded data onto a RegFile address inside the ComputeCore3 block
            @(negedge clk1)
            LAD1 = 0; LAD2 = 0;
            
            @(negedge clk1)
            @(negedge clk1)
                we = 1;
                addr_ready = 1;
                
            @(negedge clk1)
            count = count +1; we = 0; addr_ready = 0;
        end

/* ------------------------------------------------------------------------------------------------
-- LOAD values ends here
--------------------------------------------------------------------------------------------------*/	
		
		
		/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% Test case to run corresponding operation (i.e. KeyGen, Encaps & Decaps) at once 
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
		@(negedge clk1)
		start = 1;	
		@(negedge clk1)
		wait(done);		
		@(negedge clk1)
		start = 0;
		//$finish();
		/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% Test case to run continuous operation (KeyGen, Encaps, Decaps)
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
		
//		@(negedge clk1)
//		start = 1;
//		CONT = 1;
//		#100000;
//		@(negedge clk1)
//		start = 0;
//		CONT = 0;
//		$finish();

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Receiving data onto the chip port as an output (Reading public key values after generating)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
        
        for(count=10'd776; count<900; count=count+1)
		begin
                        
            // Load a 10-bit corresponding address
            for(j=0; j<10; j=j+1)
            begin
                LAD1 = 1; LAD2 = 0;
                @(negedge clk1) 
                addr = count[j];
            end
            
            @(negedge clk1)
                addr_ready = 1;
                    
            for(i=0; i<=66; i=i+1)
            begin
                LAD1 = 1; LAD2 = 1;
                @(negedge clk1);
            end
			
			@(negedge clk1)
                LAD1 = 0; LAD2 = 0;    
        end
        
        $finish();    
		
		// Secret key is in #768-#947 
		// Public key is in #776-#899 (they overlap because pk is contained in sk) 
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%      Test vectors end here for the KeyGen 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/	       
	end
always #2000  clk1 = ~clk1;
always #1000 clk2 = ~clk2;
      
endmodule
