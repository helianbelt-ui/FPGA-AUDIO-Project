//
// testbench for the I2S-reciever module generating a SDIN
//


`timescale 10ns/100ps;

module tb_I2S_RX;
   
   /////////
   // I/O //
   /////////
   
   reg BCLK = 0;
   reg LRCK = 0;
   reg SDIN = 0;
   
   wire [23:0] SAMP_LEFT;
   wire [23:0] SAMP_RIGHT;
   wire Valid_sample;
   
   /////////
   // DUT //
   /////////
   
   I2S_RX DUT (
      
      .BCLK(BCLK),
      .LRCK(LRCK),
      .SDIN(SDIN),
      .SAMP_LEFT(SAMP_LEFT),
      .SAMP_RIGHT(SAMP_RIGHT),
      .Valid_sample(Valid_sample),
	  .channel(channel)
      
   );
   
   
   ///////////////////////////
   // BCLK'n'LRCK generator //
   ///////////////////////////
   
   always #10 BCLK = ~BCLK ;
   
   always begin
   
      repeat(32) @(negedge BCLK);
	  LRCK = ~LRCK ;
	  
   end //always
   
   ///////////////////////////////////////////////////////////////
   // definizione TASK "send_sample" per inviare un sample test //
   ///////////////////////////////////////////////////////////////
   
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
   
   
   ///////////////////////////////////////////
   // sequenza di test con task send_sample //
   ///////////////////////////////////////////
   
   initial begin
      
	  $display("INIZIO SIMULAZIONE");
	  
	  //attesa 1 ciclo LRCK
	  repeat(64) @(negedge BCLK);
	  
	  
	  
	  //LEFT channel (LRCK LOW)
	  @(negedge LRCK);
	  send_sample(24'hA5A5A5);
	  
	  //RIGHT channel (LRCK HIGH)
	  @(posedge LRCK);
	  send_sample(24'h5A5A5A);
	  
	  //LEFT channel (LRCK LOW)
	  @(negedge LRCK);
	  send_sample(24'h123456);
	  
	  //RIGHT channel (LRCK HIGH)
	  @(posedge LRCK);
	  send_sample(24'h5C5B5A);
	  
	  repeat(1000) @(negedge BCLK);
	  
	  $display("FINE SIMULAZIONE");
	  $stop;
	  
   end // initial
   
   
   
   ///////////////////////
   // Monitor risultati //
   ///////////////////////
   
   always @(posedge BCLK) begin
      if (Valid_sample) begin
	     $display("TIME=%0t LRCK=%b LEFT=%h RIGHT=%h",
		           $time, LRCK, SAMP_LEFT, SAMP_RIGHT);
	  end// if
   end //always

endmodule