`timescale 1ns/1ps
 
module tb_BitCrusher;
 
//-------------------------
// INPUTS
//-------------------------
 
reg sys_clk;
reg rst;
reg select;
 
reg signed [23:0] Samp_L;
reg signed [23:0] Samp_R;
 
reg Samp_Valid_L;
reg Samp_Valid_R;
 
//-------------------------
// OUTPUTS
//-------------------------
 
wire signed [23:0] Crushed_L;
wire signed [23:0] Crushed_R;
 
wire ValidBC_L;
wire ValidBC_R;
 
//-------------------------
// DUT
//-------------------------
 
BitCrusher DUT (
 
.sys_clk (sys_clk),
.rst (rst),
.select (select),
 
.Samp_L (Samp_L),
.Samp_R (Samp_R),
 
.Samp_Valid_L (Samp_Valid_L),
.Samp_Valid_R (Samp_Valid_R),
 
.Crushed_L (Crushed_L),
.Crushed_R (Crushed_R),
 
.ValidBC_L (ValidBC_L),
.ValidBC_R (ValidBC_R)
 
);
 
//-------------------------
// CLOCK 100 MHz
//-------------------------
 
initial begin
sys_clk = 1'b0;
forever #5 sys_clk = ~sys_clk;
end
 
//-------------------------
// MONITOR
//-------------------------
 
initial begin
 
$monitor(
"T=%0t MODE=%b IN_L=%h OUT_L=%h VALID=%b",
$time,
DUT.mode,
Samp_L,
Crushed_L,
ValidBC_L
);
 
end
 
//-------------------------
// TEST
//-------------------------
 
initial begin
 
//----------------------
// INIT
//----------------------
 
rst = 1'b1;
select = 1'b0;
 
Samp_L = 24'h123456;
Samp_R = 24'h654321;
 
Samp_Valid_L = 1'b1;
Samp_Valid_R = 1'b1;
 
//----------------------
// RESET
//----------------------
 
#50;
rst = 1'b0;
 
#20;
 
//----------------------
// MODE 00
// 24 bit
//----------------------
 
$display("\nMODE 00 -> 24 BIT");
 
#40;
 
//----------------------
// MODE 01
// 16 bit
//----------------------
 
$display("\nMODE 01 -> 16 BIT");
 
select = 1'b1;
#10;
select = 1'b0;
 
#40;
 
//----------------------
// MODE 10
// 12 bit
//----------------------
 
$display("\nMODE 10 -> 12 BIT");
 
select = 1'b1;
#10;
select = 1'b0;
 
#40;
 
//----------------------
// MODE 11
// 8 bit
//----------------------
 
$display("\nMODE 11 -> 8 BIT");
 
select = 1'b1;
#10;
select = 1'b0;
 
#40;
 
//----------------------
// MODE 00
// ritorno 24 bit
//----------------------
 
$display("\nMODE 00 -> 24 BIT");
 
select = 1'b1;
#10;
select = 1'b0;
 
#40;
 
//----------------------
// Test valore negativo
//----------------------
 
$display("\nTEST NEGATIVE SAMPLE");
 
Samp_L = -24'sd123456;
Samp_R = -24'sd654321;
 
#50;
 
//----------------------
// Fine simulazione
//----------------------
 
$stop;
 
end
 
endmodule