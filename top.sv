module top(
    input  wire clk,    // 12 MHz clock on pin 20
    output wire LED,    // single orange LED, active low
    output wire RGB_R,  // red pin of RGB LED, active low
    output wire RGB_G,  // green pin of RGB LED, active low
    output wire RGB_B   // blue pin of RGB LED, active low
);
    //
    // 1) 24-bit counter for ~1 second at 12 MHz (12e6 cycles)
    //    We'll use this to toggle the single LED and to
    //    advance an index for the RGB LED.
    //
    localparam CLOCK_FREQ = 12_000_000;
    reg [23:0] counter = 24'd0;
    reg        led_state = 1'b1; // track single LED (1=off, 0=on)
    reg [2:0]  hue_index = 3'd0; // track which color for RGB LED

    always @(posedge clk) begin
        if (counter < (CLOCK_FREQ - 1)) begin
            counter <= counter + 1;
        end else begin
            counter <= 24'd0;
            // toggle single LED once each second
            led_state <= ~led_state;

            // cycle hue_index 0..5
            if (hue_index == 3'd5)
                hue_index <= 3'd0;
            else
                hue_index <= hue_index + 1;
        end
    end

    //
    // 2) Map hue_index to an RGB combination.
    //    Remember, '1' means LED off because these pins are active-low!
    //    So if we want the Red LED on, we must drive RGB_R = 0.
    //
    reg [2:0] rgb_l;

    always @(*) begin
        // We'll treat 'rgb_l=1' as "LED ON internally," but we invert below.
        case (hue_index)
            3'd0: rgb_l = 3'b100; // Red
            3'd1: rgb_l = 3'b110; // Yellow
            3'd2: rgb_l = 3'b010; // Green
            3'd3: rgb_l = 3'b011; // Cyan
            3'd4: rgb_l = 3'b001; // Blue
            3'd5: rgb_l = 3'b101; // Magenta
            default: rgb_l = 3'b000; // all off
        endcase
    end

    //
    // 3) Assign outputs (active-low!)
    //    Single LED: led_state=0 means lit, so we assign LED = ~led_state.
    //    For RGB, if rgb_l=1, that means we want it on, so we assign pin=0.
    //
    assign LED   = led_state;          // '1'=off, '0'=on (already active-low logic)
    assign RGB_R = ~rgb_l[2];         // invert because hardware is active-low
    assign RGB_G = ~rgb_l[1];
    assign RGB_B = ~rgb_l[0];

endmodule