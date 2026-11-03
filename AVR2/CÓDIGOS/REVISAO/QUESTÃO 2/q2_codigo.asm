.INCLUDE <m328Pdef.inc>


.EQU BT_RST     = PD2    ; INT0 - Botão RESET
.EQU BT_INC_DEC = PD3    ; INT1 - Botão INC/DEC

.DEF AUX = R16

.DSEG
.ORG 0x0100
count_b: .BYTE 1        
count_c: .BYTE 1        
    
.CSEG
.ORG 0x0000
    RJMP SETUP           

.ORG 0x0002
    RJMP ISR_RST         

.ORG 0x0004
    RJMP ISR_INC_DEC     

.ORG 0x0034              
    
SETUP:
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    LDI AUX, 0x0F
    OUT DDRB, AUX   
    OUT DDRC, AUX

    CBI DDRD, BT_RST
    CBI DDRD, BT_INC_DEC
    SBI PORTD, BT_RST
    SBI PORTD, BT_INC_DEC
  
    LDI AUX, 0
    STS count_b, AUX
    OUT PORTB, AUX

    LDI AUX, 15
    STS count_c, AUX
    OUT PORTC, AUX
    
    LDI AUX, 0x06
    STS EICRA, AUX
    
    SBI EIMSK, INT0
    SBI EIMSK, INT1

    SEI

MAIN:
    RJMP MAIN            ;

ISR_RST:
    PUSH AUX
    IN AUX, SREG
    PUSH AUX

    
    CLR AUX
    STS count_b, AUX
    OUT PORTB, AUX

    LDI AUX, 15
    STS count_c, AUX
    OUT PORTC, AUX

    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI


ISR_INC_DEC:
    PUSH AUX
    IN AUX, SREG
    PUSH AUX
    PUSH R17             

    SBIC PIND, BT_INC_DEC
    RJMP BOT_SOLTO

BOT_PRESSIONADO:
    LDS R17, count_b
    CPI R17, 15
    BRGE FIM_ISR_INC_DEC 

    INC R17
    STS count_b, R17
    OUT PORTB, R17
    RJMP FIM_ISR_INC_DEC

BOT_SOLTO:
    LDS R17, count_c
    CPI R17, 0
    BREQ FIM_ISR_INC_DEC

    DEC R17
    STS count_c, R17
    OUT PORTC, R17

FIM_ISR_INC_DEC:
    POP R17
    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI