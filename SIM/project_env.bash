#!/bin/bash -f



# UVM root path
#export UVM_HOME=/drives/c/questasim64_10.7c/verilog_src/uvm-1.2




export UVM_HOME=C:/questasim64_10.7c/verilog_src/uvm-1.2

# Verify root path
export APB_UART_VIP_VERIF_PATH=./..

# VIP root path
export APB_VIP_ROOT=$APB_UART_VIP_VERIF_PATH/apb_vip
export UART_VIP_ROOT=$APB_UART_VIP_VERIF_PATH/uart_vip
