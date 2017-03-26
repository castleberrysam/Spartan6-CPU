`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:55:23 03/19/2017 
// Design Name: 
// Module Name:    mux8 
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
module mux8(
    output [7:0] out,
    input sel,
    input [7:0] ina,
    input [7:0] inb
    );
    
    assign out = (sel ? inb : ina);
    
endmodule
