//==========================================================
//Project: Design and verify APB UART IP 
//File name: test_pkg.sv
//Author: Nguyen Ngoc Man
//Description: this package contains all test cases of UART 
//==========================================================
package test_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "base_test.sv"
    `include "reset_test.sv"
    `include "no_parity_test.sv"
    `include "parity_type_test.sv"
    `include "fe_pe_brk_con_test.sv"
endpackage
