`timescale 1ns / 1ps
// ============================================================
//  cdc_handshake 验证 Testbench
//  覆盖场景：
//    1. 基本单次传输，验证 data 与 out_valid 对齐
//    2. 连续多次传输
//    3. 握手进行中 rx_valid 再次到来
//    4. 超时检测（out_valid 若 100 周期内未到，判 FAIL）
// ============================================================
module cdc_handshake_tb;

// 时钟参数
parameter CLK_100M_PERIOD = 10;   // 100MHz → 周期 10ns
parameter CLK_50M_PERIOD  = 20;   //  50MHz → 周期 20ns
parameter TIMEOUT_CYCLES  = 100;  // 等待 out_valid 的最大 50MHz 周期数

// 激励信号声明
reg        clk_100m;
reg        clk_50m;
reg        rst_n;
reg  [7:0] rx_data;
reg        rx_valid;

// 输出信号声明
wire [7:0] data;
wire       out_valid;

// 例化被测模块
cdc_handshake u_dut (
    .clk_100m (clk_100m),
    .clk_50m  (clk_50m ),
    .rst_n    (rst_n   ),
    .rx_data  (rx_data ),
    .rx_valid (rx_valid),
    .data     (data    ),
    .out_valid(out_valid)
);


// 时钟生成
initial clk_100m = 1'b0;
always  #(CLK_100M_PERIOD / 2) clk_100m = ~clk_100m;

initial clk_50m  = 1'b1;          // ← 故意与 100M 反相，模拟真实板上无法对齐的情形
always  #(CLK_50M_PERIOD  / 2) clk_50m  = ~clk_50m;

// 计数参数
integer pass_count;
integer fail_count;
integer cnt;

initial begin
    pass_count = 0;
    fail_count = 0;
    cnt = 0;
end

//  主测试序列
initial begin
    // 初始化
    rst_n      = 1'b0;
    rx_data    = 8'h00;
    rx_valid   = 1'b0;
   
    // 复位 
    repeat(6) @(posedge clk_100m); // 复位持续 6 个 100MHz 周期
    rst_n = 1'b1; 
    repeat(3) @(posedge clk_100m);  // 等待逻辑稳定

    //  测试 1：基本单次传输
    $display("[TEST 1] 基本单次传输 -- 发送 0xAB");
    task_send(8'hAB);
    task_check(8'hAB, "TEST1");

    // 只是out_valid跳变了，要等一段时间，到 req 落回0，握手才算完全结束
    repeat(25) @(posedge clk_50m);

    //  测试 2：连续两次传输
    $display("[TEST 2] 连续传输 -- 先发 0x31，再发 0x32"); // 0x 表示数字是十六进制数
    task_send(8'h31);
    task_check(8'h31, "TEST2-first ");
    repeat(25) @(posedge clk_50m);  // 同样要等第一次握手完整结束

    task_send(8'h32);
    task_check(8'h32, "TEST2-second");
    repeat(25) @(posedge clk_50m);

    //  测试 3：握手进行中 rx_valid 再次拉高
    //  第一个字节 0xCC 发出后，req 已置 1，此时立刻发第二个字节 0xDD，应被忽略，所以最终 data 应为 0xCC，而不是 0xDD
    $display("[TEST 3] 握手进行中再次 rx_valid -- 应保留 0xCC 忽略 0xDD");

    // 发第一个（req 将在本拍末置 1）
    @(posedge clk_100m);
    rx_data  = 8'hCC;
    rx_valid = 1'b1;
    @(posedge clk_100m);
    rx_valid = 1'b0;

    // 紧接着发第二个（req 此时已为 1，应被 "!req" 保护门挡住）
    @(posedge clk_100m);
    rx_data  = 8'hDD;
    rx_valid = 1'b1;
    @(posedge clk_100m);
    rx_valid = 1'b0;

    task_check(8'hCC, "TEST3      ");
    repeat(25) @(posedge clk_50m);

    //  测试 4：复位后能正常工作
    $display("[TEST 4] 复位后恢复传输 -- 发送 0xFF");
    rst_n = 1'b0;
    repeat(4) @(posedge clk_100m);
    rst_n = 1'b1;
    repeat(3) @(posedge clk_100m);

    task_send(8'hFF);
    task_check(8'hFF, "TEST4      ");
    repeat(25) @(posedge clk_50m);

    //  汇总
    $display("============================================");
    $display("  测试结束   PASS = %0d   FAIL = %0d", pass_count, fail_count);
    if (fail_count == 0)
        $display("  全部通过 OK");
    else
        $display("  存在失败项，请检查波形 ERROR");
    $display("============================================");
    $finish;
end

// 发送数据给 cdc_handshake 的输入端口 rx_data、rx_valid
task task_send;
    input [7:0] byte_in;
    begin
// 这里要在100MHz时钟上升沿赋值 rx_data、rx_valid
// 否则 rx_data 和 rx_valid 可能在任意时刻被赋值
// 而如果 rx_valid 赋值时刻离上升沿太近，在 cdc_handshake 模块中就可能出现建立时间不满足的问题，导致这一拍 cdc_handshake 采样不到 rx_data，数据丢失
        @(posedge clk_100m);
        rx_data  = byte_in;
        rx_valid = 1'b1;
        @(posedge clk_100m);
        rx_valid = 1'b0;
        rx_data  = 8'h00;
    end
endtask


//  校验 out_valid 是否能正常跳变成高电平。若 out_valid 的高电平在 TIMEOUT_CYCLES 个 50MHz 周期内都未出现，则说明原模块可能有bug，判 FAIL
//  校验 out_valid 和 data 是否对齐（在同一个时钟上升沿处变化），若对齐，则有 data=expected，否则有 data!=expected
task task_check;
    input [7:0]   expected;
    input [8*12-1:0] label;     // 最长 12 个字符的测试名
    begin
        cnt = 0; 
        @(posedge clk_50m);   // 完全可以删掉，保留也只是因为 task_check 本身是在 50MHz 时钟域内工作的，象征性防御措施罢了
// while只能在仿真代码中用，while 在这里的作用跟在 C 语言中相同    
        while (!out_valid && cnt < TIMEOUT_CYCLES) begin
            @(posedge clk_50m);
            cnt = cnt + 1;
        end
// 如果不满足条件 !out_valid && cnt < TIMEOUT_CYCLES，进入下面的语句
// !out_valid && cnt < TIMEOUT_CYCLES 表示 out_valid 迟迟未能拉高，超时       
        if (cnt >= TIMEOUT_CYCLES) begin
            $display("[FAIL] %s : 超时，out_valid 未在 %0d 个周期内出现",label, TIMEOUT_CYCLES); // %s、%0d、%0h 这些都是占位符，后面的参数按顺序填进去  
            fail_count = fail_count + 1;
// out_valid 已经在 TIMEOUT_CYCLES 个 50MHz 周期内拉高，但是 data !== expected，说明 out_valid 和 data 没有对齐
        end else if (data !== expected) begin
            $display("[FAIL] %s : out_valid=1 但 data=0x%0h，期望=0x%0h",label, data, expected);
            fail_count = fail_count + 1;
// 既不超时， out_valid 和 data 又对齐，则检验通过
        end else begin
            $display("[PASS] %s : data=0x%0h，out_valid 对齐 OK",label, data);
            pass_count = pass_count + 1;
        end
    end
endtask


//  波形导出（用 iverilog + gtkwave 或 Vivado 仿真均可）
initial begin
    $dumpfile("cdc_handshake_tb.vcd");
    $dumpvars(0, cdc_handshake_tb);
end

endmodule