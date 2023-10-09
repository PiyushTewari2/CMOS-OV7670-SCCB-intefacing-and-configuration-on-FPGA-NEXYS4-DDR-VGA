`timescale 1ns / 1ps
//vga module is for forwaring the captured images via 25Mhz clock to the VGA screen
//Check the Complete VGA timings first for clear understanding
module vga(input clk25,
	       output [3:0] vga_red,
	       output [3:0] vga_green,
           output [3:0] vga_blue,
           output vga_hsync,
           output vga_vsync,
           output [18:0] frame_addr,
           input [11:0] frame_pixel); 

	parameter hRez = 640;				//since it starts from the screen area not the porch					
	parameter hStartSync = 656;         //640+16,  16 is the right porch area   
	parameter hEndSync = 752;     		//640+16+96, 96 is the hsync value
	parameter hMaxCount = 800;			//640+16+96+48 this will complete one Horizontal cycle, left porch is 48

	parameter vRez = 480; 			    //since it starts from the screen area not the porch
	parameter vStartSync = 490;	 		//480+10, 10H cycles is the bottom porch area 
	parameter vEndSync = 492;			//480+10+2, 2Hcycles is the Vsync 
	parameter vMaxCount = 525;			//480+10+2+33, 33Hcycles is the top porch

	parameter hsync_active = 0;
	parameter vsync_active = 0;
	
	reg unsigned [9:0] hCounter = {10{1'b0}};
	reg unsigned [9:0] vCounter = {10{1'b0}};
	reg unsigned [18:0] address = {19{1'b0}};
	reg unsigned [18:0] address_temp = {19{1'b0}};
	reg blank = 1;
	
	reg [3:0] vga_red_temp;
	reg [3:0] vga_blue_temp;
	reg [3:0] vga_green_temp;
	reg vga_hsync_temp;
	reg vga_vsync_temp;
	
        
	always @(posedge clk25)
		begin
		if (hCounter == hMaxCount-1)
			begin
			hCounter <= {10{1'b0}};
			if(vCounter == vMaxCount-1)
				vCounter <= {10{1'b0}};
            else
                vCounter <= vCounter+1;
			end
		else
			hCounter <= hCounter+1;
			
		if(blank == 0)
			begin
			vga_red_temp   <= frame_pixel[11:8];
			vga_green_temp <= frame_pixel[7:4];
			vga_blue_temp <= frame_pixel[3:0];
			end
		else
			begin
			vga_red_temp   <= 0;
			vga_green_temp <= 0;
			vga_blue_temp <= 0;
			end

		if(vCounter >= vRez)
			begin
			address <= {19{1'b0}};
			blank <= 1;
			end
		else
			begin
			if(hCounter < 640)
				begin
				blank <= 0;
				address <= address+1'b1;
				end
			else
				blank <= 1;
			end
			
		if(hCounter > hStartSync && hCounter <= hEndSync)
			vga_hsync_temp <= hsync_active;
		else
			vga_hsync_temp <= !hsync_active;
				
		if(vCounter >= vStartSync && vCounter < vEndSync)
			vga_vsync_temp <= vsync_active;
		else
			vga_vsync_temp <= !vsync_active;	
		end
	
	//ASSIGNING VALUES
	assign frame_addr = address;
	assign vga_red = vga_red_temp;
	assign vga_blue = vga_blue_temp;
	assign vga_green = vga_green_temp;
	assign vga_hsync = vga_hsync_temp;
	assign vga_vsync = vga_vsync_temp;
endmodule