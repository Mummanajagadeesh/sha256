`timescale 1ns/1ps
`default_nettype none

module tb_sha256_corner;
  parameter CLK_HALF_PERIOD = 5;
  parameter CLK_PERIOD = 2 * CLK_HALF_PERIOD;

  reg clk, reset_n, init, next, mode;
  reg [511:0] block;
  wire ready;
  wire [255:0] digest;
  wire digest_valid;
  integer total_tests = 0, errors = 0;

  sha256_core dut (.clk(clk), .reset_n(reset_n), .init(init), .next(next), .mode(mode),
                   .block(block), .ready(ready), .digest(digest), .digest_valid(digest_valid));
  always #CLK_HALF_PERIOD clk = ~clk;
  task reset_dut; begin reset_n=0; #(4*CLK_PERIOD); reset_n=1; end endtask
  task wait_ready; begin while(!ready) #(CLK_PERIOD); end endtask

  task corner_test(input [511:0] msg, input [127:0] name);
    integer st,en,dur,tid,pass,valid;
    begin
      total_tests++; tid=total_tests; st=$time;
      block=msg; init=1; next=0; #(CLK_PERIOD); init=0; wait_ready();
      en=$time; dur=en-st;
      valid=digest_valid; pass=(digest_valid && (^digest !== 1'bX));
      if(!pass) errors++;
      $display("| %2d | %s | corner | %040h | %040h | %0d | %s | %7d | %7d |",
        tid,name,msg[255:96],digest[255:96],valid,pass?"PASS  ":"FAIL  ",en,dur);
    end
  endtask

  initial begin
    clk=0; mode=1; init=0; next=0; reset_n=1;
    $display("\n=== SHA256 Corner-Case Verification ===\n");
    $display("+----+----------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
    reset_dut();
    corner_test(512'h0, "zero");
    corner_test({512{1'b1}}, "all_ones");
    corner_test({128{4'b1010}}, "alternating");
    $display("+----+----------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
    $display("\nTotal tests: %0d  Failures: %0d", total_tests, errors);
    $display(errors ? "RESULT: FAIL" : "RESULT: PASS");
    $finish;
  end
endmodule
