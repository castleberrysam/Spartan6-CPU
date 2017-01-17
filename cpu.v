`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:44:57 12/25/2016 
// Design Name: 
// Module Name:    cpu 
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
module cpu(
    output [15:4] io_outputs,
	 output [3:0] leds,
	 input [15:2] io_inputs,
	 input [1:0] buttons,
	 input clk_in,
	 input reset_in
	 );
	
	wire reset, clk_valid, clk1, clk4;
	
	clock_div_4 clkdiv(clk_in, clk1, clk4, clk_valid);
	or or0(reset, reset_in, ~clk_valid);
	
	wire [15:0] addr, data_in, data_out;
	wire data_write_en;
	
	mem mem0(data_out, {io_outputs, leds}, data_in, {io_inputs, buttons}, addr, data_write_en, clk1, reset);
	
	wire [15:0] busa, busb, busc, alua, alub, aluc, alu_out, reg_in, immediate;
	wire [23:0] output_en;
	wire [7:0] write_en;
	wire [12:0] ctl;
	wire [2:0] op;
	
	generate
		genvar i;
		for(i = 0; i < 8; i = i + 1) begin: cpu_regs
			reg16 register(busa, busb, busc, reg_in, output_en[(i*3)+2:(i*3)], write_en[i], clk4, reset);
		end
	endgenerate
	
	alu alu0(alu_out, op, alua, alub, aluc);
	cpu_ctl ctl0(data_write_en, op, ctl, immediate, write_en, output_en, reg_in, clk4, reset);
	tribuf16
		tbuf0(alua, busa, ctl[0]),
		tbuf1(alub, busb, ctl[1]),
		tbuf2(alub, immediate, ctl[2]),
		tbuf3(aluc, busc, ctl[3]),
		
		tbuf4(reg_in, data_out, ctl[4]),
		tbuf5(reg_in, alu_out, ctl[5]),
		
		tbuf6(addr, alu_out, ctl[6]),
		tbuf7(addr, busa, ctl[7]),
		
		tbuf8(data_in, busb, ctl[8]);
	tribuf8
		tbuf9(reg_in[7:0], immediate[7:0], ctl[9]),
		tbuf10(reg_in[7:0], busc[7:0], ctl[10]),
		
		tbuf11(reg_in[15:8], immediate[7:0], ctl[11]),
		tbuf12(reg_in[15:8], busc[15:8], ctl[12]);
	
endmodule
