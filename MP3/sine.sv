`include "memory_quarter.sv"

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

    // 9-bit counter for 512 sample positions (0 to 511)
    logic [8:0] counter = 0;
    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Extract quarter selection bits and the lower 7 bits for addressing
    logic [1:0] quarter_sel;
    logic [6:0] counter_bits;
    assign quarter_sel = counter[8:7];
    assign counter_bits = counter[6:0];

    // Determine the quarter-wave memory address and compute the output data
    // We center the waveform around 512 (mid-scale for a 10-bit DAC) so that:
    // - In quarters 1 and 2 (positive half), data = 512 + quarter_data.
    // - In quarters 3 and 4 (negative half), data = 512 - quarter_data.
    logic [6:0] quarter_address;
    logic [9:0] data; // 10-bit output

    // Quarter-cycle memory outputs a 9-bit magnitude sample (0 to 511)
    logic [8:0] quarter_data;
    memory_quarter #(
        .INIT_FILE("sine_quarter.txt")
    ) u1 (
        .clk(clk),
        .read_address(quarter_address),
        .read_data(quarter_data)
    );

    // Use a case statement on quarter_sel to choose address ordering and compute data
    always_comb begin
        case (quarter_sel)
            2'b00: begin
                // Quarter 1: rising, direct order
                quarter_address = counter_bits;        // 0 to 127
                data = 10'd512 + quarter_data;           // Offset upward
            end
            2'b01: begin
                // Quarter 2: falling, reversed order
                quarter_address = 7'd127 - counter_bits; // Reverse order 127 down to 0
                data = 10'd512 + quarter_data;           // Still add for positive half
            end
            2'b10: begin
                // Quarter 3: falling, direct order
                quarter_address = counter_bits;          // 0 to 127
                data = 10'd512 - quarter_data;           // Subtract for negative half
            end
            2'b11: begin
                // Quarter 4: rising, reversed order
                quarter_address = 7'd127 - counter_bits; // Reverse order 127 down to 0
                data = 10'd512 - quarter_data;           // Subtract for negative half
            end
            default: begin
                quarter_address = 7'd0;
                data = 10'd512;
            end
        endcase
    end

    // Map the 10-bit data to DAC outputs in the specified order
    assign {_48b, _45a, _49a, _3b, _5a, _0a, _2a, _4a, _6a, _9b} = data;

endmodule
