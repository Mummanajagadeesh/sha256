`timescale 1ns/1ps
`default_nettype none

module tb_sha256_multi;
  parameter CLK_HALF_PERIOD = 5;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  reg clk, reset_n, init, next, mode;
  reg [511:0] block;
  wire ready;
  wire [255:0] digest;
  wire digest_valid;

  integer errors = 0;
  integer total_tests = 0;

  sha256_core dut (
    .clk(clk), .reset_n(reset_n), .init(init), .next(next),
    .mode(mode), .block(block),
    .ready(ready), .digest(digest), .digest_valid(digest_valid)
  );

  always #CLK_HALF_PERIOD clk = ~clk;
  task reset_dut; begin reset_n = 0; #(4*CLK_PERIOD); reset_n = 1; end endtask
  task wait_ready; begin while (!ready) #(CLK_PERIOD); end endtask

  task print_header; begin
    $display("\n=== SHA256 Multi-block Verification ===\n");
    $display("+----+-------------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
    $display("| ID | Name        | Type    | Expected                                 | Actual                                   | V | Res  | Time(ns)| Duration |");
    $display("+----+-------------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
  end endtask
  task print_footer; begin
    $display("+----+-------------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
  end endtask

  task multi_block_test(input [511:0] blk1, input [511:0] blk2, input [255:0] exp, input [127:0] name);
    integer st, en, dur, tid, pass, valid;
    begin
      total_tests++; tid = total_tests; st = $time;
      block = blk1; init = 1; next = 0; #(CLK_PERIOD); init = 0; wait_ready();
      block = blk2; init = 0; next = 1; #(CLK_PERIOD); next = 0; wait_ready();
      en = $time; dur = en - st;
      valid = digest_valid; pass = (digest_valid && (digest === exp));
      if (!pass) errors++;
      $display("| %2d | %s | multi | %040h | %040h | %0d | %s | %7d | %7d |", tid, name, exp[255:96], digest[255:96], valid, pass ? "PASS  " : "FAIL  ", en, dur);
    end
  endtask

  initial begin
    clk = 0; mode = 1; init = 0; next = 0; reset_n = 1;
    print_header(); reset_dut();

    multi_block_test(
      512'h68656C6C6F8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000028,
      512'h6D657373616765320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000028,
      256'h09C99D8F65C1283923C1A8FFA779C3FB76943715BC61D2C93A42030DD1008130,
      "hello+msg2"
    );

    print_footer();
    $display("\nTotal tests: %0d  Failures: %0d", total_tests, errors);
    $display(errors ? "RESULT: FAIL" : "RESULT: PASS");
    $finish;
  end
endmodule
