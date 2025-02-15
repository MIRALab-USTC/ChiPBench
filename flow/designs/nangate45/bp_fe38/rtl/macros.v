module hard_mem_1rw_bit_mask_d64_w96_wrapper(clk_i, reset_i, data_i,
     addr_i, v_i, w_mask_i, w_i, data_o);
  input clk_i, reset_i, v_i, w_i;
  input [95:0] data_i, w_mask_i;
  input [5:0] addr_i;
  output [95:0] data_o;
  wire clk_i, reset_i, v_i, w_i;
  wire [95:0] data_i, w_mask_i;
  wire [5:0] addr_i;
  wire [95:0] data_o;

  fakeram45_64x96 mem (
    .clk      (clk_i   ),
    .rd_out   (data_o  ),
    .ce_in    (1'b1    ),
    .we_in    (w_i     ),
    .w_mask_in(w_mask_i),
    .addr_in  (addr_i  ),
    .wd_in    (data_i  )
  );


endmodule


module hard_mem_1rw_byte_mask_d512_w64_wrapper(
    input wire clk_i,            // Clock
    input wire reset_i,          // Reset
    input wire v_i,              // Valid signal
    input wire w_i,              // Write enable
    input wire [63:0] data_i,    // Data input
    input wire [8:0] addr_i,     // Address input
    input wire [7:0] write_mask_i, // Write mask
    output wire [63:0] data_o    // Data output
);

    // Internal signals
    wire [31:0] data_high, data_low;     // Data split into high and low parts
    wire [31:0] q_low_0, q_low_1;        // Outputs for low and high addresses
    wire [31:0] q_high_0, q_high_1;      // Outputs for high and low addresses
    reg [31:0] q_low, q_high;            // Combined outputs
    wire [7:0] addr_internal;            // Address for each fakeram module
    reg sel_high;                        // Address selector for high/low range

    // Address decomposition
    assign addr_internal = addr_i[7:0];  // Lower 8 bits for 256 rows
    always @(*) begin
        sel_high = addr_i[8];            // High bit selects high/low range
    end

    // Data decomposition
    assign data_low = data_i[31:0];
    assign data_high = data_i[63:32];

    // Instantiate 4 fakeram45_256x32 modules
    fakeram45_256x32 ram_low_0 (
        .clk(clk_i),
        .ce_in(v_i && !sel_high),          // Enable only for low range
        .we_in(w_i),
        .addr_in(addr_internal),
        .wd_in(data_low),
        .w_mask_in({{4{write_mask_i[3]}}, {4{write_mask_i[2]}}, 
                    {4{write_mask_i[1]}}, {4{write_mask_i[0]}}}),
        .rd_out(q_low_0)
    );

    fakeram45_256x32 ram_high_0 (
        .clk(clk_i),
        .ce_in(v_i && sel_high),           // Enable only for high range
        .we_in(w_i),
        .addr_in(addr_internal),
        .wd_in(data_low),
        .w_mask_in({{4{write_mask_i[3]}}, {4{write_mask_i[2]}}, 
                    {4{write_mask_i[1]}}, {4{write_mask_i[0]}}}),
        .rd_out(q_high_0)
    );

    fakeram45_256x32 ram_low_1 (
        .clk(clk_i),
        .ce_in(v_i && !sel_high),          // Enable only for low range
        .we_in(w_i),
        .addr_in(addr_internal),
        .wd_in(data_high),
        .w_mask_in({{4{write_mask_i[7]}}, {4{write_mask_i[6]}}, 
                    {4{write_mask_i[5]}}, {4{write_mask_i[4]}}}),
        .rd_out(q_low_1)
    );

    fakeram45_256x32 ram_high_1 (
        .clk(clk_i),
        .ce_in(v_i && sel_high),           // Enable only for high range
        .we_in(w_i),
        .addr_in(addr_internal),
        .wd_in(data_high),
        .w_mask_in({{4{write_mask_i[7]}}, {4{write_mask_i[6]}}, 
                    {4{write_mask_i[5]}}, {4{write_mask_i[4]}}}),
        .rd_out(q_high_1)
    );

    // Output multiplexer
    always @(*) begin
        if (sel_high) begin
            q_low = q_high_0;
            q_high = q_high_1;
        end else begin
            q_low = q_low_0;
            q_high = q_low_1;
        end
    end

    assign data_o = {q_high, q_low};

endmodule


// module hard_mem_1rw_byte_mask_d512_w64_wrapper(clk_i, reset_i, data_i,
//      addr_i, v_i, write_mask_i, w_i, data_o);
//   input clk_i, reset_i, v_i, w_i;
//   input [63:0] data_i;
//   input [8:0] addr_i;
//   input [7:0] write_mask_i;
//   output [63:0] data_o;
//   wire clk_i, reset_i, v_i, w_i;
//   wire [63:0] data_i;
//   wire [8:0] addr_i;
//   wire [7:0] write_mask_i;
//   wire [63:0] data_o;
//   wire [63:0] wen;

//   fakeram45_512x64 mem (
//     .clk      (clk_i   ),
//     .rd_out   (data_o  ),
//     .ce_in    (1'b1    ),
//     .we_in    (w_i     ),
//     .w_mask_in({{8{write_mask_i[7]}},
//                 {8{write_mask_i[6]}},
//                 {8{write_mask_i[5]}},
//                 {8{write_mask_i[4]}},
//                 {8{write_mask_i[3]}},
//                 {8{write_mask_i[2]}},
//                 {8{write_mask_i[1]}},
//                 {8{write_mask_i[0]}}}
//       ),
//     .addr_in  (addr_i  ),
//     .wd_in    (data_i  )
//   );

// endmodule

module hard_mem_1rw_bit_mask_d64_w7_wrapper(clk_i, reset_i, data_i,
     addr_i, v_i, w_mask_i, w_i, data_o);
  input clk_i, reset_i, v_i, w_i;
  input [6:0] data_i, w_mask_i;
  input [5:0] addr_i;
  output [6:0] data_o;
  wire clk_i, reset_i, v_i, w_i;
  wire [6:0] data_i, w_mask_i;
  wire [5:0] addr_i;
  wire [6:0] data_o;

  fakeram45_64x7 mem (
    .clk      (clk_i   ),
    .rd_out   (data_o  ),
    .ce_in    (1'b1    ),
    .we_in    (w_i     ),
    .w_mask_in(w_mask_i),
    .addr_in  (addr_i  ),
    .wd_in    (data_i  )
  );

endmodule

module hard_mem_1rw_d512_w64_wrapper(clk_i, v_i, reset_i, data_i,
     addr_i, w_i, data_o);
  input clk_i, v_i, reset_i, w_i;
  input [63:0] data_i;
  input [8:0] addr_i;
  output [63:0] data_o;
  wire clk_i, v_i, reset_i, w_i;
  wire [63:0] data_i;
  wire [8:0] addr_i;
  wire [63:0] data_o;

  fakeram45_512x64 mem (
    .clk      (clk_i   ),
    .rd_out   (data_o  ),
    .ce_in    (1'b1    ),
    .we_in    (w_i     ),
    .w_mask_in({64{w_i}}),
    .addr_in  (addr_i  ),
    .wd_in    (data_i  )
  );

endmodule


module bsg_mem_p36
(
  input w_clk_i,         // 写时钟信号
  input w_reset_i,       // 重置信号
  input w_v_i,           // 写使能信号
  input [0:0] w_addr_i,  // 写地址
  input [35:0] w_data_i, // 写数据
  input r_v_i,           // 读使能信号
  input [0:0] r_addr_i,  // 读地址
  output reg [35:0] r_data_o // 读数据
);

  // 内存数组
  reg [35:0] mem [1:0]; // 内存深度为 2，每行 36 位

  // 写逻辑
  always @(posedge w_clk_i) begin
    if (w_reset_i) begin
      // 在复位时清零内存
      mem[0] <= 36'b0;
      mem[1] <= 36'b0;
    end else if (w_v_i) begin
      // 写入数据到指定地址
      mem[w_addr_i] <= w_data_i;
    end
  end

  // 读逻辑
  always @(posedge w_clk_i) begin
    if (r_v_i) begin
      // 从指定地址读取数据
      r_data_o <= mem[r_addr_i];
    end
  end

endmodule

module bsg_mem_p539
(
  input w_clk_i,         // 写时钟信号
  input w_reset_i,       // 重置信号
  input w_v_i,           // 写使能信号
  input [0:0] w_addr_i,  // 写地址
  input [538:0] w_data_i, // 写数据
  input r_v_i,           // 读使能信号
  input [0:0] r_addr_i,  // 读地址
  output reg [538:0] r_data_o // 读数据
);

  // 内存数组
  reg [538:0] mem [1:0]; // 内存深度为 2，每行 36 位

  // 写逻辑
  always @(posedge w_clk_i) begin
    if (w_reset_i) begin
      // 在复位时清零内存
      mem[0] <= 538'b0;
      mem[1] <= 538'b0;
    end else if (w_v_i) begin
      // 写入数据到指定地址
      mem[w_addr_i] <= w_data_i;
    end
  end

  // 读逻辑
  always @(posedge w_clk_i) begin
    if (r_v_i) begin
      // 从指定地址读取数据
      r_data_o <= mem[r_addr_i];
    end
  end

endmodule


module bsg_mem_p540
(
  input w_clk_i,         // 写时钟信号
  input w_reset_i,       // 重置信号
  input w_v_i,           // 写使能信号
  input [0:0] w_addr_i,  // 写地址
  input [539:0] w_data_i, // 写数据
  input r_v_i,           // 读使能信号
  input [0:0] r_addr_i,  // 读地址
  output reg [539:0] r_data_o // 读数据
);

  // 内存数组
  reg [539:0] mem [1:0]; // 内存深度为 2，每行 36 位

  // 写逻辑
  always @(posedge w_clk_i) begin
    if (w_reset_i) begin
      // 在复位时清零内存
      mem[0] <= 539'b0;
      mem[1] <= 539'b0;
    end else if (w_v_i) begin
      // 写入数据到指定地址
      mem[w_addr_i] <= w_data_i;
    end
  end

  // 读逻辑
  always @(posedge w_clk_i) begin
    if (r_v_i) begin
      // 从指定地址读取数据
      r_data_o <= mem[r_addr_i];
    end
  end

endmodule