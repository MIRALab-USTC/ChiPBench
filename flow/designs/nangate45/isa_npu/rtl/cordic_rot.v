//----------------------------------------------------------------------------------------------------------
//	FILE: 		cordic_rot.v
// 	AUTHOR:		Xudong Chen
// 	
//	ABSTRACT:	behavior of the rtl module of atan()/modulus() function based on CORDIC, pipelined
// 	KEYWORDS:	fpga, CORDIC, atan()
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Xudong Chen		18/5/6		original, implement theta = atan(y/x), rho = \sqrt{x^2+y^2}
//										for theta, [-2^30, 2^30] ==> [-pi, +pi]
//-----------------------------------------------------------------------------------------------------------
// cordicï & 
module cordic_rot
#(parameter	DATA_WIDTH = 32,    // 
  parameter	EPSILON = 3,		// 
  parameter ITERATION = 8,  // 
  parameter ROM_LATENCY = 2,	// romIP
  parameter	DATA_ZERO = {DATA_WIDTH{1'B0}}	// 0
)
(
	input	wire	sys_clk, sys_rst_n,
	input	wire	[DATA_WIDTH-1:0]	src_x,
	input	wire	[DATA_WIDTH-1:0]	src_y,
	
	output	reg		[DATA_WIDTH-1:0]	rho,
    output  reg	    [DATA_WIDTH-1:0]    theta
);

	// KnïPython
	wire	[DATA_WIDTH-1:0]	Kn_THETAn_address;
	wire	[DATA_WIDTH-1:0]	Kn;
	wire	[DATA_WIDTH-1:0]	THETAn;
    cordic_factor_Kn_rom_ip 	Kn_rom_ip_core	(.address(Kn_THETAn_address),.clock(sys_clk),.q({Kn, THETAn}));
	//////////////////////////////////
	
	// CORDIC
	// reg
	reg		signed 	[DATA_WIDTH-1:0]	Xn	[0:ITERATION-1];
	reg		signed 	[DATA_WIDTH-1:0]	Yn	[0:ITERATION-1];
	reg									Sn	[0:ITERATION-1];//	y-
	// ïYnï
	reg				[DATA_WIDTH-1:0]	Nn	[0:ITERATION-1];	
	// 
	reg		signed 	[DATA_WIDTH-1:0]	Tn	[0:ITERATION-1];
	reg		signed 	[DATA_WIDTH-1:0]	T0n	[0:ITERATION-1];	// ROM
	reg		signed 	[DATA_WIDTH-1:0]	K0n	[0:ITERATION-1];	// ROM
	// 
	reg		[4:0]	cstate;	// 
	parameter		IDLE = 0;	// 
	parameter		LOAD = 1;	// ROM
	parameter		COMP = 2;	// /
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
		Nn[n] <= DATA_ZERO;
		Tn[n] <= DATA_ZERO;
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
// ïcoedic
task execute_comp_task;
begin
	// 1/4
	Xn[0] <= src_x[DATA_WIDTH-1]? (~src_x+1) : src_x;
	Sn[0] <= src_x[DATA_WIDTH-1];
	Yn[0] <= src_y;
	Nn[0] <= DATA_ZERO;
	Tn[0] <= DATA_ZERO;
	// cordicïforïï
	for(n=ITERATION-1; n>=1; n=n-1)
	begin
		// Yn[n-1]>0ï
		if(Yn[n-1]>EPSILON)
		begin
			Xn[n] <= Xn[n-1] + (Yn[n-1]>>>(n-1));
			Yn[n] <= Yn[n-1] - (Xn[n-1]>>>(n-1));
			Nn[n] <= Nn[n-1] + 1;	// ï+1
			Tn[n] <= Tn[n-1] + T0n[n-1];	// 
		end
		// Yn[n-1]<0ï
		else if(Yn[n-1]<-EPSILON)
		begin
			Xn[n] <= Xn[n-1] - (Yn[n-1]>>>(n-1));
			Yn[n] <= Yn[n-1] + (Xn[n-1]>>>(n-1));
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
		//
		Sn[n] <= Sn[n-1];
	end
end
endtask
	//////////////////////////////////////////////////
	// ïromipïROM
	assign	Kn_THETAn_address = rom_address;
	// rhoïKn
	// Kn0~1ïï32bitsignedï31-bit
	// ïï
	reg		[2*DATA_WIDTH-1:0]	rho_reg;	// ï64-bitïLSB
	reg		[DATA_WIDTH-1:0]	theta_reg;	// rho & thetaregister
	always @(posedge sys_clk)
	begin
		if(Nn[ITERATION-1]==0)
			rho_reg <= {Xn[ITERATION-1], DATA_ZERO} >>> 1;		// // bugïïbit			
		else
			rho_reg <= Xn[ITERATION-1]*K0n[Nn[ITERATION-1]-1];	// ï ï
		
		// Y-axisï
		if(Sn[ITERATION-1]==0)
			theta_reg <= Tn[ITERATION-1];
		else
		begin
			if(Tn[ITERATION-1][DATA_WIDTH-1])	// -pi-theta
				theta_reg <= {1'B1, {(DATA_WIDTH-1){1'B0}}} - Tn[ITERATION-1];
			else					// pi-theta
				theta_reg <= {1'B0, {(DATA_WIDTH-1){1'B1}}} - Tn[ITERATION-1];
		end
		////////
		rho <= rho_reg[2*DATA_WIDTH-1:DATA_WIDTH-1];
		theta <= theta_reg;
	end
	
endmodule
