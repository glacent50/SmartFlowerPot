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
    input vauxp6,vauxn6,             
    input [3:0] btn,
    output [7:0] seg_7,
    output [3:0] com,
    output reg [15:0] led,
    output led_r, led_g, led_b,
    output buzz,
    output scl, sda);

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
      
    always @(posedge clk, posedge reset_p) begin
        if (reset_p) adc_value = 0;
        else if (eoc_pedge) begin
            adc_value = do_out[15:8];
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
    

    // I2C LCD 컨트롤러
    wire init_done;
    reg [2:0] text_cmd;  // 텍스트 명령 (1: Happy, 2: Smile, 3: Sad, 4: Normal, 5: Clear)

    sfa_i2c_lcd_text_cntr lcd_text_cntr(
        .clk(clk),
        .reset_p(reset_p),
        .text_cmd(text_cmd),
        .scl(scl),
        .sda(sda),
        .init_done(init_done) // init_done 포트 연결
    );

    // test code ...
    // 버튼 입력의 상승 에지 검출 신호 [기능 테스트 용도]
    wire [3:0] btn_pedge; 
    btn_cntr btn0(clk, reset_p, btn[0], btn_pedge[0]);
    btn_cntr btn1(clk, reset_p, btn[1], btn_pedge[1]);
    btn_cntr btn2(clk, reset_p, btn[2], btn_pedge[2]);
    btn_cntr btn3(clk, reset_p, btn[3], btn_pedge[3]);

    // 1us 단위 클럭 생성
    wire clk_usec_pedge;
    clock_div_100 us_clk(
        .clk(clk),
        .reset_p(reset_p),
        .nedge_div_100(clk_usec_pedge)
    );

    // 1ms 단위 클럭 생성
    wire clk_msec_pedge;
    clock_div_1ms ms_clk(
        .clk(clk),
        .reset_p(reset_p),
        .nedge_div_1ms(clk_msec_pedge)
    );


    // 텍스트 명령 (1: Happy, 2: Smile, 3: Sad, 4: Normal, 5: Clear)
    reg sad_clear_flag;  // Sad Face 표시를 위한 Clear 플래그
    reg [15:0] sad_delay_counter;  // Clear 명령 후 지연을 위한 카운터
    reg happy_clear_flag;  // Happy Face 표시를 위한 Clear 플래그
    reg [15:0] happy_delay_counter;  // Happy Clear 명령 후 지연을 위한 카운터
    reg smile_clear_flag;  // Smile Face 표시를 위한 Clear 플래그
    reg [15:0] smile_delay_counter;  // Smile Clear 명령 후 지연을 위한 카운터
    reg normal_clear_flag;  // Normal Face 표시를 위한 Clear 플래그
    reg [15:0] normal_delay_counter;  // Normal Clear 명령 후 지연을 위한 카운터
    


    // [수위 센서 제어 범위]  
    //            0 ~ 30 : step 1
    //           31 ~ 40 : step 2 (W 글자)
    //           41 ~ 50 : step 3 (S 글자)
    //           51 ~ 55 : step 4 (O 글자)


    // 버튼 눌림 상태를 확인하는 always 블록
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            // 리셋 로직
            buzz_enable <= 1'b0;
            text_cmd <= 5;  // Clear
            color_sel <= 3'b111;            // sfp_led_rgb_cntr 에서 reset 시 off 됨. 
            sad_clear_flag <= 1'b0;
            sad_delay_counter <= 16'd0;
            happy_clear_flag <= 1'b0;
            happy_delay_counter <= 16'd0;
            smile_clear_flag <= 1'b0;
            smile_delay_counter <= 16'd0;
            normal_clear_flag <= 1'b0;
            normal_delay_counter <= 16'd0;
        end 
        else begin
            if( clk_usec_pedge )begin
                // ---- adc_value  
                if ( adc_value <= 10) begin

                    //led = 16'b0000_0000_0000_1111; //step 1
                    // Sad Face 표시를 위한 Clear 후 Sad 표시 로직
                    if (!sad_clear_flag) begin
                        led = 16'b1111_1111_1111_0000;
                        text_cmd <= 5;  // Clear 먼저 호출
                        sad_clear_flag <= 1'b1;
                        sad_delay_counter <= 16'd0;
                    end
                    else if (sad_delay_counter < 16'd3000) begin  //2ms 지연 (2,000 us)
                        sad_delay_counter <= sad_delay_counter + 1;
                        led = 16'b0000_1111_1111_0000;
                    end
                    else begin
                        text_cmd <= 3;  // Sad Face 표시
                        led = 16'b0000_0000_0000_1111;
                    end
                    
                    happy_clear_flag <= 1'b0;
                    happy_delay_counter <= 16'd0;
                    smile_clear_flag <= 1'b0;
                    smile_delay_counter <= 16'd0;
                    normal_clear_flag <= 1'b0;
                    normal_delay_counter <= 16'd0;
                    
                end
                else if (adc_value <= 20) begin
                    // Normal Face 표시를 위한 Clear 후 Normal 표시 로직
                    if (!normal_clear_flag) begin
                        led = 16'b1111_1111_1111_0000;
                        text_cmd <= 5;  // Clear 먼저 호출
                        normal_clear_flag <= 1'b1;
                        normal_delay_counter <= 16'd0;
                    end
                    else if (normal_delay_counter < 16'd3000) begin  // 3ms 지연 (3,000 us)
                        normal_delay_counter <= normal_delay_counter + 1;
                        led = 16'b0000_1111_1111_0000;
                    end
                    else begin
                        text_cmd <= 4;  // Normal Face 표시
                        led = 16'b0000_0000_1111_1111; //step 2
                    end
                    
                    // 다른 플래그들 리셋
                    sad_clear_flag <= 1'b0;
                    sad_delay_counter <= 16'd0;
                    happy_clear_flag <= 1'b0;
                    happy_delay_counter <= 16'd0;
                    smile_clear_flag <= 1'b0;
                    smile_delay_counter <= 16'd0;
                end
                else if (adc_value <= 30) begin
                    // adc_value > 40일 때 Smile Face 표시를 위한 Clear 후 Smile 표시 로직
                    if (!smile_clear_flag) begin
                        led = 16'b1111_1111_1111_0000;
                        text_cmd <= 5;  // Clear 먼저 호출
                        smile_clear_flag <= 1'b1;
                        smile_delay_counter <= 16'd0;
                    end
                    else if (smile_delay_counter < 16'd3000) begin  // 3.5ms 지연 (3,500 us)
                        smile_delay_counter <= smile_delay_counter + 1;
                        led = 16'b0000_1111_1111_0000;
                    end
                    else begin
                        text_cmd <= 2;  // Smile Face 표시
                        led = 16'b0000_1111_1111_1111; //step 3
                    end
                    
                    // 다른 플래그들 리셋
                    sad_clear_flag <= 1'b0;
                    sad_delay_counter <= 16'd0;
                    happy_clear_flag <= 1'b0;
                    happy_delay_counter <= 16'd0;
                    normal_clear_flag <= 1'b0;
                    normal_delay_counter <= 16'd0;
                end
                else begin
                    // adc_value > 50일 때 Happy Face 표시를 위한 Clear 후 Happy 표시 로직
                    if (!happy_clear_flag) begin
                        led = 16'b1111_1111_1111_0000;
                        text_cmd <= 5;  // Clear 먼저 호출
                        happy_clear_flag <= 1'b1;
                        happy_delay_counter <= 16'd0;
                    end
                    else if (happy_delay_counter < 16'd3000) begin  // 2ms 지연 (2,000 us)
                        happy_delay_counter <= happy_delay_counter + 1;
                        led = 16'b0000_1111_1111_0000;
                    end
                    else begin
                        text_cmd <= 1;  // Happy Face 표시
                        led = 16'b1111_1111_1111_1111; //step 4
                    end
                    
                    // 다른 조건일 때 sad, smile 플래그 리셋
                    sad_clear_flag <= 1'b0;
                    sad_delay_counter <= 16'd0;
                    smile_clear_flag <= 1'b0;
                    smile_delay_counter <= 16'd0;
                    normal_clear_flag <= 1'b0;
                    normal_delay_counter <= 16'd0;
                end
            end

            // ---------------------------------------------------------------------------------
            // [테스트용 버튼 처리 로직]
        
            if (btn_pedge[0]) begin  
                buzz_enable <= ~buzz_enable;  // 부저 활성화 신호 토글 (켜짐/꺼짐 전환)
                text_cmd <= 5;                // Text Clear 먼저 호출 (LCD 텍스트 클리어 명령)
            end
            if (btn_pedge[1]) begin  
                color_sel = 3'd2;             // 색상 선택: 노란색 (sfp_led_rgb_cntr 모듈에서 Yellow)
            end
            if (btn_pedge[2]) begin  
                color_sel <= 3'd1;            // 색상 선택: 녹색 (sfp_led_rgb_cntr 모듈에서 Green)
            end
            if (btn_pedge[3]) begin  
                color_sel <= 3'd0;            // 색상 선택: 빨강 (sfp_led_rgb_cntr 모듈에서 Red)
            end
            // ---------------------------------------------------------------------------------
        end
    end
        
endmodule
