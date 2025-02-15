module uart_wr
#(	
	parameter	UART_DATA_WIDTH = 8,    // uart ����λ��
	parameter	UART_ADDR_WIDTH = 2,		// endpoint-��ַλ��
	parameter	SYS_UART_DATA_MULT = 4,	// system �� cypress uart ������λ��ı���
	parameter	SYS_DATA_WIDTH = UART_DATA_WIDTH*SYS_UART_DATA_MULT // system ������λ��
)
(
	input	wire						sys_clk, sys_rst_n, // ϵͳʱ�Ӻ͸�λ�ź�
	/* CYPRESS UART SLAVEFIFO */
	input	wire						uart_sys_clk, uart_sys_rst_n,
	input	wire						uart_rxd,
	output	wire						uart_txd,
	
	/* �����Ľӿ� */
	input		[SYS_DATA_WIDTH-1:0]	sys_write_data,			// Ҫ���͵� fifo������
	input								sys_write_data_valid,	// Ҫ���͵�������Ч
	output								sys_write_data_permitted,	// ����������
	output		[UART_DATA_WIDTH-1:0]	sys_read_data,			//  �� fifo �л�ȡ������
	input								sys_read_data_req,		// �� fifo �л�ȡ������ʹ��/����
	output								sys_read_data_permitted		// �����fifo�л�ȡ����
	);
	wire								logic_uart_write_data_empty;
	wire		[SYS_DATA_WIDTH-1:0]	logic_uart_write_data /* synthesis keep */;
	wire								logic_uart_write_data_valid = !logic_uart_write_data_empty /* synthesis keep */;
	wire								logic_uart_write_data_req;
	wire		[UART_DATA_WIDTH-1:0]	logic_uart_read_data /* synthesis keep*/;
	wire								logic_uart_read_data_valid /* synthesis keep*/;

	wire		[SYS_DATA_WIDTH-1:0]	logic_fifo_write_data /* synthesis keep */;
	wire								logic_fifo_write_data_valid /* synthesis keep */;
	wire		[5:0]					logic_fifo_write_usedw /* synthesis keep */;
	wire								logic_fifo_write_full /* synthesis keep */;
	wire		[UART_DATA_WIDTH-1:0]	logic_fifo_read_data /* synthesis keep */;
	wire								logic_fifo_read_data_req /* synthesis keep */;
	wire								logic_fifo_read_empty /* synthesis keep */;

	// ���ⲿ�Ľӿڸ�ֵ
	assign		logic_fifo_write_data = sys_write_data;
	assign		logic_fifo_write_data_valid = sys_write_data_valid;
	assign		sys_write_data_permitted = (logic_fifo_write_usedw[5:3]==0);	// Ӧ��Ҫ������벿�ֵĿռ䣬���ڻ���
	assign		sys_read_data = logic_fifo_read_data;
	assign		logic_fifo_read_data_req = sys_read_data_req;
	assign		sys_read_data_permitted = !logic_fifo_read_empty;
	
	
	wire		uart_tx_busy;
	assign		logic_uart_write_data_req = !uart_tx_busy && !logic_uart_write_data_empty;
	// uart ״̬��
	uart_rtl			uart_rtl_inst(
							.clock(uart_sys_clk),
							.rst(!uart_sys_rst_n),
							.uart_rxd(uart_rxd),
							.uart_txd(uart_txd),
							// system
							.rx_en(logic_uart_read_data_valid),
							.rx_data(logic_uart_read_data),
							.tx_en(logic_uart_write_data_req),
							.tx_busy(uart_tx_busy),
							.tx_data(logic_uart_write_data)
						);
						
	// Ȼ������1���������ݵ�dcfifo
//	alt_fifo_32b_64w		
	dc_fifo				#(
							.LOG2N(6),
							.DATA_WIDTH(32)
						)
						alt_fifo_32b_64w_inst(
							.aclr(!uart_sys_rst_n),
							.wrclock(sys_clk),
							.wrreq(logic_fifo_write_data_valid),
							.data(logic_fifo_write_data),
							.wrfull(logic_fifo_write_full),
							.wrusedw(logic_fifo_write_usedw),
							.rdclock(uart_sys_clk),
							.rdreq(logic_uart_write_data_req),
							.q(logic_uart_write_data),
							.rdempty(logic_uart_write_data_empty)
						);	
	// ��������һ�����ڽ���slavefifo��������ݵ�dcfifo
//	alt_fifo_8b_4w			
	dc_fifo				#(
							.LOG2N(4),
							.DATA_WIDTH(8)
						)
						alt_fifo_8b_4w_inst(
							.aclr(!uart_sys_rst_n),
							.wrclock(uart_sys_clk),
							.wrreq(logic_uart_read_data_valid),
							.data(logic_uart_read_data),
							.rdclock(sys_clk),
							.rdreq(logic_fifo_read_data_req),
							.q(logic_fifo_read_data),
							.rdempty(logic_fifo_read_empty)
						);
						
endmodule