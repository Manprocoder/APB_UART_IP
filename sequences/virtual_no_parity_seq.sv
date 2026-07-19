//==========================================================
//Project: Design and Verify APB UART IP 
//File name: virtual_no_parity_seq.sv
//Author: Nguyen Ngoc Man
//Description:  
//==========================================================
//
class virtual_no_parity_seq#(SYS_CLK = 50_000_000, OVERSAMPLE = 16, BAUD_RATE=9600) extends virtual_base_seq;
typedef virtual_no_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) vir_np_seq;
    `uvm_object_param_utils(vir_np_seq)
    //no_parity seq
    typedef no_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) no_par_seq;
    //reset sequence
    typedef uart_rst_sequence rst_seq;
    //================================================
    //-----------Data Members
    //================================================
    no_par_seq no_par_seq_0_h, no_par_seq_1_h;
    //
    rst_seq rst0_seq_h, rst1_seq_h;
    //
    uvm_status_e status0_h, status1_h;
    //
    parameter NO_TX0 = 8;
    //
     function new(string name = "virtual_no_parity_seq");
        super.new(name);
    endfunction
    //
    virtual task body();
        get_env_handle(); //env_h---virtual_base_seq 
        //--test case sequence
        no_par_seq_0_h = no_par_seq::type_id::create("no_par_seq_0_h");
        no_par_seq_1_h = no_par_seq::type_id::create("no_par_seq_1_h");
        //--reset sequence
        rst0_seq_h = rst_seq::type_id::create("rst0_seq_h");
        rst1_seq_h = rst_seq::type_id::create("rst1_seq_h");
        //==================================================================
        //----------DO CONFIGURATION: call functions of uart_base_seq class
        //==================================================================
        //--1: assign rm handles
        no_par_seq_0_h.assign_rm_handle(env_h.reg_model_h[0]);
        no_par_seq_1_h.assign_rm_handle(env_h.reg_model_h[1]);
        //--2: enable TX_RX
        no_par_seq_0_h.en_tx_rx(2'b10, NO_TX0); //enable TX---disable RX
        no_par_seq_1_h.en_tx_rx(2'b01, NO_TX0); //disable TX---enable RX
        //--3: gen TX_DATA
        no_par_seq_0_h.gen_tx_data(NO_TX0, 0); //8 datas, UART0
        //==================================================================
        //---------START SIMULATION
        //==================================================================
        //--1: RESET
        `uvm_info(get_full_name(), "[START] reset sequence!!!", UVM_LOW)
        fork
            rst0_seq_h.start(p_sequencer.apb_sqr_h[0]);
            rst1_seq_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_full_name(), "[DONE] reset sequence!!!", UVM_LOW)
        //--2: START
        fork
            no_par_seq_0_h.start(p_sequencer.apb_sqr_h[0]);
            no_par_seq_1_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_full_name(), "[DONE]no_parity sequence!!!", UVM_LOW)
        // 
    endtask
endclass: virtual_no_parity_seq

