module uart_rx
#(
    parameter DATA_BITS = 8,
    parameter OVERSAMPLE = 16
)
(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  sample_tick,
    input  wire                  rx,

    output reg [DATA_BITS-1:0]   rx_data,
    output reg                   rx_done,
    output reg                   framing_error
);

localparam IDLE  = 3'd0;
localparam START = 3'd1;
localparam DATA  = 3'd2;
localparam STOP  = 3'd3;
localparam DONE  = 3'd4;

reg [2:0] state;

reg rx_ff1;
reg rx_ff2;
reg rx_prev;

reg [3:0] sample_counter;
reg [2:0] bit_counter;

reg [DATA_BITS-1:0] shift_reg;

reg sample7;
reg sample8;
reg sample9;

wire sampled_bit;
wire start_detect;

assign start_detect = rx_prev & ~rx_ff2;

assign sampled_bit =
       (sample7 & sample8) |
       (sample7 & sample9) |
       (sample8 & sample9);

always @(posedge clk)
begin
    if(rst)
    begin
        rx_ff1 <= 1'b1;
        rx_ff2 <= 1'b1;
        rx_prev <= 1'b1;
    end
    else
    begin
        rx_ff1 <= rx;
        rx_ff2 <= rx_ff1;
        rx_prev <= rx_ff2;
    end
end

always @(posedge clk)
begin
    if(rst)
    begin
        state <= IDLE;

        sample_counter <= 4'd0;
        bit_counter <= 3'd0;

        shift_reg <= 0;
        rx_data <= 0;

        sample7 <= 0;
        sample8 <= 0;
        sample9 <= 0;

        rx_done <= 0;
        framing_error <= 0;
    end
    else
    begin
        rx_done <= 1'b0;

        case(state)

           
        // IDLE
        IDLE:
        begin
            framing_error <= 1'b0;

            sample_counter <= 4'd0;
            bit_counter <= 3'd0;

            sample7 <= 1'b0;
            sample8 <= 1'b0;
            sample9 <= 1'b0;

            if(start_detect)
            begin
                // $display("START DETECT at %0t", $time);
                sample_counter <= 4'd0;
                state <= START;
            end
        end

           
        // START
        START:
        begin
            if(sample_tick)
            begin
                sample_counter <= sample_counter + 1'b1;

                if(sample_counter == 4'd7)
                    sample7 <= rx_ff2;

                if(sample_counter == 4'd8)
                    sample8 <= rx_ff2;

                if(sample_counter == 4'd9)
                    sample9 <= rx_ff2;

                // Check the middle of the START bit
                if(sample_counter == 4'd10)
                begin
                    if(sampled_bit == 1'b0)
                    begin
                        sample_counter <= 4'd0;
                        bit_counter <= 3'd0;

                        sample7 <= 0;
                        sample8 <= 0;
                        sample9 <= 0;

                        state <= DATA;
                    end
                    else
                    begin
                        state <= IDLE;
                    end
                end
            end
        end

           
        // DATA
        DATA:
        begin
            if(sample_tick)
            begin
                sample_counter <= sample_counter + 1'b1;

                if(sample_counter == 4'd7)
                    sample7 <= rx_ff2;

                if(sample_counter == 4'd8)
                    sample8 <= rx_ff2;

                if(sample_counter == 4'd9)
                    sample9 <= rx_ff2;


                   
                // End of One Data Bit
                if(sample_counter == 4'd15)
                begin
                    sample_counter <= 4'd0;

                    shift_reg[bit_counter] <= sampled_bit;
                    // $display("bit=%0d sample=%b sample_counter=%0d",bit_counter,sampled_bit, sample_counter);

                    if(bit_counter == (DATA_BITS-1))
                    begin
                        bit_counter <= 3'd0;
                        state <= STOP;
                    end
                    else
                    begin
                        bit_counter <= bit_counter + 1'b1;
                    end
                end
            end
        end

           
        // STOP
        STOP:
        begin
            if(sample_tick)
            begin
                sample_counter <= sample_counter + 1'b1;

                if(sample_counter == 4'd7)
                    sample7 <= rx_ff2;

                if(sample_counter == 4'd8)
                    sample8 <= rx_ff2;

                if(sample_counter == 4'd9)
                    sample9 <= rx_ff2;

                if(sample_counter == 4'd15)
                begin
                    sample_counter <= 4'd0;

                    framing_error <= ~sampled_bit;
                    // rx_data <= shift_reg;

                    state <= DONE;
                end
            end
        end

           
        // DONE
        DONE:
        begin
            rx_done <= 1'b1;
            rx_data <= shift_reg;
            state <= IDLE;
            // $display("RX_DONE time=%0t data=%h", $time, shift_reg);
        end

           
        // DEFAULT
        default:
        begin

            state <= IDLE;

        end

        endcase

    end

end

endmodule