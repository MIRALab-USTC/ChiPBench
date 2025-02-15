module memory_block_64x8(
    input wclk,
    input wrst,
    input wce,
    input we,
    input [5:0] waddr,
    input [7:0] di,
    input rclk,
    input rrst,
    input rce,
    input [5:0] raddr,
    output reg [7:0] do_slice
);
    reg [7:0] mem [63:0];
    always @(posedge wclk) begin
        if (wrst) begin
        end else if (wce && we) begin
            mem[waddr] <= di;
        end
    end
    always @(posedge rclk) begin
        if (rrst) begin
            do_slice <= 8'b0;
        end else if (rce) begin
            do_slice <= mem[raddr];
        end
    end
endmodule

module memory_block_128x8(
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
    output reg [7:0] do_slice
);
    reg [7:0] mem [127:0];
    always @(posedge wclk) begin
        if (wrst) begin
        end else if (wce && we) begin
            mem[waddr] <= di;
        end
    end
    always @(posedge rclk) begin
        if (rrst) begin
            do_slice <= 8'b0;
        end else if (rce) begin
            do_slice <= mem[raddr];
        end
    end
endmodule


module memory_block_64x24(
    input         clk,
    input         rst,
    input         ce,
    input         we,
    input         oe,
    input  [5:0]  addr,
    input  [23:0] di,
    output [23:0] do
);

    reg [23:0] mem[63:0];
    reg [5:0] ra;

    always @(posedge clk) begin
        if (rst)
            ra <= 6'd0;
        else if (ce)
            ra <= addr;
    end

    assign do = mem[ra];

    always @(posedge clk) begin
        if (we && ce)
            mem[addr] <= di;
    end

endmodule