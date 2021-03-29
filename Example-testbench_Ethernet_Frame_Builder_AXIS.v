`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cosmic AES
// Engineer: Joel Reindel
// 
// Create Date: Mon Jul 15 10:00:16 2019
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
module testbench_Ethernet_Frame_Builder_AXIS();

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
	Ethernet_Frame_Builder_AXIS uut (
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

    // test sequence
    parameter dIDLE = 64'h0; parameter kIDLE = 8'h0;
    parameter TPD0 = 64'h0001020304050607; parameter TPK0 = 8'b11111111;
    parameter TPD1 = 64'h08090A0B0C0D0E0F; parameter TPK1 = 8'b11111111;
    parameter TPD2 = 64'h1011121314151617; parameter TPK2 = 8'b11111111;
    parameter TPD3 = 64'h18191A1B1C1D1E1F; parameter TPK3 = 8'b11111111;
    parameter TPD4 = 64'h2021222324252627; parameter TPK4 = 9'b11111111;
    parameter TPD5 = 64'h2829000000000000; parameter TPK5 = 9'b11000000;
    parameter TPD6 = 64'h28292A0000000000; parameter TPK6 = 9'b11100000;
    parameter TPD7 = 64'h2800000000000000; parameter TPK7 = 9'b10000000;



	// Freerunning Clock
	initial begin
		cclk = 0;
		forever begin
			#3.2;// 152.25 MHz
			cclk = ~cclk;
		end
	end

	// Test Sequence
	initial begin
		// Initialize input
		reset_n = 1;
		dMAC = 48'h11_22_33_44_55_66;
		sMAC = 48'h50_76_af_a8_f5_e8;
		eType = 16'h0800;
		s_axis_tdata = dIDLE;
		s_axis_tkeep = kIDLE;
		s_axis_tvalid = 0;
		s_axis_tlast = 0;
		s_axis_tuser = 0;
		m_axis_tready = 1;
		#10;
		reset_n = 0;
		#10;
		reset_n = 1;
		// Wait for clear to finish
		#64;

		// Add stimulus here
		// Test expected type of sequence ending with 2 bytes in the last stream frame
		@(negedge cclk);
		s_axis_tvalid = 1;
		s_axis_tdata = TPD0; s_axis_tkeep = TPK0; #6.4;
        s_axis_tdata = TPD1; s_axis_tkeep = TPK1; #6.4;
        s_axis_tdata = TPD2; s_axis_tkeep = TPK2; #6.4;
        s_axis_tdata = TPD3; s_axis_tkeep = TPK3; #6.4;
        s_axis_tdata = TPD4; s_axis_tkeep = TPK4; #6.4;
        s_axis_tlast = 1;
        s_axis_tdata = TPD5; s_axis_tkeep = TPK5; #6.4;

        s_axis_tdata = dIDLE; s_axis_tkeep = kIDLE; 
        s_axis_tvalid = 0; s_axis_tlast = 0; s_axis_tuser = 0; m_axis_tready = 1;
        #32;
        
        // Test sequence ending with 3 bytes in the last stream frame
        @(negedge cclk);
        s_axis_tvalid = 1;
        s_axis_tdata = TPD0; s_axis_tkeep = TPK0; #6.4;
        s_axis_tdata = TPD1; s_axis_tkeep = TPK1; #6.4;
        s_axis_tdata = TPD2; s_axis_tkeep = TPK2; #6.4;
        s_axis_tdata = TPD3; s_axis_tkeep = TPK3; #6.4;
        s_axis_tdata = TPD4; s_axis_tkeep = TPK4; #6.4;
        s_axis_tlast = 1;
        s_axis_tdata = TPD6; s_axis_tkeep = TPK6; #6.4;

        s_axis_tdata = dIDLE; s_axis_tkeep = kIDLE; 
        s_axis_tvalid = 0; s_axis_tlast = 0; s_axis_tuser = 0; m_axis_tready = 1;
        #32;
        
        // Test sequence ending with 1 bytes in the last stream frame
        @(negedge cclk);
        s_axis_tvalid = 1;
        s_axis_tdata = TPD0; s_axis_tkeep = TPK0; #6.4;
        s_axis_tdata = TPD1; s_axis_tkeep = TPK1; #6.4;
        s_axis_tdata = TPD2; s_axis_tkeep = TPK2; #6.4;
        s_axis_tdata = TPD3; s_axis_tkeep = TPK3; #6.4;
        s_axis_tdata = TPD4; s_axis_tkeep = TPK4; #6.4;
        s_axis_tlast = 1;
        s_axis_tdata = TPD7; s_axis_tkeep = TPK7; #6.4;

        s_axis_tdata = dIDLE; s_axis_tkeep = kIDLE; 
        s_axis_tvalid = 0; s_axis_tlast = 0; s_axis_tuser = 0; m_axis_tready = 1;
        #32;
        
        // Test sequence ending with tuser set high with last frame
        @(negedge cclk);
        s_axis_tvalid = 1;
        s_axis_tdata = TPD0; s_axis_tkeep = TPK0; #6.4;
        s_axis_tdata = TPD1; s_axis_tkeep = TPK1; #6.4;
        s_axis_tdata = TPD2; s_axis_tkeep = TPK2; #6.4;
        s_axis_tdata = TPD3; s_axis_tkeep = TPK3; #6.4;
        s_axis_tdata = TPD4; s_axis_tkeep = TPK4; #6.4;
        s_axis_tlast = 1; s_axis_tuser = 1;
        s_axis_tdata = TPD5; s_axis_tkeep = TPK5; #6.4;

        s_axis_tdata = dIDLE; s_axis_tkeep = kIDLE; 
        s_axis_tvalid = 0; s_axis_tlast = 0; s_axis_tuser = 0; m_axis_tready = 1;
        #32;
        
        // Test sequence with tready going low durring transfer
        @(negedge cclk);
        s_axis_tvalid = 1;
        s_axis_tdata = TPD0; s_axis_tkeep = TPK0; #6.4;
        s_axis_tdata = TPD1; s_axis_tkeep = TPK1; #6.4;
        s_axis_tdata = TPD2; s_axis_tkeep = TPK2; #6.4;
        m_axis_tready = 0;
        s_axis_tdata = TPD3; s_axis_tkeep = TPK3; #6.4;
        m_axis_tready = 1;
        s_axis_tdata = TPD4; s_axis_tkeep = TPK4; #6.4;
        s_axis_tlast = 1; s_axis_tuser = 1;
        s_axis_tdata = TPD5; s_axis_tkeep = TPK5; #6.4;

        s_axis_tdata = dIDLE; s_axis_tkeep = kIDLE; 
        s_axis_tvalid = 0; s_axis_tlast = 0; s_axis_tuser = 0; m_axis_tready = 1;
        #32;
        
        #64;
		$finish;
	end
endmodule
