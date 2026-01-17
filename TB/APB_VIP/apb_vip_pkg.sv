//==========================================================
//Project: Design APB-UART IP core
//File name: apb_vip_pkg.sv
//Description: reuseable APB VIP 
//==========================================================`
package apb_vip_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import parameter_pkg::*;
//**************************************************************
//---------------------APB sequence item
//**************************************************************
class apb_seq_item #(DW = 32, APB_AW = 32) extends uvm_sequence_item;
    typedef apb_seq_item#(DW, APB_AW) this_type_t;
    `uvm_object_param_utils(apb_seq_item#(DW, APB_AW))
	//MASTER role
    rand bit [`AGENT_CNT-1:0] pready;
    rand bit [`AGENT_CNT-1:0] pslverr;
    rand int preadyDelay;
    rand logic [`AGENT_CNT-1:0] psel;
    rand logic [DW/8-1:0] pstrb;
    rand logic           penable;
    //===================================
    // Transaction Request Fields
    //===================================
    rand logic [APB_AW-1:0]  addr;
    rand logic [DW-1:0]  data;
    rand logic       write;
    bit resetn_req;
    //
	constraint c_addr {
	 addr inside {32'h0, 32'h4, 32'h8, 32'hC, 32'h10}; 
	}
	//
    //===================================
    // Constructor
    //===================================
    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

    //===================================
    // UVM built-in overrides
    //===================================
    extern function void   do_print(uvm_printer printer);
    extern function string convert2string();
    extern function bit    do_compare(uvm_object rhs, uvm_comparer comparer);
    extern function void   do_copy(uvm_object rhs);

endclass : apb_seq_item

//=======================================
// do_print
//=======================================
function void apb_seq_item::do_print(uvm_printer printer);
    super.do_print(printer);
    `ifdef APB_SLAVE
    printer.print_field("ADDR",       paddr,       $bits(addr),       UVM_HEX);
    printer.print_field("PWRITE",     pwrite,      $bits(write),      UVM_BIN);
    printer.print_field("PWDATA",     pwdata,      $bits(data),      UVM_HEX);
    printer.print_field("PSEL",       psel,        $bits(psel),        UVM_HEX);
    printer.print_field("PSTRB",      pstrb,       $bits(pstrb),       UVM_HEX);
    printer.print_field("PREADY",     pready,      $bits(pready),      UVM_BIN);
    printer.print_field("PSLVERR",    pslverr,     $bits(pslverr),     UVM_BIN);
    printer.print_field("PREADY_DELAY", preadyDelay, $bits(preadyDelay), UVM_DEC);
    `elsif APB_MASTER
    printer.print_field("ADDR",       addr,       $bits(addr),       UVM_HEX);
    printer.print_field("PWRITE",     write,      $bits(write),      UVM_BIN);
    printer.print_field("DATA",     data,      $bits(data),      UVM_HEX);
    `endif
endfunction

//=======================================
// convert2string
//=======================================
function string apb_seq_item::convert2string();
    string s;
    s = super.convert2string();
	`ifdef APB_SLAVE
    s = {s, $sformatf("ADDR    : 0x%0h\n", addr)};
    s = {s, $sformatf("WDATA   : 0x%0h\n", data)};
    s = {s, $sformatf("PWRITE  : %0b\n", write)};
    s = {s, $sformatf("PSEL    : 0x%0h\n", psel)};
    s = {s, $sformatf("PREADY  : 0x%0h\n", pready)};
    s = {s, $sformatf("PSLVERR : 0x%0h\n", pslverr)};
    s = {s, $sformatf("DELAY   : %0d\n", preadyDelay)};
`elsif APB_MASTER
    s = {s, $sformatf("ADDR = 0x%08h", addr)};
    s = {s, $sformatf("---DATA = 0x%08h", data)};
    s = {s, $sformatf("---WR_OR_RD = %0b", write)};
`endif

    return s;
endfunction

//=======================================
// do_compare
//=======================================
function bit apb_seq_item::do_compare(uvm_object rhs, uvm_comparer comparer);
    this_type_t rhs_;
    bit match;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("APB_SEQ_ITEM", "Object is not of type apb_seq_item")
        return 0;
    end
	
    match = super.do_compare(rhs, comparer);
	`ifdef APB_SLAVE
    match &= (this.addr   == rhs_.addr);
    match &= (this.data   == rhs_.data);
    match &= (this.write  == rhs_.write);
    match &= (this.psel   == rhs_.psel);
    match &= (this.pstrb  == rhs_.pstrb);
    match &= (this.pready == rhs_.pready);
    match &= (this.pslverr == rhs_.pslverr);
`elsif APB_MASTER
    match &= (this.addr  === rhs_.addr);
    match &= (this.data  === rhs_.data);
    match &= (this.write === rhs_.write);
`endif
    return match;
endfunction

//=======================================
// do_copy
//=======================================
function void apb_seq_item::do_copy(uvm_object rhs);
    this_type_t rhs_;

    if(!$cast(rhs_, rhs)) begin
        `uvm_fatal("apb_SEQ_ITEM", "Object is not of type apb_seq_item")
        return;
    end

    super.do_copy(rhs);
	`ifdef APB_SLAVE
    this.addr       = rhs_.addr;
    this.data      = rhs_.data;
    this.write      = rhs_.write;
    this.psel        = rhs_.psel;
    this.pstrb       = rhs_.pstrb;
    this.pready      = rhs_.pready;
    this.pslverr     = rhs_.pslverr;
    `elsif APB_MASTER
    this.addr       = rhs_.addr;
    this.data      = rhs_.data;
    this.write      = rhs_.write;
    `endif
endfunction
//**************************************************************
//---------------------APB sequence 
//**************************************************************
//class apb_seq#(DW = 32, APB_AW = 32) extends uvm_sequence;
//`uvm_object_param_utils(apb_seq#(DW, APB_AW))
  //// Constructor
  //function new(string name="apb_seq");
    //super.new(name);
  //endfunction
    //
//// Main task body
//virtual task body();
	//// Declare items
	//apb_seq_item #(DW, APB_AW) req;
	//`uvm_info(get_type_name(), "APB SEQUENCE body() enters!!!", UVM_LOW);
	////
	//forever begin
		//// Create request item
		//req = apb_seq_item#(DW, APB_AW)::type_id::create("APB SLAVE REQ");
		//if (req == null) begin
		//`ifdef APB_SLAVE
		//`uvm_error(get_type_name(), $sformatf("Failed to create REQ item!!!"));
		//`elsif APB_MASTER
		//`uvm_error(get_type_name(), $sformatf("Failed to create RSP item!!!"));
		//`endif
		//end
		//else begin //req_not_null
		//// Send slave request
		//start_item(req);
		//assert(req.randomize());
		//finish_item(req);
		//end //end of req_not_null
	//end //end of forever
//endtask:body	
      //
//endclass
//**************************************************************
//---------------------APB Config
//**************************************************************
class apb_agent_config extends uvm_object;
	parameter DW = 32;
	parameter APB_AW = 32;
//register factory to use type_id::create() method
    `uvm_object_utils(apb_agent_config)
    //
	virtual interface apb_if #(DW,APB_AW) apb_vif;
	uvm_active_passive_enum active = UVM_ACTIVE;
	//
	function new(string name = "apb_agent_config");
		super.new();
	endfunction
endclass
//**************************************************************
//---------------------APB Sequencer 
//**************************************************************
class apb_sequencer extends uvm_sequencer#(apb_seq_item#(DW,APB_AW));
  //Register to Factory
	`uvm_component_utils(apb_sequencer)
  //
	function new (string name = "apb_sequencer", uvm_component parent = null);
		super.new(name,parent);
	endfunction
endclass
//**************************************************************
//---------------------APB Driver 
//**************************************************************
class apb_driver extends uvm_driver#(apb_seq_item#(DW,APB_AW));
  `uvm_component_utils(apb_driver)
  //
  virtual interface apb_if #(DW, APB_AW) apb_drv_vif; // it is assigned from APB AGENT class
  REQ item; //item
  apb_agent_config drv_cfg; //config object
  //
  //variables
  //
  int counter = 0;
  bit [`AGENT_CNT-1:0] actual_pready;
  bit done, done2;
  logic [DW-1:0] rdata;
  logic active_low_rst;
  //
function new (string name ="APB Driver", uvm_component parent);
    super.new(name, parent);
endfunction:new
//
//
//
virtual function void build_phase(uvm_phase phase);
	super.build_phase(phase);
	//
	if(drv_cfg == null) begin
	`uvm_fatal(get_type_name (), "APB_AGENT_CONFIG OBJECT is NULL!!!")
	end
	else begin
	`uvm_info(get_type_name(), "APB_AGENT_CONFIG OBJECT is FOUND!!!", UVM_HIGH)
	end
//
endfunction:build_phase
//
virtual task run_phase(uvm_phase phase);
	super.run_phase(phase);
	fork
	//first thread
	forever begin: RESET_THREAD
	      reset_all();
	end
	//second thread
	forever begin: SIM_THREAD
		`uvm_info(get_type_name(), "Ready to get new Item(Transaction-level)", UVM_HIGH)
		seq_item_port.get_next_item(item);
		//
		if(drv_cfg.active == UVM_PASSIVE) begin
			slave_role(item);
		end
		else begin
			drive(item);
		end
		seq_item_port.item_done(item);
	end//end of SIM_THREAD
	join_none
endtask
    
    //---------------------------------------
  extern virtual task reset_all();
  extern virtual task drive(inout REQ packet);
  extern virtual task slave_role(REQ packet);
  
endclass
//**************************************************************************************
//***********************************MAIN TASKS*****************************************
//**************************************************************************************
//
//definition of reset_all task
//
task apb_driver::reset_all();
	  	//wait(~apb_drv_vif.presetn);
		//apb_drv_vif.s_drv_cb.pready <= {`AGENT_CNT{1'b0}};
		//apb_drv_vif.s_drv_cb.pslverr <= {`AGENT_CNT{1'b0}};
		////
		//while (1) begin
			//@(apb_drv_vif.s_drv_cb iff ~apb_drv_vif.s_drv_cb.presetn); 
			//apb_drv_vif.s_drv_cb.pready <= {`AGENT_CNT{1'b0}};
			//apb_drv_vif.s_drv_cb.pslverr <= {`AGENT_CNT{1'b0}};
		//end
		wait(~active_low_rst);
		apb_drv_vif.m_drv_cb.psel <= {`AGENT_CNT{1'b0}};
		apb_drv_vif.m_drv_cb.penable <= 1'b0;
		apb_drv_vif.m_drv_cb.pwrite <= 1'b0;
		apb_drv_vif.m_drv_cb.paddr <= {APB_AW{1'b0}};
		apb_drv_vif.m_drv_cb.pwdata <= {DW{1'b0}};
	      while(1) begin
		@(negedge active_low_rst);
		`uvm_info(get_type_name(), "DETECT NEDEDGE of ACTIVE_LOW_RST", UVM_HIGH)
		@(apb_drv_vif.m_drv_cb iff ~active_low_rst); 
		`uvm_info(get_type_name(), "RESET SIGNALS as ACTIVE_LOW_RST active", UVM_HIGH)
		apb_drv_vif.m_drv_cb.psel <= {`AGENT_CNT{1'b0}};
		apb_drv_vif.m_drv_cb.penable <= 1'b0;
		apb_drv_vif.m_drv_cb.pwrite <= 1'b0;
		apb_drv_vif.m_drv_cb.paddr <= {APB_AW{1'b0}};
		apb_drv_vif.m_drv_cb.pwdata <= {DW{1'b0}};
	      end
endtask: reset_all
//
//definition of drive task
//
task apb_driver::drive(inout REQ packet);
	//drive_reset
	if(packet.resetn_req == 1'b1) begin
		`uvm_info(get_type_name(), "drive reset", UVM_HIGH)
		active_low_rst = 1'b0;
	end
	else begin
		active_low_rst = 1'b1;
	end
	//
	@(apb_drv_vif.m_drv_cb);
	apb_drv_vif.m_drv_cb.presetn <= active_low_rst;
	//
	if(active_low_rst == 1'b1) begin //drive_info
		`uvm_info(get_type_name(), "Prepare to drive transaction", UVM_HIGH) //assume: 50ns
		@(apb_drv_vif.m_drv_cb); //clocking block: 50ns 
		`uvm_info(get_type_name(), "Drive PSEL", UVM_HIGH) //70ns
		apb_drv_vif.m_drv_cb.psel <= 1'b1;
		apb_drv_vif.m_drv_cb.penable <= 1'b0;
		apb_drv_vif.m_drv_cb.pwrite <= packet.write;
		apb_drv_vif.m_drv_cb.paddr <= packet.addr;
		apb_drv_vif.m_drv_cb.pwdata <= packet.data;
		@(apb_drv_vif.m_drv_cb); //70ns
		apb_drv_vif.m_drv_cb.penable <= 1'b1;
		//wait pready
		`uvm_info(get_type_name(), $sformatf("WAITING PREADY---MASTER AGENT!!!"), UVM_HIGH); //90ns
		@(apb_drv_vif.m_drv_cb iff apb_drv_vif.m_drv_cb.pready); //90ns
		if(packet.write == 1'b0) begin
			packet.data = apb_drv_vif.m_drv_cb.prdata;
		end
		apb_drv_vif.m_drv_cb.psel <= 1'b0;
		apb_drv_vif.m_drv_cb.penable <= 1'b0;
		apb_drv_vif.m_drv_cb.pwrite <= 1'b0;
		apb_drv_vif.m_drv_cb.paddr <= {APB_AW{1'b0}};
		apb_drv_vif.m_drv_cb.pwdata <= {DW{1'b0}};
	end//end of drive_info
endtask
//
//definition of slave_role
//
task apb_driver::slave_role(REQ packet);
counter = 0;
fork
begin //THREAD_1
@(negedge apb_drv_vif.presetn);
`uvm_info(get_type_name(), $sformatf("PRESET_N EDGE-SENSITIVE!!!"), UVM_HIGH);
end
//
begin//THREAD_2
fork

//
forever begin //SUB_THREAD_2_1
 `uvm_info(get_type_name(), $sformatf("time_1: %0t ns", $time), UVM_HIGH)
//iterates psel in turn to determine selected slave
//@(apb_drv_vif.s_drv_cb iff |apb_drv_vif.s_drv_cb.psel);
//foreach(apb_drv_vif.s_drv_cb.psel[i]) begin
	//if(apb_drv_vif.s_drv_cb.psel[i]) begin//PSEL
		//if(apb_drv_vif.s_drv_cb.pwrite && apb_drv_vif.s_drv_cb.penable) begin
		//done2 = 1'b1;
		//`uvm_info(get_type_name(),
		//$sformatf("[APB WRITE_TRANSFER]: paddr=0x%0h WriteData=0x%08h Pstrb=0x%0h\n",
		//apb_drv_vif.s_drv_cb.paddr, apb_drv_vif.s_drv_cb.pwdata, apb_drv_vif.s_drv_cb.pstrb), UVM_HIGH);
		////
		//end
	//else if(~apb_drv_vif.s_drv_cb.pwrite && ~apb_drv_vif.s_drv_cb.penable) begin
		//rdata = $random();
		//apb_drv_vif.s_drv_cb.prdata[i] <= rdata;
		//done2 = 1'b1;
		//`uvm_info(get_type_name(), $sformatf("[APB READ_TRANSFER]: paddr=0x%0h ReadData=0x%08h",
		//apb_drv_vif.s_drv_cb.paddr, rdata), UVM_HIGH);
	//end
	//else begin
		//done2 = 1'b0;
	//end
	////
	//end//end of PSEL
//end //end of foreach
//
//if(done2) break;
//`endif
//end//end of SUB_THREAD_2_1
////
//forever begin //SUB_THREAD_2_2
//@(apb_drv_vif.s_drv_cb iff |apb_drv_vif.s_drv_cb.psel);
////packet.print();
//`uvm_info(get_type_name(), $sformatf("counter = %0d", counter), UVM_HIGH);
//`uvm_info(get_type_name(), $sformatf("preadyDelay = %0d", packet.preadyDelay), UVM_HIGH);
//`ifdef APB_SLAVE
//foreach(apb_drv_vif.s_drv_cb.psel[i]) begin
	//if(apb_drv_vif.s_drv_cb.psel[i]) begin //PSEL
		//if(packet.pready[i]) begin
		//actual_pready = packet.pready;
		//done = 1'b1;
		//end
		//else if(counter == packet.preadyDelay)begin
		//actual_pready[i] = 1'b1;
		//done = 1'b1;
		//end
		//else begin
		//actual_pready = packet.pready;
		//done = 1'b0;
		//end
		////
		//apb_drv_vif.s_drv_cb.pready <= actual_pready;
		//// usually 1 (ready)
		//apb_drv_vif.s_drv_cb.pslverr <= packet.pslverr; // usually 0 (no error)
		////
		//if(~packet.pready[i] && apb_drv_vif.s_drv_cb.penable) counter++;
	//end//end of PSEL
//end//end of foreach
//if(done) begin
//break;
//end
end //end of SUB_THREAD_2_2
join
end//end of THREAD_2 
join_any
disable fork;
endtask
//**************************************************************
//---------------------APB Monitor 
//**************************************************************
class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)
  //
  virtual interface apb_if #(DW,APB_AW) apb_mon_vif;
  //
  apb_agent_config mon_cfg;
  //
  apb_seq_item#(DW,APB_AW) apb_transfer, sub_transfer;
  uvm_analysis_port #(logic) presetn_ap;  //to connect scoreboard (reset)
  uvm_analysis_port #(logic [`AGENT_CNT-1:0]) pseltb_ap;  //to connect scoreboard (psel)
  uvm_analysis_port #(apb_seq_item#(DW,APB_AW)) apb_item_ap;  //to connect scoreboard (APB Packet)
  uvm_analysis_port #(apb_seq_item#(DW,APB_AW)) apb_to_uart_item_ap;  //to connect scoreboard (APB Packet)
  //------------------------------------------
  //data members
  //------------------------------------------
  logic preset_n;
  logic [`AGENT_CNT-1:0] psel_tb;
  //
  function new(string name="APB Monitor", uvm_component parent);
    super.new(name, parent);
  endfunction:new

  extern function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task detect_rst();
  extern virtual task monitor_main_signal();
  extern virtual task monitor_sub_signal();
  extern virtual task detect_psel();

endclass

//
function void apb_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  apb_item_ap = new("apb_item_ap", this);
  apb_to_uart_item_ap = new("apb_to_uart_item_ap", this);
  presetn_ap = new("presetn_ap", this);
  pseltb_ap = new("pseltb_ap", this);
  //
  if(mon_cfg == null) begin
	  `uvm_fatal(get_type_name(), "MON_CONFIG is NULL")
  end
  else begin
	  `uvm_info(get_type_name(), "MON_CONFIG is FOUND!!!", UVM_HIGH)
  end

endfunction

//
task apb_monitor::run_phase(uvm_phase phase);
    super.run_phase(phase);
    //all task run with while(1)
    //here, we must use fork-join_none or fork-join_any
    //jork-join will block this task, while(1) never stops
    fork
        monitor_main_signal();
	monitor_sub_signal();	
        detect_rst();
        detect_psel();
    join_none
endtask
//
//---collect data of multiple slaves
//
task apb_monitor::monitor_main_signal();
  while(1) begin
    @(apb_mon_vif.mon_cb iff |apb_mon_vif.mon_cb.psel) begin
      foreach(apb_mon_vif.mon_cb.psel[i]) begin
        if(apb_mon_vif.mon_cb.psel[i] && apb_mon_vif.mon_cb.penable && apb_mon_vif.mon_cb.pready[i]) begin
            // `uvm_info(get_type_name(), $sformatf("PENABLE: %0b -- PREADY: %0b",
            // apb_mon_vif.mon_cb.penable, apb_mon_vif.mon_cb.pready[i]), UVM_LOW);
            //
            apb_transfer = apb_seq_item#(DW,APB_AW)::type_id::create("APB TRANSFER"); //(*)
            //--create_item (*) MUST be made here to avoid DATA LOSS (override mechanism)
            //--because we are using foreach loop
            //
            apb_transfer.addr[APB_AW-1:0] = apb_mon_vif.mon_cb.paddr[APB_AW-1:0];
            apb_transfer.pstrb[3:0] = apb_mon_vif.mon_cb.pstrb[3:0];
            apb_transfer.write = apb_mon_vif.mon_cb.pwrite;
            apb_transfer.data = (apb_mon_vif.mon_cb.pwrite) ? apb_mon_vif.mon_cb.pwdata : apb_mon_vif.mon_cb.prdata[i];
	    apb_transfer.pslverr = apb_mon_vif.mon_cb.pslverr;
            `uvm_info(get_type_name(), $sformatf("BUS_ADDRESS_: 0x%08h", apb_mon_vif.mon_cb.paddr), UVM_DEBUG);
            `uvm_info(get_type_name(), $sformatf("ITEM_ADDRESS: 0x%08h", apb_transfer.addr), UVM_DEBUG);
            if(apb_mon_vif.mon_cb.pwrite) begin
              `uvm_info(get_type_name(), $sformatf("WRITEDATA: 0x%08h", apb_transfer.data), UVM_DEBUG);
            end
            else begin
              `uvm_info(get_type_name(), $sformatf("READDATA: 0x%08h", apb_transfer.data), UVM_DEBUG);
            end
            //Send the transaction to analysis port which is connected to _scb
            apb_item_ap.write(apb_transfer);
          // end //end ef if penable
        end //end of if psel && pready
      end //end of foreach
    end //end of posedge clk
  end//end of while(1)
endtask
//
task apb_monitor::monitor_sub_signal();
	if(mon_cfg.active == UVM_ACTIVE) begin
		while(1) begin
		    @(apb_mon_vif.mon_cb);
		    if(apb_mon_vif.mon_cb.wr_en_o) begin
			sub_transfer = apb_seq_item#(DW, APB_AW)::type_id::create("sub_transfer");	
			sub_transfer.write = 1'b1;
			sub_transfer.addr = apb_mon_vif.mon_cb.addr_o;
			sub_transfer.data = apb_mon_vif.mon_cb.wdata_o;
			apb_to_uart_item_ap.write(sub_transfer);
			`uvm_info(get_type_name(), "[WRITE]apb_to_uart sent to scb", UVM_MEDIUM)
		    end
		   // 
		    if(apb_mon_vif.mon_cb.rd_en_o) begin
			sub_transfer = apb_seq_item#(DW, APB_AW)::type_id::create("sub_transfer");	
			sub_transfer.write = 1'b0;
			sub_transfer.addr = apb_mon_vif.mon_cb.addr_o;
			@(apb_mon_vif.mon_cb);
			sub_transfer.data = apb_mon_vif.mon_cb.rdata_i;
			apb_to_uart_item_ap.write(sub_transfer);
			`uvm_info(get_type_name(), "[READ]apb_to_uart sent to scb", UVM_MEDIUM)
		    end
		end
	end
endtask
//
//On each clock, send the reset status to _scb
//via analysis port preset_ap
task apb_monitor::detect_rst();
  while(1) begin
    @(apb_mon_vif.mon_cb);
    this.preset_n = apb_mon_vif.presetn;
    presetn_ap.write(this.preset_n);
  end
endtask
//
task apb_monitor::detect_psel();
if(mon_cfg.active == UVM_PASSIVE) begin
	  while(1) begin
	    @(apb_mon_vif.mon_cb iff apb_mon_vif.presetn);
	    this.psel_tb = apb_mon_vif.mon_cb.psel;
	    pseltb_ap.write(this.psel_tb);
	  end
  end //end of if
endtask
//**************************************************************
//---------------------APB REG ADAPTER 
//**************************************************************
class reg_apb_adapter extends uvm_reg_adapter;
  `uvm_object_utils(reg_apb_adapter)
  
  function new(string name = "reg_apb_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses = 1;
  endfunction
  
  virtual function uvm_sequence_item reg2bus (const ref uvm_reg_bus_op rw);
    apb_seq_item#(DW,APB_AW) bus_item = apb_seq_item#(DW, APB_AW)::type_id::create("bus_item");
    bus_item.addr = rw.addr;
    bus_item.data = rw.data;
    bus_item.write = (rw.kind == UVM_READ) ? 0 : 1;
    
    `uvm_info(get_type_name, $sformatf("reg2bus: addr = %0h, data = %0h, write = %0h",
	    bus_item.addr, bus_item.data, bus_item.write), UVM_LOW);
    return bus_item;
  endfunction
  
  virtual function void bus2reg (uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_seq_item#(DW, APB_AW) bus_pkt;
    if(!$cast(bus_pkt, bus_item)) begin
      `uvm_fatal(get_type_name(), "Failed to cast bus_item transaction")
     end

    rw.addr = bus_pkt.addr;
    rw.data = bus_pkt.data;
    rw.kind = (bus_pkt.write) ? UVM_WRITE: UVM_READ;
    //
    `uvm_info(get_type_name, $sformatf("bus2reg: addr = %08h, data = %08h, write = %s",
	    rw.addr, rw.data, rw.kind), UVM_LOW);
  endfunction
endclass
//**************************************************************
//---------------------APB Agent
//**************************************************************
class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)
    //
    apb_driver apb_drv_h;
    apb_monitor apb_mon_h;
    apb_sequencer apb_sqr_h;
    //
    apb_agent_config apb_cfg;
    //
    function new(string name="APB Agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
   
endclass

//
function void apb_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);
    //
    if(!uvm_config_db #(apb_agent_config)::get(this,"", "apb_cfg", apb_cfg))begin
        `uvm_fatal(get_type_name(), "apb_cfg is not found!!!")
    end
    //
    apb_mon_h = apb_monitor::type_id::create("apb_mon_h", this);
    apb_drv_h = apb_driver::type_id::create("apb_drv_h", this);
    //
apb_sqr_h = apb_sequencer::type_id::create("apb_sqr_h", this);
    //
    apb_drv_h.apb_drv_vif = apb_cfg.apb_vif;
    apb_mon_h.apb_mon_vif = apb_cfg.apb_vif;
	apb_drv_h.drv_cfg = apb_cfg;
	apb_mon_h.mon_cfg = apb_cfg;
    //$cast(apb_drv_h.drv_cfg, apb_cfg.clone()); // assign config object
    //$cast(apb_mon_h.mon_cfg, apb_cfg.clone()); // assign config object
endfunction

function void apb_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
        apb_drv_h.seq_item_port.connect(apb_sqr_h.seq_item_export);
endfunction

//
//**************************************************************
//---------------------COMPLETION OF APB VIF 
//**************************************************************
//
//
endpackage	
