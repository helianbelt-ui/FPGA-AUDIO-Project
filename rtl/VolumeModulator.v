
// SUBMODULE: VolumeModulator
//
// RELATIVE MODULE: DSP_AUDIO
//
// FUNCTION: usando 2 pulsanti si seleziona il VOLUME_VALUE da 0 a 10,
//           a ogni VOLUME_VALUE corrisponde un GAIN_VALUE che moltiplichera il segnale;
//           tale moltiplicazione sarà in Q format 24 X 16 = 40; seguono slicing e
//           saturazione per evitare wrap around da overflow
//
// TO DO:-aggiungere dither tpdf; (se serve dopo filtri dsp)
//        -sostituire slicer con rounder; (se serve dopo filtri dsp)

module VolumeModulator (
   
   //---INPUT---//
   input wire signed [23:0]   Samp_IN_L,
   input wire signed [23:0]   Samp_IN_R,
   input wire                      BCLK,
   input wire                      Plus,
   input wire                     Minus,
   input wire                       rst,
   
   //---OUTPUT---//
   output wire signed [23:0] Samp_OUT_L,
   output wire signed [23:0] Samp_OUT_R,
   output wire              LED_MAX_OUT,
   output wire              LED_MIN_OUT
   
   );
   
   ////////////////////////////////////////
   //---EDGE DETECTOR per plus e minus---//
   ////////////////////////////////////////
   
   reg          Plus_d;
   reg         Minus_d;
   wire      Plus_edge;
   wire     Minus_edge;
   
   always @(posedge BCLK or posedge rst) begin
      
	  if (rst) begin
	     
		 Plus_d  <= 1'b0;
		 Minus_d <= 1'b0;
		 
	  end // if rst
	  
	  else begin
	     
         Plus_d  <= Plus;
	     Minus_d <= Minus;
	     
	  end // else
	  
   end //always
   
   assign Plus_edge  = Plus  &  ~Plus_d;
   assign Minus_edge = Minus & ~Minus_d;
   
   ////////////////////////////////////
   //---COUNTER for GAIN selection---//
   ////////////////////////////////////
   
   localparam rst_count = 4'd7;
   reg [3:0]             count;
   reg             LED_MAX_VOL;
   reg             LED_MIN_VOL;
   
   always @(posedge BCLK) begin
      
	  if (rst) begin
	     
		 count <= rst_count;
		 LED_MAX_VOL <= 1'b0;
		 LED_MIN_VOL <= 1'b0;
		 
	  end // if rst
	  
	  else if (count < 10 && Plus_edge) begin
	     
		 count <= count + 1;
		 
	  end
	  
	  else if (count > 0 && Minus_edge) begin
	     
	     count <= count - 1;
		 
	  end
	  
	  if (count == 10 || count == 7) begin
	     LED_MAX_VOL <= 1'b1;
	  end else begin
	     LED_MAX_VOL <= 1'b0;
	  end
	  
	  if (count == 0  || count == 7) begin
	     LED_MIN_VOL <= 1'b1;
	  end else begin
	     LED_MIN_VOL <= 1'b0;
	  end
	  
   end //always
   
   assign LED_MAX_OUT = LED_MAX_VOL;
   assign LED_MIN_OUT = LED_MIN_VOL;
   
   ///////////////////////
   //---GAIN SELECTOR---//
   ///////////////////////
   
   reg signed [15:0] GAIN;
   
   always @(*) begin
      
	  case(count)
	     
	     0: GAIN = 16'h0010; // -60 dB  ≈ 0.001
		 1: GAIN = 16'h0206; // -30 dB  ≈ 0.0316
		 2: GAIN = 16'h040A; // -24 dB  ≈ 0.063
		 3: GAIN = 16'h080D; // -18 dB  ≈ 0.126
		 4: GAIN = 16'h1012; // -12 dB  ≈ 0.251
		 5: GAIN = 16'h197B; //  -8 dB  ≈ 0.398
		 6: GAIN = 16'h287D; //  -4 dB  ≈ 0.631
		 7: GAIN = 16'h4000; //   0 dB  = 1.0×
		 8: GAIN = 16'h4800; //  +1 dB  ≈ 1.122
		 9: GAIN = 16'h656E; //  +4 dB  ≈ 1.5849
		 10:GAIN = 16'h7F8D; //  +6 dB  ≈ 1.9953
		 
		 default: GAIN = 16'h4000;
		 
	  endcase
	  
   end // always
   
   //////////////////////////////////////
   //---MOLTIPLICATORE sample x gain---//
   //////////////////////////////////////
   
   wire signed [39:0] Mult_result_L;
   wire signed [39:0] Mult_result_R;
   
   assign Mult_result_L = Samp_IN_L * GAIN;
   assign Mult_result_R = Samp_IN_R * GAIN;
   
   ////////////////
   //---SLICER---// --- remuved; rounded is better
   ////////////////
   
   wire signed [23:0] Sliced_L;
   wire signed [23:0] Sliced_R;
   
   assign Sliced_L = Mult_result_L[37:14];
   assign Sliced_R = Mult_result_R[37:14];
   
   ////////////////////
   //---SATURATION---//
   ////////////////////
   
   localparam signed [23:0] MAX_POS = 24'sh7FFFFF;
   localparam signed [23:0] MIN_NEG = 24'sh800000;
   
   wire Overflow_L;
   wire Overflow_R;
   
   assign Overflow_L = (Mult_result_L[39] != Mult_result_L[38]);
   assign Overflow_R = (Mult_result_R[39] != Mult_result_R[38]);
   
   assign Samp_OUT_L = (Overflow_L) ? (Mult_result_L[39] == 1'b0 ? MAX_POS : MIN_NEG) : Sliced_L;
   assign Samp_OUT_R = (Overflow_R) ? (Mult_result_R[39] == 1'b0 ? MAX_POS : MIN_NEG) : Sliced_R;
   


endmodule