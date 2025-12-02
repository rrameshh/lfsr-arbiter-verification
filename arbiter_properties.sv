module arbiter_properties #(
    parameter NUM_REQS = 4,
    parameter K = 100  // Max starvation bound from spec
)(
    input logic                 clk,
    input logic                 rst_n,
    input logic [7:0]           lfsr_seed,
    input logic [NUM_REQS-1:0]  req,
    input logic [NUM_REQS-1:0]  grant
);
    
  
    
    // ========================================
    // ORIGINAL PROPERTY: k-cycle bounded starvation
    // ========================================
    property p_original(int id, int bound);
        @(posedge clk) disable iff (!rst_n)
        req[id] |-> ##[1:bound] grant[id];
    endproperty
    
    // Assert original property for each requestor
    generate
        for (genvar i = 0; i < NUM_REQS; i++) begin : g_original
            a_original: assert property (p_original(i, K))
                else $error("[ORIGINAL] Req[%0d] starved > %0d cycles with seed=0x%h", 
                           i, K, lfsr_seed);
        end
    endgenerate
    
    // ========================================
    // STRENGTHENED PROPERTIES (Algorithm 1)
    // These check SHORTER bounds
    // ========================================
    
    // Property with parameterized bound j
    property p_strengthened(int id, int j);
        @(posedge clk) disable iff (!rst_n)
        req[id] |-> ##[1:j] grant[id];
    endproperty
    
    // j = K/4 (weakest strengthened property)
    generate
        for (genvar i = 0; i < NUM_REQS; i++) begin : g_quarter
            a_quarter: assert property (p_strengthened(i, K/4))
                else $display("[INFO] Req[%0d] starved > %0d cycles (seed=0x%h)", 
                             i, K/4, lfsr_seed);
        end
    endgenerate
    
    // j = K/2 (medium)
    generate
        for (genvar i = 0; i < NUM_REQS; i++) begin : g_half
            a_half: assert property (p_strengthened(i, K/2))
                else $display("[INFO] Req[%0d] starved > %0d cycles (seed=0x%h)", 
                             i, K/2, lfsr_seed);
        end
    endgenerate
    
    // j = 3*K/4 (strongest)
    generate
        for (genvar i = 0; i < NUM_REQS; i++) begin : g_three_quarter
            a_three_quarter: assert property (p_strengthened(i, 3*K/4))
                else $display("[INFO] Req[%0d] starved > %0d cycles (seed=0x%h)", 
                             i, 3*K/4, lfsr_seed);
        end
    endgenerate
    
    // ========================================
    // HELPER: Track starvation cycles
    // ========================================
    int starvation_counter [NUM_REQS];
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_REQS; i++)
                starvation_counter[i] <= 0;
        end else begin
            for (int i = 0; i < NUM_REQS; i++) begin
                if (req[i] && !grant[i])
                    starvation_counter[i] <= starvation_counter[i] + 1;
                else if (grant[i])
                    starvation_counter[i] <= 0;
            end
        end
    end
    
endmodule