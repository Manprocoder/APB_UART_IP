#==========================================================
#Project: Design APB-UART IP core
#File name: uvm_list.svh 
#Description: contains all UVM components
#==========================================================
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider -height 25 {UART0_VIRTUAL}
add wave -noupdate -bin /tb/uart0_if/clk
add wave -noupdate -bin /tb/uart0_if/ctrl_valid
add wave -noupdate -bin /tb/uart0_if/parity_en
add wave -noupdate -bin /tb/uart0_if/brr_valid
add wave -noupdate -hex /tb/uart0_if/clk_per_bit
add wave -noupdate -divider -height 25 {UART1_VIRTUAL}
add wave -noupdate -bin /tb/uart1_if/clk
add wave -noupdate -bin /tb/uart1_if/ctrl_valid
add wave -noupdate -bin /tb/uart1_if/parity_en
add wave -noupdate -bin /tb/uart1_if/brr_valid
add wave -noupdate -hex /tb/uart1_if/clk_per_bit
add wave -noupdate -divider -height 23 {APB0_INTERFACE}
add wave -noupdate /tb/uart0_wrap/pclk
add wave -noupdate /tb/uart0_wrap/presetn
add wave -noupdate -hex /tb/uart0_wrap/psel
add wave -noupdate -hex /tb/uart0_wrap/penable
add wave -noupdate -hex /tb/uart0_wrap/pwrite
add wave -noupdate -hex /tb/uart0_wrap/paddr
add wave -noupdate -hex /tb/uart0_wrap/pwdata
add wave -noupdate -hex /tb/uart0_wrap/prdata
add wave -noupdate -hex /tb/uart0_wrap/pready
add wave -noupdate -hex /tb/uart0_wrap/apb_inst/cs
add wave -noupdate -hex /tb/uart0_wrap/apb_inst/wr_en_o
add wave -noupdate -hex /tb/uart0_wrap/apb_inst/rd_en_o
add wave -noupdate -hex /tb/uart0_wrap/apb_inst/addr_o
add wave -noupdate -hex /tb/uart0_wrap/apb_inst/wdata_o
add wave -noupdate -hex /tb/uart0_wrap/apb_inst/rdata_i
add wave -noupdate -divider -height 24 {APB1_INTERFACE}
add wave -noupdate /tb/uart1_wrap/pclk
add wave -noupdate /tb/uart1_wrap/presetn
add wave -noupdate -hex /tb/uart1_wrap/psel
add wave -noupdate -hex /tb/uart1_wrap/penable
add wave -noupdate -hex /tb/uart1_wrap/pwrite
add wave -noupdate -hex /tb/uart1_wrap/paddr
add wave -noupdate -hex /tb/uart1_wrap/pwdata
add wave -noupdate -hex /tb/uart1_wrap/prdata
add wave -noupdate -hex /tb/uart1_wrap/pready
add wave -noupdate -hex /tb/uart1_wrap/apb_inst/cs
add wave -noupdate -hex /tb/uart1_wrap/apb_inst/wr_en_o
add wave -noupdate -hex /tb/uart1_wrap/apb_inst/rd_en_o
add wave -noupdate -hex /tb/uart1_wrap/apb_inst/addr_o
add wave -noupdate -hex /tb/uart1_wrap/apb_inst/wdata_o
add wave -noupdate -hex /tb/uart1_wrap/apb_inst/rdata_i
add wave -noupdate -divider -height 25 {UART0_BAUD_TICK}
add wave -noupdate -bin /tb/uart0_wrap/uart_top/enable
add wave -noupdate -hex /tb/uart0_wrap/uart_top/divisor_val
add wave -noupdate -hex /tb/uart0_wrap/uart_top/br_gen_inst/counter
add wave -noupdate -bin /tb/uart0_wrap/uart_top/br_gen_inst/baud_tick_active
add wave -noupdate -divider -height 25 {UART0_INTERFACE}
add wave -noupdate -bin /tb/uart0_wrap/tx
add wave -noupdate -bin /tb/uart0_wrap/rx
add wave -noupdate -bin /tb/uart0_wrap/uart_top/baud_tick
add wave -noupdate -hex /tb/uart0_wrap/uart_top/uart_tmt_inst/shift_cnt
add wave -noupdate -bin /tb/uart0_wrap/uart_top/uart_tmt_inst/shift_en
add wave -noupdate -hex /tb/uart0_wrap/uart_top/uart_tmt_inst/txt_cs
add wave -noupdate -bin /tb/uart0_wrap/uart_top/uart_tmt_inst/tx_fifo_wr
add wave -noupdate -bin /tb/uart0_wrap/uart_top/uart_tmt_inst/tx_fifo_rd
add wave -noupdate -bin /tb/uart0_wrap/uart_top/uart_tmt_inst/tx_fifo_empty
add wave -noupdate -divider -height 24 {UART1_INTERFACE}
add wave -noupdate -bin /tb/uart1_wrap/tx
add wave -noupdate -bin /tb/uart1_wrap/rx
add wave -noupdate -bin /tb/uart1_wrap/uart_top/baud_tick
add wave -noupdate -hex /tb/uart1_wrap/uart_top/uart_rcv_inst/sample_cnt
add wave -noupdate -bin /tb/uart1_wrap/uart_top/uart_rcv_inst/sample_en
add wave -noupdate -hex /tb/uart1_wrap/uart_top/uart_rcv_inst/rx_cs
add wave -noupdate -bin /tb/uart1_wrap/uart_top/uart_rcv_inst/rx_fifo_wr
add wave -noupdate -hex /tb/uart1_wrap/uart_top/uart_rcv_inst/rx_fifo_i
add wave -noupdate -bin /tb/uart1_wrap/uart_top/uart_rcv_inst/rx_fifo_empty
add wave -noupdate -bin /tb/uart1_wrap/uart_top/uart_rcv_inst/rx_fifo_full
add wave -noupdate -bin /tb/uart1_wrap/uart_top/uart_rcv_inst/rx_fifo_rd
add wave -noupdate -hex /tb/uart1_wrap/uart_top/uart_rcv_inst/rx_fifo_o
add wave -noupdate -divider -height 24 {UART1_REG_BANK}
add wave -noupdate -bin /tb/uart1_wrap/uart_top/uart_reg_bank_inst/rx_not_empty_i
#add wave -noupdate -divider -height 25 {APB0_DRIVER}
#add wave -noupdate /uvm_root/uvm_test_top/env_h/apb_agt_h0/apb_drv_h/active_low_rst
#add wave -noupdate -divider -height 25 {APB1_DRIVER}
#add wave -noupdate /uvm_root/uvm_test_top/env_h/apb_agt_h1/apb_drv_h/active_low_rst
#add wave -noupdate -divider -height 25 {SCOREBOARD_CHK}
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/uart_01_match
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/uart_01_mismatch
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/data_match
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/data_mismatch
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/apb0_match
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/apb0_mismatch
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/apb1_match
#add wave -noupdate -radix unsigned -radixshowbase 0 /uvm_root/uvm_test_top/env_h/scb/apb1_mismatch
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {925 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1050 ns}
