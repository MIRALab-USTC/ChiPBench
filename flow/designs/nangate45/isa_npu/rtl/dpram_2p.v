/*-------------------------------------------------------------------------*\
	FILE:			dpram_2p.v
	AUTHOR:			Xudong Chen
	CREATED BY:		Xudong Chen
	$Id$
	ABSTRACT:		behavioral code for dual-clock ram module
	
	KEYWORDS:		dpram
	MODIFICATION HISTORY:
	$Log$
		Xudong 		18/6/20			original version
\*-------------------------------------------------------------------------*/

module dpram_2p
#(
parameter	LOG2N = 9,				// FIFO
parameter	N = (1<<LOG2N),			// FIFO
parameter	DATA_WIDTH = 32,		// 
parameter	ADDR_WIDTH = LOG2N 		// 
)
(
    input   wire						aclr,			// 
    // 
    input	wire						wrclock,		// 
    input	wire	[DATA_WIDTH-1:0]	data,			// 
    input	wire						wrreq,			// 
    input	wire	[ADDR_WIDTH-1:0]	wraddr,			// 
    // 
    input	wire						rdclock,		// 
    output	reg		[DATA_WIDTH-1:0]	q,				// 
    input	wire						rdreq,			// 
    input	wire	[ADDR_WIDTH-1:0]	rdaddr			// 
);

    // fakeram45_512x64
    wire [63:0] ram_read_data;      // RAM64
    wire [63:0] ram_write_data;     // RAM64

    // 3264
    assign ram_write_data = {32'b0, data}; // 32ï32

    // fakeram45_512x64
    fakeram45_512x64 ram_instance (
        .clk(wrclock),                 // 
        .ce_in(1'b1),                  // ï
        .we_in(wrreq),                 // 
        .addr_in(wrreq ? wraddr : rdaddr), // ï
        .wd_in(ram_write_data),        // 
        .w_mask_in(64'h00000000FFFFFFFF), // ï32
        .rd_out(ram_read_data)         // 
    );

    // 32
    always @(posedge rdclock or posedge aclr)
        if (aclr)
            q <= 32'b0;
        else if (rdreq)
            q <= ram_read_data[31:0];  // 32

endmodule
