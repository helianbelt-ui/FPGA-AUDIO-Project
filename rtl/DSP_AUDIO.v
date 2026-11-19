//
//
// DSP containg all sub-module
//
// FIRST module: audio volume
//


`timescale 10ns/100ps;

module DSP_AUDIO (
   
   //---INPUT---//
   input wire                   sys_clk,
   input wire                      BCLK,
   input wire                      LRCK,
   input wire                       rst, // rst_sync
   input wire signed [23:0]      SAMP_L, // SAMP_LEFT_RX
   input wire signed [23:0]      SAMP_R, // SAMP_RIGHT_RX
   input wire                      Plus, // Plus_sync
   input wire                     Minus, // Minus_sync
   input wire                 enable_HP,
   input wire                 enable_LP,
   input wire                 select_BC,
   input wire                 select_DS,
   
   //---OUTPUT---//
   output wire signed [23:0] SAMP_L_DSP,
   output wire signed [23:0] SAMP_R_DSP,
   output wire                LedMaxVol,
   output wire                LedMinVol
   
);
   
   ////////////////////////////
   //---Sync reset to LRCK---//
   ////////////////////////////
   
   reg rst_lrck0;
   reg rst_lrck1;
   wire rst_lrck;
   
   always @(posedge LRCK) begin
      rst_lrck0 <= rst;
	  rst_lrck1 <= rst_lrck0;
   end //always
   
   assign rst_lrck = rst_lrck1;
   
   ///////////////////////////
   //---NOISE GATE----------//
   //---FILE: NoiseGate.v---//
   ///////////////////////////
   
   wire signed [23:0] SAMP_L_NG;
   wire signed [23:0] SAMP_R_NG;
   
   NoiseGate denoiser (
      
	  .sys_clk         (sys_clk),
	  .rst                 (rst),
	  .Samp_L           (SAMP_L),
	  .Samp_R           (SAMP_R),
	  
	  .Samp_L_NG     (SAMP_L_NG),
	  .Samp_R_NG     (SAMP_R_NG)
	  
   );
   
   /////////////////////////////////////////////////////////////////////////////
   //--------------------FIR HIGH-PASS 127tap---------------------//---LEFT---//
   //--------------------IP: FIR_HP_127tap.veo--------------------//----------//
   /////////////////////////////////////////////////////////////////////////////
   
   //---S_AXIS_DATA LOGIC---//
   
   wire signed [23:0] s_axis_data_tdata_L;
   assign s_axis_data_tdata_L = SAMP_L_NG;
   
   wire s_axis_data_tready_L = 1'b1;
   
   reg lrck_sync0;
   reg lrck_sync1;
   
   always @(posedge sys_clk) begin //sync LRCK to system clock
      
      lrck_sync0 <= LRCK;
	  lrck_sync1 <= lrck_sync0;
	  
   end
   
   wire lrck_posedge = (lrck_sync0 == 1) && (lrck_sync1 == 0); // LRCK posedge detector
   
   reg s_axis_data_tvalid_L;
   
   always @(posedge sys_clk) begin // flag posedge lrck for tvalid
      if (lrck_posedge) begin
	     s_axis_data_tvalid_L <= 1'b1;
	  end else begin
	     s_axis_data_tvalid_L <= 1'b0;
	  end
   end
   
   //---M_AXIS LOGIC---//
   
   wire signed [39:0] m_axis_data_tdata_L;
   wire m_axis_data_tvalid_L;
   
   wire signed [39:0] HP_scaled_L = m_axis_data_tdata_L >>> 14; //aritmetic shifting to remove Q14
   wire signed [23:0] HP_out_24_L = HP_scaled_L[23:0]; // slicing to 24 bit from 40bit
   
   reg signed [23:0] SAMP_HP_OUT_LEFT;
   
   always @(posedge sys_clk) begin
      if (m_axis_data_tvalid_L) begin
	     SAMP_HP_OUT_LEFT <= HP_out_24_L;
	  end
   end
   
   FIR_HP_127tap inst_HP_left (
      .aresetn                              (~rst),  // input wire aresetn
      .aclk                              (sys_clk),  // input wire aclk 125MHz system clock
      .s_axis_data_tvalid   (s_axis_data_tvalid_L),  // input wire s_axis_data_tvalid
      .s_axis_data_tready   (s_axis_data_tready_L),  // output wire s_axis_data_tready
      .s_axis_data_tdata     (s_axis_data_tdata_L),  // input wire [23 : 0] s_axis_data_tdata
      .m_axis_data_tvalid   (m_axis_data_tvalid_L),  // output wire m_axis_data_tvalid
      .m_axis_data_tdata     (m_axis_data_tdata_L)   // output wire [39 : 0] m_axis_data_tdata
   );
   
   wire signed [23:0] SAMP_L_HP;
   assign SAMP_L_HP = (enable_HP) ? SAMP_HP_OUT_LEFT : SAMP_L_NG; // MUX to bypass the FIR HP
   
   //////////////////////////////////////////////////////////////////////////////
   //--------------------FIR HIGH-PASS 127tap---------------------//---RIGHT---//
   //--------------------IP: FIR_HP_127tap.veo--------------------//-----------//
   //////////////////////////////////////////////////////////////////////////////
   
   //---S_AXIS_DATA LOGIC---//
   
   wire signed [23:0] s_axis_data_tdata_R;
   assign s_axis_data_tdata_R = SAMP_R_NG;
   
   wire s_axis_data_tready_R = 1'b1;
   
   wire lrck_negedge = (lrck_sync0 == 0) && (lrck_sync1 == 1); // LRCK negedge detector
   
   reg s_axis_data_tvalid_R;
   
   always @(posedge sys_clk) begin // flag posedge lrck for tvalid
      if (lrck_negedge) begin
	     s_axis_data_tvalid_R <= 1'b1;
	  end else begin
	     s_axis_data_tvalid_R <= 1'b0;
	  end
   end
   
   //---M_AXIS LOGIC---//
   
   wire signed [39:0] m_axis_data_tdata_R;
   wire m_axis_data_tvalid_R;
   
   wire signed [39:0] HP_scaled_R = m_axis_data_tdata_R >>> 14; //aritmetic shifting to remove Q14
   wire signed [23:0] HP_out_24_R = HP_scaled_R[23:0]; // slicing to 24 bit from 40bit
   
   reg signed [23:0] SAMP_HP_OUT_RIGHT;
   
   always @(posedge sys_clk) begin
      if (m_axis_data_tvalid_R) begin
	     SAMP_HP_OUT_RIGHT <= HP_out_24_R;
	  end
   end
   
   FIR_HP_127tap inst_HP_rigut (
      .aresetn                              (~rst),  // input wire aresetn
      .aclk                              (sys_clk),  // input wire aclk 125MHz system clock
      .s_axis_data_tvalid   (s_axis_data_tvalid_R),  // input wire s_axis_data_tvalid
      .s_axis_data_tready   (s_axis_data_tready_R),  // output wire s_axis_data_tready
      .s_axis_data_tdata     (s_axis_data_tdata_R),  // input wire [23 : 0] s_axis_data_tdata
      .m_axis_data_tvalid   (m_axis_data_tvalid_R),  // output wire m_axis_data_tvalid
      .m_axis_data_tdata     (m_axis_data_tdata_R)   // output wire [39 : 0] m_axis_data_tdata
   );
   
   wire signed [23:0] SAMP_R_HP;
   assign SAMP_R_HP = (enable_HP) ? SAMP_HP_OUT_RIGHT : SAMP_R_NG; // MUX to bypass the FIR HP
   
   ////////////////////////////////////////////////////////////////
   //--------------------FIR LOW-PASS 31 tap---------------------//
   //--------------------FILE: FIR_LP_31tap.v--------------------//
   ////////////////////////////////////////////////////////////////
   
   wire signed [23:0] SAMP_L_LP;
   wire signed [23:0] SAMP_R_LP;
   wire               ValidLP_L;
   wire               ValidLP_R;
   
   //---CHANNEL LEFT---//
   
   FIR_LP_31tap FIR_LP_L (
      
	  .sys_clk                 (sys_clk),
	  .tvalid     (m_axis_data_tvalid_L),
	  .rst                         (rst),
	  .enable_LP             (enable_LP),
	  .SAMP_IN               (SAMP_L_HP),
	  
	  .SAMP_OUT_LP           (SAMP_L_LP),
	  .valid_LP              (ValidLP_L)
	  
   );
   
   //---CHANNEL RIGHT---//
   
   FIR_LP_31tap FIR_LP_R (
      
	  .sys_clk                 (sys_clk),
	  .tvalid     (m_axis_data_tvalid_R),
	  .rst                         (rst),
	  .enable_LP             (enable_LP),
	  .SAMP_IN               (SAMP_R_HP),
	  
	  .SAMP_OUT_LP           (SAMP_R_LP),
	  .valid_LP              (ValidLP_R)
	  
   );
   
   ////////////////////////////
   //---BIT CRUSHER----------//
   //---FILE: BitCrusher.v---//
   ////////////////////////////
   
   wire               ValidBC_L;
   wire               ValidBC_R;
   wire signed [23:0] SAMP_L_BC;
   wire signed [23:0] SAMP_R_BC;
   
   BitCrusher Bit_destroyer (
   
      .sys_clk          (sys_clk),
	  .rst                  (rst),
	  .select         (select_BC),
	  .Samp_L         (SAMP_L_LP),
	  .Samp_R         (SAMP_R_LP),
	  .Samp_Valid_L   (ValidLP_L),
	  .Samp_Valid_R   (ValidLP_R),
	  
	  .Crushed_L      (SAMP_L_BC),
	  .Crushed_R      (SAMP_R_BC),
	  .ValidBC_L      (ValidBC_L),
	  .ValidBC_R      (ValidBC_R)
	  
   );
   
   ////////////////////////////
   //---DOWNSAMPLER----------//
   //---FILE:DownSampler.v---//
   ////////////////////////////
   
   wire signed [23:0] SAMP_L_DS;
   wire signed [23:0] SAMP_R_DS;
   wire               ValidDS_L;
   wire               ValidDS_R;
   
   DownSampler DS_module (
      
	  .sys_clk       (sys_clk),
	  .rst               (rst),
	  .Valid_L     (ValidBC_L),
	  .Valid_R     (ValidBC_R),
	  .select      (select_DS),
	  .Samp_L      (SAMP_L_BC),
	  .Samp_R      (SAMP_R_BC),
	  
	  .ValidDS_L   (ValidDS_L),
	  .ValidDS_R   (ValidDS_R),
	  .Samp_L_DS   (SAMP_L_DS),
	  .Samp_R_DS   (SAMP_R_DS)
	  
	  );
      
   
   /////////////////////////////////
   //---VOLUME MODULATOR----------//
   //---FILE: VolumeModulator.v---//
   /////////////////////////////////
   
   wire signed [23:0] SAMP_VOL_L;
   wire signed [23:0] SAMP_VOL_R;
   
   VolumeModulator Volume_module (
   
      .Samp_IN_L      (SAMP_L_DS),
	  .Samp_IN_R      (SAMP_R_DS),
	  .BCLK                (BCLK),
	  .Plus                (Plus),
	  .Minus              (Minus),
	  .rst                  (rst),
	  
	  .Samp_OUT_L    (SAMP_VOL_L),
	  .Samp_OUT_R    (SAMP_VOL_R),
	  .LED_MAX_OUT    (LedMaxVol),
	  .LED_MIN_OUT    (LedMinVol)
	  
   );
   
   assign SAMP_L_DSP = SAMP_VOL_L;
   assign SAMP_R_DSP = SAMP_VOL_R;
   
endmodule
