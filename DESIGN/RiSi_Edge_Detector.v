//
//rising edge detect
//
module Risi_Edge_Detector(
    input wire clk_i,
    input wire rstn_i,
    input wire sign_i,
    output wire red_o  //
);

    //internal reg
    //
    reg prev_sign_i;
    //
    //output assignment
    assign red_o = ~prev_sign_i & sign_i;
    //
    always @(posedge clk_i, negedge rstn_i) begin
        if(~rstn_i) prev_sign_i <= 1'b0;
        else prev_sign_i <= sign_i;
    end

endmodule
