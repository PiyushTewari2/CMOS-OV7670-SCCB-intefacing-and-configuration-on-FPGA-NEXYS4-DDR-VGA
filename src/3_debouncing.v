`timescale 1ns / 1ps
//Since the input can have noise hence we will accept the inpt only if it is pressed for long duration which this debounce satisfy
//note that when the button is pressed it sends 0 not 1 thats why "i==0" is used.
//input clock is 50Mhz
//i input is from the button, be careful with the "note" condition, play with that if it gets reset without pressing
module debounce(input clk, 
				input i, 
				output o);
				 
	reg unsigned [23:0]c = {24{1'b0}};  //24 bits for counting 24 bits and hence this will act as delay, (2^24)/50M = 0.3355s
    reg out_temp = 0; 				   //output temporary register whose value will be assigned to "o" output
    
    //LOGIC:      
    always @(posedge clk)
    	begin
        if(i == 0)
        	begin
            if(c == 24'hFFFFFF)
                out_temp <= 1'b1;  //when the input is continously pressed for 0.3355s then the output should be 1           
            else
                out_temp <= 1'b0;  //else in every other case it should be 0
            c <= c+1'b1;           //since the button is pressed increment the counter
        	end
        else 
        	begin
            c <= {24{1'b0}};       //if the reset button is not pressed then make both counter and output 0
            out_temp <= 1'b0; 
        	end
    	end
    
    //ASSIGNING OUTPUT:	
    assign o = out_temp;
endmodule
