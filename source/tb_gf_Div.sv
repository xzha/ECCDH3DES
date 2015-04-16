// $Id: $
// File name:   tb_gf_Div.sv
// Created:     3/22/2015
// Author:      Manish Gupta
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Test Bench for Galois Field Division


`timescale 1ns / 100ps
module tb_gf_Div
(
);

	localparam NUM_BITS = 163;//8;	
	localparam NUM_INPUT_BITS = 3;
	localparam CLK_PERIOD = 5;
	localparam ROLLOVER_VAL = 10;
	localparam NUM_TEST_CASES = 10;
	localparam CHECK_DELAY = 1; // Check 1ns after the rising edge to allow for propagation delay

  //novopt issue
	// Declare test bench signals
	reg tb_tx_out;
	reg tb_clk;
	reg tb_n_rst;
	reg tb_ready;
	reg tb_done;
	reg [1:0] tb_sda_mode;
	reg tb_sda_out;
	reg [3:0]tb_test_num;
	reg [3:0]i;
	reg [NUM_BITS:0]tb_A;
	reg [NUM_BITS:0]tb_B;
	reg [NUM_BITS:0]tb_Q;
	reg [NUM_BITS:0]tb_product;


	always
	begin
		tb_clk = 1'b0;
		#(CLK_PERIOD/2.0);
		tb_clk = 1'b1;
		#(CLK_PERIOD/2.0);
	end

	//integer tb_test_num;

/*#(
		.NUM_BITS(8),
		.NUM_SHIFTS(2)
	)	*/ 
	// DUT Port maps
	gf_Div DUT(.clk(tb_clk), .n_rst(tb_n_rst), .A(tb_A), .B(tb_B), .start(tb_ready),  .Q(tb_Q), .done(tb_done));


	// Test bench process
	initial
	begin
		//tb_A = 9'b010000111;
		//tb_B = 9'b000000011;
		tb_A = {1'b0, 1'b1, 1'b1, 153'b0, 1'b1, 1'b1, 2'b0, 1'b1, 2'b0, 1'b1};
		tb_B = 165'd60;
	
		tb_ready = 0;


		// Power-on Reset of the DUT
		#(0.1);
		tb_n_rst	= 1'b0; 	// Need to actually toggle this in order for it to actually run dependent always blocks
		#(CLK_PERIOD * 2.25);	// Release the reset away from a clock edge
		tb_n_rst	= 1'b1; 	// Deactivate the chip reset

		// Wait for a while to see normal operation
		#(CLK_PERIOD);

		//Test Case
		@(negedge tb_clk);
		@(negedge tb_clk);
		tb_ready = 1;
		@(negedge tb_clk);
		tb_ready = 0;
		//tb_A = {1'b0, 1'b1, 1'b1, 153'b0, 1'b1, 1'b1, 2'b0, 1'b1, 2'b0, 1'b1};
		//tb_B = 165'b11;
	end


endmodule
