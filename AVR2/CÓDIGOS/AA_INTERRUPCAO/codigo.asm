; .INCLUDE <m328pdef.INC>   ; Biblioteca de definições do ATmega328P (comentada no original)

    .equ BT_ON = PD2   ; Define BT_ON como pino PD2 (pino associado à interrupção INT0)
    .equ BT_OFF = PD3  ; Define BT_OFF como pino PD3 (pino associado à interrupção INT1)

    .equ L0 = PB0      ; Define L0 como pino PB0
    .equ L1 = PB1      ; Define L1 como pino PB1
    .def AUX = R16     ; Define o apelido "AUX" para o registrador de uso geral R16

.ORG 0x0000
    RJMP SETUP         ; Vetor de Reset: Salta para a rotina de inicialização quando o microcontrolador liga

.ORG 0x0002
    RJMP I_ON          ; Vetor de Interrupção Externa 0 (INT0): Salta para ligar L1 quando o BT_ON é pressionado

.ORG 0x0004
    RJMP I_OFF         ; Vetor de Interrupção Externa 1 (INT1): Salta para desligar L1 quando o BT_OFF é pressionado

.ORG 0x0034            ; Início do código do programa (logo após a área reservada para os vetores de interrupção)
       
SETUP:
    ; Inicialização do Stack Pointer (Pilha) - Essencial para usar chamadas (RCALL) e interrupções
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; Configura LEDs (Saídas)
    SBI DDRB, L0       ; Configura PB0 (L0) como saída (Seta o bit 0 no Data Direction Register B)
    SBI DDRB, L1       ; Configura PB1 (L1) como saída
    ; LEDs desligam com "1" (assumindo montagem com lógica invertida / anodo no VCC)
    SBI PORTB, L0      ; Nível alto em PB0: apaga o LED L0
    SBI PORTB, L1      ; Nível alto em PB1: apaga o LED L1

    ; Configura Botões (Entradas com Pull-up interno)
    CBI DDRD, BT_ON    ; Configura PD2 (INT0) como entrada (Zera o bit no DDRD)
    CBI DDRD, BT_OFF   ; Configura PD3 (INT1) como entrada
    ; Ativa resistores Pull-up (mantém o pino em nível lógico "1" até que o botão aterre o sinal)
    SBI PORTD, BT_ON
    SBI PORTD, BT_OFF

; Configura Interrupções Externas (INT0 e INT1)
    LDI AUX, 0x0A       ; Carrega 0x0A (binário 00001010) no AUX
    STS EICRA, AUX      ; External Interrupt Control Register A: ISC11=1, ISC10=0 e ISC01=1, ISC00=0. Ambas sensíveis a borda de descida (quando solto -> pressionado)
    
    SBI EIMSK, INT0     ; Habilita a máscara de interrupção para INT0
    SBI EIMSK, INT1     ; Habilita a máscara de interrupção para INT1

    ; Habilita a chave geral de interrupções (Set Global Interrupt Flag no SREG)
    SEI

MAIN:
    ; Laço principal que fica piscando o L0 independentemente do que acontece com L1
    CBI PORTB, L0       ; Liga o LED L0 (coloca PB0 em nível baixo "0")
    LDI R19, 160        ; Carrega parâmetro de tempo no R19
    RCALL delay         ; Chama a sub-rotina de atraso (delay)
    
    SBI PORTB, L0       ; Desliga o LED L0 (coloca PB0 em nível alto "1")
    LDI R19, 160        ; Carrega parâmetro de tempo no R19
    RCALL delay         ; Chama a sub-rotina de atraso
    
    RJMP MAIN           ; Retorna ao início do laço (loop infinito)

; Rotina de Serviço de Interrupção para INT0 (Ligar L1)
I_ON:
    PUSH AUX            ; Salva o valor atual de AUX na pilha (contexto)
    IN AUX, SREG        ; Lê o registrador de status (SREG) atual
    PUSH AUX            ; Salva o SREG na pilha para evitar corromper flags (como as do delay/main)

    CBI PORTB, L1       ; Executa a ação da interrupção: Liga o LED L1

    POP AUX             ; Recupera o valor salvo do SREG da pilha
    OUT SREG, AUX       ; Restaura o SREG
    POP AUX             ; Recupera o valor salvo de AUX da pilha
    RETI                ; Return from Interrupt (restaura PC e reabilita interrupções globais)

; Rotina de Serviço de Interrupção para INT1 (Desligar L1)
I_OFF:
    PUSH AUX            ; Salva contexto de AUX
    IN AUX, SREG        
    PUSH AUX            ; Salva contexto do SREG

    SBI PORTB, L1       ; Executa a ação da interrupção: Desliga o LED L1

    POP AUX             ; Restaura SREG
    OUT SREG, AUX
    POP AUX             ; Restaura AUX
    RETI                ; Return from Interrupt

; SUB-ROTINA DE ATRASO (Loop aninhado triplo)
delay:
    PUSH R17            ; Salva o registrador R17 na pilha
    PUSH R18            ; Salva o registrador R18 na pilha
    IN R17, SREG        
    PUSH R17            ; Salva o SREG na pilha (usando R17 como intermediário)

    CLR R17             ; Zera R17 (0 - 1 = 255, itera 256 vezes)
    CLR R18             ; Zera R18 (itera 256 vezes para cada decremento de R19)
loop:
    DEC  R17            ; Decrementa R17 (Loop interno 1)
    BRNE loop           ; Branch if Not Equal (se não for zero, repete)
    DEC  R18            ; Decrementa R18 (Loop interno 2)
    BRNE loop           
    DEC  R19            ; Decrementa R19 (carregado com 160 no MAIN, Loop externo)
    BRNE loop           

    POP R17             ; Recupera o SREG salvo
    OUT SREG, R17       ; Restaura o SREG
    POP R18             ; Restaura R18 original
    POP R17             ; Restaura R17 original
    RET                 ; Retorna para o local de onde a sub-rotina foi chamada
