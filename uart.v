`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:16:15 03/29/2017 
// Design Name: 
// Module Name:    uart 
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
module uart(
    output reg uart_tx,
    output reg [7:0] data_out,
    output reg new_data,
    output reg buf_empty,
    input uart_rx,
    input [7:0] data_in,
    input write_data,
    input read_data,
    input uart_clk,
    input reset
    );
    
    reg [2:0] clk_cycle;
    reg [2:0] clk_offset_in;
    reg [2:0] low_cycles_in;
    reg [9:0] data_out_buf;
    reg [3:0] curr_bit_out;
    reg [3:0] curr_bit_in;
    
    always @(posedge reset or posedge uart_clk) begin
        if(reset) begin
            uart_tx = 1'b1;
            data_out = 8'b0;
            new_data = 1'b0;
            buf_empty = 1'b1;
            clk_cycle = 3'b0;
            clk_offset_in = 3'b0;
            low_cycles_in = 3'b0;
            data_out_buf = 10'b0;
            curr_bit_out = 4'b0;
            curr_bit_in = 4'b0;
        end else begin
            // input buffer being read by cpu?
            if(read_data) begin
                // clear the flag indicating that
                // new data has been received and
                // is available
                new_data = 1'b0;
            end
            
            // output buffer being written by cpu?
            if(write_data) begin
                // reset tx state if for some reason
                // the data buffer was written to
                // in the middle of a transmission
                uart_tx = 1'b1;
                buf_empty = 1'b0;
                curr_bit_out = 4'b0;
                // load input data into data buffer
                // adding in start and stop bits
                data_out_buf = {1'b1, data_in, 1'b0};
            end
            
            // send data on tx
            if(~buf_empty && clk_cycle == 3'b0) begin
                // send bit of data
                uart_tx = data_out_buf[curr_bit_out];
                curr_bit_out = curr_bit_out + 4'b1;
                if(curr_bit_out == 4'd10) begin
                    // finished sending data, signal that
                    // the data buffer is empty to the cpu
                    curr_bit_out = 4'b0;
                    buf_empty = 1'b1;
                end
            end
            
            // read data from rx
            if(curr_bit_in == 4'b0) begin
                // find the start bit
                low_cycles_in = (uart_rx ? 3'b0 : (low_cycles_in + 3'b1));
                if(low_cycles_in == 3'd5) begin
                    // found the start bit, read remaining bits every
                    // 8 clk pulses from the current cycle
                    low_cycles_in = 3'b0;
                    clk_offset_in = clk_cycle;
                    curr_bit_in = 4'b1;
                end
            end else if(curr_bit_in == 4'd9) begin
                // finished reading data, don't bother
                // reading the stop bit, signal that
                // new data is available to the cpu
                curr_bit_in = 4'b0;
                new_data = 1'b1;
            end else begin
                // read an incoming data bit
                if(clk_cycle == clk_offset_in) begin
                    data_out[curr_bit_in-1] = uart_rx;
                    curr_bit_in = curr_bit_in + 4'b1;
                end
            end
            clk_cycle = clk_cycle + 3'b1;
        end
    end
    
endmodule
