// $Id: $
// File name:   counter.sv
// Created:     2/23/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module counter(
    input logic clk,
    input logic n_rst,
    input logic cnt_up,
    input logic clear,
    output logic one_k_samples
);
    flex_counter #(.NUM_CNT_BITS(10)) fc (.clk(clk), .n_rst(n_rst), .rollover_val(10'd1000), .count_enable(cnt_up), .rollover_flag(one_k_samples));
endmodule