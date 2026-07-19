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
//
//internal assignment
//
assign baud_tick_o = |divisor_i ? (counter == 0) : 1'b0;
//
always@(posedge clk_i) begin
	if(~rst_n_i) begin
		counter <= 16'd0;
	end
	else if(enable_i | baud_tick_o)begin
		counter <= divisor_i;
	end
	else begin
		counter <= counter - 1'b1;
	end
end
//
endmodule
