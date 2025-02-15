//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Single-Port Synchronous RAM                         ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common single-port             ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides a behavioral model of generic    ////
////  single-port synchronous RAM.                                ////
////  It also contains a synthesizeable model for FPGAs.          ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Single-Port Sync RAM                              ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage Single-Port Sync RAM                               ////
////  - Virtual Silicon Single-Port Sync RAM                      ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Generic FPGA (VENDOR_FPGA)                                ////
////    Tested RAMs: Altera, Xilinx                               ////
////    Synthesis tools: LeonardoSpectrum, Synplicity             ////
////  - Xilinx (VENDOR_XILINX)                                    ////
////  - Altera (VENDOR_ALTERA)                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - fix avant! two-port ram                                  ////
////   - add additional RAMs                                      ////
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
// $Log: generic_spram.v,v $
// Revision 1.3  2003/03/18 21:45:48  rherveille
// Added WISHBONE revB.3 Registered Feedback Cycles support
//
//
//

`include "timescale.v"


module generic_spram(
	// Generic synchronous single-port RAM interface
	clk, rst, ce, we, oe, addr, di, do
);

	//
	// Default address and data buses width
	//
	parameter aw = 6; //number of address-bits
	parameter dw = 8; //number of data-bits

	//
	// Generic synchronous single-port RAM interface
	//
	input           clk;  // Clock, rising edge
	input           rst;  // Reset, active high
	input           ce;   // Chip enable input, active high
	input           we;   // Write enable input, active high
	input           oe;   // Output enable input, active high
	input  [aw-1:0] addr; // address bus inputs
	input  [dw-1:0] di;   // input data bus
	output [dw-1:0] do;   // output data bus

	//
	// Module body
	//

	//
	// Instantiation synthesizeable FPGA memory
	//
	// This code has been tested using LeonardoSpectrum and Synplicity.
	// The code correctly instantiates Altera EABs and Xilinx BlockRAMs.
	//

	// NOTE:
	// 'synthesis syn_ramstyle="block_ram"' is a Synplify attribute.
	// It instructs Synplify to map to BlockRAMs instead of the default SelectRAMs

	reg [dw-1:0] mem [(1<<aw) -1:0] /* synthesis syn_ramstyle="block_ram" */;
	reg [aw-1:0] ra;

	// read operation
	always @(posedge clk)
	  if (ce)
	    ra <= #1 addr;     // read address needs to be registered to read clock

	assign #1 do = mem[ra];

	// write operation
	always @(posedge clk)
	  if (we && ce)
	    mem[addr] <= #1 di;

endmodule



module generic_spram_9_24(
    input         clk,
    input         rst,
    input         ce,
    input         we,
    input         oe,
    input  [8:0]  addr,
    input  [23:0] di,
    output [23:0] do
);

    // 顶层的地址寄存，用于同步输出数据
    reg [8:0] ra;
    always @(posedge clk) begin
        if (rst)
            ra <= 9'd0;
        else if (ce)
            ra <= addr;
    end

    wire [23:0] do_lo;  // 下半256x24块输出
    wire [23:0] do_hi;  // 上半256x24块输出

    wire we_lo = we & ce & (addr[8] == 1'b0);
    wire we_hi = we & ce & (addr[8] == 1'b1);

    // 下半区 256x24 直接模块实例
    spram_256x24_direct u_spram_256x24_direct(
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .we(we_lo),
        .oe(oe),
        .addr(addr[7:0]),
        .di(di),
        .do(do_lo)
    );

    // 上半区 256x24 由子模块组合而成
    spram_256x24_composed u_spram_256x24_composed(
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .we(we_hi),
        .oe(oe),
        .addr(addr[7:0]),
        .di(di),
        .do(do_hi)
    );

    // 根据存的ra的高位选择输出
    assign do = (ra[8] == 1'b0) ? do_lo : do_hi;

endmodule


module spram_256x24_direct(
    input         clk,
    input         rst,
    input         ce,
    input         we,
    input         oe,
    input  [7:0]  addr,
    input  [23:0] di,
    output [23:0] do
);

    reg [23:0] mem [255:0];
    reg [7:0]  ra;

    always @(posedge clk) begin
        if (rst)
            ra <= 8'd0;
        else if (ce)
            ra <= addr;
    end

    assign do = mem[ra];

    always @(posedge clk) begin
        if (we && ce)
            mem[addr] <= di;
    end

endmodule

module spram_256x24_composed(
    input         clk,
    input         rst,
    input         ce,
    input         we,
    input         oe,
    input  [7:0]  addr,
    input  [23:0] di,
    output [23:0] do
);

    reg [7:0] ra;
    always @(posedge clk) begin
        if (rst)
            ra <= 8'd0;
        else if (ce)
            ra <= addr;
    end

    // 根据地址划分选择子模块
    wire sel_64_1   = (addr < 8'd64);
    wire sel_64_2   = (addr >= 8'd64  && addr < 8'd128);
    wire sel_128_1  = (addr >= 8'd128 && addr < 8'd256);

    // 写使能分配
    wire we_64_1   = we & ce & sel_64_1;
    wire we_64_2   = we & ce & sel_64_2;
    wire we_128_1  = we & ce & sel_128_1;

    // 子模块地址映射
    wire [5:0] addr_64_1  = addr[5:0];             // 0~63
    wire [5:0] addr_64_2  = addr[5:0];             // 64~127中的后6位地址对应0~63
    wire [6:0] addr_128_1 = addr[6:0];             // 128~255中的后7位地址对应0~127

    wire [23:0] do_64_1;
    wire [23:0] do_64_2;
    wire [23:0] do_128_1;

    memory_block_64x24 u_memory_block_64x24_1(
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .we(we_64_1),
        .oe(oe),
        .addr(addr_64_1),
        .di(di),
        .do(do_64_1)
    );

    memory_block_64x24 u_memory_block_64x24_2(
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .we(we_64_2),
        .oe(oe),
        .addr(addr_64_2),
        .di(di),
        .do(do_64_2)
    );

    spram_128x24 u_spram_128x24_1(
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .we(we_128_1),
        .oe(oe),
        .addr(addr_128_1),
        .di(di),
        .do(do_128_1)
    );

    // 读出时根据存储的ra选择最终输出
    reg [23:0] do_reg;
    always @(*) begin
        if (ra < 8'd64)
            do_reg = do_64_1;
        else if (ra < 8'd128)
            do_reg = do_64_2;
        else
            do_reg = do_128_1;
    end

    assign do = do_reg;

endmodule


// module memory_block_64x24(
//     input         clk,
//     input         rst,
//     input         ce,
//     input         we,
//     input         oe,
//     input  [5:0]  addr,
//     input  [23:0] di,
//     output [23:0] do
// );

//     reg [23:0] mem[63:0];
//     reg [5:0] ra;

//     always @(posedge clk) begin
//         if (rst)
//             ra <= 6'd0;
//         else if (ce)
//             ra <= addr;
//     end

//     assign do = mem[ra];

//     always @(posedge clk) begin
//         if (we && ce)
//             mem[addr] <= di;
//     end

// endmodule

module spram_128x24(
    input          clk,
    input          rst,
    input          ce,
    input          we,
    input          oe,
    input   [6:0]  addr,
    input   [23:0] di,
    output  [23:0] do
);
    wire [7:0] do_slice0, do_slice1, do_slice2;

    // 实例化3个128x8的内存模块
    memory_block_128x8 mem_block0 (
        .wclk(clk),
        .wrst(rst),
        .wce(ce),
        .we(we),
        .waddr(addr),
        .di(di[7:0]),
        .rclk(clk),
        .rrst(rst),
        .rce(ce),
        .raddr(addr),
        .do_slice(do_slice0)
    );

    memory_block_128x8 mem_block1 (
        .wclk(clk),
        .wrst(rst),
        .wce(ce),
        .we(we),
        .waddr(addr),
        .di(di[15:8]),
        .rclk(clk),
        .rrst(rst),
        .rce(ce),
        .raddr(addr),
        .do_slice(do_slice1)
    );

    memory_block_128x8_flatten mem_block2 (
        .wclk(clk),
        .wrst(rst),
        .wce(ce),
        .we(we),
        .waddr(addr),
        .di(di[23:16]),
        .rclk(clk),
        .rrst(rst),
        .rce(ce),
        .raddr(addr),
        .do_slice(do_slice2)
    );

    // 合并3个模块的输出数据
    assign do = {do_slice2, do_slice1, do_slice0};

endmodule


module memory_block_128x8_flatten(
    input wclk,
    input wrst,
    input wce,
    input we,
    input [6:0] waddr,
    input [7:0] di,
    input rclk,
    input rrst,
    input rce,
    input [6:0] raddr,
    output [7:0] do_slice
);
    wire [7:0] do_slice_0, do_slice_1;
    wire select_write = waddr[6];
    wire select_read = raddr[6];

    memory_block_64x8 mem_block_0 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && ~select_write),
        .we(we),
        .waddr(waddr[5:0]),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && ~select_read),
        .raddr(raddr[5:0]),
        .do_slice(do_slice_0)
    );

    memory_block_64x8 mem_block_1 (
        .wclk(wclk),
        .wrst(wrst),
        .wce(wce && select_write),
        .we(we),
        .waddr(waddr[5:0]),
        .di(di),
        .rclk(rclk),
        .rrst(rrst),
        .rce(rce && select_read),
        .raddr(raddr[5:0]),
        .do_slice(do_slice_1)
    );

    assign do_slice = select_read ? do_slice_1 : do_slice_0;
endmodule



// Top module
module generic_spram_11_24(
    clk, rst, ce, we, oe, addr, di, do
);

    input           clk;
    input           rst;
    input           ce;
    input           we;
    input           oe;
    input  [10:0]   addr;
    input  [23:0]   di;
    output [23:0]   do;

    wire [10:0] ra_wire;
    wire [23:0] mem_data_out;

    // Submodule for address latch
    addr_latch addr_latch_inst(
        .clk(clk),
        .ce(ce),
        .addr_in(addr),
        .addr_out(ra_wire)
    );

    // Submodules for smaller memory blocks
    wire [23:0] mem_block_data_out[3:0];

    memory_subblock_flatten memory_block_0(
        .clk(clk),
        .ce(ce),
        .we(we),
        .addr(addr[8:0]),
        .data_in(di),
        .data_out(mem_block_data_out[0])
    );

    memory_subblock_flatten memory_block_1(
        .clk(clk),
        .ce(ce),
        .we(we),
        .addr(addr[8:0]),
        .data_in(di),
        .data_out(mem_block_data_out[1])
    );

    memory_subblock memory_block_2(
        .clk(clk),
        .ce(ce),
        .we(we),
        .addr(addr[8:0]),
        .data_in(di),
        .data_out(mem_block_data_out[2])
    );

    memory_subblock memory_block_3(
        .clk(clk),
        .ce(ce),
        .we(we),
        .addr(addr[8:0]),
        .data_in(di),
        .data_out(mem_block_data_out[3])
    );

    // Multiplexer to select the appropriate memory block output
    memory_mux memory_mux_inst(
        .block_select(addr[10:9]),
        .data_in({mem_block_data_out[3], mem_block_data_out[2], mem_block_data_out[1], mem_block_data_out[0]}),
        .data_out(mem_data_out)
    );

    // Submodule for output latch
    output_latch output_latch_inst(
        .data_in(mem_data_out),
        .data_out(do)
    );

endmodule





// Address latch module
module addr_latch(
    clk, ce, addr_in, addr_out
);
    input          clk;
    input          ce;
    input  [10:0]  addr_in;
    output [10:0]  addr_out;
    reg    [10:0]  addr_out;

    always @(posedge clk) begin
        if (ce)
            addr_out <= #1 addr_in;
    end

endmodule

// Memory subblock module
module memory_subblock(
    clk, ce, we, addr, data_in, data_out
);
    input          clk;
    input          ce;
    input          we;
    input  [8:0]   addr;
    input  [23:0]  data_in;
    output [23:0]  data_out;
    reg    [23:0]  mem [511:0] /* synthesis syn_ramstyle="block_ram" */;
    reg    [23:0]  data_out;

    always @(posedge clk) begin
        if (we && ce)
            mem[addr] <= #1 data_in;
        if (ce)
            data_out <= #1 mem[addr];
    end

endmodule

module memory_subblock_flatten(
    clk, ce, we, addr, data_in, data_out
);
    input          clk;
    input          ce;
    input          we;
    input  [8:0]   addr;
    input  [23:0]  data_in;
    output [23:0]  data_out;
    reg    [23:0]  mem [511:0] /* synthesis syn_ramstyle="block_ram" */;
    reg    [23:0]  data_out;

    always @(posedge clk) begin
        if (we && ce)
            mem[addr] <= #1 data_in;
        if (ce)
            data_out <= #1 mem[addr];
    end

endmodule

          
// Memory multiplexer module
module memory_mux(
    block_select, data_in, data_out
);
    input [1:0] block_select;
    input [95:0] data_in;
    output [23:0] data_out;

    // Instantiate submodules for processing smaller parts of data_in
    wire [7:0] data_out_part1, data_out_part2, data_out_part3;

    memory_mux_part mux_part1 (
        .block_select(block_select),
        .data_in(data_in[31:0]),
        .data_out(data_out_part1)
    );

    memory_mux_part mux_part2 (
        .block_select(block_select),
        .data_in(data_in[63:32]),
        .data_out(data_out_part2)
    );

    memory_mux_part mux_part3 (
        .block_select(block_select),
        .data_in(data_in[95:64]),
        .data_out(data_out_part3)
    );

    // Combine outputs of smaller modules
    assign data_out = {data_out_part3, data_out_part2, data_out_part1};

endmodule

// Smaller mux module (handles 8 bits at a time)
module memory_mux_part(
    block_select, data_in, data_out
);
    input [1:0] block_select;
    input [31:0] data_in;
    output [7:0] data_out;

    wire [7:0] mux_low, mux_high;

    memory_mux_small mux_small_low (
        .block_select(block_select[0]),
        .data_in(data_in[15:0]),
        .data_out(mux_low)
    );

    memory_mux_small mux_small_high (
        .block_select(block_select[0]),
        .data_in(data_in[31:16]),
        .data_out(mux_high)
    );

    // Combine low and high results based on block_select MSB
    assign data_out = (block_select[1] == 1'b0) ? mux_low : mux_high;

endmodule

// Even smaller mux module (handles 8 bits at a time, splits into 4:1 mux)
module memory_mux_small(
    block_select, data_in, data_out
);
    input block_select;
    input [15:0] data_in;
    output [7:0] data_out;
    reg [7:0] data_out;

    always @(*) begin
        case (block_select)
            1'b0: data_out = data_in[7:0];
            1'b1: data_out = data_in[15:8];
            default: data_out = 8'd0;
        endcase
    end

endmodule

// Output latch module
module output_latch(
    data_in, data_out
);
    input  [23:0] data_in;
    output [23:0] data_out;
    assign #1 data_out = data_in;

endmodule




module generic_spram_9_32(
	// Generic synchronous single-port RAM interface
	clk, rst, ce, we, oe, addr, di, do
);

	//
	// Default address and data buses width
	//
	parameter aw = 9; //number of address-bits
	parameter dw = 32; //number of data-bits

	//
	// Generic synchronous single-port RAM interface
	//
	input           clk;  // Clock, rising edge
	input           rst;  // Reset, active high
	input           ce;   // Chip enable input, active high
	input           we;   // Write enable input, active high
	input           oe;   // Output enable input, active high
	input  [aw-1:0] addr; // address bus inputs
	input  [dw-1:0] di;   // input data bus
	output [dw-1:0] do;   // output data bus

	//
	// Module body
	//

	//
	// Instantiation synthesizeable FPGA memory
	//
	// This code has been tested using LeonardoSpectrum and Synplicity.
	// The code correctly instantiates Altera EABs and Xilinx BlockRAMs.
	//

	// NOTE:
	// 'synthesis syn_ramstyle="block_ram"' is a Synplify attribute.
	// It instructs Synplify to map to BlockRAMs instead of the default SelectRAMs

	reg [dw-1:0] mem [(1<<aw) -1:0] /* synthesis syn_ramstyle="block_ram" */;
	reg [aw-1:0] ra;

	// read operation
	always @(posedge clk)
	  if (ce)
	    ra <= #1 addr;     // read address needs to be registered to read clock

	assign #1 do = mem[ra];

	// write operation
	always @(posedge clk)
	  if (we && ce)
	    mem[addr] <= #1 di;

endmodule