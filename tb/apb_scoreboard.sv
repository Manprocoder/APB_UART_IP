//=====================================================================
//Project: Design and verify APB UART IP 
//File name: apb_scoreboard.sv 
//Author: Nguyen Ngoc Man
//Description: apb_scoreboard to check APB slave core's behavior 
//=====================================================================
import apb_pkg::*;
//
virtual class apb_scoreboard extends uvm_scoreboard;
typedef logic [7:0] data_8bit;
typedef apb_seq_item apb_type;
typedef uvm_tlm_analysis_fifo#(apb_seq_item) apb_fifo;
typedef logic [`APB_DW-1:0] sts_q [$];
typedef logic [7:0] data_q [$];
typedef logic [`APB_DW-1:0] full_data;
//
`uvm_component_utils(apb_scoreboard)    
//==========================================================
//-------DATA members
//==========================================================
//--- TLM fifos
uvm_tlm_analysis_fifo#(logic) presetn_fifo[];
apb_fifo apb_txn_fifo[];
apb_fifo apb_to_slv_fifo[];
//--transaction
apb_type apb0_item, apb1_item, apb0_to_slv_item, apb1_to_slv_item;
//--environment config handle
env_config env_cfg_h;
//--checker
int no_apb_pass, no_apb_fail;
//
sts_q sts_arr [int];
data_q rx_dat_arr [int];
//--store TX_DATA--expected RX_DATA
data_q tx_data_arr [int];
//reset flag
logic rst0_flag, rst1_flag;
//==========================================================
//-------METHODs
//==========================================================
extern function new(string name, uvm_component parent);
extern virtual function void build_phase(uvm_phase phase);
extern virtual function void report_phase(uvm_phase phase);
extern virtual function void flush_fifo();
extern virtual function void init_checker(); 
extern virtual function void init_all_arr();
//
pure virtual task run_phase(uvm_phase phase);
//
//
virtual task automatic compare_apb(
    input int apb_1_or_0,
    input apb_type exp_item,
    input apb_type act_item
);
//
string hd;
//
begin
    hd = apb_1_or_0 ? "INSIDE_CORE_APB1" : "INSIDE_CORE_APB0";
    if(act_item.compare(exp_item)) begin
        `uvm_info(get_type_name(), 
        $sformatf("[%s]: MATCH\nEXPECTED: %s --compared to--\nACTUAL: %s",
        hd, exp_item.convert2string, act_item.convert2string), UVM_HIGH)
        no_apb_pass++;
    end
    else begin
        `uvm_info(get_type_name(), 
        $sformatf("[%s]: MISMATCH\nEXPECTED: %s --compared to--\nACTUAL: %s",
        hd, exp_item.convert2string, act_item.convert2string), UVM_LOW)
        no_apb_fail++;
    end
    //
    //---RDATA
    //
    case(exp_item.addr)
        32'h4: begin
            store_status(apb_1_or_0, exp_item.data);
            `uvm_info(get_type_name(), $sformatf("APB[%0b]--store status", apb_1_or_0), UVM_LOW);
        end
        //
        32'h10: begin
            store_rdata(apb_1_or_0, exp_item.data[7:0]);
            `uvm_info(get_type_name(), $sformatf("APB[%0b]--store rdata", apb_1_or_0), UVM_LOW);
        end
    endcase
    //
    //--WDATA
    //
    if(exp_item.addr == 32'hC) begin
            store_tx_data(apb_1_or_0, exp_item.data[7:0]);
    end
end
endtask
//
virtual task store_status(
    input int apb_1_or_0,
    input full_data item
);
//
    sts_q tmp_q = {}; 
    begin
        if(sts_arr.exists(apb_1_or_0)) begin
            tmp_q = sts_arr[apb_1_or_0];
        end
        //
        tmp_q.push_back(item);
        sts_arr[apb_1_or_0] = tmp_q;
        `uvm_info(get_type_name(), $sformatf("DONE[%0d]--store status", apb_1_or_0), UVM_HIGH);
    end
endtask
//
//
virtual task store_rdata(
    input int apb_1_or_0,
    input data_8bit item
);
//
    data_q tmp_q = {}; 
    begin
        if(rx_dat_arr.exists(apb_1_or_0)) begin
            tmp_q = rx_dat_arr[apb_1_or_0];
        end
        //
        tmp_q.push_back(item);
        rx_dat_arr[apb_1_or_0] = tmp_q;
        `uvm_info(get_type_name(), $sformatf("DONE[%0d]--store rdata", apb_1_or_0), UVM_HIGH);
    end
endtask
//
virtual task store_tx_data(
    input int apb_1_or_0,
    input data_8bit item
);
//
    data_q tmp_q = {}; 
    begin
        if(tx_data_arr.exists(apb_1_or_0)) begin
            tmp_q = tx_data_arr[apb_1_or_0];
        end
        //
        tmp_q.push_back(item);
        tx_data_arr[apb_1_or_0] = tmp_q;
        `uvm_info(get_type_name(), $sformatf("DONE[%0d]--store tx_data", apb_1_or_0), UVM_HIGH);
    end
endtask
//
endclass: apb_scoreboard
//==========================================================
//-------IMPLEMENTATION of all METHODs
//==========================================================
function apb_scoreboard::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction
//
function void apb_scoreboard::build_phase(uvm_phase phase);
    //super.build_phase(phase);
    if(!uvm_config_db#(env_config)::get(this, "", "env_cfg", env_cfg_h)) begin
        `uvm_fatal(get_type_name(), "m_cfg is not FOUND!!!")
    end
    //
    presetn_fifo = new[env_cfg_h.no_of_agent];
    apb_txn_fifo = new[env_cfg_h.no_of_agent];
    apb_to_slv_fifo = new[env_cfg_h.no_of_agent];//output of APB_SLAVE, config inputs of UART
    //
    foreach(presetn_fifo[i]) begin
        presetn_fifo[i] = new($sformatf("presetn_fifo[%0d]", i), this);
    end
    //
    foreach(apb_txn_fifo[i]) begin
        apb_txn_fifo[i] = new($sformatf("apb_txn_fifo[%0d]", i), this);
    end
    //
    foreach(apb_to_slv_fifo[i]) begin
        apb_to_slv_fifo[i] = new($sformatf("apb_to_slv_fifo[%0d]", i), this);
    end
    //
    apb0_item = apb_type::type_id::create("apb0_item");
    apb1_item = apb_type::type_id::create("apb1_item");
    apb0_to_slv_item = apb_type::type_id::create("apb0_to_slv_item");
    apb1_to_slv_item = apb_type::type_id::create("apb1_to_slv_item");
    //
endfunction
//
//
function void apb_scoreboard::init_all_arr();
    for(int i = 0; i < env_cfg_h.no_of_agent; i++) begin
        sts_arr[i] = {};
        rx_dat_arr[i] = {};
        tx_data_arr[i] = {};
        //each element of arr is queue
    end
endfunction
//
function void apb_scoreboard::flush_fifo();
    //
    data_8bit tmp;
    full_data sts_tmp;
    //
    for(int i = 0; i<env_cfg_h.no_of_agent; i++) begin
        while(!apb_txn_fifo[i].is_empty()) begin
            if(apb_txn_fifo[i].try_get(apb0_item)) begin
            end
        end
        //
        while(!apb_to_slv_fifo[i].is_empty()) begin
            if(apb_to_slv_fifo[i].try_get(apb0_to_slv_item)) begin
            end
        end
    end
    //
    sts_arr.delete();
    rx_dat_arr.delete();
    tx_data_arr.delete();
    //
endfunction

//
function void apb_scoreboard::init_checker();
    begin    
        no_apb_pass = 0;
        no_apb_fail = 0;
    end
endfunction
//
function void apb_scoreboard::report_phase(uvm_phase phase);

    `uvm_info(get_type_name(), "********************************************************", UVM_LOW)
    `uvm_info(get_type_name(), "********************APB FINAL REPORT********************", UVM_LOW)
    `uvm_info(get_type_name(), "********************************************************", UVM_LOW)
     //
    `uvm_info(get_type_name(), $sformatf("APB: %0d PASS---%0d FAIL ",
     no_apb_pass, no_apb_fail), UVM_LOW)
endfunction
