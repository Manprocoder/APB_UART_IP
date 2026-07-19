//==================================================================
//--Project: Design and verify  APB-UART IP 
//--File name: uart_base_seq.sv
//--Author: Nguyen Ngoc Man
//--Description
//==================================================================
import apb_pkg::*;
import uart_ral_pkg::*;
import env_pkg::*;
//
virtual class uart_base_seq extends uvm_sequence#(apb_seq_item);
	`uvm_object_param_utils(uart_base_seq)
    //==================================================
    //---------------DATA members
    //==================================================
	apb_seq_item rst_item; //used in uart_rst_sequence
	uart_reg_model rm_h; 
	env_config env_cfg_h;
	tx_generator tx_gen_h;
	bit tx_enable; //tx_enable TX_DATA write process
	bit rx_enable;
    //
    int no_rx_data;
		//
	function new(string name = "uart_base_seq");
		super.new(name);
	endfunction
	//
	virtual function void assign_rm_handle(uart_reg_model rm_ref);
		this.rm_h = rm_ref;
	endfunction
	//
	virtual function void en_tx_rx(bit [1:0] en, int no_rx_data);
		this.tx_enable = en[1];
		this.rx_enable = en[0];
        //
        this.no_rx_data = no_rx_data;
	endfunction
	//
	virtual function void gen_tx_data(int no_of_member, int uart_0_or_1);
		tx_gen_h = tx_generator::type_id::create($sformatf("tx_gen_h[%0d]", uart_0_or_1));
		assert(tx_gen_h.randomize() with {tx_gen_h.no_dat == no_of_member;});
	endfunction
	//
	pure virtual task body();
endclass
