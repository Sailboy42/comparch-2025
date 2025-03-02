module top (
    input  logic clk,    // 12 MHz clock
    input  logic SW,     // Active-low reset
    input  logic BOOT,   // Unused
    output logic LED,    // Active-low single LED
    output logic RGB_R,  // Active-low Red
    output logic RGB_G,  // Active-low Green
    output logic RGB_B   // Active-low Blue
);

    // Generate hue_angle [0..359] over 1 second @12MHz
    parameter int  CLK_FREQ_HZ   = 12_000_000;
    parameter int  STEPS_PER_SEC = 360;
    localparam int ANGLE_COUNT_MAX = CLK_FREQ_HZ / STEPS_PER_SEC;

    logic [$clog2(ANGLE_COUNT_MAX)-1:0] angle_count;
    logic [8:0] hue_angle;

    always_ff @(posedge clk or negedge SW) begin
        if (!SW) begin
            angle_count <= '0;
            hue_angle   <= '0;
        end 
        else begin
            if (angle_count == ANGLE_COUNT_MAX - 1) begin
                angle_count <= '0;
                hue_angle <= (hue_angle == 359) ? 0 : hue_angle + 1;
            end 
            else begin
                angle_count <= angle_count + 1;
            end
        end
    end

    // HSV->RGB
    logic [7:0] red_val, green_val, blue_val;
    always_comb begin
        {red_val, green_val, blue_val} = hsv_to_rgb_8bit(hue_angle);
    end

    // PWM
    logic [7:0] pwm_counter;
    always_ff @(posedge clk or negedge SW) begin
        if (!SW) pwm_counter <= 8'd0;
        else     pwm_counter <= pwm_counter + 1;
    end

    always_comb begin
        // Active-low outputs
        RGB_R = ~(pwm_counter < red_val);
        RGB_G = ~(pwm_counter < green_val);
        RGB_B = ~(pwm_counter < blue_val);
    end

    // Keep the single LED off
    assign LED = 1'b1;

    // Simplified HSV->RGB function
    function [23:0] hsv_to_rgb_8bit (input logic [8:0] h);
        logic [2:0] seg;
        logic [7:0] r, g, b;
        logic [7:0] remainder;
        logic [7:0] t_val, q_val;

        seg       = (h / 60) % 6;
        remainder = h % 60;
        t_val     = (remainder * 8'd255) / 8'd60;
        q_val     = 8'd255 - t_val;

        case (seg)
            3'd0: {r, g, b} = {8'd255,   t_val,   8'd0};
            3'd1: {r, g, b} = {  q_val,  8'd255,  8'd0};
            3'd2: {r, g, b} = {8'd0,     8'd255,  t_val};
            3'd3: {r, g, b} = {8'd0,     q_val,   8'd255};
            3'd4: {r, g, b} = {  t_val,  8'd0,    8'd255};
            3'd5: {r, g, b} = {8'd255,   8'd0,    q_val};
            default: {r, g, b} = {8'd0, 8'd0, 8'd0};
        endcase

        hsv_to_rgb_8bit = {r, g, b};
    endfunction

endmodule
