//==================================================================================
//Project: Design UART IP
//File name: apb_if.sv
//Description:
//--TB  
//--uart_interface
//==================================================================================
//
//CRITICAL NOTE: use s_drv_cb and m_drv_cb at the same time (without `ifdef
//`elsif `endif) causes WARNING: pready, prdata are multiply driven 
//
interface apb_if(input bit pclk);
parameter DW = 32;
parameter APB_AW = 32;
   //
logic presetn;
logic [`AGENT_CNT-1:0] psel;
logic penable;
logic pwrite;
logic [2:0] pprot;
logic [3:0] pstrb;
logic [APB_AW-1:0] paddr;
logic [DW-1:0] pwdata;
logic [`AGENT_CNT-1:0][DW-1:0] prdata;
logic [`AGENT_CNT-1:0] pready;
logic [`AGENT_CNT-1:0] pslverr;
logic  pready_i;
logic [DW-1:0] rdata_i;
logic wr_en_o;
logic rd_en_o;
logic [DW-1:0] wdata_o;
logic [APB_AW-1:0] addr_o;

  //********************************************************
  //------------------clocking block
  //********************************************************
  //slave role
  `ifdef APB_SLAVE
  clocking s_drv_cb @(posedge pclk);
      input presetn, psel, penable, pwrite, pstrb, paddr, pwdata, pprot;
      output prdata, pready, pslverr;
  endclocking
`elsif APB_MASTER
  //master role
  clocking m_drv_cb @(posedge pclk);
      output presetn, psel, penable, pwrite, pstrb, paddr, pwdata, pprot;
      input prdata, pready, pslverr;
  endclocking
  `endif

  //monitor blocking block
  clocking mon_cb @(posedge pclk);
      input psel, penable, pwrite, paddr, pwdata, pstrb, prdata, pready, pslverr, pprot,
	      rdata_i, wr_en_o, rd_en_o, wdata_o, addr_o;
  endclocking
  //********************************************************
  //------------------mod port
  //********************************************************
  modport drv_mp(clocking m_drv_cb);
  modport mon_mp(clocking mon_cb);
//
  //Open file for logging
  //
  `ifdef PRINT_TO_APB_SVA_FILE
  integer apb_log_fh;
  initial begin
   apb_log_fh = $fopen("../TB/SVA_CHECK/sva_log.log", "a");
    if (apb_log_fh == 0) begin
      $display("ERROR: Could not open sva_log.log!!!");
    end
  end
  `endif
  // =====================================
  // SVA Protocol Checks
  // =====================================
  genvar i;
    generate;
    for(i = 0; i < `AGENT_CNT; i++) begin : apb_slave_checks
      //(1)
      property psel_onehot;
        @(posedge pclk) disable iff (!presetn)
          $onehot0(psel);
      endproperty
      assert property (psel_onehot)
      else begin
        `ifdef PRINT_TO_APB_SVA_FILE
        $fdisplay(apb_log_fh, "PSEL_SVA: multiple slaves selected at the same time!!! Value = %0b @time=%0t ns", psel, $time);
        `else
        $error("PSEL_SVA: multiple slaves selected at the same time!!! Value = %0b", psel);
        `endif
      end
      //reset all signals
      //DEFINE
      property reset_all_signals;
        @(posedge pclk) disable iff (!presetn)
        (presetn == 0) |=> (psel == 0 && penable == 0 && paddr == 0);
      endproperty
      //DO
      assert property (reset_all_signals)
      else begin
        `ifdef PRINT_TO_APB_SVA_FILE
        $fdisplay(apb_log_fh, "[RESEL_ALL_SIGNALS]: all APB signals are not properly reset!!! @time=%0t ns", $time);
        `else
        $error("[RESEL_ALL_SIGNALS]: all APB signals are not properly reset!!!");
        `endif
      end
      //
      //(2)
      // access_phase: if psel[i] and !penable, then penable must go high next cycle
      property access_phase;
        @(posedge pclk) disable iff (!presetn)
          (psel[i] && !penable) |=> penable;
      endproperty
      assert property(access_phase)
      else begin
        `ifdef PRINT_TO_APB_SVA_FILE
        $fdisplay(apb_log_fh, $sformatf("APB_SVA[%0d]: penable not asserted in ACCESS phase @time=%0t ns", i, $time));
        `else
        $error("APB[%0d]: penable not asserted in ACCESS phase", i);
        `endif
      end
      //
      //(3)
      // Transfer Completion only when pready[i] is asserted
      //DEFINE
      property complete_with_pready;
        @(posedge pclk) disable iff (!presetn)
          (psel[i] && penable && ~pready[i]) |=> penable;
      endproperty
      //DO
      assert property(complete_with_pready)
      else begin
        `ifdef PRINT_TO_APB_SVA_FILE
        $fdisplay(apb_log_fh, $sformatf("APB_SVA[%0d]: Transfer ended without pready @time=%0t ns", i, $time));
        `else
        $error("APB_SVA[%0d]: Transfer ended without pready", i);
        `endif
      end
      //
      //(4)
      //
      //DEFINE
      property penable_deassert;
        @(posedge pclk) disable iff (!presetn)
          (psel[i] && penable && pready[i]) |=> !penable;
      endproperty
      //DO
      assert property(penable_deassert)
      else begin
        `ifdef PRINT_TO_APB_SVA_FILE
        $fdisplay(apb_log_fh, $sformatf("APB_SVA[%0d]: Penable also ASSERT as pready is high @time=%0t ns", i, $time));
        `else
        $error("APB[%0d]: Penable also ASSERT as pready is high", i);
        `endif
      end
    end
  endgenerate
  
  //
  //close file
  //
  `ifdef PRINT_TO_APB_SVA_FILE
  final begin
    if(apb_log_fh == 1) begin
     $fclose(apb_log_fh);
    end
  end
  `endif
endinterface
