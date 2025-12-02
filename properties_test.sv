module property_test;
    logic clk, rst_n;
    logic [7:0] lfsr_seed;
    logic [3:0] req, grant;
    
    parameter K = 100;
    
    // Instantiate property checker
    random_arbiter #(.NUM_REQS(4)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .lfsr_seed(lfsr_seed),
        .req(req),
        .grant(grant)
    );

    // Instantiate checker (checker ONLY observes)
    arbiter_properties #(.NUM_REQS(4), .K(K)) ch (
        .clk(clk),
        .rst_n(rst_n),
        .lfsr_seed(lfsr_seed),
        .req(req),
        .grant(grant)
    );

    
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test: Hold req[0] active, see how long until grant
    initial begin
        $display("=== Property Strengthening Test ===\n");
        
        // Test with seed that might cause starvation
        test_with_seed(8'h01, "0x01");
        test_with_seed(8'h42, "0x42");
        test_with_seed(8'hAA, "0xAA");
        test_with_seed(8'hFF, "0xFF");
        
        $finish;
    end
    
    task test_with_seed(logic [7:0] seed_val, string seed_name);
        $display("--- Testing with seed=%s ---", seed_name);
        
        lfsr_seed = seed_val;
        rst_n = 0;
        req = 4'b0000;
        #20;
        rst_n = 1;
        #10;
        
        // Hold req[0] active continuously
        req[0] = 1'b1;
        req[3:1] = $random;  // Randomize other requests
        
        repeat(K + 20) begin
            @(posedge clk);
            req[3:1] = $random;
            req[0] = 1'b1;  // Keep req[0] active
            
            if (grant[0]) begin
                $display("  Req[0] granted after %0d cycles\n", 
                        ch.starvation_counter[0]);
                break;
            end
        end
        
        if (!grant[0])
            $display("  Req[0] NOT granted within %0d cycles\n", K);
            
    endtask
    
endmodule