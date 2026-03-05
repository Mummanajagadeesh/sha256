//=============================================================================
// sha256_seq_item.sv
// UVM Sequence Item — one SHA-256 transaction
//=============================================================================

class sha256_seq_item extends uvm_sequence_item;

    `uvm_object_utils(sha256_seq_item)

    //-------------------------------------------------------------------------
    // Stimulus fields
    //-------------------------------------------------------------------------
    rand logic [511:0] block_in;   // 512-bit input block
    rand logic         mode;       // 0 = SHA-224, 1 = SHA-256
    rand logic         init;       // 1 = first block
    rand logic         next;       // 1 = chained block

    //-------------------------------------------------------------------------
    // Expected / observed response fields
    //-------------------------------------------------------------------------
    logic [255:0] expected_digest;
    logic [255:0] observed_digest;

    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    function new(string name = "sha256_seq_item");
        super.new(name);
    endfunction

    //-------------------------------------------------------------------------
    // Constraints — default: init transactions, mode=1 (SHA-256)
    //-------------------------------------------------------------------------
    constraint c_mode  { mode == 1'b1; }
    constraint c_flags { init == 1'b1; next == 1'b0; }

    //-------------------------------------------------------------------------
    // UVM utility methods
    //-------------------------------------------------------------------------
    function string convert2string();
        return $sformatf(
            "mode=%0b init=%0b next=%0b block=0x%0h | exp=0x%0h obs=0x%0h",
            mode, init, next, block_in, expected_digest, observed_digest
        );
    endfunction

endclass