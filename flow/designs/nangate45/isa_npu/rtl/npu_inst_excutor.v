//----------------------------------------------------------------------------------------------------------
//	FILE: 		npu_inst_excutor.v
// 	AUTHOR:		Xudong Chen
// 	
//	ABSTRACT:	behavior of the rtl module of ISA-NPU
// 	KEYWORDS:	fpga, ISA, NPU
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Xudong Chen		18/3/9		original, CONVïTRAN
//										CNN:ALMï3631.8 / M10Kï19 / DSPï46 / Fmaxï54.67 MHz
//										Cyclone V series, SoC FPGA
//			Xudong Chen		18/3/10		CNNïpython/matlab
//			Xudong Chen		18/3/13		CNNïDDR100%
//										CNN:ALMï3487.9 / M10Kï25 / DSPï42 / Fmaxï71.21 MHz
//			Xudong Chen		18/5/16		$1FIFO$3ïïï
//										ïCyclone IV
//										LEï16.4 K	/ M9Kï18 / DSPï110 / Fmaxï> 50 Mhz
//			Xudong Chen		18/5/24		CNNNPUï
//			Xudong			18/7/16		ram/fifomodule
//			Xudong			18/7/26		module
//-----------------------------------------------------------------------------------------------------------
// CNN
module npu_inst_excutor
#(parameter	DATA_WIDTH = 32,    // 
  parameter	FRAC_WIDTH = 16,	// 
  parameter RAM_LATENCY = 2,	// ramIP
  parameter MAC_LATENCY = 2,	// ramIP
  parameter	DIV_LATENCY = 50,	// 
  parameter	DMI_LATENCY = 2,	// 
  parameter	DATA_UNIT = {{(DATA_WIDTH-FRAC_WIDTH-1){1'B0}}, 1'B1, {FRAC_WIDTH{1'B0}}}, // 1 
  parameter	DATA_ZERO = {DATA_WIDTH{1'B0}},	// 0
  parameter	INST_WIDTH = 128	// 
)
(
	input	wire						clk, rst_n,	// 
	input	wire	[INST_WIDTH-1:0]	npu_inst,	// CNN
	input	wire						npu_inst_en,	// 
	output	reg							npu_inst_ready,	// 
	output	reg		[DATA_WIDTH-1:0]	npu_inst_time,	// 
	// DDR
	output	wire						DDR_WRITE_CLK,
	output	wire	[DATA_WIDTH-1:0]	DDR_WRITE_ADDR,
	output	wire	[DATA_WIDTH-1:0]	DDR_WRITE_DATA,
	output	wire						DDR_WRITE_REQ,
	input	wire						DDR_WRITE_READY,
	output	wire						DDR_READ_CLK,
	output	wire	[DATA_WIDTH-1:0]	DDR_READ_ADDR,
	output	wire						DDR_READ_REQ,
	input	wire						DDR_READ_READY,
	input	wire	[DATA_WIDTH-1:0]	DDR_READ_DATA,
	input	wire						DDR_READ_DATA_VALID
);
	
	// ddr
	reg		[31:0]	ddr_read_addr;
	reg				ddr_read_req;
	wire			ddr_read_ready;
	wire	[31:0]	ddr_read_data;
	wire			ddr_read_data_valid;
	reg		[31:0]	ddr_write_addr;
	wire			ddr_write_req;
	wire			ddr_write_ready;
	wire	[31:0]	ddr_write_data;
	///////////
	assign			DDR_WRITE_CLK = clk;
	assign			DDR_WRITE_ADDR = ddr_write_addr;
	assign			DDR_WRITE_DATA = ddr_write_data;
	assign			DDR_WRITE_REQ = ddr_write_req;
	assign			ddr_write_ready = DDR_WRITE_READY;
	
	wire			ddr_write_data_valid = ddr_write_ready && ddr_write_req;	// 
	//
	assign			DDR_READ_CLK = clk;
	assign			DDR_READ_ADDR = ddr_read_addr;
	assign			DDR_READ_REQ = ddr_read_req;
	assign			ddr_read_ready = DDR_READ_READY;
	assign			ddr_read_data = DDR_READ_DATA;
	assign			ddr_read_data_valid = DDR_READ_DATA_VALID;
	
	//
	reg		[31:0]	ddr_write_row;	// DDR
	reg		[31:0]	ddr_write_col;	// DDR
	
	///////////////
	
/* CNN

	[127:124][123:92][91:60][59:28][27:0]
		OP 		$1		$2		$3		MNPK
						
ADD		0		$1		$2		$3		M/N/0/0		==> $3 = $1+$2
ADDi	1		$1		i		$3		M/N/0/0		==> $3 = $1+i
SUB		2		$1		$2		$3		M/N/0/0		==> $3 = $1-$2
SUBi	3		$1		i		$3		M/N/0/0		==> $3 = $1-i
MULT	4		$1		$2		$3		M/N/P/0		==> $3 = $1x$2
MULTi	5		$1		i		$3		M/N/0/0		==> $3 = $1xi
DOT		6		$1		$2		$3		M/N/0/0		==> $3 = $1.$2
CONV	7		$1		$2		$3		M/N/Km/Kn	==> $3 = $1*$2
POOL	8		$1		mode	$3		M/N/Pm/Pn	==> $3 = pooling($1)	// mode = max/mean
SIGM	9		$1		xx		$3		M/N/0/0		==> $3 = sigmoid($1)
RELU	10		$1		xx		$3		M/N/0/0		==> $3 = ReLU($1)
TANH	11		$1		xx		$3		M/N/0/0		==> $3 = tanh($1)
GRAY	12		$1		xx		$3		M/N/0/0		==> $3 = gray($1)	// RGB565-->
TRAN	13		$1		xx		$3		M/N/0/0		==> $3 = tran($1)	// 
ADDs	14		$1		$2		$3		M/N/0/0		==> $3 = $1 + $2 x ones(M, N)	// matrixscalar
SUBs	15		$1		$2		$3		M/N/0/0		==> $3 = $1 - $2 x ones(M, N)	// matrixscalar
*/
	parameter		ADD = 0;		// 
	parameter		ADDi = 1;		// 
	parameter		SUB = 2;		// 
	parameter		SUBi = 3;		// 
	parameter		MULT = 4;		// 
	parameter		MULTi = 5;		// 
	parameter		DOT = 6;		// 
	parameter		CONV = 7;		// 2D
	parameter		POOL = 8;		// 2D
	parameter		SIGM = 9;		// sigmoid
	parameter		RELU = 10;		// ReLU
	parameter		TANH = 11;		// tanh
	parameter		GRAY = 12;		// RGB--
	parameter		TRAN = 13;		// 
	parameter		ADDs = 14;		// +
	parameter		SUBs = 15;		// -

	reg		[3:0]	OP;	// 
	reg		[31:0]	Dollar1;	// 1
	reg		[31:0]	Dollar2;	// 2
	reg		[31:0]	Dollar3;	// 3
	reg		[8:0]	M;	// 1
	reg		[8:0]	N;	// 1	/ 2
	reg		[8:0]	P;	// 2
	reg		[4:0]	Km, Kn;	// 
	reg		[4:0]	Pm, Pn;	// 
	reg		[127:0]	OP_EN;	// OP
	//
	reg		[31:0]	IMM;	// 
	reg		[31:0]	MODE;	// POOLï[0] / maxpool[1]
	reg		signed	[31:0]	SCALAR;	// $2
	// CNN
	always @(posedge clk)
	begin
		OP_EN <= {OP_EN[126:0], npu_inst_en};
		if(npu_inst_en)
		begin
			OP <= npu_inst[127:124];
			Dollar1 <= npu_inst[123:92];
			Dollar2 <= npu_inst[91:60];
			Dollar3 <= npu_inst[59:28];
			M <= npu_inst[27:19];
			N <= npu_inst[18:10];
			P <= npu_inst[9:1];
			Km <= npu_inst[9:5];
			Kn <= npu_inst[4:0];
			Pm <= npu_inst[9:5];
			Pn <= npu_inst[4:0];
			IMM <= npu_inst[91:60];
			MODE <= npu_inst[91:60];	
		end
	end
	
	// 	// $1/$2ïDDRïburstïï
	//   $3ïDDR
	wire	[31:0]		npu_scfifo_Dollar1_q;
	wire				npu_scfifo_Dollar1_rdreq;
	wire				npu_scfifo_Dollar1_rdempty;
	wire	[8:0]		npu_scfifo_Dollar1_rdusedw;
	wire	[31:0]		npu_scfifo_Dollar1_data;
	wire				npu_scfifo_Dollar1_wrreq;
	wire	[31:0]		npu_scfifo_Dollar2_q;
	reg					npu_scfifo_Dollar2_rdreq;
	wire				npu_scfifo_Dollar2_rdempty;
	wire	[8:0]		npu_scfifo_Dollar2_rdusedw;
	wire	[31:0]		npu_scfifo_Dollar2_data;
	wire				npu_scfifo_Dollar2_wrreq;
	wire	[31:0]		npu_scfifo_Dollar3_q;
	wire				npu_scfifo_Dollar3_rdreq;
	wire				npu_scfifo_Dollar3_rdempty;
	wire	[8:0]		npu_scfifo_Dollar3_rdusedw;
	// $1FIFO$3ïïï
	// 
	reg		[31:0]		npu_scfifo_Dollar3_data;
	reg					npu_scfifo_Dollar3_wrreq;
	sc_fifo				#(
							.LOG2N(9),
							.DATA_WIDTH(DATA_WIDTH)
						)
						npu_scfifo_Dollar1(
							.aclr(!rst_n),
							.clock(clk),
							.data(npu_scfifo_Dollar1_data),
							.rdreq(npu_scfifo_Dollar1_rdreq),
							.wrreq(npu_scfifo_Dollar1_wrreq),
							.empty(npu_scfifo_Dollar1_rdempty),
							.full(),
							.q(npu_scfifo_Dollar1_q),
							.usedw(npu_scfifo_Dollar1_rdusedw)
						);
	sc_fifo				#(
							.LOG2N(9),
							.DATA_WIDTH(DATA_WIDTH)
						)
						npu_scfifo_Dollar2(
							.aclr(!rst_n),
							.clock(clk),
							.data(npu_scfifo_Dollar2_data),
							.rdreq(npu_scfifo_Dollar2_rdreq),
							.wrreq(npu_scfifo_Dollar2_wrreq),
							.empty(npu_scfifo_Dollar2_rdempty),
							.full(),
							.q(npu_scfifo_Dollar2_q),
							.usedw(npu_scfifo_Dollar2_rdusedw)
						);
	sc_fifo				#(
							.LOG2N(9),
							.DATA_WIDTH(DATA_WIDTH)
						)
						npu_scfifo_Dollar3(
							.aclr(!rst_n),
							.clock(clk),
							.data(npu_scfifo_Dollar3_data),
							.rdreq(npu_scfifo_Dollar3_rdreq),
							.wrreq(npu_scfifo_Dollar3_wrreq),
							.empty(npu_scfifo_Dollar3_rdempty),
							.full(),
							.q(npu_scfifo_Dollar3_q),
							.usedw(npu_scfifo_Dollar3_rdusedw)
						);
						
	//////////////////////////////////////////////////////////////////////////////////					
	// FSMCNN
	reg		[5:0]	cstate;
	reg		[5:0]	substate;
	reg		[5:0]	delay;
	reg		[31:0]	GPC0;	//  -- general proposal counter
	reg		[31:0]	GPC1;	//  -- general proposal counter
	reg		[31:0]	GPC2;	//  -- general proposal counter
	reg		[31:0]	GPC3;	//  -- general proposal counter
	reg		[31:0]	GPC4;	//  -- general proposal counter
	reg		[31:0]	GPC5;	//  -- general proposal counter
	parameter		IDLE = 0;	// 
	parameter		ExADD = 1;	// 
	parameter		ExADDi = 2;	// 
	parameter		ExSUB = 3;	// 
	parameter		ExSUBi = 4;	// 
	parameter		ExMulti = 5;	// 
	parameter		ExMult = 6;	// 
	parameter		ExDOT = 7;	// 
	parameter		ExConv = 8;	// 
	parameter		ExPool = 9;	// pooling
	parameter		ExReLU = 11;	// ReLU
	parameter		ExSigmoid = 10;	// sigmoid
	parameter		ExTanh = 12;	// tanh
	parameter		ExTran = 14;	// 
	parameter		ExGray = 13;	// 
	parameter		ExADDs = 15;	// +
	parameter		ExSUBs = 16;	// -
	always @(posedge clk)
		if(!rst_n)
			reset_system_task;
		else
		begin
			case(cstate)
				// 
				IDLE: begin
					idle_task;
				end
				
				// 
				ExADD: begin
					ex_add_sub_task;
				end
				
				// 
				ExSUB: begin
					ex_add_sub_task;
				end
				
				// 
				ExADDi: begin
					ex_add_sub_imm_task;
				end
				
				// 
				ExSUBi: begin
					ex_add_sub_imm_task;
				end
				
				// ReLU
				ExReLU: begin
					ex_add_sub_imm_task;	// 
				end
				
				
				// sigmoid
				ExSigmoid: begin
					ex_add_sub_imm_task;	// 
				end
				
				
				// tanh
				ExTanh: begin
					ex_add_sub_imm_task;	// 
				end
				
				// 
				ExDOT: begin
					ex_add_sub_task;	// 
				end
				
				// 
				ExMulti: begin
					ex_add_sub_imm_task;	// 
				end
				
				// 2-D(3x3validï)
				ExConv: begin
					ex_conv_task;	// 
				end
				
				// poolingï2x2poolingï
				ExPool: begin
					ex_pool_task;	// pooling
				end
				
				// 
				ExMult: begin
					ex_mult_task;	// 
				end
				
				// 
				ExTran: begin
					ex_tran_task;	// 
				end
				
				// RGB565
				ExGray: begin
					ex_add_sub_imm_task;	// 
				end
					
				// 
				ExADDs: begin
					ex_add_sub_scalar_task;	//
				end
				
				// -
				ExSUBs: begin
					ex_add_sub_scalar_task;	//
				end
				
				//
				default: begin
					reset_system_task;
				end
			endcase
			
		end
////////////////////////////////////////////////
// 
	//  
	wire		[31:0]			ddr_read_data_rho;	// 
	reg			[127:0]			ddr_read_data_valid_shifter;	// 
	// 2018-04-05: bugïnpu_inst_shifterddr_read_data_valid_shifterïï
	always @(posedge clk)
		if(npu_inst_en)
			ddr_read_data_valid_shifter <= 0;
		else
			ddr_read_data_valid_shifter <= {ddr_read_data_valid_shifter[126:0], ddr_read_data_valid};
	// 
	cordic_tanh_sigm_rtl		cordic_tanh_sigm_rtl_inst(
									.sys_clk(clk),
									.sys_rst_n(rst_n),
									.src_x(ddr_read_data),
									.rho(ddr_read_data_rho),
									.algorithm({(OP==TANH), (OP==SIGM)})
								);

	wire	signed	[31:0]		dot_a = (cstate==ExMulti)? IMM : npu_scfifo_Dollar1_q;
	wire	signed	[31:0]		dot_b = ddr_read_data;
	wire	signed	[63:0]		dot_c = dot_a * dot_b;
	// 
	//////////////////////////////////////////////////////////////////////////////////
	// ï$1
	wire	[31:0]		npu_ram_inst_4_q;
	wire				npu_ram_inst_4_wren;
	wire	[31:0]		npu_ram_inst_4_data;
	reg		[8:0]		npu_ram_inst_4_wraddress;
	reg		[8:0]		npu_ram_inst_4_rdaddress;
	dpram_2p  npu_ram_256pts_inst_4(
							.wrclock(clk),
							.rdclock(clk),
							.data(npu_ram_inst_4_data),
							.rdaddr(npu_ram_inst_4_rdaddress),
							.wraddr(npu_ram_inst_4_wraddress),
							.wrreq(npu_ram_inst_4_wren),
							.rdreq(1),
							.q(npu_ram_inst_4_q)
						);
	// $1RAM
	always @(posedge clk)
		if(cstate==ExMult && substate==0)
			npu_ram_inst_4_wraddress <= 0;
		else if(cstate==ExMult && substate<=2 && ddr_read_data_valid)
			npu_ram_inst_4_wraddress <= npu_ram_inst_4_wraddress + 1;	// 1
	
	assign	npu_ram_inst_4_wren = (cstate==ExMult && substate<=2 && ddr_read_data_valid);
	assign	npu_ram_inst_4_data = ddr_read_data;
	
	// MAC
	always @(posedge clk)
		if(cstate==ExMult && substate<=2)
			npu_ram_inst_4_rdaddress <= 0;
		else if(cstate==ExMult && substate>=3)
		begin
			if(ddr_read_data_valid)
				if(npu_ram_inst_4_rdaddress>=(N-1))
					npu_ram_inst_4_rdaddress <= 0;
				else
					npu_ram_inst_4_rdaddress <= npu_ram_inst_4_rdaddress + 1;
		end
		
	// ddr_read_data
	reg		[31:0]		ddr_read_data_prev	[0:5];
	integer		l;
	always @(posedge clk)
	begin
		for(l=0; l<5; l=l+1)
			ddr_read_data_prev[l+1] <= ddr_read_data_prev[l];
		ddr_read_data_prev[0] <= ddr_read_data;
	end
	
	// MAC
	reg		[31:0]				vec_mac_elem_cnt;
	always @(posedge clk)
		if(cstate==ExMult && (substate<=2 || substate==8))
			vec_mac_elem_cnt <= 0;
		else if(ddr_read_data_valid_shifter[1])
			vec_mac_elem_cnt <= (vec_mac_elem_cnt>=(N-1))? 0 : vec_mac_elem_cnt + 1;
			
	// MACï
	// 2018-03-09ïbugïMACï
	wire	signed		[31:0]	vec_mac_a = ddr_read_data_prev[1];
	wire	signed		[31:0]	vec_mac_b = npu_ram_inst_4_q;
	wire	signed		[63:0]	vec_mac_c = vec_mac_a*vec_mac_b;
	reg		signed		[31:0]	vec_mac_result;
	reg							vec_mac_result_en;
	always @(posedge clk)
		if(cstate==ExMult && (substate<=2 || substate==8))
			vec_mac_result <= 0;
		else if(ddr_read_data_valid_shifter[1] && vec_mac_elem_cnt>0)
			vec_mac_result <= vec_mac_result + vec_mac_c[DATA_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
		else if(ddr_read_data_valid_shifter[1] && vec_mac_elem_cnt==0)
			vec_mac_result <= vec_mac_c[DATA_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
	
	always @(posedge clk)
		vec_mac_result_en <= (cstate==ExMult && substate>=3 && substate<8) && (ddr_read_data_valid_shifter[1] && vec_mac_elem_cnt==(N-1));
	
	// ï 
	reg		[7:0]	RGB888_R;
	reg		[7:0]	RGB888_G;
	reg		[7:0]	RGB888_B;
	always @(posedge clk)
	begin
		RGB888_R <= {ddr_read_data[15:11], 3'B000};
		RGB888_G <= {ddr_read_data[10:5], 2'B00};
		RGB888_B <= {ddr_read_data[4:0], 3'B000};
	end
	// RGB to YUV
	reg		[16:0]	YUV422_Y_reg;// = 66*RGB888_R + 129 * RGB888_G + 25*RGB888_B;
	reg		[16:0]	YUV422_Cb_reg;// = -38*RGB888_R - 74*RGB888_G + 112*RGB888_B;
	reg		[16:0]	YUV422_Cr_reg;// = 112*RGB888_R - 94*RGB888_G - 18*RGB888_B;
	// set_multicycle_path -- ï
	// ï 5CSEBA6U23I7 ïï65MHz(Fmax=81.63MHz)
	// ïMAC * / +  ==> 171.79MHz
	reg		[16:0]	RGB888_R_66;
	reg		[16:0]	RGB888_R_38;
	reg		[16:0]	RGB888_R_112;
	reg		[16:0]	RGB888_G_129;
	reg		[16:0]	RGB888_G_74;
	reg		[16:0]	RGB888_G_94;
	reg		[16:0]	RGB888_B_25;
	reg		[16:0]	RGB888_B_112;
	reg		[16:0]	RGB888_B_18;
	reg		[8:0]	YUV422_Y;
	reg		[8:0]	YUV422_Cb;
	reg		[8:0]	YUV422_Cr;
	always @(posedge clk)
	begin
		RGB888_R_66 <= 9'D66*RGB888_R;
		RGB888_R_38 <= 9'D38*RGB888_R;
		RGB888_R_112 <= 9'D112*RGB888_R;
		RGB888_G_129 <= 9'D129*RGB888_G;
		RGB888_G_74 <= 9'D74*RGB888_G;
		RGB888_G_94 <= 9'D94*RGB888_G;
		RGB888_B_25 <= 9'D25*RGB888_B;
		RGB888_B_112 <= 9'D112*RGB888_B;
		RGB888_B_18 <= 9'D18*RGB888_B;
		
		YUV422_Y_reg <= RGB888_R_66 + RGB888_G_129 + RGB888_B_25;
		YUV422_Cb_reg <= - RGB888_R_38 - RGB888_G_74 + RGB888_B_112;
		YUV422_Cr_reg <= RGB888_R_112 - RGB888_G_94 - RGB888_B_18;
		
		// 
		YUV422_Y <= (YUV422_Y_reg>>>8) + 16;	// 16~235
		YUV422_Cb <= (YUV422_Cb_reg>>>8) + 128;	// 16~240
		YUV422_Cr <= (YUV422_Cr_reg>>>8) + 128;	// 16~240
			
	end
	
	wire	[7:0]	YUV422_Y_valid = (YUV422_Y<16)? 16 : (YUV422_Y>235)? 235 : YUV422_Y;
	wire	[7:0]	YUV422_Cb_valid = (YUV422_Cb<16)? 16 : (YUV422_Cb>240)? 240 : YUV422_Cb;
	wire	[7:0]	YUV422_Cr_valid = (YUV422_Cr<16)? 16 : (YUV422_Cr>240)? 240 : YUV422_Cr;
	///////////////
	// 
	wire	signed	[DATA_WIDTH-1:0]	conv_write_data;
	wire								conv_write_data_valid;
	wire								conv_read_data_valid = (((cstate==ExConv && substate>=2 && substate<7) || (cstate==ExPool)) && ddr_read_data_valid);
	wire								kerl_read_data_valid = ((cstate==ExConv && substate<2) && ddr_read_data_valid);
	// 
	reg				[DATA_WIDTH-1:0]	kernel_m;
	reg				[DATA_WIDTH-1:0]	kernel_n;
	reg				[DATA_WIDTH-1:0]	width;
	reg									arith_type;
	reg									pool_type;
	wire			[DATA_WIDTH-1:0]	pool_opt_col;
	always @ ( posedge clk )
	begin
		if ( OP == CONV )
		begin
			kernel_m 		<= Km;
			kernel_n 		<= Kn;
			arith_type 		<= 1'B0;
			pool_type 		<= 1'B0;
		end
		else if ( OP == POOL )
		begin
			kernel_m 		<= Pm;
			kernel_n 		<= Pn;
			arith_type 		<= 1'B1;
			pool_type 		<= MODE;
		end
		else
		begin
			arith_type 		<= 1'B0;
			pool_type 		<= 1'B0;
		end
		
		width <= N;
	end
	npu_conv_rtl	
	#(
		.Km					( 5 					),
		.Kn					( 5		 				)
	) 	u0_npu_conv_rtl
	(
		.clk				( clk					), 
		.rst				( OP_EN[2]				),
		// 
		.kernel_clr			( OP_EN[2]				),
		.kernel_m			( kernel_m				),
		.kernel_n			( kernel_n				),
		.kernel_data		( ddr_read_data			),
		.kernel_data_valid	( kerl_read_data_valid 	),
		//
		.width				( width					),
		.read_data			( ddr_read_data			),
		.read_data_valid	( conv_read_data_valid	),
		//
		.write_data			( conv_write_data		),
		.write_data_valid	( conv_write_data_valid	),
		//
		.arith_type			( arith_type			),
		.pool_type			( pool_type				),
		//
		.pool_opt_col		( pool_opt_col 			)
	);
	
	/////////// FIFO
	// 2018-05-16: $1FIFO$3ïïï
	assign			npu_scfifo_Dollar1_data = ddr_read_data;
	assign			npu_scfifo_Dollar1_wrreq = ddr_read_data_valid && 
														(	(cstate==ExADD && substate<=2) ||
															(cstate==ExSUB && substate<=2) ||
															(cstate==ExDOT && substate<=2) 
														);
	assign			npu_scfifo_Dollar1_rdreq = ddr_read_data_valid && 
														(	(cstate==ExADD && substate>=3) ||
															(cstate==ExSUB && substate>=3) ||
															(cstate==ExDOT && substate>=3)
														);
	// 
	always @(posedge clk)
	begin
		npu_scfifo_Dollar3_data 				<= 	(cstate==ExADD)? (npu_scfifo_Dollar1_q + ddr_read_data) : 
														(cstate==ExSUB)? (npu_scfifo_Dollar1_q - ddr_read_data) : 
														(cstate==ExDOT)? (dot_c[DATA_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH]) : 
														(cstate==ExADDi)? (ddr_read_data + IMM) : 
														(cstate==ExSUBi)? (ddr_read_data - IMM) : 
														(cstate==ExADDs)? (ddr_read_data + SCALAR) : 
														(cstate==ExSUBs)? (ddr_read_data - SCALAR) : 
														(cstate==ExMult)? vec_mac_result : 
														(cstate==ExConv)? conv_write_data : 
														(cstate==ExPool)? conv_write_data : 
														(cstate==ExTran)? ddr_read_data : 
														(cstate==ExGray)? ({{DATA_WIDTH{1'B0}}, YUV422_Y_valid, {FRAC_WIDTH{1'B0}}}) : 
														(cstate==ExMulti)? (dot_c[DATA_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH]) : 
														(cstate==ExReLU)? (ddr_read_data[31]? 32'H0000_0000 : ddr_read_data) : 
														(cstate==ExSigmoid)? ddr_read_data_rho : 
														(cstate==ExTanh)? ddr_read_data_rho : 
														32'H0000_0000;
		npu_scfifo_Dollar3_wrreq 				<= 	(
															ddr_read_data_valid && 
															(	(cstate==ExADD && substate>=3) ||
																(cstate==ExSUB && substate>=3) ||
																(cstate==ExDOT && substate>=3) ||
																(cstate==ExSUBi) || 
																(cstate==ExADDi) ||
																(cstate==ExMulti) ||
																(cstate==ExTran) ||
																(cstate==ExReLU) ||
																(cstate==ExADDs && substate<3) ||
																(cstate==ExSUBs && substate<3)
															)
														) ||
														(
															ddr_read_data_valid_shifter[38] && 
															(	(cstate==ExSigmoid) ||
																(cstate==ExTanh) 
															)
														) ||
														(
															( cstate==ExConv && conv_write_data_valid ) ||
															( cstate==ExPool && conv_write_data_valid)
														) ||
														(
															ddr_read_data_valid_shifter[2] && 
															(	cstate==ExMult && vec_mac_result_en
															)
														) ||
														(
															ddr_read_data_valid_shifter[3] && 
															(	cstate==ExGray	 	
															)
														);
														
	end													
	
////////////////////////
// gtak
// 	task
task reset_system_task;
begin
	cstate <= IDLE;
	substate <= 0;	// ïFSMFSM
	npu_inst_ready <= 1;	// 
	// DDR
	ddr_read_req <= 0;
	// DDR
	//ddr_write_req <= 0;
	// $1/$2/$3FIFO
	//npu_scfifo_Dollar3_rdreq <= 0;
end
endtask

// task
task idle_task;
begin
	// OP
	if(OP_EN[0])
	begin
		case(OP)
			ADD: begin
				cstate <= ExADD;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			SUB: begin
				cstate <= ExSUB;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			ADDi: begin
				cstate <= ExADDi;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			SUBi: begin
				cstate <= ExSUBi;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			RELU: begin
				cstate <= ExReLU;	//	 RELU
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			SIGM: begin
				cstate <= ExSigmoid;	//	 sigmoid
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			TANH: begin
				cstate <= ExTanh;	//	 tanh
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			DOT: begin
				cstate <= ExDOT;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			MULTi: begin
				cstate <= ExMulti;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			CONV: begin
				cstate <= ExConv;	//	 2D valid
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			POOL: begin
				cstate <= ExPool;	//	 2D valid
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				GPC5 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
				
			MULT: begin
				cstate <= ExMult;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
				
			TRAN: begin
				cstate <= ExTran;	//	 
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			GRAY: begin
				cstate <= ExGray;	//	 RGB565/
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			ADDs: begin
				cstate <= ExADDs;	//	 +
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			SUBs: begin
				cstate <= ExSUBs;	//	 -
				substate <= 0;
				GPC0 <= 0;
				GPC1 <= 0;
				npu_inst_ready <= 0;	// not ready
			end
			
			default: begin
				reset_system_task;
			end
		
		endcase
	end
end
endtask

// /
task ex_add_sub_task;
begin
	case(substate)
		0: begin
			// ADDï 
			if(GPC0>=M)
				reset_system_task;
			// 
			else
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 1;
				ddr_read_addr <= Dollar1 + (GPC0*N);	// $1
				ddr_read_req <= 1;
			end
		end
		
		1: begin
			// $1ï$2
			if(GPC1>=(N-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				substate <= 2;
				ddr_read_req <= 0;	// DDR
			end
			// $1
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + 1;
					ddr_read_req <= 1;
				end
			end
		end
		
		// $1-fifo
		2: begin
			if(npu_scfifo_Dollar1_rdusedw>=N)
			begin
				substate <= 3;
				ddr_read_addr <= Dollar2 + (GPC0*N);	// $2
				ddr_read_req <= 1;
			end
		end
		
		// $2
		3: begin
			if(GPC1>=(N-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 4;
				ddr_read_req <= 0;	// DDR
				// DDR
				//ddr_write_addr <= Dollar3 + (GPC0*N);	// $3
			end
			// $2
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + 1;
					ddr_read_req <= 1;
				end
			end
		end
		
		// $3ïN
		4: begin
			if(ddr_write_data_valid && ddr_write_col>=(N-1))
			begin
				substate <= 0;
				GPC0 <= GPC0 + 1;
				GPC1 <= 0;
				GPC2 <= 0;
			end
		end
		
		// 
		default: begin
			reset_system_task;
		end
	endcase
end
endtask

// 
task ex_add_sub_imm_task;
begin
	case(substate)
		0: begin
			// ADDï 
			if(GPC0>=M)
				reset_system_task;
			// 
			else
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 1;
				ddr_read_addr <= Dollar1 + (GPC0*N);	// $1
				ddr_read_req <= 1;
			end
		end
		
		1: begin
			// $1ï$3
			if(GPC1>=(N-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				substate <= 2;
				ddr_read_req <= 0;	// DDR
				// DDR
				//ddr_write_addr <= Dollar3 + (GPC0*N);	// $3
			end
			// $1
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + 1;
					ddr_read_req <= 1;
				end
			end
		end
		
		
		// $3ïN
		2: begin
			if(ddr_write_data_valid && ddr_write_col>=(N-1))
			begin
				substate <= 0;
				GPC0 <= GPC0 + 1;
				GPC1 <= 0;
				GPC2 <= 0;
			end
		end
		
		// 
		default: begin
			reset_system_task;
		end
	endcase
end
endtask

////////////////////////////////////////////
// 2D-valid
task ex_conv_task;
begin
	case(substate)
		// 
		0: begin
			// ï & 
			if(GPC0>=(Km*Kn))
			begin
				GPC0 <= 0; 
				substate <= 7;
				delay <= 0;
				ddr_read_req <= 0;
			end
			// 
			else
			begin
				substate <= 1;
				ddr_read_addr <= Dollar2 + GPC0;	// $2ïï
				ddr_read_req <= 1;
			end
		end
		
		1: begin
			if(ddr_read_ready)
				ddr_read_req <= 0;
			if(ddr_read_data_valid)
			begin
				GPC0 <= GPC0 + 1;
				substate <= 0;		// 0ïkernel
			end
		end
		
		// ïï
		// rdata_valid[6]ïdelayï
		7: begin
			if(delay>=8)
				substate <= 2;
			else
				delay <= delay + 1;
		end
		
		
		// 
		2: begin
			// ï 
			if(GPC0>=M)
				reset_system_task;
			// 
			else
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 3;
				ddr_read_addr <= Dollar1 + (GPC0*N);	// $1
				ddr_read_req <= 1;
			end
		end
		
		3: begin
			// $1Kmï$3
			// Km
			if(GPC1>=(N-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				GPC0 <= GPC0 + 1;	// 1
				ddr_read_addr <= ddr_read_addr + 1;	//  1
				if(GPC0>=(Km-1))
				begin
					substate <= 4;
					ddr_read_req <= 0;	// DDR
					// DDR
					//ddr_write_addr <= Dollar3 + ((GPC0-Km+1)*(N-Kn+1));	// $3
					GPC2 <= 0;	// GPC2
				end
			end
			// $1
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + 1;
					ddr_read_req <= 1;
				end
			end
		end
		
		
		// $3ïN
		4: begin
			if(ddr_write_data_valid && ddr_write_col>=(N-Kn))
			begin
				substate <= 2;
				GPC1 <= 0;
				GPC2 <= 0;
			end
		end
		
		// 
		default: begin
			reset_system_task;
		end
	endcase
	
	
end
endtask

///////////////////////////////////////////////
// 
task ex_pool_task;
begin
	case(substate)
		// 
		0: begin
			// ï 
			if(GPC0>=M)
				reset_system_task;
			// 
			else
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 1;
				ddr_read_addr <= Dollar1 + (GPC0*N);	// $1
				ddr_read_req <= 1;
			end
		end
		
		1: begin
			// $1ï$3
			if(GPC1>=(N-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				GPC0 <= GPC0 + 1;	// 1
				GPC5 <= GPC5 + 1;	// 1
				ddr_read_addr <= ddr_read_addr + 1;	//  1
				if(GPC0>=(M-1)&& GPC5<(Pm-1))	// 
					reset_system_task;
				else if(GPC5>=(Pm-1))	// 
				begin
					substate <= 2;
					ddr_read_req <= 0;	// DDR
					// DDR
					//ddr_write_addr <= Dollar3 + ((GPC0>>>1)*(N>>>1));	// $3
					GPC2 <= 0;	// GPC2
				end
			end
			// $1
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + 1;
					ddr_read_req <= 1;
				end
			end
		end
		
		// $3ïN
		2: begin
			if(ddr_write_data_valid && ddr_write_col>=(pool_opt_col-1))
			begin
				substate <= 0;
				GPC1 <= 0;
				GPC2 <= 0;
				GPC5 <= 0;
			end
		end
		// 
		default: begin
			reset_system_task;
		end
	endcase
end
endtask

///////////////////////////////////////////////////////////////
// 
task ex_mult_task;
begin
	case(substate)
		0: begin
			// MULTï 
			if(GPC0>=M)
				reset_system_task;
			// 
			else
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 1;
				ddr_read_addr <= Dollar1 + (GPC0*N);	// $1
				ddr_read_req <= 1;
			end
		end
		
		1: begin
			// $1ï$2
			if(GPC1>=(N-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				substate <= 2;
				delay <= 0;
				ddr_read_req <= 0;	// DDR
			end
			// $1
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + 1;
					ddr_read_req <= 1;
				end
			end
		end
		
		// $1-fifo
		2: begin
			if(npu_ram_inst_4_wraddress>=N)
			begin
				//  $2(8ïïbug)
				substate <= 8;
				delay <= 0;
				GPC2 <= 0;
				ddr_read_req <= 0;
			end
		end
		
		//
		8: begin
			if(delay>=5)
				substate <= 3;
			else
				delay <= delay + 1;
		end
		
		// $2
		3: begin
			if(GPC2>=P)
			begin
				substate <= 5;		// ïC
				GPC0 <= GPC0 + 1;
				GPC4 <= 0;	// C
			end
			// 
			else
			begin
				ddr_read_addr <= Dollar2 + GPC2;
				substate <= 4;
				GPC3 <= 0;
				ddr_read_req <= 1;
			end
		end
		
		// 
		4: begin
			if(ddr_read_ready)
			begin
				if(GPC3>=(N-1))
				begin
					substate <= 3;
					GPC2 <= GPC2 + 1;
					ddr_read_req <= 0;	// ddrï
				end
				else
				begin
					GPC3 <= GPC3 + 1;
					ddr_read_addr <= ddr_read_addr + P;
					ddr_read_req <= 1;
				end
			end
		end
		
		// $3ïN
		5: begin
			if(ddr_write_data_valid && ddr_write_col>=(P-1))
			begin
				substate <= 0;
			end
		end
		
		// 
		default: begin
			reset_system_task;
		end
	endcase
end
endtask
////////////////////////////////////////////////////////////////////////////////////

// 
task ex_tran_task;
begin
	case(substate)
		0: begin
			// ADDï 
			if(GPC0>=N)
				reset_system_task;
			// 
			else
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 1;
				ddr_read_addr <= Dollar1 + GPC0;	// $1
				ddr_read_req <= 1;
			end
		end
		
		1: begin
			// $1ï$3
			if(GPC1>=(M-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				substate <= 2;
				ddr_read_req <= 0;	// DDR
				// DDR
				//ddr_write_addr <= Dollar3 + (GPC0);	// $3
			end
			// $1
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + N;	// 
					ddr_read_req <= 1;
				end
			end
		end
		
		
		// $3ïNïïïï
		2: begin
			if(ddr_write_data_valid && ddr_write_col>=(M-1))
			begin
				substate <= 0;
				GPC0 <= GPC0 + 1;
				GPC1 <= 0;
				GPC2 <= 0;
			end
		end
		// 
		default: begin
			reset_system_task;
		end
	endcase
end
endtask

// 
task ex_add_sub_scalar_task;
begin
	case(substate)
		0: begin
			// ADDï 
			if(GPC0>=M)
				reset_system_task;
			// 
			else
			begin
				GPC1 <= 0;
				GPC2 <= 0;
				substate <= 3;
				ddr_read_addr <= Dollar2 ;	// $2
				ddr_read_req <= 1;
			end
		end
		// $2
		3: begin
			if(ddr_read_ready)
			begin
				ddr_read_req <= 0;
				substate <= 4;
			end
		end
		// $2
		4: begin
			if(ddr_read_data_valid)
			begin
				SCALAR <= ddr_read_data;	// 
				ddr_read_addr <= Dollar1 + (GPC0*N);	// $1
				ddr_read_req <= 1;
				substate <= 1;
			end
		end
		
		1: begin
			// $1ï$3
			if(GPC1>=(N-1) && ddr_read_ready)
			begin
				GPC1 <= 0;
				substate <= 2;
				ddr_read_req <= 0;	// DDR
				// DDR
				//ddr_write_addr <= Dollar3 + (GPC0*N);	// $3
			end
			// $1
			else
			begin
				if(ddr_read_ready)
				begin
					GPC1 <= GPC1 + 1;
					ddr_read_addr <= ddr_read_addr + 1;
					ddr_read_req <= 1;
				end
			end
		end
		
		
		// $3ïN
		2: begin
			if(ddr_write_data_valid && ddr_write_col>=(N-1))
			begin
				substate <= 0;
				GPC0 <= GPC0 + 1;
				GPC1 <= 0;
				GPC2 <= 0;
			end
		end
		
		// 
		default: begin
			reset_system_task;
		end
	endcase

end
endtask
/////////////////////////////////////////////////////////////////////////////////////

	// DDR
	assign			ddr_write_data = npu_scfifo_Dollar3_q;
	assign			ddr_write_req = !npu_scfifo_Dollar3_rdempty;
	assign			npu_scfifo_Dollar3_rdreq = ddr_write_data_valid;
	always @(posedge clk)
		if(OP_EN[0])
		begin
			ddr_write_col <= 0;
			ddr_write_row <= 0;
		end
		else
		begin
			if(OP==ADD || OP==SUB || OP==ADDi || OP==SUBi || OP==MULTi || OP==DOT || OP==SIGM || OP==RELU || OP==TANH || OP==GRAY || OP==ADDs || OP==SUBs)
			begin
				if(ddr_write_data_valid)
				begin
					if(ddr_write_col>=(N-1))
					begin
						ddr_write_col <= 0;
						ddr_write_row <= ddr_write_row + 1;
					end
					else
						ddr_write_col <= ddr_write_col + 1;
				end
			end
			else if(OP==MULT)
			begin
				if(ddr_write_data_valid)
				begin
					if(ddr_write_col>=(P-1))
					begin
						ddr_write_col <= 0;
						ddr_write_row <= ddr_write_row + 1;
					end
					else
						ddr_write_col <= ddr_write_col + 1;
				end
			end
			else if(OP==CONV)
			begin
				if(ddr_write_data_valid)
				begin
					if(ddr_write_col>=(N-Kn))
					begin
						ddr_write_col <= 0;
						ddr_write_row <= ddr_write_row + 1;
					end
					else
						ddr_write_col <= ddr_write_col + 1;
				end
			end
			else if(OP==POOL)
			begin
				if(ddr_write_data_valid)
				begin
					if(ddr_write_col>=(pool_opt_col-1))
					begin
						ddr_write_col <= 0;
						ddr_write_row <= ddr_write_row + 1;
					end
					else
						ddr_write_col <= ddr_write_col + 1;
				end
			end
			else if(OP==TRAN)
			begin
				if(ddr_write_data_valid)
				begin
					if(ddr_write_col>=(M-1))
					begin
						ddr_write_col <= 0;
						ddr_write_row <= ddr_write_row + 1;
					end
					else
						ddr_write_col <= ddr_write_col + 1;
				end
			end
		end
		
	// DDR
	always @(posedge clk)
	begin
		if(OP_EN[1])
			ddr_write_addr <= Dollar3;
		else if(ddr_write_data_valid)
			ddr_write_addr <= ddr_write_addr + 1;
	end

////////////////////////////////////////////////////////////////////////////////////

	reg		[31:0]		ddr_write_cnt;	// DDR
	always @(posedge clk)
		if(npu_inst_ready)
			ddr_write_cnt <= 0;
		else if(ddr_write_req && ddr_write_ready)
			ddr_write_cnt <= ddr_write_cnt + 1;

	wire	signed	[31:0]	ddr_write_data_signed = ddr_write_data;
////////////////////////////////////////////////////////////////////////////////////
// 
	always @(posedge clk)
		if(npu_inst_en)
			npu_inst_time <= 0;
		else if(!npu_inst_ready)
			npu_inst_time <= npu_inst_time + 1;
	
endmodule
	