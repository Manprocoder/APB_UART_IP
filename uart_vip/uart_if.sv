//==================================================================================
//Project: Design and Verify APB_UART IP
//File name: uart_if.sv
//Description:
//==================================================================================
interface uart_if(input bit clk);
	logic rst_n;
	logic rx;
	logic tx;
	logic brr_valid;
	logic [15:0] brr_value;
	logic ctrl_valid;
	logic parity_en;
	//
	clocking uart_mon_cb @(posedge clk);
		input tx, rx, brr_valid, brr_value, ctrl_valid, parity_en;
	endclocking
endinterface
