//==================================================================================
//Project: Design and Verify APB UART IP
//File name: env_pkg.sv
//Author: Nguyen Ngoc Man
//Description:
//==================================================================================
package env_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "env_config.sv"
    `include "apb_coverage.sv"
    `include "virtual_sequencer.sv"
    `include "apb_uart_scoreboard.sv"  
    `include "env.sv" 
endpackage

