// �exp()�
// �cordic
// Mark: 2018/6/3: /bug
module cordic_exp_rtl
#(parameter	DATA_WIDTH = 32,    // ��
  parameter	FRAC_WIDTH = 16,	// �
  parameter	EPSILON = 16,		// 
  parameter ITERATION = 8,  	// ���
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

	// Kn��Python��
	wire	[DATA_WIDTH-1:0]	Kn_THETAn_address;
	wire	[DATA_WIDTH-1:0]	Kn;
	wire	[DATA_WIDTH-1:0]	THETAn;
	cordic_factor_exp_rom_ip 	exp_cordic_rom_ip_core	(.address(Kn_THETAn_address),.clock(sys_clk),.q({Kn, THETAn}));
	 //////////////////////////////////

	// ��CORDIC
	// ���reg�
	reg		signed 	[DATA_WIDTH-1:0]	Xn	[0:ITERATION-1];	// ������x(�)
	reg		signed 	[DATA_WIDTH-1:0]	In	[0:ITERATION-1];	// ������x(��)
	reg		signed 	[DATA_WIDTH-1:0]	Zn	[0:ITERATION-1];
	reg									LOFn[0:ITERATION-1];	// 
	reg									UOFn[0:ITERATION+2];	// 
	// ����Zn��
	reg				[DATA_WIDTH-1:0]	Nn	[0:ITERATION+1];	// ��bug�Nn�
	// �
	reg		signed 	[DATA_WIDTH-1:0]	Tn	[0:ITERATION-1];
	reg		signed 	[DATA_WIDTH-1:0]	T0n	[0:ITERATION-1];	// ROM�
	reg		signed 	[DATA_WIDTH-1:0]	K0n	[0:ITERATION-1];	// ROM�
	// 
	reg		[4:0]	cstate;	// ��
	parameter		IDLE = 0;	// 
	parameter		LOAD = 1;	// ROM�
	parameter		COMP = 2;	// ��/
	reg		[DATA_WIDTH-1:0]	timer_in_state;	// ���
	reg		[DATA_WIDTH-1:0]	rom_address;	// ROM��
	// cordic �� + ��&1/4���
	always @(posedge sys_clk)
		// �
		if(!sys_rst_n)
			init_system_task;
		// �����
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
// task�
integer	n;
// ��
task init_system_task;
begin
	cstate <= IDLE;	// 
	// ���
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
	// ��
	timer_in_state <= DATA_ZERO;
	// rom��
	rom_address <= 0;
end
endtask
////////////////////
// �IDLE��load
// ��romlatency
task prepare_load_task;
begin	
	// ������rom�
	if(timer_in_state>=(ROM_LATENCY-1))
	begin
		cstate <= LOAD;
		// ��
		timer_in_state <= DATA_ZERO;
	end
	// ���ROM�
	else
	begin
		timer_in_state <= timer_in_state+1;
	end
	// rom
	rom_address <= rom_address+1;
end
endtask
// �LOADload�
task execute_load_task;
begin	
	// ��
	if(timer_in_state>=(ITERATION))
	begin
		cstate <= COMP;
		// ��
		timer_in_state <= DATA_ZERO;
	end
	else
	begin
		// ��rom��
		T0n[timer_in_state] <= THETAn;
		K0n[timer_in_state] <= Kn;
		rom_address <= rom_address+1;
		timer_in_state <= timer_in_state+1;
	end
end
endtask
// ��coedic���
task execute_comp_task;
begin
	// ��
	// ���� - �
	Xn[0] <= {{(DATA_WIDTH-FRAC_WIDTH){1'B0}}, src_x[FRAC_WIDTH-1:0]};
	In[0] <= (src_x >>> FRAC_WIDTH);
	// /�
	LOFn[0] <= src_x < (-DATA_LOF);
	UOFn[0] <= src_x >= (DATA_UOF);
	// �Z = 1
	Zn[0] <= DATA_UNIT;
	// �N = 0
	Nn[0] <= DATA_ZERO;
	// T=0
	Tn[0] <= DATA_ZERO;
	// �cordic����for��
	for(n=ITERATION-1; n>=1; n=n-1)
	begin
		// � X & I 
		Xn[n] <= Xn[n-1];
		In[n] <= In[n-1];
		// �Tn[n-1]>Xn[n-1]��
		if(Tn[n-1]>(Xn[n-1]+EPSILON))
		begin
			Zn[n] <= Zn[n-1] - (Zn[n-1]>>>(n));
			Nn[n] <= Nn[n-1] + 1;	// ������+1
			Tn[n] <= Tn[n-1] - T0n[n-1];	// 
		end
		// �Tn[n-1]<Xn[n-1]��
		else if(Xn[n-1]>(Tn[n-1]+EPSILON))
		begin
			Zn[n] <= Zn[n-1] + (Zn[n-1]>>>(n));
			Nn[n] <= Nn[n-1] + 1;	// ������+1
			Tn[n] <= Tn[n-1] + T0n[n-1];	// 
		end
		// ������
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
	// �
	UOFn[ITERATION] <= UOFn[ITERATION-1];
	UOFn[ITERATION+1] <= UOFn[ITERATION];
	UOFn[ITERATION+2] <= UOFn[ITERATION+1];
end
endtask
	//////////////////////////////////////////////////
	// ��romip��ROM
	assign	Kn_THETAn_address = rom_address;
	// Kn[]� + �����
	// ��������
	reg		[DATA_WIDTH-1:0]	Kn_res [0:1];	// ��K0nram
	reg		[DATA_WIDTH-1:0]	Zn_res [0:1];
	reg		[DATA_WIDTH-1:0]	Xn_res [0:1];
	reg		[DATA_WIDTH-1:0]	In_res [0:1];
	always @(posedge sys_clk)
	begin
		Kn_res[0] <= K0n[Nn[ITERATION-1]-1];
		Zn_res[0] <= LOFn[ITERATION-1]? DATA_ZERO : UOFn[ITERATION-1]? {1'B0, {(DATA_WIDTH-1){1'B1}}} : Zn[ITERATION-1];	// �/
		Xn_res[0] <= Xn[ITERATION-1];
		In_res[0] <= In[ITERATION-1];
		// �
		Kn_res[1] <= Kn_res[0];
		Zn_res[1] <= Zn_res[0];
		Xn_res[1] <= Xn_res[0];
		In_res[1] <= In_res[0];
	end
	// ��rhoKn�
	// �Kn0~1���32bitsigned(FRAC_WIDTH)-bit
	// ������
	reg		[2*DATA_WIDTH-1:0]	rho_reg [0:1];	// ����64-bit���LSB
	reg		[DATA_WIDTH-1:0]	x_reg [0:1];		// ���rho�
	// [0] ���� [1]����
	wire	[DATA_WIDTH-1:0]	int_part_exp_val;	// �� exp ��
	reg		[DATA_WIDTH-1:0]	x;			
	always @(posedge sys_clk)
	begin
		// ���
		if(UOFn[ITERATION+1]==0)
		begin
			if(Nn[ITERATION+1]==0)
				rho_reg[0] <= Zn_res[1]*DATA_UNIT;			
			else
				rho_reg[0] <= Zn_res[1]*Kn_res[1];	//  �������
		end
		// ���
		else 
			rho_reg[0] <= {1'B0, {(2*DATA_WIDTH-1){1'B1}}};
		// 
		x_reg[0] <= Xn_res[1]|(In_res[1]<<<FRAC_WIDTH);
		////////
		// ����
		x_reg[1] <= x_reg[0];
		// ���
		if(UOFn[ITERATION+2]==0)
			rho_reg[1] <= rho_reg[0][2*DATA_WIDTH-1:FRAC_WIDTH]*int_part_exp_val;
		else
			rho_reg[1] <= (1<<(DATA_WIDTH+FRAC_WIDTH-1))-1;
		////////
		rho <= rho_reg[1][DATA_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
		x <= x_reg[1];
	end
	// ROM������	
	cordic_int_part_exp_rom_ip	int_part_mdl(.address(In_res[0]+128), .clock(sys_clk), .q(int_part_exp_val));
endmodule
