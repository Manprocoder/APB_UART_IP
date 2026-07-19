//===============================================================================================================
//Project: Design UART (Universal Asynchronous Receiver Transmitter)
//File name: uart_wrapper.v
//Description: APB slave ip + UART TOP ip
//===============================================================================================================
module uart_wrapper(
//APB interface
pclk, presetn, psel, penable, pwrite, paddr, pwdata, pstrb, prdata, pready, pslverr,
//INTERRUPT
`ifdef INTERRUPT
int_req,
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
input wire [03:0] pstrb;
output wire [31:0] prdata;
output wire pready;
output wire pslverr;
//INTERRUPT
`ifdef INTERRUPT
output wire int_req;
`endif
//UART interface
input wire rx;
output wire tx;
//WIREs
//
wire [31:0] rdata_ref;
wire [31:0] wdata_ref;
wire [31:0] addr_ref;
wire write_ref, enable_ref;
wire rdy_ref = 1'b1;
wire err_ref = 1'b0;
wire [3:0] be_ref;
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
.pstrb(pstrb),
.prdata(prdata),
.pready(pready),
.pslverr(pslverr),
.rdata_i(rdata_ref),
.pready_i(rdy_ref),
.err_i(err_ref),
.en_o(enable_ref),
.be_o(be_ref),
.wr_en_o(write_ref),
.wdata_o(wdata_ref),
.addr_o(addr_ref)
);
//2: UART

uart_top uart_top(
	.clk_i(pclk),
       	.rst_n_i(presetn),
       	.ctrl_en_i(enable_ref),
       	.ctrl_wr_i(write_ref),
       	.ctrl_addr_i(addr_ref[4:2]),
       	.ctrl_data_i(wdata_ref),
	`ifdef INTERRUPT
	.int_req(int_req),
	`endif
       	.rx_i(rx),
	.tx_o(tx),
       	.ctrl_data_o(rdata_ref)  
);
//
endmodule
