//
// TESTBENCH to test the PassTrough to check the I2S serial protocol
//

`timescale 10ns/100ps;

module tb_PassTrough;
   
   /////////////
   //---I/O---//
   /////////////
   
   reg  BCLK  = 0;
   reg  LRCK  = 0;
   reg  SDIN  = 0;
   
   wire SOUT;
   
   /////////////
   //---DUT---//
   /////////////
   
   PassTrough DUT (
      
	  //input
	  .BCLK(BCLK),
	  .LRCK(LRCK),
	  .SDIN(SDIN),
	  //output
	  .SOUT(SOUT)
	  
   );
   
   ///////////////////////////////
   //---BCLK'n'LRCK generator---//
   ///////////////////////////////
   
   always #10 BCLK = ~BCLK;
   
   always begin
      
      repeat(32) @(negedge BCLK);
	  LRCK = ~LRCK;
	  
   end//always
   
   ///////////////////////////////////////////////////////////////////
   //---definizione TASK "send_sample" per inviare un sample test---//
   ///////////////////////////////////////////////////////////////////
   
   task send_sample( input [23:0] sample);
      
      integer i;
      begin
	  
	     @(negedge BCLK);
		 
		 for ( i=23; i>=0; i = i-1) begin // for gira al contrario per essere MSB-first
		    SDIN = sample[i];
			@(negedge BCLK);
		 end// for
		 
		 //padding fino a 32 bit
		 SDIN = 0;
		 repeat(7) @(negedge BCLK);
		 
	  end //begin
	  
   endtask
   
   ///////////////////////////////////////////////
   //---sequenza di test con task send_sample---//
   ///////////////////////////////////////////////
   
   initial begin
      
	  $display("INIZIO SIMULAZIONE");
	  
	  //attesa 1 ciclo LRCK
	  repeat(64) @(negedge BCLK);
	  
	  
	  //LEFT channel (LRCK LOW)
	  @(negedge LRCK);
	  send_sample(24'hA5A5A5);
	  
	  //RIGHT channel (LRCK HIGH)
	  @(posedge LRCK);
	  send_sample(24'hAAAAAA);
	  
	  //LEFT channel (LRCK LOW)
	  @(negedge LRCK);
	  send_sample(24'h123456);
	  
	  //RIGHT channel (LRCK HIGH)
	  @(posedge LRCK);
	  send_sample(24'h5C5B5A);
	  
	  //attesa 1 ciclo LRCK
	  repeat(100) @(negedge BCLK);
	  $display("FINE SIMULAZIONE");
	  $stop;
	  
   end // initial
   
endmodule