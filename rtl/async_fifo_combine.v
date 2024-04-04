`timescale 1 ns / 1 ps
`default_nettype none


module async_fifo_combine #(parameter DSIZE = 8,
                            parameter ASIZE_FIFO1 = 4,
                            parameter ASIZE_FIFO2 = 4,
                            parameter AWFULLSIZE_FIFO1 = 1,
                            parameter AREMPTYSIZE_FIFO1 = 1,
                            parameter AWFULLSIZE_FIFO2 = 1,
                            parameter AREMPTYSIZE_FIFO2 = 1,
                            parameter FALLTHROUGH = "TRUE")
                           (input wire wclk,
                            input wire wrst_n,
                            input wire winc,
                            input wire [DSIZE-1:0] wdata,
                            output wire wfull_fifo1,
                            output wire awfull_fifo1,
                            output wire wfull_fifo2,
                            output wire awfull_fifo2,
                            input wire rclk,
                            input wire rrst_n,
                            input wire rinc,
                            output wire [DSIZE-1:0] rdata,
                            output wire rempty_fifo1,
                            output wire arempty_fifo1,
                            output wire rempty_fifo2,
                            output wire arempty_fifo2                        
                            );
    
    
    
    // fifo1
    
    reg [DSIZE-1:0] rdata_fifo1;
    reg rinc_fifo1;


    wire wclk_fifo1, wrst_n_fifo1;
    wire rclk_fifo1, rrst_n_fifo1;
    
    assign wrst_n_fifo1 = wrst_n;
    assign rrst_n_fifo1 = wrst_n;
    assign wclk_fifo1   = wclk;
    assign rclk_fifo1   = wclk;
    

    // Instantiate the FIFO
    async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE_FIFO1), .AWFULLSIZE(AWFULLSIZE_FIFO1), .AREMPTYSIZE(AREMPTYSIZE_FIFO1), .FALLTHROUGH(FALLTHROUGH)) dut (
    .winc(winc),
    .wclk(wclk_fifo1),
    .wrst_n(wrst_n_fifo1),
    .rinc(rinc_fifo1),
    .rclk(rclk_fifo1),
    .rrst_n(rrst_n_fifo1),
    .wdata(wdata),
    .rdata(rdata_fifo1),
    .wfull(wfull_fifo1),
    .rempty(rempty_fifo1),
    .arempty(arempty_fifo1),
    .awfull(awfull_fifo1)
    );
    
    
    //fifo 2

    reg [DSIZE-1:0] wdata_fifo2;
    reg winc_fifo2;


    wire rclk_fifo2, rrst_n_fifo2;
    wire wrst_n_fifo2, wclk_fifo2;
    assign wrst_n_fifo2 = wrst_n;
    assign rrst_n_fifo2 = rrst_n;
    assign wclk_fifo2   = wclk;
    assign rclk_fifo2   = rclk;
    
    // Instantiate the FIFO
    async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE_FIFO2), .AWFULLSIZE(AWFULLSIZE_FIFO2), .AREMPTYSIZE(AREMPTYSIZE_FIFO2),.FALLTHROUGH(FALLTHROUGH)) dut2 (
    .winc(winc_fifo2),
    .wclk(wclk_fifo2),
    .wrst_n(wrst_n_fifo2),
    .rinc(rinc),
    .rclk(rclk_fifo2),
    .rrst_n(rrst_n_fifo2),
    .wdata(wdata_fifo2),
    .rdata(rdata),
    .wfull(wfull_fifo2),
    .rempty(rempty_fifo2),
    .arempty(arempty_fifo2),
    .awfull(awfull_fifo2)
    );



    assign wdata_fifo2 = rdata_fifo1;
    assign winc_fifo2 = !(rempty_fifo1);
    assign rinc_fifo1 = !(wfull_fifo2);



    //now, the synchronization of the 2 fifo



endmodule
    `resetall
