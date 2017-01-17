`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:15:15 12/25/2016 
// Design Name: 
// Module Name:    alu 
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
module alu(
    output reg [15:0] out,
    input [2:0] op,
    input [15:0] ina,
    input [15:0] inb,
    input [15:0] inc
    );
	
	always @(*) begin
		case(op)
			// Logic functions
			3'b000: out = ina & inb;
			3'b001: out = ina | inb;
			3'b010: out = ~ina;
			// Comparison functions
			3'b011: out = (|inc)    ? (inb) : (ina + 1);
			3'b100: out = (inc[15]) ? (inb) : (ina + 1);
			// Addition functions
			3'b101: out = ina + inb;
			3'b110: out = (|inc) ? (ina + inb) : (ina + 1);
			default: out = 16'b0;
		endcase
	end

endmodule
