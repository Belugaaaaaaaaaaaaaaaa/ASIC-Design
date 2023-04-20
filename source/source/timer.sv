// $Id: $
// File name:   timer.sv
// Created:     2/16/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module timer(
    input logic clk,
    input logic n_rst,
    input logic enable_timer,
    input logic [3:0]data_size,
    input logic [13:0] bit_period,
    output logic shift_strobe,
    output logic packet_done
);
    flex_counter #(.NUM_CNT_BITS(14))f1(.clk(clk), .n_rst(n_rst), .clear((!enable_timer | packet_done)), .count_enable(enable_timer), .rollover_val(bit_period), .rollover_flag(shift_strobe));
    flex_counter #(.NUM_CNT_BITS(4))f2(.clk(clk), .n_rst(n_rst), .clear((!enable_timer | packet_done)), .count_enable(shift_strobe), .rollover_val(data_size+1'b1), .rollover_flag(packet_done));

endmodule
