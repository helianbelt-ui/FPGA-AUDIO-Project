
// SUBMODULE: FIR_LP_7tap
//
// RELATIVE MODULE: DSP_AUDIO
//
// FUNCTION: Filtro FIR passa basso a 7 tap per ottenere un cutoff a circa 6800 Hz; 
//           costruito per simmetria dei coefficienti di peso del filtro;
//           coefficienti normalizzati a 1 e destritti da reg 16 bit format Q14;
//           segue slicer con saturazione per tornare ai 24 bit iniziali.
//
// TO DO:
//
//

`timescale 1ns/100ps;

module FIR_LP_7tap (
   
   //---INPUT---//
   input wire                     LRCK,
   input wire                      rst,
   input wire                enable_LP,
   input wire signed [23:0]     SAMP_L,
   input wire signed [23:0]     SAMP_R,
   //---OUTPUT---//
   output wire signed [23:0] SAMP_L_LP,
   output wire signed [23:0] SAMP_R_LP
   
   );
   
   /////////////////////////
   //---DEF PESI FILTRO---//
   /////////////////////////
   
   reg signed [15:0] h [0:6];
   
   initial begin
       h[0] = 16'sd819;
       h[1] = 16'sd1638;
       h[2] = 16'sd3277;
       h[3] = 16'sd4915;
       h[4] = 16'sd3277;
       h[5] = 16'sd1638;
       h[6] = 16'sd819;
   end
   
   /////////////////////////////////////
   //---SHIFT REGISTER CHANNEL LEFT---//
   /////////////////////////////////////
   
   reg signed [23:0] xl [0:6];
   
   integer i;
   
   always @(posedge LRCK or posedge rst) begin
      
	  if (rst) begin
	     xl[0] <= 24'sd0;
         xl[1] <= 24'sd0;
         xl[2] <= 24'sd0;
         xl[3] <= 24'sd0;
         xl[4] <= 24'sd0;
         xl[5] <= 24'sd0;
         xl[6] <= 24'sd0;
	  end //rst
	  else begin
	     xl[0] <= SAMP_L;
		 xl[1] <= xl[0];
		 xl[2] <= xl[1];
		 xl[3] <= xl[2];
		 xl[4] <= xl[3];
		 xl[5] <= xl[4];
		 xl[6] <= xl[5];
	  end //else
	  
   end // always posedge lrck or rst
   
   //////////////////////////////////////
   //---SHIFT REGISTER CHANNEL RIGHT---//
   //////////////////////////////////////
   
   reg signed [23:0] xr [0:6];
   
   always @(negedge LRCK or posedge rst) begin
      
	  if (rst) begin
	     xr[0] <= 24'sd0;
         xr[1] <= 24'sd0;
         xr[2] <= 24'sd0;
         xr[3] <= 24'sd0;
         xr[4] <= 24'sd0;
         xr[5] <= 24'sd0;
         xr[6] <= 24'sd0;
	  end //rst
	  else begin
	     xr[0] <= SAMP_R;
		 xr[1] <= xr[0];
		 xr[2] <= xr[1];
		 xr[3] <= xr[2];
		 xr[4] <= xr[3];
		 xr[5] <= xr[4];
		 xr[6] <= xr[5];
	  end //else
	  
   end // always negedge lrck or rst
   
   
   ////////////////////////
   //---MOLT.PESI LEFT---//
   ////////////////////////
   
   wire signed [39:0] pl [0:6];
   
   genvar k;
   
   generate
      for (k=0; k<7; k=k+1) begin
	     assign pl[k] = xl[k] * h[k];
	  end //for
   endgenerate
   
   /////////////////////////
   //---MOLT.PESI RIGHT---//
   /////////////////////////
   
   wire signed [39:0] pr [0:6];
   
   genvar j;
   
   generate
      for (j=0; j<7; j=j+1) begin
	     assign pr[j] = xr[j] * h[j];
	  end //for
   endgenerate
   
   
   ///////////////////////////////
   //---SOMMA PROD FILTRO L/R---//
   ///////////////////////////////
   
   wire signed [39:0] acc_l;
   
   assign acc_l =
          pl[0] +
		  pl[1] +
		  pl[2] +
		  pl[3] +
		  pl[4] +
		  pl[5] +
		  pl[6];
   
   
   wire signed [39:0] acc_r;
   
   assign acc_r =
          pr[0] +
		  pr[1] +
		  pr[2] +
		  pr[3] +
		  pr[4] +
		  pr[5] +
		  pr[6];
   
   
   //////////////////////////////////////
   //---SLICING 40->24, Q14->Q0, L/R---//
   //////////////////////////////////////
   
   wire signed [23:0] y_l_raw = acc_l[37:14];
   wire signed [23:0] y_r_raw = acc_r[37:14];
   
   ////////////////////////////////
   //---OVERFLOW DETECTION L/R---//
   ////////////////////////////////
   
   wire ovf_pos_l = (acc_l[39:38] == 2'b01);
   wire ovf_neg_l = (acc_l[39:38] == 2'b10);
   
   wire ovf_pos_r = (acc_r[39:38] == 2'b01);
   wire ovf_neg_r = (acc_r[39:38] == 2'b10);
   
   //////////////////////////////
   //---CLAMP FOR SATURATION---//
   //////////////////////////////
   
   localparam signed [23:0] MAX24 = 24'sh7FFFFF;
   localparam signed [23:0] MIN24 = 24'sh800000;
   
   wire signed [23:0] y_l_sat =
    ovf_pos_l ? MAX24 :
    ovf_neg_l ? MIN24 :
               y_l_raw;
   
   wire signed [23:0] y_r_sat =
    ovf_pos_r ? MAX24 :
    ovf_neg_r ? MIN24 :
               y_r_raw;
   
   ////////////////////////
   //---MUX FOR ENABLE---//
   ////////////////////////
   
   assign SAMP_L_LP = enable_LP ? y_l_sat : SAMP_L;
   assign SAMP_R_LP = enable_LP ? y_r_sat : SAMP_R;
   
endmodule