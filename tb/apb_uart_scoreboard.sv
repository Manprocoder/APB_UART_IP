//==========================================================
//Project: Design and verify APB UART IP 
//File name: apb_uart_scoreboard.sv 
//Author: Nguyen Ngoc Man
//Description:  
//==========================================================
`include "apb_scoreboard.sv"
import uart_pkg::*;
import uart_ral_pkg::*;
//
class apb_uart_scoreboard extends apb_scoreboard;
typedef uvm_tlm_analysis_fifo#(uart_seq_item) uart_fifo;
typedef uvm_tlm_analysis_fifo#(logic) int_fifo;
	//
	`uvm_component_utils(apb_uart_scoreboard)
	//==============================================================
	//data members
	//==============================================================
    //--parameter
    parameter NO_USED_STATUS_BITS = 10;
    //--STATUS bit array
    string sts_bit_arr [NO_USED_STATUS_BITS] = {"FRAME_ERROR", "PARITY_ERROR", "BREAK_CON", "TX_OV", "RX_OV", "RX_FULL", "TX_FULL", "RX_NOT_EMPTY", "UART_BUSY", "RX_UD"};
	//--uvm_tlm_analysis fifo
	uart_fifo uart_tx_fifo[];//used
	uart_fifo uart_rx_fifo[];
    `ifdef INTERRUPT
    int_fifo int_fifo[]; 
    `endif
	//--reg model fifo handle
	uart_reg_model rm_h[];
	//--uart transaction handle
	uart_seq_item uart0_tx_item, uart0_rx_item, uart1_tx_item, uart1_rx_item;
    //checkers
    //--1: compare data frame 
    int serial_uart_01_pass, serial_uart_01_fail, serial_uart_10_pass, serial_uart_10_fail;
    int parallel_uart_01_pass, parallel_uart_01_fail, parallel_uart_10_pass, parallel_uart_10_fail;
	//--2: count STATUS register
    int cnt_of_status_arr [string];
	//int no_frame_err = 0;
	//int no_parity_err = 0;
	//int no_break_con = 0;
	//int no_tx_full = 0;
	//int no_rx_full = 0;
	//int no_rx_ov = 0;
	//int no_tx_ov = 0;
	//int no_rx_not_empty = 0;
	//int no_rx_ud = 0;
	//int no_busy = 0;
    //
    `ifdef INTERRUPT
    int no_uart0_int, no_uart1_int;
    `endif
	//==========================================================
	//----------METHODs
	//==========================================================
	extern function new(string name, uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task run_phase(uvm_phase phase);
	extern virtual function void check_phase(uvm_phase phase);
	extern virtual function void report_phase(uvm_phase phase);
	extern virtual function void final_phase(uvm_phase phase);
	extern virtual function void check_status(input logic [`APB_AW-1:0] status);
    extern virtual function void detect_status_bit(input bit bit_status, input string hd);
    extern virtual function void compare_serial(input bit [1:0] control, data_8bit exp_data, uart_seq_item act_data, inout int no_pass, inout int  no_fail);
    extern virtual function void compare_parallel(input bit control, data_8bit exp_data, data_8bit act_data, inout int no_pass, inout int no_fail);
    extern virtual function void init_checker();
    extern virtual function void flush_fifo();
    extern virtual function void init_cnt_of_status_arr();
    `ifdef INTERRUPT
    //MUST NOT use extern keyword for automatic 
    virtual task automatic notify_interrupt(bit uart0_or_1);
        if(uart0_or_1) begin
            no_uart0_int++;
        end
        else begin
            no_uart1_int++;
        end
    endtask;
    `endif
    //
endclass: apb_uart_scoreboard
	//==========================================================
	//----------IMPLEMENTATION of all METHODs
	//==========================================================
	function apb_uart_scoreboard::new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction
	//build_phase
 	function void apb_uart_scoreboard::build_phase(uvm_phase phase);
		super.build_phase(phase);
        //
		uart_tx_fifo = new[env_cfg_h.no_of_agent];
		uart_rx_fifo = new[env_cfg_h.no_of_agent];
		rm_h = new[env_cfg_h.no_of_agent];
        `ifdef INTERRUPT
		int_fifo = new[env_cfg_h.no_of_agent];
        `endif
		//
		foreach(uart_tx_fifo[i]) begin
			uart_tx_fifo[i] = new($sformatf("uart_tx_fifo[%0d]", i), this);
		end
		//
		foreach(uart_rx_fifo[i]) begin
			uart_rx_fifo[i] = new($sformatf("uart_rx_fifo[%0d]", i), this);
		end
        //
        `ifdef INTERRUPT
		foreach(int_fifo[i]) begin
			int_fifo[i] = new($sformatf("int_fifo[%0d]", i), this);
		end
        `endif
		//
		uart0_tx_item = uart_seq_item::type_id::create("uart0_tx_item");
		uart0_rx_item = uart_seq_item::type_id::create("uart0_rx_item");
		uart1_tx_item = uart_seq_item::type_id::create("uart1_tx_item");
		uart1_rx_item = uart_seq_item::type_id::create("uart1_rx_item");
		//
		for(int i = 0; i < env_cfg_h.no_of_agent; i++) begin
            if(!uvm_config_db#(uart_reg_model)::get(this, "", $sformatf("reg_model_h%0d", i), rm_h[i])) begin
                `uvm_fatal(get_type_name(), "rm_h is NOT found!!!");
            end
		end
		//
	endfunction
	//
	//run_phase
	//
	task apb_uart_scoreboard::run_phase(uvm_phase phase);
        init_checker();
        init_cnt_of_status_arr();
        init_all_arr(); //inside apb_scoreboard, sts readdata array, tx_data arr, rx readdata arr
        forever begin: MAIN_RUN
        fork 
            forever begin: DETECT_RESET_APB0
                //`uvm_info(get_type_name(), "APB0 WAIT RESET", UVM_HIGH) //(*)
                //(*) causes simulation extremely low
                presetn_fifo[0].get(rst0_flag);
                if(rst0_flag == 1'b0) begin
                `uvm_info(get_type_name(), "APB0 RESET active low", UVM_LOW)
                break;
                end
            end: DETECT_RESET_APB0
            //
            forever begin: HANDLE_APB_0
                `uvm_info(get_type_name(), "CHECK APB SLAVE of UART0", UVM_HIGH)
                //wait actual apb transfer
                apb_to_slv_fifo[0].get(apb0_to_slv_item);
                //wait expected apb transfer
                apb_txn_fifo[0].get(apb0_item);
                //
                compare_apb(0, apb0_item, apb0_to_slv_item);
                //
            end:HANDLE_APB_0
        //
            forever begin:DETECT_RESET_APB1
                //`uvm_info(get_type_name(), "APB1 WAIT RESET", UVM_HIGH)
                presetn_fifo[1].get(rst1_flag);
                if(rst1_flag == 1'b0) begin
                `uvm_info(get_type_name(), "APB1 RESET active low", UVM_LOW)
                break;
                end
            end: DETECT_RESET_APB1
            //
            forever begin: HANDLE_APB_1
                `uvm_info(get_type_name(), "CHECK APB SLAVE of UART1", UVM_HIGH)
                apb_to_slv_fifo[1].get(apb1_to_slv_item);
                apb_txn_fifo[1].get(apb1_item);
                //
                compare_apb(1, apb1_item, apb1_to_slv_item);
            end: HANDLE_APB_1

            //
            `ifdef INTERRUPT
            forever begin
                int_fifo[0].get();
                notify_interrupt(1'b0);
            end
            //
            forever begin
                int_fifo[1].get();
                notify_interrupt(1'b1);
            end
            `endif
        join_any
        disable fork;
        //
        flush_fifo();
        init_all_arr(); //inside apb_scoreboard, sts readdata array, tx_data arr, rx readdata arr
        `uvm_info(get_type_name(), "[RESET_DETECTED]Clear all CHECKERs and FIFOs", UVM_LOW)
        end: MAIN_RUN
	endtask
	//
	//check_phase
	//
	function void apb_uart_scoreboard::check_phase(uvm_phase phase);
		data_8bit exp_data = 0, act_data = 0;
        full_data status_data;
        bit rdata_rdy = 1'b1;
        bit tx_data_rdy = 1'b1;
        data_q rx_tmp_q, tx_tmp_q;
        sts_q sts_tmp_q;
        //
        if(rx_dat_arr.size() == 0) begin
            `uvm_info(get_type_name(), "rx_dat_arr is EMPTY", UVM_LOW)
            rdata_rdy = 1'b0;
        end
        //
        if(tx_data_arr.size() == 0) begin
            `uvm_info(get_type_name(), "tx_data_arr is EMPTY", UVM_LOW)
            tx_data_rdy = 1'b0;
        end
		//=============================================================== 
		//----------------------TX0_RX1
		//=============================================================== 
		while(1) begin
            if(!rdata_rdy || !tx_data_rdy) break;
            //
            if(uart_tx_fifo[0].is_empty()) begin
                `uvm_info(get_type_name(), "uart_tx_fifo[0]is EMPTY", UVM_LOW)
                break;
            end 
            //
            rx_tmp_q = rx_dat_arr[1];
            tx_tmp_q = tx_data_arr[0];
            //
            if(rx_tmp_q.size() == 0) begin
                `uvm_info(get_type_name(), "rx_data_q[1] is EMPTY", UVM_LOW)
                break;
            end
            //
            if(tx_tmp_q.size() == 0) begin
                `uvm_info(get_type_name(), "tx_data_q[0] is EMPTY", UVM_LOW)
                break;
            end
            //
			foreach(rx_tmp_q[i]) begin: TX0_RX1_START
                exp_data = tx_tmp_q[i];
                act_data = rx_tmp_q[i];
                //
				if(uart_tx_fifo[0].try_get(uart0_tx_item)) begin
                    //----------------------compare PARALEL-SERIAL
					compare_serial(2'b11, exp_data, uart0_tx_item, serial_uart_01_pass, serial_uart_01_fail);
	//input bit [1:0] control, //print_parity, uart_01_or_10, 
	//input data_8bit data,
	//input uart_seq_item item,
                    //---------------------compare PARALEL-PARALEL 
					compare_parallel(1'b0, exp_data, act_data, parallel_uart_01_pass, parallel_uart_01_fail);
				end
				else begin
					`uvm_error(get_type_name(), "try_get uart_tx_fifo[0] FAILED!!!")
				end
			end: TX0_RX1_START 
		end

		//=============================================================== 
		//----------------------TX1_RX0
		//=============================================================== 
		while(1) begin
            if(!rdata_rdy || !tx_data_rdy) break;
            //
            if(uart_tx_fifo[1].is_empty()) begin
                `uvm_info(get_type_name(), "uart_tx_fifo[1]is EMPTY", UVM_LOW)
                break;
            end 
            //
            rx_tmp_q = rx_dat_arr[0];
            tx_tmp_q = tx_data_arr[1];
            //
            if(rx_tmp_q.size() == 0) begin
                `uvm_info(get_type_name(), "rx_data_q[0] is EMPTY", UVM_LOW)
                break;
            end
            //
            if(tx_tmp_q.size() == 0) begin
                `uvm_info(get_type_name(), "tx_data_q[1] is EMPTY", UVM_LOW)
                break;
            end
            //
			foreach(rx_tmp_q[i]) begin: TX1_RX0_START
                act_data = rx_tmp_q[i];
                exp_data = tx_tmp_q[i];
                //
				if(uart_tx_fifo[1].try_get(uart1_tx_item)) begin
                    //----------------------compare PARALEL-SERIAL
					compare_serial(2'b11, exp_data, uart0_tx_item, serial_uart_10_pass, serial_uart_10_fail);
	//input bit [1:0] control, //print_parity, uart_01_or_10, 
	//input data_8bit data,
	//input uart_seq_item item,
                    //---------------------compare PARALEL-PARALEL 
					compare_parallel(1'b1, exp_data, act_data, parallel_uart_10_pass, parallel_uart_10_fail);
				end
				else begin
					`uvm_error(get_type_name(), "try_get uart_tx_fifo[1] FAILED!!!")
				end
			end:TX1_RX0_START
		end
        //
        if(sts_arr.size() == 0) begin
            `uvm_error(get_type_name(), "status readdata  array is EMPTY!!!")
        end
        else begin
            for(int i = 0; i < sts_arr.size(); i++) begin 
                sts_tmp_q = sts_arr[i];
                //
                if(sts_tmp_q.size() == 0) begin
                    `uvm_error(get_type_name(), $sformatf("sts_q[%0d] is EMPTY!!!", i))
                end
                else begin
                    foreach(sts_tmp_q[i]) begin
                        check_status(sts_tmp_q[i]);
                    end
                end
                //
            end
        end
        //
	endfunction
//report_phase
function void apb_uart_scoreboard::report_phase(uvm_phase phase);
    super.report_phase(phase);
    //
    `uvm_info(get_type_name(), "***************************************************", UVM_LOW)
    `uvm_info(get_type_name(), "******************FINAL REPORT*********************", UVM_LOW)
    `uvm_info(get_type_name(), "***************************************************", UVM_LOW)
     //
    `uvm_info(get_type_name(), $sformatf("UART0_TX(SERIAL__): %0d PASS---%0d FAIL ",
     serial_uart_01_pass, serial_uart_01_fail), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("UART1_TX(SERIAL__): %0d PASS---%0d FAIL ",
     serial_uart_10_pass, serial_uart_10_fail), UVM_LOW)
     //
    `uvm_info(get_type_name(), $sformatf("UART0_RX(PARALLEL): %0d PASS---%0d FAIL ",
     parallel_uart_01_pass, parallel_uart_01_fail), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("UART1_RX(PARALLEL): %0d PASS---%0d FAIL ",
     parallel_uart_10_pass, parallel_uart_10_fail), UVM_LOW)
     //
    `uvm_info(get_type_name(), "**************STATUS REGISTER REPORT************", UVM_LOW)
    for(int i = 0; i < NO_USED_STATUS_BITS; i++) begin
        `uvm_info(get_type_name(), $sformatf("NO_%s = %0d ", sts_bit_arr[i], cnt_of_status_arr[sts_bit_arr[i]]), UVM_LOW)
    end
    //
    `ifdef
    `uvm_info(get_type_name(), "********************INTERRUPT REPORT********************", UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("UART0_INTERRUPT = %0d ", no_uart0_int), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("UART1_INTERRUPT = %0d ", no_uart1_int), UVM_LOW)
    `endif
endfunction
//
function void apb_uart_scoreboard::final_phase(uvm_phase phase);
    flush_fifo();
endfunction
//
//
function void apb_uart_scoreboard::compare_parallel(bit control, data_8bit exp_data, data_8bit act_data, inout int no_pass, inout int no_fail);
    string hd;
    //
    begin
        hd = control ? "U1_TXD_U0_RXD" : "U0_TXD_U1_RXD";
        if(exp_data == act_data) begin
            `uvm_info(get_type_name(), 
            $sformatf("[%s]PASS exp: %08b---act: %08b",
                hd, exp_data, act_data), UVM_LOW)
            //
            no_pass++;
         end
        else begin
            `uvm_info(get_type_name(), 
            $sformatf("[%s]FAIL exp: %08b---act: %08b",
                hd, exp_data, act_data), UVM_LOW)
            //
            no_fail++;
        end
    end
endfunction//end of compare PARALEL-PARALEL
	//
	//-----------------------compare APB with mirrored value of reg model
	//
	function void apb_uart_scoreboard::compare_serial(
		input bit [1:0] control, //print_parity, uart_01_or_10, 
		input data_8bit exp_data,
		input uart_seq_item act_data,
		inout int no_pass,
		inout int no_fail
	);
		string hd;
		bit uart_01_or_10 = control[0];
		bit print_parity = control[1];
		//
	begin
		hd = uart_01_or_10 ? "U0_TXD_U1_RX" : "U1_TXD_U0_RX";
		//
		//
		if(exp_data == act_data.tx_data) begin
            `uvm_info(get_type_name(), 
			$sformatf("[%s]PASS exp: %08b---act: %08b", hd, exp_data, act_data.tx_data), UVM_LOW)
            no_pass++;
		end
		else begin
		`uvm_info(get_type_name(), 
			$sformatf("[%s]FAIL exp: %08b---act: %08b", hd, exp_data, act_data.tx_data), UVM_LOW)
            no_fail++;
		end
		//
		if(print_parity) begin 
			`uvm_info(get_full_name(), 
			$sformatf("[%s]PARITY bit = %0b --- STOP bit = %0b",
			 hd, act_data.parity_bit, act_data.stop_bit), UVM_LOW)
		end
	end
	endfunction
    //
    //
function void apb_uart_scoreboard::check_status(input logic [`APB_AW-1:0] status);
    string hd = "";
    //
    for(int i = 0; i < NO_USED_STATUS_BITS; i++) begin
        //
        hd = sts_bit_arr[i];
        detect_status_bit(status[i], hd);
    end
endfunction
//
//
function void apb_uart_scoreboard::detect_status_bit(input bit bit_status, input string hd);
    if(bit_status) begin
        `uvm_info(get_type_name(), $sformatf("[%s]", hd), UVM_LOW)
        //
        if(cnt_of_status_arr.exists(hd)) begin
            cnt_of_status_arr[hd]++;
        end
        else begin
            cnt_of_status_arr[hd] = 1;
        end
    end						
endfunction
//
function void apb_uart_scoreboard::init_cnt_of_status_arr();
    string hd = "";
    //
    for(int i = 0; i < NO_USED_STATUS_BITS; i++) begin
        hd = sts_bit_arr[i];
        cnt_of_status_arr[hd] = 0;
        //
    end
endfunction
//
function void apb_uart_scoreboard::init_checker();
    super.init_checker();
    begin
        serial_uart_01_pass = 0;
        serial_uart_01_fail = 0;
        serial_uart_10_pass = 0;
        serial_uart_10_fail = 0;
        //
        parallel_uart_01_pass = 0;
        parallel_uart_01_fail = 0;
        parallel_uart_10_pass = 0;
        parallel_uart_10_fail = 0;
        //
        `ifdef INTERRUPT
        no_uart0_int = 0;
        no_uart1_int = 0;
        `endif
        //
        cnt_of_status_arr.delete();
    end
endfunction
//
function void apb_uart_scoreboard::flush_fifo();
    uart_seq_item tmp;
    logic int_tmp;
    //
    super.flush_fifo();
    begin
        for(integer i = 0; i < env_cfg_h.no_of_agent; i++) begin
            while(!uart_tx_fifo[i].is_empty()) begin
                if(uart_tx_fifo[i].try_get(tmp)) begin
                end
            end
            `ifdef INTERRUPT
            while(!int_fifo[i].is_empty()) begin
                if(int_fifo[i].try_get(int_tmp)) begin
                end
            end
            `endif
        end
    end
endfunction
//
