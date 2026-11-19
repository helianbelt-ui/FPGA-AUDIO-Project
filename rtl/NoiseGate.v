//
// SUBMODULE: NoiseGate
//
// RELATIVE MODULE: DSP_AUDIO
//
// FUNCTION: this module put a double trheshhold with an HYSTERESIS cicle of open/closed gate to remove
//           noise near 0V to avoid noisy sound dued to the strong quantizzation added by the bitcrusher
//
// TO DO:
//
//

module NoiseGate (
   
   //---INPUT---//
   input wire                    sys_clk,
   input wire                        rst,
   input wire signed [23:0]       Samp_L,
   input wire signed [23:0]       Samp_R,
   //---OUTPUT---//

   output wire signed [23:0]   Samp_L_NG,
   output wire signed [23:0]   Samp_R_NG
   
   );
   
   localparam signed [23:0] TH_ON  = 24'sd3000;
   localparam signed [23:0] TH_OFF = 24'sd1500;
   
   reg gate_l;
   reg gate_r;
   
   always @(posedge sys_clk or posedge rst) begin
      
	  if (rst) begin
	     
		 gate_l <= 1'b0;
		 gate_r <= 1'b0;
		 
	  end //if rst
	  
	  else begin
	     
		 //---LEFT CH---//
		 if (!gate_l) begin
		    
			if ( (Samp_L > TH_ON) || (Samp_L < -TH_ON) )   gate_l <= 1'b1;
		    
		 end else begin
		    
			if ( (Samp_L < TH_OFF) && (Samp_L > -TH_OFF) ) gate_l <= 1'b0;
		 end
		 
		 //---RIGHT CH---//
		 if (!gate_r) begin
		    
			if ( (Samp_R > TH_ON) || (Samp_R < -TH_ON) )   gate_r <= 1'b1;
		    
		 end else begin
		    
			if ( (Samp_R < TH_OFF) && (Samp_R > -TH_OFF) ) gate_r <= 1'b0;
		 end
		 
	  end //else
	  
   end //always
   
   assign Samp_L_NG = gate_l ? Samp_L : 24'sd0;
   assign Samp_R_NG = gate_r ? Samp_R : 24'sd0;
   
   
endmodule