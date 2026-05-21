// 顶层模块
module elevator_top (
    input  wire       sys_clk       ,
    input  wire       sys_rst_n     ,
    input  wire       sys_touch_key ,
    input  wire [3:0] key_in        ,
    input  wire       rx_pin        ,
    output wire [5:0] DIG           ,
    output wire [7:0] SEG           ,
    output wire [3:0] LED           ,
    output wire       BEEP          ,
    output wire       tx_pin        
);

    // 内部网线定义
    wire       sys_en;
    wire       boot_en;
    wire       timer_en;
    wire       tick_3s;
    wire       tick_4s;
    wire [3:0] elv_state;
    wire [1:0] current_floor;
    wire [3:0] key_deb;
    wire [3:0] key;
    wire [3:0] time_10;
    wire [3:0] time_01;
    wire       clk_50m;
    wire       clk_100m;
    wire [7:0] monitor_tx_data;
    wire       monitor_tx_req;
    wire       uart_busy;
    wire       fifo_empty;
    wire [7:0] fifo_dout;
    wire       fifo_rd_en;
    wire [7:0] rx_data;
    wire       done;
    wire [7:0] data;
    wire       valid;
    wire [1:0] virtual_key;

    // 例化修改后的 PLL IP核 (没有 reset 和 locked)
    clk_wiz_0 u_pll (
        .clk_out1 (clk_50m),  // 供电梯和 FIFO 写侧使用
        .clk_out2 (clk_100m), // 供 UART 和 FIFO 读侧使用
        .clk_in1  (sys_clk)   // 接入物理引脚
    );

    // 系统开关模块
    sys_pwr_ctrl u_sys_pwr_ctrl (
        .clk          ( clk_50m       ),
        .rst_n        ( sys_rst_n     ),
        .touch_key    ( sys_touch_key ),
        .sys_en       ( sys_en        ),  
        .boot_en      ( boot_en       )
    );

    // 核心状态模块
    elevator_fsm u_elevator_fsm (
        .clk          ( clk_50m       ),
        .rst_n        ( sys_rst_n     ),
        .key          ( key       ),
        .sys_en       ( sys_en        ),
        .tick_3s      ( tick_3s       ),
        .tick_4s      ( tick_4s       ),
        .timer_en     ( timer_en      ),
        .elv_state    ( elv_state     ),
        .floor        ( current_floor )
    );

    // 4秒计时器模块
    timer_ctrl u_timer_ctrl (
        .clk          ( clk_50m       ),
        .rst_n        ( sys_rst_n     ),
        .sys_en       ( sys_en        ),
        .timer_en     ( timer_en      ),
        .time_10      ( time_10       ),
        .time_01      ( time_01       ),
        .tick_3s      ( tick_3s       ),
        .tick_4s      ( tick_4s       )
    );

    // 数码管动态显示模块
    seg_display_ctrl u_seg_display_ctrl (
        .clk          ( clk_50m       ),
        .sys_en       ( sys_en        ),
        .boot_en      ( boot_en       ),
        .elv_state    ( elv_state     ),
        .floor        ( current_floor ),
        .time_01      ( time_01       ),
        .time_10      ( time_10       ),
        .dig          ( DIG           ),
        .seg          ( SEG           )
    );

    // LED 控制模块
    led_ctrl u_led_ctrl (
        .clk          ( clk_50m       ),
        .rst_n        ( sys_rst_n     ),
        .sys_en       ( sys_en        ),
        .elv_state    ( elv_state     ),
        .key          ( key       ),
        .led          ( LED           )
    );

    // 蜂鸣器模块
    buzzer_ctrl u_buzzer_ctrl (
        .clk          ( clk_50m       ),
        .rst_n        ( sys_rst_n     ),
        .sys_en       ( sys_en        ),
        .tick_4s      ( tick_4s       ),
        .beep         ( BEEP          )
    );

    // 按键消抖模块 (利用 generate for 循环生成 4 个实例)
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : KEY_DEBOUNCE_INST
            key_debounce u_key_debounce (
                .clk      ( clk_50m     ),
                .rst_n    ( sys_rst_n   ),
                .key_in   ( key_in[i]   ),
                .key_deb  ( key_deb[i]  )
            );
        end
    endgenerate
    
    state_monitor u_state_monitor (
        .clk       ( clk_50m         ), // 50MHz 时钟域
        .rst_n     ( sys_rst_n       ),
        .elv_state ( elv_state       ), // 接入电梯状态
        .tx_data   ( monitor_tx_data ), // 输出 ASCII 码
        .tx_req    ( monitor_tx_req  )  // 输出 1 周期脉冲
    );

    // FIFO 模块
    fifo_async u_fifo_async (
        .rst    ( ~sys_rst_n      ), // 【必须显式取反连接】
        
        .wr_clk ( clk_50m         ), // 写时钟 50MHz
        .din    ( monitor_tx_data ), // 写数据
        .wr_en  ( monitor_tx_req  ), // 写使能 (利用监控器的脉冲)
        .full   (                 ), // 悬空不接 (我们确信发得很慢，不会溢出)
        
        .rd_clk ( clk_100m        ), // 读时钟 100MHz
        .dout   ( fifo_dout       ), // 读出的数据
        .rd_en  ( fifo_rd_en      ), // 读使能
        .empty  ( fifo_empty      )  // 空标志
    );
    
    uart_tx u_uart_tx (
        .clk     ( clk_100m    ), // 【注意】这里是 100MHz！
        .rst_n   ( sys_rst_n   ),
        .tx_en   ( fifo_rd_en  ), // 读出数据的那一刻，触发发送
        .tx_data ( fifo_dout   ), // 从 FIFO 读出的数据
        .tx_pin  ( tx_pin ), // 连到物理引脚
        .tx_busy ( uart_busy   )
    );

    // 【读逻辑握手】：只要 FIFO 里有数据 (!empty)，且 UART 不忙，就读出一个字节
    assign fifo_rd_en = (!fifo_empty) && (!uart_busy);
   
   // 串口接收模块
    uart_rx u_uart_rx(
        .clk     ( clk_100m    ), // 【注意】这里是 100MHz！
        .rst_n   ( sys_rst_n   ),
        .rx_pin  ( rx_pin      ), // 读出数据的那一刻，触发发送
        .rx_data ( rx_data   ), // 从 FIFO 读出的数据
        .rx_done ( done      ) // 连到物理引脚 
    );
    
    // 跨时钟域握手协议模块
    cdc_handshake u_cdc_handshake(
        .clk_100m( clk_100m    ), 
        .clk_50m ( clk_50m     ), 
        .rst_n   ( sys_rst_n   ),
        .rx_data ( rx_data     ),
        .rx_valid( done        ),
        .data    (data         ),
        .out_valid(valid)      
    );

    // 指令解析器模块        
    Ins_Dec u_Ins_Dec(
    .data(data),
    .valid(valid),
    .virtual_key(virtual_key)
    );

    assign key[0]=(key_deb[0]&~virtual_key[0]);
    assign key[1]=(key_deb[1]&~virtual_key[1]);
    assign key[2]=(key_deb[2]&~virtual_key[0]);
    assign key[3]=(key_deb[3]&~virtual_key[1]);
    
endmodule