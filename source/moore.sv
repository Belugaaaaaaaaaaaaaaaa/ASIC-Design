// $Id: $
// File name:   moore.sv
// Created:     2/10/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module moore(
    input logic clk,
    input logic n_rst,
    input logic i,
    output logic o
);
    typedef enum logic [2:0] {S0, S1, S2, S3, S4} state_type;
    state_type state, next; 
    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 0) begin
            state <= S0;
        end 
        else begin
            state <=next;
        end
    end

    assign o = (state == S4);

    always_comb begin
        next = state;
        //o = 0;
        case(state)
        S0: begin 
            if(i == 1) begin
            next = S1;
            end
            else begin
                next = S0;
            end
        end
        S1: begin 
            if(i == 1) begin
            next = S2;
            end
            else begin
                next = S0;
            end

        end
        S2: begin 
            if(i == 0) begin
            next = S3;
            end
            else begin
                next = S2;
            end

        end
        S3: begin 
            if(i == 1) begin
            next = S4;
            end
            else begin
                next = S0;
            end
        end
        S4: begin 
            if(i == 1) begin
            next = S2;
            end
            else begin
                next = S0;
            end
            //o = 1;
        end
        endcase
    end
endmodule
