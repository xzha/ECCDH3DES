// $Id: mg78 $
// Created:     3/31/2015 
// Author:      Nico Bellante
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: DES CODE

module des_DES (
	input logic [0:63] input_block,
	input logic [0:15][0:47] round_keys,
	input logic clk,
	input logic n_rst,
	input logic data_valid_in,
	output logic data_valid_out,
	output logic [0:63] output_block,
	input logic [4:0] round_select,
	output logic [0:63] selected_out
);
genvar i;

logic [0:16][0:31] left ;
logic [0:16][0:31] right;
logic [0:16] data_valid;

logic [0:63] after_initial_permutation;

des_initial_permutation ip (
	.input_wires(input_block),
	.output_wires(after_initial_permutation)
	);

des_inverse_initial_permutation invip (
	.input_wires({right[16], left[16]}),
	.output_wires(output_block)
	);

assign left[0]    = after_initial_permutation[0:31];
assign right[0]   = after_initial_permutation[32:63];
assign data_valid[0] = data_valid_in; 
assign data_valid_out = data_valid[16];

generate
	for (i=0; i<16; i++)
	begin: DESROUNDFOR
		des_DES_round DES_R(
			.input_left  (left[i]),
			.input_right (right[i]),
			.round_key   (round_keys[i]),
			.clk         (clk),
			.n_rst       (n_rst),
			.data_valid_in  (data_valid[i]),
			.data_valid_out (data_valid[i+1]),
			.output_left (left[i+1]),
			.output_right(right[i+1])
			);
	end
endgenerate

assign selected_out = 


endmodule
