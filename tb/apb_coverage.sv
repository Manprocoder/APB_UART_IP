//===============================================================
//Project: Design and Verify APB UART IP
//File: apb_coverage.sv
//Author: Nguyen Ngoc Man
//Description: 
//===============================================================
import apb_pkg::*;
`include "apb_cov_item.sv"
class apb_coverage extends uvm_subscriber#(apb_seq_item);
    `uvm_component_utils(apb_coverage);
    apb_group apb_gr_h;
    //==========================================================
    //--------METHODs
    //==========================================================
    extern function new(string name = "apb_coverage", uvm_component parent);
    extern virtual function void write(apb_seq_item t);
endclass: apb_coverage
    //==========================================================
    //--------IMPLEMENATATION of all METHODs
    //==========================================================
    function apb_coverage::new(string name = "apb_coverage", uvm_component parent);
        super.new(name, parent);
        //
        apb_gr_h = new();
    endfunction
    //
    //-----------BE CAREFUL: we MUST use t here
    //
    function void apb_coverage::write(apb_seq_item t);
       $cast(item, t.clone()); 
       apb_gr_h.sample(); 
    endfunction

