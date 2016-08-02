/////////////////////////////////////////////////////////////////////
//   This file is part of the GOST R34.12-2015 aka «Kuznyechik»    //
//   CryptoCore project                                            //
//   Copyright (c) 2016 Dmitry Murzinov (kakstattakim@gmail.com)   //
/////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns


module tb ();

parameter WIDTH_KEY  = 256;
parameter WIDTH_DATA = 128;

// clock generator settings:
parameter cycles_reset =  2;  // rst active  (clk)
parameter clk_period   = 10;  // clk period ns
parameter clk_delay    =  0;  // clk initial delay

reg clk;    // clock
reg rst;    // sync reset
reg enable;
reg load;

wire ready;

//reg  [WIDTH_KEY-1:0]  key;   // cipher key  input
reg  [WIDTH_DATA-1:0] pdata = 0; // plain  text input
reg  [WIDTH_DATA-1:0] cdata; // cipher text output

reg  [WIDTH_DATA-1:0] reference_data = 0; // reference data for verify

wire EQUAL = (cdata == reference_data);
wire [8*4-1:0] STATUS = EQUAL ? "OK" : "FAIL";

reg [24:0] clk_counter; // just clock counter for debug

reg [WIDTH_DATA-1:0] DATA [0:3];
assign DATA[0] = 128'h64a59400000000000000000000000000;
assign DATA[1] = 128'hd456584dd0e3e84cc3166e4b7fa2890d;
assign DATA[2] = 128'h79d26221b87b584cd42fbc4ffea5de9a;
assign DATA[3] = 128'h0e93691a0cfc60408b7b68f66b513c13;

reg [WIDTH_DATA-1:0] REFERENCE [0:3];
assign REFERENCE[0] = 128'hd456584dd0e3e84cc3166e4b7fa2890d;
assign REFERENCE[1] = 128'h79d26221b87b584cd42fbc4ffea5de9a;
assign REFERENCE[2] = 128'h0e93691a0cfc60408b7b68f66b513c13;
assign REFERENCE[3] = 128'he6a8094fee0aa204fd97bcb0b44b8580;

/*
L(128'h64a59400000000000000000000000000)= 128'hd456584dd0e3e84cc3166e4b7fa2890d;
L(128'hd456584dd0e3e84cc3166e4b7fa2890d)= 128'h79d26221b87b584cd42fbc4ffea5de9a;
L(128'h79d26221b87b584cd42fbc4ffea5de9a)= 128'h0e93691a0cfc60408b7b68f66b513c13;
L(128'h0e93691a0cfc60408b7b68f66b513c13)= 128'he6a8094fee0aa204fd97bcb0b44b8580;

R(128'h00000000000000000000000000000100) = 128'h94000000000000000000000000000001;
R(128'h94000000000000000000000000000001) = 128'ha5940000000000000000000000000000;
R(128'hа5940000000000000000000000000000) = 128'h64а59400000000000000000000000000;
R(128'h64a59400000000000000000000000000) = 128'h0d64a594000000000000000000000000;
*/


L_stage L_stage_u0(
  .clk(clk),
  .enable(enable),
  .load(load),
  .DI(pdata),
  .DO(cdata),
  .ready(ready)
);



// Clock generation
 always begin
 # (clk_delay);
   forever # (clk_period/2) clk = ~clk;
 end

always begin
 @( posedge clk );
    clk_counter <=  clk_counter + 1;
end // always


reg [7:0] k = 8'hzz;

// Initial statement
initial begin
 #0 clk  = 1'b0;
    clk_counter = 0;
    enable = 1;
    load = 0;
  @(posedge clk)
    load = 1;
  @(posedge clk)
  //#(clk_period*2)
    load = 0;

  for (k=0;k<4;k=k+1) begin
    @(posedge clk)
    reference_data = REFERENCE[k];
    pdata = DATA[k];
    load = 1;
    @(posedge clk)
    load = 0;
    //cdata = ...
    @(posedge ready);
    #1 $display("IN: %H \t REFOUT: %H \t OUT: %H  ---> %s", pdata, reference_data, cdata, STATUS);
    @(posedge clk);
  end

  #(clk_period*10);
  $finish;
end


/////////////// dumping
initial
 begin
    $dumpfile("L_stage.vcd");
    $dumpvars(0,tb);
 end

endmodule
// eof









////////////////////// linear operation L
module L_stage
#(parameter    W = 128) // width of inputs
 (input  wire         clk,
  input  wire         enable,
  input  wire         load,
  input  wire [W-1:0] DI,
  output wire [W-1:0] DO,
  output wire         ready
  );

  reg [7:0] x;

  //reg [7:0] b [0:15+1];
  reg [7:0] b [16:0];

  wire gf256_enable;
  wire gf256_load;

  wire  [7:0] gf256_do [0:15];
  wire [15:0] gf256_ready;

  wire ready_int = & gf256_ready;

  assign gf256_enable = enable;
  assign gf256_load   = load;

  reg [3:0] counter;
  always @(posedge clk)
    if (load)
      counter <= {4{1'b1}};
    else if (enable & ready_int)
      counter <= counter - 1;


  genvar k;
  /////////// An LFSR with 16 elements from GF(2^8)
  generate // 16 rounds
    //for (k=0;k<16;k=k+1) begin
    for (k=15;k>=0;k=k-1) begin
      always @(posedge clk)
        if (load)
          b[k] <= DI[8*(k+1)-1:8*k];
        else if (enable & ready_int) begin
          b[k+1] <= b[k];
          b[0] <= x;
        end
        //else if (ready_int)
          //b[0] <= x;

      always @(posedge clk)
        if (load)
          x <= 8'h00;
        else if (enable)
          x <= x ^ gf256_do[k];

      assign DO[8*(k+1)-1:8*k] = b[k];

      mul_gf256
        gf256_u0(
          .clk(clk),
          .enable(gf256_enable),
          .load(gf256_load),
          .data(b[k]),
          .L_vec(L_vec(k)),
          .gf256(gf256_do[k]),
          .ready(gf256_ready[k])
        );

    end
  endgenerate
  ////////////////////////////////////

  assign ready = ~(|counter);

//////// Linear vector from sect 5.1.2
//uint8_t L_vec [0:15] = { 0x94, 0x20, 0x85, 0x10, 0xC2, 0xC0, 0x01, 0xFB, 0x01, 0xC0, 0xC2, 0x10, 0x85, 0x20, 0x94, 0x01};
function [7:0] L_vec( input [3:0] x );
  begin
    case(x)
      4'd00: L_vec = 8'h94;
      4'd01: L_vec = 8'h20;
      4'd02: L_vec = 8'h85;
      4'd03: L_vec = 8'h10;
      4'd04: L_vec = 8'hC2;
      4'd05: L_vec = 8'hC0;
      4'd06: L_vec = 8'h01;
      4'd07: L_vec = 8'hFB;
      4'd08: L_vec = 8'h01;
      4'd09: L_vec = 8'hC0;
      4'd10: L_vec = 8'hC2;
      4'd11: L_vec = 8'h10;
      4'd12: L_vec = 8'h85;
      4'd13: L_vec = 8'h20;
      4'd14: L_vec = 8'h94;
      4'd15: L_vec = 8'h01;
    endcase
  end
endfunction

endmodule
// eof



////////////// poly multiplication mod p(x) = x^8 + x^7 + x^6 + x + 1
module mul_gf256
#(parameter    W = 8) // width of inputs
 (input  wire         clk,
  input  wire         enable,
  input  wire         load,
  input  wire [W-1:0] data,
  input  wire [W-1:0] L_vec,
  output reg  [W-1:0] gf256,
  output reg          ready
  );

  reg [W-1:0] lsfr;
  reg [W-1:0] poly;

  wire null_poly = |poly; // if poly is empty
  //wire null_poly = (poly <= 1); // if poly is empty

  always @(posedge clk) begin
    if (load) begin
      lsfr  <= data;
      poly  <= L_vec;
      gf256 <= 8'h00;
    end
    else if (enable && null_poly) begin
      //lsfr <= {lsfr[6]^lsfr[7],lsfr[5]^lsfr[7],lsfr[4],lsfr[3],lsfr[2],lsfr[1],lsfr[0]^lsfr[7],lsfr[7]};
      lsfr <= (lsfr << 1) ^ (lsfr[7] ? 8'hC3 : 8'h00);
      poly <= poly >> 1;
      if(poly[0])
        gf256 <= gf256 ^ lsfr;
    end
  end

  always @(posedge clk) begin
    if (load)
      ready <= 1'b0;
    else if (!null_poly)
      ready <= 1'b1;
  end

endmodule
// eof
