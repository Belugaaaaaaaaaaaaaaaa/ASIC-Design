// $Id: $
// File name:   ahb_lite_slave.sv
// Created:     3/21/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module ahb_lite_slave(
    input logic clk,
    input logic n_rst,
    input logic [1:0] coefficient_num,
    input logic modwait,
    input logic [15:0]fir_out,
    input logic err,
    input logic hsel,
    input logic [3:0] haddr,
    input logic hsize,
    input logic [1:0] htrans,
    input logic clear,
    input logic hwrite,
    input logic [15:0] hwdata, 
    output logic [15:0] fir_coefficient,
    output logic [15:0] sample_data,
    output logic data_ready,
    output logic new_coefficient_set,
    output logic [15:0] hrdata,
    output logic hresp
);
    logic nxt_data_ready;
    logic nxt_new_coefficient_set;
    logic [3:0] [15:0] coefficient;
    logic [3:0] [15:0] nxt_fir_coefficient;
    logic [15:0] nxt_sample_data;
    logic prev_hwrite;
    logic prev_hsize;
    logic prev_hsel;
    logic [3:0] prev_haddr;
    logic [15:0] nxt_hrdata;
    logic data_ready_2;
    always_ff @ (posedge clk, negedge n_rst) begin
        if(n_rst == 0) begin
            hrdata <= 0;
            data_ready <= 0;
            new_coefficient_set <= 0;
            sample_data <= 0;
            prev_haddr <= 0;
            prev_hsize <= 0;
            coefficient <= 0;
            data_ready_2 <= 0;
        end
        else begin
            new_coefficient_set <= nxt_new_coefficient_set;
            sample_data <= nxt_sample_data;
            prev_haddr <= haddr;
            prev_hsize <= hsize;
            prev_hwrite <= hwrite;
            coefficient <= nxt_fir_coefficient;
            data_ready <= nxt_data_ready | data_ready_2;
            data_ready_2 <= nxt_data_ready;
            hrdata <= nxt_hrdata;
            prev_hsel <= hsel;
        end
    end
    always_comb begin
        if(clear) begin
            nxt_new_coefficient_set = 0;
        end
        else begin
            nxt_new_coefficient_set = new_coefficient_set;
        end
        nxt_data_ready = 0;
        nxt_fir_coefficient = coefficient;
        nxt_sample_data = sample_data;
        hresp = (hwrite && ((haddr == 0) || (haddr == 1) || (haddr == 2) || (haddr == 3))|| (haddr == 15));
        if(prev_hsel) begin
            if(prev_hwrite) begin
                if(prev_hsize == 0) begin
                    case(prev_haddr)
                        4: begin 
                            nxt_sample_data[7:0] = hwdata[7:0];
                            nxt_data_ready = 1;
                        end
                        5: begin 
                            nxt_sample_data[15:8] = hwdata[15:8];
                            nxt_data_ready = 1;
                        end
                        6,8,10,12: nxt_fir_coefficient[(prev_haddr - 6)/2][7:0] = hwdata[7:0];

                        7,9,11,13: nxt_fir_coefficient[(prev_haddr-7)/2][15:8] = hwdata[15:8];

                        14: nxt_new_coefficient_set = hwdata[0];
                    endcase
                end
                else begin
                    case(prev_haddr)
                        4,5:begin 
                            nxt_sample_data = hwdata;
                            nxt_data_ready = 1;
                        end
                        6,8,10,12: nxt_fir_coefficient[(prev_haddr - 6)/2] = hwdata;

                        7,9,11,13: nxt_fir_coefficient[(prev_haddr-7)/2] = hwdata;

                        14: nxt_new_coefficient_set = hwdata[0];
                    endcase
                end
            end
        end
    end

    always_comb begin
        nxt_hrdata = hrdata;
        if(hsel) begin
            if(prev_hwrite == 1 && hwrite == 0 && haddr == prev_haddr) begin
                        nxt_hrdata = hwdata;                    
                    end
            else if(!hwrite) begin
                if(hsize == 1'b0) begin
                    //nxt_hrdata = 'd100;
                    case(haddr)
                        0: nxt_hrdata[7:0] = {7'b0,(modwait || new_coefficient_set)};
                        1: nxt_hrdata [15:8] = {7'b0, err};
                        2: nxt_hrdata[7:0] = fir_out[7:0];
                        3: nxt_hrdata[15:8] = fir_out[15:8];
                        4:  nxt_hrdata[7:0] = sample_data[7:0];
                        5: nxt_hrdata[15:8] = sample_data[15:8];
                        6,8,10,12: nxt_hrdata[7:0] = coefficient[(haddr - 6)/2][7:0];
                        7,9,11,13: nxt_hrdata[15:8] = coefficient[(haddr-7)/2][15:8];
                        14: nxt_hrdata[0] = new_coefficient_set;
                    endcase
                end
                else if(hsize == 1'b1) begin
                    //nxt_hrdata = 'd2;
                    case(haddr)
                        0,1: nxt_hrdata = {7'b0, err, 7'b0, (modwait || new_coefficient_set)};
                        2,3: nxt_hrdata = fir_out;
                        4: nxt_hrdata = sample_data[15:0];
                        5: nxt_hrdata = sample_data[15:0];
                        6,8,10,12: nxt_hrdata = coefficient[(haddr - 6)/2];
                        7,9,11,13: nxt_hrdata = coefficient[(haddr-7)/2];
                        14: nxt_hrdata[0] = new_coefficient_set;
                        15: nxt_hrdata[0] = new_coefficient_set;
                    endcase
                end
            end
        end
end

    always_comb begin
        fir_coefficient = coefficient[coefficient_num];
    end
endmodule
