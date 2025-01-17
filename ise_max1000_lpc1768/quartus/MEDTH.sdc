## Generated SDC file "MEDTH.sdc"

## Copyright (C) 2018  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 18.0.0 Build 614 04/24/2018 SJ Standard Edition"

## DATE    "Thu Mar 14 19:02:43 2019"

##
## DEVICE  "10M50DAF484C6GES"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 83.333 -waveform { 0.000 41.666 } [get_ports {clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {\sintesis:PLL|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 25 -divide_by 3 -phase 15.00 -master_clock {clk} [get_pins {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {\sintesis:PLL|altpll_component|auto_generated|pll1|clk[0]}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_ports {SCL SDA nRst}] 
set_false_path -to [get_ports {SCL SDA }]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

