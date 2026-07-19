//===============================================================
//Project: Design and Verify APB UART IP
//File: apb_checker_top.sv
//Author: Nguyen Ngoc Man
//Description: this module is used for checking APB VIP
//===============================================================
module apb_checker_top (apb_if apb_bus);
  //Checker connection
  apb_checker apb_checker();
  //parameter
  //
    assign apb_checker.pclk     = apb_bus.pclk;
    assign apb_checker.presetn  = apb_bus.presetn;
    assign apb_checker.psel     = apb_bus.psel;
    assign apb_checker.penable  = apb_bus.penable;
    assign apb_checker.pwrite   = apb_bus.pwrite;
    assign apb_checker.paddr    = apb_bus.paddr;
    assign apb_checker.pwdata   = apb_bus.pwdata;
    assign apb_checker.pstrb    = apb_bus.pstrb;
    assign apb_checker.prdata   = apb_bus.prdata;
    assign apb_checker.pready   = apb_bus.pready;
    assign apb_checker.pslverr  = apb_bus.pslverr;
endmodule
 
