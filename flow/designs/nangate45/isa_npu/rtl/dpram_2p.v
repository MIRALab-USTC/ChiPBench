/*-------------------------------------------------------------------------*\
	FILE:			dpram_2p.v
	AUTHOR:			Xudong Chen
	CREATED BY:		Xudong Chen
	$Id$
	ABSTRACT:		behavioral code for dual-clock ram module
	
	KEYWORDS:		dpram
	MODIFICATION HISTORY:
	$Log$
		Xudong 		18/6/20			original version
\*-------------------------------------------------------------------------*/

module dpram_2p
#(
parameter	LOG2N = 9,				// 这是FIFO深度的对数值
parameter	N = (1<<LOG2N),			// FIFO的深度
parameter	DATA_WIDTH = 32,		// 数据宽度
parameter	ADDR_WIDTH = LOG2N 		// 地址宽度
)
(
    input   wire						aclr,			// 异步复位
    // 写入端口的信号线
    input	wire						wrclock,		// 写时钟
    input	wire	[DATA_WIDTH-1:0]	data,			// 写数据
    input	wire						wrreq,			// 写请求
    input	wire	[ADDR_WIDTH-1:0]	wraddr,			// 写地址
    // 读取端口的信号线
    input	wire						rdclock,		// 读时钟
    output	reg		[DATA_WIDTH-1:0]	q,				// 读数据
    input	wire						rdreq,			// 读请求
    input	wire	[ADDR_WIDTH-1:0]	rdaddr			// 读地址
);

    // 实例化fakeram45_512x64
    wire [63:0] ram_read_data;      // 从RAM读取的64位数据
    wire [63:0] ram_write_data;     // 写入RAM的64位数据

    // 将32位输入数据扩展为64位
    assign ram_write_data = {32'b0, data}; // 写入低32位，高32位未使用

    // 实例化fakeram45_512x64
    fakeram45_512x64 ram_instance (
        .clk(wrclock),                 // 写时钟
        .ce_in(1'b1),                  // 芯片使能，始终有效
        .we_in(wrreq),                 // 写使能信号
        .addr_in(wrreq ? wraddr : rdaddr), // 写地址或读地址，根据操作选择
        .wd_in(ram_write_data),        // 写入的数据
        .w_mask_in(64'h00000000FFFFFFFF), // 写掩码，仅写入低32位
        .rd_out(ram_read_data)         // 读取的数据输出
    );

    // 提取低32位作为读数据
    always @(posedge rdclock or posedge aclr)
        if (aclr)
            q <= 32'b0;
        else if (rdreq)
            q <= ram_read_data[31:0];  // 只取低32位数据

endmodule
