module MEMORIA (
    a23_a0,
    mr_,mw_,
    d7_d0
);
    input[23:0] a23_a0;
    input mr_,mw_;
    inout[7:0] d7_d0;
    
    function[1:0] seleziona;
        input [7:0] a23_a16;
        casex(a23_a16)
            8'B11111111: seleziona = 2'B10;
            default:     seleziona = 2'B01;
        endcase
        
    endfunction

    wire selettoreRAM_,selettoreROM_;
    assign {selettoreRAM_,selettoreROM_} = seleziona(a23_a0[23:16]);
    
    ROM rom(
        .a23_a0(a23_a0),
        .s_(selettoreROM_),
        .mr_(mr_),
        .d7_d0(d7_d0)
    );

    RAM ram(
        .a23_a0(a23_a0),
        .s_(selettoreRAM_),
        .mr_(mr_),
        .mw_(mw_),
        .d7_d0(d7_d0)
    );

endmodule