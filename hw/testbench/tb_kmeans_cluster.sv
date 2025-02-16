//----------------------+-------------------------------------------------------
// Filename             | tb_kmeans_cluster.sv
// File created on      | 09/02/2025
// Created by           | Sree Sankar E
//                      |
//                      |
//                      |
//----------------------+-------------------------------------------------------
//
//------------------------------------------------------------------------------
// Testbench
//------------------------------------------------------------------------------

module tb_kmeans_cluster();

    localparam DW       = 16;
    localparam CLUSTERS = 2 ;
    localparam PARAMS   = 13;

    logic                          clk_i           ;
    logic                          resetn_i        ;
    logic                          enable_i        ;
    logic [                  31:0] status_o        ;
    logic [CLUSTERS*PARAMS*DW-1:0] centroid_i      ;
    logic                          centroid_valid_i;
    logic [         PARAMS*DW-1:0] data_i          ;
    logic                          data_valid_i    ;
    logic [  $clog2(CLUSTERS)-1:0] cluster_o       ;
    logic [                DW-1:0] min_dist_o      ;
    logic                          valid_o         ;

    integer fd_data    ; // File Decriptor for input data
    integer fd_centroid; // File Decriptor for feature centroids

    logic [DW-1:0] data     [0:2*PARAMS-1]; // 2 Sets of Data for simulation
    logic [DW-1:0] centroid [0:CLUSTERS*PARAMS-1];

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------

    kmeans_cluster #(
        .DW       (DW      ),
        .CLUSTERS (CLUSTERS),
        .PARAMS   (PARAMS  )
    ) dut(.*);

//------------------------------------------------------------------------------
// Stimulus
//------------------------------------------------------------------------------

    always #5 clk_i =~clk_i;

    // Reading Data and Centroids from Files
    initial
        begin
        fd_data     = $fopen("../../../../../src/data.txt","r"); // Provide proper path
        fd_centroid = $fopen("../../../../../src/centroid.txt","r"); // Provide proper path
        #10
        if(fd_data != 0 && fd_centroid != 0)
            begin
            $display("Files found %d %d",fd_data,fd_centroid);
            end
        else
            begin
            $display("File not-found %d %d",fd_data,fd_centroid);
            end
        // Reading Data
        for(int itr = 0; itr < 2*PARAMS; itr++)
            begin
            $fscanf(fd_data, "%d\n", data[itr]);
            end
        // Reading Centroids
        for(int itr = 0; itr < (CLUSTERS*PARAMS); itr++)
            begin
            $fscanf(fd_centroid, "%d\n", centroid[itr]);
            end
        end

    initial
        begin
        // Init
        clk_i            <= 'h0;
        resetn_i         <= 'h0;
        enable_i         <= 'h0;
        centroid_i       <= 'h0;
        centroid_valid_i <= 'h0;
        data_i           <= 'h0;
        data_valid_i     <= 'h0;
        // Reset Deassert
        #10
        resetn_i <= 'h1;
        // Load Centroids and Data
        #10
        centroid_valid_i <= 'h1;
        data_valid_i     <= 'h1;
        for(int itr = 0; itr < PARAMS; itr++)
            begin
            data_i[itr*DW +: DW] <= data[itr];
            end
        for(int itr = 0; itr < PARAMS*CLUSTERS; itr++)
            begin
            centroid_i[itr*DW +: DW] <= centroid[itr];
            end
        // Trigger Calculation
        #10
        enable_i         <= 'h1;
        centroid_valid_i <= 'h0;
        data_valid_i     <= 'h0;
        #15
        enable_i         <= 'h0;
        // Output
        @(posedge valid_o);
            begin
            $display("Cluster %X",cluster_o);
            $display("Minimum Distance %X",min_dist_o);
            end
        #50
        data_valid_i     <= 'h1;
        for(int itr = 0; itr < PARAMS; itr++)
            begin
            data_i[itr*DW +: DW] <= data[itr+PARAMS];
            end
        #10
        enable_i <= 'h1;
        #10
        enable_i <= 'h0;
        end

endmodule