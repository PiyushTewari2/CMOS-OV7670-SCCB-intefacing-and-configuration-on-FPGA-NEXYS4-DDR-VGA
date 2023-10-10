`timescale 1ns / 1ps
//The "main" module in charge of the SCCB communication with the OmniVision OV7670 camera.
//As explained in the Register Set section of the datasheet, the camera slave address is x"42" (0x42, hexadecimal) for writting and and x"43" fo reading
//SCCB Timing: 
//                 0 1 2 3
//       :________:     ___:     ___:
//  SCL  :        :\___/   :\___/   :
//       :        :        :        :
//       :__      :   _____:__ _____:
//  SDA  :  \_____:__/__d7_:__X__d6_:
//       :0 1 2 3 :0 1 2 3 :0 1 2 3
//                :        :
//                :.Tsccb..:

//          init                                  dont   Another phase
//        sequence 0 1 2 3                        care    OR end bit
//       :______  :   ___  :   ___  : :   ___  :   ___  :  ______
//  SCL  :      \_:__/   \_:__/   \_: :__/   \_:__/   \_:_/
//       :        :        :        : :        :        :
//       :__      : _______: _______: : _______: _______:    ____
//  SDA  :  \_____:/__d7___:X__d6___: :X__d0___:X___Z___:___/    
//       :0 1 2 3 :0 1 2 3 :0 1 2 3
//                :        :
//                :.Tsccb..:                     DNTC_ST:END_SEQ_ST
//       INIT_SEQ_ST
//
//     The period Tsccb is divided in 4 parts.
//     SCL changes at the end of 1st and 3rd quarters
//     SDA changes at the end of the peridod (end of last (4th) quarter)
//     When transmiting bits, SDA must not change when SCL is high
//     Max frequency of the sccb clock 100 KHz: Period 10 us
//     Half of the time will be high, the other half low: 5 us
//     However, the minimum clok low period for the sccb_clk is 1.3 us
//     making low and high the same time, would be 2.6 us (~384,6 KHz)
module main(input clk50m, 
			input finish, 
			input [15:0]add_value, 
			output siod, 
			output send, 
			input starter, 
			output sioc_real);
	
	//Temporary registers which whose values will be assigned to the output regs		
    reg siod_temp = 1'b0;
    reg send_temp = 1'b0;
    reg sioc_temp = 1;
    
    //This is the slave address for writing the values in the registers of camera
    reg [7:0]id_address = 8'h42;
    
    //These are various flags and counter registers for creating the SCCB timing
    reg starter_previous = 0;     //This is to copy the starter clock, storing the previous value of starter, this will be high from the start of the transmission till the end, its rising edge will mark the start of transmission
    reg mega_counter_begin = 0;   //mega counter begin is the flag to start mega counter for the 50Mhz clock, it counts for 1 clock cycle of 50Khz 
    reg [9:0]mega_counter = 500;  //this is the mega counter, it is initialised with 500, to maintain the starting condition (refer the manual for timings)
    reg [4:0]counter = 0;		  //this counter is for counting individual bits of one transmission phase, which contains 27 bits
    reg stop_condition_begin = 0; //this is the stop condition flag which should be HIGH after the finish of one "register" write cycle (27 sioc) 
    reg bring_next_reg = 0;		  //this flag is for bringing next register
    reg starter_condition = 0;	  //this is the start condtion flag which needs to start before sendind the 27 data clocks, this is for starting the start condition
    reg [6:0]start_counter = 0;   //this keeps the count of the start condition, it works on 50Mhz clock and is there to satify the starting condition
    reg [5:0]stop_counter = 0;    //similarly this is the counter to satisfy the stop condition
    reg long_delay = 0;			  //long_delay is the flag for the time between two resister write values, since the clock is left HIGH Z it needs time to settle to 0
    reg [23:0]maha_counter = 0;	  //this huge counter servers the role for creating such long counter 
   
   	//LOGIC: 
    always@(posedge clk50m)
        begin
        if (starter == 0) 
            begin
            siod_temp <= 1'b0;  //when starter is not on keep the line high z, 
            sioc_temp <= 1'b1;
            end
        if (starter == 1 && starter_previous==0)  // as soon as the starter triggers go to checking posedge of 100k  
            begin
            //This begins as the positive edge of the starter hence we have to start the starting condition, 
            //starter previous will be 1 which will be valid in the next cycle
            starter_condition <= 1;
            starter_previous <= 1;
            end 
        if (starter == 1)
            begin
            //beginning the start condition
            //this is where we enter in the start condition, here the clock should trigger before data becomes 0
            //note that counter values 35 and 105 are chosen in such a way that they sufficiently satisfy the start condtion 
            if (starter_condition == 1)
                begin
                send_temp <= 0;
                start_counter <= start_counter+1;
                if (start_counter == 0)
                	begin
                	siod_temp <= 1;            //siod is HIGH initially
                	end
                if (start_counter == 35)
                    begin
                    siod_temp <= 0;            //then after 35 cycles it should be low
                    end         
                end
                if (start_counter == 105)      //this marks the end of the starting condition, hence we will reset the starter counter and flag, and begin the mega counter flag 
                    begin
                    sioc_temp <= 0;
                    mega_counter_begin <= 1;
                    starter_condition <= 0;
                    start_counter <= 0;
                    end
                                 
            //Data Transmission, now the data transmission begins hence mega counter will work, which helps creating both sioc and siod for configuration    
            //since the mega counter has begun, this works on the 50Mhz clock hence 940 is chosen in such a way that it satify the sccb timing
            if (mega_counter_begin == 1) mega_counter <= mega_counter+1;
            if (mega_counter == 940) counter <= counter+1;
            if (counter > 0 && counter < 29)        						          //this counter is for the individual data bits (27) of the transmission phase. (refer the sccb interface document)
            	begin
                if (counter < 9 && counter > 0) siod_temp <= id_address[8-counter];   //First the id address is sent
                if (counter == 9) siod_temp <= 0;
                if (counter > 9 && counter < 18) siod_temp <= add_value[25-counter];  //then the register address     
                if (counter == 18) siod_temp <= 0;
                if (counter > 18 && counter < 27) siod_temp <= add_value[26-counter]; //and then the register value
                if (counter == 27) siod_temp <= 0;   								  //Last value of siod, now the end condtion will begin
                if (counter == 28)    												  //hence the counter is reset, mega counter is brought back to initial conditon, megacounter flg is rest, and stop counter condition is activated    
                    begin
                    counter <= 0;
                    mega_counter <= 500;
                    mega_counter_begin <= 0;
                    sioc_temp <= 1;
                    stop_condition_begin <= 1;
                    end
                end
            if (mega_counter == 999)            //this is for creating the sioc with the help of mega counter, this will create a 50Khz clock (sioc)
                begin
                sioc_temp <= !sioc_temp;
                mega_counter <= 0;
                end        
            if (mega_counter == 499)
                sioc_temp <= !sioc_temp;

            //Stop Condition begin
            //Now let us see the stop conditon, it will also satisfy the stop condtion setup and hold timings
            if (stop_condition_begin == 1)
            	begin
            	stop_counter <= stop_counter+1;  //stop counter will be there for satifying the stop condtion timings
            	if (stop_counter == 35)
            		siod_temp <= 1;
            	if (stop_counter == 36)          //with the end of the stop condtion there will be completion of one "register writing", hence we need along delay so that HIGH Z settles to 0 and then we have to begin the start condtion once again until we receive a finished and we will also increment send, so that the address advances meanwhile
            		begin
            		siod_temp <= 1'bz;
            		stop_counter <= 0;
            		stop_condition_begin <= 0;
            		bring_next_reg <= 1;
            		long_delay <= 1;
            		end
            	end
            
            //call the next register meanwhile
            if (bring_next_reg == 1)
            	begin
            	send_temp <= 1;
            	bring_next_reg <= 0;
            	end
            
            //to give a good delay
            if (long_delay == 1)
            	begin
            	maha_counter <= maha_counter+1;
            	if (maha_counter == 15000000)
            		begin
            		starter_condition <= 1;
            		maha_counter <= 0;
            		end
            	end                  
            end
        end

	//ASSIGNING VALUES:
    assign siod = siod_temp;
    assign send = send_temp;
	assign sioc_real = sioc_temp; 
endmodule
