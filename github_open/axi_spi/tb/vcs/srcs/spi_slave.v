/******************************************
* the author : hust-coded
* the date   : 2023.04.05
* description : spi slave used to control the ads1284
* every transition will include 2 bytes commands and n bytes data
* we will check format of the commands and react different  according the value of command
********************************************/
`timescale 1ns / 1ps

module spi_slave(

   input clk,
   input rst_n,
   input sclk,
   input spi_cs,
   input MOSI,
   input datardy_fall,
   output wire MISO
   

);

localparam reg_num = 3;
localparam ADC_NOP = 7'h00;
localparam ADC_WAKEUP = 7'b0;  /* Wake-up from Standby mode, 00h or 01h, TYPE: Control */
localparam ADC_STANDBY = 7'h02; /* Enter Standby mode, 02h or 03h, TYPE: control */
localparam ADC_SYNC = 7'h04;    /* Synchronize the A/D conversion, 04h or 05h, TYPE: Control */
localparam ADC_RESET = 7'h06;   /* Reset registers to default values, 06h or 07h, TYPE: Control */
localparam ADC_RDATAC = 7'h10;  /* Read data continuous, 10h, TYPE: Control */
localparam ADC_SDATAC = 7'h11; /* Stop read data continuous, 11h, TYPE: Control */
localparam ADC_RDATA =  7'h12;   /* Read data by command, 12h, TYPE: Data */

localparam ADC_RREG = 7'h20; /* Read nnnnn register(s) at address rrrr, \
                      001r rrrr(20h + 000r rrrr),                \
                      000n nnnn(00h + n nnnn), TYPE: Register */

localparam ADC_WREG = 7'h40; /* Write nnnnn register(s) at address rrrr, \
                      010r rrrr(40h + 000r rrrr),                 \
                      000n nnnn(00h + n nnnn), TYPE: Register */
// rx and tx pulse
reg [7:0] rx_cnt; //used to count the rise of sclk
wire rx_pulse;
reg  rx_pulse_r;
wire spi_cs_fall;
reg [7:0] tx_cnt;
wire tx_pulse;
reg  tx_pulse_r;
reg spi_miso_r;
//reg map
reg [7:0] slave_reg1;
reg [7:0] slave_reg2;
reg [7:0] slave_reg3;

//sclk reg
reg sclk_r;
reg spi_cs_r;
//command
reg [7:0] cmd1;
reg [7:0] cmd2;
reg [7:0] cmd3;
//commands decode
wire adc_nop;
assign adc_nop = (cmd1 == ADC_NOP);
wire adc_wakeup;
assign adc_wakeup = (cmd1[7:1] ==ADC_WAKEUP);
wire adc_rdata;
assign adc_rdata = (cmd1 == ADC_RDATA);
wire adc_rdatac;
assign adc_rdatac = (cmd1 == ADC_RDATAC);
wire adc_rreg;
assign adc_rreg = ( cmd1[5] == 1'b1);
wire adc_sdatac;
assign adc_sdatac = (cmd1 == ADC_SDATAC);
wire adc_wreg;
assign adc_wreg = (cmd1[6] == 1'b1);

wire [4:0] reg_address;
assign reg_address = (cmd2[4:0]);
//wire [4:0] reg_length;
//assign reg_length = (adc_rreg || adc_wreg)? (cmd2[4:0]):(5'd0);
//reg [7:0] adc_w_data;
reg [7:0] adc_r_data;

//adc_data
reg [31:0] adc_data;
wire [31:0] mem_data;
wire rd_en;
reg [17 : 0]  rd_addr;
//reg [5:0] data_cnt;

always@(posedge clk)begin
 sclk_r <= sclk;
end

always@(posedge clk)begin
 spi_cs_r <= spi_cs;
end

assign rx_pulse = (spi_cs == 1'b0)? (sclk & ~sclk_r):(1'b0);
assign spi_cs_fall = spi_cs_r & ~spi_cs;//cap the fall of cs
assign tx_pulse = (spi_cs == 1'b0)? (!sclk & sclk_r):(1'b0);

always@(posedge clk or negedge rst_n)begin
     if(!rst_n)
       rx_pulse_r <= 1'b0;
    else if(rx_pulse)
         rx_pulse_r <= 1'b1;
     else 
          rx_pulse_r <= 1'b0;
end

always@(posedge clk or negedge rst_n)begin
     if(!rst_n)
       tx_pulse_r <= 1'b0;
    else if(tx_pulse)
         tx_pulse_r <= 1'b1;
     else 
          tx_pulse_r <= 1'b0;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    rx_cnt <= 8'b0;
    else if(spi_cs == 1'b1)
    rx_cnt <= 8'b0;
    else if(rx_pulse && rx_cnt == 8'd8 && slave_reg2 != 8'hFF)
    rx_cnt <= rx_cnt;
    else if(rx_pulse && rx_cnt <= 8'd32)
    rx_cnt <= rx_cnt + 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    tx_cnt <= 8'b0;
    else if(spi_cs == 1'b1)
    tx_cnt <= 8'b0;
    else if(tx_pulse && tx_cnt == 8'd8 && slave_reg2 != 8'hFF)
    tx_cnt <= tx_cnt;
    else if(tx_pulse && tx_cnt <= 8'd32)
    tx_cnt <= tx_cnt + 1'b1;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    cmd1 <= 8'd0;
    else if(!spi_cs && rx_cnt < 8'd8 && rx_pulse)
    cmd1 <= {cmd1[6:0],MOSI};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    cmd2 <= 8'd0;
    else if(spi_cs_fall)
    cmd2 <= cmd1;
end

always@(posedge clk or negedge rst_n)begin
   if(!rst_n)
     cmd3 <= 8'd0;
   else if(spi_cs_fall && (cmd2[5] == 1 || cmd2[6] == 1))
     cmd3 <= cmd2;
end

// the function of adc_sdatac
//assign MISO = (adc_data[7]); //MSB first

//assign rd_en = (adc_rdatac & rx_cnt >= 8'd29);

//always @(posedge sclk or negedge rst_n) begin
//    if(!rst_n)
//    data_cnt <= 6'd0;
//    else if(data_cnt == 6'd31)
//    data_cnt <= 6'd0;
//    else if(rd_en)
//    data_cnt <= data_cnt + 6'd1;
//end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
    rd_addr <= 18'd0;
     else if(rd_addr == 18'd160003 && tx_pulse && tx_cnt == 8'd31)//max addr is 160003
     rd_addr <= 18'd0;
    else if(tx_cnt == 8'd31 && tx_pulse && slave_reg2 == 8'hFF)
    rd_addr <= rd_addr + 1'b1;
end

wire [6:0] cmd_state;

assign cmd_state = {adc_nop,adc_wakeup,adc_rdata,adc_rdatac,adc_rreg,adc_sdatac,adc_wreg};

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
     slave_reg1 <= 8'd0;
     slave_reg2 <= 8'd0;
     slave_reg3 <= 8'd0;
    end
    else if((cmd2 == 8'd0) && (cmd3[6] == 1'b1) && rx_pulse && rx_cnt < 8'd8)begin
    case(reg_address)
    5'd0:slave_reg1 <= {slave_reg1[6:0],MOSI};
    5'd1:slave_reg2 <= {slave_reg2[6:0],MOSI};
    5'd2:slave_reg3 <= {slave_reg3[6:0],MOSI};
    default: begin
        slave_reg1 <= slave_reg1;
        slave_reg2 <= slave_reg2;
        slave_reg3 <= slave_reg3;
    end
    endcase
    end
    else if(adc_rdatac && rx_cnt >= 8'd8) begin
       slave_reg1 <= slave_reg1;
       slave_reg2 <= 8'hFF;
       slave_reg3 <= slave_reg3;
     end
    else if(adc_sdatac &&  rx_cnt >= 8'd8) begin
       slave_reg1 <= slave_reg1;
       slave_reg2 <= 8'h11;
       slave_reg3 <= slave_reg3;
     end
    
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
       adc_r_data <= 32'd0;
    else if(cmd3 == ADC_RREG && rx_cnt == 8'd0 && slave_reg2 != 8'hFF)begin
    case(reg_address)
    5'd0: adc_r_data <= slave_reg1;
    5'd1: adc_r_data <= slave_reg2;
    5'd2: adc_r_data <= slave_reg3;
    default: adc_r_data <= 8'd0;     
    endcase
    end
    else if(tx_pulse && slave_reg2 != 8'hFF)
          adc_r_data <= adc_r_data << 1;
    
end

//always @(posedge sclk or negedge rst_n) begin
//    if(!rst_n)
//     tx_cnt <= 8'd30;
//    else if(tx_cnt == 8'd31)
//     tx_cnt <= 8'd0;
//    else if(rx_cnt >= 8'd30 && adc_rdatac)
//     tx_cnt <= tx_cnt + 1'b1;
//end

always@(posedge clk or negedge rst_n)begin
     if(!rst_n)
      adc_data <= 8'd0;
     else if(slave_reg2 == 8'hFF && spi_cs_fall)
      adc_data <= mem_data;
     else if(slave_reg2 == 8'h11 && spi_cs_fall)
      adc_data <= adc_data; //mosi keep
     else if(tx_pulse)
      adc_data <= (adc_data << 1);   
end

//always @(posedge clk or negedge rst_n) begin
//   if(!rst_n)
//    adc_data <= 8'd0;
//   else if(rx_cnt == 8'd63 || (adc_rdatac && tx_cnt == 8'd8)) begin
//    case(cmd_state)
//    7'b1000000: begin
//    adc_data <= 8'd0;
//    end
//    7'b0100000: begin
//    adc_data <= 8'd0;
//    end
//    7'b0010000: begin
//    adc_data <= mem_data;
//    end
//    7'b0001000: begin
//    adc_data <= mem_data;
//    end
//    7'b0000100: begin
//    adc_data <= adc_r_data;
//    end
//    7'b0000010: begin
//    adc_data <= adc_data;
//    end
//    7'b0000001: begin
//    adc_data <= 8'd1;
//    end
//    default: adc_data <= 8'd0;
//    endcase
//    end
//    else if(rx_pulse)
//    adc_data <= {adc_data[6:0],1'b0};//the rise of sclk
//end

//always@(posedge clk or negedge rst_n)begin
//       if(tx_pulse)
//       spi_miso_r <= adc_data[31];
//end
assign MISO = (spi_cs)? (1'bz):((cmd3 == ADC_RREG && slave_reg2 != 8'hFF)? (adc_r_data[7]):(adc_data[31])); //MSB first
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n)
//     reg_address <= 5'd0;
//     else if(rx_pulse && rx_cnt <  rx_cnt < 8'd8)
//     reg_address <= {reg_address[4:1],MOSI};
// end

blk_mem_gen_0 adc_data_m (
  .clka(clk),    // input wire clka
  //.ena(rd_en),      // input wire ena
  .addra(rd_addr),  // input wire [19 : 0] addra
  .douta(mem_data)  // output wire [7 : 0] douta
);

//mem adc_data_m
//(
//   .clk(sclk),
//   .addra(rd_addr),
//   .en(rd_en),
//   .dout(mem_data),

//);





endmodule
