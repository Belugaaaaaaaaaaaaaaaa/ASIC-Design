// $Id: $
// File name:   tb_flex_counter.sv
// Created:     2/3/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
`timescale 1ns / 10ps

module tb_flex_counter();

  // Define local parameters used by the test bench
  localparam  CLK_PERIOD    = 2.5;
  localparam  FF_SETUP_TIME = 0.190;
  localparam  FF_HOLD_TIME  = 0.100;
  localparam  CHECK_DELAY   = (CLK_PERIOD - FF_SETUP_TIME); // Check right before the setup time starts
  
  localparam  INACTIVE_VALUE     = 1'b0;
  localparam  RESET_OUTPUT_VALUE = INACTIVE_VALUE;
  
  // Declare DUT portmap signals
  reg tb_clk;
  reg tb_n_rst;
  reg tb_count_enable;
  reg tb_clear;
  reg [3:0] tb_count_out;
  reg [3:0] tb_rollover_val;
  reg tb_rollover_flag;
  
  
  // Declare test bench signals
  integer tb_test_num;
  string tb_test_case;
  
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
    //@(negedge tb_clk);
    //@(negedge tb_clk);
  end
  endtask

  // Task to cleanly and consistently check DUT output values
  task check_output;

    input logic [3:0] expected_value;
    input logic expected_flag;
    input string check_tag;
  
  begin
    #(0.5);
    if(expected_value == tb_count_out) begin // Check passed
      $info("Correct synchronizer output %s during %s test case", check_tag, tb_test_case);
    end
    else begin // Check failed
      $error("Incorrect synchronizer output %s during %s test case", check_tag, tb_test_case);
    end

    if(expected_flag == tb_rollover_flag) begin // Check passed
      $info("Correct synchronizer output %s during %s test case", check_tag, tb_test_case);
    end
    else begin // Check failed
      $error("Incorrect synchronizer output %s during %s test case", check_tag, tb_test_case);
    end
  end
  endtask


  // Task to cleanly and consistently check for correct values during MetaStability Test Cases
  task clear_dut;
  begin
    // Activate the reset
    tb_clear = 1'b1;

    // Maintain the reset for more than one cycle
    @(posedge tb_clk);
    @(posedge tb_clk);

    // Wait until safely away from rising edge of the clock before releasing
    @(negedge tb_clk);
    tb_clear = 1'b0;

    // Leave out of reset for a couple cycles before allowing other stimulus
    // Wait for negative clock edges, 
    // since inputs to DUT should normally be applied away from rising clock edges
    //@(negedge tb_clk);
    //@(negedge tb_clk);
  end
  endtask
  // Clock generation block
  always
  begin
    // Start with clock low to avoid false rising edge events at t=0
    tb_clk = 1'b0;
    // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
    tb_clk = 1'b1;
    // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
  end
  
  // DUT Port map
  flex_counter DUT(.clk(tb_clk), .n_rst(tb_n_rst), .clear(tb_clear), .count_enable(tb_count_enable), .count_out(tb_count_out),.rollover_val(tb_rollover_val), .rollover_flag(tb_rollover_flag));
  
  // Test bench main process
  initial
  begin
    // Initialize all of the test inputs
    tb_n_rst  = 1'b1;              // Initialize to be inactive
    tb_test_num = 0;               // Initialize test case counter
    tb_test_case = "Test bench initializaton";

    // Wait some time before starting first test case
    #(0.1);
    
    // ************************************************************************
    // Test Case 1: Power-on Reset of the DUT
    // ************************************************************************
    tb_test_num = tb_test_num + 1;
    tb_test_case = "Power on Reset";
    // Note: Do not use reset task during reset test case since we need to specifically check behavior during reset
    // Wait some time before applying test case stimulus
    #(0.1);
    // Apply test case initial stimulus
    tb_count_enable  = INACTIVE_VALUE; // Set to be the the non-reset value
    tb_n_rst  = 1'b0;    // Activate reset
    
    // Wait for a bit before checking for correct functionality
    #(CLK_PERIOD * 0.5);

    // Check that internal state was correctly reset
    check_output( 0,0,
                  "after reset applied");
    
    // Check that the reset value is maintained during a clock cycle
    #(CLK_PERIOD);
    check_output( 0,0, 
                  "after clock cycle while in reset");
    
    // Release the reset away from a clock edge
    @(posedge tb_clk);
    #(2 * FF_HOLD_TIME);
    tb_n_rst  = 1'b1;   // Deactivate the chip reset
    #0.1;
    // Check that internal state was correctly keep after reset release
    check_output( 0,0, 
                  "after reset was released");

    // ************************************************************************
    // Test Case 2: Normal Operation with rollover value not power of 2
    // ************************************************************************    
    @(negedge tb_clk); 
    tb_test_num = tb_test_num + 1;
    tb_test_case = "Normal Operation with rollover value not power of 2";
    // Start out with inactive value and reset the DUT to isolate from prior tests
   
   

    // Assign test case stimulus
    tb_rollover_val= 4'b0101;
    tb_clear = 0;
    tb_count_enable = 1;
    reset_dut();
    // Wait for DUT to process stimulus before checking results
    //@(posedge tb_clk); 
    //@(posedge tb_clk); 
    // Move away from risign edge and allow for propagation delays before checking
    //#(CHECK_DELAY);
    // Check results
    check_output( 0,0,"");
   
    @(posedge tb_clk);
    check_output( 1,0,"");

    @(posedge tb_clk);
    check_output( 2,0,"");
    @(posedge tb_clk);
    check_output( 3,0,"");
    @(posedge tb_clk);
    check_output( 4,0,"");
    @(posedge tb_clk);
    check_output( 5,1,"");

    @(posedge tb_clk);
    check_output(1,0,"");
    @(posedge tb_clk);
    check_output(2,0,"");
    // ************************************************************************
    // Test Case 3: Normal Operation duscontinous counting
    // ************************************************************************    
    @(negedge tb_clk); 
    tb_test_num = tb_test_num + 1;
    tb_test_case = "Normal Operation duscontinous counting";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    tb_rollover_val= 7;
    tb_clear = 0;
    tb_count_enable = 1;
    reset_dut();


    // Wait for DUT to process stimulus before checking results
    
    // Move away from risign edge and allow for propagation delays before checking
    //#(CHECK_DELAY);
    // Check results
    check_output( 0,0,"");
    @(posedge tb_clk);
    check_output( 1,0,"");

    @(posedge tb_clk);
    check_output( 2,0,"");
    @(posedge tb_clk);
    check_output( 3,0,"");
    @(posedge tb_clk);
    check_output( 4,0,"");
    tb_count_enable = 0;
    @(posedge tb_clk);
    check_output( 4,0,"");
    
    @(posedge tb_clk);
    check_output(4,0,"");
    tb_count_enable = 1;
    @(posedge tb_clk);
    check_output(5,0,"");
    @(posedge tb_clk);
    check_output(6,0,"");
    @(posedge tb_clk);
    check_output(7,1,"");
    // ************************************************************************    
    // Test Case 4: Setup Violation with clear 1
    // ************************************************************************
    @(negedge tb_clk); 
    tb_test_num = tb_test_num + 1;
    tb_test_case = "Normal Operation with clear as 1";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    tb_rollover_val= 7;
    tb_clear = 0;
    tb_count_enable = 1;
    reset_dut();


    // Wait for DUT to process stimulus before checking results
    
    // Move away from risign edge and allow for propagation delays before checking
    //#(CHECK_DELAY);
    // Check results
    check_output( 0,0,"");
    @(posedge tb_clk);
    check_output( 1,0,"");

    @(posedge tb_clk);
    check_output( 2,0,"");
    @(posedge tb_clk);
    check_output( 3,0,"");
    @(posedge tb_clk);
    check_output( 4,0,"");
    tb_clear = 1;
    @(posedge tb_clk);
    check_output(0,0,"");
    
    @(posedge tb_clk);
    check_output(0,0,"");
    tb_clear = 0;
    @(posedge tb_clk);
    check_output(1,0,"");
    @(posedge tb_clk);
    check_output(2,0,"");
    @(posedge tb_clk);
    check_output(3,1,"");
    // ************************************************************************    
    // Test Case 5: Setup Violation with Input as a '1'
    // ************************************************************************
    
    @(negedge tb_clk); 
    tb_test_num = tb_test_num + 1;
    tb_test_case = "Normal Operation with rollover value not power of 2";
    // Start out with inactive value and reset the DUT to isolate from prior tests
   
   

    // Assign test case stimulus
    tb_rollover_val= 15;
    tb_clear = 0;
    tb_count_enable = 1;
    reset_dut();
    // Wait for DUT to process stimulus before checking results
    //@(posedge tb_clk); 
    //@(posedge tb_clk); 
    // Move away from risign edge and allow for propagation delays before checking
    //#(CHECK_DELAY);
    // Check results
    check_output( 0,0,"");
    @(posedge tb_clk);
    check_output( 1,0,"");

    @(posedge tb_clk);
    check_output( 2,0,"");
    @(posedge tb_clk);
    check_output( 3,0,"");
    @(posedge tb_clk);
    check_output( 4,0,"");
    @(posedge tb_clk);
    check_output( 5,0,"");
    @(posedge tb_clk);
    check_output( 6,0,"");
    @(posedge tb_clk);
    check_output( 7,0,"");
    @(posedge tb_clk);
    check_output( 8,0,"");
    @(posedge tb_clk);
    check_output( 9,0,"");
    @(posedge tb_clk);
    check_output( 10,0,"");
    @(posedge tb_clk);
    check_output( 11,0,"");
    @(posedge tb_clk);
    check_output( 12,0,"");
    @(posedge tb_clk);
    check_output( 13,0,"");
    @(posedge tb_clk);
    check_output( 14,0,"");
    @(posedge tb_clk);
    check_output( 15,1,"");
    @(posedge tb_clk);
    check_output( 1,0,"");

  $stop;
  end
endmodule
