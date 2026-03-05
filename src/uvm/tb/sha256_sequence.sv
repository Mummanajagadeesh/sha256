//=============================================================================
// sha256_sequencer.sv
// Standard UVM sequencer — no customisation needed for basic tests
//=============================================================================

class sha256_sequencer extends uvm_sequencer #(sha256_seq_item);
    `uvm_component_utils(sha256_sequencer)

    function new(string name = "sha256_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass