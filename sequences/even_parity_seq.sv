
//======================================================================================
//--Project: Design and verify  APB-UART IP 
//--File name: even_parity_seq.sv
//--Author: Nguyen Ngoc Man
//--Description: check UART operation with no parity 
//--Configuration of this class is implemented in virtual_even_parity_seq class
//======================================================================================
import apb_pkg::*;
import uart_ral_pkg::*;
import env_pkg::*;
//
class even_parity_seq#(SYS_CLK = 50_000_000, OVERSAMPLE = 16, BAUD_RATE=9600) extends uart_base_seq;
typedef even_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) seq_name;
	localparam DIVISOR = SYS_CLK/(OVERSAMPLE * BAUD_RATE) - 1;
    localparam CLK_CYCLE = (10**9/SYS_CLK);
	`uvm_object_param_utils(seq_name)
	//
	int i;
    int no_apb_trans;
	//
	function new(string name = "even_parity_seq");
		super.new(name);
        i = 0;
        no_apb_trans = 0;
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
			rm_h.CTRL.parity_case == EVEN_PARITY;
			rm_h.CTRL.interrupt_en == 0;}
		); //no parity and no interrupt
		//
		wdata_h = rm_h.CTRL.get();
		rm_h.CTRL.write(status_h, wdata_h, .path(UVM_FRONTDOOR));
		`uvm_info(get_name(), $sformatf("[CONTROL]WRITE DONE---STATUS = %s!!!", status_h), UVM_LOW)
        //
        no_apb_trans++;
		//
		//============================================
		//set up BBR
		//============================================
		$cast(wdata_h, DIVISOR);
		rm_h.DIV.write(status_h, wdata_h, .path(UVM_FRONTDOOR));
		`uvm_info(get_name(), $sformatf("[BRR_VALUE]WRITE DONE---STATUS = %s!!!", status_h), UVM_LOW)
        no_apb_trans++;
		//============================================
		//Write TX_DATA
		//============================================
		if(tx_enable) begin: OPERATOR_OF_TX
            //
            foreach(tx_gen_h.tx_dat_fifo[i]) begin
                wdata_h = tx_gen_h.tx_dat_fifo[i];
                rm_h.TX_DATA.write(status_h, wdata_h, UVM_FRONTDOOR);
                `uvm_info(get_name(), 
                $sformatf("WR TX_DATA[%0d] = %0h---STS[%0d] = %s", i, wdata_h, i, status_h), UVM_LOW)
                no_apb_trans++;
            end
		end:OPERATOR_OF_TX 
		//==================================================================
        //Read TX_DATA
		//==================================================================
		if(rx_enable) begin: OPERATOR_OF_RX 
            #(DIVISOR*OVERSAMPLE*CLK_CYCLE*20*8);
            `uvm_info(get_name(), $sformatf("DIV_VALUE = %0d", DIVISOR), UVM_MEDIUM)
            `uvm_info(get_name(), $sformatf("OVERSAMPLE = %0d", OVERSAMPLE), UVM_MEDIUM)
            `uvm_info(get_name(), $sformatf("CLK_CYCLE = %0d", CLK_CYCLE), UVM_MEDIUM)
            //DIVISOR*OVERSAMPLE*CLK_CYCLE: cycle count of shifting ONE bit
            //10: total bits ,8: frames 
            repeat(no_rx_data) begin
                //CRITICAL NOTE: TXD_REG is only-read register, so we
                //do NOT care DESIRED_VALUE  => only focus on
                //MIRRORED_VALUE
                //rm_h.RXD.print();
                rm_h.RX_DATA.read(status_h, rd_out, .path(UVM_FRONTDOOR));
                `uvm_info(get_name(), $sformatf("Rd_RX[%0d]STS = %s", i++, status_h), UVM_LOW)
                no_apb_trans++;
            end
		end: OPERATOR_OF_RX 
	endtask

endclass
