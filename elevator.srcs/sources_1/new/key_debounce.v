// 按键消抖模块
module key_debounce (
    input  wire clk     ,
    input  wire rst_n   ,
    input  wire key_in  ,
    output reg  key_deb  // 消抖后的输入
);

    reg[19:0] cnt_delay; 
    reg         key_d0; // 第1拍：同步外部异步信号
    reg         key_d1; // 第2拍：彻底消除亚稳态
    reg         key_d2; // 第3拍：用于检测电平变化

    parameter MAX_CNT_20MS = 20'd999_999;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            cnt_delay <= 20'd0; 
            key_d0    <= 1'b1;  
            key_d1    <= 1'b1; 
            key_d2    <= 1'b1; 
            key_deb   <= 1'b1; 
        end // 消抖，虽然都用了两级寄存器打拍，但跟边沿检测不同
        else begin
            key_d0 <= key_in; 
            key_d1 <= key_d0; 
            key_d2 <= key_d1; // 异步信号打两拍，并移位缓存
            
            if (key_d2 != key_d1) begin 
                cnt_delay <= 20'd0; 
            end // 与前一拍不同，也就是在变化，一定是在发生抖动，重置20ms倒计时
            else if (cnt_delay <= MAX_CNT_20MS) begin
                cnt_delay <= cnt_delay + 1'b1; 
                if (cnt_delay == MAX_CNT_20MS) begin 
                    key_deb <= key_d2; 
                end // 刚好达到 20ms 阈值的那一个瞬间，更新有效电平，不在这一步清零，是为了防止陷入循环，这样可以减少动态功耗
            end
        end
    end

endmodule