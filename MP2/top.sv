//////////////////////////////////////////////////////////
// Filename: top.sv
// Description: Top-level module for iceBlinkPico (iCE40UP5K-SG48)
//              that cycles the on-board RGB LED once per second.
// Toolchain: OSS CAD Suite / Yosys + nextpnr-ice40 + icepack
//////////////////////////////////////////////////////////

module top (
    //------------------------------------------------------
    // I/O matching your .pcf pin assignments
    //------------------------------------------------------
    input  logic clk,     // 12 MHz clock on pin 20
    input  logic SW,      // Active-low switch on pin 38
    input  logic BOOT,    // Active-low boot button on pin 9 (unused here)
    output logic LED,     // On-board LED (active-low) on pin 42
    output logic RGB_R,   // On-board Red LED (active-low) on pin 41
    output logic RGB_G,   // On-board Green LED (active-low) on pin 40
    output logic RGB_B    // On-board Blue LED (active-low) on pin 39
);

    //------------------------------------------------------
    // 1) Generate a hue angle that makes a full sweep
    //    (0..359 degrees) in exactly 1 second.
    //------------------------------------------------------
    // The board provides a 12 MHz clock; 12e6 cycles/second.
    // We'll increment the hue 360 times per second => 1 deg/ms.
    //
    //    ANGLE_COUNT_MAX = 12_000_000 / 360 = 33_333.3...
    // We'll use integer division and floor, which is fine.
    //------------------------------------------------------
    parameter int CLK_FREQ_HZ   = 12_000_000;
    parameter int STEPS_PER_SEC = 360;
    localparam int ANGLE_COUNT_MAX = CLK_FREQ_HZ / STEPS_PER_SEC;

    // Counter and angle
    logic [$clog2(ANGLE_COUNT_MAX)-1:0] angle_count;
    logic [8:0] hue_angle; // Enough bits for [0..359]

    always_ff @(posedge clk or negedge SW) begin
        if (!SW) begin
            // Use the switch as an asynchronous reset
            angle_count <= '0;
            hue_angle   <= '0;
        end
        else begin
            if (angle_count == (ANGLE_COUNT_MAX - 1)) begin
                angle_count <= '0;
                // Once we hit 359, wrap back to 0
                if (hue_angle == 359)
                    hue_angle <= 0;
                else
                    hue_angle <= hue_angle + 1;
            end
            else begin
                angle_count <= angle_count + 1;
            end
        end
    end

    //------------------------------------------------------
    // 2) Convert HSV -> RGB
    //    For S=1, V=1, compute 8-bit R, G, B from [0..359].
    //------------------------------------------------------
    // We'll use a piecewise function for “rainbow” transitions.
    // Alternatively, you could implement a lookup table, etc.
    //------------------------------------------------------
    function automatic [23:0] hsv_to_rgb_8bit (input int h);
        // h is in [0..359], full saturation, full brightness
        // Return packed {R[7:0], G[7:0], B[7:0]}
        logic [15:0] remainder, p, q, t, v;

        remainder = h % 60;
        p         = 16'd0;
        q         = 16'd255 - (remainder * 16'd255) / 16'd60;
        t         = (remainder * 16'd255) / 16'd60;
        v         = 16'd255;

        int r, g, b;
        logic [2:0] seg;
        seg = (h / 60) % 6;
        case (seg)
            0: begin r = v; g = t; b = p; end
            1: begin r = q; g = v; b = p; end
            2: begin r = p; g = v; b = t; end
            3: begin r = p; g = q; b = v; end
            4: begin r = t; g = p; b = v; end
            5: begin r = v; g = p; b = q; end
            default: begin r = 0; g = 0; b = 0; end
        endcase

        hsv_to_rgb_8bit = {r[7:0], g[7:0], b[7:0]};
    endfunction

    logic [7:0] red_val, green_val, blue_val;

    always_comb begin
        {red_val, green_val, blue_val} = hsv_to_rgb_8bit(hue_angle);
    end

    //------------------------------------------------------
    // 3) PWM Generation
    //------------------------------------------------------
    // We'll use an 8-bit counter and compare red_val, etc.
    // Because the board's RGB pins are active-low, we'll invert
    // the output signals to turn the LED on when the comparator is true.
    //------------------------------------------------------
    logic [7:0] pwm_counter;

    always_ff @(posedge clk or negedge SW) begin
        if (!SW)
            pwm_counter <= 8'd0;
        else
            pwm_counter <= pwm_counter + 1'b1;
    end

    // Compare each color's intensity to the PWM counter
    always_comb begin
        // "On" internally means (pwm_counter < color_val).
        // But the hardware pins are active-low, so invert.
        RGB_R = ~(pwm_counter < red_val);
        RGB_G = ~(pwm_counter < green_val);
        RGB_B = ~(pwm_counter < blue_val);
    end

    //------------------------------------------------------
    // 4) Single LED (active-low)
    //------------------------------------------------------
    // We’ll keep it off by driving it high
    // (feel free to tie it to some logic if you want).
    //------------------------------------------------------
    assign LED = 1'b1; 

endmodule
