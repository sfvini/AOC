; =============================================================================
; PROGRAMA: Soma de 16 bits (C = A + B) em 4 Modos de Endereçamento (ATmega328P)
; Nome do Arquivo: SOMA16BITS.asm
; =============================================================================
; DESCRIÇÃO:
;   Soma duas variáveis de 16 bits (A e B) e armazena o resultado em C (16 bits).
;   Implementa os 4 modos de endereçamento da SRAM:
;   1. Direto (LDS / STS)
;   2. Indireto Simples (LD / ST sem incremento)
;   3. Indireto com Pós-incremento (LD X+ / ST Z+)
;   4. Indireto com Deslocamento (LDD / STD)
; =============================================================================

.DSEG                        ; Seleciona o segmento de memória RAM (Dados)
.ORG SRAM_START              ; Define o endereço inicial da SRAM (0x0100 no ATmega328P)
    A: .BYTE 2               ; Reserva 2 bytes para a variável A (16 bits: 0x0100 e 0x0101)
    B: .BYTE 2               ; Reserva 2 bytes para a variável B (16 bits: 0x0102 e 0x0103)
    C: .BYTE 2               ; Reserva 2 bytes para a variável C (16 bits: 0x0104 e 0x0105)

.CSEG                        ; Seleciona o segmento de memória Flash (Programa)
.ORG 0x0000                  ; Vetor de Reset
    RJMP START               ; Salta para o início da execução

START:
    ; --- Inicialização do Stack Pointer (Pilha) ---
    LDI R16, HIGH(RAMEND)    ; Carrega o byte alto de RAMEND (0x08)
    OUT SPH, R16             ; Configura SPH
    LDI R16, LOW(RAMEND)     ; Carrega o byte baixo de RAMEND (0xFF)
    OUT SPL, R16             ; Configura SPL (SP aponta para 0x08FF)

; =============================================================================
; MODO 1: DIRETO (sem ponteiros) - LDS e STS
; =============================================================================
    ; Byte 0 (LSB - Byte Menos Significativo)
    LDS R16, A               ; Lê o valor do Byte 0 de A (0x0100) e envia para R16
    LDS R17, B               ; Lê o valor do Byte 0 de B (0x0102) e envia para R17
    ADD R16, R17             ; Soma simples (R16 = R16 + R17). O resultado fica em R16
    STS C, R16               ; Guarda o resultado de R16 no Byte 0 de C (0x0104)
    
    ; Byte 1 (MSB - Byte Mais Significativo)
    LDS R16, A+1             ; Lê o valor do Byte 1 de A (0x0101) e envia para R16
    LDS R17, B+1             ; Lê o valor do Byte 1 de B (0x0103) e envia para R17
    ADC R16, R17             ; Soma com Carry (R16 = R16 + R17 + C) para propagar o "vai-um"
    STS C+1, R16             ; Guarda o resultado de R16 no Byte 1 de C (0x0105)

; =============================================================================
; MODO 2: INDIRETO SIMPLES (com ponteiros sem incremento) - LD e ST
; =============================================================================
    ; Como os endereços são de 16 bits e os registradores são de 8 bits:
    ; Ponteiro X (R27:R26) -> Aponta para A
    ; Ponteiro Y (R29:R28) -> Aponta para B
    ; Ponteiro Z (R31:R30) -> Aponta para C

    LDI XH, HIGH(A)          ; Carrega a parte alta do endereço de A no registrador XH (R27)
    LDI XL, LOW(A)           ; Carrega a parte baixa do endereço de A no registrador XL (R26)
    
    LDI YH, HIGH(B)          ; Carrega a parte alta do endereço de B no registrador YH (R29)
    LDI YL, LOW(B)           ; Carrega a parte baixa do endereço de B no registrador YL (R28)
    
    LDI ZH, HIGH(C)          ; Carrega a parte alta do endereço de C no registrador ZH (R31)
    LDI ZL, LOW(C)           ; Carrega a parte baixa do endereço de C no registrador ZL (R30)

    ; Byte 0 (LSB)
    LD R16, X                ; Lê o conteúdo do endereço apontado por X (A[0]) para R16
    LD R17, Y                ; Lê o conteúdo do endereço apontado por Y (B[0]) para R17
    ADD R16, R17             ; Soma simples dos bytes menos significativos
    ST Z, R16                ; Grava o resultado no endereço apontado por Z (C[0])

    ; Avança manualmente os ponteiros para o Byte 1 (sem autoincremento)
    ADIW XL, 1               ; Soma 1 ao par X (X aponta para A+1)
    ADIW YL, 1               ; Soma 1 ao par Y (Y aponta para B+1)
    ADIW ZL, 1               ; Soma 1 ao par Z (Z aponta para C+1)

    ; Byte 1 (MSB)
    LD R16, X                ; Lê A[1]
    LD R17, Y                ; Lê B[1]
    ADC R16, R17             ; Soma com Carry para propagar o transporte
    ST Z, R16                ; Grava o resultado em C[1]

; =============================================================================
; MODO 3: INDIRETO COM PÓS-INCREMENTO - LD X+ e ST Z+
; =============================================================================
    ; Reinicializa os ponteiros na base das variáveis
    LDI XH, HIGH(A) \ LDI XL, LOW(A)
    LDI YH, HIGH(B) \ LDI YL, LOW(B)
    LDI ZH, HIGH(C) \ LDI ZL, LOW(C)

    ; Byte 0 (LSB)
    LD R16, X+               ; Lê A[0] e incrementa o ponteiro X (+1) automaticamente
    LD R17, Y+               ; Lê B[0] e incrementa o ponteiro Y (+1) automaticamente
    ADD R16, R17             ; Soma simples
    ST Z+, R16               ; Grava C[0] e incrementa o ponteiro Z (+1) automaticamente

    ; Byte 1 (MSB)
    LD R16, X+               ; Lê A[1] (já no endereço incrementado A+1)
    LD R17, Y+               ; Lê B[1] (já no endereço incrementado B+1)
    ADC R16, R17             ; Soma com Carry
    ST Z+, R16               ; Grava C[1]

; =============================================================================
; MODO 4: INDIRETO COM DESLOCAMENTO - LDD e STD (Usando o ponteiro Y)
; =============================================================================
    ; LDD/STD operam apenas com os ponteiros Y e Z.
    ; Fixamos o ponteiro Y na base do primeiro endereço (A = 0x0100):
    ;   A está no deslocamento Y+0 (LSB) e Y+1 (MSB)
    ;   B está no deslocamento Y+2 (LSB) e Y+3 (MSB)
    ;   C está no deslocamento Y+4 (LSB) e Y+5 (MSB)

    LDI YH, HIGH(A)          ; Carrega parte alta do endereço base de A
    LDI YL, LOW(A)           ; Carrega parte baixa do endereço base de A -> Y fixo em 0x0100

    ; Byte 0 (LSB)
    LDD R16, Y+0             ; Lê A[0] usando offset +0
    LDD R17, Y+2             ; Lê B[0] usando offset +2
    ADD R16, R17             ; Soma simples
    STD Y+4, R16             ; Grava em C[0] usando offset +4

    ; Byte 1 (MSB)
    LDD R16, Y+1             ; Lê A[1] usando offset +1
    LDD R17, Y+3             ; Lê B[1] usando offset +3
    ADC R16, R17             ; Soma com Carry
    STD Y+5, R16             ; Grava em C[1] usando offset +5

FIM:
    RJMP FIM                 ; Laço infinito para encerramento seguro
