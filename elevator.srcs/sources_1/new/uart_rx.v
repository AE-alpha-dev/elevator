module uart_rx (
    input  clk,       // 100MHz 时钟
    input  rst_n,     // 低电平复位
    input  rx_pin,    // UART 物理接收引脚
    output reg  [7:0] rx_data,   // 接收到的 8 位数据
    output reg        rx_done   // 接收完成脉冲 (仅维持 1 个时钟周期)
);

reg rx_begin;
reg [9:0] cnt;
reg [3:0] bit_cnt;
reg rx_pin_d1;
reg rx_pin_d2;
reg [7:0] rx_shift_reg;

wire baud_tick;
wire half_tick;

parameter MAX = 10'd867;       // 100MHz / 115200
parameter HALF_MAX = 10'd433;  // 半个波特率周期，用于中间点采样

always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_pin_d1 <= 1'b1;
            rx_pin_d2 <= 1'b1;
        end
        else begin
            rx_pin_d1 <= rx_pin;
            rx_pin_d2 <= rx_pin_d1;
        end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_begin <= 1'b0;
    end else begin
        if (rx_done) begin
            rx_begin <= 1'b0;
        end else if (!rx_begin) begin
            if (rx_pin_d2 & ~rx_pin_d1)   // 检测下降沿，启动接收
                rx_begin <= 1'b1;
        end else begin
            // 已在接收中：在第一个 half_tick（起始位中央）验证
            if (half_tick && bit_cnt == 4'd0 && rx_pin_d2 != 1'b0)
                rx_begin <= 1'b0;          // 是毛刺，立即中止
        end
    end
end

always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg<=8'd0;
            bit_cnt<=4'b0;
        end
        else if (!rx_begin) begin   // ← 新增：不在接收中时保持复位
            bit_cnt <= 4'd0;
        end
        else if(half_tick) begin                
                bit_cnt<=bit_cnt+1'b1;
                if(bit_cnt > 4'd0 && bit_cnt < 4'd9) begin
                    rx_shift_reg<= {rx_pin_d2, rx_shift_reg[7:1]};
                end
        end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rx_data <= 8'd0;
    else if (bit_cnt == 4'd9)
        rx_data <= rx_shift_reg;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) rx_done <= 1'b0;
    else        rx_done <= (bit_cnt == 4'd10 && cnt == HALF_MAX + 1'b1); //如果用if(bit_cnt == 4'd10 && cnt == HALF_MAX + 1'b1)无法实现单周期脉冲的效果
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        cnt <= 10'd0;
    else if (rx_begin) begin
        if (baud_tick) begin
            cnt <= 10'd0;
        end
        else 
            cnt <= cnt + 1'b1;
    end
    else 
        cnt <= 10'd0; 
end

assign baud_tick = (cnt == MAX);
assign half_tick = (cnt == HALF_MAX);

endmodule