module cdc_handshake (
    input clk_100m,
    input clk_50m,
    input rst_n,
    input [7:0] rx_data,
    input rx_valid,
    output reg [7:0] data,
    output out_valid,
    
    // ILA 调试端口
    output dbg_req,       // 100MHz 域
    output dbg_ack_d1,    // 100MHz 域
    output dbg_ack_d2,    // 100MHz 域
    output [7:0] dbg_data_reg, // 100MHz 域
    output dbg_req_d1,    // 50MHz 域
    output dbg_req_d2,    // 50MHz 域
    output dbg_req_d3,    // 50MHz 域
    output dbg_ack,       // 50MHz 域
    output dbg_out_valid_d // 50MHz 域
);

reg [7:0] data_reg;
reg out_valid_d;
reg req;
reg req_d1;
reg req_d2;
reg req_d3;
reg ack;
reg ack_d1;
reg ack_d2;

// ack_d2 用于 100MHz 时钟域
always @(posedge clk_100m or negedge rst_n) begin
    if(!rst_n) begin       
       ack_d1<=1'b0;
       ack_d2<=1'b0;
    end
    else begin
        ack_d1<=ack;
        ack_d2<=ack_d1;
    end
end

// req_d2 用于 50MHz 时钟域
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin      
       req_d1<=1'b0;
       req_d2<=1'b0;
       req_d3<=1'b0;
    end
    else begin
        req_d1<=req;
        req_d2<=req_d1;
        req_d3<=req_d2;
    end
end

always @(posedge clk_100m or negedge rst_n) begin
    if(!rst_n) begin
        data_reg<=8'd0;
        req<=1'b0; // 有趣的是，req 是在 100MHz 时钟域初始化的
    end
    else begin
        if(rx_valid && !req)  begin
            req<=1'b1; 
            data_reg<=rx_data;
        end
        else begin
            if(ack_d2) begin
                req<=1'b0;
            end
        end
    end
end

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        data<=8'd0; 
        ack<=1'b0; // 有趣的是，ack 是在 50MHz 时钟域初始化的
    end
    else begin
        if(req_d2) begin
            data<=data_reg; 
            ack<=1'b1;
        end
            else begin
                ack<=1'b0;
            end
    end
end

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
    out_valid_d <= 1'b0;
    end
    else begin       
    out_valid_d <= req_d2 & (~req_d3); // 上升沿检测，打一拍，对齐 data 和 out_valid
    end
end

assign out_valid = out_valid_d;

// 调试信号直连
assign dbg_req        = req;
assign dbg_ack_d1     = ack_d1;
assign dbg_ack_d2     = ack_d2;
assign dbg_data_reg   = data_reg;
assign dbg_req_d1     = req_d1;
assign dbg_req_d2     = req_d2;
assign dbg_req_d3     = req_d3;
assign dbg_ack        = ack;
assign dbg_out_valid_d = out_valid_d;

endmodule