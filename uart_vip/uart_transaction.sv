//======================================================================
//--Project: Design and verify APB_UART IP
//--File: uart_transaction.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//======================================================================
class uart_seq_item extends uvm_sequence_item;
	`uvm_object_utils(uart_seq_item)
	//
	//variables
	//
	logic [7:0] tx_data;
	logic [7:0] rx_data;
	logic parity_bit;
	logic stop_bit;
	//
	function new (string name = "uart_seq_item");
		super.new(name);
	endfunction	
	//
	function void do_print(uvm_printer printer);
	    //super.do_print(printer);
	    printer.print_field("TX_DATA", tx_data, $bits(tx_data), UVM_HEX);
	    printer.print_field("RX_DATA", rx_data, $bits(rx_data), UVM_HEX);
	    printer.print_field("PARITY_BIT", parity_bit, $bits(parity_bit), UVM_BIN);
	    printer.print_field("STOP_BIT", stop_bit, $bits(stop_bit), UVM_BIN);
	endfunction	
endclass

