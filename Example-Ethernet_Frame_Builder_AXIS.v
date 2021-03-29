`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cosmic AES
// Engineer: Joel Reindel
// 
// Create Date: 07/11/2019 12:41:53 PM
// Design Name: 10GbE MAC & PHY
// Module Name: Ethernet_Frame_Builder_AXIS
// Project Name: RLSD (Sif)
// Target Devices: xcku085-flf1924 
// Tool Versions: Vivado 2018.2.1
// Description: Takes payload as input and packages into an ethernet frame (minus the CRC) 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: This file was designed for a 64 bit data path
// 
//////////////////////////////////////////////////////////////////////////////////


module Ethernet_Frame_Builder_AXIS(
    input wire cclk, // clock
    input wire reset_n, // asyncronous active low reset
    
    // Header info
    input wire [47:0] dMAC, // destination MAC
    input wire [47:0] sMAC, // source MAC 
    input wire [15:0] eType, // ethernet type. Should be 0x0800 for IPv4 
    
    // Slave Interface
    input wire [63:0] s_axis_tdata, // AXI-S slave input: transfer payload 
    input wire [7:0] s_axis_tkeep, // AXI-S slave input: byte qualifyer for payload data. 1 = payload byte, 0 = null byte
    input wire s_axis_tvalid, // AXI-S slave input: indicates that the master is driving a valid transfer.
    output reg s_axis_tready, // AXI-S slave output: indicates that the slave can accept a transfer in the current cycle.
    input wire s_axis_tlast, // AXI-S slave input: indicates the boundry of a packet
    input wire s_axis_tuser, // AXI-S slave input: User specified sideband information. When asserted syncronous with tlast this errors out the ethernet frame (canceling packet?)
    
    // Master Interface
    output reg [63:0] m_axis_tdata, // AXI-S master output: 
    output reg [7:0] m_axis_tkeep, // AXI-S master output:
    output reg m_axis_tvalid, // AXI-S master output:
    input wire m_axis_tready, // AXI-S master input: If slave is not ready (deaserted), from start to end of transfer (inclusive), this will cause pipline jam error
    output reg m_axis_tlast, // AXI-S output:
    output reg m_axis_tuser, // AXI-S output: indicates control or error command on xgmii or bad crc. Equivelant to rx_error_bad_frame is high.

    // Error Codes
    output reg err_pipe_jam // Caused by downstream slave not being ready for output stream.
    );
    
    // States
    parameter IDLE      = 3'h0,
              HEADER1   = 3'h1,
              HEADER2   = 3'h2,
              STREAM    = 3'h3,
              LAST      = 3'h4,
              ONE_MORE  = 3'h5;
    
    // Wire Declarations
    wire reset;
    wire [63:0] tdata_out;
    wire [7:0] tkeep_out;
    
    // Register Declarations
    reg [2:0] state, nextState;
    reg [63:0] data_buf_0; 
    reg [63:0] data_buf_1;
    reg [63:0] data_buf_2;
    reg [47:0] data_buf_3;
    reg [63:0] data_buf_next_0;
    reg [63:0] data_buf_next_1;
    reg [63:0] data_buf_next_2;
    reg [47:0] data_buf_next_3;
    reg [7:0] keep_buf_0;
    reg [7:0] keep_buf_1;
    reg [7:0] keep_buf_2;
    reg [5:0] keep_buf_3;
    reg [7:0] keep_buf_next_0;
    reg [7:0] keep_buf_next_1;
    reg [7:0] keep_buf_next_2;
    reg [5:0] keep_buf_next_3;
    reg last_buf_0;
    reg last_buf_1;
    reg last_buf_2;
    reg last_buf_3;
    reg last_buf_next_0;
    reg last_buf_next_1;
    reg last_buf_next_2;
    reg last_buf_next_3;
    reg user_buf_0;
    reg user_buf_1;
    reg user_buf_2;
    reg user_buf_3;
    reg user_buf_next_0;
    reg user_buf_next_1;
    reg user_buf_next_2;
    reg user_buf_next_3;
        
    // Cuseronnections
    assign reset = !reset_n;
    assign tdata_out = {data_buf_3, data_buf_2[63:48]}; // data rearangement
    assign tkeep_out  ={keep_buf_3, keep_buf_2[7:6]}; // keep rearangement
    
    // Initialization
    initial begin
        s_axis_tready = 0;
        m_axis_tdata = 0;
        m_axis_tkeep = 0;
        m_axis_tvalid = 0;
        m_axis_tlast = 0;
        m_axis_tuser = 0;
        err_pipe_jam = 0;
        state = IDLE;
        nextState = IDLE;
        data_buf_0 = 0;
        data_buf_1 = 0;
        data_buf_2 = 0;
        data_buf_3 = 0;
        data_buf_next_0 = 0;
        data_buf_next_1 = 0;
        data_buf_next_2 = 0;
        data_buf_next_3 = 0;
        keep_buf_0 = 0;
        keep_buf_1 = 0;
        keep_buf_2 = 0;
        keep_buf_3 = 0;
        keep_buf_next_0 = 0;
        keep_buf_next_1 = 0;
        keep_buf_next_2 = 0;
        keep_buf_next_3 = 0;
        last_buf_0 = 0;
        last_buf_1 = 0;
        last_buf_2 = 0;
        last_buf_3 = 0;
        last_buf_next_0 = 0;
        last_buf_next_1 = 0;
        last_buf_next_2 = 0;
        last_buf_next_3 = 0;
        user_buf_0 = 0;
        user_buf_1 = 0;
        user_buf_2 = 0;
        user_buf_3 = 0;
        user_buf_next_0 = 0;
        user_buf_next_1 = 0;
        user_buf_next_2 = 0;
        user_buf_next_3 = 0;
    end
    
    // feed forward buffer connections (async)
    always @(*) begin
        data_buf_next_0 =  s_axis_tdata;
        data_buf_next_1 = data_buf_0;
        data_buf_next_2 = data_buf_1;
        data_buf_next_3 = data_buf_2[48:0];
        
        keep_buf_next_0 =  s_axis_tkeep;
        keep_buf_next_1 = keep_buf_0;
        keep_buf_next_2 = keep_buf_1;
        keep_buf_next_3 = keep_buf_2[5:0];
        
        last_buf_next_0 = s_axis_tlast;
        last_buf_next_1 = last_buf_0;
        last_buf_next_2 = last_buf_1;
        last_buf_next_3 = last_buf_2; 
        
        user_buf_next_0 = s_axis_tuser;
        user_buf_next_1 = user_buf_0;
        user_buf_next_2 = user_buf_1;
        user_buf_next_3 = user_buf_2;
        
    end
    
    // Buffer advancement syncronous logic. Posedge triggered for initial capture of input
    always @(posedge cclk or posedge reset) begin
        if(reset) begin
            data_buf_0 <= 0;
            keep_buf_0 <= 0;
            last_buf_0 <= 0;
            user_buf_0 <= 0;
        end
        else begin
            data_buf_0 <= data_buf_next_0;            
            keep_buf_0 <= keep_buf_next_0;            
            last_buf_0 <= last_buf_next_0;            
            user_buf_0 <= user_buf_next_0;        
        end
    end
    
    // Buffer advancement syncronous logic. Negedge triggered for output facing registers
    always @(negedge cclk or posedge reset) begin
        if(reset) begin
            data_buf_1 <= 0;
            data_buf_2 <= 0;
            data_buf_3 <= 0;
            keep_buf_1 <= 0;
            keep_buf_2 <= 0;
            keep_buf_3 <= 0;
            last_buf_1 <= 0;
            last_buf_2 <= 0;
            last_buf_3 <= 0;
            user_buf_1 <= 0;
            user_buf_2 <= 0;
            user_buf_3 <= 0; 
        end
        else begin
            data_buf_1 <= data_buf_next_1;
            data_buf_2 <= data_buf_next_2;
            data_buf_3 <= data_buf_next_3;
            keep_buf_1 <= keep_buf_next_1;
            keep_buf_2 <= keep_buf_next_2;
            keep_buf_3 <= keep_buf_next_3;
            last_buf_1 <= last_buf_next_1;
            last_buf_2 <= last_buf_next_2;
            last_buf_3 <= last_buf_next_3;
            user_buf_1 <= user_buf_next_1;
            user_buf_2 <= user_buf_next_2;
            user_buf_3 <= user_buf_next_3;
        end
    end
    
    // State machine combo logic to control insert of header
    always @(*) begin
        case (state)
            IDLE: begin        //      = 3'h0,
                m_axis_tdata = 0; 
                m_axis_tkeep = 0;
                m_axis_tvalid = 0;
                s_axis_tready = 1;
                m_axis_tlast = 0;
                m_axis_tuser = 0;
                err_pipe_jam = 0;
                if(s_axis_tvalid) begin
                    nextState = HEADER1;
                end
                else begin
                    nextState = IDLE;
                end
            end
            
            HEADER1: begin        //   = 3'h1,
                m_axis_tdata = {dMAC[47:0],sMAC[47:32]}; 
                m_axis_tkeep = 8'hff;
                m_axis_tvalid = 1;
                s_axis_tready = 1;
                m_axis_tlast = 0;
                m_axis_tuser = 0;
                if(!m_axis_tready)
                    err_pipe_jam = 1;
                else
                    err_pipe_jam = 0;
                nextState = HEADER2;
            end
            
            HEADER2: begin        //   = 3'h2,
                m_axis_tdata = {sMAC[31:0],eType[15:0],tdata_out[15:0]}; 
                m_axis_tkeep = {6'b111111,tkeep_out[1:0]};
                m_axis_tvalid = 1;
                s_axis_tready = 1;
                m_axis_tlast = 0;
                m_axis_tuser = 0;
                if(!m_axis_tready)
                    err_pipe_jam = 1;
                else
                    err_pipe_jam = 0;
                nextState = STREAM;
            end
            
            STREAM: begin        //    = 3'h3,
                m_axis_tdata = tdata_out; 
                m_axis_tkeep = tkeep_out;
                m_axis_tvalid = 1;
                s_axis_tready = 1;
                m_axis_tlast = 0;
                m_axis_tuser = 0;
                if(!m_axis_tready)
                    err_pipe_jam = 1;
                else
                    err_pipe_jam = 0;
                    
                if(last_buf_0) begin // last seen on input
                    nextState = LAST;
                end
                else begin
                    nextState = STREAM;
                end
            end
            
            LAST: begin        //      = 3'h4;
                m_axis_tdata = tdata_out; 
                m_axis_tkeep = tkeep_out;
                m_axis_tvalid = 1;
                s_axis_tready = 0;
                m_axis_tuser = 0;
                /*if(!m_axis_tready)
                    err_pipe_jam = 1;
                else
                    err_pipe_jam = 0;*/
                    
                if(last_buf_1) begin // last in buffer
                    if(keep_buf_1[5:0] != 6'b000000) begin // one more transfer
                        m_axis_tlast = 0;
                        nextState = ONE_MORE;
                    end
                    else begin // this is the last transfer
                        m_axis_tlast = last_buf_1;
                        m_axis_tuser = user_buf_1;
                        nextState = IDLE;
                    end
                end
                else begin // still steaming
                    m_axis_tlast = 0;
                    nextState = STREAM;
                end
            end
            
            ONE_MORE: begin        //  = 3'h5;
                m_axis_tdata = tdata_out; 
                m_axis_tkeep = tkeep_out;
                m_axis_tvalid = 1;
                s_axis_tready = 0;
                m_axis_tlast = last_buf_2;
                m_axis_tuser = user_buf_2;
                /*if(!m_axis_tready)
                    err_pipe_jam = 1;
                else
                    err_pipe_jam = 0;*/
                nextState = IDLE;
            end
            
            default: begin
                m_axis_tdata = 0; 
                m_axis_tkeep = 0;
                m_axis_tvalid = 0;
                s_axis_tready = 1;
                m_axis_tlast = 0;
                m_axis_tuser = 0;
                err_pipe_jam = 0;
                nextState = IDLE;
            end
        endcase
    end
    
    // State machine syncronous logic and reset
    always @(negedge cclk or posedge reset) begin
        if(reset) begin
            state <= IDLE;
        end
        else begin
            state <= nextState;
        end
    end
    
    
endmodule
