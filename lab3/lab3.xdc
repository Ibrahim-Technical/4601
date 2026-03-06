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
set_property PACKAGE_PIN Y9   [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -name sys_clk -period 10.000 [get_ports clk_100mhz]

# -------------------------------------------------------------------
# Push-button Center (BTNC) = P16
# Asynchronous input — synchronised by sync2 inside lab3_top.v
# Active-HIGH (pressing = logic 1)
# -------------------------------------------------------------------
set_property PACKAGE_PIN P16  [get_ports btnc_raw]
set_property IOSTANDARD LVCMOS33 [get_ports btnc_raw]

# -------------------------------------------------------------------
# Slide Switch SW0 = F22
# Asynchronous input — synchronised by sync2 inside lab3_top.v
# Used as active-LOW reset: SW0 UP (=1) → rst_n=0 → controller reset
# -------------------------------------------------------------------
set_property PACKAGE_PIN F22  [get_ports sw0_raw]
set_property IOSTANDARD LVCMOS33 [get_ports sw0_raw]

# -------------------------------------------------------------------
# LED LD0 = T22 — RAW bounce reference (btnc_raw direct)
# -------------------------------------------------------------------
set_property PACKAGE_PIN T22  [get_ports led0]
set_property IOSTANDARD LVCMOS33 [get_ports led0]

# -------------------------------------------------------------------
# LED LD1 = T21 — Debounced controller output
# -------------------------------------------------------------------
set_property PACKAGE_PIN T21  [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led1]
