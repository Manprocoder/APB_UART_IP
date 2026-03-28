//==========================================================
//Project: Design APB-UART IP core
//File name: virtual_base_seq_pkg.sv
//Description: virtual sequence package
//==========================================================
package virtual_sequence_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import apb_vip_pkg::*;
	import parameter_pkg::*;
	import sequence_pkg::*;
	import env_cfg_pkg::*;
	import env_pkg::*;
	//base sequence
	class virtual_base_seq extends uvm_sequence#(uvm_sequence_item);
		`uvm_object_utils(virtual_base_seq)
		`uvm_declare_p_sequencer(virtual_sequencer)
		//env_config env_cfg_h;
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
//
//reset sequence
//
	class virtual_seq extends virtual_base_seq;
		`uvm_object_utils(virtual_seq)
		parameter SYS_CLK = 50_000_000;
		parameter OVERSAMPLE = 16;
		parameter BAUD_RATE = 9600;
		parameter BAUD_RATE_2 = 115200;
		typedef uart_rst_sequence#(DW, APB_AW) rst_seq;
		typedef uart_even_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) uart_even_parity_seq;
		typedef parity_frame_error_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) pe_fe_0_seq;
		typedef parity_frame_error_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE_2) pe_fe_1_seq;
		//
		//reset sequence
		rst_seq rst0_seq_h, rst1_seq_h;
		//read register after reset
		reg_model_rst_seq rm0_rst_seq, rm1_rst_seq;
		//full frame sequence
		uart_even_parity_seq even_parity_seq_h0, even_parity_seq_h1;
		//parity error, frame error, break condition sequence
		pe_fe_0_seq pe_fe_0_seq_h;
		pe_fe_1_seq pe_fe_1_seq_h;
		//
		function new(string name = "virtual_seq");
			super.new(name);
		endfunction
		//
		virtual task body();
			//super.body();//get environment handle  => ILLEGAL instruction
			get_env_handle(); //(*)
			//
			rst0_seq_h = rst_seq::type_id::create("rst0_seq_h");
			rst1_seq_h = rst_seq::type_id::create("rst1_seq_h");
			even_parity_seq_h0 = uart_even_parity_seq::type_id::create("uart0_even_parity_seq");
			even_parity_seq_h1 = uart_even_parity_seq::type_id::create("uart1_even_parity_seq");
			pe_fe_0_seq_h = pe_fe_0_seq::type_id::create("pe_fe_0_seq_h"); 
			pe_fe_1_seq_h = pe_fe_1_seq::type_id::create("pe_fe_1_seq_h"); 
			//
			rm0_rst_seq = reg_model_rst_seq::type_id::create("rm0_rst_seq");
			rm1_rst_seq = reg_model_rst_seq::type_id::create("rm1_rst_seq");
			//from(*) => assign reg model handle 
			even_parity_seq_h0.assign_rm_handle(env_h.reg_model_h[0]);
			even_parity_seq_h1.assign_rm_handle(env_h.reg_model_h[1]);
			pe_fe_0_seq_h.assign_rm_handle(env_h.reg_model_h[0]);
			pe_fe_1_seq_h.assign_rm_handle(env_h.reg_model_h[1]);
			//
			even_parity_seq_h0.en_tx_rx_operation(2'b10);//disable RX of UART0
			even_parity_seq_h1.en_tx_rx_operation(2'b01);//disable TX of UART1---> only care RX
			pe_fe_0_seq_h.en_tx_rx_operation(2'b10);//disable RX of UART0---> only care TX
			pe_fe_1_seq_h.en_tx_rx_operation(2'b01);//disable TX of UART1---> only care RX
			//
			rm0_rst_seq.set_rm_handle_and_sequencer(env_h.reg_model_h[0], p_sequencer.apb_sqr_h[0]);
			rm1_rst_seq.set_rm_handle_and_sequencer(env_h.reg_model_h[1], p_sequencer.apb_sqr_h[1]);
	//=====end of assigning reg model and sequencer handle =========
			//
			//run sequences
			//
			`uvm_info(get_full_name(), "pre-run uart0 reset sequence!!!", UVM_HIGH)
			rst0_seq_h.start(p_sequencer.apb_sqr_h[0]);
			`uvm_info(get_full_name(), "finish uart0 reset sequence!!!", UVM_HIGH)
			rst1_seq_h.start(p_sequencer.apb_sqr_h[1]);
			`uvm_info(get_full_name(), "finish uart1 reset sequence!!!", UVM_HIGH)
			//run built-in RAL reset sequence
			fork
				rm0_rst_seq.body();
				rm1_rst_seq.body();
			join
			//
			`uvm_info(get_full_name(), "[VIRTUAL_SEQ]Built-in reset sequence DONE!!!", UVM_HIGH)
			//run main sim
			fork
				even_parity_seq_h0.start(p_sequencer.apb_sqr_h[0]);
				//---write 8 TX_DATA to DUT => expect TX_FULL bit is HIGH
				//---disable TX_sub_module of UART1 => expects
				//RD_UD bit is HIGH
				even_parity_seq_h1.start(p_sequencer.apb_sqr_h[1]);
				//---wait the 8-TX_DATA shift process of
				//UART1 to complete before read RX_FIFO =>
				//expects RX_FULL bit is HIGH,
				//expects RX_NOT_EMPTY bit is HIGH
				//expects RX_NOT_EMPTY bit is SLOW after read
				//all RX_DATA out
			join
			`uvm_info(get_type_name(), $sformatf("[TEST_CASE_ONE]DONE time = %0t", $time), UVM_LOW)
			//
			fork
				pe_fe_0_seq_h.start(p_sequencer.apb_sqr_h[0]);
				pe_fe_1_seq_h.start(p_sequencer.apb_sqr_h[1]);
			join 
			//disable fork;
			//pe_fe_0_seq_h runs on baud rate of 9600
			//pe_fe_1_seq_h runs on baud rate of 115_200
			//--after reading RXD of second thread, the continuous
			//operation of first one has no meaning, so we use
			//a mix of join_any and disable fork to save
			//simulation time
			`uvm_info(get_type_name(), $sformatf("[TEST_CASE_SECOND]DONE time = %0t", $time), UVM_LOW)
			//
		endtask
	endclass
endpackage 
