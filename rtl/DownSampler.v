//
// SUBMODULE: DownSampler
//
// RELATIVE MODULE: DSP_AUDIO
//
// FUNCTION: this module coupled with the BitCrusher module create a real digital BITCRUSHER,
//           this module divide the sample rate by a choosable number, this'll create a LO-FI/ old console sound.
//
// TO DO: 1) creare direttamente un blocco di downsampling regolabile in 3/4 modalità; 24 kHz, 12 kHz e
//        2) inserire se serve un LPF comune di circa 5 kHz; cinsidero
//        3) SDOPPIARE LOGICA CANALE L E R SAPARATE
//
//

module DownSampler (
   
   //---INPUT---//
   input wire                    sys_clk,
   input wire                        rst,
   input wire                    Valid_L,
   input wire                    Valid_R,
   input wire                     select,
   input wire signed [23:0]       Samp_L,
   input wire signed [23:0]       Samp_R,
   //---OUTPUT---//
   output wire                 ValidDS_L,
   output wire                 ValidDS_R,
   output wire signed [23:0]   Samp_L_DS,
   output wire signed [23:0]   Samp_R_DS
   
   );
    
   ////////////////////////
   //---MODE SELECTION---//
   ////////////////////////
   
   //---EDGE DETECTOR for select---///
   
   reg       select_d;
   wire   select_edge;
   
   always @(posedge sys_clk or posedge rst) begin
      
	  if (rst) begin
	     
	     select_d <= 1'b0;
	     
	  end else begin
	     
	     select_d <= select;
		 
	  end
	  
   end// always 
   
   assign select_edge = select & ~select_d;
   
   
   //---MODE SELECTION---//
   
   reg [1:0] mode = 2'b00;
   
   always @(posedge sys_clk or posedge rst) begin
      
	  if (rst) begin
	  
	     mode <= 2'b00;
	  
	  end
	  
	  else if(select_edge) begin
	     
		 mode <= mode + 2'b01;
		 
	  end
	  
   end // mode selection
   
   ///////////////////////////
   //---DECIMATION by S&H---//
   ///////////////////////////
   
   //---EDGE DETECTOR FOR VALID signal---//
   //
   //reg     Valid_L_d;
   //wire Valid_L_edge;
   //
   //always @(posedge sys_clk) begin
   //   
   //   Valid_L_d <= Valid_L;
   //  
   //end

   //assign Valid_L_edge = Valid_L & ~Valid_L_d;
   
   //---DECIMATION DIVIDER---//
   
   reg [3:0] M;
   
   always @(*) begin
      
	  case (mode)
	     
		 2'b00:   M =   4'd1; //no DS 96 kHz
		 2'b01:   M =   4'd4; // 24kHz
		 2'b10:   M =   4'd8; // 12kHz
		 2'b11:   M =  4'd12; // 8kHz
		 default: M =   4'd1;
		 
	  endcase
	  
   end // always
   
   reg        [3:0]       count_L;
   reg signed [23:0] HeldSample_L;
   
   reg signed [23:0] HeldSample_R;
   reg        [3:0]       count_R;
   
   always @(posedge sys_clk or posedge rst) begin
      
	  if (rst) begin
	     
		 count_L      <=   4'd0;
         count_R      <=   4'd0;
		 HeldSample_L <= 24'sd0;
		 HeldSample_R <= 24'sd0;
		 
	  end //if rst
	  
	  else begin
	     
		 if (Valid_L) begin
		    
			if (count_L == M-1) begin
			   
			   HeldSample_L <= Samp_L;
			   count_L      <=   4'd0;
			   
			end else begin
			   
			   count_L <= count_L + 1;
			   
			end
		 end // Valid_L

		 if (Valid_R) begin
		    
			if (count_R == M-1) begin
			   
			   HeldSample_R <= Samp_R;
			   count_R      <=   4'd0;
			   
			end else begin
			   
			   count_R <= count_R + 1;
			   
			end
		 end // Valid_R
		 
		 
	  end//else
   
   end
   
   //---DEBUG BYPASS---//
   
   //assign Samp_L_DS = Samp_L;
   //assign Samp_R_DS = Samp_R;
   
   //---OUTPUT---//
   
   assign Samp_L_DS = HeldSample_L;
   assign Samp_R_DS = HeldSample_R;
   
   
   assign ValidDS_L = Valid_L;
   assign ValidDS_R = Valid_R;
   
endmodule