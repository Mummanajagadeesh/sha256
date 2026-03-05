//=============================================================================
// sha256_driver.sv
//=============================================================================

class sha256_driver extends uvm_driver #(sha256_seq_item);
    `uvm_component_utils(sha256_driver)

    virtual sha256_if vif;

    function new(string name = "sha256_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual sha256_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "sha256_driver: virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        sha256_seq_item item;

        vif.init     <= 0;
        vif.next     <= 0;
        vif.mode     <= 1;
        vif.block_in <= '0;

        // Wait for reset to de-assert before doing anything
        @(posedge vif.clk);
        while (!vif.reset_n) @(posedge vif.clk);
        `uvm_info("DRIVER", "Reset de-asserted, driver ready", UVM_LOW)

        // Extra settling cycles after reset
        repeat (3) @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(sha256_seq_item item);

        // Wait until DUT is ready
        @(posedge vif.clk);
        while (!vif.ready) @(posedge vif.clk);

        vif.init     <= item.init;
        vif.next     <= item.next;
        vif.mode     <= item.mode;
        vif.block_in <= item.block_in;
        @(posedge vif.clk);

        vif.init <= 0;
        vif.next <= 0;

        // Wait for digest_valid
        @(posedge vif.clk);
        while (!vif.digest_valid) @(posedge vif.clk);

        `uvm_info("DRIVER",
            $sformatf("digest_valid asserted. digest=0x%0h", vif.digest),
            UVM_MEDIUM)

    endtask

endclass