`timescale 1ns/1ps
`default_nettype none

module tb_sha256_failcase;
  parameter CLK_HALF_PERIOD = 5;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  reg clk, reset_n, init, next, mode;
  reg [511:0] block;
  wire ready;
  wire [255:0] digest;
  wire digest_valid;
  integer total_tests = 0, errors = 0;

  // Instantiate DUT
  sha256_core dut (
    .clk(clk), .reset_n(reset_n), .init(init), .next(next), .mode(mode),
    .block(block), .ready(ready), .digest(digest), .digest_valid(digest_valid)
  );

  // Clock
  always #CLK_HALF_PERIOD clk = ~clk;

  // Tasks
  task reset_dut;
    begin
      reset_n = 0;
      #(4*CLK_PERIOD);
      reset_n = 1;
    end
  endtask

  task wait_ready;
    begin
      while (!ready)
        #(CLK_PERIOD);
    end
  endtask

  task fail_test(
    input [511:0] blk,
    input [255:0] expected,
    input [127:0] name
  );
    integer st, en, dur, tid, pass, valid;
    begin
      total_tests++;
      tid = total_tests;
      st = $time;

      block = blk;
      init = 1;
      next = 0;
      #(CLK_PERIOD);
      init = 0;

      wait_ready();
      en = $time;
      dur = en - st;

      valid = digest_valid;
      pass = (digest_valid && (digest === expected));

      if (!pass)
        errors++;

      $display("| %2d | %s | exp=%040h | act=%040h | valid=%0d | %s | %7d | %7d |",
               tid, name, expected[255:96], digest[255:96],
               valid, pass ? "PASS  " : "FAIL  ", en, dur);
    end
  endtask

  initial begin
    clk = 0; mode = 1; init = 0; next = 0; reset_n = 1;
    $display("\n=== SHA256 Intentional Fail-Case Verification ===\n");
    $display("+----+----------+------------------------------------------+------------------------------------------+---+------+---------+----------+");

    reset_dut();

    // 1. Known vector with wrong expected digest (should FAIL)
    fail_test(
      512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018,
      256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, // intentionally wrong
      "abc_wrong_exp"
    );

    // 2. Block with all zeros but wrong expected
    fail_test(
      512'h0,
      256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
      "zero_block_wrong"
    );

    // 3. Uninitialized (X) block test – expect undefined digest or invalid
    fail_test(
      {512{1'bx}},
      256'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF,
      "x_block"
    );

    // 4. Trigger `next` without `ready` (protocol violation)
    total_tests++;
    $display("| %2d | %s | Manual protocol violation (next high before ready) |", total_tests, "bad_protocol");
    block = 512'h1234;
    init = 1; next = 1; #(CLK_PERIOD);
    init = 0; next = 0;
    if (digest_valid)
      errors++;

    // 5. Multi-block with reversed order (expected mismatch)
    fail_test(
      {512{8'h55}},
      256'h0000000000000000000000000000000000000000000000000000000000000000,
      "multi_reversed"
    );

    $display("+----+----------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
    $display("\nTotal tests: %0d  Failures: %0d", total_tests, errors);
    $display(errors ? "RESULT: FAIL (as expected)" : "RESULT: PASS (unexpected)");
    $finish;
  end
endmodule
