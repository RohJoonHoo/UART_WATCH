module command_to_btn (
    input clk,
    input reset,
    input [7:0] fifo_rx_data,
    input fifo_empty,
    output reg fifo_rd_en,
    output reg run,
    output reg clear,
    output reg hour,
    output reg min,
    output reg sec
);

    reg [3:0] state;
    parameter IDLE = 4'd0, PROCESS = 4'd1, RUN_STATE = 4'd2, CLEAR_STATE = 4'd3,
              HOUR_STATE = 4'd4, MIN_STATE = 4'd5, SEC_STATE = 4'd6, WAIT = 4'd7;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            fifo_rd_en <= 0;
            run <= 0;
            clear <= 0;
            hour <= 0;
            min <= 0;
            sec <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (!fifo_empty) begin
                        fifo_rd_en <= 1;
                        state <= PROCESS;
                    end
                end
                PROCESS: begin
                    fifo_rd_en <= 0;
                    case (fifo_rx_data)
                        8'h52, 8'h72: state <= RUN_STATE;  // 'R', 'r'
                        8'h43, 8'h63: state <= CLEAR_STATE;  // 'C', 'c'
                        8'h48, 8'h68: state <= HOUR_STATE;  // 'H', 'h'
                        8'h4D, 8'h6D: state <= MIN_STATE;  // 'M', 'm'
                        8'h53, 8'h73: state <= SEC_STATE;  // 'S', 's'
                        default: state <= WAIT;
                    endcase
                end
                RUN_STATE: begin
                    run   <= 1;
                    state <= WAIT;
                end
                CLEAR_STATE: begin
                    clear <= 1;
                    state <= WAIT;
                end
                HOUR_STATE: begin
                    hour  <= 1;
                    state <= WAIT;
                end
                MIN_STATE: begin
                    min   <= 1;
                    state <= WAIT;
                end
                SEC_STATE: begin
                    sec   <= 1;
                    state <= WAIT;
                end
                WAIT: begin
                    run   <= 0;
                    clear <= 0;
                    hour  <= 0;
                    min   <= 0;
                    sec   <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
