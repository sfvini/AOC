; =============================================================================
; DESCRIÇÃO:
;   Soma duas variáveis de 32 bits (A e B) e armazena o resultado em C (32 bits).
;   Demonstra as 4 implementações dos modos de endereçamento da SRAM:
;   1. Direto (LDS / STS)
;   2. Indireto Simples (LD / ST com ADIW)
;   3. Indireto com Pós-incremento (LD X+ / ST Z+)
;   4. Indireto com Deslocamento (LDD / STD com ponteiro Y)
; =============================================================================

.INCLUDE <m328Pdef.inc>      ; Inclui o arquivo de definições de registradores do ATmega328P

.DSEG                        ; Seleciona o segmento de memória de dados (SRAM)
.ORG SRAM_START              ; Define o endereço inicial da SRAM (0x0100 no ATmega328P)
    A: .BYTE 4               ; Reserva 4 bytes na SRAM para a variável A (32 bits: 0x0100 a 0x0103)
    B: .BYTE 4               ; Reserva 4 bytes na SRAM para a variável B (32 bits: 0x0104 a 0x0107)
    C: .BYTE 4               ; Reserva 4 bytes na SRAM para a variável C (32 bits: 0x0108 a 0x010B)

.CSEG                        ; Seleciona o segmento de memória de programa (Flash)
.ORG 0x0000                  ; Vetor de Reset
    RJMP START               ; Salto incondicional para o início do programa

START:

; =============================================================================
; 1. ENDEREÇAMENTO DIRETO (LDS / STS)
; Operação realizada utilizando endereços diretos absolutos na SRAM.
; =============================================================================
    ; --- Byte 0 (LSB - Byte Menos Significativo) ---
    LDS R16, A               ; Carrega o Byte 0 de A (endereço 0x0100) em R16
    LDS R17, B               ; Carrega o Byte 0 de B (endereço 0x0104) em R17
    ADD R16, R17             ; Soma simples (R16 = R16 + R17). Define a flag Carry 'C' em caso de estouro
    STS C, R16               ; Grava o resultado no Byte 0 de C (endereço 0x0108)

    ; --- Byte 1 ---
    LDS R16, A+1             ; Carrega o Byte 1 de A (0x0101) em R16
    LDS R17, B+1             ; Carrega o Byte 1 de B (0x0105) em R17
    ADC R16, R17             ; Soma com Carry (R16 = R16 + R17 + C) para propagar o "vai-um"
    STS C+1, R16             ; Grava o resultado no Byte 1 de C (0x0109)

    ; --- Byte 2 ---
    LDS R16, A+2             ; Carrega o Byte 2 de A (0x0102) em R16
    LDS R17, B+2             ; Carrega o Byte 2 de B (0x0106) em R17
    ADC R16, R17             ; Soma com Carry propagando o transporte acumulado
    STS C+2, R16             ; Grava o resultado no Byte 2 de C (0x010A)

    ; --- Byte 3 (MSB - Byte Mais Significativo) ---
    LDS R16, A+3             ; Carrega o Byte 3 de A (0x0103) em R16
    LDS R17, B+3             ; Carrega o Byte 3 de B (0x0107) em R17
    ADC R16, R17             ; Soma com Carry propagando o transporte acumulado
    STS C+3, R16             ; Grava o resultado no Byte 3 de C (0x010B)


; =============================================================================
; 2. ENDEREÇAMENTO INDIRETO SIMPLES (SEM INCREMENTO AUTOMÁTICO)
; Utiliza os pares registradores ponteiro X (R27:R26), Y (R29:R28) e Z (R31:R30).
; =============================================================================
    ; Aponta X para a variável A, Y para B e Z para C
    LDI R27, HIGH(A)         ; Carrega a parte alta do endereço de A em XH (R27)
    LDI R26, LOW(A)          ; Carrega a parte baixa do endereço de A em XL (R26) -> X aponta para 0x0100
    
    LDI R29, HIGH(B)         ; Carrega a parte alta do endereço de B em YH (R29)
    LDI R28, LOW(B)          ; Carrega a parte baixa do endereço de B em YL (R28) -> Y aponta para 0x0104
    
    LDI R31, HIGH(C)         ; Carrega a parte alta do endereço de C em ZH (R31)
    LDI R30, LOW(C)          ; Carrega a parte baixa do endereço de C em ZL (R30) -> Z aponta para 0x0108

    ; --- Byte 0 (LSB) ---
    LD R16, X                ; Lê o byte da SRAM no endereço apontado por X (A[0]) para R16
    LD R17, Y                ; Lê o byte da SRAM no endereço apontado por Y (B[0]) para R17
    ADD R16, R17             ; Soma simples dos bytes menos significativos
    ST Z, R16                ; Grava o resultado da soma no endereço apontado por Z (C[0])

    ; Incrementa manualmente os registradores ponteiro para avançar ao Byte 1
    ADIW R26, 1              ; Incrementa o par X (R27:R26) em +1 (X aponta para A+1)
    ADIW R28, 1              ; Incrementa o par Y (R29:R28) em +1 (Y aponta para B+1)
    ADIW R30, 1              ; Incrementa o par Z (R31:R30) em +1 (Z aponta para C+1)

    ; --- Byte 1 ---
    LD R16, X                ; Lê A[1]
    LD R17, Y                ; Lê B[1]
    ADC R16, R17             ; Soma com Carry
    ST Z, R16                ; Grava em C[1]

    ; Incrementa manualmente os registradores ponteiro para avançar ao Byte 2
    ADIW R26, 1              ; X aponta para A+2
    ADIW R28, 1              ; Y aponta para B+2
    ADIW R30, 1              ; Z aponta para C+2

    ; --- Byte 2 ---
    LD R16, X                ; Lê A[2]
    LD R17, Y                ; Lê B[2]
    ADC R16, R17             ; Soma com Carry
    ST Z, R16                ; Grava em C[2]

    ; Incrementa manualmente os registradores ponteiro para avançar ao Byte 3
    ADIW R26, 1              ; X aponta para A+3
    ADIW R28, 1              ; Y aponta para B+3
    ADIW R30, 1              ; Z aponta para C+3

    ; --- Byte 3 (MSB) ---
    LD R16, X                ; Lê A[3]
    LD R17, Y                ; Lê B[3]
    ADC R16, R17             ; Soma com Carry
    ST Z, R16                ; Grava em C[3]


; =============================================================================
; 3. ENDEREÇAMENTO INDIRETO COM PÓS-INCREMENTO (LD X+ / ST Z+)
; Lê ou escreve na SRAM e avança o ponteiro (+1) automaticamente em 1 único ciclo.
; =============================================================================
    ; Reinicializa os ponteiros no início de cada variável
    LDI R27, HIGH(A)         ; XH
    LDI R26, LOW(A)          ; XL -> Ponteiro X aponta para A (0x0100)
    LDI R29, HIGH(B)         ; YH
    LDI R28, LOW(B)          ; YL -> Ponteiro Y aponta para B (0x0104)
    LDI R31, HIGH(C)         ; ZH
    LDI R30, LOW(C)          ; ZL -> Ponteiro Z aponta para C (0x0108)

    ; --- Byte 0 (LSB) ---
    LD R16, X+               ; Lê A[0] e incrementa o ponteiro X (+1) automaticamente
    LD R17, Y+               ; Lê B[0] e incrementa o ponteiro Y (+1) automaticamente
    ADD R16, R17             ; Soma simples
    ST Z+, R16               ; Grava C[0] e incrementa o ponteiro Z (+1) automaticamente

    ; --- Byte 1 ---
    LD R16, X+               ; Lê A[1] e avança X
    LD R17, Y+               ; Lê B[1] e avança Y
    ADC R16, R17             ; Soma com Carry
    ST Z+, R16               ; Grava C[1] e avança Z

    ; --- Byte 2 ---
    LD R16, X+               ; Lê A[2] e avança X
    LD R17, Y+               ; Lê B[2] e avança Y
    ADC R16, R17             ; Soma com Carry
    ST Z+, R16               ; Grava C[2] e avança Z

    ; --- Byte 3 (MSB) ---
    LD R16, X+               ; Lê A[3] e avança X
    LD R17, Y+               ; Lê B[3] e avança Y
    ADC R16, R17             ; Soma com Carry
    ST Z+, R16               ; Grava C[3] e avança Z


; =============================================================================
; 4. ENDEREÇAMENTO INDIRETO COM DESLOCAMENTO (LDD / STD)
; Utiliza um único ponteiro fixo (Y = 0x0100) e acessa posições via offset constante.
; Mapeamento em relação a Y (0x0100):
;   - Variável A (0x0100..0x0103): Y+0, Y+1, Y+2, Y+3
;   - Variável B (0x0104..0x0107): Y+4, Y+5, Y+6, Y+7
;   - Variável C (0x0108..0x010B): Y+8, Y+9, Y+10, Y+11
; =============================================================================
    LDI R29, HIGH(A)         ; YH (R29)
    LDI R28, LOW(A)          ; YL (R28) -> Ponteiro Y fixado no endereço base 0x0100

    ; --- Byte 0 (LSB) ---
    LDD R16, Y+0             ; Lê A[0] no deslocamento Y+0 (0x0100)
    LDD R17, Y+4             ; Lê B[0] no deslocamento Y+4 (0x0104)
    ADD R16, R17             ; Soma simples
    STD Y+8, R16             ; Grava em C[0] no deslocamento Y+8 (0x0108)

    ; --- Byte 1 ---
    LDD R16, Y+1             ; Lê A[1] no deslocamento Y+1 (0x0101)
    LDD R17, Y+5             ; Lê B[1] no deslocamento Y+5 (0x0105)
    ADC R16, R17             ; Soma com Carry
    STD Y+9, R16             ; Grava em C[1] no deslocamento Y+9 (0x0109)

    ; --- Byte 2 ---
    LDD R16, Y+2             ; Lê A[2] no deslocamento Y+2 (0x0102)
    LDD R17, Y+6             ; Lê B[2] no deslocamento Y+6 (0x0106)
    ADC R16, R17             ; Soma com Carry
    STD Y+10, R16            ; Grava em C[2] no deslocamento Y+10 (0x010A)

    ; --- Byte 3 (MSB) ---
    LDD R16, Y+3             ; Lê A[3] no deslocamento Y+3 (0x0103)
    LDD R17, Y+7             ; Lê B[3] no deslocamento Y+7 (0x0107)
    ADC R16, R17             ; Soma com Carry
    STD Y+11, R16            ; Grava em C[3] no deslocamento Y+11 (0x010B)

FIM:
    RJMP FIM                 ; Laço infinito para travamento seguro da CPU
