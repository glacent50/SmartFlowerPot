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
