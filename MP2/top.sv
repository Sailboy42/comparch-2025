module top(
  input  logic clk,         // 12 MHz clock
  output logic RGB_R,       // Red output (active low)
  output logic RGB_G,       // Green output (active low)
  output logic RGB_B        // Blue output (active low)
);

  // Parameters: for a 1-second color cycle with 360 steps at 12 MHz.
  parameter int CLK_FREQ = 12000000;
  parameter int STEPS    = 360;
  localparam int ANGLE_MAX = CLK_FREQ / STEPS;  // ~33333 cycles per hue step

  // Internal signals
  logic [15:0] angle_count;
  logic [8:0]  hue_angle;
  logic [7:0]  pwm_counter;
  logic [7:0]  red_val, green_val, blue_val;

  // Generate hue angle: Increment after ANGLE_MAX cycles, wrap at 359.
  always_ff @(posedge clk) begin
    if (angle_count == ANGLE_MAX - 1) begin
      angle_count <= 0;
      hue_angle   <= (hue_angle == 359) ? 0 : hue_angle + 1;
    end else begin
      angle_count <= angle_count + 1;
    end
  end

  // HSV-to-RGB conversion (piecewise linear)
  always_comb begin
    if (hue_angle < 120) begin
      red_val   = 8'd255 - (hue_angle * 8'd255) / 120;
      green_val = (hue_angle * 8'd255) / 120;
      blue_val  = 8'd0;
    end else if (hue_angle < 240) begin
      red_val   = 8'd0;
      green_val = 8'd255 - ((hue_angle - 120) * 8'd255) / 120;
      blue_val  = ((hue_angle - 120) * 8'd255) / 120;
    end else begin
      red_val   = ((hue_angle - 240) * 8'd255) / 120;
      green_val = 8'd0;
      blue_val  = 8'd255 - ((hue_angle - 240) * 8'd255) / 120;
    end
  end

  // 8-bit PWM counter
  always_ff @(posedge clk)
    pwm_counter <= pwm_counter + 1;

  // Generate active-low PWM outputs based on PWM comparison.
  assign RGB_R = (pwm_counter < red_val)   ? 1'b0 : 1'b1;
  assign RGB_G = (pwm_counter < green_val) ? 1'b0 : 1'b1;
  assign RGB_B = (pwm_counter < blue_val)  ? 1'b0 : 1'b1;

endmodule