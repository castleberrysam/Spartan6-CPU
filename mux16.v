`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:27:38 12/25/2016 
// Design Name: 
// Module Name:    mux16 
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
module mux16(
    output [15:0] out,
    input sel,
    input [15:0] ina,
    input [15:0] inb
    );

	generate
		genvar i;
		for(i = 0; i < 16; i = i + 1) begin: muxes
			mux multiplexer(out[i], sel, ina[i], inb[i]);
		end
	endgenerate

endmodule
