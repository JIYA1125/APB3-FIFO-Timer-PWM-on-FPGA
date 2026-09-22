`timescale 1ns / 1ps

module top_tb;

    reg clk;
    reg rst;

    reg [15:0] sw;

    reg btnU;
    reg btnD;

    wire [9:0] led;
    wire [3:0] an;
    wire [6:0] seg;

    wire pwm_out;
    wire tx;


    // =====================================================
    // DUT
    // =====================================================

    // IMPORTANT:
    //
    // 10 clocks = 1 simulated second
    //
    // This makes the timer easy to see in simulation.

    top #(
        .TIMER_CLK_PER_SEC(10),
        .DEBOUNCE_COUNT_MAX(2)
    ) dut (

        .clk(clk),
        .rst(rst),

        .sw(sw),

        .btnU(btnU),
        .btnD(btnD),

        .led(led),
        .an(an),
        .seg(seg),

        .pwm_out(pwm_out),
        .tx(tx)

    );


    // =====================================================
    // CLOCK
    // =====================================================

    // 100 MHz
    // Period = 10 ns

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst  = 1'b1;

        sw   = 16'h0000;

        btnU = 1'b0;
        btnD = 1'b0;


        // -------------------------------------------------
        // RESET
        // -------------------------------------------------

        #100;

        rst = 1'b0;


        // -------------------------------------------------
        // FIFO WRITE
        //
        // 16'hA520
        //
        // A5 = FIFO DATA
        // 20 = FIFO ADDRESS
        // -------------------------------------------------

        sw = 16'hA520;


        // Wait for switch synchronization
        // and APB transaction

        repeat(15)
            @(posedge clk);


        $display("--------------------------------------");
        $display("FIFO WRITE");
        $display("Timer running = %b", dut.timer_running);
        $display("Timer seconds = %d", dut.timer_seconds);
        $display("--------------------------------------");


        // -------------------------------------------------
        // TIMER RUNNING
        // -------------------------------------------------

        repeat(30)
            @(posedge clk);


        $display("--------------------------------------");
        $display("TIMER AFTER 30 CLOCKS");
        $display("Timer running = %b", dut.timer_running);
        $display("Timer seconds = %d", dut.timer_seconds);
        $display("--------------------------------------");


        // -------------------------------------------------
        // SECOND FIFO WRITE
        //
        // Timer MUST NOT restart.
        // -------------------------------------------------

        sw = 16'h5520;


        repeat(15)
            @(posedge clk);


        $display("--------------------------------------");
        $display("SECOND FIFO WRITE");
        $display("Timer running = %b", dut.timer_running);
        $display("Timer seconds = %d", dut.timer_seconds);
        $display("--------------------------------------");


        // -------------------------------------------------
        // LET TIMER CONTINUE
        // -------------------------------------------------

        repeat(20)
            @(posedge clk);


        $display("--------------------------------------");
        $display("BEFORE FIFO READ");
        $display("Timer running = %b", dut.timer_running);
        $display("Timer seconds = %d", dut.timer_seconds);
        $display("--------------------------------------");


        // -------------------------------------------------
        // FIFO READ
        //
        // btnD = READ
        // -------------------------------------------------

        btnD = 1'b1;


        repeat(5)
            @(posedge clk);


        btnD = 1'b0;


        // Wait for debounce,
        // edge detection and APB read

        repeat(15)
            @(posedge clk);


        $display("--------------------------------------");
        $display("FIFO READ");
        $display("Timer running = %b", dut.timer_running);
        $display("Timer seconds = %d", dut.timer_seconds);
        $display("--------------------------------------");


        // -------------------------------------------------
        // TIMER MUST REMAIN STOPPED
        // -------------------------------------------------

        repeat(30)
            @(posedge clk);


        $display("--------------------------------------");
        $display("AFTER WAITING");
        $display("Timer running = %b", dut.timer_running);
        $display("Timer seconds = %d", dut.timer_seconds);
        $display("--------------------------------------");


        $display("");
        $display("======================================");
        $display("       TIMER SIMULATION FINISHED");
        $display("======================================");


        $finish;

    end

endmodule
