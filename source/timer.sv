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
    output logic shift_strobe,
    output logic packet_done
);
    flex_counter f1(.clk(clk), .n_rst(n_rst), .clear((!enable_timer | packet_done)), .count_enable(enable_timer), .rollover_val(4'd10), .rollover_flag(shift_strobe));
    flex_counter f2(.clk(clk), .n_rst(n_rst), .clear((!enable_timer | packet_done)), .count_enable(shift_strobe), .rollover_val(4'd9), .rollover_flag(packet_done));

endmodule