onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {TOP LEVEL INPUTS}
#add wave -noupdate -format Literal -radix hex sim:/test_cpu/c1/*
add wave -noupdate -format Literal -radix hex sim:/test_cpu/c1/clk
add wave -noupdate -format Literal -radix hex sim:/test_cpu/c1/rst
add wave -noupdate -format Literal -radix hex sim:/test_cpu/c1/ram/ram
add wave -position end  sim:/test_cpu/c1/INCFEQCSZ
add wave -position end  sim:/test_cpu/c1/port_c_out
add wave -position end  sim:/test_cpu/c1/w_q
add wave -position end  sim:/test_cpu/c1/GOTO
add wave -position end  sim:/test_cpu/c1/pc_q
add wave -position end  sim:/test_cpu/c1/ps
#add wave -noupdate -format Literal -radix unsigned  /test_FileName/test_Signal
# -radix後接型態 十進位 decimal, 1bit logic, 十六進位 hex, 二進位 binary, 正整數 unsigned

