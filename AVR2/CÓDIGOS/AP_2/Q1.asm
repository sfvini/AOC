; Questão 1: GPIO
; - Implementar um sistema com dois botões, ALTERNADO (PD3) e JUNTOS (PD2), e dois LEDs, L1 (PD1) e o L0 (PD0).
; - Enquanto o botão ALTERNADO estiver pressionado, os LEDs devem piscar alternadamente a cada 2s.
; - Enquanto o botão JUNTOS estiver pressionado, os LEDs devem piscar juntos a cada 1s.
; - Se nenhum botão for pressionado, os LEDs devem permanecer apagados.
; - Considere que os dois botões nunca serão pressionados juntos.

.INCLUDE <m328Pdef.inc>

; --- Definições dos Pinos ---
.EQU L0 = PORTD0         ; LED 0 no pino PD0
.EQU L1 = PORTD1         ; LED 1 no pino PD1
.EQU BT_JUN = PIND2      ; Botão JUNTOS no pino PD2
.EQU BT_ALT = PIND3      ; Botão ALTERNADO no pino PD3

; --- Registradores Auxiliares ---
.DEF AUX = R16
.DEF R_DEL1 = R17        ; Usado para o tempo do delay
.DEF R_DEL2 = R18
.DEF R_DEL3 = R19

.CSEG
.ORG 0x0000
    RJMP SETUP

SETUP:
    ; Configura a Pilha (necessário para RCALL)
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; Configura LEDs (PD0 e PD1) como SAÍDAS (1)
    SBI DDRD, L0
    SBI DDRD, L1

    ; Configura Botões (PD2 e PD3) como ENTRADAS (0)
    CBI DDRD, BT_JUN
    CBI DDRD, BT_ALT

    ; Liga Resistores de Pull-up dos botões (1)
    SBI PORTD, BT_JUN
    SBI PORTD, BT_ALT

    ; Inicia LEDs apagados (Apaga com '1')
    SBI PORTD, L0
    SBI PORTD, L1

MAIN:
    ; Verifica se o Botão ALTERNADO foi pressionado (Gera 0)
    SBIC PIND, BT_ALT    ; Se o pino for 1 (solto), pula a próxima linha
    RJMP VERIFICA_JUN    ; Se pulou, vai testar o outro botão
    RJMP MODO_ALTER      ; Se não pulou (é 0), entra no modo alternado

VERIFICA_JUN:
    ; Verifica se o Botão JUNTOS foi pressionado (Gera 0)
    SBIC PIND, BT_JUN    ; Se o pino for 1 (solto), pula a próxima linha
    RJMP APAGA_TUDO      ; Se pulou, significa que nenhum está apertado
    RJMP MODO_JUNTOS     ; Se não pulou (é 0), entra no modo juntos

APAGA_TUDO:
    SBI PORTD, L0        ; Desliga L0
    SBI PORTD, L1        ; Desliga L1
    RJMP MAIN            ; Volta para o começo

; --- Modos de Piscar ---

MODO_ALTER:
    CBI PORTD, L0        ; Liga L0 (com 0)
    SBI PORTD, L1        ; Desliga L1
    LDI R_DEL1, 160      ; Delay de ~2s
    RCALL DELAY_PROG

    SBI PORTD, L0        ; Desliga L0
    CBI PORTD, L1        ; Liga L1 (com 0)
    LDI R_DEL1, 160      ; Delay de ~2s
    RCALL DELAY_PROG
    RJMP MAIN

MODO_JUNTOS:
    CBI PORTD, L0        ; Liga Ambos
    CBI PORTD, L1
    LDI R_DEL1, 80       ; Delay de ~1s
    RCALL DELAY_PROG

    SBI PORTD, L0        ; Desliga Ambos
    SBI PORTD, L1
    LDI R_DEL1, 80       ; Delay de ~1s
    RCALL DELAY_PROG
    RJMP MAIN

; --- Sub-rotina de Delay ---
DELAY_PROG:
    PUSH R_DEL1
    PUSH R_DEL2
    PUSH R_DEL3
DL_LOOP1: LDI R_DEL2, 200
DL_LOOP2: LDI R_DEL3, 250
DL_LOOP3: NOP
    DEC R_DEL3
    BRNE DL_LOOP3
    DEC R_DEL2
    BRNE DL_LOOP2
    DEC R_DEL1
    BRNE DL_LOOP1
    POP R_DEL3
    POP R_DEL2
    POP R_DEL1
    RET
