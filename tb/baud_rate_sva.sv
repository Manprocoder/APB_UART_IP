//==========================================================================
//Project: Design and Verify APB UART IP
//File: baud_rate_sva.sv
//Author: Nguyen Ngoc Man
//Description: this module take a role of checking cnt of baud rate 
//==========================================================================
module baud_rate_sva(clk, rst_n, en, baud_tick, cnt);
input logic clk;
input logic rst_n;
input logic en;
input logic baud_tick;
input logic [15:0] cnt;
//
    property check_rst_value;
        @(posedge clk) ~rst_n |=> (cnt == 0); 
    endproperty
    //
    property check_cnt;
        @(posedge clk) disable iff (~rst_n) 
        (en | baud_tick) |=> ##1 ((cnt != 0) throughout (cnt == $past(cnt - 1'b1)));
    endproperty
    //
    assert property (check_rst_value);
    assert property (check_cnt);
endmodule
//
