//==========================================================
//Project: Design APB-UART IP core
//File name: tb.sv 
//Author: Nguyen Ngoc Man
//Description: UVM test_bench
//==========================================================
//--tb can not give access to package if it is not imported
`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_pkg::*;
import apb_pkg::*;
import env_pkg::*;
import test_pkg::*; //uvm_test is package file, so we must import it to avoid uvm_fatal "no component instantiated"
//
module tb;
	//
	//global signals
	//
	bit clk0, clk1;
	//uart signals
	bit uart0_to_uart1, uart1_to_uart0;
	//
	initial begin
		forever #(`CLK_CYCLE_1/2.0) clk0 = ~clk0;
	end
	//
	initial begin
		forever #(`CLK_CYCLE_2/2.0) clk1 = ~clk1;
	end
	//
	//virtual interface
	//
apb_if apb0_if(.pclk(clk0));
apb_if apb1_if(.pclk(clk1));
uart_if uart0_if(.clk(clk0));
uart_if uart1_if(.clk(clk1));
interrupt_if int0_if();
interrupt_if int1_if();
//
	//
	//DUT
	//
	assign uart0_if.tx = uart0_to_uart1;
	assign uart0_if.rx = uart1_to_uart0;
	assign uart1_if.tx = uart1_to_uart0;
	assign uart1_if.rx = uart0_to_uart1;
	//assign reset
	assign uart0_if.rst_n = apb0_if.presetn;
	assign uart1_if.rst_n = apb1_if.presetn;
	//assign uart_control
	assign uart0_if.ctrl_valid = apb0_if.psel & apb0_if.pwrite & apb0_if.penable & (apb0_if.paddr == 32'd0);
	assign uart1_if.ctrl_valid = apb1_if.psel & apb1_if.pwrite & apb1_if.penable & (apb1_if.paddr == 32'd0);
	assign uart0_if.parity_en = apb0_if.pwdata[1];
	assign uart1_if.parity_en = apb1_if.pwdata[1];
	//assign brr value
	assign uart0_if.brr_valid = apb0_if.psel & apb0_if.pwrite & apb0_if.penable & (apb0_if.paddr == 32'd8);
	assign uart1_if.brr_valid = apb1_if.psel & apb1_if.pwrite & apb1_if.penable & (apb1_if.paddr == 32'd8);
	assign uart0_if.brr_value = apb0_if.pwdata[15:0];
	assign uart1_if.brr_value = apb1_if.pwdata[15:0];
//	output of apb_slave in uart_wrapper
	assign apb0_if.pready_i = uart0_wrap.rdy_ref;
	assign apb0_if.rdata_i = uart0_wrap.rdata_ref;
	assign apb0_if.err_i = uart0_wrap.err_ref;
	assign apb0_if.be_o = uart0_wrap.be_ref;
	assign apb0_if.en_o = uart0_wrap.enable_ref;
	assign apb0_if.wr_en_o = uart0_wrap.write_ref;
	assign apb0_if.wdata_o = uart0_wrap.wdata_ref;
	assign apb0_if.addr_o = uart0_wrap.addr_ref;
	//
	assign apb1_if.pready_i = uart1_wrap.rdy_ref;
	assign apb1_if.rdata_i = uart1_wrap.rdata_ref;
	assign apb1_if.err_i = uart1_wrap.err_ref;
	assign apb1_if.be_o = uart1_wrap.be_ref;
	assign apb1_if.en_o = uart1_wrap.enable_ref;
	assign apb1_if.wr_en_o = uart1_wrap.write_ref;
	assign apb1_if.wdata_o = uart1_wrap.wdata_ref;
	assign apb1_if.addr_o = uart1_wrap.addr_ref;
	//
	//UART0
uart_wrapper uart0_wrap(
//APB interface
.pclk(apb0_if.pclk),
.presetn(apb0_if.presetn), 
.psel(apb0_if.psel), 
.penable(apb0_if.penable), 
.pwrite(apb0_if.pwrite), 
.paddr(apb0_if.paddr), 
.pwdata(apb0_if.pwdata),
.pstrb(apb0_if.pstrb),
.pready(apb0_if.pready),
.prdata(apb0_if.prdata),
.pslverr(apb0_if.pslverr),
//INTERRUPT
`ifdef INTERRUPT
.int_req(int0_if.int_req),
`endif
//UART interface
.rx(uart1_to_uart0),
.tx(uart0_to_uart1)
); 
//UART1
uart_wrapper uart1_wrap(
//APB interface
.pclk(apb1_if.pclk),
.presetn(apb1_if.presetn), 
.psel(apb1_if.psel), 
.penable(apb1_if.penable), 
.pwrite(apb1_if.pwrite), 
.paddr(apb1_if.paddr), 
.pwdata(apb1_if.pwdata),
.pstrb(apb1_if.pstrb),
.pready(apb1_if.pready),
.prdata(apb1_if.prdata),
.pslverr(apb1_if.pslverr),

//INTERRUPT
`ifdef INTERRUPT
.int_req(int0_if.int_req),
`endif
//UART interface
.rx(uart0_to_uart1),
.tx(uart1_to_uart0)
); 
	//
    apb_checker_top apb0_checker(apb0_if);
    apb_checker_top apb1_checker(apb1_if);
    //
    //baud rate assertion
	//
    bind uart0_wrap.uart_top.br_gen_inst baud_rate_sva br0_sva(
        .clk(clk_i),
        .rst_n(rst_n_i),
        .en(enable_i),
        .baud_tick(baud_tick_o),
        .cnt(counter)
    );
    //
    bind uart1_wrap.uart_top.br_gen_inst baud_rate_sva br1_sva(
        .clk(clk_i),
        .rst_n(rst_n_i),
        .en(enable_i),
        .baud_tick(baud_tick_o),
        .cnt(counter)
    );
	//store virtual interface into UVM_config_db
	initial begin
		uvm_config_db#(virtual interface apb_if)::set(null, "*", "apb0_if", apb0_if);
		uvm_config_db#(virtual interface apb_if)::set(null, "*", "apb1_if", apb1_if);
		uvm_config_db#(virtual interface uart_if)::set(null, "uvm_test_top.env_h.uart_agt_h0*", "uart_if", uart0_if);
		uvm_config_db#(virtual interface uart_if)::set(null, "uvm_test_top.env_h.uart_agt_h1*", "uart_if", uart1_if);
		`ifdef INTERRUPT
		uvm_config_db#(virtual interface interrupt_if)::set(null, "uvm_test_top.env_h.uart_agt_h0*", "int_if", int0_if);
		uvm_config_db#(virtual interface interrupt_if)::set(null, "uvm_test_top.env_h.uart_agt_h1*", "int_if", int1_if);
		`endif
	end
	//
	initial begin
		run_test();
	end
	//
endmodule
