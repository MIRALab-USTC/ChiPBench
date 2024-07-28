/*-------------------------------------------------------------------------*\
	FILE:			sync_dual_clock.v
	AUTHOR:			Xudong Chen
	CREATED BY:		Xudong Chen
	$Id$
	ABSTRACT:		behavioral code for dual-clock sync module
	
	KEYWORDS:		dual clock, sync
	MODIFICATION HISTORY:
	$Log$
		Xudong 		18/6/20			original version
\*-------------------------------------------------------------------------*/
module sync_dual_clock
#(
parameter	WIDTH = 6,			// 
parameter	SYNC_STAGE = 2		// ïïï
)
(
input	wire				clock_dst,
input	wire	[WIDTH-1:0]	src,
output	wire	[WIDTH-1:0]	dst
);

//
reg		[WIDTH-1:0]			sync_reg	[0:SYNC_STAGE-1];
integer p;
always @(posedge clock_dst)
begin
	sync_reg[0] <= src;
	for(p=1; p<SYNC_STAGE; p=p+1)
		sync_reg[p] <= sync_reg[p-1];
end

assign						dst = sync_reg[SYNC_STAGE-1];	// 

endmodule