//----------------------+-------------------------------------------------------
// Filename             | compute_unit.sv
// File created on      | 08/02/2025
// Created by           | Sree Sankar E
//                      |
//                      |
//----------------------+-------------------------------------------------------
//
//------------------------------------------------------------------------------
// Compute Unit
// > 1st Cycle = (data_i - centroid_i)
// > 2nd Cycle = (data_i - centroid_i) * (data_i - centroid_i)
// > 3rd Cycle = Summation(2nd Cycle Data)
//------------------------------------------------------------------------------

module compute_unit #(
    parameter DW = 8
)(
    input           clk_i           ,
    input           resetn_i        ,
    input           enable_i        ,
    input  [   2:0] ctrl_i          ,
    input  [DW-1:0] prev_accum_i    ,
    input  [DW-1:0] centroid_i      ,
    input           centroid_valid_i,
    input  [DW-1:0] data_i          ,
    input           data_valid_i    ,
    output [DW-1:0] res_o
);

//------------------------------------------------------------------------------
// Registering Data when not enabled to avoid changes in data during computaiton
//------------------------------------------------------------------------------

    logic [  DW-1:0] centroid_reg;
    logic [  DW-1:0] data_reg    ;
    logic [2*DW-1:0] res_reg     ;
    logic [2*DW-1:0] res         ;

    always_ff @(posedge clk_i)
        begin
        if(!resetn_i)
            begin
            centroid_reg <= 'h0;
            data_reg     <= 'h0;
            res_reg      <= 'h0;
            end
        else
            begin
            // Registering Centroid
            if(centroid_valid_i)
                begin
                centroid_reg <= centroid_i;
                end
            // Registering Data
            if(data_valid_i)
                begin
                data_reg <= data_i;
                end
            // Registering result
            if(|ctrl_i)
                begin
                res_reg <= res;
                end
            end
        end

//------------------------------------------------------------------------------
// 2's complement addition for subtraction
//------------------------------------------------------------------------------

    logic [DW-1:0] centroid_neg;

    assign centroid_neg = (centroid_reg[DW-1]) ? centroid_reg : (~centroid_reg + 'h1) ;

//------------------------------------------------------------------------------
// DSP for Mat Opertions
// > DSP Configuration    : (A + D) * B
//      > 1st Cycle Operatiron : (Xi - Ci)
//      > 2nd Cycle Operatiron : ((Xi - Ci) * (Xi - Ci))
//      > 3rd Cycle Operatiron : Sum((Xi - Ci) * (Xi - Ci))
//------------------------------------------------------------------------------

    logic [DW-1:0] in_a;
    logic [DW-1:0] in_b;
    logic [DW-1:0] in_d;

    mult_sub mult_sub_inst (
        .A      (in_a ), // input wire [7 : 0] A
        .B      (in_b ), // input wire [7 : 0] B
        .D      (in_d ), // input wire [7 : 0] D
        .P      (res  )  // output wire [16 : 0] P
    );

    assign in_a = ctrl_i[0] ? data_reg     : res_reg;
    assign in_b = ctrl_i[1] ? res_reg      : 'h1;
    assign in_d = ctrl_i[0] ? centroid_neg :
                  ctrl_i[1] ? 'h0          : prev_accum_i;

//------------------------------------------------------------------------------
// Output
//------------------------------------------------------------------------------

    assign res_o = ctrl_i[2] ? res : res_reg;

endmodule