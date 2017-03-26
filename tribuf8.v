`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:19:35 01/05/2017 
// Design Name: 
// Module Name:    tribuf8 
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
module tribuf8(
    output [7:0] out,
    input [7:0] in,
    input output_en
    );

    generate
        genvar i;
        for(i = 0; i < 8; i = i + 1) begin: tribufs
            tribuf tbuf(out[i], in[i], output_en);
        end
    endgenerate

endmodule
