`timescale 1ns/1ns
`include "top.sv"

module tb_top;

  // Test bench signals
    logic clk;
    logic RGB_R;
    logic RGB_G;
    logic RGB_B;

  // Instantiate the DUT
  top dut (
    .clk   (clk),
    .RGB_R (RGB_R),
    .RGB_G (RGB_G),
    .RGB_B (RGB_B)
  );

  // Clock generation
   always begin
        #41.6667 clk = ~clk;
    end

  initial begin
    // Clock generation
    clk = 0;
    // Dump waves for GTKWave
    $dumpfile("mp2_tb.vcd");
    $dumpvars(0, tb_top);
    // Run lenght
    #1_000_000_000;
    $finish;
  end

endmodule
