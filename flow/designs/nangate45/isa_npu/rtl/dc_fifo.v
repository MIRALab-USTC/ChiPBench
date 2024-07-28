/*-------------------------------------------------------------------------*\
	FILE:			dc_fifo.v
	AUTHOR:			Xudong Chen
	CREATED BY:		Xudong Chen
	$Id$
	ABSTRACT:		behavioral code for dual-clock fifo module
	
	KEYWORDS:		dcfifo, dpram
	MODIFICATION HISTORY:
	$Log$
		Xudong 		18/6/20			original version
		Xudong  	18/6/21			add synthesis preserve to gray-enc/dec
		Xudong 		18/6/26			add sync stage parameter
\*-------------------------------------------------------------------------*/

module dc_fifo
#(
parameter	LOG2N = 6,				// FIFO
parameter	N = (1<<LOG2N),			// FIFO
parameter	DATA_WIDTH = 32,		// 
parameter	ADDR_WIDTH = LOG2N,		// 
parameter	SYNC_STAGE = 4			// 
)
(
input  	wire						aclr,			// 
// 
input	wire						wrclock,		// 
input	wire	[DATA_WIDTH-1:0]	data,			// 
input	wire						wrreq,			// 
output	wire	[ADDR_WIDTH-1:0]	wrusedw,		// 
output	wire						wrfull,			// 
output	wire						wrempty,		// 
// 
input	wire						rdclock,		// 
output	reg		[DATA_WIDTH-1:0]	q,				// 
input	wire						rdreq,			// 
output	wire	[ADDR_WIDTH-1:0]	rdusedw,		// 
output	wire						rdfull,			// 
output	wire						rdempty			// 
);

/*-------------------------------------------------------------------------*\
	signals
\*-------------------------------------------------------------------------*/

// 
reg		[DATA_WIDTH-1:0]			dpram	[0:N-1];	// ïDPRAM
reg		[ADDR_WIDTH:0]				wr_addr;			// 
reg		[ADDR_WIDTH:0]				rd_addr;			// 

/////////////// gray
wire	[ADDR_WIDTH:0]				wr_addr_gray_enc /* synthesis preserve */;	// 1-clock pipeline
wire	[ADDR_WIDTH:0]				rd_addr_gray_enc /* synthesis preserve */;	// 1-clock pipeline

// 
wire	[ADDR_WIDTH:0]				wr_addr_gray_sync /* synthesis preserve */;	// write-gray --> read-clock
wire	[ADDR_WIDTH:0]				rd_addr_gray_sync /* synthesis preserve */;	// read-gray --> write-clock

// 
wire	[ADDR_WIDTH:0]				wr_addr_gray_dec /* synthesis preserve */;	// write-addr --> read-clock
wire	[ADDR_WIDTH:0]				rd_addr_gray_dec /* synthesis preserve */;	// read-addr --> write-clock
/*-------------------------------------------------------------------------*\
	process
\*-------------------------------------------------------------------------*/
// 
always @(posedge wrclock or posedge aclr)
	if(aclr==1)
		wr_addr <= 0;
	else if(wrreq && !wrfull)
		wr_addr <= wr_addr + {{(ADDR_WIDTH){1'B0}}, 1'B1};
		
// 
always @(posedge rdclock or posedge aclr)
	if(aclr==1)
		rd_addr <= 0;
	else if(rdreq && !rdempty)
		rd_addr <= rd_addr + {{(ADDR_WIDTH){1'B0}}, 1'B1};
		
// 
// 
always @(posedge wrclock)
	if(wrreq && !wrfull)
		dpram[wr_addr[ADDR_WIDTH-1:0]] <= data;
// 
always @(*)
	q = dpram[rd_addr[ADDR_WIDTH-1:0]];
//

// 
assign		wrusedw = (wr_addr - rd_addr_gray_dec + N);
assign		wrfull 	= (wrusedw>=(N-SYNC_STAGE-4));
assign		wrempty = (wrusedw==0);
assign		rdusedw = (wr_addr_gray_dec - rd_addr + N);
assign		rdfull 	= (rdusedw>=(N-SYNC_STAGE-4));
assign		rdempty = (rdusedw==0);
/*-------------------------------------------------------------------------*\
	instantiation
\*-------------------------------------------------------------------------*/
// 	
gray_enc_1p		
#(
	.WIDTH(ADDR_WIDTH+1)
)
u0_gray_enc_1p(
	.clock(wrclock),
	.src(wr_addr),
	.dst(wr_addr_gray_enc)
);

gray_enc_1p		
#(
	.WIDTH(ADDR_WIDTH+1)
)
u1_gray_enc_1p(
	.clock(rdclock),
	.src(rd_addr),
	.dst(rd_addr_gray_enc)
);
// 
sync_dual_clock
#(
	.WIDTH(ADDR_WIDTH+1),
	.SYNC_STAGE(SYNC_STAGE)
)
u0_sync_dual_clock
(
	.clock_dst(rdclock),
	.src(wr_addr_gray_enc),
	.dst(wr_addr_gray_sync)
);
sync_dual_clock
#(
	.WIDTH(ADDR_WIDTH+1),
	.SYNC_STAGE(SYNC_STAGE)
)
u1_sync_dual_clock
(
	.clock_dst(wrclock),
	.src(rd_addr_gray_enc),
	.dst(rd_addr_gray_sync)
);

gray_dec_1p		
#(
	.WIDTH(ADDR_WIDTH+1)
)
u0_gray_dec_1p(
	.clock(wrclock),
	.src(rd_addr_gray_sync),
	.dst(rd_addr_gray_dec)
);

gray_dec_1p		
#(
	.WIDTH(ADDR_WIDTH+1)
)
u1_gray_dec_1p(
	.clock(rdclock),
	.src(wr_addr_gray_sync),
	.dst(wr_addr_gray_dec)
);

//////////////////////////////////////////////////////////////

endmodule