
// SUBMODULE: BitCrusher
//
// RELATIVE MODULE: DSP_AUDIO
//
// FUNCTION: this bit crusher will crush (sending to 0) a choosable number of LSB, making the sound more retro
//           as a game boy; this module could be activate saparatly form other module and cuold be coupled with
//           a regolable DownSampler to maximize the retro effect.
//
// TO DO:
//
//


module BitCrusher (
   
   //---INPUT---//
   input wire                    sys_clk,
   input wire                        rst,
   input wire                     select,
   input wire signed [23:0]       Samp_L,
   input wire signed [23:0]       Samp_R,
   input wire               Samp_Valid_L,
   input wire               Samp_Valid_R,
   
   //---OUTPUT---//
   output wire signed [23:0]   Crushed_L,
   output wire signed [23:0]   Crushed_R,
   output wire                 ValidBC_L,
   output wire                 ValidBC_R
   
);

   ///////////////////////////////////
   //---EDGE DETECTOR for select---///
   ///////////////////////////////////
   
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

   ////////////////////////
   //---mode selection---//   how many bits do u want to crush?
   ////////////////////////

   reg [1:0] mode;
   
   always @(posedge sys_clk or posedge rst) begin
      
      if (rst) begin
	  
	     mode <= 2'b00;
		 
	  end else if (select_edge) begin
	     
	     mode <= mode + 2'b01;
	     
	  end//else if select
	  
   end// always

   //////////////////////
   //---BIT CRUSHING---//
   //////////////////////
   
   reg signed [23:0] crushed_l;
   reg signed [23:0] crushed_r;
   
   always @(*) begin
      
	  case(mode)
	  
	     2'b00: begin          // NO BIT CRUSHING
		    crushed_l = Samp_L;
			crushed_r = Samp_R;
		 end
		 
		 2'b01: begin          // OUTPUT 12 bit
		    crushed_l = {Samp_L[23:12], 12'd0};
			crushed_r = {Samp_R[23:12], 12'd0};
		 end
		 
		 2'b10: begin          // OUTPUT 8 bit
		    crushed_l = {Samp_L[23:16], 16'd0};
			crushed_r = {Samp_R[23:16], 16'd0};
		 end
		 
		 2'b11: begin          // OUTPUT 4 bit
		    crushed_l = {Samp_L[23:20], 20'd0};
			crushed_r = {Samp_R[23:20], 20'd0};
			//crushed_l = 24'd0;
			//crushed_r = 24'd0;
		 end
		 
	  endcase
	  
   end// always
   
   assign Crushed_L = crushed_l;
   assign Crushed_R = crushed_r;
   
   assign ValidBC_L = Samp_Valid_L;
   assign ValidBC_R = Samp_Valid_R;
   
endmodule