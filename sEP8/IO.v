module IO(
    clock, reset_,
    ior_, iow_,
    d7_d0,
    a15_a0
);
    input clock, reset_;
    input ior_, iow_;
    input [7:0] d7_d0;
    input [15:0] a15_a0;

    wire out_s_;
    assign out_s_ = a15_a0 == 16'H0000 ? 1'B0 : 1'B1;

    interfaccia_stampa_carattere stampa_carattere(
        .s_(out_s_),
        .iow_(iow_),
        .d7_d0(d7_d0)
    );  

endmodule

module interfaccia_stampa_carattere (
    s_,
    iow_,
    d7_d0
);
    input s_,iow_;
    input [7:0] d7_d0;
    
    wire e ;
    assign e = {s_, iow_} == 2'B00 ? 1'B1 : 1'B0;

    always @(posedge e) 
        //$display("Il carattere e': %c",d7_d0);
        $write("%c",d7_d0);
    /*
    always @(s_,iow_) begin
       if({s_,iow_}==2'B00)
        $display("Il carattere e': %c",d7_d0);
       
    end
    */
endmodule
