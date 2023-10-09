`timescale 1ns / 1ps
//the sccb module is for configuring camera registers using the sccb protocol
//within the sccb module there lies the controller and the registers
module sccb(input clock_50,
			input reset, 
			output sio_d,	
			output sioc_sachha);
    
    wire[15:0] data;		//16 bit address-value pair of the data, and the corresponding address
    wire forward_command;   //This is sent from controller to the register module after one register value is sent via sioc
    wire completed;			//This is sent from the controller to the register module after completing one cycle of the transmission 
    wire process;           //This command is sent from the register module to the controller once the transmisssion starts
     
    //Once the transmission begins (after pressing the reset button) the registers start getting written
    registers register(.clk_50(clock_50),.resend(reset),.advance(forward_command),.command(data),.finished(completed),.process_start(process));
    //the main controller takes the register values and then sends them serially through sioc to the camera for configuring the camera
    main controller(.clk50m(clock_50),.finish(completed),.add_value(data),.siod(sio_d),.send(forward_command), .starter(process),.sioc_real(sioc_sachha));
endmodule