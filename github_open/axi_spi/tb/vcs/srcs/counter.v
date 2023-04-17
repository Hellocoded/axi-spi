/*******************************
*
* the author : hust-coded
* the date   : 2023.04.05
* description : generate the signal of datardy  every 64 sclk
*
**/
`timescale 1ns / 1ps

module counter64(

  input clk,
  input rst_n,
  
  output wire datardy_fall

);

wire counter_flag;
reg [6:0] counter;
reg  datardy_r;
reg [6:0] datardy_r_dly1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
       counter <= 7'b0;
    else if(counter == 7'd64)
       counter <= 7'b0;
    else
       counter <= counter + 1'b1;
    
end

assign counter_flag = (counter == 7'd64)? (1'b1):(1'b0);

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
       datardy_r <= 1'b0;
    else if(datardy_r == 1'b1)
       datardy_r <= 1'b0;
    else if(counter_flag)
       datardy_r <= 1'b1;
end

always@(posedge clk)begin
    datardy_r_dly1 <= datardy_r; //dly
end



assign datardy_fall = (~datardy_r & datardy_r_dly1); // capture the fall of datardy

endmodule