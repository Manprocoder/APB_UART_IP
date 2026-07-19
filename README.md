
**DESIGN and VERIFICATION of APB_UART IP **
- 
**Design**


![APB_UART Block Diagram](/IMAGE/apb_uart_bd.png)


APB4 protocol
+ address bus width = 32 bits, data bus width = 32 bits

UART protocol
+ supports frame error check, parity err check, break condition, ONLY 8-bit data frame
+ 3 registers: 32-bit control, 32-bit status, 16-bit brr_value (DIVISOR in image)
+ TX FIFO: WIDTH = 8, DEPTH = 8
+ RX FIFO: WIDTH = 10, DEPTH = 8 //WIDTH: parity_err, frame_err, rx_data

**Verification**

UVM testbench Architecture 

![APB_UART Block Diagram](/IMAGE/apb_uart_tb.png)

Details:

2 DUT instances: UART0 and UART1

Active APB Agent and Passive UART Agent

Register Model

Scoreboard:

apb_scoreboard virtual class:
- Main Attributes:
+ uvm_tlm_analysis_fifo: apb_txn_fifo(store APB transfers by APB bus), apb_to_slv_fifo (store signals UART communicates with APB)
+ associative array: status_arr(store readdata of status), rdata_arr(store readdata of rx_data), tx_data_arr (store tx_data --- expected data)
+ checkers: no_apb_pass, no_apb_fail;

- Main Methods(function/task): 
+ init_checker: clear no_apb_pass, no_apb_fail;
+ init_all_arr() and flush_fifo(): init associative array and flush all fifos
+ compare_apb(): compare apb_txn_fifo to apb_to_slv_fifo

apb_uart_Scoreboard (derived/child) class:
- Main Attributes:
+ uvm_tlm_analysis_fifo: uart_tx_fifo (store serial tx data and reformatted into parallel)
+ associative array: cnt_of_status_arr (count number of HIGH logic of individual status bit --- each bit has seperate counter)
+ checkers: to store the fail/pass result of comparing TX_DATA to serial TX and comparing TX_DATA to RX_DATA 

- Main Methods:
+ compare_serial(): compare TX_DATA to serial TX 
+ compare_parallel(): compare TX_DATA to RX_DATA 

**SIMULATION RESULT**

Pass/Fail




Code Coverage




Functional Coverage


