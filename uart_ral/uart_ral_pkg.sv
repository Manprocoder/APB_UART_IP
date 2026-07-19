//==================================================================================
//Project: Design and Veify APB UART IP
//File: uart_ral_pkg.sv
//Author: Nguyen Ngoc Man
//Description:
//==================================================================================
package uart_ral_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "config.sv"
    `include "uart_reg.sv"
    `include "ctrl_reg_cbs.sv"
    `include "status_reg_cbs.sv"
    `include "div_reg_cbs.sv"
    `include "uart_reg_adapter.sv"
    `include "uart_reg_block.sv"
endpackage: uart_ral_pkg
