//==================================================================================
//--Project: Design and Verify APB_UART IP
//--File name: uart_pkg.sv
//--Author: Nguyen Ngoc Man
//--Description:
//==================================================================================
package uart_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "uart_transaction.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"
endpackage
