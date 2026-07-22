module baud_generator
#(
    parameter integer CLK_FREQ   = 50_000_000,
    parameter integer BAUD_RATE  = 9600,
    parameter integer OVERSAMPLE = 16
)
(
    input  wire clk,
    input  wire rst,

    output reg  baud_tick,
    output reg  sample_tick
);

     
    // Divider Calculation (Rounded to Nearest Integer)
    localparam integer BAUD_DIV = (CLK_FREQ + (BAUD_RATE/2)) / BAUD_RATE;
    localparam integer SAMPLE_DIV = (CLK_FREQ + ((BAUD_RATE * OVERSAMPLE)/2)) / (BAUD_RATE * OVERSAMPLE);

     
    // Counter Width Calculation
    localparam integer BAUD_CNT_WIDTH   = $clog2(BAUD_DIV);
    localparam integer SAMPLE_CNT_WIDTH = $clog2(SAMPLE_DIV);

     
    // Counters
    reg [BAUD_CNT_WIDTH-1:0]   baud_counter;
    reg [SAMPLE_CNT_WIDTH-1:0] sample_counter;

     
    // Baud Tick Generator
    always @(posedge clk) begin
        if (rst) begin
            baud_counter <= 0;
            baud_tick    <= 1'b0;
        end
        else begin
            if (baud_counter == BAUD_DIV-1) begin
                baud_counter <= 0;
                baud_tick    <= 1'b1;
            end
            else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick    <= 1'b0;
            end
        end
    end

     
    // 16x Sample Tick Generator
    always @(posedge clk) begin
        if (rst) begin
            sample_counter <= 0;
            sample_tick    <= 1'b0;
        end
        else begin
            if (sample_counter == SAMPLE_DIV-1) begin
                sample_counter <= 0;
                sample_tick    <= 1'b1;
            end
            else begin
                sample_counter <= sample_counter + 1'b1;
                sample_tick    <= 1'b0;
            end
        end
    end

endmodule