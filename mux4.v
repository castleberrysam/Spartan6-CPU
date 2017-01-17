`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:16:35 12/25/2016 
// Design Name: 
// Module Name:    mux4 
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
module mux4(
    output out,
    input [1:0] sel,
    input ina,
    input inb,
    input inc,
    input ind
    );
	
	wire out0, out1;
	
	mux mux0(out0, sel[0], ina, inb);
	mux mux1(out1, sel[0], inc, ind);
	mux mux2(out, sel[1], out0, out1);

endmodule
