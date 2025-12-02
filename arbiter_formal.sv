module arbiter_formal (
    input wire clk,
    input wire rst_n
);
    parameter K = 50;
    
    wire [3:0] req, grant;
    wire [7:0] lfsr_seed;
    
    // Instantiate arbiter
    random_arbiter #(.NUM_REQS(4), .GRANT_HOLD(4)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .lfsr_seed(lfsr_seed),
        .req(req),
        .grant(grant)
    );
    
    // Formal: seed is any constant (SMT solver explores all values)
    (* anyconst *) wire [7:0] seed_val;
    assign lfsr_seed = (seed_val == 8'h00) ? 8'h01 : seed_val;
    
    // Formal: any request pattern
    (* anyseq *) wire [3:0] req_val;
    assign req = req_val;
    
    // Track starvation cycles for req[0]
    reg [7:0] req0_wait;
    initial req0_wait = 0;  // Explicit initialization
    
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            req0_wait <= 0;
        else if (req[0] && !grant[0])
            req0_wait <= req0_wait + 1;
        else if (grant[0])
            req0_wait <= 0;
    end
    
    // Track if we're past initialization
    reg past_valid;
    initial past_valid = 0;
    always @(posedge clk)
        past_valid <= 1;
    
    // Formal checks (only after initialization)
    always @* begin
        if (rst_n && past_valid) begin
            // Assumption: at least one request active
            if (req == 4'b0000)
                assume(0);
            
            // Assertion: req[0] shouldn't starve >= K cycles
            if (req[0] && req0_wait >= K)
                assert(0);
        end
    end
    
endmodule

