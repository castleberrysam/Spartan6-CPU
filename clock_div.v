`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:29:23 01/07/2017 
// Design Name: 
// Module Name:    clock_div 
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
module clock_div(
    output clk_out,
    input clk_in
    );
	
	reg [1:0] value;
	
	assign clk_out = value[1];
	
	initial begin
		value = 2'b00;
	end
	
	always @(posedge clk_in) begin
		value <= value + 1;
	end

endmodule
