`timescale 1ns / 1ps
//this is for capturing thw image from the camera
module ov7670_capture_verilog(input pclk,
                              input vsync,
                              input href,
                              input [7:0] d,
                              output [18:0] addr,
                              output [11:0] dout,
                              output we);
                              
    reg [15:0] d_latch = {16{1'b0}};                  //This is the data latch and holds the data
    reg [18:0] address = {19{1'b0}};				  //stores the addres of the pixel
    reg  unsigned [18:0] address_next = {19{1'b0}};
    reg [1:0] wr_hold = {2{1'b0}};
    
    reg [11:0] dout_temp;                             //RGB444
    reg we_temp;
    
    //LOGIC: 
    always@ (posedge pclk)                            //data sync with the pclock (pixel clock)
        begin
            if(vsync == 1)                            //this is according to the timing for VGA output, check these timing from OV7670 datasheet
                begin
                    address <= {19{1'b0}};            //initially the address will be zero
                    address_next <= {19{1'b0}};       
                    wr_hold <= {2{1'b0}};
                end
            else
                begin
                	//the task is to bring the pixel data into one variable, since it is RGB444, hence data comes as:
                	//Cycle1: GGGGBBBB
                	//Cycle2: XXXXRRRR
                	//the dlatch is attaching two clocks data into one vector, hence in two cycles dout will get its value
                    dout_temp <= {d_latch[15:12],d_latch[10:7],d_latch[4:1]};
                    address <= address_next;
                    we_temp <= wr_hold[1];
                    wr_hold <= {wr_hold[0], (href && !wr_hold[0])};
                    d_latch <= {d_latch [7:0], d};                              //d-latch taking the d values in two clocks for getting one pixel data
                    if(wr_hold[1] == 1)
                    	address_next <= address_next+1;
                end
        end
	
	//ASSIGNING VALUES:         
    assign addr = address;
    assign dout = dout_temp;
    assign we = we_temp;    
endmodule
