//==========================================================
//Project: Design and Verify APB UART IP 
//File name: parity_type_test.sv
//Author: Nguyen Ngoc Man
//Description:this test runs odd and even parity 
//==========================================================
class parity_type_test extends base_test;
	`uvm_component_utils(parity_type_test)
    parameter SYS_CLK = 50*(10**6);
    parameter OVERSAMPLE = 16;
    parameter BAUD_RATE = 9600;  
    typedef virtual_parity_type_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) vir_pt_seq;
	//============================================
    //-----------Data Members
	//============================================
	vir_pt_seq v_seq_h; 
    int no_tx_data = 8;
    //
	function new (string name = "parity_type_test", uvm_component parent = null);
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
		v_seq_h = vir_pt_seq::type_id::create("v_seq_h");
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
        end:RUN
		begin: TIMEOUT
			#120ms;
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
        total_apb_trans = v_seq_h.odd_p_seq_0_h.no_apb_trans + v_seq_h.odd_p_seq_1_h.no_apb_trans
         + v_seq_h.even_p_seq_0_h.no_apb_trans + v_seq_h.even_p_seq_1_h.no_apb_trans;
        // 
        `uvm_info(get_name(), $sformatf("NUMBER of APB transfers: %0d", total_apb_trans) , UVM_LOW)
        //
        total_apb_trans = 0;
        total_apb_trans = v_seq_h.NO_TX0 + v_seq_h.NO_TX1;
        //
        `uvm_info(get_name(), $sformatf("NUMBER of CMP_TX_PARA_RX_SERI: %0d", total_apb_trans) , UVM_LOW)
        `uvm_info(get_name(), $sformatf("NUMBER of CMP_TX_PARA_RX_PARA: %0d", total_apb_trans) , UVM_LOW)
    endfunction
endclass
