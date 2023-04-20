// $Id: $
// File name:   magnitude.sv
// Created:     2/23/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module magnitude(
    input logic [16:0] in,
    output logic [15:0] out
);
    always_comb begin
        if(in[16] == 1'b1)begin
            out = (~in[15:0]) + 1;
        end
        else begin
            out = in[15:0];
        end
    end
endmodule
