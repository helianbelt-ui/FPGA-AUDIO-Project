//
// FIRST TRY TO INSTALL A PASSTROUGH ON FPGA 
//
// SUB-MODULE IN USE: Z7_MMCM,I2S_RX, I2S_TX, Debouncer
//
// THIS TOP MODULE NEED THE FILE glbl.v and MMCM ip Z7_MMCM
//
// NOTE DI PERCORSO:

`timescale 10ns/100ps;

module hw_Passtrough (
   
   //---INPUT---//
   input wire        clk,
   input wire   SDIN_ADC,
   input wire  reset_pin,
   
   //---OUTPUT---//
   output wire  BCLK_DAC,
   output wire  BCLK_ADC,
   output wire  LRCK_DAC,
   output wire  LRCK_ADC,
   output wire SDOUT_DAC,
   output wire  MCLK_ADC,
   output wire  MCLK_DAC,
   
   //---TEST-IO---//
   output wire  SDOUT_PROBE,
   output wire  LRCK_PROBE
   
);

   ////////////////////
   //---I/O BUFFER---//
   //---& BUFG INP---//
   ////////////////////
   
   //---inter-connection---//
   wire     sys_clk;
   wire       reset;
   wire        SDIN;
   wire        LRCK;
   wire   BCLK_MMCM;
   wire        BCLK;
   wire   MCLK_MMCM;
   
   //---System clock---//
   IBUF sys_clock ( .I(clk      ), .O(sys_clk) );
   
   //---INPUT---//
   
   BUFG BCLK_bufg ( .I(BCLK_MMCM ), .O(BCLK   ) );
   IBUF SDIN_ibuf ( .I(SDIN_ADC  ), .O(SDIN   ) );   // SDIN from ADC
   IBUF rest_ibuf ( .I(reset_pin ), .O(reset  ) );   // reset from PIN
   
   //---OUTPUT---//
   
   OBUF BCLK_odac ( .I(BCLK     ), .O(BCLK_DAC ) );   // BCLK to DAC
   OBUF BCLK_oadc ( .I(BCLK     ), .O(BCLK_ADC ) );   // BCLK to ADC
   OBUF LRCK_odac ( .I(LRCK     ), .O(LRCK_DAC ) );   // LRCK to DAC
   OBUF LRCK_oadc ( .I(LRCK     ), .O(LRCK_ADC ) );   // LRCK to ADC

   OBUF SDOU_obuf ( .I(SDOUT    ), .O(SDOUT_DAC) );   // SDOUT from TX to DAC
   OBUF MCLK_oadc ( .I(MCLK_MMCM), .O(MCLK_ADC ) );   // MCLK from MMCM to ADC
   OBUF MCLK_odac ( .I(MCLK_MMCM), .O(MCLK_DAC ) );   // MCLK from MMCM to DAC
   
   //---OUTPUT for TEST---//
   
   OBUF SDOU_test ( .I(SDOUT    ), .O(SDOUT_PROBE ) );   // SDOUT for testing porpouse
   OBUF LRCK_test ( .I(LRCK     ), .O(LRCK_PROBE  ) );   // LRCK  for testing porpouse
   
   /////////////////////////
   //--------MMCM---------//
   //---file: MMCM.v------//
   /////////////////////////
   
   wire LOCKED;
   
   MMCM CLK_inst (
      
      .CLK_IN   (sys_clk    ),   // input from system clk
	  .reset    (reset_clean),   // input from pin
	  .MCLK     (MCLK_MMCM  ),   // output to ADC
	  .BCLK     (BCLK_MMCM  ),   // output to logic and codec
	  .LOCKED   (LOCKED     )    // output for sync_reset
	  
   );
   
   //////////////////////////
   //------RESET_SYNC------//
   //---file: Deboucer.v---//
   //////////////////////////
   
   wire rst_clean;
   wire  rst_sync_sys;
   
   Debouncer #( .N(20) ) debouncer_btn (
      
	  .clk      (sys_clk),
	  .btn_in     (reset),
	  .btn_out(rst_clean)
	  
   );
   
   assign rst_sync_sys = rst_clean | ~LOCKED; // reset with button and automatic reset for mmcm locking
   
   ////////////////////////////
   //---Sync reset to BCLK---//
   ////////////////////////////
   
   reg      rst0;
   reg      rst1;
   wire rst_sync;
   
   always @(posedge BCLK) begin
      
	  rst0 <= rst_sync_sys;
	  rst1 <=         rst0;
	  
   end //always
   
   assign rst_sync = rst1;
   
   //////////////////////////
   //---LRCK TICKCOUNTER---//
   //---file: lrck_gen.v---//
   //////////////////////////
   
   lrck_gen #(.FRAME_SIZE(32)) LRCKGEN (
   
      .BCLK        (BCLK),
	  .reset   (rst_sync),
	  .LRCK        (LRCK)
	  
   );
   
   ////////////////////////
   //-------I2S_RX-------//
   //---file: I2S_RX.v---//
   ////////////////////////
   
   //---inter-connection---//
   wire [23:0]    SAMP_LEFT;
   wire [23:0]   SAMP_RIGHT;
   wire               Valid;
   wire                 chn;
   
   I2S_RX reciever(
      
      .BCLK               (BCLK),   // INPUT
	  .LRCK               (LRCK),
	  .SDIN               (SDIN),
	  .reset          (rst_sync),
	  .SAMP_LEFT     (SAMP_LEFT),   // OUTPUT
	  .SAMP_RIGHT   (SAMP_RIGHT),
	  .Valid_sample      (Valid),
	  .channel             (chn)
	  
   );
   
   ////////////////////////
   //-------I2S_TX-------//
   //---file: I2S_TX.v---//
   ////////////////////////
   
   wire SDOUT;
   
   I2S_TX transmitter(
      
	  .BCLK               (BCLK),
	  .LRCK               (LRCK),
	  .SAMP_LEFT     (SAMP_LEFT),
	  .SAMP_RIGHT   (SAMP_RIGHT),
	  .reset          (rst_sync),
	  .SDATA             (SDOUT)
	  
   );
   
   
endmodule