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


module hard_mem_1rw_byte_mask_d512_w64_wrapper(clk_i, reset_i, data_i,
     addr_i, v_i, write_mask_i, w_i, data_o);
  input clk_i, reset_i, v_i, w_i;
  input [63:0] data_i;
  input [8:0] addr_i;
  input [7:0] write_mask_i;
  output [63:0] data_o;
  wire clk_i, reset_i, v_i, w_i;
  wire [63:0] data_i;
  wire [8:0] addr_i;
  wire [7:0] write_mask_i;
  wire [63:0] data_o;
  wire [63:0] wen;

  fakeram45_512x64 mem (
    .clk      (clk_i   ),
    .rd_out   (data_o  ),
    .ce_in    (1'b1    ),
    .we_in    (w_i     ),
    .w_mask_in({{8{write_mask_i[7]}},
                {8{write_mask_i[6]}},
                {8{write_mask_i[5]}},
                {8{write_mask_i[4]}},
                {8{write_mask_i[3]}},
                {8{write_mask_i[2]}},
                {8{write_mask_i[1]}},
                {8{write_mask_i[0]}}}
      ),
    .addr_in  (addr_i  ),
    .wd_in    (data_i  )
  );

endmodule



module hard_mem_1rw_bit_mask_d64_w15_wrapper (
  input clk_i,             // 时钟信号
  input reset_i,           // 复位信号
  input v_i,               // 有效信号，控制读/写
  input w_i,               // 写使能信号
  input [14:0] data_i,     // 写数据输入
  input [5:0] addr_i,      // 地址信号，支持 64 个地址
  input [14:0] w_mask_i,   // 写掩码信号，每位控制相应数据位是否写入
  output reg [14:0] data_o // 读数据输出
);

  // 定义 64x15 的存储阵列
  reg [14:0] mem [63:0];

  // 同步读写逻辑
  always @(posedge clk_i) begin
    if (reset_i) begin
      // 在复位时清零存储器
      integer i;
      for (i = 0; i < 64; i = i + 1) begin
        mem[i] <= 15'b0;
      end
      data_o <= 15'b0;
    end else if (v_i) begin
      if (w_i) begin
        // 写操作，结合写掩码
        mem[addr_i] <= (mem[addr_i] & ~w_mask_i) | (data_i & w_mask_i);
      end else begin
        // 读操作
        data_o <= mem[addr_i];
      end
    end
  end

endmodule



// module hard_mem_1rw_bit_mask_d64_w15_wrapper(clk_i, reset_i, data_i,
//      addr_i, v_i, w_mask_i, w_i, data_o);
//   input clk_i, reset_i, v_i, w_i;
//   input [14:0] data_i, w_mask_i;
//   input [5:0] addr_i;
//   output [14:0] data_o;
//   wire clk_i, reset_i, v_i, w_i;
//   wire [14:0] data_i, w_mask_i;
//   wire [5:0] addr_i;
//   wire [14:0] data_o;

//   fakeram45_64x15 mem (
//     .clk      (clk_i   ),
//     .rd_out   (data_o  ),
//     .ce_in    (1'b1    ),
//     .we_in    (w_i     ),
//     .w_mask_in(w_mask_i),
//     .addr_in  (addr_i  ),
//     .wd_in    (data_i  )
//   );

// endmodule