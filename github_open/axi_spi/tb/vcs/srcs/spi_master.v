
/*---------------------------------------------------------------------------------------------------------------------
-- Author:          Peter Hasza, hasza.peti@gmail.com
-- 
-- Create Date:     04/02/2017 
-- Module Name:     spi_master
-- Project Name:    AXI_SPI_IF
-- Description: 
--							A simple SPI master interface.
--								Device control informations are coming from the Control Register.
--								These are the following:
--										- CLK ratio between the system clock and the SCLK
--										- Clock polarity
--										- Clock phase
--										- Data order
--
--								Information regarding the current SPI transfer is coming from the Transfer Control Register.
--								These are the following:
--										-- SS (Slave Select)
--										-- Direction
--										--	Number of bytes
--										-- Transfer start
--
--								An SPI transfer is only started when there is a HIGH pulse on the trans_start_i.
--								The controller will assert the trans_done_o, once the current transfer is done.
--								The data to be transmitted is acquired in the TX FIFO.
--								The received data is loaded into the RX FIFO.
--
--								A WRITE transfer is done once, the TX FIFO is empty.
--								The controller stalls the bus if the RX FIFO is full.
--
------------------------------ REVISION HISTORY -----------------------------------------------------------------------
--
-- 2017.apr.2	|	hp3265	||	Initial version
-- 2017.apr.20	|	hp3265	||	Clock generation, CPOl and CPHA assignment
-- 2017.apr.23	|	hp3265	||	FSM enable signals
-----------------------------------------------------------------------------------------------------------------------
-- TODO
-- * Finish the FSM for the transfers
-- * Generate trans_done_o
-- * Control FIFO outputs
-- * Testing, commenting, clean up
-----------------------------------------------------------------------------------------------------------------------*/

module spi_master (

		// Reset and Clocking
		input clk_i,
		input reset_n_i,
		
		/* Register interface */
		input	[31:0]								reg_control_i,
		input	[31:0]								reg_trans_ctrl_i,
		
		// FIFO2SPI interface
		output										trans_done_o,
		input										trans_start_i,
		
		// TX FIFO
		input										tx_empty_i,
		input	[31:0]								tx_data_i,
		output										tx_pull_o,
		
		// RX FIFO
		input										rx_full_i,
		output [31:0]								rx_data_o,
		output										rx_push_o,		

		// Serial interface
      output 								        spi_ssel_o,
      output 										spi_sck_o,
      output 										spi_mosi_o,
      input 										spi_miso_i

	);
	
	/*=============================================================================================
    --  CLOCK GENERATION
    --=============================================================================================*/

	wire [3:0] clk_div_y;
	wire cpol_y,cpha_y;
	
	wire sclk_y;
	assign clk_div_y = reg_control_i[3:0];
	assign cpol_y = reg_control_i[9];
	assign cpha_y = reg_control_i[10];
	reg clock_en_y;
	
	
	wire msb_first;
	assign msb_first = reg_control_i[8];
	
	CLK_gen sclk_gen(clk_i, clock_en_y, reset_n_i, clk_div_y, sclk_y);
	
	reg prev_sclk_y;
	always @ (posedge clk_i)
			prev_sclk_y <= sclk_y;
			
	reg sclk_rise_y;
	always @(posedge clk_i) 
	begin
		if (!prev_sclk_y & sclk_y) // rising edge of SCLK
			sclk_rise_y <= 1;
		else
			sclk_rise_y <= 0;
	end
	
	reg sclk_fall_y;
	always @(posedge clk_i) 
	begin
		if (prev_sclk_y & !sclk_y) // falling edge of SCLK
			sclk_fall_y <= 1;
		else
			sclk_fall_y <= 0;
	end
    /*=============================================================================================
    -- Sampling clock enable generation: depending on CPHA
//	 --=============================================================================================*/
	wire samp_ce_y;
	wire shift_ce_y;
	reg samp_ce_y_r;
      reg shift_ce_y_r;
	assign samp_ce_y = (!cpha_y) ? sclk_rise_y : sclk_fall_y;
	assign shift_ce_y = (!cpha_y) ? sclk_fall_y : sclk_rise_y;// cpha == 0
	
        always@(posedge clk_i ,negedge reset_n_i) begin
           if(!reset_n_i)
               samp_ce_y_r <= 1'b0;
           else 
               samp_ce_y_r <= samp_ce_y;
        end
        always@(posedge clk_i ,negedge reset_n_i) begin
           if(!reset_n_i)
               shift_ce_y_r <= 1'b0;
           else 
               shift_ce_y_r <= shift_ce_y;
        end

	reg sclk_delay_y;
	reg slave_select_en_delay_y;
      reg slave_select_en_y;
	always @ (posedge clk_i,negedge reset_n_i)
	begin
		if(!reset_n_i)
		begin
			sclk_delay_y <= 0;
			slave_select_en_delay_y <= 0;
		end
		else
		begin
			sclk_delay_y <= sclk_y;
			slave_select_en_delay_y <= slave_select_en_y;
		end	
	end
		
	reg spi_sclk_y;
	reg ss_y;
	always @ (posedge clk_i,negedge reset_n_i)
	begin		
		if(!reset_n_i)
		begin
			spi_sclk_y <= 0;
			ss_y = 0;
		end
		else
		begin
			spi_sclk_y <= sclk_delay_y;
			ss_y = slave_select_en_delay_y;// two cycles delay
		end
	end
	
	
	localparam [1:0] 
		IDLE  = 2'b00,
		LOAD = 2'b01,
		TRANSFER = 2'b10,
		TRANSFER_DONE = 2'b11;
		
	reg [5:0] bits;
	always@(*)
	begin
		case(reg_trans_ctrl_i[6:5]) 
			2'b00 : bits <= 8;
			2'b01 : bits <= 16;	
			2'b10 : bits <= 32;
			default : bits <= 8;
		endcase
	end	
		
	reg [1:0] state;
	reg tx_pull_y,rx_push_y;	
	reg transfer_en_y;
	reg trans_done_y;
	reg [5:0] bit_counter_y;
	reg [5:0] num_of_transferred_bits_y;
	//reg slave_select_en_y;
	/*seq*/
	always @(posedge clk_i,negedge reset_n_i) 
	begin
		if (!reset_n_i) 
		begin
			state <= IDLE;
			tx_pull_y <= 0;
			trans_done_y <= 0;
			transfer_en_y <= 0;
			rx_push_y <= 0;
			clock_en_y <= 0;
			slave_select_en_y <= 0;
			num_of_transferred_bits_y <= 0;
		end
		else
			case(state)
				IDLE :
				begin
					tx_pull_y <= 0;
					trans_done_y <= 0;		
					transfer_en_y <= 0;
					rx_push_y <= 0;
					clock_en_y <= 0;
					slave_select_en_y <= 0;
					if(trans_start_i)
					begin
						state <= LOAD;
					end
				end
				LOAD :
				begin
					tx_pull_y <= 1;//from tx fifo get the data
					rx_push_y <= 0;
					trans_done_y <= 0;
					transfer_en_y <= 1;
					clock_en_y <= 1;
					slave_select_en_y <= 1; //cs enable 
					num_of_transferred_bits_y <= bits;// number of transfer
					state <= TRANSFER;// go into the state of transfer
				end
				TRANSFER : 
				begin				
					transfer_en_y <= 0;
					tx_pull_y <= 0;//get the one data-width data  // the width is defined by the register from users
					if(bit_counter_y == num_of_transferred_bits_y)
							state <= TRANSFER_DONE;
				end
				TRANSFER_DONE : 
				begin
					//clock_en_y <= 0;
					rx_push_y <= 1;//push the rx data into rx fifo 
					if(!tx_empty_i)//if tx fifo is not empty ,then keep sending data again
					begin
						state <= LOAD;
                                     clock_en_y <= 1;
					end
					else
					begin
						trans_done_y <= 1;
                                      clock_en_y <= 0;
						state <= IDLE;
					end
				end
			endcase
	end
	
	always @(posedge clk_i,negedge reset_n_i) 
	begin
		if (!reset_n_i) // rising edge of SCLK
			bit_counter_y <= 0;
		else if(transfer_en_y || rx_push_y)
			bit_counter_y <= 0;
		else if(state == TRANSFER && !cpha_y && shift_ce_y_r)//the fall of sclk count 
			bit_counter_y <= bit_counter_y+1 ;			
		else if(state == TRANSFER && cpha_y && samp_ce_y_r)
			bit_counter_y <= bit_counter_y+1;		
		else 
			bit_counter_y <= bit_counter_y;
	end


	reg [7:0] fifo0,fifo1,fifo2,fifo3;
	//reg [7:0] tx_fifo0,tx_fifo1,tx_fifo2,tx_fifo3;
	//reg [7:0] rx_fifo0,rx_fifo1,rx_fifo2,rx_fifo3;
	
	always@(posedge clk_i,negedge reset_n_i)
	begin
		if(!reset_n_i)
		begin
			fifo0 <= 0;
			fifo1 <= 0;
			fifo2 <= 0;
			fifo3 <= 0;	
		end
		else if(tx_pull_y)
		begin
			fifo0 <= tx_data_i[7:0];
			fifo1 <= tx_data_i[15:8];
			fifo2 <= tx_data_i[23:16];
			fifo3 <= tx_data_i[31:24];	
		end
		else if(ss_y)
			begin
				if(shift_ce_y)
				begin
					if(!msb_first)
					begin
						fifo0 <= {fifo1[0],fifo0[7:1]};//移位寄存�?
						fifo1 <= {fifo2[0],fifo1[7:1]};
						fifo2 <= {fifo3[0],fifo2[7:1]};
						fifo3 <= {spi_miso_i,fifo3[7:1]};
					end
					else
					begin
						fifo0 <= {fifo0[6:0],spi_miso_i};//sample will change fifo[7]
						fifo1 <= {fifo1[6:0],fifo0[7]};
						fifo2 <= {fifo2[6:0],fifo1[7]};
						fifo3 <= {fifo3[6:0],fifo2[7]};
					end
				end
			end
       
	end
	
      

//    /*=============================================================================================
//    -- mosi generation
//    =============================================================================================*/		

	
	  reg data_valid_y;
      reg data_valid_y_dly1;
	always@(posedge clk_i,negedge reset_n_i)
	begin
		if(!reset_n_i) begin
			data_valid_y<=0;
                  data_valid_y_dly1 <= 0;
                end
		else begin
			data_valid_y<= tx_pull_y;// when tx_pull work,the next cycle data valid
    	             data_valid_y_dly1 <= data_valid_y;
                end
	end
	
	/*if cpha = 0 put first bit to mosi line when turns chipselect active*/
	
	wire en;
	assign en = (data_valid_y_dly1 && !cpha_y) ? 1'b1 : 1'b0;
//	reg en;
//	always@(posedge clk_i,negedge reset_n_i)
//	begin
//		if(!reset_n_i)
//			en <= 0;
//		else if(data_valid_y && !cpha_y)
//			en<= 1;	
//		else 
//			en <= 0;
//	end
	
	reg mosi_y;
	reg [31:0] rx_data_y;
	always@(posedge clk_i,negedge reset_n_i)
	begin
		if(!reset_n_i) //ss_y active default high?
			mosi_y <= 1'b0;
            else if((en) || shift_ce_y_r) begin
			if(!msb_first)
					mosi_y <= fifo0[0];
				else
				begin
					case(num_of_transferred_bits_y)
						 6'd8		:	mosi_y <= fifo0[7];
						 6'd16	:	mosi_y <= fifo1[7];
						 6'd32	:	mosi_y <= fifo3[7];
					endcase
				end
            end
	end
	
	initial rx_data_y = 0;
	always@(*)
	begin
		if(!msb_first)
		begin
			case(num_of_transferred_bits_y)
				 6'd8		: 	rx_data_y <= {24'd0,fifo3};
				 6'd16	:	rx_data_y <= {16'd0,fifo3,fifo2};
				 6'd32	:  rx_data_y <= {fifo3,fifo2,fifo1,fifo0};
			endcase
		end
		else
		begin
			case(num_of_transferred_bits_y)
				 6'd8		: 	rx_data_y <= {24'd0,fifo0};
				 6'd16	:	rx_data_y <= {16'd0,fifo1,fifo0};
				 6'd32	:  rx_data_y <= {fifo3,fifo2,fifo1,fifo0};
			endcase
		end
	end

	reg [31:0] rx_data;
	always@(posedge clk_i,negedge reset_n_i)
	begin
		if(!reset_n_i)
			rx_data <= 0;
		else 
			rx_data <= rx_data_y;
	end

//    /*=============================================================================================
//    -- SCK out logic: pipeline phase compensation for the SCK line
//    =============================================================================================*/	

	wire [3:0] ss_n = reg_trans_ctrl_i[3:0];// the number of slave

	assign tx_pull_o = tx_pull_y;
	assign trans_done_o = trans_done_y;
	assign rx_data_o = rx_data;
	assign rx_push_o = rx_push_y;		
	assign spi_ssel_o = (ss_y) ? ~(ss_y) : 1'b1; //bitwise,active default low
	assign spi_sck_o = (cpol_y) ? ~spi_sclk_y : spi_sclk_y;
	assign spi_mosi_o = (ss_y) ? mosi_y : 1'bz;


endmodule
