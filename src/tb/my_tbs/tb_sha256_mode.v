`timescale 1ns/1ps
`default_nettype none

module tb_sha256_mode;
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

  task single_block_test(input [511:0] blk, input [255:0] exp, input [127:0] name);
    integer st,en,dur,tid,pass,valid;
    begin
      total_tests++; tid=total_tests; st=$time;
      block=blk; init=1; next=0; #(CLK_PERIOD); init=0; wait_ready();
      en=$time; dur=en-st;
      valid=digest_valid; pass=(digest_valid && (digest===exp));
      if(!pass) errors++;
      $display("| %2d | %s | mode0 | %040h | %040h | %0d | %s | %7d | %7d |",
        tid,name,exp[255:96],digest[255:96],valid,pass?"PASS  ":"FAIL  ",en,dur);
    end
  endtask

  initial begin
    clk=0; mode=0; init=0; next=0; reset_n=1;
    $display("\n=== SHA256 Mode=0 Verification ===\n");
    $display("+----+----------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
    reset_dut();

    single_block_test(
      512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018,
      256'h23097D223405D8228642A477BDA255B32AADBCE4BDA0B3F7E36C9DA7D2DA082D,
      "abc_mode0"
    );

    $display("+----+----------+---------+------------------------------------------+------------------------------------------+---+------+---------+----------+");
    $display("\nTotal tests: %0d  Failures: %0d", total_tests, errors);
    $display(errors ? "RESULT: FAIL" : "RESULT: PASS");
    $finish;
  end
endmodule
