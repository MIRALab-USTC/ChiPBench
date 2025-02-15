/*-------------------------------------------------------------------------------*\
	FILE:			gray_enc_1p.v
	AUTHOR:			Xudong Chen
	CREATED BY:		Xudong Chen
	$Id$
	ABSTRACT:		behavioral code for gray encoding module, with 1-clock pipeline
	
	KEYWORDS:		gray, encode, 1-clock pipeline 
	MODIFICATION HISTORY:
	$Log$
		Xudong 		18/6/20			original version
		Xudong		18/6/21			rectify, gray encode not right
\*-------------------------------------------------------------------------------*/
module gray_enc_1p
#(
parameter	WIDTH = 6			// 
)
(
input		wire					clock,	// 
input		wire	[WIDTH-1:0]		src,	// 
output		reg		[WIDTH-1:0]		dst		// 
);

// 
integer	p;
reg		[WIDTH-1:0]	dst_x;
always @(*)
begin
	dst_x[WIDTH-1] = src[WIDTH-1];		// g[N-1] = b[N-1]
	for(p=WIDTH-2; p>=0; p=p-1)
	begin
		dst_x[p] = src[p]^src[p+1];		// g[n] = b[n]^b[n+1]	, 0 <= n <= N-2
	end
end

// 
always @(posedge clock)
	dst <= dst_x;

endmodule