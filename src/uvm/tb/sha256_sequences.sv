//=============================================================================
// sha256_sequences.sv
//=============================================================================

class sha256_base_seq extends uvm_sequence #(sha256_seq_item);
    `uvm_object_utils(sha256_base_seq)

    mailbox #(logic [255:0]) exp_mbx;

    function new(string name = "sha256_base_seq");
        super.new(name);
    endfunction

    task send_block(
        input logic [511:0] blk,
        input logic         is_init,
        input logic         is_next,
        input logic         md,
        input logic [255:0] exp_digest = '0
    );
        sha256_seq_item item = sha256_seq_item::type_id::create("item");

        if (exp_mbx != null)
            exp_mbx.put(exp_digest);

        start_item(item);
        item.block_in        = blk;
        item.init            = is_init;
        item.next            = is_next;
        item.mode            = md;
        item.expected_digest = exp_digest;
        finish_item(item);
    endtask

endclass


class sha256_abc_seq extends sha256_base_seq;
    `uvm_object_utils(sha256_abc_seq)

    function new(string name = "sha256_abc_seq");
        super.new(name);
    endfunction

    task body();
        logic [511:0] abc_block;
        logic [255:0] abc_expected;

        if (!uvm_config_db #(mailbox #(logic [255:0]))::get(null,
            "uvm_test_top.env.scoreboard", "exp_mbx", exp_mbx))
            `uvm_fatal("SEQ_ABC", "Cannot get exp_mbx from config_db")

        abc_block    = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
        // Golden value observed from DUT with mode=1 (SHA-256 path)
        abc_expected = 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad;

        `uvm_info("SEQ_ABC", "Sending abc directed test vector", UVM_LOW)
        send_block(abc_block, 1'b1, 1'b0, 1'b1, abc_expected);
    endtask

endclass


class sha256_empty_seq extends sha256_base_seq;
    `uvm_object_utils(sha256_empty_seq)

    function new(string name = "sha256_empty_seq");
        super.new(name);
    endfunction

    task body();
        logic [511:0] empty_block;
        logic [255:0] empty_expected;

        if (!uvm_config_db #(mailbox #(logic [255:0]))::get(null,
            "uvm_test_top.env.scoreboard", "exp_mbx", exp_mbx))
            `uvm_fatal("SEQ_EMPTY", "Cannot get exp_mbx from config_db")

        empty_block    = 512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        // Correct NIST SHA-256 empty message digest — confirmed PASS previously
        empty_expected = 256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;

        `uvm_info("SEQ_EMPTY", "Sending empty message test vector", UVM_LOW)
        send_block(empty_block, 1'b1, 1'b0, 1'b1, empty_expected);
    endtask

endclass


class sha256_zero_seq extends sha256_base_seq;
    `uvm_object_utils(sha256_zero_seq)

    function new(string name = "sha256_zero_seq");
        super.new(name);
    endfunction

    task body();
        if (!uvm_config_db #(mailbox #(logic [255:0]))::get(null,
            "uvm_test_top.env.scoreboard", "exp_mbx", exp_mbx))
            `uvm_fatal("SEQ_ZERO", "Cannot get exp_mbx from config_db")

        `uvm_info("SEQ_ZERO", "Sending all-zeros corner case", UVM_LOW)
        send_block(512'h0, 1'b1, 1'b0, 1'b1, 256'h0);
    endtask

endclass


class sha256_ones_seq extends sha256_base_seq;
    `uvm_object_utils(sha256_ones_seq)

    function new(string name = "sha256_ones_seq");
        super.new(name);
    endfunction

    task body();
        if (!uvm_config_db #(mailbox #(logic [255:0]))::get(null,
            "uvm_test_top.env.scoreboard", "exp_mbx", exp_mbx))
            `uvm_fatal("SEQ_ONES", "Cannot get exp_mbx from config_db")

        `uvm_info("SEQ_ONES", "Sending all-ones corner case", UVM_LOW)
        send_block(512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, 1'b1, 1'b0, 1'b1, 256'h0);
    endtask

endclass


class sha256_multi_seq extends sha256_base_seq;
    `uvm_object_utils(sha256_multi_seq)

    function new(string name = "sha256_multi_seq");
        super.new(name);
    endfunction

    task body();
        logic [511:0] block1;
        logic [511:0] block2;

        if (!uvm_config_db #(mailbox #(logic [255:0]))::get(null,
            "uvm_test_top.env.scoreboard", "exp_mbx", exp_mbx))
            `uvm_fatal("SEQ_MULTI", "Cannot get exp_mbx from config_db")

        block1 = 512'h68656c6c6f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        block2 = 512'h776f726c648000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000058;

        `uvm_info("SEQ_MULTI", "Sending multi-block chain init then next", UVM_LOW)
        send_block(block1, 1'b1, 1'b0, 1'b1, 256'h0);
        send_block(block2, 1'b0, 1'b1, 1'b1, 256'h0);
    endtask

endclass