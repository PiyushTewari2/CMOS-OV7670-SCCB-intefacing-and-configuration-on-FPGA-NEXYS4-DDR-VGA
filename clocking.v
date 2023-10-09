`timescale 1ns / 1ps
//This is to divide the 100Mhz/50Mhz clock by 2
module clocking_verilog(input clk_in, 
					    output clk_out);

    wire clk_in; 
    reg clk_out;
    
    //LOGIC:
    initial clk_out <= 0;
    always @ (posedge clk_in) //Will trigger at every positive edge
        begin
        clk_out <= !clk_out;  //Change the output at every pos-edge, hence this will make the output frequency half 
        end
endmodule