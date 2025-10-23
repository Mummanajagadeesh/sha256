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

  // Reset task
  task reset_dut;
    begin
      reset_n = 0;
      #(4*CLK_PERIOD);
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
  task single_block_test(input [511:0] msg_block, input [255:0] expected, input [127:0] name);
    begin
      total_tests = total_tests + 1;
      block = msg_block;
      init = 1; next = 0; #(CLK_PERIOD);
      init = 0;
      wait_ready();
      if (digest_valid && digest === expected)
        $display("PASS: %s digest = %h", name, digest);
      else begin
        $display("FAIL: %s", name);
        $display("Expected: %h", expected);
        $display("Got     : %h", digest);
        errors = errors + 1;
      end
    end
  endtask

  // Multi-block test
  task multi_block_test(input [511:0] block1, input [511:0] block2, input [255:0] expected, input [127:0] name);
    begin
      total_tests = total_tests + 1;
      block = block1; init=1; next=0; #(CLK_PERIOD); init=0; wait_ready();
      block = block2; init=0; next=1; #(CLK_PERIOD); next=0; wait_ready();
      if (digest_valid && digest === expected)
        $display("PASS: %s multi-block digest executed", name);
      else begin
        $display("FAIL: %s multi-block digest", name);
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
      msg = {$random,$random,$random,$random,$random,$random,$random,$random,
             $random,$random,$random,$random,$random,$random,$random,$random};
      block = msg; init=1; next=0; #(CLK_PERIOD); init=0; wait_ready();
      if (digest_valid && ^digest !== 1'bX)
        $display("PASS: Random test %0d executed cleanly", tc_number);
      else begin
        $display("FAIL: Random test %0d produced X/Z or invalid digest", tc_number);
        errors = errors + 1;
      end
    end
  endtask

  // Corner test
  task corner_test(input [511:0] msg, input [127:0] name);
    begin
      total_tests = total_tests + 1;
      block = msg; init=1; next=0; #(CLK_PERIOD); init=0; wait_ready();
      if (digest_valid && ^digest !== 1'bX)
        $display("PASS: %s corner-case test", name);
      else begin
        $display("FAIL: %s corner-case produced X/Z or invalid digest", name);
        errors = errors + 1;
      end
    end
  endtask

  // Main TB
  initial begin
    clk=0; init=0; next=0; mode=1; reset_n=1;
    $display("\n--- SHA256 Functional Verification ---\n");
    reset_dut();

    // Single-block directed tests
    single_block_test(
      512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018,
      256'hBA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD,
      "abc"
    );

    single_block_test(
      512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
      256'hE3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855,
      "empty"
    );

    // Multi-block test with correct digest
    multi_block_test(
      512'h68656C6C6F8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000028,
      512'h6D657373616765320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000028,
      256'h09C99D8F65C1283923C1A8FFA779C3FB76943715BC61D2C93A42030DD1008130,
      "hello+msg2"
    );

    // Random tests
    random_test(1);
    random_test(2);
    random_test(3);

    // Corner-case tests
    corner_test(512'h0, "zero");
    corner_test({512{1'b1}}, "all_ones");
    corner_test({128{4'b1010}}, "alternating");

    // Mode-0 test with correct digest
    mode=0;
    single_block_test(
      512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018,
      256'h23097D223405D8228642A477BDA255B32AADBCE4BDA0B3F7E36C9DA7D2DA082D,
      "abc_mode0"
    );
    mode=1;

    // Summary
    if(errors==0)
      $display("\nAll %0d tests PASSED ✅", total_tests);
    else
      $display("\n%0d of %0d tests FAILED ❌", errors, total_tests);

    $finish;
  end

endmodule
