// $Id: $
// File name:   ECCDH3DES.sv
// Created:     4/15/2015
// Author:      Lucas Dahl
// Lab Section: 337-03
// Version:     1.0  Initial Design Entry
// Description: Top Level block

module ECCDH3DES
(
	input wire clk,
	input wire n_rst,
	input wire [63:0] data_in,
	input wire start,
	input wire is_encrypt,
	output reg data_ready,
	output reg [2:0] mode,
	output reg [63:0] data_out
);

	reg estart;
	reg edone;
	reg [163:0] k;
	reg [163:0] Pix;
	reg [163:0] Piy;
	reg [163:0] Pox;
	reg [163:0] Poy;
	reg [163:0] Skx;
	reg [163:0] Sky;
	reg [63:0] DES_input;
	reg [63:0] DES_output;

	point_multiplication ECC(.clk(clk), .n_rst(n_rst), .k(k), .x(Pix), .y(Piy), .SkX(Pox), .SkY(Poy), .start(estart), .done(edone));

	control CONT(.clk(clk), .n_rst(n_rst), .start(start), .data_in(data_in), .mode(mode), .data_out(data_out), .data_ready(data_ready), .edone(edone), .Pox(Pox), .Poy(Poy), .k(k), .Pix(Pix), .Piy(Piy), .estart(estart), .DES_output(DES_output), .Skx(Skx), .Sky(Sky), .DES_input(DES_input));

	TripleDES DES(.clk(clk), .n_rst(n_rst), .input_block(DES_input), .SKx(Skx), .SKy(Sky), .output_block(DES_output), .is_encrypt(is_encrypt));

endmodule
