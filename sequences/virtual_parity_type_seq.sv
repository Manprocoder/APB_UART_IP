//==========================================================
//Project: Design and Verify APB UART IP 
//File name: virtual_parity_type_seq.sv
//Author: Nguyen Ngoc Man
//Description: this class runs odd and even parity of UART 
//==========================================================
//
class virtual_parity_type_seq#(SYS_CLK = 50_000_000, OVERSAMPLE = 16, BAUD_RATE=9600) extends virtual_base_seq;
typedef virtual_parity_type_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) vir_pt_seq;
    `uvm_object_param_utils(vir_pt_seq)
    //parity_type seq
    typedef odd_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) odd_p_seq;
    typedef even_parity_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE) even_p_seq;
    //reset sequence
    typedef uart_rst_sequence rst_seq;
    //================================================
    //-----------Data Members
    //================================================
    odd_p_seq odd_p_seq_0_h, odd_p_seq_1_h;
    even_p_seq even_p_seq_0_h, even_p_seq_1_h;
    //
    rst_seq rst0_seq_h, rst1_seq_h;
    //
    uvm_status_e status0_h, status1_h;
    //number of test
    parameter NO_TX0 = 8;
    parameter NO_TX1 = 8;
    //
     function new(string name = "virtual_parity_type_seq");
        super.new(name);
    endfunction
    //
    virtual task body();
        get_env_handle(); //env_h---virtual_base_seq 
        //--test case sequence
        odd_p_seq_0_h = odd_p_seq::type_id::create("odd_p_seq_0_h");
        odd_p_seq_1_h = odd_p_seq::type_id::create("odd_p_seq_1_h");
        even_p_seq_0_h = even_p_seq::type_id::create("even_p_seq_0_h");
        even_p_seq_1_h = even_p_seq::type_id::create("even_p_seq_1_h");
        //--reset sequence
        rst0_seq_h = rst_seq::type_id::create("rst0_seq_h");
        rst1_seq_h = rst_seq::type_id::create("rst1_seq_h");
        //==================================================================
        //----------DO CONFIGURATION: call functions of uart_base_seq class
        //==================================================================
        //--1: assign rm handles
        odd_p_seq_0_h.assign_rm_handle(env_h.reg_model_h[0]);
        odd_p_seq_1_h.assign_rm_handle(env_h.reg_model_h[1]);
        even_p_seq_0_h.assign_rm_handle(env_h.reg_model_h[0]);
        even_p_seq_1_h.assign_rm_handle(env_h.reg_model_h[1]);
        //--2: enable TX_RX
        odd_p_seq_0_h.en_tx_rx(2'b10, NO_TX0); //enable TX---disable RX
        odd_p_seq_1_h.en_tx_rx(2'b01, NO_TX0); //disable TX---enable RX
        even_p_seq_0_h.en_tx_rx(2'b10, NO_TX1); //enable TX---disable RX
        even_p_seq_1_h.en_tx_rx(2'b01, NO_TX1); //disable TX---enable RX
        //--3: gen TX_DATA
        odd_p_seq_0_h.gen_tx_data(NO_TX0, 0); //no_test, UART0
        even_p_seq_0_h.gen_tx_data(NO_TX1, 0); //8 datas, UART0
        //==================================================================
        //---------START SIMULATION
        //==================================================================
        //--1: RESET
        `uvm_info(get_name(), "[START] reset sequence!!!", UVM_LOW)
        fork
            rst0_seq_h.start(p_sequencer.apb_sqr_h[0]);
            rst1_seq_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_name(), "[DONE] reset sequence!!!", UVM_LOW)
        //--2: START
        fork
            odd_p_seq_0_h.start(p_sequencer.apb_sqr_h[0]);
            odd_p_seq_1_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_name(), "[DONE]odd_parity_type sequence!!!", UVM_LOW)
        //--3: START
        fork
            even_p_seq_0_h.start(p_sequencer.apb_sqr_h[0]);
            even_p_seq_1_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_name(), "[DONE]even_parity_type sequence!!!", UVM_LOW)
        // 
    endtask
endclass: virtual_parity_type_seq

