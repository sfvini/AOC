; Questão 2: Interrupção
; - Converta o código acima para que os botões funcionem com as interrupções externas.
; - Configure e habilite adequadamente a INT0 e a INT1.
; - O acionamento dos LEDs e o delay não podem estar dentro da interrupção. Utilize variáveis na SRAM para comunicar o estado para o loop principal, o qual deverá fazer os acionamentos dos LEDs.

.INCLUDE <m328Pdef.inc>

.DEF AUX = R16
.DEF R_DEL1 = R17
.DEF R_DEL2 = R18
.DEF R_DEL3 = R19

; --- Variável na SRAM ---
.DSEG
.ORG 0x0100
VAR_MODO: .BYTE 1        ; 0=Desligado, 1=Alternado, 2=Juntos

.CSEG
; --- Vetores de Interrupção ---
.ORG 0x0000
    RJMP INICIO          ; Reset
.ORG 0x0002
    RJMP ISR_INT0        ; Botão JUNTOS (PD2)
.ORG 0x0004
    RJMP ISR_INT1        ; Botão ALTERNADO (PD3)

.ORG 0x0034              ; Passa a área dos vetores
INICIO:
    ; Configura Pilha
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; Configura Saídas e Entradas
    SBI DDRD, 0
    SBI DDRD, 1
    CBI DDRD, 2
    CBI DDRD, 3
    SBI PORTD, 2
    SBI PORTD, 3
    SBI PORTD, 0
    SBI PORTD, 1

    ; Zera a variável VAR_MODO
    LDI AUX, 0
    STS VAR_MODO, AUX

    ; Configura EICRA para "Qualquer Mudança Lógica" em INT0 e INT1
    ; EICRA = 0b00000101 (0x05) -> ISC10 e ISC00 em 1
    LDI AUX, 0x05
    STS EICRA, AUX

    ; Habilita INT0 e INT1 no EIMSK
    ; EIMSK = 0b00000011 (0x03)
    LDI AUX, 0x03
    OUT EIMSK, AUX

    ; Habilita interrupção global
    SEI

LOOP_PRINCIPAL:
    LDS AUX, VAR_MODO    ; Lê o valor que a interrupção gravou

    CPI AUX, 1           ; Se for 1, vai pro modo Alternado
    BREQ FAZ_ALTERNADO

    CPI AUX, 2           ; Se for 2, vai pro modo Juntos
    BREQ FAZ_JUNTOS

    ; Se for 0 (Desligado), apaga os LEDs
    SBI PORTD, 0
    SBI PORTD, 1
    RJMP LOOP_PRINCIPAL

FAZ_ALTERNADO:
    CBI PORTD, 0
    SBI PORTD, 1
    LDI R_DEL1, 160
    RCALL DELAY
    
    SBI PORTD, 0
    CBI PORTD, 1
    LDI R_DEL1, 160
    RCALL DELAY
    RJMP LOOP_PRINCIPAL

FAZ_JUNTOS:
    CBI PORTD, 0
    CBI PORTD, 1
    LDI R_DEL1, 80
    RCALL DELAY

    SBI PORTD, 0
    SBI PORTD, 1
    LDI R_DEL1, 80
    RCALL DELAY
    RJMP LOOP_PRINCIPAL

; --- Interrupções ---
; Utilizando R20 e R21 fixos para a ISR para evitar PUSH/POP e simplificar a leitura

ISR_INT0: 
    IN R20, SREG         ; Salva SREG no R20
    
    SBIS PIND, 2         ; Testa PD2 (pula se for 1 / solto)
    RJMP APERTOU_INT0
    
    ; Se o pino for 1 (Soltou)
    LDI R21, 0           
    STS VAR_MODO, R21
    RJMP FIM_INT0
    
APERTOU_INT0:
    LDI R21, 2           ; Se o pino for 0 (Apertou)
    STS VAR_MODO, R21
    
FIM_INT0:
    OUT SREG, R20        ; Devolve SREG
    RETI


ISR_INT1:
    IN R20, SREG         ; Salva SREG no R20
    
    SBIS PIND, 3         ; Testa PD3 (pula se for 1 / solto)
    RJMP APERTOU_INT1
    
    ; Se o pino for 1 (Soltou)
    LDI R21, 0           
    STS VAR_MODO, R21
    RJMP FIM_INT1
    
APERTOU_INT1:
    LDI R21, 1           ; Se o pino for 0 (Apertou)
    STS VAR_MODO, R21
    
FIM_INT1:
    OUT SREG, R20        ; Devolve SREG
    RETI

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
