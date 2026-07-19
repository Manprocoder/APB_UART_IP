//==================================================================
//--Project: Design and verify APB-UART IP 
//--File name: tx_generator.sv
//--Author: Nguyen Ngoc Man
//--Description
//==================================================================
class tx_generator extends uvm_sequence_item;
	`uvm_object_utils(tx_generator)
	typedef enum logic [1:0] {FULL_ZERO, FULL_ONE, EVEN_ONE, ODD_ONE} data_case; 
	//all fields
	rand uvm_reg_data_t tx_dat_fifo[$];
	//
	//
	rand data_case tx_data_case [];
	rand bit [7:0] dat_q [$];
	rand int no_dat;
	//
	constraint no_dat_c{
		no_dat inside {[1:8]}; 
	}
	//
	constraint dat_q_size_c{
		dat_q.size() == no_dat;
	}
	//
	constraint case_c{
		tx_data_case.size() == no_dat;
		foreach(tx_data_case[i]) {
			tx_data_case[i] dist {FULL_ZERO:=1, FULL_ONE:=1, EVEN_ONE:=2, ODD_ONE:=2};
		}
	}
	//
	constraint dat_q_value_c{
		foreach(dat_q[i]) { 
			if(tx_data_case[i] == FULL_ZERO) {
				dat_q[i] == 8'h00;
			}
			else if(tx_data_case[i] == FULL_ONE) {
				dat_q[i] == 8'hff;
			}
			else if(tx_data_case[i] == EVEN_ONE) {	
				($countones(dat_q[i]) % 2) == 0;
			}
			else if(tx_data_case[i] == ODD_ONE) {
				($countones(dat_q[i]) % 2) == 1;
			}
		}
	};

	function new(string name = "tx_generator");
		super.new(name);
	endfunction
	//
	//
	function void post_randomize();
		tx_dat_fifo.delete();
		foreach(dat_q[i]) begin
			tx_dat_fifo.push_back(dat_q[i]);
			`uvm_info(get_full_name(), $sformatf("dat_q[%0d] = %02h", i, dat_q[i]), UVM_MEDIUM)
		end
		dat_q.delete();
	endfunction
	//
endclass
