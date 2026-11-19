//
//      ////////////////
//      //------------//
//      //---I2S_RX---//
//      //------------//
//      ////////////////
//
//
// I2S reciver: this module take the serial data from the CS5343 A/D and create 1 sample of 24bit for channel (sx e dx)
// using I2s protocol.
// This module receives 2 clock: BCLK (bitclock) ~3MHz and WS/LRCK (word select) of 48KHz that choose the channel
// when WS changes, after 1 BCLK cycle, start data comunication (2'comp) with MSB (sign).
// SDIN is the data out from CS5343 A/D, is a serial data
//
// every time LRCK changes, after a period od BCLK, this module write the value of SDIN in a shift register, 
// when all 24 bits are witten a counter flag Valid_sample and the sample is readi end overwritten in a register,
// after that, when LRCLK chenges again, this work is repeated on the second channel
// the values of the 2 chennels are the output ---> DSP
//
// SAMPLING FREQUENCY 48 KHz;
// LRCK = LOW   --->   left channel
// LRCK = HIGH  --->   right channel

`timescale 10ns/100ps;


module I2S_RX (
   
   input wire                       BCLK,
   input wire                       LRCK,
   input wire                       SDIN,
   input wire                      reset,
   
   output reg signed [23:0]    SAMP_LEFT,
   output reg signed [23:0]   SAMP_RIGHT,
   output reg               Valid_sample,
   output reg                    channel
   
   );
   
   reg lrck_d            = 0;    //ritardo di LRCK
   //reg wait_msb        = 0;    //attenda il clock per MSB
   reg [4:0] bit_cnt     = 0;    //conta che siano arriviti tutti i 24 bit del sample
   reg [23:0] shift_reg  = 0;    //shift register su cui scrive il sample
   
   always @( posedge BCLK ) begin
   
      if (reset) begin
	     
		 bit_cnt      <= 0;
		 shift_reg    <= 0;
		 SAMP_LEFT    <= 0;
		 SAMP_RIGHT   <= 0;
		 lrck_d       <= 0;
		 Valid_sample <= 0;
		 
	  end //if reset
	  
	  else begin //logic
	  
	     Valid_sample <= 1'b0;
	     
         lrck_d <= LRCK;  //flag per ritardo MSB rispetto a change LRCK
	     
	     if (lrck_d != LRCK) begin //vede change di LRCK->flag wait a cycle; reset bit counter
	        
	        //wait_msb <= 1'b1;
		    bit_cnt    <=    0;
		    
	     end//if lrck_d != LRCK

	     else begin

	        shift_reg <= {shift_reg[22:0],SDIN};
	        bit_cnt <= bit_cnt + 1;
		 
		    if (bit_cnt == 23) begin
		       
			   if (lrck_d == 1'b1) begin
			      SAMP_RIGHT <= {shift_reg[22:0],SDIN};
			   end//if
			   
			   if (lrck_d == 1'b0) begin
			      SAMP_LEFT <= {shift_reg[22:0],SDIN};
			   end//if
			   
			   Valid_sample <= 1'b1;
			   channel <= lrck_d;
			   
		    end //if bit_cnt = 23
		    
	     end// else
	  
	  end //logic
	  
   end//always
   
   
endmodule