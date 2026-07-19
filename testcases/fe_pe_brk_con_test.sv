//============================================================================================
//Project: Design and Verify APB UART IP 
//File name: fe_pe_brk_con_test.sv
//Author: Nguyen Ngoc Man
//Description:this test is used for testing frame error, parity error, break condition 
//============================================================================================
class fe_pe_brk_con_test extends base_test;
	`uvm_component_utils(fe_pe_brk_con_test)
    parameter SYS_CLK = 50*(10**6);
    parameter OVERSAMPLE = 16;
    parameter BAUD_RATE = 9600;  
    parameter BAUD_RATE_2 = 115200;  
    typedef virtual_fr_par_brk_err_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE, BAUD_RATE_2) vir_f_p_brk_seq;
	//============================================
    //-----------Data Members
	//============================================
	vir_f_p_brk_seq v_seq_h; 
    int no_tx_data = 1;
    //
	function new (string name = "fe_pe_brk_con_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction
	//
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		uvm_config_db#(int)::set(this, "env_h*", "no_tx_data", no_tx_data);
	endfunction
	//
	virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
	endfunction
    //
	virtual task run_phase(uvm_phase phase);
		v_seq_h = vir_f_p_brk_seq::type_id::create("v_seq_h");
		//
       `uvm_info(get_type_name(), "PREPARE FOR SIMULATION!!!", UVM_HIGH)
		phase.raise_objection(this);
       `uvm_info(get_type_name(), "START SIMULATION!!!", UVM_HIGH)
       fork 
       begin: RUN
           if(env_cfg_h.has_virtual_sequencer) begin
               v_seq_h.start(env_h.vsqr_h);
			end
			else begin
				init_vseq(v_seq_h); //assign sequencer in virtual sequence to actual exising sequencer
				v_seq_h.start(null);
			end
			//#50ms;
            //---using extra 50ms because
            //--UART0 ONLY writes configuration and disable RX channel
            //--UART1 operates RX channel with low BRR (16'h1A)
            //--sequence ends quickly 
            //--UART0 samples TX with HIGH BRR (16'h144)
            //--those infos lead to INADEQUATE time to monitor TX channel of UART0
            //
        end:RUN
		begin: TIMEOUT
			#50ms;
			`uvm_info(get_type_name(), "==========================================================", UVM_LOW)
			`uvm_info(get_type_name(), "==================TIMEOUT---TIMEOUT----TIMEOUT============", UVM_LOW)
			`uvm_info(get_type_name(), "==========================================================", UVM_LOW)
		end: TIMEOUT 
		join_any
		disable fork;
		phase.drop_objection(this);
	endtask
    //
    virtual function void report_phase(uvm_phase phase);
        int total_apb_trans = 0;
        total_apb_trans = v_seq_h.fe_pe_brk_0_seq_h.no_apb_trans + v_seq_h.fe_pe_brk_1_seq_h.no_apb_trans;
        // 
        `uvm_info(get_name(), $sformatf("NUMBER of APB transfers: %0d", total_apb_trans) , UVM_LOW)
        //
        total_apb_trans = 0;
        total_apb_trans = v_seq_h.NO_TX0 + v_seq_h.NO_TX1;
        //
        `uvm_info(get_name(), $sformatf("NUMBER of CMP_TX_PARA_RX_SERI: %0d", total_apb_trans) , UVM_LOW)
        `uvm_info(get_name(), $sformatf("NUMBER of CMP_TX_PARA_RX_PARA: %0d", total_apb_trans) , UVM_LOW)
        //
        `uvm_info(get_name(), $sformatf("FRAME_ERR_ bit: %0b", v_seq_h.fe_pe_brk_1_seq_h.fr_err) , UVM_LOW)
        `uvm_info(get_name(), $sformatf("PARITY_ERR bit: %0b", v_seq_h.fe_pe_brk_1_seq_h.parity_err) , UVM_LOW)
        `uvm_info(get_name(), $sformatf("BRK_CON___ bit: %0b", v_seq_h.fe_pe_brk_1_seq_h.brk_con) , UVM_LOW)
    endfunction
endclass
