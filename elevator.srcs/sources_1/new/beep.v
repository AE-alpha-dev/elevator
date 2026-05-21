// ·äÃùÆ÷·¢ÉùÄ£¿é
module buzzer_ctrl (
    input  wire clk     ,
    input  wire rst_n   ,
    input  wire sys_en  ,
    input  wire tick_4s ,
    output reg  beep   
);

    wire        tick_05s;
    reg  [24:0] cnt_05s;

    parameter MAX_CNT_05S = 25'd24_999_999;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)           beep <= 1'b0;
        else if (!sys_en)     beep <= 1'b0;
        else if (tick_4s)     beep <= 1'b1;
        else if (tick_05s)    beep <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)           cnt_05s <= 25'd0;
        else if (!sys_en)     cnt_05s <= 25'd0;
        else if (!beep)       cnt_05s <= 25'd0;
        else if (tick_05s)    cnt_05s <= 25'd0;
        else                  cnt_05s <= cnt_05s + 1'b1;
    end

    assign tick_05s = (cnt_05s == MAX_CNT_05S);

endmodule