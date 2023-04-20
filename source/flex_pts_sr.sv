module flex_pts_sr#(parameter NUM_BITS = 4, parameter SHIFT_MSB = 1)(
    input logic clk,
    input logic n_rst,
    input logic shift_enable,
    input logic load_enable,
    input logic [NUM_BITS-1:0] parallel_in,
    output logic serial_out
);
logic [NUM_BITS-1:0] out;
logic [NUM_BITS-1:0] next;
 always_ff @(posedge clk, negedge n_rst) begin
    if(1'b0 == n_rst) begin
        out <= '1;
    end
    else begin
        out <= next;
    end
 end
 always_comb begin
    if(SHIFT_MSB == 1)begin
        serial_out <= out[NUM_BITS-1];
    end
    else begin
        serial_out <= out[0];
    end
 end
 always_comb begin
    if(!SHIFT_MSB) begin
        if(load_enable == 1) begin
            next = parallel_in;
        end
        else if(shift_enable) begin
            next[NUM_BITS-1] = 1;
            next[NUM_BITS-2:0] = out[NUM_BITS-1:1];
        end
        else begin
            next = out;
        end
    end
    else begin
            if(load_enable == 1) begin
                next = parallel_in;
            end
            else if(shift_enable) begin
                next[0] = 1;
                next[NUM_BITS-1:1] = out[NUM_BITS-2:0];
        end
        else begin
           next = out;
        end
    end
 end
 endmodule