// $Id: $
// File name:   rcv_block.sv
// Created:     2/16/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module rcv_block(
    input logic clk,
    input logic n_rst,
    input logic serial_in,
    input logic data_read,
    output logic [7:0] rx_data,
    output logic data_ready,
    output logic overrun_error,
    output logic framing_error
);
    logic load_buffer;
    logic packet_done;
    logic sbc_clear;
    logic sbc_enable;
    logic stop_bit;
    logic enable_timer;
    logic shift_strobe;
    logic new_packet_detected;
    logic [7:0] packet_data;

    rx_data_buff r1(.clk(clk), .n_rst(n_rst), .packet_data(packet_data), .load_buffer(load_buffer), .data_read(data_read), .rx_data(rx_data), .data_ready(data_ready), .overrun_error(overrun_error));
    stop_bit_chk c1(.clk(clk), .n_rst(n_rst), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .stop_bit(stop_bit), .framing_error(framing_error));
    timer t1(.clk(clk), .n_rst(n_rst), .enable_timer(enable_timer), .shift_strobe(shift_strobe), .packet_done(packet_done));
    rcu rc(.clk(clk), .n_rst(n_rst), .new_packet_detected(new_packet_detected), .packet_done(packet_done), .framing_error(framing_error), .sbc_clear(sbc_clear), .sbc_enable(sbc_enable), .load_buffer(load_buffer), .enable_timer(enable_timer));
    sr_9bit sr(.clk(clk), .n_rst(n_rst), .shift_strobe(shift_strobe), .serial_in(serial_in), .packet_data(packet_data), .stop_bit(stop_bit));
    start_bit_det det(.clk(clk), .n_rst(n_rst), .serial_in(serial_in), .new_packet_detected(new_packet_detected));
endmodule