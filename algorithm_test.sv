module algorithm_test;
    logic clk, rst_n;
    logic [7:0] lfsr_seed;
    logic [3:0] req, grant;

    parameter K = 50;       // Starvation bound
    parameter NUM_REQS = 4;

    random_arbiter #(
        .NUM_REQS(NUM_REQS),
        .GRANT_HOLD(4)
    ) dut (.*);


    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Track cycles req[0] has waited
    logic [7:0] req0_cycles;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            req0_cycles <= 0;
        else if (req[0] && !grant[0])
            req0_cycles <= req0_cycles + 1;
        else if (grant[0])
            req0_cycles <= 0;
    end

    logic test_result;

    initial begin
        $display("========================================");
        $display("ALGORITHM 1: Property Strengthening");
        $display("Bound k = %0d cycles", K);
        $display("========================================");
        run_algorithm1();
        $finish;
    end

    // -------------------------------------------------------------
    // Algorithm 1
    // -------------------------------------------------------------
    task run_algorithm1();
        int j_min = 1;
        int j_max = K;
        int j;
        int iteration = 0;

        logic [7:0] problem_seeds[$];
        int problem_bounds[$];

        // Step 1: try original bound with random seed
        $display("STEP 1: Check full bound with random seed");
        lfsr_seed = $urandom_range(1, 255);
        $display("  Seed = 0x%h", lfsr_seed);

        test_bound(K, lfsr_seed, test_result);
        if (test_result)
            $display("  PASS: No starvation\n");
        else
            $display("  FAIL: Starvation detected\n");

        // Step 2: binary search with strengthened properties
        $display("STEP 2: Binary search with smaller bounds");

        while (j_min < j_max) begin
            j = (j_min + j_max) / 2;
            iteration++;

            $display("Iteration %0d: test bound j = %0d (range %0d to %0d)",
                     iteration, j, j_min, j_max);

            lfsr_seed = $urandom_range(1, 255);
            $display("  Trying seed 0x%h", lfsr_seed);

            test_bound(j, lfsr_seed, test_result);

            if (test_result) begin
                $display("  PASS at j = %0d\n", j);
                j_min = j + 1;
            end else begin
                $display("  FAIL at j = %0d", j);

                problem_seeds.push_back(lfsr_seed);
                problem_bounds.push_back(j);

                $display("  Checking full bound (k=%0d) with same seed...", K);

                test_bound(K, lfsr_seed, test_result);
                if (!test_result) begin
                    $display("  BUG FOUND: Seed 0x%h fails full bound\n", lfsr_seed);
                end else begin
                    $display("  Full bound passes with this seed\n");
                end

                j_max = j - 1;
            end
        end

        // Summary
        $display("\n========================================");
        $display("VERIFICATION COMPLETE");
        $display("Iterations: %0d", iteration);
        $display("Problematic seeds found: %0d", problem_seeds.size);

        foreach (problem_seeds[i]) begin
            $display("  Seed 0x%h failed at j = %0d", 
                    problem_seeds[i], problem_bounds[i]);
        end
        $display("========================================");
    endtask

    // -------------------------------------------------------------
    // Run one starvation test for given bound and seed
    // -------------------------------------------------------------
    task automatic test_bound(int bound, logic [7:0] seed, output logic passed);
        int cycles;
        logic got_grant = 0;

        // Reset
        lfsr_seed = seed;
        rst_n = 0;
        req = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // Hold req[0] active
        req[0] = 1;

        for (cycles = 0; cycles < bound + 10; cycles++) begin
            @(posedge clk);
            req[3:1] = $random;
            req[0] = 1;

            if (grant[0]) begin
                $display("    Grant after %0d cycles", req0_cycles);
                got_grant = 1;
                break;
            end
        end

        if (!got_grant)
            $display("    No grant within %0d cycles", bound);

        passed = got_grant;
    endtask

endmodule
