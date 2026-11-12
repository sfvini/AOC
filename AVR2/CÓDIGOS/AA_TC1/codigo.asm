.ORG 0x0000            
    RJMP setup

.ORG 0x001A             
    RJMP isr_tc1

setup:	
    SBI DDRB, 5        
    CBI PORTB, 5       
    
    LDI R16, 0b00000100 
    STS TCCR1B, R16    
    LDI R16, 1
    STS TIMSK1, R16     

    SEI               

main:
    RJMP main           

isr_tc1:
    SBI PINB, 5         
    RETI            