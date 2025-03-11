`timescale 1ns/1ps
`include "sine.sv"

module tb_top;
    // Clock signal
    logic clk;

    // DAC output wires
    logic _9b;
    logic _6a;
    logic _4a;
    logic _2a;
    logic _0a;
    logic _5a;
    logic _3b;
    logic _49a;
    logic _45a;
    logic _48b;

    // Instantiate the top-level module
    top uut (
        .clk(clk),
        ._9b(_9b),
        ._6a(_6a),
        ._4a(_4a),
        ._2a(_2a),
        ._0a(_0a),
        ._5a(_5a),
        ._3b(_3b),
        ._49a(_49a),
        ._45a(_45a),
        ._48b(_48b)
    );

    // Generate a clock with a 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Dump waveforms and end simulation after a full cycle plus margin
    initial begin
        $dumpfile("tb_top.vcd");  // VCD file for viewing waveforms in gtkwave
        $dumpvars(0, tb_top);
        // Run simulation for 6000ns, which covers more than one full cycle (5120ns for one cycle)
        #6000;
        $finish;
    end
endmodule
