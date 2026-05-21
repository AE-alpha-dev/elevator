`timescale 1ns/1ps
module elevator_fsm_tb;

// 信号声明
reg clk;
reg rst_n;
reg sys_en;
reg [3:0] key;
reg tick_3s;
reg tick_4s;

wire timer_en;
wire [3:0] elv_state;
wire [1:0] floor;

integer pass_count;
integer fail_count;

// 模块例化
elevator_fsm u_elevator_fsm_tb(
.clk(clk),
.rst_n(rst_n),
.sys_en(sys_en),
.key(key),
.tick_3s(tick_3s),
.tick_4s(tick_4s),
.timer_en(timer_en),
.elv_state(elv_state),
.floor(floor)
);

// 生成时钟
initial clk=1'b0;
always #10 clk=~clk;

// 测试序列
initial begin
    // 初始化
    pass_count = 0;
    fail_count = 0;
    rst_n=1'b0;
    sys_en=1'b0;
    key=4'b1111;
    tick_3s=1'b0;
    tick_4s=1'b0;
    
    // 不再复位
    repeat(8) @(posedge clk);
    rst_n=1'b1;

    // 单上 2 楼
    repeat(8) @(posedge clk);
    sys_en=1'b1;
    
    repeat(50) @(posedge clk);
    key[1]=1'b0;

    // 检查 timer_en 是否拉高
    repeat(3) @(posedge clk);
    if(timer_en==1'b1) begin
    $display("[PASS] timer_en 正确拉高 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] timer_en 没能正确拉高 ERROR");
    fail_count = fail_count + 1;
    end

    repeat(50) @(posedge clk);
    key[1]=1'b1;
    
    repeat(200) @(posedge clk);
    tick_3s=1'b1;
    @(posedge clk);
    tick_3s=1'b0;

    // 立刻检查 floor 是否变成2
    @(posedge clk);
    if (floor == 2'd2) begin
    $display("[PASS] tick_3s后floor=2 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] tick_3s后floor=%0d，期望2 ERROR", floor);
    fail_count = fail_count + 1;
    end

    repeat(100) @(posedge clk);
    tick_4s=1'b1;
    @(posedge clk);
    tick_4s=1'b0;

    // 立刻检查 elv_state 是否变成4'b0100
    @(posedge clk);
    if (elv_state==4'b0100) begin
    $display("[PASS] tick_4s后 elv_state=4'b0100 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] tick_4s后 elv_state=%0b，期望 4'b0100 ERROR", elv_state);
    fail_count = fail_count + 1;
    end

    repeat(8) @(posedge clk);

    // 复位
    rst_n=1'b0;
    sys_en=1'b0;

    // 上 2 楼时，按下 1 楼键
    repeat(8) @(posedge clk);
    rst_n=1'b1;
    repeat(8) @(posedge clk);
    sys_en=1'b1;

    repeat(50) @(posedge clk);
    key[1]=1'b0;
    
    // 检查 timer_en 是否拉高
    repeat(3) @(posedge clk);
    if(timer_en==1'b1) begin
    $display("[PASS] timer_en 正确拉高 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] timer_en 没能正确拉高 ERROR");
    fail_count = fail_count + 1;
    end

    repeat(50) @(posedge clk);
    key[1]=1'b1; 
    repeat(50) @(posedge clk);
    key[0]=1'b0; 
    repeat(50) @(posedge clk);
    key[0]=1'b1; 
    repeat(200) @(posedge clk);
    tick_3s=1'b1;
    @(posedge clk); 
    tick_3s=1'b0;

    // 立刻检查 floor 是否变成2
    @(posedge clk);
    if (floor == 2'd2) begin
    $display("[PASS] tick_3s后floor=2 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] tick_3s后floor=%0d，期望2 ERROR", floor);
    fail_count = fail_count + 1;
    end

    repeat(500) @(posedge clk);
    tick_4s=1'b1;
    @(posedge clk); 
    tick_4s=1'b0;

    // 立刻检查 elv_state 是否变成 4'b0100
    @(posedge clk);
    if (elv_state==4'b0100) begin
    $display("[PASS] tick_4s后 elv_state=4'b0100 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] tick_4s后 elv_state=%0b，期望 4'b0100 ERROR", elv_state);
    fail_count = fail_count + 1;
    end

    // 检查 timer_en 是否拉高
    repeat(3) @(posedge clk);
    if(timer_en==1'b1) begin
    $display("[PASS] timer_en 正确拉高 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] timer_en 没能正确拉高 ERROR");
    fail_count = fail_count + 1;
    end

    repeat(250) @(posedge clk);
    tick_3s=1'b1;
    @(posedge clk); 
    tick_3s=1'b0;

    // 立刻检查 floor 是否变成1
    @(posedge clk);
    if (floor == 2'd1) begin
    $display("[PASS] tick_3s后floor=1 OK");
    pass_count = pass_count + 1;
    end
    else begin
    $display("[FAIL] tick_3s后floor=%0d，期望1 ERROR", floor);
    fail_count = fail_count + 1;
    end

    repeat(500) @(posedge clk);
    tick_4s=1'b1;
    @(posedge clk);
    tick_4s=1'b0;

    // 立刻检查 elv_state 是否变成4'b0001
    @(posedge clk);
    if (elv_state==4'b0001) begin
    $display("[PASS] tick_4s后 elv_state=4'b0001 OK");
    pass_count = pass_count + 1;
    end 
    else begin
    $display("[FAIL] tick_4s后 elv_state=%0b，期望 4'b0001 ERROR", elv_state);
    fail_count = fail_count + 1;
    end

    repeat(8) @(posedge clk);

    // 最后汇总
    $display("==================================");
    $display("PASS=%0d  FAIL=%0d", pass_count, fail_count);
    if (fail_count == 0)
        $display("全部通过 OK");
    else
        $display("存在失败项 ERROR");
    $display("==================================");

$finish;

end

initial begin
    $dumpfile("elevator_fsm_tb.vcd");
    $dumpvars(0, elevator_fsm_tb);
end

endmodule
