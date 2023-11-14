//`include "parametri_opcode.v" o così o lo includo direttamente nel comando iverilog 
//--> se lo includo qua si vede anche nel sEP8.v

module ROM (
    a23_a0,
    s_,
    mr_,
    d7_d0
);
    parameter ritardo_lettura = 2;
    input [23:0] a23_a0; 
    input s_,mr_;
    output [7:0] d7_d0;
    
    `include "parametri_opcode.v"
    
    function [7:0] valore;
        input [23:0] a23_a0;
        casex (a23_a0)
            24'HFF0000: valore = opcode_nop; // NOP 
            24'HFF0001: valore = opcode_mov_operando_AL; //
            24'HFF0002: valore = 8'H41; // A
            24'HFF0003: valore = opcode_outAL; // 
            24'HFF0004: valore = 8'H00;
            24'HFF0005: valore = 8'H00;
            24'HFF0006: valore = opcode_add_operando_AL;
            24'HFF0007: valore = 8'H01;
            24'HFF0008: valore = opcode_cmp_operando_AL;
            24'HFF0009: valore = 8'H5A; // Z
            24'HFF000A: valore = opcode_jbe;
            24'HFF000B: valore = 8'H03;
            24'HFF000C: valore = 8'H00;
            24'HFF000D: valore = 8'HFF;
            24'HFF000E: valore = opcode_hlt; // HLT
        endcase
        
    endfunction

    assign #ritardo_lettura d7_d0 = {s_,mr_}==2'b00 ? valore(a23_a0) : 8'HZZ;
    
endmodule