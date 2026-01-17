//===============================================================================================
//Project: Design UART IP
//File name: uart_receiver.v
//Description: this module takes a role of translating SERIAL data into PARALEL data
//===============================================================================================
module uart_receiver(
clk_i, rst_n_i, rd_en_i, parity_en_i, even_parity_i, baud_tick_i, rx_i,
rx_data_o, err_parity_o, err_frame_o, break_bit_o, rx_overrun_o,
rx_buffer_full_o, rx_not_empty_o
);
//PORTs
input wire clk_i;
input wire rst_n_i;
//input wire enable_i;
input wire rd_en_i;
input wire parity_en_i;
input wire even_parity_i;
input wire baud_tick_i;
input wire rx_i;
output wire [7:0] rx_data_o;
output wire err_parity_o;
output wire err_frame_o;
output wire break_bit_o;
output wire rx_overrun_o;
output wire rx_buffer_full_o;
output wire rx_not_empty_o;
//VARIABLEs
//
//--1: Parameters of RX FSM
localparam RX_IDLE = 2'd0;
localparam RCV_BYTE = 2'd1;
localparam RCV_PARITY = 2'd2;
localparam WAIT_STOP_BIT = 2'd3;
//--2: FSM reg
reg [1:0] rx_cs;
//--3: FIFO signals
//--3.1: Configure
parameter DATA_WIDTH    = 10; //data(byte), parity_error, frame_error 
parameter POINTER_WIDTH = 3;
//--3.2: signals 
wire rx_fifo_wr, rx_fifo_rd, rx_fifo_empty, rx_fifo_full;
wire rx_fifo_ov;
wire [9:0] rx_fifo_i, rx_fifo_o;
//--4: signals of receiving data
reg [7:0] rx_data_reg;
reg parity_status;
reg frame_status;
reg [3:0] bit_cnt;
reg [3:0] sample_cnt; 
reg [1:0] sync_ff;
reg rx_done;
reg [3:0] break_cnt;
wire sample_en;
//IMPLEMENTATION
//--A: main module
//======================================================
//----------------OUTPUT ASSIGNMENT
//======================================================
assign rx_data_o = rx_fifo_o[9:2];
assign err_parity_o = rx_fifo_o[1];
assign err_frame_o = rx_fifo_o[0];
assign break_bit_o = parity_en_i ? (break_cnt > 4'd10) : (break_cnt > 4'd9);
assign rx_overrun_o = rx_fifo_ov;
assign rx_buffer_full_o = rx_fifo_full;
assign rx_not_empty_o = ~rx_fifo_empty;
//======================================================
//----------------MAIN FUNCTION
//======================================================
//2 d_ff synchronizer is implemeted with asynchronous reset to ensure CDC
//problem 
always@(posedge clk_i, negedge rst_n_i) begin
	if(~rst_n_i) begin
		sync_ff <= 2'b00;
	end
	else sync_ff <= {sync_ff[0], rx_i};
end
//
assign sample_en = ((rx_cs == RX_IDLE) ? (sample_cnt == 4'd7) : (sample_cnt == 4'd15)) & baud_tick_i;
//
always@(posedge clk_i) begin
	if(~rst_n_i) begin
		rx_cs <= RX_IDLE;
		sample_cnt <= 4'd0;
		bit_cnt <= 4'd0;
		rx_data_reg <= 8'd0;
		parity_status <= 1'b0;
		frame_status <= 1'b0;
		rx_done <= 1'b0;
	end
	else begin
		case(rx_cs)
			RX_IDLE: begin
				if(baud_tick_i) sample_cnt <= sample_cnt + 1'b1;
				//
				if(sample_en) begin
					sample_cnt <= 4'd0;
					//
					if(~sync_ff[1]) begin
						rx_cs <= RCV_BYTE;
						bit_cnt <= bit_cnt + 1'b1;
					end
					else begin
						rx_cs <= RX_IDLE;
					end
				end
				//
				if(rx_done) begin
					sample_cnt <= 4'd0;
					bit_cnt <= 4'd0;
					rx_data_reg <= 8'd0;
					parity_status <= 1'b0;
					frame_status <= 1'b0;
					rx_done <= 1'b0;
				end
			end
			RCV_BYTE: begin
				if(baud_tick_i) sample_cnt <= sample_cnt + 1'b1;
				//
				if(sample_en) begin
					sample_cnt <= 4'd0;
					bit_cnt <= bit_cnt + 1'b1;
					rx_data_reg <= {sync_ff[1], rx_data_reg[7:1]}; 
					//
					if(bit_cnt == 4'd8) begin //START bit + rcv 7 bits data
						bit_cnt <= 4'd0;
						if(parity_en_i) begin
							rx_cs <= RCV_PARITY;
						end	
						else begin
							rx_cs <= WAIT_STOP_BIT;
							parity_status <= 1'b0;
						end
					end
				end
			end
			RCV_PARITY: begin
				if(baud_tick_i) sample_cnt <= sample_cnt + 1'b1;
				//
				if(sample_en) begin
					sample_cnt <= 4'd0;
					parity_status <= even_parity_i ? ^{rx_data_reg, sync_ff[1]} : ~^{rx_data_reg, sync_ff[1]};
					rx_cs <= WAIT_STOP_BIT;
				end
			end
			WAIT_STOP_BIT: begin
				if(baud_tick_i) sample_cnt <= sample_cnt + 1'b1;
				//
				if(sample_en) begin
					sample_cnt <= 4'd0;
					frame_status <= ~sync_ff[1];
					rx_done <= 1'b1;
					rx_cs <= RX_IDLE;
				end//end of if sample_en
			end
		endcase
	end
end
//
//BREAK CONDITION
//
always@(posedge clk_i) begin
	if(~rst_n_i) begin
		break_cnt <= 4'd0;
	end
	//else if(enable_i) begin
		else if(sample_en) begin
			if(break_bit_o) begin
				break_cnt <= 4'd0;
			end
			else if(~sync_ff[1]) begin
			     break_cnt <= break_cnt + 1'b1;
		        end
			else begin
				break_cnt <= 4'd0;
			end
		end
	//end
end
//
//--B: internal sub module
//
assign rx_fifo_wr = rx_done;
assign rx_fifo_rd = rd_en_i;
assign rx_fifo_i = {rx_data_reg, parity_status, frame_status};
//
rx_fifo#(DATA_WIDTH, POINTER_WIDTH) rx_fifo(
	.rst_n(rst_n_i),
       	.wr(rx_fifo_wr),
       	.rd(rx_fifo_rd),
        .clk(clk_i),
	.sfifo_empty(rx_fifo_empty),
        .sfifo_full(rx_fifo_full),
        .sfifo_ov(rx_fifo_ov),
        .data_in(rx_fifo_i),
       	.data_out(rx_fifo_o)
);

endmodule
