`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:43:25 12/25/2016 
// Design Name: 
// Module Name:    tribuf16 
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
module tribuf16(
    output [15:0] out,
    input [15:0] in,
    input output_en
    );

    generate
        genvar i;
        for(i = 0; i < 16; i = i + 1) begin: tribufs
            tribuf tbuf(out[i], in[i], output_en);
        end
    endgenerate

endmodule
