`timescale 1ns / 1ps

module uart_fifo #
(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)
(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                     wr_en,
    input  wire                     rd_en,

    input  wire [DATA_WIDTH-1:0]    wr_data,

    output reg  [DATA_WIDTH-1:0]    rd_data,

    output wire                     full,
    output wire                     empty,

    output reg [$clog2(DEPTH):0]    count
);

localparam ADDR_WIDTH = $clog2(DEPTH);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;

assign empty = (count == 0);
assign full  = (count == DEPTH);

//------------------------------------------------------------
// Pointer Wrap Function
//------------------------------------------------------------
function [ADDR_WIDTH-1:0] next_ptr;
    input [ADDR_WIDTH-1:0] ptr;
begin
    if(ptr == DEPTH-1)
        next_ptr = 0;
    else
        next_ptr = ptr + 1'b1;
end
endfunction

//------------------------------------------------------------
// FIFO
//------------------------------------------------------------
always @(posedge clk)
begin
    if(rst)
    begin
        wr_ptr  <= 0;
        rd_ptr  <= 0;
        count   <= 0;
        rd_data <= 0;
    end
    else
    begin

        //----------------------------------------------------
        // Simultaneous Read & Write
        //----------------------------------------------------
        if(wr_en && rd_en)
        begin
            if(empty)
            begin
                // FIFO empty: ignore read, perform write
                mem[wr_ptr] <= wr_data;
                wr_ptr <= next_ptr(wr_ptr);
                count <= count + 1'b1;

                //$display("WRITE(E): ptr=%0d data=%h", wr_ptr, wr_data);
            end
            else if(full)
            begin
                // FIFO full: perform read and overwrite oldest
                rd_data <= mem[rd_ptr];
                mem[wr_ptr] <= wr_data;

                rd_ptr <= next_ptr(rd_ptr);
                wr_ptr <= next_ptr(wr_ptr);

                //$display("RW(F): R=%h W=%h", mem[rd_ptr], wr_data);
            end
            else
            begin
                // Normal simultaneous read/write
                rd_data <= mem[rd_ptr];
                mem[wr_ptr] <= wr_data;

                rd_ptr <= next_ptr(rd_ptr);
                wr_ptr <= next_ptr(wr_ptr);

                //$display("RW: R=%h W=%h", mem[rd_ptr], wr_data);
            end
        end

        //----------------------------------------------------
        // Write Only
        //----------------------------------------------------
        else if(wr_en && !full)
        begin
            mem[wr_ptr] <= wr_data;

            // $display("WRITE: ptr=%0d data=%h", wr_ptr, wr_data);

            wr_ptr <= next_ptr(wr_ptr);
            count <= count + 1'b1;
        end

        //----------------------------------------------------
        // Read Only
        //----------------------------------------------------
        else if(rd_en && !empty)
        begin
            rd_data <= mem[rd_ptr];

            // $display("READ : ptr=%0d data=%h", rd_ptr, mem[rd_ptr]);
            // $strobe ("AFTER NBA rd_data=%h", rd_data);

            rd_ptr <= next_ptr(rd_ptr);
            count <= count - 1'b1;
        end

    end

    
end

always @(posedge clk)
begin
    // $display("FIFO: rd_en=%b empty=%b time=%0t", rd_en, empty, $time);
end

endmodule