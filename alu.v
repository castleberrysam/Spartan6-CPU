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
    output reg cout,
    input [3:0] op,
    input [3:0] logic_func,
    input [15:0] ina,
    input [15:0] inb,
    input [15:0] inc,
    input cin
    );
    
    integer i;

    always @(*) begin
        out = 16'b0;
        cout = cin;
        case(op)
            4'b0000 : {cout, out} = ina + inb + cin;
            4'b0001 : out = (ina << inb[3:0]) | ({16{cin}} >> -inb[3:0]);
            4'b0010 : {cout, out} = {1'b1, ina} - inb - ~cin;
            4'b0011 : out = (ina << inb[3:0]) | (ina >> -inb[3:0]);
            4'b0100 : for(i = 0; i < 16; i = i + 1) out[i] = logic_func[{ina[i], inb[i]}];
            4'b0101 : out = (|inc)    ? (ina) : (ina + inb);
            4'b0110 : out = (~|inc)   ? (ina) : (ina + inb);
            4'b0111 : out = (inc[15]) ? (ina) : (ina + inb);
        endcase
    end

endmodule
