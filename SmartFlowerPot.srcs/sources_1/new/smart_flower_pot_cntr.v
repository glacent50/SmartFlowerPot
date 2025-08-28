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

module sfa_i2c_lcd_text_cntr(
    input clk, reset_p,
    input text_start,              // 텍스트 출력 시작 신호
    input clear_start,             // 화면 지우기 시작 신호
    input smile_start,             // "Smile Face" 출력 시작 신호
    output scl, sda,
    output reg text_done,          // 텍스트 출력 완료 신호
    output reg clear_done,         // 화면 지우기 완료 신호
    output reg smile_done,         // "Smile Face" 출력 완료 신호
    output reg init_done          // 초기화 완료 신호
);

    // I2C LCD 전송 모듈 인스턴스화
    reg [7:0] send_buffer;
    reg send, rs;
    wire busy;
    
    i2c_lcd_send_byte send_byte(
        .clk(clk), .reset_p(reset_p),
        .addr(7'h27), .send_buffer(send_buffer),
        .send(send), .rs(rs),
        .scl(scl), .sda(sda), .busy(busy), .led()
    );

    // "Hello World" 문자열 정의
    reg [7:0] hello_string [0:10];
    initial begin
        hello_string[0] = "H"; hello_string[1] = "e"; hello_string[2] = "l"; 
        hello_string[3] = "l"; hello_string[4] = "o"; hello_string[5] = " ";
        hello_string[6] = "W"; hello_string[7] = "o"; hello_string[8] = "r"; 
        hello_string[9] = "l"; hello_string[10] = "d";
    end

    // "Smile Face" 문자열 정의
    reg [7:0] smile_string [0:9];
    initial begin
        smile_string[0] = "S"; smile_string[1] = "m"; smile_string[2] = "i"; 
        smile_string[3] = "l"; smile_string[4] = "e"; smile_string[5] = " ";
        smile_string[6] = "F"; smile_string[7] = "a"; smile_string[8] = "c"; 
        smile_string[9] = "e";
    end

    // FSM 상태 정의
    localparam IDLE = 4'b0000;
    localparam INIT = 4'b0001;
    localparam SEND_STRING = 4'b0011;
    localparam CLEAR_DISPLAY = 4'b0100;
    localparam SEND_SMILE = 4'b0101;

    reg [3:0] state, next_state;
    reg [3:0] char_index;      // 문자열 인덱스 (0~10)
    reg [2:0] init_index;      // 초기화 명령 인덱스
    reg [31:0] cnt_data;       // 초기화용 카운터
    reg [3:0] max_char_index;  // 현재 문자열의 최대 인덱스
    reg next_action;           // 다음에 수행할 동작 (0: Hello World, 1: Smile Face)
    // init_done은 이제 output으로 선언됨

    // 초기화 명령 (HD44780 표준)
    reg [7:0] init_cmds [0:5];
    initial begin
        init_cmds[0] = 8'h33;  // Function set: 8-bit mode
        init_cmds[1] = 8'h32;  // Function set: 4-bit mode
        init_cmds[2] = 8'h28;  // Function set: 4-bit, 2 line, 5x8 dots
        init_cmds[3] = 8'h0c;  // Display control: Display on, cursor off
        init_cmds[4] = 8'h01;  // Clear display
        init_cmds[5] = 8'h06;  // Entry mode set: Increment cursor
    end

    // 상태 전이
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) state = IDLE;
        else state = next_state;
    end

    // FSM 로직
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            next_state = IDLE;
            send = 0;
            rs = 0;
            char_index = 0;
            init_index = 0;
            cnt_data = 0;
            max_char_index = 0;
            next_action = 0;
            init_done = 0;
            text_done = 0;
            clear_done = 0;
            smile_done = 0;
        end else begin
            case (state)
                IDLE: begin
                    // 완료 신호들을 일정 시간 후 리셋
                    if (text_done || clear_done || smile_done) begin
                        text_done = 0;
                        clear_done = 0;
                        smile_done = 0;
                    end
                    
                    if (!init_done) begin
                        // 초기화 대기 (80ms)
                        if (cnt_data < 32'd8_000_000) begin
                            cnt_data = cnt_data + 1;
                        end else begin
                            next_state <= INIT;
                            cnt_data = 0;
                        end
                    end 
                    else begin
                        // 초기화 완료 후 명령 대기
                        if (text_start) begin
                            char_index = 0;
                            max_char_index = 11; // "Hello World" 길이
                            next_action = 0; // Hello World 출력 예정
                            next_state = SEND_STRING;
                        end 
                        else if (clear_start) begin
                            next_state = CLEAR_DISPLAY;
                        end 
                        else if (smile_start) begin
                            char_index = 0;
                            max_char_index = 10; // "Smile Face" 길이
                            next_action = 1; // Smile Face 출력 예정
                            next_state = SEND_SMILE;
                        end
                    end
                end
                
                INIT: begin
                    if (busy) begin
                        send = 0;
                        if (init_index >= 6) begin
                            next_state = IDLE;
                            init_index = 0;
                            init_done = 1;
                        end
                    end 
                    else if (!send) begin
                        rs = 0;  // 명령 모드
                        send_buffer = init_cmds[init_index];
                        send = 1;
                        init_index = init_index + 1;
                    end
                end
                
               SEND_STRING: begin
                    if (busy) begin
                        send = 0;
                        if (char_index >= max_char_index) begin  // 문자열 전송 완료
                            next_state = IDLE;
                            char_index = 0;
                            text_done = 1;
                        end
                    end else if (!send) begin
                        rs = 1;  // 데이터 모드
                        send_buffer = hello_string[char_index];
                        send = 1;
                        char_index = char_index + 1;
                    end
                end
                
                SEND_SMILE: begin
                    if (busy) begin
                        send = 0;
                        if (char_index >= max_char_index) begin  // "Smile Face" 전송 완료
                            next_state = IDLE;
                            char_index = 0;
                            smile_done = 1;
                        end
                    end else if (!send) begin
                        rs = 1;  // 데이터 모드
                        send_buffer = smile_string[char_index];
                        send = 1;
                        char_index = char_index + 1;
                    end
                end
                
                CLEAR_DISPLAY: begin
                    if (busy) begin
                        send = 0;
                        next_state = IDLE;
                        clear_done = 1;
                    end 
                    else if (!send) begin
                        rs = 0;  // 명령 모드
                        send_buffer = 8'h01; // Clear Display 명령
                        send = 1;
                    end
                end
            endcase
        end
    end
endmodule
