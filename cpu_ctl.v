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
    output reg [12:0] ctl_out,
    output reg [15:0] immediate,
    output reg [7:0] write_en,
    output reg [23:0] output_en,
    input [15:0] ctl_in,
	 input clk,
	 input reset
    );
	
	wire [7:0] reg1, reg2, reg3, reg4;
	wire [23:0] reg1_en, reg2_en, reg3_en, reg4_en;
	
	reg [15:0] insn;
	reg [1:0] insn_cycle;
	
	assign reg1 = 8'b1 << insn[13:11];
	assign reg1_en = 24'b1 << (insn[13:11] * 3);
	
	assign reg2 = 8'b1 << insn[10:8];
	assign reg2_en = 24'b1 << (insn[10:8] * 3);
	
	assign reg3 = 8'b1 << insn[7:5];
	assign reg3_en = 24'b1 << (insn[7:5] * 3);
	
	assign reg4 = 8'b1 << insn[4:2];
	assign reg4_en = 24'b1 << (insn[4:2] * 3);
	
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			insn = 16'b0;
			insn_cycle = 2'b0;
		end else if(insn_cycle == 2'b00) begin
			insn = ctl_in;
			insn_cycle = 2'b01;
		end else begin
			insn_cycle = {insn_cycle[0], 1'b0};
		end
	end
	
	always @(negedge clk or posedge reset) begin
		if(reset) begin
			write_en = 8'b0;
			data_write_en = 1'b0;
			alu_op = 3'b0;
			output_en = 24'b0;
			ctl_out = 13'b0;
			immediate = 16'b0;
		end else case(insn_cycle)
			2'b00 : begin
				// instruction fetch (PC -> ADDR, data -> CTL-IN)
				write_en = 8'b0;
				data_write_en = 1'b0;
				output_en = 24'b1;
				ctl_out = 13'b0000010010000;
			end
			2'b01 : begin
				if(insn[15]) begin
					if(insn[14]) begin
						// MOV R1, [R2 + C] (R2 -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> ADDR, DATA -> REG-IN, write R1)
						// instruction encoding: 0b11RRRrrrcccccccc
						write_en = reg1;
						data_write_en = 1'b0;
						alu_op = 3'b101;
						output_en = reg2_en;
						ctl_out = 13'b0000001010101;
						immediate = {{8{insn[7]}}, insn[7:0]};
					end else begin
						// MOV [R1 + C], R2 (R1 -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> ADDR, R2 -> BUSB -> DATA, write data)
						// instruction encoding: 0b10RRRrrrcccccccc
						write_en = 8'b0;
						data_write_en = 1'b1;
						alu_op = 3'b101;
						output_en = reg1_en | (reg2_en << 1);
						ctl_out = 13'b0000101000101;
						immediate = {{8{insn[7]}}, insn[7:0]};
					end
				end else case(insn[14:11])
					4'b0000 : begin
						// ADD R1, C (R1 -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b00000RRRcccccccc
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b101;
						output_en = reg2_en;
						ctl_out = 13'b0000000100101;
						immediate = {{8{insn[7]}}, insn[7:0]};
					end
					4'b0001 : begin
						// ANDL R1, C (R1 -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b00001RRRcccccccc
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b000;
						output_en = reg2_en;
						ctl_out = 13'b0000000100101;
						immediate = {8'hff, insn[7:0]};
					end
					4'b0010 : begin
						// ANDH R1, C (R1 -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b00010RRRcccccccc
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b000;
						output_en = reg2_en;
						ctl_out = 13'b0000000100101;
						immediate = {insn[7:0], 8'hff};
					end
					4'b0011 : begin
						// ORL R1, C (R1 -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b00011RRRcccccccc
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b001;
						output_en = reg2_en;
						ctl_out = 13'b0000000100101;
						immediate = {8'h00, insn[7:0]};
					end
					4'b0100 : begin
						// ORH R1, C (R1 -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b00100RRRcccccccc
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b001;
						output_en = reg2_en;
						ctl_out = 13'b0000000100101;
						immediate = {insn[7:0], 8'h00};
					end
					4'b0101 : begin
						// MOVL R1, C
						// instruction encoding: 0b00101RRRcccccccc
						write_en = reg2;
						data_write_en = 1'b0;
						output_en = reg2_en << 2;
						ctl_out = 13'b1001000000000;
						immediate[7:0] = insn[7:0];
					end
					4'b0110 : begin
						// MOVH R1, C
						// instruction encoding: 0b00110RRRcccccccc
						write_en = reg2;
						data_write_en = 1'b0;
						output_en = reg2_en << 2;
						ctl_out = 13'b0110000000000;
						immediate[7:0] = insn[7:0];
					end
					4'b0111 : begin
						// BRNZ R1, C (R1 -> BUSC -> ALU-C, PC -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> REG-IN, write PC)
						// instruction encoding: 0b00111RRRcccccccc
						write_en = 8'b1;
						data_write_en = 1'b0;
						alu_op = 3'b110;
						output_en = (reg2_en << 2) | 24'b1;
						ctl_out = 13'b0000000101101;
						immediate = {{8{insn[7]}}, insn[7:0]};
					end
					4'b1000 : begin
						// NOT R1, R2 (R2 -> BUSA -> ALU-A, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b01000RRRrrrxxxxx
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b010;
						output_en = reg3_en;
						ctl_out = 13'b0000000100001;
					end
					4'b1001 : begin
						// ADD R1, R2, R3 (R2 -> BUSA -> ALU-A, R3 -> BUSB -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b01001RRRrrrGGGxx
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b101;
						output_en = reg3_en | (reg4_en << 1);
						ctl_out = 13'b0000000100011;
					end
					4'b1010 : begin
						// AND R1, R2, R3 (R2 -> BUSA -> ALU-A, R3 -> BUSB -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b01010RRRrrrGGGxx
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b000;
						output_en = reg3_en | (reg4_en << 1);
						ctl_out = 13'b0000000100011;
					end
					4'b1011 : begin
						// OR R1, R2, R3 (R2 -> BUSA -> ALU-A, R3 -> BUSB -> ALU-B, ALU-OUT -> REG-IN, write R1)
						// instruction encoding: 0b01011RRRrrrGGGxx
						write_en = reg2;
						data_write_en = 1'b0;
						alu_op = 3'b001;
						output_en = reg3_en | (reg4_en << 1);
						ctl_out = 13'b0000000100011;
					end
					4'b1100 : begin
						// MULT R1, R2
						write_en = 8'b0;
						data_write_en = 1'b0;
						output_en = 24'b0;
						ctl_out = 13'b0000000000000;
					end
					4'b1101 : begin
						// PUSH R1
						write_en = 8'b0;
						data_write_en = 1'b0;
						output_en = 24'b0;
						ctl_out = 13'b0000000000000;
					end
					4'b1110 : begin
						// POP R1
						write_en = 8'b0;
						data_write_en = 1'b0;
						output_en = 24'b0;
						ctl_out = 13'b0000000000000;
					end
					4'b1111 : begin
						// SHIFT R1, C
						write_en = 8'b0;
						data_write_en = 1'b0;
						output_en = 24'b0;
						ctl_out = 13'b0000000000000;
					end
				endcase
			end
			2'b10 : begin
				// program counter increment (PC -> BUSA -> ALU-A, IMM -> ALU-B, ALU-OUT -> REG-IN, write PC)
				immediate = {15'b0, ~write_en[0]};
				write_en = 8'b1;
				data_write_en = 1'b0;
				alu_op = 3'b101;
				output_en = 24'b1;
				ctl_out = 13'b0000000100101;
			end
		endcase
	end

endmodule
