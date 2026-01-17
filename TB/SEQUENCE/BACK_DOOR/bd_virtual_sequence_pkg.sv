//==========================================================
//Project: Design APB-UART IP core
//File name: bd_virtual_sequence.sv 
//Description: virtual sequence has back door access
//==========================================================
package bd_virtual_sequence_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import sequence_pkg::*;
	import bd_sequence_pkg::*;
	import parameter_pkg::*;
	import virtual_sequence_pkg::*;
	//
	class bd_virtual_sequence extends virtual_base_seq; 
		`uvm_object_utils(bd_virtual_sequence)
		//
		parameter FREQUENCY = 50_000_000;
		parameter OVERSAMPLE = 16;
		parameter BAUD_RATE = 9600;
		typedef uart_rst_sequence#(DW, APB_AW) rst_seq;
		typedef full_frame_9600_backdoor_seq#(FREQUENCY, OVERSAMPLE, BAUD_RATE) full_fr_bd_seq;
		//
		rst_seq rst0_seq_h, rst1_seq_h;
		full_fr_bd_seq full_frame_bd_seq_h0, full_frame_bd_seq_h1;
		//
		function new(string name = "bd_virtual_sequence");
			super.new(name);
		endfunction
		//
		virtual task body();
			get_env_handle(); //(*)
			//
			rst0_seq_h = rst_seq::type_id::create("rst0_seq_h");
			rst1_seq_h = rst_seq::type_id::create("rst1_seq_h");
			full_frame_bd_seq_h0 = full_fr_bd_seq::type_id::create("full_frame_bd_seq_h0");
			full_frame_bd_seq_h1 = full_fr_bd_seq::type_id::create("full_frame_bd_seq_h1");
			//
			//from(*) => assign reg model handle 
			full_frame_bd_seq_h0.assign_rm_handler(env_h.reg_model_h[0]);
			full_frame_bd_seq_h1.assign_rm_handler(env_h.reg_model_h[1]);
			//run
			rst0_seq_h.start(p_sequencer.apb_sqr_h[0]);
			`uvm_info(get_full_name(), "finish uart0 reset sequence!!!", UVM_MEDIUM)
			rst1_seq_h.start(p_sequencer.apb_sqr_h[1]);
			`uvm_info(get_full_name(), "finish uart1 reset sequence!!!", UVM_MEDIUM)
			//
			//run main sim
			fork
				full_frame_bd_seq_h0.start(p_sequencer.apb_sqr_h[0]);
				full_frame_bd_seq_h1.start(p_sequencer.apb_sqr_h[1]);
			join
			`uvm_info(get_full_name(), "TEST_CASE DONE!!!", UVM_MEDIUM)
		endtask
	endclass
endpackage
