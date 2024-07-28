module altsyncram8x64 (
    input wire [7:0] address_a,  // Address input (8 bits for 256 entries)
    input wire clock0,           // Clock input
    output wire [63:0] q_a,      // Data output (64 bits)
    input wire aclr0,            // Asynchronous clear (not used)
    input wire aclr1,            // Asynchronous clear (not used)
    input wire address_b,        // Secondary address input (not used)
    input wire addressstall_a,   // Address stall (not used)
    input wire addressstall_b,   // Address stall (not used)
    input wire byteena_a,        // Byte enable (not used)
    input wire byteena_b,        // Byte enable (not used)
    input wire clock1,           // Secondary clock (not used)
    input wire clocken0,         // Clock enable (not used)
    input wire clocken1,         // Clock enable (not used)
    input wire clocken2,         // Clock enable (not used)
    input wire clocken3,         // Clock enable (not used)
    input wire [63:0] data_a,    // Data input (64 bits)
    input wire data_b,           // Data input (not used)
    output wire eccstatus,       // ECC status (not used)
    output wire [63:0] q_b,      // Secondary data output (not used)
    input wire rden_a,           // Read enable
    input wire rden_b,           // Secondary read enable (not used)
    input wire wren_a,           // Write enable
    input wire wren_b            // Secondary write enable (not used)
);

    // ï32
    wire [31:0] q_a_part [1:0];  // 23264
    wire [31:0] data_a_part [1:0]; // 
    assign {data_a_part[1], data_a_part[0]} = data_a;

    // 64
    assign q_a = {q_a_part[1], q_a_part[0]};

    // 2fakeram45_256x32
    fakeram45_256x32 ram0 (
        .clk(clock0),
        .ce_in(1'b1),                   // Always enabled
        .we_in(wren_a),                 // Write enable
        .addr_in(address_a),            // Address
        .wd_in(data_a_part[0]),         // 32
        .w_mask_in(32'hFFFFFFFF),       // 
        .rd_out(q_a_part[0])            // 32
    );

    fakeram45_256x32 ram1 (
        .clk(clock0),
        .ce_in(1'b1),                   // Always enabled
        .we_in(wren_a),                 // Write enable
        .addr_in(address_a),            // Address
        .wd_in(data_a_part[1]),         // 32
        .w_mask_in(32'hFFFFFFFF),       // 
        .rd_out(q_a_part[1])            // 32
    );

    // 
    assign eccstatus = 1'b0;            // ECC status is not used
    assign q_b = 64'b0;                 // Secondary data output is not used

endmodule

// module altsyncram8x64 (
//     input wire [7:0] address_a,  // Address input
//     input wire clock0,          // Clock input
//     output reg [63:0] q_a,      // Data output
//     input wire aclr0,           // Asynchronous clear (not used)
//     input wire aclr1,           // Asynchronous clear (not used)
//     input wire address_b,       // Secondary address input (not used)
//     input wire addressstall_a,  // Address stall (not used)
//     input wire addressstall_b,  // Address stall (not used)
//     input wire byteena_a,       // Byte enable (not used)
//     input wire byteena_b,       // Byte enable (not used)
//     input wire clock1,          // Secondary clock (not used)
//     input wire clocken0,        // Clock enable (not used)
//     input wire clocken1,        // Clock enable (not used)
//     input wire clocken2,        // Clock enable (not used)
//     input wire clocken3,        // Clock enable (not used)
//     input wire [63:0] data_a,   // Data input (not used)
//     input wire data_b,          // Data input (not used)
//     output wire eccstatus,      // ECC status (not used)
//     output wire [63:0] q_b,     // Secondary data output (not used)
//     input wire rden_a,          // Read enable
//     input wire rden_b,          // Secondary read enable (not used)
//     input wire wren_a,          // Write enable (not used)
//     input wire wren_b           // Secondary write enable (not used)
// );

//     // ROM memory array
//     reg [63:0] rom_memory [0:255];

//     // Initializing ROM from a memory initialization file (MIF)


//     // Reading data from ROM
//     always @(posedge clock0) begin
//         if (rden_a) begin
//             q_a <= rom_memory[address_a];
//         end
//     end

//     // Unused outputs
//     assign eccstatus = 1'b0;
//     assign q_b = 64'b0;

// endmodule


module altsyncram8x32 (
    input wire [7:0] address_a,  // Address input
    input wire clock0,           // Clock input
    output wire [31:0] q_a,      // Data output
    input wire aclr0,            // Asynchronous clear (not used)
    input wire aclr1,            // Asynchronous clear (not used)
    input wire address_b,        // Secondary address input (not used)
    input wire addressstall_a,   // Address stall (not used)
    input wire addressstall_b,   // Address stall (not used)
    input wire byteena_a,        // Byte enable (not used)
    input wire byteena_b,        // Byte enable (not used)
    input wire clock1,           // Secondary clock (not used)
    input wire clocken0,         // Clock enable (not used)
    input wire clocken1,         // Clock enable (not used)
    input wire clocken2,         // Clock enable (not used)
    input wire clocken3,         // Clock enable (not used)
    input wire [31:0] data_a,    // Data input
    input wire data_b,           // Data input (not used)
    output wire eccstatus,       // ECC status (not used)
    output wire [31:0] q_b,      // Secondary data output (not used)
    input wire rden_a,           // Read enable
    input wire rden_b,           // Secondary read enable (not used)
    input wire wren_a,           // Write enable
    input wire wren_b            // Secondary write enable (not used)
);

    // Instantiating the fakeram45_256x32 module
    fakeram45_256x32 memory (
        .clk(clock0),            // Connect clock0 to fakeram clk
        .ce_in(1'b1),            // Enable chip (always enabled in this case)
        .we_in(wren_a),          // Write enable
        .addr_in(address_a),     // Address input
        .wd_in(data_a),          // Write data
        .w_mask_in(32'hFFFFFFFF),// Write mask (write all bits)
        .rd_out(q_a)             // Read data output
    );

    // Unused outputs
    assign eccstatus = 1'b0;     // ECC status is not used
    assign q_b = 32'b0;          // Secondary data output is not used

endmodule


// module altsyncram8x32 (
//     input wire [7:0] address_a,  // Address input
//     input wire clock0,          // Clock input
//     output reg [31:0] q_a,      // Data output
//     input wire aclr0,           // Asynchronous clear (not used)
//     input wire aclr1,           // Asynchronous clear (not used)
//     input wire address_b,       // Secondary address input (not used)
//     input wire addressstall_a,  // Address stall (not used)
//     input wire addressstall_b,  // Address stall (not used)
//     input wire byteena_a,       // Byte enable (not used)
//     input wire byteena_b,       // Byte enable (not used)
//     input wire clock1,          // Secondary clock (not used)
//     input wire clocken0,        // Clock enable (not used)
//     input wire clocken1,        // Clock enable (not used)
//     input wire clocken2,        // Clock enable (not used)
//     input wire clocken3,        // Clock enable (not used)
//     input wire [31:0] data_a,   // Data input (not used)
//     input wire data_b,          // Data input (not used)
//     output wire eccstatus,      // ECC status (not used)
//     output wire [31:0] q_b,     // Secondary data output (not used)
//     input wire rden_a,          // Read enable
//     input wire rden_b,          // Secondary read enable (not used)
//     input wire wren_a,          // Write enable (not used)
//     input wire wren_b           // Secondary write enable (not used)
// );

//     // ROM memory array
//     reg [31:0] rom_memory [0:255];

//     // Initializing ROM from a memory initialization file (MIF)


//     // Reading data from ROM
//     always @(posedge clock0) begin
//         if (rden_a) begin
//             q_a <= rom_memory[address_a];
//         end
//     end

//     // Unused outputs
//     assign eccstatus = 1'b0;
//     assign q_b = 32'b0;

// endmodule

module altsyncram10x128 (
    input wire [9:0] address_a,  // Address input (10 bits for 1024 entries)
    input wire clock0,           // Clock input
    output wire [127:0] q_a,     // Data output (128 bits)
    input wire aclr0,            // Asynchronous clear (not used)
    input wire aclr1,            // Asynchronous clear (not used)
    input wire address_b,        // Secondary address input (not used)
    input wire addressstall_a,   // Address stall (not used)
    input wire addressstall_b,   // Address stall (not used)
    input wire byteena_a,        // Byte enable (not used)
    input wire byteena_b,        // Byte enable (not used)
    input wire clock1,           // Secondary clock (not used)
    input wire clocken0,         // Clock enable (not used)
    input wire clocken1,         // Clock enable (not used)
    input wire clocken2,         // Clock enable (not used)
    input wire clocken3,         // Clock enable (not used)
    input wire [127:0] data_a,   // Data input (128 bits)
    input wire data_b,           // Data input (not used)
    output wire eccstatus,       // ECC status (not used)
    output wire [127:0] q_b,     // Secondary data output (not used)
    input wire rden_a,           // Read enable
    input wire rden_b,           // Secondary read enable (not used)
    input wire wren_a,           // Write enable
    input wire wren_b            // Secondary write enable (not used)
);

    // 4ï32
    wire [31:0] q_a_part [3:0];  // 432128
    wire [31:0] data_a_part [3:0]; // 4
    assign {data_a_part[3], data_a_part[2], data_a_part[1], data_a_part[0]} = data_a;

    // 4128
    assign q_a = {q_a_part[3], q_a_part[2], q_a_part[1], q_a_part[0]};

    // 4fakeram45_1024x32
    fakeram45_1024x32 ram0 (
        .clk(clock0),
        .ce_in(1'b1),                   // Always enabled
        .we_in(wren_a),                 // Write enable
        .addr_in(address_a),            // Address
        .wd_in(data_a_part[0]),         // 32
        .w_mask_in(32'hFFFFFFFF),       // 
        .rd_out(q_a_part[0])            // 32
    );

    fakeram45_1024x32 ram1 (
        .clk(clock0),
        .ce_in(1'b1),                   // Always enabled
        .we_in(wren_a),                 // Write enable
        .addr_in(address_a),            // Address
        .wd_in(data_a_part[1]),         // 32
        .w_mask_in(32'hFFFFFFFF),       // 
        .rd_out(q_a_part[1])            // 32
    );

    fakeram45_1024x32 ram2 (
        .clk(clock0),
        .ce_in(1'b1),                   // Always enabled
        .we_in(wren_a),                 // Write enable
        .addr_in(address_a),            // Address
        .wd_in(data_a_part[2]),         // 32
        .w_mask_in(32'hFFFFFFFF),       // 
        .rd_out(q_a_part[2])            // 32
    );

    fakeram45_1024x32 ram3 (
        .clk(clock0),
        .ce_in(1'b1),                   // Always enabled
        .we_in(wren_a),                 // Write enable
        .addr_in(address_a),            // Address
        .wd_in(data_a_part[3]),         // 32
        .w_mask_in(32'hFFFFFFFF),       // 
        .rd_out(q_a_part[3])            // 32
    );

    // 
    assign eccstatus = 1'b0;            // ECC status is not used
    assign q_b = 128'b0;                // Secondary data output is not used

endmodule


// module altsyncram10x128 (
//     input wire [9:0] address_a,  // Address input
//     input wire clock0,          // Clock input
//     output reg [127:0] q_a,      // Data output
//     input wire aclr0,           // Asynchronous clear (not used)
//     input wire aclr1,           // Asynchronous clear (not used)
//     input wire address_b,       // Secondary address input (not used)
//     input wire addressstall_a,  // Address stall (not used)
//     input wire addressstall_b,  // Address stall (not used)
//     input wire byteena_a,       // Byte enable (not used)
//     input wire byteena_b,       // Byte enable (not used)
//     input wire clock1,          // Secondary clock (not used)
//     input wire clocken0,        // Clock enable (not used)
//     input wire clocken1,        // Clock enable (not used)
//     input wire clocken2,        // Clock enable (not used)
//     input wire clocken3,        // Clock enable (not used)
//     input wire [127:0] data_a,   // Data input (not used)
//     input wire data_b,          // Data input (not used)
//     output wire eccstatus,      // ECC status (not used)
//     output wire [127:0] q_b,     // Secondary data output (not used)
//     input wire rden_a,          // Read enable
//     input wire rden_b,          // Secondary read enable (not used)
//     input wire wren_a,          // Write enable (not used)
//     input wire wren_b           // Secondary write enable (not used)
// );

//     // ROM memory array
//     reg [127:0] rom_memory [0:1023];

//     // Initializing ROM from a memory initialization file (MIF)


//     // Reading data from ROM
//     always @(posedge clock0) begin
//         if (rden_a) begin
//             q_a <= rom_memory[address_a];
//         end
//     end

//     // Unused outputs
//     assign eccstatus = 1'b0;
//     assign q_b = 128'b0;

// endmodule

module altsyncram16x32 (
    input wire [15:0] address_a,  // Address input
    input wire clock0,           // Clock input
    output reg [31:0] q_a,       // Data output
    input wire aclr0,            // Asynchronous clear (not used)
    input wire aclr1,            // Asynchronous clear (not used)
    input wire address_b,        // Secondary address input (not used)
    input wire addressstall_a,   // Address stall (not used)
    input wire addressstall_b,   // Address stall (not used)
    input wire byteena_a,        // Byte enable (not used)
    input wire byteena_b,        // Byte enable (not used)
    input wire clock1,           // Secondary clock (not used)
    input wire clocken0,         // Clock enable (not used)
    input wire clocken1,         // Clock enable (not used)
    input wire clocken2,         // Clock enable (not used)
    input wire clocken3,         // Clock enable (not used)
    input wire [31:0] data_a,    // Data input (not used)
    input wire data_b,           // Data input (not used)
    output wire eccstatus,       // ECC status (not used)
    output wire [31:0] q_b,      // Secondary data output (not used)
    input wire rden_a,           // Read enable
    input wire rden_b,           // Secondary read enable (not used)
    input wire wren_a,           // Write enable (not used)
    input wire wren_b            // Secondary write enable (not used)
);

    // Outputs from the two altsyncram8x32 instances
    wire [31:0] q_a_lower;
    wire [31:0] q_a_upper;

    // Instantiate the lower altsyncram8x32 for address range 0x0000 to 0x00FF
    altsyncram8x32 lower_memory (
        .address_a(address_a[7:0]), // Lower 8 bits of address
        .clock0(clock0),
        .q_a(q_a_lower),
        .aclr0(aclr0),
        .aclr1(aclr1),
        .address_b(address_b),
        .addressstall_a(addressstall_a),
        .addressstall_b(addressstall_b),
        .byteena_a(byteena_a),
        .byteena_b(byteena_b),
        .clock1(clock1),
        .clocken0(clocken0),
        .clocken1(clocken1),
        .clocken2(clocken2),
        .clocken3(clocken3),
        .data_a(data_a),
        .data_b(data_b),
        .eccstatus(),
        .q_b(),
        .rden_a(rden_a & (address_a[15:8] == 8'h00)), // Enable only for lower range
        .rden_b(rden_b),
        .wren_a(wren_a),
        .wren_b(wren_b)
    );

    // Instantiate the upper altsyncram8x32 for address range 0x0100 to 0x01FF
    altsyncram8x32 upper_memory (
        .address_a(address_a[7:0]), // Lower 8 bits of address
        .clock0(clock0),
        .q_a(q_a_upper),
        .aclr0(aclr0),
        .aclr1(aclr1),
        .address_b(address_b),
        .addressstall_a(addressstall_a),
        .addressstall_b(addressstall_b),
        .byteena_a(byteena_a),
        .byteena_b(byteena_b),
        .clock1(clock1),
        .clocken0(clocken0),
        .clocken1(clocken1),
        .clocken2(clocken2),
        .clocken3(clocken3),
        .data_a(data_a),
        .data_b(data_b),
        .eccstatus(),
        .q_b(),
        .rden_a(rden_a & (address_a[15:8] == 8'h01)), // Enable only for upper range
        .rden_b(rden_b),
        .wren_a(wren_a),
        .wren_b(wren_b)
    );

    // Combine outputs based on the upper address bit
    always @(posedge clock0) begin
        if (rden_a) begin
            if (address_a[15:8] == 8'h00) begin
                q_a <= q_a_lower;
            end else if (address_a[15:8] == 8'h01) begin
                q_a <= q_a_upper;
            end
        end
    end

    // Unused outputs
    assign eccstatus = 1'b0;
    assign q_b = 32'b0;

endmodule
