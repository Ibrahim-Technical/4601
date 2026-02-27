## -----------------------------------------------------------------------------
## ELEC4601: Digital and Embedded Systems Design
## Week 3 Lab 2 constraints for Digilent ZedBoard (Zynq-7000)
## -----------------------------------------------------------------------------

## 1. Clock Signal (100 MHz PL Clock)
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

## 2. PL-Side Push Buttons (Active-High)
# Reset Button (BTND - Down Button)
set_property PACKAGE_PIN R16 [get_ports reset_btn]
set_property IOSTANDARD LVCMOS33 [get_ports reset_btn]

# FSM Debounce Input (BTNC - Center Button)
set_property PACKAGE_PIN P16 [get_ports btn_in]
set_property IOSTANDARD LVCMOS33 [get_ports btn_in]

# Raw Input for comparison (BTNR - Right Button)
set_property PACKAGE_PIN R18 [get_ports btn_raw]
set_property IOSTANDARD LVCMOS33 [get_ports btn_raw]

## 3. PL-Side LEDs
# Debounced Output LED (LD0)
set_property PACKAGE_PIN T22 [get_ports led_debounced]
set_property IOSTANDARD LVCMOS33 [get_ports led_debounced]

# Raw Output LED (LD1)
set_property PACKAGE_PIN T21 [get_ports led_raw]
set_property IOSTANDARD LVCMOS33 [get_ports led_raw]