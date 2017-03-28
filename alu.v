`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:15:15 12/25/2016 
// Design Name: 
// Module Name:    alu 
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
module alu(
    output reg [15:0] out,
    input [2:0] op,
    input [3:0] logic_func,
    input [15:0] ina,
    input [15:0] inb,
    input [15:0] inc
    );
    
    integer i;

    always @(*) begin
        case(op)
            3'b000 : out = ina + inb;
            3'b001 : out = ina + inb + 16'b1;
            3'b010 : out = ina - inb;
            3'b011 : out = (ina << inb[3:0]) | (ina >> -inb[3:0]);
            3'b100 : for(i = 0; i < 16; i = i + 1) out[i] = logic_func[{ina[i], inb[i]}];
            3'b101 : out = (|inc)    ? (ina) : (ina + inb);
            3'b110 : out = (~|inc)   ? (ina) : (ina + inb);
            3'b111 : out = (inc[15]) ? (ina) : (ina + inb);
        endcase
    end

endmodule
