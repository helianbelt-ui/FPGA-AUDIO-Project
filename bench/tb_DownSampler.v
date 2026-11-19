`timescale 1ns/1ps

module tb_DownSampler;

    reg sys_clk;
    reg rst;

    reg Valid_L;
    reg Valid_R;
    reg select;

    reg signed [23:0] Samp_L;
    reg signed [23:0] Samp_R;

    wire ValidDS_L;
    wire ValidDS_R;

    wire signed [23:0] Samp_L_DS;
    wire signed [23:0] Samp_R_DS;

    //-------------------------
    // DUT
    //-------------------------

    DownSampler DUT (
        .sys_clk    (sys_clk),
        .rst        (rst),
        .Valid_L    (Valid_L),
        .Valid_R    (Valid_R),
        .select     (select),
        .Samp_L     (Samp_L),
        .Samp_R     (Samp_R),
        .ValidDS_L  (ValidDS_L),
        .ValidDS_R  (ValidDS_R),
        .Samp_L_DS  (Samp_L_DS),
        .Samp_R_DS  (Samp_R_DS)
    );

    //-------------------------
    // 100 MHz clock
    //-------------------------

    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk;
    end

    //-------------------------
    // Stimulus
    //-------------------------

    integer n;

    initial begin

        rst     = 1;
        Valid_L = 0;
        Valid_R = 0;
        select  = 0;
        Samp_L  = 0;
        Samp_R  = 0;

        #100;

        rst = 0;

        //---------------------------------
        // MODE 0 : M = 1
        //---------------------------------

        $display("MODE 0 (M=1)");

        for(n=0; n<8; n=n+1) begin

            @(posedge sys_clk);

            Samp_L  <= n;
            Valid_L <= 1'b1;

            @(posedge sys_clk);

            Valid_L <= 1'b0;

            Samp_R  <= 100+n;
            Valid_R <= 1'b1;

            @(posedge sys_clk);

            Valid_R <= 1'b0;

        end

        //---------------------------------
        // switch -> MODE 1 (M=4)
        //---------------------------------

        $display("MODE 1 (M=4)");

        @(posedge sys_clk);
        select <= 1'b1;

        @(posedge sys_clk);
        select <= 1'b0;

        //---------------------------------
        // send 20 stereo samples
        //---------------------------------

        for(n=0; n<20; n=n+1) begin

            @(posedge sys_clk);

            Samp_L  <= 1000+n;
            Valid_L <= 1'b1;

            @(posedge sys_clk);

            Valid_L <= 1'b0;

            Samp_R  <= 2000+n;
            Valid_R <= 1'b1;

            @(posedge sys_clk);

            Valid_R <= 1'b0;

        end

        //---------------------------------
        // Fine simulazione
        //---------------------------------

        #100;

        $finish;

    end

    //-------------------------
    // Monitor
    //-------------------------

    initial begin

        $monitor(
            "T=%0t | mode=%0d | VL=%b VR=%b | InL=%0d InR=%0d | OutL=%0d OutR=%0d",
            $time,
            DUT.mode,
            Valid_L,
            Valid_R,
            Samp_L,
            Samp_R,
            Samp_L_DS,
            Samp_R_DS
        );

    end
	
	always @(posedge sys_clk) begin
    if (Valid_R && DUT.update_pair)
        $display("UPDATE R @ %0t", $time);
end

endmodule