// $Id: $
// File name:   apb_slave.sv
// Created:     3/1/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module apb_slave (
    input logic clk,
    input logic n_rst,
    input logic [7:0] rx_data,
    input logic data_ready,
    input logic overrun_error,
    input logic framing_error,
    input logic psel,
    input logic [2:0] paddr,
    input logic penable,
    input logic pwrite,
    input logic [7:0] pwdata,
    output logic [7:0] prdata,
    output logic pslverr,
    output logic [3:0] data_size,
    output logic [13:0] bit_period,
    output logic data_read
);
logic [13:0] nxt_bit_period;
logic [7:0] nxt_prdata;
logic [3:0] nxt_data_size;
always_ff @(posedge clk, negedge n_rst) begin
    if(n_rst == 1'b0) begin
        bit_period <= 14'd10;
	prdata <= 0;
        data_size <= 4'd8;
    end
    else begin
        bit_period <= nxt_bit_period;
        prdata <= nxt_prdata;
        data_size <= nxt_data_size;
    end
end

always_comb begin
    if (psel) begin
        nxt_bit_period = bit_period;
        nxt_data_size = data_size;
        nxt_prdata = prdata;
        pslverr = (pwrite && ((paddr == 0) || (paddr == 1) || (paddr == 6)) || (paddr == 5) || (paddr == 7));
        if(pwrite) begin
            data_read = 0;
            if(paddr == 2)begin
                nxt_bit_period[7:0] = pwdata;
            end
            else if(paddr == 3)begin
                nxt_bit_period[13:8] = pwdata[5:0];
            end 
            else if(paddr == 4)begin
                nxt_data_size = pwdata[3:0];
            end
        end
        else begin
            data_read = 0;
            if(paddr == 0)begin
                nxt_prdata = data_ready;
            end
            else if(paddr == 1)begin
                nxt_prdata = 1*framing_error + 2* overrun_error;
            end
            else if(paddr == 6) begin
                data_read = 1;
                nxt_prdata = rx_data;
            end
            else if(paddr == 2)begin
                nxt_prdata = bit_period[7:0];
            end
            else if(paddr == 3) begin
                nxt_prdata = bit_period[13:8];
            end
            else if(paddr == 4) begin
                nxt_prdata = data_size;
            end
        end
    end
    else begin
        data_read = 0;
        nxt_bit_period = bit_period;
        nxt_data_size = data_size;
        nxt_prdata = prdata;
        pslverr = 0;
    end
        
end
endmodule
