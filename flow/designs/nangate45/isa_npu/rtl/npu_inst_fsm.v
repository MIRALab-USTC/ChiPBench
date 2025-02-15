// CNN
module npu_inst_fsm
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
	input	wire	[INST_WIDTH-1:0]	npu_inst_q,	// CNN
	output	reg 	[DATA_WIDTH-1:0]	npu_inst_addr,	// CNN
	input	wire						npu_inst_start,	// 
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

    // 
    reg     [3:0]   cstate;
    reg     [10:0]  delay;
    reg             npu_inst_parser_en;
    wire            npu_inst_parser_ready;
    always @(posedge clk)
        if(!rst_n)
        begin
            cstate <= 0;
            npu_inst_parser_en <= 0;
        end
        else 
        begin
            case(cstate)
                0: begin
                    if(npu_inst_start)
                    begin
                        npu_inst_addr <= 0;
                        cstate <= 1;
                        delay <= 0;
                        npu_inst_parser_en <= 0;
                    end
                end
                
                1: begin
                    if(delay>=3)
                    begin
                        if(npu_inst_q==128'D0)  // NOP
                        begin
                            cstate <= 0;
                            npu_inst_parser_en <= 0;
                        end
                        else if(npu_inst_parser_ready)
                        begin
                            cstate <= 2;
                            npu_inst_parser_en <= 1;
                        end
                    end
                    
                    else
                        delay <= delay + 1;
                end
                
                2: begin
                    npu_inst_parser_en <= 0;    // 
                    cstate <= 5;
                    delay <= 0;
                end
                
                // 
                5: begin
                    if(delay>=5)
                        cstate <= 3;
                    else
                        delay <= delay + 1;
                end
                
                3: begin
                    if(npu_inst_parser_ready)
                    begin
                        cstate <= 4;
                        npu_inst_parser_en <= 0;
                    end
                end
                
                4: begin
                    npu_inst_addr <= npu_inst_addr + 1;
                    cstate <= 1;
                    delay <= 0;
                end
                
                
                default: begin
                    cstate <= 0;
                    npu_inst_parser_en <= 0;
                end
                
            endcase
        
        end
        
    //
    always @(posedge clk)
        npu_inst_ready <= (cstate==0);
        
    always @(posedge clk)
        if(npu_inst_start)
            npu_inst_time <= 0;
        else if(!npu_inst_ready)
            npu_inst_time <= npu_inst_time + 1;
        
    // CNN
	npu_inst_excutor			npu_inst_excutor_inst(
									.clk(clk),
									.rst_n(rst_n),
									.npu_inst(npu_inst_q),
									.npu_inst_en(npu_inst_parser_en),
									.npu_inst_ready(npu_inst_parser_ready),
									// DDR
									.DDR_WRITE_CLK(DDR_WRITE_CLK),
									.DDR_WRITE_ADDR(DDR_WRITE_ADDR),
									.DDR_WRITE_DATA(DDR_WRITE_DATA),
									.DDR_WRITE_REQ(DDR_WRITE_REQ),
									.DDR_WRITE_READY(DDR_WRITE_READY),
									.DDR_READ_CLK(DDR_READ_CLK),
									.DDR_READ_ADDR(DDR_READ_ADDR),
									.DDR_READ_REQ(DDR_READ_REQ),
									.DDR_READ_READY(DDR_READ_READY),
									.DDR_READ_DATA(DDR_READ_DATA),
									.DDR_READ_DATA_VALID(DDR_READ_DATA_VALID)
								);

endmodule