module des_TripleDES (
	input logic [0:63] input_block,
	input logic [0:191] Sk,
	input logic is_encrypt,
	input wire clk,
	output logic [0:63] output_block
);

logic [0:2][0:15][0:47] round_keys;

logic [0:63] DES1_output;
logic [0:63] DES2_output;


des_key_schedule KS (
	.Sk(Sk),
	.is_encrypt(is_encrypt),
	.round_keys(round_keys)
	);


des_DES DES1 (
	.input_block     (input_block),
	.round_keys      (round_keys[0]),
	.output_block    (DES1_output),
	.clk         	 (clk)
	);

des_DES DES2 (
	.input_block	(DES1_output),
	.round_keys 	(round_keys[1]),
	.output_block   (DES2_output),
	.clk            (clk)
	);

des_DES DES3 (
	.input_block     (DES2_output),
	.round_keys 	 (round_keys[2]),
	.output_block    (output_block),
	.clk             (clk)
	);

endmodule
