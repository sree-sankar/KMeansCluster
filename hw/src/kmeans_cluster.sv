//----------------------+-------------------------------------------------------
// Filename             | compute_unit.sv
// File created on      | 08/02/2025
// Created by           | Sree Sankar E
//                      |
//                      |
//----------------------+-------------------------------------------------------
//
//------------------------------------------------------------------------------
// K Means Clustering
//   > 5 Clock Latency for result
//   > Reusing the same DSP for subtraction, squaring and addition
//   > Square Root is not taken as there is no need for cluster finding
//------------------------------------------------------------------------------

module kmeans_cluster #(
    parameter DW       = 8                          ,
    parameter CLUSTERS = 2                          ,
    parameter PARAMS   = 13
)(
    // Clock and Reset
    input                           clk_i           ,
    input                           resetn_i        ,
    // Control and Status
    input                           enable_i        ,
    output [                  31:0] status_o        ,
    // Input Centroid
    input  [CLUSTERS*PARAMS*DW-1:0] centroid_i      ,
    input                           centroid_valid_i,
    // Input Data
    input  [         PARAMS*DW-1:0] data_i          ,
    input                           data_valid_i    ,
    // Output Data
    output [  $clog2(CLUSTERS)-1:0] cluster_o       ,
    output [              2*DW-1:0] min_dist_o      ,
    output                          valid_o
);

    localparam CLUSTERS_DW = $clog2(CLUSTERS);

//------------------------------------------------------------------------------
// Control Path
//------------------------------------------------------------------------------

    enum logic [5:0] {
        IDLE  = 'h01, // Idle state
        SUB   = 'h02, // Subtraction state (Xi - Ci)
        SQR   = 'h04, // Square state (Xi - Ci) * (Xi - Ci)
        ADD   = 'h08,  // Add all elements Sum of all((Xi - Ci) * (Xi - Ci))
        // SQRT  = 'h10, // Find square root
        MIN   = 'h10 // Find minimum distance
    } kmeans_state;

    // State Signal
    logic       idle_state;
    logic       sub_state ;
    logic       sqr_state ;
    logic       add_state ;
    logic       min_state ;
    // Control
    logic [2:0] ctrl      ;

    always_ff @(posedge clk_i)
        begin
        if(!resetn_i)
            begin
            kmeans_state <= IDLE;
            end
        else
            begin
            case(kmeans_state)
                IDLE :
                    begin
                    if(enable_i)
                        begin
                        kmeans_state <= SUB;
                        end
                    end
                SUB :
                    begin
                    kmeans_state <= SQR;
                    end
                SQR :
                    begin
                    kmeans_state <= ADD;
                    end
                ADD :
                    begin
                    kmeans_state <= MIN;
                    end
                MIN :
                    begin
                    kmeans_state <= IDLE;
                    end
                // SQRT :
                //     begin
                //     kmeans_state <= IDLE;
                //     end
                default : kmeans_state <= IDLE;
            endcase
            end
        end

    assign idle_state = (kmeans_state == IDLE) ? 'h1 : 'h0;
    assign sub_state  = (kmeans_state == SUB ) ? 'h1 : 'h0;
    assign sqr_state  = (kmeans_state == SQR ) ? 'h1 : 'h0;
    assign add_state  = (kmeans_state == ADD ) ? 'h1 : 'h0;
    assign min_state  = (kmeans_state == MIN ) ? 'h1 : 'h0;

//------------------------------------------------------------------------------
// Status
//------------------------------------------------------------------------------

    assign status_o = kmeans_state;

//------------------------------------------------------------------------------
// Euclidian Distance Calculation for each cluster
//------------------------------------------------------------------------------

    logic [     2*DW-1:0] euclidean_dist [0:CLUSTERS-1];
    logic [PARAMS*DW-1:0] centroid       [0:CLUSTERS-1];

    generate
        for(genvar cluster_count = 'h0; cluster_count < CLUSTERS; cluster_count++)
            begin
            euclidean_dist #(
                .DW               (DW                           ),
                .PARAMS           (PARAMS                       )
            ) euclidean_dist_inst(
                .clk_i            (clk_i                        ),
                .resetn_i         (resetn_i                     ),
                .enable_i         (enable_i                     ),
                .ctrl_i           (ctrl                         ),
                .centroid_i       (centroid[cluster_count]      ),
                .centroid_valid_i (centroid_valid_i             ),
                .data_i           (data_i                       ),
                .data_valid_i     (data_valid_i                 ),
                .dist_o           (euclidean_dist[cluster_count])
            );
            end
    endgenerate

    assign ctrl = {add_state,sqr_state,sub_state};

//------------------------------------------------------------------------------
// Muxing Centroid
//------------------------------------------------------------------------------

    always_comb
        begin
        for(int cluster_count = 0; cluster_count <CLUSTERS; cluster_count++)
            begin
            centroid[cluster_count] = centroid_i[cluster_count*PARAMS*DW +: PARAMS*DW];
            end
        end

//------------------------------------------------------------------------------
// Minimum Distance Cluster
//------------------------------------------------------------------------------

    logic [       2*DW-1:0] min_dist;
    logic [CLUSTERS_DW-1:0] cluster ;

    always_comb
        begin
        if(min_state)
            begin
            min_dist = {DW{1'b1}};
            cluster  = 'h0;
            for(int cluster_count = 'h0; cluster_count < CLUSTERS; cluster_count++)
                begin
                if(min_dist > euclidean_dist[cluster_count])
                    begin
                    min_dist = euclidean_dist[cluster_count];
                    cluster  = cluster_count;
                    end
                end
            end
        else
            begin
            min_dist = {DW{1'b1}};
            cluster  = 'h0;
            end
        end

//------------------------------------------------------------------------------
// Sampling
//------------------------------------------------------------------------------

    logic [       2*DW-1:0] min_dist_s;
    logic [CLUSTERS_DW-1:0] cluster_s ;
    logic                   valid     ;

    always_ff @(posedge clk_i)
        begin
        if(!resetn_i)
            begin
            min_dist_s <= 'h0;
            cluster_s  <= 'h0;
            valid      <= 'h0;
            end
        else
            begin
            valid <= min_state;
            if(min_state)
                begin
                min_dist_s <= min_dist;
                cluster_s  <= cluster ;
                end
            end
        end

//------------------------------------------------------------------------------
// Output
//------------------------------------------------------------------------------

    assign cluster_o  = cluster_s ;
    assign min_dist_o = min_dist_s;
    assign valid_o    = valid     ;

endmodule