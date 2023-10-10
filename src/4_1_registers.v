`timescale 1ns / 1ps
//This module stores the value of the registers being configured with their values.
//as soon as the resend which is the output from the debounce becomes 1 it starts working
//the work is to keep the command as the address-value pair till one complete transmission cycle is completed
module registers(input clk_50,
				 input resend, 
				 input advance, 
				 output [15:0] command, 
				 output finished, 
				 output process_start);
				 
    reg [15:0] o_dout;                //Temporary variable to store the address-value pair
    reg finished_temp = 1'b0;         //initialising finished_temp as zero, this is for sending HIGH flag when one complete configuartion is done
    reg [8:0] address = {9{1'b0}};    //this is the register counter, and increments after advance, so to change the value of command
    reg process_start_temp = 1'b0;    //as soon as the process starts i.e. resend is executed, process_start will remain high when at last the finished is executed then it is low.
    reg advance_previous = 1'b0;      //this is to store the previous value advance, used to know if there is some triggering in advance
    
    //lOGIC_1: Whenever there is change in o_dout then to assign finished_temp its value. Its just checking whether the camera configuration is complete or not
    always@(o_dout)
    begin
    	if(o_dout == 16'hFFFF) 
    		finished_temp <= 1;
        else
            finished_temp <= 0;
    end
 
    //LOGIC_2:
    always@(posedge clk_50)
        begin
        if (finished_temp==1)
            process_start_temp<=0;                  //This works as the triggering signal for starting a new transmission
        if(resend == 1)
            begin
                address <= {9{1'b0}};               //once the resend is started we have to make address which is the counter as zero
                if (finished_temp==0)               //this one is the positive edge for the process_start
                    process_start_temp<=1;
                else
                    process_start_temp<=0;
            end        
        else if (advance==1 && advance_previous==0) //As soon as advance is triggered (received from input), which is done after one cycle of transmission of one value-address pair    
            begin
            address <= address+1;  					//To increment the address
            advance_previous <= 1;   				//for the next cycle advanced_previous becomes 1
            end
        else if (advance == 0) 
        	advance_previous <= 0; 					//for the next cycle advance_previous becomes 0
        //These are the values of registers tuned in such a way that it shows correct output   
		case (address) 
			00:  o_dout <=  16'h1280; // COM7   Reset
			01:  o_dout <=  16'h1280; // COM7   Reset
			02:  o_dout <=  16'h1204; // COM7   Size & RGB output
			03:  o_dout <=  16'h1100; // CLKRC  Prescaler - Fin/(1+1)
			04:  o_dout <=  16'h0C00; // COM3   Lots of stuff, enable scaling, all others off
			05:  o_dout <=  16'h3E00; // COM14  PCLK scaling off
   			06:  o_dout <=  16'h8C00; // RGB444 Set RGB format
   			07:  o_dout <=  16'h0400; // COM1   no CCIR601
 			08:  o_dout <=  16'h4010; // COM15  Full 0-255 output, RGB 565
			09:  o_dout <=  16'h3a04; // TSLB   Set UV ordering,  do not auto-reset window
			10:  o_dout <=  16'h1438; // COM9  - AGC Celling
			11:  o_dout <=  16'h4fb3; // MTX1  - colour conversion matrix
			12:  o_dout <=  16'h50b3; // MTX2  - colour conversion matrix
			13:  o_dout <=  16'h5100; // MTX3  - colour conversion matrix
			14:  o_dout <=  16'h523d; // MTX4  - colour conversion matrix
			15:  o_dout <=  16'h53a7; // MTX5  - colour conversion matrix
			16:  o_dout <=  16'h54e4; // MTX6  - colour conversion matrix
			17:  o_dout <=  16'h589e; // MTXS  - Matrix sign and auto contrast
			18:  o_dout <=  16'h3dc0; // COM13 - Turn on GAMMA and UV Auto adjust
			19:  o_dout <=  16'h1100; // CLKRC  Prescaler - Fin/(1+1)
			20:  o_dout <=  16'h1711; // HSTART HREF start (high 8 bits)
			21:  o_dout <=  16'h1861; // HSTOP  HREF stop (high 8 bits)
			22:  o_dout <=  16'h32A4; // HREF   Edge offset and low 3 bits of HSTART and HSTOP		
			23:  o_dout <=  16'h1903; // VSTART VSYNC start (high 8 bits)
			24:  o_dout <=  16'h1A7b; // VSTOP  VSYNC stop (high 8 bits) 
			25:  o_dout <=  16'h030a; // VREF   VSYNC low two bits            
            26:  o_dout <=  16'h69_00; //GFIX       fix gain control
		    27:  o_dout <=  16'h74_00; //REG74      Digital gain control
		    28:  o_dout <=  16'hB0_84; //RSVD       magic value from the internet *required* for good color
		    29:  o_dout <=  16'hB1_0c; //ABLC1
			30:  o_dout <=  16'hB2_0e; //RSVD       more magic internet values
		    31:  o_dout <=  16'hB3_80; //THL_ST
			//begin mystery scaling numbers
		    32:  o_dout <=  16'h70_3a;
			33:  o_dout <=  16'h71_35;
		    34:  o_dout <=  16'h72_11;
		    35:  o_dout <=  16'h73_f0;
			36:  o_dout <=  16'ha2_02;
		    //gamma curve values
			37:  o_dout <=  16'h7a_20;
			38:  o_dout <=  16'h7b_10;
		    39:  o_dout <=  16'h7c_1e;
			40:  o_dout <=  16'h7d_35;
		    41:  o_dout <=  16'h7e_5a;
			42:  o_dout <=  16'h7f_69;
		    43:  o_dout <=  16'h80_76;
			44:  o_dout <=  16'h81_80;
		    45:  o_dout <=  16'h82_88;
			46:  o_dout <=  16'h83_8f;
		    47:  o_dout <=  16'h84_96;
		   	48:  o_dout <=  16'h85_a3;
		    49:  o_dout <=  16'h86_af;
			50:  o_dout <=  16'h87_c4;
		    51:  o_dout <=  16'h88_d7;
			52:  o_dout <=  16'h89_e8;
		    //AGC and AEC
			53:  o_dout <=  16'h13_e0; //COM8, disable AGC / AEC
		    54:  o_dout <=  16'h00_00; //set gain reg to 0 for AGC
			55:  o_dout <=  16'h10_00; //set ARCJ reg to 0
		    56:  o_dout <=  16'h0d_40; //magic reserved bit for COM4
		   	57:  o_dout <=  16'h14_18; //COM9, 4x gain + magic bit
			58:  o_dout <=  16'ha5_05; // BD50MAX
		    59:  o_dout <=  16'hab_07; //DB60MAX
			60:  o_dout <=  16'h24_95; //AGC upper limit
		    61:  o_dout <=  16'h25_33; //AGC lower limit
			62:  o_dout <=  16'h26_e3; //AGC/AEC fast mode op region
		    63:  o_dout <=  16'h9f_78; //HAECC1
			64:  o_dout <=  16'ha0_68; //HAECC2
		    65:  o_dout <=  16'ha1_03; //magic
			66:  o_dout <=  16'ha6_d8; //HAECC3
		    67:  o_dout <=  16'ha7_d8; //HAECC4
			68:  o_dout <=  16'ha8_f0; //HAECC5
			69:  o_dout <=  16'ha9_90; //HAECC6
		    70:  o_dout <=  16'haa_94; //HAECC7
			71:  o_dout <=  16'h13_e5; //COM8, enable AGC / AEC
			72:  o_dout <=  16'h1E_23; //Mirror Image
			73:  o_dout <=  16'h69_06; //gain of RGB(manually adjusted)     
           	default: o_dout <= 16'hFFFF;//mark end of ROM
        endcase
        end
        
    //ASSIGNING VALUES:     
    assign command = o_dout; 
    assign finished = finished_temp;
    assign process_start = process_start_temp; 
endmodule
