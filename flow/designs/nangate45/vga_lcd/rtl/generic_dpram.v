//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Dual-Port Synchronous RAM                           ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common dual-port               ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  dual-port synchronous RAM.                                  ////
////  It also contains a fully synthesizeable model for FPGAs.    ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Dual-Port Sync RAM                                ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage 2-port Sync RAM                                    ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Generic FPGA (VENDOR_FPGA)                                ////
////    Tested RAMs: Altera, Xilinx                               ////
////    Synthesis tools: LeonardoSpectrum, Synplicity             ////
////  - Xilinx (VENDOR_XILINX)                                    ////
////  - Altera (VENDOR_ALTERA)                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - fix Avant!                                               ////
////   - add additional RAMs (VS etc)                             ////
////                                                              ////
////  Author(s):                                                  ////
////      - Richard Herveille, richard@asics.ws                   ////
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
// $Log: generic_dpram.v,v $
// Revision 1.3  2003/03/18 21:45:48  rherveille
// Added WISHBONE revB.3 Registered Feedback Cycles support
//
// Revision 1.4  2002/09/28 08:18:52  rherveille
// Changed synthesizeable FPGA memory implementation.
// Fixed some issues with Xilinx BlockRAM
//
// Revision 1.3  2001/11/09 00:34:18  samg
// minor changes: unified with all common rams
//
// Revision 1.2  2001/11/08 19:11:31  samg
// added valid checks to behvioral model
//
// Revision 1.1.1.1  2001/09/14 09:57:10  rherveille
// Major cleanup.
// Files are now compliant to Altera & Xilinx memories.
// Memories are now compatible, i.e. drop-in replacements.
// Added synthesizeable generic FPGA description.
// Created "generic_memories" cvs entry.
//
// Revision 1.1.1.2  2001/08/21 13:09:27  damjan
// *** empty log message ***
//
// Revision 1.1  2001/08/20 18:23:20  damjan
// Initial revision
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/30 05:38:02  lampret
// Adding empty directories required by HDL coding guidelines
//
//

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

`define VENDOR_FPGA
//`define VENDOR_XILINX
//`define VENDOR_ALTERA

//module generic_dpram_11_24(
//	rclk, rrst, rce, oe, raddr, do,
//	wclk, wrst, wce, we, waddr, di
//);
//
//	input           rclk;
//	input           rrst;
//	input           rce;
//	input           oe;
//	input  [10:0]   raddr;
//	output [23:0]   do;
//
//	input          wclk;
//	input          wrst;
//	input          wce;
//	input          we;
//	input [10:0]   waddr;
//	input [23:0]   di;
//
//	reg [23:0] mem [2047:0];
//	reg [23:0] do_reg;
//
//	assign do = (oe & rce) ? do_reg : {24{1'bz}};
//
//	always @(posedge rclk)
//		if (rce)
//           		do_reg <= #1 (we && (waddr==raddr)) ? {24{1'bx}} : mem[raddr];
//
//	always @(posedge wclk)
//		if (wce && we)
//			mem[waddr] <= #1 di;
//endmodule

module generic_dpram_11_24(
    // 
    input           rclk,
    input           rrst,
    input           rce,
    input           oe,
    input  [10:0]   raddr,
    output [23:0]   do,
    
    // 
    input           wclk,
    input           wrst,
    input           wce,
    input           we,
    input  [10:0]   waddr,
    input  [23:0]   di
);
    // 
    wire [7:0] di0, di1, di2;
    write_control u_write_control (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce),
        .we(we),
        .waddr(waddr),
        .di(di),
        .di0(di0),
        .di1(di1),
        .di2(di2)
    );
    
    //  Memory Slice Split 
    wire [7:0] do0, do1, do2;
    
    memory_slice_8bit_flatten u_mem_slice0 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce),
        .we(we),
        .waddr(waddr),
        .di(di0),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce),
        .raddr(raddr),
        .do_slice(do0)
    );
    
    memory_slice_8bit_split u_mem_slice1 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce),
        .we(we),
        .waddr(waddr),
        .di(di1),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce),
        .raddr(raddr),
        .do_slice(do1)
    );
    
    memory_slice_8bit_split_2 u_mem_slice2 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce),
        .we(we),
        .waddr(waddr),
        .di(di2),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce),
        .raddr(raddr),
        .do_slice(do2)
    );
    
    // 
    read_control u_read_control (
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce),
        .oe(oe),
        .raddr(raddr),
        .do0(do0),
        .do1(do1),
        .do2(do2),
        .do(do)
    );
    
endmodule

module read_control(
    input          rclk,
    input          rrst,
    input          rce,
    input          oe,
    input  [10:0]  raddr,
    
    //  Memory Slice Split 
    input  [7:0]   do0,
    input  [7:0]   do1,
    input  [7:0]   do2,
    
    // 
    output [23:0]  do
);
    reg [23:0] do_reg;
    
    assign do = (oe & rce) ? do_reg : {24{1'bz}};
    
    always @(posedge rclk) begin
        if (rrst) begin
            do_reg <= 24'b0;
        end else if (rce) begin
            do_reg <= {do2, do1, do0};
        end
    end
endmodule

module write_control(
    input          wclk,
    input          wrst,
    input          wce,
    input          we,
    input  [10:0]  waddr,
    input  [23:0]  di,
    
    // 
    output [7:0]    di0,
    output [7:0]    di1,
    output [7:0]    di2
);
    //  24  3  8 
    assign di0 = di[7:0];
    assign di1 = di[15:8];
    assign di2 = di[23:16];
endmodule

module memory_slice_8bit_flatten(
    // 
    input        wclk,
    input        wrst,
    input        wce,
    input        we,
    input  [10:0] waddr,
    input  [7:0]  di,
    
    // 
    input        rclk,
    input        rrst,
    input        rce,
    input  [10:0] raddr,
    
    // 
    output reg [7:0] do_slice
);
    // 
    reg [7:0] mem [2047:0];
    
    // 
    always @(posedge wclk) begin
        if (wrst) begin
            // 
        end else if (wce && we) begin
            mem[waddr] <= di;
        end
    end
    
    // 
    always @(posedge rclk) begin
        if (rrst) begin
            do_slice <= 8'b0;
        end else if (rce) begin
            do_slice <= mem[raddr];
        end
    end
endmodule

module memory_slice_8bit_split_2(
    input wclk,
    input wrst,
    input wce,
    input we,
    input [10:0] waddr,
    input [7:0] di,
    input rclk,
    input rrst,
    input rce,
    input [10:0] raddr,
    output [7:0] do_slice
);
    wire [2:0] write_sel = waddr[10:8];
    wire [7:0] local_waddr = waddr[7:0];
    wire [2:0] read_sel = raddr[10:8];
    wire [7:0] local_raddr = raddr[7:0];
    wire [7:0] do0, do1, do2, do3, do4, do5, do6, do7;
    memory_block_256x8 u_mem0 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd0)),
        .we(we & (write_sel == 3'd0)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd0)),
        .raddr(local_raddr),
        .do_slice(do0)
    );
    memory_block_256x8 u_mem1 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd1)),
        .we(we & (write_sel == 3'd1)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd1)),
        .raddr(local_raddr),
        .do_slice(do1)
    );
    memory_block_256x8 u_mem2 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd2)),
        .we(we & (write_sel == 3'd2)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd2)),
        .raddr(local_raddr),
        .do_slice(do2)
    );
    memory_block_256x8 u_mem3 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd3)),
        .we(we & (write_sel == 3'd3)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd3)),
        .raddr(local_raddr),
        .do_slice(do3)
    );
    memory_block_256x8 u_mem4 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd4)),
        .we(we & (write_sel == 3'd4)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd4)),
        .raddr(local_raddr),
        .do_slice(do4)
    );
    memory_block_256x8 u_mem5 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd5)),
        .we(we & (write_sel == 3'd5)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd5)),
        .raddr(local_raddr),
        .do_slice(do5)
    );
    memory_block_256x8 u_mem6 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd6)),
        .we(we & (write_sel == 3'd6)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd6)),
        .raddr(local_raddr),
        .do_slice(do6)
    );
    memory_block_256x8 u_mem7 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 3'd7)),
        .we(we & (write_sel == 3'd7)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 3'd7)),
        .raddr(local_raddr),
        .do_slice(do7)
    );
    assign do_slice = (read_sel == 3'd0) ? do0 :
                      (read_sel == 3'd1) ? do1 :
                      (read_sel == 3'd2) ? do2 :
                      (read_sel == 3'd3) ? do3 :
                      (read_sel == 3'd4) ? do4 :
                      (read_sel == 3'd5) ? do5 :
                      (read_sel == 3'd6) ? do6 :
                                           do7;
endmodule

//module memory_block_256x8(
//    input wclk,
//    input wrst,
//    input wce,
//    input we,
//    input [7:0] waddr,
//    input [7:0] di,
//    input rclk,
//    input rrst,
//    input rce,
//    input [7:0] raddr,
//    output reg [7:0] do_slice
//);
//    reg [7:0] mem [255:0];
//    always @(posedge wclk) begin
//        if (wrst) begin
//        end else if (wce && we) begin
//            mem[waddr] <= di;
//        end
//    end
//    always @(posedge rclk) begin
//        if (rrst) begin
//            do_slice <= 8'b0;
//        end else if (rce) begin
//            do_slice <= mem[raddr];
//        end
//    end
//endmodule


module memory_block_256x8(
    input wclk,
    input wrst,
    input wce,
    input we,
    input [7:0] waddr,
    input [7:0] di,
    input rclk,
    input rrst,
    input rce,
    input [7:0] raddr,
    output [7:0] do_slice
);
    wire [1:0] write_sel = waddr[7:6];
    wire [5:0] local_waddr = waddr[5:0];
    wire [1:0] read_sel = raddr[7:6];
    wire [5:0] local_raddr = raddr[5:0];
    wire [7:0] do0, do1, do2, do3;

    memory_block_64x8 u_mem0 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 2'd0)),
        .we(we & (write_sel == 2'd0)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 2'd0)),
        .raddr(local_raddr),
        .do_slice(do0)
    );

    memory_block_64x8 u_mem1 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 2'd1)),
        .we(we & (write_sel == 2'd1)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 2'd1)),
        .raddr(local_raddr),
        .do_slice(do1)
    );

    memory_block_64x8 u_mem2 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 2'd2)),
        .we(we & (write_sel == 2'd2)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 2'd2)),
        .raddr(local_raddr),
        .do_slice(do2)
    );

    memory_block_64x8 u_mem3 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_sel == 2'd3)),
        .we(we & (write_sel == 2'd3)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_sel == 2'd3)),
        .raddr(local_raddr),
        .do_slice(do3)
    );

    assign do_slice = (read_sel == 2'd0) ? do0 :
                      (read_sel == 2'd1) ? do1 :
                      (read_sel == 2'd2) ? do2 :
                                           do3;
endmodule


module memory_slice_8bit_split(
    // 
    input        wclk,
    input        wrst,
    input        wce,
    input        we,
    input  [10:0] waddr,
    input  [7:0]  di,
    
    // 
    input        rclk,
    input        rrst,
    input        rce,
    input  [10:0] raddr,
    
    // 
    output [7:0] do_slice
);
    // 
    wire [1:0] write_select = waddr[10:9];  //  2 
    wire [8:0] local_waddr = waddr[8:0];    //  9 
    
    wire [1:0] read_select = raddr[10:9];
    wire [8:0] local_raddr = raddr[8:0];
    
    // 
    wire [7:0] do0, do1, do2, do3;
    
    // 
    memory_block_512x8_split u_mem0 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_select == 2'b00)),
        .we(we & (write_select == 2'b00)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_select == 2'b00)),
        .raddr(local_raddr),
        .do_slice(do0)
    );
    
    memory_block_512x8_split u_mem1 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_select == 2'b01)),
        .we(we & (write_select == 2'b01)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_select == 2'b01)),
        .raddr(local_raddr),
        .do_slice(do1)
    );
    
    memory_block_512x8_split u_mem2 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_select == 2'b10)),
        .we(we & (write_select == 2'b10)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_select == 2'b10)),
        .raddr(local_raddr),
        .do_slice(do2)
    );
    
    memory_block_512x8_split u_mem3 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce & (write_select == 2'b11)),
        .we(we & (write_select == 2'b11)),
        .waddr(local_waddr),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce & (read_select == 2'b11)),
        .raddr(local_raddr),
        .do_slice(do3)
    );
    
    // 
    assign do_slice = (read_select == 2'b00) ? do0 :
                      (read_select == 2'b01) ? do1 :
                      (read_select == 2'b10) ? do2 :
                      /* (read_select == 2'b11) */ do3;
endmodule

module memory_block_512x8(
    // 
    input        wclk,
    input        wrst,
    input        wce,
    input        we,
    input  [8:0] waddr,  // 9 
    input  [7:0] di,
    
    // 
    input        rclk,
    input        rrst,
    input        rce,
    input  [8:0] raddr,  // 9 
    
    // 
    output reg [7:0] do_slice
);
    // 
    reg [7:0] mem [511:0];
    
    // 
    always @(posedge wclk) begin
        if (wrst) begin
            // ïï
        end else if (wce && we) begin
            mem[waddr] <= di;
        end
    end
    
    // 
    always @(posedge rclk) begin
        if (rrst) begin
            do_slice <= 8'b0;
        end else if (rce) begin
            do_slice <= mem[raddr];
        end
    end
endmodule


// module memory_block_64x8(
//     input wclk,
//     input wrst,
//     input wce,
//     input we,
//     input [5:0] waddr,
//     input [7:0] di,
//     input rclk,
//     input rrst,
//     input rce,
//     input [5:0] raddr,
//     output reg [7:0] do_slice
// );
//     reg [7:0] mem [63:0];
//     always @(posedge wclk) begin
//         if (wrst) begin
//         end else if (wce && we) begin
//             mem[waddr] <= di;
//         end
//     end
//     always @(posedge rclk) begin
//         if (rrst) begin
//             do_slice <= 8'b0;
//         end else if (rce) begin
//             do_slice <= mem[raddr];
//         end
//     end
// endmodule

// module memory_block_128x8(
//     input wclk,
//     input wrst,
//     input wce,
//     input we,
//     input [6:0] waddr,
//     input [7:0] di,
//     input rclk,
//     input rrst,
//     input rce,
//     input [6:0] raddr,
//     output reg [7:0] do_slice
// );
//     reg [7:0] mem [127:0];
//     always @(posedge wclk) begin
//         if (wrst) begin
//         end else if (wce && we) begin
//             mem[waddr] <= di;
//         end
//     end
//     always @(posedge rclk) begin
//         if (rrst) begin
//             do_slice <= 8'b0;
//         end else if (rce) begin
//             do_slice <= mem[raddr];
//         end
//     end
// endmodule

module memory_block_512x8_split(
    input wclk,
    input wrst,
    input wce,
    input we,
    input [8:0] waddr,
    input [7:0] di,
    input rclk,
    input rrst,
    input rce,
    input [8:0] raddr,
    output [7:0] do_slice
);
    wire [2:0] write_sel = waddr[8:6];
    wire [2:0] read_sel = raddr[8:6];
    wire [5:0] write_addr_64_0 = waddr[5:0];
    wire [5:0] write_addr_64_1 = waddr[5:0];
    wire [5:0] write_addr_64_2 = waddr[5:0];
    wire [5:0] write_addr_64_3 = waddr[5:0];
    wire [6:0] write_addr_128_0 = waddr[6:0];
    wire [6:0] write_addr_128_1 = waddr[6:0];
    wire [5:0] read_addr_64_0 = raddr[5:0];
    wire [5:0] read_addr_64_1 = raddr[5:0];
    wire [5:0] read_addr_64_2 = raddr[5:0];
    wire [5:0] read_addr_64_3 = raddr[5:0];
    wire [6:0] read_addr_128_0 = raddr[6:0];
    wire [6:0] read_addr_128_1 = raddr[6:0];
    wire [7:0] do0, do1, do2, do3, do4, do5;
    memory_block_64x8 u_mem0 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && (write_sel == 3'd0)),
        .we(we && (write_sel == 3'd0)),
        .waddr(write_addr_64_0),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && (read_sel == 3'd0)),
        .raddr(read_addr_64_0),
        .do_slice(do0)
    );
    memory_block_64x8 u_mem1 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && (write_sel == 3'd1)),
        .we(we && (write_sel == 3'd1)),
        .waddr(write_addr_64_1),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && (read_sel == 3'd1)),
        .raddr(read_addr_64_1),
        .do_slice(do1)
    );
    memory_block_64x8 u_mem2 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && (write_sel == 3'd2)),
        .we(we && (write_sel == 3'd2)),
        .waddr(write_addr_64_2),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && (read_sel == 3'd2)),
        .raddr(read_addr_64_2),
        .do_slice(do2)
    );
    memory_block_64x8 u_mem3 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && (write_sel == 3'd3)),
        .we(we && (write_sel == 3'd3)),
        .waddr(write_addr_64_3),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && (read_sel == 3'd3)),
        .raddr(read_addr_64_3),
        .do_slice(do3)
    );
    memory_block_128x8 u_mem4 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && (write_sel == 3'd4)),
        .we(we && (write_sel == 3'd4)),
        .waddr(write_addr_128_0),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && (read_sel == 3'd4)),
        .raddr(read_addr_128_0),
        .do_slice(do4)
    );
    memory_block_128x8 u_mem5 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && (write_sel == 3'd5)),
        .we(we && (write_sel == 3'd5)),
        .waddr(write_addr_128_1),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && (read_sel == 3'd5)),
        .raddr(read_addr_128_1),
        .do_slice(do5)
    );
    assign do_slice = (read_sel == 3'd0) ? do0 :
                      (read_sel == 3'd1) ? do1 :
                      (read_sel == 3'd2) ? do2 :
                      (read_sel == 3'd3) ? do3 :
                      (read_sel == 3'd4) ? do4 :
                                           do5;
endmodule






module generic_dpram_9_32(
	// Generic synchronous dual-port RAM interface
	rclk, rrst, rce, oe, raddr, do,
	wclk, wrst, wce, we, waddr, di
);

	//
	// Default address and data buses width
	//
	parameter aw = 9;  // number of bits in address-bus
	parameter dw = 32; // number of bits in data-bus

	//
	// Generic synchronous double-port RAM interface
	//
	// read port
	input           rclk;  // read clock, rising edge trigger
	input           rrst;  // read port reset, active high
	input           rce;   // read port chip enable, active high
	input           oe;	   // output enable, active high
	input  [aw-1:0] raddr; // read address
	output [dw-1:0] do;    // data output

	// write port
	input          wclk;  // write clock, rising edge trigger
	input          wrst;  // write port reset, active high
	input          wce;   // write port chip enable, active high
	input          we;    // write enable, active high
	input [aw-1:0] waddr; // write address
	input [dw-1:0] di;    // data input

	//
	// Module body
	//

	//
	// Generic dual-port synchronous RAM model
	//

	//
	// Generic RAM's registers and wires
	//
	reg	[dw-1:0]	mem [(1<<aw)-1:0]; // RAM content
	reg	[dw-1:0]	do_reg;            // RAM data output register

	//
	// Data output drivers
	//
	assign do = (oe & rce) ? do_reg : {dw{1'bz}};

	// read operation
	always @(posedge rclk)
		if (rce)
          		do_reg <= #1 (we && (waddr==raddr)) ? {dw{1'b x}} : mem[raddr];

	// write operation
	always @(posedge wclk)
		if (wce && we)
			mem[waddr] <= #1 di;


	// Task prints range of memory
	// *** Remember that tasks are non reentrant, don't call this task in parallel for multiple instantiations.
	task print_ram;
	input [aw-1:0] start;
	input [aw-1:0] finish;
	integer rnum;
  	begin
    		for (rnum=start;rnum<=finish;rnum=rnum+1)
      			$display("Addr %h = %h",rnum,mem[rnum]);
  	end
	endtask



endmodule