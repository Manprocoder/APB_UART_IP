//==================================================================================
//Project: Design UART IP
//File name: my_env.sv
//Description:
//--TB  
//--my_enviroment
//==================================================================================
package env_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import apb_vip_pkg::*;
import uart_vip_pkg::*;
import uart_ral_pkg::*;
import parameter_pkg::*;
import scoreboard_pkg::*;
import env_cfg_pkg::*;
//
class my_env extends uvm_env;
	`uvm_component_utils(my_env)
	//
	scoreboard scb;
	apb_agent apb_agt_h[];
	uart_agent uart_agt_h[];
	env_config env_cfg_h;
	virtual_sequencer vsqr_h;
	//reg model
	uvm_reg_predictor #(apb_seq_item#(DW, APB_AW)) predictor_h[];//, predictor_h1;
	uart_reg_model reg_model_h[];//, reg_model_h1;
	reg_apb_adapter adapter_h[];//, adapter_h1;		
	uvm_reg_backdoor reg_bd_h[];
	//interface
	//virtual interface apb_if#(DW, APB_AW) apb0_vif, apb1_vif;
	//apb config
	apb_agent_config apb_cfg_h[];//apb_cfg_h0, apb_cfg_h1;
	bit set_up_done;
	bit vseqr_existing;
	bit back_door_en;
	//
	//
	function new(string name = "my_env", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	//
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		//
		if(!uvm_config_db#(env_config)::get(this, "", "env_cfg", env_cfg_h)) begin
			`uvm_fatal(get_type_name(), "env_cfg is not FOUND!!!")
		end
		else begin
			set_up_done = 0;
			apb_agt_h = new[env_cfg_h.no_of_agent];
			uart_agt_h = new[env_cfg_h.no_of_agent];
			apb_cfg_h = new[env_cfg_h.no_of_agent];
			//
			foreach(apb_agt_h[i]) begin
				apb_agt_h[i] = apb_agent::type_id::create($sformatf("apb_agt_h%0d", i), this);	
				uart_agt_h[i] = uart_agent::type_id::create($sformatf("uart_agt_h%0d", i), this);	
				apb_cfg_h[i] = apb_agent_config::type_id::create($sformatf("apb_cfg_h%0d", i));
			end
			//
			set_up_done = 1;
		end
		//
	if(set_up_done) begin
		//if(env_cfg_h.scoreboard == 1) begin
			scb = scoreboard::type_id::create("scb", this);	
		//end	
		if(env_cfg_h.has_virtual_sequencer) begin
			vsqr_h = virtual_sequencer::type_id::create("vsqr_h", this);
			vseqr_existing = 1;
		end
			adapter_h = new[env_cfg_h.no_of_agent];
			predictor_h = new[env_cfg_h.no_of_agent];
			reg_model_h = new[env_cfg_h.no_of_agent];
			reg_bd_h = new[env_cfg_h.no_of_agent];
			`uvm_info(get_type_name(), "[ENV]FINISH INSTATIATING AGENT AND SCB!!!", UVM_HIGH)
		foreach(apb_agt_h[i]) begin
			if(!uvm_config_db#(virtual interface apb_if#(DW, APB_AW))
				::get(null, "*", $sformatf("apb_if_%0d", i), apb_cfg_h[i].apb_vif)) begin
				`uvm_fatal(get_type_name(), $sformatf("APB[%0d] VIF not FOUND!!!", i))
			end
			//
			apb_cfg_h[i].active = UVM_ACTIVE;
			//store config
			uvm_config_db#(apb_agent_config)::set(null,
			       	$sformatf("uvm_test_top.env_h.apb_agt_h%0d*", i), "apb_cfg", apb_cfg_h[i]);
			//
		    adapter_h[i] = reg_apb_adapter::type_id::create($sformatf("adapter_h%0d", i));
		    predictor_h[i] = uvm_reg_predictor#(apb_seq_item#(DW, APB_AW))::type_id::create(
			    $sformatf("predictor_h%0d", i), this);
		    reg_model_h[i] = uart_reg_model::type_id::create($sformatf("reg_model_h%0d", i));
		    reg_model_h[i].build($sformatf("uart%0d_wrap.uart_top.uart_reg_bank_inst", i));
		    `ifdef BACK_DOOR
		    reg_bd_h[i] = new();
		    reg_model_h[i].set_backdoor(reg_bd_h[i]);
		    reg_model_h[i].map.set_auto_predict(1);
		    `endif
		    reg_model_h[i].reset();
		    reg_model_h[i].lock_model();
		    reg_model_h[i].print();
		    uvm_config_db#(uart_reg_model)::set(uvm_root::get(), "*", $sformatf("reg_model_h%0d", i), reg_model_h[i]);
	    end//end of foreach
end//end of set_up_done
endfunction
	//
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		`uvm_info(get_type_name(), "[APB]START TO CONNECT MON_SCB ports!!!", UVM_HIGH)
		//connect ports
		//main interface
		`uvm_info(get_type_name(), $sformatf("set_up_done = %0b", set_up_done), UVM_HIGH)
	if(set_up_done) begin
		if(vseqr_existing) begin
			vsqr_h.apb_sqr_h = new[env_cfg_h.no_of_agent];
			vsqr_h.apb_agt_h = new[env_cfg_h.no_of_agent];
		end
		//
		for(int i =0; i < env_cfg_h.no_of_agent; i++) begin //FOR_LOOP
		//assign actual sequencer handles to virtual sequencer
		if(vseqr_existing) begin
			vsqr_h.apb_sqr_h[i] = apb_agt_h[i].apb_sqr_h;
			vsqr_h.apb_agt_h[i] = apb_agt_h[i];
		end
		//
		apb_agt_h[i].apb_mon_h.presetn_ap.connect(scb.presetn_fifo[i].analysis_export);
		apb_agt_h[i].apb_mon_h.apb_item_ap.connect(scb.apb_txn_fifo[i].analysis_export);
		apb_agt_h[i].apb_mon_h.apb_to_uart_item_ap.connect(scb.apb_to_uart_txn_fifo[i].analysis_export);
		`uvm_info(get_type_name(), $sformatf("[APB%0d]SUCCEED TO CONNECT MON_SCB ports!!!",i), UVM_MEDIUM)
		//
		//uart_agt_h[i].uart_mon_h.tx_to_scb_ap.connect($sformatf("scb.uart%0d_tx_aimp", i)); //not allowed
		//port in string format is NOT ALLOWED
		uart_agt_h[i].uart_mon_h.tx_to_scb_ap.connect(scb.uart_tx_fifo[i].analysis_export);
		uart_agt_h[i].uart_mon_h.rx_to_scb_ap.connect(scb.uart_rx_fifo[i].analysis_export);
		`uvm_info(get_type_name(), $sformatf("[UART%0d]SUCCEED TO CONNECT MON_SCB ports!!!",i), UVM_MEDIUM)
		//
		if(vseqr_existing) begin
			reg_model_h[i].map.set_sequencer(.sequencer(vsqr_h.apb_sqr_h[i]), .adapter(adapter_h[i]));
		end
		else begin
			reg_model_h[i].map.set_sequencer(.sequencer(apb_agt_h[i].apb_sqr_h), .adapter(adapter_h[i]));
		end
		//
	        reg_model_h[i].map.set_base_addr('h0);    
		`uvm_info(get_type_name(), $sformatf("[REG_MODEL%0d]SUCCEED TO SET SEQUENCER!!!",i), UVM_MEDIUM)
		predictor_h[i].map = reg_model_h[i].map; //Assigning map handle
	    	predictor_h[i].adapter = adapter_h[i]; //Assigning adapter handle
	    	apb_agt_h[i].apb_mon_h.apb_item_ap.connect(predictor_h[i].bus_in); 
		//
	    end //end of FOR_LOOP
		//
		set_up_done = 0;
	end//end of set_up_done
    endfunction
endclass
endpackage
