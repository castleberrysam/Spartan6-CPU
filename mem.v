`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:14:19 01/06/2017 
// Design Name: 
// Module Name:    mem 
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
module mem(
    output reg [15:0] data_out,
	 output reg [15:0] io_outputs,
    input [15:0] data_in,
	 input [15:0] io_inputs,
    input [15:0] addr,
    input write_en,
    input clk,
	 input reset
    );
	
	wire [15:0] rom_out, ram_out, mem_out;
	
	rom_8k_x_16 rom(clk, addr[12:0], rom_out);
	ram_4k_x_16 ram(clk, write_en, addr[11:0], data_in, ram_out);
	
	mux16 mux0(mem_out, &addr[15:12], rom_out, ram_out);
	
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			io_outputs = 16'b0;
		end else if(addr == 16'h2001 && write_en) begin
			io_outputs = data_in;
		end
	end
	
	always @(negedge clk or posedge reset) begin
		if(reset) begin
			data_out = 16'b0;
		end else if(addr == 16'h2000) begin
			data_out = io_inputs;
		end else if(addr == 16'h2001) begin
			data_out = io_outputs;
		end else begin
			data_out = mem_out;
		end
	end
	
endmodule
