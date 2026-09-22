`timescale 1ns / 1ps

module elapsed_timer #(
    parameter integer CLK_PER_SEC = 100_000_000
)(
    input wire clk,
    input wire rst,

    input wire start_event,
    input wire stop_event,

    output reg [15:0] elapsed_seconds,
    output reg running
);

integer tick_count;

always @(posedge clk or posedge rst) begin

    if(rst) begin

        tick_count      <= 0;
        elapsed_seconds <= 16'd0;
        running         <= 1'b0;

    end

    else begin

        // READ FIFO = STOP TIMER
        if(stop_event) begin
            running <= 1'b0;
        end

        // FIRST VALID FIFO WRITE = START TIMER
        else if(start_event && !running) begin

            running         <= 1'b1;
            elapsed_seconds <= 16'd1;
            tick_count      <= 0;

        end

        // TIMER RUNNING
        else if(running) begin

            if(tick_count == CLK_PER_SEC - 1) begin

                tick_count <= 0;

                if(elapsed_seconds < 16'd9999)
                    elapsed_seconds <= elapsed_seconds + 1'b1;

            end

            else begin
                tick_count <= tick_count + 1;
            end

        end
    end

end

endmodule
