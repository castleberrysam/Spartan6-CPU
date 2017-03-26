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
    output reg [7:0] data_out,
    output reg [31:0] io_outputs,
    input [7:0] data_in,
    input [31:0] io_inputs,
    input [15:0] addr,
    input write_en,
    input clk,
    input reset
    );

    wire [7:0] rom_out, ram_out, mem_out;

    rom_32k_x_8 rom(clk, addr[14:0], rom_out);
    ram_32k_x_8 ram(clk, write_en, addr[14:0], data_in, ram_out);

    mux8 mux0(mem_out, addr[15], rom_out, ram_out);

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            io_outputs = 32'b0;
        end else if(write_en) case(addr)
            16'hfff8 : io_outputs[7:0] = data_in;
            16'hfff9 : io_outputs[15:8] = data_in;
            16'hfffa : io_outputs[23:16] = data_in;
            16'hfffb : io_outputs[31:24] = data_in;
        endcase
    end
	
    always @(negedge clk or posedge reset) begin
        if(reset) begin
            data_out = 16'b0;
        end else case(addr)
            16'hfff8 : data_out = io_outputs[7:0];
            16'hfff9 : data_out = io_outputs[15:8];
            16'hfffa : data_out = io_outputs[23:16];
            16'hfffb : data_out = io_outputs[31:24];
            16'hfffc : data_out = io_inputs[7:0];
            16'hfffd : data_out = io_inputs[15:8];
            16'hfffe : data_out = io_inputs[23:16];
            16'hffff : data_out = io_inputs[31:24];
            default  : data_out = mem_out;
        endcase
    end

endmodule
