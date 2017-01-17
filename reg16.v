`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:37:32 12/25/2016 
// Design Name: 
// Module Name:    reg16 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module reg16(
    output [15:0] outa,
	 output [15:0] outb,
	 output [15:0] outc,
	 input [15:0] in,
	 input [2:0] output_en,
	 input write_en,
	 input clk,
	 input reset
    );
	
	reg [15:0] value, value_out;
	
	tribuf16
		tbufa(outa, value_out, output_en[0]),
		tbufb(outb, value_out, output_en[1]),
		tbufc(outc, value_out, output_en[2]);
	
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			value = 16'b0;
		end else if(write_en) begin
			value = in;
		end
	end
	
	always @(negedge clk or posedge reset) begin
		if(reset) begin
			value_out = 16'b0;
		end else begin
			value_out = value;
		end
	end
	
endmodule
