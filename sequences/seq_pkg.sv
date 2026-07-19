//==========================================================
//Project: Design and Verify APB UART IP 
//File name: seq_pkg.sv
//Author: Nguyen Ngoc Man
//Description:  
//==========================================================
package seq_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "tx_generator.sv"
    `include "uart_base_seq.sv"
    `include "uart_rst_seq.sv"
    `include "reg_model_rst_seq.sv"      
    `include "no_parity_seq.sv"      
    `include "even_parity_seq.sv"      
    `include "odd_parity_seq.sv"      
    `include "fr_par_brk_err_seq.sv"      
    `include "virtual_base_seq.sv"
    `include "virtual_rst_seq.sv"
    `include "virtual_no_parity_seq.sv"      
    `include "virtual_parity_type_seq.sv"      
    `include "virtual_fr_par_brk_err_seq.sv"      
endpackage: seq_pkg
