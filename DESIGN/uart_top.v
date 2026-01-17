//===============================================================================================================
//Project: Design UART (Universal Asynchronous Receiver Transmitter)
//File name: uart_top.v
//Description: Connect all sub-modules (uart_reg_bank, baud_rate_generator, uart_receiver and uart_transmitter)
//===============================================================================================================
module uart_top(
	clk_i, rst_n_i, ctrl_wr_i, ctrl_rd_i, ctrl_addr_i, ctrl_data_i,
	`ifdef INTERRUPT
		pe_int, fe_int, tx_ov_int, rx_ov_int, break_int, rx_data_int,
	`endif
       	rx_i, tx_o, ctrl_data_o  
);
//PORTs
input wire clk_i;
input wire rst_n_i;
input wire ctrl_wr_i;
input wire ctrl_rd_i;
input wire [2:0] ctrl_addr_i;
input wire [31:0] ctrl_data_i;
`ifdef INTERRUPT
output wire pe_int;
output wire fe_int;
output wire tx_ov_int;
output wire rx_ov_int;
output wire break_int;
output wire rx_data_int;
`endif
input wire rx_i;
output wire tx_o;
output wire [31:0] ctrl_data_o;
//WIREs
//--1: UART REG BANK outputs
wire parity_en;
wire even_parity;
wire [15:0] divisor_val;
wire pop, push;
wire enable;
//--2: BAUD RATE GENERATOR outputs
wire baud_tick;
//--3: UART TRANSMITTER outputs
wire tx_overrun;
wire tx_full;
wire busy;
//wire trans_empty;
//--4: UART RECEIVER outputs
wire rx_overrun;
wire rx_full;
wire rx_not_empty;
wire parity_err;
wire frame_err;
wire break_con;
wire [7:0] rx_fifo_outdata;
//SUBMODULEs
//--1: uart_reg_bank inst
uart_reg_bank uart_reg_bank_inst(
	.clk_i(clk_i),
       	.rst_n_i(rst_n_i),
	.ctrl_wr_i(ctrl_wr_i),
       	.ctrl_rd_i(ctrl_rd_i),
       	.ctrl_addr_i(ctrl_addr_i),
       	.ctrl_data_i(ctrl_data_i),
	.parity_err_i(parity_err),
       	.frame_err_i(frame_err),
       	.break_bit_i(break_con),
       	.tx_overrun_i(tx_overrun),
       	.rx_overrun_i(rx_overrun),
       	.tx_full_i(tx_full),
       	.rx_full_i(rx_full),
       	.busy_i(busy),
	//.trans_empty_i(trans_empty),
	.rx_not_empty_i(rx_not_empty),
	.rx_fifo_outdata_i(rx_fifo_outdata),
       	.parity_en_o(parity_en),
       	.even_parity_o(even_parity),
       	.ctrl_data_o(ctrl_data_o), 
	`ifdef INTERRUPT
	.pe_int(pe_int),
	.fe_int(fe_int),
       	.tx_ov_int(tx_ov_int),
       	.rx_ov_int(rx_ov_int),
       	.break_int(break_int),
	.rx_data_int(rx_data_int),
	`endif
	//
       	.enable_o(enable),
	.divisor_val_o(divisor_val),
	.push_o(push),
	.pop_o(pop)
       	//
);
//--2: uart_baud_rate_generator inst
baud_rate_generator br_gen_inst(
	.clk_i(clk_i),
       	.rst_n_i(rst_n_i),
       	.enable_i(enable),
       	.divisor_i(divisor_val),
       	.baud_tick_o(baud_tick)
);
//--3: uart_transmitter inst
uart_transmitter uart_tmt_inst(
	.clk_i(clk_i),
       	.rst_n_i(rst_n_i),
       	//.enable_i(ctrl_en),
       	.tx_data_vld_i(push),
       	.parity_en_i(parity_en),
	.even_parity_i(even_parity),
       	.baud_tick_i(baud_tick),
       	.tx_data_i(ctrl_data_i[7:0]),
       	.tx_overrun_o(tx_overrun),
       	.tx_buffer_full_o(tx_full),
	.tx_busy_o(busy),
	//.trans_empty_o(trans_empty),
       	.tx_o(tx_o)
);
//--4: uart_receiver inst
uart_receiver uart_rcv_inst(
	.clk_i(clk_i),
       	.rst_n_i(rst_n_i),
       	//.enable_i(ctrl_en),
       	.rd_en_i(pop),
       	.parity_en_i(parity_en),
	.even_parity_i(even_parity),
       	.baud_tick_i(baud_tick),
       	.rx_i(rx_i),
	.rx_data_o(rx_fifo_outdata),
       	.err_parity_o(parity_err),
       	.err_frame_o(frame_err),
       	.break_bit_o(break_con),
       	.rx_overrun_o(rx_overrun),
	.rx_buffer_full_o(rx_full),
	.rx_not_empty_o(rx_not_empty)
	//
);
endmodule
