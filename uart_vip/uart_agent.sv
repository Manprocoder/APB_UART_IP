//==================================================================================
//--Project: Design and Verify APB_UART IP
//--File name: uart_agent.sv
//--Author: Nguyen Ngoc Man
//--Description:
//==================================================================================
class uart_agent extends uvm_agent;
	`uvm_component_utils(uart_agent)
	//
	//sub components
	//
	uart_monitor uart_mon_h;
	//
	function new(string name = "uart_agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	//
	virtual function void build_phase(uvm_phase phase);
		//super.build_phase(phase);
		uart_mon_h = uart_monitor::type_id::create("uart_mon_h", this);
	endfunction
endclass
