.DSEG ; Segmento de memória RAM
.ORG SRAM_START ; 0x0100 para o ATmega328P
    
    A: .BYTE 4 ; Variável de 32 bits
    B: .BYTE 4 ; Variável de 32 bits
    C: .BYTE 4 ; Variável de 32 bits

    
.CSEG ; Segmento da memória Flash (programa)

START:
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
   
    LDI XL, LOW(A)         
    LDI XH, HIGH(A)       
    
    LDI YL, LOW(B)       
    LDI YH, HIGH(B)        
    
    LDI ZL, LOW(C)       
    LDI ZH, HIGH(C) 
    
    LDI R16, 0x11
    LDI R17, 0x22
    LDI R18, 0x33
    LDI R19, 0x44
    
    RCALL init_32bits     
     
    LDI XL, LOW(B)          
    LDI XH, HIGH(B)
    
    RCALL zera_32bits       
    
    LDI XL, LOW(A)         
    LDI XH, HIGH(A)
    
    RCALL sub_32bits        
    
   FIM:
    RJMP FIM
    
init_32bits:
    ST X+, R16    
    ST X+, R17      
    ST X+, R18     
    ST X+, R19      

    RET
    
zera_32bits:
    PUSH R16
    CLR R16         
    ST X+, R16     
    ST X+, R16     
    ST X+, R16     
    ST X+, R16      
    
    POP R16

    RET
   
    
sub_32bits:
    PUSH R16
    PUSH R17
    
    IN R16, SREG            
    PUSH R16
    
    LD R16, X+          
    LD R17, Y+          
    SUB R16, R17        
    ST Z+, R16          
    
    LD R16, X+
    LD R17, Y+
    SBC R16, R17        
    ST Z+, R16

    LD R16, X+
    LD R17, Y+
    SBC R16, R17
    ST Z+, R16

    LD R16, X+
    LD R17, Y+
    SBC R16, R17
    ST Z+, R16

    POP R16                 
    OUT SREG, R16
    
    POP R17
    POP R16
    
    RET
