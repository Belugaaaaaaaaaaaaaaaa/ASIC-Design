// $Id: $
// File name:   tb_ahb_lite_fir_filter.sv
// Created:     3/27/2023
// Author:      Liangcheng Jiang
// Lab Section: 337-16
// Version:     1.0  Initial Design Entry
// Description: tb for ahb filter

`timescale 1ns / 10ps

module tb_ahb_lite_fir_filter();
	// Timing related constants
	localparam CLK_PERIOD = 10;
	localparam BUS_DELAY  = 800; // Based on FF propagation delay

	// Sizing related constants

	localparam NUM_VAL_BITS	= 16;
	localparam MAX_VAL_BIT	= NUM_VAL_BITS - 1;
	localparam DATA_WIDTH      = 2;
	localparam ADDR_WIDTH      = 4;
	localparam DATA_WIDTH_BITS = DATA_WIDTH * 8;
	localparam DATA_MAX_BIT    = DATA_WIDTH_BITS - 1;
	localparam ADDR_MAX_BIT    = ADDR_WIDTH - 1;
	localparam COEFF1 		= 16'h8000; // 1.0
	localparam COEFF_5 		= 16'h4000; // 0.5
	localparam COEFF_25 	= 16'h2000; // 0.25
	localparam COEFF_125 	= 16'h1000; // 0.125
	localparam COEFF0  		= 16'h0000; // 0.0

	// Define our address mapping scheme via constants
	localparam ADDR_STATUS      = 4'd0;
	localparam ADDR_STATUS_BUSY = 4'd0;
	localparam ADDR_STATUS_ERR  = 4'd1;
	localparam ADDR_RESULT      = 4'd2;
	localparam ADDR_SAMPLE      = 4'd4;
	localparam ADDR_COEF_START  = 4'd6;  // F0
	localparam ADDR_COEF_SET    = 4'd14; // Coeff Set Confirmation

	// AHB-Lite-Slave reset value constants
	localparam RESET_COEFF  = '0;
	localparam RESET_SAMPLE = '0;

	// Testing setup signals
	logic                      tb_enqueue_transaction;
	logic                      tb_transaction_write;
	logic                      tb_transaction_fake;
	logic [ADDR_MAX_BIT:0]     tb_transaction_addr;
	logic [DATA_MAX_BIT:0]     tb_transaction_data;
	logic                      tb_transaction_error;
	logic [2:0]                tb_transaction_size;
	// Testing control signal(s)
	logic    tb_enable_transactions;
	integer  tb_current_transaction_num;
	logic    tb_current_transaction_error;
	logic    tb_model_reset;
	string   tb_test_case;
	integer  tb_test_case_num;
	integer tb_test_time;
	logic [DATA_MAX_BIT:0] tb_test_data;
	string                 tb_check_tag;
	logic                  tb_mismatch;
	logic                  tb_check;

	logic tb_clk;
	logic tb_n_rst;

	logic                  tb_hsel;
	logic [1:0]            tb_htrans;
	logic [ADDR_MAX_BIT:0] tb_haddr;
	logic [2:0]            tb_hsize;
	logic                  tb_hwrite;
	logic [DATA_MAX_BIT:0] tb_hwdata;
	logic [DATA_MAX_BIT:0] tb_hrdata;
	logic                  tb_hresp;
	logic                  tb_clear;

	logic [DATA_MAX_BIT:0]  tb_fir_out;
	logic                   tb_modwait;
	logic                   tb_err;
	logic [1:0]             tb_coeff_num;

	logic                   tb_expected_data_ready;
	logic [DATA_MAX_BIT:0]  tb_expected_sample;
	logic                   tb_expected_new_coeff_set;
	logic [DATA_MAX_BIT:0]  tb_expected_coeff;
	logic                   tb_expected_hresp;


	typedef struct
	{
		reg [MAX_VAL_BIT:0] coeffs[3:0];
		reg [MAX_VAL_BIT:0] samples[3:0];
		reg [MAX_VAL_BIT:0] results[3:0];
		reg errors[3:0];
	} testVector;


testVector tb_test_vectors[];

//*****************************************************************************
// Clock Generation Block
//*****************************************************************************
// Clock generation block
always begin
  // Start with clock low to avoid false rising edge events at t=0
  tb_clk = 1'b0;
  // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
  tb_clk = 1'b1;
  // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
  #(CLK_PERIOD/2.0);
end


//*****************************************************************************
// Bus Model Instance
//*****************************************************************************
ahb_lite_bus BFM (.clk(tb_clk),
                  // Testing setup signals
                  .enqueue_transaction(tb_enqueue_transaction),
                  .transaction_write(tb_transaction_write),
                  .transaction_fake(tb_transaction_fake),
                  .transaction_addr(tb_transaction_addr),
                  .transaction_data(tb_transaction_data),
                  .transaction_error(tb_transaction_error),
                  .transaction_size(tb_transaction_size),
                  // Testing controls
                  .model_reset(tb_model_reset),
                  .enable_transactions(tb_enable_transactions),
                  .current_transaction_num(tb_current_transaction_num),
                  .current_transaction_error(tb_current_transaction_error),
                  // AHB-Lite-Slave Side
                  .hsel(tb_hsel),
                  .htrans(tb_htrans),
                  .haddr(tb_haddr),
                  .hsize(tb_hsize),
                  .hwrite(tb_hwrite),
                  .hwdata(tb_hwdata),
                  .hrdata(tb_hrdata),
                  .hresp(tb_hresp));

//*****************************************************************************
// DUT Instance
//*****************************************************************************
ahb_lite_fir_filter all (.clk(tb_clk), .n_rst(tb_n_rst),
                    // FIR Filter Operation signals

                    .hsel(tb_hsel),
                    .htrans(tb_htrans),
                    .haddr(tb_haddr),
                    .hsize(tb_hsize[0]),
                    .hwrite(tb_hwrite),
                    .hwdata(tb_hwdata),
                    .hrdata(tb_hrdata),
                    .hresp(tb_hresp)

);


	//*****************************************************************************
	// Task
	//*****************************************************************************
	// Task for standard DUT reset procedure
	task reset_dut;
	begin
	  // Activate the reset
	  tb_n_rst = 1'b0;

	  // Maintain the reset for more than one cycle
	  @(posedge tb_clk);
	  @(posedge tb_clk);

	  // Wait until safely away from rising edge of the clock before releasing
	  @(negedge tb_clk);
	  tb_n_rst = 1'b1;

	  // Leave out of reset for a couple cycles before allowing other stimulus
	  // Wait for negative clock edges, 
	  // since inputs to DUT should normally be applied away from rising clock edges
	  @(negedge tb_clk);
	  @(negedge tb_clk);
	end
	endtask



	// Task to cleanly and consistently check DUT output values
	task check_outputs;
	  input string check_tag;
	begin
	  tb_mismatch = 1'b0;
	  tb_check    = 1'b1;
	  if(tb_hresp == tb_expected_hresp) begin // Check passed
	    $info("Correct 'resp' output %s during %s test case", check_tag, tb_test_case);
	  end
	  else begin // Check failed
	    tb_mismatch = 1'b1;
	    $error("Incorrect 'resp' output %s during %s test case", check_tag, tb_test_case);
	  end

	  // Wait some small amount of time so check pulse timing is visible on waves
	  #(0.1);
	  tb_check =1'b0;
	end
	endtask

	// Task to pulse the reset for the bus model
	task reset_model;
	begin
	  tb_model_reset = 1'b1;
	  #(0.1);
	  tb_model_reset = 1'b0;
	end
	endtask

	// Task to enqueue a new transaction
	task enqueue_transaction;
	  input logic for_dut;
	  input logic write_mode;
	  input logic [ADDR_MAX_BIT:0] address;
	  input logic [DATA_MAX_BIT:0] data;
	  input logic expected_error;
	  input logic size;
	begin
	  // Make sure enqueue flag is low (will need a 0->1 pulse later)
	  tb_enqueue_transaction = 1'b0;
	  #0.1ns;

	  // Setup info about transaction
	  tb_transaction_fake  = ~for_dut;
	  tb_transaction_write = write_mode;
	  tb_transaction_addr  = address;
	  tb_transaction_data  = data;
	  tb_transaction_error = expected_error;
	  tb_transaction_size  = {2'b00,size};

	  // Pulse the enqueue flag
	  tb_enqueue_transaction = 1'b1;
	  #0.1ns;
	  tb_enqueue_transaction = 1'b0;
	end
	endtask

	// Task to wait for multiple transactions to happen
	task execute_transactions;
	  input integer num_transactions;
	  integer wait_var;
	begin
	  // Activate the bus model
	  tb_enable_transactions = 1'b1;
	  @(posedge tb_clk);

	  // Process the transactions (all but last one overlap 1 out of 2 cycles
	  for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
	    @(posedge tb_clk);
	  end

	  // Run out the last one (currently in data phase)
	  @(posedge tb_clk);

	  // Turn off the bus model
	  @(negedge tb_clk);
	  tb_enable_transactions = 1'b0;
	end
	endtask

	// Task to clear/initialize all FIR-side inputs
	task init_fir_side;
	begin
	  tb_fir_out   = '0;
	  tb_modwait   = 1'b0;
	  tb_err       = 1'b0;
	  tb_coeff_num = 2'd0;
	end
	endtask

	// Task to clear/initialize all FIR-side inputs
	task init_expected_outs;
	begin
	  tb_expected_data_ready    = 1'b0;
	  tb_expected_sample        = RESET_SAMPLE;
	  tb_expected_new_coeff_set = 1'b0;
	  tb_expected_coeff         = RESET_COEFF;
	end
	endtask


	initial begin
	  tb_test_case       = "Initilization";
	  tb_test_case_num   = 0;
	  tb_test_time = 0;
	  tb_test_data       = '0;
	  tb_check_tag       = "N/A";
	  tb_check           = 1'b0;
	  tb_mismatch        = 1'b0;
	  tb_n_rst          = 1'b1;
	  init_fir_side();
	  tb_model_reset          = 1'b0;
	  tb_enable_transactions  = 1'b0;
	  tb_enqueue_transaction  = 1'b0;
	  tb_transaction_write    = 1'b0;
	  tb_transaction_fake     = 1'b0;
	  tb_transaction_addr     = '0;
	  tb_transaction_data     = '0;
	  tb_transaction_error    = 1'b0;
	  tb_transaction_size     = 3'd0;
	  tb_clear = 0;

	  tb_test_vectors = new[2];
			// Test case 0
			tb_test_vectors[0].coeffs		= {{COEFF_5}, {COEFF1}, {COEFF1}, {COEFF_5}};
			tb_test_vectors[0].samples	= {16'd100, 16'd100, 16'd100, 16'd100};
			tb_test_vectors[0].results	= {16'd0, 16'd50, 16'd50 ,16'd50};
			tb_test_vectors[0].errors		= {1'b0, 1'b0, 1'b0, 1'b0};

			// Test case 1
			tb_test_vectors[1].coeffs		= {{COEFF_5}, {COEFF1}, {COEFF1} ,{COEFF_5}};
			tb_test_vectors[1].samples	= {16'hffff, 16'd1, 16'hffff, 16'd1};
			tb_test_vectors[1].results	= {16'd1, 16'd1, 16'd1 ,16'd1};
			tb_test_vectors[1].errors		= {16'd256, 1'b0, 1'b0, 1'b0};

	  // Wait some time before starting first test case
	  #(0.1);

	  reset_model();

	  // Power-on-Reset Test Case
	  tb_test_case     = "Power-on-Reset";
	  tb_test_case_num = tb_test_case_num + 1;
	  
	  // Setup FIR Filter provided signals with 'active' values for reset check
	  tb_fir_out   = '1;
	  tb_modwait   = 1'b1;
	  tb_err       = 1'b1;
	  tb_coeff_num = 2'd1;
	  tb_expected_hresp = 0;

	  // Reset the DUT
	  reset_dut();

	  // Check outputs for reset state
	  init_expected_outs();
	  check_outputs("after DUT reset");

	  // Give some visual spacing between check and next test case start
	  #(CLK_PERIOD * 3);

	  // Test Case: Set a new sample value
	  tb_test_case     = "Sample data send";
	  tb_test_case_num = tb_test_case_num + 1;
	  init_fir_side();
	  init_expected_outs();
	  
	  reset_dut();

	  // Enqueue the needed transactions (Low Coeff Address => F0, just add 2 x index)
	  tb_test_data = 16'd1000; 
	  tb_test_time += 1;
	  enqueue_transaction(1'b1, 1'b1, ADDR_SAMPLE, tb_test_data, 1'b0, 1'b1);
		tb_test_time += 1;
	  execute_transactions(1);
	  tb_test_time += 1;
	  enqueue_transaction(1'b1, 1'b0, ADDR_SAMPLE, tb_test_data, 1'b0, 1'b1);
	tb_test_time += 1;
	  execute_transactions(1);

	  // Check the DUT outputs
	  tb_expected_data_ready    = 1'b1;
	  tb_expected_sample        = tb_test_data;
	  tb_expected_new_coeff_set = 1'b0;
	  tb_expected_coeff         = RESET_COEFF;
	  check_outputs("write sample data");

	  // Give some visual spacing between check and next test case start
	  #(CLK_PERIOD * 3);

	  // Test Case: Configure and check a Coefficient Value
	  tb_test_case     = "set f3";
	  tb_test_case_num = tb_test_case_num + 1;
	  init_fir_side();
	  init_expected_outs();

	  reset_dut();
	  tb_test_data = 16'h8000; // Fixed decimal value of 1.0
		tb_test_time += 1;
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 6), tb_test_data, 1'b0, 1'b1);
		tb_test_time += 1;
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 6), tb_test_data, 1'b0, 1'b1);
	  execute_transactions(2);

	  tb_expected_data_ready    = 1'b0;
	  tb_expected_sample        = RESET_SAMPLE;
	  tb_expected_new_coeff_set = 1'b0;
	  tb_expected_coeff         = RESET_COEFF;
	  check_outputs("f3 write check");

	  // Give some visual spacing between check and next test case start
	  #(CLK_PERIOD * 3);


	  // Test Case: Configure and check a Coefficient Value
	  tb_test_case     = "fir_coefficient";
	  tb_test_case_num = tb_test_case_num + 1;
	  init_fir_side();
	  init_expected_outs();

	  // Reset the DUT to isolate from prior test case
	  reset_dut();
	  		

	  tb_test_data = 16'd2; // Fixed decimal value of 1.0
	  tb_test_time += 1;
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 0), tb_test_vectors[0].coeffs[0], 1'b0, 1'b1);
	  tb_test_time += 1;
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 2), tb_test_vectors[0].coeffs[1], 1'b0, 1'b1);
	  tb_test_time += 1;

	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 4), tb_test_vectors[0].coeffs[2], 1'b0, 1'b1);
	  tb_test_time += 1;
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 6), tb_test_vectors[0].coeffs[3], 1'b0, 1'b1);
	  tb_test_time += 1;
	  execute_transactions(4);

	  #(CLK_PERIOD);

	  // Enqueue the 'check' read
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 0), tb_test_vectors[0].coeffs[0], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 2), tb_test_vectors[0].coeffs[1], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 4), tb_test_vectors[0].coeffs[2], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 6), tb_test_vectors[0].coeffs[3], 1'b0, 1'b1);

	  // Run the transactions via the model
	  execute_transactions(4);
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 8), 16'b1, 1'b0, 1'b1);
	  execute_transactions(1);

	  #(CLK_PERIOD * 30);
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[0].samples[0], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd2, tb_test_vectors[0].results[0], 1'b0, 1'b1);
	  execute_transactions(1);
	//
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[0].samples[1], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd2, tb_test_vectors[0].results[1], 1'b0, 1'b1);
	  execute_transactions(1);
	//
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[0].samples[2], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd2, tb_test_vectors[0].results[2], 1'b0, 1'b1);
	  execute_transactions(1);
	//
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[0].samples[3], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd2, tb_test_vectors[0].results[3], 1'b0, 1'b1);
	  execute_transactions(1);

	  tb_expected_data_ready    = 1'b0;
	  tb_expected_sample        = RESET_SAMPLE;
	  tb_expected_new_coeff_set = 1'b0;
	  tb_expected_coeff         = RESET_COEFF;
	  check_outputs("after attempting to configure F3");

	  #(CLK_PERIOD * 3);

	  // Test Case: Configure and check a Coefficient Value
	  tb_test_case     = "error 4 coeffs";
	  tb_test_case_num = tb_test_case_num + 1;
	  init_fir_side();
	  init_expected_outs();

	  // Reset the DUT to isolate from prior test case
	  reset_dut();
	  		

	  // Enqueue the needed transactions (Low Coeff Address => F0, just add 2 x index)
	  tb_test_data = 16'd2; // Fixed decimal value of 1.0
	  // Enqueue the write
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 0), tb_test_vectors[1].coeffs[0], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 2), tb_test_vectors[1].coeffs[1], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 4), tb_test_vectors[1].coeffs[2], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 6), tb_test_vectors[1].coeffs[3], 1'b0, 1'b1);
	  // Run the transactions via the model
	  execute_transactions(4);

	  #(CLK_PERIOD);

	  // Enqueue the 'check' read
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 0), tb_test_vectors[1].coeffs[0], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 2), tb_test_vectors[1].coeffs[1], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 4), tb_test_vectors[1].coeffs[2], 1'b0, 1'b1);
	  enqueue_transaction(1'b1, 1'b0, (ADDR_COEF_START + 6), tb_test_vectors[1].coeffs[3], 1'b0, 1'b1);
	  // Run the transactions via the model
	  execute_transactions(4);
	  enqueue_transaction(1'b1, 1'b1, (ADDR_COEF_START + 8), 16'b1, 1'b0, 1'b1);
	  execute_transactions(1);

	  #(CLK_PERIOD * 30);
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[1].samples[0], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd0, tb_test_vectors[1].errors[0], 1'b0, 1'b1);
	  execute_transactions(1);
	//
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[1].samples[1], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd0, tb_test_vectors[1].errors[1], 1'b0, 1'b1);
	  execute_transactions(1);
	//
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[1].samples[2], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd0, tb_test_vectors[1].errors[2], 1'b0, 1'b1);
	  execute_transactions(1);
	//
	  enqueue_transaction(1'b1, 1'b1, 4'd4, tb_test_vectors[1].samples[3], 1'b0, 1'b1);
	  execute_transactions(1);
	  #(CLK_PERIOD * 25);
	  enqueue_transaction(1'b1, 1'b0, 4'd0, 16'd256, 1'b0, 1'b1);
	  execute_transactions(1);

	  
	  tb_expected_data_ready    = 1'b0;
	  tb_expected_sample        = RESET_SAMPLE;
	  tb_expected_new_coeff_set = 1'b0;
	  tb_expected_coeff         = RESET_COEFF;
	  check_outputs("set f3");

	  #(CLK_PERIOD * 3);

	  // Test Case: Configure and check a Coefficient Value
	  tb_test_case     = "invalid write";
	  tb_test_case_num = tb_test_case_num + 1;
	  init_fir_side();
	  init_expected_outs();

	  reset_dut();
	  enqueue_transaction(1'b1, 1'b1, 4'd1, 16'b0, 1'b1, 1'b1);
	  enqueue_transaction(1'b1, 1'b1, 4'd3, 16'b0, 1'b1, 1'b1);
	  enqueue_transaction(1'b1, 1'b1, 4'd1, 16'b0, 1'b1, 1'b0);
	  enqueue_transaction(1'b1, 1'b1, 4'd3, 16'b0, 1'b1, 1'b0);
	  execute_transactions(4);

	  $stop();
	end
endmodule

