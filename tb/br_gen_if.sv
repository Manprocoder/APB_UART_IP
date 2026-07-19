
//==========================================================================
//Project: Design and Verintfy APB UART IP
//File: br_gen_int.sv
//Author: Nguyen Ngoc Man
//Description
//==========================================================================
interface br_gen_if;
    //
    logic clk;
    logic rst_n;
    logic enable;
    logic baud_tick;
    logic [15:0] counter;
endinterface
