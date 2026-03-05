//=============================================================================
// sha256_env.sv
// Top-level UVM environment — instantiates agent and scoreboard
//=============================================================================

class sha256_env extends uvm_env;
    `uvm_component_utils(sha256_env)

    //-------------------------------------------------------------------------
    // Sub-components
    //-------------------------------------------------------------------------
    sha256_agent      agent;
    sha256_scoreboard scoreboard;

    //-------------------------------------------------------------------------
    // Constructor
    //-------------------------------------------------------------------------
    function new(string name = "sha256_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    //-------------------------------------------------------------------------
    // Build phase
    //-------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = sha256_agent     ::type_id::create("agent",      this);
        scoreboard = sha256_scoreboard::type_id::create("scoreboard", this);
    endfunction

    //-------------------------------------------------------------------------
    // Connect phase — agent monitor → scoreboard
    //-------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        agent.ap.connect(scoreboard.analysis_export);
    endfunction

endclass