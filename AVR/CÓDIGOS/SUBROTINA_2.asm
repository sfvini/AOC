; =============================================================================
; DESCRIÇÃO:
; 1. inc_32bits: Incrementa a variável de 32 bits apontada pelo registrador X.
; 2. dec_32bits: Decrementa a variável de 32 bits apontada pelo registrador X.
; 3. mov_32bits: Copia a variável de 32 bits apontada por X para Y.
; =============================================================================

.DSEG                        ; Seleciona o segmento de memória de dados (SRAM)
.ORG SRAM_START              ; Define o endereço inicial da SRAM (0x0100 para ATmega328P)
    VAR1 : .BYTE 4           ; Reserva 4 bytes na SRAM para a variável VAR1 (32 bits)
    VAR2 : .BYTE 4           ; Reserva 4 bytes na SRAM para a variável VAR2 (32 bits)

.CSEG                        ; Seleciona o segmento de memória de programa (Flash)
.ORG 0x0000                  ; Vetor de Reset (Endereço 0x0000)
    RJMP START               ; Salto inicial para a rotina principal

START:    
    ; --- 1. Teste da Sub-rotina inc_32bits ---
    LDI R16, 5               ; Carrega o valor imediato 5 no registrador R16
    LDI XL, LOW(VAR1)        ; Carrega o byte baixo do endereço de VAR1 em XL (R26)
    LDI XH, HIGH(VAR1)       ; Carrega o byte alto do endereço de VAR1 em XH (R27) -> X aponta para VAR1
    ST X, R16                ; Armazena o valor 5 no byte menos significativo (LSB) de VAR1
    CALL inc_32bits          ; Executa o incremento na variável apontada por X
    
    ; --- 2. Teste da Sub-rotina dec_32bits ---
    CALL dec_32bits          ; Executa o decremento na variável apontada por X
    
    ; --- 3. Carga de Dados de Teste (0xDDCCBBAA) em VAR1 ---
    LDI R16, 0XAA            ; Byte 0 (LSB - Menos significativo) = 0xAA
    ST X+, R16               ; Grava 0xAA em VAR1[0] e avança o ponteiro X para VAR1[1]
    LDI R16, 0XBB            ; Byte 1 = 0xBB
    ST X+, R16               ; Grava 0xBB em VAR1[1] e avança o ponteiro X para VAR1[2]
    LDI R16, 0XCC            ; Byte 2 = 0xCC
    ST X+, R16               ; Grava 0xCC em VAR1[2] e avança o ponteiro X para VAR1[3]
    LDI R16, 0XDD            ; Byte 3 (MSB - Mais significativo) = 0xDD
    ST X+, R16               ; Grava 0xDD em VAR1[3] e avança o ponteiro X
    
    ; --- 4. Re-inicialização dos Ponteiros para a Cópia (mov_32bits) ---
    LDI XL, LOW(VAR1)        ; Re-aponta a parte baixa do ponteiro X para o início de VAR1
    LDI XH, HIGH(VAR1)       ; Re-aponta a parte alta do ponteiro X para o início de VAR1
    
    LDI YL, LOW(VAR2)        ; Aponta a parte baixa do ponteiro Y para o início de VAR2 (R28)
    LDI YH, HIGH(VAR2)       ; Aponta a parte alta do ponteiro Y para o início de VAR2 (R29)
    
    CALL mov_32bits          ; Copia os 4 bytes de VAR1 (apontada por X) para VAR2 (apontada por Y)
    
FIM:
    RJMP START               ; Retorna ao início do programa para manter a execução contínua

; =============================================================================
; SUB-ROTINAS MODULARES
; =============================================================================

; -----------------------------------------------------------------------------
; Sub-rotina: inc_32bits
; Descrição : Incrementa o conteúdo da variável apontada pelo ponteiro X.
; Parâmetros: Registrador X = Ponteiro para a posição inicial da variável.
; Preserva  : Preserva o registrador R17 e as flags do Registrador de Status (SREG).
; -----------------------------------------------------------------------------
inc_32bits:
    PUSH R17                 ; Salva o registrador de trabalho R17 na pilha
    IN R17, SREG             ; Lê o estado atual das flags do Registrador de Status (SREG)
    PUSH R17                 ; Salva a cópia do SREG na pilha
    
    LD R17, X                ; Lê o byte da posição atual de X para o registrador R17
    INC R17                  ; Incrementa em +1 o valor em R17
    ST X, R17                ; Sobreescreve o valor incrementado na mesma posição da SRAM
    
    POP R17                  ; Desempilha e recupera o estado original do SREG
    OUT SREG, R17            ; Restaura as flags do SREG no sistema
    POP R17                  ; Restaura o valor original do registrador R17 da pilha
    
    RET                      ; Retorna ao programa principal

; -----------------------------------------------------------------------------
; Sub-rotina: dec_32bits
; Descrição : Decrementa o conteúdo da variável apontada pelo ponteiro X.
; Parâmetros: Registrador X = Ponteiro para a posição inicial da variável.
; Preserva  : Preserva o registrador R17 e as flags do Registrador de Status (SREG).
; -----------------------------------------------------------------------------
dec_32bits:
    PUSH R17                 ; Salva o registrador de trabalho R17 na pilha
    IN R17, SREG             ; Lê o estado atual das flags do SREG
    PUSH R17                 ; Salva a cópia do SREG na pilha
    
    LD R17, X                ; Lê o byte da posição atual de X para R17
    DEC R17                  ; Decrementa em -1 o valor em R17
    ST X, R17                ; Sobreescreve o valor decrementado na mesma posição da SRAM
    
    POP R17                  ; Desempilha e recupera o estado original do SREG
    OUT SREG, R17            ; Restaura as flags do SREG no sistema
    POP R17                  ; Restaura o valor original do registrador R17
    RET                      ; Retorna ao programa principal

; -----------------------------------------------------------------------------
; Sub-rotina: mov_32bits
; Descrição : Copia 4 bytes contíguos da variável apontada por X para Y.
; Parâmetros: Registrador X = Ponteiro de origem (origem)
;             Registrador Y = Ponteiro de destino (destino)
; Preserva  : Preserva R17, R18 e o Registrador de Status (SREG).
; -----------------------------------------------------------------------------
mov_32bits:
    PUSH R17                 ; Salva o registrador R17 na pilha
    PUSH R18                 ; Salva o registrador R18 na pilha
    IN R17, SREG             ; Lê o estado atual das flags do SREG
    PUSH R17                 ; Salva a cópia do SREG na pilha
    
    LDI R17, 4               ; Inicializa o contador de loop em 4 bytes (32 bits)

loop_mov_32bits:
    LD R18, X+               ; Lê o byte de X (origem), grava em R18 e incrementa X (+1)
    ST Y+, R18               ; Grava R18 no endereço Y (destino) e incrementa Y (+1)
    DEC R17                  ; Decrementa o contador do laço
    BRNE loop_mov_32bits     ; Continua o laço se R17 != 0 (executa 4 vezes)
    
    POP R17                  ; Desempilha a cópia do SREG
    OUT SREG, R17            ; Restaura o registrador SREG
    POP R18                  ; Restaura o valor original de R18
    POP R17                  ; Restaura o valor original de R17
    RET                      ; Retorna ao programa principal
