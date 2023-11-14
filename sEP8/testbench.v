module testbench();

    // bus
    wire clock;
    wire[7:0] d7_d0;
    wire[23:0] a23_a0;
    wire [15:0] a15_a0;
    wire mr_,mw_,ior_,iow_;
    wire tb_halt;
    wire tb_nvi;
    reg reset_;

    assign a15_a0 = a23_a0[15:0];

    // moduli
    clock_generator clk(
        .clock(clock)
    );

    MEMORIA memoria(
        .a23_a0(a23_a0),
        .mr_(mr_),
        .mw_(mw_),
        .d7_d0(d7_d0)
    );

    Processore sEP8(
        .d7_d0(d7_d0),
        .a23_a0(a23_a0),
        .mr_(mr_),
        .mw_(mw_),
        .ior_(ior_),
        .iow_(iow_),
        .clock(clock),
        .reset_(reset_),
        .tb_halt(tb_halt),
        .tb_nvi(tb_nvi)
    );

    IO spazio_IO (
        .clock(clock),
        .reset_(reset_),
        .ior_(ior_),
        .iow_(iow_),
        .a15_a0(a15_a0),
        .d7_d0(d7_d0)
    );

    initial 
        begin
            $dumpfile("waveform.vcd");
            $dumpvars;

            reset_ = 0; 
            #(clk.HALF_PERIOD)
            reset_ = 1;
            fork 
                begin
                    @(posedge tb_halt) begin
                        $display("\nSimulazione terminata: il processore ha eseguito un'istruzione HLT"); 
                        $finish;
                    end
                end
                begin
                    @(posedge tb_nvi) begin
                        $display("\nSimulazione terminata: il processore ha prelevato un'istruzione non valida"); 
                        $finish;
                    end                 
                end               
            join
        end 
    
endmodule