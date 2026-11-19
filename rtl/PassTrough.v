//
// Pass-Trough module to test the comunication from I2S_RX to I2S_TX 
//

`timescale 10ns/100ps

module PassTrough (
   
   //input
   input  wire  BCLK,
   input  wire  LRCK,
   input  wire  SDIN,
   
   //output
   output wire SOUT
   
   );
   
   ///////////////////////////////
   //---In-module connections---//
   ///////////////////////////////
   
   wire [23:0]  SAMP_LEFT_outRX;
   wire [23:0] SAMP_RIGHT_outRX;
   wire [23:0]  SAMP_LEFT_innTX;
   wire [23:0] SAMP_RIGHT_innTX;
   wire             Valid;
   wire           channel;
   wire             SDATA;
   
   /////////////////////////
   //---reciever I2S_RX---//
   /////////////////////////
   
   I2S_RX reciever (
      
      //input
	  .BCLK(BCLK),
	  .LRCK(LRCK),
	  .SDIN(SDIN),
	  //output
	  .SAMP_LEFT(SAMP_LEFT_outRX),
	  .SAMP_RIGHT(SAMP_RIGHT_outRX),
	  .Valid_sample(Valid),
	  .channel(channel)
	  
   );
   
   /////////////////////////////////
   //---intermodule connections---//
   /////////////////////////////////
   
   assign SAMP_LEFT_innTX  = SAMP_LEFT_outRX;
   assign SAMP_RIGHT_innTX = SAMP_RIGHT_outRX;
   
   ////////////////////////////
   //---transmitter I2S_TX---//
   ////////////////////////////
   
   I2S_TX transmitter (
      
	  //input
	  .BCLK(BCLK),
	  .LRCK(LRCK),
	  .SAMP_LEFT(SAMP_LEFT_innTX),
	  .SAMP_RIGHT(SAMP_RIGHT_innTX),
	  //output
	  .SDATA(SDATA)
	  
   );
   
   assign SOUT = SDATA;
   
endmodule