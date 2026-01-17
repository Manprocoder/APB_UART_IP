
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
//define uvm analysis implement ports
//`uvm_analysis_imp_decl(_apb_uart0_presetn)
//`uvm_analysis_imp_decl(_apb_uart0_transfer)
//`uvm_analysis_imp_decl(_apb_uart1_presetn)
//`uvm_analysis_imp_decl(_apb_uart1_transfer)
////output of apb_slave ip 
//`uvm_analysis_imp_decl(_sub_apb0_transfer)
//`uvm_analysis_imp_decl(_sub_apb1_transfer)
//`uvm_analysis_imp_decl(_uart0_tx)
//`uvm_analysis_imp_decl(_uart0_rx)
//`uvm_analysis_imp_decl(_uart1_tx)
//`uvm_analysis_imp_decl(_uart1_rx)
//
class scoreboard extends uvm_scoreboard;
typedef apb_seq_item#(DW, APB_AW) apb_type;
	`uvm_component_utils(scoreboard)
	parameter OVERSAMPLE = 16;
	//analysis implement ports
	//
	uvm_tlm_analysis_fifo#(logic) presetn_fifo[];
	uvm_tlm_analysis_fifo#(apb_seq_item#(DW, APB_AW)) apb_txn_fifo[];
	uvm_tlm_analysis_fifo#(apb_seq_item#(DW, APB_AW)) sub_apb_txn_fifo[];
	uvm_tlm_analysis_fifo#(uart_seq_item) uart_tx_fifo[];
	uvm_tlm_analysis_fifo#(uart_seq_item) uart_rx_fifo[];
	//uvm_analysis_imp_apb_uart0_presetn#(logic, scoreboard) apb_uart0_presetn_aimp;
	//uvm_analysis_imp_apb_uart0_transfer#(apb_seq_item#(DW, APB_AW), scoreboard) apb_uart0_transfer_aimp;
	//uvm_analysis_imp_apb_uart1_presetn#(logic, scoreboard) apb_uart1_presetn_aimp;
	//uvm_analysis_imp_apb_uart1_transfer#(apb_seq_item#(DW, APB_AW), scoreboard) apb_uart1_transfer_aimp;
	////
	//uvm_analysis_imp_sub_apb0_transfer#(apb_seq_item#(DW, APB_AW), scoreboard) sub_apb0_transfer_aimp;
	//uvm_analysis_imp_sub_apb1_transfer#(apb_seq_item#(DW, APB_AW), scoreboard) sub_apb1_transfer_aimp;
	////
	//uvm_analysis_imp_uart0_tx#(uart_seq_item, scoreboard) uart0_tx_aimp;
	//uvm_analysis_imp_uart0_rx#(uart_seq_item, scoreboard) uart0_rx_aimp;
	//uvm_analysis_imp_uart1_tx#(uart_seq_item, scoreboard) uart1_tx_aimp;
	//uvm_analysis_imp_uart1_rx#(uart_seq_item, scoreboard) uart1_rx_aimp;
	//
	//data members
	//
	//checkers
	integer tx_match = 0, tx_mismatch = 0;
	integer rx_match = 0, rx_mismatch = 0;
	integer data_match = 0, data_mismatch = 0;
	integer apb0_match = 0, apb0_mismatch = 0;
	integer apb1_match = 0, apb1_mismatch = 0;
	//
	int tx0_cnt, tx1_cnt;
	int rx0_cnt, rx1_cnt;
	int tx0_bits_cnt, tx1_bits_cnt;
	int rx0_bits_cnt, rx1_bits_cnt;
	//
	logic uart0_tx_q [$];
	logic uart0_rx_q [$];
	logic uart1_tx_q [$];
	logic uart1_rx_q [$];
	//
	logic [31:0] apb0_status;
	logic [31:0] apb1_status;
	logic [31:0] apb0_control;
	logic [31:0] apb1_control;
	logic [15:0] apb0_BRR;
	logic [15:0] apb1_BRR;
	//
	logic [7:0] uart0_tx_data_q [$];
	logic [7:0] uart0_rx_data_q [$];
	logic [7:0] uart1_tx_data_q [$];
	logic [7:0] uart1_rx_data_q [$];
	//
	logic uart0_parity_bit_q [$];
	logic uart1_parity_bit_q [$];
	//
	logic [10:0] tx0_full_frame, tx1_full_frame;
	logic [7:0] tx0_data, tx1_data;
	logic [9:0] rx0_full_frame, rx1_full_frame;
	logic [7:0] rx0_data, rx1_data;
	//
	//tx0 signals
	bit detect_start_bit_tx0, tx0_done, uart0_parity_en, uart0_parity_type;
	logic tx0_tmp;
	//tx1 signals
	bit detect_start_bit_tx1, tx1_done, uart1_parity_en, uart1_parity_type;
	logic tx1_tmp;
	//rx0 signals
	bit uart0_parity_bit, expected0_parity_bit, detect_start_bit_rx0, rx0_done, rx0_complete;
       	logic rx0_tmp;
	//rx1 signals
	bit uart1_parity_bit, expected1_parity_bit, detect_start_bit_rx1, rx1_done, rx1_complete;
        logic rx1_tmp;
	//
	bit uart0_status_rdy, uart1_status_rdy;
	bit uart0_status_updated, uart1_status_updated;
	//
	//queue to store and compare actual apb slave and expected apb slave
	//
	apb_type expected_apb0_q [$];
	apb_type expected_apb1_q [$];
	apb_type exp_apb0_item, exp_apb1_item;
       //	act_apb0_item, act_apb1_item;
	//compare full data
	//
	logic [7:0] expected_rx0_data_q [$];
	logic [7:0] actual_rx0_data_q [$];
	logic [7:0] expected_rx1_data_q [$];
	logic [7:0] actual_rx1_data_q [$];
	//
	//constructor
	//
	function new(string name = "scoreboard", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	//
	//================================================
	//write function
	//================================================
	//--1
	//virtual function void write_apb_uart0_presetn(logic apb_0_presetn);
		//if(~apb_0_presetn) begin
			//`uvm_info(get_type_name(), "APB0 Presetn active low", UVM_LOW)
			//apb0_control = 0;
			//apb0_status = 0;
			//apb0_BRR = 0;
			//uart0_tx_data_q.delete();
			//uart0_rx_data_q.delete();
			//uart0_tx_q.delete();
			//uart0_rx_q.delete();
			//detect_start_bit_tx0 = 1'b1;
			//detect_start_bit_tx1 = 1'b1;
			//expected_apb0_q.delete();
		//end
		//else begin
		//end
	//endfunction
	////--2
	//virtual function void write_apb_uart0_transfer(apb_seq_item#(DW, APB_AW) apb_item);
		////
		//expected_apb0_q.push_back(apb_item);
		////
		//case(apb_item.addr[4:2])
			//0: apb0_control = apb_item.data;
			//1: begin
				//if(~apb_item.write) begin
					//apb0_status = apb_item.data;
					//if(uart0_status_rdy == 1'b1) begin
						//uart0_status_updated = 1'b1;
						//uart0_status_rdy = 1'b0;
					//end
				//end
			//end
			//2: apb0_BRR = apb_item.data;
			//3: uart0_tx_data_q.push_back(apb_item.data[7:0]);
			//4: begin
				//uart0_rx_data_q.push_back(apb_item.data[7:0]);
				//uart0_status_rdy = 1'b1;
			//end
		//endcase
	//endfunction
	////--3
	//virtual function void write_apb_uart1_presetn(logic apb_1_presetn);
		//if(~apb_1_presetn) begin
			//`uvm_info(get_type_name(), "APB1 Presetn active low", UVM_LOW)
			//apb1_control = 0;
			//apb1_status = 0;
			//apb1_BRR = 0;
			//uart1_tx_data_q.delete();
			//uart1_rx_data_q.delete();
			//uart1_tx_q.delete();
			//uart1_rx_q.delete();
			//detect_start_bit_tx1 = 1'b1;
			//expected_apb1_q.delete();
		//end
		//else begin
		//end
	//endfunction
	////--4
	//virtual function void write_apb_uart1_transfer(apb_seq_item#(DW, APB_AW) apb_item);
		////
		//expected_apb1_q.push_back(apb_item);
		////
		//case(apb_item.addr[4:2])
			//0: apb1_control = apb_item.data;
			//1: begin
				//if(~apb_item.write) begin
					//apb1_status = apb_item.data;
					//if(uart1_status_rdy == 1'b1) begin
						//uart1_status_updated = 1'b1;
						//uart1_status_rdy = 1'b0;
					//end
				//end
			//end
			//2: apb1_BRR = apb_item.data;
			//3: uart1_tx_data_q.push_back(apb_item.data[7:0]);
			//4: begin
				//uart1_rx_data_q.push_back(apb_item.data[7:0]);
				//uart1_status_rdy = 1'b1;
			//end
		//endcase
	//endfunction
	////--2.actual
	//virtual function void write_sub_apb0_transfer(apb_type apb_item);
		//exp_apb0_item = expected_apb0_q.pop_front();
		//if(apb_item.compare(exp_apb0_item)) begin
			//`uvm_info(get_type_name(),$sformatf("[APB0_MATCH]\n: actual: %s vs expected: %s",
			       	//apb_item.convert2string(), exp_apb0_item.convert2string()), UVM_LOW);
			 //apb0_match++;
		//end
		//else begin
			//`uvm_info(get_type_name(),$sformatf("[APB0_MISMATCH]\n: actual: %s vs expected: %s",
			       	//apb_item.convert2string(), exp_apb0_item.convert2string()), UVM_LOW);
			 //apb0_mismatch++;
		//end
	//endfunction
	////--4.actual
	//virtual function void write_sub_apb1_transfer(apb_type apb_item);
		//exp_apb1_item = expected_apb1_q.pop_front();
		//if(apb_item.compare(exp_apb1_item)) begin
			//`uvm_info(get_type_name(),$sformatf("[APB1_MATCH]\n: actual: %s vs expected: %s",
			       	//apb_item.convert2string(), exp_apb0_item.convert2string()), UVM_LOW);
			 //apb1_match++;
		//end
		//else begin
			//`uvm_info(get_type_name(),$sformatf("[APB1_MISMATCH]\n: actual: %s vs expected: %s",
			       	//apb_item.convert2string(), exp_apb0_item.convert2string()), UVM_LOW);
			 //apb1_mismatch++;
		//end
	//endfunction
	////--5
	//virtual function void write_uart0_tx(uart_seq_item uart_item);
		//uart0_tx_q.push_front(uart_item.tx);
	//endfunction
	////--6
	//virtual function void write_uart0_rx(uart_seq_item uart_item);
		//uart0_rx_q.push_front(uart_item.rx);
	//endfunction
	////--7
	//virtual function void write_uart1_tx(uart_seq_item uart_item);
		//uart1_tx_q.push_front(uart_item.tx);
	//endfunction
	////--8
	//virtual function void write_uart1_rx(uart_seq_item uart_item);
		//uart1_rx_q.push_front(uart_item.rx);
	//endfunction
	//
	//================================================
	//UVM phase
	//================================================
	//build_phase
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		//apb_uart0_presetn_aimp = new("apb_uart0_presetn_aimp", this);
		//apb_uart0_transfer_aimp = new("apb_uart0_transfer_aimp", this);
		//apb_uart1_presetn_aimp = new("apb_uart1_presetn_aimp", this);
		//apb_uart1_transfer_aimp = new("apb_uart1_transfer_aimp", this);
		////output of apb slave ip
		//sub_apb0_transfer_aimp = new("sub_apb0_transfer_aimp", this);
		//sub_apb1_transfer_aimp = new("sub_apb1_transfer_aimp", this);
		////
		//uart0_tx_aimp = new("uart0_tx_aimp", this);
		//uart0_rx_aimp = new("uart0_rx_aimp", this);
		//uart1_tx_aimp = new("uart1_tx_aimp", this);
		//uart1_rx_aimp = new("uart1_rx_aimp", this);
		//
		//apb0_item = apb_seq_item#(DW, APB_AW)::type_id::create("apb0_item");
		//apb1_item = apb_seq_item#(DW, APB_AW)::type_id::create("apb1_item");
		//uart0_item = uart_seq_item::type_id::create("uart0_item");
		//uart1_item = uart_seq_item::type_id::create("uart1_item");
	endfunction
	//run_phase
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		fork//MAIN FORK
		forever begin: UART0_THREAD
			fork
			begin: UART0_TX_THEAD
			wait(uart0_tx_q.size()>0);
			tx0_tmp = uart0_tx_q.pop_back();
			if(detect_start_bit_tx0) begin
				detect_start_bit(tx0_tmp, detect_start_bit_tx0);
				if(detect_start_bit_tx0 == 1'b0) begin
					have_parity(apb0_control, uart0_parity_en, uart0_parity_type);
				end
			end
			//
			if(detect_start_bit_tx0 == 1'b0) begin //pack_frame
			pack_tx_frame(uart0_parity_en, tx0_tmp,
			       	tx0_cnt, tx0_bits_cnt, tx0_full_frame, tx0_done);
			//
			if(tx0_done) begin
				//pop expected data
				tx0_data = uart0_tx_data_q.pop_front();
				//compare
				tx_compare(uart0_parity_en, uart0_parity_type, tx0_full_frame, tx0_data, 1'b0, uart0_parity_bit);
				detect_start_bit_tx0 = 1'b1;
				tx0_done = 1'b0;
				//store expected rx_data for uart1
				if(uart0_parity_en) uart1_parity_bit_q.push_back(uart0_parity_bit);
				expected_rx1_data_q.push_back(tx0_data);
				`uvm_info(get_type_name(), "TX0_DONE", UVM_MEDIUM)
			end
			end//end of pack_frame
			end//end of UART0_TX_THREAD
			//
			begin: UART0_RX_THREAD
				wait(uart0_rx_q.size()>0);
				rx0_tmp = uart0_rx_q.pop_back();
				if(detect_start_bit_rx0) begin
					if(~rx0_tmp) begin
						detect_start_bit_rx0 = 0;
					end
				end
				//
				if(detect_start_bit_rx0 == 1'b0) begin //pack_frame_rx0
				rx0_full_frame = {rx0_full_frame[8:0], rx0_tmp};
				rx0_bits_cnt = rx0_bits_cnt + 1;
				rx0_complete = uart0_parity_en ? (rx0_bits_cnt == 10) : (rx0_bits_cnt == 9); 	
				//
				if(rx0_complete) begin
					if(rx0_bits_cnt == 9) begin
						rx0_full_frame = {rx0_full_frame[8:1], 1'b0, rx0_full_frame[0]};
						`uvm_info(get_type_name(), 
							$sformatf("[NO_PARITY]RX0_full_frame = %0b", rx0_full_frame), UVM_HIGH)
					end
					rx0_done = 1'b1;
					rx0_bits_cnt = 0;
				end
				//
				if(rx0_done) begin
					wait(uart0_rx_data_q.size() > 0);
					wait(uart0_status_updated == 1);
					uart0_status_updated = 0;
					rx0_data = uart0_rx_data_q.pop_front();
					//extract expected parity bit
					if(uart0_parity_en) expected0_parity_bit = uart0_parity_bit_q.pop_front();
					//do compare
					rx_compare(uart0_parity_en, expected0_parity_bit,
					rx0_full_frame, rx0_data, apb0_status, 1'b0);
					//
					rx0_done = 1'b0;
					actual_rx0_data_q.push_back(rx0_data);
				end
				end//pack_frame_rx0
			end//end of UART0_RX_THREAD
			join_none
		end//end of UART0_THREAD
		//
		forever begin: UART1_THREAD
			fork
			begin: TX_UART1_THREAD
			wait(uart1_tx_q.size()>0);
			tx1_tmp = uart1_tx_q.pop_back();
			if(detect_start_bit_tx1) begin
				detect_start_bit(tx1_tmp, detect_start_bit_tx1);
				if(detect_start_bit_tx1 == 1'b0) begin
					have_parity(apb1_control, uart1_parity_en, uart1_parity_type);
				end
			end
			//
			//
			if(detect_start_bit_tx1 == 1'b0) begin //pack_frame
			pack_tx_frame(uart1_parity_en, tx1_tmp,
			       	tx1_cnt, tx1_bits_cnt, tx1_full_frame, tx1_done);
			//
			if(tx1_done) begin
				tx1_data = uart1_tx_data_q.pop_front();
				tx_compare(uart1_parity_en, uart1_parity_type, tx1_full_frame, tx1_data, 1'b1, uart1_parity_bit);
				tx1_done = 1'b0;
				detect_start_bit_tx1 = 1; 
				//store expected data and parity bit for uart0
				//comparison
				if(uart1_parity_en) uart0_parity_bit_q.push_back(uart1_parity_bit);
				expected_rx0_data_q.push_back(tx1_data);
				`uvm_info(get_type_name(), "TX1_DONE", UVM_MEDIUM)
			end
			end//end of pack_frame 
			end//end of TX_UART1_THREAD
			//
			begin: RX_UART1_THREAD
				wait(uart1_rx_q.size()>0);
				rx1_tmp = uart1_rx_q.pop_back();
				if(detect_start_bit_rx1) begin
					if(~rx1_tmp) begin
						detect_start_bit_rx1 = 1;
					end
				end
				//
				if(detect_start_bit_rx1 == 1'b1) begin
				rx1_full_frame = {rx1_full_frame[8:1], rx1_tmp};
				rx1_bits_cnt = rx1_bits_cnt + 1;
				rx1_complete = uart1_parity_en ? (rx1_bits_cnt == 10) : (rx1_bits_cnt == 9); 	
				//
				if(rx1_complete) begin
					if(rx1_bits_cnt == 9) begin
						rx1_full_frame = {rx1_full_frame[8:1], 1'b0, rx1_full_frame[0]};
						`uvm_info(get_type_name(), 
							$sformatf("[NO_PARITY]RX1_full_frame = %0b", rx1_full_frame), UVM_HIGH)
					end
					rx1_done = 1'b1;
					rx1_bits_cnt = 1;
				end
				//
				if(rx1_done) begin
					wait(uart1_rx_data_q.size() > 0);
					wait(uart1_status_updated == 1);
					uart1_status_updated = 0; 
					//extract actual data
					rx1_data = uart1_rx_data_q.pop_front();
					//extract expected parity bit
					if(uart1_parity_en) expected1_parity_bit = uart1_parity_bit_q.pop_front();
					//do compare
					rx_compare(uart1_parity_en, expected1_parity_bit,
					       	rx1_full_frame, rx1_data, apb1_status, 1'b1);
					//
					rx1_done = 1'b0;
					actual_rx1_data_q.push_back(rx1_data);
				end
				end
			end//end of RX_UART1_THREAD
			join_none
		end//end of UART1_THREAD
		join_none //MAIN_FORK
	endtask

	//check_phase
	virtual function void check_phase(uvm_phase phase);
		logic [7:0] expected_rx_data = 0;
		logic [7:0] actual_rx_data = 0;
		
		forever begin
			if(expected_rx0_data_q.size() && actual_rx0_data_q.size()) begin
				expected_rx_data = expected_rx0_data_q.pop_front();
				actual_rx_data = actual_rx0_data_q.pop_front();
				if(expected_rx_data == actual_rx_data) begin
					data_match++;
				end	
				else begin
					`uvm_info(get_type_name(), 
					$sformatf("[TX0-RX1]DATA MISMATCH: %0b vs %0b", expected_rx_data, actual_rx_data), UVM_LOW)
					data_mismatch++;
				end
			end
			//
			if(expected_rx1_data_q.size() && actual_rx1_data_q.size()) begin
				expected_rx_data = expected_rx1_data_q.pop_front();
				actual_rx_data = actual_rx1_data_q.pop_front();
				if(expected_rx_data == actual_rx_data) begin
					data_match++;
				end	
				else begin
					`uvm_info(get_type_name(), 
					$sformatf("[TX1-RX0]DATA MISMATCH: %0b vs %0b", expected_rx_data, actual_rx_data), UVM_LOW)
					data_mismatch++;
				end
			end
	end//end of forever
	endfunction
	//report_phase
	virtual function void report_phase(uvm_phase phase);
		`uvm_info(get_type_name(), "**************************************************************", UVM_LOW)
		`uvm_info(get_type_name(), "**************************FINAL REPORT************************", UVM_LOW)
		`uvm_info(get_type_name(), "**************************************************************", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("TX: %0d matches---%0d mismatches ", tx_match, tx_mismatch), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("RX: %0d matches---%0d mismatches ", rx_match, rx_mismatch), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("DATA: %0d matches---%0d mismatches ", data_match, data_mismatch), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("APB0: %0d matches---%0d mismatches ", apb0_match, apb0_mismatch), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("APB0: %0d matches---%0d mismatches ", apb1_match, apb1_mismatch), UVM_LOW)
	endfunction
	//
	//sub tasks
	//
	//--add "automatic" key_word: "virtual task automatic detect_start_bit"
	//--CAUSES bit_tmp and detect_start_bit are undefined
	virtual task detect_start_bit(
		input logic bit_tmp,
		output logic detect_start_bit
	);
		//
		begin
			if(bit_tmp) detect_start_bit = 1'b1;
			else detect_start_bit = 1'b0;
		end
	endtask
	//
	virtual task pack_tx_frame(
		input logic parity_en_i,
		input logic tx_tmp_i,
		inout int tx_shift_cnt,
		inout int tx_bits_cnt,
		inout logic [10:0] tx_full_frame,
		output logic tx_done

	); 
	logic complete;
	begin
		if(tx_shift_cnt == OVERSAMPLE-1) begin
			tx_shift_cnt = 0;
			tx_full_frame = {tx_full_frame[9:0], tx_tmp_i};
			tx_bits_cnt = tx_bits_cnt + 1;
			//
			complete = parity_en_i ? (tx_bits_cnt == 11) : (tx_bits_cnt == 10);
			if(complete) begin
				if(tx_bits_cnt == 10) begin
					tx_full_frame = {tx_full_frame[9:1], 1'b0, tx_full_frame[0]};
				`uvm_info(get_type_name(), $sformatf("[NO PARITY]tx_full_frame: %0b", tx_full_frame), UVM_HIGH)
				end
				tx_done = 1'b1;
			end

		end//end of tx_shift_cnt
		else begin
			tx_shift_cnt = tx_shift_cnt + 1;
		end
	end//
	endtask
	//
	virtual task tx_compare(
		input bit parity_en,
		input bit parity_type,
		input logic [10:0] tx_full_frame,
		input logic [7:0] tx_data,
		input bit tx1_belong,
		output bit parity_bit
	);
	string hd;
	//
	begin//MAIN_TX
		hd = tx1_belong ? "TX1" : "TX0";
		//
		if(parity_en) begin
			parity_bit = parity_type ? ^tx_data : ~(^tx_data);
		end
		else begin
			parity_bit = 0;
		end
		//compare
		if(tx_full_frame[10] == 1'b0 && (tx_full_frame[9:2] == tx_data) 
			&& (tx_full_frame[1] == parity_bit) && tx_full_frame[0]==1'b1) begin
		`uvm_info(get_type_name(), $sformatf("%s_MATCH\n: full_frame: %0b vs tx_data: %0b",
		       	hd, tx_full_frame, tx_data), UVM_LOW);
			//increase checker
			tx_match++;
		end
		else begin
		`uvm_info(get_type_name(), $sformatf("%s_MISMATCH\n: full_frame: %0b vs tx_data: %0b",
		       	hd, tx_full_frame, tx_data), UVM_LOW);
			//increase checker
			tx_mismatch++;
		end
	end//MAIN_TX
	//
	endtask
	//
	//
	//
	virtual task rx_compare(
		input bit parity_en,
		//input logic parity_type,
		input bit parity_bit,
		input logic [9:0] rx_full_frame,
		input logic [7:0] rx_data,
		input logic [31:0] status,
		input bit rx1_belong
	);
	string hd, hd1, hd2, hd3;
	//
	//
//:%s/\<RX[0-9_]\+\>/"&"/g

	begin//MAIN 
	 hd = rx1_belong ? "RX1" : "RX0";
	 hd1 = rx1_belong ? "RX1_PARITY" : "RX0_PARITY";
	 hd2 = rx1_belong ? "RX1_STOP" : "RX0_STOP";
	 hd3 = rx1_belong ? "RX1_STATUS" : "RX0_STATUS";
		if(parity_en) begin//PARITY_COMPARE
			if(rx_full_frame[1] == parity_bit) begin
				`uvm_info(get_type_name(), 
					$sformatf("%s_MATCH: %0b vs %0b", hd1, rx_full_frame[1], parity_bit), UVM_LOW);
				rx_match++;
				if(status[1] == 1'b0) begin
				`uvm_info(get_type_name(), 
					$sformatf("%s_MATCH: %0b", hd3, status[1]), UVM_LOW);
				rx_match++;
				end
				else begin
				rx_mismatch++;
				`uvm_info(get_type_name(), $sformatf("%s_MISMATCH: %0b", hd3, status[1]), UVM_LOW);
				end
			end
			else begin
				`uvm_info(get_type_name(), 
					$sformatf("%s_MISMATCH: %0b vs %0b", hd1, rx_full_frame[1], parity_bit), UVM_LOW);
				rx_mismatch++;
				if(status[1] == 1'b1) begin
				`uvm_info(get_type_name(), $sformatf("%s_MATCH: %0b", hd3, status[1]), UVM_LOW);
				rx_match++;
				end
				else begin
				rx_mismatch++;
				`uvm_info(get_type_name(), $sformatf("%s_MISMATCH: %0b", hd3, status[1]), UVM_LOW);
				end

			end

		end//PARITY_COMPARE
		//DATA
		if(rx_full_frame[9:2] == rx_data) begin
			`uvm_info(get_type_name(), $sformatf("%s_MATCH\n: rx_full_frame: %0b vs rx_data: %0b",
			       	hd, rx_full_frame[9:2], rx_data), UVM_LOW);
			rx_match++;
		end
		else begin
			`uvm_info(get_type_name(), $sformatf("%s_MISMATCH: rx_full_frame: %0b vs rx_data: %0b", 
				hd, rx_full_frame[9:2], rx_data), UVM_LOW);
			rx_mismatch++;
		end
		//STOP bit (frame bit)
		if(rx_full_frame[0] == 1'b1) begin
			`uvm_info(get_type_name(), $sformatf("%s_MATCH: %0b", hd2, rx_full_frame[0]), UVM_LOW);
			rx_match++;
			if(status[1] == 1'b0) begin
			`uvm_info(get_type_name(), $sformatf("%s_MATCH: %0b", hd3, status[0]), UVM_LOW);
			rx_match++;
			end
			else begin
			rx_mismatch++;
			`uvm_info(get_type_name(), $sformatf("%s_MISMATCH: %0b", hd3, status[0]), UVM_LOW);
			end
		end//end of rx_full_frame[0] == 1'b1
		else begin
			`uvm_info(get_type_name(), $sformatf("%s_MISMATCH: %0b", hd2, rx_full_frame[0]), UVM_LOW);
			rx_match++;
			if(status[1] == 1'b1) begin
			`uvm_info(get_type_name(), $sformatf("%s_MATCH: %0b", hd3, status[0]), UVM_LOW);
			rx_match++;
			end
			else begin
			rx_mismatch++;
			`uvm_info(get_type_name(), $sformatf("%s_MISMATCH: %0b", hd3, status[0]), UVM_LOW);
			end

		end
	end//MAIN
	//
	endtask
	//
	virtual function void have_parity(
		input logic [31:0] control,
		output logic parity_en,
		output logic parity_type
	);
		begin
			parity_en = control[0];
			parity_type = control[1];
		end
	endfunction

	//
endclass
endpackage
