//==================================================================================
//Project: Design UART IP
//File name: uart_vip_pkg.sv
//Description:
//--TB  
//--uart vip
//==================================================================================
package uart_vip_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
//==================================================================================
//-------------------------UART Sequence Item
//==================================================================================
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
//==================================================================================
//-------------------------UART Sequence
//==================================================================================
class uart_seq extends uvm_sequence#(uart_seq_item);
	`uvm_object_utils(uart_seq)
	//
	//variables
	//
	
	//
	function new (string name = "uart_seq");
		super.new(name);
	endfunction	
endclass
//==================================================================================
//-------------------------UART Monitor 
//==================================================================================
class uart_monitor extends uvm_monitor;
	`uvm_component_utils(uart_monitor)
	//parameters
	parameter OVERSAMPLE = 16;
	parameter UART_DW = 16;
	//
	//virtual interface
	//
	virtual interface uart_if uart_vif;	
	//ports
	uvm_analysis_port#(uart_seq_item) tx_to_scb_ap;
	uvm_analysis_port#(uart_seq_item) rx_to_scb_ap;
	//
	uart_seq_item tx_item, rx_item;
	//
	//-------------handle configuration
	//
	typedef struct{
		bit [UART_DW-1:0] brr_value;
		bit have_parity;
	} ctrl_info;
	//
	ctrl_info ctrl_info_h;
	uvm_put_port#(ctrl_info) put_port;
	uvm_get_port#(ctrl_info) get_port;
	uvm_tlm_fifo#(ctrl_info) ctrl_tlm_fifo;
	//others
	bit parity_exist;
	bit [UART_DW-1:0] clk_used_per_bit;
	//second thread of run_phase task
	logic [UART_DW-1:0] rx_brr_value;
	bit rx_parity_exist;
	ctrl_info ctrl_info_h2;
	bit config_avail_flag;
	int k;
	//
	function new (string name = "uart_monitor", uvm_component parent = null);
		super.new(name, parent);
	endfunction	
	//
	virtual function void build_phase(uvm_phase phase);
		//super.build_phase(phase);
		//get vif
		if(!uvm_config_db#(virtual interface uart_if)::get(this, "", "uart_if", uart_vif)) begin
			`uvm_fatal(get_full_name(), "UART_VIF not FOUND!!!")
		end
		//
		tx_to_scb_ap = new("tx_to_scb_ap", this);
		rx_to_scb_ap = new("rx_to_scb_ap", this);
		put_port = new("put_port", this);
		get_port = new("get_port", this);
		ctrl_tlm_fifo = new("CONTROL_TLM_FIFO", this, 2);
		k = 0;
	endfunction
	//
	virtual function void connect_phase(uvm_phase phase);
		this.put_port.connect(ctrl_tlm_fifo.put_export);
		this.get_port.connect(ctrl_tlm_fifo.get_export);
	endfunction
	//
	virtual task run_phase(uvm_phase phase);
		fork
		forever begin
			@(negedge uart_vif.rst_n);
			disable fork;
			`uvm_info(get_type_name(), "[UART_MONITOR]: Reset_n is active!!!", UVM_LOW)
		end
		//
		forever begin: CAPTURE_UART_CONTROL
			wait(uart_vif.rst_n == 1'b1);	
			fork
			capture_parity(parity_exist);
			capture_brr(clk_used_per_bit);
			join
			`uvm_info(get_type_name(), "[UART_CTRL_INFO]CAPTURED!!!", UVM_MEDIUM)
			//
			ctrl_info_h.brr_value = clk_used_per_bit - 1'b1;
			ctrl_info_h.have_parity = parity_exist;
			//
			if(!ctrl_tlm_fifo.try_put(ctrl_info_h)) begin
				`uvm_error(get_type_name(), "CTRL_TLM_FIFO is FULL!!!")
			end
		end
		//--------------------------------------------//
		forever begin: MONITOR_RX
			wait(uart_vif.rst_n == 1'b1);	
			if(rx_brr_value === {UART_DW{1'bx}} || (config_avail_flag == 1'b1)) begin
				while(1) begin
					@(uart_vif.uart_mon_cb);
					if(ctrl_tlm_fifo.try_get(ctrl_info_h2)) begin
						break;
					end
				end
				//
				config_avail_flag = 0;
				`uvm_info(get_type_name(), "[UART_CTRL_INFO]RECEIVED!!!", UVM_MEDIUM)
				rx_brr_value = ctrl_info_h2.brr_value;
				rx_parity_exist = ctrl_info_h2.have_parity;
				display(ctrl_info_h2);
			end
			//else begin
				//if(ctrl_tlm_fifo.try_get(ctrl_info_h2)) begin
					//rx_brr_value = ctrl_info_h2.brr_value;
					//rx_parity_exist = ctrl_info_h2.have_parity;
					//`uvm_info(get_type_name(), "[RUNNING]Succeed to get new UART control info", UVM_LOW)
					//display(ctrl_info_h2);
				//end
			//end
			`uvm_info(get_type_name(), "CALL monitor task!!!", UVM_MEDIUM)
			//
			monitor(rx_brr_value, rx_parity_exist, config_avail_flag);
		end
		join_none
	endtask
	//
	//collect rx
	//
	virtual task monitor(input bit [UART_DW-1:0] brr_value, input bit parity_exist, output bit config_avail_flag);
		fork
			begin
			@(uart_vif.uart_mon_cb iff (uart_vif.uart_mon_cb.ctrl_valid || uart_vif.uart_mon_cb.brr_valid));
			`uvm_info(get_type_name(), "NEW CONFIG exists!!!", UVM_MEDIUM)
			config_avail_flag = 1;
			end
			//
			begin
			collect_rx(rx_brr_value, rx_parity_exist);
			end
		join_any
		disable fork; //as new configuration exist, process exists right away
	endtask
	//
	//capture control
	//
	virtual task capture_parity(output bit parity_enable);
		@(uart_vif.uart_mon_cb iff uart_vif.uart_mon_cb.ctrl_valid);
		parity_enable = uart_vif.uart_mon_cb.parity_en;
		//
		`uvm_info(get_type_name(), 
		$sformatf("[CAPTURE_PARITY] time = %0t---parity_enable = %0b", $time, parity_enable), UVM_MEDIUM)
	endtask
	//
	//
	virtual task capture_brr(output bit [UART_DW-1:0] clk_per_bit);
		@(uart_vif.uart_mon_cb iff uart_vif.uart_mon_cb.brr_valid);
		clk_per_bit = uart_vif.uart_mon_cb.clk_per_bit;
		//
		`uvm_info(get_type_name(), 
		$sformatf("[CAPTURE_CTRL] clk_per_bit = %08h!!!", clk_per_bit), UVM_MEDIUM)
	endtask
	//====================================================================================
	//--------------------collect data 
	//====================================================================================
	//---2: RX
	virtual task collect_rx(input bit [UART_DW-1:0] brr_value, input bit parity_exist);
		@(uart_vif.uart_mon_cb iff ~uart_vif.uart_mon_cb.rx);
		`uvm_info(get_full_name(), $sformatf("Time = %0t---SAMPLE_RX PROCESS START!!!", $time), UVM_MEDIUM)
		//wait sample first rx bit
		wait_clk_per_bit(brr_value);
		`uvm_info(get_full_name(), $sformatf("Time = %0t---PREPARE SAMPLING FIRST_BIT RX_DATA!!!", $time), UVM_LOW)
		//sample rx_data
		rx_item = uart_seq_item::type_id::create("rx_item");
		//
		for(int i = 0; i < 8; i++) begin
			//
			repeat(2) wait_clk_per_bit(brr_value);
			rx_item.rx_data[i] = uart_vif.uart_mon_cb.rx; 
		end
		`uvm_info(get_full_name(), $sformatf("Time = %0t---SAMPLE RX_DATA DONE!!!", $time), UVM_MEDIUM)
		//sample PARITY bit and STOP bit
		repeat(2) wait_clk_per_bit(brr_value);
		if(parity_exist) begin
			`uvm_info(get_full_name(), $sformatf("Time = %0t---SAMPLE PARITY_BIT!!!", $time), UVM_MEDIUM)
			rx_item.parity_bit = uart_vif.uart_mon_cb.rx; 
			repeat(2) wait_clk_per_bit(brr_value);
			`uvm_info(get_full_name(), $sformatf("Time = %0t---SAMPLE STOP BIT!!!", $time), UVM_MEDIUM)
			rx_item.stop_bit = uart_vif.uart_mon_cb.rx; 
		end
		else begin
			rx_item.stop_bit = uart_vif.uart_mon_cb.rx; 
		end
		rx_to_scb_ap.write(rx_item);
		`uvm_info(get_full_name(), "WRITE RX_DATA, PARITY_BIT, STOP_BIT", UVM_LOW)
		rx_item.print();
		`uvm_info(get_full_name(), $sformatf("RX_Item[%0d]", ++k), UVM_LOW)
		//
	endtask
	//
	//====================================================================================
	//--------------------------------end of collecting data 
	//====================================================================================
	//
	virtual function void display(input ctrl_info ctrl_info_ref);
		`uvm_info(get_type_name(), $sformatf("BRR = %04h", ctrl_info_ref.brr_value), UVM_LOW);
		`uvm_info(get_type_name(), $sformatf("HAVE_PARITY = %0b", ctrl_info_ref.have_parity), UVM_LOW);
	endfunction
	//
	//
	virtual task wait_clk_per_bit(input bit [UART_DW-1:0] brr_value);
		for(int i = 0;i < OVERSAMPLE/2; i++) begin
			repeat(brr_value) @(uart_vif.uart_mon_cb);
		end
	endtask
endclass
//==================================================================================
//-------------------------UART Agent
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
//
endpackage
