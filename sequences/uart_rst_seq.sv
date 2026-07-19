//==================================================================
//--Project: Design and verify  APB-UART IP 
//--File name: uart_rst_seq.sv
//--Author: Nguyen Ngoc Man
//--Description
//==================================================================
class uart_rst_sequence extends uart_base_seq;
	`uvm_object_utils(uart_rst_sequence)
	//
	function new(string name = "uart_rst_sequence");
		super.new(name);
	endfunction
	//
	virtual task body();
		`uvm_info(get_type_name(), "[START]--inside body", UVM_MEDIUM)
		rst_item = apb_seq_item::type_id::create("uart_rst_item");
		//
		start_item(rst_item);
		rst_item.resetn_req = 1;
		finish_item(rst_item);
		get_response(rst_item);
		`uvm_info(get_type_name(), "[DONE]--inside body", UVM_MEDIUM)
		//
	endtask
endclass
