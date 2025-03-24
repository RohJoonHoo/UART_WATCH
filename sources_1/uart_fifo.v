`timescale 1ns / 1ps

module uart_fifo (
    input  clk,
    input  reset,
    input  rx,
    input rd_en,
    output fifo_empty,
    output tx,
    output [7:0]fifo_rx_data
);

    wire w_tick;
    wire w_rx_done;
    wire w_tx_done;
    wire tx_empty;
    wire [7:0] w_rx_data;
//    wire [7:0] fifo_rx_data;
    wire [7:0] fifo_tx_data;

    baud_tick_gen TICK_GEN (
        .clk(clk),
        .reset(reset),
        .baud_tick(w_tick)
    );

    uart_rx UART_RX (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data)
    );

    fifo FIFO_RX (
        .clk(clk),
        .reset(reset),
        .wdata(w_rx_data),
        .wr(w_rx_done),
        .full(),
        .rd(rd_en),
        .rdata(fifo_rx_data),
        .empty(fifo_empty)
    );

    fifo FIFO_TX (
        .clk(clk),
        .reset(reset),
        .wdata(fifo_rx_data),
        .wr(~fifo_empty & rd_en),
        .full(),
        .rd(~w_tx_done),
        .rdata(fifo_tx_data),
        .empty(tx_empty)
    );

    uart_tx UART_TX (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .start_trigger(~tx_empty),
        .data_in(fifo_tx_data),
        .o_tx(tx),
        .o_tx_done(w_tx_done)
    );
endmodule
