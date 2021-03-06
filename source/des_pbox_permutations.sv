// $Id: mg78 $
// Created:     3/31/2015 
// Author:      Nico Bellante
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: pbox permutations

module des_pbox_permutations (
	input wire [0:31] input_wires,
	output wire [0:31] output_wires
);
	// applies pbox permutation as specified in DES standards
	assign output_wires[0] = input_wires[15];
	assign output_wires[1] = input_wires[6];
	assign output_wires[2] = input_wires[19];
	assign output_wires[3] = input_wires[20];
	assign output_wires[4] = input_wires[28];
	assign output_wires[5] = input_wires[11];
	assign output_wires[6] = input_wires[27];
	assign output_wires[7] = input_wires[16];
	assign output_wires[8] = input_wires[0];
	assign output_wires[9] = input_wires[14];
	assign output_wires[10] = input_wires[22];
	assign output_wires[11] = input_wires[25];
	assign output_wires[12] = input_wires[4];
	assign output_wires[13] = input_wires[17];
	assign output_wires[14] = input_wires[30];
	assign output_wires[15] = input_wires[9];
	assign output_wires[16] = input_wires[1];
	assign output_wires[17] = input_wires[7];
	assign output_wires[18] = input_wires[23];
	assign output_wires[19] = input_wires[13];
	assign output_wires[20] = input_wires[31];
	assign output_wires[21] = input_wires[26];
	assign output_wires[22] = input_wires[2];
	assign output_wires[23] = input_wires[8];
	assign output_wires[24] = input_wires[18];
	assign output_wires[25] = input_wires[12];
	assign output_wires[26] = input_wires[29];
	assign output_wires[27] = input_wires[5];
	assign output_wires[28] = input_wires[21];
	assign output_wires[29] = input_wires[10];
	assign output_wires[30] = input_wires[3];
	assign output_wires[31] = input_wires[24];

endmodule
