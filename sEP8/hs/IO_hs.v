module IO (
    clock, 
    reset_,
    ior_,
    iow_,
    d7_d0,
    a15_a0
);
    input clock, reset_;
    input ior_, iow_;
    inout [7:0] d7_d0;
    input [15:0] a15_a0;
    
    reg fo;
    wire [7:0] carattere;
    //wire s_;
    //assign s_ = a15_a0 == 16'H0000 ? 1'B0 : 1'B1;

    wire out_s_;
    assign out_s_ = a15_a0[15:1] == 15'B000000000000000 ? 1'B0 : 1'B1;

    interfaccia_stampa_carattere stampa_carattere(
        .ior_(ior_),
        .iow_(iow_),
        .s_(out_s_),
        .a0(a15_a0[0]),
        .d7_d0(d7_d0),
        .fo(fo),
        .carattere(carattere)
    );  

    initial 
        begin
            fo = 0;
            while(1) begin
                #200 // simulo il comportamento del dispositivo
                fo = 1;
                @(carattere) // devo aspettare che venga fatta una scrittura
                fo = 0;
            end
        end

endmodule

module interfaccia_stampa_carattere (
    iow_, ior_,
    s_, a0, d7_d0,
    fo, 
    carattere
);
    input iow_, ior_;
    input s_;
    input a0;
    input fo; 
    inout [7:0] d7_d0;
    output [7:0] carattere;

    reg DIR;
    reg [7:0] D7_D0;
    assign d7_d0 = DIR == 1 ? D7_D0 : 8'HZZ;
    reg [7:0] CARATTERE;
    assign carattere = CARATTERE;

    wire eb;
    assign eb = {s_, iow_, a0} == 3'B001 ? 1'B1 : 1'B0;
    wire es;
    assign es = {s_, ior_, a0} == 3'B000 ? 1'B1 : 1'B0;

    always @(*) begin
        if( s_==1 || ior_ ==1 )
            DIR <= 0;
    end
    always @(*) 
        if ( es==1'B1 ) // operazione di lettura all'indirizzo corretto
                begin
                    D7_D0 <= {2'B0, fo, 5'B0};
                    DIR <= 1;
                end 
    always @(*)
        if( eb==1'b1 && fo==1 ) // operazione di scrittura all'indirizzo corretto, con buffer vuoto
                begin
                    $write("%c",d7_d0);
                    CARATTERE <= d7_d0;
                end
endmodule
