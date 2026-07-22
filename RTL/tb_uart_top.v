`include "uart_top.v"

`timescale 1ns/1ps

module tb_uart_top;

localparam CLK_PERIOD = 20;   // 50 MHz

//----------------------------------------------------------
// Signals
//----------------------------------------------------------

reg clk;
reg rst;

wire tx;
wire rx;

reg  [7:0] tx_data;
reg        tx_wr;
wire       tx_full;

wire [7:0] rx_data;
reg        rx_rd;
wire       rx_empty;

wire framing_error;

//----------------------------------------------------------
// Loopback
//----------------------------------------------------------

assign rx = tx;

//----------------------------------------------------------
// DUT
//----------------------------------------------------------

uart_top
#(
    .CLK_FREQ(50_000_000),
    .BAUD_RATE(9600)
)
dut
(
    .clk(clk),
    .rst(rst),

    .rx(rx),
    .tx(tx),

    .tx_data(tx_data),
    .tx_wr(tx_wr),
    .tx_full(tx_full),

    .rx_data(rx_data),
    .rx_rd(rx_rd),
    .rx_empty(rx_empty),

    .framing_error(framing_error)
);

//----------------------------------------------------------
// Clock
//----------------------------------------------------------

always #(CLK_PERIOD/2) clk = ~clk;

//----------------------------------------------------------
// Write Task
//----------------------------------------------------------

task uart_write;

input [7:0] data;

begin

    @(posedge clk);

    while(tx_full)
        @(posedge clk);

    tx_data <= data;
    tx_wr   <= 1'b1;

    @(posedge clk);

    tx_wr <= 1'b0;

    $display("Time=%0t TX_WRITE Data=%h (%c)", $time, data, data);

end

endtask

//----------------------------------------------------------
// Read Task
//----------------------------------------------------------
task uart_read;
begin
    while (rx_empty)
        @(posedge clk);

    @(negedge clk);
    rx_rd <= 1'b1;

    @(posedge clk);

    rx_rd <= 1'b0;

    @(posedge clk);

    $display("Time=%0t RX_READ Data=%h (%c)", $time, rx_data, rx_data);
end
endtask

//----------------------------------------------------------
// Test
//----------------------------------------------------------

initial
begin

    clk = 0;
    rst = 1;

    tx_data = 0;
    tx_wr   = 0;
    rx_rd   = 0;

    repeat(10) @(posedge clk);

    rst = 0;
    // #100000;
    //--------------------------------------------------
    // Send HELLO
    //--------------------------------------------------

    uart_write("H");
    uart_write("E");
    uart_write("L");
    uart_write("L");
    uart_write("O");
    
    //--------------------------------------------------
    // Wait for transmission
    //--------------------------------------------------

    // $monitor("time=%0t count=%0d empty=%b full=%b",  $time,  dut.rx_fifo_count,  rx_empty,  dut.rx_fifo_full);

    #12000000;

    repeat (5)
    uart_read();


    #1000;

    $finish;

end




endmodule