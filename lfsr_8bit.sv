module lfsr_8bit (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] seed,      // Configurable seed (1 to 255)
    output logic [7:0] lfsr_out
);
    
    logic [7:0] lfsr_reg;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize with seed
            lfsr_reg <= (seed == 8'h00) ? 8'h01 : seed;  // Avoid all-zeros
        end else begin
            lfsr_reg <= {lfsr_reg[6:0], 
                         lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3]};
        end
    end
    
    assign lfsr_out = lfsr_reg;
    
endmodule