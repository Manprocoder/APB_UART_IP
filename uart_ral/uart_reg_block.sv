//==================================================================================
//--Project: Design and Verify APB_UART IP
//--File name: uart_reg_model.sv
//--Author: Nguyen Ngoc Man
//--Description:
//==================================================================================
class uart_reg_model extends uvm_reg_block;
  //register UVM factory
  `uvm_object_utils(uart_reg_model)
  //all regs
  rand txd_reg TX_DATA;
  rxd_reg RX_DATA;
  rand uart_ctrl_reg CTRL;
  uart_status_reg STATUS;
  rand uart_divisor_reg DIV;
  //
  uvm_reg_map map;

  function new(string name = "uart_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build(input string dut_name);
    //set up hdl
    CTRL = uart_ctrl_reg::type_id::create("CTRL");
    CTRL.build();
    CTRL.configure(this);
    //set up hdl
	CTRL.add_hdl_path_slice("control", 0, 32); 
    STATUS = uart_status_reg::type_id::create("STATUS");
    STATUS.build();
    STATUS.configure(this);
    //set up hdl
	STATUS.add_hdl_path_slice("status", 0, 32); 
    DIV = uart_divisor_reg::type_id::create("DIV");
    DIV.build();
    DIV.configure(this);
    //set up hdl
	DIV.add_hdl_path_slice("divisor", 0, 16); 
    //
    TX_DATA = txd_reg::type_id::create("TX_DATA");
    TX_DATA.build();
    TX_DATA.configure(this);
    //
    RX_DATA = rxd_reg::type_id::create("RX_DATA");
    RX_DATA.build();
    RX_DATA.configure(this);
    //
    map = create_map("map", 'h0, 4, UVM_LITTLE_ENDIAN);

    map.add_reg(CTRL, 32'h0, "RW");
    map.add_reg(STATUS, 32'h4, "RW");
    map.add_reg(DIV, 32'h8, "RW");
    map.add_reg(TX_DATA, 32'hc, "RW");
    map.add_reg(RX_DATA, 32'h10, "RW");
    //
	add_hdl_path(dut_name, "RTL");
//for back door access
    lock_model();
  endfunction

endclass: uart_reg_model
