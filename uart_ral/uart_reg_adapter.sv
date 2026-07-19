//==================================================================================
//--Project: Design and Verify APB_UART IP
//--File name: uart_reg_adapter.sv
//--Author: Nguyen Ngoc Man
//--Description:
//==================================================================================
import apb_pkg::*;
//
class reg_apb_adapter extends uvm_reg_adapter;
  `uvm_object_utils(reg_apb_adapter)
  
  function new(string name = "reg_apb_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses = 1;
  endfunction
  
  virtual function uvm_sequence_item reg2bus (const ref uvm_reg_bus_op rw);
    apb_seq_item bus_item = apb_seq_item::type_id::create("bus_item");
    bus_item.addr = rw.addr;
    bus_item.data = rw.data;
    bus_item.wr_en = (rw.kind == UVM_READ) ? 0 : 1;
    
    `uvm_info(get_name(), $sformatf("reg2bus: addr = %0h, data = %0h, wr_en = %0h",
	    bus_item.addr, bus_item.data, bus_item.wr_en), UVM_LOW);
    return bus_item;
  endfunction
  
  virtual function void bus2reg (uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_seq_item bus_pkt;
    if(!$cast(bus_pkt, bus_item)) begin
      `uvm_fatal(get_name(), "Failed to cast bus_item transaction")
     end

    rw.addr = bus_pkt.addr;
    rw.data = bus_pkt.data;
    rw.kind = (bus_pkt.wr_en) ? UVM_WRITE: UVM_READ;
    //
    `uvm_info(get_name(), $sformatf("bus2reg: addr = %08h, data = %08h, wr_en = %s",
	    rw.addr, rw.data, rw.kind), UVM_LOW);
  endfunction
endclass
