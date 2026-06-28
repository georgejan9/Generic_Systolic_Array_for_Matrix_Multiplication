`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/27/2025 10:11:51 PM
// Design Name: 
// Module Name: systolic_array_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Corrected testbench with file logging.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - Added file I/O for logging simulation results.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module systolic_array_tb();
    // Parameters
    parameter integer DATAWIDTH = 16;
    parameter integer N_SIZE = 3;

    // Signals
    reg clk, rst_n, valid_in;
    reg [DATAWIDTH-1:0] matrix_a_in [N_SIZE-1:0];
    reg [DATAWIDTH-1:0] matrix_b_in [N_SIZE-1:0];
    wire valid_out;
    wire [2*(DATAWIDTH)-1:0] matrix_c_out [N_SIZE-1:0];

    // File handle for logging
    integer file_handle;
    
    // Stored input matrices for logging
    reg [DATAWIDTH-1:0] matrix_a_log [N_SIZE-1:0][N_SIZE-1:0];
    reg [DATAWIDTH-1:0] matrix_b_log [N_SIZE-1:0][N_SIZE-1:0];

    // Instantiate the Design Under Test (DUT)
    systolic_array # (.DATAWIDTH(DATAWIDTH), .N_SIZE(N_SIZE)) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .matrix_a_in(matrix_a_in),
        .matrix_b_in(matrix_b_in),
        .valid_out(valid_out),
        .matrix_c_out(matrix_c_out)
    );

    // Clock generator
    initial begin
        clk = 0;
        forever #50 clk = ~clk; // 100ns period -> 10MHz clock
    end

    // Test sequence
    initial begin
        // Open the log file for writing. This will create 'file.log'.
        file_handle = $fopen("file.log", "w");
        if (file_handle == 0) begin
            $display("ERROR: Could not open file.log for writing.");
            $finish;
        end

        // --- Reset and Initialization ---
        rst_n = 1;
        @(negedge clk);
        rst_n = 0;
        valid_in = 0;
        matrix_a_in = '{default:0};
        matrix_b_in = '{default:0};
        @(negedge clk);
        rst_n = 1;

        // --- Apply Inputs and Log Them ---
        $fdisplay(file_handle, "--- Simulation Log ---");
        $fdisplay(file_handle, "Input Matrix A:");
        
        // Cycle 1
        @(negedge clk);
        valid_in = 1;
        matrix_a_in[0] = 3; matrix_a_in[1] = 1; matrix_a_in[2] = 11;
        matrix_b_in[0] = 8; matrix_b_in[1] = 9; matrix_b_in[2] = 7;
        // Store for logging
        matrix_a_log[0] = matrix_a_in;
        matrix_b_log[0] = matrix_b_in;

        // Cycle 2
        @(negedge clk);
        matrix_a_in[0] = 9; matrix_a_in[1] = 5; matrix_a_in[2] = 15;
        matrix_b_in[0] = 5; matrix_b_in[1] = 15; matrix_b_in[2] = 2;
        // Store for logging
        matrix_a_log[1] = matrix_a_in;
        matrix_b_log[1] = matrix_b_in;

        // Cycle 3
        @(negedge clk);
        matrix_a_in[0] = 2; matrix_a_in[1] = 7; matrix_a_in[2] = 21;
        matrix_b_in[0] = 1; matrix_b_in[1] = 11; matrix_b_in[2] = 13;
        // Store for logging
        matrix_a_log[2] = matrix_a_in;
        matrix_b_log[2] = matrix_b_in;

        // De-assert valid_in
        @(negedge clk);
        valid_in = 0;
        matrix_a_in = '{default:0};
        matrix_b_in = '{default:0};

        // --- Print stored input matrices to the log file ---
        // Note: Systolic arrays process rows/columns. How you print depends on how you fed them.
        // This assumes matrix_a_in was a column and matrix_b_in was a row each cycle.
        $fdisplay(file_handle, "Matrix A (fed as columns):");
        for (int i = 0; i < N_SIZE; i++) begin
            $fdisplay(file_handle, "\t%d\t%d\t%d", matrix_a_log[0][i], matrix_a_log[1][i], matrix_a_log[2][i]);
        end
        
        $fdisplay(file_handle, "\nInput Matrix B (fed as rows):");
        for (int i = 0; i < N_SIZE; i++) begin
            $fdisplay(file_handle, "\t%d\t%d\t%d", matrix_b_log[i][0], matrix_b_log[i][1], matrix_b_log[i][2]);
        end
        
        $fdisplay(file_handle, "\n----------------------");
        $fdisplay(file_handle, "Output Matrix C:");

        // Wait for all valid outputs
        repeat (N_SIZE) begin
            @(posedge valid_out);
            @(negedge clk); // Ensure data is stable
            $fdisplay(file_handle, "\t%p", matrix_c_out);
        end
        
        // --- End Simulation ---
        $display("TEST PASSED: All outputs received and logged.");
        #100;
        
        // Close the log file
        $fclose(file_handle);
        $finish;
    end

    // Console monitoring (optional, but good for live debugging)
    initial
        $monitor("Time=%0t: rst_n=%b, valid_in=%b, valid_out=%b, matrix_c_out=%p",
                 $time, rst_n, valid_in, valid_out, matrix_c_out);

endmodule
/* another testbench but does not write on file.log
module systolic_array_tb();
    parameter integer DATAWIDTH=16;
    parameter integer N_SIZE=3;
    reg clk,rst_n,valid_in;
    reg [DATAWIDTH-1:0] matrix_a_in [N_SIZE-1:0];
    reg [DATAWIDTH-1:0] matrix_b_in [N_SIZE-1:0];
    wire valid_out;
    wire [2*(DATAWIDTH)-1:0] matrix_c_out [N_SIZE-1:0];
    
//DUT
systolic_array # (.DATAWIDTH(DATAWIDTH),.N_SIZE(N_SIZE)) DUT
(
    .clk (clk),.rst_n (rst_n),.valid_in (valid_in),
    .matrix_a_in (matrix_a_in),
    .matrix_b_in (matrix_b_in),
    .valid_out (valid_out),
    .matrix_c_out (matrix_c_out)
);
// clk
    initial
    begin
        clk=0;
    forever 
        #100 clk=~clk;
    end
// test inputs
initial
begin
        rst_n=1;
    @(negedge clk)
        rst_n=0;
        valid_in=0;
        matrix_a_in = '{default:0};
        matrix_b_in = '{default:0};
    @(negedge clk)
        rst_n=1;
        valid_in=1;
        matrix_a_in[0]='d3;
        matrix_a_in[1]='d1;
        matrix_a_in[2]='d11;
        
        matrix_b_in[0]='d8;
        matrix_b_in[1]='d9;
        matrix_b_in[2]='d7;
    @(negedge clk)
            matrix_a_in[0]='d9;
            matrix_a_in[1]='d5;
            matrix_a_in[2]='d15;
            
            matrix_b_in[0]='d5;
            matrix_b_in[1]='d15;
            matrix_b_in[2]='d2;
    @(negedge clk)
            matrix_a_in[0]='d2;
            matrix_a_in[1]='d7;
            matrix_a_in[2]='d21;
            
            matrix_b_in[0]='d1;
            matrix_b_in[1]='d11;
            matrix_b_in[2]='d13;
    @(negedge clk)
        valid_in=0;
            matrix_a_in[0]='d9;
            matrix_a_in[1]='d9;
            matrix_a_in[2]='d9;
            
            matrix_b_in[0]='d9;
            matrix_b_in[1]='d9;
            matrix_b_in[2]='d9;
    @(negedge clk)
    @(negedge clk)
    if (matrix_c_out[0]!=71 || matrix_c_out[1]!=184 || matrix_c_out[2]!=65)
    begin
        $display ("ERROR");
        $stop;
    end
    @(negedge clk)
    if (matrix_c_out[0]!=40 || matrix_c_out[1]!=161 || matrix_c_out[2]!=108)
    begin
        $display ("ERROR");
        $stop;
    end
    @(negedge clk)
    if (matrix_c_out[0]!=184 || matrix_c_out[1]!=555 || matrix_c_out[2]!=380)
    begin
        $display ("ERROR");
        $stop;
    end
$display ("TEST passed");
    #1500;
$stop;
end 

// monitoring
initial
    $monitor ("reset = %b,Valid input = %b ,input A = %p,input B = %p,output = %p,Valid output = %b" 
    , rst_n , valid_in , matrix_a_in , matrix_b_in , matrix_c_out , valid_out);
endmodule
*/