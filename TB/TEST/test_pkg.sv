//==========================================================
//Project: Design APB-UART IP core
//File name: test_pkg.sv
//Description: test package
//==========================================================
package test_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import parameter_pkg::*;
import sequence_pkg::*;
import virtual_sequence_pkg::*;
//import bd_sequence_pkg::*;
//import bd_virtual_sequence_pkg::*;
import env_pkg::*;
import env_cfg_pkg::*;
//
//critical note: because of being in package, it cannot access to non-package classes,
//-- so we must pack all necessary classes 
//
class base_test extends uvm_test;
	`uvm_component_utils(base_test)
	//
	my_env env_h;
	env_config env_cfg_h;
	virtual_seq v_seq_h; 
	//
	function new (string name = "base_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	//
	virtual function void build_phase(uvm_phase phase);
		//instantiate comps
		super.build_phase(phase);
		env_h = my_env::type_id::create("env_h", this);
		env_cfg_h = env_config::type_id::create("env_cfg_h");
		//
		uvm_config_db#(env_config)::set(this, "env_h", "env_cfg", env_cfg_h);
	endfunction
	//
	virtual function void init_vseq(virtual_base_seq vseq);
		for(int i = 0; i < env_cfg_h.no_of_agent; i++) begin
			vseq.apb_sqr_h[i] = env_h.apb_agt_h[i].apb_sqr_h;	
		end
	endfunction
	//
	virtual function void start_of_simulation_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction
	//
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		v_seq_h = virtual_seq::type_id::create("v_seq_h");
		//
	       `uvm_info(get_type_name(), "PREPARE FOR SIMULATION!!!", UVM_HIGH)
		phase.raise_objection(this);
	       `uvm_info(get_type_name(), "START SIMULATION!!!", UVM_HIGH)
	       //fork 
	       //begin
		       if(env_cfg_h.has_virtual_sequencer) begin
			       v_seq_h.start(env_h.vsqr_h);
			end
			else begin
				init_vseq(v_seq_h); //assign sequencer in virtual sequence to actual exising sequencer
				v_seq_h.start(null);
			end
		       //#`SIM_TIME;
			phase.phase_done.set_drain_time(this, `SIM_TIME/2);
		       `uvm_info(get_type_name(), "SIMULATION_THREAD DONE!!!", UVM_HIGH)
       		//end
		//begin: TIMEOUT_BREAK
			//#10ms;
			//`uvm_info(get_type_name(), "=================================================================", UVM_LOW)
			//`uvm_info(get_type_name(), "============TIMEOUT---TIMEOUT----TIMEOUT---10ms ends=============", UVM_LOW)
			//`uvm_info(get_type_name(), "=================================================================", UVM_LOW)
			//$finish;
		//end
		//join_any
		//disable fork;
		phase.drop_objection(this);
	endtask
endclass
//
class full_frame_test extends base_test;
	`uvm_component_utils(full_frame_test)
	//
	function new (string name = "full_frame_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	//
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
	//
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
	endtask
endclass
//
endpackage
