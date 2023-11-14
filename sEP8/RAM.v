module RAM (
    a23_a0,
    s_, mw_, mr_,
    d7_d0
);
    parameter dimensione_ram = (1<<24), // 16777216 
              ritardo_lettura = 2,
              ritardo_scrittura = 2;
    
    input[23:0] a23_a0;
    input s_,mw_,mr_;
    inout[7:0] d7_d0;

    reg [7:0] CELLE[0:dimensione_ram-1];

    assign #ritardo_lettura d7_d0 = {s_,mr_,mw_}==3'B001 ? CELLE[a23_a0] : 8'HZZ;

    always @(d7_d0 , s_, mr_, mw_ ) #ritardo_scrittura
        CELLE[a23_a0]<= {s_,mr_,mw_}==3'B010 ? d7_d0 : CELLE[a23_a0];
    
endmodule