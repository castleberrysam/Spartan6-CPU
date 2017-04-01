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
    output uart_tx,
    input [7:0] data_in,
    input [31:0] io_inputs,
    input [15:0] addr,
    input write_en,
    input uart_rx,
    input uart_clk,
    input clk,
    input reset
    );
    
    // 0xffff - 0xfffc : r  : gpio input pins
    // 0xfffb - 0xfff8 : rw : gpio output pins
    // 0xfff7 - 0xfff0 : r  : uart input buffer
    // 0xffef - 0xffe8 :  w : uart output buffer
    // 0xffe6          : rw : uart input count
    // 0xffe4          : rw : uart output count

    wire [7:0] rom_out, ram_out, mem_out;
    
    wire uart_data_avail, uart_txbuf_empty;
    reg uart_clear_avail, uart_write_en;
    reg [7:0] uart_in;
    wire [7:0] uart_out;
    reg [63:0] uart_input_buf;
    reg [7:0] uart_input_count;
    reg [63:0] uart_output_buf;
    reg [7:0] uart_output_count;
    
    reg [1:0] mem_write_cooldown;

    rom_32k_x_8 rom(clk, addr[14:0], rom_out);
    ram_32k_x_8 ram(clk, write_en, addr[14:0], data_in, ram_out);
    uart uart(uart_tx, uart_out, uart_data_avail, uart_txbuf_empty, uart_rx,
              uart_in, uart_write_en, uart_clear_avail, uart_clk, reset);

    mux8 mux0(mem_out, addr[15], rom_out, ram_out);
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            io_outputs = 32'b0;
            uart_in = 8'b0;
            uart_write_en = 1'b0;
            uart_clear_avail = 1'b0;
            uart_input_buf = 64'b0;
            uart_input_count = 8'b0;
            uart_output_buf = 64'b0;
            uart_output_count = 8'b0;
            mem_write_cooldown = 2'b01;
        end else begin
            // special write operations
            if(mem_write_cooldown == 2'b00 && write_en) case(addr)
                16'hffe4 : uart_output_count = (data_in > 8'd8 ? 8'd8 : data_in);
                16'hffe6 : uart_input_count = 8'b0;
                16'hffe8 : uart_output_buf[7:0] = data_in;
                16'hffe9 : uart_output_buf[15:8] = data_in;
                16'hffea : uart_output_buf[23:16] = data_in;
                16'hffeb : uart_output_buf[31:24] = data_in;
                16'hffec : uart_output_buf[39:32] = data_in;
                16'hffed : uart_output_buf[47:40] = data_in;
                16'hffee : uart_output_buf[55:48] = data_in;
                16'hffef : uart_output_buf[63:56] = data_in;
                16'hfff8 : io_outputs[7:0] = data_in;
                16'hfff9 : io_outputs[15:8] = data_in;
                16'hfffa : io_outputs[23:16] = data_in;
                16'hfffb : io_outputs[31:24] = data_in;
            endcase
            /* This is implemented because the memory clock is faster than
             * the CPU clock. This results in a memory write actually writing
             * to the RAM four times with the same parameters per write since
             * the CPU only changes the inputs every four memory clock cycles.
             * Normally it doesn't cause any problems but for special registers
             * which can change for other reasons the multiple writes results
             * in changed values being overwritten. This cooldown counter limits
             * writes to the special registers to once per four clock cycles to
             * avoid this problem.
             */
            mem_write_cooldown = mem_write_cooldown + 2'b1;
            
            // uart output buffer management
            if(uart_txbuf_empty) begin
                if(uart_output_count != 16'b0 && uart_write_en != 1'b1) begin
                    case(uart_output_count)
                        16'd1: uart_in = uart_output_buf[63:56];
                        16'd2: uart_in = uart_output_buf[55:48];
                        16'd3: uart_in = uart_output_buf[47:40];
                        16'd4: uart_in = uart_output_buf[39:32];
                        16'd5: uart_in = uart_output_buf[31:24];
                        16'd6: uart_in = uart_output_buf[23:16];
                        16'd7: uart_in = uart_output_buf[15:8];
                        16'd8: uart_in = uart_output_buf[7:0];
                    endcase
                    uart_output_count = uart_output_count - 8'b1;
                    uart_write_en = 1'b1;
                end
            end else begin
                uart_write_en = 1'b0;
            end
            
            // uart input buffer management
            if(uart_data_avail) begin
                if(uart_input_count != 16'd8 && uart_clear_avail != 1'b1) begin
                    case(uart_input_count)
                        16'd0: uart_input_buf[7:0] = uart_out;
                        16'd1: uart_input_buf[15:8] = uart_out;
                        16'd2: uart_input_buf[23:16] = uart_out;
                        16'd3: uart_input_buf[31:24] = uart_out;
                        16'd4: uart_input_buf[39:32] = uart_out;
                        16'd5: uart_input_buf[47:40] = uart_out;
                        16'd6: uart_input_buf[55:48] = uart_out;
                        16'd7: uart_input_buf[63:56] = uart_out;
                    endcase
                    uart_input_count = uart_input_count + 8'b1;
                    uart_clear_avail = 1'b1;
                end
            end else begin
                uart_clear_avail = 1'b0;
            end
        end
    end
	
    // special read operations
    always @(negedge clk or posedge reset) begin
        if(reset) begin
            data_out = 8'b0;
        end else case(addr)
            16'hffe4 : data_out = uart_output_count;
            16'hffe6 : data_out = uart_input_count;
            16'hfff0 : data_out = uart_input_buf[7:0];
            16'hfff1 : data_out = uart_input_buf[15:8];
            16'hfff2 : data_out = uart_input_buf[23:16];
            16'hfff3 : data_out = uart_input_buf[31:24];
            16'hfff4 : data_out = uart_input_buf[39:32];
            16'hfff5 : data_out = uart_input_buf[47:40];
            16'hfff6 : data_out = uart_input_buf[55:48];
            16'hfff7 : data_out = uart_input_buf[63:56];
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
