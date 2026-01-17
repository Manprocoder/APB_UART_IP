//==========================================================
//Project: Design APB-UART IP core
//File name: env_cfg_pkg.sv
//Description: env config
//==========================================================
package env_cfg_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import apb_vip_pkg::*;
	//
	//config
	//
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
	//
	//virtual sequencer
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
endpackage
