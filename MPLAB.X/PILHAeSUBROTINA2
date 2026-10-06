;   inc_32bits
;   Incremente uma variável de 32 bits apontada por X.

;   Parâmetros:
;   Registrador X: Ponteiro para a posição inicial da variável.

;   dec_32bits

;   Decremente uma variável de 32 bits apontada por X.

;   Parâmetros:
;   Registrador X: Ponteiro para a posição inicial da variável.

;   mov_32bits

;   Copie uma variável de 32 bits apontada por X para outra variável 
;   apontada por Y.

;   Parâmetros:
;   Registrador X: Ponteiro para a posição inicial da variável a ser copiada.
;   Registrador Y: Ponteiro para a posição inicial da variável que receberá
;   o valor.

;OBS.:
;   Para todos os casos, considere o byte menos significativo armazenado 
;   no menor endereço.
;   Implemente as sub-rotinas sem chamada de sub-rotinas intermediárias.
;   Implemente testes para cada uma das sub-rotinas.
; =============================================================================
    
.DSEG
.ORG SRAM_START
    VAR1 : .BYTE 4
    VAR2 : .BYTE 4
.CSEG
START:    

    LDI R16, 5
    LDI XL, LOW(VAR1)
    LDI XH, HIGH(VAR1)
    ST X, R16
    CALL inc_32bits
    
    CALL dec_32bits

    LDI R16, 0XAA
    ST X+, R16
    LDI R16, 0XBB
    ST X+, R16
    LDI R16, 0XCC
    ST X+, R16
    LDI R16, 0XDD
    ST X+, R16
    LDI XL, LOW(VAR1)
    LDI XH, HIGH(VAR1)
    ; Vamos apontar Y para VAR2
    LDI YL, LOW(VAR2)
    LDI YH, HIGH(VAR2)
    CALL mov_32bits
    
    RJMP START
    

inc_32bits:
    PUSH R17
    IN R17, SREG
    PUSH R17
    
    LD R17, X
    INC R17
    ST X, R17
    
    POP R17
    OUT SREG, R17
    POP R17
    
    RET


dec_32bits:
    PUSH R17 
    IN R17, SREG 
    PUSH R17
    
    LD R17, X
    DEC R17
    ST X, R17
    
    POP R17
    OUT SREG, R17
    POP R17
    RET


mov_32bits:
    PUSH R17 
    PUSH R18 
    IN R17, SREG 
    PUSH R17
    
    LDI R17, 4
    loop_mov_32bits:
	  LD R18, X+
	  ST Y+, R18
	  DEC R17
	  BRNE loop_mov_32bits
    
    POP R17
    OUT SREG, R17
    POP R18
    POP R17
    RET
