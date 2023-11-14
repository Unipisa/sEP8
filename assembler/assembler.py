#!/usr/bin/python3
import sys
import io
import os
from binascii import unhexlify
'''
if len(sys.argv) < 2:
    sys.exit();
'''
instr_trad = {
	"HLT"		:"opcode_hlt", 
	"NOP"		:"opcode_nop",
	"MOVALAH"	:"opcode_ALtoAH",
	"MOVAHAL"	:"opcode_AHtoAL",
	"INCDP"	 	:"opcode_incDP",
	"SHLAL"		:"opcode_shlAL",
	"SHRAL"	 	:"opcode_shrAL",
	"NOTAL"	 	:"opcode_notAL",
	"SHLAH"	 	:"opcode_shlAH",
	"SHRAH"	 	:"opcode_shrAH",
	"NOTAH"	 	:"opcode_notAH",
	"PUSHAL"	:"opcode_pushAL",
	"POPAL"		:"opcode_popAL",
	"PUSHAH"	:"opcode_pushAH",
	"POPAH"	    :"opcode_popAH",
	"PUSHDP"	:"opcode_pushDP",
	"POPDP"		:"opcode_popDP",
	"RET"		:"opcode_ret",
	# "IRET"		:"8'H12",
	#"EXCHSP"    :"8'h15",	

	"INaddrAL"  :"opcode_inAL",
	"OUTALaddr" :"opcode_outAL",
	"MOVopDP"	:"opcode_mov_operando_DP",
	"MOVopSP" 	:"opcode_mov_operando_SP",
	"MOVaddrDP" :"opcode_mov_indirizzo_DP",
	"MOVDPaddr" :"opcode_mov_DP_indirizzo",
	# "LIDTPaddr"	:"8'H26",

	"MOV(DP)AL" :"opcode_mov_DP_AL",
	"CMP(DP)AL" :"opcode_cmp_DP_AL",
	"ADD(DP)AL" :"opcode_add_DP_AL",
	"SUB(DP)AL" :"opcode_sub_DP_AL",
	"AND(DP)AL" :"opcode_and_DP_AL",
	"OR(DP)AL" 	:"opcode_or_DP_AL",
	"MOV(DP)AH" :"opcode_mov_DP_AH",
	"CMP(DP)AH" :"opcode_cmp_DP_AH",
	"ADD(DP)AH" :"opcode_add_DP_AH",
	"SUB(DP)AH" :"opcode_sub_DP_AH",
	"AND(DP)AH" :"opcode_and_DP_AH",
	"OR(DP)AH" 	:"opcode_or_DP_AH",

	"MOVAL(DP)" :"opcode_mov_AL_DP",
	"MOVAH(DP)" :"opcode_mov_AH_DP",

	"MOVopAL" 	:"opcode_mov_operando_AL",
	"CMPopAL" 	:"opcode_cmp_operando_AL",
	"ADDopAL" 	:"opcode_add_operando_AL",
	"SUBopAL" 	:"opcode_sub_operando_AL",
	"ANDopAL" 	:"opcode_and_operando_AL",
	"ORopAL" 	:"opcode_or_operando_AL",
	"MOVopAH" 	:"opcode_mov_operando_AH",
	"CMPopAH" 	:"opcode_cmp_operando_AH",
	"ADDopAH" 	:"opcode_add_operando_AH",
	"SUBopAH" 	:"opcode_sub_operando_AH",
	"ANDopAH" 	:"opcode_and_operando_AH",
	"ORopAH" 	:"opcode_or_operando_AH",
	#"INTop"		:"8'H8C",

	"MOVaddrAL" :"opcode_mov_indirizzo_AL",
	"CMPaddrAL" :"opcode_cmp_indirizzo_AL",
	"ADDaddrAL" :"opcode_add_indirizzo_AL",
	"SUBaddrAL" :"opcode_sub_indirizzo_AL",
	"ANDaddrAL" :"opcode_and_indirizzo_AL",
	"ORaddrAL" 	:"opcode_or_indirizzo_AL",
	"MOVaddrAH" :"opcode_mov_indirizzo_AH",
	"CMPaddrAH" :"opcode_cmp_indirizzo_AH",
	"ADDaddrAH" :"opcode_add_indirizzo_AH",
	"SUBaddrAH" :"opcode_sub_indirizzo_AH",
	"ANDaddrAH" :"opcode_and_indirizzo_AH",
	"ORaddrAH" 	:"opcode_or_indirizzo_AH",

	"MOVALaddr"	:"opcode_mov_AL_indirizzo",
	"MOVAHaddr" :"opcode_mov_AH_indirizzo",

	"JMPaddr"	:"opcode_jmp",
	"JEaddr"	:"opcode_je",
	"JNEaddr"	:"opcode_jne",
	"JAaddr"	:"opcode_ja",
	"JAEaddr"	:"opcode_jae",
	"JBaddr"	:"opcode_jb",
	"JBEaddr"	:"opcode_jbe",
	"JGaddr"	:"opcode_jg",
	"JGEaddr"	:"opcode_jge",
	"JLaddr"	:"opcode_jl",
	"JLEaddr"	:"opcode_jle",
	"JZaddr"	:"opcode_jz",
	"JNZaddr"	:"opcode_jnz",
	"JCaddr"	:"opcode_jc",
	"JNCaddr"	:"opcode_jnc",
	"JOaddr"	:"opcode_jo",
	"JNOaddr"	:"opcode_jno",
	"JSaddr"	:"opcode_js",
	"JNSaddr"	:"opcode_jns",
	"CALLaddr"	:"opcode_call",
}

addressable_regs = [
	"%AL",
	"%AH",
	"%SP",
	"%DP",
	"(%DP)",
	"" # serve nel caso in cui non ci sia il secondo parametro?
]

def splitBytes(strl): #WE ASSUME LITERLAS ARE ALWAYS GIVEN IN HEX
	output = [];
	strl = strl[2:] # rimuovo 0x
	while(len(strl)%2):
		strl="0"+strl; #NORMALIZE LENGTH
	for i in range(len(strl),0,-2):
		output.append("8'H"+strl[i-2:i]);
	return output; # output contiene una lista di stringhe 0xHH

def prepareOperand(operand):
	return splitBytes(operand[1:]) # si rimuove il $

def assembly(lines): # (lines)
    dizionario_etichette = {};
    indirizzo = 0xFF0000
    stringa =": valore = "
    # lines = ["AND $0x20,%AL","HLT","JMP 0xAABBCC","MOV %AL,0xDDEEFF"]
    # print(lines)
    lines = [x.strip() for x in lines]
    out = []
    for line in lines:
        # line.upper() per mettere tutto l'input in uppercase ?
        if line.startswith("#") :
            continue

        # encodedOp = ""
        encodedSrc = []
        encodedDst = []

        instr = line.split() # separo opcode e operandi
        opcode = instr[0] # ricavo opcode
        
        if len(instr) == 1: # ho solo opcode
            if opcode.endswith(':') :  # non è proprio un opcode, aggiorna
                dizionario_etichette[opcode[:-1]]=indirizzo
                # print(dizionario_etichette)
                # print(opcode[:-1])
                # print (hex(indirizzo))
            else :
               linea_r = "24'H" + str(hex(indirizzo)[2:]).upper() + stringa + instr_trad[opcode.upper()] + ";"
               out.append(linea_r) 
               indirizzo += 1
            # print(hex(indirizzo))
            continue
        opcode = opcode.upper() # serve quando si mette un'istruzione in minuscolo
        operands = instr[1].split(",") # separo operandi

        if len(operands) < 2: # se non ho due operandi metto il secondo vuoto ?
            operands.append("")

        src = operands[0]
        #print(src)
        dst = operands[1]
        # print(dst)
        #print(dst)

        if src.upper() in addressable_regs:
            if src.startswith('(') :
                opcode += '(' + src[2:].upper()
            else:
                opcode += src[1:].upper() # rimuovo %
        elif src.startswith('$'):
            opcode += "op"
            encodedSrc = prepareOperand(src)
        elif src in dizionario_etichette : 
             encodedSrc = splitBytes(hex(dizionario_etichette[src]))
             # print(encodedSrc)
             opcode +="addr"
        else: # perchè separo i casi ?
            if instr[0] != "IN" and instr[0] != "OUT":
                __tmp = int(src, 16)
                tmp = hex(__tmp)
                encodedSrc = splitBytes(tmp)
                # print("Relocated " + src + " to " + tmp)
            else:
                tmp = hex(int(src, 16))
                encodedSrc = splitBytes(src)
            opcode += "addr"

        if dst.upper() in addressable_regs:
            if dst.startswith('(') :
                opcode += '(' + dst[2:].upper()
            else:
                opcode += dst[1:].upper() # rimuovo %
            #opcode += dst[1:] # rimuovo %, ma se il secondo parametro è "" cosa succede?
        elif dst.startswith('$'):
            opcode += "op"
            encodedDst = prepareOperand(dst)
        else: # non basta mettere direttamente tmp = hex(int(dst,16)) \n encodedDST = splitBytes(dst) ?
            if instr[0] != "IN" and instr[0] != "OUT": # mi sembra da rimuovere 
                __dsttmp = int(dst, 16)
                dsttmp = hex(__dsttmp)
                encodedDst = splitBytes(dsttmp)
                # print("Relocated " + dst + " to " + dsttmp)
            else:
                tmp = hex(int(dst, 16))
                encodedDst = splitBytes(dst)
            opcode += "addr"
            
        # print(opcode)
        # mi ricavo la linea con 0xFF0000: valore = param.opcode_hlt;
        linea_r = "24'H" + str(hex(indirizzo)[2:]).upper() + stringa + instr_trad[opcode] + ";"
        indirizzo +=1
        # print(linea_r)
        #encodedOp = instr_trad[opcode]
        out.append(linea_r)
        #print(encodeddst)
        
        for elemento in encodedSrc :
            linea_r = "24'H" +str(hex(indirizzo)[2:]).upper() + stringa + elemento.upper() + ";"
            indirizzo += 1
            out.append(linea_r)
        
        for elemento in encodedDst :
            linea_r = "24'H" + str(hex(indirizzo)[2:]).upper() + stringa + elemento.upper() + ";"
            indirizzo += 1
            out.append(linea_r)
    return out


filename = sys.argv[1];

lines = [];

with open(filename) as fd: 
     lines = fd.readlines();
out = assembly(lines)
outfilename = "ROM_" + os.path.splitext(filename)[0] +".v";
file = open(outfilename,"w")
stringa = "module ROM(\n\ta23_a0,\n\ts_,mr_,\n\td7_d0\n);\n\tparameter ritardo_lettura = 2;\n\tinput [23:0] a23_a0;\n\tinput s_,mr_;\n\toutput [7:0] d7_d0;\n\t`include \"parametri_opcode.v\"\n\tfunction [7:0] valore;\n\t\tinput [23:0] a23_a0;\n\t\tcasex (a23_a0)\n";
file.write(stringa)
file.close()
# with open(outfilename, 'a') as file:
file = open(outfilename,"a")
for elem in out:
    file.write("\t\t\t"+ elem + "\n")
file.close()
file = open(outfilename,"a")
stringa = "\t\tendcase\n\tendfunction\n\tassign #ritardo_lettura d7_d0 = {s_,mr_}==2'b00 ? valore(a23_a0) : 8'HZZ;\nendmodule\n";
file.write(stringa);
file.close()

# controllare che gli input siano tutti in maiuscolo