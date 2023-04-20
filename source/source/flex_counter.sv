// $Id: $
// File name:   flex_counter.sv
// Created:     2/1/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
module flex_counter#(parameter NUM_CNT_BITS = 4)
(
	input logic clk, 
	input logic n_rst, 
	input logic clear, 
	input logic count_enable, 
	input logic [NUM_CNT_BITS-1:0]rollover_val, 
	output logic [NUM_CNT_BITS-1:0]count_out, 
	output logic rollover_flag
);
logic [NUM_CNT_BITS-1:0]cout;
logic flag;

always_ff @ (posedge clk, negedge n_rst) begin
	if (n_rst == 1'b0) begin
		count_out <= '0;
		rollover_flag <= 0;
	end
	else begin
		count_out <= cout;
		rollover_flag <= flag;
	end
end
always_comb begin 

	if (clear == 1'b1) begin
		cout = 0;
		flag = 0;
	end
	else if(count_enable == 1'b1) begin
		cout = count_out + 1;
		flag = '0;
		if(cout == rollover_val) begin
			flag = 1;
			
		end
		else if (cout > rollover_val) begin
			cout = 1;
			flag = '0;
		end
	end
	else begin
		flag = 0;
		cout = count_out;
	end
	
end
endmodule
