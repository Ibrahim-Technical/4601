## ELEC4601 Lab 2 Bonus — ZedBoard Constraints
## Short Press vs Long Press Detection

## Clock — 100 MHz
set_property PACKAGE_PIN Y9       [get_ports clk]
set_property IOSTANDARD LVCMOS33  [get_ports clk]
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

## Reset Button — BTND
set_property PACKAGE_PIN R16      [get_ports reset_btn]
set_property IOSTANDARD LVCMOS33  [get_ports reset_btn]

## Button Input — BTNC
set_property PACKAGE_PIN P16      [get_ports btn_in]
set_property IOSTANDARD LVCMOS33  [get_ports btn_in]

## Short Press LED — LD0
set_property PACKAGE_PIN T22      [get_ports led_short]
set_property IOSTANDARD LVCMOS33  [get_ports led_short]

## Long Press LED — LD1
set_property PACKAGE_PIN T21      [get_ports led_long]
set_property IOSTANDARD LVCMOS33  [get_ports led_long]
