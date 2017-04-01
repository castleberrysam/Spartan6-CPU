`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:31:35 03/24/2017
// Design Name:   cpu
// Module Name:   /home/sam/Desktop/spartan6-cpu/test_cpu.v
// Project Name:  Project
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: cpu
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_cpu;

	// Inputs
	reg [31:0] io_inputs;
    reg uart_rx;
	reg clk_in;
	reg reset_in;

	// Outputs
	wire [31:0] io_outputs;
    wire uart_tx;

	// Instantiate the Unit Under Test (UUT)
	cpu uut (
		.io_outputs(io_outputs), 
        .uart_tx(uart_tx), 
		.io_inputs(io_inputs), 
        .uart_rx(uart_rx), 
		.clk_in(clk_in), 
		.reset_in(reset_in)
	);

	initial begin
		// Initialize Inputs
		io_inputs = 0;
        uart_rx = 1;
		clk_in = 0;
		reset_in = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        forever begin
            #10;
            clk_in = 1;
            #10;
            clk_in = 0;
            
            uart_rx = uart_tx;
        end
	end
      
endmodule

