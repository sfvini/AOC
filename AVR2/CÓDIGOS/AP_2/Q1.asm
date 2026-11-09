; Questão 1: GPIO
; - Implementar um sistema com dois botões, ALTERNADO (PD3) e JUNTOS (PD2), e dois LEDs, L1 (PD1) e o L0 (PD0).
; - Enquanto o botão ALTERNADO estiver pressionado, os LEDs devem piscar alternadamente a cada 2s.
; - Enquanto o botão JUNTOS estiver pressionado, os LEDs devem piscar juntos a cada 1s.
; - Se nenhum botão for pressionado, os LEDs devem permanecer apagados.
; - Considere que os dois botões nunca serão pressionados juntos.

.INCLUDE <m328Pdef.inc>

.DEF AUX = R16
.DEF R_DEL1 = R17
.DEF R_DEL2 = R18
.DEF R_DEL3 = R19

.CSEG
.ORG 0x0000
    RJMP INICIO

INICIO:
    ; Configura a Pilha para o RCALL
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; Configura PD0 (L0) e PD1 (L1) como SAÍDAS (1)
    SBI DDRD, 0
    SBI DDRD, 1

    ; Configura PD2 (JUNTOS) e PD3 (ALTERNADO) como ENTRADAS (0)
    CBI DDRD, 2
    CBI DDRD, 3

    ; Liga Resistores de Pull-up nas entradas (Escreve 1 no PORTD)
    SBI PORTD, 2
    SBI PORTD, 3

    ; Inicia LEDs apagados (Escreve 1 para desligar)
    SBI PORTD, 0
    SBI PORTD, 1

LOOP_PRINCIPAL:
    ; SBIS pula a próxima instrução se o bit estiver em 1 (botão solto)
    SBIS PIND, 3         ; Verifica PD3 (Alternado)
    RJMP FAZ_ALTERNADO   ; Só entra aqui se PD3 for 0 (pressionado)

    SBIS PIND, 2         ; Verifica PD2 (Juntos)
    RJMP FAZ_JUNTOS      ; Só entra aqui se PD2 for 0 (pressionado)

    ; Se chegou aqui, nenhum botão está pressionado
    SBI PORTD, 0         ; Apaga L0
    SBI PORTD, 1         ; Apaga L1
    RJMP LOOP_PRINCIPAL

FAZ_ALTERNADO:
    CBI PORTD, 0         ; Liga L0 (com 0)
    SBI PORTD, 1         ; Desliga L1
    LDI R_DEL1, 160      ; ~2 segundos
    RCALL DELAY

    SBI PORTD, 0         ; Desliga L0
    CBI PORTD, 1         ; Liga L1 (com 0)
    LDI R_DEL1, 160      ; ~2 segundos
    RCALL DELAY
    
    RJMP LOOP_PRINCIPAL  ; Volta para testar os botões

FAZ_JUNTOS:
    CBI PORTD, 0         ; Liga L0
    CBI PORTD, 1         ; Liga L1
    LDI R_DEL1, 80       ; ~1 segundo
    RCALL DELAY

    SBI PORTD, 0         ; Desliga L0
    SBI PORTD, 1         ; Desliga L1
    LDI R_DEL1, 80       ; ~1 segundo
    RCALL DELAY
    
    RJMP LOOP_PRINCIPAL  ; Volta para testar os botões

; --- Sub-rotina de Delay ---
DELAY:
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
