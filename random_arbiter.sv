module random_arbiter #(
    parameter NUM_REQS = 4,
    parameter GRANT_HOLD = 4  // Increased hold time
)(
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic [7:0]           lfsr_seed,
    input  logic [NUM_REQS-1:0]  req,
    output logic [NUM_REQS-1:0]  grant
);
    
    logic [7:0] random_val;
    logic [1:0] priority_ptr;
    logic [NUM_REQS-1:0] grant_reg;
    logic [7:0] grant_counter;
    
    lfsr_8bit lfsr_inst (
        .clk(clk),
        .rst_n(rst_n),
        .seed(lfsr_seed),
        .lfsr_out(random_val)
    );
    
    assign priority_ptr = random_val[1:0];
    
    // SUPER UNFAIR: req[0] needs LFSR value to be divisible by 16!
    // This means bottom 4 bits must be 0000
    logic req0_can_win;
    assign req0_can_win = (random_val[3:0] == 4'b0000);  // Very rare!
    
    // Combinational arbitration
    logic [NUM_REQS-1:0] grant_next;
    always_comb begin
        grant_next = '0;
        
        // Check if we're still holding a grant
        if (|grant_reg && grant_counter < GRANT_HOLD-1) begin
            grant_next = grant_reg;  // Keep holding
        end else begin
            // New arbitration cycle
            
            // UNFAIR RULE: req[0] only wins in very specific LFSR states
            if (req[0] && req0_can_win) begin
                grant_next[0] = 1'b1;
            end
            // req[1] wins if priority_ptr == 1 and req[0] can't win
            else if (req[1] && (priority_ptr == 2'b01)) begin
                grant_next[1] = 1'b1;
            end
            // req[2] wins if priority_ptr == 2
            else if (req[2] && (priority_ptr == 2'b10)) begin
                grant_next[2] = 1'b1;
            end
            // req[3] wins if priority_ptr == 3
            else if (req[3] && (priority_ptr == 2'b11)) begin
                grant_next[3] = 1'b1;
            end
            // Fallback: priority order 3,2,1 (never 0)
            else if (req[3]) begin
                grant_next[3] = 1'b1;
            end else if (req[2]) begin
                grant_next[2] = 1'b1;
            end else if (req[1]) begin
                grant_next[1] = 1'b1;
            end
            // req[0] gets nothing unless LFSR[3:0] == 0
        end
    end
    
    // Grant hold register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_reg <= '0;
            grant_counter <= 0;
        end else begin
            if (|grant_next) begin
                if (grant_next == grant_reg) begin
                    // Continue holding
                    grant_counter <= grant_counter + 1;
                end else begin
                    // New grant
                    grant_reg <= grant_next;
                    grant_counter <= 0;
                end
            end else begin
                // No grant
                grant_reg <= '0;
                grant_counter <= 0;
            end
        end
    end
    
    assign grant = grant_reg;
    
endmodule