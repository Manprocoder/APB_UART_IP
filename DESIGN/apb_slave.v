//===============================================================================================================
//Project: Design UART (Universal Asynchronous Receiver Transmitter)
//File name: apb_slave.v
//Description: configure UART's SFR
//===============================================================================================================
module apb_slave(
	pclk, presetn, psel, penable, pwrite, paddr, pwdata, prdata, pready, rdata_i, pready_i,
       	wr_en_o, rd_en_o, wdata_o, addr_o
);
//PORTs
//APB interface
input wire pclk;
input wire presetn;
input wire psel;
input wire penable;
input wire pwrite;
input wire [31:0] paddr;
input wire [31:0] pwdata;
output reg [31:0] prdata;
output reg pready;
//others
input wire [31:0] rdata_i;
input wire pready_i;
output reg wr_en_o;
output reg rd_en_o;
output reg [31:0] wdata_o;
output reg [31:0] addr_o;
//VARIABLES
//--1
//FSM state localparam
localparam IDLE = 1'b0;
localparam ACCESS = 1'b1;
//--2
//state reg
reg cs, ns;
//IMPLEMENT
//reg block
always@(posedge pclk, negedge presetn) begin
	if(~presetn) cs <= IDLE;
	else cs <= ns;
end
//
//
always@(*) begin
	ns = cs;
	wr_en_o = 1'b0;
	rd_en_o = 1'b0;
	wdata_o = 32'd0;
	addr_o = 32'd0;
	pready = 1'b0;
	prdata = 32'd0;
	//
	//
	case(cs)
		IDLE: begin
			if(psel) begin
				ns = ACCESS; 
				rd_en_o = ~pwrite;
			end	
			else begin
				ns = IDLE;
			end
			wr_en_o = 1'b0;
			wdata_o = pwdata;
			addr_o = paddr;
			pready = 1'b0;
			prdata = 32'd0;
		end
		ACCESS: begin
			pready = pready_i; 
			wdata_o = pwdata;
			addr_o = paddr;
			rd_en_o = 1'b0;
			//
			if(penable) begin
				ns = IDLE;
				wr_en_o = pwrite;
				prdata = pwrite ? 32'd0 : rdata_i;
			end
			else begin
				ns = ACCESS;
			end
		end

	endcase
end
//
endmodule
