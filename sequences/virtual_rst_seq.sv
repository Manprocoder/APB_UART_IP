//==========================================================
//Project: Design and Verify APB UART IP 
//File name: virtual_rst_seq.sv
//Author: Nguyen Ngoc Man
//Description: reset test with built-in reset sequence 
//==========================================================

//
class virtual_rst_seq extends virtual_base_seq;
    `uvm_object_utils(virtual_rst_seq)
    //
    typedef uart_rst_sequence rst_seq;
    //reset sequence
    rst_seq rst0_seq_h, rst1_seq_h;
    //read reset-value of all registers 
    reg_model_rst_seq rm0_rst_seq, rm1_rst_seq;
    //
    uvm_status_e status0_h, status1_h;
    //
     function new(string name = "virtual_rst_seq");
        super.new(name);
    endfunction
    //
    virtual task body();
        get_env_handle(); //env_h---virtual_base_seq 
        //
        rst0_seq_h = rst_seq::type_id::create("rst0_seq_h");
        rst1_seq_h = rst_seq::type_id::create("rst1_seq_h");
        //
        rm0_rst_seq = reg_model_rst_seq::type_id::create("rm0_rst_seq");
        rm1_rst_seq = reg_model_rst_seq::type_id::create("rm1_rst_seq");
        //
        //
        rm0_rst_seq.set_rm_handle_and_sequencer(env_h.reg_model_h[0], p_sequencer.apb_sqr_h[0]);
        rm1_rst_seq.set_rm_handle_and_sequencer(env_h.reg_model_h[1], p_sequencer.apb_sqr_h[1]);
        //
        //---FIRST RESET
        //
        `uvm_info(get_full_name(), "[START]FIRST_RESET reset sequence!!!", UVM_MEDIUM)
        fork
            rst0_seq_h.start(p_sequencer.apb_sqr_h[0]);
            rst1_seq_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_full_name(), "[DONE]FIRST_RESET reset sequence!!!", UVM_MEDIUM)
        //
        //---WRITE ANY VALUE
        //
            fork
                env_h.reg_model_h[0].CTRL.write(status0_h, 32'hFAFAFAFA, .path(UVM_FRONTDOOR));
                env_h.reg_model_h[1].CTRL.write(status1_h, 32'hFBFBFBFB, .path(UVM_FRONTDOOR));
            join
            `uvm_info(get_full_name(), $sformatf("[WRITE_CTRL]STATUS[0] = %s --- STATUS[1] = %s",  status0_h, status1_h), UVM_MEDIUM)
        //
            fork
                env_h.reg_model_h[0].STATUS.write(status0_h, 32'hFAFAFAFA, .path(UVM_FRONTDOOR));
                env_h.reg_model_h[1].STATUS.write(status1_h, 32'hFBFBFBFB, .path(UVM_FRONTDOOR));
            join
            `uvm_info(get_full_name(), $sformatf("[WRITE_STATUS]STATUS[0] = %s --- STATUS[1] = %s",  status0_h, status1_h), UVM_MEDIUM)
        //
            fork
                env_h.reg_model_h[0].DIV.write(status0_h, 32'hFAFAFAFA, .path(UVM_FRONTDOOR));
                env_h.reg_model_h[1].DIV.write(status1_h, 32'hFBFBFBFB, .path(UVM_FRONTDOOR));
            join
            `uvm_info(get_full_name(), $sformatf("[WRITE_DIV]STATUS[0] = %s --- STATUS[1] = %s",  status0_h, status1_h), UVM_MEDIUM)
        //
        //---SECOND RESET
        //
        `uvm_info(get_full_name(), "[START]RESET_AFTER_WRITE reset sequence!!!", UVM_MEDIUM)
        fork
            rst0_seq_h.start(p_sequencer.apb_sqr_h[0]);
            rst1_seq_h.start(p_sequencer.apb_sqr_h[1]);
        join
        `uvm_info(get_full_name(), "[DONE]RESET_AFTER_WRITE reset sequence!!!", UVM_MEDIUM)
        // 
        //run built-in RAL reset sequence
        //---read reset-value of CTRL, STATUS, DIV registers
        //
        fork
            rm0_rst_seq.body();
            rm1_rst_seq.body();
        join
        //
        //----------------reg callbacks to check reset-value of all registers
        //----------------result of testcase will be reported in report_phase of reset_test class
        //
    endtask
endclass: virtual_rst_seq

