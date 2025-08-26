`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2025 04:45:32 PM
// Design Name: 
// Module Name: water_sensor
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


// module water_level_display_case (
//     input clk,
//     input reset_p,
//     input [1:0] water_level, // 00, 01, 10, 11 (2비트 수위 입력)
//     output reg [2:0] led
// );

//     always @(posedge clk or posedge reset_p) begin
//         if (reset_p) begin
//             led <= 3'b000;
//         end 
//         else begin
//             case (water_level)
//                 2'b00: led <= 3'b000; // 매우 낮음
//                 2'b01: led <= 3'b001; // LOW
//                 2'b10: led <= 3'b011; // MID
//                 2'b11: led <= 3'b111; // HIGH
//                 default: led <= 3'b000;
//             endcase
//         end
//     end

// endmodule

module water_level_single_pin(
    input clk,
    input reset_p,
    input sensor_in,
    output reg [2:0] led
);

    localparam THRESHOLD_LOW  = 1000;
    localparam THRESHOLD_MID  = 3000;
    localparam THRESHOLD_HIGH = 6000;

    reg [31:0] high_counter;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            high_counter <= 0;
            led <= 3'b000;
        end else begin
            if (sensor_in) begin
                // 센서 신호가 HIGH면 카운트 증가
                high_counter <= high_counter + 1;
            end else begin
                // 센서 신호가 LOW면 카운터 초기화
                high_counter <= 0;
            end

            // 카운터 값에 따라 LED 단계 결정
            if (high_counter == 0) begin
                led <= 3'b000;        // 물 안 닿음
            end else if (high_counter < THRESHOLD_LOW) begin
                led <= 3'b001;        // 조금 닿음
            end else if (high_counter < THRESHOLD_MID) begin
                led <= 3'b011;        // 반쯤 닿음
            end else if (high_counter >= THRESHOLD_MID) begin
                led <= 3'b111;        // 완전히 닿음
            end
        end
    end
endmodule
