//
// FIRST TRY TO INSTALL A PASSTROUGH ON FPGA 
//
// SUB-MODULE IN USE: Z7_MMCM,I2S_RX, I2S_TX, Debouncer
//
// THIS TOP MODULE NEED THE FILE glbl.v and MMCM ip Z7_MMCM
//
// RESET MODE: active high; NAME: rst_sync; condiereing MMCM ~locked
//
// NOTE DI PERCORSO:-aggiungere qui i controlli per il dsp come puilsanti volume e accensione e spegnimento filtri
//                  - aggiungere sincronizzazione Plus e Minus con 2 FF


`timescale 10ns/100ps;

module AUDIO (
   
   //---INPUT---//
   input wire            clk,
   input wire       SDIN_ADC,
   input wire      reset_pin,
   input wire           Plus,
   input wire          Minus,
   input wire      enable_HP,
   input wire      enable_LP,
   input wire      select_BC,
   input wire      select_DS,
   
   //---OUTPUT---//
   output wire      BCLK_DAC,
   output wire      BCLK_ADC,
   output wire      LRCK_DAC,
   output wire      LRCK_ADC,
   output wire     SDOUT_DAC,
   output wire      MCLK_ADC,
   output wire      MCLK_DAC,
   output wire        LOCKED,
   output wire     LedMaxVol,
   output wire     LedMinVol,
   output wire     LED_en_HP,
   output wire LED_NEG_en_HP,
   output wire     LED_en_LP,
   output wire LED_NEG_en_LP,
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
   wire     buf_clk;
   wire       reset;
   wire        SDIN;
   wire        LRCK;
   wire   BCLK_MMCM;
   wire        BCLK;
   wire   MCLK_MMCM;
   
   //---System clock---//
   IBUF buf_clock ( .I(clk      ), .O(buf_clk ) );
   BUFG sys_clock ( .I(buf_clk  ), .O(sys_clk ) );
   
   //---INPUT---//
   
   BUFG BCLK_bufg ( .I(BCLK_MMCM), .O(BCLK    ) );
   IBUF SDIN_ibuf ( .I(SDIN_ADC ), .O(SDIN    ) );   // SDIN from ADC
   IBUF rest_ibuf ( .I(reset_pin), .O(reset   ) );   // reset from PIN
   
   //---OUTPUT---//
   
   OBUF BCLK_odac ( .I(BCLK     ), .O(BCLK_DAC ) );   // BCLK to DAC
   OBUF BCLK_oadc ( .I(BCLK     ), .O(BCLK_ADC ) );   // BCLK to ADC
   OBUF LRCK_odac ( .I(LRCK     ), .O(LRCK_DAC ) );   // LRCK to DAC
   OBUF LRCK_oadc ( .I(LRCK     ), .O(LRCK_ADC ) );   // LRCK to ADC
   
   OBUF SDOU_obuf ( .I(SDOUT    ), .O(SDOUT_DAC) );   // SDOUT from TX to DAC
   OBUF MCLK_oadc ( .I(MCLK_MMCM), .O(MCLK_ADC ) );   // MCLK from MMCM to ADC
   OBUF MCLK_odac ( .I(MCLK_MMCM), .O(MCLK_DAC ) );   // MCLK from MMCM to DAC
   
   //---OUTPUT for TEST---//
   
   //OBUF SDOU_test ( .I(SDOUT    ), .O(SDOUT_PROBE ) );   // SDOUT for testing porpouse
   //OBUF LRCK_test ( .I(LRCK     ), .O(LRCK_PROBE  ) );   // LRCK  for testing porpouse
   
   /////////////////////////
   //--------MMCM---------//
   //---file: MMCM.v------//
   /////////////////////////
   
   wire LOCKED;
   
   MMCM CLK_inst (
      
      .CLK_IN   (sys_clk    ),   // input from system clk
	  .reset    (rst_clean  ),   // input from pin
	  .MCLK     (MCLK_MMCM  ),   // output to ADC
	  .BCLK     (BCLK_MMCM  ),   // output to logic and codec
	  .LOCKED   (LOCKED     )    // output for sync_reset
	  
   );
   
   //////////////////////////
   //------RESET_SYNC------//
   //---file: Deboucer.v---//
   //////////////////////////
   
   wire     rst_clean;
   wire  rst_sync_sys;
   
   Debouncer #( .N(20) ) debouncer_rst (
      
	  .clk       (sys_clk  ),
	  .btn_in    (reset    ),
	  .btn_out   (rst_clean)
	  
   );
   
   assign rst_sync_sys = rst_clean | ~LOCKED; // reset with button and automatic reset for mmcm locking
   
   ////////////////////////////
   //---Sync reset to BCLK---//
   ////////////////////////////
   
   reg      rst0;
   reg      rst1;
   wire rst_sync;
   
   always @(posedge BCLK) begin  // 2FF sync
      
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
   wire [23:0]      SAMP_LEFT_RX;
   wire [23:0]     SAMP_RIGHT_RX;
   wire                    Valid;
   wire                      chn;
   
   I2S_RX reciever(
      
      .BCLK                  (BCLK),   // INPUT
	  .LRCK                  (LRCK),
	  .SDIN                  (SDIN),
	  .reset             (rst_sync),
	  .SAMP_LEFT     (SAMP_LEFT_RX),   // OUTPUT
	  .SAMP_RIGHT   (SAMP_RIGHT_RX),
	  .Valid_sample         (Valid),
	  .channel                (chn)
	  
   );
   
   ///////////////////////////
   //---Plus/Minus Volume---//
   //---file: Deboucer.v----//
   ///////////////////////////
   
   wire  Plus_clean;
   wire Minus_clean;
   
   Debouncer #( .N(20) ) debouncer_Plus (
      
	  .clk       (sys_clk   ),
	  .btn_in    (Plus      ),
	  .btn_out   (Plus_clean)
	  
   );
   
   Debouncer #( .N(20) ) debouncer_Minus (
      
	  .clk       (sys_clk    ),
	  .btn_in    (Minus      ),
	  .btn_out   (Minus_clean)
	  
   );
   
   ////////////////////////////////////////
   //---PLUS/MINUS VOLUME SYNC to BCLK---//
   ////////////////////////////////////////
   
   reg       Plus0;
   reg       Plus1;
   reg      Minus0;
   reg      Minus1;
   wire  Plus_sync;
   wire Minus_sync;
   
   always @(posedge BCLK) begin  // 2FF sync
      
	  Plus0  <=  Plus_clean;
	  Plus1  <=       Plus0;
	  
	  Minus0 <= Minus_clean;
	  Minus1 <=      Minus0;
	  
   end //always
   
   assign Plus_sync  =  Plus1;
   assign Minus_sync = Minus1;
   
   /////////////////////////////////////////////
   //---MODE select buttom for BC debouncer---//
   /////////////////////////////////////////////
   
   wire select_BC_clean;
   
   Debouncer #( .N(20) ) debouncer_BC (
    
      .clk       (sys_clk   ),
      .btn_in    (select_BC      ),
      .btn_out   (select_BC_clean)
   
   );
   
   //---SYNC select mode BC to BCLK---//
   
   reg         select0;
   reg         select1;
   wire select_BC_sync;
   
   always @(posedge BCLK) begin  // 2FF sync
      
	  select0  <=  select_BC_clean;
	  select1  <=       select0;
	  
   end //always
   
   assign select_BC_sync  =  select1;
   
   /////////////////////////////////////////////
   //---MODE select buttom for DS debouncer---//
   /////////////////////////////////////////////
   
   wire select_DS_clean;
   
   Debouncer #( .N(20) ) debouncer_DS (
    
      .clk       (sys_clk   ),
      .btn_in    (select_DS      ),
      .btn_out   (select_DS_clean)
   
   );
   
   //---SYNC select mode BC to BCLK---//
   
   reg         select0_DS;
   reg         select1_DS;
   wire select_DS_sync;
   
   always @(posedge BCLK) begin  // 2FF sync
      
	  select0_DS  <=  select_DS_clean;
	  select1_DS  <=       select0_DS;
	  
   end //always
   
   assign select_DS_sync  =  select1_DS;
   
   //////////////////////////////////////////////////////////////
   //                                                          //
   // BLOCCO DSP AUDIO CON FILTRI DA AGGIUNGERE NEL RTL FINALE //
   //                                                          //
   //////////////////////////////////////////////////////////////
   
   wire signed [23:0]   SAMP_LEFT_DSP;
   wire signed [23:0]  SAMP_RIGHT_DSP;
   
   DSP_AUDIO DSP_inst(
      
	  .sys_clk             (sys_clk),
      .BCLK                   (BCLK),
	  .LRCK                   (LRCK),
	  .rst                (rst_sync),
	  .SAMP_L         (SAMP_LEFT_RX),
	  .SAMP_R        (SAMP_RIGHT_RX),
	  .Plus              (Plus_sync),
	  .Minus            (Minus_sync),
	  .enable_HP         (enable_HP),
	  .enable_LP         (enable_LP),
	  .select_BC    (select_BC_sync),
	  .select_DS    (select_DS_sync),
	  
	  .SAMP_L_DSP    (SAMP_LEFT_DSP),
	  .SAMP_R_DSP   (SAMP_RIGHT_DSP),
	  .LedMaxVol         (LedMaxVol),
	  .LedMinVol         (LedMinVol)
	  
   );
   
   //---LED VISUAL HP---//
   assign LED_en_HP = enable_HP;
   assign LED_NEG_en_HP = ~enable_HP;
   
   //---LED VISUAL LP---//
   
   assign LED_en_LP = enable_LP;
   assign LED_NEG_en_LP = (enable_LP) ? 1'b0 : 1'b1;
   
   ////////////////////////
   //-------I2S_TX-------//
   //---file: I2S_TX.v---//
   ////////////////////////
   
   wire SDOUT;
   
   I2S_TX transmitter(
      
	  .BCLK                   (BCLK),
	  .LRCK                   (LRCK),
	  .SAMP_LEFT     (SAMP_LEFT_DSP),
	  .SAMP_RIGHT   (SAMP_RIGHT_DSP),
	  .reset              (rst_sync),
	  .SDATA                 (SDOUT)
	  
   );
   
   
endmodule