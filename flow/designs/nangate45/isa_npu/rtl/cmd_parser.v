module cmd_parser
#(	
	parameter	UART_DATA_WIDTH = 8,    // uart 
	parameter	UART_ADDR_WIDTH = 2,		// endpoint-
	parameter	SYS_UART_DATA_MULT = 4,	// system  cypress uart 
	parameter	SYS_DATA_WIDTH = UART_DATA_WIDTH*SYS_UART_DATA_MULT // system 
)
(
	output	wire						receive_valid_cmd,	// 
	input	wire						sys_clk, sys_rst_n, // 
	input	wire	[5:1]				sys_key_fn,		// ïï
	//
	input	wire [SYS_DATA_WIDTH-1:0]	adc_ddr_write_addr,			// adcddr
	input	wire [SYS_DATA_WIDTH-1:0]	adc_ddr_write_addr_mask,			// adcddr
	// 
	output	reg							audio_sample_en,	// 
	// ïNPUïNPUï
	output	reg	[SYS_DATA_WIDTH-1:0]	npu_inst_part,
	output	reg							npu_inst_part_en,	
	//  uart
	output	reg	[SYS_DATA_WIDTH-1:0]	sys_uart_write_data,			//  fifo
	output	reg							sys_uart_write_data_valid,	// 
	input								sys_uart_write_data_permitted,	// 
	input		[UART_DATA_WIDTH-1:0]	sys_uart_read_data,			//   fifo 
	output	reg							sys_uart_read_data_req,		//  fifo /
	input								sys_uart_read_data_permitted,		// fifo
	// ddr
	output	reg	[SYS_DATA_WIDTH-1:0]	sys_ddr_write_addr,			// ddr
	output	reg	[SYS_DATA_WIDTH-1:0]	sys_ddr_write_data,			//  ddr
	output	reg							sys_ddr_write_data_valid,	// ddr
	output	reg							sys_ddr_write_burst_begin,	// ddrburstï1-clockï
	input								sys_ddr_write_data_permitted,	// ddr
	output	reg	[SYS_DATA_WIDTH-1:0]	sys_ddr_read_addr,			//  ddr
	input		[SYS_DATA_WIDTH-1:0]	sys_ddr_read_data,			//   ddr 
	input								sys_ddr_read_data_valid,		//   ddr 
	output	reg							sys_ddr_read_burst_begin,	// ddrburstï1-clockï
	output	reg							sys_ddr_read_data_req,		//  ddr /
	input								sys_ddr_read_data_permitted		//  ddr 
);
	
// ïrfifoïuart
// ï0ï1ï2ï3
reg		[3:0]	read_cnt;
reg		[127:0]	uart_cmd_shift /* synthesis noprune */;
always @(posedge sys_clk)
	if(!sys_rst_n)
	begin
		uart_cmd_shift <= 0;
		read_cnt <= 0;
	end
	else 
	begin
		case(read_cnt)
			// rfifo
			0: begin
				if(sys_uart_read_data_permitted)
				begin
					read_cnt <= 1;
					sys_uart_read_data_req <= 0;
				end
			end
			
			// 
			1: begin
				read_cnt <= 2;
				uart_cmd_shift <= {uart_cmd_shift[119:0], 
									sys_uart_read_data[7:0]
								};
				sys_uart_read_data_req <= 1;	// FIFO
			end
			
			// rfifo
			2: begin
				read_cnt <= 3;
				sys_uart_read_data_req <= 0;
			end
			
			// 3ïuart-cmd_shift
			3: 	read_cnt <= 0;
			
			default:
				read_cnt <= 0;
		endcase
	end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	////////////////////////////////////////////
	//  hello  = {68,65,6c,6c,6f, xx, yy, zz, aa} {xx, yy, zz, aa} ï32 bitï
	//  helloworldhh = {68,65,6c,6c,6f, 77 6F 72 6C 64 68 68, mm, nn, ...} {mm, nn}
	reg		[31:0]		send_back_cnt;
	
	reg					test_uart_cmd;	// uart(hello/xxxx)
	reg					read_ddr_cmd;	// ddr(r_ddr/xxxx)
	reg					write_ddr_cmd; // ddr(w_ddr/xxxx/yyyy)
	reg					cont_read_cmd; // ddr(contr/xxxx/yyyy)
	reg					cont_write_cmd; // ddr(contw/xxxx/yyyy)
	reg					adc_read_cmd;	// adcddr(cradc/ffff/yyyy)
	reg					audio_sample_cmd;	// (audio/tttttttt)
	reg					measure_ram_cmd;	// RAM(msddr/xxxx/yyyy)	
	reg					npu_inst_cmd;		// NPUïnpust/tttttttt)
	always @(posedge sys_clk)
	begin
		test_uart_cmd <= (uart_cmd_shift[79:40]==40'H68656C6C6F && (read_cnt==3));	
		read_ddr_cmd <= (uart_cmd_shift[79:40]==40'H725F646472 && (read_cnt==3));
		write_ddr_cmd <= (uart_cmd_shift[111:72]==40'H775F646472 && (read_cnt==3));
		cont_read_cmd <= (uart_cmd_shift[111:72]==40'H636F6E7472  && (read_cnt==3));
		cont_write_cmd <= (uart_cmd_shift[111:72]==40'H636F6E7477 && (read_cnt==3));
		adc_read_cmd <= (uart_cmd_shift[111:72]==40'H6372616463 && (read_cnt==3));
		audio_sample_cmd <= (uart_cmd_shift[79:40]==40'H617564696F && (read_cnt==3));
		measure_ram_cmd <= (uart_cmd_shift[111:72]==40'H6D73646472 && (read_cnt==3));
		npu_inst_cmd <= (uart_cmd_shift[79:40]==40'H6E70757374 && (read_cnt==3));
	end
	
	assign				receive_valid_cmd = (npu_inst_cmd|test_uart_cmd|read_ddr_cmd|write_ddr_cmd|cont_read_cmd|cont_write_cmd|adc_read_cmd|audio_sample_cmd|measure_ram_cmd);
	reg		[8:0]		receive_cmd_type;
	always @(posedge sys_clk)
		if(receive_valid_cmd)
			receive_cmd_type <= {npu_inst_cmd, measure_ram_cmd, audio_sample_cmd, adc_read_cmd, cont_write_cmd, cont_read_cmd, write_ddr_cmd, read_ddr_cmd, test_uart_cmd};
	
	/////////////////
	// DDR-HMC sys_ddr_read_data  sys_ddr_read_data_valid 
	// registerï
	reg		[SYS_DATA_WIDTH-1:0]	sys_ddr_read_data_reg;
	reg								sys_ddr_read_data_valid_reg;
	always @(posedge sys_clk)
	begin
		sys_ddr_read_data_reg <= sys_ddr_read_data;
		sys_ddr_read_data_valid_reg <= sys_ddr_read_data_valid;
	end
	/////////////////////////////////
	// ïuart_cmd_shift 
	reg		[127:0]		uart_cmd_shift_reg;
	always @(posedge sys_clk)
		if(receive_valid_cmd)	// ïïï0x0D/0x0Aï	2018-05-04
			uart_cmd_shift_reg <= uart_cmd_shift;
	// ïuartfifoï  sys_ddr_write_data_permitted 
	reg		sys_uart_write_data_permitted_reg;
	always @(posedge sys_clk)
		sys_uart_write_data_permitted_reg <= sys_uart_write_data_permitted;
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ddr
// wfifoalmost fullïHMCï
// wfifoHMC
// HMCï
	reg		[4:0]		ddr_wr_state;
	reg		[31:0]		ddr_wr_number;	//  ddr 
	reg		[31:0]		ddr_wr_time;	// DDR
	always @(posedge sys_clk)
		if(!sys_rst_n)
		begin
			sys_ddr_read_data_req <= 0;		// 
			sys_ddr_write_data_valid <= 0;	// 
			sys_ddr_read_burst_begin <= 0;		// burst
			sys_ddr_write_burst_begin <= 0;	// burst
			ddr_wr_state <= 0;	// ddr
			// 
			audio_sample_en <= 0;		
			// NPU
			npu_inst_part_en <= 0;
		end
		else
		begin
			case(ddr_wr_state)
				0:	begin
					sys_ddr_read_data_req <= 0;		// 
					sys_ddr_write_data_valid <= 0;	// 
					sys_ddr_read_burst_begin <= 0;		// burst
					sys_ddr_write_burst_begin <= 0;	// burst
					// NPU
					npu_inst_part_en <= 0;
					//
					// ddr
					if(read_ddr_cmd)
						ddr_wr_state <= 1;
					// ddr
					else if(write_ddr_cmd)
						ddr_wr_state <= 3;
					// ddr
					else if(cont_write_cmd)
					begin
						ddr_wr_state <= 5;
						ddr_wr_number <= 0;
					end
					// ddr
					else if(cont_read_cmd)
					begin
						ddr_wr_state <= 7;
						ddr_wr_number <= 0;
					end
					// adc
					else if(adc_read_cmd)
					begin
						ddr_wr_state <= 10;
						ddr_wr_number <= 0;
					end
					// 
					else if(audio_sample_cmd)
					begin
						ddr_wr_state <= 13;
						ddr_wr_number <= 0;
						audio_sample_en <= 1;	// 
					end
					// DDR
					else if(measure_ram_cmd)
					begin
						ddr_wr_state <= 14;	// 
						ddr_wr_number <= 0;
						ddr_wr_time <= 0;	// 
					end
					// NPU
					else if(npu_inst_cmd)
					begin
						ddr_wr_state <= 18;
					end
				end
				
				// 
				1: begin
					// ddr
					if(sys_ddr_read_data_permitted)
					begin	
						sys_ddr_read_addr <= uart_cmd_shift_reg[39:8];
						sys_ddr_read_data_req <= 1;
						sys_ddr_read_burst_begin <= 1;	// burstïclockïï
						ddr_wr_state <= 2;
					end
				end
				
				2: begin
					sys_ddr_read_burst_begin <= 0;		// burst
					// ddr
					if(sys_ddr_read_data_permitted)
					begin	
						//sys_ddr_read_addr <= 0;
						sys_ddr_read_data_req <= 0;
						ddr_wr_state <= 0;
					end
				end	
					
				// 
				3: begin
					// ddr
					if(sys_ddr_write_data_permitted)
					begin
						sys_ddr_write_addr <= uart_cmd_shift_reg[71:40];
						sys_ddr_write_data <= uart_cmd_shift_reg[39:8];
						sys_ddr_write_data_valid <= 1;
						sys_ddr_write_burst_begin <= 1;	// burstïclockïï
						ddr_wr_state <= 4;
					end
				end
				
				4: begin
					sys_ddr_write_burst_begin <= 0;	// burst
					// ddr
					if(sys_ddr_write_data_permitted)
					begin	
						//sys_ddr_write_addr <= 0;
						//sys_ddr_write_data <= 0;
						sys_ddr_write_data_valid <= 0;
						ddr_wr_state <= 0;
					end
				end	
				
				
				// 
				5: begin
					// ddr
					if(sys_ddr_write_data_permitted)
					begin
						sys_ddr_write_addr <= uart_cmd_shift_reg[71:40];
						sys_ddr_write_data <= uart_cmd_shift_reg[71:40];	// 
						sys_ddr_write_data_valid <= 1;
						sys_ddr_write_burst_begin <= 1;	// burstïclockïï
						ddr_wr_state <= 6;
						// ++
						ddr_wr_number <= ddr_wr_number+1;
					end
				end
				
				6: begin
					sys_ddr_write_burst_begin <= 0;	// burst
					// ddr
					if(sys_ddr_write_data_permitted)
					begin	
						sys_ddr_write_addr <= sys_ddr_write_addr+1;
						sys_ddr_write_data <= sys_ddr_write_data+1;
						if(ddr_wr_number<uart_cmd_shift_reg[39:8])
						begin
							sys_ddr_write_data_valid <= 1;
							ddr_wr_number <= ddr_wr_number+1;
						end
						else 
						begin
							sys_ddr_write_data_valid <= 0;
							ddr_wr_state <= 0;
						end
					end
				end	
				
				// ddr
				7: begin
					// ddr
					if(sys_ddr_read_data_permitted)
					begin	
						sys_ddr_read_addr <= uart_cmd_shift_reg[71:40];
						sys_ddr_read_data_req <= 1;
						sys_ddr_read_burst_begin <= 1;	// burstïclockïï
						ddr_wr_state <= 8;
						// ++
						ddr_wr_number <= ddr_wr_number+1;
					end
				end
				
				8: begin
					sys_ddr_read_burst_begin <= 0;		// burst
					// ddr
					if(sys_ddr_read_data_permitted)
					begin	
						// ïïslavefifo
						if(ddr_wr_number<uart_cmd_shift_reg[39:8])
						begin
							// uartïddr++ï
							if(sys_uart_write_data_permitted_reg)
							begin
								sys_ddr_read_addr <= sys_ddr_read_addr+1;
								sys_ddr_read_data_req <= 1;
								// ++
								ddr_wr_number <= ddr_wr_number+1;
							end
							// uartïddr
							// ïïburst_begin
							else
							begin
								sys_ddr_read_data_req <= 0;
								ddr_wr_state <= 9;
							end
						end
						// ï
						else 
						begin
							sys_ddr_read_data_req <= 0;
							ddr_wr_state <= 0;
						end
					end
				end	
				
				9: begin
					// uart
					if(sys_uart_write_data_permitted_reg)
					begin	
						sys_ddr_read_addr <= sys_ddr_read_addr+1;
						sys_ddr_read_data_req <= 1;
						sys_ddr_read_burst_begin <= 1;	// burstïclockïï
						ddr_wr_state <= 8;
						// ++
						ddr_wr_number <= ddr_wr_number+1;
					end
				end
				/////////////////////////////////////////////////
				
				// adcddr
				10: begin
					// ddr
					if(sys_ddr_read_data_permitted)
					begin	
						sys_ddr_read_addr <= ((adc_ddr_write_addr-uart_cmd_shift_reg[39:8])&adc_ddr_write_addr_mask);
						sys_ddr_read_data_req <= 1;
						sys_ddr_read_burst_begin <= 1;	// burstïclockïï
						ddr_wr_state <= 11;
						// ++
						ddr_wr_number <= ddr_wr_number+1;
					end
				end
				
				11: begin
					sys_ddr_read_burst_begin <= 0;		// burst
					// ddr
					if(sys_ddr_read_data_permitted)
					begin	
						// ïïslavefifo
						if(ddr_wr_number<uart_cmd_shift_reg[39:8])
						begin
							// uartïddr++ï
							if(sys_uart_write_data_permitted_reg)
							begin
								sys_ddr_read_addr <= ((sys_ddr_read_addr+1)&adc_ddr_write_addr_mask);
								sys_ddr_read_data_req <= 1;
								// ++
								ddr_wr_number <= ddr_wr_number+1;
							end
							// uartïddr
							// ïïburst_begin
							else
							begin
								sys_ddr_read_data_req <= 0;
								ddr_wr_state <= 12;
							end
						end
						// ï
						else 
						begin
							sys_ddr_read_data_req <= 0;
							ddr_wr_state <= 0;
						end
					end
				end	
				
				12: begin
					// uart
					if(sys_uart_write_data_permitted_reg)
					begin	
						sys_ddr_read_addr <= ((sys_ddr_read_addr+1)&adc_ddr_write_addr_mask);
						sys_ddr_read_data_req <= 1;
						sys_ddr_read_burst_begin <= 1;	// burstïclockïï
						ddr_wr_state <= 11;
						// ++
						ddr_wr_number <= ddr_wr_number+1;
					end
				end
				
				13: begin
					// ttttttttclock
					if(ddr_wr_number>=uart_cmd_shift_reg[39:8])
					begin
						audio_sample_en <= 0;	// ï
						ddr_wr_number <= 0;
						ddr_wr_state <= 0;
					end
					else
						ddr_wr_number <= ddr_wr_number + 1;	// 
				end
				
				// DDR
				14: begin
					ddr_wr_time <= ddr_wr_time + 1;
					// ddr
					if(sys_ddr_write_data_permitted)
					begin
						sys_ddr_write_addr <= uart_cmd_shift_reg[71:40];
						sys_ddr_write_data <= uart_cmd_shift_reg[71:40];	// 
						sys_ddr_write_data_valid <= 1;
						ddr_wr_state <= 15;
						// ++
						ddr_wr_number <= ddr_wr_number+1;
					end
				end
				
				15: begin
					ddr_wr_time <= ddr_wr_time + 1;
					// ddr
					if(sys_ddr_write_data_permitted)
					begin	
						sys_ddr_write_addr <= sys_ddr_write_addr+1;
						sys_ddr_write_data <= sys_ddr_write_data+1;
						if(ddr_wr_number<uart_cmd_shift_reg[39:8])
						begin
							sys_ddr_write_data_valid <= 1;
							ddr_wr_number <= ddr_wr_number+1;
						end
						else 
						begin
							sys_ddr_write_data_valid <= 0;
							ddr_wr_state <= 16;	// DDR
							ddr_wr_number <= 0;
						end
					end
				end	
				
				16: begin
					ddr_wr_time <= ddr_wr_time + 1;
					// ddr
					if(sys_ddr_read_data_permitted)
					begin
						sys_ddr_read_addr <= uart_cmd_shift_reg[71:40];
						sys_ddr_read_data_req <= 1;
						ddr_wr_state <= 17;
						// ++
						ddr_wr_number <= ddr_wr_number+1;
					end
				end
				
				17: begin
					ddr_wr_time <= ddr_wr_time + 1;
					// ddr
					if(sys_ddr_read_data_permitted)
					begin	
						sys_ddr_read_addr <= sys_ddr_read_addr+1;
						if(ddr_wr_number<uart_cmd_shift_reg[39:8])
						begin
							sys_ddr_read_data_req <= 1;
							ddr_wr_number <= ddr_wr_number+1;
						end
						else 
						begin
							sys_ddr_read_data_req <= 0;
							ddr_wr_state <= 0;	// IDLE
						end
					end
				end	
				
				// NPU
				18: begin
					npu_inst_part <= uart_cmd_shift_reg[39:8];
					npu_inst_part_en <= 1;
					ddr_wr_state <= 0;	// IDLE
				end
				//////////////////////////////////////////////
				
				default: begin
					sys_ddr_read_data_req <= 0;		// 
					sys_ddr_write_data_valid <= 0;	// 
					sys_ddr_read_burst_begin <= 0;		// burst
					sys_ddr_write_burst_begin <= 0;	// burst
					ddr_wr_state <= 0;
				end
			endcase
		end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ï
reg		[4:0]	pkt_state;
reg		[31:0]	pkt_cnt;
always @(posedge sys_clk)
	if(!sys_rst_n)
	begin
		pkt_state <= 0;
		sys_uart_write_data_valid <= 0;
	end
	else
	begin
		case(pkt_state)
			0: begin
				sys_uart_write_data_valid <= 0;
				if(test_uart_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 1;
				end
				else if(read_ddr_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 2;
				end
				else if(write_ddr_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 3;
				end
				else if(cont_read_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 4;
				end
				else if(cont_write_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 5;
				end
				else if(adc_read_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 6;
				end
				else if(audio_sample_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 7;
				end
				else if(measure_ram_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 8;
				end
				else if(npu_inst_cmd)
				begin
					pkt_cnt <= 0;
					pkt_state <= 11;
				end
			end
			
			// uart 
			1: begin
				if(pkt_cnt >= (uart_cmd_shift_reg[39:8]+3))
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else
				begin
					if(sys_uart_write_data_permitted_reg)
					begin
						if(pkt_cnt==0) 		sys_uart_write_data <= 32'H68656C6C;	// hell
						else if(pkt_cnt==1)	sys_uart_write_data <= 32'H6F776F72;	// owor
						else if(pkt_cnt==2)	sys_uart_write_data <= 32'H6C646868;	// ldhh
						else				sys_uart_write_data <= pkt_cnt-3;	// ï00, 01, 02, ...
						pkt_cnt <= pkt_cnt + 1;
					end
					sys_uart_write_data_valid <= sys_uart_write_data_permitted_reg;
				end
			end
			
			// ddr
			2 : begin
				if(pkt_cnt >= 2)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else 
				begin
					if(pkt_cnt==0)
					begin
						if(sys_uart_write_data_permitted_reg)
						begin
							sys_uart_write_data <= 32'H72646472;	// rddr
							pkt_cnt <= pkt_cnt + 1;
							sys_uart_write_data_valid <= 1;
						end
						else
							sys_uart_write_data_valid <= 0;
					end
					else if(sys_ddr_read_data_valid_reg)
					begin
						sys_uart_write_data <= sys_key_fn[2]? sys_ddr_read_data_reg : {sys_ddr_read_data_reg[15:0], sys_ddr_read_data_reg[31:16]};	
						pkt_cnt <= pkt_cnt + 1;
						sys_uart_write_data_valid <= 1;
					end
					else
						sys_uart_write_data_valid <= 0;
				end
			end
			
			// ddr
			3: begin
				if(pkt_cnt >= 1)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else if(sys_uart_write_data_permitted_reg)
				begin
					sys_uart_write_data <= 32'H77646472;	// wddr
					pkt_cnt <= pkt_cnt + 1;
					sys_uart_write_data_valid <= 1;
				end
				else
					sys_uart_write_data_valid <= 0;
			end
			
			// ddr
			4: begin
				if(pkt_cnt >= uart_cmd_shift_reg[39:8]+1)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else 
				begin
					// 
					if(pkt_cnt==0)
					begin
						if(sys_uart_write_data_permitted_reg)
						begin
							sys_uart_write_data <= 32'H72636F6E;	// rcon
							pkt_cnt <= pkt_cnt + 1;
							sys_uart_write_data_valid <= 1;
						end
						else
							sys_uart_write_data_valid <= 0;
					end
					else if(sys_ddr_read_data_valid_reg)
					begin
						sys_uart_write_data <= sys_key_fn[2]? sys_ddr_read_data_reg : {sys_ddr_read_data_reg[15:0], sys_ddr_read_data_reg[31:16]};	
						pkt_cnt <= pkt_cnt + 1;
						sys_uart_write_data_valid <= 1;
					end
					else
						sys_uart_write_data_valid <= 0;
				end
			end
			
			// ddr 
			5: begin
				if(pkt_cnt >= 1)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else if(sys_uart_write_data_permitted_reg)
				begin
					sys_uart_write_data <= 32'H77636F6E;	// wcon
					pkt_cnt <= pkt_cnt + 1;
					sys_uart_write_data_valid <= 1;
				end
				else
					sys_uart_write_data_valid <= 0;
			end
			
			// ddr
			6: begin
				if(pkt_cnt >= uart_cmd_shift_reg[39:8]+1)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else 
				begin
					// 
					if(pkt_cnt==0)
					begin
						if(sys_uart_write_data_permitted_reg)
						begin
							sys_uart_write_data <= 32'H72616463;	// radc
							pkt_cnt <= pkt_cnt + 1;
							sys_uart_write_data_valid <= 1;
						end
						else
							sys_uart_write_data_valid <= 0;
					end
					else if(sys_ddr_read_data_valid_reg)
					begin
						sys_uart_write_data <= sys_key_fn[2]? sys_ddr_read_data_reg : {sys_ddr_read_data_reg[15:0], sys_ddr_read_data_reg[31:16]};	
						pkt_cnt <= pkt_cnt + 1;
						sys_uart_write_data_valid <= 1;
					end
					else
						sys_uart_write_data_valid <= 0;
				end
			end
			// 
			7: begin
				if(pkt_cnt >= 1)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else if(sys_uart_write_data_permitted_reg)
				begin
					sys_uart_write_data <= 32'H61756469;	// audi
					pkt_cnt <= pkt_cnt + 1;
					sys_uart_write_data_valid <= 1;
				end
				else
					sys_uart_write_data_valid <= 0;
			end
			// DDR
			8: begin
				// DDR
				if(ddr_wr_state>=15 && ddr_wr_number<=17)
				begin
					pkt_state <= 9;
					pkt_cnt <= 0;
				end
			end
			9: begin
				// DDR
				if(ddr_wr_state==0)
				begin
					pkt_state <= 10;
					pkt_cnt <= 0;
				end
			end
			10: begin
				// DDR
				if(pkt_cnt >= 2)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				// 
				else 
				begin
					if(pkt_cnt==0)
					begin
						if(sys_uart_write_data_permitted_reg)
						begin
							sys_uart_write_data <= 32'H6D646472;	// mddr
							pkt_cnt <= pkt_cnt + 1;
							sys_uart_write_data_valid <= 1;
						end
					end
					else if(pkt_cnt == 1)
					begin
						if(sys_uart_write_data_permitted_reg)
						begin
							sys_uart_write_data <= ddr_wr_time;	// ïcmdï
							pkt_cnt <= pkt_cnt + 1;
							sys_uart_write_data_valid <= 1;
						end
					end
				end
			end
			// NPU
			11: begin
				if(pkt_cnt >= 1)
				begin
					pkt_state <= 0;
					sys_uart_write_data_valid <= 0;
				end
				else if(sys_uart_write_data_permitted_reg)
				begin
					sys_uart_write_data <= 32'H696e7374;	// inst
					pkt_cnt <= pkt_cnt + 1;
					sys_uart_write_data_valid <= 1;
				end
				else
					sys_uart_write_data_valid <= 0;
			end
			//
			default: begin
				pkt_state <= 0;
				sys_uart_write_data_valid <= 0;
			end
			///////////
		endcase
	end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule

	
	