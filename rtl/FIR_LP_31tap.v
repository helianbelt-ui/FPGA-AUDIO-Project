
// SUBMODULE: FIR_LP_31tap
//
// RELATIVE MODULE: DSP_AUDIO
//
// FUNCTION: Filtro FIR passa basso a 31 tap per ottenere un cutoff a circa 6800 Hz; 
//           costruito per simmetria dei coefficienti di peso del filtro;
//           coefficienti normalizzati a 1 e destritti da reg 16 bit format Q14;
//           segue slicer con saturazione per tornare ai 24 bit iniziali.
//
// TO DO:
//
//

`timescale 1ns/100ps;

module FIR_LP_31tap (
   
   //---INPUT---//
   input wire                      sys_clk,
   input wire                       tvalid,
   input wire                          rst,
   input wire                    enable_LP,
   input wire signed [23:0]        SAMP_IN,
   
   //---OUTPUT---//
   output wire signed [23:0]   SAMP_OUT_LP,
   output wire                    valid_LP
   
   );
   
   /////////////////////////
   //---DEF PESI FILTRO---//
   /////////////////////////
   
   reg signed [15:0] h [0:30];
   
   initial begin
      h[0]  = 16'sd   14;
      h[1]  = 16'sd   27;
      h[2]  = 16'sd   55;
      h[3]  = 16'sd   99;
      h[4]  = 16'sd  162;
      h[5]  = 16'sd  244;
      h[6]  = 16'sd  346;
      h[7]  = 16'sd  462;
      h[8]  = 16'sd  590;
      h[9]  = 16'sd  720;
      h[10] = 16'sd  844;
      h[11] = 16'sd  954;
      h[12] = 16'sd 1037;
      h[13] = 16'sd 1088;
      h[14] = 16'sd 1097;
      h[15] = 16'sd 1088;   // centro
      h[16] = 16'sd 1097;
      h[17] = 16'sd 1088;
      h[18] = 16'sd 1037;
      h[19] = 16'sd  954;
      h[20] = 16'sd  844;
      h[21] = 16'sd  720;
      h[22] = 16'sd  590;
      h[23] = 16'sd  462;
      h[24] = 16'sd  346;
      h[25] = 16'sd  244;
      h[26] = 16'sd  162;
      h[27] = 16'sd   99;
      h[28] = 16'sd   55;
      h[29] = 16'sd   27;
      h[30] = 16'sd   14;
   end
   
   ////////////////////////////////
   //---SHIFT REGISTER CHANNEL---//
   ////////////////////////////////
   
   reg signed [23:0] xl [0:30];
   reg             SampleValid;
   
   integer i;
   
   always @(posedge sys_clk or posedge rst) begin
      
	  if (rst) begin
	  
	     for(i=0; i<31; i=i+1) xl[i] <= 24'sd0;
		 SampleValid <= 1'b0;
	  
	  end //rst
	  
	  else begin
	     
	     SampleValid <= tvalid;
		 
	     if (tvalid) begin
	  
	        xl[0] <= SAMP_IN;
		    for (i=1; i<31; i=i+1) xl[i] <= xl[i-1];
			
		 end//if
		 
	  end //else
	  
   end // always posedge lrck or rst
   
   
   ///////////////////
   //---MOLT.PESI---//  da aggiungere registro post moltiplicazione
   ///////////////////
   
   wire signed [39:0] pl [0:30];
   genvar k;
   
   generate
      for (k=0; k<31; k=k+1) begin
	     assign pl[k] = xl[k] * h[k];
	  end //for
   endgenerate
   
   //---registro per stadio intermedio pre adder--//
   
   reg signed [39:0] pl_reg [0:30];
   reg               valid_pre_add;
   integer jj;
   
   always @(posedge sys_clk) begin
   
      if (rst) begin
      
         valid_pre_add <= 1'b0;
         for (jj=0; jj<31; jj=jj+1) pl_reg[jj] <= 40'sd0;
      end//if
      else begin
         
         valid_pre_add <= SampleValid;
         for (jj=0; jj<31; jj=jj+1) pl_reg[jj] <= pl[jj];
         
      end//else
   
   end // always
   
   
   /////////////////////////////////////
   //---SOMMA: ADDER TREE 5 LIVELLI---//
   /////////////////////////////////////
   
   //---1st level---//
   
   wire signed [40:0] sl [0:15];
   genvar l_0;
   
   generate
      for (l_0=0; l_0<15; l_0=l_0+1) begin
         assign sl[l_0] = pl_reg[2*l_0] + pl_reg[2*l_0+1];
      end //for
   endgenerate
   
   assign sl[15] = pl_reg[30];
   
   //---1st stage reg---//
   
   reg signed [40:0] sl_reg [0:15];
   reg                   validL_s1;
   
   integer i_0;
   
   always @(posedge sys_clk) begin
      
      if (rst) begin
         
         validL_s1 <= 1'b0;
         for (i_0=0; i_0<16; i_0=i_0+1) sl_reg[i_0] <= 41'sd0;
         
      end //if rst
      else begin
         
         validL_s1 <= valid_pre_add;
         for (i_0=0; i_0<16; i_0=i_0+1) sl_reg[i_0] <= sl[i_0];
         
      end//else
      
   end //always
   
   //---2nd level---//
   
   wire signed [41:0] tl [0:7];
   genvar l_1;
   
   generate
      for (l_1=0; l_1<8; l_1=l_1+1) begin
         assign tl[l_1] = sl_reg[2*l_1] + sl_reg[2*l_1+1];
      end//for
   endgenerate
   
   //---2nd stage reg---//
   
   reg signed [41:0] tl_reg [0:7];
   reg                  validL_s2;
   
   integer i_1;
   
   always @(posedge sys_clk) begin
      
      if (rst) begin
         
         validL_s2 <= 1'b0;
         for (i_1=0; i_1 <8; i_1=i_1+1) tl_reg[i_1] <= 42'sd0;
         
      end //if rst
      else begin
         
         validL_s2 <= validL_s1;
         for (i_1=0; i_1 <8; i_1=i_1+1) tl_reg[i_1] <= tl[i_1];
         
      end //else
      
   end //always
   
   //---3th level---//
   
   wire signed [42:0] ul [0:3];
   genvar l_2;
   
   generate
      for (l_2=0; l_2<4; l_2=l_2+1) begin
         assign ul[l_2] = tl_reg[2*l_2] +tl_reg[2*l_2+1];
      end//for
   endgenerate
   
   //---3th stage reg---//
   
   reg signed [42:0] ul_reg [0:3];
   reg                  validL_s3;
   
   integer i_2;
   
   always @(posedge sys_clk) begin
      
      if (rst) begin
         
         validL_s3 <= 1'b0;
         for (i_2=0; i_2 <4; i_2=i_2+1) ul_reg[i_2] <= 43'sd0;
         
      end//is rst
      else begin
         
         validL_s3 <= validL_s2;
         for (i_2=0; i_2 <4; i_2=i_2+1) ul_reg[i_2] <= ul[i_2];
         
      end//else
      
   end//always
   
   //---4th level---//
   
   wire signed [43:0] vl [0:1];
   genvar l_3;
   
   generate
      for (l_3=0; l_3<2; l_3=l_3+1) begin
         assign vl[l_3] = ul_reg[2*l_3] +ul_reg[2*l_3+1];
      end//for
   endgenerate
   
   //---4th stage reg---//
   
   reg signed [43:0] vl_reg [0:1];
   reg                  validL_s4;
   
   integer i_3;
   
   always @(posedge sys_clk) begin
      
      if (rst) begin
         
         validL_s4 <= 1'b0;
         for (i_3=0; i_3 <2; i_3=i_3+1) vl_reg[i_3] <= 44'sd0;
         
      end//is rst
      else begin
         
         validL_s4 <= validL_s3;
         for (i_3=0; i_3 <2; i_3=i_3+1) vl_reg[i_3] <= vl[i_3];
         
      end//else
      
   end//always
   
   //---5th level---//
   
   wire signed [44:0] zl;
   assign zl = vl_reg[0] + vl_reg[1];
   
   //---5th stage reg--//
   
   reg signed [44:0]    zl_reg;
   reg               validL_s5;
   
   always @(posedge sys_clk) begin
      
      if (rst) begin
         
         validL_s5 <=   1'b0;
         zl_reg    <= 45'sd0;
         
      end
      else begin
         
         validL_s5 <= validL_s4;
         zl_reg    <=        zl;
         
      end //else
      
   end //always
   
   
   /////////////////////////////////
   //---SLICING 40->24, Q14->Q0---//
   /////////////////////////////////
   
   wire signed [23:0] y_l_raw = zl_reg[37:14];
   
   ////////////////////////////
   //---OVERFLOW DETECTION---// zl_reg è [44:0] (45bit) quello di segno è zl_reg[37]
   ////////////////////////////
   
   wire ovf_pos_l = (zl_reg[37] == 1'b0) && (|zl_reg[44:38] == 1'b1); // zl=0 positivo ma se 1 in [44:38] è 1 allora overflow positivo
   wire ovf_neg_l = (zl_reg[37] == 1'b1) && (~(&zl_reg[44:38])); // zl=1 negativo ma se c'è 0 in [44:38] allora undeflow
   
   
   //////////////////////////////
   //---CLAMP FOR SATURATION---//
   //////////////////////////////
   
   localparam signed [23:0] MAX24 = 24'sh7FFFFF;
   localparam signed [23:0] MIN24 = 24'sh800000;
   
   wire signed [23:0] y_l_sat = ovf_pos_l ? MAX24 : ovf_neg_l ? MIN24 : y_l_raw;
   
   ////////////////////////
   //---MUX FOR ENABLE---//
   ////////////////////////
   
   assign SAMP_OUT_LP   = enable_LP ? y_l_sat : SAMP_IN;
   assign valid_LP      =                     validL_s5;
   
endmodule