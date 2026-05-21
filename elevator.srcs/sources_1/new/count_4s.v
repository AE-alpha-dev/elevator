// 4Ãë¼ÆÊ±Æ÷Ä£¿é
module timer_ctrl (
    input  wire       clk      ,
    input  wire       rst_n    ,
    input  wire       sys_en   ,
    input  wire       timer_en ,
    output reg  [3:0] time_10  ,
    output reg  [3:0] time_01  ,
    output wire       tick_3s  ,
    output wire       tick_4s  
);

    reg  [22:0] cnt_01s;
    wire        tick_01s;

    parameter MAX_CNT_01S = 23'd4_999_999;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            time_10 <= 4'd3; 
            time_01 <= 4'd9; 
        end
        else if (!sys_en) begin 
            time_10 <= time_10;    
            time_01 <= time_01;    
        end
        else if (!timer_en) begin 
            time_10 <= 4'd3; 
            time_01 <= 4'd9; 
        end
        else if (tick_01s) begin
            if (time_10 == 4'd0 && time_01 == 4'd0) begin 
                time_10 <= 4'd3; 
                time_01 <= 4'd9; 
            end
            else if (time_01 == 4'd0) begin 
                time_10 <= time_10 - 1'b1; 
                time_01 <= 4'd9; 
            end
            else begin
                time_01 <= time_01 - 1'b1; 
            end
        end
    end

    assign tick_3s = tick_01s && (time_10 == 4'd1) && (time_01 == 4'd0);
    assign tick_4s = tick_01s && (time_10 == 4'd0) && (time_01 == 4'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            cnt_01s <= 23'd0;
        else if (!sys_en) 
            cnt_01s <= cnt_01s;
        else if (!timer_en) 
            cnt_01s <= 23'd0;
        else if (tick_01s) 
            cnt_01s <= 23'd0;
        else 
            cnt_01s <= cnt_01s + 1'b1;
    end

    assign tick_01s = (cnt_01s == MAX_CNT_01S);

endmodule