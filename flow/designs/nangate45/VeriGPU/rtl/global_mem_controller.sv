// represents GPU global memory
// we add in simulated delay

// `timescale 1ns/10ps
// parameter mem_simulated_delay = 5;
// parameter memory_size = 512;
// module global_mem_controller (
//     input clk,
//     input rst,
//     // input ena,  // enables incoming requests to be processed. whilst this is low, incoming requests are stored
//                 // (only a single request can be stored), and once this goes high, it will be processed
//                 // this lets us turn off reset, load in our program into memory, then turn on enable
//                 // and the processor starts running

//     input core1_rd_req,
//     input core1_wr_req,

//     input [addr_width - 1:0]      core1_addr,
//     output reg [data_width - 1:0] core1_rd_data,
//     input [data_width - 1:0]      core1_wr_data,

//     output reg core1_busy,
//     output reg core1_ack,

//     // for use by comp_driver.sv; might migrate to use contr_ in the future, perhaps
//     // no simulated delay added
//     /*
//     input                    oob_wr_en,
//     input [addr_width - 1:0] oob_wr_addr,
//     input [data_width - 1:0] oob_wr_data,
//     */

//     // for use by controller.sv
//     // we'll probalby add siulated delay to this
//     input                    contr_wr_en,
//     input                    contr_rd_en,
//     input [addr_width - 1:0] contr_wr_addr,
//     input [data_width - 1:0] contr_wr_data,
//     input [addr_width - 1:0] contr_rd_addr,
//     output reg [data_width - 1:0] contr_rd_data,
//     output reg contr_rd_ack
// );
//     reg [data_width - 1:0] mem[memory_size];

//     reg [addr_width - 1:0] received_addr;
//     reg [data_width - 1:0] received_data;
//     reg                    received_rd_req;
//     reg                    received_wr_req;

//     reg [7:0]              clks_to_wait;

//     reg                    n_busy;
//     reg                    n_ack;

//     reg [addr_width - 1:0] n_received_addr;
//     reg [data_width - 1:0] n_received_data;
//     reg                    n_received_rd_req;
//     reg                    n_received_wr_req;

//     reg [7:0]              n_clks_to_wait;

//     reg                    n_read_now;
//     reg                    n_write_now;

//     // reg n_contr_rd_ack;

//     reg [data_width - 1:0] n_rd_data;

//     always @(*) begin
//     // $monitor("t=%0d mem.always*.mon rst=%0d ena=%0d rd_req=%0d wr_req=%0d addr=%0d rd_data=%0d wr_data=%0d busy=%0d ack=%0d clks_to_wait=%0d",
//     //   $time, rst, ena, rd_req, wr_req, addr, rd_data, wr_data, busy, ack, clks_to_wait);
//     // $display("t=%0d mem.always*.disp rst=%0d ena=%0d rd_req=%0d wr_req=%0d addr=%0d rd_data=%0d wr_data=%0d busy=%0d ack=%0d clks_to_wait=%0d",
//     //   $time, rst, ena, rd_req, wr_req, addr, rd_data, wr_data, busy, ack, clks_to_wait);
//     // $display("t=%0d mem.always*.strb rst=%0d ena=%0d rd_req=%0d wr_req=%0d addr=%0d rd_data=%0d wr_data=%0d busy=%0d ack=%0d clks_to_wait=%0d",
//     //   $time, rst, ena, rd_req, wr_req, addr, rd_data, wr_data, busy, ack, clks_to_wait);

//         n_ack = 0;
//         n_busy = 0;

//         n_received_rd_req = received_rd_req;
//         n_received_wr_req = received_wr_req;

//         n_rd_data = '0;
//         n_received_addr = received_addr;
//         n_received_data = received_data;

//         n_write_now = 0;
//         n_read_now = 0;

//         n_clks_to_wait = 0;

//         // n_contr_rd_ack = 0;

//         // $display("rst %0d received_rd_req=%0d", rst, received_rd_req);
//         `assert_known(received_rd_req);
//         `assert_known(received_wr_req);
//         `assert_known(core1_wr_req);
//         `assert_known(core1_rd_req);
//         // `assert_known(ena);
//         if (received_rd_req) begin
//             `assert_known(clks_to_wait);
//             if (clks_to_wait == 0) begin
//                 n_ack = 1;
//                 n_read_now = 1;
//                 // n_rd_data <= mem[{2'b0, received_addr[31:2]}];
//                 n_received_rd_req = 0;
//                 n_received_wr_req = 0;
//                 n_busy = 0;
//             end else begin
//                 n_clks_to_wait = clks_to_wait - 1;
//                 n_busy = 1;
//             end
//         end else if(received_wr_req) begin
//             `assert_known(clks_to_wait);
//             if (clks_to_wait == 0) begin
//                 n_ack = 1;
//                 n_write_now = 1;
//                 n_received_rd_req = 0;
//                 n_received_wr_req = 0;
//                 n_busy = 0;
//             end else begin
//                 n_clks_to_wait = clks_to_wait - 1;
//                 n_busy = 1;
//             end
//         end else if (core1_wr_req) begin
//             n_received_wr_req = 1;
//             n_clks_to_wait = mem_simulated_delay - 1;
//             // $display("writing addr=%0d", addr);
//             n_received_addr = core1_addr;
//             n_received_data = core1_wr_data;
//             n_ack = 0;
//             n_busy = 1;
//         end else if (core1_rd_req) begin
//             n_received_rd_req = 1;
//             n_clks_to_wait = mem_simulated_delay - 1;
//             // $display("reading addr=%0d", addr);
//             n_received_addr = core1_addr;
//             n_ack = 0;
//             n_busy = 1;
//         end
//     end

//     always @(posedge clk, negedge rst) begin
//         `assert_known(rst);
//         if(~rst) begin
//             // $display("mem_delayed.rst");
//             clks_to_wait <= 0;
//             core1_busy <= 0;
//             core1_ack <= 0;
//             core1_rd_data <= '0;

//             received_addr <= 0;
//             received_data <= 0;

//             received_rd_req <= 0;
//             received_wr_req <= 0;

//             contr_rd_ack <= 0;
//         end else begin
//             // $display("mem_delayed.clk non reset");
//             /*
//             `assert_known(oob_wr_en);
//             if(oob_wr_en) begin
//                 // $display("oob_wen mem[%0d] = %0d", oob_wr_addr, oob_wr_data);
//                 mem[oob_wr_addr >> 2] <= oob_wr_data;
//             end
//             */

//             contr_rd_ack <= 0;

//             if(contr_wr_en) begin
//                 // $display("mem controller contr wr en writing %0d to addr %0d", contr_wr_data, contr_wr_addr);
//                 mem[contr_wr_addr >> 2] <= contr_wr_data;
//             end

//             if(contr_rd_en) begin
//                 // $display("mem controller contr rd en reading %0d from addr %0d", mem[contr_rd_addr >> 2], contr_rd_addr);
//                 contr_rd_data <= mem[contr_rd_addr >> 2];
//                 contr_rd_ack <= 1;
//             end

//             // if(ena) begin
//             //     $display(
//             //         "t=%0d mem_delayed.ff n_clks=%0d n_received_rd_req=%0d n_received_wr_req=%0d n_ack=%0d n_busy=%0d n_received_addr=%0d n_read_now=%0d mem[n_received_addr]=%0d",
//             //         $time, n_clks_to_wait, n_received_rd_req, n_received_wr_req, n_ack, n_busy, n_received_addr, n_read_now, mem[n_received_addr]);
//             // end
//             clks_to_wait <= n_clks_to_wait;
//             core1_busy <= n_busy;
//             core1_ack <= n_ack;
//             core1_rd_data <= '0;

//             received_addr <= n_received_addr;
//             received_data <= n_received_data;

//             received_rd_req <= n_received_rd_req;
//             received_wr_req <= n_received_wr_req;

//             `assert_known(n_write_now);
//             if(n_write_now) begin
//                 // $display("writing now n_received_data=%0d n_received_addr=%0d", n_received_data, n_received_addr);
//                 mem[{2'b0, n_received_addr[31:2]}] <= n_received_data;
//             end

//             `assert_known(n_read_now);
//             if(n_read_now) begin
//                 // $display(
//                 //     "reading rd data n_received_addr=%0d mem[ {2'b0, n_received_addr[31:2]} ]=%0d",
//                 //     n_received_addr, mem[ {2'b0, n_received_addr[31:2]} ]);
//                 core1_rd_data <= mem[ {2'b0, n_received_addr[31:2]} ];
//             end
//         end
//     end
// endmodule
parameter mem_simulated_delay = 5;
parameter memory_size         = 512; // total # of 32-bit words
parameter data_width          = 32;
parameter addr_width          = 32;
module global_mem_controller(
    input                      clk,
    input                      rst,

    // Core 1 request interface
    input                      core1_rd_req,
    input                      core1_wr_req,
    input  [addr_width - 1:0]  core1_addr,
    output reg [data_width-1:0] core1_rd_data,
    input  [data_width-1:0]    core1_wr_data,
    output reg                 core1_busy,
    output reg                 core1_ack,

    // Controller-driven interface (unchanged)
    input                      contr_wr_en,
    input                      contr_rd_en,
    input  [addr_width - 1:0]  contr_wr_addr,
    input  [data_width - 1:0]  contr_wr_data,
    input  [addr_width - 1:0]  contr_rd_addr,
    output reg [data_width-1:0] contr_rd_data,
    output reg                 contr_rd_ack
);

    // ------------------------------------------------------------------------
    // 1) Submemory arrangement parameters
    // ------------------------------------------------------------------------
    // We'll split the total 16 MB (16,777,216 32-bit words) into 16 blocks,
    // each block is 1,048,576 (2^20) words. 16 * (2^20) = 16,777,216 total words.
    // Adjust if you have fewer or more sub-blocks.
    localparam SUBMEM_SIZE   = 32;  // # of 32-bit words in each submem
    localparam NUM_SUBMEM    = 16;       // total submem blocks
    // Check that memory_size matches the product
    // for safety or just rely on your top-level to do so:
    // localparam check = (SUBMEM_SIZE * NUM_SUBMEM == memory_size) ? 1 : 0;

    // A small function to compute clog2, if needed:
    function integer clog2;
        input integer x;
        integer i;
        begin
            i = 0;
            while ((1 << i) < x) i = i + 1;
            clog2 = i;
        end
    endfunction

    // For an address in *bytes*, we shift >>2 to get a word index.
    // Then, top bits select which submem, low bits select offset in that submem.
    localparam SUBMEM_SIZE_LOG2 = clog2(SUBMEM_SIZE);

    // ------------------------------------------------------------------------
    // 2) State regs and control signals (unchanged from original)
    // ------------------------------------------------------------------------
    reg [addr_width - 1:0] received_addr;
    reg [data_width - 1:0] received_data;
    reg                    received_rd_req;
    reg                    received_wr_req;
    reg [7:0]              clks_to_wait;

    reg                    n_busy;
    reg                    n_ack;
    reg [addr_width - 1:0] n_received_addr;
    reg [data_width - 1:0] n_received_data;
    reg                    n_received_rd_req;
    reg                    n_received_wr_req;
    reg [7:0]              n_clks_to_wait;

    reg                    n_read_now;
    reg                    n_write_now;
    reg [data_width - 1:0] n_rd_data;

    // ------------------------------------------------------------------------
    // 3) Wires to/from the submem blocks
    // ------------------------------------------------------------------------
    // We'll instantiate an array of small_mem.
    // Each has a single read-data wire out. We’ll multiplex them.
    wire [data_width-1:0] submem_rd_data [0:NUM_SUBMEM-1];

    // For the core transactions (the "delayed" path), we decode once at the end.
    // For the controller side (contr_*), we decode separately.

    // =========== Address decode for the "core" read/write path ===========
    //  - We get word-index = received_addr[31:2].
    //  - submem_idx  = top bits
    //  - submem_addr = low bits
    wire [31:0] word_index_core = received_addr[31:2];  // ignoring bottom 2 bits
    wire [clog2(NUM_SUBMEM)-1:0] submem_idx_core = word_index_core[SUBMEM_SIZE_LOG2 +: clog2(NUM_SUBMEM)];
    wire [SUBMEM_SIZE_LOG2-1:0] submem_off_core  = word_index_core[SUBMEM_SIZE_LOG2-1:0];

    // =========== Address decode for the controller read/write path =============
    wire [31:0] word_index_contr_wr = contr_wr_addr[31:2];
    wire [31:0] word_index_contr_rd = contr_rd_addr[31:2];

    wire [clog2(NUM_SUBMEM)-1:0] submem_idx_contr_wr
        = word_index_contr_wr[SUBMEM_SIZE_LOG2 +: clog2(NUM_SUBMEM)];
    wire [clog2(NUM_SUBMEM)-1:0] submem_idx_contr_rd
        = word_index_contr_rd[SUBMEM_SIZE_LOG2 +: clog2(NUM_SUBMEM)];

    wire [SUBMEM_SIZE_LOG2-1:0] submem_off_contr_wr
        = word_index_contr_wr[SUBMEM_SIZE_LOG2-1:0];
    wire [SUBMEM_SIZE_LOG2-1:0] submem_off_contr_rd
        = word_index_contr_rd[SUBMEM_SIZE_LOG2-1:0];

    // ------------------------------------------------------------------------
    // 4) Generate the submem blocks
    // ------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin : SUBMEM_ARRAY
            small_mem u_submem (
                .clk(clk),
                // We combine write requests from:
                // 1) The "core" path (n_write_now) if submem_idx_core == i
                // 2) The controller path (contr_wr_en) if submem_idx_contr_wr == i
                // If both happen in same cycle, you might want arbitration logic.
                .wr_en( (n_write_now && (submem_idx_core == i)) ||
                        (contr_wr_en  && (submem_idx_contr_wr == i)) ),

                // For the address, if it’s the core writing, use submem_off_core,
                // else if it’s the controller writing, use submem_off_contr_wr.
                // This is a simplistic approach that merges signals.
                // For strict design, you might need separate cycles or arbitration.
                .addr( (n_write_now && (submem_idx_core == i)) ? submem_off_core :
                       (contr_wr_en  && (submem_idx_contr_wr == i)) ? submem_off_contr_wr :
                       // default
                       submem_off_core ),
                .wr_data( (n_write_now && (submem_idx_core == i)) ? n_received_data :
                          (contr_wr_en  && (submem_idx_contr_wr == i)) ? contr_wr_data :
                          {data_width{1'b0}} ),
                .rd_data(submem_rd_data[i])
            );
        end
    endgenerate

    genvar i;
    generate
        for (i = 12; i < NUM_SUBMEM-1; i = i + 1) begin : SUBMEM_ARRAY
            small_mem_cell u_submem_cell (
                .clk(clk),
                // We combine write requests from:
                // 1) The "core" path (n_write_now) if submem_idx_core == i
                // 2) The controller path (contr_wr_en) if submem_idx_contr_wr == i
                // If both happen in same cycle, you might want arbitration logic.
                .wr_en( (n_write_now && (submem_idx_core == i)) ||
                        (contr_wr_en  && (submem_idx_contr_wr == i)) ),

                // For the address, if it’s the core writing, use submem_off_core,
                // else if it’s the controller writing, use submem_off_contr_wr.
                // This is a simplistic approach that merges signals.
                // For strict design, you might need separate cycles or arbitration.
                .addr( (n_write_now && (submem_idx_core == i)) ? submem_off_core :
                       (contr_wr_en  && (submem_idx_contr_wr == i)) ? submem_off_contr_wr :
                       // default
                       submem_off_core ),
                .wr_data( (n_write_now && (submem_idx_core == i)) ? n_received_data :
                          (contr_wr_en  && (submem_idx_contr_wr == i)) ? contr_wr_data :
                          {data_width{1'b0}} ),
                .rd_data(submem_rd_data[i])
            );
        end
    endgenerate
//     small_mem_cell u_submem_cell (
//     .clk(clk),
//     // We combine write requests from:
//     // 1) The "core" path (n_write_now) if submem_idx_core == i
//     // 2) The controller path (contr_wr_en) if submem_idx_contr_wr == i
//     // If both happen in same cycle, you might want arbitration logic.
//     .wr_en( (n_write_now && (submem_idx_core == NUM_SUBMEM-1)) ||
//             (contr_wr_en  && (submem_idx_contr_wr == NUM_SUBMEM-1)) ),

//     // For the address, if it’s the core writing, use submem_off_core,
//     // else if it’s the controller writing, use submem_off_contr_wr.
//     // This is a simplistic approach that merges signals.
//     // For strict design, you might need separate cycles or arbitration.
//     .addr( (n_write_now && (submem_idx_core == NUM_SUBMEM-1)) ? submem_off_core :
//             (contr_wr_en  && (submem_idx_contr_wr == NUM_SUBMEM-1)) ? submem_off_contr_wr :
//             // default
//             submem_off_core ),
//     .wr_data( (n_write_now && (submem_idx_core == NUM_SUBMEM-1)) ? n_received_data :
//                 (contr_wr_en  && (submem_idx_contr_wr == NUM_SUBMEM-1)) ? contr_wr_data :
//                 {data_width{1'b0}} ),
//     .rd_data(submem_rd_data[NUM_SUBMEM-1])
// );

    // ------------------------------------------------------------------------
    // 5) Combinational logic (mostly the same as original)
    // ------------------------------------------------------------------------
    always @(*) begin
        // Default
        n_ack              = 0;
        n_busy             = 0;
        n_received_rd_req  = received_rd_req;
        n_received_wr_req  = received_wr_req;
        n_rd_data          = '0;
        n_received_addr    = received_addr;
        n_received_data    = received_data;
        n_write_now        = 0;
        n_read_now         = 0;
        n_clks_to_wait     = 0;

        // Make sure signals are known
        `assert_known(received_rd_req);
        `assert_known(received_wr_req);
        `assert_known(core1_wr_req);
        `assert_known(core1_rd_req);

        if (received_rd_req) begin
            `assert_known(clks_to_wait);
            if (clks_to_wait == 0) begin
                n_ack             = 1;
                n_read_now        = 1;  // triggers the submem read in clocked block
                n_received_rd_req = 0;
                n_received_wr_req = 0;
                n_busy            = 0;
            end else begin
                n_clks_to_wait = clks_to_wait - 1;
                n_busy         = 1;
            end
        end
        else if (received_wr_req) begin
            `assert_known(clks_to_wait);
            if (clks_to_wait == 0) begin
                n_ack             = 1;
                n_write_now       = 1;  // triggers the submem write in clocked block
                n_received_rd_req = 0;
                n_received_wr_req = 0;
                n_busy            = 0;
            end else begin
                n_clks_to_wait = clks_to_wait - 1;
                n_busy         = 1;
            end
        end
        else if (core1_wr_req) begin
            n_received_wr_req = 1;
            n_clks_to_wait    = mem_simulated_delay - 1;
            n_received_addr   = core1_addr;
            n_received_data   = core1_wr_data;
            n_ack             = 0;
            n_busy            = 1;
        end
        else if (core1_rd_req) begin
            n_received_rd_req = 1;
            n_clks_to_wait    = mem_simulated_delay - 1;
            n_received_addr   = core1_addr;
            n_ack             = 0;
            n_busy            = 1;
        end
    end

    // ------------------------------------------------------------------------
    // 6) Sequential logic
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        `assert_known(rst);
        if (~rst) begin
            clks_to_wait      <= 0;
            core1_busy        <= 0;
            core1_ack         <= 0;
            core1_rd_data     <= '0;

            received_addr     <= 0;
            received_data     <= 0;
            received_rd_req   <= 0;
            received_wr_req   <= 0;
            contr_rd_ack      <= 0;
            contr_rd_data     <= '0;
        end else begin
            // Default
            contr_rd_ack <= 0;

            // -------------- Controller path reads ----------------
            // If contr_rd_en is high, we read from the appropriate submem
            // immediately in this clock (synchronous read).
            // Because we have the submem's outputs in submem_rd_data[],
            // we do a bank select and then assign contr_rd_data.
            if (contr_rd_en) begin
                // Indicate ack
                contr_rd_ack <= 1;
                // Mux out the data from the right submem
                contr_rd_data <= submem_rd_data[submem_idx_contr_rd];
            end

            // -------------- Controller path writes ---------------
            // Handled automatically by wr_en in the submem generation logic
            // (no extra code needed here, aside from a debug message if you want).

            // -------------- The delayed core1 path ---------------
            clks_to_wait  <= n_clks_to_wait;
            core1_busy    <= n_busy;
            core1_ack     <= n_ack;

            // By default we do not assign anything; only if n_read_now is set:
            core1_rd_data <= core1_rd_data;

            received_addr <= n_received_addr;
            received_data <= n_received_data;
            received_rd_req <= n_received_rd_req;
            received_wr_req <= n_received_wr_req;

            // The actual write occurs inside the submem on wr_en=1.
            // Here we only do final assignment for the read data:
            if (n_read_now) begin
                // Data is read out of the correct submem via submem_rd_data[].
                core1_rd_data <= submem_rd_data[submem_idx_core];
            end
        end
    end

endmodule
