//==================================================================================
//Project: Design UART IP
//File name: uart_if.sv
//Description:
//--TB  
//--uart_interface
//==================================================================================
interface uart_if(input bit clk);
	logic rst_n;
	logic rx;
	logic tx;
	logic brr_valid;
	logic [15:0] clk_per_bit;
	logic ctrl_valid;
	logic parity_en;
	//
	clocking uart_mon_cb @(posedge clk);
		input tx, rx, brr_valid, clk_per_bit, ctrl_valid, parity_en;
	endclocking
endinterface
