`timescale 1ns / 1ps

module Top_project (
    input clk,
    input reset,
    input [1:0] sw,
    input btnL,
    btnR,
    btnU,
    btnD,
    input rx,
    output tx,
    output [3:0] led,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
);

    wire [7:0] fifo_rx_data;
    wire fifo_empty, fifo_rd_en;
    wire run, clear, hour, min, sec;

    uart_fifo UART_FIFO (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx),
        .fifo_rx_data(fifo_rx_data),
        .fifo_empty(fifo_empty),
        .rd_en(fifo_rd_en)
    );

    command_to_btn CMD_PROC (
        .clk(clk),
        .reset(reset),
        .fifo_rx_data(fifo_rx_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .run(run),
        .clear(clear),
        .hour(hour),
        .min(min),
        .sec(sec)
    );

    Top_stopwatch STOPWATCH (
        .clk(clk),
        .reset(reset),
        .btnL(btnL),
        .btnR(btnR),
        .btnU(btnU),
        .btnD(btnD),
        .sw_mode(sw[1]),
        .sw_time_mode(sw[0]),
        .w_pc_run(run),
        .w_pc_clear(clear),
        .w_pc_hour(hour),
        .w_pc_min(min),
        .w_pc_sec(sec),
        .led(led),
        .fnd_comm(fnd_comm),
        .fnd_font(fnd_font)
    );


endmodule
