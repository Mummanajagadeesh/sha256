`timescale 1ns/1ps
`default_nettype none

module tb_sha256_single;
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

  task print_table_header; begin
    $display("\n=== SHA256 Single-Block Verification ===\n");
    $display("+----+----------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
    $display("| ID | Name     | Type    | Expected                                 | Actual                                   | V | Res  | Time(ns)| Duration |");
    $display("+----+----------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
  end endtask

  task print_table_footer; begin
    $display("+----+----------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
  end endtask

  task print_row(input integer id, input [127:0] name, input [255:0] exp, input [255:0] act, input integer pass, input integer valid, input integer t, input integer dur);
    reg [159:0] exp_s, act_s; reg [8*6:1] res;
    begin
      exp_s = exp[255:96]; act_s = act[255:96];
      res = pass ? "PASS  " : "FAIL  ";
      $display("| %2d | %s | single | %040h | %040h | %0d | %s | %7d | %7d |", id, name, exp_s, act_s, valid, res, t, dur);
    end
  endtask

  task single_block_test(input [511:0] blk, input [255:0] exp, input [127:0] name);
    integer st, en, dur, tid, pass, valid;
    begin
      total_tests++; tid = total_tests; st = $time;
      block = blk; init = 1; next = 0; #(CLK_PERIOD); init = 0; wait_ready();
      en = $time; dur = en - st;
      valid = digest_valid; pass = (digest_valid && (digest === exp));
      if (!pass) errors++;
      print_row(tid, name, exp, digest, pass, valid, en, dur);
    end
  endtask

  initial begin
    clk = 0; mode = 1; init = 0; next = 0; reset_n = 1;
    print_table_header(); reset_dut();

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

    print_table_footer();
    $display("\nTotal tests: %0d  Failures: %0d", total_tests, errors);
    $display(errors ? "RESULT: FAIL" : "RESULT: PASS");
    $finish;
  end
endmodule
