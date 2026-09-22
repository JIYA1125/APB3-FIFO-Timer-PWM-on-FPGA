`timescale 1ns / 1ps

module top #(
    parameter integer TIMER_CLK_PER_SEC = 100_000_000,
    parameter integer DEBOUNCE_COUNT_MAX = 1_000_000
)(
    input wire clk,
    input wire rst,

    input wire [15:0] sw,

    input wire btnU,
    input wire btnD,

    output wire [9:0] led,
    output wire [3:0] an,
    output wire [6:0] seg,

    output wire pwm_out,
    output wire tx
);

    // =====================================================
    // BUTTON SIGNALS
    // =====================================================

    wire wr_db;
    wire rd_db;

    wire wr_pulse;
    wire rd_pulse;


    debounce #(
        .COUNT_MAX(DEBOUNCE_COUNT_MAX)
    ) D1 (
        .clk(clk),
        .rst(rst),
        .btn(btnU),
        .btn_db(wr_db)
    );


    debounce #(
        .COUNT_MAX(DEBOUNCE_COUNT_MAX)
    ) D2 (
        .clk(clk),
        .rst(rst),
        .btn(btnD),
        .btn_db(rd_db)
    );


    edge_detector E1 (
        .clk(clk),
        .rst(rst),
        .signal_in(wr_db),
        .pulse(wr_pulse)
    );


    edge_detector E2 (
        .clk(clk),
        .rst(rst),
        .signal_in(rd_db),
        .pulse(rd_pulse)
    );


    // =====================================================
    // SWITCH SYNCHRONIZATION
    // =====================================================

    reg [15:0] sw_ff1;
    reg [15:0] sw_ff2;
    reg [15:0] last_sw;

    wire sw_changed;

    always @(posedge clk or posedge rst) begin

        if(rst) begin
            sw_ff1  <= 16'h0000;
            sw_ff2  <= 16'h0000;
            last_sw <= 16'h0000;
        end

        else begin
            sw_ff1  <= sw;
            sw_ff2  <= sw_ff1;
            last_sw <= sw_ff2;
        end

    end

    assign sw_changed = (sw_ff2 != last_sw);


    // =====================================================
    // APB MASTER SIGNALS
    // =====================================================

    wire apb_start;
    wire apb_rw;

    wire [15:0] command_data;

    wire psel;
    wire penable;
    wire pwrite;

    wire [7:0] paddr;
    wire [7:0] pwdata;

    wire [7:0] read_data;

    wire done;
    wire master_error;


    assign apb_start = wr_pulse || rd_pulse || sw_changed;

    assign apb_rw = wr_pulse || sw_changed;

    assign command_data = sw_ff2;


    apb3_master MASTER (

        .clk(clk),
        .rst(rst),

        .start(apb_start),
        .rw(apb_rw),

        .command_data(command_data),

        .pready(pready),
        .pslverr(pslverr),
        .prdata(prdata),

        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),

        .paddr(paddr),
        .pwdata(pwdata),

        .read_data(read_data),

        .done(done),
        .error(master_error)

    );


    // =====================================================
    // APB DECODER
    // =====================================================

    wire uart_sel;
    wire gpio_sel;
    wire fifo_sel;
    wire pwm_sel;
    wire error_sel;


    apb3_decoder DECODER (

        .psel(psel),
        .paddr(paddr),

        .uart_sel(uart_sel),
        .gpio_sel(gpio_sel),
        .fifo_sel(fifo_sel),
        .pwm_sel(pwm_sel),
        .error_sel(error_sel)

    );


    // =====================================================
    // FIFO SIGNALS
    // =====================================================

    wire [7:0] fifo_prdata;
    wire fifo_pready;
    wire fifo_pslverr;

    wire fifo_wr_en;
    wire fifo_rd_en;

    wire [7:0] fifo_data_in;
    wire [7:0] fifo_data_out;

    wire fifo_full;
    wire fifo_empty;

    wire [3:0] fifo_count;


    apb_fifo_slave FIFO_SLAVE (

        .clk(clk),
        .rst(rst),

        .psel(fifo_sel),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),

        .prdata(fifo_prdata),
        .pready(fifo_pready),
        .pslverr(fifo_pslverr),

        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),

        .data_in(fifo_data_in),
        .data_out(fifo_data_out),

        .full(fifo_full),
        .empty(fifo_empty)

    );


    FIFO FIFO_MEMORY (

        .clk(clk),
        .rst(rst),

        .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en),

        .data_in(fifo_data_in),
        .data_out(fifo_data_out),

        .full(fifo_full),
        .empty(fifo_empty),

        .count(fifo_count)

    );


    // =====================================================
    // TIMER
    // =====================================================

    wire [15:0] timer_seconds;
    wire timer_running;


    elapsed_timer #(
        .CLK_PER_SEC(TIMER_CLK_PER_SEC)
    ) TIMER (

        .clk(clk),
        .rst(rst),

        .start_event(fifo_wr_en),
        .stop_event(fifo_rd_en),

        .elapsed_seconds(timer_seconds),
        .running(timer_running)

    );


    // =====================================================
    // TIMER DISPLAY
    // =====================================================

    timer_display_mux TIMER_DISPLAY (

        .clk(clk),
        .value(timer_seconds),

        .an(an),
        .seg(seg)

    );


    // =====================================================
    // PWM
    // =====================================================

    wire [7:0] pwm_prdata;
    wire pwm_pready;
    wire pwm_pslverr;


    pwm_slave PWM (

        .clk(clk),
        .rst(rst),

        .psel(pwm_sel),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),

        .prdata(pwm_prdata),
        .pready(pwm_pready),
        .pslverr(pwm_pslverr),

        .pwm_out(pwm_out)

    );


    // =====================================================
    // UART
    // =====================================================

    wire [7:0] uart_prdata;
    wire uart_pready;
    wire uart_pslverr;

    wire [7:0] uart_tx_data;
    wire uart_tx_valid;

    wire [7:0] uart_rx_data;
    wire uart_rx_valid;

    assign uart_rx_data  = 8'h00;
    assign uart_rx_valid = 1'b0;


    uart_slave UART (

        .PCLK(clk),
        .PRESETn(~rst),

        .PSEL(uart_sel),
        .PENABLE(penable),
        .PWRITE(pwrite),

        .PADDR(paddr),
        .PWDATA(pwdata),

        .PRDATA(uart_prdata),
        .PREADY(uart_pready),
        .PSLVERR(uart_pslverr),

        .uart_rx_data(uart_rx_data),
        .uart_rx_valid(uart_rx_valid),

        .uart_tx_data(uart_tx_data),
        .uart_tx_valid(uart_tx_valid)

    );


    // =====================================================
    // BAUD GENERATOR
    // =====================================================

    wire rx_tick;
    wire tx_tick;


    baud_generator BAUD (

        .clk(clk),
        .rst(rst),

        .rx_tick(rx_tick),
        .tx_tick(tx_tick)

    );


    // =====================================================
    // UART TRANSMITTER
    // =====================================================

    wire tx_busy;


    uart_transmitter UART_TX (

        .clk(clk),
        .rst(rst),

        .tx_tick(tx_tick),

        .data_in(uart_tx_data),
        .tx_start(uart_tx_valid),

        .tx(tx),
        .tx_busy(tx_busy)

    );


    // =====================================================
    // APB RESPONSE MUX
    // =====================================================

    wire [7:0] prdata;
    wire pready;
    wire pslverr;


    assign pready =
        uart_sel  ? uart_pready  :
        fifo_sel  ? fifo_pready  :
        pwm_sel   ? pwm_pready   :
        error_sel ? 1'b1         :
                    1'b1;


    assign pslverr =
        uart_sel  ? uart_pslverr :
        fifo_sel  ? fifo_pslverr :
        pwm_sel   ? pwm_pslverr  :
        error_sel ? 1'b1         :
                    1'b0;


    assign prdata =
        uart_sel ? uart_prdata :
        fifo_sel ? fifo_prdata :
        pwm_sel  ? pwm_prdata  :
                   8'h00;


    // =====================================================
    // LED DEBUG OUTPUTS
    // =====================================================

    assign led[0] = psel;
    assign led[1] = penable;
    assign led[2] = pwrite;
    assign led[3] = done;

    assign led[4] = timer_running;

    assign led[5] = wr_pulse;
    assign led[6] = rd_pulse;

    assign led[7] = fifo_full;
    assign led[8] = fifo_empty;

    assign led[9] = pwm_out;


endmodule
