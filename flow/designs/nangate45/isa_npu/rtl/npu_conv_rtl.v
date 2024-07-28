/*----------------------------------------------------------------------------------------------------*\
	FILE: 		npu_conv_rtl.v
 	AUTHOR:		Xudong Chen
 	
	ABSTRACT:	behavior of the module of npu_conv_rtl
 	KEYWORDS:	fpga, convolution
 
 	MODIFICATION HISTORY:
	$Log$
			Xudong Chen 	18/7/24		original, ïKm x Knï
							18/7/27		pooling
							18/7/28		ïïFmax
							18/7/29		ram_q[x]==>field_data[y]ïïv1.0
							18/8/2		functionïATlayerï
\*------------------------------------------------------------------------------------------------------*/
module npu_conv_rtl
#(
	parameter	Km = 3,							// row
	parameter	Kn = 3,							// col
	parameter	Ksz = Km * Kn,					// 
	parameter	ATlayer = CeilLog2(Ksz)+1,		// ceil( log2( Ksz ) + 1 )	// 
	parameter	ATsize = 1<<(ATlayer),			// 
	parameter	logW = 9,						// ïï
	parameter	ADDR_WIDTH = 9,					// 
	parameter	DATA_WIDTH = 32,    			// 
	parameter	FRAC_WIDTH = 16,				// 
	parameter	DATA_UNIT = {{(DATA_WIDTH-FRAC_WIDTH-1){1'B0}}, 1'B1, {FRAC_WIDTH{1'B0}}}, // 1 
	parameter	DATA_ZERO = {DATA_WIDTH{1'B0}},	// 0
	parameter	DATA_MINF = {1'B1, {(DATA_WIDTH-1){1'B0}}},	// 
	parameter	DATA_PINF = {1'B0, {(DATA_WIDTH-1){1'B1}}}	// 
)
(
	clk, 
	rst,
	// 
	kernel_clr,
	kernel_m,
	kernel_n,
	kernel_data,
	kernel_data_valid,
	//
	width,
	read_data,
	read_data_valid,
	//
	write_data,
	write_data_valid,
	// conv/pool
	arith_type,
	pool_type,
	// 
	pool_opt_col
);

/*-------------------------------------------------------------------*\
	functions
\*-------------------------------------------------------------------*/
function integer CeilLog2;
	input	[31:0]	size;
	integer i;
begin	
	CeilLog2 = 1;
	for ( i = 1; 2 ** i < size; i = i + 1 )
		CeilLog2 = i + 1;
end		
endfunction

/*-------------------------------------------------------------------*\
	I/O signals
\*-------------------------------------------------------------------*/
input	wire						clk, rst;				// /
input	wire						kernel_clr;				// 
input	wire	[ADDR_WIDTH-1:0]	kernel_m;				// 
input	wire	[ADDR_WIDTH-1:0]	kernel_n;				// 
input	wire	[DATA_WIDTH-1:0]	kernel_data;			// 
input	wire						kernel_data_valid;		// 

input	wire	[DATA_WIDTH-1:0]	width;					// 
input	wire	[DATA_WIDTH-1:0]	read_data;				// 
input	wire						read_data_valid;		// 
//
output	reg		[DATA_WIDTH-1:0]	write_data;				// 
output	reg							write_data_valid;		// 
// /
input	wire						arith_type;				// 0-convolution, 1-pooling
input	wire						pool_type;				// 0-mean_pool, 1-max_pool
//
output	reg		[DATA_WIDTH-1:0]	pool_opt_col;
/*-------------------------------------------------------------------*\
	parameters
\*-------------------------------------------------------------------*/
localparam							CONV_TYPE = 1'B0;	
localparam							POOL_TYPE = 1'B1;	
localparam							MEAN_TYPE = 1'B0;
localparam							MAX_TYPE = 1'B1;
/*-------------------------------------------------------------------*\
	signals
\*-------------------------------------------------------------------*/
// 
reg				[ADDR_WIDTH-1:0]	kernel_row;
reg				[ADDR_WIDTH-1:0]	kernel_col;
reg				[ADDR_WIDTH-1:0]	kernel_addr;			// 
reg				[DATA_WIDTH-1:0]	kernel_datax;			// 
reg									kernel_data_validx;		// 
//
reg		signed	[DATA_WIDTH-1:0]	kernel_q	[0:Ksz-1];	// 
//wire	signed	[DATA_WIDTH-1:0]	kernel_qs	[0:Ksz-1];	// 
reg		signed	[DATA_WIDTH-1:0]	field_q		[0:Ksz-1];	// 
//wire	signed	[DATA_WIDTH-1:0]	field_qs	[0:Ksz-1];	// 
reg									field_q_en;					
reg				[DATA_WIDTH-1:0]	field_con_idx[0:Km-1];	// 
//wire			[DATA_WIDTH-1:0]	field_con_idx_s[0:Km-1];// = field_con_idx[0];
reg		signed	[DATA_WIDTH-1:0]	field_data	[0:Km-1];	// 
//wire	signed	[DATA_WIDTH-1:0]	field_data_s[0:Km-1];	// 
reg									field_data_valid	;	// 
// p2p
reg		signed	[DATA_WIDTH-1:0]	field_mult	[0:Ksz-1];	// 	
reg		signed	[2*DATA_WIDTH-1:0]	field_mults	[0:Ksz-1];	// 	
reg									field_zero	[0:Ksz-1];	// 	==0
//wire	signed	[DATA_WIDTH-1:0]	field_mult_s[0:Ksz-1];	// 	
reg									field_mult_en;		
reg									field_mults_en;		
// 
reg		signed	[DATA_WIDTH-1:0]	ATnode 	  [0:ATsize-1];	// 	
//wire	signed	[DATA_WIDTH-1:0]	ATnodes	  [0:ATsize-1];	// 	
reg									ATnode_en [0:ATlayer-1];// 
//wire								ATnode_ens[0:ATlayer-1];// 
// 
reg				[DATA_WIDTH-1:0]	ConvResRow;				// 
reg				[DATA_WIDTH-1:0]	ConvResCol;				// 
reg				[DATA_WIDTH-1:0]	ConvCycRow;				// (0 ~ kernel_m-1)
reg				[DATA_WIDTH-1:0]	ConvCycCol;				// (0 ~ kernel_n-1)
// pooling
reg		signed	[DATA_WIDTH-1:0]	div_numer;				// divider
reg		signed	[DATA_WIDTH-1:0]	div_denom;				// divider
wire	signed	[DATA_WIDTH-1:0]	div_quotient;			// 
wire								div_dst_en;				// 
reg									div_src_en;				// 
// 
wire								write_data_validx;
wire			[DATA_WIDTH-1:0]	opt_colx;
reg									pool_opt_col_rdy;		// 
// shifter taps
reg				[DATA_WIDTH-1:0]	ram_wptr 			;	// ram
reg				[DATA_WIDTH-1:0]	ram_wptr_sync [0:1] ;	// 
reg									ram_wren_sync [0:1] ;	// 
reg				[DATA_WIDTH-1:0]	ram_rptr			;	// ram	// ram_wptr3clock
reg									ram_rden			;	// 
reg				[DATA_WIDTH-1:0]	ram_waddr			;	// ram
wire	signed	[DATA_WIDTH-1:0]	ram_data	[0:Km-1];	// ram
wire			[DATA_WIDTH-1:0]	ram_wraddr	[0:Km-1];	// ram
wire								ram_wrreq	[0:Km-1];	// ram
wire	signed	[DATA_WIDTH-1:0]	ram_q		[0:Km-1];	// ram
wire			[DATA_WIDTH-1:0]	ram_rdaddr	[0:Km-1];	// ram
wire								ram_rdreq	[0:Km-1];	// ram
/*-------------------------------------------------------------------*\
	timing
//
	// Ex. width == 45, kernel_m == 3, kernel_n == 3
	clk				:	_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_
	rst				:	___|-----|________________________________________________________________________________________________________________________
	read_data		:	_________________| d0| d1| d2| d3| d4| d5| d6| d7| d8| d9|d10|d11|...|d33|d34|d35|d36|d37|d38|d39|d40|d41|d42|d43|d44|
	read_data_valid	: 	_________________|------------------------------------------------...------------------------------------------------|_____
	
	ram_wptr		:		 |0																												 | 1
	ram_wraddr[0]	:	_____|0  		     | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10| 11|...| 33| 34| 35| 36| 37| 38| 39| 40| 41| 42| 43| 44| 0 
	ram_rdaddr[0]	:	_____|44			 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10|...| 32| 33| 34| 35| 36| 37| 38| 39| 40| 41| 42| 43| 44
	ram_q[0]		:   _____________|   q44      	 | q0| q1| q2| q3| q4| q5| q6| q7| q8|...|q30|q31|q32|q33|q34|q35|q36|q37|q38|q39|q40|q41|q42|q43|q44
	
	ram_wptr_sync[0]:	_________|0																												 | 1
	ram_wptr_sync[0]:	_____________|0																												 | 1
	ram_rden		: 	_____________________________|------------------------------------------------...------------------------------------------------|_____
	ram_rptr		:	_________________|0																												 | 1
	field_con_idx[0]:	_________________| 1 																											 | 2
	field_con_idx[1]:	_________________| 2 																											 | 3
	field_con_idx[2]:	_________________| 3 																											 | 4
	// 
	field_data[0]	:   _____________________|q44      	 | q0| q1| q2| q3| q4| q5| q6| q7| q8|...|q30|q31|q32|q33|q34|q35|q36|q37|q38|q39|q40|q41|q42|q43|q44
	field_data_valid: 	_________________________________|------------------------------------------------...------------------------------------------------|_____
	// 
	field_q[x]		:   _________________________|q44      	 | q0| q1| q2| q3| q4| q5| q6| q7| q8|...|q30|q31|q32|q33|q34|q35|q36|q37|q38|q39|q40|q41|q42|q43|q44
	field_q_en		: 	_____________________________________|------------------------------------------------...------------------------------------------------|_____
	// 
	field_mults[x]	:   _____________________________|m44      	 | m0| m1| m2| m3| m4| m5| m6| m7| m8|...|m30|m31|m32|m33|m34|m35|m36|m37|m38|m39|m40|m41|m42|m43|m44
	field_mults_en	: 	_________________________________________|------------------------------------------------...------------------------------------------------|_____
	field_mult[x]	:   _________________________________|m44      	 | m0| m1| m2| m3| m4| m5| m6| m7| m8|...|m30|m31|m32|m33|m34|m35|m36|m37|m38|m39|m40|m41|m42|m43|m44
	field_mult_en	: 	_____________________________________________|------------------------------------------------...------------------------------------------------|_____
	// 
	ATnode[#L0]		: 	_________________________________________________| m0| m1| m2| m3| m4| m5| m6| m7| m8|...|m30|m31|m32|m33|m34|m35|m36|m37|m38|m39|m40|m41|m42|m43|m44
	ATnode[#L1]		: 	_____________________________________________________| m0| m1| m2| m3| m4| m5| m6| m7| m8|...|m30|m31|m32|m33|m34|m35|m36|m37|m38|m39|m40|m41|m42|m43|m44
	...
	ATnode[#L4]		: 	_________________________________________________________________| m0| m1| m2| m3| m4| m5| m6| m7| m8|...|m30|m31|m32|m33|m34|m35|m36|m37|m38|m39|m40|m41|m42|m43|m44
	ATnode_en[#L4]	: 	_________________________________________________________________|------------------------------------------------...------------------------------------------------|_____
	// 
	ConvResCol		:	_____|0  		     											     | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10| 11|...| 33| 34| 35| 36| 37| 38| 39| 40| 41| 42| 43| 44| 0 	
	ConvResRow		:	_____|0															    																								 | 1

	ConvCycCol		:	_____|0  		     											     | 1 | 2 | 0 | 1 | 2 | 0 | 1 | 2 | 0 | 1 | 2 |...| 0 | 1 | 2 | 0 | 1 | 2 | 0 | 1 | 2 | 0 | 1 | 2 | 0 	
	ConvCycRow		:	_____|0															    																								 | 1

\*-------------------------------------------------------------------*/

/*-------------------------------------------------------------------*\
	process
\*-------------------------------------------------------------------*/
// 
always @ ( posedge clk )
	if ( kernel_clr == 1'B1 )
	begin
		kernel_row <= 0;
		kernel_col <= 0;
	end
	else if ( kernel_data_valid == 1'B1 )
	begin
		if ( kernel_col >= ( kernel_n - 1 ) )
		begin
			kernel_row <= kernel_row + 1;
			kernel_col <= 0;
		end
		else
			kernel_col <= kernel_col + 1;
	end
// 
always @ ( posedge clk )
begin
	kernel_addr 		<= ( kernel_row * Kn + kernel_col );
	kernel_datax		<= kernel_data;
	kernel_data_validx	<= kernel_data_valid;
end
// 
genvar	ki;
genvar 	kj;
generate
	for ( ki = 0; ki < Km; ki = ki + 1 )
	begin : conv_kernel_row
		for ( kj = 0; kj < Kn; kj = kj + 1 )
		begin : conv_kernel_col
			always @ ( posedge clk )
			begin
				if ( kernel_clr == 1'B1 )
				begin
					if ( arith_type == CONV_TYPE )
						kernel_q[ki*Kn+kj] 		<= DATA_ZERO;
					else if ( arith_type == POOL_TYPE && pool_type == MEAN_TYPE )
					begin
						if (( ki < kernel_m ) && ( kj < kernel_n ))
							kernel_q[ki*Kn+kj] 	<= DATA_UNIT;
						else
							kernel_q[ki*Kn+kj] 	<= DATA_ZERO;
					end
					else if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE )
						kernel_q[ki*Kn+kj] 	<= DATA_UNIT;
				end
				else if ( kernel_addr == ( ki*Kn+kj ) && kernel_data_validx == 1'B1)
					kernel_q[ki*Kn+kj] 			<= kernel_datax;
			end	
			//
			//assign	kernel_qs[ki*Kn+kj]			= kernel_q[ki*Kn+kj];
		end
	end
endgenerate
// ramïshifter-taps
// wraddr
always @ ( posedge clk )
begin	
	if ( rst == 1'B1 )
	begin
		ram_waddr 		<= 0;
		ram_wptr		<= 0;
	end
	else if ( read_data_valid )
	begin
		if ( ram_waddr >= ( width - 1) )
		begin
			ram_waddr	<= 0;
			//
			if ( ram_wptr >= (kernel_m - 1) )
				ram_wptr <= 0;
			else
				ram_wptr <= ram_wptr + 1'B1;
		end
		else
			ram_waddr	<= ram_waddr + 1;
	end
end
// 3clock
always @ ( posedge clk )
begin
	//
	ram_rden			<= ram_wren_sync[1];
	ram_wren_sync[1]	<= ram_wren_sync[0];
	ram_wren_sync[0] 	<= read_data_valid;
	//
	ram_rptr			<= ram_wptr_sync[1];
	ram_wptr_sync[1] 	<= ram_wptr_sync[0];
	ram_wptr_sync[0]	<= ram_wptr;
	//
end
// ram_q[x]  ===[Km, ram_rptr]==> field_data[y]
//				x = (ram_rptr - y + kernel_m)%kernel_m
genvar 		y;
generate
	for ( y = 0; y < Km; y = y + 1 )
	begin : connect
		always @ ( posedge clk )
		begin : index
			if ( y < kernel_m )
			begin
				if ((( ram_wptr_sync[1] + kernel_m - y ) == kernel_m ) || (( ram_wptr_sync[1] + kernel_m - y ) == ( kernel_m <<< 1 )))
					field_con_idx[y] <= 0;
				else if((( ram_wptr_sync[1] + kernel_m - y ) > kernel_m ) && (( ram_wptr_sync[1] + kernel_m - y ) < ( kernel_m <<< 1 )))
					field_con_idx[y] <= ( ram_wptr_sync[1] + kernel_m - y - kernel_m );
				else
					field_con_idx[y] <= ( ram_wptr_sync[1] + kernel_m - y );
			end
			else
				field_con_idx[y] 	 <= 0;
		end
		//
		//assign	field_con_idx_s[y] 	= field_con_idx[y];
		//assign	field_data_s[y] 	= field_data[y];
		//
		always @ ( posedge clk )
		begin : value
			//
			field_data[y] 		<= ram_q[field_con_idx[y]];
		end
	end
endgenerate

always @ ( posedge clk )
	field_data_valid	<= ram_rden;
	
// 
genvar 		convi;
genvar 		convj;
generate
	for ( convi = 0; convi < Km; convi = convi + 1 )
	begin : conv_row
		for ( convj = 0; convj < Kn; convj = convj + 1 )
		begin : conv_col
			begin : construct
				if ( convj == 0 )
					// 0
					always @ ( posedge clk )
					begin
						if ( rst == 1'B1 )
						begin
							if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE )
								field_q[convi*Kn+convj] <= DATA_MINF;
							else
								field_q[convi*Kn+convj] <= DATA_ZERO;
						end
						else 
						begin
							if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE )
							begin
								if ( field_data_valid == 1'B1 && convi < kernel_m )
									field_q[convi*Kn+convj] <= field_data[convi];
								else if ( field_data_valid == 1'B1 && convi >= kernel_m )
									field_q[convi*Kn+convj] <= DATA_MINF;
							end
							else
							begin
								if ( field_data_valid == 1'B1 )
									field_q[convi*Kn+convj] <= field_data[convi];
							end
						end
					end
				else
				begin
					// 1...Kn-1
					always @ ( posedge clk )
					begin
						if ( rst == 1'B1 )
						begin
							if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE )
								field_q[convi*Kn+convj] <= DATA_MINF;
							else
								field_q[convi*Kn+convj] <= DATA_ZERO;
						end
						else 
						begin
							if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE )
							begin
								if ( field_data_valid == 1'B1 && convj < kernel_n )
									field_q[convi*Kn+convj] <= field_q[convi*Kn+convj-1];
								else if ( field_data_valid == 1'B1 && convj >= kernel_n )
									field_q[convi*Kn+convj] <= DATA_MINF;
							end
							else
							begin
								if ( field_data_valid == 1'B1 )
									field_q[convi*Kn+convj] <= field_q[convi*Kn+convj-1];
							end
						end
					end
				end
				//
				//assign		field_qs[convi*Kn+convj] = field_q[convi*Kn+convj];
			end
		end
	end
endgenerate
// 
always @ ( posedge clk )
	field_q_en <= field_data_valid;
	
// 
genvar 	pts;
generate
	for ( pts = 0; pts < Ksz; pts = pts + 1 )
	begin : multi
		// 
		always @ ( posedge clk )
		begin
			field_mults[pts] 	<= field_q[pts] * kernel_q[pts];
			field_zero[pts] 	<= ( kernel_q[pts] == DATA_ZERO );
		end
		// 
		always @ ( posedge clk )
		begin
			field_mult[pts] <= ( field_zero[pts] == 1'B1 )? DATA_ZERO : field_mults[pts][DATA_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
		end
		// 
		//assign	field_mult_s[pts] = field_mult[pts];
	end
endgenerate

always @ ( posedge clk )
begin
	field_mult_en 	<= field_mults_en;
	field_mults_en 	<= field_q_en;
end
	
// 
genvar 	at_layer;
genvar	at_node_idx;
generate
	for ( at_layer = 0; at_layer < ATlayer; at_layer = at_layer + 1 )
	begin : ATtree
		//
		//assign	ATnode_ens[ at_layer ] = ATnode_en[ at_layer ];
		// 0ï
		if ( at_layer == 0 )
		begin
			for ( at_node_idx = 0; at_node_idx < ( ATsize >> ( 1 + at_layer )); at_node_idx = at_node_idx + 1 )
			begin : layer_0
				always @ ( posedge clk )
				begin
					if ( rst == 1'B1 )
					begin
						if ( arith_type == CONV_TYPE )
							ATnode[ at_node_idx ] <= DATA_ZERO;
						else if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE)
							ATnode[ at_node_idx ] <= DATA_MINF;
						else
							ATnode[ at_node_idx ] <= DATA_ZERO;
					end
					else if ( at_node_idx < Ksz && field_mult_en == 1'B1 )
						ATnode[ at_node_idx ] <= field_mult[ at_node_idx ];
				end
			
				//assign	ATnodes[ at_node_idx ] = ATnode[ at_node_idx ];
				
			end
			
			always @ ( posedge clk )
				ATnode_en[ at_layer ] <= field_mult_en;
		end
		// 
		/*
		*/
		else 
		begin
			for ( at_node_idx = 0; at_node_idx < ( ATsize >> ( 1 + at_layer )); at_node_idx = at_node_idx + 1 )
			begin : layer_else
				always @ ( posedge clk )
				begin
					if ( rst == 1'B1 )
					begin
						if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE )
							ATnode[ ATsize - ( ATsize >> ( at_layer )) + at_node_idx ] <= DATA_MINF;
						else
							ATnode[ ATsize - ( ATsize >> ( at_layer )) + at_node_idx ] <= DATA_ZERO;
					end
					else
					begin
						if ( arith_type == POOL_TYPE && pool_type == MAX_TYPE )
							ATnode[ ATsize - ( ATsize >> ( at_layer )) + at_node_idx ] <= 
								( ATnode[ ATsize - ( ATsize >> ( at_layer - 1 )) + ( at_node_idx <<< 1 )] > ATnode[ ATsize - ( ATsize >> ( at_layer - 1 )) + ( at_node_idx <<< 1 ) +1 ] )?
									ATnode[ ATsize - ( ATsize >> ( at_layer - 1 )) + ( at_node_idx <<< 1 )] : 
									ATnode[ ATsize - ( ATsize >> ( at_layer - 1 )) + ( at_node_idx <<< 1 ) +1 ];
						else
							ATnode[ ATsize - ( ATsize >> ( at_layer )) + at_node_idx ] <= 
								ATnode[ ATsize - ( ATsize >> ( at_layer - 1 )) + ( at_node_idx <<< 1 )] + 
								ATnode[ ATsize - ( ATsize >> ( at_layer - 1 )) + ( at_node_idx <<< 1 ) +1 ];
					end
				end
				
				//assign	ATnodes[ ATsize - ( ATsize >> ( at_layer )) + at_node_idx ] = ATnode[ ATsize - ( ATsize >> ( at_layer )) + at_node_idx ];
				
			end
			
			always @ ( posedge clk )
				ATnode_en[ at_layer ] <= ATnode_en[ at_layer - 1 ];
		end
	end
endgenerate

// ïpoolïmean-poolï
always @ ( posedge clk )
begin
	if ( rst == 1'B1 && arith_type == POOL_TYPE )
	begin
		div_numer			<= width;
		// mean_pool / 
		div_denom			<= kernel_n;
		div_src_en			<= 1'B1;
	end
	else
	begin
		div_numer			<= ATnode[ ATsize - ( ATsize >> ( ATlayer - 1 ) ) ];
		// mean_pool / 
		div_denom			<= ( arith_type == POOL_TYPE && pool_type == MEAN_TYPE )? {32'D0, ( kernel_m * kernel_n ), {FRAC_WIDTH{1'B0}}} : DATA_UNIT;
		div_src_en			<= ATnode_en[ ATlayer - 1 ];
	end
end
// 
always @ ( posedge clk )
begin
	if ( rst == 1'B1 )
	begin
		ConvResRow 		<= 0;
		ConvResCol		<= 0;
	end
	// ATï
	else if ( pool_opt_col_rdy == 1'B1 && div_dst_en == 1'B1 )
	begin
		if ( ConvResCol >= ( width - 1 ) )
		begin	
			ConvResRow	<= ConvResRow + 1;
			ConvResCol	<= 0;
		end
		else
			ConvResCol	<= ConvResCol + 1;
	end
end
// 
always @ ( posedge clk )
begin
	if ( rst == 1'B1 )
	begin
		ConvCycRow 		<= 0;
		ConvCycCol		<= 0;
	end
	// ATï
	else if ( pool_opt_col_rdy == 1'B1 && div_dst_en == 1'B1 )
	begin
		if ( ConvCycCol >= ( kernel_n - 1 ) || ConvResCol >= ( width - 1 ))
			ConvCycCol	<= 0;
		else
			ConvCycCol	<= ConvCycCol + 1;
		//
		if ( ConvResCol >= ( width - 1 ) )
		begin
			//
			if ( ConvCycRow >= ( kernel_m - 1 ))
				ConvCycRow	<= 0;
			else
				ConvCycRow	<= ConvCycRow + 1;
		end
	end
end


// 
// 
assign	write_data_validx = ( arith_type == CONV_TYPE )? ( pool_opt_col_rdy && div_dst_en && ( ConvResCol >= ( kernel_n - 1 )) && ( ConvResRow >= ( kernel_m - 1 )) ) : 
							( arith_type == POOL_TYPE )? ( pool_opt_col_rdy && div_dst_en && ( ConvCycCol == ( kernel_n - 1 )) && ( ConvCycRow == ( kernel_m - 1 )) ) : 
							1'B0;
// 
always @ ( posedge clk )
begin
	write_data 			<= div_quotient;
	write_data_valid 	<= write_data_validx;
end

// pooloingï
always @ ( posedge clk )
	if ( rst == 1'B1 )
	begin
		if ( arith_type == POOL_TYPE )
			pool_opt_col_rdy 	<= 1'B0;
		else
			pool_opt_col_rdy 	<= 1'B1;
	end
	else if ( pool_opt_col_rdy == 1'B0 && div_dst_en == 1'B1 && arith_type == POOL_TYPE )
	begin
		pool_opt_col 			<= div_quotient>>>FRAC_WIDTH;
		pool_opt_col_rdy 		<= 1'B1;
	end

/*-------------------------------------------------------------------*\
	instances
\*-------------------------------------------------------------------*/
// 
// 
fixed_sdiv	u0_fixed_sdiv
(
	.sys_clk			( clk 				),
	.sys_rst_n			( !rst				),
	.numer				( div_numer			),
	.denom				( div_denom			),
	.quotient			( div_quotient		),
	.src_en				( div_src_en		),
	.dst_en				( div_dst_en		)
);

// 
genvar	rami;
generate
	for ( rami = 0; rami < Km; rami = rami + 1 )
	begin : ram
		//
		assign			ram_wraddr[rami]	= ram_waddr;
		assign			ram_data[rami] 		= read_data;
		assign			ram_wrreq[rami]		= read_data_valid && ( ram_wptr == rami );
		assign			ram_rdreq[rami] 	= 1'B1;
		assign			ram_rdaddr[rami]	= ( ram_wraddr[rami]==0 )? ( width - 1'B1 ) : ( ram_wraddr[rami] - 1'B1 );
		dpram_2p u_dpram_2p 
		(
			.wrclock	( clk 				),
			.data		( ram_data[rami] 	),
			.wrreq		( ram_wrreq[rami]	),
			.wraddr		( ram_wraddr[rami]	),
			.rdclock	( clk 				),
			.q			( ram_q[rami] 		),
			.rdreq		( ram_rdreq[rami]	),
			.rdaddr		( ram_rdaddr[rami]	)
		);
	end
endgenerate

endmodule