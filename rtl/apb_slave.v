//===============================================================================================================
//Project: Design and Verify APB UART (Universal Asynchronous Receiver Transmitter)
//File name: apb_slave.v
//Author: Nguyen Ngoc Man
//Description: configure UART's SFR
//===============================================================================================================
module apb_slave(
    //APB INTERFACE
	pclk, presetn, psel, penable, pwrite, paddr, pwdata, pstrb, prdata, pready, pslverr,
    //
    rdata_i, pready_i, err_i,
    en_o, wr_en_o, wdata_o, be_o, addr_o
);
//PORTs
//APB interface
input wire pclk;
input wire presetn;
input wire psel;
input wire penable;
input wire pwrite;
input wire [03:0] pstrb;
input wire [31:0] paddr;
input wire [31:0] pwdata;
output reg [31:0] prdata;
output reg pready;
output reg pslverr;
//others
input wire [31:0] rdata_i;
input wire pready_i;
input wire err_i;
output reg en_o;
output reg wr_en_o;
output reg [03:0] be_o;
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
	ns = IDLE;
	en_o = 1'b0;
	wr_en_o = 1'b0;
	wdata_o = 32'd0;
	addr_o = 32'd0;
    be_o = 4'b0;
	pready = 1'b0;
    pslverr = 1'b0;
	prdata = 32'd0;
	//
	//
	case(cs)
		IDLE: begin
			if(psel ^ penable) begin
				ns = ACCESS; 
				en_o = pwrite ? 1'b0 : 1'b1;
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
            pslverr = err_i;
            be_o = pstrb;
            wr_en_o = 1'b1;
			//
			if(pready) begin
				ns = IDLE;
				en_o = 1'b1;
				prdata = pwrite ? 32'd0 : rdata_i;
			end
			else begin
				ns = ACCESS;
			end
		end
        default: begin
                ns = IDLE;
                en_o = 1'b0;
                wr_en_o = 1'b0;
                wdata_o = 32'd0;
                addr_o = 32'd0;
                be_o = 4'b0;
                pready = 1'b0;
                pslverr = 1'b0;
                prdata = 32'd0;
        end
	endcase
end
//
endmodule
