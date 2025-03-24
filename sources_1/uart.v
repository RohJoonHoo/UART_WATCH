`timescale 1ns / 1ps

module TOP_UART (
    input clk,
    input reset,
    input rx,
    output tx,
    output [7:0] seg,
    output [3:0] seg_comm
);
    wire w_rx_done;
    wire [7:0] w_rx_data;
    assign seg_comm = 4'b1110;

    uart U_UART_1(
        .clk(clk),
        .reset(reset),

    //tx
        .btn_start(w_rx_done),
        .tx_data_in(w_rx_data),
        .tx(tx),
        .o_tx_done(),

    //rx
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data)
    );

endmodule

module uart (
    input clk,
    input reset,

    //tx
    input        btn_start,
    input  [7:0] tx_data_in,
    output       tx,
    output       o_tx_done,

    //rx
    input        rx,
    output       rx_done,
    output [7:0] rx_data
);
    wire w_tick;

    baud_tick_gen U_BAUD_Tick_Gen (
        .clk(clk),
        .reset(reset),
        .baud_tick(w_tick)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .start_trigger(btn_start),
        .data_in(tx_data_in),
        .o_tx(tx),
        .o_tx_done(o_tx_done)
    );
    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .rx(rx),
        .rx_done(rx_done),
        .rx_data(rx_data)
    );

endmodule

module uart_tx (
    input clk,
    input reset,
    input tick,
    input start_trigger,
    input [7:0] data_in,
    output o_tx,
    output o_tx_done
);
    // fsm
    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter DATA = 2'b10;
    parameter STOP = 2'b11;
    reg [7:0] data_in_reg, data_in_next;
    reg [2:0] state, next_state;
    reg tx_reg, tx_next;
    reg tx_done, tx_done_next;

    reg [2:0] data_counter, data_counter_next;
    reg [3:0] tick_count_reg, tick_count_next;

    assign o_tx = tx_reg;
    assign o_tx_done = tx_done;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 1'b0;
            tx_reg <= 1'b1;
            tx_done <= 1'b0;
            data_counter <= 3'b000;
            tick_count_reg <= 4'h0;
            data_in_reg <= 0;
        end else begin
            state <= next_state;
            tx_reg <= tx_next;
            tx_done <= tx_done_next;
            data_counter <= data_counter_next;
            tick_count_reg <= tick_count_next;
            data_in_reg <= data_in_next;
        end
    end

    always @(*) begin
        next_state = state;
        tx_next = tx_reg;
        tx_done_next = tx_done;
        data_counter_next = data_counter;
        tick_count_next = tick_count_reg;
        data_in_next = data_in_reg;
        case (state)
            IDLE: begin
                tx_next = 1'b1;
                tx_done_next = 1'b0;
                tick_count_next = 4'h0;
                if (start_trigger) begin
                    next_state = START;
                    data_in_next = data_in;
                end
            end
            START: begin
                tx_done_next = 1'b1;
                tx_next = 1'b0;
                if (tick == 1'b1) begin
                    if (tick_count_reg == 4'hf) begin
                        next_state = DATA;
                        data_counter_next = 3'b000;
                        tick_count_next = 4'h0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_in_reg[data_counter];
                if (tick == 1'b1) begin
                    if (tick_count_reg == 4'hf) begin
                        tick_count_next = 4'h0;
                        if (data_counter == 3'b111) begin
                            next_state = STOP;
                        end else begin
                            next_state = DATA;
                            data_counter_next = data_counter + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (tick == 1'b1) begin
                    if (tick_count_reg == 4'hf) begin
                        next_state = IDLE;
                        tick_count_next = 4'h0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module uart_rx (
    input        clk,
    input        reset,
    input        tick,
    input        rx,
    output       rx_done,
    output [7:0] rx_data
);
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] state, next_state;
    reg rx_done_reg, rx_done_next;
    reg [2:0] bit_count_reg, bit_count_next;
    reg [4:0] tick_count_reg, tick_count_next;
    reg [7:0] rx_data_reg, rx_data_next;

    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    // state
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state          <= 0;
            rx_done_reg    <= 0;
            rx_data_reg    <= 0;
            bit_count_reg  <= 0;
            tick_count_reg <= 0;
        end else begin
            state          <= next_state;
            rx_done_reg    <= rx_done_next;
            rx_data_reg    <= rx_data_next;
            bit_count_reg  <= bit_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    always @(*) begin
        next_state = state;
        tick_count_next = tick_count_reg;
        bit_count_next = bit_count_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = rx_done_reg;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                bit_count_next  = 0;
                rx_done_next = 0;
                if (rx == 1'b0) begin
                    next_state = START;
                end
            end
            START: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 7) begin
                        next_state = DATA;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 15) begin
                        rx_data_next[bit_count_reg] = rx;
                        tick_count_next = 0;
                        if (bit_count_reg == 7) begin
                            next_state = STOP;
                            bit_count_next = 0;
                        end else begin
                            next_state = DATA;
                            bit_count_next = bit_count_reg + 1;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (tick == 1'b1) begin
                    if (tick_count_reg == 23) begin
                        rx_done_next = 1'b1;
                        next_state = IDLE;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module baud_tick_gen (
    input  clk,
    input  reset,
    output baud_tick
);

    parameter BAUD_RATE = 9600;
    localparam BAUD_COUNT = (100_000_000 / BAUD_RATE) / 16;
    reg [$clog2(BAUD_COUNT)-1 : 0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign baud_tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = tick_reg + 1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end
endmodule
