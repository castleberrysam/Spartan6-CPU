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
    output [31:0] io_outputs,
    output uart_tx,
    input [31:0] io_inputs,
    input uart_rx,
    input clk_in,
    input reset_in
    );

    wire reset, clk_valid, clk1, clk4;

    clock_div_4 clkdiv(clk_in, clk1, clk4, clk_valid);
    assign reset = ~(reset_in & clk_valid);

    wire [15:0] addr;
    wire [7:0] data_in, data_out;
    wire data_write_en;

    mem mem0(data_out, io_outputs, uart_tx, data_in, io_inputs, addr, data_write_en, uart_rx, clk4, clk1, reset);

    wire [15:0] busa, busb, alua, alub, aluc, alu_out, reg_in, imm, imm2, write_en;
    wire [47:0] output_en;
    wire [10:0] ctl;
    wire [3:0] logic_func;
    wire [3:0] op;
    wire alu_cin, alu_cout;

    generate
        genvar i;
        for(i = 0; i < 16; i = i + 1) begin: cpu_regs
            reg16 register(busa, busb, aluc, reg_in, output_en[(i*3)+2:(i*3)], write_en[i], clk4, reset);
        end
    endgenerate

    alu alu0(alu_out, alu_cout, op, logic_func, alua, alub, aluc, alu_cin);
    cpu_ctl ctl0(data_write_en, op, logic_func, alu_cin, ctl, imm, imm2, write_en, output_en, data_out, alu_cout, clk4, reset);
    
    tribuf16
        tbuf0(alua, busa, ctl[0]),
        tbuf1(alub, busb, ctl[1]),
        
        tbuf2(alub, imm, ctl[2]),
        tbuf3(alub, imm2, ctl[3]),
        
        tbuf4(addr, busa, ctl[4]),
        tbuf5(addr, alu_out, ctl[5]),
        
        tbuf6(reg_in, busb, ctl[6]),
        tbuf7(reg_in, alu_out, ctl[7]),
        
        tbuf8(busb, imm, ctl[8]);
    tribuf8
        tbuf9(data_in, busb[7:0], ctl[9]),
        tbuf10(data_in, busb[15:8], ctl[10]);

endmodule
