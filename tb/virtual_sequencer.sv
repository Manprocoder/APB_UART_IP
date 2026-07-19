//=====================================================================
//Project: Design and verify APB UART IP 
//File name: virtual_sequencer.sv
//Author: Nguyen Ngoc Man
//Description: this class contains ALL SEQUENCERs in environment 
//=====================================================================
import apb_pkg::*;
//
class virtual_sequencer extends uvm_sequencer#(uvm_sequence_item);
    `uvm_component_utils(virtual_sequencer)
    //
    apb_sequencer apb_sqr_h[];
    apb_agent apb_agt_h[];
    //
    function new(string name = "virtual sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
