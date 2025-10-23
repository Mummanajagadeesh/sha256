`timescale 1ns/1ps
`default_nettype none

module my_tb_sha256_core;

  parameter CLK_HALF_PERIOD = 5;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  // DUT signals
  reg clk, reset_n, init, next, mode;
  reg [511:0] block;
  wire ready;
  wire [255:0] digest;
  wire digest_valid;

  // For results
  integer errors = 0;
  integer total_tests = 0;

  // Instantiate DUT
  sha256_core dut (
    .clk(clk),
    .reset_n(reset_n),
    .init(init),
    .next(next),
    .mode(mode),
    .block(block),
    .ready(ready),
    .digest(digest),
    .digest_valid(digest_valid)
  );

  // Clock
  always #CLK_HALF_PERIOD clk = ~clk;

  // Reset Task
  task reset_dut;
    begin
      reset_n = 0;
      #(4 * CLK_PERIOD);
      reset_n = 1;
    end
  endtask

  // Wait for ready
  task wait_ready;
    begin
      while (!ready)
        #(CLK_PERIOD);
    end
  endtask

  // Single-block test
  task single_block_test(
    input [511:0] msg_block,
    input [255:0] expected,
    input [127:0] name
  );
    begin
      total_tests = total_tests + 1;
      block = msg_block;
      init  = 1;
      #(CLK_PERIOD);
      init  = 0;
      wait_ready();

      if (digest === expected) begin
        $display("PASS: %s digest = %h", name, digest);
      end else begin
        $display("FAIL: %s", name);
        $display("Expected: %h", expected);
        $display("Got     : %h", digest);
        errors = errors + 1;
      end
    end
  endtask

  // Random test
  task random_test(input [7:0] tc_number);
    reg [511:0] msg;
    begin
      total_tests = total_tests + 1;
      msg = {$random, $random, $random, $random,
             $random, $random, $random, $random,
             $random, $random, $random, $random,
             $random, $random, $random, $random};
      block = msg;
      init  = 1;
      #(CLK_PERIOD);
      init  = 0;
      wait_ready();

      if (^digest === 1'bX) begin
        $display("FAIL: Random test %0d produced X/Z values", tc_number);
        errors = errors + 1;
      end else begin
        $display("PASS: Random test %0d executed cleanly", tc_number);
      end
    end
  endtask

  // Corner case tests
  task corner_test_zero;
    begin
      total_tests = total_tests + 1;
      block = 512'h0;
      init  = 1;
      #(CLK_PERIOD);
      init  = 0;
      wait_ready();
      if (^digest === 1'bX) begin
        $display("FAIL: Zero input caused X");
        errors = errors + 1;
      end else begin
        $display("PASS: Zero input test");
      end
    end
  endtask

  task corner_test_all_ones;
    begin
      total_tests = total_tests + 1;
      block = {512{1'b1}};
      init  = 1;
      #(CLK_PERIOD);
      init  = 0;
      wait_ready();
      if (^digest === 1'bX) begin
        $display("FAIL: All ones input caused X");
        errors = errors + 1;
      end else begin
        $display("PASS: All ones input test");
      end
    end
  endtask

  task corner_test_alternating;
    begin
      total_tests = total_tests + 1;
      block = {128{4'b1010}}; // 512-bit alternating 1010
      init  = 1;
      #(CLK_PERIOD);
      init  = 0;
      wait_ready();
      if (^digest === 1'bX) begin
        $display("FAIL: Alternating input caused X");
        errors = errors + 1;
      end else begin
        $display("PASS: Alternating pattern input test");
      end
    end
  endtask

  // Directed known testcases
  initial begin
    clk = 0;
    init = 0;
    next = 0;
    mode = 1; // Normal mode
    reset_n = 1;

    $display("\n--- SHA256 Functional Verification ---\n");
    reset_dut();

    // Test 1: "abc"
    single_block_test(
      512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018,
      256'hBA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD,
      "abc"
    );

    // Test 2: Empty string
    single_block_test(
      512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
      256'hE3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855,
      "empty"
    );

    // Test 3: "hello"
    single_block_test(
      512'h68656C6C6F8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000028,
      256'h2CF24DBA5FB0A30E26E83B2AC5B9E29E1B161E5C1FA7425E73043362938B9824, // corrected
      "hello"
    );

    // Test 4–6: Corner-case tests
    corner_test_zero();
    corner_test_all_ones();
    corner_test_alternating();

    // Test 7–11: Random tests
    random_test(1);
    random_test(2);
    random_test(3);
    random_test(4);
    random_test(5);

    // Summary
    if (errors == 0)
      $display("\nAll %0d tests PASSED ✅", total_tests);
    else
      $display("\n%0d of %0d tests FAILED ❌", errors, total_tests);

    $finish;
  end
endmodule
