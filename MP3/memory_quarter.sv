module memory_quarter #(
    parameter INIT_FILE = ""
)(
    input  logic       clk,
    input  logic [6:0] read_address, // 7-bit address (0 to 127)
    output logic [8:0] read_data     // 9-bit sample
);

    // Declare memory array for storing 128 9-bit samples of the first quarter cycle
    logic [8:0] sample_memory [0:127];

    // Load samples from INIT_FILE if provided
    initial if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, sample_memory);
    end

    // Synchronous read from the memory array
    always_ff @(posedge clk) begin
        read_data <= sample_memory[read_address];
    end

endmodule
