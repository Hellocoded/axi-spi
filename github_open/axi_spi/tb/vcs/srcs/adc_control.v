/********************************************************
* the author : hust-coded
* the date   : 2023.04.05
* description : use the decoded cmd to control the ads1284
*
*********************************************************/
`timescale 1ns / 1ps

module adc_control 
(
   input clk,
   input rst_n,
   input sclk,
   input spi_cs,
   input MOSI,
   output wire MISO
   

    
);

  wire datardy_fall;

  spi_slave spi_slave(

   .clk(clk),
   .rst_n(rst_n),
   .sclk(sclk),
   .spi_cs(spi_cs),
   .MOSI(MOSI),
   .datardy_fall(datardy_fall),
   .MISO(MISO)

);

  counter64 counter(

  .clk(clk),
  .rst_n(rst_n),
  
  .datardy_fall(datardy_fall)

);
   

endmodule
