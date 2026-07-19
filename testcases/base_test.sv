//==========================================================
//Project: Design and verify APB UART IP 
//File name: base_test.sv
//Author: Nguyen Ngoc Man
//Description: 
//==========================================================
import seq_pkg::*;
import env_pkg::*;
//
//critical note: because of being in package, it cannot access to non-package classes,
//-- so we must pack all necessary classes 
//
virtual class base_test extends uvm_test;
	`uvm_component_utils(base_test)
	//
	my_env env_h;
	env_config env_cfg_h;
	//
	function new (string name = "base_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	//
	virtual function void build_phase(uvm_phase phase);
		env_h = my_env::type_id::create("env_h", this);
		env_cfg_h = env_config::type_id::create("env_cfg_h");
		//
		uvm_config_db#(env_config)::set(this, "env_h*", "env_cfg", env_cfg_h);
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
	pure virtual task run_phase(uvm_phase phase);
endclass
//
