.INCLUDE <m328Pdef.inc>

.EQU AJUSTE  = PB1
.EQU SELECAO = PB2

setup:
    LDI  R16, 0xFF
    OUT  DDRD, R16        

    CBI  DDRB, AJUSTE    
    SBI  PORTB, AJUSTE    
    
    CBI  DDRB, SELECAO   
    SBI  PORTB, SELECAO  
	
loop:
    LDI  R16, 0x00          

    SBIS PINB, AJUSTE       
    ORI  R16, 0x0F         

    SBIS PINB, SELECAO      
    ORI  R16, 0xF0          

    OUT  PORTD, R16          
    RJMP loop