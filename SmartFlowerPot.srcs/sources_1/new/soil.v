`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2025 04:18:20 PM
// Design Name: 
// Module Name: soil
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

// 간단한 확인용(토양수분센서 / DO에 연결)
module soil_moisture_monitor (
    input clk,
    input reset_p,
    input soil_sensor,  // 디지털 입력: 1 = 건조, 0 = 습함
    output reg pump_on, // 펌프 제어 출력
    output reg [15:0] led // 디버깅용 출력
);

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            pump_on <= 0;
            led <= 0;
        end else begin
            if (soil_sensor == 1'b1) begin // 건조 상태
                pump_on <= 1;
                led[0] <= 1; // LED로 상태 표시
            end else begin
                pump_on <= 0;
                led[0] <= 0;
            end
        end
    end

endmodule

