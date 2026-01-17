//==========================================================
//Project: Design APB-UART IP core
//File name: sequence_pkg.sv
//Description: sequence package
//==========================================================
package sequence_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import apb_vip_pkg::*;
import parameter_pkg::*;
import uart_ral_pkg::*;
import env_pkg::*;
import env_cfg_pkg::*;
//
//================================================
//------------TX GENERATOR
//================================================
class tx_generator extends uvm_sequence_item;
	`uvm_object_utils(tx_generator)
	typedef enum logic [1:0] {FULL_ZERO, FULL_ONE, EVEN_ONE, ODD_ONE} data_case; 
	//all fields
	rand uvm_reg_data_t tx_dat_fifo[$];
	//
	//
	rand data_case tx_data_case [];
	rand bit [7:0] dat_q [$];
	rand int no_dat;
	//
	constraint no_dat_c{
		no_dat inside {[1:8]}; 
	}
	//
	constraint dat_q_size_c{
		dat_q.size() == no_dat;
	}
	//
	constraint case_c{
		tx_data_case.size() == no_dat;
		foreach(tx_data_case[i]) {
			tx_data_case[i] dist {FULL_ZERO:=1, FULL_ONE:=1, EVEN_ONE:=2, ODD_ONE:=2};
		}
	}
	//
	constraint dat_q_value_c{
		foreach(dat_q[i]) { 
			if(tx_data_case[i] == FULL_ZERO) {
				dat_q[i] == 8'h00;
			}
			else if(tx_data_case[i] == FULL_ONE) {
				dat_q[i] == 8'hff;
			}
			else if(tx_data_case[i] == EVEN_ONE) {	
				($countones(dat_q[i]) % 2) == 0;
			}
			else if(tx_data_case[i] == ODD_ONE) {
				($countones(dat_q[i]) % 2) == 1;
			}
		}
	};

	function new(string name = "tx_generator");
		super.new(name);
	endfunction
	//
	//
	function void post_randomize();
		tx_dat_fifo.delete();
		foreach(dat_q[i]) begin
			tx_dat_fifo.push_back(dat_q[i]);
			`uvm_info(get_full_name(), $sformatf("dat_q[%0d] = %02h", i, dat_q[i]), UVM_LOW)
		end
		dat_q.delete();
	endfunction
	//
endclass
//================================================================================
//------------UART_BASE_SEQ
//================================================================================
virtual class uart_base_seq#(DW = 32, APB_AW = 32) extends uvm_sequence#(apb_seq_item#(DW, APB_AW));
	`uvm_object_param_utils(uart_base_seq#(DW, APB_AW))

	apb_seq_item#(DW, APB_AW) rst_item;
	uart_reg_model rm_h; 
	env_config env_cfg_h;
	tx_generator tx_gen_h;
	bit tx_enable; //tx_enable TX_DATA write process
	bit rx_enable;
		//
	function new(string name = "uart_base_seq");
		super.new(name);
	endfunction
	//
	virtual function void assign_rm_handle(uart_reg_model rm_ref);
		this.rm_h = rm_ref;
	endfunction
	//
	virtual function void en_tx_rx_operation(bit [1:0] en);
		this.tx_enable = en[1];
		this.rx_enable = en[0];
	endfunction
	//
	virtual function void gen_tx_data(int no_of_member);
		tx_gen_h = tx_generator::type_id::create("tx_gen_h");
		assert(tx_gen_h.randomize() with {tx_gen_h.no_dat == no_of_member;});
	endfunction
	//
	pure virtual task body();
endclass
//
//rst sequence
//
class uart_rst_sequence#(DW = 32, APB_AW = 32) extends uart_base_seq#(DW, APB_AW);
	`uvm_object_param_utils(uart_rst_sequence#(DW, APB_AW))
	//
	function new(string name = "uart_rst_sequence");
		super.new(name);
	endfunction
	//
	virtual task body();
		`uvm_info(get_type_name(), "[uart0_reset sequence] enters body task ", UVM_LOW)
		rst_item = apb_seq_item#(DW, APB_AW)::type_id::create("uart0_rst_item");
		//
		`uvm_info(get_type_name(), "[uart0_reset sequence] start generating stimulus", UVM_LOW)
		start_item(rst_item);
		rst_item.resetn_req = 1;
		finish_item(rst_item);
		get_response(rst_item);
		//
	endtask
endclass
//
//----built-in test sequence: RESET
//
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
		reg_model_h.TXD.get_full_name()}, "NO_REG_HW_RESET_TEST", 1); 
		//--2: rx_fifo
		uvm_resource_db #(bit)::set({"REG::", 
		reg_model_h.RXD.get_full_name()}, "NO_REG_HW_RESET_TEST", 1); 
		//
		rst_seq = uvm_reg_hw_reset_seq::type_id::create("reg_model_rst_seq");
		rst_seq.model = reg_model_h;
		rst_seq.start(sqr_h);
		`uvm_info(get_type_name(), "BUILT-IN RAL RESET SEQUENCE DONE!!!", UVM_LOW)
	endtask
endclass
//==============================================================================================================
//------------------------------------EVEN PARITY CASE  
//==============================================================================================================
//
class uart_even_parity_seq#(SYS_CLK = 50_000_000, OVERSAMPLE = 16, BAUD_RATE=9600) extends uart_base_seq#(DW, APB_AW);
	parameter DIVISOR = SYS_CLK/(OVERSAMPLE * BAUD_RATE) - 1;
	parameter NUMBER = 8;
	`uvm_object_param_utils(uart_even_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE))
	//
	int i;
	//
	function new(string name = "uart_even_parity_seq");
		super.new(name);
	endfunction
	//
	//
	virtual task body();
		uvm_status_e status_h;
		uvm_reg_data_t wdata_h, rd_out, mirrored_val;
		//
		if(rm_h == null) begin
			`uvm_fatal(get_type_name(), "rm_h is NULL")
		end
		//============================================
		//set up control register
		//============================================
		assert(rm_h.CTRL.randomize() with {
			rm_h.CTRL.parity_case == 2'b01;
			rm_h.CTRL.interrupt_en == 0;}
		); //even parity and no interrupt
		//
		rm_h.CTRL.update(status_h, .path(UVM_FRONTDOOR));
		`uvm_info(get_type_name(), $sformatf("[CONTROL]WRITE DONE---STATUS = %s!!!", status_h), UVM_LOW)
		//
		//mirrored_val = rm_h.CTRL.get_mirrored_value();
		//wdata_h = rm_h.CTRL.get(); //desired value
		//`uvm_info(get_type_name(),
		//$sformatf("[CONTROL]MV = %08h --- DV = %08h", mirrored_val, wdata_h), UVM_LOW)
		//============================================
		//set up BBR
		//============================================
		$cast(wdata_h, DIVISOR);
		rm_h.DIV.write(status_h, wdata_h, .path(UVM_FRONTDOOR));
		`uvm_info(get_type_name(), $sformatf("[BRR_VALUE]WRITE DONE---STATUS = %s!!!", status_h), UVM_LOW)
		//============================================
		//set up tx_data register
		//============================================
		if(tx_enable) begin// OPERATOR_OF_TX
		gen_tx_data(NUMBER);
		//
		foreach(tx_gen_h.tx_dat_fifo[i]) begin
			wdata_h = tx_gen_h.tx_dat_fifo[i];
			rm_h.TXD.write(status_h, wdata_h, UVM_FRONTDOOR);
			`uvm_info(get_type_name(), 
			$sformatf("[WRITE_TX][WRITE]:DATA[%0d] = %0h---STATUS[%0d] = %s!!!", i, wdata_h, i, status_h), UVM_LOW)
			//rm_h.TXD.print();
			//
			//---------------check MV and DV
		//mirrored_val = rm_h.TXD.get_mirrored_value();
		//wdata_h = rm_h.TXD.get();
		//`uvm_info(get_type_name(),
		//$sformatf("[WRITE_TX][BEFORE_SET][%0d]MV = %08h --- DV = %08h", i, mirrored_val, wdata_h), UVM_LOW)
			//
			//rm_h.TXD.set(wdata_h);
			//rm_h.TXD.update(status_h); 
		end
		//read STATUS and expect 5th bit in STATUS's DUT reg is HIGH 
		//----=>expects TX_FIFO full
		rm_h.STATUS.read(status_h, rd_out);
		`uvm_info(get_type_name(), $sformatf("[RD_STATUS][AFTER_WR_TX_DATA]STATUS = %s!!!", status_h), UVM_LOW)
		end//end of tx_enable OPERATOR_OF_TX 
		//
		//rm_h.DIV.print();
		mirrored_val = rm_h.DIV.get_mirrored_value();
		wdata_h = rm_h.DIV.get();
		`uvm_info(get_type_name(),
		$sformatf("[BRR_VALUE] WRITE DONE-->MV = %08h --- DV = %08h", mirrored_val, wdata_h), UVM_LOW)
		//==================================================================
		//Read Status and RX_data: Read status---> Read Rx_fifo
		//--->Read Status again
		//==================================================================
		if(rx_enable) begin //RX_ENABLE
		#(DIVISOR*OVERSAMPLE*14*8*`CLK_CYCLE);
		//---(1)
		//=> predict STATUS = 32'h0000_0080 => 7th bit (RX_NOT_EMPTY)
		//is HIGH
		rm_h.STATUS.read(status_h, rd_out, .path(UVM_FRONTDOOR));
		//---(2)
		repeat(NUMBER) begin
			//CRITICAL NOTE: TXD_REG is only-read register, so we
			//do NOT care DESIRED_VALUE  => only focus on
			//MIRRORED_VALUE
			//rm_h.RXD.print();
		rm_h.RXD.read(status_h, rd_out, .path(UVM_FRONTDOOR));
		`uvm_info(get_type_name(), $sformatf("[READ_RX][DONE][%0d]---STATUS = %s!!!", i++, status_h), UVM_LOW)
		end
		//---(3)
		//predict status is reset back 0 after reading RXD
		rm_h.STATUS.read(status_h, rd_out, .path(UVM_FRONTDOOR));
		end //RX_ENABLE
		//=> expect rx_not_empty---7th bit is LOW 
		//=> expect trans_empty ---9th bit is HIGH
	endtask

endclass
//==========================================================================================================
//sequence to test parity error, frame error, break condition
//Idea: 
//--FREQUENCY: 50MHz:
//--UART0: BAUD_RATE: 9600 => BRR = 16'd324 => total time for START bit:
//OVERSAMPLE * 324 = 16*324 = 5184 cycles
//--UART1: BAUD_RATE: 115200 => BRR = 16'd26 => 
//--26 * 8(START bit) + 26 * 16 * 10(8 bit DATA, parity bit, stop bit) = 4368
//cycles
//==> total time for sampling full frame of UART1 < total time for sending START bit
//of UART0 ==> sampled full frame of UART1 is predicted as a completely bit-0 sequence --> we
//configure odd parity to make up parity error plot
//
//==========================================================================================================
class parity_frame_error_seq#(SYS_CLK = 50_000_000, OVERSAMPLE = 16, BAUD_RATE=9600) extends uart_base_seq#(DW, APB_AW);
	parameter logic [15:0] DIVISOR = SYS_CLK/(OVERSAMPLE * BAUD_RATE) - 1;
	parameter BEFORE_RXD = 32'h0000_0080;
	parameter AFTER_RXD = 32'h0000_0087;
	`uvm_object_param_utils(parity_frame_error_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE))
	//
	function new(string name = "parity_frame_error_seq");
		super.new(name);
	endfunction
	//
	//
	virtual task body();
		uvm_status_e status_h;
		uvm_reg_data_t wdata_h, rd_out, mirrored_val;
		//
		if(rm_h == null) begin
			`uvm_fatal(get_type_name(), "rm_h is NULL")
		end
		//============================================
		//set up control register
		//============================================
		assert(rm_h.CTRL.randomize() with {
			rm_h.CTRL.parity_case == 2'b10; //odd parity
			rm_h.CTRL.interrupt_en == 0;
		});
		rm_h.CTRL.update(status_h, .path(UVM_FRONTDOOR));
		`uvm_info(get_type_name(), $sformatf("[CONTROL]WRITE DONE---STATUS = %s!!!", status_h), UVM_LOW)
		//============================================
		//set up BRR_VALUE register
		//============================================
		rm_h.DIV.write(status_h, DIVISOR, .path(UVM_FRONTDOOR));
		`uvm_info(get_type_name(), $sformatf("[DIV]WRITE DONE---STATUS = %s!!!", status_h), UVM_LOW)
		//
		rm_h.DIV.mirror(status_h, UVM_CHECK); //along with setting provides_reponses to HIGH in adapter class
		//
		//============================================
		//set up TXD input
		//============================================
		if(tx_enable) begin
		rm_h.TXD.write(status_h, 8'h00, .path(UVM_FRONTDOOR));
		`uvm_info(get_type_name(), $sformatf("[TXD]WRITE DONE---STATUS = %s!!!", status_h), UVM_LOW)
		end
		//============================================
		//--read STATUS and read RXD
		//============================================
		if(rx_enable) begin
			// sample 11 bit but we use 14 for certainty
		#(OVERSAMPLE * DIVISOR * 14 * `CLK_CYCLE); //create 10-bit latency of sampling
		//--read status attemp 1
		//=> predict STATUS = 32'h0000_0084 => 
		//--> 7th bit (RX_NOT_EMPTY) and 2nd bit (BREAK_CON) is HIGH
		//rm_h.map.set_check_on_read(1); //only when set_auto_predict(0)
		rm_h.STATUS.read(status_h, rd_out, UVM_FRONTDOOR);
		`uvm_info(get_type_name(), $sformatf("[STATUS]BEFORE_RD_RXD---STATUS = %s!!!", status_h), UVM_LOW)
		//--2: rd RXD
		rm_h.RXD.read(status_h, rd_out, UVM_FRONTDOOR);
		`uvm_info(get_type_name(), $sformatf("[RXD]READ DONE---STATUS = %s!!!", status_h), UVM_LOW)
		//
		//--read status attemp 2
		//=> predict STATUS = 32'h0000_0007 => 
		//-->, 2nd (BREAK_CON), 1st (PE), LSB (FE) are HIGH
		//=>rm_h.STATUS.mirror(status_h, rd_out, UVM_PREDICT); (*)
		//(*)status is not read 
		rm_h.STATUS.read(status_h, rd_out);
		`uvm_info(get_type_name(), $sformatf("[STATUS]AFTER_RD_RXD---STATUS = %s!!!", status_h), UVM_LOW)
		//--3: clear status
		rm_h.STATUS.write(status_h, 32'd0, .path(UVM_FRONTDOOR));
		`uvm_info(get_type_name(), $sformatf("[STATUS]CLEAR---STATUS = %s!!!", status_h), UVM_LOW)
		//--4: read STATUS again
		rm_h.STATUS.read(status_h, rd_out);
		`uvm_info(get_type_name(), $sformatf("[STATUS]AFTER_CLEAR---STATUS = %s!!!", status_h), UVM_LOW)
		end
	endtask
endclass
endpackage

