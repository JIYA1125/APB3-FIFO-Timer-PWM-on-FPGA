`timescale 1ns / 1ps

module FIFO (
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [7:0] data_in,

    output reg [7:0] data_out,
    output wire full,
    output wire empty,
    output reg [3:0] count
);

reg [7:0] mem [0:7];

reg [2:0] wr_ptr;
reg [2:0] rd_ptr;

assign full  = (count == 4'd8);
assign empty = (count == 4'd0);

always @(posedge clk or posedge rst) begin

    if (rst) begin
        wr_ptr    <= 3'd0;
        rd_ptr    <= 3'd0;
        count     <= 4'd0;
        data_out  <= 8'd0;
    end

    else begin

        if (wr_en && !full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
        end

        if (rd_en && !empty) begin
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1;
        end

        case ({wr_en && !full, rd_en && !empty})

            2'b10:
                count <= count + 1'b1;

            2'b01:
                count <= count - 1'b1;

            default:
                count <= count;

        endcase
    end
end

endmodule
