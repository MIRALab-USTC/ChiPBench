module SyncSpRamBeNx64_00000008_00000100_0_2
  (
   Clk_CI,
   Rst_RBI,
   CSel_SI,
   WrEn_SI,
   BEn_SI,
   WrData_DI,
   Addr_DI,
   RdData_DO
   );
   
   input [7:0]   BEn_SI; // Byte-enable: ignore or use as needed
   input [63:0]  WrData_DI; // 64-bit write data
   input [7:0] 	 Addr_DI; // 8-bit address
   output [63:0] RdData_DO; // 64-bit read data
   input 	 Clk_CI;
   input 	 Rst_RBI; // Reset: ignore or use as needed
   input 	 CSel_SI;
   input 	 WrEn_SI;
   wire 	 csel_b, wren_b;
   wire [31:0] WMaskIn0, WMaskIn1;

   assign wren_b = ~WrEn_SI; // Active-low global-write-enable
   assign csel_b = ~CSel_SI; // Active-low chip-select-enable

   // Instantiate fakeram45_256x32 modules
   fakeram45_256x32 macro_mem_0 (
       .clk(Clk_CI),
       .rd_out(RdData_DO[31:0]),
       .ce_in(csel_b),
       .we_in(wren_b),
       .addr_in(Addr_DI),
       .w_mask_in(WMaskIn0),
       .wd_in(WrData_DI[31:0])
   );

   fakeram45_256x32 macro_mem_1 (
       .clk(Clk_CI),
       .rd_out(RdData_DO[63:32]),
       .ce_in(csel_b),
       .we_in(wren_b),
       .addr_in(Addr_DI),
       .w_mask_in(WMaskIn1),
       .wd_in(WrData_DI[63:32])
   );

endmodule // SyncSpRamBeNx64_00000008_00000100_0_2

module limping_SyncSpRamBeNx64_00000008_00000100_0_2
(
   Clk_CI,
   Rst_RBI,
   CSel_SI,
   WrEn_SI,
   BEn_SI,
   WrData_DI,
   Addr_DI,
   RdData_DO
);

   input [7:0]   BEn_SI;
   input [63:0]  WrData_DI;
   input [7:0]   Addr_DI;
   output [63:0] RdData_DO;
   input         Clk_CI;
   input         Rst_RBI;
   input         CSel_SI;
   input         WrEn_SI;
   wire          csel_b, wren_b;
   wire [15:0]   WMaskIn0, WMaskIn1;

   assign wren_b = ~WrEn_SI;
   assign csel_b = ~CSel_SI;

   // Instantiate fakeram45_256x16
   fakeram45_256x16 macro_mem_0 (
       .clk(Clk_CI),
       .rd_out(RdData_DO[15:0]),
       .ce_in(csel_b),
       .we_in(wren_b),
       .addr_in(Addr_DI),
       .w_mask_in(WMaskIn0),
       .wd_in(WrData_DI[15:0])
   );

   fakeram45_256x48 macro_mem_1 (
       .clk(Clk_CI),
       .rd_out(RdData_DO[63:16]),
       .ce_in(csel_b),
       .we_in(wren_b),
       .addr_in(Addr_DI),
       .w_mask_in(WMaskIn1),
       .wd_in(WrData_DI[63:16])
   );

endmodule // limping_SyncSpRamBeNx64_00000008_00000100_0_2

module SyncSpRamBeNx64_00000008_00000100_0_2_d45
  (
   Clk_CI,
   Rst_RBI,
   CSel_SI,
   WrEn_SI,
   BEn_SI,
   WrData_DI,
   Addr_DI,
   RdData_DO
   );
   
   input [7:0]   BEn_SI;
   input [44:0]  WrData_DI;
   input [7:0]   Addr_DI;
   output [44:0] RdData_DO;
   input 	 Clk_CI;
   input 	 Rst_RBI;
   input 	 CSel_SI;
   input 	 WrEn_SI;
   wire 	 csel_b, wren_b;
   wire [47:0] WrData_DO_wire, RdData_DO_wire;
   wire [47:0] WMaskIn;

   assign wren_b = ~WrEn_SI;
   assign csel_b = ~CSel_SI;
   assign WrData_DO_wire = {3'b0, WrData_DI};
   assign RdData_DO = RdData_DO_wire[44:0];

   // Instantiate fakeram45_256x48
   fakeram45_256x48 macro_mem (
       .clk(Clk_CI),
       .rd_out(RdData_DO_wire),
       .ce_in(csel_b),
       .we_in(wren_b),
       .addr_in(Addr_DI),
       .w_mask_in(WMaskIn),
       .wd_in(WrData_DO_wire)
   );

endmodule // SyncSpRamBeNx64_00000008_00000100_0_2_d45

module SyncSpRamBeNx64_00000008_00000100_0_2_d44
  (
   Clk_CI,
   Rst_RBI,
   CSel_SI,
   WrEn_SI,
   BEn_SI,
   WrData_DI,
   Addr_DI,
   RdData_DO
   );
   
   input [7:0]   BEn_SI; // byte-enable: ignore or use as needed
   input [43:0]  WrData_DI;
   input [7:0] 	 Addr_DI;
   output [43:0] RdData_DO;
   input 	 Clk_CI;
   input 	 Rst_RBI; // reset: ignore or use as needed
   input 	 CSel_SI;
   input 	 WrEn_SI;
   wire [47:0] 	 RdData_DO_wire;
   wire 	 csel_b,wren_b;
   wire [15:0] WMaskIn, NotWMaskIn;

   assign NotWMaskIn = 16'b0;
   assign WMaskIn = ~NotWMaskIn;   
   assign wren_b = ~WrEn_SI; // active-low global-write-enable
   assign csel_b = ~CSel_SI; // active-low chip-select-enable
   assign RdData_DO = RdData_DO_wire[43:0];

   fakeram45_256x16 macro_mem_0 (.clk(Clk_CI),.rd_out(RdData_DO_wire[15:0]), .ce_in(csel_b),.we_in(wren_b),.addr_in(Addr_DI),.w_mask_in(WMaskIn),.wd_in(WrData_DI[15:0]));
   fakeram45_256x16 macro_mem_1 (.clk(Clk_CI),.rd_out(RdData_DO_wire[31:16]),.ce_in(csel_b),.we_in(wren_b),.addr_in(Addr_DI),.w_mask_in(WMaskIn),.wd_in(WrData_DI[31:16]));
   fakeram45_256x16 macro_mem_2 (.clk(Clk_CI),.rd_out(RdData_DO_wire[47:32]),.ce_in(csel_b),.we_in(wren_b),.addr_in(Addr_DI),.w_mask_in(WMaskIn),.wd_in({4'b0000, WrData_DI[43:32]}));
   
endmodule // SyncSpRamBeNx64_00000008_00000100_0_2_d44

