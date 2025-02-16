//----------------------+-------------------------------------------------------
// Filename             | euclidean_dist.sv
// File created on      | 08/02/2025
// Created by           | Sree Sankar E
//                      |
//                      |
//----------------------+-------------------------------------------------------
//
//------------------------------------------------------------------------------
// Euclidean Distance Calculation for each class
// > Not taking square root as the least the distace is for infereing
// > If required root can be taken using CORDIC algorithm
//------------------------------------------------------------------------------

module euclidean_dist #(
    parameter DW     = 8                   ,
    parameter PARAMS = 1
)(
    input                  clk_i           ,
    input                  resetn_i        ,
    input                  enable_i        ,
    input  [          2:0] ctrl_i          ,
    // Input Centroid
    input  [PARAMS*DW-1:0] centroid_i      ,
    input                  centroid_valid_i,
    // Input Data
    input  [PARAMS*DW-1:0] data_i          ,
    input                  data_valid_i    ,
    // Output Distance
    output [       DW-1:0] dist_o
);

//------------------------------------------------------------------------------
// Distance Calculation
//------------------------------------------------------------------------------

    logic [DW-1:0] res        [0:PARAMS-1];
    logic [DW-1:0] prev_accum [0:PARAMS-1];
    logic [DW-1:0] centroid   [0:PARAMS-1];
    logic [DW-1:0] data       [0:PARAMS-1];

    generate
        for(genvar params_count = 'h0; params_count < PARAMS; params_count++)
            begin
            compute_unit #(
                .DW              (DW                          )
            ) compute_unit (
                .clk_i           (clk_i                       ),
                .resetn_i        (resetn_i                    ),
                .enable_i        (enable_i                    ),
                .ctrl_i          (ctrl_i                      ),
                .centroid_i      (centroid[params_count]      ),
                .centroid_valid_i(centroid_valid_i            ),
                .prev_accum_i    (prev_accum[params_count]    ),
                .data_i          (data[params_count]          ),
                .data_valid_i    (data_valid_i                ),
                .res_o           (res[params_count]           )
            );
            end
    endgenerate

//------------------------------------------------------------------------------
// Muxing Data and Centroid
//------------------------------------------------------------------------------

    always_comb
        begin
        for(int params_count = 0; params_count < PARAMS; params_count++)
            begin
            centroid[params_count]   = centroid_i[params_count*DW +: DW];
            data[params_count]       = data_i[params_count*DW +: DW];
            prev_accum[params_count] = (params_count == 'h0) ? 'h0 : res[params_count-1];
            end
        end

//------------------------------------------------------------------------------
// Output
//------------------------------------------------------------------------------

    assign dist_o = res[PARAMS-1];

endmodule