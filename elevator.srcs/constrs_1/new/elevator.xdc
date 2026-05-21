# 主时钟
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]

# 异步时钟域声明，告诉Vivado这两个时钟之间的路径由握手协议保证
set_clock_groups -asynchronous \
    -group [get_clocks clk_out1_clk_wiz_0] \
    -group [get_clocks clk_out2_clk_wiz_0]

# 时钟与复位
set_property PACKAGE_PIN R4 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property PACKAGE_PIN U2 [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n]

# 触摸按键
set_property PACKAGE_PIN T5 [get_ports sys_touch_key]
set_property IOSTANDARD LVCMOS33 [get_ports sys_touch_key]

# 4个功能按键
set_property PACKAGE_PIN T1 [get_ports {key_in[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[0]}]
set_property PACKAGE_PIN U1 [get_ports {key_in[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[1]}]
set_property PACKAGE_PIN W2 [get_ports {key_in[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[2]}]
set_property PACKAGE_PIN T3 [get_ports {key_in[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key_in[3]}]

# 蜂鸣器
set_property PACKAGE_PIN P16 [get_ports BEEP]
set_property IOSTANDARD LVCMOS33 [get_ports BEEP]

# 4个LED指示灯
set_property PACKAGE_PIN R2 [get_ports {LED[0]}]
set_property PACKAGE_PIN R3 [get_ports {LED[1]}]
set_property PACKAGE_PIN V2 [get_ports {LED[2]}]
set_property PACKAGE_PIN Y2 [get_ports {LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]

# 数码管位选，DIG[0] 表示从右往左第一位数码管的位选信号
set_property PACKAGE_PIN J15 [get_ports {DIG[0]}]
set_property PACKAGE_PIN H17 [get_ports {DIG[1]}]
set_property PACKAGE_PIN H13 [get_ports {DIG[2]}]
set_property PACKAGE_PIN G17 [get_ports {DIG[3]}]
set_property PACKAGE_PIN H18 [get_ports {DIG[4]}]
set_property PACKAGE_PIN G18 [get_ports {DIG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DIG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DIG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DIG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DIG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DIG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DIG[5]}]

# 数码管段选
set_property PACKAGE_PIN H15 [get_ports {SEG[0]}]
set_property PACKAGE_PIN G16 [get_ports {SEG[1]}]
set_property PACKAGE_PIN L13 [get_ports {SEG[2]}]
set_property PACKAGE_PIN G15 [get_ports {SEG[3]}]
set_property PACKAGE_PIN K13 [get_ports {SEG[4]}]
set_property PACKAGE_PIN G13 [get_ports {SEG[5]}]
set_property PACKAGE_PIN H14 [get_ports {SEG[6]}]
set_property PACKAGE_PIN J14 [get_ports {SEG[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[7]}]

# UART 发送接口
set_property PACKAGE_PIN T6 [get_ports tx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports tx_pin]

# UART 接收接口
set_property PACKAGE_PIN U5 [get_ports rx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports rx_pin]

# 全局电压与配置属性 (避免 Vivado 报 DRC 警告)
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# SPI Flash 相关设置 
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]