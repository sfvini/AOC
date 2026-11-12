.ORG 0x0000           
    RJMP setup

.ORG 0x0016            
    RJMP isr_tc1

setup:
    SBI DDRB, 5         
    CBI PORTB, 5        

    ; configuração do OCR1A para 1 segundo exato
    ; com clock de 16 MHz e prescaler de 256, temos 62.500 ticks por segundo.
    ; o timer começa em 0, o limite é 62500 - 1 = 62499 (0xF423 em Hex)
    LDI R16, 0xF4       
    STS OCR1AH, R16    
    LDI R16, 0x23       
    STS OCR1AL, R16  

    ; configuração do TCCR1A (Desconecta pinos de hardware, modo normal nas saídas)
    LDI R16, 0x00
    STS TCCR1A, R16

    ; configuração do TCCR1B (Ativa modo CTC e Prescaler de 256)
    ; Bits WGM12 = 1 (Modo CTC), CS12 = 1 (Prescaler 256) -> 0b00001100 (0x0C)
    LDI R16, 0x0C
    STS TCCR1B, R16     

    ; Habilita a interrupção por Comparação A (Output Compare A Match Interrupt)
    LDI R16, 0x02       ; Bit OCIE1A (Bit 1) habilitado
    STS TIMSK1, R16     

    SEI               
    
main:
    RJMP main          

isr_tc1:
    SBI PINB, 5         
    RETI               