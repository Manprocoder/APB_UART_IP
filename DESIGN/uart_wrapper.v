//===============================================================================================================
//Project: Design UART (Universal Asynchronous Receiver Transmitter)
//File name: uart_wrapper.v
//Description: APB slave ip + UART TOP ip
//===============================================================================================================
module uart_wrapper(
//APB interface
pclk, presetn, psel, penable, pwrite, paddr, pwdata, prdata, pready,
//INTERRUPT
`ifdef INTERRUPT
pe_int, fe_int, tx_ov_int, rx_ov_int, break_int, rx_data_int,
`endif
//UART interface
rx, tx
); 
//
//PORTs
//
//APB interface
input wire pclk;
input wire presetn;
input wire psel;
input wire penable;
input wire pwrite;
input wire [31:0] paddr;
input wire [31:0] pwdata;
output wire [31:0] prdata;
output wire pready;
//INTERRUPT
`ifdef INTERRUPT
output wire pe_int;
output wire fe_int;
output wire tx_ov_int;
output wire rx_ov_int;
output wire break_int;
output wire rx_data_int;
`endif
//UART interface
input wire rx;
output wire tx;
//WIREs
//
wire [31:0] rdata_ref;
wire [31:0] wdata_ref;
wire [31:0] addr_ref;
wire write_ref, read_ref;
//INSTANCES
//1: APB
apb_slave apb_inst(
.pclk(pclk),
.presetn(presetn),
.psel(psel),
.penable(penable),
.pwrite(pwrite),
.paddr(paddr),
.pwdata(pwdata),
.prdata(prdata),
.pready(pready),
.rdata_i(rdata_ref),
.pready_i(1'b1),
.wr_en_o(write_ref),
.rd_en_o(read_ref),
.wdata_o(wdata_ref),
.addr_o(addr_ref)
);
//2: UART

uart_top uart_top(
	.clk_i(pclk),
       	.rst_n_i(presetn),
       	.ctrl_wr_i(write_ref),
       	.ctrl_rd_i(read_ref),
       	.ctrl_addr_i(addr_ref[4:2]),
       	.ctrl_data_i(wdata_ref),
	`ifdef INTERRUPT
	.pe_int(pe_int),
	.fe_int(fe_int),
       	.tx_ov_int(tx_ov_int),
       	.rx_ov_int(rx_ov_int),
       	.break_int(break_int),
       	.rx_data_int(rx_data_int),
	`endif
       	.rx_i(rx),
	.tx_o(tx),
       	.ctrl_data_o(rdata_ref)  
);
//
endmodule
