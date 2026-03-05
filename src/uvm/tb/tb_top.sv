//=============================================================================
// tb_top.sv
//=============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "sha256_if.sv"
`include "sha256_seq_item.sv"
`include "sha256_sequencer.sv"
`include "sha256_driver.sv"
`include "sha256_monitor.sv"
`include "sha256_scoreboard.sv"
`include "sha256_agent.sv"
`include "sha256_env.sv"
`include "sha256_sequences.sv"
`include "sha256_test.sv"

module tb_top;

    logic clk;
    logic reset_n;

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset_n = 0;
        repeat (5) @(posedge clk);
        reset_n = 1;
        `uvm_info("TOP", "Reset de-asserted", UVM_LOW)
    end

    sha256_if dut_if (.clk(clk));
    assign dut_if.reset_n = reset_n;

    sha256_core dut (
        .clk          (clk),
        .reset_n      (dut_if.reset_n),
        .init         (dut_if.init),
        .next         (dut_if.next),
        .mode         (dut_if.mode),
        .block        (dut_if.block_in),
        .ready        (dut_if.ready),
        .digest       (dut_if.digest),
        .digest_valid (dut_if.digest_valid)
    );

    initial begin
        uvm_config_db #(virtual sha256_if)::set(null, "uvm_test_top.*", "vif", dut_if);
        run_test("sha256_test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule

