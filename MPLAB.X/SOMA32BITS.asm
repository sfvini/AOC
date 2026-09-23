.INCLUDE <m328Pdef.INC>

.DSEG ; Segmento de memória RAM
.ORG SRAM_START ; 0x0100 para o ATmega328P
    A: .BYTE 4 
    B: .BYTE 4 
    C: .BYTE 4 

.CSEG ; Segmento da memória Flash (programa)

START:

    ; 1. ENDEREÇAMENTO DIRETO (LDS / STS)
    ; Byte 0
    LDS R16, A
    LDS R17, B
    ADD R16, R17
    STS C, R16

    ; Byte 1
    LDS R16, A+1
    LDS R17, B+1
    ADC R16, R17
    STS C+1, R16

    ; Byte 2
    LDS R16, A+2
    LDS R17, B+2
    ADC R16, R17
    STS C+2, R16

    ; Byte 3 
    LDS R16, A+3
    LDS R17, B+3
    ADC R16, R17
    STS C+3, R16


    ; 2. ENDEREÇAMENTO INDIRETO (SEM INCREMENTAR)
    ; Aponta X para A, Y para B e Z para C
    LDI R27, HIGH(A) ; XH
    LDI R26, LOW(A)  ; XL
    LDI R29, HIGH(B) ; YH
    LDI R28, LOW(B)  ; YL
    LDI R31, HIGH(C) ; ZH
    LDI R30, LOW(C)  ; ZL

    ; Byte 0 
    LD R16, X
    LD R17, Y
    ADD R16, R17
    ST Z, R16

    ; Incrementa os ponteiros para o Byte 1
    ADIW R26, 1
    ADIW R28, 1
    ADIW R30, 1

    ; Byte 1
    LD R16, X
    LD R17, Y
    ADC R16, R17
    ST Z, R16

    ; Incrementa os ponteiros para o Byte 2
    ADIW R26, 1
    ADIW R28, 1
    ADIW R30, 1

    ; Byte 2
    LD R16, X
    LD R17, Y
    ADC R16, R17
    ST Z, R16

    ; Incrementa os ponteiros para o Byte 3
    ADIW R26, 1
    ADIW R28, 1
    ADIW R30, 1

    ; Byte 3 
    LD R16, X
    LD R17, Y
    ADC R16, R17
    ST Z, R16


    ; 3. ENDEREÇAMENTO INDIRETO COM PÓS-INCREMENTO
    ; Reinicializa os ponteiros no início de cada variável
    LDI R27, HIGH(A)
    LDI R26, LOW(A)
    LDI R29, HIGH(B)
    LDI R28, LOW(B)
    LDI R31, HIGH(C)
    LDI R30, LOW(C)

    ; Byte 0 
    LD R16, X+
    LD R17, Y+
    ADD R16, R17
    ST Z+, R16

    ; Byte 1
    LD R16, X+
    LD R17, Y+
    ADC R16, R17
    ST Z+, R16

    ; Byte 2
    LD R16, X+
    LD R17, Y+
    ADC R16, R17
    ST Z+, R16

    ; Byte 3 
    LD R16, X+
    LD R17, Y+
    ADC R16, R17
    ST Z+, R16


    ; 4. ENDEREÇAMENTO INDIRETO COM DESLOCAMENTO (LDD / STD)
    LDI R29, HIGH(A) ; YH
    LDI R28, LOW(A)  ; YL

    ; Byte 0 
    LDD R16, Y+0
    LDD R17, Y+4
    ADD R16, R17
    STD Y+8, R16

    ; Byte 1
    LDD R16, Y+1
    LDD R17, Y+5
    ADC R16, R17
    STD Y+9, R16

    ; Byte 2
    LDD R16, Y+2
    LDD R17, Y+6
    ADC R16, R17
    STD Y+10, R16

    ; Byte 3 
    LDD R16, Y+3
    LDD R17, Y+7
    ADC R16, R17
    STD Y+11, R16

FIM:
    RJMP FIM