/////////////////////////////////////////////////////////////////////
//   This file is part of the GOST R34.12-2015 aka «Kuznyechik»    //
//   CryptoCore project                                            //
//   Copyright (c) 2016 Dmitry Murzinov (kakstattakim@gmail.com)   //
/////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns

`include "sbox.vh"

module tb ();

parameter WIDTH_KEY  = 256;
parameter WIDTH_DATA = 128;

// clock generator settings:
parameter cycles_reset =  2;  // rst active  (clk)
parameter clk_period   = 10;  // clk period ns
parameter clk_delay    =  0;  // clk initial delay

reg clk;    // clock
reg rst;    // sync reset

reg  [WIDTH_KEY-1:0]  key;   // cipher key   input
reg  [WIDTH_DATA-1:0] pdata; // plain  text  input
reg  [WIDTH_DATA-1:0] cdata; // cipher text output

reg  [WIDTH_DATA-1:0] pdata_d; //  plain text  input
wire [WIDTH_DATA-1:0] cdata_d; // cipher text output

reg  [WIDTH_DATA-1:0] reference_data; // reference data for verify

wire EQUAL = (cdata == reference_data);
wire [8*4-1:0] STATUS = EQUAL ? "OK" : "FAIL";

reg [24:0] clk_counter; // just clock counter for debug

reg [WIDTH_DATA-1:0] DATA [0:3];
assign DATA[0] = 128'hffeeddccbbaa99881122334455667700;
assign DATA[1] = 128'hb66cd8887d38e8d77765aeea0c9a7efc;
assign DATA[2] = 128'h559d8dd7bd06cbfe7e7b262523280d39;
assign DATA[3] = 128'h0c3322fed531e4630d80ef5c5a81c50b;

reg [WIDTH_DATA-1:0] REFERENCE [0:3];
assign REFERENCE[0] = 128'hb66cd8887d38e8d77765aeea0c9a7efc;
assign REFERENCE[1] = 128'h559d8dd7bd06cbfe7e7b262523280d39;
assign REFERENCE[2] = 128'h0c3322fed531e4630d80ef5c5a81c50b;
assign REFERENCE[3] = 128'h23ae65633f842d29c5df529c13f5acda;

/*
S(128'hffeeddccbbaa99881122334455667700) = 128'hb66cd8887d38e8d77765aeea0c9a7efc
S(128'hb66cd8887d38e8d77765aeea0c9a7efc) = 128'h559d8dd7bd06cbfe7e7b262523280d39
S(128'h559d8dd7bd06cbfe7e7b262523280d39) = 128'h0c3322fed531e4630d80ef5c5a81c50b
S(128'h0c3322fed531e4630d80ef5c5a81c50b) = 128'h23ae65633f842d29c5df529c13f5acda
*/

// Clock generation
 always begin
 # (clk_delay);
   forever # (clk_period/2) clk = ~clk;
 end

always begin
 @( posedge clk );
    clk_counter <=  clk_counter + 1;
end // always


reg [7:0] k;

// Initial statement
initial begin
 #0 clk  = 1'b0;
    clk_counter = 0;

  for (k=0;k<4;k=k+1) begin
    @(posedge clk)
    reference_data = REFERENCE[k];
    pdata = DATA[k];
    cdata = Sbox(pdata);
    #1 $display("IN: %H \t REFOUT: %H \t OUT: %H  ---> %s", pdata, reference_data, cdata, STATUS);
  end

  $finish;
end

/*
// ======= Sbox(x) =======
function [127:0] Sbox( input [127:0] x );
logic [7:0] K [0:15];
integer j;
localparam W = 8;
begin
//generate
  for (j=0;j<16;j=j+1) begin
    K[j] = PI(x[W*j+W-1:W*j]);
    Sbox[W*(j+1)-1:W*j] = K[j];
  end
//endgenerate
end
endfunction
*/
// ======= Sbox(x) =======
function [127:0] Sbox( input [127:0] x );
logic [7:0] K [0:15];
begin

    K[0]  = PI(x[7:0]);
    K[1]  = PI(x[15:8]);
    K[2]  = PI(x[23:16]);
    K[3]  = PI(x[31:24]);
    K[4]  = PI(x[39:32]);
    K[5]  = PI(x[47:40]);
    K[6]  = PI(x[55:48]);
    K[7]  = PI(x[63:56]);
    K[8]  = PI(x[71:64]);
    K[9]  = PI(x[79:72]);
    K[10] = PI(x[87:80]);
    K[11] = PI(x[95:88]);
    K[12] = PI(x[103:96]);
    K[13] = PI(x[111:104]);
    K[14] = PI(x[119:112]);
    K[15] = PI(x[127:120]);

    Sbox = {K[15],K[14],K[13],K[12],K[11],K[10],K[9],K[8],K[7],K[6],K[5],K[4],K[3],K[2],K[1],K[0]};
end
endfunction


/*
/////////////// dumping
initial
 begin
    $dumpfile("S_stage.vcd");
    $dumpvars(0,tb);
 end
*/

endmodule
// eof
