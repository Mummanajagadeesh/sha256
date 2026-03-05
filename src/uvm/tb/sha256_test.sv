//=============================================================================
// sha256_test.sv
//=============================================================================

class sha256_test extends uvm_test;
    `uvm_component_utils(sha256_test)

    sha256_env env;

    function new(string name = "sha256_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sha256_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        sha256_abc_seq   abc_seq;
        sha256_empty_seq empty_seq;
        sha256_zero_seq  zero_seq;
        sha256_ones_seq  ones_seq;
        sha256_multi_seq multi_seq;

        phase.raise_objection(this);

        `uvm_info("TEST", "\n\n===== SHA-256 UVM TEST START =====\n", UVM_NONE)

        abc_seq = sha256_abc_seq::type_id::create("abc_seq");
        abc_seq.start(env.agent.sequencer);

        empty_seq = sha256_empty_seq::type_id::create("empty_seq");
        empty_seq.start(env.agent.sequencer);

        zero_seq = sha256_zero_seq::type_id::create("zero_seq");
        zero_seq.start(env.agent.sequencer);

        ones_seq = sha256_ones_seq::type_id::create("ones_seq");
        ones_seq.start(env.agent.sequencer);

        multi_seq = sha256_multi_seq::type_id::create("multi_seq");
        multi_seq.start(env.agent.sequencer);

        `uvm_info("TEST", "\n\n===== SHA-256 UVM TEST DONE =====\n", UVM_NONE)

        phase.drop_objection(this);
    endtask

endclass