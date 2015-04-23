module des_key_permutation2 (
	input logic [0:55] input_wires,
	output logic [0:47] output_wires
);
genvar i;

logic [0:47][5:0] key_permutation_2 = {6'd13, 6'd16, 6'd10, 6'd23, 6'd0, 6'd4, 6'd2, 6'd27, 6'd14, 6'd5, 6'd20, 6'd9, 6'd22, 6'd18, 6'd11, 6'd3, 6'd25, 6'd7, 6'd15, 6'd6, 6'd26, 6'd19, 6'd12, 6'd1, 6'd40, 6'd51, 6'd30, 6'd36, 6'd46, 6'd54, 6'd29, 6'd39, 6'd50, 6'd44, 6'd32, 6'd47, 6'd43, 6'd48, 6'd38, 6'd55, 6'd33, 6'd52, 6'd45, 6'd41, 6'd49, 6'd35, 6'd28, 6'd31};
generate
		for (i=0; i<48; i++)
		begin: KP2FOR
			assign output_wires[i] = input_wires[key_permutation_2[i]];
		end
endgenerate

endmodule