`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/15 11:37:42
// Design Name: 
// Module Name: axi_fifo_spi
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  control module compared with regs_mod and fifo2spi
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_fifo_spi(
       
       //clk and rstn
       input clk_i,
       input aresetn,
       
       // interface with axi axi 
       input wr_valid,
       input rd_valid,
       input [1:0] rw_addr,
       input wire [31:0] slv_reg0, // control_reg
       input wire [31:0] slv_reg1, // transfer control reg
       input wire [31:0] slv_reg2, // status reg
       input wire [31:0] slv_reg3, // wr/rd fifo reg
 
       //interface with fifo
        // rx_fifo
       //input wire  [31:0] rx_fifo_data_i,
       input wire  rx_fifo_empty_i,
       output wire rx_fifo_pull_o,
        //tx_fifo
       input wire tx_fifo_full_i,
       output reg tx_fifo_push_o,
       output reg [31:0] tx_fifo_data,

      //interface with spi,
      input wire trans_done_i,
      output wire trans_start_o,
      output reg [31:0] reg_control_o,
      output reg [31:0] transfer_control_o,
      output reg [31:0] reg_status_o,
      output reg [31:0] rx_fifo_data


    );
    
    reg spi_busy;
    //control reg
    /*=============================================================================================
	--  Control Register		|		R(h)W
	--=============================================================================================*/
	//   spi_clk_div	|	3:0		||		Clock ratio AXI / SPI 								|| reset value : 1
	//   reserved		|	7:4		||		default 0												|| reset value : 0
	//   data_order	|	8:8		||		1: MSB first, 0: LSB first							|| reset value : 0
	//	  CPOL  			|	9:9		||		1: SCLK HIGH in IDLE, 0: SCLK LOW in IDLE		|| reset value : 0
	//	  CPHA	 		|	10:10		||		1: Leading edge setup, Trailing edge sample 
	//												0: Leading edge sample, Trailing edge setup	|| reset value : 0
	//	  reserved		|	31:11		||		default 0												|| reset value : 0
    always@(posedge clk_i or negedge aresetn)begin
     if(!aresetn)
        reg_control_o <= 32'd0;
     else if(wr_valid && rw_addr == 2'h0)
        reg_control_o <= slv_reg0;
     else if(rd_valid && rw_addr == 2'h0)
        reg_control_o <= reg_control_o;
    end
    
    //transfer reg
    /*=============================================================================================
	--  Transfer Control Register	|	R(h)W
	--=============================================================================================*/
	//  slv_0_en		|	0:0		||		SS 0 enable		(0 disable, 1 enable)			|| reset value : 0
	//  slv_1_en		|	1:1		||		SS 1 enable		(0 disable, 1 enable)			|| reset value : 0
	//  slv_2_en		|	2:2		||		SS 2 enable		(0 disable, 1 enable)			|| reset value : 0
	//  slv_3_en		|	3:3		||		SS 3 enable		(0 disable, 1 enable)			|| reset value : 0
	//  reserved		|	4:4		||		default 0												|| reset value : 0	
	//  Bits per trans|	6:5		||		Num of bits per tranfer								|| reset value : 0
	//												00 - 8 default			
	//												01	- 16
	//												10 - 32
	//												11 - ignored		
	//	 reserved		|  12:7		|| 	default 0												|| reset value : 0
	//	 trans_start   |  13:13   	||    1: Transfer is ready to start, 0: IDLE			|| reset value : 0
	//	 reserved		|	31:14		||		default 0												|| reset value : 0
	wire start_flag;
	reg start_flag_dly1;
	assign start_flag = transfer_control_o[13];
	always@(posedge clk_i)begin
	 //start_flag <= slv_reg1[13];
	 start_flag_dly1 <= start_flag;	
	end
	
	assign trans_start_o = !start_flag_dly1 & start_flag;

    always@(posedge clk_i or negedge aresetn)begin
     if(!aresetn)
       transfer_control_o <= 32'd0;
     else if(trans_start_o)
       transfer_control_o <= transfer_control_o & 14'b01_1111_1111_1111; // clear the start pulse
     else if(wr_valid & rw_addr == 2'h1)
       transfer_control_o <= slv_reg1;
     else if(rd_valid & rw_addr == 2'h1)
         transfer_control_o <= transfer_control_o;
    end

    
    always@(posedge clk_i or negedge aresetn)begin
     if(!aresetn)
       spi_busy <= 1'd0;
     else if(trans_start_o)
       spi_busy <= 1'd1;
     else if(trans_done_i)
       spi_busy <= 1'd0;
    
    end
    //status register
    /*=============================================================================================
	--  Status Register	|	Read Only
	--=============================================================================================*/
	//   spi_busy		|	0:0		||		Signals ongoing SPI transfer (0 idle, 1 busy)	|| reset value : 0
	//	  rx_fifo_empty|	1:1		||		SPI RD buffer empty at RD access						|| reset value : 0
	//   tx_fifo_full	|  2:2		||		SPI WR buffer full at WR access						|| reset value : 0
	//   reserved		|	31:3		||		default 0													|| reset value : 0   

    always@(posedge clk_i or negedge aresetn)begin
      if(!aresetn)
        reg_status_o <= 32'd0;
      else if(rd_valid && rw_addr == 2'h2)
        reg_status_o <= {29'd0,tx_fifo_full_i,rx_fifo_empty_i,spi_busy};
      else
        reg_status_o <= reg_status_o;
    end
    
    //wr/rd fifo
    
    always@(posedge clk_i or negedge aresetn)begin
      if(!aresetn)begin
        tx_fifo_push_o <= 1'd0;
        tx_fifo_data <= 32'd0;
      end 
      else if(wr_valid & !tx_fifo_full_i && rw_addr == 2'h3)begin
       tx_fifo_push_o <= 1'd1;
       tx_fifo_data <= slv_reg3;
      end
      else if(tx_fifo_full_i)begin
       tx_fifo_push_o <= 1'd0;
       tx_fifo_data <= tx_fifo_data;
      end
       else begin
       tx_fifo_push_o <= 1'd0;
       tx_fifo_data <= tx_fifo_data;
       end
       
    
    end
    
   assign rx_fifo_pull_o = rd_valid && (rw_addr == 2'h3) && !rx_fifo_empty_i;
    
  //  always@(*)begin
  //    if(!aresetn)begin
  //      //rx_fifo_pull_o <= 1'd0;
  //      rx_fifo_data = 32'd0;
  //    end
  //    else if(rd_valid && !rx_fifo_empty_i && rw_addr == 2'h3)begin
   //     //rx_fifo_pull_o <= 1'd1;
  //      rx_fifo_data = rx_fifo_data_i;
  //    end
  //    else begin
        //rx_fifo_pull_o <= 1'd0;
  //      rx_fifo_data = 32'hFFFFFFFF;
  //    end
  //  end
    

    
    
    
    
    
    
    
    
endmodule
