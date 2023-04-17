/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"


#define AXI_SPI_0  0x40000000
//#define AXI_SPI_1  XPAR_AXI_SPI_IF_1_BASEADDR

/* ADC command definition */
#define ADC_NOP    0x00
#define ADC_WAKEUP 0x00  /* Wake-up from Standby mode, 00h or 01h, TYPE: Control */
#define ADC_STANDBY 0x02 /* Enter Standby mode, 02h or 03h, TYPE: control */
#define ADC_SYNC 0x04    /* Synchronize the A/D conversion, 04h or 05h, TYPE: Control */
#define ADC_RESET 0x06   /* Reset registers to default values, 06h or 07h, TYPE: Control */
#define ADC_RDATAC 0x10  /* Read data continuous, 10h, TYPE: Control */
#define ADC_SDATAC 0x11  /* Stop read data continuous, 11h, TYPE: Control */
#define ADC_RDATA 0x12   /* Read data by command, 12h, TYPE: Data */

#define ADC_RREG 0x20 /* Read nnnnn register(s) at address rrrr, \
                      001r rrrr(20h + 000r rrrr),                \
                      000n nnnn(00h + n nnnn), TYPE: Register */

#define ADC_WREG 0x40 /* Write nnnnn register(s) at address rrrr, \
                      010r rrrr(40h + 000r rrrr),                 \
                      000n nnnn(00h + n nnnn), TYPE: Register */

void write_cmd(int BaseAddress,u32 cmd,u32 *rx_buf,u32 ByteCount)
{
	u32 write_data;
	u32 read_data;
	 // ===========================================
	 // WRITE TX FIFO
	 // ===========================================
   //wdata_i = cmd; // 0 - 7
   //awaddr_i = 3;
  Xil_Out32(BaseAddress+12,(u32)(cmd));
  usleep(1);
     // ===========================================
	 // WRITE TRANSFER CONTROL REGISTER
	 // ===========================================
//	 if(number_bytes == 1)wdata_i = 32'h0000_2002; // 0010 0000 0000 0010,13bit == 1,transfer start
//       else if(number_bytes == 2)wdata_i = 32'h0000_2022;
//        else if(number_bytes == 4)wdata_i = 32'h0000_2042;
//	 awaddr_i = 1;
 if(ByteCount == 1) write_data  = 0x00002002;
 else if(ByteCount == 2) write_data = 0x00002022;
 else if(ByteCount == 4) write_data = 0x00002042;
 Xil_Out32(BaseAddress+4,write_data);

 // ===========================================
 // READ STATUS REGISTER
 // ===========================================
 //araddr_i = 2;
 read_data = Xil_In32(BaseAddress+8);
 usleep(1);
 while(read_data)
 {
	 read_data = Xil_In32(BaseAddress+8);
	 usleep(1);
 }
 usleep(1);
 // ===========================================
 // READ RX FIFO
 // ===========================================
 *rx_buf = (u32)Xil_In32(BaseAddress+12);
 usleep(1);



}


u32 rx_buf[12]={0,};
u32 tx_buf[12] = {0,};
u32 adc_data;
int i=0;
int32_t adc_ip_test(int BaseAddress)
{
   //int ret = 0;
   //unsigned char tx_buf;
   //unsigned char rx_buf;
	u32 adc_data;
   //unsigned char dout_byte[4] = {0,};
  // unsigned char reg_data;
   //int i = 0;
   tx_buf[0] = ADC_SDATAC;
   write_cmd(BaseAddress,0x00000011,&(rx_buf[0]),1);
   usleep(1);
   tx_buf[1] = ADC_WREG;
   write_cmd(BaseAddress,0x00000040,&(rx_buf[1]),1);
   usleep(1);
   tx_buf[2] = 0x00;
   write_cmd(BaseAddress,0x00000000,&(rx_buf[2]),1);
   usleep(1);
   tx_buf[3] = 0xFF;
   write_cmd(BaseAddress,0x00000022,&(rx_buf[3]),1);
   usleep(1);
   tx_buf[4] = ADC_RREG;
   write_cmd(BaseAddress,0x00000020,&(rx_buf[4]),1);
   usleep(1);
   tx_buf[5] = 0x00;
   write_cmd(BaseAddress,0x00000000,&(rx_buf[5]),1);
   usleep(1);
   tx_buf[6] = 0x00;
   write_cmd(BaseAddress,0x00000000,&(rx_buf[6]),1);
   printf("the reg data is %lx\n",rx_buf[6]);
   usleep(1);
   tx_buf[8] = ADC_NOP;
   tx_buf[9] = ADC_NOP;
   tx_buf[10] = ADC_NOP;
   tx_buf[11] = ADC_NOP;
   write_cmd(BaseAddress,0x00000010,&(rx_buf[7]),1);
   printf("the adc capure!\n");
   while(i <= 160003)
   {
     write_cmd(BaseAddress,0x00000000,&(adc_data),4);
     printf("the adc data is %lx\n",adc_data);
     //XUartPs_SendByte(XPAR_PS7_UART_0_BASEADDR,);
     i++;
   }
  // adc_data =


  return adc_data;

}

u32 adc_data;
int32_t test_data;
int main()
{
	u32 initial_data = 0x00000102;
    init_platform();

    print("Hello World\n\r");

    // wdata_i = 32'h0000_0102; // clock div == 2 and cpha == 0,cpol == 0,msb first
	// awaddr_i = 0;
    Xil_Out32(AXI_SPI_0,initial_data);
    usleep(1);
    //Xil_Out32(AXI_SPI_1,initial_data);
    //usleep(1);
    //test_data = adc_ip_test(AXI_SPI_1);
    usleep(1);
    adc_data = adc_ip_test(AXI_SPI_0);
    printf("the last adc data is %lx\n",adc_data);

    cleanup_platform();
    return 0;
}
