`timescale 10ns/10ns
`include "top2.sv"

module tb_top;

  // Test bench signals
  logic clk;
  logic SW;
  logic BOOT;
  wire LED;
  wire RGB_R;
  wire RGB_G;
  wire RGB_B;

  // Instantiate the DUT (Design Under Test)
  top dut (
    .clk   (clk),
    .SW    (SW),
    .BOOT  (BOOT),
    .LED   (LED),
    .RGB_R (RGB_R),
    .RGB_G (RGB_G),
    .RGB_B (RGB_B)
  );

  // Clock generation: Generate a 12 MHz clock (83.3 ns period)
  initial clk = 0;
  always #41.7 clk = ~clk;  // toggles every 41.7 ns ~ 12 MHz

  // Emulate reset behavior
  initial begin
    SW = 1'b0;    // assert reset
    BOOT = 1'b0;  // if unused, just keep low
    #100;         // hold reset for 100 ns
    SW = 1'b1;    // release reset

    // Dump waves for GTKWave
    $dumpfile("mp2.vcd");
    $dumpvars(0, tb_top);

    // Run simulation long enough to see a full hue cycle (1 second)
    #10000000;  // 1e7 * 10 ns = 100,000,000 ns = 1 second
    $finish;
  end

endmodule
