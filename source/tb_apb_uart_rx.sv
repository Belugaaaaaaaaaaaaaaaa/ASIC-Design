// $Id: $
// File name:   tb_apb_uart_rx.sv
// Created:     3/6/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
`timescale 1ns / 10ps

module tb_apb_uart_rx();

localparam CLK_PERIOD = 10;
localparam BUS_DELAY  = 800ps; // Based on FF propagation delay

// Sizing related constants
localparam DATA_WIDTH      = 1;
localparam ADDR_WIDTH      = 3;
localparam DATA_WIDTH_BITS = DATA_WIDTH * 8;
localparam DATA_MAX_BIT    = DATA_WIDTH_BITS - 1;
localparam ADDR_MAX_BIT    = ADDR_WIDTH - 1;

// Define our address mapping scheme via constants
localparam ADDR_DATA_SR  = 3'd0;
localparam ADDR_ERROR_SR = 3'd1;
localparam ADDR_BIT_CR0  = 3'd2;
localparam ADDR_BIT_CR1  = ADDR_BIT_CR0 + 1;
localparam ADDR_DATA_CR  = 3'd4;
localparam ADDR_RX_DATA  = 3'd6;

// APB-Slave reset value constants
// Student TODO: Update these based on the reset values for your config registers
localparam RESET_BIT_PERIOD = '0;
localparam RESET_DATA_SIZE  = '0;


logic                          tb_enqueue_transaction;
logic                          tb_transaction_write;
logic                          tb_transaction_fake;
logic [(ADDR_WIDTH - 1):0]     tb_transaction_addr;
logic [((DATA_WIDTH*8) - 1):0] tb_transaction_data;
logic                          tb_transaction_error;
// Testing control signal(s)
logic    tb_enable_transactions;
integer  tb_current_transaction_num;
logic    tb_model_reset;
string   tb_test_case;
integer  tb_test_case_num;
logic [DATA_MAX_BIT:0] tb_test_data;
string                 tb_check_tag;
logic [13:0]           tb_test_bit_period;
logic                  tb_mismatch;
logic                  tb_check;


//*****************************************************************************
// General System signals
//*****************************************************************************
logic tb_clk;
logic tb_n_rst;

//*****************************************************************************
// APB-Slave side signals
//*****************************************************************************
logic                          tb_psel;
logic [(ADDR_WIDTH - 1):0]     tb_paddr;
logic                          tb_penable;
logic                          tb_pwrite;
logic [((DATA_WIDTH*8) - 1):0] tb_pwdata;
logic [((DATA_WIDTH*8) - 1):0] tb_prdata;
logic                          tb_pslverr;


//*****************************************************************************
// UART-side Signals
//*****************************************************************************
// From UART(TB)
logic [7:0]  tb_rx_data;
logic        tb_data_ready;
logic        tb_overrun_error;
logic        tb_framing_error;
// To UART (From DUT)
logic        tb_data_read;
logic [3:0]  tb_data_size;
logic [13:0] tb_bit_period;
logic        tb_expected_data_read;
logic [3:0]  tb_expected_data_size;
logic [13:0] tb_expected_bit_period;

//reg        tb_test_data_read;
reg       tb_test_stop_bit;
reg [3:0]      tb_test_data_size;

  reg [7:0] tb_expected_rx_data;
  reg       tb_expected_framing_error;
  reg       tb_expected_data_ready;
  reg       tb_expected_overrun;
  reg tb_serial_in;
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
apb_bus BFM ( .clk(tb_clk),
          // Testing setup signals
          .enqueue_transaction(tb_enqueue_transaction),
          .transaction_write(tb_transaction_write),
          .transaction_fake(tb_transaction_fake),
          .transaction_addr(tb_transaction_addr),
          .transaction_data(tb_transaction_data),
          .transaction_error(tb_transaction_error),
          // Testing controls
          .model_reset(tb_model_reset),
          .enable_transactions(tb_enable_transactions),
          .current_transaction_num(tb_current_transaction_num),
          // APB-Slave Side
          .psel(tb_psel),
          .paddr(tb_paddr),
          .penable(tb_penable),
          .pwrite(tb_pwrite),
          .pwdata(tb_pwdata),
          .prdata(tb_prdata),
          .pslverr(tb_pslverr));


//*****************************************************************************
// DUT Instance
//*****************************************************************************
apb_slave DUT ( .clk(tb_clk), .n_rst(tb_n_rst),
            // UART Operation signals
            .rx_data(tb_rx_data),
            .data_ready(tb_data_ready),
            .overrun_error(tb_overrun_error),
            .framing_error(tb_framing_error),
            .data_read(tb_data_read),
            // APB-Slave bus signals
            .psel(tb_psel),
            .paddr(tb_paddr),
            .penable(tb_penable),
            .pwrite(tb_pwrite),
            .pwdata(tb_pwdata),
            .prdata(tb_prdata),
            .pslverr(tb_pslverr),
            // UART Configuration values
            .data_size(tb_data_size),
            .bit_period(tb_bit_period));


rcv_block rcv
  (
    .clk(tb_clk),
    .n_rst(tb_n_rst),
    .serial_in(tb_serial_in),
    .data_read(tb_data_read),
    .rx_data(tb_rx_data),
    .data_ready(tb_data_ready),
    .overrun_error(tb_overrun_error),
    .framing_error(tb_framing_error),
    .data_size(tb_data_size),
    .bit_period(tb_bit_period)
  );


//*****************************************************************************
// DUT Related TB Tasks
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


  task send_packet;
    input  [7:0] data;
    input  stop_bit;
    input  [3:0] data_size;
    input  time data_period;
    
    integer i;
  begin
    // First synchronize to away from clock's rising edge
    @(negedge tb_clk)
    
    // Send start bit
    tb_serial_in = 1'b0;
    #data_period;
    
    // Send data bits
    for(i = 0; i < data_size; i = i + 1)
    begin
      tb_serial_in = data[i];
      #data_period;
    end
    
    // Send stop bit
    tb_serial_in = stop_bit;
    #data_period;
  end
  endtask


//*****************************************************************************
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

  // Process the transactions
  for(wait_var = 0; wait_var < num_transactions; wait_var++) begin
    @(posedge tb_clk);
    @(posedge tb_clk);
  end

  // Turn off the bus model
  @(negedge tb_clk);
  tb_enable_transactions = 1'b0;
end
endtask



// Task to cleanly and consistently check DUT output values
task check_outputs;
  input string check_tag;
begin
  tb_mismatch = 1'b0;
  tb_check    = 1'b1;
  if(tb_expected_data_read == tb_data_read) begin // Check passed
    $info("Correct 'data_read' output %s during %s test case", check_tag, tb_test_case);
  end
  else begin // Check failed
    tb_mismatch = 1'b1;
    $error("Incorrect 'data_read' output %s during %s test case", check_tag, tb_test_case);
  end



  // Wait some small amount of time so check pulse timing is visible on waves
  #(0.1);
  tb_check =1'b0;
end
endtask




// Main TB Process
//*****************************************************************************
//*****************************************************************************
initial begin
  // Initialize Test Case Navigation Signals
  tb_test_case       = "Initilization";
  tb_test_case_num   = -1;
  tb_test_data       = '0;
  tb_check_tag       = "N/A";
  tb_test_bit_period = '0;
  tb_check           = 1'b0;
  tb_mismatch        = 1'b0;
  // Initialize all of the directly controled DUT inputs
  tb_n_rst          = 1'b0;
  
  // Initialize all of the bus model control inputs
  tb_model_reset          = 1'b0;
  tb_enable_transactions  = 1'b0;
  tb_enqueue_transaction  = 1'b0;
  tb_transaction_write    = 1'b0;
  tb_transaction_fake     = 1'b0;
  tb_transaction_addr     = '0;
  tb_transaction_data     = '0;
  tb_transaction_error    = 1'b0;

  tb_serial_in = 1;

  tb_test_stop_bit          = 1'b1;
 // tb_test_data_read         = 1'b0;
  
  // Wait some time before starting first test case
  #(0.1);

  // Clear the bus model
  reset_model();

  tb_test_case     = "Power-on-Reset";
  tb_test_case_num = tb_test_case_num + 1;

    //tb_test_bit_period        = NORM_DATA_PERIOD;
   // tb_test_data_read         = 1'b0;
    tb_expected_rx_data       = '1;
    tb_expected_data_ready    = 1'b0; 
    tb_expected_framing_error = 1'b0;
    tb_expected_overrun       = 1'b0;


//*****************************************************************************
  // Test Case: 

  tb_test_bit_period = 14'd10;
  tb_test_data_size = 3'd8;


  tb_test_data       = 8'b11010101;
  tb_test_stop_bit   = 1'b1;
  //tb_test_bit_period = NORM_DATA_PERIOD;
  tb_expected_data_read  = 1'b0;

  reset_dut();

  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR0, tb_test_bit_period[7:0], 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR1, {2'b00, tb_test_bit_period[13:8]}, 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_DATA_CR, 8, 1'b0);

  execute_transactions(3);

  send_packet(tb_test_data, tb_test_stop_bit, tb_data_size, tb_test_bit_period * CLK_PERIOD);

  #(tb_test_bit_period * 9);
  enqueue_transaction(1'b1, 1'b0, ADDR_RX_DATA, tb_test_data, 1'b0);
  execute_transactions(1);
  // Check outputs
  //check_outputs("data read");

//*****************************************************************************
  // Test Case: 

  tb_test_stop_bit   = 1'b0;


  reset_dut();

  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR0, tb_test_bit_period[7:0], 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR1, {2'b00, tb_test_bit_period[13:8]}, 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_DATA_CR, 8, 1'b0);

  execute_transactions(3);

  send_packet(tb_test_data, tb_test_stop_bit, tb_data_size, tb_test_bit_period * CLK_PERIOD);

  #(tb_test_bit_period * 9);
  enqueue_transaction(1'b1, 1'b0, ADDR_ERROR_SR, 1, 1'b0);
  execute_transactions(1);


//*****************************************************************************
  // Test Case: 

  tb_test_stop_bit   = 1'b1;
  //tb_overrun_error = 1;


  reset_dut();

  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR0, tb_test_bit_period[7:0], 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR1, {2'b00, tb_test_bit_period[13:8]}, 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_DATA_CR, 8, 1'b0);

  execute_transactions(3);

  send_packet(tb_test_data, tb_test_stop_bit,tb_data_size, tb_test_bit_period * CLK_PERIOD);
  send_packet(tb_test_data, tb_test_stop_bit, tb_data_size, tb_test_bit_period * CLK_PERIOD);

  #(tb_test_bit_period * 9);
  enqueue_transaction(1'b1, 1'b0, ADDR_ERROR_SR, 2, 1'b0);
  execute_transactions(1);


//*****************************************************************************
  // Test Case: 

  tb_test_stop_bit   = 1'b1;
  //tb_overrun_error = 0;
  tb_test_bit_period = 14'd10;
  tb_test_data_size = 4'd5;


  tb_test_data       = 5'b10101;


  reset_dut();

  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR0, tb_test_bit_period[7:0], 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR1, {2'b00, tb_test_bit_period[13:8]}, 1'b0);
  enqueue_transaction(1'b1, 1'b1, ADDR_DATA_CR, tb_test_data_size, 1'b0);

  execute_transactions(3);

  send_packet(tb_test_data, tb_test_stop_bit, tb_data_size, tb_test_bit_period * CLK_PERIOD);
  
  #(tb_test_bit_period * 6);
  enqueue_transaction(1'b1, 1'b0, ADDR_ERROR_SR, 0, 1'b0);
  execute_transactions(1);

//
//   //Test Case:
//   tb_test_stop_bit   = 1'b1;
//   tb_overrun_error = 0;
//   tb_test_bit_period = 14'd10;
//   tb_test_data_size = 4'd7;


//   tb_test_data       = 7'b0110101;

//   reset_dut();
//   enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR0, tb_test_bit_period[7:0], 1'b0);
//   enqueue_transaction(1'b1, 1'b1, ADDR_BIT_CR1, {2'b00, tb_test_bit_period[13:8]}, 1'b0);
//   enqueue_transaction(1'b1, 1'b1, ADDR_DATA_CR, tb_test_data_size, 1'b0);
//   execute_transactions(3);

//   send_packet(tb_test_data, tb_test_stop_bit, tb_test_bit_period*CLK_PERIOD);

//   #(tb_test_bit_period*6);
//   check_outputs("data_size");
//   enqueue_transaction(1'b1,1'b0, ADDR_ERROR_SR,0, 1'b0);
//   execute_transactions(1);
 end
endmodule
