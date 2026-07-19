//==================================================================
//--Project: Design and verify  APB-UART IP 
//--File name: reg_model_rst_seq.sv
//--Author: Nguyen Ngoc Man
//--Description: built-in reset sequence of reg model
//==================================================================
class reg_model_rst_seq extends uvm_reg_hw_reset_seq;
	`uvm_object_utils(reg_model_rst_seq)
	//
	uart_reg_model reg_model_h;
	apb_sequencer sqr_h;
	//
	function new(string name = "reg_model_rst_seq");
		super.new(name);
	endfunction
	//
	virtual function void set_rm_handle_and_sequencer(uart_reg_model rm_h, apb_sequencer sqr_ref);
		this.reg_model_h = rm_h;
		this.sqr_h = sqr_ref;
	endfunction	
	//
	virtual task body();
		uvm_reg_hw_reset_seq rst_seq;
		//
		//--> ignore TXD reg as verifying after-reset state
		//--1: tx_fifo
		uvm_resource_db #(bit)::set({"REG::", 
		reg_model_h.TX_DATA.get_full_name()}, "NO_REG_HW_RESET_TEST", 1); 
		//--2: rx_fifo
		uvm_resource_db #(bit)::set({"REG::", 
		reg_model_h.RX_DATA.get_full_name()}, "NO_REG_HW_RESET_TEST", 1); 
		//
		rst_seq = uvm_reg_hw_reset_seq::type_id::create("reg_model_rst_seq");
		rst_seq.model = reg_model_h;
		rst_seq.start(sqr_h);
		`uvm_info(get_type_name(), "BUILT-IN RAL RESET SEQUENCE DONE!!!", UVM_MEDIUM)
	endtask
endclass
