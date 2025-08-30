`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/18/2025 10:19:42 AM
// Design Name: 
// Module Name: clock_library
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


module clock_div_100(
    input clk, reset_p,
    output reg clk_div_100,
    output nedge_div_100, pedge_div_100);
    
    reg [5:0] cnt_sysclk;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            clk_div_100 = 0;
        end
        else begin
            if(cnt_sysclk >= 49)begin
                cnt_sysclk = 0;
                clk_div_100 = ~clk_div_100;
            end
            else cnt_sysclk = cnt_sysclk + 1;
        end
    end
    
    edge_detector_p cl_ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div_100),
        .p_edge(pedge_div_100), .n_edge(nedge_div_100));
    
endmodule

//입력 100 MHz(10 ns)일 때, clk_div_100은 50클럭마다 토글하므로 전체 주기는 100클럭(1 μs), 
//출력 주파수는 1 MHz입니다.


module clock_div_1ms(
    input clk, reset_p,
    output reg clk_div_1ms,
    output nedge_div_1ms, pedge_div_1ms);
    
    reg [15:0] cnt_sysclk;  // 16비트로 확장 (50,000까지 카운트)
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            cnt_sysclk = 0;
            clk_div_1ms = 0;
        end
        else begin
            if(cnt_sysclk >= 49999)begin  // 50,000 클럭마다 토글 (0~49999)
                cnt_sysclk = 0;
                clk_div_1ms = ~clk_div_1ms;
            end
            else cnt_sysclk = cnt_sysclk + 1;
        end
    end
    
    edge_detector_p cl_ed_1ms(
        .clk(clk), .reset_p(reset_p), .cp(clk_div_1ms),
        .p_edge(pedge_div_1ms), .n_edge(nedge_div_1ms));
    
endmodule




