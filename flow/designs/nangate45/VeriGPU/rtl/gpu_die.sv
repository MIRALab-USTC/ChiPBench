// represents the contents of the GPU die, i.e. contains things like:
// GPU cores
// shared memory
// GPU controller
// global memory controller
//
// for now, the global memory controller also contains global memory, but we will split those
// off from each other

// `default_nettype none
// module gpu_die(
//     input clk,
//     input rst,

//     // comms with mainboard cpu
//     input [31:0] cpu_recv_instr,  
//     // I'm using in/out, because less ambigous than rd/wr I feel, i.e. invariant
//     // with PoV this module, or PoV calling module
//     input [31:0] cpu_in_data,
//     output reg [31:0] cpu_out_data,
//     output reg cpu_out_ack,

//     output reg halt,
//     output reg outflen,
//     output reg outen,
//     output reg [data_width - 1:0] out
// );
//     wire core1_mem_rd_req;
//     wire core1_mem_wr_req;

//     wire [addr_width - 1:0] core1_mem_addr;
//     wire [data_width - 1:0] core1_mem_rd_data;
//     wire [data_width - 1:0] core1_mem_wr_data;

//     wire core1_mem_busy;
//     wire core1_mem_ack;

//     wire contr_mem_wr_en;
//     wire contr_mem_rd_en;
//     wire [addr_width - 1:0] contr_mem_wr_addr;
//     wire [data_width - 1:0] contr_mem_wr_data;
//     wire [addr_width - 1:0] contr_mem_rd_addr;
//     wire [data_width - 1:0] contr_mem_rd_data;
//     wire contr_mem_rd_ack;

//     wire contr_core1_ena;
//     wire contr_core1_clr;
//     wire contr_core1_set_pc_req;
//     wire [data_width - 1:0] contr_core1_set_pc_addr;
//     wire contr_core1_halt;

//     reg core1_halt;

//     global_mem_controller global_mem_controller_(
//         .clk(clk),
//         .rst(rst),
//         // .ena(ena),

//         .core1_addr(core1_mem_addr),
//         .core1_wr_req(core1_mem_wr_req),
//         .core1_rd_req(core1_mem_rd_req),
//         .core1_rd_data(core1_mem_rd_data),
//         .core1_wr_data(core1_mem_wr_data),
//         .core1_busy(core1_mem_busy),
//         .core1_ack(core1_mem_ack),

//         .contr_wr_en(contr_mem_wr_en),
//         .contr_rd_en(contr_mem_rd_en),
//         .contr_wr_addr(contr_mem_wr_addr),
//         .contr_wr_data(contr_mem_wr_data),
//         .contr_rd_addr(contr_mem_rd_addr),
//         .contr_rd_data(contr_mem_rd_data),
//         .contr_rd_ack(contr_mem_rd_ack)

//         // .oob_wr_addr(oob_wr_addr), .oob_wr_data(oob_wr_data),
//         // .oob_wen(oob_wen)

//         // .contr_wr_addr(oob_wr_addr), .contr_wr_data(oob_wr_data),
//         // .contr_wen(oob_wen)
//     );

//     core core1(
//         .rst(rst),
//         .clk(clk),
//         .clr(contr_core1_clr),
//         .ena(contr_core1_ena),
//         .set_pc_req(contr_core1_set_pc_req),
//         .set_pc_addr(contr_core1_set_pc_addr),

//         .outflen(outflen),
//         .out(out),
//         .outen(outen),

//         .halt(contr_core1_halt),

//         .mem_addr(core1_mem_addr),
//         .mem_rd_data(core1_mem_rd_data),
//         .mem_wr_data(core1_mem_wr_data),
//         .mem_ack(core1_mem_ack),
//         .mem_busy(core1_mem_busy),
//         .mem_rd_req(core1_mem_rd_req),
//         .mem_wr_req(core1_mem_wr_req)
//     );

//     gpu_controller gpu_controller_(
//         .rst(rst),
//         .clk(clk),

//         .cpu_recv_instr(cpu_recv_instr),
//         .cpu_in_data(cpu_in_data),
//         .cpu_out_data(cpu_out_data),
//         .cpu_out_ack(cpu_out_ack),

//         .mem_wr_en(contr_mem_wr_en),
//         .mem_rd_en(contr_mem_rd_en),
//         .mem_wr_addr(contr_mem_wr_addr),
//         .mem_wr_data(contr_mem_wr_data),
//         .mem_rd_addr(contr_mem_rd_addr),
//         .mem_rd_data(contr_mem_rd_data),
//         .mem_rd_ack(contr_mem_rd_ack),

//         .core_ena(contr_core1_ena),
//         .core_clr(contr_core1_clr),
//         .core_halt(contr_core1_halt),
//         .core_set_pc_req(contr_core1_set_pc_req),
//         .core_set_pc_addr(contr_core1_set_pc_addr)
//     );
// endmodule
`default_nettype none
module gpu_die (
    input clk,
    input rst,

    // 与主板 CPU 的通信
    input [31:0] cpu_recv_instr,
    input [31:0] cpu_in_data,
    output reg [31:0] cpu_out_data,
    output reg cpu_out_ack,

    output reg halt,
    output reg outflen,
    output reg outen,
    output reg [data_width - 1:0] out
);

    // 核心信号数组
    wire [NUM_CORES-1:0] core_mem_rd_req;
    wire [NUM_CORES-1:0] core_mem_wr_req;
    wire [addr_width-1:0] core_mem_addr [NUM_CORES-1:0];
    wire [data_width-1:0] core_mem_rd_data [NUM_CORES-1:0];
    wire [data_width-1:0] core_mem_wr_data [NUM_CORES-1:0];
    wire [NUM_CORES-1:0] core_mem_busy;
    wire [NUM_CORES-1:0] core_mem_ack;

    wire [NUM_CORES-1:0] core_halt;
    wire [NUM_CORES-1:0] core_ena;
    wire [NUM_CORES-1:0] core_clr;
    wire [NUM_CORES-1:0] core_set_pc_req;
    wire [data_width-1:0] core_set_pc_addr [NUM_CORES-1:0];

    // 仲裁相关变量
    reg [$clog2(NUM_CORES)-1:0] active_core;

    // 全局内存控制器实例
    global_mem_controller global_mem_controller_(
        .clk(clk),
        .rst(rst),

        .core1_addr(core_mem_addr[active_core]),
        .core1_wr_req(core_mem_wr_req[active_core]),
        .core1_rd_req(core_mem_rd_req[active_core]),
        .core1_rd_data(core_mem_rd_data[active_core]),
        .core1_wr_data(core_mem_wr_data[active_core]),
        .core1_busy(core_mem_busy[active_core]),
        .core1_ack(core_mem_ack[active_core])
    );

    // 仲裁逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_core <= 0;
        end else begin
            if (!core_mem_busy[active_core]) begin
                active_core <= (active_core + 1) % NUM_CORES;
            end
        end
    end

    // 核心实例生成
    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i = i + 1) begin : core_array
            core_cell core_inst (
                .rst(rst),
                .clk(clk),
                .clr(core_clr[i]),
                .ena(core_ena[i]),
                .set_pc_req(core_set_pc_req[i]),
                .set_pc_addr(core_set_pc_addr[i]),

                .outflen(outflen), // 所有核心共享同一输出信号
                .out(out),
                .outen(outen),

                .halt(core_halt[i]),

                .mem_addr(core_mem_addr[i]),
                .mem_rd_data(core_mem_rd_data[i]),
                .mem_wr_data(core_mem_wr_data[i]),
                .mem_ack(core_mem_ack[i]),
                .mem_busy(core_mem_busy[i]),
                .mem_rd_req(core_mem_rd_req[i]),
                .mem_wr_req(core_mem_wr_req[i])
            );
        end
    endgenerate

        // core_cell core_inst_cell (
        //     .rst(rst),
        //     .clk(clk),
        //     .clr(core_clr[NUM_CORES-1]),
        //     .ena(core_ena[NUM_CORES-1]),
        //     .set_pc_req(core_set_pc_req[NUM_CORES-1]),
        //     .set_pc_addr(core_set_pc_addr[NUM_CORES-1]),

        //     .outflen(outflen), // 所有核心共享同一输出信号
        //     .out(out),
        //     .outen(outen),

        //     .halt(core_halt[NUM_CORES-1]),

        //     .mem_addr(core_mem_addr[NUM_CORES-1]),
        //     .mem_rd_data(core_mem_rd_data[NUM_CORES-1]),
        //     .mem_wr_data(core_mem_wr_data[NUM_CORES-1]),
        //     .mem_ack(core_mem_ack[NUM_CORES-1]),
        //     .mem_busy(core_mem_busy[NUM_CORES-1]),
        //     .mem_rd_req(core_mem_rd_req[NUM_CORES-1]),
        //     .mem_wr_req(core_mem_wr_req[NUM_CORES-1])
        // );


    // GPU 控制器实例
    gpu_controller gpu_controller_(
        .rst(rst),
        .clk(clk),

        .cpu_recv_instr(cpu_recv_instr),
        .cpu_in_data(cpu_in_data),
        .cpu_out_data(cpu_out_data),
        .cpu_out_ack(cpu_out_ack),

        .mem_wr_en(core_mem_wr_req[active_core]),
        .mem_rd_en(core_mem_rd_req[active_core]),
        .mem_wr_addr(core_mem_addr[active_core]),
        .mem_wr_data(core_mem_wr_data[active_core]),
        .mem_rd_addr(core_mem_addr[active_core]),
        .mem_rd_data(core_mem_rd_data[active_core]),
        .mem_rd_ack(core_mem_ack[active_core]),

        .core_ena(core_ena[active_core]),
        .core_clr(core_clr[active_core]),
        .core_halt(core_halt[active_core]),
        .core_set_pc_req(core_set_pc_req[active_core]),
        .core_set_pc_addr(core_set_pc_addr[active_core])
    );

    // 整合核心输出信号（例如 halt 信号）
    always @(*) begin
        halt = |core_halt; // 如果任何一个核心发出 halt 信号，则整体 halt
    end

endmodule
