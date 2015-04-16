// $Id: $
// File name:   tb_point_multiplication.sv
// Created:     3/25/2015
// Author:      Manish Gupta
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Test bench for Point Multiplication



`timescale 1ns / 100ps
module tb_point_multiplication
(
);

	localparam NUM_BITS = 163;	
	localparam NUM_INPUT_BITS = 3;
	localparam CLK_PERIOD = 4;
	localparam ROLLOVER_VAL = 10;
	localparam NUM_TEST_CASES = 10;
	localparam CHECK_DELAY = 1; // Check 1ns after the rising edge to allow for propagation delay

  //novopt issue
	// Declare test bench signals
	reg tb_tx_out;
	reg tb_clk;
	reg tb_n_rst;
	reg tb_start;
	reg tb_done;
	reg [1:0] tb_sda_mode;
	reg tb_sda_out;
	reg [3:0]tb_test_num;
	//reg [3:0]i;
	reg [NUM_BITS:0]tb_x1;
	reg [NUM_BITS:0]tb_y1;
	reg [NUM_BITS:0]tb_x2;
	reg [NUM_BITS:0]tb_y2;

	reg [NUM_BITS:0]tb_pubAX;
	reg [NUM_BITS:0]tb_pubAY;

	reg [NUM_BITS:0]tb_pubBX;
	reg [NUM_BITS:0]tb_pubBY;

	reg [NUM_BITS:0]tb_sesPubAPrivBX;
	reg [NUM_BITS:0]tb_sesPubAPrivBY;


	reg [NUM_BITS:0]tb_sesPubBPrivAX;
	reg [NUM_BITS:0]tb_sesPubBPrivAY;

	reg [NUM_BITS:0]tb_k;
	integer i;


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


	/*x1,
	input wire [NUM_BITS:0] y1,
	input wire [NUM_BITS:0] x2,
	input wire [NUM_BITS:0] y2,
	output wire [NUM_BITS:0] x3,
	output wire [NUM_BITS:0] y3,

	input wire start,
	output wire done */
	// DUT Port maps
	point_multiplication DUT(.clk(tb_clk), .n_rst(tb_n_rst), .x(tb_x1), .y(tb_y1), .SkX(tb_x2), .SkY(tb_y2),.k(tb_k), .start(tb_start), .done(tb_done));


	// Test bench process
	initial
	begin
		//tb_x1 = 9'b000000011;
		//tb_y1 = 9'b000000011;
		tb_k = 5;
		//tb_x1 = {1'b0, 1'b1, 1'b1, 153'b0, 1'b1, 1'b1, 2'b0, 1'b1, 2'b0, 1'b1};
		//tb_y1 = 165'b11;
	
		tb_x1 = 164'h3f0eba16286a2d57ea0991168d4994637e8343e36;
		tb_y1 = 165'h0d51fbc6c71a0094fa2cdd545b11c5c0c797324f1;

		tb_start = 0;


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
		tb_start = 1;
		@(negedge tb_clk);
		tb_start = 0;

		@(posedge tb_done);
		$info("First mult done");
		@(negedge tb_clk);	
		@(negedge tb_clk);	
		/*for(i=0; i < 25000; i++)
		begin
			@(negedge tb_clk);	
		end*/
		tb_pubAX = tb_x2;
		tb_pubAY = tb_y2;

		tb_k = 15;
		@(negedge tb_clk);
		tb_start = 1;
		@(negedge tb_clk);
		tb_start = 0;

		@(posedge tb_done);
		$info("Second mult done");
		@(negedge tb_clk);	
		@(negedge tb_clk);	
		/*for(i=0; i < 25000; i++)
		begin
			@(negedge tb_clk);
		end*/
		tb_pubBX = tb_x2;
		tb_pubBY = tb_y2;


		tb_x1 = tb_pubAX;
		tb_y1 = tb_pubAY;
		@(negedge tb_clk);
		tb_start = 1;
		@(negedge tb_clk);
		tb_start = 0;

		/*for(i=0; i < 25000; i++)
		begin
			@(negedge tb_clk);
		end*/
		@(posedge tb_done);
		$info("Third mult done");
		@(negedge tb_clk);	
		@(negedge tb_clk);	

		tb_sesPubAPrivBX = tb_x2;
		tb_sesPubAPrivBY = tb_y2;
		tb_x1 = tb_pubBX;
		tb_y1 = tb_pubBY;
		tb_k = 5;
		
		@(negedge tb_clk);
		tb_start = 1;
		@(negedge tb_clk);
		tb_start = 0;

/*		for(i=0; i < 25000; i++)
		begin
			@(negedge tb_clk);
		end
*/

		@(posedge tb_done);
		$info("Fourth mult done");
		@(negedge tb_clk);	
		@(negedge tb_clk);	
		tb_sesPubBPrivAX = tb_x2;
		tb_sesPubBPrivAY = tb_y2;

		if((tb_sesPubBPrivAX == tb_sesPubAPrivBX) && (tb_sesPubBPrivAY == tb_sesPubAPrivBY))
		begin
			$info("Correct Session Keys YESSSSSSSSSSSS!");
		end
		else
		begin	
			$error("Incorrect value BLAHHH");
		end
		//tb_A = {1'b0, 1'b1, 1'b1, 153'b0, 1'b1, 1'b1, 2'b0, 1'b1, 2'b0, 1'b1};
		//tb_B = 165'b11;
	end


endmodule
