// Macro: 11x2
// module macro_11x2 (
//     input             clk,    // Clock
//     input             cs,     // Chip Select
//     input             we,     // Write Enable
//     input  [10:0]     addr,   // Address
//     input  [1:0]      di,    // Data In
//     output [1:0]      doq    // Data Out
// );
//   reg [1:0] mem [0:2047];
//   always @(posedge clk) begin
//     if (cs && we) begin
//       mem[addr] <= di;
//     end
//   end
//   assign doq = cs ? mem[addr] : 2'b0;
// endmodule

// // Macro: 9x7
// module macro_9x7 (
//     input            clk,
//     input            cs,
//     input            we,
//     input  [8:0]     addr,
//     input  [6:0]     di,
//     output [6:0]     doq
// );
//   reg [6:0] mem [0:511];
//   always @(posedge clk) begin
//     if (cs && we) begin
//       mem[addr] <= di;
//     end
//   end
//   assign doq = cs ? mem[addr] : 7'b0;
// endmodule

// // Macro: 9x6
// module macro_9x6 (
//     input            clk,
//     input            cs,
//     input            we,
//     input  [8:0]     addr,
//     input  [5:0]     di,
//     output [5:0]     doq
// );
//   reg [5:0] mem [0:511];
//   always @(posedge clk) begin
//     if (cs && we) begin
//       mem[addr] <= di;
//     end
//   end
//   assign doq = cs ? mem[addr] : 6'b0;
// endmodule

// // Macro: 9x3
// module macro_9x3 (
//     input            clk,
//     input            cs,
//     input            we,
//     input  [8:0]     addr,
//     input  [2:0]     di,
//     output [2:0]     doq
// );
//   reg [2:0] mem [0:511];
//   always @(posedge clk) begin
//     if (cs && we) begin
//       mem[addr] <= di;
//     end
//   end
//   assign doq = cs ? mem[addr] : 3'b0;
// endmodule

// // Macro: 6x8
// module macro_6x8 (
//     input           clk,
//     input           cs,
//     input           we,
//     input  [5:0]    addr,
//     input  [7:0]    di,
//     output [7:0]    doq
// );
//   reg [7:0] mem [0:63];
//   always @(posedge clk) begin
//     if (cs && we) begin
//       mem[addr] <= di;
//     end
//   end
//   assign doq = cs ? mem[addr] : 8'b0;
// endmodule

// // Macro: 6x6
// module macro_6x6 (
//     input           clk,
//     input           cs,
//     input           we,
//     input  [5:0]    addr,
//     input  [5:0]    di,
//     output [5:0]    doq
// );
//   reg [5:0] mem [0:63];
//   always @(posedge clk) begin
//     if (cs && we) begin
//       mem[addr] <= di;
//     end
//   end
//   assign doq = cs ? mem[addr] : 6'b0;
// endmodule

// SPRAM: or1200_spram_1 (11x32)
module or1200_spram_1 (
    input            clk,
    input            ce,
    input            we,
    input  [10:0]    addr,
    input  [31:0]    di,
    output [31:0]    doq
);
    wire [1:0] macro_dout [15:0];
    genvar i;
    generate
      for(i=0; i<16; i=i+1) begin : GEN_MACRO_11x2
        macro_11x2 u_macro_11x2 (
          .clk  (clk),
          .cs   (ce),
          .we   (we),
          .addr (addr),
          .di  (di[2*i+1 : 2*i]),
          .doq (macro_dout[i])
        );
      end
    endgenerate
    assign doq = {macro_dout[15], macro_dout[14], macro_dout[13], macro_dout[12],
                   macro_dout[11], macro_dout[10], macro_dout[9], macro_dout[8],
                   macro_dout[7], macro_dout[6], macro_dout[5], macro_dout[4],
                   macro_dout[3], macro_dout[2], macro_dout[1], macro_dout[0]};
endmodule

// SPRAM: or1200_spram_2 (9x20)
module or1200_spram_2 (
    input           clk,
    input           ce,
    input           we,
    input  [8:0]    addr,
    input  [19:0]   di,
    output [19:0]   doq
);
    wire [6:0] dout_7_0, dout_7_1;
    wire [2:0] dout_3_0, dout_3_1;
    macro_9x7 u_macro_9x7_0 (.clk(clk), .cs(ce), .we(we), .addr(addr), .di(di[6:0]), .doq(dout_7_0));
    macro_9x7 u_macro_9x7_1 (.clk(clk), .cs(ce), .we(we), .addr(addr), .di(di[13:7]), .doq(dout_7_1));
    macro_9x3 u_macro_9x3_0 (.clk(clk), .cs(ce), .we(we), .addr(addr), .di(di[16:14]), .doq(dout_3_0));
    macro_9x3 u_macro_9x3_1 (.clk(clk), .cs(ce), .we(we), .addr(addr), .di(di[19:17]), .doq(dout_3_1));
    assign doq = {dout_3_1, dout_3_0, dout_7_1, dout_7_0};
endmodule

// SPRAM: or1200_spram_3 (6x22)
module or1200_spram_3 (
    input          clk,
    input          ce,
    input          we,
    input  [5:0]   addr,
    input  [21:0]  di,
    output [21:0]  doq
);
    wire [7:0] dout8_0, dout8_1;
    wire [5:0] dout6;
    macro_6x8 u_macro_6x8_0 (.clk(clk), .cs(ce), .we(we), .addr(addr), .di(di[7:0]), .doq(dout8_0));
    macro_6x8 u_macro_6x8_1 (.clk(clk), .cs(ce), .we(we), .addr(addr), .di(di[15:8]), .doq(dout8_1));
    macro_6x6 u_macro_6x6 (.clk(clk), .cs(ce), .we(we), .addr(addr), .di(di[21:16]), .doq(dout6));
    assign doq = {dout6, dout8_1, dout8_0};
endmodule

// SPRAM: or1200_spram_4 (9x21)
module or1200_spram_4 (
    input           clk,
    input           ce,
    input           we,
    input  [8:0]    addr,
    input  [20:0]   di,
    output [20:0]   doq
);
    wire [2:0] dout_3 [6:0];
    genvar i;
    generate
      for (i = 0; i < 7; i = i + 1) begin : GEN_9x3
        macro_9x3 u_9x3 (
          .clk (clk),
          .cs  (ce),
          .we  (we),
          .addr(addr),
          .di (di[3*i+2 : 3*i]),
          .doq(dout_3[i])
        );
      end
    endgenerate
    assign doq = {dout_3[6], dout_3[5], dout_3[4], dout_3[3], dout_3[2], dout_3[1], dout_3[0]};
endmodule

// SPRAM: or1200_spram_5 (6x24)
module or1200_spram_5 (
    input          clk,
    input          ce,
    input          we,
    input  [5:0]   addr,
    input  [23:0]  di,
    output [23:0]  doq
);
    wire [5:0] dout6 [3:0];
    genvar i;
    generate
      for (i = 0; i < 4; i = i + 1) begin : GEN_6x6
        macro_6x6 u_6x6 (
          .clk  (clk),
          .cs   (ce),
          .we   (we),
          .addr (addr),
          .di  (di[6*i+5 : 6*i]),
          .doq (dout6[i])
        );
      end
    endgenerate
    assign doq = {dout6[3], dout6[2], dout6[1], dout6[0]};
endmodule



module or1200_spram_1_32_bw
(
    clk, ce, we, addr, di, doq
);

    //
    // Default address and data buses width
    //
    parameter aw = 11;
    parameter dw = 32;

    //
    // Generic synchronous single-port RAM interface
    //
    input wire              clk;    // Clock
    input wire              ce;     // Chip enable input
    input wire [3:0]        we;     // Write enable input
    input wire [10:0]       addr;   // Address bus inputs
    input wire [31:0]       di;     // Input data bus
    output wire [31:0]      doq;    // Output data bus

    // Internal wires for 16-bit RAM modules
    wire [15:0] doq_low, doq_high; // Outputs of low and high RAM modules

    // Instantiation of two fakeram45_256x16 modules
    fakeram45_256x16 ram_low (
        .clk(clk),
        .ce_in(ce),
        .we_in(we[1:0] != 2'b00), // Enable write for low RAM when either byte is written
        .addr_in(addr[10:0]),
        .wd_in(di[15:0]),         // Write lower 16 bits
        .w_mask_in({we[1], we[0]}), // Write mask for lower 16 bits
        .rd_out(doq_low)          // Read output
    );

    fakeram45_256x16 ram_high (
        .clk(clk),
        .ce_in(ce),
        .we_in(we[3:2] != 2'b00), // Enable write for high RAM when either byte is written
        .addr_in(addr[10:0]),
        .wd_in(di[31:16]),        // Write upper 16 bits
        .w_mask_in({we[3], we[2]}), // Write mask for upper 16 bits
        .rd_out(doq_high)         // Read output
    );

    // Combine outputs of the two RAM modules into a 32-bit output
    assign doq = {doq_high, doq_low};

endmodule // or1200_spram_1_32_bw
