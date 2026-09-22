`timescale 1ns / 1ps

module debounce #(
    parameter integer COUNT_MAX = 1_000_000
)(
    input wire clk,
    input wire rst,
    input wire btn,

    output reg btn_db
);

localparam integer COUNT_WIDTH =
    (COUNT_MAX <= 2) ? 1 : $clog2(COUNT_MAX);

reg [COUNT_WIDTH-1:0] count;

reg btn_meta;
reg btn_sync;

always @(posedge clk or posedge rst) begin

    if(rst) begin
        btn_meta <= 1'b0;
        btn_sync <= 1'b0;
        btn_db   <= 1'b0;
        count    <= 0;
    end

    else begin

        btn_meta <= btn;
        btn_sync <= btn_meta;

        if(btn_sync == btn_db) begin
            count <= 0;
        end

        else if(count == COUNT_MAX-1) begin
            btn_db <= btn_sync;
            count  <= 0;
        end

        else begin
            count <= count + 1'b1;
        end

    end
end

endmodule
