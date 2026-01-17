//==================================================================================
//Project: Design UART IP
//File name: uart_reg_pkg.sv
//Description:
//--TB  
//--UART regs
//==================================================================================
//***CRITICAL NOTE***: volatile ? UVM_NO_CHECK : UVM_CHECK 
//==================================================================================
//
//extern function bit predict (uvm_reg_data_t    value,
                                //uvm_reg_byte_en_t be = -1,
                                //uvm_predict_e     kind = UVM_PREDICT_DIRECT,
                                //uvm_path_e        path = UVM_FRONTDOOR,
                                //uvm_reg_map       map = null,
                                //string            fname = "",
                                //int               lineno = 0);
//
//
package uart_ral_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
	//control register
class uart_ctrl_reg extends uvm_reg;
	//register factory
	`uvm_object_utils(uart_ctrl_reg)
	//all field of register
	//rand bit rand_p_en;
	//rand bit rand_p_type;
	//rand bit rand_pe_int;
	//rand bit rand_fe_int;
	//rand bit rand_tx_ov_int;
	//rand bit rand_rx_ov_int;
	//rand bit rand_brk_int;
	//rand bit rand_rx_int;
	//rand int rand_reserved;
	typedef enum logic [1:0] {NO_PARITY, EVEN_PARITY, ODD_PARITY} parity_ctrl;
	rand parity_ctrl parity_case;
	rand logic interrupt_en;
	//configure uart operation
	rand uvm_reg_field P_EN; //bit 1
	rand uvm_reg_field P_TYPE; //bit 2
	//enable interrupt
	rand uvm_reg_field PE_INT; //bit 8
	rand uvm_reg_field FE_INT; //bit 9
	rand uvm_reg_field TX_OV_INT; //bit 10
	rand uvm_reg_field RX_OV_INT; //bit 11
	rand uvm_reg_field BRK_INT; //bit 12
	rand uvm_reg_field RX_INT; //bit 13
	rand uvm_reg_field RESERVED;

	//
	function new (string name = "uart_ctrl_reg");
		super.new (name, 32, UVM_NO_COVERAGE);
	endfunction
	//for reference
	//extern function void configure(uvm_reg        parent, 		// Parent register handle
                                   //int unsigned   size, 		// Bit-width of the field
                                   //int unsigned   lsb_pos, 		// LSB index of the field in register
                                   //string         access, 		// Read/read-write/etc access policy
                                   //bit            volatile,
                                   //uvm_reg_data_t reset,
                                   //bit            has_reset,
                                   //bit            is_rand,
                                   //bit            individually_accessible);
	virtual function void build ();
		// Create object instance for each field
		this.P_EN  = uvm_reg_field::type_id::create ("P_EN");
		this.P_TYPE     = uvm_reg_field::type_id::create ("P_TYPE");
		this.PE_INT     = uvm_reg_field::type_id::create ("PE_INT"); //parity error interrupt
		this.FE_INT     = uvm_reg_field::type_id::create ("FE_INT"); //frame error interrupt
		this.TX_OV_INT  = uvm_reg_field::type_id::create ("TX_OV_INT"); //tx fifo overflow
		this.RX_OV_INT  = uvm_reg_field::type_id::create ("RX_OV_INT"); //rx fifo overflow
		this.BRK_INT    = uvm_reg_field::type_id::create ("BRK_INT");
		this.RX_INT     = uvm_reg_field::type_id::create ("RX_INT"); //rx data is available in rx fifo 
		this.RESERVED   = uvm_reg_field::type_id::create ("RESERVED"); //rx data is available in rx fifo 
		// Configure each field
		this.P_EN.configure (this, 1, 1, "RW", 0, 1'b0, 1, 1, 1);
		this.P_TYPE.configure (this, 1, 2, "RW", 0, 1'b0, 1, 1, 1);
		this.PE_INT.configure (this, 1, 8, "RW", 0, 1'b0, 1, 1, 1);
		this.FE_INT.configure (this, 1, 9, "RW", 0, 1'b0, 1, 1, 1);
		this.TX_OV_INT.configure (this, 1, 10, "RW", 0, 1'b0, 1, 1, 1);
		this.RX_OV_INT.configure (this, 1, 11, "RW", 0, 1'b0, 1, 1, 1);
		this.BRK_INT.configure (this, 1, 12, "RW", 0, 1'b0, 1, 1, 1);
		this.RX_INT.configure (this, 1, 13, "RW", 0, 1'b0, 1, 1, 1);
		this.RESERVED.configure (this, 18, 14, "RW", 0, 18'h0, 1, 1, 1);
	endfunction
	//
	function void post_randomize();
		case(parity_case)
			NO_PARITY: begin
				P_EN.set(1'b0);
				P_TYPE.set(1'b0);
			end
			EVEN_PARITY: begin
				P_EN.set(1'b1);
				P_TYPE.set(1'b1);
			end	
			ODD_PARITY: begin
				P_EN.set(1'b1);
				P_TYPE.set(1'b0);
			end
		endcase
		//
		if(interrupt_en) begin
			PE_INT.set(1'b1);
			FE_INT.set(1'b1);
			TX_OV_INT.set(1'b1);
			RX_OV_INT.set(1'b1);
			BRK_INT.set(1'b1);
			RX_INT.set(1'b1);
		end
		else begin
			PE_INT.set(1'b0);
			FE_INT.set(1'b0);
			TX_OV_INT.set(1'b0);
			RX_OV_INT.set(1'b0);
			BRK_INT.set(1'b0);
			RX_INT.set(1'b0);
		end
		//
		RESERVED.set(0);
	endfunction
endclass
//status register
class uart_status_reg extends uvm_reg;
	//register factory
	`uvm_object_utils(uart_status_reg)
	//all fields
	uvm_reg_field FE;
	uvm_reg_field PE;
	uvm_reg_field BRK;
	uvm_reg_field TX_OV;
	uvm_reg_field RX_OV;
	uvm_reg_field TX_FULL;
	uvm_reg_field RX_FULL;
	uvm_reg_field RX_NOT_EMPTY;
	uvm_reg_field BUSY;
	//uvm_reg_field TMT;
	uvm_reg_field RX_UD;
	uvm_reg_field RESERVED;
//{22'd0, RX_UD, BUSY_i, RX_NOT_EMPTY_i, RX_FULL_i, TX_FULL_i, RX_OV, TX_OV, bit_break, bit_parity, FE};
	//contructor
	function new (string name = "uart_status_reg");
		super.new (name, 32, UVM_NO_COVERAGE);
	endfunction
	//
	//for reference
	//extern function void configure(uvm_reg        parent, 		// Parent register handle
                                   //int unsigned   size, 		// Bit-width of the field
                                   //int unsigned   lsb_pos, 		// LSB index of the field in register
                                   //string         access, 		// Read/read-write/etc access policy
                                   //bit            volatile,
                                   //uvm_reg_data_t reset,
                                   //bit            has_reset,
                                   //bit            is_rand,
                                   //bit            individually_accessible);
	virtual function void build ();
		// Create object instance for each field
		this.FE     = uvm_reg_field::type_id::create ("FE"); //
		this.PE     = uvm_reg_field::type_id::create ("PE"); //
		this.BRK    = uvm_reg_field::type_id::create ("BRK"); //
		this.TX_OV  = uvm_reg_field::type_id::create ("TX_OV"); //tx fifo overflow
		this.RX_OV  = uvm_reg_field::type_id::create ("RX_OV"); //rx fifo overflow
		this.TX_FULL    = uvm_reg_field::type_id::create ("TX_FULL"); //tx fifo full
		this.RX_FULL    = uvm_reg_field::type_id::create ("RX_FULL"); //rx fifo full
		this.RX_NOT_EMPTY = uvm_reg_field::type_id::create ("RX_NOT_EMPTY"); //
		this.BUSY    = uvm_reg_field::type_id::create ("BUSY"); //
		this.RX_UD    = uvm_reg_field::type_id::create ("RX_UD"); //
		this.RESERVED    = uvm_reg_field::type_id::create ("RESERVED"); //
		// Configure each field
		this.FE.configure (this, 1, 0, "RW", 1, 1'b0, 1, 0, 0);
		this.PE.configure (this, 1, 1, "RW", 1, 1'b0, 1, 0, 0);
		this.BRK.configure (this, 1, 2, "RW", 1, 1'b0, 1, 0, 0);
		this.TX_OV.configure (this, 1, 3, "RW", 1, 1'b0, 1, 0, 0);
		this.RX_OV.configure (this, 1, 4, "RW", 1, 1'b0, 1, 0, 0);
		this.TX_FULL.configure (this, 1, 5, "RO", 1, 1'b0, 1, 0, 0);
		this.RX_FULL.configure (this, 1, 6, "RO", 1, 1'b0, 1, 0, 0);
		this.RX_NOT_EMPTY.configure (this, 1, 7, "RO", 1, 1'b0, 1, 0, 0);
		this.BUSY.configure (this, 1, 8, "RO", 0, 1'b0, 1, 0, 0);
		this.RX_UD.configure (this, 1, 9, "RW", 1, 1'b0, 1, 0, 0); //rx fifo underflow
		this.RESERVED.configure (this, 22, 10, "RO", 1, 22'd0, 1, 0, 0); //no use
	endfunction
		//this.TMT    = uvm_reg_field::type_id::create ("TMT"); //
		//this.TMT.configure (this, 1, 9, "RO", 1, 1'b1, 1, 0, 1); //transmit register empty

endclass
//divisor register
class uart_divisor_reg extends uvm_reg;
	//register factory
	`uvm_object_utils(uart_divisor_reg)
	//all fields
	rand uvm_reg_field divisor;
	//contructor
	function new (string name = "uart_divisor_reg");
		super.new (name, 16, UVM_NO_COVERAGE);
	endfunction
	//
	virtual function void build();
		this.divisor    = uvm_reg_field::type_id::create ("divisor"); 
		this.divisor.configure (this, 16, 0, "RW", 0, 16'h0000, 1, 1, 1);
	endfunction
endclass
//TX data fifo 
class txd_reg extends uvm_reg;
	//register factory
	`uvm_object_utils(txd_reg)
	//
	rand uvm_reg_field TXD;
	//contructor
	function new (string name = "txd_reg");
		super.new (name, 8, UVM_NO_COVERAGE);
	endfunction
	//
	//for reference
	//extern function void configure(uvm_reg        parent, 		// Parent register handle
                                   //int unsigned   size, 		// Bit-width of the field
                                   //int unsigned   lsb_pos, 		// LSB index of the field in register
                                   //string         access, 		// Read/read-write/etc access policy
                                   //bit            volatile,
                                   //uvm_reg_data_t reset,
                                   //bit            has_reset,
                                   //bit            is_rand,
                                   //bit            individually_accessible);
	virtual function void build();
		this.TXD = uvm_reg_field::type_id::create ("TXD"); 
		this.TXD.configure (this, 8, 0, "WO", 0, 8'h00, 1, 1, 1);
	endfunction
	//
endclass
//RX data fifo
class rxd_reg extends uvm_reg;
	//register factory
	`uvm_object_utils(rxd_reg)
	uvm_reg_field RXD;
	//contructor
	function new (string name = "rxd_reg");
		//name, depth, width, coverage
		super.new (name, 8, UVM_NO_COVERAGE);
	endfunction
	//
	//for reference
	//extern function void configure(uvm_reg        parent, 		// Parent register handle
                                   //int unsigned   size, 		// Bit-width of the field
                                   //int unsigned   lsb_pos, 		// LSB index of the field in register
                                   //string         access, 		// Read/read-write/etc access policy
                                   //bit            volatile,
                                   //uvm_reg_data_t reset,
                                   //bit            has_reset,
                                   //bit            is_rand,
                                   //bit            individually_accessible);
	virtual function void build();
		//critical note: we must set volatile bit to HIGH because this
		//register is internally written by DUT
		//unless, DUT value is always 0 as using mirror() method, and this
		//leads to mismatch between DUT value and current mirrored
		//value as setting UVM_CHECK in mirror() method  
		this.RXD = uvm_reg_field::type_id::create ("RXD"); 
		this.RXD.configure (this, 8, 0, "RO", 1, 8'h00, 1, 0, 1);
	endfunction
	//
endclass

//uart register block
class uart_reg_model extends uvm_reg_block;
  //register UVM factory
  `uvm_object_utils(uart_reg_model)
  //all regs
  rand txd_reg TXD;
  rxd_reg RXD;
  rand uart_ctrl_reg CTRL;
  uart_status_reg STATUS;
  rand uart_divisor_reg DIV;
  //
  uvm_reg_map map;

  function new(string name = "uart_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build(input string dut_name);
	  //back door access to fifo is NOT ALLOWED
    TXD = txd_reg::type_id::create("TXD");
    TXD.build();
    TXD.configure(this);
    //
    RXD = rxd_reg::type_id::create("RXD");
    RXD.build();
    RXD.configure(this);
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

    map = create_map("map", 'h0, 4, UVM_LITTLE_ENDIAN);

    map.add_reg(CTRL, 32'h0, "RW");
    map.add_reg(STATUS, 32'h4, "RW");
    map.add_reg(DIV, 32'h8, "RW");
    map.add_reg(TXD, 32'hc, "WO");
    map.add_reg(RXD, 32'h10, "RO");
    //
	add_hdl_path(dut_name, "RTL");
//for back door access
    lock_model();
  endfunction

endclass: uart_reg_model
endpackage
