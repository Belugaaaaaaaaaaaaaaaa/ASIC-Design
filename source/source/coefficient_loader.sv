// $Id: $
// File name:   coefficient_loader.sv
// Created:     3/21/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
 module coefficient_loader(
    input logic clk,
    input logic n_reset,
    input logic new_coefficient_set,
    input logic modwait,
	output logic clear,
    output logic load_coeff,
    output logic [1:0] coefficient_num
);
    logic [3:0] state;
    logic [3:0] nxt_state;
	logic [1:0] nxt_coefficient_num;
    always_ff @(posedge clk, negedge n_reset) begin
        if(1'b0 == n_reset) begin
            state <= 0;
			coefficient_num <= 0;
        end
        else begin
            state <= nxt_state;
			coefficient_num <= nxt_coefficient_num;
        end
    end

    always_comb begin
		clear = 1'b0;
		nxt_state = state;
		nxt_coefficient_num = coefficient_num;
		load_coeff = 0;
        case(state)
            0: begin 
                if(new_coefficient_set) begin
                    nxt_state = 1;
                end
                else begin
                    nxt_state = 0;
                end
            end
            1: begin
                if(modwait) begin
                    nxt_state = state;
                end
                else begin
                    nxt_coefficient_num = 2'd0;
                    load_coeff = 1'b1;
                    nxt_state = 2;
                end
            end
            2: begin
                load_coeff = 1'b1;
                nxt_state = 3;
            end
            3: begin
                if(modwait) begin
                    nxt_state = state;
                end
                else if(new_coefficient_set) begin
                    nxt_coefficient_num = 2'd1;
                    load_coeff = 1'b1;
                    nxt_state = 4;
                end
            end
            4: begin
                load_coeff = 1'b1;
                nxt_state = 5;
            end
            5: begin
				if(modwait) begin
                    nxt_state = state;
                end
                else if(new_coefficient_set) begin
                    nxt_coefficient_num = 2'd2;
                    load_coeff = 1'b1;
                    nxt_state = 6;
                end
            end
			6: begin
					load_coeff = 1'b1;
					nxt_state = 7;
				end
			7: begin
				if(modwait) begin
                    nxt_state = state;
                end
                else if(new_coefficient_set) begin
                    nxt_coefficient_num = 2'd3;
                    load_coeff = 1'b1;
                    nxt_state = 8;
                end
			end
			8: begin
					load_coeff = 1'b1;
					nxt_state = 9;
				end
			9:begin
				clear = 1;
				nxt_coefficient_num = 0;
				nxt_state = 0;
				load_coeff = 0;
			end
        endcase
    end
endmodule 