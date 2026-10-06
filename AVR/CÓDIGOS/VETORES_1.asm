; =============================================================================
; DESCRIÇÃO:
;   1. Aloca quatro vetores na SRAM: A1 (10 bytes), A2 (10 bytes), A3 (10 bytes) e A4 (3 bytes).
;   2. Inicializa A1 e A2 com a sequência de 1 até 10 usando pós-incremento (ST X+, ST Y+).
;   3. Soma A1 em ordem direta com A2 em ordem inversa (usando pré-decremento -Y) e salva em A3.
;   4. Realiza somas específicas de posições de A2 e A3 usando o modo Indireto com Deslocamento (LDD),
;      armazenando os resultados no vetor A4.
; =============================================================================

.DSEG                        ; Seleciona o segmento de memória de dados (SRAM)
.ORG SRAM_START              ; Define o endereço inicial da SRAM (0x0100 para ATmega328P)

    ; Declaração de espaço na SRAM para os vetores
    A1: .BYTE 10             ; Aloca 10 bytes para A1 (endereços 0x0100 a 0x0109)
    A2: .BYTE 10             ; Aloca 10 bytes para A2 (endereços 0x010A a 0x0113)
    A3: .BYTE 10             ; Aloca 10 bytes para A3 (endereços 0x0114 a 0x011D)
    A4: .BYTE 3              ; Aloca 3 bytes para A4  (endereços 0x011E a 0x0120)

.CSEG                        ; Seleciona o segmento de memória de código (Flash)
.ORG 0x0000                  ; Vetor de Reset
    
    ; Configura o ponteiro X para apontar para o início do vetor A1 (0x0100)
    LDI XL, LOW(A1)          ; Carrega o byte inferior do endereço de A1 em XL (R26)
    LDI XH, HIGH(A1)         ; Carrega o byte superior do endereço de A1 em XH (R27) -> X aponta para A1[0]
    
    ; Configura o ponteiro Y para apontar para o início do vetor A2 (0x010A)
    LDI YL, LOW(A2)          ; Carrega o byte inferior do endereço de A2 em YL (R28)
    LDI YH, HIGH(A2)         ; Carrega o byte superior do endereço de A2 em YH (R29) -> Y aponta para A2[0]

    LDI R16, 1               ; R16 = 1 (Valor inicial a ser gravado nos vetores A1 e A2)
    LDI R17, 10              ; R17 = 10 (Contador de iterações do loop)

; =============================================================================
; BLOCO 1: Inicialização dos Vetores A1 e A2 com a sequência 1 a 10
; =============================================================================
loop1:
    ST X+, R16               ; Armazena R16 no endereço apontado por X e incrementa X (+1) -> A1[i]
    ST Y+, R16               ; Armazena R16 no endereço apontado por Y e incrementa Y (+1) -> A2[i]
    
    INC R16                  ; Incrementa o valor em R16 (1, 2, 3... até 10)
    DEC R17                  ; Decrementa o contador de iterações (R17 = R17 - 1)
    BRNE loop1               ; Salta para 'loop1' se R17 != 0 (repetido 10 vezes)

; =============================================================================
; BLOCO 2: Soma Invertida (A1 em ordem direta + A2 em ordem inversa -> A3)
; =============================================================================
    ; Reposiciona o ponteiro X no início de A1 (0x0100)
    LDI XL, LOW(A1)          ; XL recebe a parte baixa do endereço de A1
    LDI XH, HIGH(A1)         ; XH recebe a parte alta do endereço de A1 -> X aponta para A1[0]

    ; Aponta o ponteiro Y para 1 posição APÓS o fim do vetor A2 (endereço A2 + 10 bytes = 0x0114)
    ; O primeiro pré-decremento (-Y) recuará Y para 0x0113 (A2[9], último elemento de A2)
    LDI YL, LOW(A2 + 10)     ; YL recebe a parte baixa do endereço final de A2 + 10
    LDI YH, HIGH(A2 + 10)    ; YH recebe a parte alta do endereço final de A2 + 10

    ; Configura o ponteiro Z para o início de A3 (0x0114)
    LDI ZL, LOW(A3)          ; ZL recebe a parte baixa do endereço de A3
    LDI ZH, HIGH(A3)         ; ZH recebe a parte alta do endereço de A3 -> Z aponta para A3[0]

    LDI R17, 10              ; Carrega R17 com o contador de 10 iterações para o loop2

loop2:
    LD R16, X+               ; Lê A1[i] para R16 e avança o ponteiro X (+1) em direção ao fim de A1
    LD R18, -Y               ; Decrementa Y em -1 PRIMEIRO (recua) e lê A2 de trás para frente para R18
    ADD R16, R18             ; Soma os dois valores: R16 = A1[i] + A2[9-i] (Resultado sempre 11)
    ST Z+, R16               ; Armazena a soma na posição A3[i] e avança o ponteiro Z (+1)

    DEC R17                  ; Decrementa o contador do laço (R17 = R17 - 1)
    BRNE loop2               ; Repete o laço2 enquanto R17 != 0 (executa 10 vezes)

; =============================================================================
; BLOCO 3: Somas Específicas com Deslocamento (LDD) Armazenadas em A4
; =============================================================================
    ; Reposiciona os ponteiros base para a operação:
    LDI YL, LOW(A2)          ; YL recebe a parte baixa do endereço base de A2
    LDI YH, HIGH(A2)         ; YH recebe a parte alta do endereço base de A2 -> Y fixado na base de A2
    
    LDI ZL, LOW(A3)          ; ZL recebe a parte baixa do endereço base de A3
    LDI ZH, HIGH(A3)         ; ZH recebe a parte alta do endereço base de A3 -> Z fixado na base de A3
    
    LDI XL, LOW(A4)          ; XL recebe a parte baixa do endereço base de A4
    LDI XH, HIGH(A4)         ; XH recebe a parte alta do endereço base de A4 -> X aponta para a base de A4

    ; --- Operação 1: A2[1] + A3[3] -> A4[0] (2 + 11 = 13) ---
    LDD R16, Y+1             ; Lê A2 com deslocamento +1 (A2[1] = 2) para R16
    LDD R18, Z+3             ; Lê A3 com deslocamento +3 (A3[3] = 11) para R18
    ADD R16, R18             ; Soma R16 = 2 + 11 = 13 (0x0D)
    ST X+, R16               ; Armazena 13 em A4[0] e avança o ponteiro X (+1) para A4[1]

    ; --- Operação 2: A2[3] + A3[4] -> A4[1] (4 + 11 = 15) ---
    LDD R16, Y+3             ; Lê A2 com deslocamento +3 (A2[3] = 4) para R16
    LDD R18, Z+4             ; Lê A3 com deslocamento +4 (A3[4] = 11) para R18
    ADD R16, R18             ; Soma R16 = 4 + 11 = 15 (0x0F)
    ST X+, R16               ; Armazena 15 em A4[1] e avança o ponteiro X (+1) para A4[2]

    ; --- Operação 3: A2[5] + A3[7] -> A4[2] (6 + 11 = 17) ---
    LDD R16, Y+5             ; Lê A2 com deslocamento +5 (A2[5] = 6) para R16
    LDD R18, Z+7             ; Lê A3 com deslocamento +7 (A3[7] = 11) para R18
    ADD R16, R18             ; Soma R16 = 6 + 11 = 17 (0x11)
    ST X+, R16               ; Armazena 17 em A4[2]

end:
    RJMP end                 ; Laço infinito para travamento seguro da CPU
