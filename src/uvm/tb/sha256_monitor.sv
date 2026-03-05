//=============================================================================
// sha256_monitor.sv
// Observes DUT outputs and broadcasts transactions to the scoreboard
//=============================================================================

class sha256_monitor extends uvm_monitor;
    `uvm_component_utils(sha256_monitor)

    //-------------------------------------------------------------------------
    // Analysis port — sends observed transactions to scoreboard
    //-------------------------------------------------------------------------
    uvm_analysis_port #(sha256_seq_item) ap;

    //-------------------------------------------------------------------------
    // Virtual interface handle
    //-------------------------------------------------------------------------
    virtual sha256_if vif;

    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    function new(string name = "sha256_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //-------------------------------------------------------------------------
    // Build phase
    //-------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual sha256_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "sha256_monitor: virtual interface not found in config_db")
    endfunction

    //-------------------------------------------------------------------------
    // Run phase — watch for digest_valid and capture result
    //-------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        sha256_seq_item item;

        forever begin
            // Wait for init or next to be asserted (start of transaction)
            @(posedge vif.clk);
            if (vif.init || vif.next) begin

                item = sha256_seq_item::type_id::create("mon_item");
                item.init     = vif.init;
                item.next     = vif.next;
                item.mode     = vif.mode;
                item.block_in = vif.block_in;

                // Wait for digest_valid
                @(posedge vif.clk);
                while (!vif.digest_valid) @(posedge vif.clk);

                item.observed_digest = vif.digest;

                `uvm_info("MONITOR",
                    $sformatf("Captured digest=0x%0h", item.observed_digest),
                    UVM_MEDIUM)

                ap.write(item);
            end
        end
    endtask

endclass