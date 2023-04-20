// $Id: $
// File name:   rcu.sv
// Created:     2/17/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module rcu(
    input logic clk,
    input logic n_rst,
    input logic new_packet_detected,
    input logic framing_error,
    input logic packet_done,
    output logic sbc_clear,
    output logic sbc_enable,
    output logic load_buffer,
    output logic enable_timer
);
    typedef enum logic [3:0] {S0, S1, S2, S3, S4, S5} state_type;
    state_type state, next; 
    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 0) begin
            state <= S0;
        end 
        else begin
            state <=next;
        end
    end
    assign sbc_clear = (state == S1);
    assign sbc_enable = (state == S3);
    assign enable_timer = (state == S2);
    assign load_buffer = (state == S5);
    always_comb begin
        next = state;
        case(state)
            S0: begin
                if(new_packet_detected == 1) begin
                    next = S1;
                end
                else begin
                    next = S0;

                end
            end
            S1: begin
                //sbc_clear = 1;
                next = S2;
            end
            S2: begin
                //enable_timer = 1;
                if(packet_done) begin
                    next = S3;
                end 
                else begin
                    next = S2;
                end
            end
            S3: begin
                //sbc_enable = 1;
                next = S4;
            end
            S4: begin
                next = framing_error ? S0 : S5;
            end
            S5: begin
                //load_buffer = 1;
                next = S0;
            end
        endcase
    end
    endmodule