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
  logic [7:0] pwm_red;
  logic [7:0] pwm_green;
  logic [7:0] pwm_blue;
  logic [15:0] angle_count;
  logic [8:0]  hue_angle;
  logic [7:0]  pwm_counter;

    initial begin
        angle_count = 0;
        hue_angle = 0;
        pwm_counter = 0;
    end

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
  case (hue_angle / 60)
    0: begin
         // Hue: 0° to 59° – red is max, blue is min, green increases.
         pwm_red   = 255;
         pwm_green = (hue_angle * 255) / 60;
         pwm_blue  = 0;
       end
    1: begin
         // Hue: 60° to 119° – green is max, blue is min, red decreases.
         pwm_red   = 255 - (((hue_angle - 60) * 255) / 60);
         pwm_green = 255;
         pwm_blue  = 0;
       end
    2: begin
         // Hue: 120° to 179° – green is max, red is min, blue increases.
         pwm_red   = 0;
         pwm_green = 255;
         pwm_blue  = (((hue_angle - 120) * 255) / 60);
       end
    3: begin
         // Hue: 180° to 239° – blue is max, red is min, green decreases.
         pwm_red   = 0;
         pwm_green = 255 - (((hue_angle - 180) * 255) / 60);
         pwm_blue  = 255;
       end
    4: begin
         // Hue: 240° to 299° – blue is max, green is min, red increases.
         pwm_red   = (((hue_angle - 240) * 255) / 60);
         pwm_green = 0;
         pwm_blue  = 255;
       end
    5: begin
         // Hue: 300° to 359° – red is max, green is min, blue decreases.
         pwm_red   = 255;
         pwm_green = 0;
         pwm_blue  = 255 - (((hue_angle - 300) * 255) / 60);
       end
    default: begin
         // For any out-of-range values, default to black.
         pwm_red   = 0;
         pwm_green = 0;
         pwm_blue  = 0;
       end
  endcase
end

  // 8-bit PWM counter
  always_ff @(posedge clk)
    pwm_counter <= pwm_counter + 1;

  // Generate active-low PWM outputs based on PWM comparison.
  assign RGB_R = ~(pwm_counter < pwm_red);
  assign RGB_G = ~(pwm_counter < pwm_green);
  assign RGB_B = ~(pwm_counter < pwm_blue);

endmodule