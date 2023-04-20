// $Id: $
// File name:   controller.sv
// Created:     2/23/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module controller(
    input logic clk,
    input logic n_rst,
    input logic dr,
    input logic lc,
    input logic overflow,
    output logic cnt_up,
    output logic clear,
    output logic modwait,
    output logic [2:0] op,
    output logic [3:0] src1,
    output logic [3:0] src2,
    output logic [3:0] dest,
    output logic err
);
    typedef enum logic [4:0] {idle, cs, cs1, cs2, cs3, cs4, store, zero, s1, s2, s3, s4, mul1, a1, mul2, sub1, mul3, a2, mul4, sub2, eidle} state_type;
    state_type state, nxt;
    logic nxt_wait;
    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 1'b0) begin
            state <= idle;
            modwait <= 0;
        end
        else begin
            state <= nxt;
            modwait <= nxt_wait;
        end
    end

    always_comb begin
        clear = lc;
        nxt = state;
        nxt_wait = 1'b0;
        err = 0;
        cnt_up = 0;
        op = 3'b000;
        src1 = 4'd0;
        src2 = 4'd0;
        dest = 4'd0;
        case(state)
            idle:begin
                op = 3'b000;
                nxt_wait = 0;
                err = 0;
                if(lc == 1'b1) begin
                    nxt = cs;
                end
                else if(dr == 1'b1) begin
                    nxt = store;
                end
                else begin
                    nxt = idle;
                end
            end
            cs:begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b011;
                nxt = cs1;
                src1 = 4'd0;
                src2 = 4'd0;
                dest = 4'd15;
                err = 0;
                cnt_up = 0;
            end
            cs1:begin
                clear = lc;
                nxt_wait = 1;
                nxt = cs2;
                src1 = 4'd13;
                src2 = 0;
                dest = 4'd14;
                op = 001;
            end
            cs2:begin
                clear = lc;
                nxt_wait = 1;
                nxt = cs3;
                src1 = 4'd12;
                src2 = 0;
                cnt_up = 0;
                dest = 4'd13;
                op = 3'b001;
            end
            cs3:begin
                clear = lc;
                nxt_wait = 1;
                nxt = cs4;
                src1 = 4'd11;
                src2 = 4'd0;
                dest = 4'd12;
                op = 001;
                err = 0;
                cnt_up = 0;
            end
            cs4:begin
                clear = lc;
                nxt_wait = 1;
                nxt = idle;
                src1 = 4'd15;
                src2 = 4'd0;
                dest = 4'd11;
                op = 3'b001;
                err = 0;
                cnt_up = 0;
            end
            store: begin
                clear = lc;
                op = 3'b010;
                cnt_up = 1;
                src1 = 0;
                src2 = 0;
                nxt_wait = 1;
                dest = 4'd10;
                if(dr == 1'b1) begin
                    nxt = zero;
                    op = 3'b010;
                end
                else begin
                    nxt = eidle;
                end
            end
            zero: begin
                nxt_wait = 1;
                clear = lc;
                cnt_up = 0;
                op = 3'b101;
                dest = 4'd0;
                src1 = 4'd0;
                src2 = 4'd0;
                nxt = s1;
                err = 0;
            end
            s1:begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b001;
                src1 = 4'd3;
                src2 = 4'd0;
                dest = 4'd4;
                cnt_up = 0;
                nxt = s2;
            end
            s2:begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b001;
                src1 = 4'd2;
                src2 = 4'd0;
                dest = 4'd3;
                cnt_up = 0;
                nxt = s3;
                err = 0;
            end
            s3:begin
                nxt_wait = 1;
                clear = lc;
                op = 001;
                src1 = 4'd1;
                src2 = 4'd0;
                dest = 4'd2;
                cnt_up = 0;
                nxt = s4;
                err = 0;
            end
            s4:begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b001;
                src1 = 4'd10;
                src2 = 4'd0;
                dest = 4'd1;
                cnt_up = 0;
                nxt = mul1;
                err = 0;
            end
            mul1: begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b110;
                src1 = 4'd1;
                src2 = 4'd11;
                dest = 4'd9;
                nxt = sub1;
                cnt_up = 0;
            end
            sub1:begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b101;
                src1 = 4'd0;
                src2 = 4'd9;
                dest = 4'd0;
                err = 0;
                if(overflow) begin
                    nxt = eidle;
                end
                else begin
                    nxt = mul2;
                end
            end
            
            mul2: begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b110;
                src1 = 4'd2;
                src2 = 4'd12;
                dest = 4'd9;
                nxt = a1;
                err = 0;
            end
            a1: begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b100;
                src1 = 4'd0;
                src2 = 4'd9;
                dest = 4'd0;
                if(overflow) begin
                    nxt = eidle;
                end
                else begin
                    nxt = mul3;
                end
            end
            
            mul3: begin
                clear = lc;
                nxt_wait = 1;
                cnt_up = 0;
                op = 3'b110;
                src1 = 4'd3;
                src2 = 4'd13;
                dest = 4'd9;
                nxt = sub2;
                err = 0;
            end
            sub2:begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b101;
                src1 = 4'd0;
                src2 = 4'd9;
                dest = 4'd0;
                if(overflow) begin
                    nxt = eidle;
                    op = 3'b101;  
                end
                else begin
                    nxt = mul4;
                end
            end
            
            mul4: begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b110;
                src1 = 4'd4;
                src2 = 4'd14;
                dest = 4'd9;
                nxt = a2;
            end
            a2: begin
                nxt_wait = 1;
                clear = lc;
                op = 3'b100;
                src1 = 4'd9;
                src2 = 4'd0;
                dest = 4'd0;
                if(overflow) begin
                    nxt = eidle;
                end
                else begin
                    nxt = idle;
                end
            end
            eidle: begin
                nxt_wait = 0;
                op = 3'b000;
                cnt_up = 0;
                clear = lc;
                err = 1;
                if(dr) begin
                    nxt = store;
                end
                else begin
                    nxt = eidle;
                end
            end
        endcase
    end
endmodule
