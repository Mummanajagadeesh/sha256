//=============================================================================
// sha256_agent.sv
// Active agent — contains driver, monitor, and sequencer
//=============================================================================

class sha256_agent extends uvm_agent;
    `uvm_component_utils(sha256_agent)

    //-------------------------------------------------------------------------
    // Sub-components
    //-------------------------------------------------------------------------
    sha256_driver     driver;
    sha256_monitor    monitor;
    sha256_sequencer  sequencer;

    //-------------------------------------------------------------------------
    // Analysis port (forwarded from monitor)
    //-------------------------------------------------------------------------
    uvm_analysis_port #(sha256_seq_item) ap;

    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    function new(string name = "sha256_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //-------------------------------------------------------------------------
    // Build phase
    //-------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = sha256_driver   ::type_id::create("driver",    this);
        monitor   = sha256_monitor  ::type_id::create("monitor",   this);
        sequencer = sha256_sequencer::type_id::create("sequencer", this);
        ap        = new("ap", this);
    endfunction

    //-------------------------------------------------------------------------
    // Connect phase — wire driver ↔ sequencer and forward monitor's ap
    //-------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction

endclass