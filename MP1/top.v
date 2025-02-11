module top(
    input  wire clk,       // 12 MHz clock input from the iceBlinkPico
    // Match the pin names in the PCF exactly:
    output wire RGB_R,      // Red pin of on-board RGB LED (active-low)
    output wire RGB_G,      // Green pin of on-board RGB LED (active-low)
    output wire RGB_B       // Blue pin of on-board RGB LED (active-low)
);

    //------------------------------------------------------------
    // 1) Build a 24-bit counter to count 1-second intervals.
    //    Since clk is 12 MHz, 12e6 cycles = 1 second.
    //------------------------------------------------------------
    localparam CLOCK_FREQ = 12_000_000;
    reg [23:0] counter_reg = 24'd0;

    // We'll track a "hue index" from 0..5 (six distinct colors).
    reg [2:0] hue_index = 3'd0;

    always @(posedge clk) begin
        if (counter_reg < (CLOCK_FREQ - 1)) begin
            counter_reg <= counter_reg + 1'b1;
        end else begin
            counter_reg <= 24'd0;
            // Advance hue index every second, wrap around after 5 -> 0
            if (hue_index == 3'd5)
                hue_index <= 3'd0;
            else
                hue_index <= hue_index + 1'b1;
        end
    end

    //------------------------------------------------------------
    // 2) A small LUT mapping hue_index -> RGB (full saturation)
    //    We'll define 1 = "LED ON" internally, 0 = "LED OFF." Then
    //    invert at outputs because pins are active-low.
    //
    //    Hues (HSV at 100% sat + value):
    //      0:   Red      (1,0,0)
    //      1:   Yellow   (1,1,0)
    //      2:   Green    (0,1,0)
    //      3:   Cyan     (0,1,1)
    //      4:   Blue     (0,0,1)
    //      5:   Magenta  (1,0,1)
    //------------------------------------------------------------
    reg rgb_r;
    reg rgb_g;
    reg rgb_b;

    always @(*) begin
        case (hue_index)
            3'd0: {rgb_r, rgb_g, rgb_b} = 3'b100; // Red
            3'd1: {rgb_r, rgb_g, rgb_b} = 3'b110; // Yellow
            3'd2: {rgb_r, rgb_g, rgb_b} = 3'b010; // Green
            3'd3: {rgb_r, rgb_g, rgb_b} = 3'b011; // Cyan
            3'd4: {rgb_r, rgb_g, rgb_b} = 3'b001; // Blue
            3'd5: {rgb_r, rgb_g, rgb_b} = 3'b101; // Magenta
            default: {rgb_r, rgb_g, rgb_b} = 3'b000; // Off
        endcase
    end

    //------------------------------------------------------------
    // 3) Drive the actual RGB LED pins (active-low!).
    //    If rgb_r=1 means "Red On," we must drive the pin LOW => ~rgb_r.
    //------------------------------------------------------------
    assign RGB_R = ~rgb_r;
    assign RGB_G = ~rgb_g;
    assign RGB_B = ~rgb_b;

endmodule