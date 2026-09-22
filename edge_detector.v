`timescale 1ns / 1ps

module edge_detector(
    input wire clk,
    input wire rst,
    input wire signal_in,

    output reg pulse
);

reg signal_d;

always @(posedge clk or posedge rst) begin

    if(rst) begin
        signal_d <= 1'b0;
        pulse    <= 1'b0;
    end

    else begin
        pulse    <= signal_in & ~signal_d;
        signal_d <= signal_in;
    end

end

endmodule
