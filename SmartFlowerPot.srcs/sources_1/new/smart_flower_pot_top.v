`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/26/2025 12:15:02 PM
// Design Name: 
// Module Name: smart_flower_pot_top
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

module smart_flower_pot_top(
    input clk, reset_p,
    inout dht11_data,
    input vauxp6,vauxn6,              // Auxiliary channel 6
    input [3:0] btn,
    output [7:0] seg_7,
    output [3:0] com,
    output reg [15:0] led,
    output led_r, led_g, led_b,
    output buzz);

    // DHT11 센서를 제어하여 습도와 온도를 읽어오는 모듈
    wire [7:0] humidity, temperature;
    dht11_cntr dht11(
        .clk(clk), .reset_p(reset_p),
        .dht11_data(dht11_data),
        .humidity(humidity), .temperature(temperature));
    
    // 8비트 와이어를 선언하여 습도와 온도를 BCD 형식으로 저장
    // fnd_cntr 모듈을 인스턴스화하여 결합된 BCD 값을 7-세그먼트 디스플레이로 제어
    wire [7:0] humi_bcd, tmpr_bcd;
    bin_to_dec bcd_humi(.bin(humidity), .bcd(humi_bcd));
    bin_to_dec bcd_tmpr(.bin(temperature), .bcd(tmpr_bcd));   
    fnd_cntr fnd(.clk(clk), .reset_p(reset_p),
        .fnd_value({humi_bcd, tmpr_bcd}),
        .hex_bcd(1),
        .seg_7(seg_7), .com(com));


    // 워터센서를 사용하여 물 높이 조절. 
    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out;

    xadc_wiz_0 adc
          (
          .daddr_in({2'b00, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk)                 ,             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),                           // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),                         // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),                            // Auxiliary channel 6
          .vauxn6(vauxn6),
          .channel_out(channel_out),                  // Channel Selection Outputs
          .do_out(do_out),                            // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out)                          // End of Conversion Signal
          );

    reg [11:0] adc_value;
    wire eoc_pedge;
    edge_detector_p echo_ed(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(eoc_out),
        .p_edge(eoc_pedge)
    );
    
    //   수위 센서  0 ~ 30 : step 1
    //           31 ~ 40 : step 2 (W 글자)
    //           41 ~ 50 : step 3 (S 글자)
    //           51 ~ 55 : step 4 (O 글자)       
    
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) adc_value = 0;
        else if (eoc_pedge) begin
            adc_value = do_out[15:8];

            if ( adc_value <= 10) begin
                led = 16'b0000_0000_0000_0000;
            end
            else if ( adc_value <= 30) begin
                led = 16'b0000_0000_0000_1111; //step 1
            end
            else if (adc_value <= 40) begin
                led = 16'b0000_0000_1111_1111; //step 2
            end
            else if (adc_value <= 50) begin
                led = 16'b0000_1111_1111_1111; //step 3
            end
            else begin
                led = 16'b1111_1111_1111_1111; //step 4
            end
        end
    end

    // 부저 제어 모듈
    reg  buzz_enable; // 부저 활성화 신호를 저장하는 레지스터
    wire buzz_out; // 부저 출력 신호
    sfp_buzz_cntr buzz_inst ( // 부저 제어 모듈 인스턴스화 (클럭, 리셋, 활성화 신호를 받아 부저 출력 제어)
        .clk     (clk),
        .reset_p (reset_p),
        .buzz_e  (buzz_enable),
        .buzz    (buzz_out)
    );
    assign buzz = buzz_out; // 부저 출력 신호를 상위 모듈에 연결 (최종 출력)

    // RGB LED 제어 (RGB LED의 색상을 선택하고 출력 신호를 제어)
    reg  [2:0] color_sel; // 색상 선택 신호 (3비트)
    wire led_r_out, led_g_out, led_b_out; // RGB LED 출력 신호
    sfp_led_rgb_cntr led_rgb_inst ( // RGB LED 제어 모듈 인스턴스화
        .clk       (clk),        
        .reset_p   (reset_p),    
        .color_sel (color_sel),  
        .led_r     (led_r_out),  
        .led_g     (led_g_out),  
        .led_b     (led_b_out)   
    );
    assign led_r = led_r_out; // Red LED 출력 신호 연결
    assign led_g = led_g_out; // Green LED 출력 신호 연결
    assign led_b = led_b_out; // Blue LED 출력 신호 연결

    // 버튼 입력의 상승 에지 검출 신호 [기능 테스트 용도]
    wire [3:0] btn_pedge; 
    btn_cntr btn0(clk, reset_p, btn[0], btn_pedge[0]);
    btn_cntr btn1(clk, reset_p, btn[1], btn_pedge[1]);
    btn_cntr btn2(clk, reset_p, btn[2], btn_pedge[2]);
    btn_cntr btn3(clk, reset_p, btn[3], btn_pedge[3]);
    
    // 버튼 눌림 상태를 확인하는 always 블록
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            // 리셋 로직
            buzz_enable <= 1'b0;
            //color_sel <= 3'd6; // sfp_led_rgb_cntr 에서 reset 시 off 됨. 
        end else begin
            if (btn_pedge[0]) begin
                // 버튼 0 눌림 동작: 부저 토글
                buzz_enable <= ~buzz_enable;
            end
            if (btn_pedge[1]) begin
                // 버튼 1 눌림 동작: RGB LED를 노란색으로 설정
                // 색상 선택 (예: 3비트, 0: Red, 1: Green, 2: Blue, 3: Yellow, 4: Cyan, 5: Magenta, 6: White)
                color_sel <= 3'd2; // 2은 Blue에 해당
            end
            if (btn_pedge[2]) begin
                // 버튼 2 눌림 동작
                color_sel <= 3'd1; // 1은 Green에 해당
            end
            if (btn_pedge[3]) begin
                // 버튼 3 눌림 동작
                color_sel <= 3'd0; // 1은 Green에 해당
            end
        end
    end
    
    // i2c_lcd_text 문자 출력 로직 추가작성 필요 : switch 버튼으로 처리.
    
endmodule







