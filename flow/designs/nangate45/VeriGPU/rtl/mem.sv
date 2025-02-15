module small_mem_cell #(
    parameter DATA_WIDTH = 32,
    parameter SUBMEM_SIZE = 32  // number of 32-bit words in this sub-block
) (
    input                     clk,
    input                     wr_en,   // write-enable
    input      [31:0]         addr,    // local offset address (in words)
    input      [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data
);

    // Store SUBMEM_SIZE * DATA_WIDTH bits total.
    // Each index holds one DATA_WIDTH word.
    reg [DATA_WIDTH-1:0] mem_array [0:SUBMEM_SIZE-1];

    // Because we always read after the rising edge (for example),
    // we can do a synchronous read, or “read-during-write” style, as needed.
    always @(posedge clk) begin
        if (wr_en)
            mem_array[addr] <= wr_data;
        rd_data <= mem_array[addr];
    end

endmodule

