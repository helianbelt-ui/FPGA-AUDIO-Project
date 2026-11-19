`timescale 1ns/1ps

module tb_VolumeModulator1;

  // Clock
  reg clk = 0;
  always #5 clk = ~clk; // 100 MHz

  // DUT I/Os
  reg signed [23:0] Samp_IN_L = 0;
  reg signed [23:0] Samp_IN_R = 0;
  reg Plus = 0;
  reg Minus = 0;
  reg rst = 0;
  wire signed [23:0] Samp_OUT_L;
  wire signed [23:0] Samp_OUT_R;

  // Instantiate DUT
  VolumeModulator dut (
    .Samp_IN_L(Samp_IN_L),
    .Samp_IN_R(Samp_IN_R),
    .BCLK(clk),
    .Plus(Plus),
    .Minus(Minus),
    .rst(rst),
    .Samp_OUT_L(Samp_OUT_L),
    .Samp_OUT_R(Samp_OUT_R)
  );

  // Local constants for clipping detection (match DUT)
  localparam signed [23:0] MAX_POS = 24'sh7FFFFF;
  localparam signed [23:0] MIN_NEG = 24'sh800000;

  // Counters and debug
  integer cycle = 0;
  integer overflow_count_L = 0;
  integer overflow_count_R = 0;
  integer i;

  // Simple 16-bit LFSR for pseudo-random input
  reg [15:0] lfsr = 16'hACE1;
  always @(posedge clk) begin
    lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13]};
  end

  // Tasks to simulate button press (one clock pulse)
  task press_plus(input integer wait_cycles_after);
    begin
      Plus = 1;
      @(posedge clk);
      Plus = 0;
      repeat (wait_cycles_after) @(posedge clk);
    end
  endtask

  task press_minus(input integer wait_cycles_after);
    begin
      Minus = 1;
      @(posedge clk);
      Minus = 0;
      repeat (wait_cycles_after) @(posedge clk);
    end
  endtask

  // Stimulus
  initial begin
    // Waveform dump
    $dumpfile("tb_VolumeModulator1.vcd");
    $dumpvars(0, tb_VolumeModulator1);

    // Initialize signals
    Plus = 0;
    Minus = 0;
    Samp_IN_L = 0;
    Samp_IN_R = 0;
    rst = 1; // assert reset
    repeat (8) @(posedge clk);

    rst = 0; // release reset
    repeat (8) @(posedge clk);

    $display("[%0t] Starting stimulus", $time);

    // 1) Silence
    Samp_IN_L <= 0;
    Samp_IN_R <= 0;
    repeat (50) @(posedge clk);

    // 2) Single-sample full-scale impulse on left
    Samp_IN_L <= 24'sh7FFFFF;
    Samp_IN_R <= 0;
    @(posedge clk);
    Samp_IN_L <= 0;
    repeat (20) @(posedge clk);

    // 3) Ramp up/down both channels
    for (i = 0; i < 200; i = i + 1) begin
      if (i < 100) begin
        Samp_IN_L <= $signed((i * 24'sh7FFFFF) / 100);
        Samp_IN_R <= $signed(((100 - i) * 24'sh7FFFFF) / 100);
      end else begin
        Samp_IN_L <= $signed(((200 - i) * 24'sh7FFFFF) / 100);
        Samp_IN_R <= $signed(((i - 100) * 24'sh7FFFFF) / 100);
      end
      @(posedge clk);
    end

    // 4) Full-scale alternating to stress clipping
    for (i = 0; i < 50; i = i + 1) begin
      Samp_IN_L <= (i[0]) ? 24'sh7FFFFF : 24'sh800000;
      Samp_IN_R <= (i[0]) ? 24'sh7FFFFF : 24'sh800000;
      @(posedge clk);
    end
    Samp_IN_L <= 0;
    Samp_IN_R <= 0;
    repeat (10) @(posedge clk);

    // 5) Random noise (LFSR) to exercise many values
    for (i = 0; i < 400; i = i + 1) begin
      Samp_IN_L <= {lfsr, 8'h00};      // scale 16->24 bits
      Samp_IN_R <= {~lfsr, 8'h00};
      @(posedge clk);
    end

    // 6) Change gain up 5 steps
    for (i = 0; i < 5; i = i + 1) begin
      press_plus(6);
    end

    // Run some samples at higher gain
    for (i = 0; i < 300; i = i + 1) begin
      Samp_IN_L <= {lfsr, 8'h00};
      Samp_IN_R <= {~lfsr, 8'h00};
      @(posedge clk);
    end

    // 7) Change gain down 3 steps
    for (i = 0; i < 3; i = i + 1) begin
      press_minus(6);
    end

    // More random samples
    for (i = 0; i < 200; i = i + 1) begin
      Samp_IN_L <= {lfsr, 8'h00};
      Samp_IN_R <= {~lfsr, 8'h00};
      @(posedge clk);
    end

    // Final silence
    Samp_IN_L <= 0;
    Samp_IN_R <= 0;
    repeat (50) @(posedge clk);

    $display("[%0t] Stimulus finished", $time);
    $display("Overflow counts L=%0d R=%0d", overflow_count_L, overflow_count_R);

    $finish;
  end

  // Monitor outputs and count clipping occurrences
  always @(posedge clk) begin
    cycle = cycle + 1;
    if (Samp_OUT_L === MAX_POS || Samp_OUT_L === MIN_NEG) overflow_count_L = overflow_count_L + 1;
    if (Samp_OUT_R === MAX_POS || Samp_OUT_R === MIN_NEG) overflow_count_R = overflow_count_R + 1;

    // occasional status print
    if ((cycle % 500) == 0) begin
      $display("[%0t] cycle=%0d IN_L=%0h OUT_L=%0h IN_R=%0h OUT_R=%0h ovfL=%0d ovfR=%0d",
               $time, cycle, Samp_IN_L, Samp_OUT_L, Samp_IN_R, Samp_OUT_R, overflow_count_L, overflow_count_R);
    end
  end

endmodule
