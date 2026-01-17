//==========================================================
//Project: Design APB-UART IP core
//File name: tb.sv 
//Description: UVM test_bench
//==========================================================
//--tb can not give access to package if it is not imported
`include "uvm_macros.svh"
module tb;
import parameter_pkg::*;
import uvm_pkg::*;
import test_pkg::*; //uvm_test is package file, so we must import it to avoid uvm_fatal "no component instantiated"
	//
	//global signals
	//
	reg clk0, clk1;
	//uart signals
	bit uart0_to_uart1, uart1_to_uart0;
	//
	initial begin
		clk0 = 0;
		forever #(`CLK_CYCLE/2.0) clk0 = ~clk0;
	end
	//
	initial begin
		clk1 = 0;
		forever #(`CLK_CYCLE/2.0) clk1 = ~clk1;
	end
	//
	initial begin
		$display("CLK_CYCLE = %0d", `CLK_CYCLE);
	end
	//
	//virtual interface
	//
apb_if#(DW, APB_AW) apb_if_0(.pclk(clk0));
apb_if#(DW, APB_AW) apb_if_1(.pclk(clk1));
uart_if uart0_if(.clk(clk0));
uart_if uart1_if(.clk(clk1));
interrupt_if int0_if();
interrupt_if int1_if();
	//
	//DUT
	//
	assign uart0_if.tx = uart0_to_uart1;
	assign uart0_if.rx = uart1_to_uart0;
	assign uart1_if.tx = uart1_to_uart0;
	assign uart1_if.rx = uart0_to_uart1;
	//assign reset
	assign uart0_if.rst_n = apb_if_0.presetn;
	assign uart1_if.rst_n = apb_if_1.presetn;
	//assign uart_control
	assign uart0_if.ctrl_valid = apb_if_0.psel & apb_if_0.pwrite & apb_if_0.penable & (apb_if_0.paddr == 32'd0);
	assign uart1_if.ctrl_valid = apb_if_1.psel & apb_if_1.pwrite & apb_if_1.penable & (apb_if_1.paddr == 32'd0);
	assign uart0_if.parity_en = apb_if_0.pwdata[1];
	assign uart1_if.parity_en = apb_if_1.pwdata[1];
	//assign brr value
	assign uart0_if.brr_valid = apb_if_0.psel & apb_if_0.pwrite & apb_if_0.penable & (apb_if_0.paddr == 32'd8);
	assign uart1_if.brr_valid = apb_if_1.psel & apb_if_1.pwrite & apb_if_1.penable & (apb_if_1.paddr == 32'd8);
	assign uart0_if.clk_per_bit = apb_if_0.pwdata[15:0];
	assign uart1_if.clk_per_bit = apb_if_1.pwdata[15:0];
//	output of apb_slave in uart_wrapper
	assign apb_if_0.rdata_i = uart0_wrap.rdata_ref;
	assign apb_if_0.wr_en_o = uart0_wrap.apb_inst.wr_en_o;
	assign apb_if_0.rd_en_o = uart0_wrap.apb_inst.rd_en_o;
	assign apb_if_0.wdata_o = uart0_wrap.apb_inst.wdata_o;
	assign apb_if_0.addr_o = uart0_wrap.apb_inst.addr_o;
	//
	assign apb_if_1.rdata_i = uart1_wrap.rdata_ref;
	assign apb_if_1.wr_en_o = uart1_wrap.apb_inst.wr_en_o;
	assign apb_if_1.rd_en_o = uart1_wrap.apb_inst.rd_en_o;
	assign apb_if_1.wdata_o = uart1_wrap.apb_inst.wdata_o;
	assign apb_if_1.addr_o = uart1_wrap.apb_inst.addr_o;
	//
	//UART0
uart_wrapper uart0_wrap(
//APB interface
.pclk(apb_if_0.pclk),
.presetn(apb_if_0.presetn), 
.psel(apb_if_0.psel), 
.penable(apb_if_0.penable), 
.pwrite(apb_if_0.pwrite), 
.paddr(apb_if_0.paddr), 
.pwdata(apb_if_0.pwdata),
.prdata(apb_if_0.prdata),
.pready(apb_if_0.pready),
//INTERRUPT
`ifdef INTERRUPT
.pe_int(int0_if.pe_int),
.fe_int(int0_if.fe_int), 
.tx_ov_int(int0_if.tx_ov_int), 
.rx_ov_int(int0_if.rx_ov_int), 
.break_int(int0_if.break_int), 
.rx_data_int(int0_if.rx_data_int),
`endif
//UART interface
.rx(uart1_to_uart0),
.tx(uart0_to_uart1)
); 
//UART1
uart_wrapper uart1_wrap(
//APB interface
.pclk(apb_if_1.pclk),
.presetn(apb_if_1.presetn), 
.psel(apb_if_1.psel), 
.penable(apb_if_1.penable), 
.pwrite(apb_if_1.pwrite), 
.paddr(apb_if_1.paddr), 
.pwdata(apb_if_1.pwdata),
.prdata(apb_if_1.prdata),
.pready(apb_if_1.pready),
//INTERRUPT
`ifdef INTERRUPT
.pe_int(int1_if.pe_int),
.fe_int(int1_if.fe_int), 
.tx_ov_int(int1_if.tx_ov_int), 
.rx_ov_int(int1_if.rx_ov_int), 
.break_int(int1_if.break_int), 
.rx_data_int(int1_if.rx_data_int),
`endif
//UART interface
.rx(uart0_to_uart1),
.tx(uart1_to_uart0)
); 
	//
	//store virtual interface into UVM_config_db
	//
	initial begin
		uvm_config_db#(virtual interface apb_if#(DW, APB_AW))::set(null, "*", "apb_if_0", apb_if_0);
		uvm_config_db#(virtual interface apb_if#(DW, APB_AW))::set(null, "*", "apb_if_1", apb_if_1);
		uvm_config_db#(virtual interface uart_if)::set(null, "uvm_test_top.env_h.uart_agt_h0*", "uart_if", uart0_if);
		uvm_config_db#(virtual interface uart_if)::set(null, "uvm_test_top.env_h.uart_agt_h1*", "uart_if", uart1_if);
		`ifdef INTERRUPT
		uvm_config_db#(virtual interface interrupt_if)::set(null, "uvm_test_top", "int0_if", int0_if);
		uvm_config_db#(virtual interface interrupt_if)::set(null, "uvm_test_top", "int1_if", int1_if);
		`endif
	end
	//
	initial begin
		run_test();
	end
	//
endmodule
