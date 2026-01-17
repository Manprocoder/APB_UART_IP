//==========================================================
//Project: Design APB-UART IP core
//File name: scoreboard.sv 
//Description: scoreboard 
//==========================================================
package scoreboard_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import apb_vip_pkg::*;
import uart_vip_pkg::*;
import parameter_pkg::*;
import env_cfg_pkg::*;
import uart_ral_pkg::*;
//
class scoreboard extends uvm_scoreboard;
typedef apb_seq_item#(DW, APB_AW) apb_type;
typedef logic [7:0] data_8bit;
typedef uvm_tlm_analysis_fifo#(apb_seq_item#(DW, APB_AW)) apb_fifo;
typedef uvm_tlm_analysis_fifo#(uart_seq_item) uart_fifo;
	//
	`uvm_component_utils(scoreboard)
	//analysis implement ports
	//
	uvm_tlm_analysis_fifo#(logic) presetn_fifo[];
	//uvm_tlm_analysis_fifo#(apb_seq_item#(DW, APB_AW)) apb_txn_fifo[];
	//uvm_tlm_analysis_fifo#(apb_seq_item#(DW, APB_AW)) apb_to_uart_txn_fifo[];
	//uvm_tlm_analysis_fifo#(uart_seq_item) uart_tx_fifo[];
	//uvm_tlm_analysis_fifo#(uart_seq_item) uart_rx_fifo[];
	apb_fifo apb_txn_fifo[];
	apb_fifo apb_to_uart_txn_fifo[];
	uart_fifo uart_tx_fifo[];
	uart_fifo uart_rx_fifo[];
	//
	env_config m_cfg_h;
	uart_reg_model rm_h[];
	//item
	apb_type apb0_item, apb1_item, apb0_to_uart_item, apb1_to_uart_item;
	uart_seq_item uart0_tx_item, uart0_rx_item, uart1_tx_item, uart1_rx_item;
	//reset flag
	logic rst_flag0, rst_flag1;
	//
	//data members
	//
	//checkers
	int apb_rm_match = 0, apb_rm_mismatch = 0;
	int uart_01_match = 0, uart_01_mismatch = 0;
	int data_match = 0, data_mismatch = 0;
	int apb0_match = 0, apb0_mismatch = 0;
	int apb1_match = 0, apb1_mismatch = 0;
	//checkers to count STATUS register
	int no_frame_err = 0;
	int no_parity_err = 0;
	int no_break_con = 0;
	int no_tx_full = 0;
	int no_rx_full = 0;
	int no_rx_ov = 0;
	int no_tx_ov = 0;
	int no_rx_not_empty = 0;
	int no_rx_ud = 0;
	int no_busy = 0;
	//
	//compare full data
	//
	data_8bit exp_rx0_data_q [$]; //tx0_data
	data_8bit act_rx0_data_q [$];   //rx0_data
	data_8bit exp_rx1_data_q [$]; //tx1_data
	data_8bit act_rx1_data_q [$];   //rx1_data
	//
	//constructor
	//
	function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	//================================================
	//UVM phase
	//================================================
	//build_phase
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db#(env_config)::get(null, "uvm_test_top.env_h", "env_cfg", m_cfg_h)) begin
			`uvm_fatal(get_type_name(), "m_cfg is not FOUND!!!")
		end
		//
		presetn_fifo = new[m_cfg_h.no_of_agent];
		apb_txn_fifo = new[m_cfg_h.no_of_agent];
		apb_to_uart_txn_fifo = new[m_cfg_h.no_of_agent];//output of APB_SLAVE, config inputs of UART
		uart_tx_fifo = new[m_cfg_h.no_of_agent];
		uart_rx_fifo = new[m_cfg_h.no_of_agent];
		rm_h = new[m_cfg_h.no_of_agent];
		//
		foreach(presetn_fifo[i]) begin
			presetn_fifo[i] = new($sformatf("presetn_fifo[%0d]", i), this);
		end
		//
		foreach(apb_txn_fifo[i]) begin
			apb_txn_fifo[i] = new($sformatf("apb_txn_fifo[%0d]", i), this);
		end
		//
		foreach(apb_to_uart_txn_fifo[i]) begin
			apb_to_uart_txn_fifo[i] = new($sformatf("apb_to_uart_txn_fifo[%0d]", i), this);
		end
		//
		foreach(uart_tx_fifo[i]) begin
			uart_tx_fifo[i] = new($sformatf("uart_tx_fifo[%0d]", i), this);
		end
		//
		foreach(uart_rx_fifo[i]) begin
			uart_rx_fifo[i] = new($sformatf("uart_rx_fifo[%0d]", i), this);
		end

		apb0_item = apb_seq_item#(DW, APB_AW)::type_id::create("apb0_item");
		apb1_item = apb_seq_item#(DW, APB_AW)::type_id::create("apb1_item");
		apb0_to_uart_item = apb_seq_item#(DW, APB_AW)::type_id::create("apb0_to_uart_item");
		apb1_to_uart_item = apb_seq_item#(DW, APB_AW)::type_id::create("apb1_to_uart_item");
		//
		uart0_tx_item = uart_seq_item::type_id::create("uart0_tx_item");
		//uart0_rx_item = uart_seq_item::type_id::create("uart0_rx_item");
		//uart1_tx_item = uart_seq_item::type_id::create("uart1_tx_item");
		uart1_rx_item = uart_seq_item::type_id::create("uart1_rx_item");
		//
		for(int i = 0; i < m_cfg_h.no_of_agent; i++) begin
		if(!uvm_config_db#(uart_reg_model)::get(uvm_root::get(), "*", $sformatf("reg_model_h%0d", i), rm_h[i])) begin
			`uvm_fatal(get_type_name(), "rm_h is NOT found!!!");
		end
		end
		//
	endfunction
	//
	//run_phase
	//
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		fork//MAIN FORK
		forever begin: RESET_THREAD
			fork
				begin
					//`uvm_info(get_type_name(), "APB0 WAIT RESET", UVM_HIGH) //(*)
					//(*) causes simulation extremely low
					presetn_fifo[0].get(rst_flag0);
					if(rst_flag0 == 1'b0) begin
					`uvm_info(get_type_name(), "APB0 RESET active low", UVM_MEDIUM)
					end
				end
				//
				begin
					//`uvm_info(get_type_name(), "APB1 WAIT RESET", UVM_HIGH)
					presetn_fifo[1].get(rst_flag1);
					if(rst_flag1 == 1'b0) begin
					`uvm_info(get_type_name(), "APB1 RESET active low", UVM_MEDIUM)
					end
				end
				//join_none => CRITICAL NOTE: Having no
				//instructions after join_none leads to tb be stucked at t = 0, so
				//time does not advance
				//Useful method: using join_any to avoid no
				//time advancement
			join
			//
			if(~rst_flag0 || ~rst_flag1) begin
				init();
				flush_fifo();
				`uvm_info(get_type_name(), "[CLR_ALL]Clear all CHECKERs and Flush all FIFOs and QUEUEs", UVM_MEDIUM)
			end
			//
			//foreach(uart_rx_fifo[i]) begin
				//uart_rx_fifo[i] = new($sformatf("uart_rx_fifo[%0d]", i), this);
			//end
			//=> ILLEGAL
		end//end of RESET_THREAD
		//
		forever begin: HANDLE_APB_0
			//`uvm_info(get_type_name(), "APB0 WAIT CONTROL OUTPUT of APB_SLAVE", UVM_HIGH)
			//wait actual apb transfer
			apb_to_uart_txn_fifo[0].get(apb0_to_uart_item);
			//wait expected apb transfer
			apb_txn_fifo[0].get(apb0_item);
			//
		//input bit apb_1_or_0,
		//input reg_model_h rm_h,
		//input apb_type exp_item,
		//input apb_type act_item,
		//inout data_8bit tx_data_q [$],
		//inout data_8bit rx_data_q [$],
		//inout int match,
		//inout int mismatch,
		//inout int apb_rm_match,
		//inout int apb_rm_mismatch
			handle_apb(0, rm_h[0], apb0_item, apb0_to_uart_item, 
			exp_rx1_data_q, act_rx0_data_q, apb0_match, apb0_mismatch, apb_rm_match, apb_rm_mismatch);
			//
		end//end of HANDLE_APB_0
		forever begin: HANDLE_APB_1
			//`uvm_info(get_type_name(), "APB1 WAIT CONTROL OUTPUT of APB_SLAVE", UVM_HIGH)
			apb_to_uart_txn_fifo[1].get(apb1_to_uart_item);
			apb_txn_fifo[1].get(apb1_item);
			//
			handle_apb(1, rm_h[1], apb1_item, apb1_to_uart_item, 
			exp_rx0_data_q, act_rx1_data_q, apb1_match, apb1_mismatch, apb_rm_match, apb_rm_mismatch);
		end
		//
		join_none //MAIN_FORK
	endtask
	//
	//check_phase
	//
	virtual function void check_phase(uvm_phase phase);
		data_8bit exp_data = 0, act_data = 0;
		//
		//
		if(exp_rx1_data_q.size() > 0 && !uart_rx_fifo[1].is_empty()) begin
			foreach(exp_rx1_data_q[i]) begin
				exp_data = exp_rx1_data_q[i];
				if(uart_rx_fifo[1].try_get(uart1_rx_item)) begin
					compare_data(2'b11, exp_data, uart1_rx_item, uart_01_match, uart_01_mismatch);
	//input bit [1:0] control, //print_parity, uart_01_or_10, 
	//input data_8bit data,
	//input uart_seq_item item,
	//inout int match,
	//inout int mismatch,
				end
				else begin
					`uvm_error(get_type_name(), "try_get uart_rx_fifo[1] FAILED!!!")
				end
			end
		end//end of compare PARALEL against SERIAL
		//=============================================================== 
		//==================compare PARALEL-PARALEL ==================
		//=============================================================== 
		if(exp_rx1_data_q.size() > 0 && act_rx1_data_q.size() > 0) begin
			foreach(exp_rx1_data_q[i]) begin
				exp_data = exp_rx1_data_q[i];
				act_data = act_rx1_data_q[i];
				//
				if(exp_data == act_data) begin
					`uvm_info(get_type_name(), 
					$sformatf("[FULL: UART0_TX_UART1_RX]MATCH--> exp = %08b --- act = %08b",
				       	exp_data, act_data), UVM_LOW)
					data_match++;
				end
				else begin
					`uvm_info(get_type_name(), 
					$sformatf("[FULL: UART0_TX_UART1_RX]MISMATCH--> exp = %08b --- act = %08b",
				       	exp_data, act_data), UVM_LOW)
					data_mismatch++;
				end
			end
		end//end of compare PARALEL-PARALEL
		//
		exp_rx1_data_q.delete();
		act_rx1_data_q.delete();
	endfunction
	//report_phase
	virtual function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "**************************************************************", UVM_LOW)
		`uvm_info(get_type_name(), "**************************FINAL REPORT************************", UVM_LOW)
		`uvm_info(get_type_name(), "**************************************************************", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("BUS--MIRRORED(mirrored updated???): %0d UPDATED---%0d STALE ",
		 apb_rm_match, apb_rm_mismatch), UVM_LOW)
		 //
		`uvm_info(get_type_name(), $sformatf("UART0_TX_DATA--UART1_RX: %0d matches---%0d mismatches ",
		 uart_01_match, uart_01_mismatch), UVM_LOW)
		 //
		`uvm_info(get_type_name(), $sformatf("DATA_FULL: %0d matches---%0d mismatches ",
		 data_match, data_mismatch), UVM_LOW)
		 //
		`uvm_info(get_type_name(), $sformatf("INSIDE_CORE_APB0: %0d matches---%0d mismatches ",
		 apb0_match, apb0_mismatch), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("INSIDE_CORE_APB1: %0d matches---%0d mismatches ", 
		apb1_match, apb1_mismatch), UVM_LOW)
		`uvm_info(get_type_name(), "********************STATUS REGISTER REPORT********************", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_FRAME_ERR = %0d ", no_frame_err), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_PARITY_ERR = %0d ", no_parity_err), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_BREAK_CON = %0d ", no_break_con), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_TX_FULL = %0d ", no_tx_full), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_RX_FULL = %0d ", no_rx_full), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_RX_OV = %0d ", no_rx_ov), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_TX_OV = %0d ", no_tx_ov), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_RX_NOT_EMPTY = %0d ", no_rx_not_empty), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_RX_UD = %0d ", no_rx_ud), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("NO_BUSY = %0d ", no_busy), UVM_LOW)
	endfunction
	//
	//
	//
	virtual function void init();
	//checkers
	 apb_rm_match = 0;
	 apb_rm_mismatch = 0;
	 uart_01_match = 0;
	 uart_01_mismatch = 0;
	 data_match = 0;
	 data_mismatch = 0;
	 apb0_match = 0;
	 apb0_mismatch = 0;
	 apb1_match = 0;
	 apb1_mismatch = 0;
	no_frame_err = 0;
	no_parity_err = 0;
	no_break_con = 0;
	no_tx_full = 0;
	no_rx_full = 0;
	no_rx_ov = 0;
	no_tx_ov = 0;
	no_rx_not_empty = 0;
	no_rx_ud = 0;
	no_busy = 0;
	//
	//compare full data
	//
	 exp_rx0_data_q.delete(); //tx0_data
	 act_rx0_data_q.delete();   //rx0_data
	 exp_rx1_data_q.delete(); //tx1_data
	 act_rx1_data_q.delete();   //rx1_data
	endfunction
	//
	//
	virtual task flush_fifo();
		for(int i = 0; i<m_cfg_h.no_of_agent; i++) begin
			while(!apb_txn_fifo[i].is_empty())
			apb_txn_fifo[i].get(apb0_item);
			while(!apb_to_uart_txn_fifo[i].is_empty())
			apb_to_uart_txn_fifo[i].get(apb0_to_uart_item);
			while(!uart_tx_fifo[i].is_empty())
			uart_tx_fifo[i].get(uart0_tx_item);
			while(!uart_rx_fifo[i].is_empty())
			uart_rx_fifo[i].get(uart0_tx_item);

		end
	endtask
	//
	//sub tasks
	//
	virtual task automatic handle_apb(
		input bit apb_1_or_0,
		input uart_reg_model rm_h,
		input apb_type exp_item,
		input apb_type act_item,
		inout data_8bit tx_data_q [$],
		inout data_8bit rx_data_q [$],
		inout int match,
		inout int mismatch,
		inout int apb_rm_match,
		inout int apb_rm_mismatch
	);
	//
	string hd;
	logic [31:0] status = 0;
	uvm_reg_data_t mirrored_val = 0;
	uvm_reg_data_t peek_data = 0;
	uvm_status_e bd_status;
	bit rx_data1_en;
	bit rx_data0_en;
	//
	begin
		hd = apb_1_or_0 ? "INSIDE_CORE_APB1" : "INSIDE_CORE_APB0";
		if(act_item.compare(exp_item)) begin
			`uvm_info(get_type_name(), 
			$sformatf("[%s]: MATCH\nEXPECTED: %s --compared to-- ACTUAL: %s",
			hd, exp_item.convert2string, act_item.convert2string), UVM_LOW)
			match++;
		end
		else begin
			`uvm_info(get_type_name(), 
			$sformatf("[%s]: MISMATCH\nEXPECTED: %s --compared to-- ACTUAL: %s",
			hd, exp_item.convert2string, act_item.convert2string), UVM_LOW)
			mismatch++;
		end
		//store queue to compare TX
		case(exp_item.addr)
			32'h0: begin //control
				mirrored_val = rm_h.CTRL.get_mirrored_value();	
				comp_apb_to_rm(exp_item.addr[4:2], exp_item.data, mirrored_val, apb_rm_match, apb_rm_mismatch);
			end
			32'h4: begin
				mirrored_val = rm_h.STATUS.get_mirrored_value();	
				comp_apb_to_rm(exp_item.addr[4:2], exp_item.data, mirrored_val, apb_rm_match, apb_rm_mismatch);
				//
				if(~exp_item.write) begin
					status = exp_item.data;
					//
					if(status[0]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]FRAME_ERROR", hd), UVM_LOW)
						no_frame_err++;
					end						
					//
					if(status[1]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]PARITY_ERROR", hd), UVM_LOW)
						no_parity_err++;
					end						
					//
					if(status[2]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]BREAK_CON", hd), UVM_LOW)
						no_break_con++;
					end						
					//
					if(status[3]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]TX_FIFO_OVERFLOW", hd), UVM_LOW)
						no_tx_ov++;
					end						
					//
					if(status[4]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]RX_FIFO_OVERFLOW", hd), UVM_LOW)
						no_rx_ov++;
					end						
					//
					if(status[5]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]TX_FIFO_FULL", hd), UVM_LOW)
						no_tx_full++;
					end						
					//
					if(status[6]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]RX_FIFO_FULL", hd), UVM_LOW)
						no_rx_full++;
					end						
					//
					if(status[7]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]RX_FIFO_NOT_EMPTY", hd), UVM_LOW)
						no_rx_not_empty++;
					end						
					//
					if(status[8]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]UART_BUSY", hd), UVM_LOW)
						no_busy++;
					end						
					//
					//if(status[9]) begin
						//`uvm_info(get_type_name(), $sformatf("[%s]TX_SHIFT_REG_EMPTY", hd), UVM_LOW)
					//end						
					//
					if(status[9]) begin
						`uvm_info(get_type_name(), $sformatf("[%s]RX_UNDERFLOW", hd), UVM_LOW)
						no_rx_ud++;
					end						
				end
			end
			32'h8: begin// BRR_VALUE
				mirrored_val = rm_h.DIV.get_mirrored_value();	
				comp_apb_to_rm(exp_item.addr[4:2], exp_item.data, mirrored_val, apb_rm_match, apb_rm_mismatch);
			end
			32'hC:begin
				tx_data_q.push_back(exp_item.data[7:0]);
				`uvm_info(get_type_name(), 
				$sformatf("[%s]new exp_rx_data--> tx_data = %08b!!!", hd, exp_item.data[7:0]), UVM_LOW)
				//
				mirrored_val = rm_h.TXD.get_mirrored_value();	
				comp_apb_to_rm(exp_item.addr[4:2], exp_item.data, mirrored_val, apb_rm_match, apb_rm_mismatch);
			end		
			32'h10:begin
				//
				mirrored_val = rm_h.RXD.get_mirrored_value();	
				comp_apb_to_rm(exp_item.addr[4:2], exp_item.data, mirrored_val, apb_rm_match, apb_rm_mismatch);
				//
				//rm_h.RXD.peek(bd_status, peek_data);
				//`uvm_info(get_type_name(), $sformatf("[%s][%s]PEEK_RXD = %0h", hd, bd_status, peek_data), UVM_LOW)
				//
				//`uvm_info(get_type_name(), $sformatf("[%s][RX_DATA]rx_data0_en = %0b---rx_data1_en = %0b",
				 //hd, rx_data0_en, rx_data1_en), UVM_LOW)
				 //
				rx_data0_en = ~apb_1_or_0 & !uart_rx_fifo[0].is_empty();
				rx_data1_en = apb_1_or_0 & !uart_rx_fifo[1].is_empty();
				//
				if(rx_data1_en || rx_data0_en) begin
					rx_data_q.push_back(exp_item.data[7:0]);
				`uvm_info(get_type_name(),
				 $sformatf("[%s]new act_rx_data--> rx_data = %08b!!!", hd, exp_item.data[7:0]), UVM_LOW)
				end
			end
		endcase

	end
	endtask
	//
	//-----------------------compare APB with mirrored value of reg model
	//
	virtual task automatic comp_apb_to_rm(
		input logic [2:0] addr,
		input logic [31:0] bus_data, //actual bus transfer
		input uvm_reg_data_t mirrored_data,//mirrored value of RM
		inout int match,
		inout int mismatch
		//

	);
		string hd;
		begin
			//
			case(addr)
				0: hd = "CONTROL_REG";
				1: hd = "STATUS_REG";
				2: hd = "BRR_REG";
				3: hd = "TXD_REG";
				4: hd = "RXD_REG";
			endcase
			//
			if(bus_data === mirrored_data) begin
				`uvm_info(get_full_name(), 
				$sformatf("[%s]MIRRORED_UPDATED--> bus_data = %08h---mirrored_data = %08h",
			       	hd, bus_data, mirrored_data), UVM_LOW)
				match++;
			end
			else begin
				`uvm_info(get_full_name(), 
				$sformatf("[%s]MIRRORED_STALE--> bus_data = %08h---mirrored_data = %08h", 
				hd, bus_data, mirrored_data), UVM_LOW)
				mismatch++;
			end
		end
	endtask
	//
	//----------------------compare TX-RX
	//
	virtual function void compare_data(
		input bit [1:0] control, //print_parity, uart_01_or_10, 
		input data_8bit data,
		input uart_seq_item item,
		inout int match,
		inout int mismatch
		//inout data_8bit data_q [$]
	);
		string hd;
		bit uart_01_or_10 = control[0];
		bit print_parity = control[1];
		data_8bit exp = 0, act = 0;
		//
	begin
		hd = uart_01_or_10 ? "UART0_TX_UART1_RX" : "UART1_TX_UART0_RX";
		//
		exp = data;
		act = item.rx_data;
		//
		if(exp == act) begin
		`uvm_info(get_type_name(), 
			$sformatf("[%s]MATCH--> TX_Data(Expected) = %08b --- RX(Actual) = %08b", hd, exp, act), UVM_LOW)
			match++;
		end
		else begin
		`uvm_info(get_type_name(), 
			$sformatf("[%s]MISMATCH--> TX_Data(Expected) = %08b --- RX(Actual) = %08b", hd, exp, act), UVM_LOW)
			mismatch++;
		end
		//
		if(print_parity) begin 
			`uvm_info(get_full_name(), 
			$sformatf("[%s]PARITY bit = %0b --- STOP bit = %0b",
			 hd, item.parity_bit, item.stop_bit), UVM_LOW)
		end
	end
	endfunction
//
endclass
endpackage
