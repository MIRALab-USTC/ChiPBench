//----------------------------------------------------------------------------------------------------------
//	FILE: 		npu_paras_config.v
// 	AUTHOR:		Xudong Chen
// 	
//	ABSTRACT:	config CNN parameters into DDR/SRAM RAM
// 	KEYWORDS:	fpga, cnn, parameter, RAM
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Xudong Chen		18/3/9		original, DDRCNN
//										
//-----------------------------------------------------------------------------------------------------------
// CNN
module npu_paras_config
#(parameter	DATA_WIDTH = 32,    // 
  parameter	FRAC_WIDTH = 16,	// 
  parameter RAM_LATENCY = 2,	// ramIP
  parameter	PARA_BIAS = 32'H00010000	// CNN
)
(
	input	wire						clk, rst_n,	// 
	input	wire						npu_paras_en,	// 
	output	wire						npu_paras_ready,	// CNN
	input	wire	[DATA_WIDTH-1:0]	npu_paras_q,	// CNN
	output	reg		[DATA_WIDTH-1:0]	npu_paras_addr,	// CNN
	// DDR
	output	wire						DDR_WRITE_CLK,
	output	wire	[DATA_WIDTH-1:0]	DDR_WRITE_ADDR,
	output	wire	[DATA_WIDTH-1:0]	DDR_WRITE_DATA,
	output	wire						DDR_WRITE_REQ,
	input	wire						DDR_WRITE_READY
);
	
	reg		[31:0]	ddr_write_addr;
	reg				ddr_write_req;
	wire			ddr_write_ready;
	reg		[31:0]	ddr_write_data;
	///////////
	assign			DDR_WRITE_CLK = clk;
	assign			DDR_WRITE_ADDR = ddr_write_addr;
	assign			DDR_WRITE_DATA = ddr_write_data;
	assign			DDR_WRITE_REQ = ddr_write_req;
	assign			ddr_write_ready = DDR_WRITE_READY;
	
	wire			ddr_write_data_valid = ddr_write_ready && ddr_write_req;	// 
	//
	//  npu_paras_en 
	reg				npu_paras_enx;
	always @(posedge clk)
		npu_paras_enx <= npu_paras_en;
	wire			npu_paras_en_up = (!npu_paras_enx && npu_paras_en);	// 
	//
	reg		[3:0]	cstate;
	reg		[31:0]	delay;
	reg		[31:0]	total_paras_num;	// 
	always @(posedge clk)
		if(!rst_n)
		begin
			cstate <= 0;
			delay <= 0;
			npu_paras_addr <= 0;
			ddr_write_req <= 0;	// DDR
		end
		else
		begin
			case(cstate)
				0: begin
					if(npu_paras_en_up)
					begin
						cstate <= 1;
						npu_paras_addr <= 0;
						delay <= 0;
					end
					//
					ddr_write_req <= 0;	// DDR
				end
				// RAM
				1: begin
					if(delay>RAM_LATENCY)
					begin
						cstate <= 2;	// 
						total_paras_num <= npu_paras_q;	// 
						delay <= 0;
						ddr_write_addr <= PARA_BIAS;
					end
					else
						delay <= delay + 1;
					///////	
					ddr_write_req <= 0;	// DDR
				end
				// 
				2: begin
					if(npu_paras_addr>total_paras_num)
					begin
						cstate <= 0;
						npu_paras_addr <= 0;
						delay <= 0;
					end
					else
					begin
						cstate <= 3;	// RAM
						npu_paras_addr <= npu_paras_addr + 1;
						delay <= 0;
					end
					ddr_write_req <= 0;	// DDR
				end
				// 
				3: begin
					if(delay>RAM_LATENCY)
					begin
						cstate <= 4;	// DDR
						ddr_write_data <= npu_paras_q;
						ddr_write_req <= 1;	// DDRï
						delay <= 0;
					end
					else
						delay <= delay + 1;
				end
				// DDR
				4: begin
					if(ddr_write_ready)
					begin
						ddr_write_req <= 0;	// DDR
						ddr_write_addr <= ddr_write_addr + 1;	// DDR+1
						cstate <= 2;	// 
					end
				end
				//
				default: begin
					cstate <= 0;
					delay <= 0;
					npu_paras_addr <= 0;
					ddr_write_req <= 0;	// DDR
				end
				
			endcase
		
		end
	/////////////////////////////////////////////////////////
	assign	npu_paras_ready = (cstate==0);
	////////////////////////////////////////////////////
endmodule
	