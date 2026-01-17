//================================================================
//--Project: Design UART IP
//--File name: baud_rate_generator.v
//--Description: Generate clock pulse to synchronize TX and RX
//================================================================
module baud_rate_generator(clk_i, rst_n_i, enable_i, divisor_i, baud_tick_o);
//PORTS
input wire clk_i;
input wire rst_n_i;
input wire enable_i;
input wire [15:0] divisor_i;
output wire baud_tick_o;
//VARIABLES
reg [15:0] counter;
reg baud_tick_valid;
//
//output assignment
//
assign baud_tick_o = baud_tick_valid;
//
//internal assignment
//
assign baud_tick_active = |divisor_i ? (counter == {16{1'b1}}) : 1'b0;
//
always@(posedge clk_i) begin
	if(~rst_n_i) begin
		counter <= 16'd0;
	end
	else if(enable_i | baud_tick_active)begin
		counter <= divisor_i - 1'd1;
	end
	else begin
		counter <= counter - 1'b1;
	end
end
//
always@(posedge clk_i) begin
	if(~rst_n_i) baud_tick_valid <= 1'b0;
	else if(baud_tick_active) begin
		baud_tick_valid <= 1'b1;
	end
	else baud_tick_valid <= 1'b0;
end
//
endmodule
