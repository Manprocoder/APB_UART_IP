//===========================================================================
//--Project: Design and Verify APB UART IP
//--File: apb_monitor.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//===========================================================================
class apb_monitor extends uvm_monitor;
  typedef apb_seq_item apb_item;
  `uvm_component_utils(apb_monitor)
  //
  apb_item apb_trans_h, other_trans_h;
  apb_agent_config mon_cfg;
  uvm_analysis_port #(logic) presetn_ap;  //to connect scoreboard (reset)
//  uvm_analysis_port #(logic [`SLAVE_CNT-1:0]) pseltb_ap;  //to connect scoreboard (psel)
  uvm_analysis_port #(apb_item) apb_item_ap;  //to connect scoreboard (APB Packet)
  uvm_analysis_port #(apb_item) Other_ap;  //to connect scoreboard (other Packet)
  //------------------------------------------
  //data members
  //------------------------------------------
  logic preset_n;
  //logic [`SLAVE_CNT-1:0] psel_tb;
  //
  function new(string name="APB Monitor", uvm_component parent);
    super.new(name, parent);
  endfunction:new

  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task detect_rst();
  extern virtual task monitor_apb_data();
  extern virtual task monitor_other_signals(); //slave peripheral of APB 
  //extern virtual task detect_psel();

endclass
//====================================================================================
//------------------IMPLEMENTATION of all METHODs
//====================================================================================
function void apb_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  //
  apb_item_ap = new("apb_item_ap", this);
  Other_ap = new("Other_ap", this);
  presetn_ap = new("presetn_ap", this);
 // pseltb_ap = new("pseltb_ap", this);
endfunction
//
task apb_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    //all task run with while(1)
    //here, we must use fork-join_none or fork-join_any
    //jork-join will block this task, while(1) never stops
    fork
        monitor_apb_data();
        monitor_other_signals();
        detect_rst();
      //  detect_psel();
    join_none
endtask
//
//---collect data of multiple slaves
//
task apb_monitor::monitor_apb_data();
  while(1) begin
    @(mon_cfg.vif.mon_cb iff mon_cfg.vif.mon_cb.psel) begin
        if(mon_cfg.vif.mon_cb.psel && mon_cfg.vif.mon_cb.penable && mon_cfg.vif.mon_cb.pready) begin
            //
            apb_trans_h = apb_item::type_id::create("apb_trans_h"); //(*)
            //--(*) MUST be used to create NEW OBJECT--DYNAMIC to avoid override mechanism because of STATIC
            //--because we are using foreach loop
            //
            apb_trans_h.addr[31:0] = mon_cfg.vif.mon_cb.paddr[31:0];
            apb_trans_h.be[3:0] = mon_cfg.vif.mon_cb.pstrb[3:0];
            apb_trans_h.wr_en = mon_cfg.vif.mon_cb.pwrite;
            if(apb_trans_h.wr_en) begin
                apb_trans_h.data = mon_cfg.vif.mon_cb.pwdata;
            end
            else begin
                apb_trans_h.data = mon_cfg.vif.mon_cb.prdata;
            end
            //
            apb_trans_h.err = mon_cfg.vif.mon_cb.pslverr; 
            //Send the transaction to analysis port which is connected to Scb
            apb_item_ap.write(apb_trans_h);
          // end //end of if penable
        end //end of if psel && pready
    end //end of posedge clk
  end//end of while(1)
endtask
//

task apb_monitor::monitor_other_signals();
 	if(mon_cfg.active == UVM_ACTIVE) begin
		while(1) begin
		    @(mon_cfg.vif.other_mon_cb);
		    if(mon_cfg.vif.other_mon_cb.en_o) begin: ENABLE
                other_trans_h = apb_seq_item::type_id::create("other_trans_h");	
                //
                if(mon_cfg.vif.other_mon_cb.wr_en_o) begin
                    other_trans_h.wr_en = 1'b1;
                    other_trans_h.addr = mon_cfg.vif.other_mon_cb.addr_o;
                    other_trans_h.data = mon_cfg.vif.other_mon_cb.wdata_o;
                    other_trans_h.err = mon_cfg.vif.other_mon_cb.err_i;
                    other_trans_h.be = mon_cfg.vif.other_mon_cb.be_o;
                    //
                    `uvm_info(get_type_name(), "[WRITE_APB_OTHERs] send to scb!!! ", UVM_MEDIUM)
                end
                else begin
		   //-------------------------------------------------------------------------------------------// 
                    other_trans_h.wr_en = 1'b0;
                    other_trans_h.addr = mon_cfg.vif.other_mon_cb.addr_o;
                    //
                    @(mon_cfg.vif.other_mon_cb);// iff mon_cfg.vif.other_mon_cb.pready_i);
                    other_trans_h.data = mon_cfg.vif.other_mon_cb.rdata_i;
                    other_trans_h.err = mon_cfg.vif.other_mon_cb.err_i;
                    other_trans_h.be = mon_cfg.vif.other_mon_cb.be_o;
                    //
                    `uvm_info(get_type_name(), "[READ__APB_OTHERs] send to scb !!! ", UVM_MEDIUM)
                end
                //
                Other_ap.write(other_trans_h);
            end: ENABLE
            //
		end//end of while(1)
	end
endtask
//On each clock, send the reset status to Scb
//via analysis port preset_ap
task apb_monitor::detect_rst();
  while(1) begin
    @(mon_cfg.vif.mon_cb);
    this.preset_n = mon_cfg.vif.presetn;
    presetn_ap.write(this.preset_n);
  end
endtask
//
//task apb_monitor::detect_psel();
  //while(1) begin
    //@(mon_cfg.vif.mon_cb iff mon_cfg.vif.presetn);
    //this.psel_tb = mon_cfg.vif.mon_cb.psel;
    //pseltb_ap.write(this.psel_tb);
  //end
//endtask
