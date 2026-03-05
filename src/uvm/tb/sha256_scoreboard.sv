//=============================================================================
// sha256_scoreboard.sv
//=============================================================================

class sha256_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sha256_scoreboard)

    uvm_analysis_imp #(sha256_seq_item, sha256_scoreboard) analysis_export;

    // Queue of expected digests fed by sequences via config_db mailbox
    mailbox #(logic [255:0]) exp_mbx;

    int unsigned pass_count;
    int unsigned fail_count;

    function new(string name = "sha256_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        pass_count = 0;
        fail_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        exp_mbx = new();
        uvm_config_db #(mailbox #(logic [255:0]))::set(this, "", "exp_mbx", exp_mbx);
    endfunction

    function void write(sha256_seq_item item);
        logic [255:0] expected;

        if (exp_mbx.try_get(expected)) begin
            if (expected === 256'h0) begin
                `uvm_info("SB", $sformatf(
                    "SKIP (no expected set) observed=0x%0h", item.observed_digest), UVM_MEDIUM)
                return;
            end
            if (item.observed_digest === expected) begin
                pass_count++;
                `uvm_info("SB", $sformatf(
                    "PASS [%0d]  digest=0x%0h", pass_count, item.observed_digest), UVM_LOW)
            end else begin
                fail_count++;
                `uvm_error("SB", $sformatf(
                    "FAIL [%0d]  expected=0x%0h  observed=0x%0h",
                    fail_count, expected, item.observed_digest))
            end
        end else begin
            `uvm_info("SB", $sformatf(
                "SKIP (no expected queued) observed=0x%0h", item.observed_digest), UVM_MEDIUM)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf(
            "\n\n========== SCOREBOARD SUMMARY ==========\n  PASS : %0d\n  FAIL : %0d\n=========================================\n",
            pass_count, fail_count), UVM_NONE)
    endfunction

endclass