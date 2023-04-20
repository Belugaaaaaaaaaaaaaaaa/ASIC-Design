// $Id: $
// File name:   mealy.sv
// Created:     2/10/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module mealy(
    input logic clk,
    input logic n_rst,
    input logic i,
    output logic o
);
typedef enum logic [1:0] {S0,S1,S2,S3} state_type;
state_type state, next; 
    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 0) begin
            state <= S0;
        end 
        else begin
            state <=next;
        end
    end
always_comb begin
    next = state;
    o = 0;
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
            next = S1;
            o = 1;
            end
            else begin
                next = S0;
            end
        end
    endcase
end
endmodule