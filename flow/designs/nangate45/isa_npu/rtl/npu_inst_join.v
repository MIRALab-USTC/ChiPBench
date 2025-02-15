module npu_inst_join
(
	input	wire			npu_inst_clk, npu_inst_rst_n,
	input	wire	[31:0]	npu_inst_part,
	input	wire			npu_inst_part_en,
	output	reg		[127:0]	npu_inst,
	output	reg				npu_inst_en
);

	wire	RESETN = npu_inst_rst_n;
	// npu_inst/npu_inst_en
	// 
	reg		[3:0]	npu_inst_state;
	reg		[31:0]	npu_inst_delay;	// ïï
	always @(posedge npu_inst_clk)
		if(!RESETN)
		begin
			npu_inst_state <= 0;
			npu_inst <= 0;
			npu_inst_en <= 0;
			npu_inst_delay <= 0;
		end
		else
		begin
			case(npu_inst_state)
				0: begin
					if(npu_inst_part_en)
					begin
						npu_inst <= {npu_inst[95:0], npu_inst_part};
						npu_inst_en <= 0;
						npu_inst_state <= 1;
						npu_inst_delay <= 0;
					end
				end
				
				// ï
				1: begin
					if(npu_inst_part_en)
					begin
						npu_inst <= {npu_inst[95:0], npu_inst_part};
						npu_inst_en <= 0;
						npu_inst_delay <= 0;
					end
					else if(npu_inst_delay>=2000000)	// 40ms
					begin
						npu_inst_en <= 1;
						npu_inst_state <= 2;
						npu_inst_delay <= 0;
					end
					else 
						npu_inst_delay <= npu_inst_delay + 1;	// ++
				end
				
				// 
				2: begin
					npu_inst_en <= 0;
					npu_inst_state <= 0;
				end
				
				default: begin
					npu_inst_state <= 0;
					npu_inst <= 0;
					npu_inst_en <= 0;
					npu_inst_delay <= 0;
				end
				
			endcase
		end
		
endmodule