`timescale 1ns / 1ps
//Note:
//	1. This is implemented for OV7670 CMOS camera under RGB444 configuration, and for VGA output 
//	2. Read the Omnivision OV_7670 manual, understand the timing diagram for the SCCB First.
//	3. Once configuation is happeing see the register values and tune them according to your need
//	4. Can take help from the linux driver for the OV7670 which have the register values
//	5. Also study how VGA works and the timings for the HSYNC and VSYNC

//The "top_module" contains all the modules.

// INPUTS: 
//1. "clk100": We are having input clock ("clk100") of 100Mhz from the Development Board Nexys4 DDR, this 100Mhz clock is first divided by 2 to get a 50Mhz clock
//Which is further divided by 1000 to get a 500Khz clock and divided by 2 to get a 25Mhz clock.
//the 25Mhz clock acts as the input to the camera module, also it drives the VGA module for 60fps setting.
//2. "btn": btn is for the reset button, once pressed it would reset the camera configuration by sending sda data synced with scl clock for configuring the camera's registers.
//3. "OV7670_D": this is the 8 bit data line, though which the image data is received by the FPGA.
//4. "OV7670_HREF"; "OV7670_VSYNC"; "OV7670_PCLK": these are for the bringing the frame and will control whether the image is for VGA or QVGA or QQVGA

//OUTPUTS:
//1. OV7670_PWDN: should be LOW.
//2. OV7670_RESET: should be HIGH.
//3. OV7670_SIOC: This is the clock (<100kHz), will operate at 50Khz when the configuration data will be sent; else the line will be HIGHZ.
//4. OV7670_SIOD: This is for sending the configuration data 
//5. OV7670_XCLK: This is the input clock of the camera module
//6. [3:0] vga_red, [3:0] vga_green, [3:0] vga_blue: The 3 bit are sent to DAC using the Board, to single lines of VGA.
//7. vga_hsync, vga_vsync: For syncing the vertical and horizontal area of the VGA screen
module top_module(input clk100, 
				  output OV7670_SIOC, 
				  inout OV7670_SIOD, 
				  output OV7670_RESET, 
				  output OV7670_PWDN, 
				  input OV7670_VSYNC, 
				  input OV7670_HREF, 
				  input OV7670_PCLK, 
				  output OV7670_XCLK, 
				  input [7:0] OV7670_D, 
				  output [3:0] vga_red, 
				  output [3:0] vga_green, 
				  output [3:0] vga_blue, 
				  output vga_hsync, 
				  output vga_vsync, 
				  input btn);
                      
    wire [18:0] frame_addr;	  //Frame address is the location of the pixel, coming from the VGA module to buffer
    wire [11:0] frame_pixel;  //Frame pixel have the data of one pixel going from buffer to VGA
    wire [18:0] capture_addr; //capture address is the location of captured pixel going ot the buffer
    wire [11:0] capture_data; //capture data is the pixel data which is captured in 2 cycles going to the buffer
    wire capture_we;		  //capture write enable is the the enable flag
    wire resend;			  //resend is for triggering the register reset, after debouncing the input
    wire clk50;				  //50Mhz clock
    wire clk25;				  //25Mhz clock
                          
    //debounce the input button so that unnecessary nosisy input does not lead to reconfiguration of camera registers  
    debounce db1(.clk(clk50),.i(btn),.o(resend));
    
    //these the are various clock signals used
    clocking_verilog clk1(.clk_in(clk100),.clk_out(clk50));
    clocking_verilog clk2(.clk_in(clk50),.clk_out(clk25));
    
    //sccb stands for serial camera control bus, it is for camera configuation this module houses other two modules namely: Registers and main controller
    sccb sccb_controller(.clock_50(clk50) ,.reset(resend),.sio_d(OV7670_SIOD),.sioc_sachha(OV7670_SIOC));
    
    // The following three modules are responsible for taking the image data from the camera with the pclock, and then storing the pixel data in the buffer which is forwarded to the vga, which sends the pixel with the hsync and vsync to the output screen.
    frame_buffer memory(.wea(capture_we),.addra(capture_addr),.dina(capture_data),.clk(clk50),.addrb(frame_addr),.doutb(frame_pixel));
    ov7670_capture_verilog cap1(.pclk(OV7670_PCLK),.vsync(OV7670_VSYNC),.href(OV7670_HREF),.d(OV7670_D),.addr(capture_addr),.dout(capture_data),.we(capture_we));
    vga vg1(.clk25(clk25),.vga_red(vga_red),.vga_green(vga_green),.vga_blue(vga_blue),.vga_hsync(vga_hsync),.vga_vsync(vga_vsync),.frame_addr(frame_addr),.frame_pixel(frame_pixel));
    
    //assigning the reset=1, powerdown=0 and xclock as 25Mhz
    assign OV7670_PWDN = 0;
    assign OV7670_RESET = 1;
    assign OV7670_XCLK = clk25;
endmodule