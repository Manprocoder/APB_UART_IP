//------------------------------------------------------
//--Project: Design and Verify APB UART IP
//--File: apb_seq.sv
//--Author: Nguyen Ngoc Man
//--Description
//------------------------------------------------------
class apb_seq extends uvm_sequence;
typedef apb_seq_item apb_item;
`uvm_object_utils(apb_seq)

// Constructor
function new(string name = "apb_seq");
    super.new(name);
endfunction

// Main task body
virtual task body();
endtask:body	
  
endclass
  
