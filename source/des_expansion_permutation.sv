module des_expansion_permutation (
	input logic [0:31] input_wires,
	output logic [0:47] output_wires

);
genvar i;

logic [0:47][5:0] expansion_permutation = {6'd31, 6'd0, 6'd1, 6'd2, 6'd3, 6'd4, 6'd3, 6'd4, 6'd5, 6'd6, 6'd7, 6'd8, 6'd7, 6'd8, 6'd9, 6'd10, 6'd11, 6'd12, 6'd11, 6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd15, 6'd16, 6'd17, 6'd18, 6'd19, 6'd20, 6'd19, 6'd20, 6'd21, 6'd22, 6'd23, 6'd24, 6'd23, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd27, 6'd28, 6'd29, 6'd30, 6'd31, 6'd0};
generate
		for (i=0; i<48; i++)
		begin: EXPPERFOR
			assign output_wires[i] = input_wires[expansion_permutation[i]];
		end
endgenerate

endmodule