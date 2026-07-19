//===============================================================
//Project: Design and Verify APB UART IP
//File: apb_checker.sv
//Author: Nguyen Ngoc Man
//Description: this module is used for checking APB VIP
//===============================================================
module apb_checker();
    logic pclk;
    logic presetn;
    logic [`SLAVE_CNT-1:0]psel;
    logic penable;
    logic pwrite;
    logic [`APB_AW-1:0] paddr;
    logic [`APB_DW-1:0] pwdata;
    logic [`APB_DW/8-1:0] pstrb;
    logic [`SLAVE_CNT-1:0][`APB_DW-1:0] prdata;
    logic [`SLAVE_CNT-1:0] pready;
    logic [`SLAVE_CNT-1:0] pslverr;
    //
    parameter INST_NAME_0 = "APB_PROTOCOL_CHECKER";
    parameter INST_NAME_1 = "APB_WARNING";
    parameter INST_NAME_2 = "APB_ERROR";
    //
    always@(posedge pclk) begin
      if(|psel && penable && presetn) begin
        case (pwrite)
        1'bx: $display("[%s][%s][%0t ns] PWRITE is x\n", INST_NAME_0, INST_NAME_1, $time);
        1'bz: $display("[%s][%s][%0t ns] PWRITE is z\n", INST_NAME_0, INST_NAME_1, $time);
        endcase 
        //
        case (|paddr)
        1'bx: $display("[%s][%s][%0t ns] PADDR is x\n", INST_NAME_0, INST_NAME_1, $time);
        1'bz: $display("[%s][%s][%0t ns] PADDR is z\n", INST_NAME_0, INST_NAME_1, $time);
        endcase 
        //
        case (|pwdata)
        1'bx: $display("[%s][%s][%0t ns] PWDATA is x\n", INST_NAME_0, INST_NAME_1, $time);
        1'bz: $display("[%s][%s][%0t ns] PWDATA is z\n", INST_NAME_0, INST_NAME_1, $time);
        endcase 
        //
        `ifdef SUPPORT_BE
        case (|pstrb)
        1'bx: $display("[%s][%s][%0t ns] PSTRB is x\n", INST_NAME_0, INST_NAME_1, $time);
        1'bz: $display("[%s][%s][%0t ns] PSTRB is z\n", INST_NAME_0, INST_NAME_1, $time);
        endcase 
        `endif
        //
        for (integer i = 0; i < `SLAVE_CNT; i = i+1) begin
            case (|prdata[i])
            1'bx: $display("[%s][%s][%0t ns] PRDATA is x\n", INST_NAME_0, INST_NAME_1, $time);
            1'bz: $display("[%s][%s][%0t ns] PRDATA is z\n", INST_NAME_0, INST_NAME_1, $time);
            endcase 
        end
        //
        case (|pready)
        1'bx: $display("[%s][%s][%0t ns] PREADY is x\n", INST_NAME_0, INST_NAME_2, $time);
        1'bz: $display("[%s][%s][%0t ns] PREADY is z\n", INST_NAME_0, INST_NAME_2, $time);
        endcase 
        //
        case (|pslverr)
        1'bx: $display("[%s][%s][%0t ns] PSLVERR is x\n", INST_NAME_0, INST_NAME_1, $time);
        1'bz: $display("[%s][%s][%0t ns] PSLVERR is z\n", INST_NAME_0, INST_NAME_1, $time);
        endcase 
      end //end of if
    end
endmodule
