;    Faça um programa que some duas variáveis (A e B) e armazena o resultado em uma terceira (C)
;    Considere todas as variáveis de 16 bits.
;    Considere as varáveis A, B e C armazenadas sequencialmente a partir do primeiro endereço da memória SRAM.
;    Faça 4 implementações utilizando os seguintes modos de endereçamento: Direto, Indireto (sem incrementar), Indireto com Pós-incremento e Indireto com Deslocamento.

.DSEG ; Segmento de memória RAM
.ORG SRAM_START ; 0x0100 para o ATmega328P
    A: .BYTE 2
    B: .BYTE 2 
    C: .BYTE 2 

.CSEG ; Segmento da memória Flash (programa)

START:
;   DIRETO (sem ponteiros) - LDS e STS
    
    ; Byte 0 
    LDS R16, A ; Lê o valor de A e envia para R16
    LDS R17, B ; Lê o valor de B e envia para R17
    ADD R16, R17 ; Faz a soma e o resultado fica em R16
    STS C, R16 ; Guarda o resultado de R16 em C
    
    ; Byte 1
    LDS R16, A+1
    LDS R17, B+1
    ADC R16, R17 ; Como é 16 bits, pode "sobrar" um valor da soma, o ADC soma esse valor (carry) e garante que ele não vai ser perdido 
    STS C+1, R16
    
;   INDIRETO (com ponteiros) - LD e ST, X, Y e Z
    
    ; X -> A
    ; Y -> B
    ; Z -> C
    
    ; Como são endereços de 16 bits, e o ATmega328P é um microcontrolador de 8 bits, é necessário "cortar" o endereço ao meio
    ; R27/R29/R31 fica com a parte alta (HIGH), que fica na esquerda e é a mais significativa 
    ; R26/R28/R30 fica com a parte baixa (LOW), que fica na direita e é a menos significativa 

    LDI XH, HIGH(A) ; R27
    LDI XL, LOW(A)  ; R26
    
    LDI YH, HIGH(B) ; R29
    LDI YL, LOW(B)  ; R28
    
    LDI ZH, HIGH(C) ; R31
    LDI ZL, LOW(C)  ; R30
