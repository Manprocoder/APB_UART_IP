//==========================================================
//Project: Design and Verify APB UART IP 
//File name: no_parity_test.sv
//Author: Nguyen Ngoc Man
//Description: 
//==========================================================
class no_parity_test extends base_test;
	`uvm_component_utils(no_parity_test)
    parameter SYS_CLK = 50*(10**6);
    parameter OVERSAMPLE = 16;
    parameter BAUD_RATE = 9600;  
    typedef virtual_no_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) vir_np_seq;
	//============================================
    //-----------Data Members
	//============================================
	vir_np_seq v_seq_h; 
    int no_tx_data = 8;
    //
	function new (string name = "no_parity_test", uvm_component parent = null);
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
		v_seq_h = vir_np_seq::type_id::create("v_seq_h");
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
           #10ms;
        end:RUN
		begin: TIMEOUT
			#20ms;
			`uvm_info(get_type_name(), "=================================================================", UVM_LOW)
			`uvm_info(get_type_name(), "============TIMEOUT---TIMEOUT----TIMEOUT---20ms ends=============", UVM_LOW)
			`uvm_info(get_type_name(), "=================================================================", UVM_LOW)
		end: TIMEOUT 
		join_any
		disable fork;
		phase.drop_objection(this);
	endtask
endclass
