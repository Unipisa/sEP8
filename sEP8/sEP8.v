//-----------------------------------------------------------------
// DESCRIZIONE COMPLETA DEL PROCESSORE
//-----------------------------------------------------------------

module Processore(
    d7_d0,
    a23_a0,
    mr_, mw_,
    ior_, iow_,
    clock, reset_,
    tb_halt, tb_stage, tb_nvi
);

    input clock, reset_;
    inout[7:0] d7_d0;
    output[23:0] a23_a0;
    output mr_, mw_;
    output ior_, iow_;
    // filo di uscita con il solo scopo di segnalare alla testbench quando terminare
    output tb_halt;
    // filo di uscita con il solo scopo di segnalare alla testbench in che fase il processore si trova
    output tb_stage;
    // filo di uscita con il solo scopo di segnalare alla testbench quando si verifica un'istruzione non valida
    output tb_nvi;

    // REGISTRI OPERATIVI DI SUPPORTO ALLE VARIABILI DI USCITA E ALLE
    // VARIABILI BIDIREZIONALI E CONNESSIONE DELLE VARIABILI AI REGISTRI
    reg DIR;
    reg[7:0] D7_D0;
    reg[23:0] A23_A0;
    reg MR_, MW_, IOR_, IOW_;
    // DATI UTILI NELLA TESTBENCH
    reg TB_HALT;
    reg TB_STAGE;
    reg TB_NVI;


    assign mr_ = MR_;
    assign mw_ = MW_;
    assign ior_ = IOR_;
    assign iow_ = IOW_;
    assign a23_a0 = A23_A0;
    assign d7_d0 = (DIR==1) ? D7_D0 : 'HZZ; //FORCHETTA

    assign tb_halt = TB_HALT;
    assign tb_stage = TB_STAGE;
    assign tb_nvi = TB_NVI;

    // REGISTRI OPERATIVI INTERNI
    reg[2:0] NUMLOC;
    reg[7:0] AL, AH, F, OPCODE, SOURCE, APP3, APP2, APP1, APP0;
    reg[23:0] DP, IP, SP, DEST_ADDR;

    // REGISTRO DI STATO, REGISTRO MJR E CODIFICA DEGLI STATI INTERNI
    reg[6:0] STAR, MJR; 
    parameter fetch0 = 0, 
              fetch1 = 1,
              fetch2 = 2,
              fetch3 = 3,
              fetchF2_0 = 4,
              fetchF2_1 = 5,
              fetchF3_0 = 6,
              fetchF4_0 = 7,
              fetchF4_1 = 8,
              fetchF5_0 = 9,
              fetchF5_1 = 10,
              fetchF5_2 = 11,
              fetchF6_0 = 12,
              fetchF6_1 = 13,
              fetchF7_0 = 14,
              fetchF7_1 = 15,
              nvi = 16,
              fetchEnd = 17,
              fetchEnd1 = 18,
              nop = 19,
              hlt = 20,
              ALtoAH = 21,
              AHtoAL = 22,
              incDP = 23,
              ldAL = 24,
              ldAH = 25,
              storeAL = 26,
              storeAH = 27,
              ldSP = 28,
              ldSP1 = 29,
              ldimmDP = 30,
              ldimmDP1 = 31,
              lddirDP = 32,
              lddirDP1 = 33,
              lddirDP2 = 34,
              storeDP = 35,
              storeDP1 = 36,
              in = 37,
              in1 = 38,
              in2 = 39,
              in3 = 40,
              out = 41,
              out1 = 42,
              out2 = 43,
              out3 = 44,
              out4 = 45,
              aluAL = 46,
              aluAH = 47,
              jmp = 48,
              pushAL = 49,
              pushAH = 50,
              pushDP = 51,
              popAL = 52,
              popAL1 = 53,
              popAH = 54,
              popAH1 = 55,
              popDP = 56,
              popDP1 = 57,
              call = 58,
              call1 = 59,
              ret = 60,
              ret1 = 61,
              readB = 62,
              readW = 63,
              readM = 64,
              readL = 65,
              read0 = 66,
              read1 = 67,
              read2 = 68,
              read3 = 69,
              read4 = 70,
              writeB = 71,
              writeW = 72,
              writeM = 73,
              writeL = 74,
              write0 = 75,
              write1 = 76,
              write2 = 77,
              write3 = 78,
              write4 = 79,
              write5 = 80,
              write6 = 81,
              write7 = 82,
              write8 = 83,
              write9 = 84,
              write10 = 85,
              write11 = 86;

    // RETI COMBINATORIE NON STANDARD
          // label per gli opcode delle istruzioni
    `include "parametri_opcode.v"

    // prende in ingresso un byte e restituisce 1 se quel byte è l'opcode di un'istruzione nota, 0 altrimenti
    function valid_fetch; // pagina 185 del libro
        input[7:0] opcode;
        casex (opcode)
            // FORMATO F0
            opcode_hlt:    valid_fetch = 1'b1; // HLT
            opcode_nop:    valid_fetch = 1'b1; // NOP
            opcode_ALtoAH: valid_fetch = 1'b1; // MOV AL,AH
            opcode_AHtoAL: valid_fetch = 1'b1; // MOV AH,AL
            opcode_incDP:  valid_fetch = 1'b1; // INC DP
            opcode_shlAL:  valid_fetch = 1'b1; // SHL AL
            opcode_shrAL:  valid_fetch = 1'b1; // SHR AL
            opcode_notAL:  valid_fetch = 1'b1; // NOT AL 
            opcode_shlAH:  valid_fetch = 1'b1; // SHL AH
            opcode_shrAH:  valid_fetch = 1'b1; // SHR AH
            opcode_notAH:  valid_fetch = 1'b1; // NOT AH
            opcode_pushAL: valid_fetch = 1'b1; // PUSH AL
            opcode_popAL:  valid_fetch = 1'b1; // POP AL
            opcode_pushAH: valid_fetch = 1'b1; // PUSH AH
            opcode_popAH:  valid_fetch = 1'b1; // POP AH
            opcode_pushDP: valid_fetch = 1'b1; // PUSH DP
            opcode_popDP:  valid_fetch = 1'b1; // POP DP
            opcode_ret:    valid_fetch = 1'b1; // RET 
            // FORMATO F1
            opcode_inAL:             valid_fetch = 1'b1; // IN offset,AL
            opcode_outAL:            valid_fetch = 1'b1; // OUT AL,offset
            opcode_mov_operando_DP:  valid_fetch = 1'b1; // MOV $operando,DP
            opcode_mov_operando_SP:  valid_fetch = 1'b1; // MOV $operando,SP
            opcode_mov_indirizzo_DP: valid_fetch = 1'b1; // MOV indirizzo,DP
            opcode_mov_DP_indirizzo: valid_fetch = 1'b1; // MOV DP,indirizzo
            // FORMATO F2
            opcode_mov_DP_AL: valid_fetch = 1'b1; // MOV (DP),AL
            opcode_cmp_DP_AL: valid_fetch = 1'b1; // CMP (DP),AL
            opcode_add_DP_AL: valid_fetch = 1'b1; // ADD (DP),AL
            opcode_sub_DP_AL: valid_fetch = 1'b1; // SUB (DP),AL
            opcode_and_DP_AL: valid_fetch = 1'b1; // AND (DP),AL
            opcode_or_DP_AL:  valid_fetch = 1'b1; // OR  (DP),AL
            opcode_mov_DP_AH: valid_fetch = 1'b1; // MOV (DP),AH
            opcode_cmp_DP_AH: valid_fetch = 1'b1; // CMP (DP),AH
            opcode_add_DP_AH: valid_fetch = 1'b1; // ADD (DP),AH
            opcode_sub_DP_AH: valid_fetch = 1'b1; // SUB (DP),AH
            opcode_and_DP_AH: valid_fetch = 1'b1; // AND (DP),AH
            opcode_or_DP_AH:  valid_fetch = 1'b1; // OR  (DP),AH
            // FORMATO F3
            opcode_mov_AL_DP: valid_fetch = 1'b1; // MOV AL,(DP)
            opcode_mov_AH_DP: valid_fetch = 1'b1; // MOV AH,(DP)
            // FORMATO F4
            opcode_mov_operando_AL: valid_fetch = 1'b1; // MOV $operando,AL
            opcode_cmp_operando_AL: valid_fetch = 1'b1; // CMP $operando,AL
            opcode_add_operando_AL: valid_fetch = 1'b1; // ADD $operando,AL 
            opcode_sub_operando_AL: valid_fetch = 1'b1; // SUB $operando,AL 
            opcode_and_operando_AL: valid_fetch = 1'b1; // AND $operando,AL 
            opcode_or_operando_AL : valid_fetch = 1'b1; // OR  $operando,AL 
            opcode_mov_operando_AH: valid_fetch = 1'b1; // MOV $operando,AH
            opcode_cmp_operando_AH: valid_fetch = 1'b1; // CMP $operando,AH
            opcode_add_operando_AH: valid_fetch = 1'b1; // ADD $operando,AH 
            opcode_sub_operando_AH: valid_fetch = 1'b1; // SUB $operando,AH 
            opcode_and_operando_AH: valid_fetch = 1'b1; // AND $operando,AH 
            opcode_or_operando_AH : valid_fetch = 1'b1; // OR  $operando,AH 
            // FORMATO F5
            opcode_mov_indirizzo_AL: valid_fetch = 1'b1; // MOV indirizzo,AL
            opcode_cmp_indirizzo_AL: valid_fetch = 1'b1; // CMP indirizzo,AL
            opcode_add_indirizzo_AL: valid_fetch = 1'b1; // ADD indirizzo,AL 
            opcode_sub_indirizzo_AL: valid_fetch = 1'b1; // SUB indirizzo,AL 
            opcode_and_indirizzo_AL: valid_fetch = 1'b1; // AND indirizzo,AL 
            opcode_or_indirizzo_AL : valid_fetch = 1'b1; // OR  indirizzo,AL 
            opcode_mov_indirizzo_AH: valid_fetch = 1'b1; // MOV indirizzo,AH
            opcode_cmp_indirizzo_AH: valid_fetch = 1'b1; // CMP indirizzo,AH
            opcode_add_indirizzo_AH: valid_fetch = 1'b1; // ADD indirizzo,AH 
            opcode_sub_indirizzo_AH: valid_fetch = 1'b1; // SUB indirizzo,AH 
            opcode_and_indirizzo_AH: valid_fetch = 1'b1; // AND indirizzo,AH 
            opcode_or_indirizzo_AH : valid_fetch = 1'b1; // OR  indirizzo,AH 
            // FORMATO F6
            opcode_mov_AL_indirizzo: valid_fetch = 1'b1; // MOV AL,indirizzo
            opcode_mov_AH_indirizzo: valid_fetch = 1'b1; // MOV AH,indirizzo
            // FORMATO F7
            opcode_jmp  : valid_fetch = 1'b1; // JMP indirizzo 
            opcode_je   : valid_fetch = 1'b1; // JE indirizzo
            opcode_jne  : valid_fetch = 1'b1; // JNE indirizzo
            opcode_ja   : valid_fetch = 1'b1; // JA indirizzo
            opcode_jae  : valid_fetch = 1'b1; // JAE indirizzo
            opcode_jb   : valid_fetch = 1'b1; // JB indirizzo
            opcode_jbe  : valid_fetch = 1'b1; // JBE indirizzo
            opcode_jg   : valid_fetch = 1'b1; // JG indirizzo
            opcode_jge  : valid_fetch = 1'b1; // JGE indirizzo
            opcode_jl   : valid_fetch = 1'b1; // JL indirizzo
            opcode_jle  : valid_fetch = 1'b1; // JLE indirizzo
            opcode_jz   : valid_fetch = 1'b1; // JZ indirizzo
            opcode_jnz  : valid_fetch = 1'b1; // JNZ indirizzo
            opcode_jc   : valid_fetch = 1'b1; // JC indirizzo
            opcode_jnc  : valid_fetch = 1'b1; // JNC indirizzo
            opcode_jo   : valid_fetch = 1'b1; // JO indirizzo
            opcode_jno  : valid_fetch = 1'b1; // JNO indirizzo
            opcode_js   : valid_fetch = 1'b1; // JS indirizzo
            opcode_jns  : valid_fetch = 1'b1; // JNS indirizzo
            opcode_call : valid_fetch = 1'b1; // CALL indirizzo
            // ISTRUZIONE NON NOTA
            default: valid_fetch = 1'b0;
        endcase
    endfunction
    

    // Prende in ingresso un byte, che interpreta come un opcode valido, e restituisce la codifica del primo stato interno
    // dell'esecuzione dell'istruzione relativa
    function[6:0] first_execution_state;
        input[7:0] opcode;
        casex (opcode)
            // FORMATO F0
            opcode_hlt    : first_execution_state = hlt; // HLT
            opcode_nop    : first_execution_state = nop; // NOP
            opcode_ALtoAH : first_execution_state = ALtoAH; // MOV AL,AH
            opcode_AHtoAL : first_execution_state = AHtoAL; // MOV AH,AL
            opcode_incDP  : first_execution_state = incDP; // INC DP
            opcode_shlAL  : first_execution_state = aluAL; // SHL AL
            opcode_shrAL  : first_execution_state = aluAL; // SHR AL
            opcode_notAL  : first_execution_state = aluAL; // NOT AL 
            opcode_shlAH  : first_execution_state = aluAH; // SHL AH
            opcode_shrAH  : first_execution_state = aluAH; // SHR AH
            opcode_notAH  : first_execution_state = aluAH; // NOT AH
            opcode_pushAL : first_execution_state = pushAL; // PUSH AL
            opcode_popAL  : first_execution_state = popAL; // POP AL
            opcode_pushAH : first_execution_state = pushAH; // PUSH AH
            opcode_popAH  : first_execution_state = popAH; // POP AH
            opcode_pushDP : first_execution_state = pushDP; // PUSH DP
            opcode_popDP  : first_execution_state = popDP; // POP DP
            opcode_ret    : first_execution_state = ret; // RET 
            // FORMATO F1
            opcode_inAL             : first_execution_state = in; // IN offset,AL
            opcode_outAL            : first_execution_state = out; // OUT AL,offset
            opcode_mov_operando_DP  : first_execution_state = ldimmDP; // MOV $operando,DP
            opcode_mov_operando_SP  : first_execution_state = ldSP; // MOV $operando,SP
            opcode_mov_indirizzo_DP : first_execution_state = lddirDP; // MOV indirizzo,DP
            opcode_mov_DP_indirizzo : first_execution_state = storeDP; // MOV DP,indirizzo
            // FORMATO F2
            opcode_mov_DP_AL : first_execution_state = ldAL;  // MOV (DP),AL
            opcode_cmp_DP_AL : first_execution_state = aluAL; // CMP (DP),AL
            opcode_add_DP_AL : first_execution_state = aluAL; // ADD (DP),AL
            opcode_sub_DP_AL : first_execution_state = aluAL; // SUB (DP),AL
            opcode_and_DP_AL : first_execution_state = aluAL; // AND (DP),AL
            opcode_or_DP_AL  : first_execution_state = aluAL; // OR  (DP),AL
            opcode_mov_DP_AH : first_execution_state = ldAH;  // MOV (DP),AH
            opcode_cmp_DP_AH : first_execution_state = aluAH; // CMP (DP),AH
            opcode_add_DP_AH : first_execution_state = aluAH; // ADD (DP),AH
            opcode_sub_DP_AH : first_execution_state = aluAH; // SUB (DP),AH
            opcode_and_DP_AH : first_execution_state = aluAH; // AND (DP),AH
            opcode_or_DP_AH  : first_execution_state = aluAH; // OR  (DP),AH
            // FORMATO F3
            opcode_mov_AL_DP : first_execution_state = storeAL; // MOV AL,(DP)
            opcode_mov_AH_DP : first_execution_state = storeAH; // MOV AH,(DP)
            // FORMATO F4
            opcode_mov_operando_AL : first_execution_state = ldAL;  // MOV $operando,AL
            opcode_cmp_operando_AL : first_execution_state = aluAL; // CMP $operando,AL
            opcode_add_operando_AL : first_execution_state = aluAL; // ADD $operando,AL 
            opcode_sub_operando_AL : first_execution_state = aluAL; // SUB $operando,AL 
            opcode_and_operando_AL : first_execution_state = aluAL; // AND $operando,AL 
            opcode_or_operando_AL  : first_execution_state = aluAL; // OR  $operando,AL 
            opcode_mov_operando_AH : first_execution_state = ldAH;  // MOV $operando,AH
            opcode_cmp_operando_AH : first_execution_state = aluAH; // CMP $operando,AH
            opcode_add_operando_AH : first_execution_state = aluAH; // ADD $operando,AH 
            opcode_sub_operando_AH : first_execution_state = aluAH; // SUB $operando,AH 
            opcode_and_operando_AH : first_execution_state = aluAH; // AND $operando,AH 
            opcode_or_operando_AH  : first_execution_state = aluAH; // OR  $operando,AH 
            // FORMATO F5
            opcode_mov_indirizzo_AL : first_execution_state = ldAL;  // MOV indirizzo,AL
            opcode_cmp_indirizzo_AL : first_execution_state = aluAL; // CMP indirizzo,AL
            opcode_add_indirizzo_AL : first_execution_state = aluAL; // ADD indirizzo,AL 
            opcode_sub_indirizzo_AL : first_execution_state = aluAL; // SUB indirizzo,AL 
            opcode_and_indirizzo_AL : first_execution_state = aluAL; // AND indirizzo,AL 
            opcode_or_indirizzo_AL  : first_execution_state = aluAL; // OR  indirizzo,AL 
            opcode_mov_indirizzo_AH : first_execution_state = ldAH;  // MOV indirizzo,AH
            opcode_cmp_indirizzo_AH : first_execution_state = aluAH; // CMP indirizzo,AH
            opcode_add_indirizzo_AH : first_execution_state = aluAH; // ADD indirizzo,AH 
            opcode_sub_indirizzo_AH : first_execution_state = aluAH; // SUB indirizzo,AH 
            opcode_and_indirizzo_AH : first_execution_state = aluAH; // AND indirizzo,AH 
            opcode_or_indirizzo_AH  : first_execution_state = aluAH; // OR  indirizzo,AH 
            // FORMATO F6
            opcode_mov_AL_indirizzo : first_execution_state = storeAL; // MOV AL,indirizzo
            opcode_mov_AH_indirizzo : first_execution_state = storeAH; // MOV AH,indirizzo
            // FORMATO F7
            opcode_jmp  : first_execution_state = jmp; // JMP indirizzo 
            opcode_je   : first_execution_state = jmp; // JE indirizzo
            opcode_jne  : first_execution_state = jmp; // JNE indirizzo
            opcode_ja   : first_execution_state = jmp; // JA indirizzo
            opcode_jae  : first_execution_state = jmp; // JAE indirizzo
            opcode_jb   : first_execution_state = jmp; // JB indirizzo
            opcode_jbe  : first_execution_state = jmp; // JBE indirizzo
            opcode_jg   : first_execution_state = jmp; // JG indirizzo
            opcode_jge  : first_execution_state = jmp; // JGE indirizzo
            opcode_jl   : first_execution_state = jmp; // JL indirizzo
            opcode_jle  : first_execution_state = jmp; // JLE indirizzo
            opcode_jz   : first_execution_state = jmp; // JZ indirizzo
            opcode_jnz  : first_execution_state = jmp; // JNZ indirizzo
            opcode_jc   : first_execution_state = jmp; // JC indirizzo
            opcode_jnc  : first_execution_state = jmp; // JNC indirizzo
            opcode_jo   : first_execution_state = jmp; // JO indirizzo
            opcode_jno  : first_execution_state = jmp; // JNO indirizzo
            opcode_js   : first_execution_state = jmp; // JS indirizzo
            opcode_jns  : first_execution_state = jmp; // JNS indirizzo
            opcode_call : first_execution_state = call; // CALL indirizzo
            // ISTRUZIONE NON NOTA
            // default    : first_execution_state = 1'b0; // se sono qua sono sicuro di avere un istruzione valida
        endcase
    endfunction

    // Prende in ingresso due byte, che saranno il contenuto di OPCODE di F. Restituisce 1 se OPCODE è la codifica di iun salto 
    // incondizionato (JMP); OPCODE è la codifica di un salto condizionato e la condizione richiesta da OPCODE, valutata testando 
    // il contenuto di F, risulta vera. E' la rete che decide se si deve saltare o no
    function jmp_condition; // OF SF ZF CF
        input[7:0] opcode;
        input[7:0] flag;
        casex (opcode)
            opcode_jmp : jmp_condition = 1'b1;                                                 // JMP indirizzo  
            opcode_je  : jmp_condition = ( flag[1]==1 ) ? 1'b1: 1'b0 ;                         // JE indirizzo 
            opcode_jne : jmp_condition = ( flag[1]==0 ) ? 1'b1: 1'b0 ;                         // JNE indirizzo 
            opcode_ja  : jmp_condition = ( flag[0]==0 && flag[1]==0 ) ? 1'b1: 1'b0 ;           // JA indirizzo
            opcode_jae : jmp_condition = ( flag[0]==0 ) ? 1'b1: 1'b0 ;                         // JAE indirizzo
            opcode_jb  : jmp_condition = ( flag[0]==1 ) ? 1'b1: 1'b0 ;                         // JB indirizzo
            opcode_jbe : jmp_condition = ( flag[1]==1 || flag[0]==1 ) ? 1'b1: 1'b0 ;           // JBE indirizzo
            opcode_jg  : jmp_condition = ( flag[1]==0 ) ? 1'b1: 1'b0 ;                         // JG indirizzo
            opcode_jge : jmp_condition = ( flag[2]==flag[3] ) ? 1'b1: 1'b0 ;                   // JGE indirizzo
            opcode_jl  : jmp_condition = ( flag[2]!=flag[3] ) ? 1'b1: 1'b0 ;                   // JL indirizzo
            opcode_jle : jmp_condition = ( (flag[1]==1) || (flag[2]!=flag[3])) ? 1'b1: 1'b0 ;  // JLE indirizzo
            opcode_jz  : jmp_condition = ( flag[1]==1 ) ? 1'b1: 1'b0 ;                         // JZ indirizzo
            opcode_jnz : jmp_condition = ( flag[1]==0 ) ? 1'b1: 1'b0 ;                         // JNZ indirizzo
            opcode_jc  : jmp_condition = ( flag[0]==1 ) ? 1'b1: 1'b0 ;                         // JC indirizzo
            opcode_jnc : jmp_condition = ( flag[0]==0 ) ? 1'b1: 1'b0 ;                         // JNC indirizzo
            opcode_jo  : jmp_condition = ( flag[3]==1 ) ? 1'b1: 1'b0 ;                         // JO indirizzo
            opcode_jno : jmp_condition = ( flag[3]==0 ) ? 1'b1: 1'b0 ;                         // JNO indirizzo
            opcode_js  : jmp_condition = ( flag[2]==1 ) ? 1'b1: 1'b0 ;                         // JS indirizzo
            opcode_jns : jmp_condition = ( flag[2]==0 ) ? 1'b1: 1'b0 ;                         // JNS indirizzo
        endcase
    endfunction

    // Simula la ALU interna al processore. Interpreta i 3 byte passati in ingresso come opcode, un operando sorgente, un operando
    // destinatario, e restituisce il risultato su 8 bit dell'elaborazione svolta. Tale risultato sarà tipicamente usato per 
    // una scrittura dentro AL/AH
    function[7:0] alu_result;
        input[7:0] opcode, operando1, operando2;
        casex (opcode) 
            opcode_cmp_DP_AL: alu_result = operando2;             // CMP (DP),AL
            opcode_add_DP_AL: alu_result = operando1 + operando2; // ADD (DP),AL
            opcode_sub_DP_AL: alu_result = operando2 - operando1; // SUB (DP),AL
            opcode_and_DP_AL: alu_result = operando1 & operando2; // AND (DP),AL
            opcode_or_DP_AL: alu_result = operando1 | operando2; // OR  (DP),AL
            opcode_cmp_operando_AL: alu_result = operando2;             // CMP $operando,AL
            opcode_add_operando_AL: alu_result = operando1 + operando2; // ADD $operando,AL 
            opcode_sub_operando_AL: alu_result = operando2 - operando1; // SUB $operando,AL 
            opcode_and_operando_AL: alu_result = operando1 & operando2; // AND $operando,AL 
            opcode_or_operando_AL: alu_result = operando1 | operando2; // OR  $operando,AL 
            opcode_cmp_indirizzo_AL: alu_result = operando2;             // CMP indirizzo,AL
            opcode_add_indirizzo_AL: alu_result = operando1 + operando2; // ADD indirizzo,AL 
            opcode_sub_indirizzo_AL: alu_result = operando2 - operando1; // SUB indirizzo,AL 
            opcode_and_indirizzo_AL: alu_result = operando1 & operando2; // AND indirizzo,AL 
            opcode_or_indirizzo_AL: alu_result = operando1 | operando2; // OR  indirizzo,AL 
            opcode_notAL: alu_result = ~operando2;            // NOT AL 
            opcode_shlAL: alu_result = operando2<<1;          // SHL AL
            opcode_shrAL: alu_result = operando2>>1;          // SHR AL

            opcode_cmp_DP_AH: alu_result = operando2;             // CMP (DP),AH
            opcode_add_DP_AH: alu_result = operando1 + operando2; // ADD (DP),AH
            opcode_sub_DP_AH: alu_result = operando2 - operando1; // SUB (DP),AH
            opcode_and_DP_AH: alu_result = operando1 & operando2; // AND (DP),AH
            opcode_or_DP_AH: alu_result = operando1 | operando2; // OR  (DP),AH
            opcode_cmp_operando_AH: alu_result = operando2;             // CMP $operando,AH
            opcode_add_operando_AH: alu_result = operando1 + operando2; // ADD $operando,AH 
            opcode_sub_operando_AH: alu_result = operando2 - operando1; // SUB $operando,AH 
            opcode_and_operando_AH: alu_result = operando1 & operando2; // AND $operando,AH 
            opcode_or_operando_AH: alu_result = operando1 | operando2; // OR  $operando,AH 
            opcode_cmp_indirizzo_AH: alu_result = operando2;             // CMP indirizzo,AH
            opcode_add_indirizzo_AH: alu_result = operando1 + operando2; // ADD indirizzo,AH 
            opcode_sub_indirizzo_AH: alu_result = operando2 - operando1; // SUB indirizzo,AH 
            opcode_and_indirizzo_AH: alu_result = operando1 & operando2; // AND indirizzo,AH 
            opcode_or_indirizzo_AH: alu_result = operando1 | operando2; // OR  indirizzo,AH 
            opcode_notAH: alu_result = ~operando2;            // NOT AH
            opcode_shlAH: alu_result = operando2<<1;          // SHL AH
            opcode_shrAH: alu_result = operando2>>1;          // SHR AH
        endcase
    endfunction

    // Prende in ingresso gli stessi byte e simula l'aggiornamento dei flag consistente con l'operazione specificata in opcode e 
    // con lo stato degli operandi. Ritorna quindi uno stato di uscita a 4 bit, che rappresentano i 4 flag significativi 
    // del registro F
    function[3:0] alu_flag; // OF SF ZF CF
        input[7:0] opcode, operando1, operando2;
        
        reg [7:0] differenza;
        reg [7:0] somma;
        reg [8:0] differenza_estesa;
        reg [8:0] somma_estesa;
        reg [7:0] and_bit_bit;
        reg [7:0] or_bit_bit;
        begin
        differenza = operando2 - operando1;
        somma = operando1 + operando2;
        differenza_estesa = {1'b0,operando2}-{1'b0,operando1}; 
        somma_estesa = {1'b0,operando2}+{1'b0,operando1};
        and_bit_bit = operando1 & operando2;
        or_bit_bit = operando1 | operando2;
        casex (opcode)
            
            opcode_cmp_DP_AL: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // CMP (DP),AL
            
            opcode_add_DP_AL: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]!=somma[7]?1'b0:1'b1), // of
                somma[7]==1?1'b1:1'b0, //sf
                somma==0? 1'b1:1'b0, // zf
                somma_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // ADD (DP),AL

            opcode_sub_DP_AL: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // SUB (DP),AL
            
            opcode_and_DP_AL: alu_flag = {
                1'b0,    // of
                and_bit_bit[7]==1?1'b1:1'b0,    // sf
                and_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // AND (DP),AL
            
            opcode_or_DP_AL: alu_flag = {
                1'b0,    // of
                or_bit_bit[7]==1?1'b1:1'b0,    // sf
                or_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // OR  (DP),AL

            opcode_cmp_operando_AL: alu_flag =  {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, // sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // CMP $operando,AL

            opcode_add_operando_AL: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]!=somma[7]?1'b0:1'b1), // of
                somma[7]==1?1'b1:1'b0, //sf
                somma==0? 1'b1:1'b0, // zf
                somma_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // ADD $operando,AL 

            opcode_sub_operando_AL: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // SUB $operando,AL 

            opcode_and_operando_AL: alu_flag ={
                1'b0,    // of
                and_bit_bit[7]==1?1'b1:1'b0,    // sf
                and_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // AND $operando,AL 
            opcode_or_operando_AL: alu_flag = {
                1'b0,    // of
                or_bit_bit[7]==1?1'b1:1'b0,    // sf
                or_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // OR  $operando,AL

            opcode_cmp_indirizzo_AL: alu_flag =  {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // CMP indirizzo,AL

            opcode_add_indirizzo_AL: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]!=somma[7]?1'b0:1'b1), // of
                somma[7]==1?1'b1:1'b0, //sf
                somma==0? 1'b1:1'b0, // zf
                somma_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // ADD indirizzo,AL 

            opcode_sub_indirizzo_AL: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // SUB indirizzo,AL 

            opcode_and_indirizzo_AL: alu_flag ={
                1'b0,    // of
                and_bit_bit[7]==1?1'b1:1'b0,    // sf
                and_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // AND indirizzo,AL 

            opcode_or_indirizzo_AL: alu_flag = {
                1'b0,    // of
                or_bit_bit[7]==1?1'b1:1'b0,    // sf
                or_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // OR  indirizzo,AL 
            
            opcode_notAL: alu_flag = {
                F[1], // of
                F[2], // sf
                F[3], // zf
                F[0]  // cf
            };  // NOT AL 
            
            opcode_shlAL: alu_flag = {
                1'b0, // of
                1'b0, // sf
                1'b0, // zf
                operando2[7] // cf
            };  // SHL AL
            
            opcode_shrAL: alu_flag = {
                1'b0, // of
                1'b0, // sf
                1'b0, // zf
                operando2[0] // cf
            };  // SHR AL

            opcode_cmp_DP_AH: alu_flag =  {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            };  // CMP (DP),AH

            opcode_add_DP_AH: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]!=somma[7]?1'b0:1'b1), // of
                somma[7]==1?1'b1:1'b0, //sf
                somma==0? 1'b1:1'b0, // zf
                somma_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // ADD (DP),AH

            opcode_sub_DP_AH: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // SUB (DP),AH

            opcode_and_DP_AH: alu_flag = {
                1'b0,    // of
                and_bit_bit[7]==1?1'b1:1'b0,    // sf
                and_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // AND (DP),AH 

            opcode_or_DP_AH: alu_flag = {
                1'b0,    // of
                or_bit_bit[7]==1?1'b1:1'b0,    // sf
                or_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // OR (DP),AH

            opcode_cmp_operando_AH: alu_flag =  {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // CMP $operando,AH

            opcode_add_operando_AH: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]!=somma[7]?1'b0:1'b1), // of
                somma[7]==1?1'b1:1'b0, //sf
                somma==0? 1'b1:1'b0, // zf
                somma_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // ADD $operando,AH 

            opcode_sub_operando_AH: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // SUB $operando,AH 

            opcode_and_operando_AH: alu_flag = {
                1'b0,    // of
                and_bit_bit[7]==1?1'b1:1'b0,    // sf
                and_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // AND $operando,AH 

            opcode_or_operando_AH: alu_flag = {
                1'b0,    // of
                or_bit_bit[7]==1?1'b1:1'b0,    // sf
                or_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // OR $operando,AH 

            opcode_cmp_indirizzo_AH: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // CMP indirizzo,AH

            opcode_add_indirizzo_AH: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]!=somma[7]?1'b0:1'b1), // of
                somma[7]==1?1'b1:1'b0, //sf
                somma==0? 1'b1:1'b0, // zf
                somma_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // ADD indirizzo,AH 

            opcode_sub_indirizzo_AH: alu_flag = {
                operando2[7]==operando1[7]?1'b0:(operando2[7]==differenza[7]?1'b0:1'b1), // of
                differenza[7]==1?1'b1:1'b0, //sf
                differenza==0? 1'b1:1'b0, // zf
                differenza_estesa[8]==0 ?1'b0:1'b1 // cf
            }; // SUB indirizzo,AH 

            opcode_and_indirizzo_AH: alu_flag = {
                1'b0,    // of
                and_bit_bit[7]==1?1'b1:1'b0,    // sf
                and_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // AND indirizzo,AH 

            opcode_or_indirizzo_AH: alu_flag = {
                1'b0,    // of
                or_bit_bit[7]==1?1'b1:1'b0,    // sf
                or_bit_bit==0?1'b1:1'b0,    // zf
                1'b0     // cf
            }; // OR  indirizzo,AH 

            opcode_notAH: alu_flag = {
                F[1], // of
                F[2], // sf
                F[3], // zf
                F[0] // cf
            };  // NOT AH

            opcode_shlAH: alu_flag = {
                1'b0, // of
                1'b0, // sf
                1'b0, // zf
                operando2[7] // cf
            };  // SHL AH

            opcode_shrAH: alu_flag = {
                1'b0, // of
                1'b0, // sf
                1'b0, // zf
                operando2[0] // cf
            };  // SHR AH
        endcase
        end
    endfunction

    // ALTRI MNEMONICI
    parameter[2:0] F0='B000,
                   F1='B001,
                   F2='B010,
                   F3='B011,
                   F4='B100,
                   F5='B101,
                   F6='B110,
                   F7='B111;

    //----------------------------------------------------------------
    // AL RESET_ INIZIALE
    always @(reset_==0) #1 begin 
                                IP<='HFF0000; F<='H00; DIR<=0;
                                MR_<=1; MW_<=1; IOR_<=1; IOW_<=1;
                                STAR<=fetch0; 
                                TB_HALT<=0; TB_STAGE<=0; TB_NVI<=0;
                           end
    //----------------------------------------------------------------

    // ALL’ARRIVO DEI SEGNALI DI SINCRONIZZAZIONE
    always @(posedge clock) if (reset_==1) #3
        casex(STAR)
        //----------------------------------------------------------------
            // FASE DI CHIAMATA
            fetch0: begin A23_A0<=IP; IP<=IP+1; MJR<=fetch1; STAR<=readB; end

            fetch1: begin OPCODE<=APP0; STAR<=fetch2; end

            fetch2: begin
                         MJR<=(OPCODE[7:5]==F0)?fetchEnd:
                              (OPCODE[7:5]==F1)?fetchEnd:
                              (OPCODE[7:5]==F2)?fetchF2_0:
                              (OPCODE[7:5]==F3)?fetchF3_0:
                              (OPCODE[7:5]==F4)?fetchF4_0:
                              (OPCODE[7:5]==F5)?fetchF5_0:
                              (OPCODE[7:5]==F6)?fetchF6_0:
                              /* default */     fetchF7_0;
                           STAR<=(valid_fetch(OPCODE)==1)?fetch3:nvi; 
                    end

            fetch3: begin STAR<=MJR; end

            fetchF2_0: begin A23_A0<=DP; MJR<=fetchF2_1; STAR<=readB; end

            fetchF2_1: begin SOURCE<=APP0; STAR<=fetchEnd; end

            fetchF3_0: begin DEST_ADDR<=DP; STAR<=fetchEnd; end

            fetchF4_0: begin A23_A0<=IP; IP<=IP+1; MJR<=fetchF4_1; STAR<=readB; end

            fetchF4_1: begin SOURCE<=APP0; STAR<=fetchEnd; end

            fetchF5_0: begin A23_A0<=IP; IP<=IP+3; MJR<=fetchF5_1; STAR<=readM; end

            fetchF5_1: begin A23_A0<={APP2,APP1,APP0}; MJR<=fetchF5_2; STAR<=readB; end

            fetchF5_2: begin SOURCE<=APP0; STAR<=fetchEnd; end

            fetchF6_0: begin A23_A0<=IP; IP<=IP+3; MJR<=fetchF6_1; STAR<=readM; end

            fetchF6_1: begin DEST_ADDR<={APP2,APP1,APP0}; STAR<=fetchEnd; end

            fetchF7_0: begin A23_A0<=IP; IP<=IP+3; MJR<=fetchF7_1; STAR<=readM; end

            fetchF7_1: begin DEST_ADDR<={APP2,APP1,APP0}; STAR<=fetchEnd; end

            //----------------------------------------------------------------
            // TERMINAZIONE DELLA FASE DI CHIAMATA
            // TERMINAZIONE CON BLOCCO PER ISTRUZIONE NON VALIDA
            nvi: begin STAR<=nvi; TB_NVI<=1; end // devo metterlo anche qui TB_HALT<=1; ?? Devo interrompere la simulazione pure in questo caso

            // TERMINAZIONE REGOLARE CON PASSAGGIO ALLA FASE DI ESECUZIONE
            fetchEnd: begin MJR<=first_execution_state(OPCODE); STAR<=fetchEnd1; end

            fetchEnd1: begin STAR<=MJR; TB_STAGE<=1; end // tb_stage a 1 -->indica la fase di esecuzione

            //----------------------------------------------------------------
            // FASE DI ESECUZIONE
            //------------- istruzione NOP ----------------
            nop: begin STAR<=fetch0; TB_STAGE<=0; end // ogni volta che trovo fetch0 devo resettare tb_stage

            //------------- istruzione HLT ----------------
            hlt: begin STAR<=hlt; TB_HALT<=1; end

            //------------- istruzione MOV AL,AH ----------------
            ALtoAH: begin AH<=AL; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione MOV AH,AL ----------------
            AHtoAL: begin AL<=AH; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione INC DP ----------------
            incDP: begin DP<=DP+1; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzioni MOV (DP),AL ----------------
                                    // MOV $operando,AL
                                    // MOV indirizzo,AL
            ldAL: begin AL<=SOURCE; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzioni MOV (DP),AH ----------------
                                    // MOV $operando,AH
                                    // MOV indirizzo,AH
            ldAH: begin AH<=SOURCE; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzioni MOV AL,(DP) ----------------
                                    // MOV AL,indirizzo
            storeAL: begin A23_A0<=DEST_ADDR; APP0<=AL;
                           MJR<=fetch0; STAR<=writeB; end

            //------------- istruzioni MOV AH,(DP) ----------------
                                    // MOV AH,indirizzo
            storeAH: begin A23_A0<=DEST_ADDR; APP0<=AH;
                           MJR<=fetch0; STAR<=writeB;  end

            //------------- istruzione MOV $operando,SP ----------------
            ldSP: begin A23_A0<=IP; IP<=IP+3; MJR<=ldSP1; STAR<=readM; end

            ldSP1: begin SP<={APP2,APP1,APP0}; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione MOV $operando,DP ----------------
            ldimmDP: begin A23_A0<=IP; IP<=IP+3; MJR<=ldimmDP1;
                           STAR<=readM; end

            ldimmDP1: begin DP<={APP2,APP1,APP0}; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione MOV indirizzo,DP ------------------
            lddirDP: begin A23_A0<=IP; IP<=IP+3; MJR<=lddirDP1;
                           STAR<=readM; end

            lddirDP1: begin A23_A0<={APP2,APP1,APP0}; MJR<=lddirDP2;
                            STAR<=readM; end

            lddirDP2: begin DP<={APP2,APP1,APP0}; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione MOV DP,indirizzo ----------------
            storeDP: begin A23_A0<=IP; IP<=IP+3;
                           MJR<=storeDP1; STAR<=readM; end

            storeDP1: begin A23_A0<={APP2,APP1,APP0}; {APP2,APP1,APP0}<=DP;
                            MJR<=fetch0; STAR<=writeM;  end

            //------------- istruzione IN offset,AL ----------------
            in: begin A23_A0<=IP; IP<=IP+2; MJR<=in1; STAR<=readW; end

            in1: begin A23_A0<={8'H00,APP1,APP0}; STAR<=in2; end

            in2: begin IOR_<=0; STAR<=in3; end

            in3: begin AL<=d7_d0; IOR_<=1; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione OUT AL,offset ----------------
            out: begin A23_A0<=IP; IP<=IP+2; MJR<=out1; STAR<=readW; end

            out1: begin A23_A0<={8'H00,APP1,APP0}; D7_D0<=AL; DIR<=1;
                        STAR<=out2; end

            out2: begin IOW_<=0; STAR<=out3; end

            out3: begin IOW_<=1; STAR<=out4; end

            out4: begin DIR<=0; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzioni ADD (DP),AL ----------------
                                    // ADD $operando,AL
                                    // ADD indirizzo,AL
                                    // SUB (DP),AL
                                    // SUB $operando,AL
                                    // SUB indirizzo,AL
                                    // AND (DP),AL
                                    // AND $operando,AL
                                    // AND indirizzo,AL
                                    // OR (DP),AL
                                    // OR $operando,AL
                                    // OR indirizzo,AL
                                    // CMP (DP),AL
                                    // CMP $operando,AL
                                    // CMP indirizzo,AL
                                    // NOT AL
                                    // SHL AL
                                    // SHR AL

            aluAL: begin AL<=alu_result(OPCODE,SOURCE,AL);
                         F<={F[7:4],alu_flag(OPCODE,SOURCE,AL)};
                         STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzioni ADD (DP),AH ----------------
                                    // ADD $operando,AH
                                    // ADD indirizzo,AH
                                    // SUB (DP),AH
                                    // SUB $operando,AH
                                    // SUB indirizzo,AH
                                    // AND (DP),AH
                                    // AND $operando,AH
                                    // AND indirizzo,AH
                                    // OR (DP),AH
                                    // OR $operando,AH
                                    // OR indirizzo,AH
                                    // CMP (DP),AH
                                    // CMP $operando,AH
                                    // CMP indirizzo,AH
                                    // NOT AH
                                    // SHL AH
                                    // SHR AH
            aluAH: begin AH<=alu_result(OPCODE,SOURCE,AH);
                         F<={F[7:4],alu_flag(OPCODE,SOURCE,AH)};
                         STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzioni JMP indirizzo ---------------
                                    // JA indirizzo
                                    // JAE indirizzo
                                    // JB indirizzo
                                    // JBE indirizzo
                                    // JC indirizzo
                                    // JE indirizzo
                                    // JG indirizzo
                                    // JGE indirizzo
                                    // JL indirizzo
                                    // JLE indirizzo
                                    // JNC indirizzo
                                    // JNE indirizzo
                                    // JNO indirizzo
                                    // JNS indirizzo
                                    // JNZ indirizzo
                                    // JS indirizzo
                                    // JO indirizzo
                                    // JZ indirizzo
            jmp: begin IP<=(jmp_condition(OPCODE,F)==1)?DEST_ADDR:IP;
                       STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione PUSH AL ----------------
            pushAL: begin A23_A0<=SP-1; SP<=SP-1; APP0<=AL;
                          MJR<=fetch0; STAR<=writeB; end

            //------------- istruzione PUSH AH ----------------
            pushAH: begin A23_A0<=SP-1; SP<=SP-1; APP0<=AH;
                          MJR<=fetch0; STAR<=writeB; end

            //------------- istruzione PUSH DP ----------------
            pushDP: begin A23_A0<=SP-3; SP<=SP-3; {APP2,APP1,APP0}<=DP;
                          MJR<=fetch0; STAR<=writeM; end

            //------------- istruzione POP AL ----------------
            popAL: begin A23_A0<=SP; SP<=SP+1; MJR<=popAL1; STAR<=readB;end

            popAL1: begin AL<=APP0; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione POP AH ----------------
            popAH: begin A23_A0<=SP; SP<=SP+1; MJR<=popAH1; STAR<=readB; end

            popAH1: begin AH<=APP0; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione POP DP ----------------
            popDP: begin A23_A0<=SP; SP<=SP+3; MJR<=popDP1; STAR<=readM; end

            popDP1: begin DP<={APP2,APP1,APP0}; STAR<=fetch0; TB_STAGE<=0; end
            //------------- istruzione CALL indirizzo ----------------
            call: begin A23_A0<=SP-3; SP<=SP-3; {APP2,APP1,APP0}<=IP;
                        MJR<=call1; STAR<=writeM; end

            call1: begin IP<=DEST_ADDR; STAR<=fetch0; TB_STAGE<=0; end

            //------------- istruzione RET ----------------
            ret: begin A23_A0<=SP; SP<=SP+3; MJR<=ret1; STAR<=readM; end

            ret1: begin IP<={APP2,APP1,APP0}; STAR<=fetch0; TB_STAGE<=0; end

            //----------------------------------------------------------------
            // MICROSOTTOPROGRAMMA PER LETTURE IN MEMORIA
            readB: begin MR_<=0; NUMLOC<=1; STAR<=read0; end
            
            readW: begin MR_<=0; NUMLOC<=2; STAR<=read0; end
            
            readM: begin MR_<=0; NUMLOC<=3; STAR<=read0; end
            
            readL: begin MR_<=0; NUMLOC<=4; STAR<=read0; end

            read0: begin APP0<=d7_d0; A23_A0<=A23_A0+1; NUMLOC<=NUMLOC-1;
                         STAR<=(NUMLOC==1)?read4:read1; end

            read1: begin APP1<=d7_d0; A23_A0<=A23_A0+1; NUMLOC<=NUMLOC-1;
                         STAR<=(NUMLOC==1)?read4:read2; end

            read2: begin APP2<=d7_d0; A23_A0<=A23_A0+1; NUMLOC<=NUMLOC-1;
                         STAR<=(NUMLOC==1)?read4:read3; end

            read3: begin APP3<=d7_d0; A23_A0<=A23_A0+1; STAR<=read4; end

            read4: begin MR_<=1; STAR<=MJR; TB_STAGE<=(MJR==fetch0)?0:TB_STAGE; end

            // MICROSOTTOPROGRAMMA PER SCRITTURE IN MEMORIA
            writeB: begin D7_D0<=APP0; DIR<=1; NUMLOC<=1; STAR<=write0; end

            writeW: begin D7_D0<=APP0; DIR<=1; NUMLOC<=2; STAR<=write0; end

            writeM: begin D7_D0<=APP0; DIR<=1; NUMLOC<=3; STAR<=write0; end

            writeL: begin D7_D0<=APP0; DIR<=1; NUMLOC<=4; STAR<=write0; end

            write0: begin MW_<=0; STAR<=write1; end

            write1: begin MW_<=1; STAR<= (NUMLOC==1) ? write11 : write2; end

            write2: begin D7_D0<=APP1; A23_A0<=A23_A0+1; NUMLOC<=NUMLOC-1;
                          STAR<=write3; end

            write3: begin MW_<=0; STAR<=write4; end

            write4: begin MW_<=1; STAR<=(NUMLOC==1)?write11:write5; end

            write5: begin D7_D0<=APP2; A23_A0<=A23_A0+1; NUMLOC<=NUMLOC-1;
                          STAR<=write6; end

            write6: begin MW_<=0; STAR<=write7; end

            write7: begin MW_<=1; STAR<=(NUMLOC==1)?write11:write8; end

            write8: begin D7_D0<=APP3; A23_A0<=A23_A0+1; STAR<=write9; end

            write9: begin MW_<=0; STAR<=write10; end

            write10: begin MW_<=1; STAR<=write11; end

            write11: begin DIR<=0; STAR<=MJR; TB_STAGE<=(MJR==fetch0)?0:TB_STAGE; end

    endcase

endmodule
//-----------------------------------------------------------------