/*------------------------------------------------------------------------------*\
	FILE: 		top.v
 	AUTHOR:		Xudong Chen
 	
	ABSTRACT:	behavior of the top module of NPU
 	KEYWORDS:	fpga, NPU
 
 	MODIFICATION HISTORY:
	$Log$
			Xudong Chen 	18/8/5		original, 
\*-------------------------------------------------------------------------------*/
module npu_top(
    //////// CLOCK ////////
    input             CLOCK_50,    // 

    //////// LED ////////
    output     [8:0]  LEDG,
    output    [17:0]  LEDR,

    //////// KEY ////////
    input      [3:0]  KEY,

    //////// SW ////////
    input     [17:0]  SW,

    //////// RS232 ////////
    input             UART_RXD,
    output            UART_TXD,

    //////// SRAM ////////
    output    [19:0]  SRAM_ADDR,
    output            SRAM_CE_N,
    inout     [15:0]  SRAM_DQ,
    output            SRAM_LB_N,
    output            SRAM_OE_N,
    output            SRAM_UB_N,
    output            SRAM_WE_N
);

    ////////////////////////////////////////////////////////
    // SW (�)
    // [0]: reserved�0
    // [1]: reserved�0
    // [2]: reserved�0
    // [3]: KEY[3]CNN�1-->
    // [4]: reserved�0
    // [5]: CNN��1-->
    ////////////////////////////////////////////////////////

    //  ()
    wire TEST_MODE = (SW[5:1] == 5'b10100);
    wire SAMP_MODE = (SW[5:1] == 5'b00011);
    wire RUN_MODE  = (SW[5:1] == 5'b01001);
    wire SIMU_MODE = (SW[5:1] == 5'b01000); // �MFCCSRAM

    ////////////////////////////////////////////////////////
    // 
    wire RESET_N = KEY[0];

    ////////////////////////////////////////////////////////
    //  CLOCK60
    wire CLOCK60,CLOCK50,CLOCK40;
	assign CLOCK60 = CLOCK_50;
	assign CLOCK50 = CLOCK_50;
	assign CLOCK40 = CLOCK_50;

    ////////////////////////////////////////////////////////
    // 
    wire sys_clk;
	assign sys_clk  = CLOCK60;
	wire sys_rst_n;
    assign sys_rst_n = RESET_N;
	// uart
	// �
	// uart
	wire		[31:0]					sys_uart_write_data /* synthesis keep */;
	wire								sys_uart_write_data_valid /* synthesis keep */;
	wire								sys_uart_write_data_permitted /* synthesis keep */;
	wire		[15:0]					sys_uart_read_data /* synthesis keep */;
	wire								sys_uart_read_data_req /* synthesis keep */;
	wire								sys_uart_read_data_permitted /* synthesis keep */;
	// ddr
	wire		[31:0]					sys_ddr_write_addr /* synthesis keep */;
	wire		[31:0]					sys_ddr_write_data /* synthesis keep */;
	wire								sys_ddr_write_data_valid /* synthesis keep */;
	wire								sys_ddr_write_burst_begin /* synthesis keep */;
	wire								sys_ddr_write_data_permitted /* synthesis keep */;
	wire		[31:0]					sys_ddr_read_addr /* synthesis keep */;
	wire		[31:0]					sys_ddr_read_data /* synthesis keep */;
	wire								sys_ddr_read_data_valid /* synthesis keep */;
	wire								sys_ddr_read_burst_begin /* synthesis keep */;
	wire								sys_ddr_read_data_req /* synthesis keep */;
	wire								sys_ddr_read_data_permitted /* synthesis keep */;
	wire								logic_receive_valid_cmd;
	/********************************************************************************************/
	// NPU
	wire		[31:0]					npu_inst_part;
	wire								npu_inst_part_en;
	/*
	*/
	cmd_parser			cmd_parser_inst(
							.sys_clk(sys_clk),
							.sys_rst_n(sys_rst_n),
							.sys_uart_write_data(sys_uart_write_data),
							.sys_uart_write_data_valid(sys_uart_write_data_valid),
							.sys_uart_write_data_permitted(sys_uart_write_data_permitted),
							.sys_uart_read_data(sys_uart_read_data),
							.sys_uart_read_data_req(sys_uart_read_data_req),
							.sys_uart_read_data_permitted(sys_uart_read_data_permitted),
							.sys_ddr_write_addr(sys_ddr_write_addr),
							.sys_ddr_write_data(sys_ddr_write_data),
							.sys_ddr_write_data_valid(sys_ddr_write_data_valid),
							.sys_ddr_write_burst_begin(sys_ddr_write_burst_begin),
							.sys_ddr_write_data_permitted(sys_ddr_write_data_permitted),
							.sys_ddr_read_addr(sys_ddr_read_addr),
							.sys_ddr_read_data(sys_ddr_read_data),
							.sys_ddr_read_data_valid(sys_ddr_read_data_valid),
							.sys_ddr_read_data_req(sys_ddr_read_data_req),
							.sys_ddr_read_burst_begin(sys_ddr_read_burst_begin),
							.sys_ddr_read_data_permitted(sys_ddr_read_data_permitted),
							.receive_valid_cmd(logic_receive_valid_cmd),
							.sys_key_fn(8'HFF),
							//
							.adc_ddr_write_addr(),
							.adc_ddr_write_addr_mask(),
							//
							.audio_sample_en(audio_sample_en),
							// NPU
							.npu_inst_part(npu_inst_part),
							.npu_inst_part_en(npu_inst_part_en)
						);
	// 
	// cypress uart
	// uartslavefifo
	uart_wr				uart_wr_inst(
							.sys_clk(sys_clk),
							.sys_rst_n(sys_rst_n),
							.uart_rxd(UART_RXD),
							.uart_txd(UART_TXD),
							.uart_sys_clk(CLOCK50),
							.uart_sys_rst_n(RESET_N),
							.sys_write_data(sys_uart_write_data),
							.sys_write_data_valid(sys_uart_write_data_valid),
							.sys_write_data_permitted(sys_uart_write_data_permitted),
							.sys_read_data(sys_uart_read_data),
							.sys_read_data_req(sys_uart_read_data_req),
							.sys_read_data_permitted(sys_uart_read_data_permitted)
						);	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////
	///////////////////////////// NPU 
	/*
	*/
	wire	[127:0]				npu_inst /* synthesis noprune */;
	wire						npu_inst_en /* synthesis noprune */;
	wire						npu_inst_ready;
	// NPU
	wire	[31:0]				npu_inst_time;
	wire						NPU_DDR_WRITE_CLK;
	wire	[31:0]				NPU_DDR_WRITE_ADDR;
	wire	[31:0]				NPU_DDR_WRITE_DATA;
	wire						NPU_DDR_WRITE_REQ;
	wire						NPU_DDR_WRITE_READY;
	wire						NPU_DDR_READ_CLK;
	wire	[31:0]				NPU_DDR_READ_ADDR;
	wire						NPU_DDR_READ_REQ;
	wire						NPU_DDR_READ_READY;
	wire	[31:0]				NPU_DDR_READ_DATA;
	wire						NPU_DDR_READ_DATA_VALID;
	wire						npu_inst_clk = CLOCK60;
	wire						npu_inst_rst_n = RESET_N;
    wire    [31:0]              npu_inst_addr;
    wire    [127:0]             npu_inst_q;
	wire						npu_inst_start_vad;	// NPU
	// debug�NPU/
	// NPU�debug� KEY_CNN ==1���	// mark: 2018/6/4
	wire						KEY3_DOWN;	// 3
    wire                        npu_inst_start = TEST_MODE? ((npu_inst_en && npu_inst==128'D2)|KEY3_DOWN) : (RUN_MODE||SIMU_MODE)? npu_inst_start_vad : 0;	
	npu_inst_fsm				npu_inst_fsm_inst(
									.clk(npu_inst_clk),
									.rst_n(npu_inst_rst_n),
									.npu_inst_addr(npu_inst_addr),
									.npu_inst_q(npu_inst_q),
									.npu_inst_start(npu_inst_start),
									.npu_inst_ready(npu_inst_ready),
									.npu_inst_time(npu_inst_time),
									// DDR
									.DDR_WRITE_CLK(NPU_DDR_WRITE_CLK),
									.DDR_WRITE_ADDR(NPU_DDR_WRITE_ADDR),
									.DDR_WRITE_DATA(NPU_DDR_WRITE_DATA),
									.DDR_WRITE_REQ(NPU_DDR_WRITE_REQ),
									.DDR_WRITE_READY(NPU_DDR_WRITE_READY),
									.DDR_READ_CLK(NPU_DDR_READ_CLK),
									.DDR_READ_ADDR(NPU_DDR_READ_ADDR),
									.DDR_READ_REQ(NPU_DDR_READ_REQ),
									.DDR_READ_READY(NPU_DDR_READ_READY),
									.DDR_READ_DATA(NPU_DDR_READ_DATA),
									.DDR_READ_DATA_VALID(NPU_DDR_READ_DATA_VALID)
								);
	//  
	reg		[1:0]				KEY3;
	always @(posedge npu_inst_clk)
		KEY3 <= {KEY3[0], KEY[3]};
	assign						KEY3_DOWN = (KEY3==2'B10);
                                
    // NPU
    reg     [31:0]      npu_inst_wraddr;
    always @(posedge npu_inst_clk)
        if(npu_inst_en && npu_inst==128'D1)
            npu_inst_wraddr <= 0;
        else if(npu_inst_en && npu_inst!=128'D1 && npu_inst!=128'D2)
            npu_inst_wraddr <= npu_inst_wraddr  +1;
    // NPURAM
    npu_inst_ram            npu_inst_ram_inst(
                                .data(npu_inst),
                                .wren(npu_inst_en && npu_inst!=128'D1 && npu_inst!=128'D2),
                                .wraddress(npu_inst_wraddr),
                                .wrclock(npu_inst_clk),
                                .rdclock(npu_inst_clk),
                                .rdaddress(npu_inst_addr),
                                .q(npu_inst_q)
                            );   
    // NPURAM�memory editor
    npu_inst_ram_bak        npu_inst_ram_bak_inst(
                                .data(npu_inst),
                                .wren(npu_inst_en && npu_inst!=128'D1 && npu_inst!=128'D2),
                                .address(npu_inst_wraddr),
                                .clock(npu_inst_clk)
                            );   
							
	// npu_inst/npu_inst_en
	// 
	npu_inst_join			npu_inst_join_inst(
								.npu_inst_clk(npu_inst_clk),
								.npu_inst_rst_n(npu_inst_rst_n),
								.npu_inst_part(npu_inst_part),
								.npu_inst_part_en(npu_inst_part_en),
								.npu_inst(npu_inst),
								.npu_inst_en(npu_inst_en)
							);
	/////////////////////////////////////////////////////////////////////
	// CNN
	// CNN
	wire					cnn_paras_ready;	// 
	wire					cnn_paras_en = !KEY[2];	// 
	wire	[31:0]			cnn_paras_q;	// CNN
	wire	[31:0]			cnn_paras_addr;	// CNN
	// DDR
	wire					CNN_DDR_WRITE_CLK;
	wire	[31:0]			CNN_DDR_WRITE_ADDR;
	wire	[31:0]			CNN_DDR_WRITE_DATA;
	wire					CNN_DDR_WRITE_REQ;
	wire					CNN_DDR_WRITE_READY;
	//
	npu_paras_rom			npu_paras_rom_inst(
								.clock(CLOCK60),
								.address(cnn_paras_addr),
								.q(cnn_paras_q)
							);
	
	npu_paras_config		npu_paras_config_inst(
								.clk(CLOCK60),
								.rst_n(RESET_N),
								.npu_paras_ready(cnn_paras_ready),
								.npu_paras_en(cnn_paras_en),
								.npu_paras_addr(cnn_paras_addr),
								.npu_paras_q(cnn_paras_q),
								// DDR
								.DDR_WRITE_CLK(CNN_DDR_WRITE_CLK),
								.DDR_WRITE_ADDR(CNN_DDR_WRITE_ADDR),
								.DDR_WRITE_DATA(CNN_DDR_WRITE_DATA),
								.DDR_WRITE_REQ(CNN_DDR_WRITE_REQ),
								.DDR_WRITE_READY(CNN_DDR_WRITE_READY)
							);
	/////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////
	///////////////////
	// 
	wire		afi_phy_clk /* synthesis keep */;
	wire		afi_phy_rst_n /* synthesis keep */;
	// SSRAM
	// 	// ddrIP
	//	// 
	wire        local_ready;                //              local.waitrequest_n
	wire        local_burstbegin;           //                   .beginbursttransfer
	wire [31:0] local_addr;                 //                   .address
	wire        local_rdata_valid;          //                   .readdatavalid
	wire [31:0] local_rdata;                //                   .readdata
	wire [31:0] local_wdata;                //                   .writedata
	wire [3:0]  local_be;                   //                   .byteenable
	wire        local_read_req;             //                   .read
	wire        local_write_req;            //                   .write
	wire [2:0]  local_size;                 //                   .burstcount
	wire		local_waitrequest;
	//	// 
	wire        attach_ready;                //              attach.waitrequest_n
	wire        attach_burstbegin;           //                   .beginbursttransfer
	wire [31:0] attach_addr;                 //                   .address
	wire        attach_rdata_valid;          //                   .readdatavalid
	wire [31:0] attach_rdata;                //                   .readdata
	wire [31:0] attach_wdata;                //                   .writedata
	wire [3:0]  attach_be;                   //                   .byteenable
	wire        attach_read_req;             //                   .read
	wire        attach_write_req;            //                   .write
	wire [2:0]  attach_size;                 //                   .burstcount
	wire		attach_ready_w, attach_ready_r;	// 
	assign		attach_ready = 	attach_write_req? attach_ready_w : 
								attach_read_req? attach_ready_r : 
								attach_ready_w && attach_ready_r;	// �
	//
	///////// 
	// SSRAM
	sram_controller		sram_controller_inst(
							.CLOCK(CLOCK40),
							.RESET_N(RESET_N),
							.sram_avalon_clock(afi_phy_clk),
							.sram_avalon_reset_n(afi_phy_rst_n),
							.sram_avalon_address(local_addr),
							.sram_avalon_writedata(local_wdata),
							.sram_avalon_write_n(!local_write_req),
							.sram_avalon_read_n(!local_read_req),
							.sram_avalon_readdata(local_rdata),
							.sram_avalon_readdatavalid(local_rdata_valid),
							.sram_avalon_waitrequest(local_waitrequest),
							//
							.sram_pins_addr(SRAM_ADDR),
							.sram_pins_dq(SRAM_DQ),
							.sram_pins_ce_n(SRAM_CE_N),
							.sram_pins_oe_n(SRAM_OE_N),
							.sram_pins_we_n(SRAM_WE_N),
							.sram_pins_lb_n(SRAM_LB_N),
							.sram_pins_ub_n(SRAM_UB_N)
						);
	////////////////////////////////////////////////////////////////////////////////////////
	mux_ddr_access		mux_ddr_access_local_inst(
							.afi_phy_clk(afi_phy_clk),
							.afi_phy_rst_n(afi_phy_rst_n),
							//
							.local_address(local_addr),
							.local_write_req(local_write_req),
							.local_read_req(local_read_req),
							.local_burstbegin(local_burstbegin),
							.local_wdata(local_wdata),
							.local_be(local_be),
							.local_size(local_size),
							.local_ready(!local_waitrequest),
							.local_rdata(local_rdata),
							.local_rdata_valid(local_rdata_valid),
							//.local_refresh_ack,
							.local_init_done(RESET_N),
							///////////////
							// 
							.wport_clock_6(afi_phy_clk),
							.wport_addr_6(attach_addr),
							.wport_data_6(attach_wdata),
							.wport_req_6(attach_write_req),
							.wport_ready_6(attach_ready_w),
							.rport_clock_7(afi_phy_clk),
							.rport_addr_7(attach_addr),
							.rport_data_7(attach_rdata),
							.rport_data_valid_7(attach_rdata_valid),
							.rport_req_7(attach_read_req),
							.rport_ready_7(attach_ready_r),
							// MFCC mark[2018/6/6]: CNN�MFCC
							.wport_clock_4(),
							.wport_addr_4(),
							.wport_data_4(),
							.wport_req_4(),
							.wport_ready_4(),
							// MFCC
							.rport_clock_3(),
							.rport_addr_3(),
							.rport_data_3(),
							.rport_data_valid_3(),
							.rport_req_3(),
							.rport_ready_3(),
							// CNN mark[2018/6/6]: CNN�CNN
							.wport_clock_2(CNN_DDR_WRITE_CLK),
							.wport_addr_2(CNN_DDR_WRITE_ADDR),
							.wport_data_2(CNN_DDR_WRITE_DATA),
							.wport_req_2(CNN_DDR_WRITE_REQ && (RUN_MODE||TEST_MODE||SIMU_MODE)),
							.wport_ready_2(CNN_DDR_WRITE_READY),
							// NPU
							.wport_clock_0(NPU_DDR_WRITE_CLK),
							.wport_addr_0(NPU_DDR_WRITE_ADDR),
							.wport_data_0(NPU_DDR_WRITE_DATA),
							.wport_req_0(NPU_DDR_WRITE_REQ && (RUN_MODE||TEST_MODE||SIMU_MODE)),
							.wport_ready_0(NPU_DDR_WRITE_READY),
							// NPU
							.rport_clock_1(NPU_DDR_READ_CLK),
							.rport_addr_1(NPU_DDR_READ_ADDR),
							.rport_data_1(NPU_DDR_READ_DATA),
							.rport_data_valid_1(NPU_DDR_READ_DATA_VALID),
							.rport_req_1(NPU_DDR_READ_REQ && (RUN_MODE||TEST_MODE||SIMU_MODE)),
							.rport_ready_1(NPU_DDR_READ_READY)
						);
	// 
	mux_ddr_access		mux_ddr_access_attach_inst(
							.afi_phy_clk(afi_phy_clk),
							.afi_phy_rst_n(afi_phy_rst_n),
							//
							.local_address(attach_addr),
							.local_write_req(attach_write_req),
							.local_read_req(attach_read_req),
							.local_burstbegin(attach_burstbegin),
							.local_wdata(attach_wdata),
							.local_be(attach_be),
							.local_size(attach_size),
							.local_ready(attach_ready),
							.local_rdata(attach_rdata),
							.local_rdata_valid(attach_rdata_valid),
							//.local_refresh_ack,
							.local_init_done(RESET_N),
							///////////////
							//  
							.wport_clock_4(sys_clk),
							.wport_addr_4(sys_ddr_write_addr),
							.wport_data_4(sys_ddr_write_data),
							.wport_req_4(sys_ddr_write_data_valid),
							.wport_ready_4(sys_ddr_write_data_permitted),
							//  
							.rport_clock_5(sys_clk),
							.rport_addr_5(sys_ddr_read_addr),
							.rport_data_5(sys_ddr_read_data),
							.rport_data_valid_5(sys_ddr_read_data_valid),
							.rport_req_5(sys_ddr_read_data_req),
							.rport_ready_5(sys_ddr_read_data_permitted),
							//  
							.wport_clock_0(),
							.wport_addr_0(),
							.wport_data_0(),
							.wport_req_0(),
							.wport_ready_0(),
							// MFCC 
							.wport_clock_2(),
							.wport_addr_2(),
							.wport_data_2(),
							.wport_req_2(),
							.wport_ready_2()
							
						);
	


endmodule