; .INCLUDE <m328Pdef.inc>
    
.DSEG
.ORG 0x0100 ; endereço inicial    
contagem: .BYTE 1 ; variável que apresenta o número de "estouros"
intervalo: .BYTE 1 ; variável que determina quando o LED pisca
    
.CSEG    
.ORG 0x0000
    RJMP setup 

.ORG 0x0002 ; endereço do botão
    RJMP ISR_INT0 
    
.ORG 0x0020 ; endereço do estouro do T/C0
    RJMP ISR_TC0B 
  
.ORG 0x0034 ; começo do código principal
    
setup:
; configuração da pilha
LDI R16, HIGH(RAMEND)
OUT SPH, R16
LDI R16, LOW(RAMEND)
OUT SPL, R16

; configuração de entradas e saídas
; 1 botão e 1 led

SBI DDRB, 5 ; PB5 como saída  
CBI DDRD, 2 ; PD2 como entrada  
SBI PORTD, 2 ; 1 = desligado, 0 = ligado
    
; o período inicial é 1 segundo, logo, vão ser 500ms ligado e 500ms desligado
LDI R16, 0 
STS contagem, R16 ; inicialmente, a contagem está em 0
LDI R16, 31
STS intervalo, R16 ; 500ms de intervalo (31 overflows de 16,384ms = 500ms --> intervalo = tempo_alvo/tempo_um_estouro)
    
; configurar o temporizador e habilitar interrupções por estouro
LDI R16, 0x05
OUT TCCR0B, R16  
LDI R16, 1
STS TIMSK0, R16    

; configurar a interrupção do botão
LDI R16, 0x02      ; configura ISC01=1 e ISC00=0 (Interrupção na borda de descida - ao apertar o botão)
STS EICRA, R16
LDI R16, 1
OUT EIMSK, R16

SEI
    
main:
RJMP main
    
ISR_TC0B: ; interrupção que inverte o led ao chegar no intervalo	
    ; salva o contexto
    PUSH R16
    IN R16, SREG
    PUSH R16
    PUSH R17
    
    LDS R16, contagem ; lê o valor de contagem
    INC R16  ; incrementa a contagem 
    
    LDS R17, intervalo ; lê o valor de intervalo (desliga - liga)
    CP R16, R17 ; compara os dois
    
    BRLO SALVAR ; se contagem for menor que intervalo (não chegou no tempo para desligar/ligar), só pula para salvar o novo valor
    
    SBI PINB, 5 ; escreve 1 no PINB e inverte o pino PB5 (Liga/Desliga o LED)
    LDI R16, 0 ; volta o ciclo 
    
    SALVAR:
	STS contagem, R16 ; guarda o valor atual de "contagem"
    
    POP R17
    POP R16
    OUT SREG, R16      
    POP R16
    RETI       
    
ISR_INT0: ; interrupção para mudar o intervalo
    PUSH R16
    IN R16, SREG
    PUSH R16
    
    LDS R16, intervalo ; lê o intervalo atual
    SUBI R16, 6 ; subtrai 6 (6*16ms = 100ms)
    
    CPI R16, 7 ; compara o novo valor com 7 (o limite mínimo de 200ms - 100ms cada estágio)
    BRSH SALVAR_2 ; se for maior ou igual a 7 vai salvar.
    
    LDI R16, 31 ; se o valor ficou menor que 7 volta o para o mais lento (1s - 500ms)

    SALVAR_2:
    STS intervalo, R16 ;  guarda o valor atual de "intervalo"
    
    POP R16
    OUT SREG, R16
    POP R16
    RETI              
    
