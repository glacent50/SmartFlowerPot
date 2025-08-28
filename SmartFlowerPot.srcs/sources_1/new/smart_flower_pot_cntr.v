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
    input [2:0] text_cmd,          // 텍스트 명령 (1: Happy, 2: Smile, 3: Sad, 4: Normal, 5: Clear)
    output scl, sda,
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

    // "Happy Face" 문자열 정의
    reg [7:0] happy_string [0:9];
    initial begin
        happy_string[0] = "H"; happy_string[1] = "a"; happy_string[2] = "p"; 
        happy_string[3] = "p"; happy_string[4] = "y"; happy_string[5] = " ";
        happy_string[6] = "F"; happy_string[7] = "a"; happy_string[8] = "c"; 
        happy_string[9] = "e";
    end

    // "Smile Face" 문자열 정의
    reg [7:0] smile_string [0:9];
    initial begin
        smile_string[0] = "S"; smile_string[1] = "m"; smile_string[2] = "i"; 
        smile_string[3] = "l"; smile_string[4] = "e"; smile_string[5] = " ";
        smile_string[6] = "F"; smile_string[7] = "a"; smile_string[8] = "c"; 
        smile_string[9] = "e";
    end

    // "Sad Face" 문자열 정의
    reg [7:0] sad_string [0:7];
    initial begin
        sad_string[0] = "S"; sad_string[1] = "a"; sad_string[2] = "d"; 
        sad_string[3] = " "; sad_string[4] = "F"; sad_string[5] = "a"; 
        sad_string[6] = "c"; sad_string[7] = "e";
    end

    // "Normal Face" 문자열 정의
    reg [7:0] normal_string [0:10];
    initial begin
        normal_string[0] = "N"; normal_string[1] = "o"; normal_string[2] = "r"; 
        normal_string[3] = "m"; normal_string[4] = "a"; normal_string[5] = "l"; 
        normal_string[6] = " "; normal_string[7] = "F"; normal_string[8] = "a"; 
        normal_string[9] = "c"; normal_string[10] = "e";
    end

    // FSM 상태 정의 (1-hot 인코딩)
    localparam IDLE         = 7'b000_0001;  // 0: 대기 상태
    localparam INIT         = 7'b000_0010;  // 1: 초기화 상태  
    localparam SEND_HAPPY   = 7'b000_0100;  // 2: Happy Face 전송 상태
    localparam CLEAR_DISPLAY= 7'b000_1000;  // 3: 화면 지우기 상태
    localparam SEND_SMILE   = 7'b001_0000;  // 4: Smile Face 전송 상태
    localparam SEND_SAD     = 7'b010_0000;  // 5: Sad Face 전송 상태
    localparam SEND_NORMAL  = 7'b100_0000;  // 6: Normal Face 전송 상태

    reg [6:0] state, next_state;
    reg [3:0] char_index;      // 문자열 인덱스 (0~10)
    reg [2:0] init_index;      // 초기화 명령 인덱스
    reg [31:0] cnt_data;       // 초기화용 카운터
    reg [3:0] max_char_index;  // 현재 문자열의 최대 인덱스
    reg [2:0] text_cmd_prev;   // 이전 text_cmd 값 저장 (엣지 감지용)
    wire text_cmd_edge;        // text_cmd 변화 감지 신호
    
    // 내부 완료 신호들 (외부 포트에서 내부 변수로 변경)
    reg happy_done;            // Happy Face 출력 완료 신호
    reg clear_done;            // 화면 지우기 완료 신호
    reg smile_done;            // "Smile Face" 출력 완료 신호
    reg sad_done;              // "Sad Face" 출력 완료 신호
    reg normal_done;           // "Normal Face" 출력 완료 신호

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

    // text_cmd 엣지 감지 로직
    assign text_cmd_edge = (text_cmd != text_cmd_prev) && (text_cmd != 3'b000);

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
            text_cmd_prev = 0;
            init_done = 0;
            happy_done = 0;
            clear_done = 0;
            smile_done = 0;
            sad_done = 0;
            normal_done = 0;
        end else begin
            // text_cmd 이전 값 업데이트 (엣지 감지용)
            text_cmd_prev <= text_cmd;
            
            case (state)
                IDLE: begin
                    // 완료 신호들을 일정 시간 후 리셋
                    if (happy_done || clear_done || smile_done || sad_done || normal_done) begin
                        happy_done = 0;
                        clear_done = 0;
                        smile_done = 0;
                        sad_done = 0;
                        normal_done = 0;
                    end
                    
                    if (!init_done) begin
                        // 초기화 대기 (80ms)
                        if (cnt_data < 32'd8_000_000) begin
                            cnt_data = cnt_data + 1;
                        end else begin
                            next_state = INIT;
                            cnt_data = 0;
                        end
                    end 
                    else begin
                        // 초기화 완료 후 명령 대기
                        if (text_cmd_edge) begin
                            case (text_cmd)
                                3'b001: begin // Happy Face
                                    char_index = 0;
                                    max_char_index = 10;
                                    next_state = SEND_HAPPY;
                                end
                                3'b010: begin // Smile Face
                                    char_index = 0;
                                    max_char_index = 10;
                                    next_state = SEND_SMILE;
                                end
                                3'b011: begin // Sad Face
                                    char_index = 0;
                                    max_char_index = 8;
                                    next_state = SEND_SAD;
                                end
                                3'b100: begin // Normal Face
                                    char_index = 0;
                                    max_char_index = 11;
                                    next_state = SEND_NORMAL;
                                end
                                3'b101: begin // Clear Display
                                    next_state = CLEAR_DISPLAY;
                                end
                                default: begin
                                    // 잘못된 명령이거나 0인 경우 아무 동작 안함
                                end
                            endcase
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
                
               SEND_HAPPY: begin
                    if (busy) begin
                        send = 0;
                        if (char_index >= max_char_index) begin  // 문자열 전송 완료
                            next_state = IDLE;
                            char_index = 0;
                            happy_done = 1;
                        end
                    end else if (!send) begin
                        rs = 1;  // 데이터 모드
                        send_buffer = happy_string[char_index];
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
                
                SEND_SAD: begin
                    if (busy) begin
                        send = 0;
                        if (char_index >= max_char_index) begin  // "Sad Face" 전송 완료
                            next_state = IDLE;
                            char_index = 0;
                            sad_done = 1;
                        end
                    end else if (!send) begin
                        rs = 1;  // 데이터 모드
                        send_buffer = sad_string[char_index];
                        send = 1;
                        char_index = char_index + 1;
                    end
                end
                
                SEND_NORMAL: begin
                    if (busy) begin
                        send = 0;
                        if (char_index >= max_char_index) begin  // "Normal Face" 전송 완료
                            next_state = IDLE;
                            char_index = 0;
                            normal_done = 1;
                        end
                    end else if (!send) begin
                        rs = 1;  // 데이터 모드
                        send_buffer = normal_string[char_index];
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
