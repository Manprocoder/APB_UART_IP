//==================================================================================
//--Project: Design and Verify APB_UART IP
//--File name: ctrl_reg_cbs.sv
//--Author: Nguyen Ngoc Man
//--Description:
//==================================================================================
class ctrl_reg_cbs extends uvm_reg_cbs;
     `uvm_object_utils(ctrl_reg_cbs)
     int no_pass;
     int no_fail;
     //=================================================================
     //----------------METHODs
     //=================================================================
     extern function new(string name = "ctrl_reg_cbs");
     extern virtual task post_read(uvm_reg_item rw);
endclass: ctrl_reg_cbs
     //=================================================================
     //----------------IMPLEMENTATION of all METHODs
     //=================================================================
 function ctrl_reg_cbs::new(string name = "ctrl_reg_cbs");
   super.new(name);
   no_fail = 0;
   no_pass = 0;
 endfunction
     //
task ctrl_reg_cbs::post_read(uvm_reg_item rw);

  uvm_reg rg;
  uvm_reg_data_t mirror;
  uvm_reg_data_t actual;
  //
  if(!$cast(rg, rw.element)) begin
      `uvm_error(get_name(), "rw.element is not a uvm_reg!!!");
  end

  actual = rw.value[0];
  mirror = rg.get_mirrored_value();

    if(actual != mirror) begin
        `uvm_error(get_name(), $sformatf("[FAIL]%s Mirror=0x%0h Actual=0x%0h", rg.get_name(), mirror, actual));
        no_fail++;
    end
    else begin
        `uvm_info(get_name(), $sformatf("[PASS]%s Mirror=0x%0h Actual=0x%0h", rg.get_name(), mirror, actual), UVM_MEDIUM);
        no_pass++;
    end
endtask
