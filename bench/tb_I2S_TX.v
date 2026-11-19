//
// testbench for the I2S-Transmitter module generating a SDIN
//

`timescale 10ns/100ps;

module tb_I2S_TX;
   
   /////////
   // I/O //
   /////////
   
   reg                       BCLK = 0;
   reg                       LRCK = 0;
   reg [23:0]  SAMP_LEFT = 24'hA5A5A5;
   reg [23:0] SAMP_RIGHT = 24'h123456;
   wire                         SDATA;
   
   /////////
   // DUT //
   /////////
   
   I2S_TX DUT(
      
      .BCLK(BCLK),
	  .LRCK(LRCK),
	  .SAMP_LEFT(SAMP_LEFT),
	  .SAMP_RIGHT(SAMP_RIGHT),
	  .SDATA(SDATA)
	  
   );
   
   ///////////////////////////
   // BLCK n LRCK generator //
   ///////////////////////////
   
   always #(10) BCLK = ~BCLK;
   
   always begin
      
	  repeat(32) @(negedge BCLK);
	  LRCK = ~LRCK;
	  
   end //always
   
   ///////////////////
   // main stimulus //
   ///////////////////
   
   initial begin
      
	  repeat(291) @(posedge BCLK);
	  SAMP_LEFT = 24'h111111;
	  SAMP_RIGHT = 24'hAAAAAA;
	  repeat(200) @(posedge BCLK);
	  $stop;
	  
   end //initial
   
   
endmodule