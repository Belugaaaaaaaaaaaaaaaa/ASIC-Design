// $Id: $
// File name:   tb_mealy.sv
// Created:     2/10/2023
// Author:      Tingyu Wu
// Lab Section: 337-17
// Version:     1.0  Initial Design Entry
// Description: .
`timescale 1ns/10ps

module tb_mealy();
    localparam CLK_PERIOD = 2.5;
    localparam PROPAGATION_DELAY = 0.8; // Allow for 800 ps for FF propagation delay

    localparam  INACTIVE_VALUE     = 1'b1;
    localparam  SR_SIZE_BITS       = 4;
    localparam  SR_MAX_BIT         = SR_SIZE_BITS - 1;
    localparam  RESET_OUTPUT_VALUE = 1'b1;
    localparam FF_setup_time = 0.19;
    localparam FF_HOLD_TIME = 0.1;
    localparam CHECK_DELAY = (CLK_PERIOD - FF_setup_time);
    integer tb_test_num;
    string  tb_test_case;
    integer tb_bit_num;
    logic   tb_check;
    logic tb_i;
    logic tb_o;
    logic tb_n_rst;
    logic tb_clk;
    

    logic  tb_expected_ouput;
    logic  tb_test_data [];

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

    // Task to manage the timing of sending one bit out of the shift register
    task send_bit;
    input logic input_bit;
    begin
        // Synchronize to the negative edge of clock to prevent timing errors
        @(negedge tb_clk);
        tb_i = input_bit;

        // Wait for the value to have been shifted in on the rising clock edge
        @(posedge tb_clk);
        #(PROPAGATION_DELAY);

    end
    endtask


    task send_stream;
        input logic bit_stream[];
        begin
            for(tb_bit_num = 0; tb_bit_num < bit_stream.size(); tb_bit_num++) begin
                send_bit(bit_stream[tb_bit_num]);
            end
        end
    endtask

    task check_output;
        input logic tb_expected_ouput;
        input string check_tag;
    begin
        #(CHECK_DELAY);
        if(tb_expected_ouput == tb_o) begin // Check passed
        $info("Correct serial output %s during %s test case", check_tag, tb_test_case);
        end
        else begin // Check failed
        $error("Incorrect serial output %s during %s test case", check_tag, tb_test_case);
        end
        #(0.1);
        // Wait some small amount of time so check pulse timing is visible on waves
        end
    endtask
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

    
    
    // DUT Port map
        mealy DUT(.clk(tb_clk), .n_rst(tb_n_rst), .i(tb_i), .o(tb_o));
    
    // Test bench main process
    initial
    begin
        tb_test_num = 0;
        tb_test_case = "";
        tb_bit_num = 0;
        tb_check = 0;
        tb_n_rst = 1'b1;
        #(0.1);
        // Test 1:POWER ON REST//
        tb_test_num = tb_test_num+1;
        tb_test_case = "POWER ON REST";
        #(0.1);
        tb_n_rst = 1'b0;
        #(CLK_PERIOD*0.5);
        check_output('0,"RESET");
        #(CLK_PERIOD);
        check_output('0,"A FULL CLK AFTER RESET");
        @(negedge tb_clk);
        tb_n_rst = 1'b1;
        #(PROPAGATION_DELAY);
        check_output('0,"RESET INACTIVE");
        //Test 2: INPUT 1101
        tb_test_num = tb_test_num + 1;
        tb_test_case = "1101";
        #(0.1);
        reset_dut();
        tb_test_data = '{1,1,0,1};
        send_stream(tb_test_data);
        check_output('1,"HAS 1101");
        //Test 3: input 11001
        tb_test_num = tb_test_num + 1;
        tb_test_case = "11001";
        #(0.1);
        reset_dut();
        tb_test_data = '{1,1,0,0,1};
        send_stream(tb_test_data);
        check_output('0,"No 1101");
        //Test 4: input 1101101
        tb_test_num = tb_test_num + 1;
        tb_test_case = "1101101";
        #(0.1);
        reset_dut();
        tb_test_data = '{0,1,1,0,1,1,0,1,1,1};
        send_stream(tb_test_data);
        check_output('1,"HAS 1101");
        //Test 5: input 101010
        tb_test_num = tb_test_num + 1;
        tb_test_case = "101010";
        #(0.1);
        reset_dut();
        tb_test_data = '{1,0,1,0,1,0};
        send_stream(tb_test_data);
        check_output('0,"No 1101");
        //Test 6: INPUT 11010
        tb_test_num = tb_test_num + 1;
        tb_test_case = "1,1,0,1 RESET";
        #(0.1);
        reset_dut();
        tb_test_data = '{0,1,1,0,1,1,0,1};
        send_stream(tb_test_data);
        reset_dut();
        check_output('0,"RESET AFTER DETECTION");
        //Test 7: input 1100
        tb_test_num = tb_test_num + 1;
        tb_test_case = "1100";
        #(0.1);
        reset_dut();
        tb_test_data = '{1,1,0,0};
        send_stream(tb_test_data);
        check_output('0,"No 1101");
        //Test 2: INPUT 01010
        tb_test_num = tb_test_num + 1;
        tb_test_case = "01010";
        #(0.1);
        reset_dut();
        tb_test_data = '{0,1,0,1,0};
        send_stream(tb_test_data);
        check_output('0,"NO 1101");
    end 
endmodule