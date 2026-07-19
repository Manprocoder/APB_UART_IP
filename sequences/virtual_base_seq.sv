//==========================================================
//Project: Design and Verify APB UART IP 
//File name: virtual_base_seq.sv
//Author: Nguyen Ngoc Man
//Description:  
//==========================================================
import env_pkg::*;
import apb_pkg::*;
//base sequence
class virtual_base_seq extends uvm_sequence#(uvm_sequence_item);
    `uvm_object_utils(virtual_base_seq)
    `uvm_declare_p_sequencer(virtual_sequencer)
    //
    apb_sequencer apb_sqr_h[]; //applied for using virtual sequence
    //handle array is assigned from test package
    my_env env_h;
    //
    //
    function new(string name = "virtual_base_seq");
        super.new(name);
    endfunction
    //
    virtual function void get_env_handle();
        if(!$cast(env_h, uvm_top.find("uvm_test_top.env_h"))) begin
            `uvm_error(get_type_name(), "env_h is not found");
        end
    endfunction
endclass
