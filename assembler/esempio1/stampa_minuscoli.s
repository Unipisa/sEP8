main:
    nop
# ciao questo è un commento
    mov $0x41,%AL
loop1:
    OR $0x20,%AL
    OUT %AL,0x0000
    add $0x01,%AL
    CMP $0x7A,%AL
    JBE loop1
    hlt