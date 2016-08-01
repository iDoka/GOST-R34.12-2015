/////////////////////////////////////////////////////////////////////
//   This file is part of the GOST R34.12-2015 aka «Kuznyechik»    //
//   CryptoCore project                                            //
//   Copyright (c) 2016 Dmitry Murzinov (kakstattakim@gmail.com)   //
/////////////////////////////////////////////////////////////////////

#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
////////////////////
#include <string.h>
#include <stdlib.h>

#include "s-box-parameter.h"

int main(int argc, const char *argv[]) {

  int j;

  // print header
  printf("/////////////////////////////////////////////////////////////////////\n");
  printf("//   This file is part of the GOST R34.12-2015 aka «Kuznyechik»    //\n");
  printf("//   CryptoCore project                                            //\n");
  printf("//   Copyright (c) 2016 Dmitry Murzinov (kakstattakim@gmail.com)   //\n");
  printf("/////////////////////////////////////////////////////////////////////\n\n\n");

  // generate Sbox
  printf("function [7:0] PI( input [7:0] x );\n");
  printf("  begin\n");
  printf("    case(x)\n");
  for ( j = 0; j < 256; j++ ) {
    printf("      8'h%02X: PI = 8'h%02X;\n", j, PI[j]);
  }
  printf("    endcase\n");
  printf("  end\n");
  printf("endfunction\n\n");

  // generate inverse-Sbox
  printf("function [7:0] PI_INV( input [7:0] x );\n");
  printf("  begin\n");
  printf("    case(x)\n");
  for ( j = 0; j < 256; j++ ) {
    printf("      8'h%02X: PI_INV = 8'h%02X;\n", j, PI_INV[j]);
  }
  //printf("      default: PI_INV = 8'hxx;\n");
  printf("    endcase\n");
  printf("  end\n");
  printf("endfunction\n\n");
  printf("//EOF\n");


  return EXIT_SUCCESS;
}

