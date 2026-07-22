module uart_tx
#(
    parameter DATA_BITS = 8
)
(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  baud_tick,

    input  wire                  tx_start,
    input  wire [DATA_BITS-1:0]  tx_data,

    output reg                   tx,
    output reg                   tx_busy,
    output reg                   tx_done
);

    //----------------------------------------------------------
    // State Encoding
    //----------------------------------------------------------

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;

    //----------------------------------------------------------
    // Registers
    //----------------------------------------------------------

    reg [DATA_BITS-1:0] shift_reg;
    reg [2:0] bit_counter;

    //----------------------------------------------------------
    // Transmitter FSM
    //----------------------------------------------------------

    always @(posedge clk)
    begin

        if(rst)
        begin

            state <= IDLE;

            tx <= 1'b1;

            tx_busy <= 1'b0;
            tx_done <= 1'b0;

            shift_reg <= {DATA_BITS{1'b0}};
            bit_counter <= 3'd0;

        end
        else
        begin

            tx_done <= 1'b0;

            case(state)

            //--------------------------------------------------
            // IDLE
            //--------------------------------------------------

            IDLE:
            begin

                tx <= 1'b1;
                tx_busy <= 1'b0;

                if(tx_start)
                begin
                    shift_reg <= tx_data;
                    // $display("TX START data=%h", tx_data);
                    bit_counter <= 3'd0;

                    tx_busy <= 1'b1;
                    state <= START;
                end

            end

            //--------------------------------------------------
            // START
            //--------------------------------------------------

            START:
            begin

                tx <= 1'b0;

                if(baud_tick)
                begin
                    state <= DATA;
                end

            end

            //--------------------------------------------------
            // DATA
            //--------------------------------------------------

            DATA:
            begin

                tx <= shift_reg[0];

                if(baud_tick)
                begin

                    shift_reg <= {1'b0, shift_reg[DATA_BITS-1:1]};

                    if(bit_counter == DATA_BITS-1)
                    begin
                        state <= STOP;
                    end
                    else
                    begin
                        bit_counter <= bit_counter + 1'b1;
                    end

                end

            end

            //--------------------------------------------------
            // STOP
            //--------------------------------------------------

            STOP:
            begin

                tx <= 1'b1;

                if(baud_tick)
                begin
                    tx_busy <= 1'b0;
                    tx_done <= 1'b1;
                    state <= IDLE;
                end

            end

            default:
            begin
                state <= IDLE;
            end

            endcase

        end

    end

endmodule