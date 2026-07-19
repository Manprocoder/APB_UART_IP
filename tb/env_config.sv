//==========================================================
//Project: Design and verify APB UART IP 
//File name: env_config.sv
//Author: Nguyen Ngoc Man
//Description: 
//==========================================================
class env_config extends uvm_object;
    `uvm_object_utils(env_config)
    //data members
    bit scoreboard = 1;
    bit has_virtual_sequencer = 1;
    int no_of_agent = 2;
    //
    function new(string name = "env_config");
        super.new(name);
    endfunction
endclass
