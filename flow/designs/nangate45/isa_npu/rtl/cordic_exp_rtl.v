// öexp()ý
// ùcordic
// Mark: 2018/6/3: /bug
module cordic_exp_rtl
#(parameter	DATA_WIDTH = 32,    // ýí
  parameter	FRAC_WIDTH = 16,	// ý
  parameter	EPSILON = 16,		// 
  parameter ITERATION = 8,  	// üúý
  parameter ROM_LATENCY = 2,	// romIP
  parameter	DATA_UNIT = {{(DATA_WIDTH-FRAC_WIDTH-1){1'B0}}, 1'B1, {FRAC_WIDTH{1'B0}}}, // 1 
  parameter	DATA_ZERO = {DATA_WIDTH{1'B0}},	// 0
  parameter	DATA_LOF = (FRAC_WIDTH*11)<<(FRAC_WIDTH-4),	//  ==> 0  e^-11 ==> 2^-16, 
  parameter	DATA_UOF = ((DATA_WIDTH-FRAC_WIDTH-1)*11)<<(FRAC_WIDTH-4)	//  ==> (2**31-1)  e^10.39 ==> 2^15, 
)
(
	input	wire								sys_clk, sys_rst_n,
	input	wire	signed	[DATA_WIDTH-1:0]	src_x,
	
	output	reg		signed	[DATA_WIDTH-1:0]	rho
);

	// KnýíPythonúý
	wire	[DATA_WIDTH-1:0]	Kn_THETAn_address;
	wire	[DATA_WIDTH-1:0]	Kn;
	wire	[DATA_WIDTH-1:0]	THETAn;
	cordic_factor_exp_rom_ip 	exp_cordic_rom_ip_core	(.address(Kn_THETAn_address),.clock(sys_clk),.q({Kn, THETAn}));
	 //////////////////////////////////

	// ò÷CORDIC
	// ùöóregó
	reg		signed 	[DATA_WIDTH-1:0]	Xn	[0:ITERATION-1];	// ò÷ùüúëx(ý)
	reg		signed 	[DATA_WIDTH-1:0]	In	[0:ITERATION-1];	// ò÷ùüúëx(ûý)
	reg		signed 	[DATA_WIDTH-1:0]	Zn	[0:ITERATION-1];
	reg									LOFn[0:ITERATION-1];	// 
	reg									UOFn[0:ITERATION+2];	// 
	// üúýòZnêò
	reg				[DATA_WIDTH-1:0]	Nn	[0:ITERATION+1];	// öòbugïNnø
	// ý
	reg		signed 	[DATA_WIDTH-1:0]	Tn	[0:ITERATION-1];
	reg		signed 	[DATA_WIDTH-1:0]	T0n	[0:ITERATION-1];	// ROMï
	reg		signed 	[DATA_WIDTH-1:0]	K0n	[0:ITERATION-1];	// ROMï
	// 
	reg		[4:0]	cstate;	// ý÷
	parameter		IDLE = 0;	// 
	parameter		LOAD = 1;	// ROMý
	parameter		COMP = 2;	// ý÷/
	reg		[DATA_WIDTH-1:0]	timer_in_state;	// öý÷
	reg		[DATA_WIDTH-1:0]	rom_address;	// ROMý÷
	// cordic üú + ýë&1/4óýí
	always @(posedge sys_clk)
		// õ
		if(!sys_rst_n)
			init_system_task;
		// ñòýüú
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
// taskö
integer	n;
// õö
task init_system_task;
begin
	cstate <= IDLE;	// 
	// óù÷
	for(n=0; n<ITERATION; n=n+1)
	begin
		Xn[n] <= DATA_ZERO;
		Zn[n] <= DATA_ZERO;
		Nn[n] <= DATA_ZERO;
		Tn[n] <= DATA_ZERO;
		//
		LOFn[n] <= 0;
		UOFn[n] <= 0;
	end
	// ý÷
	timer_in_state <= DATA_ZERO;
	// romý÷
	rom_address <= 0;
end
endtask
////////////////////
// óIDLEøëload
// ÷òromlatency
task prepare_load_task;
begin	
	// ûýøöøëromý
	if(timer_in_state>=(ROM_LATENCY-1))
	begin
		cstate <= LOAD;
		// ý÷
		timer_in_state <= DATA_ZERO;
	end
	// ñòøROMý
	else
	begin
		timer_in_state <= timer_in_state+1;
	end
	// rom
	rom_address <= rom_address+1;
end
endtask
// óLOADloadî
task execute_load_task;
begin	
	// øö
	if(timer_in_state>=(ITERATION))
	begin
		cstate <= COMP;
		// ý÷
		timer_in_state <= DATA_ZERO;
	end
	else
	begin
		// ñòromïý
		T0n[timer_in_state] <= THETAn;
		K0n[timer_in_state] <= Kn;
		rom_address <= rom_address+1;
		timer_in_state <= timer_in_state+1;
	end
end
endtask
// ûöcoedicüúý
task execute_comp_task;
begin
	// ëý
	// îýûý - ý
	Xn[0] <= {{(DATA_WIDTH-FRAC_WIDTH){1'B0}}, src_x[FRAC_WIDTH-1:0]};
	In[0] <= (src_x >>> FRAC_WIDTH);
	// /ð
	LOFn[0] <= src_x < (-DATA_LOF);
	UOFn[0] <= src_x >= (DATA_UOF);
	// õZ = 1
	Zn[0] <= DATA_UNIT;
	// óN = 0
	Nn[0] <= DATA_ZERO;
	// T=0
	Tn[0] <= DATA_ZERO;
	// ócordicüúýïforòû
	for(n=ITERATION-1; n>=1; n=n-1)
	begin
		// ë X & I 
		Xn[n] <= Xn[n-1];
		In[n] <= In[n-1];
		// ûTn[n-1]>Xn[n-1]ëý
		if(Tn[n-1]>(Xn[n-1]+EPSILON))
		begin
			Zn[n] <= Zn[n-1] - (Zn[n-1]>>>(n));
			Nn[n] <= Nn[n-1] + 1;	// øüúüúý+1
			Tn[n] <= Tn[n-1] - T0n[n-1];	// 
		end
		// ûTn[n-1]<Xn[n-1]ëý
		else if(Xn[n-1]>(Tn[n-1]+EPSILON))
		begin
			Zn[n] <= Zn[n-1] + (Zn[n-1]>>>(n));
			Nn[n] <= Nn[n-1] + 1;	// øüúüúý+1
			Tn[n] <= Tn[n-1] + T0n[n-1];	// 
		end
		// ñò÷üúý
		else
		begin
			Zn[n] <= Zn[n-1];
			Nn[n] <= Nn[n-1];
			Tn[n] <= Tn[n-1];
		end
		//
		LOFn[n] <= LOFn[n-1];
		UOFn[n] <= UOFn[n-1];
	end
	// Nn
	Nn[ITERATION] <= Nn[ITERATION-1];
	Nn[ITERATION+1] <= Nn[ITERATION];
	// ê
	UOFn[ITERATION] <= UOFn[ITERATION-1];
	UOFn[ITERATION+1] <= UOFn[ITERATION];
	UOFn[ITERATION+2] <= UOFn[ITERATION+1];
end
endtask
	//////////////////////////////////////////////////
	// îóromipøöROM
	assign	Kn_THETAn_address = rom_address;
	// Kn[]ï + öýûìò
	// ùï÷öýóìò
	reg		[DATA_WIDTH-1:0]	Kn_res [0:1];	// ÷öK0nram
	reg		[DATA_WIDTH-1:0]	Zn_res [0:1];
	reg		[DATA_WIDTH-1:0]	Xn_res [0:1];
	reg		[DATA_WIDTH-1:0]	In_res [0:1];
	always @(posedge sys_clk)
	begin
		Kn_res[0] <= K0n[Nn[ITERATION-1]-1];
		Zn_res[0] <= LOFn[ITERATION-1]? DATA_ZERO : UOFn[ITERATION-1]? {1'B0, {(DATA_WIDTH-1){1'B1}}} : Zn[ITERATION-1];	// ö/
		Xn_res[0] <= Xn[ITERATION-1];
		In_res[0] <= In[ITERATION-1];
		// ò
		Kn_res[1] <= Kn_res[0];
		Zn_res[1] <= Zn_res[0];
		Xn_res[1] <= Xn_res[0];
		In_res[1] <= In_res[0];
	end
	// óýrhoKný
	// ïKn0~1ýùò32bitsigned(FRAC_WIDTH)-bit
	// òîóöòö
	reg		[2*DATA_WIDTH-1:0]	rho_reg [0:1];	// ýòöò64-bitîóôLSB
	reg		[DATA_WIDTH-1:0]	x_reg [0:1];		// ëòörhoø
	// [0] ûýòý [1]ûýóý
	wire	[DATA_WIDTH-1:0]	int_part_exp_val;	// ûý exp ûý
	reg		[DATA_WIDTH-1:0]	x;			
	always @(posedge sys_clk)
	begin
		// ûòö
		if(UOFn[ITERATION+1]==0)
		begin
			if(Nn[ITERATION+1]==0)
				rho_reg[0] <= Zn_res[1]*DATA_UNIT;			
			else
				rho_reg[0] <= Zn_res[1]*Kn_res[1];	//  ïòîëì÷û
		end
		// ûòö
		else 
			rho_reg[0] <= {1'B0, {(2*DATA_WIDTH-1){1'B1}}};
		// 
		x_reg[0] <= Xn_res[1]|(In_res[1]<<<FRAC_WIDTH);
		////////
		// ëûýý
		x_reg[1] <= x_reg[0];
		// ûòö
		if(UOFn[ITERATION+2]==0)
			rho_reg[1] <= rho_reg[0][2*DATA_WIDTH-1:FRAC_WIDTH]*int_part_exp_val;
		else
			rho_reg[1] <= (1<<(DATA_WIDTH+FRAC_WIDTH-1))-1;
		////////
		rho <= rho_reg[1][DATA_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
		x <= x_reg[1];
	end
	// ROMïöûýýû	
	cordic_int_part_exp_rom_ip	int_part_mdl(.address(In_res[0]+128), .clock(sys_clk), .q(int_part_exp_val));
endmodule
