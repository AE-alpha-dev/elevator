module uart_tx (
    input  wire       clk,       // 100MHz 系统时钟
    input  wire       rst_n,     // 低电平复位
    input  wire       tx_en,     // 发送使能信号 (脉冲，拉高1个时钟周期代表开始发送)
    input  wire [7:0] tx_data,   // 需要发送的 8 位数据
    output reg        tx_pin,    // UART 物理发送引脚 (空闲时必须保持高电平 1)
    output reg        tx_busy    // 忙碌标志位 (发送期间为 1，发送完毕/空闲为 0)
);

// 100MHz / 115200 ≈ 868。计数从 0 到 867 刚好是 434 个周期
parameter MAX = 10'd867; 

reg [9:0] cnt;
reg [3:0] bit_cnt;
reg [9:0] shift_reg;

wire baud_tick;

// ----------------------------------------------------
// 1. 波特率发生器：只有在发送时才计数，空闲时清零
// ----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        cnt <= 10'd0;
    else if (tx_busy) begin
        if (cnt == MAX) 
            cnt <= 10'd0;
        else 
            cnt <= cnt + 1'b1;
    end
    else 
        cnt <= 10'd0; // 【修复1】确保空闲时清零
end

assign baud_tick = (cnt == MAX);

// ----------------------------------------------------
// 2. 发送主控逻辑：避免多驱动，集中管理状态
// ----------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_busy   <= 1'b0;
        tx_pin    <= 1'b1;      // UART 空闲时必须是高电平
        bit_cnt   <= 4'd0;
        shift_reg <= 10'd0;     // 【修复2】统一在同一个 always 块中复位
    end
    else begin
        // 当空闲且收到使能信号时，启动发送
        if (tx_en && !tx_busy) begin
            tx_busy   <= 1'b1;
            // 拼接数据：停止位(1) + 数据位 + 起始位(0)
            shift_reg <= {1'b1, tx_data, 1'b0}; 
            bit_cnt   <= 4'd0;
            tx_pin    <= 1'b1;  // 准备发送，引脚先保持高
        end
        // 正在发送中
        else if (tx_busy) begin
            if (baud_tick) begin
                if (bit_cnt < 10) begin
                    // 还没发完，继续发
                    tx_pin    <= shift_reg[0];        // 把最低位推向引脚
                    shift_reg <= shift_reg >> 1;      // 数据右移一位
                    bit_cnt   <= bit_cnt + 1'b1;      // 已发送位数 +1
                end 
                else begin
                    // 【修复3】发满了10位，结束发送
                    tx_busy   <= 1'b0;
                    tx_pin    <= 1'b1; // 恢复空闲电平
                end
            end
        end
    end
end

endmodule