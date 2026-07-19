//==========================================================================
//Project: Design and Verintfy APB UART IP
//File: baud_rate_sva_top.sv
//Author: Nguyen Ngoc Man
//Description: this module take a role of checking counter of baud rate 
//==========================================================================
module baud_rate_sva_top(br_gen_if intf);
    baud_rate_sva bd_sva_inst();
    //
    assign bd_sva_inst.clk = intf.clk;
    assign bd_sva_inst.rst_n = intf.rst_n;
    assign bd_sva_inst.en = intf.enable;
    assign bd_sva_inst.baud_tick = intf.baud_tick;
    assign bd_sva_inst.cnt = intf.counter;
endmodule
