//==================================================================================
//Project: Design and verify APB_UART IP
//File name: uart_monitor.sv
//Author: Nguyen Ngoc Man
//Description:
//==================================================================================
class uart_monitor extends uvm_monitor;
	`uvm_component_utils(uart_monitor)
    //=======================================================================
    //-----------------------------DATA members
    //=======================================================================
	//parameters
	parameter OVERSAMPLE = 16;
	parameter UART_DW = 16;
	//
	//virtual interface
	//
	virtual interface uart_if uart_vif;	
    //
    `ifdef INTERRUPT
	virtual interface interrupt_if int_vif;	
    `endif
	//ports
	uvm_analysis_port#(uart_seq_item) tx_to_scb_ap;
	uvm_analysis_port#(uart_seq_item) rx_to_scb_ap;
	uvm_analysis_port#(logic) int_ap;
	//
	uart_seq_item tx_item, rx_item;
	//--handle configuration
	typedef struct{
		bit [UART_DW-1:0] brr_value;
		bit have_parity;
	} ctrl_info;
	//others
	bit parity_exist;
	bit [UART_DW-1:0] mon_brr_val;
	logic config_avail_flag;
	int i;
    int tx_idx; //used in capture tx interface 
    //--active when new config exists
    bit new_cfg_exists;
    //
    int no_tx_data;
    //=======================================================================
    //-----------------------------METHODs
    //=======================================================================
	extern function new (string name = "uart_monitor", uvm_component parent = null);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task run_phase(uvm_phase phase);
	extern virtual task monitor(input bit [UART_DW-1:0] brr_value, input bit parity_exist, output bit config_avail_flag);
    `ifdef INTERRUPT
	extern virtual task monitor_int();
    `endif
    extern virtual task capture_parity(output bit parity_enable);
	extern virtual task collect_tx(input bit [UART_DW-1:0] brr_value, input bit parity_exist);
	extern virtual function void display(input ctrl_info ctrl_info_ref);
	extern virtual task wait_clk_per_bit(input bit [UART_DW-1:0] brr_value);
    //
    //----automatic MUST NOT be placed outside class scope (not use extern keyword)
    //
   	virtual task automatic capture_brr(ref bit [UART_DW-1:0] brr_value);
        begin
            @(uart_vif.uart_mon_cb iff uart_vif.uart_mon_cb.brr_valid);
            brr_value = uart_vif.uart_mon_cb.brr_value - 1'b1;
            new_cfg_exists = 1'b1;
            //
            `uvm_info(get_type_name(), 
            $sformatf("[CAPTURE_CTRL] brr_value = %08h!!!", brr_value), UVM_LOW)
        end
	endtask
endclass:uart_monitor
    //=======================================================================
    //-----------------------IMPLEMENTATION of all METHODs
    //=======================================================================
	function uart_monitor::new (string name = "uart_monitor", uvm_component parent = null);
		super.new(name, parent);
		i = 0;
        tx_idx = 0;
	endfunction	
	//
	function void uart_monitor::build_phase(uvm_phase phase);
		//super.build_phase(phase);
		//get vif
		if(!uvm_config_db#(virtual interface uart_if)::get(this, "", "uart_if", uart_vif)) begin
			`uvm_fatal(get_name(), "UART_VIF not FOUND!!!")
		end
        //
        `ifdef INTERRUPT
		if(!uvm_config_db#(virtual interface interrupt_if)::get(this, "", "int_if", int_vif)) begin
			`uvm_fatal(get_name(), "INT_VIF not FOUND!!!")
		end
        //
        int_ap = new("int_ap", this);
        //
        `endif
        //
		if(!uvm_config_db#(int)::get(this, "", "no_tx_data", no_tx_data)) begin
			`uvm_fatal(get_name(), "no_tx_data not FOUND!!!")
		end
		//
		tx_to_scb_ap = new("tx_to_scb_ap", this);
		rx_to_scb_ap = new("rx_to_scb_ap", this);
	endfunction
	//
	//
	task uart_monitor::run_phase(uvm_phase phase);
		fork
		forever begin: DETECT_RST
			@(negedge uart_vif.rst_n);
			disable fork;
			`uvm_info(get_type_name(), "[UART_MONITOR]: Reset_n is active!!!", UVM_LOW)
		end
		//
		forever begin: CAPTURE_UART_CONTROL
			//
			wait(uart_vif.rst_n == 1'b1);	
			`uvm_info(get_type_name(), $sformatf("[UART_CTRL_INFO]PREPARED TO CAPTURE[%0d]!!!", ++i), UVM_LOW)
			fork
			capture_parity(parity_exist);
			capture_brr(mon_brr_val);
			join
		end
		//	begin
		forever begin: CAPTURE_RX
				if((config_avail_flag === 1'bx) || config_avail_flag === 1'b1) begin
                    `uvm_info(get_type_name(), "[UART_CTRL_INFO] WAIT CLK_USED_PER_BIT CHANGED!!!", UVM_LOW)
                    @(new_cfg_exists == 1'b1);//wait until change of mon_brr_val
                    //--MUST NOTICE
                    //---if 2 write access with same value--> it does not trigger
                    `uvm_info(get_type_name(), "[UART_CTRL_INFO]CLK_USED_PER_BIT CHANGED!!!", UVM_LOW)
                    new_cfg_exists = 0;
				end
				monitor(mon_brr_val, parity_exist, config_avail_flag);
		end
        //
        `ifdef INTERRUPT
        begin: MONITOR_INTERRUPT
            monitor_int();
        end
        `endif
		join_none
	endtask
    //
    //
    //
    `ifdef INTERRUPT
    task uart_monitor::monitor_int();
        forever begin
            @(posedge int_vif.int_req);
            int_ap.write(1'b1);
        end
    endtask
    `endif
	//
	//collect rx
	//
	task uart_monitor::monitor(input bit [UART_DW-1:0] brr_value, input bit parity_exist, output bit config_avail_flag);
			config_avail_flag = 0;
		fork
			begin
                @(uart_vif.uart_mon_cb iff (uart_vif.uart_mon_cb.ctrl_valid || uart_vif.uart_mon_cb.brr_valid));
                `uvm_info(get_type_name(), "NEW CONFIG exists!!!", UVM_LOW)
                config_avail_flag = 1;
			end
			//
			forever begin
                collect_tx(brr_value, parity_exist);
			end
		join_any
		disable fork; //as new configuration appears, process exits right away
	endtask
	//
	//capture control
	//
	task uart_monitor::capture_parity(output bit parity_enable);
		@(uart_vif.uart_mon_cb iff uart_vif.uart_mon_cb.ctrl_valid);
		parity_enable = uart_vif.uart_mon_cb.parity_en;
		//
		`uvm_info(get_type_name(), 
		$sformatf("[CAPTURE_PARITY]parity_enable = %0b", parity_enable), UVM_LOW)
	endtask
	//====================================================================================
	//--------------------collect data 
	//====================================================================================
	task uart_monitor::collect_tx(input bit [UART_DW-1:0] brr_value, input bit parity_exist);
		@(uart_vif.uart_mon_cb iff ~uart_vif.uart_mon_cb.tx);
		`uvm_info(get_name(), $sformatf("SAMPLING TX_Item[%0d] START!!!", tx_idx), UVM_LOW)
		//sample tx_data
		tx_item = uart_seq_item::type_id::create("tx_item");
		//
		for(int i = 0; i < 8; i++) begin
            wait_clk_per_bit(brr_value);
            `uvm_info(get_name(), $sformatf("TX_[%0d] = %0b", i, uart_vif.uart_mon_cb.tx), UVM_MEDIUM)
			tx_item.tx_data[i] = uart_vif.uart_mon_cb.tx; 
		end
        //
		`uvm_info(get_name(), $sformatf("SAMPLE TX_DATA[%0d] DONE!!!", tx_idx), UVM_LOW)
		//sample PARITY bit and STOP bit
		wait_clk_per_bit(brr_value);
        //
		if(parity_exist) begin
			`uvm_info(get_name(), $sformatf("SAMPLE PARITY_BIT!!!"), UVM_LOW)
			tx_item.parity_bit = uart_vif.uart_mon_cb.tx; 
            wait_clk_per_bit(brr_value);
            //
			`uvm_info(get_name(), $sformatf("SAMPLE STOP BIT!!!"), UVM_LOW)
			tx_item.stop_bit = uart_vif.uart_mon_cb.tx; 
		end
		else begin
			tx_item.stop_bit = uart_vif.uart_mon_cb.tx; 
		end
		`uvm_info(get_name(), $sformatf("SAMPLING TX_Item[%0d] DONE", tx_idx), UVM_LOW)
		tx_item.print();
		tx_to_scb_ap.write(tx_item);
		`uvm_info(get_name(), $sformatf("WRITE TX_Item[%0d] to scb", tx_idx), UVM_LOW)
        //
        if(tx_idx == no_tx_data) begin
            tx_idx = 0;
        end
        else begin
            tx_idx++;
        end
		//
	endtask
	//====================================================================================
	//--------------------------------end of collecting data 
	//====================================================================================
	//
	function void uart_monitor::display(input ctrl_info ctrl_info_ref);
		`uvm_info(get_type_name(), $sformatf("BRR = %04h", ctrl_info_ref.brr_value), UVM_LOW);
		`uvm_info(get_type_name(), $sformatf("HAVE_PARITY = %0b", ctrl_info_ref.have_parity), UVM_LOW);
	endfunction
	//
	//
	task uart_monitor::wait_clk_per_bit(input bit [UART_DW-1:0] brr_value);
		for(int i = 0;i <= OVERSAMPLE; i++) begin
			repeat(brr_value) @(uart_vif.uart_mon_cb);
		end
	endtask
