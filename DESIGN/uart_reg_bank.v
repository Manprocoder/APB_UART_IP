//==================================================================================
//Project: Design UART IP
//File name: uart_reg_bank.v
//Description: this module contains functional registers
//==================================================================================
module uart_reg_bank(
	clk_i, rst_n_i, ctrl_wr_i, ctrl_rd_i, ctrl_addr_i, ctrl_data_i,
	parity_err_i, frame_err_i, break_bit_i, tx_overrun_i, rx_overrun_i,
       	tx_full_i, rx_full_i, busy_i, rx_not_empty_i, rx_fifo_outdata_i, 
       	parity_en_o, even_parity_o, ctrl_data_o, 
	`ifdef INTERRUPT
	pe_int, fe_int, tx_ov_int, rx_ov_int, break_int, rx_data_int,
	`endif
	//
	enable_o, divisor_val_o, push_o, pop_o
       	//
);
//PORTs
input wire clk_i;
input wire rst_n_i;
input wire ctrl_wr_i;
input wire ctrl_rd_i;
input wire [2:0] ctrl_addr_i;
input wire [31:0] ctrl_data_i;
input wire parity_err_i;
input wire frame_err_i;
input wire break_bit_i;
input wire tx_overrun_i;
input wire rx_overrun_i;
input wire tx_full_i;
input wire rx_full_i;
input wire busy_i;
//input wire trans_empty_i;
input wire rx_not_empty_i;
input wire [7:0] rx_fifo_outdata_i;
output wire parity_en_o;
output wire even_parity_o;
output reg [31:0] ctrl_data_o;
//INTERRUPT
`ifdef INTERRUPT
output wire pe_int;
output wire fe_int;
output wire tx_ov_int;
output wire rx_ov_int;
output wire break_int;
output wire rx_data_int;
`endif
output wire enable_o;
output wire [15:0] divisor_val_o;
output wire push_o;
output wire pop_o;
//
//REGISTERs
reg [31:0] control;
wire [31:0] status;
reg [15:0] divisor;
reg start;
//
wire clr_status;
wire tx_ov_pulse, rx_ov_pulse;
reg bit_parity, bit_frame_err, bit_break;
reg bit_tx_ov, bit_rx_ov;
reg rx_ud;
//=============================================================
//------------------OUTPUT ASSIGNMENT
//=============================================================
assign divisor_val_o = divisor;
assign enable_o = start;
assign parity_en_o = control[1];
assign even_parity_o = control[2];
assign push_o = ctrl_wr_i & (ctrl_addr_i == 3'd3);
assign pop_o = ctrl_rd_i & (ctrl_addr_i == 3'd4);

`ifdef INTERRUPT
assign pe_int = pop_o & parity_err_i & control[8];
assign fe_int = pop_o & frame_err_i & control[9];
assign tx_ov_int = tx_ov_pulse & control[10];
assign rx_ov_int = rx_ov_pulse & control[11];
assign break_int = break_bit_i & control[12];
assign rx_data_int = rx_not_empty_i & control[13];
`endif
//=============================================================
//------------------- INTERNAL ASSIGNMENT
//=============================================================
assign clr_status = ctrl_wr_i & (ctrl_addr_i == 3'd1);
//
//control and divisor register --- datain
always@(posedge clk_i) begin
	if(~rst_n_i) begin
		control <= 32'd0;
		divisor <= 16'd0;
		start <= 1'b0;
	end
	else if(ctrl_wr_i) begin
		case(ctrl_addr_i) 
		0: control <= ctrl_data_i;
		2: begin
			divisor <= ctrl_data_i[15:0];
			start <= 1'b1;
		end
		endcase
	end
	else start <= 1'b0;
end
//
//control, divisor, status register --- ctrl_data_out
//
//status register
assign status = {22'd0, rx_ud, busy_i, 
	rx_not_empty_i, rx_full_i, tx_full_i, bit_rx_ov, bit_tx_ov, bit_break, bit_parity, bit_frame_err};
//
always@(posedge clk_i) begin
	if(~rst_n_i) ctrl_data_o <= 32'd0;
	else if(ctrl_rd_i) begin
		case(ctrl_addr_i)
		0: ctrl_data_o <= control;
		1: ctrl_data_o <= status;
		2: ctrl_data_o <= {16'd0, divisor};
		4: ctrl_data_o <= {24'd0, rx_fifo_outdata_i};
		endcase
	end
end
//
always@(posedge clk_i) begin
	if(~rst_n_i) rx_ud <= 1'b0;
	else if(clr_status)  rx_ud <= 1'b0;
	else if(pop_o & ~rx_not_empty_i) rx_ud <= 1'b1;
end
//break bit
always@(posedge clk_i) begin
	if(~rst_n_i) bit_break <= 1'b0;
	else if(clr_status) bit_break <= 1'b0;
	else if(break_bit_i) bit_break <= 1'b1;
end
//parity bit and frame bit
always@(posedge clk_i) begin
	if(~rst_n_i) begin
		bit_parity <= 1'b0;
		bit_frame_err <= 1'b0;
	end
	else if(clr_status) begin
		bit_parity <= 1'b0;
		bit_frame_err <= 1'b0;
	end
	else if(pop_o) begin
		bit_parity <= parity_err_i;
		bit_frame_err <= frame_err_i;
	end
end
//
//tx_overrun bit and rx_overrun bit
//
always@(posedge clk_i) begin
	if(~rst_n_i) bit_tx_ov <= 1'b0;
	else if(clr_status) bit_tx_ov <= 1'b0;
	else if(tx_ov_pulse) bit_tx_ov <= 1'b1;
end
//
always@(posedge clk_i) begin
	if(~rst_n_i) bit_rx_ov <= 1'b0;
	else if(clr_status) bit_rx_ov <= 1'b0;
	else if(rx_ov_pulse) bit_rx_ov <= 1'b1;
end
//
Risi_Edge_Detector tx_ov_signal(
    .clk_i(clk_i),
    .rstn_i(rst_n_i),
    .sign_i(tx_overrun_i),
    .red_o(tx_ov_pulse)  
    //
);
//

Risi_Edge_Detector rx_ov_signal(
    .clk_i(clk_i),
    .rstn_i(rst_n_i),
    .sign_i(rx_overrun_i),
    .red_o(rx_ov_pulse)  
    //
);
//
endmodule
