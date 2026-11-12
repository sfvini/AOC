.INCLUDE <m328Pdef.inc>     ; Inclui as definições de hardware do ATmega328P

.EQU BT_RST     = PD2       ; Define o pino PD2 como BT_RST (gatilho da interrupção INT0)
.EQU BT_INC_DEC = PD3       ; Define o pino PD3 como BT_INC_DEC (gatilho da interrupção INT1)

.DEF AUX = R16              ; Cria o apelido "AUX" para o registrador R16

; --- Segmento de Dados (SRAM) ---
.DSEG
.ORG 0x0100                 ; Início da memória SRAM de dados
count_b: .BYTE 1            ; Reserva 1 byte na SRAM para a variável count_b
count_c: .BYTE 1            ; Reserva 1 byte na SRAM para a variável count_c
    
; --- Segmento de Código (Flash) ---
.CSEG
.ORG 0x0000
    RJMP SETUP              ; Vetor de Reset: Salta para a configuração inicial

.ORG 0x0002
    RJMP ISR_RST            ; Vetor INT0: Salta para a rotina de reset dos contadores

.ORG 0x0004
    RJMP ISR_INC_DEC        ; Vetor INT1: Salta para a rotina de incremento/decremento

.ORG 0x0034                 ; Fim dos vetores de interrupção, início do programa principal
        
SETUP:
    ; Inicializa o Stack Pointer (Pilha)
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; Configuração de Saídas
    LDI AUX, 0x0F           ; Carrega 0x0F (00001111 em binário)
    OUT DDRB, AUX           ; Configura os 4 bits menos significativos de PORTB como saída
    OUT DDRC, AUX           ; Configura os 4 bits menos significativos de PORTC como saída

    ; Configuração de Entradas (Botões)
    CBI DDRD, BT_RST        ; Configura PD2 (INT0) como entrada
    CBI DDRD, BT_INC_DEC    ; Configura PD3 (INT1) como entrada
    SBI PORTD, BT_RST       ; Habilita Pull-up interno no PD2
    SBI PORTD, BT_INC_DEC   ; Habilita Pull-up interno no PD3
  
    ; Inicializa variáveis e saídas
    LDI AUX, 0              ; Carrega 0
    STS count_b, AUX        ; Salva 0 na variável count_b na SRAM
    OUT PORTB, AUX          ; Envia 0 para a PORTB

    LDI AUX, 15             ; Carrega 15
    STS count_c, AUX        ; Salva 15 na variável count_c na SRAM
    OUT PORTC, AUX          ; Envia 15 para a PORTC
    
    ; Configuração das Interrupções Externas
    LDI AUX, 0x06           ; Binário 0000 0110 (ISC11=0, ISC10=1, ISC01=1, ISC00=0)
    STS EICRA, AUX          ; INT1 configurada para "Qualquer Mudança Lógica" (sobe ou desce) e INT0 para "Borda de Descida" (aperto)
    
    SBI EIMSK, INT0         ; Habilita a interrupção externa 0
    SBI EIMSK, INT1         ; Habilita a interrupção externa 1

    SEI                     ; Habilita as interrupções globais

MAIN:
    RJMP MAIN               ; Loop infinito. Todo o trabalho é feito nas interrupções

; --- Rotina da Interrupção INT0 (Botão Reset - Borda de Descida) ---
ISR_RST:
    PUSH AUX                ; Salva o contexto de AUX
    IN AUX, SREG            ; Lê o Status Register
    PUSH AUX                ; Salva o SREG na pilha

    ; Zera count_b e PORTB
    CLR AUX                 
    STS count_b, AUX        
    OUT PORTB, AUX          

    ; Restaura count_c e PORTC para 15
    LDI AUX, 15             
    STS count_c, AUX        
    OUT PORTC, AUX          

    POP AUX                 ; Restaura o SREG
    OUT SREG, AUX
    POP AUX                 ; Restaura AUX
    RETI                    ; Retorna da interrupção


; --- Rotina da Interrupção INT1 (Qualquer Mudança Lógica: Aperto ou Soltura) ---
ISR_INC_DEC:
    PUSH AUX                ; Salva o contexto de AUX
    IN AUX, SREG            
    PUSH AUX                ; Salva SREG
    PUSH R17                ; Salva R17, pois será usado para as contas

    ; Verifica se a interrupção foi por apertar ou soltar o botão
    SBIC PIND, BT_INC_DEC   ; Testa o pino do botão. Se estiver solto (1), pula para BOT_SOLTO
    RJMP BOT_SOLTO          ; Se o botão estiver solto, vai decrementar C

BOT_PRESSIONADO:            ; Executado quando o botão é APERTADO (nível 0)
    LDS R17, count_b        ; Lê o valor de count_b da SRAM
    CPI R17, 15             ; Compara com o limite máximo (15)
    BRGE FIM_ISR_INC_DEC    ; Se for maior ou igual a 15 (Branch if Greater or Equal), não faz nada

    INC R17                 ; Incrementa count_b
    STS count_b, R17        ; Salva na SRAM
    OUT PORTB, R17          ; Atualiza os LEDs da PORTB
    RJMP FIM_ISR_INC_DEC    ; Vai para o fim da rotina

BOT_SOLTO:                  ; Executado quando o botão é SOLTO (nível 1)
    LDS R17, count_c        ; Lê o valor de count_c da SRAM
    CPI R17, 0              ; Compara com o limite mínimo (0)
    BREQ FIM_ISR_INC_DEC    ; Se for igual a 0 (Branch if Equal), não faz nada

    DEC R17                 ; Decrementa count_c
    STS count_c, R17        ; Salva na SRAM
    OUT PORTC, R17          ; Atualiza os LEDs da PORTC

FIM_ISR_INC_
