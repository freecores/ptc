//////////////////////////////////////////////////////////////////////
////                                                              ////
////  WISHBONE PWM/Timer/Counter                                  ////
////                                                              ////
////  This file is part of the PTC project                        ////
////  http://www.opencores.org/cores/ptc/                         ////
////                                                              ////
////  Description                                                 ////
////  Implementation of PWM/Timer/Counter IP core according to    ////
////  PTC IP core specification document.                         ////
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
// Revision 1.1  2001/06/05 07:45:36  lampret
// Added initial RTL and test benches. There are still some issues with these files.
//
//

// synopsys translate_off
`include "timescale.vh"
// synopsys translate_on
`include "defines.vh"

module ptc(
	// WISHBONE Interface
	clk_i, rst_i, cyc_i, adr_i, dat_i, sel_i, we_i, stb_i,
	dat_o, ack_o, err_o, inta_o,

	// External PTC Interface
	ptc_ecgt, ptc_capt, ptc_pwm, ptc_oen
);

parameter dw = 32;
parameter aw = `PTC_ADDRHH+1;
parameter cw = `PTC_CW;

//
// WISHBONE Interface
//
input			clk_i;	// Clock
input			rst_i;	// Reset
input			cyc_i;	// cycle valid input
input 	[aw-1:0]	adr_i;	// address bus inputs
input	[dw-1:0]	dat_i;	// input data bus
input	[3:0]		sel_i;	// byte select inputs
input			we_i;	// indicates write transfer
input			stb_i;	// strobe input
output	[dw-1:0]	dat_o;	// output data bus
output			ack_o;	// normal termination
output			err_o;	// termination w/ error
output			inta_o;	// Interrupt request output

//
// External PTC Interface
//
input		ptc_ecgt;	// EClk/Gate input
input		ptc_capt;	// Capture input
output		ptc_pwm;	// PWM output
output		ptc_oen;	// PWM output driver enable

`ifdef PTC_IMPLEMENTED

//
// PTC Main Counter Register (or no register)
//
`ifdef RPTC_CNTR
reg	[cw-1:0]	rptc_cntr;	// RPTC_CNTR register
`else
wire	[cw-1:0]	rptc_cntr;	// No RPTC_CNTR register
`endif

//
// PTC HI Reference/Capture Register (or no register)
//
`ifdef RPTC_HRC
reg	[cw-1:0]	rptc_hrc;	// RPTC_HRC register
`else
wire	[cw-1:0]	rptc_hrc;	// No RPTC_HRC register
`endif

//
// PTC LO Reference/Capture Register (or no register)
//
`ifdef RPTC_LRC
reg	[cw-1:0]	rptc_lrc;	// RPTC_LRC register
`else
wire	[cw-1:0]	rptc_lrc;	// No RPTC_LRC register
`endif

//
// PTC Control Register (or no register)
//
`ifdef RPTC_CTRL
reg	[8:0]		rptc_ctrl;	// RPTC_CTRL register
`else
wire	[8:0]		rptc_ctrl;	// No RPTC_CTRL register
`endif

//
// Internal wires & regs
//
wire			rptc_cntr_sel;	// RPTC_CNTR select
wire			rptc_hrc_sel;	// RPTC_HRC select
wire			rptc_lrc_sel;	// RPTC_LRC select
wire			rptc_ctrl_sel;	// RPTC_CTRL select
wire			hrc_match;	// RPTC_HRC matches RPTC_CNTR
wire			lrc_match;	// RPTC_LRC matches RPTC_CNTR
wire			restart;	// Restart counter when asserted
wire			stop;		// Stop counter when asserted
wire			cntr_clk;	// Counter clock
wire			cntr_rst;	// Counter reset
wire			hrc_clk;	// RPTC_HRC clock
wire			lrc_clk;	// RPTC_LRC clock
wire			eclk_gate;	// ptc_ecgt xored by RPTC_CTRL[NEC]
wire			gate;		// Gate function of ptc_ecgt
wire			pwm_rst;	// Reset of a PWM output
reg	[dw-1:0]	dat_o;		// Data out
reg			ptc_pwm;	// PWM output
reg			int;		// Interrupt reg
wire			int_match;	// Interrupt match
wire			full_decoding;	// Full address decoding qualification

//
// All WISHBONE transfer terminations are successful except when:
// a) full address decoding is enabled and address doesn't match
//    any of the PTC registers
// b) sel_i evaluation is enabled and one of the sel_i inputs is zero
//
assign ack_o = cyc_i & stb_i & !err_o;
`ifdef FULL_DECODE
`ifdef STRICT_32BIT_ACCESS
assign err_o = cyc_i & stb_i & !full_decoding | (sel_i != 4'b1111);
`else
assign err_o = cyc_i & stb_i & !full_decoding;
`endif
`else
`ifdef STRICT_32BIT_ACCESS
assign err_o = (sel_i != 4'b1111);
`else
assign err_o = 1'b0;
`endif
`endif

//
// Counter clock is selected by RPTC_CTRL[ECLK]. When it is set,
// external clock is used.
//
assign cntr_clk = rptc_ctrl[`RPTC_CTRL_ECLK] ? eclk_gate : clk_i;

//
// Counter reset
//
assign cntr_rst = rst_i | restart;

//
// HRC clock is selected by RPTC_CTRL[CAPTE]. When it is set,
// ptc_capt is used as a clock.
//
assign hrc_clk = rptc_ctrl[`RPTC_CTRL_CAPTE] ? ptc_capt : clk_i;

//
// LRC clock is selected by RPTC_CTRL[CAPTE]. When it is set,
// inverted ptc_capt is used as a clock.
//
assign lrc_clk = rptc_ctrl[`RPTC_CTRL_CAPTE] ? ~ptc_capt : clk_i;

//
// PWM output driver enable is inverted RPTC_CTRL[OE]
//
assign ptc_oen = ~rptc_ctrl[`RPTC_CTRL_OE];

//
// Use RPTC_CTRL[NEC]
//
assign eclk_gate = ptc_ecgt ^ rptc_ctrl[`RPTC_CTRL_NEC];

//
// Gate function is active when RPTC_CTRL[ECLK] is cleared
//
assign gate = eclk_gate & ~rptc_ctrl[`RPTC_CTRL_ECLK];

//
// Full address decoder
//
`ifdef FULL_DECODE
assign full_decoding = (adr_i[`PTC_ADDRHH:`PTC_ADDRHL] == {`PTC_ADDRHH-`PTC_ADDRHL+1{1'b0}}) &
			(adr_i[`PTC_ADDRLH:`PTC_ADDRLL] == {`PTC_ADDRLH-`PTC_ADDRLL+1{1'b0}});
`else
assign full_decoding = 1'b1;
`endif

//
// PTC registers address decoder
//
assign rptc_cntr_sel = cyc_i & stb_i & (adr_i[`PTCOFS_BITS] == `RPTC_CNTR) & full_decoding;
assign rptc_hrc_sel = cyc_i & stb_i & (adr_i[`PTCOFS_BITS] == `RPTC_HRC) & full_decoding;
assign rptc_lrc_sel = cyc_i & stb_i & (adr_i[`PTCOFS_BITS] == `RPTC_LRC) & full_decoding;
assign rptc_ctrl_sel = cyc_i & stb_i & (adr_i[`PTCOFS_BITS] == `RPTC_CTRL) & full_decoding;

//
// Write to RPTC_CTRL or update of RPTC_CTRL[INT] bit
//
`ifdef RPTC_CTRL
always @(posedge clk_i or posedge rst_i)
	if (rst_i)
		rptc_ctrl <= #1 9'b0;
	else if (rptc_ctrl_sel && we_i)
		rptc_ctrl <= #1 dat_i[8:0];
	else if (rptc_ctrl[`RPTC_CTRL_INTE])
		rptc_ctrl[`RPTC_CTRL_INT] <= #1 rptc_ctrl[`RPTC_CTRL_INT] | int;
`else
assign rptc_ctrl = `DEF_RPTC_CTRL;
`endif

//
// Write to RPTC_HRC
//
`ifdef RPTC_HRC
always @(posedge hrc_clk or posedge rst_i)
	if (rst_i)
		rptc_hrc <= #1 {cw{1'b0}};
	else if (rptc_hrc_sel && we_i)
		rptc_hrc <= #1 dat_i[cw-1:0];
	else if (rptc_ctrl[`RPTC_CTRL_CAPTE])
		rptc_hrc <= #1 rptc_cntr;
`else
assign rptc_hrc = `DEF_RPTC_HRC;
`endif

//
// Write to RPTC_LRC
//
`ifdef RPTC_LRC
always @(posedge lrc_clk or posedge rst_i)
	if (rst_i)
		rptc_lrc <= #1 {cw{1'b0}};
	else if (rptc_lrc_sel && we_i)
		rptc_lrc <= #1 dat_i[cw-1:0];
	else if (rptc_ctrl[`RPTC_CTRL_CAPTE])
		rptc_lrc <= #1 rptc_cntr;
`else
assign rptc_lrc = `DEF_RPTC_LRC;
`endif

//
// Write to or increment of RPTC_CNTR
//
`ifdef RPTC_CNTR
always @(posedge cntr_clk or posedge cntr_rst)
	if (cntr_rst)
		rptc_cntr <= #1 {cw{1'b0}};
	else if (rptc_cntr_sel && we_i)
		rptc_cntr <= #1 dat_i[cw-1:0];
	else if (!stop && rptc_ctrl[`RPTC_CTRL_EN] && !gate)
		rptc_cntr <= #1 rptc_cntr + 1;
`else
assign rptc_cntr = `DEF_RPTC_CNTR;
`endif

//
// Read PTC registers
//
always @(adr_i or rptc_hrc or rptc_lrc or rptc_ctrl or rptc_cntr)
	case (adr_i[`PTCOFS_BITS])	// synopsys full_case parallel_case
`ifdef PTC_READREGS
		`RPTC_HRC: dat_o[dw-1:0] <= {{dw-cw{1'b0}}, rptc_hrc};
		`RPTC_LRC: dat_o[dw-1:0] <= {{dw-cw{1'b0}}, rptc_lrc};
		`RPTC_CTRL: dat_o[dw-1:0] <= {{dw-9{1'b0}}, rptc_ctrl};
`endif
		default: dat_o[dw-1:0] <= {{dw-cw{1'b0}}, rptc_cntr};
	endcase

//
// A match when RPTC_HRC is equal to RPTC_CNTR
//
assign hrc_match = rptc_ctrl[`RPTC_CTRL_EN] & (rptc_cntr == rptc_hrc);

//
// A match when RPTC_LRC is equal to RPTC_CNTR
//
assign lrc_match = rptc_ctrl[`RPTC_CTRL_EN] & (rptc_cntr == rptc_lrc);

//
// Restart counter when lrc_match asserted and RPTC_CTRL[SINGLE] cleared
// or when RPTC_CTRL[CNTRRST] is set
//
assign restart = lrc_match & ~rptc_ctrl[`RPTC_CTRL_SINGLE]
	| rptc_ctrl[`RPTC_CTRL_CNTRRST];

//
// Stop counter when lrc_match and RPTC_CTRL[SINGLE] both asserted
//
assign stop = lrc_match & rptc_ctrl[`RPTC_CTRL_SINGLE];

//
// PWM reset when lrc_match or system reset
//
assign pwm_rst = lrc_match | rst_i;

//
// PWM output
//
always @(posedge clk_i)	// posedge pwm_rst or posedge hrc_match
	if (pwm_rst)
		ptc_pwm <= #1 1'b0;
	else if (hrc_match)
		ptc_pwm <= #1 1'b1;

//
// Generate an interrupt request
//
assign int_match = (lrc_match | hrc_match) & rptc_ctrl[`RPTC_CTRL_INTE];

// Register interrupt request
always @(posedge int_match or posedge clk_i)
	if (int_match)
		int <= #1 1'b1;
	else
		int <= #1 1'b0;

//
// Alias
//
assign inta_o = rptc_ctrl[`RPTC_CTRL_INT];

`else

//
// When PTC is not implemented, drive all outputs as would when RPTC_CTRL
// is cleared and WISHBONE transfers complete with errors
//
assign inta_o = 1'b0;
assign ack_o = 1'b0;
assign err_o = cyc_i & stb_i;
assign ptc_pwm = 1'b0;
assign ptc_oen = 1'b1;

//
// Read PTC registers
//
`ifdef PTC_READREGS
assign dat_o = {dw{1'b0}};
`endif

`endif

endmodule
