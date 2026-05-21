// 指令解析器模块
module Ins_Dec(
    input [7:0] data,
    input valid,
    output [1:0] virtual_key
);

assign virtual_key[0]=(valid && (data == 8'h31));// 8'h31 表示 1
assign virtual_key[1]=(valid && (data == 8'h32));// 8'h32 表示 2

endmodule