module des_DES_round (
	input logic  [0:31] input_left,
	input logic  [0:31] input_right,
	input logic  [0:47] round_key,
	input logic clk,
	input logic n_rst,
	output logic [0:31] output_left,
	output logic [0:31] output_right
);

logic [0:31] f_out;

logic  [0:31] input_left_reg;
logic  [0:31] input_right_reg;

always_ff @(posedge clk) 
begin
	input_left_reg <= input_left;
	input_right_reg <= input_right;
end

des_feistel F(
	.f_input_wires (input_right_reg),
	.round_key     (round_key),
	.f_output_wires(f_out)
	);

assign output_left = input_right_reg;
assign output_right = input_left_reg ^ f_out;

endmodule