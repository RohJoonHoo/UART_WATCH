module Top_stopwatch (
    input clk,
    input reset,
    input btnL,
    input btnR,
    input btnU,
    input btnD,
    input sw_mode,
    input sw_time_mode,
    input w_pc_run,
    input w_pc_clear,
    input w_pc_hour,
    input w_pc_min,
    input w_pc_sec,
    output [3:0] led,
    output [3:0] fnd_comm,
    output [7:0] fnd_font
);

    assign led = (sw_mode)? (sw_time_mode)?4'b1000:4'b0100:(sw_time_mode)?4'b0010:4'b0001;

    wire w_btnL, w_btnR, run, clear;
    wire btn_L, btn_R, btn_U, btn_D;
    wire [6:0] s_msec, s_sec, s_min, s_hour;
    wire [6:0] w_msec, w_sec, w_min, w_hour;
    wire [6:0] o_msec, o_sec, o_min, o_hour;

    btn_debounce U_btn_left (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );

    btn_debounce U_btn_right (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );

    btn_debounce U_btn_up (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );

    btn_debounce U_btn_down (
        .clk  (clk),
        .reset(reset),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );

    assign btn_L = w_btnL | w_pc_run | w_pc_hour;
    assign btn_R = w_btnR | w_pc_clear;
    assign btn_U = w_btnU | w_pc_sec;
    assign btn_D = w_btnD | w_pc_min;


    stopwatch_cu Stopwatch_CU (
        .clk(clk),
        .reset(reset),
        .mode(sw_mode),
        .i_btn_run(btn_L),
        .i_btn_clear(btn_R),
        .o_run(run),
        .o_clear(clear)
    );

    stopwatch_dp Stopwatch_DP (
        .clk  (clk),
        .reset(reset),
        .run  (run),
        .clear(clear),
        .msec (s_msec),
        .sec  (s_sec),
        .min  (s_min),
        .hour (s_hour)
    );


    watch_cu U_Watch_CU (
        .clk(clk),
        .reset(reset),
        .mode(sw_mode),
        .i_btn_sec(btn_U),
        .i_btn_min(btn_D),
        .i_btn_hour(btn_L),
        .o_btn_sec(w_btn_sec),
        .o_btn_min(w_btn_min),
        .o_btn_hour(w_btn_hour)
    );


    watch_dp Watch_DP (
        .clk(clk),
        .reset(reset),
        .btn_sec(w_btn_sec),
        .btn_min(w_btn_min),
        .btn_hour(w_btn_hour),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );

    mux_2x1_watch U_mux_watch_sw (
        .sel(sw_mode),
        .s_msec(s_msec),
        .s_sec(s_sec),
        .s_min(s_min),
        .s_hour(s_hour),
        .w_msec(w_msec),
        .w_sec(w_sec),
        .w_min(w_min),
        .w_hour(w_hour),
        .o_msec(o_msec),
        .o_sec(o_sec),
        .o_min(o_min),
        .o_hour(o_hour)
    );

    fnd_controller U_Fnd_Ctrl (
        .clk(clk),
        .reset(reset),
        .sw_time_mode(sw_time_mode),
        .msec(o_msec),
        .sec(o_sec),
        .min(o_min),
        .hour(o_hour),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );

endmodule

module mux_2x1_watch (
    input sel,
    input [6:0] s_msec,
    input [6:0] s_sec,
    input [6:0] s_min,
    input [6:0] s_hour,
    input [6:0] w_msec,
    input [6:0] w_sec,
    input [6:0] w_min,
    input [6:0] w_hour,
    output reg [6:0] o_msec,
    output reg [6:0] o_sec,
    output reg [6:0] o_min,
    output reg [6:0] o_hour
);
    always @(*) begin
        case (sel)
            1'b0: begin
                o_msec = s_msec;
                o_sec  = s_sec;
                o_min  = s_min;
                o_hour = s_hour;
            end
            1'b1: begin
                o_msec = w_msec;
                o_sec  = w_sec;
                o_min  = w_min;
                o_hour = w_hour;
            end
        endcase
    end
endmodule

module watch_cu (
    input clk,
    input reset,
    input mode,
    input i_btn_sec,
    input i_btn_min,
    input i_btn_hour,
    output reg o_btn_sec,
    output reg o_btn_min,
    output reg o_btn_hour
);

    // fsm 구조로 CU를 설계
    parameter WATCH = 2'b00, SEC_UP = 2'b01, MIN_UP = 2'b10, HOUR_UP = 2'b11;

    reg [1:0] state, next;
    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= WATCH;
        end else begin
            state <= next;
        end
    end

    // next state
    always @(*) begin
        next = state;
        case (state)
            WATCH: begin
                if (mode & i_btn_sec) begin
                    next = SEC_UP;
                end else if (mode & i_btn_min) begin
                    next = MIN_UP;
                end else if (mode & i_btn_hour) begin
                    next = HOUR_UP;
                end
            end
            SEC_UP: begin
                if (mode & i_btn_sec == 0) begin
                    next = WATCH;
                end
            end
            MIN_UP: begin
                if (mode & i_btn_min == 0) begin
                    next = WATCH;
                end
            end
            HOUR_UP: begin
                if (mode & i_btn_hour == 0) begin
                    next = WATCH;
                end
            end
            default: next = state;
        endcase
    end

    // output
    always @(*) begin
        o_btn_sec  = 0;
        o_btn_min  = 0;
        o_btn_hour = 0;
        case (state)
            WATCH: begin
                o_btn_sec  = 1'b0;
                o_btn_min  = 1'b0;
                o_btn_hour = 1'b0;
            end
            SEC_UP: begin
                o_btn_sec  = 1'b1;
                o_btn_min  = 1'b0;
                o_btn_hour = 1'b0;
            end
            MIN_UP: begin
                o_btn_sec  = 1'b0;
                o_btn_min  = 1'b1;
                o_btn_hour = 1'b0;
            end
            HOUR_UP: begin
                o_btn_sec  = 1'b0;
                o_btn_min  = 1'b0;
                o_btn_hour = 1'b1;
            end
        endcase
    end
endmodule

module watch_dp (
    input clk,
    input reset,
    input btn_sec,
    input btn_min,
    input btn_hour,
    output [6:0] msec,
    output [6:0] sec,
    output [6:0] min,
    output [6:0] hour
);

    wire w_clk_100hz, tick_sec, tick_min;


    clk_div_100 clk_div_100 (
        .clk  (clk),
        .reset(reset),
        .run  (1),
        .clear(0),
        .o_clk(w_clk_100hz)
    );

    time_show #(
        .TICK_COUNT(100),
        .INITIAL_VALUE(0)
    ) time_msec (
        .clk(clk),
        .reset(reset),
        .tick(w_clk_100hz),
        .btn_up(1'b0),
        .o_time(msec),
        .o_tick(tick_msec)
    );

    time_show #(
        .TICK_COUNT(60),
        .INITIAL_VALUE(0)
    ) time_sec (
        .clk(clk),
        .reset(reset),
        .tick(tick_msec),
        .btn_up(btn_sec),
        .o_time(sec),
        .o_tick(tick_sec)
    );
    time_show #(
        .TICK_COUNT(60),
        .INITIAL_VALUE(0)
    ) time_min (
        .clk(clk),
        .reset(reset),
        .tick(tick_sec),
        .btn_up(btn_min),
        .o_time(min),
        .o_tick(tick_min)
    );

    time_show #(
        .TICK_COUNT(24),
        .INITIAL_VALUE(12)
    ) time_hour (
        .clk(clk),
        .reset(reset),
        .tick(tick_min),
        .btn_up(btn_hour),
        .o_time(hour),
        .o_tick()
    );

endmodule


module time_show (
    input clk,
    input reset,
    input tick,
    input btn_up,
    output [6:0] o_time,
    output o_tick
);

    parameter TICK_COUNT = 100, INITIAL_VALUE = 0;

    reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign o_time = count_reg;
    assign o_tick = tick_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= INITIAL_VALUE;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next  = 1'b0;
        if (btn_up) begin
            count_next = count_reg + 1;
        end
        if (tick) begin
            if (count_reg == TICK_COUNT - 1) begin
                count_next = 0;
                tick_next  = 1'b1;
            end else begin
                count_next = count_reg + 1;
                tick_next  = 1'b0;
            end
        end

        // 버튼으로 인한 overflow방지
        if (count_next >= TICK_COUNT) begin
            count_next = 0;
            tick_next  = 1'b1;
        end
    end
endmodule

module stopwatch_cu (
    input clk,
    input reset,
    input mode,
    input i_btn_run,
    input i_btn_clear,
    output reg o_run,
    output reg o_clear
);

    // fsm 구조로 CU를 설계
    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    reg [1:0] state, next;
    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
        end else begin
            state <= next;
        end
    end

    // next state
    always @(*) begin
        next = state;
        case (state)
            STOP: begin
                if (!mode & i_btn_run) begin
                    next = RUN;
                end else if (!mode & i_btn_clear) begin
                    next = CLEAR;
                end
            end
            RUN: begin
                if (!mode & i_btn_run) begin
                    next = STOP;
                end
            end
            CLEAR: begin
                if (!mode & i_btn_clear == 0) begin
                    next = STOP;
                end
            end
            default: next = state;
        endcase
    end

    // output
    always @(*) begin
        o_run   = 0;
        o_clear = 0;
        case (state)
            STOP: begin
                o_run   = 1'b0;
                o_clear = 1'b0;
            end
            RUN: begin
                o_run   = 1'b1;
                o_clear = 1'b0;
            end
            CLEAR: begin
                o_clear = 1'b1;
            end
        endcase
    end
endmodule

module stopwatch_dp (
    input clk,
    input reset,
    input run,
    input clear,
    output [6:0] msec,
    output [6:0] sec,
    output [6:0] min,
    output [6:0] hour
);

    wire w_clk_100hz, tick_sec, tick_min;

    clk_div_100 clk_div_100 (
        .clk  (clk),
        .reset(reset),
        .run  (run),
        .clear(clear),
        .o_clk(w_clk_100hz)
    );

    time_counter #(
        .TICK_COUNT(100)
    ) time_counter_msec (
        .clk(clk),
        .reset(reset),
        .tick(w_clk_100hz),
        .clear(clear),
        .o_time(msec),
        .o_tick(tick_msec)
    );
    time_counter #(
        .TICK_COUNT(60)
    ) time_counter_sec (
        .clk(clk),
        .reset(reset),
        .tick(tick_msec),
        .clear(clear),
        .o_time(sec),
        .o_tick(tick_sec)
    );
    time_counter #(
        .TICK_COUNT(60)
    ) time_counter_min (
        .clk(clk),
        .reset(reset),
        .tick(tick_sec),
        .clear(clear),
        .o_time(min),
        .o_tick(tick_min)
    );
    time_counter #(
        .TICK_COUNT(24)
    ) time_counter_hour (
        .clk(clk),
        .reset(reset),
        .tick(tick_min),
        .clear(clear),
        .o_time(hour),
        .o_tick()
    );
endmodule

module time_counter (
    input clk,
    input reset,
    input tick,
    input clear,
    output [6:0] o_time,
    output o_tick
);

    parameter TICK_COUNT = 100;

    reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign o_time = count_reg;
    assign o_tick = tick_reg;


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
        tick_next  = 1'b0;
        if (clear) begin
            count_next = 0;
        end else if (tick) begin
            if (count_reg == TICK_COUNT - 1) begin
                count_next = 0;
                tick_next  = 1'b1;
            end else begin
                count_next = count_reg + 1;
                tick_next  = 1'b0;
            end

        end
    end

endmodule



module clk_div_100 (
    input  clk,
    input  reset,
    input  run,
    input  clear,
    output o_clk
);
    parameter FCOUNT = 1_000_000;  //100hz 가져오고 싶음
    reg [$clog2(FCOUNT)-1:0] count_reg, count_next;
    reg clk_reg, clk_next;
    // 출력을 f/f 으로 내보내기 위함 (sequencial한 output을 위함)

    assign o_clk = clk_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            clk_reg   <= 0;
        end else begin
            count_reg <= count_next;
            clk_reg   <= clk_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        clk_next   = clk_reg;
        if (clear == 1'b1) begin
            count_next = 0;
            clk_next   = 0;
        end else if (run == 1'b1) begin
            if (count_reg == FCOUNT - 1) begin
                count_next = 0;
                clk_next   = 1'b1;
            end else begin
                count_next = count_reg + 1;
                clk_next   = 1'b0;
            end
        end

    end

endmodule
