## File: lab3.xdc
## Purpose: Map HDL ports to ZedBoard pins and define 100 MHz clock
## Corrected pin assignments (verified against ZedBoard reference manual
## and user-provided pin map):
##   BTNC = P16  (starter had N19 — incorrect for ZedBoard)
##   SW0  = F22  (starter had G15 — incorrect for ZedBoard)

# -------------------------------------------------------------------
# 100 MHz PL clock on ZedBoard (pin Y9)
# 10.000 ns period constraint → timing closure requires WNS >= 0
# -------------------------------------------------------------------
set_property PACKAGE_PIN Y9 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk [get_ports clk_100mhz]

# -------------------------------------------------------------------
# Push-button Center (BTNC) = P16
# Asynchronous input — synchronised by sync2 inside lab3_top.v
# Active-HIGH (pressing = logic 1)
# -------------------------------------------------------------------
set_property PACKAGE_PIN P16 [get_ports btnc_raw]
set_property IOSTANDARD LVCMOS33 [get_ports btnc_raw]

# -------------------------------------------------------------------
# Slide Switch SW0 = F22
# Asynchronous input — synchronised by sync2 inside lab3_top.v
# Used as active-LOW reset: SW0 UP (=1) → rst_n=0 → controller reset
# -------------------------------------------------------------------
set_property PACKAGE_PIN F22 [get_ports sw0_raw]
set_property IOSTANDARD LVCMOS33 [get_ports sw0_raw]

# -------------------------------------------------------------------
# LED LD0 = T22 — RAW bounce reference (btnc_raw direct)
# -------------------------------------------------------------------
set_property PACKAGE_PIN T22 [get_ports led0]
set_property IOSTANDARD LVCMOS33 [get_ports led0]

# -------------------------------------------------------------------
# LED LD1 = T21 — Debounced controller output
# -------------------------------------------------------------------
set_property PACKAGE_PIN T21 [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led1]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_100mhz_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 21 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {u_ctrl/counter[0]} {u_ctrl/counter[1]} {u_ctrl/counter[2]} {u_ctrl/counter[3]} {u_ctrl/counter[4]} {u_ctrl/counter[5]} {u_ctrl/counter[6]} {u_ctrl/counter[7]} {u_ctrl/counter[8]} {u_ctrl/counter[9]} {u_ctrl/counter[10]} {u_ctrl/counter[11]} {u_ctrl/counter[12]} {u_ctrl/counter[13]} {u_ctrl/counter[14]} {u_ctrl/counter[15]} {u_ctrl/counter[16]} {u_ctrl/counter[17]} {u_ctrl/counter[18]} {u_ctrl/counter[19]} {u_ctrl/counter[20]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 2 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {u_ctrl/state[0]} {u_ctrl/state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list u_ctrl/btnc_probe]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list btnc_sync]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_100mhz_IBUF_BUFG]
