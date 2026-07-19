//==========================================================================================================
//Project: Design and Verify APB UART IP 
//File name: fr_par_brk_err_seq.sv
//Author: Nguyen Ngoc Man
//Description: 
//
//--sequence to test parity error, frame error, break condition
//--Idea: 
//--FREQUENCY: 50MHz:
//--1: BREAK CONDITION and FRAME ERROR
//***************Test BREAK CONDITION and FRAME ERR
//
//--UART0: BAUD_RATE: 9600 => BRR = 16'd324 => total time for START bit:
//--OVERSAMPLE * 324 = 16*324 = 5184 cycles
//--UART1: BAUD_RATE: 115200 => BRR = 16'd26 => 
//--26 * 8(START bit) + 26 * 16 * 10(8 bit DATA, parity bit, stop bit) = 4368
//cycles
//--==> total time for sampling full frame of UART1 < total time for sending START bit
//--of UART0 ==> sampled full frame of UART1 is predicted as a completely bit-0 sequence 
//***************End of Test BREAK CONDITION and FRAME ERR
//--2: PARITY ERROR 
//--RCV data of UART1 is full of bit 0 => even parity is expected --- config odd parity to 
//--make up PARITY ERROR plot
//
//==========================================================================================================
import apb_pkg::*;
import uart_ral_pkg::*;
import env_pkg::*;
//
class fr_par_brk_err_seq#(SYS_CLK = 50_000_000, OVERSAMPLE = 16, BAUD_RATE=9600, BAUD_RATE_2 = 115200) extends uart_base_seq;
typedef fr_par_brk_err_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE, BAUD_RATE_2) this_seq;
    //--parameters
	localparam DIVISOR_1 = SYS_CLK/(OVERSAMPLE * BAUD_RATE) - 1; //is written to BRR register of hardware
	localparam DIVISOR_2 = SYS_CLK/(OVERSAMPLE * BAUD_RATE_2) - 1; // is used to count required time to start READ data if rx_enable is active
    localparam CLK_CYCLE = (10**9)/SYS_CLK;
    //
	`uvm_object_param_utils(this_seq)
    //counter to track a number of transfer
    int no_apb_trans;
    //status flag
    bit fr_err, parity_err, brk_con;
	//
	function new(string name = "fr_par_brk_err_seq");
		super.new(name);
        no_apb_trans = 0;
	endfunction
	//
	//
	virtual task body();
		uvm_status_e status_h;
		uvm_reg_data_t wdata_h, rd_out, mirrored_val;
		//
		if(rm_h == null) begin
			`uvm_fatal(get_name(), "rm_h is NULL")
		end
		//============================================
		//set up control register
		//============================================
		assert(rm_h.CTRL.randomize() with {
			rm_h.CTRL.parity_case == ODD_PARITY; 
			rm_h.CTRL.interrupt_en == 0;
		});
        wdata_h = rm_h.CTRL.get();
		rm_h.CTRL.write(status_h, wdata_h, .path(UVM_FRONTDOOR));
		`uvm_info(get_name(), $sformatf("[WR_CTRL]STATUS = %s", status_h), UVM_LOW)
        no_apb_trans++;
		//============================================
		//set up BRR_VALUE register
		//============================================
		rm_h.DIV.write(status_h, DIVISOR_1, .path(UVM_FRONTDOOR));
		`uvm_info(get_name(), $sformatf("[WR_DIV]STATUS = %s", status_h), UVM_LOW)
        no_apb_trans++;
		//============================================
		//set up TXD input
		//============================================
		if(tx_enable) begin
            rm_h.TX_DATA.write(status_h, 8'h00, .path(UVM_FRONTDOOR));
            `uvm_info(get_name(), $sformatf("[WR_TXD]STATUS = %s", status_h), UVM_LOW)
            no_apb_trans++;
		end
		//============================================
		//--read STATUS and read RXD
		//============================================
		if(rx_enable) begin
            #(OVERSAMPLE * DIVISOR_2 * CLK_CYCLE * 20); 		
            `uvm_info(get_name(), "DIV VALUE below is not brr value written to hardware", UVM_MEDIUM)
            `uvm_info(get_name(), $sformatf("DIV_VALUE = %0d", DIVISOR_2), UVM_MEDIUM)
            `uvm_info(get_name(), $sformatf("OVERSAMPLE = %0d", OVERSAMPLE), UVM_MEDIUM)
            `uvm_info(get_name(), $sformatf("CLK_CYCLE = %0d", CLK_CYCLE), UVM_MEDIUM)
            //OVERSAMPLE * DIVISOR * CLK_CYCLE  //needed cycles to shift new bit
            //(BREAK_CON) is HIGH
            //rm_h.map.set_check_on_read(1); //only when set_auto_predict(0)
            //--1: rd RXD
            rm_h.RX_DATA.read(status_h, rd_out, UVM_FRONTDOOR);
            `uvm_info(get_name(), $sformatf("[RD_RXD]STATUS = %s", status_h), UVM_LOW)
            no_apb_trans++;
            //--2: rd status
            rm_h.STATUS.read(status_h, rd_out, UVM_FRONTDOOR);
            `uvm_info(get_name(), $sformatf("[RD_STS]STATUS = %s", status_h), UVM_LOW)
            no_apb_trans++;
            //---------------------------------------------------
            //----------check status
            //---------------------------------------------------
            if(rd_out[0] == 1'b1) begin
                fr_err = 1'b1;
            end
            //
            if(rd_out[1] == 1'b1) begin
                parity_err = 1'b1;
            end
            //
            if(rd_out[2] == 1'b1) begin
                brk_con = 1'b1;
            end

    //[0-9]{"FRAME_ERROR", "PARITY_ERROR", "BREAK_CON", "TX_OV", "RX_OV", "RX_FULL", "TX_FULL", "RX_NOT_EMPTY", "UART_BUSY", "RX_UD"};
            //
            //--3: clear status
            rm_h.STATUS.write(status_h, 32'd0, .path(UVM_FRONTDOOR));
            `uvm_info(get_name(), $sformatf("[CLR_STS]STATUS = %s", status_h), UVM_LOW)
            no_apb_trans++;
            //--4: read STATUS again
            rm_h.STATUS.read(status_h, rd_out);
            `uvm_info(get_name(), $sformatf("[RD_STS]AFTER_CLEAR---STATUS = %s", status_h), UVM_LOW)
            no_apb_trans++;
		end
	endtask
endclass

