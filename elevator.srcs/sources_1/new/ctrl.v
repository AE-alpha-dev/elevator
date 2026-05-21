// 系统开关模块
module sys_pwr_ctrl (
    input  wire clk       ,
    input  wire rst_n     ,
    input  wire touch_key ,
    output wire sys_en    ,   
    output wire boot_en 
);    

    parameter OFF     = 3'b001;
    parameter BOOTING = 3'b010;
    parameter ON      = 3'b100;
    parameter MAX_CNT_1S = 26'd49_999_999;

    reg  [2:0]  current_state, next_state;
    reg  [25:0] cnt_1s;
    reg         touch_d1;
    reg         touch_d2;
    reg         touch_d3;

    wire        tick_1s; 
    wire        touch_pulse;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            touch_d1 <= 1'b0;
            touch_d2 <= 1'b0;
            touch_d3 <= 1'b0;
        end
        else begin
            touch_d1 <= touch_key;  // 可能亚稳态，不参与逻辑
            touch_d2 <= touch_d1;   // 亚稳态已消解
            touch_d3 <= touch_d2;   // 用于边沿检测
        end
    end

    assign touch_pulse = touch_d2 & (~touch_d3); // 触摸键高电平有效，这里抓取其上升沿

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= OFF; 
        else 
            current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state; 
        case (current_state)
            OFF     : if (touch_pulse) next_state = BOOTING;
            BOOTING : if (tick_1s)     next_state = ON;
            ON      : if (touch_pulse) next_state = OFF;
            default :                  next_state = OFF;
        endcase
    end

    assign sys_en  = (current_state == ON);     
    assign boot_en = (current_state == BOOTING); 
    assign tick_1s = (cnt_1s == MAX_CNT_1S);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            cnt_1s <= 26'd0; 
        end 
        else if (boot_en) begin 
            if (tick_1s) 
                cnt_1s <= 26'd0;
            else 
                cnt_1s <= cnt_1s + 1'b1;
        end 
        else begin 
            cnt_1s <= 26'd0; 
        end
    end

endmodule
