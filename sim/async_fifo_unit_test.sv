`include "svut_h.sv"
`timescale 1 ns / 1 ps

module async_fifo_unit_test;

    `SVUT_SETUP

    `ifndef AEMPTY
    `define AEMPTY 1
    `endif

    `ifndef AFULL
    `define AFULL 1
    `endif

    `ifndef FALLTHROUGH
    `define FALLTHROUGH "TRUE"
    `endif

    parameter DSIZE = 32;
    parameter ASIZE = 4;
    parameter AREMPTYSIZE = 16;
    parameter AWFULLSIZE = 16;
    parameter FALLTHROUGH = `FALLTHROUGH;
    parameter MAX_TRAFFIC = 10;

    integer timeout;

    reg              wclk;
    reg              wrst_n;
    reg              winc;
    reg  [DSIZE-1:0] wdata;
    wire             wfull_fifo1;
    wire             awfull_fifo1;
    wire             wfull_fifo2;
    wire             awfull_fifo2;
    reg              rclk;
    reg              rrst_n;
    reg              rinc;
    wire [DSIZE-1:0] rdata;
    wire             rempty_fifo1;
    wire             arempty_fifo1;
    wire             rempty_fifo2;
    wire             arempty_fifo2;
    async_fifo_combine
    #(
        .DSIZE        (DSIZE),
        .ASIZE_FIFO1        (ASIZE),
        .ASIZE_FIFO2        (ASIZE),
        .AWFULLSIZE_FIFO1   (AWFULLSIZE),
        .AWFULLSIZE_FIFO2   (AWFULLSIZE),
        .AREMPTYSIZE_FIFO1  (AREMPTYSIZE),
        .AREMPTYSIZE_FIFO2  (AREMPTYSIZE),
        .FALLTHROUGH  (FALLTHROUGH)
    )
    dut
    (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull_fifo1(wfull_fifo1),
        .awfull_fifo1(awfull_fifo1),
        .wfull_fifo2(wfull_fifo2),
        .awfull_fifo2(awfull_fifo2),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .rempty_fifo1(rempty_fifo1),
        .arempty_fifo1(arempty_fifo1),
        .rempty_fifo2(rempty_fifo2),
        .arempty_fifo2(arempty_fifo2)
    );

    // An example to create a clock
    initial wclk = 1'b0;
    always #2 wclk <= ~wclk;
    initial rclk = 1'b0;
    always #3 rclk <= ~rclk;

    // An example to dump data for visualization
    initial begin
        $dumpfile("async_fifo_unit_test.vcd");
        $dumpvars(0, async_fifo_unit_test);
    end

    task setup(msg="Setup testcase");
    begin

        wrst_n = 1'b0;
        winc = 1'b0;
        wdata = 0;
        rrst_n = 1'b0;
        rinc = 1'b0;
        #100;
        wrst_n = 1;
        rrst_n = 1;
        #50;
        timeout = 0;
        @(posedge wclk);

    end
    endtask

    task teardown(msg="Tearing down");
    begin
        #50;
    end
    endtask

    `TEST_SUITE("ASYNCFIFO")

    `UNIT_TEST("TEST_IDLE")

        `FAIL_IF(wfull_fifo1);
        `FAIL_IF(wfull_fifo2);
        `FAIL_IF(!rempty_fifo2);
        `FAIL_IF(!rempty_fifo1);
    `UNIT_TEST_END

    // `UNIT_TEST("TEST_SINGLE_WRITE_THEN_READ")

    //     @(posedge wclk)

    //     winc = 1;
    //     wdata = 32'hA;

    //     @(posedge wclk)

    //     winc = 0;

    //     @(posedge rclk)

    //     wait (rempty == 1'b0);

    //     rinc = 1;
    //     @(negedge rclk)

    //     `FAIL_IF_NOT_EQUAL(rdata, 32'hA);

    // `UNIT_TEST_END

    `UNIT_TEST("TEST_MULTIPLE_WRITE_THEN_READ")
        `FAIL_IF(wfull_fifo1);
        `FAIL_IF(!rempty_fifo1);
        for (int i=0; i < 2**(ASIZE); i=i+1) begin
            @(negedge wclk);
            winc = 1;
            wdata = i;


        end
        @(negedge wclk);
        winc = 0;

        #100
        // fifo 2 should be full
        `FAIL_IF(rempty_fifo2 == 1);
        `FAIL_IF(arempty_fifo2 == 0);


        `FAIL_IF(wfull_fifo1 == 1);// fifo1 should be able to write now
        `FAIL_IF(awfull_fifo1 == 0);   
        `FAIL_IF(rempty_fifo1==0);
        @(posedge rclk);

        rinc = 1;
        for (int i=0;  i < 2**(ASIZE); i=i+1) begin
            @(posedge rclk);
            `FAIL_IF_NOT_EQUAL(rdata, i);
        end
        `FAIL_IF(rempty_fifo1 == 0);
        `FAIL_IF(wfull_fifo1 == 1);
    `UNIT_TEST_END

    `UNIT_TEST("TEST_WRITE_TILL_FULL_THEN_READ")
        `FAIL_IF(wfull_fifo1);
        `FAIL_IF(!rempty_fifo1);
        for (int i=0; i < 2**(ASIZE); i=i+1) begin
            @(negedge wclk);
            winc = 1;
            wdata = i;
        end
        @(negedge wclk);
        winc = 0;

        #100

        // fifo1 should still be empty for write
        `FAIL_IF(rempty_fifo1 == 0);
        `FAIL_IF(wfull_fifo1 == 1);

        // // fifo 2 should indicate full with data to read
        `FAIL_IF(rempty_fifo2==1);
        `FAIL_IF(wfull_fifo2 == 0);


        // do another round of write
        for (int i=0; i < 2**(ASIZE); i=i+1) begin
            @(negedge wclk);
            winc = 1;
            wdata = i+1;
        end
        @(negedge wclk);
        winc = 0;
        // by now, fifo1 should be full, fifo 2 should still keep it full with data

        `FAIL_IF(wfull_fifo1==0);
        `FAIL_IF(rempty_fifo1==1);

        `FAIL_IF(rempty_fifo2==1);
        `FAIL_IF(wfull_fifo2==0);
        
        @(posedge rclk);

        rinc = 1;
        for (int i=0;  i < 2**(ASIZE); i=i+1) begin
            @(posedge rclk);
            `FAIL_IF_NOT_EQUAL(rdata, i);
        end
        @(negedge rclk);
        rinc = 0;


        #100
        // fifo1 should be free to write, but still have data in fifo2
        `FAIL_IF(wfull_fifo1==1);
        `FAIL_IF(rempty_fifo1==0);
        `FAIL_IF(wfull_fifo2==0);
        `FAIL_IF(rempty_fifo2==1);


        @(posedge rclk);

        rinc = 1;
        for (int i=0;  i < 2**(ASIZE); i=i+1) begin
            @(posedge rclk);
            `FAIL_IF_NOT_EQUAL(rdata, i+1);
        end
        @(negedge rclk);
        rinc = 0;
        
        #100
        // fifo2 should be empty, so do fifo1
        `FAIL_IF(wfull_fifo1==1);
        `FAIL_IF(rempty_fifo1==0);
        `FAIL_IF(wfull_fifo2 == 1);
        `FAIL_IF(rempty_fifo2 == 0);

        
    `UNIT_TEST_END
    // `UNIT_TEST("TEST_FULL_FLAG")

    //     winc = 1;

    //     for (int i=0; i<2**ASIZE; i=i+1) begin
    //         @(negedge wclk)
    //         wdata = i;
    //     end

    //     @(negedge wclk);
    //     winc = 0;

    //     @(posedge wclk)
    //     `FAIL_IF_NOT_EQUAL(wfull, 1);

    // `UNIT_TEST_END

    // `UNIT_TEST("TEST_EMPTY_FLAG")

    //     `FAIL_IF_NOT_EQUAL(rempty, 1);

    //     for (int i=0; i<2**ASIZE; i=i+1) begin
    //         @(posedge wclk)
    //         winc = 1;
    //         wdata = i;
    //     end

    //     `FAIL_IF_NOT_EQUAL(rempty, 0);

    // `UNIT_TEST_END

    // `UNIT_TEST("TEST_ALMOST_EMPTY_FLAG")

    //     `FAIL_IF_NOT_EQUAL(arempty, 0);

    //     winc = 1;
    //     for (int i=0; i<AREMPTYSIZE; i=i+1) begin

    //         @(negedge wclk)
    //         wdata = i;

    //     end

    //     @(negedge wclk);
    //     winc = 0;

    //     #100;
    //     `FAIL_IF_NOT_EQUAL(arempty, 1);

    // `UNIT_TEST_END

    // `UNIT_TEST("TEST_ALMOST_FULL_FLAG")

    //     winc = 1;
    //     for (int i=0; i<2**ASIZE-AWFULLSIZE; i=i+1) begin

    //         @(negedge wclk)
    //         wdata = i;

    //     end

    //     @(negedge wclk);
    //     winc = 0;

    //     @(posedge wclk)
    //     `FAIL_IF_NOT_EQUAL(awfull, 1);

    // `UNIT_TEST_END

    // `UNIT_TEST("TEST_CONCURRENT_WRITE_READ")

    //     fork
    //     // Concurrent accesses
    //     begin
    //         fork
    //         // Write source
    //         begin
    //             winc = 1;
    //             for (int i=0; i<MAX_TRAFFIC; i=i+1) begin
    //                 while (wfull)
    //                     @(negedge wclk);
    //                 @(negedge wclk);
    //                 wdata = i;
    //             end
    //             winc = 0;
    //         end
    //         // Read sink
    //         begin
    //             for (int i=0; i<MAX_TRAFFIC; i=i+1) begin
    //                 while (rempty)
    //                     @(posedge rclk);
    //                 rinc = 1;
    //                 @(negedge rclk);
    //                 `FAIL_IF_NOT_EQUAL(rdata, i);
    //             end
    //             rinc = 0;
    //         end
    //         join
    //     end
    //     // Timeout management
    //     begin
    //         while (timeout<10000) begin
    //             timeout = timeout + 1;
    //             @(posedge rclk);
    //         end
    //         `ERROR("Reached timeout!");
    //     end
    //     join_any

    // `UNIT_TEST_END

    `TEST_SUITE_END

endmodule

