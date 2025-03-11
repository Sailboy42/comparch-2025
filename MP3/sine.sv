`include "memory_quarter.sv"  // Use the modified quarter-cycle memory module

module top(
    input  logic clk, 
    output logic _9b,    // D0
    output logic _6a,    // D1
    output logic _4a,    // D2
    output logic _2a,    // D3
    output logic _0a,    // D4
    output logic _5a,    // D5
    output logic _3b,    // D6
    output logic _49a,   // D7
    output logic _45a,   // D8
    output logic _48b    // D9
);

    // Helper function to extract the lower 7 bits without using a constant select.
    function automatic logic [6:0] lower7(input logic [8:0] x);
        lower7 = x - ((x >> 7) << 7);
    endfunction

    // 9-bit counter for 512 sample positions (0 to 511)
    logic [8:0] counter = 0;
    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Determine which quarter of the cycle and compute quarter address and sign
    logic [6:0] quarter_address;
    logic       sign;
    
    always_comb begin
        if (counter < 9'd128) begin
            // Quarter 1: 0 to 127
            quarter_address = lower7(counter);  // Extract lower 7 bits
            sign = 1'b0;
        end else if (counter < 9'd256) begin
            // Quarter 2: 128 to 255
            quarter_address = 7'd127 - (counter - 9'd128);
            sign = 1'b0;
        end else if (counter < 9'd384) begin
            // Quarter 3: 256 to 383
            quarter_address = counter - 9'd256; // yields 0 to 127
            sign = 1'b1;
        end else begin
            // Quarter 4: 384 to 511
            quarter_address = 7'd127 - (counter - 9'd384);
            sign = 1'b1;
        end
    end

    // Quarter-cycle memory outputs a 9-bit magnitude sample
    logic [8:0] quarter_data;
    memory_quarter #(
        .INIT_FILE("sine_quarter.txt")
    ) u1 (
        .clk(clk),
        .read_address(quarter_address),
        .read_data(quarter_data)
    );

    // Combine sign and magnitude to form a 10-bit sample output.
    // (Assuming a simple sign/magnitude representation.)
    logic [9:0] data;
    assign data = {sign, quarter_data};

    // Map the 10-bit data to the DAC outputs (order may reflect wiring requirements)
    assign {_48b, _45a, _49a, _3b, _5a, _0a, _2a, _4a, _6a, _9b} = data;

endmodule
