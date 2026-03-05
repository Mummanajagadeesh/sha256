//=============================================================================
// sha256_if.sv
// Interface for SHA-256 core DUT
//=============================================================================

interface sha256_if (input logic clk);

    logic        reset_n;
    logic        init;
    logic        next;
    logic        mode;
    logic [511:0] block_in;
    logic        ready;
    logic [255:0] digest;
    logic        digest_valid;

endinterface