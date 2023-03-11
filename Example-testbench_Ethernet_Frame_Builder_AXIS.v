`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: Fri Mar 10 17:40:20 2023
// Design Name: 
// Module Name: Ethernet_Frame_Builder_AXIS
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module testbench_Ethernet_Frame_Builder_AXIS#(
)();

	// inputs
	reg cclk;
	reg reset_n;
	reg [47:0]dMAC;
	reg [47:0]sMAC;
	reg [15:0]eType;
	reg [63:0]s_axis_tdata;
	reg [7:0]s_axis_tkeep;
	reg s_axis_tvalid;
	reg s_axis_tlast;
	reg s_axis_tuser;
	reg m_axis_tready;

	// outputs
	wire s_axis_tready;
	wire [63:0]m_axis_tdata;
	wire [7:0]m_axis_tkeep;
	wire m_axis_tvalid;
	wire m_axis_tlast;
	wire m_axis_tuser;
	wire err_pipe_jam;

	// unit under test
	Ethernet_Frame_Builder_AXIS#(
) uut (
	.cclk(cclk),	// input  cclk (clock)
	.reset_n(reset_n),	// input  reset_n (asyncronous active low reset)
	.dMAC(dMAC),	// input [47:0] dMAC (destination MAC)
	.sMAC(sMAC),	// input [47:0] sMAC (source MAC)
	.eType(eType),	// input [15:0] eType (ethernet type. Should be 0x0800 for IPv4)
	.s_axis_tdata(s_axis_tdata),	// input [63:0] s_axis_tdata (AXI-S slave input: transfer payload)
	.s_axis_tkeep(s_axis_tkeep),	// input [7:0] s_axis_tkeep (AXI-S slave input: byte qualifyer for payload data. 1 = payload byte, 0 = null byte)
	.s_axis_tvalid(s_axis_tvalid),	// input  s_axis_tvalid (AXI-S slave input: indicates that the master is driving a valid transfer.)
	.s_axis_tready(s_axis_tready),	// output  s_axis_tready (AXI-S slave output: indicates that the slave can accept a transfer in the current cycle.)
	.s_axis_tlast(s_axis_tlast),	// input  s_axis_tlast (AXI-S slave input: indicates the boundry of a packet)
	.s_axis_tuser(s_axis_tuser),	// input  s_axis_tuser (AXI-S slave input: User specified sideband information. When asserted syncronous with tlast this errors out the ethernet frame (canceling packet?))
	.m_axis_tdata(m_axis_tdata),	// output [63:0] m_axis_tdata (AXI-S master output:)
	.m_axis_tkeep(m_axis_tkeep),	// output [7:0] m_axis_tkeep (AXI-S master output:)
	.m_axis_tvalid(m_axis_tvalid),	// output  m_axis_tvalid (AXI-S master output:)
	.m_axis_tready(m_axis_tready),	// input  m_axis_tready (AXI-S master input: If slave is not ready (deaserted), from start to end of transfer (inclusive), this will cause pipline jam error)
	.m_axis_tlast(m_axis_tlast),	// output  m_axis_tlast (AXI-S output:)
	.m_axis_tuser(m_axis_tuser),	// output  m_axis_tuser (AXI-S output: indicates control or error command on xgmii or bad crc. Equivelant to rx_error_bad_frame is high.)
	.err_pipe_jam(err_pipe_jam)	// output  err_pipe_jam (Caused by downstream slave not being ready for output stream.)
	);

	// Freerunning Clock(s)?
//	initial begin
//		clk = 0;
//		forever begin
//			#0.5;// 1ns cycle
//			clk = ~clk;
//		end
//	end

	// Test Sequence
	initial begin
		// Initialize inputs
		cclk = 0;
		reset_n = 0;
		dMAC = 'b0;
		sMAC = 'b0;
		eType = 'b0;
		s_axis_tdata = 'b0;
		s_axis_tkeep = 'b0;
		s_axis_tvalid = 0;
		s_axis_tlast = 0;
		s_axis_tuser = 0;
		m_axis_tready = 0;
		// Wait for clear to finish
		#100;

		// Add stimulus here
		
		
		$finish;
	end
endmodule
