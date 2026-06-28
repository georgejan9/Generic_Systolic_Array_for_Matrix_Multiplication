`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/27/2025 10:06:56 PM
// Design Name: 
// Module Name: systolic_array
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module systolic_array # (parameter integer DATAWIDTH=16,parameter integer N_SIZE=5)
(
    input clk,rst_n,valid_in,
    input [DATAWIDTH-1:0] matrix_a_in [N_SIZE-1:0],
    input [DATAWIDTH-1:0] matrix_b_in [N_SIZE-1:0],
    output valid_out,
    output [2*(DATAWIDTH)-1:0] matrix_c_out [N_SIZE-1:0]
);
//A reg array 
wire [DATAWIDTH-1:0] output_A [N_SIZE-1:0];
wire [N_SIZE-1:0]valid_A,rst_A ;
wire [2*(DATAWIDTH)-1:0] out_c [N_SIZE-1:0][N_SIZE-1:0];
wire valid_out_matrix [N_SIZE-1:0][N_SIZE-1:0];
wire Start_out [N_SIZE-1:0][N_SIZE-1:0];

REG_array # (.DATAWIDTH(DATAWIDTH),.N_SIZE(N_SIZE)) ArrayA
(
    .clk (clk),.valid_in (valid_in),.rst_n(rst_n),
    .matrix_in (matrix_a_in),
    .valid_out(valid_A),
    .matrix_out (output_A)
);
//B reg array 
wire [DATAWIDTH-1:0] output_B [N_SIZE-1:0];
wire [N_SIZE-1:0]valid_B,rst_B ;

REG_array # (.DATAWIDTH(DATAWIDTH),.N_SIZE(N_SIZE)) ArrayB
(
    .clk (clk),.valid_in (valid_in),.rst_n(rst_n),
    .matrix_in (matrix_b_in),
    .valid_out(valid_B),
    .matrix_out (output_B)
);

//PE_array
PE_array # (.DATAWIDTH(DATAWIDTH),.N_SIZE(N_SIZE)) pe_array (
    .in_A (output_A),
    .in_B (output_B),
    .valid_B (valid_B),
    .clk(clk),.rst_n(rst_n),
    .out_c (out_c),
    .valid_out (valid_out_matrix)
    );
//valid flag
wire Start_out_flag;
assign valid_out = valid_out_matrix[0][N_SIZE-1];
assign Start_out_flag = valid_out_matrix[0][N_SIZE-2];

//output
MUX #(.DATAWIDTH(DATAWIDTH),.N_SIZE(N_SIZE)) MUX_OUT
(   .valid (valid_out), .clk (clk),.rst_n(rst_n),
    .data_in (out_c),
    .data_out(matrix_c_out)
);
endmodule


//PE array
module PE_array # (parameter integer DATAWIDTH=16,parameter integer N_SIZE=5)(
    input [DATAWIDTH-1:0] in_A [N_SIZE-1:0],
    input [DATAWIDTH-1:0] in_B [N_SIZE-1:0],
    input [N_SIZE-1:0]valid_B ,
    input clk,rst_n,
    output [2*(DATAWIDTH)-1:0] out_c [N_SIZE-1:0][N_SIZE-1:0],
    output valid_out [N_SIZE-1:0][N_SIZE-1:0]
    );
wire [DATAWIDTH-1:0] A [N_SIZE-1:0][N_SIZE-1:0];
wire [DATAWIDTH-1:0] B [N_SIZE-1:0][N_SIZE-1:0];
reg valid [N_SIZE-1:0][N_SIZE-1:0];
generate
genvar i,j,k;
for (k=0 ; k< N_SIZE ; k=k+1)
begin
    assign A [k][0]=in_A[k];
    assign B [0][k]=in_B[k];
    assign valid [0][k]= valid_B[k];
end
for (i=0 ; i<N_SIZE ; i=i+1)
begin : PE_array

    for (j=0 ; j<N_SIZE ; j=j+1)
    begin

    PE # (.DATAWIDTH (DATAWIDTH),.N_SIZE (N_SIZE)) pe_in (
    .clk (clk), .rst_n (rst_n), .valid_in (valid [i][j]), 
    .a_in (A[i][j]), .b_in (B[i][j]),
    .a_out (A[i][j+1]), .b_out (B[i+1][j]), 
    .o_out (out_c[i][j]),
    .valid_out (valid_out[i][j]),.validin_out(valid [i+1][j])
    );
    end
end
endgenerate
endmodule

//PE
module PE # (parameter integer DATAWIDTH = 16, parameter integer N_SIZE =5)  (
    input clk , rst_n , valid_in , 
    input [DATAWIDTH-1:0] a_in , b_in ,
    output reg [DATAWIDTH-1:0] a_out , b_out , 
    output [2*(DATAWIDTH)-1:0] o_out ,
    output reg valid_out,validin_out
    );
    
reg [2*(DATAWIDTH)-1:0] o_saved;
reg [$clog2(N_SIZE)-1:0] counter;
assign o_out = o_saved;
always @ (posedge clk or negedge rst_n)
begin
    if (rst_n == 1'b0)
    begin
        o_saved <= 0;
        valid_out <= 1'b0;
        counter <= 0;
        validin_out<=1'b0;
    end
    else if (valid_in == 1'b1)
    begin
        a_out <= a_in;
        b_out <= b_in;
        o_saved <= o_saved + a_in*b_in;
        counter <= counter + 1;
        validin_out<=valid_in;  //transfar valid_in
        if (counter == N_SIZE-1)//generate valid_out flag 
            valid_out <= 1'b1;
    end
    else if (valid_in == 1'b0)
    begin
        counter <= 0;
        o_saved <= o_saved; 
        validin_out <= valid_in;       
    end
    else
        o_saved <= o_saved;
end
endmodule

//REG array
module REG_array # (parameter integer DATAWIDTH=16,parameter integer N_SIZE=5)
(
    input clk,valid_in,rst_n,
    input [DATAWIDTH-1:0] matrix_in [N_SIZE-1:0],
    output [N_SIZE-1:0]valid_out,
    output [DATAWIDTH-1:0] matrix_out [N_SIZE-1:0]
);
wire [DATAWIDTH-1:0] A [N_SIZE-1:0][N_SIZE-1:0];
wire valid_c [N_SIZE-1:0][N_SIZE-1:0] ;

generate
genvar i,k;
for (i=0 ; i<N_SIZE ; i=i+1)
begin
    assign A[i][0] = matrix_in [i];
    assign valid_c [i][0] = valid_in;
    if (i==0)
    begin
            assign matrix_out[i] = matrix_in [0];
            assign valid_out [i]= valid_in;
    end
    else
    begin  
        for (k=0 ; k<i ; k=k+1)
        begin : REG_column_stage
        
        REG # (.DATAWIDTH(DATAWIDTH))  reg_in(
                    .clk (clk),.valid_in (valid_c [i][k]),
                    .rst_n(rst_n),
                    .in (A[i][k]),
                    .out (A[i][k+1]),
                    .valid_inout (valid_c [i][k+1])
                    );
        if (k+1==i)
        begin
            assign matrix_out[i] = A[i][k+1];
            assign valid_out [i]= valid_c [i][k+1];
        end                  
        end
    end
end
endgenerate
endmodule


//REG
module REG # (parameter integer DATAWIDTH = 16)  (
    input clk ,valid_in , rst_n,
    input [DATAWIDTH-1:0] in ,
    output reg [DATAWIDTH-1:0] out ,
    output reg valid_inout 
    );
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n==0)
        out<=0;
    else 
    begin
    out<=in;
    valid_inout<=valid_in;
    end
end
endmodule

//MUX
module MUX #(parameter integer DATAWIDTH= 16,parameter integer N_SIZE= 5) 
(   input valid , clk ,rst_n,
    input  [2*(DATAWIDTH)-1:0] data_in [N_SIZE-1:0][N_SIZE-1:0],
    output [2*(DATAWIDTH)-1:0] data_out[N_SIZE-1:0]
);
reg [$clog2(N_SIZE)-1:0] sel;
    always @ (posedge clk or negedge rst_n)
    begin
    if (rst_n==1'b0)
        sel<=0;
    else if (valid==1'b1)
    begin
        sel<=sel+1 ;
    end
    end
    assign data_out = data_in[sel] ;
endmodule
