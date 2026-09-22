`timescale 1ns / 1ps

module apb_fifo_slave(
    input wire clk,
    input wire rst,
    input wire psel,
    input wire penable,
    input wire pwrite,
    input wire [7:0] pwdata,

    output reg [7:0] prdata,
    output reg pready,
    output reg pslverr,

    output reg wr_en,
    output reg rd_en,

    output wire [7:0] data_in,

    input wire [7:0] data_out,
    input wire full,
    input wire empty
);

assign data_in = pwdata;

reg read_pending;

always @(posedge clk or posedge rst) begin

    if (rst) begin

        wr_en         <= 1'b0;
        rd_en         <= 1'b0;
        pready        <= 1'b0;
        pslverr       <= 1'b0;
        prdata        <= 8'd0;
        read_pending  <= 1'b0;

    end

    else begin

        wr_en   <= 1'b0;
        rd_en   <= 1'b0;
        pready  <= 1'b0;
        pslverr <= 1'b0;

        if (read_pending) begin

            prdata       <= data_out;
            pready       <= 1'b1;
            read_pending <= 1'b0;

        end

        else if (psel && penable) begin

            if (pwrite) begin

                if (!full) begin
                    wr_en  <= 1'b1;
                    pready <= 1'b1;
                end

                else begin
                    pslverr <= 1'b1;
                    pready  <= 1'b1;
                end

            end

            else begin

                if (!empty) begin
                    rd_en        <= 1'b1;
                    read_pending <= 1'b1;
                end

                else begin
                    pslverr <= 1'b1;
                    pready  <= 1'b1;
                end

            end
        end
    end
end

endmodule
