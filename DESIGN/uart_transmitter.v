//==================================================================================
//Project: Design UART IP
//File name: uart_transmitter.v
//Description: this module takes a role of translating paralel data into serial data
//==================================================================================
module uart_transmitter(clk_i, rst_n_i, tx_data_vld_i, parity_en_i, even_parity_i,
	baud_tick_i, tx_data_i,
       tx_overrun_o, tx_buffer_full_o, tx_busy_o, tx_o
);
//PORTs
input wire clk_i;
input wire rst_n_i;
input wire parity_en_i;
input wire even_parity_i;
input wire tx_data_vld_i;
input wire baud_tick_i;
input wire [7:0] tx_data_i;
output wire tx_overrun_o;
output wire tx_buffer_full_o;
output wire tx_busy_o;
//output wire trans_empty_o;
output wire tx_o;
//VARIABLEs
//--1: parameter of transmit FSM
localparam TX_IDLE = 3'd0;
localparam SEND_START = 3'd1;
localparam SEND_BYTE = 3'd2;
localparam SEND_PARITY = 3'd3;
localparam SEND_STOP = 3'd4;
//--2: state register of transmit FSM
reg [2:0] txt_cs; 
//--3: TRANSMIT FIFO HANDLING
//--3.1: configure
parameter DATA_WIDTH    = 8;
parameter POINTER_WIDTH = 3;
//--3.2: signals 
wire tx_fifo_wr, tx_fifo_rd, tx_fifo_empty, tx_fifo_full;
wire tx_fifo_ov;
wire [7:0] tx_fifo_i, tx_fifo_o;
//--4: handle data shifting
reg [6:0] tx_shift_reg;
reg bit_out;
reg [3:0] data_bit_cnt;
reg [3:0] shift_cnt;
reg tx_pop;
reg busy;
reg parity_bit;
wire shift_en;
//IMPLEMENTATION
//**********************************************************
//-------------------OUTPUT ASSIGNMENT
//**********************************************************
assign tx_o = bit_out;
assign tx_overrun_o = tx_fifo_ov;
assign tx_buffer_full_o = tx_fifo_full;
assign tx_busy_o = busy;
//assign trans_empty_o = ~(txt_cs == SEND_BYTE);
//--A: main module
//
//--A.1: state reg
assign shift_en = (shift_cnt == 4'd15) & baud_tick_i;
//
always@(posedge clk_i) begin
	if(~rst_n_i) begin
		txt_cs <= TX_IDLE;
		bit_out <= 1'b1;
		tx_shift_reg <= 7'd0;
		shift_cnt <= 4'd0;
		data_bit_cnt <= 4'd0;
		busy <= 1'b0;
		tx_pop <= 1'b0;
		parity_bit <= 1'b0;
	end
	else begin
		case(txt_cs)
			TX_IDLE: begin
				if(~tx_fifo_empty & baud_tick_i) begin
					txt_cs <= SEND_START;
					bit_out <= 1'b0; //START bit
					busy <= 1'b1;
				end
				else begin
					txt_cs <= TX_IDLE;
					busy <= 1'b0;
				end
				//
					tx_shift_reg <= 7'd0;
					data_bit_cnt <= 4'd0;
			end
			SEND_START: begin
				//
				if(baud_tick_i) shift_cnt <= shift_cnt + 1'b1;
				//
				if(shift_en) begin
					txt_cs <= SEND_BYTE;
					{tx_shift_reg, bit_out} <= tx_fifo_o;
					parity_bit <= even_parity_i ? ^tx_fifo_o : ~^tx_fifo_o;
					tx_pop <= 1'b1;
					shift_cnt <= 4'd0;
				end
				//
			end
			SEND_BYTE: begin //shift LSB
				if(tx_pop) tx_pop <= 1'b0;
				//
				if(baud_tick_i) shift_cnt <= shift_cnt + 1'b1;
				//
				if(shift_en) begin
					shift_cnt <= 4'd0;
					//
					if(data_bit_cnt == 4'd7) begin
						data_bit_cnt <= 4'd0;
						//
						if(parity_en_i) begin
							txt_cs <= SEND_PARITY;
							bit_out <= parity_bit;
						end
						else begin
							txt_cs <= SEND_STOP; 
							bit_out <= 1'b1;
						end
					end
					else begin
						{tx_shift_reg, bit_out} <= {1'b0, tx_shift_reg};
						data_bit_cnt <= data_bit_cnt + 1'd1;
					end
				end //end of if shift_en
			end
			SEND_PARITY: begin
				if(baud_tick_i) shift_cnt <= shift_cnt + 1'b1;
				//
				if(shift_en) begin
					txt_cs <= SEND_STOP;
					shift_cnt <= 4'd0;
					bit_out <= 1'b1;
				end
			end
			SEND_STOP: begin
				if(baud_tick_i) shift_cnt <= shift_cnt + 1'b1;
				//
				if(shift_en) begin
					txt_cs <= TX_IDLE;
					shift_cnt <= 4'd0;
				end
			end
		endcase
	end//end of else if(~rst_n_i)
end//end of always block
//--B: internal sub module
//
assign tx_fifo_wr = tx_data_vld_i;
assign tx_fifo_rd = tx_pop;
assign tx_fifo_i = tx_data_i;
//
tx_fifo#(DATA_WIDTH, POINTER_WIDTH) tx_fifo(
	.rst_n(rst_n_i),
       	.wr(tx_fifo_wr),
       	.rd(tx_fifo_rd),
        .clk(clk_i),
	.sfifo_empty(tx_fifo_empty),
        .sfifo_full(tx_fifo_full),
	.sfifo_ov(tx_fifo_ov),
        .data_in(tx_fifo_i),
       	.data_out(tx_fifo_o)
);

endmodule
