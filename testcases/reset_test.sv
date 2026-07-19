
//==========================================================
//Project: Design and verify APB UART IP 
//File name: reset_test.sv
//Author: Nguyen Ngoc Man
//Description: 
//==========================================================
import seq_pkg::*;
import env_pkg::*;
//
//critical note: because of being in package, it cannot access to non-package classes,
//-- so we must pack all necessary classes 
//
class reset_test extends base_test;
	`uvm_component_utils(reset_test)
	//
	virtual_rst_seq v_seq_h; 
	//
	function new (string name = "reset_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
    //
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
	//
	virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
	endfunction
    //
	virtual task run_phase(uvm_phase phase);
		v_seq_h = virtual_rst_seq::type_id::create("v_seq_h");
		//
       `uvm_info(get_type_name(), "PREPARE FOR SIMULATION!!!", UVM_HIGH)
		phase.raise_objection(this);
       `uvm_info(get_type_name(), "START SIMULATION!!!", UVM_HIGH)
       fork 
       begin: RUN
           if(env_cfg_h.has_virtual_sequencer) begin
               v_seq_h.start(env_h.vsqr_h);
			end
			else begin
				init_vseq(v_seq_h); //assign sequencer in virtual sequence to actual exising sequencer
				v_seq_h.start(null);
			end
           #1000;
        end:RUN
		begin: TIMEOUT
			#10ms;
			`uvm_info(get_type_name(), "=================================================================", UVM_LOW)
			`uvm_info(get_type_name(), "============TIMEOUT---TIMEOUT----TIMEOUT---10ms ends=============", UVM_LOW)
			`uvm_info(get_type_name(), "=================================================================", UVM_LOW)
		end: TIMEOUT 
		join_any
		disable fork;
		phase.drop_objection(this);
	endtask
    //
    virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_type_name(), "===========================RESET_TEST_REPORT=====================", UVM_LOW)
    `uvm_info(get_type_name(), "=================================================================", UVM_LOW)
    `uvm_info(get_full_name(), $sformatf("[CTRL_CMP__]PASS: %0d---FAIL: %0d", env_h.ctrl_cbs_h.no_pass, env_h.ctrl_cbs_h.no_fail), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("[STATUS_CMP]PASS: %0d---FAIL: %0d", env_h.status_cbs_h.no_pass, env_h.status_cbs_h.no_fail), UVM_MEDIUM)
    `uvm_info(get_full_name(), $sformatf("[DIV_CMP___]PASS: %0d---FAIL: %0d", env_h.div_cbs_h.no_pass, env_h.div_cbs_h.no_fail), UVM_MEDIUM)
    endfunction
endclass
//
