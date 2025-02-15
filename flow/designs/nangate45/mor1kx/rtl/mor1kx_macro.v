/********** 1) Macro: spram_8x4 **********/
// module spram_8x4 (
//     input              clk,
//     input      [2:0]   raddr,  
//     input              re,
//     input      [2:0]   waddr,
//     input              we,
//     input      [3:0]   din,
//     output reg [3:0]   dout
// );
//     reg [3:0] mem [0:7];
//     always @(posedge clk) begin
//         if (we) mem[waddr] <= din;
//         if (re) dout <= mem[raddr];
//     end
// endmodule

// /********** 2) Macro: spram_8x8 **********/
// module spram_8x8 (
//     input              clk,
//     input      [2:0]   raddr,
//     input              re,
//     input      [2:0]   waddr,
//     input              we,
//     input      [7:0]   din,
//     output reg [7:0]   dout
// );
//     reg [7:0] mem [0:7];
//     always @(posedge clk) begin
//         if (we) mem[waddr] <= din;
//         if (re) dout <= mem[raddr];
//     end
// endmodule

// /********** 3) Macro: spram_8x16 **********/
// module spram_8x16 (
//     input               clk,
//     input      [2:0]    raddr,
//     input               re,
//     input      [2:0]    waddr,
//     input               we,
//     input      [15:0]   din,
//     output reg [15:0]   dout
// );
//     reg [15:0] mem [0:7];
//     always @(posedge clk) begin
//         if (we) mem[waddr] <= din;
//         if (re) dout <= mem[raddr];
//     end
// endmodule

// /********** 4) Macro: spram_9x4 **********/
// module spram_9x4 (
//     input               clk,
//     input      [3:0]    raddr, // 0~8
//     input               re,
//     input      [3:0]    waddr,
//     input               we,
//     input      [3:0]    din,
//     output reg [3:0]    dout
// );
//     reg [3:0] mem [0:8];
//     always @(posedge clk) begin
//         if (we && waddr < 9) mem[waddr] <= din;
//         if (re && raddr < 9) dout <= mem[raddr];
//     end
// endmodule

// /********** 5) Macro: spram_9x8 **********/
// module spram_9x8 (
//     input               clk,
//     input      [3:0]    raddr,
//     input               re,
//     input      [3:0]    waddr,
//     input               we,
//     input      [7:0]    din,
//     output reg [7:0]    dout
// );
//     reg [7:0] mem [0:8];
//     always @(posedge clk) begin
//         if (we && waddr < 9) mem[waddr] <= din;
//         if (re && raddr < 9) dout <= mem[raddr];
//     end
// endmodule

// /********** 6) Macro: spram_12x4 **********/
// module spram_12x4 (
//     input               clk,
//     input      [11:0]   raddr, // 0~11
//     input               re,
//     input      [11:0]   waddr,
//     input               we,
//     input      [3:0]    din,
//     output reg [3:0]    dout
// );
//     reg [3:0] mem [0:11];
//     always @(posedge clk) begin
//         if (we && waddr < 12) mem[waddr] <= din;
//         if (re && raddr < 12) dout <= mem[raddr];
//     end
// endmodule

// /********** 7) Macro: spram_12x8 **********/
// module spram_12x8 (
//     input               clk,
//     input      [11:0]   raddr,
//     input               re,
//     input      [11:0]   waddr,
//     input               we,
//     input      [7:0]    din,
//     output reg [7:0]    dout
// );
//     reg [7:0] mem [0:11];
//     always @(posedge clk) begin
//         if (we && waddr < 12) mem[waddr] <= din;
//         if (re && raddr < 12) dout <= mem[raddr];
//     end
// endmodule

/************************************************************/
/**********   6  SPRAM   **********/
/************************************************************/

/* 
 * : mor1kx_simple_dpram_sclk_1 : 12x32
 * : 7 spram_12x4 (28bit) + 1 spram_12x8 (8bit)ï36bitï4bit
 */
module mor1kx_simple_dpram_sclk_1
(
    input                       clk,
    input      [11:0]          raddr,
    input                       re,
    input      [11:0]          waddr,
    input                       we,
    input      [31:0]          din,
    output     [31:0]          dout
);

    //  36bit  :
    //   partA = 28bit ( 7 spram_12x4 )
    //   partB = 8bit  ( 1 spram_12x8 )
    wire [27:0] partA_dout;
    wire [7:0]  partB_dout;

    // 
    wire [27:0] partA_din = din[27:0];
    wire [7:0]  partB_din = din[31:24];  // 8partB

    // partA7ï4 bit
    genvar i;
    generate
        for (i = 0; i < 7; i=i+1) begin : GEN_12X4
            spram_12x4 u_12x4 (
                .clk   (clk),
                .raddr (raddr),
                .re    (re),
                .waddr (waddr),
                .we    (we),
                .din   (partA_din[i*4 +: 4]),
                .dout  (partA_dout[i*4 +: 4])
            );
        end
    endgenerate

    // partB: 12x8
    spram_12x8 u_12x8 (
        .clk   (clk),
        .raddr (raddr),
        .re    (re),
        .waddr (waddr),
        .we    (we),
        .din   (partB_din),
        .dout  (partB_dout)
    );

    // 
    // dout[27:0]  partA_dout
    // dout[31:28]  partB_dout[3:0]?  dout[31:24]
    // ï
    assign dout = { partB_dout, partA_dout[23:0] };

endmodule

/* 
 *  mor1kx_simple_dpram_sclk_1 : mor1kx_simple_dpram_sclk_5 : 12x32
 */
module mor1kx_simple_dpram_sclk_5
(
    input                       clk,
    input      [11:0]          raddr,
    input                       re,
    input      [11:0]          waddr,
    input                       we,
    input      [31:0]          din,
    output     [31:0]          dout
);

    wire [27:0] partA_dout;
    wire [7:0]  partB_dout;
    wire [27:0] partA_din = din[27:0];
    wire [7:0]  partB_din = din[31:24];

    genvar i;
    generate
        for (i = 0; i < 7; i=i+1) begin : GEN_12X4
            spram_12x4 u_12x4 (
                .clk   (clk),
                .raddr (raddr),
                .re    (re),
                .waddr (waddr),
                .we    (we),
                .din   (partA_din[i*4 +: 4]),
                .dout  (partA_dout[i*4 +: 4])
            );
        end
    endgenerate

    spram_12x8 u_12x8 (
        .clk   (clk),
        .raddr (raddr),
        .re    (re),
        .waddr (waddr),
        .we    (we),
        .din   (partB_din),
        .dout  (partB_dout)
    );

    assign dout = { partB_dout, partA_dout[23:0] };

endmodule

/*
 * mor1kx_simple_dpram_sclk_2 : 8x101
 * : 
 *   - 1 spram_8x16 => 16bit
 *   - 1 spram_8x8  =>  8bit
 *   - 21 spram_8x4 => 84bit
 *  108bit,  7bit, 23
 */
module mor1kx_simple_dpram_sclk_2
(
    input                     clk,
    input      [7:0]         raddr,
    input                     re,
    input      [7:0]         waddr,
    input                     we,
    input      [100:0]       din,
    output     [100:0]       dout
);

    // : 
    //   partA_16 (18x16)
    //   partB_8  (18x8)
    //   partC_84 (218x4)

    // 
    wire [15:0] partA_16_dout;
    wire [7:0]  partB_8_dout;
    wire [83:0] partC_84_dout;

    // 
    wire [15:0] partA_16_din = din[15:0];
    wire [7:0]  partB_8_din  = din[23:16];
    wire [83:0] partC_84_din = din[100:24]; //  77bit? 

    // (ïï)
    //  din[100:24] => 77bitï
    // ï

    // 1) spram_8x16
    spram_8x16 u_8x16 (
        .clk   (clk),
        .raddr (raddr[2:0]),  // 83bit
        .re    (re),
        .waddr (waddr[2:0]),
        .we    (we),
        .din   (partA_16_din),
        .dout  (partA_16_dout)
    );

    // 2) spram_8x8
    spram_8x8 u_8x8 (
        .clk   (clk),
        .raddr (raddr[2:0]),
        .re    (re),
        .waddr (waddr[2:0]),
        .we    (we),
        .din   (partB_8_din),
        .dout  (partB_8_dout)
    );

    // 3) spram_8x4 (21)
    wire [21*4-1:0] c_din_bus  = partC_84_din;  // 84bit
    wire [21*4-1:0] c_dout_bus;

    genvar i;
    generate
        for(i=0; i<21; i=i+1) begin : GEN_8X4
            spram_8x4 u_8x4 (
                .clk   (clk),
                .raddr (raddr[2:0]),
                .re    (re),
                .waddr (waddr[2:0]),
                .we    (we),
                .din   (c_din_bus[i*4 +: 4]),
                .dout  (c_dout_bus[i*4 +: 4])
            );
        end
    endgenerate

    //  ()
    assign partC_84_dout = c_dout_bus;
    assign dout = {
        //  partC_84_dout  dout[100:17] (84bit)
        partC_84_dout,
        // partB_8_dout => dout[16:9] (8bit)
        partB_8_dout,
        // partA_16_dout => dout[8:0]  9bit? ï
        partA_16_dout[8:0]  
    };

endmodule

/*
 * mor1kx_simple_dpram_sclk_3/4/6 : 9x39
 * :  9x39 
 *   - spram_9x4 8 => 32bit
 *   - spram_9x8 1 => 8bit
 * 40bit, 1bit, 9
 */

/* mor1kx_simple_dpram_sclk_3 */
module mor1kx_simple_dpram_sclk_3
(
    input                     clk,
    input      [8:0]         raddr, // 0~38
    input                     re,
    input      [8:0]         waddr,
    input                     we,
    input      [38:0]        din,
    output     [38:0]        dout
);

    wire [31:0] partA_32_dout;
    wire [7:0]  partB_8_dout;

    wire [31:0] partA_32_din = din[31:0];
    wire [7:0]  partB_8_din  = din[38:31]; 

    // spram_9x4 x 8
    genvar i;
    generate
        for(i=0; i<8; i=i+1) begin : GEN_9X4
            wire [3:0] slice_din  = partA_32_din[i*4 +: 4];
            wire [3:0] slice_dout;
            spram_9x4 u_9x4(
                .clk   (clk),
                .raddr (raddr[3:0]),
                .re    (re),
                .waddr (waddr[3:0]),
                .we    (we),
                .din   (slice_din),
                .dout  (slice_dout)
            );
            assign partA_32_dout[i*4 +: 4] = slice_dout;
        end
    endgenerate

    // spram_9x8 x 1
    spram_9x8 u_9x8 (
        .clk   (clk),
        .raddr (raddr[3:0]),
        .re    (re),
        .waddr (waddr[3:0]),
        .we    (we),
        .din   (partB_8_din),
        .dout  (partB_8_dout)
    );

    // ()
    assign dout = { partB_8_dout[7:0], partA_32_dout[31:0] };

endmodule

/* mor1kx_simple_dpram_sclk_4 : 9x39,  */
module mor1kx_simple_dpram_sclk_4
(
    input                     clk,
    input      [8:0]         raddr,
    input                     re,
    input      [8:0]         waddr,
    input                     we,
    input      [38:0]        din,
    output     [38:0]        dout
);

    // ï
    // ï _3 
    // ...
    // ï
    wire [31:0] partA_32_dout;
    wire [7:0]  partB_8_dout;
    wire [31:0] partA_32_din = din[31:0];
    wire [7:0]  partB_8_din  = din[38:31]; 

    genvar i;
    generate
        for(i=0; i<8; i=i+1) begin : GEN_9X4
            wire [3:0] slice_din  = partA_32_din[i*4 +: 4];
            wire [3:0] slice_dout;
            spram_9x4 u_9x4(
                .clk   (clk),
                .raddr (raddr[3:0]),
                .re    (re),
                .waddr (waddr[3:0]),
                .we    (we),
                .din   (slice_din),
                .dout  (slice_dout)
            );
            assign partA_32_dout[i*4 +: 4] = slice_dout;
        end
    endgenerate

    spram_9x8 u_9x8 (
        .clk   (clk),
        .raddr (raddr[3:0]),
        .re    (re),
        .waddr (waddr[3:0]),
        .we    (we),
        .din   (partB_8_din),
        .dout  (partB_8_dout)
    );

    assign dout = { partB_8_dout, partA_32_dout };
endmodule

/* mor1kx_simple_dpram_sclk_6 : 9x39,  */
module mor1kx_simple_dpram_sclk_6
(
    input                     clk,
    input      [8:0]         raddr,
    input                     re,
    input      [8:0]         waddr,
    input                     we,
    input      [38:0]        din,
    output     [38:0]        dout
);
    //  _3,_4 ï
    wire [31:0] partA_32_dout;
    wire [7:0]  partB_8_dout;
    wire [31:0] partA_32_din = din[31:0];
    wire [7:0]  partB_8_din  = din[38:31]; 

    genvar i;
    generate
        for(i=0; i<8; i=i+1) begin : GEN_9X4
            wire [3:0] slice_din  = partA_32_din[i*4 +: 4];
            wire [3:0] slice_dout;
            spram_9x4 u_9x4(
                .clk   (clk),
                .raddr (raddr[3:0]),
                .re    (re),
                .waddr (waddr[3:0]),
                .we    (we),
                .din   (slice_din),
                .dout  (slice_dout)
            );
            assign partA_32_dout[i*4 +: 4] = slice_dout;
        end
    endgenerate

    spram_9x8 u_9x8 (
        .clk   (clk),
        .raddr (raddr[3:0]),
        .re    (re),
        .waddr (waddr[3:0]),
        .we    (we),
        .din   (partB_8_din),
        .dout  (partB_8_dout)
    );

    assign dout = { partB_8_dout, partA_32_dout };
endmodule

