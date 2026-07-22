`include "baud_generator.v"
`include "uart_tx.v"
`include "uart_rx.v"
`include "uart_fifo.v"

module uart_top
#(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 9600,
    parameter DATA_BITS  = 8,
    parameter FIFO_DEPTH = 16
)
(
    input  wire                  clk,
    input  wire                  rst,

    // UART Pins
    input  wire                  rx,
    output wire                  tx,

    // CPU TX Interface
    input  wire [DATA_BITS-1:0]  tx_data,
    input  wire                  tx_wr,
    output wire                  tx_full,

    // CPU RX Interface
    output wire [DATA_BITS-1:0]  rx_data,
    input  wire                  rx_rd,
    output wire                  rx_empty,

    output wire                  framing_error
);

    //----------------------------------------------------------
    // Tick Signals
    //----------------------------------------------------------

    wire baud_tick;
    wire sample_tick;

    //----------------------------------------------------------
    // UART TX Signals
    //----------------------------------------------------------

    reg                   tx_start;
    wire                  tx_busy;
    wire                  tx_done;

    reg  [DATA_BITS-1:0]  tx_shift_reg;

    //----------------------------------------------------------
    // UART RX Signals
    //----------------------------------------------------------

    wire [DATA_BITS-1:0]  uart_rx_data;
    wire                  uart_rx_done;
    wire                  uart_frame_error;

    assign framing_error = uart_frame_error;

    //----------------------------------------------------------
    // TX FIFO Signals
    //----------------------------------------------------------

    wire [DATA_BITS-1:0] tx_fifo_dout;

    reg                  tx_fifo_rd;

    wire                 tx_fifo_empty;

    //----------------------------------------------------------
    // RX FIFO Signals
    //----------------------------------------------------------

    reg                  rx_fifo_wr;

    wire                 rx_fifo_full;

    //----------------------------------------------------------
    // Baud Generator
    //----------------------------------------------------------

    baud_generator
    #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLE(16)
    )
    baud_gen
    (
        .clk(clk),
        .rst(rst),

        .baud_tick(baud_tick),
        .sample_tick(sample_tick)
    );

    //----------------------------------------------------------
    // UART TX
    //----------------------------------------------------------

    uart_tx
    #(
        .DATA_BITS(DATA_BITS)
    )
    tx_inst
    (
        .clk(clk),
        .rst(rst),

        .baud_tick(baud_tick),

        .tx_start(tx_start),
        .tx_data(tx_shift_reg),

        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    //----------------------------------------------------------
    // UART RX
    //----------------------------------------------------------

    uart_rx
    #(
        .DATA_BITS(DATA_BITS),
        .OVERSAMPLE(16)
    )
    rx_inst
    (
        .clk(clk),
        .rst(rst),

        .sample_tick(sample_tick),

        .rx(rx),

        .rx_data(uart_rx_data),
        .rx_done(uart_rx_done),
        .framing_error(uart_frame_error)
    );

    //----------------------------------------------------------
    // TX FIFO
    //----------------------------------------------------------

    wire [$clog2(FIFO_DEPTH):0] tx_fifo_count;
    wire [$clog2(FIFO_DEPTH):0] rx_fifo_count;

    uart_fifo
    #(
        .DATA_WIDTH(DATA_BITS),
        .DEPTH(FIFO_DEPTH)
    )
    tx_fifo
    (
        .clk(clk),
        .rst(rst),

        .wr_en(tx_wr),
        .rd_en(tx_fifo_rd),

        .wr_data(tx_data),
        .rd_data(tx_fifo_dout),

        .full(tx_full),
        .empty(tx_fifo_empty),
        .count(tx_fifo_count)
    );

    //----------------------------------------------------------
    // RX FIFO
    //----------------------------------------------------------
    reg [DATA_BITS-1:0] rx_fifo_data;

    uart_fifo
    #(
        .DATA_WIDTH(DATA_BITS),
        .DEPTH(FIFO_DEPTH)
    )
    rx_fifo
    (
        .clk(clk),
        .rst(rst),

        .wr_en(rx_fifo_wr),
        .rd_en(rx_rd),

        .wr_data(rx_fifo_data),
        .rd_data(rx_data),

        .full(rx_fifo_full),
        .empty(rx_empty),
        .count(rx_fifo_count)
    );

    //----------------------------------------------------------
    // TX Controller FSM
    //----------------------------------------------------------

    localparam TX_IDLE      = 3'd0;
    localparam TX_READ_REQ  = 3'd1;
    localparam TX_READ_WAIT = 3'd2;
    localparam TX_LOAD      = 3'd3;
    localparam TX_START     = 3'd4;
    localparam TX_WAIT      = 3'd5;

    reg [2:0] tx_state;

        //----------------------------------------------------------
    // TX Controller + RX FIFO Logic
    //----------------------------------------------------------

    always @(posedge clk)
    begin
        if(rst)
        begin
            tx_state     <= TX_IDLE;

            tx_fifo_rd   <= 1'b0;
            tx_start     <= 1'b0;

            tx_shift_reg <= {DATA_BITS{1'b0}};

            rx_fifo_wr   <= 1'b0;
        end
        else
        begin
            
            // Default pulses
            tx_fifo_rd <= 1'b0;
            tx_start   <= 1'b0;
            rx_fifo_wr <= 1'b0;

            // RX FIFO write
            if (uart_rx_done && !rx_fifo_full) begin
                rx_fifo_data <= uart_rx_data;
                rx_fifo_wr   <= 1'b1;
            end

                

            //--------------------------------------------------
            // TX Controller FSM
            //--------------------------------------------------

            case (tx_state)

                TX_IDLE:
                begin
                    if (!tx_busy && !tx_fifo_empty)
                    begin
                        tx_fifo_rd <= 1'b1;
                        tx_state   <= TX_READ_REQ;
                    end
                end

                // FIFO performs rd_data <= mem[rd_ptr]
                TX_READ_REQ:
                begin
                    tx_state <= TX_READ_WAIT;
                end

                // Wait one full clock for rd_data to update
                TX_READ_WAIT:
                begin
                    tx_state <= TX_LOAD;
                end

                // Now rd_data is stable
                TX_LOAD:
                begin
                    tx_shift_reg <= tx_fifo_dout;
                    tx_state <= TX_START;
                end

                TX_START:
                begin
                    tx_start <= 1'b1;
                    tx_state <= TX_WAIT;
                end

                TX_WAIT:
                begin
                    if (tx_done)
                        tx_state <= TX_IDLE;
                end

            endcase
        end
    end

endmodule