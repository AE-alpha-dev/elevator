module state_monitor(
    input  wire       clk       ,  // 50MHz 时钟
    input  wire       rst_n     ,
    input  wire [3:0] elv_state ,  // 接入电梯输出的状态
    output reg  [7:0] tx_data   ,  // 准备发送的 ASCII 码
    output wire       tx_req       // 仅维持 1 个周期的发送脉冲
);

    // ==========================================
    // 1. 边缘检测逻辑 (Edge Detection)
    // ==========================================
    reg [3:0] last_state; 
    
    // 每来一个时钟上升沿，就把现在的状态"备份"给 last_state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_state <= 4'b0001; // 默认初始状态为 STAY1
        end else begin
            last_state <= elv_state; 
        end
    end
    
    assign tx_req = (elv_state != last_state);
    
    // ==========================================
    // 2. 状态映射逻辑 (修复版：改为组合逻辑)
    // ==========================================
    always @(*) begin  // 【关键修复】去掉了 posedge clk，使用组合逻辑
        case(elv_state)
            4'b0001: tx_data = 8'h31; // '1' (注意这里用阻塞赋值 = )
            4'b0010: tx_data = 8'h55; // 'U'
            4'b0100: tx_data = 8'h32; // '2'
            4'b1000: tx_data = 8'h44; // 'D'
            default: tx_data = 8'h3F; // '?'
        endcase
    end

endmodule