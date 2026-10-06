; =============================================================================
; DESCRIÇÃO:
; 1. Declarar dois vetores com 8 posições de 8 bits (V0 e V1) e um vetor com 4 posições (V2).
; 2. Inicializar V0 com os valores de 8 até 15.
; 3. Copiar V0 de trás para frente para V1 (usando pré-decremento).
; 4. Somar as posições pares de V0 com as posições ímpares de V1, gravando o resultado em V2:
;      - V2(0) = V0(0) + V1(1) =  8 + 14 = 22
;      - V2(1) = V0(2) + V1(3) = 10 + 12 = 22
;      - V2(2) = V0(4) + V1(5) = 12 + 10 = 22
;      - V2(3) = V0(6) + V1(7) = 14 + 8  = 22
; =============================================================================

.DSEG                        ; Seleciona o segmento de memória RAM (Data Segment)
.ORG SRAM_START              ; Define o endereço inicial da SRAM (0x0100 para o ATmega328P)
    V0 : .BYTE 8             ; Reserva 8 bytes contíguos na SRAM para o vetor V0 (0x0100 a 0x0107)
    V1 : .BYTE 8             ; Reserva 8 bytes contíguos na SRAM para o vetor V1 (0x0108 a 0x010F)
    V2 : .BYTE 4             ; Reserva 4 bytes contíguos na SRAM para o vetor V2 (0x0110 a 0x0113)

.CSEG                        ; Seleciona o segmento de memória Flash (Code Segment)
.ORG 0x0000                  ; Vetor de Reset do microcontrolador
    RJMP START               ; Salto incondicional para o rótulo inicial de execução

START:
    ; --- Inicialização dos Ponteiros de Endereçamento ---
    LDI XL, LOW(V0)          ; Carrega a parte baixa do endereço base de V0 no registrador XL (R26)
    LDI XH, HIGH(V0)         ; Carrega a parte alta do endereço base de V0 no registrador XH (R27) -> X aponta para V0 (0x0100)
    
    LDI YL, LOW(V1)          ; Carrega a parte baixa do endereço base de V1 no registrador YL (R28)
    LDI YH, HIGH(V1)         ; Carrega a parte alta do endereço base de V1 no registrador YH (R29) -> Y aponta para V1 (0x0108)

; =============================================================================
; 1. INICIALIZAÇÃO DE V0 (Valores de 8 até 15)
; Utiliza o modo de endereçamento indireto com pós-incremento (ST X+, R16).
; =============================================================================
init_v0:
    LDI R16, 8               ; Carrega o valor inicial 8 em R16 (servirá como dado e comparador)

loop_init_v0:
    ST X+, R16               ; Grava o valor atual de R16 na posição apontada por X e incrementa X (+1)
    INC R16                  ; Incrementa o valor numérico a ser gravado (8, 9, 10... 15)
    CPI R16, 16              ; Compara R16 com 16 (para interromper o laço quando R16 atingir 16)
    BRNE loop_init_v0        ; Salta de volta para loop_init_v0 enquanto R16 != 16
                             ; Ao final deste laço, V0 contém [8, 9, 10, 11, 12, 13, 14, 15]
                             ; O ponteiro X fica posicionado exatamente em V0 + 8 (0x0108, início de V1)

; =============================================================================
; 2. CÓPIA INVERTIDA DE V0 PARA V1 (De trás para frente)
; Como X está no endereço imediatamente APÓS V0[7], utiliza-se o modo
; Indireto com Pré-Decremento (LD R17, -X) para recuar e ler de trás para frente.
; =============================================================================
copy_rev_v0_to_v1:
    LDI R16, 8               ; Carrega o contador do laço de repetição (8 iterações)

loop_copy_rev_v0_to_v1:
    LD R17, -X               ; Decrementa X PRIMEIRO (aponta para V0[7]) e lê o byte para R17
    ST Y+, R17               ; Grava o byte em V1[i] e avança o ponteiro Y (+1)
    DEC R16                  ; Decrementa o contador de iterações
    BRNE loop_copy_rev_v0_to_v1 ; Continua o laço enquanto R16 != 0
                             ; Ao final deste laço, V1 contém [15, 14, 13, 12, 11, 10, 9, 8]

; =============================================================================
; 3. SOMA DAS POSIÇÕES PARES DE V0 COM AS ÍMPARES DE V1 SALVAS EM V2
; Utiliza o Modo Indireto com Deslocamento (LDD R, Y+q / Z+q) para acessar
; índices específicos de V0 e V1 sem alterar os ponteiros base.
; =============================================================================
sum_parV0_imparV1_to_V2:
    ; Configura os ponteiros base para a operação:
    ; Y -> Ponteiro para a base do vetor V0 (0x0100)
    ; Z -> Ponteiro para a base do vetor V1 (0x0108)
    ; X -> Ponteiro para a base do vetor V2 (0x0110)
    
    LDI YL, LOW(V0)          ; Carrega byte baixo de V0 em YL (R28)
    LDI YH, HIGH(V0)         ; Carrega byte alto de V0 em YH (R29) -> Y fixado na base de V0
    
    LDI ZL, LOW(V1)          ; Carrega byte baixo de V1 em ZL (R30)
    LDI ZH, HIGH(V1)         ; Carrega byte alto de V1 em ZH (R31) -> Z fixado na base de V1
    
    LDI XL, LOW(V2)          ; Carrega byte baixo de V2 em XL (R26)
    LDI XH, HIGH(V2)         ; Carrega byte alto de V2 em XH (R27) -> X aponta para a base de V2
    
    ; --- Operação 1: V2(0) = V0(0) + V1(1) -> 8 + 14 = 22 ---
    LDD R17, Y+0             ; Lê V0[0] usando offset +0 a partir de Y
    LDD R18, Z+1             ; Lê V1[1] usando offset +1 a partir de Z
    ADD R17, R18             ; Soma os dois valores (8 + 14 = 22)
    ST X+, R17               ; Grava em V2[0] e avança o ponteiro X (+1) para V2[1]
    
    ; --- Operação 2: V2(1) = V0(2) + V1(3) -> 10 + 12 = 22 ---
    LDD R17, Y+2             ; Lê V0[2] usando offset +2 a partir de Y
    LDD R18, Z+3             ; Lê V1[3] usando offset +3 a partir de Z
    ADD R17, R18             ; Soma os dois valores (10 + 12 = 22)
    ST X+, R17               ; Grava em V2[1] e avança o ponteiro X (+1) para V2[2]
    
    ; --- Operação 3: V2(2) = V0(4) + V1(5) -> 12 + 10 = 22 ---
    LDD R17, Y+4             ; Lê V0[4] usando offset +4 a partir de Y
    LDD R18, Z+5             ; Lê V1[5] usando offset +5 a partir de Z
    ADD R17, R18             ; Soma os dois valores (12 + 10 = 22)
    ST X+, R17               ; Grava em V2[2] e avança o ponteiro X (+1) para V2[3]
    
    ; --- Operação 4: V2(3) = V0(6) + V1(7) -> 14 + 8 = 22 ---
    LDD R17, Y+6             ; Lê V0[6] usando offset +6 a partir de Y
    LDD R18, Z+7             ; Lê V1[7] usando offset +7 a partir de Z
    ADD R17, R18             ; Soma os dois valores (14 + 8 = 22)
    ST X+, R17               ; Grava em V2[3]
    
    ; Resultado final esperado: Todas as 4 posições de V2 contêm o valor 22 (0x16 em hex).

FIM:
    RJMP START               ; Laço infinito para manter a execução do programa em ciclo continuo
