//
// Module to Buffer-Clock 
//
// BCLK and LRCK from the cs5343 to FPGA  ( IBUF + BUFG )
// MCLK from internal fpga MMCM to cs5343 ( BUFG + OBUF )

`timescale 10ns/100ps;

module Clock_Buffer (
   
   //input
   input wire   BCLK_IN,
   input wire   LRCK_IN,
   input wire MCLK_MMCM,
   
   //output
   output wire BCLK,
   output wire LRCK,
   output wire MCLK_PIN
   
   );
   
   //////////////
   //---MCLK---//
   //////////////
   
   wire MCLK;
   
   BUFG mclk_bufg_inst(
      
      .I(MCLK_MMCM),
	  .O(MCLK)
	  
   );
   
   OBUF mclk_obuf_inst(
      
      .I(MCLK),
	  .O(MCLK_PIN)
	  
   );
   
   //////////////
   //---BCLK---//
   //////////////
   
   wire bclk_ibuf;
   
   IBUF bclk_ibuf_inst(
      
      .I(BCLK_IN),
	  .O(bclk_ibuf)
	  
   );
   
   BUFG bclk_bufg_inst(
      
      .I(bclk_ibuf),
	  .O(BCLK)
	  
   );
   
   //////////////
   //---LRCK---//
   //////////////
   
   wire lrck_ibuf;
   
   IBUF lrck_ibuf_inst(
      
      .I(LRCK_IN),
	  .O(lrck_ibuf)
	  
   );
   
   BUFG lrck_bufg_inst(
      
      .I(lrck_ibuf),
	  .O(LRCK)
	  
   );
   
   
endmodule