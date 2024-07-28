/*-------------------------------------------------------------------------*\
	FILE:			sc_fifo.v
	AUTHOR:			Xudong Chen
	CREATED BY:		Xudong Chen
	$Id$
	ABSTRACT:		behavioral code for dual-clock fifo module
	
	KEYWORDS:		scfifo, dpram
	MODIFICATION HISTORY:
	$Log$
		Xudong 		18/7/16			original version
\*-------------------------------------------------------------------------*/

module sc_fifo
#(
parameter	LOG2N = 6,				// FIFO
parameter	N = (1<<LOG2N),			// FIFO
parameter	DATA_WIDTH = 32,		// 
parameter	ADDR_WIDTH = LOG2N 		// 
)
(
input  	wire						aclr,			// 
input	wire						clock,			// 
// 
input	wire	[DATA_WIDTH-1:0]	data,			// 
input	wire						wrreq,			// 
// 
output	reg		[DATA_WIDTH-1:0]	q,				// 
input	wire						rdreq,			// 
// 
output	wire	[ADDR_WIDTH-1:0]	usedw,			// 
output	wire						full,			// 
output	wire						empty			// 
);

/*-------------------------------------------------------------------------*\
	signals
\*-------------------------------------------------------------------------*/

// 
reg		[DATA_WIDTH-1:0]			dpram	[0:N-1];	// ïDPRAM
reg		[ADDR_WIDTH:0]				wr_addr;			// 
reg		[ADDR_WIDTH:0]				rd_addr;			// 

/*-------------------------------------------------------------------------*\
	timing
\*-------------------------------------------------------------------------*/

/*
	for writing:
		clock		_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|-
		aclr		__|-|____________________________________________
		wrreq		 ____|-----------------------------------|_______
		wraddr		 _|  0	 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |________
		data		 ____| d0| d1| d2| d3| d4| d5| d6| d7| d8|________
		
	for reading:
		clock		_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|-
		aclr		__|-|____________________________________________
		rdreq		 ____|-----------------------------------|_______
		rdaddr		 _|  0	 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |________
		q			 _| d0	 | d1| d2| d3| d4| d5| d6| d7| d8|________
	
*/

/*-------------------------------------------------------------------------*\
	process
\*-------------------------------------------------------------------------*/
// 
always @(posedge clock or posedge aclr)
	if(aclr==1)
		wr_addr <= 0;
	else if(wrreq && !full)
		wr_addr <= wr_addr + {{(ADDR_WIDTH){1'B0}}, 1'B1};
		
// 
always @(posedge clock or posedge aclr)
	if(aclr==1)
		rd_addr <= 0;
	else if(rdreq && !empty)
		rd_addr <= rd_addr + {{(ADDR_WIDTH){1'B0}}, 1'B1};
		
// 
// 
always @(posedge clock)
	if(wrreq && !full)
		dpram[wr_addr[ADDR_WIDTH-1:0]] <= data;
// 
always @(*)
	q = dpram[rd_addr[ADDR_WIDTH-1:0]];
//

// 
assign		usedw = (wr_addr - rd_addr + N);
assign		full  = (usedw>=N);
assign		empty = (usedw==0);
/*-------------------------------------------------------------------------*\
	instantiation
\*-------------------------------------------------------------------------*/
//////////////////////////////////////////////////////////////

endmodule