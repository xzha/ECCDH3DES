module des_DES (
	input logic [0:63] input_block,
	input logic [0:15][0:47] round_keys,
	input logic clk,
	output logic [0:63] output_block
);
genvar i;

logic [0:16][0:31] left ;
logic [0:16][0:31] right;

logic [0:63] after_initial_permutation;
logic [0:63] after_inv_initial_permutation;

des_initial_permutation ip (
	.input_wires(input_block),
	.output_wires(after_initial_permutation)
	);

des_inverse_initial_permutation invip (
	.input_wires({right[16], left[16]}),
	.output_wires(output_block)
	);

assign left[0]  = after_initial_permutation[0:31];
assign right[0] = after_initial_permutation[32:63] ;

generate
	for (i=0; i<16; i++)
	begin
		des_DES_round DES_R(
			.input_left  (left[i]),
			.input_right (right[i]),
			.round_key   (round_keys[i]),
			.clk         (clk),
			.output_left (left[i+1]),
			.output_right(right[i+1])
			);
	end
endgenerate


endmodule
