`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2025 07:11:14 PM
// Design Name: 
// Module Name: smart_flower_pot_cntr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sfp_led_rgb_cntr (
    input clk, reset_p,
    input [2:0] color_sel, // 색상 선택 (예: 3비트, 0: Red, 1: Green, 2: Blue, 3: Yellow, 4: Cyan, 5: Magenta, 6: White)
    output reg led_r,
    output reg led_g,
    output reg led_b
);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p) begin
            led_r = 0; led_g = 0; led_b = 0;
        end else begin
            case (color_sel)
                3'b000: begin led_r = 1; led_g = 0; led_b = 0; end // Red
                3'b001: begin led_r = 0; led_g = 1; led_b = 0; end // Green
                3'b010: begin led_r = 0; led_g = 0; led_b = 1; end // Blue
                3'b011: begin led_r = 1; led_g = 1; led_b = 0; end // Yellow (Red + Green)
                3'b100: begin led_r = 0; led_g = 1; led_b = 1; end // Cyan (Green + Blue)
                3'b101: begin led_r = 1; led_g = 0; led_b = 1; end // Magenta (Red + Blue)
                3'b110: begin led_r = 1; led_g = 1; led_b = 1; end // White (Red + Green + Blue)
                default: begin led_r = 0; led_g = 0; led_b = 0; end // 모두 꺼짐
            endcase
        end
    end

endmodule


module sfp_buzz_cntr (
    input clk, reset_p,     // 시스템 클럭
    input buzz_e,           // 부저 ON/OFF 제어
    output reg buzz         // 부저 출력 핀
);

    always @(posedge clk, posedge reset_p) begin
        if (reset_p)
            buzz = 1'b0;
        else begin
            if (buzz_e)
                buzz = 1'b1;    // 부저 ON
            else
                buzz = 1'b0;    // 부저 OFF
        end
    end

endmodule








