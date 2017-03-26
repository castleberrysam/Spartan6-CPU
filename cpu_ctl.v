`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:49:31 12/25/2016 
// Design Name: 
// Module Name:    cpu_ctl 
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
module cpu_ctl(
    output reg data_write_en,
    output reg [2:0] alu_op,
    output [3:0] alu_logic_func,
    output reg [10:0] ctl_out,
    output reg [15:0] immediate,
    output reg [15:0] immediate2,
    output reg [15:0] write_en,
    output reg [47:0] output_en,
    input [7:0] data_in,
    input clk,
    input reset
    );
    
    reg [31:0] insn;
    reg [7:0] insn_cycle;
    
    assign alu_logic_func = insn[11:8];
    
    wire [15:0] reg_1, reg_2, reg_3;
    wire [47:0] out_1, out_2, out_3;
    wire insn_len_1, insn_len_2, insn_len_3, insn_len_4;
    
    assign reg_1 = 16'b1 << insn[3:0];
    assign reg_2 = 16'b1 << insn[15:12];
    assign reg_3 = 16'b1 << insn[11:8];
    
    assign out_1 = 48'b1 << (insn[3:0] * 3);
    assign out_2 = 48'b1 << (insn[15:12] * 3);
    assign out_3 = 48'b1 << (insn[11:8] * 3);
    
    function [1:0] insn_len;
        input [3:0] opcode;
        
        case(opcode)
            4'b0000: insn_len = 2'b00;
            4'b0001: insn_len = 2'b00;
            
            4'b0010: insn_len = 2'b01;
            4'b0011: insn_len = 2'b01;
            4'b0100: insn_len = 2'b01;
            4'b0101: insn_len = 2'b01;
            4'b0110: insn_len = 2'b01;
            
            4'b0111: insn_len = 2'b10;
            4'b1000: insn_len = 2'b10;
            4'b1001: insn_len = 2'b10;
            
            4'b1010: insn_len = 2'b11;
            4'b1011: insn_len = 2'b11;
            4'b1100: insn_len = 2'b11;
            4'b1101: insn_len = 2'b11;
            4'b1110: insn_len = 2'b11;
            4'b1111: insn_len = 2'b11;
        endcase
        
    endfunction

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            insn = 32'b0;
            insn_cycle = 8'b0;
        end else case(insn_cycle)
            8'b00 : begin
                insn[7:0] = data_in;
                insn_cycle = (insn_len(insn[7:4]) == 2'b00) ? 8'b100 : 8'b01;
            end
            8'b01 : begin
                insn[15:8] = data_in;
                insn_cycle = (insn_len(insn[7:4]) == 2'b01) ? 8'b100 : 8'b10;
            end
            8'b10 : begin
                insn[23:16] = data_in;
                insn_cycle = (insn_len(insn[7:4]) == 2'b10) ? 8'b100 : 8'b11;
            end
            8'b11 : begin
                insn[31:24] = data_in;
                insn_cycle = 8'b100;
            end
            default : case(insn[7:4])
                4'b0000 : begin
                    // PUSH R
                    // SP -> BUSA -> ALUA, 16'hffff -> ALUB, ALU-OUT -> ADDR, R -> BUSB [7:0]-> DATAIN, write data
                    // SP -> BUSA -> ALUA, 16'hfffe -> ALUB, ALU-OUT -> REG-IN, write SP, SP -> BUSA -> ADDR, R -> BUSB [15:8]-> DATAIN, write data
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b101;
                        8'b101  : insn_cycle = 8'b110;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b0001 : begin
                    // POP R
                    // SP -> BUSA -> ADDR, DATAOUT -> CTLIN, SP -> BUSA -> ALUA, 16'b1 -> ALUB, ALU-OUT -> REG-IN, write SP
                    // SP -> BUSA -> ADDR, DATAOUT -> CTLIN, SP -> BUSA -> ALUA, 16'b1 -> ALUB, ALU-OUT -> REG-IN, write SP
                    // IMM -> REGIN, write R
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b111;
                        8'b111  : insn_cycle = 8'b1000;
                        8'b1000 : insn_cycle = 8'b1001;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b0010 : begin
                    // LFUN C, R1, R2
                    // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b1010;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b0011 : begin
                    // ADD R1, R2
                    // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b1011;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b0100 : begin
                    // SUB R1, R2
                    // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b1100;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b0101 : begin
                    // ROT R1, R2
                    // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b1101;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b0110 : begin
                    // ROT R, C
                    // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write R
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b1110;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b0111 : begin
                    // ADD R, C
                    // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write R
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b1111;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b1000 : begin
                    // MOV R, C
                    // IMM -> REGIN, write R
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b10000;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b1001 : begin
                    // PUSH C
                    // SP -> BUSA -> ADDR, IMM -> BUSB [15:8]-> DATAIN, write data, SP -> BUSA -> ALUA, 16'hffff -> ALUB, ALU-OUT -> REG-IN, write SP
                    // SP -> BUSA -> ADDR, IMM -> BUSB [7:0]-> DATAIN, write data, SP -> BUSA -> ALUA, 16'hffff -> ALUB, ALU-OUT -> REG-IN, write SP
                    case(insn_cycle)
                        8'b100   : insn_cycle = 8'b10001;
                        8'b10001 : insn_cycle = 8'b10010;
                        default  : insn_cycle = 8'b00;
                    endcase
                end
                4'b1010 : begin
                    // LFUN C, R, C
                    // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write R1
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b10011;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b1011 : begin
                    // BEZ R1, R2 + C
                    // R1 -> BUSC -> ALUC, R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write PC
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b10100;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b1100 : begin
                    // BNEZ R1, R2 + C
                    // R1 -> BUSC -> ALUC, R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write PC
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b10101;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b1101 : begin
                    // BGEZ R1, R2 + C
                    // R1 -> BUSB -> ALUC, R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write PC
                    case(insn_cycle)
                        8'b100  : insn_cycle = 8'b10110;
                        default : insn_cycle = 8'b00;
                    endcase
                end
                4'b1110 : begin
                    // MOV R1, [R2 + C]
                    // R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, DATAOUT -> CTLIN
                    // R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, DATAOUT -> CTLIN
                    // IMM -> BUSC -> REGIN, write R1
                    case(insn_cycle)
                        8'b100   : insn_cycle = 8'b10111;
                        8'b10111 : insn_cycle = 8'b11000;
                        8'b11000 : insn_cycle = 8'b11001;
                        default  : insn_cycle = 8'b00;
                    endcase
                end
                4'b1111 : begin
                    // MOV [R1 + C], R2
                    // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, R2 -> BUSB [7:0]-> DATAIN, write data
                    // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, R2 -> BUSB [15:8]-> DATAIN, write data
                    case(insn_cycle)
                        8'b100   : insn_cycle = 8'b11010;
                        8'b11010 : insn_cycle = 8'b11011;
                        default  : insn_cycle = 8'b00;
                    endcase
                end
            endcase
        endcase
    end

    always @(negedge clk or posedge reset) begin
        if(reset) begin
            write_en = 16'b0;
            data_write_en = 1'b0;
            alu_op = 3'b0;
            output_en = 48'b0;
            ctl_out = 11'b0;
            immediate = 16'b0;
            immediate2 = 16'b0;
        end else case(insn_cycle)
            8'b00, 8'b01, 8'b10, 8'b11 : begin
                // instruction fetch
                // PC -> BUSA -> ADDR, PC -> BUSA -> ALUA, 16'b1 -> ALUB, ALU-OUT -> REG-IN, write PC
                write_en = 16'b1;
                data_write_en = 1'b0;
                alu_op = 3'b000;
                output_en = 48'b1;
                ctl_out = 11'b00010010101;
                immediate = 16'b1;
            end
            8'b100 : begin
                write_en = 16'b0;
                data_write_en = 1'b0;
            end
            8'b101 : begin
                // SP -> BUSA -> ALUA, 16'hffff -> ALUB, ALU-OUT -> ADDR, R -> BUSB [7:0]-> DATAIN, write data
                write_en = 16'b0;
                data_write_en = 1'b1;
                alu_op = 3'b000;
                output_en = 48'b1000 | (out_1 << 1);
                ctl_out = 11'b01000100101;
                immediate = 16'hffff;
            end
            8'b110 : begin
                // SP -> BUSA -> ALUA, 16'hfffe -> ALUB, ALU-OUT -> REG-IN, write SP, SP -> BUSA -> ADDR, R -> BUSB [15:8]-> DATAIN, write data
                write_en = 16'b10;
                data_write_en = 1'b1;
                alu_op = 3'b000;
                output_en = 48'b1000 | (out_1 << 1);
                ctl_out = 11'b10010010101;
                immediate = 16'hfffe;
            end
            8'b111 : begin
                // SP -> BUSA -> ADDR, DATAOUT -> CTLIN, SP -> BUSA -> ALUA, 16'b1 -> ALUB, ALU-OUT -> REG-IN, write SP
                write_en = 16'b10;
                data_write_en = 1'b0;
                alu_op = 3'b000;
                output_en = 48'b1000;
                ctl_out = 11'b00010011001;
                immediate2 = 16'b1;
                immediate[7:0] = data_in;
            end
            8'b1000 : begin
                // SP -> BUSA -> ADDR, DATAOUT -> CTLIN, SP -> BUSA -> ALUA, 16'b1 -> ALUB, ALU-OUT -> REG-IN, write SP
                write_en = 16'b10;
                data_write_en = 1'b0;
                alu_op = 3'b000;
                output_en = 48'b1000;
                ctl_out = 11'b00010011001;
                immediate2 = 16'b1;
                immediate[15:8] = data_in;
            end
            8'b1001 : begin
                // IMM -> REGIN, write R
                write_en = reg_1;
                data_write_en = 1'b0;
                ctl_out = 11'b00101000000;
            end
            8'b1010 : begin
                // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                write_en = reg_1;
                data_write_en = 1'b0;
                alu_op = 3'b100;
                output_en = out_1 | (out_2 << 1);
                ctl_out = 11'b00010000011;
            end
            8'b1011 : begin
                // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                write_en = reg_2;
                data_write_en = 1'b0;
                alu_op = 3'b000;
                output_en = out_2 | (out_3 << 1);
                ctl_out = 11'b00010000011;
            end
            8'b1100 : begin
                // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                write_en = reg_2;
                data_write_en = 1'b0;
                alu_op = 3'b010;
                output_en = out_2 | (out_3 << 1);
                ctl_out = 11'b00010000011;
            end
            8'b1101 : begin
                // R1 -> BUSA -> ALUA, R2 -> BUSB -> ALUB, ALUOUT -> REGIN, write R1
                write_en = reg_2;
                data_write_en = 1'b0;
                alu_op = 3'b011;
                output_en = out_2 | (out_3 << 1);
                ctl_out = 11'b00010000011;
            end
            8'b1110 : begin
                // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write R
                write_en = reg_1;
                data_write_en = 1'b0;
                alu_op = 3'b011;
                output_en = out_1;
                ctl_out = 11'b00010000101;
                immediate = insn[11:8];
            end
            8'b1111 : begin
                // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write R
                write_en = reg_1;
                data_write_en = 1'b0;
                alu_op = 3'b000;
                output_en = out_1;
                ctl_out = 11'b00010000101;
                immediate = insn[23:8];
            end
            8'b10000 : begin
                // IMM -> BUSB -> REGIN, write R
                write_en = reg_1;
                data_write_en = 1'b0;
                ctl_out = 11'b00101000000;
                immediate = insn[23:8];
            end
            8'b10001 : begin
                // SP -> BUSA -> ADDR, IMM -> BUSB [15:8]-> DATAIN, write data, SP -> BUSA -> ALUA, 16'hffff -> ALUB, ALU-OUT -> REG-IN, write SP
                write_en = 16'b10;
                data_write_en = 1'b1;
                alu_op = 3'b000;
                output_en = 48'b1000;
                ctl_out = 11'b10110011001;
                immediate = insn[23:8];
                immediate2 = 16'hffff;
            end
            8'b10010 : begin
                // SP -> BUSA -> ADDR, IMM -> BUSB [7:0]-> DATAIN, write data, SP -> BUSA -> ALUA, 16'hffff -> ALUB, ALU-OUT -> REG-IN, write SP
                write_en = 16'b10;
                data_write_en = 1'b1;
                alu_op = 3'b000;
                output_en = 48'b1000;
                ctl_out = 11'b01110011001;
                immediate = insn[23:8];
                immediate2 = 16'hffff;
            end
            8'b10011 : begin
                // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write R1
                write_en = reg_2;
                data_write_en = 1'b0;
                alu_op = 3'b100;
                output_en = out_2;
                ctl_out = 11'b00010000101;
                immediate = insn[31:16];
            end
            8'b10100 : begin
                // R1 -> BUSC -> ALUC, R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write PC
                write_en = 16'b1;
                data_write_en = 1'b0;
                alu_op = 3'b101;
                output_en = (out_2 << 2) | out_3;
                ctl_out = 11'b00010000101;
                immediate = insn[31:16];
            end
            8'b10101 : begin
                // R1 -> BUSC -> ALUC, R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write PC
                write_en = 16'b1;
                data_write_en = 1'b0;
                alu_op = 3'b110;
                output_en = (out_2 << 2) | out_3;
                ctl_out = 11'b00010000101;
                immediate = insn[31:16];
            end
            8'b10110 : begin
                // R1 -> BUSB -> ALUC, R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> REGIN, write PC
                write_en = 16'b1;
                data_write_en = 1'b0;
                alu_op = 3'b111;
                output_en = (out_2 << 2) | out_3;
                ctl_out = 11'b00010000101;
                immediate = insn[31:16];
            end
            8'b10111 : begin
                // R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, DATAOUT -> CTLIN
                write_en = 16'b0;
                data_write_en = 1'b0;
                alu_op = 3'b000;
                output_en = out_3;
                ctl_out = 11'b00000101001;
                immediate2 = insn[31:16];
                immediate[7:0] = data_in;
            end
            8'b11000 : begin
                // R2 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, DATAOUT -> CTLIN
                write_en = 16'b0;
                data_write_en = 1'b0;
                alu_op = 3'b001;
                output_en = out_3;
                ctl_out = 11'b00000101001;
                immediate2 = insn[31:16];
                immediate[15:8] = data_in;
            end
            8'b11001 : begin
                // IMM -> BUSB -> REGIN, write R1
                write_en = reg_2;
                data_write_en = 1'b0;
                ctl_out = 11'b00101000000;
            end
            8'b11010 : begin
                // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, R2 -> BUSB [7:0]-> DATAIN, write data
                write_en = 16'b0;
                data_write_en = 1'b1;
                alu_op = 3'b000;
                output_en = out_2 | (out_3 << 1);
                ctl_out = 11'b01000100101;
                immediate = insn[31:16];
            end
            8'b11011 : begin
                // R1 -> BUSA -> ALUA, IMM -> ALUB, ALUOUT -> ADDR, R2 -> BUSB [15:8]-> DATAIN, write data
                write_en = 16'b0;
                data_write_en = 1'b1;
                alu_op = 3'b001;
                output_en = out_2 | (out_3 << 1);
                ctl_out = 11'b10000100101;
                immediate = insn[31:16];
            end
        endcase
    end

endmodule
