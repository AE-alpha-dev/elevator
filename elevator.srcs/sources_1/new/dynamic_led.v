// 数码管显示模块
module seg_display_ctrl (
    input  wire       clk       ,
    input  wire [1:0] floor     ,                
    input  wire       sys_en    ,
    input  wire       boot_en   ,
    input  wire [3:0] elv_state ,
    input  wire [3:0] time_01   ,    
    input  wire [3:0] time_10   ,
    output reg  [5:0] dig       ,
    output reg  [7:0] seg
);

    reg  [4:0]  disp_data = 5'd31; 
    reg  [2:0]  scan_cnt  = 3'd0;
    reg  [15:0] cnt_1ms   = 16'd0;

    wire        stay;

    parameter MAX_CNT_1MS = 16'd49_999;
    
    assign stay = (elv_state == 4'b0001 || elv_state == 4'b0100);

    always @(*) begin
        dig       = 6'b111_111;
        disp_data = 5'd31; 

        case (scan_cnt) 
            3'd0: begin  
                dig = 6'b111_110; 
                if (!sys_en && !boot_en) 
                    disp_data = 5'd10; // 'F'
                else if (boot_en) 
                    disp_data = 5'd11; // 'N'
                else if (sys_en)  
                    disp_data = {3'b000, floor};
            end
            3'd1: begin 
                dig = 6'b111_101;
                if (!sys_en && !boot_en) 
                    disp_data = 5'd10; // 'F'
                else if (boot_en) 
                    disp_data = 5'd0;  // 'O'
                else if (sys_en)  
                    disp_data = 5'd31; // 灭
            end
            3'd2: begin 
                dig = 6'b111_011;
                if (!sys_en && !boot_en) 
                    disp_data = 5'd0;  // 'O'
                else if (boot_en) 
                    disp_data = 5'd31; // 灭
                else if (sys_en) begin
                    if (stay)                        
                        disp_data = 5'd12; // 待机
                    else if (elv_state == 4'b0010)   
                        disp_data = 5'd13; // 上行
                    else if (elv_state == 4'b1000)   
                        disp_data = 5'd14; // 下行
                end
            end
            3'd3: begin 
                dig = 6'b110_111;
                disp_data = 5'd31; // 灭 
            end
            3'd4: begin 
                dig = 6'b101_111;
                if (sys_en) 
                    disp_data = {1'b0, time_01}; 
            end
            3'd5: begin 
                dig = 6'b011_111;
                if (sys_en) 
                    disp_data = time_10 + 5'd16; 
            end
        endcase
    end

    always @(posedge clk) begin
        if (cnt_1ms == MAX_CNT_1MS) begin 
            cnt_1ms <= 16'd0;
        end else begin
            cnt_1ms <= cnt_1ms + 1'b1;
        end
    end

    wire tick_1ms = (cnt_1ms == MAX_CNT_1MS); 

    always @(posedge clk) begin // 永远只用全局时钟
        if (tick_1ms) begin // 神来一笔
            if (scan_cnt >= 3'd5) 
                scan_cnt <= 3'd0;
            else 
                scan_cnt <= scan_cnt + 1'b1;
        end
    end

    always @(*) begin
        case (disp_data)
            5'd0 :  seg = 8'b1100_0000; 
            5'd1 :  seg = 8'b1111_1001; 
            5'd2 :  seg = 8'b1010_0100; 
            5'd3 :  seg = 8'b1011_0000; 
            5'd4 :  seg = 8'b1001_1001; 
            5'd5 :  seg = 8'b1001_0010;
            5'd6 :  seg = 8'b1000_0010;
            5'd7 :  seg = 8'b1111_1000;
            5'd8 :  seg = 8'b1000_0000; 
            5'd9 :  seg = 8'b1001_0000;
            5'd16:  seg = 8'b0100_0000; //'0.'
            5'd17:  seg = 8'b0111_1001; //'1.'
            5'd18:  seg = 8'b0010_0100; //'2.'
            5'd19:  seg = 8'b0011_0000; //'3.'
            5'd20:  seg = 8'b0001_1001; //'4.'
            5'd10:  seg = 8'b1000_1110; // 'F'
            5'd11:  seg = 8'b1100_1000; // 'N'
            5'd12:  seg = 8'b1011_1111; // 待机
            5'd13:  seg = 8'b1011_1110; // 上行
            5'd14:  seg = 8'b1011_0111; // 下行
            5'd31:  seg = 8'b1111_1111; // 灭
            default: seg = 8'b1111_1111;
        endcase
    end

endmodule