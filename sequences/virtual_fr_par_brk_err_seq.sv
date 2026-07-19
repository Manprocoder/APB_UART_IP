//==========================================================
//Project: Design and Verify APB UART IP 
//File name: virtual_fr_par_brk_err_seq.sv
//Author: Nguyen Ngoc Man
//Description: 
//--frame error, parity error, break_error 
//==========================================================
//
class virtual_fr_par_brk_err_seq#(SYS_CLK = 50_000_000, OVERSAMPLE = 16, BAUD_RATE = 9600, BAUD_RATE_2 = 115200) extends virtual_base_seq;
typedef virtual_fr_par_brk_err_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE, BAUD_RATE_2) this_seq;
    `uvm_object_param_utils(this_seq)
    typedef uart_rst_sequence rst_seq;
    //MUST notice
    //first baud_rate is written to brr_reg of hardware
    //second baud_rate is used to count required time to start READ data 
    //
    typedef fr_par_brk_err_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE, BAUD_RATE_2) fe_pe_brk_0_seq;
    typedef fr_par_brk_err_seq#(SYS_CLK, OVERSAMPLE, BAUD_RATE_2, BAUD_RATE) fe_pe_brk_1_seq;
    //
    //reset sequence
    rst_seq rst0_seq_h, rst1_seq_h;
    //parity error, frame error, break condition sequence
    fe_pe_brk_0_seq fe_pe_brk_0_seq_h;
    fe_pe_brk_1_seq fe_pe_brk_1_seq_h;
    //number of test
    parameter NO_TX0 = 1;
    parameter NO_TX1 = 1;
    //
    function new(string name = "virtual_fr_par_brk_err_seq");
        super.new(name);
    endfunction
    //
    virtual task body();
        //super.body();//get environment handle  => ILLEGAL instruction
        get_env_handle(); //get env handle
        //
        rst0_seq_h = rst_seq::type_id::create("rst0_seq_h");
        rst1_seq_h = rst_seq::type_id::create("rst1_seq_h");
        fe_pe_brk_0_seq_h = fe_pe_brk_0_seq::type_id::create("fe_pe_brk_0_seq_h"); 
        fe_pe_brk_1_seq_h = fe_pe_brk_1_seq::type_id::create("fe_pe_brk_1_seq_h"); 
        //===============================================================
        //-----------------DO CONFIGURATION---call uart_base_seq functions
        //===============================================================
        //assign reg model handle 
        fe_pe_brk_0_seq_h.assign_rm_handle(env_h.reg_model_h[0]);
        fe_pe_brk_1_seq_h.assign_rm_handle(env_h.reg_model_h[1]);
        //
        fe_pe_brk_0_seq_h.en_tx_rx(2'b10, NO_TX0);//enable TX, disable RX       
        fe_pe_brk_1_seq_h.en_tx_rx(2'b01, NO_TX1);//disable TX, enable RX
        //===============================================================
        //-----------------START SIMULATION
        //===============================================================
        //--1: RESET
        `uvm_info(get_name(), "[START]reset sequence!!!", UVM_LOW)
        fork 
        rst0_seq_h.start(p_sequencer.apb_sqr_h[0]);
        rst1_seq_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_name(), "[DONE]reset sequence!!!", UVM_LOW)
        //
        //--2: START 
        //
        fork
            fe_pe_brk_0_seq_h.start(p_sequencer.apb_sqr_h[0]);
            fe_pe_brk_1_seq_h.start(p_sequencer.apb_sqr_h[1]);
        join 
        `uvm_info(get_type_name(), "[DONE]fe_pe_brk sequence", UVM_LOW)
        //
    endtask
endclass
