// $Id: $
// File name:   ahb_lite_fir_filter.sv
// Created:     3/21/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module ahb_lite_fir_filter(
    input logic clk,
    input logic n_rst,
    input logic hsel,
    input logic [3:0] haddr,
    input logic hsize,
    input logic [1:0] htrans,
    input logic hwrite,
    input logic [15:0] hwdata,
    output logic [15:0] hrdata,
    output logic hresp
);
    logic err;
    logic data_ready;
    logic [15:0] sample_data;
    logic modwait;
    logic new_coefficient_set;
    logic load_coeff;
    logic [1:0]coefficient_num;
    logic [15:0] fir_coefficient;
    logic [15:0] fir_out;
    logic clear;

    ahb_lite_slave s1(.clk(clk), .n_rst(n_rst), .sample_data(sample_data), .clear(clear),.data_ready(data_ready),
    .new_coefficient_set(new_coefficient_set), .fir_coefficient(fir_coefficient), .modwait(modwait),
    .fir_out(fir_out), .err(err), .hsel(hsel), .haddr(haddr), .hsize(hsize), .htrans(htrans), .hwrite(hwrite),
    .hwdata(hwdata), .hrdata(hrdata), .hresp(hresp),.coefficient_num(coefficient_num));

    fir_filter f1(.clk(clk), .n_reset(n_rst), .sample_data(sample_data),
    .data_ready(data_ready), .fir_coefficient(fir_coefficient), .load_coeff(load_coeff),
    .modwait(modwait), .fir_out(fir_out), .err(err));

    coefficient_loader l1(.clk(clk), .n_reset(n_rst), .new_coefficient_set(new_coefficient_set),
    .load_coeff(load_coeff), .modwait(modwait), .coefficient_num(coefficient_num),.clear(clear));
endmodule
