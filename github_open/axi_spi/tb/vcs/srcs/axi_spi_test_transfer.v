`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   07:22:37 05/11/2017
// Design Name:   axi_spi_if
// Module Name:   E:/University/AXI_SPI_IF/ise/axi_spi_test_transfer.v
// Project Name:  axi_spi_if
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: axi_spi_if
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module axi_spi_test_transfer;

	// Inputs
	reg clk_i;
	reg reset_n_i;
	reg initial_flag;
	wire awvalid_i;
	wire [31:0] awaddr_i;
	wire [2:0]  awprot_i;
	wire wvalid_i;
	wire [31:0] wdata_i;
	wire [3:0] wstrb_i;
	wire bready_i;
	wire arvalid_i;
	wire [31:0] araddr_i;
	wire [2:0] arprot_i;
	wire rready_i;
	reg [31:0] transfer_cmd;
	reg [3:0] transfer_addr;
	reg rw_flag; //0:write,1:read
	reg [31:0] wdata_task;
       reg [2:0] number_transfer;
	wire spi_miso_i;
	
	//reg [2:0] read_status_reg;
      reg flag;
	// Outputs
	wire awready_o;
	wire wready_o;
	wire bvalid_o;
	wire [1:0] bresp_o;
	wire arready_o;
	wire rvalid_o;
	wire [31:0] rdata_o;
	wire [1:0] rresp_o;
	wire spi_ssel_o;
	wire spi_sck_o;
	wire spi_mosi_o;
	wire error;
	wire transfer_done;
	integer i;
      integer last_number;
       
	// Instantiate the Unit Under Test (UUT)
	axi_spi_if uut (
		.clk_i(clk_i), 
		.reset_n_i(reset_n_i), 
		.awvalid_i(awvalid_i), 
		.awready_o(awready_o), 
		.awaddr_i(awaddr_i), 
		.awprot_i(awprot_i), 
		.wvalid_i(wvalid_i), 
		.wready_o(wready_o), 
		.wdata_i(wdata_i), 
		.wstrb_i(wstrb_i), 
		.bvalid_o(bvalid_o), 
		.bready_i(bready_i), 
		.bresp_o(bresp_o), 
		.arvalid_i(arvalid_i), 
		.arready_o(arready_o), 
		.araddr_i(araddr_i), 
		.arprot_i(arprot_i), 
		.rvalid_o(rvalid_o), 
		.rready_i(rready_i), 
		.rdata_o(rdata_o), 
		.rresp_o(rresp_o), 
		.spi_ssel_o(spi_ssel_o), 
		.spi_sck_o(spi_sck_o), 
		.spi_mosi_o(spi_mosi_o), 
		.spi_miso_i(spi_miso_i)
	);
	
	axi_master #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// The master will start generating data from the C_M_START_DATA_VALUE value
		.C_M_START_DATA_VALUE(32'h00000000),
		// The master requires a target slave base address.
    // The master will initiate read and write transactions on the slave with base address specified here as a parameter.
		.C_M_TARGET_SLAVE_BASE_ADDR(32'h43C00000),
		// Width of M_AXI address bus. 
    // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		.C_M_AXI_ADDR_WIDTH(32),
		// Width of M_AXI data bus. 
    // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		.C_M_AXI_DATA_WIDTH(32),
		// Transaction number is the number of write 
    // and read transactions the master will perform as a part of this example memory test.
		.C_M_TRANSACTIONS_NUM(1)
	) axi_master
	(
		// Users to add ports here
       .TRANSFER_CMD(transfer_cmd),
       .TRANSFER_ADDR(transfer_addr),
       .RW_FLAG(rw_flag),
		// User ports ends
		// Do not modify the ports beyond this line

		// Initiate AXI transactions
		.INIT_AXI_TXN(initial_flag),
		// Asserts when ERROR is detected
		.ERROR(error),
		// Asserts when AXI transactions is complete
		.TXN_DONE(transfer_done),
		// AXI clock signal
		.M_AXI_ACLK(clk_i),
		// AXI active low reset signal
		.M_AXI_ARESETN(reset_n_i),
		// Master Interface Write Address Channel ports. Write address (issued by master)
		.M_AXI_AWADDR(awaddr_i),
		// Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
		.M_AXI_AWPROT(awprot_i),
		// Write address valid. 
    // This signal indicates that the master signaling valid write address and control information.
		.M_AXI_AWVALID(awvalid_i),
		// Write address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		.M_AXI_AWREADY(awready_o),
		// Master Interface Write Data Channel ports. Write data (issued by master)
		.M_AXI_WDATA(wdata_i),
		// Write strobes. 
    // This signal indicates which byte lanes hold valid data.
    // There is one write strobe bit for each eight bits of the write data bus.
		 .M_AXI_WSTRB(wstrb_i),
		// Write valid. This signal indicates that valid write data and strobes are available.
		.M_AXI_WVALID(wvalid_i),
		// Write ready. This signal indicates that the slave can accept the write data.
		.M_AXI_WREADY(wready_o),
		// Master Interface Write Response Channel ports. 
    // This signal indicates the status of the write transaction.
		.M_AXI_BRESP(bresp_o),
		// Write response valid. 
    // This signal indicates that the channel is signaling a valid write response
		.M_AXI_BVALID(bvalid_o),
		// Response ready. This signal indicates that the master can accept a write response.
		.M_AXI_BREADY(bready_i),
		// Master Interface Read Address Channel ports. Read address (issued by master)
		.M_AXI_ARADDR(araddr_i),
		// Protection type. 
    // This signal indicates the privilege and security level of the transaction, 
    // and whether the transaction is a data access or an instruction access.
	    .M_AXI_ARPROT(arprot_i),
		// Read address valid. 
    // This signal indicates that the channel is signaling valid read address and control information.
		.M_AXI_ARVALID(arvalid_i),
		// Read address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		.M_AXI_ARREADY(arready_o),
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		.M_AXI_RDATA(rdata_o),
		// Read response. This signal indicates the status of the read transfer.
		.M_AXI_RRESP(rresp_o),
		// Read valid. This signal indicates that the channel is signaling the required read data.
		.M_AXI_RVALID(rvalid_o),
		// Read ready. This signal indicates that the master can accept the read data and response information.
		.M_AXI_RREADY(rready_i)
	);

	
	
	
	
	adc_control uut_adc
(
   .clk(clk_i),
   .rst_n(reset_n_i),
   .sclk(spi_sck_o),
   .spi_cs(spi_ssel_o),
   .MOSI(spi_mosi_o),
   .MISO(spi_miso_i)
    
);

integer fid;
initial
begin
	//fid = $fopen("./adc_data.txt", "r");
    fid = $fopen("./adc_data.txt", "w"); //write
    if (!fid)
        $display("file open error");
end

task transfer(
  input [3:0] addr_offset,
  input [31:0] reg_value,
  input rw_flag_i
);
begin
    transfer_cmd = reg_value;
    transfer_addr = addr_offset;
    rw_flag  = rw_flag_i;
    initial_flag = 1;   
    wait(transfer_done);
    initial_flag = 0;
    
end
endtask



task write_cmd
(
   input [31:0] cmd,
   input [31:0] number_bytes
);
begin

// ===========================================
 // WRITE TX FIFO
 // ===========================================
		 
		 for (i=0; i < 1; i = i + 1) begin
	//		wdata_i = 32'h1000_0000 + i;
            transfer(12,cmd,0);	//write address:0x43C0000C,write data:cmd
			#100;
		end

		 // ===========================================
		 // WRITE TRANSFER CONTROL REGISTER
		 // ===========================================
             number_transfer = number_bytes;

		 if(number_transfer == 1)wdata_task = 32'h0000_2002; // 0010 0000 0000 0010,13bit == 1,transfer start
             else if(number_transfer == 2)wdata_task = 32'h0000_2022;
             else if(number_transfer == 4)wdata_task = 32'h0000_2042;
		 
		 transfer(4,wdata_task,0);// write transfer : address: 0x43C00004,write data: wdata_task
		 //spi_miso_i = 1;
		 	 
		 // ===========================================
		 // READ STATUS REGISTER
		 // ===========================================
		#100;
            transfer(8,32'h0,1);
		 
		 #100;
		 
		 while (rdata_o) begin // when rdata valid
		 transfer(8,32'h0,1);
		 
	     #100;
		 end
		
		 // ===========================================
		 // READ RX FIFO
		 // ===========================================
		 for (i=0; i < 1; i = i + 1) begin
			transfer(12,32'h0,1);
			#100;			
		end
		
            if(number_bytes == 4 && last_number != 4) $fwrite(fid, "%s\n", "the adc data rec begin!");
            $fwrite(fid, "%x,\n", rdata_o);
            last_number = number_bytes;
end
endtask




	initial begin
		// Initialize Inputs
		clk_i = 0;
		reset_n_i = 0;	
        flag = 0;
        transfer_cmd = 0;        
        transfer_addr = 0;
        initial_flag = 0;
        wdata_task = 0;
        rw_flag = 0;
		//spi_miso_i = 0;		
		// Wait 100 ns for global reset to finish
		#100;
        reset_n_i = 1;	
        transfer(0,32'h0000_0102,0);
		/*		
		reg_control_i = 32'h0000_0602;
		reg_trans_ctrl_i = 32'h0000_0002;
		*/
		 // ===========================================
		 // WRITE CONTROL REGISTER
		 // ===========================================		 
		 #100;		 
        write_cmd(32'h00000011,1);
           #10000; //24*sclk_cycle
        write_cmd(32'h00000040,1);
           #10000; //24*sclk_cycle
        write_cmd(32'h00000000,1);
           #10000; //24*sclk_cycle
        write_cmd(32'h00000022,1);
           #10000; //24*sclk_cycle
        write_cmd(32'h00000020,1);
           #10000; //24*sclk_cycle
        write_cmd(32'h00000000,1);
           #10000; //24*sclk_cycle
        write_cmd(32'h00000000,1);
           #10000; //24*sclk_cycle
        write_cmd(32'h00000010,1);
        flag = 1;
           //#10000; //24*sclk_cycle
        //write_cmd(32'h00000010,1);
           #10000; //24*sclk_cycle
           repeat(1)begin
        write_cmd(32'h00000000,4);
             end
           #400000;//end

            $finish;


	end
	
		//always #77 spi_miso_i = ~spi_miso_i;	
	
		always #5 clk_i = ~clk_i;
      


//always @(posedge sclk)begin
//    $fwrite(fid, "%x,\n", adc_data);
//     else if(flag_rise)
//    $fwrite(fid, "%x,\n", 0);
//end


initial begin
        $fsdbDumpfile("sim_axi.fsdb");
        $fsdbDumpvars(0,axi_spi_test_transfer);
        $display("********************wave dump start**********************");
 end






endmodule
