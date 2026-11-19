//
// GENERATE LRCK CLOCK FROM BCLK
// THIS MODULE TAKE BCLK 6.144MHz AND DIVIDE IT FOR 64 USIGN A TICK-COUNTER TO OBTAIN A 96kHz SAMPLE FREQUENCY
//

`timescale 10ns/100ps;

module lrck_gen #( parameter FRAME_SIZE = 32)( // NB FRAME_SIZE is an half of the real frame size required
   
   input  wire  BCLK,
   input  wire reset,
   
   output wire  LRCK
);
   
   localparam cnt_width = $clog2(FRAME_SIZE); //calcolo size reg per counter
   
   reg [cnt_width-1:0] cnt = 0;
   
   reg lrck_reg = 0;
   
   always @(negedge BCLK) begin
   
      if (reset) begin
	  
	     cnt      <= 0;
		 lrck_reg <= 0;
		 
	  end else begin
	  
	     if( cnt == FRAME_SIZE-1 ) begin
		    
			lrck_reg <= ~lrck_reg;
			cnt      <=         0;
			
		 end else begin
		    
			cnt      <=     cnt+1;
			
		 end
		 
	  end
	  
   end//always
   
   assign LRCK = lrck_reg;
   
endmodule