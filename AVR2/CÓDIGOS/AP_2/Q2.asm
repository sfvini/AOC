; Questão 2: Interrupção
; - Converta o código acima para que os botões funcionem com as interrupções externas.
; - Configure e habilite adequadamente a INT0 e a INT1.
; - O acionamento dos LEDs e o delay não podem estar dentro da interrupção. Utilize variáveis na SRAM para comunicar o estado para o loop principal, o qual deverá fazer os acionamentos dos LEDs.

.INCLUDE <m328Pdef.inc>

; --- Definições dos Pinos ---
.EQU L0 = PORTD0
.EQU L1 = PORTD1
.EQU BT_JUN = PIND2      ; INT0
.EQU BT_ALT = PIND3      ; INT1

; --- Registradores Auxiliares ---
.DEF AUX = R16
.DEF R_DEL1 = R17
.DEF R_DEL2 = R18
.DEF R_DEL3 = R19

; --- Variável na Memória RAM (SRAM) ---
.DSEG
.ORG 0x0100
estado: .BYTE 1          ; Vai guardar: 0=Desligado, 1=Alternado, 2=Juntos

.CSEG
; --- Vetores de Interrupção ---
.ORG 0x0000
    RJMP SETUP           ; Reset
.ORG 0x0002
    RJMP ISR_JUNTOS      ; Interrupção INT0 (PD2)
.ORG 0x0004
    RJMP ISR_ALTER       ; Interrupção INT1 (PD3)

.ORG 0x0034
SETUP:
    ; 1. Configura a Pilha
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; 2. Configura Entradas e Saídas
    SBI DDRD, L0
    SBI DDRD, L1
    CBI DDRD, BT_JUN
    CBI DDRD, BT_ALT
    SBI PORTD, BT_JUN
    SBI PORTD, BT_ALT
    SBI PORTD, L0
    SBI PORTD, L1

    ; 3. Inicia a variável "estado" com 0 (Desligado)
    LDI AUX, 0
    STS estado, AUX

    ; 4. Configura as Interrupções para "Qualquer Mudança de Estado"
    ; Para ativar quando aperta E quando solta.
    ; Código 0x05 (Binário 0000 0101) = ISC10 e ISC00 em '1'
    LDI AUX, 0x05
    STS EICRA, AUX

    ; 5. Habilita INT0 e INT1
    LDI AUX, (1<<INT1)|(1<<INT0)
    OUT EIMSK, AUX

    ; 6. Liga chave geral de interrupção
    SEI

; --- Loop Principal ---
MAIN:
    LDS AUX, estado      ; Lê o que as interrupções gravaram na memória

    CPI AUX, 1           ; Se for 1, vai pro modo Alternado
    BREQ EXEC_ALTER

    CPI AUX, 2           ; Se for 2, vai pro modo Juntos
    BREQ EXEC_JUNTOS

    ; Se for 0 (ou outro valor), apaga os LEDs
    SBI PORTD, L0
    SBI PORTD, L1
    RJMP MAIN

EXEC_ALTER:
    CBI PORTD, L0        ; Liga L0
    SBI PORTD, L1        ; Desliga L1
    LDI R_DEL1, 160
    RCALL DELAY_PROG
    
    SBI PORTD, L0        ; Desliga L0
    CBI PORTD, L1        ; Liga L1
    LDI R_DEL1, 160
    RCALL DELAY_PROG
    RJMP MAIN

EXEC_JUNTOS:
    CBI PORTD, L0        ; Liga Ambos
    CBI PORTD, L1
    LDI R_DEL1, 80
    RCALL DELAY_PROG

    SBI PORTD, L0        ; Desliga Ambos
    SBI PORTD, L1
    LDI R_DEL1, 80
    RCALL DELAY_PROG
    RJMP MAIN

; --- Interrupção INT0 (Botão JUNTOS) ---
ISR_JUNTOS:
    PUSH AUX             ; Salva AUX
    IN AUX, SREG         ; Lê SREG
    PUSH AUX             ; Salva SREG

    ; Lê o pino para saber se foi apertado(0) ou solto(1)
    SBIC PIND, BT_JUN    ; Se solto (1), pula o botão apertado
    RJMP SOLTO_JUNTOS

    LDI AUX, 2           ; Se apertou, salva 2 na memória
    STS estado, AUX
    RJMP FIM_INT0

SOLTO_JUNTOS:
    LDI AUX, 0           ; Se soltou, salva 0 na memória
    STS estado, AUX

FIM_INT0:
    POP AUX
    OUT SREG, AUX        ; Devolve SREG
    POP AUX              ; Devolve AUX
    RETI

; --- Interrupção INT1 (Botão ALTERNADO) ---
ISR_ALTER:
    PUSH AUX
    IN AUX, SREG
    PUSH AUX

    SBIC PIND, BT_ALT    ; Testa o pino
    RJMP SOLTO_ALTER

    LDI AUX, 1           ; Se apertou, salva 1 na memória
    STS estado, AUX
    RJMP FIM_INT1

SOLTO_ALTER:
    LDI AUX, 0           ; Se soltou, salva 0 na memória
    STS estado, AUX

FIM_INT1:
    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI

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
