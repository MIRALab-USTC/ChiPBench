//----------------------------------------------------------------------------------------------------------
//	FILE: 		cordic_ln.v
// 	AUTHOR:		Xudong Chen
// 	
//	ABSTRACT:	behavior of the rtl module of ln() function based on CORDIC, pipelined
// 	KEYWORDS:	fpga, CORDIC, ln()
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Xudong Chen		18/5/6		original, implement ln(r) = p*ln(2) + ln(t), 
//										and for numerical stability, 1/4 < t < 1/2
//			Xudong Chen		18/5/19		ï								
//-----------------------------------------------------------------------------------------------------------

module cordic_ln
#(	parameter	DATA_WIDTH = 32,    // 
	parameter 	FRAC_WIDTH = 16,
	parameter	EPSILON = 3,		// 
	parameter 	ITERATION = 8,  // 
	parameter 	ROM_LATENCY = 2,	// romIP
	parameter	DATA_ZERO = {DATA_WIDTH{1'B0}},	// 0
	parameter	DATA_UNIT = {{(DATA_WIDTH-1){1'B0}}, 1'B1, {FRAC_WIDTH{1'B0}}},	// 1
	parameter	LN_2 = 32'D45426,	// ln(2)
	parameter	LN_EPS = -2362156	// ïnp.log(np.finfo(float).eps)*2**16ï
)
(
	input	wire								sys_clk, sys_rst_n,
	input	wire	signed	[DATA_WIDTH-1:0]	r,
	output	reg		signed	[DATA_WIDTH-1:0]	ln_r
);
	
	// KnïPython
	wire	[DATA_WIDTH-1:0]	Kn_THETAn_address;
	wire	[DATA_WIDTH-1:0]	Kn;
	wire	[DATA_WIDTH-1:0]	THETAn;
	cordic_factor_exp_rom_ip 	exp_cordic_rom_ip_core	(.address(Kn_THETAn_address),.clock(sys_clk),.q({Kn, THETAn}));
	//////////////////////////////////
	// tanh^-1(a) = 1/2 * ln^-1((1+a)/(1-a)), and if we let 1+a/1-a = b,
	// then we have: tanh^-1((b-1)/(b+1)) = 1/2 * ln(b)
	// CORDIC
	// reg
	reg		signed 	[DATA_WIDTH-1:0]	Xn	[0:ITERATION-1];	// ï1
	reg		signed 	[DATA_WIDTH-1:0]	Yn	[0:ITERATION-1];	// ï1
	reg		signed 	[DATA_WIDTH-1:0]	Pn	[0:ITERATION-1];	// /ï[1/2, 1]
	reg									LOFn[0:ITERATION];	// 
	// ïZnï
	reg				[DATA_WIDTH-1:0]	Nn	[0:ITERATION+1];	// bugïNn
	// 
	reg		signed 	[DATA_WIDTH-1:0]	Tn	[0:ITERATION-1];
	reg		signed 	[DATA_WIDTH-1:0]	T0n	[0:ITERATION-1];	// ROM
	reg		signed 	[DATA_WIDTH-1:0]	K0n	[0:ITERATION-1];	// ROM
	// 
	reg		[4:0]				cstate;		// 
	parameter					IDLE = 0;	// 
	parameter					LOAD = 1;	// ROM
	parameter					COMP = 2;	// /
	reg		[DATA_WIDTH-1:0]	timer_in_state;	// 
	reg		[DATA_WIDTH-1:0]	rom_address;	// ROM
	// cordic  + &1/4
	always @(posedge sys_clk)
		// 
		if(!sys_rst_n)
			init_system_task;
		// 
		else
		begin
			case(cstate)
				IDLE:		prepare_load_task;
				LOAD:		execute_load_task;
				COMP:		execute_comp_task;	
				default:	init_system_task;
			endcase
		end
///////////////////////////////
// task
integer	n;
// 
task init_system_task;
begin
	cstate <= IDLE;	// 
	// 
	for(n=0; n<ITERATION; n=n+1)
	begin
		Xn[n] <= DATA_ZERO;
		Yn[n] <= DATA_ZERO;
		Pn[n] <= DATA_ZERO;
		Nn[n] <= DATA_ZERO;
		Tn[n] <= DATA_ZERO;
		LOFn[n] <= 0;
	end
	// 
	timer_in_state <= DATA_ZERO;
	// rom
	rom_address <= 0;
end
endtask
////////////////////
// IDLEïloadï
// romlatency
task prepare_load_task;
begin	
	// ïrom
	if(timer_in_state>=(ROM_LATENCY-1))
	begin
		cstate <= LOAD;
		// 
		timer_in_state <= DATA_ZERO;
	end
	// ïROM
	else
	begin
		timer_in_state <= timer_in_state+1;
	end
	// rom
	rom_address <= rom_address+1;
end
endtask
// LOADïload
task execute_load_task;
begin	
	// ïï
	if(timer_in_state>=(ITERATION))
	begin
		cstate <= COMP;
		// 
		timer_in_state <= DATA_ZERO;
	end
	else
	begin
		// ïrom
		T0n[timer_in_state] <= THETAn;
		K0n[timer_in_state] <= Kn;
		rom_address <= rom_address+1;
		timer_in_state <= timer_in_state+1;
	end
end
endtask
// ïcordic
reg		[DATA_WIDTH-1:0]	rx;
always @(posedge sys_clk)
	rx <= r[DATA_WIDTH-1]? (~r+1) : r;
task execute_comp_task;
begin
	// 
	// casexï
	casex(rx)
		32'B1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 17;
			Xn[0] <= (rx>>>17) + DATA_UNIT;
			Yn[0] <= (rx>>>17) - DATA_UNIT;
		end
		32'B01XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 16;
			Xn[0] <= (rx>>>16) + DATA_UNIT;
			Yn[0] <= (rx>>>16) - DATA_UNIT;
		end
		32'B001XXXXXXXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 15;
			Xn[0] <= (rx>>>15) + DATA_UNIT;
			Yn[0] <= (rx>>>15) - DATA_UNIT;
		end
		32'B0001XXXXXXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 14;
			Xn[0] <= (rx>>>14) + DATA_UNIT;
			Yn[0] <= (rx>>>14) - DATA_UNIT;
		end
		32'B00001XXXXXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 13;
			Xn[0] <= (rx>>>13) + DATA_UNIT;
			Yn[0] <= (rx>>>13) - DATA_UNIT;
		end
		32'B000001XXXXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 12;
			Xn[0] <= (rx>>>12) + DATA_UNIT;
			Yn[0] <= (rx>>>12) - DATA_UNIT;
		end
		32'B0000001XXXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 11;
			Xn[0] <= (rx>>>11) + DATA_UNIT;
			Yn[0] <= (rx>>>11) - DATA_UNIT;
		end
		32'B00000001XXXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 10;
			Xn[0] <= (rx>>>10) + DATA_UNIT;
			Yn[0] <= (rx>>>10) - DATA_UNIT;
		end
		32'B000000001XXXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 9;
			Xn[0] <= (rx>>>9) + DATA_UNIT;
			Yn[0] <= (rx>>>9) - DATA_UNIT;
		end
		32'B0000000001XXXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 8;
			Xn[0] <= (rx>>>8) + DATA_UNIT;
			Yn[0] <= (rx>>>8) - DATA_UNIT;
		end
		32'B00000000001XXXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 7;
			Xn[0] <= (rx>>>7) + DATA_UNIT;
			Yn[0] <= (rx>>>7) - DATA_UNIT;
		end
		32'B000000000001XXXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 6;
			Xn[0] <= (rx>>>6) + DATA_UNIT;
			Yn[0] <= (rx>>>6) - DATA_UNIT;
		end
		32'B0000000000001XXXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 5;
			Xn[0] <= (rx>>>5) + DATA_UNIT;
			Yn[0] <= (rx>>>5) - DATA_UNIT;
		end
		32'B00000000000001XXXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 4;
			Xn[0] <= (rx>>>4) + DATA_UNIT;
			Yn[0] <= (rx>>>4) - DATA_UNIT;
		end
		32'B000000000000001XXXXXXXXXXXXXXXXX : begin
			Pn[0] <= 3;
			Xn[0] <= (rx>>>3) + DATA_UNIT;
			Yn[0] <= (rx>>>3) - DATA_UNIT;
		end
		32'B0000000000000001XXXXXXXXXXXXXXXX : begin
			Pn[0] <= 2;
			Xn[0] <= (rx>>>2) + DATA_UNIT;
			Yn[0] <= (rx>>>2) - DATA_UNIT;
		end
		32'B00000000000000001XXXXXXXXXXXXXXX : begin
			Pn[0] <= 1;
			Xn[0] <= (rx>>>1) + DATA_UNIT;
			Yn[0] <= (rx>>>1) - DATA_UNIT;
		end
		32'B000000000000000001XXXXXXXXXXXXXX : begin
			Pn[0] <= 0;
			Xn[0] <= rx + DATA_UNIT;
			Yn[0] <= rx - DATA_UNIT;
		end
		32'B0000000000000000001XXXXXXXXXXXXX : begin
			Pn[0] <= -1;
			Xn[0] <= (rx<<<1) + DATA_UNIT;
			Yn[0] <= (rx<<<1) - DATA_UNIT;
		end
		32'B00000000000000000001XXXXXXXXXXXX : begin
			Pn[0] <= -2;
			Xn[0] <= (rx<<<2) + DATA_UNIT;
			Yn[0] <= (rx<<<2) - DATA_UNIT;
		end
		32'B000000000000000000001XXXXXXXXXXX : begin
			Pn[0] <= -3;
			Xn[0] <= (rx<<<3) + DATA_UNIT;
			Yn[0] <= (rx<<<3) - DATA_UNIT;
		end
		32'B0000000000000000000001XXXXXXXXXX : begin
			Pn[0] <= -4;
			Xn[0] <= (rx<<<4) + DATA_UNIT;
			Yn[0] <= (rx<<<4) - DATA_UNIT;
		end
		32'B00000000000000000000001XXXXXXXXX : begin
			Pn[0] <= -5;
			Xn[0] <= (rx<<<5) + DATA_UNIT;
			Yn[0] <= (rx<<<5) - DATA_UNIT;
		end
		32'B000000000000000000000001XXXXXXXX : begin
			Pn[0] <= -6;
			Xn[0] <= (rx<<<6) + DATA_UNIT;
			Yn[0] <= (rx<<<6) - DATA_UNIT;
		end
		32'B0000000000000000000000001XXXXXXX : begin
			Pn[0] <= -7;
			Xn[0] <= (rx<<<7) + DATA_UNIT;
			Yn[0] <= (rx<<<7) - DATA_UNIT;
		end
		32'B00000000000000000000000001XXXXXX : begin
			Pn[0] <= -8;
			Xn[0] <= (rx<<<8) + DATA_UNIT;
			Yn[0] <= (rx<<<8) - DATA_UNIT;
		end
		32'B000000000000000000000000001XXXXX : begin
			Pn[0] <= -9;
			Xn[0] <= (rx<<<9) + DATA_UNIT;
			Yn[0] <= (rx<<<9) - DATA_UNIT;
		end
		32'B0000000000000000000000000001XXXX : begin
			Pn[0] <= -10;
			Xn[0] <= (rx<<<10) + DATA_UNIT;
			Yn[0] <= (rx<<<10) - DATA_UNIT;
		end
		32'B00000000000000000000000000001XXX : begin
			Pn[0] <= -11;
			Xn[0] <= (rx<<<11) + DATA_UNIT;
			Yn[0] <= (rx<<<11) - DATA_UNIT;
		end
		32'B000000000000000000000000000001XX : begin
			Pn[0] <= -12;
			Xn[0] <= (rx<<<12) + DATA_UNIT;
			Yn[0] <= (rx<<<12) - DATA_UNIT;
		end
		32'B0000000000000000000000000000001X : begin
			Pn[0] <= -13;
			Xn[0] <= (rx<<<13) + DATA_UNIT;
			Yn[0] <= (rx<<<13) - DATA_UNIT;
		end
		32'B00000000000000000000000000000001 : begin
			Pn[0] <= -14;
			Xn[0] <= (rx<<<14) + DATA_UNIT;
			Yn[0] <= (rx<<<14) - DATA_UNIT;
		end
		default: begin
			Pn[0] <= 0;
			Xn[0] <= + DATA_UNIT;
			Yn[0] <= - DATA_UNIT;
		end


	endcase
	//////////////////////////////////
	// ?
	LOFn[0] <= (rx==0);
	// N = 0
	Nn[0] <= DATA_ZERO;
	// T=0
	Tn[0] <= DATA_ZERO;
	// cordicïforïï
	for(n=ITERATION-1; n>=1; n=n-1)
	begin
		//  Pn 
		Pn[n] <= Pn[n-1];
		LOFn[n] <= LOFn[n-1];
		// Yn[n-1]>0ï
		if(Yn[n-1]>EPSILON)
		begin
			Xn[n] <= Xn[n-1] - (Yn[n-1]>>>(n));
			Yn[n] <= Yn[n-1] - (Xn[n-1]>>>(n));
			Nn[n] <= Nn[n-1] + 1;	// ï+1
			Tn[n] <= Tn[n-1] + T0n[n-1];	// 
		end
		// Yn[n-1]<0ï
		else if(Yn[n-1]<-EPSILON)
		begin
			Xn[n] <= Xn[n-1] + (Yn[n-1]>>>(n));
			Yn[n] <= Yn[n-1] + (Xn[n-1]>>>(n));
			Nn[n] <= Nn[n-1] + 1;	// ï+1
			Tn[n] <= Tn[n-1] - T0n[n-1];	// 
		end
		// ï
		else
		begin
			Xn[n] <= Xn[n-1];
			Yn[n] <= Yn[n-1];
			Nn[n] <= Nn[n-1];
			Tn[n] <= Tn[n-1];
		end
	end
	LOFn[ITERATION] <= LOFn[ITERATION-1];
end
endtask
	
	// ïromipïROM
	assign	Kn_THETAn_address = rom_address;
	// 
	reg		signed 	[2*DATA_WIDTH-1:0]	bias;// = (Pn[ITERATION-1] * LN_2);
	reg		signed 	[DATA_WIDTH-1:0]	theta;
	always @(posedge sys_clk)
	begin
		bias <= (Pn[ITERATION-1] * LN_2);
		theta <= Tn[ITERATION-1] * 2;
		ln_r <= LOFn[ITERATION]? LN_EPS : (theta + bias);	// ln(0) 
	end	
	// 
	wire	signed	[31:0]	P0 = Pn[0];
	wire	signed	[31:0]	X0 = Xn[0];
	wire	signed	[31:0]	Y0 = Yn[0];
	wire	signed	[31:0]	Pf = Pn[ITERATION-1];
	wire	signed	[31:0]	Xf = Xn[ITERATION-1];
	wire	signed	[31:0]	Yf = Yn[ITERATION-1];
	
endmodule