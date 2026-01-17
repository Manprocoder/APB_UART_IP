//==========================================================
//Project: Design APB-UART IP core
//File name: backdoor_pkg.sv
//Description: backdoorsequence package
//==========================================================
package bd_sequence_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import sequence_pkg::*;
import parameter_pkg::*;
//
class full_frame_9600_backdoor_seq#(FREQUENCY = 50_000_000, OVERSAMPLE = 16, BAUD_RATE = 9600) extends uart_base_seq#(DW, APB_AW);
	`uvm_object_param_utils(full_frame_9600_backdoor_seq#(FREQUENCY, OVERSAMPLE, BAUD_RATE))
	parameter BRR_VALUE = FREQUENCY/(BAUD_RATE*OVERSAMPLE)-1;
	//
	function new(string name = "full_frame_9600_backdoor_seq");
		super.new(name);
	endfunction
	//
	virtual task body();
		uvm_reg_data_t wdata;
		uvm_status_e status_h;
		//============================================
		//set up control register
		//============================================
		assert(rm_h.CTRL.randomize() with {
			rm_h.CTRL.parity_case == 2'b01;
			rm_h.CTRL.interrupt_en == 0;}
		); //even parity and no interrupt
		//
		wdata = rm_h.CTRL.get();	
		rm_h.CTRL.poke(status_h, wdata);	
		`uvm_info(get_type_name(), $sformatf("[BACKDOOR]WRITE CONTROL DONE---STATUS = %s!!!", status_h), UVM_MEDIUM)
		//============================================
		//set up tx_data register
		//============================================
		//assert(rm_h.TXD.randomize() with {rm_h.TXD.tx_data_case == 2'b10;}); //even one_bit
		////
		//wdata = rm_h.TXD.get();	
		//rm_h.TXD.poke(status_h, wdata);	
		//`uvm_info(get_type_name(), $sformatf("[BACKDOOR]WRITE TX_DATA DONE---STATUS = %s!!!", status_h), UVM_MEDIUM)
		//============================================
		//set up BBR
		//============================================
		$cast(wdata, BRR_VALUE);
		rm_h.DIV.poke(status_h, wdata);	
		`uvm_info(get_type_name(), $sformatf("[BACKDOOR]WRITE BRR_VALUE DONE---STATUS = %s!!!", status_h), UVM_MEDIUM)
		
	endtask
endclass
endpackage
