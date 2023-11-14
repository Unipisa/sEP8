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
            24'HFF0001: valore = opcode_mov_operando_AH;
            24'HFF0002: valore = 8'H41; // A
            24'HFF0003: valore = opcode_inAL;
            24'HFF0004: valore = 8'H00;
            24'HFF0005: valore = 8'H00;
            24'HFF0006: valore = opcode_and_operando_AL;
            24'HFF0007: valore = 8'H20;
            24'HFF0008: valore = opcode_jz;
            24'HFF0009: valore = 8'H03;
            24'HFF000A: valore = 8'H00;
            24'HFF000B: valore = 8'HFF;
            24'HFF000C: valore = opcode_AHtoAL;
            24'HFF000D: valore = opcode_outAL; // 
            24'HFF000E: valore = 8'H01;
            24'HFF000F: valore = 8'H00;
            24'HFF0010: valore = opcode_add_operando_AH;
            24'HFF0011: valore = 8'H01;
            24'HFF0012: valore = opcode_cmp_operando_AH;
            24'HFF0013: valore = 8'H5A; // Z
            24'HFF0014: valore = opcode_jbe;
            24'HFF0015: valore = 8'H03;
            24'HFF0016: valore = 8'H00;
            24'HFF0017: valore = 8'HFF;
            24'HFF0018: valore = opcode_hlt; // HLT
        endcase
        
    endfunction

    assign #ritardo_lettura d7_d0 = {s_,mr_}==2'b00 ? valore(a23_a0) : 8'HZZ;
    
endmodule