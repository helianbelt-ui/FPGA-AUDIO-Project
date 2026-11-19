
//---TESTBENCH for NoiseGate module

`timescale 1ns/1ps

module tb_NoiseGate;

    reg sys_clk;
    reg rst;

    reg signed [23:0] Samp_L;
    reg signed [23:0] Samp_R;
    reg Valid_L;
    reg Valid_R;

    wire ValidNG_L;
    wire ValidNG_R;
    wire signed [23:0] Samp_L_NG;
    wire signed [23:0] Samp_R_NG;

    // DUT
    NoiseGate DUT (
        .sys_clk(sys_clk),
        .rst(rst),
        .Samp_L(Samp_L),
        .Samp_R(Samp_R),
        .Valid_L(Valid_L),
        .Valid_R(Valid_R),
        .ValidNG_L(ValidNG_L),
        .ValidNG_R(ValidNG_R),
        .Samp_L_NG(Samp_L_NG),
        .Samp_R_NG(Samp_R_NG)
    );

    //-------------------------------------------------
    // Clock 100 MHz
    //-------------------------------------------------
    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk;
    end

    //-------------------------------------------------
    // Stimuli
    //-------------------------------------------------
    initial begin

        rst     = 1'b1;
        Samp_L  = 24'sd0;
        Samp_R  = 24'sd0;
        Valid_L = 1'b1;
        Valid_R = 1'b1;

        #20;
        rst = 1'b0;

        //-------------------------------------------------
        // Gate chiuso
        //-------------------------------------------------
        @(posedge sys_clk);
        Samp_L <= 24'sd1000;
        Samp_R <= 24'sd1000;

        repeat(3) @(posedge sys_clk);

        //-------------------------------------------------
        // Sopra TH_ON = 3000 -> apre
        //-------------------------------------------------
        Samp_L <= 24'sd4000;
        Samp_R <= 24'sd4000;

        repeat(3) @(posedge sys_clk);

        //-------------------------------------------------
        // Tra TH_OFF e TH_ON -> deve restare aperto
        //-------------------------------------------------
        Samp_L <= 24'sd2000;
        Samp_R <= 24'sd2000;

        repeat(3) @(posedge sys_clk);

        //-------------------------------------------------
        // Sotto TH_OFF = 1500 -> chiude
        //-------------------------------------------------
        Samp_L <= 24'sd1000;
        Samp_R <= 24'sd1000;

        repeat(3) @(posedge sys_clk);

        //-------------------------------------------------
        // Test lato negativo
        //-------------------------------------------------
        Samp_L <= -24'sd4000;
        Samp_R <= -24'sd4000;

        repeat(3) @(posedge sys_clk);

        //-------------------------------------------------
        // Ancora dentro isteresi
        //-------------------------------------------------
        Samp_L <= -24'sd2000;
        Samp_R <= -24'sd2000;

        repeat(3) @(posedge sys_clk);

        //-------------------------------------------------
        // Chiusura
        //-------------------------------------------------
        Samp_L <= -24'sd1000;
        Samp_R <= -24'sd1000;

        repeat(3) @(posedge sys_clk);

        //-------------------------------------------------
        // Fine
        //-------------------------------------------------
        $finish;

    end

    //-------------------------------------------------
    // Monitor
    //-------------------------------------------------
    initial begin
        $monitor("T=%0t | Samp_L=%0d | Out_L=%0d | Samp_R=%0d | Out_R=%0d",
                  $time, Samp_L, Samp_L_NG, Samp_R, Samp_R_NG);
    end

endmodule