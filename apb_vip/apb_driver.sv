//===========================================================================
//--Project: Design and verify APB UART IP
//--File: apb_driver.sv
//--Author: Nguyen Ngoc Man
//--Description: 
//===========================================================================
class apb_driver extends uvm_driver#(apb_seq_item);
  `uvm_component_utils(apb_driver)
  //===============================================
  //---------------Data Members
  //===============================================
  parameter DEPTH = 4096; //using localparam causes error 
  //--transaction
  REQ item;
  //--config object
  apb_agent_config drv_cfg; //config object
  //--handle response in
  int counter = 0;
  bit actual_pready;
  logic [`APB_AW-1:0] rdata;
  //--
  bit done, done2;
  //--Memory 
  logic [7:0] mem [DEPTH]; 
  logic [`APB_DW-1:0] new_value, current_value;
  //reset
  bit active_low_rst;
  //===============================================================
  //-------------------Methods
  //===============================================================

extern function new (string name ="APB Driver", uvm_component parent);
extern virtual function void build_phase(uvm_phase phase);
extern virtual task run_phase(uvm_phase phase);
extern virtual task reset_all();
extern virtual task drive();
extern virtual task master_task(inout REQ packet);
extern virtual task slave_task(REQ packet);
extern virtual function void mem_init();
extern virtual task mem_access(bit wr_en,
 logic [3:0] be, logic [11:0] addr, logic [31:0] data_in, output logic [31:0] data_o);
//
endclass
//=====================================================================
//---------------IMPLEMENTATION of all METHODs
//=====================================================================
function apb_driver::new(string name ="APB Driver", uvm_component parent);
    super.new(name, parent);
endfunction 
//
function void apb_driver:: build_phase(uvm_phase phase);
    super.build_phase(phase);
    //
    if(drv_cfg == null) begin
      `uvm_fatal (get_type_name (), "APB_AGENT_CONFIG OBJECT is NULL!!!")
    end
    else begin
     
    end
//
endfunction:build_phase
//
task apb_driver::run_phase(uvm_phase phase);
    //super.run_phase(phase);
  fork
     reset_all();
     drive(); 
  join_none
endtask
//**************************************************************************************
//***********************************MAIN TASKS*****************************************
//**************************************************************************************
//Initiate all control signals when the reset is active
//Run time: run until the end of the simulation
task apb_driver::reset_all();
  wait (~drv_cfg.vif.presetn) begin
      if(drv_cfg.active == UVM_PASSIVE) begin
        drv_cfg.vif.s_drv_cb.pready <= 1'b0;
        drv_cfg.vif.s_drv_cb.pslverr <= 1'b0;
      end
      else begin
        drv_cfg.vif.m_drv_cb.psel <= 1'b0;
        drv_cfg.vif.m_drv_cb.penable <= 1'b0;
        drv_cfg.vif.m_drv_cb.pwrite <= 1'b0;
        drv_cfg.vif.m_drv_cb.paddr  <= {`APB_DW{1'b0}};
        drv_cfg.vif.m_drv_cb.pwdata <= {`APB_AW{1'b0}};
        drv_cfg.vif.m_drv_cb.pstrb <= {(`APB_AW/8){1'b0}};
      end
    mem_init();
  end

  while (1) begin
    @(negedge drv_cfg.vif.presetn);
	@(drv_cfg.vif.s_drv_cb iff ~drv_cfg.vif.presetn); //Reset of DUT is synchronize reset
    if(drv_cfg.active == UVM_PASSIVE) begin
		drv_cfg.vif.s_drv_cb.pready <= 1'b0;
		drv_cfg.vif.s_drv_cb.pslverr <= 1'b0;
   end
   else begin
        drv_cfg.vif.m_drv_cb.psel <= 1'b0;
        drv_cfg.vif.m_drv_cb.penable <= 1'b0;
        drv_cfg.vif.m_drv_cb.pwrite <= 1'b0;
        drv_cfg.vif.m_drv_cb.paddr  <= {`APB_DW{1'b0}};
        drv_cfg.vif.m_drv_cb.pwdata <= {`APB_AW{1'b0}};
        drv_cfg.vif.m_drv_cb.pstrb <= {(`APB_AW/8){1'b0}};
   end
	    mem_init();
  end
endtask: reset_all
//
//definition of drive task
//
task apb_driver::drive();
    forever begin
        //@(posedge drv_cfg.vif.presetn);
        //#(`CLK_CYCLE);
        //while(drv_cfg.vif.presetn) begin
            seq_item_port.get_next_item(item);
            //
            if(drv_cfg.active == UVM_ACTIVE) begin
                master_task(item);
            end
            else begin
                slave_task(item);
            end
            //
            seq_item_port.item_done(item);
        //end
    end//end of forever
endtask
//
//definition of master task
//
task apb_driver::master_task(inout REQ packet);
    if(packet.resetn_req == 1'b1) begin
		`uvm_info(get_type_name(), "drive reset", UVM_MEDIUM)
		active_low_rst = 1'b0;
	end
	else begin
		active_low_rst = 1'b1;
	end
	//
	@(drv_cfg.vif.m_drv_cb);
	drv_cfg.vif.presetn <= active_low_rst;
    //
    if(active_low_rst == 1'b1) begin: RESET_HIGH
    `uvm_info(get_type_name(), "Drive Data", UVM_HIGH)
	//
    @(drv_cfg.vif.m_drv_cb);
    drv_cfg.vif.m_drv_cb.psel <= 1'b1;
    drv_cfg.vif.m_drv_cb.penable <= 1'b0;
    drv_cfg.vif.m_drv_cb.pwrite <= packet.wr_en;
    drv_cfg.vif.m_drv_cb.paddr  <= packet.addr;
    drv_cfg.vif.m_drv_cb.pwdata <= packet.data;
    drv_cfg.vif.m_drv_cb.pstrb <= packet.be;
    @(drv_cfg.vif.m_drv_cb);
    drv_cfg.vif.m_drv_cb.penable <= 1'b1;
    //wait PREADY
    //while(1) begin
		//`uvm_info(get_type_name(), "WAIT_PREADY", UVM_HIGH)
         //if(drv_cfg.vif.m_drv_cb.pready) begin
            //if(!packet.wr_en) begin
            //packet.data = drv_cfg.vif.m_drv_cb.prdata;
            //end 
            //break; 
         //end
        //@(drv_cfg.vif.m_drv_cb);
    //end
    @(drv_cfg.vif.m_drv_cb iff drv_cfg.vif.m_drv_cb.pready);
    if(!packet.wr_en) begin
        packet.data = drv_cfg.vif.m_drv_cb.prdata;
    end 
    //
    drv_cfg.vif.m_drv_cb.psel <= 1'b0;
    drv_cfg.vif.m_drv_cb.penable <= 1'b0;
    drv_cfg.vif.m_drv_cb.pwrite <= 1'b0;
    drv_cfg.vif.m_drv_cb.paddr  <= {`APB_AW{1'b0}};
    drv_cfg.vif.m_drv_cb.pwdata <= {`APB_DW{1'b0}};
    drv_cfg.vif.m_drv_cb.pstrb <= {(`APB_DW/8){1'b0}};
    end: RESET_HIGH
    `uvm_info(get_type_name(), "[DONE]send transaction!!!", UVM_HIGH)
endtask
//
//definition of slave task
//
task apb_driver::slave_task(REQ packet);
    counter = 0;
    fork
        begin //THREAD_1
        @(negedge drv_cfg.vif.presetn);
        `uvm_info(get_type_name(), $sformatf("PRESET_N EDGE-SENSITIVE!!!"), UVM_HIGH);
        end
        //
        begin//THREAD_2
        fork
        //
        forever begin //SUB_THREAD_2_1
             `uvm_info(get_type_name(), $sformatf("time_1: %0t ns", $time), UVM_HIGH)
            //iterates psel in turn to determine selected slave
            @(drv_cfg.vif.s_drv_cb iff drv_cfg.vif.s_drv_cb.psel);
            if(drv_cfg.vif.s_drv_cb.psel) begin//PSEL_IF
                if(drv_cfg.vif.s_drv_cb.pwrite && drv_cfg.vif.s_drv_cb.penable) begin
                mem_access(1'b1, drv_cfg.vif.s_drv_cb.pstrb, drv_cfg.vif.s_drv_cb.paddr[11:0], drv_cfg.vif.s_drv_cb.pwdata, rdata);
                done2 = 1'b1;
                `uvm_info(get_type_name(),
                $sformatf("[APB WRITE_TRANSFER]: paddr=0x%0h WriteData=0x%08h Pstrb=0x%0h\n cur_mem = 0x%08h new_mem = 0x%08h",
                drv_cfg.vif.s_drv_cb.paddr, drv_cfg.vif.s_drv_cb.pwdata, drv_cfg.vif.s_drv_cb.pstrb, current_value, new_value), UVM_HIGH);
                //
                end
            else if(~drv_cfg.vif.s_drv_cb.pwrite && ~drv_cfg.vif.s_drv_cb.penable) begin
                mem_access(1'b0, drv_cfg.vif.s_drv_cb.pstrb, drv_cfg.vif.s_drv_cb.paddr[11:0], drv_cfg.vif.s_drv_cb.pwdata, rdata);
                drv_cfg.vif.s_drv_cb.prdata <= rdata;
                done2 = 1'b1;
                `uvm_info(get_type_name(), $sformatf("[APB READ_TRANSFER]: paddr=0x%0h ReadData=0x%08h",
                drv_cfg.vif.s_drv_cb.paddr, rdata), UVM_HIGH);
            end
            else begin
                done2 = 1'b0;
            end
            //
            end//end of PSEL_IF
        if(done2) break;
        end//end of SUB_THREAD_2_1
        //
        forever begin //SUB_THREAD_2_2
            @(drv_cfg.vif.s_drv_cb iff drv_cfg.vif.s_drv_cb.psel);
            //packet.print();
            `uvm_info(get_type_name(), $sformatf("counter = %0d", counter), UVM_HIGH);
            `uvm_info(get_type_name(), $sformatf("preadyDelay = %0d", packet.preadyDelay), UVM_HIGH);
            if(drv_cfg.vif.s_drv_cb.psel) begin //PSEL_IF
                if(packet.pready) begin
                actual_pready = packet.pready;
                done = 1'b1;
                end
                else if(counter == packet.preadyDelay)begin
                actual_pready = 1'b1;
                done = 1'b1;
                end
                else begin
                actual_pready = packet.pready;
                done = 1'b0;
                end
                //
                drv_cfg.vif.s_drv_cb.pready <= actual_pready;
                // usually 1 (ready)
                drv_cfg.vif.s_drv_cb.pslverr <= packet.err; // usually 0 (no error)
                //
                if(~packet.pready && drv_cfg.vif.s_drv_cb.penable) counter++;
            end//end of PSEL_IF
            if(done) begin
            break;
            end

        end //end of SUB_THREAD_2_2
    join
    end//end of THREAD_2 
    join_any
    disable fork;
endtask
//
function void apb_driver::mem_init();
    for(int j=0; j < DEPTH; j++) begin
        mem[j] = 0;
    end
endfunction	
//
//definition of mem_access function
//
task apb_driver::mem_access(
	input bit wr_en,
	input logic [3:0] be,
	input logic [11:0] addr,
	input logic [31:0] data_in,
	output logic [31:0] data_o
);	
	//big-endian
	begin
		if(wr_en) begin
			mem[addr+0] = (be[3]) ? data_in[31:24] : mem[addr+0];
			mem[addr+1] = (be[2]) ? data_in[23:16] : mem[addr+1];
			mem[addr+2] = (be[1]) ? data_in[15:08] : mem[addr+2];
			mem[addr+3] = (be[0]) ? data_in[07:00] : mem[addr+3];
			//data_o = 32'd0;
		end
		else begin
			data_o = {mem[addr+0], mem[addr+1], mem[addr+2], mem[addr+3]};
		end
	end
endtask

