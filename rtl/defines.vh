//////////////////////////////////////////////////////////////////////
////                                                              ////
////  WISHBONE PWM/Timer/Counter Definitions                      ////
////                                                              ////
////  This file is part of the PTC project                        ////
////  http://www.opencores.org/cores/ptc/                         ////
////                                                              ////
////  Description                                                 ////
////  PTC definitions.                                            ////
////                                                              ////
////  To Do:                                                      ////
////   Nothing                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
//

`define PTC_IMPLEMENTED
`define PTC_READREGS
`define PTCOFS_BITS	3:2
`define RPTC_CNTR	2'h0	// Address 0x0
`define RPTC_HRC	2'h1	// Address 0x4
`define RPTC_LRC	2'h2	// Address 0x8
`define RPTC_CTRL	2'h3	// Address 0xc

`define RPTC_CTRL_EN		0
`define RPTC_CTRL_ECLK		1
`define RPTC_CTRL_NEC		2
`define RPTC_CTRL_OE		3
`define RPTC_CTRL_SINGLE	4
`define RPTC_CTRL_INTE		5
`define RPTC_CTRL_INT		6
`define RPTC_CTRL_CNTRRST	7
`define RPTC_CTRL_CAPTE		8

