`timescale 1ns / 1ps

module timer_display_mux(
    input wire clk,
    input wire [15:0] value,

    output reg [3:0] an,
    output wire [6:0] seg
);

reg [15:0] refresh_counter;
reg [3:0] digit;

integer thousands;
integer hundreds;
integer tens;
integer ones;

always @(posedge clk) begin
    refresh_counter <= refresh_counter + 1'b1;
end

always @(*) begin

    thousands = (value / 1000) % 10;
    hundreds  = (value / 100)  % 10;
    tens      = (value / 10)   % 10;
    ones      = value % 10;

    case(refresh_counter[15:14])

        2'b00: begin
            an    = 4'b1110;
            digit = ones[3:0];
        end

        2'b01: begin
            an    = 4'b1101;
            digit = tens[3:0];
        end

        2'b10: begin
            an    = 4'b1011;
            digit = hundreds[3:0];
        end

        2'b11: begin
            an    = 4'b0111;
            digit = thousands[3:0];
        end

        default: begin
            an    = 4'b1111;
            digit = 4'd0;
        end

    endcase
end

hex_to_7seg h_timer(
    .hex(digit),
    .seg(seg)
);

endmodule
