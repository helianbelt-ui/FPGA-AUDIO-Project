//
// MODULE FOR DEBOUCING, used for the reset buttom
//
// working principle 2FF


`timescale 10ns/100ps;

module Debouncer #( parameter N = 20)(
   
   //---INPUT---//
   input   wire     clk,
   input   wire  btn_in,
   //---OUTPUT---//
   output  reg  btn_out
);

   reg [N-1:0]  count = 0;
   reg      btn_sync0 = 0;
   reg      btn_sync1 = 0;
   
   always @(posedge clk) begin
      
	  btn_sync0 <=    btn_in;
	  btn_sync1 <= btn_sync0;
	  
	  if ( btn_sync1 == btn_out ) begin
	  
	     count <= 0;
	  
	  end else begin
	     
		 count <= count + 1;
		 if (&count) begin
		    
			btn_out <= btn_sync1;
			
		 end// if &counter
		 
	  end //else
	  
   end //always


endmodule