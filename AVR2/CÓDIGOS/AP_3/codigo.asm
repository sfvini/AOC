; Onda quadrada de 100 kHz no PB5 enquanto PD2 estiver pressionado
; Meio periodo = 5 
; Prescaler: 40 para 5
; Estouro: TCNT0 = 256 - 40 = 216 
  
    
.ORG 0x0000                 ; Vetor de Reset
    RJMP setup
.ORG 0x0002                 ; Vetor da interrupcao 
    RJMP i_int0
.ORG 0x0020                 ; Vetor de estouro
    RJMP i_tc0
   
    
setup:
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    SBI DDRB, 5             ; PB5 como saida
    CBI PORTB, 5           
    CBI DDRD, 2             ; PD2 entrada
    SBI PORTD, 2 
    LDI R17, 216            
    LDI R16, 0x00           
    OUT TCCR0A, R16
    LDI R16, 0x00           ; timer 0 inicia parado
    OUT TCCR0B, R16
    LDI R16, 0x01           ; habilita interrupcao por Overflow
    STS TIMSK0, R16
    LDI R16, 0x01         
    STS EICRA, R16
    LDI R16, 0x01         
    OUT EIMSK, R16
    SEI
   
    
main:
    RJMP main
    
    
i_tc0:
    OUT TCNT0, R17          ; recarrega TCNT0 
    SBI PINB, 5             ; inverte PB5
    RETI                    

    
i_int0:
    PUSH R16
    IN R16, SREG
    PUSH R16
    SBIC PIND, 2            ; PD2 apertado pula o rjmp
    RJMP botao_solto
botao_pressionado:
    OUT TCNT0, R17          ; carrega TCNT0
    LDI R16, 0x01           ; liga timer 0 prescaler 1 
    OUT TCCR0B, R16
    RJMP fim_int0
botao_solto:
    LDI R16, 0x00           ; para o timer 0 
    OUT TCCR0B, R16
    CBI PORTB, 5            ; saida em nivel baixo
fim_int0:
    POP R16
    OUT SREG, R16
    POP R16
    RETI
