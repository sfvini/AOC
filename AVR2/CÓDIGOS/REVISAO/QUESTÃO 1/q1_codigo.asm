.INCLUDE <m328Pdef.inc>

.EQU RST     = PB1        ; Botão RESET 
.EQU INC_DEC = PB2        ; Botão INC/DEC 

.DEF AUX     = R16        
.DEF COUNT_B = R17        ; B (0 a 15)
.DEF COUNT_C = R18        ; C (15 a 0)


setup:
    LDI  AUX, 0xFF
    OUT  DDRD, AUX        

    CBI  DDRB, RST    
    SBI  PORTB, RST    
    
    CBI  DDRB, INC_DEC   
    SBI  PORTB, INC_DEC  
    
    CLR  COUNT_B
    LDI  COUNT_C, 15

    MOV  AUX, COUNT_C
    SWAP AUX                  
    OR   AUX, COUNT_B         
    OUT  PORTD, AUX           


main:
    SBIC PINB, RST
    RJMP inc_dec

    CLR  COUNT_B
    LDI  COUNT_C, 15
    RJMP atualizar_saida     

    
inc_dec:
    SBIC PINB, INC_DEC
    RJMP main                     

    CPI  COUNT_B, 15
    BREQ espera_soltar                 

    INC  COUNT_B
    DEC  COUNT_C

    
atualizar_saida:
    MOV  AUX, COUNT_C
    SWAP AUX                    
    OR   AUX, COUNT_B           
    OUT  PORTD, AUX             

    
espera_soltar:
    SBIS PINB, INC_DEC
    RJMP espera_soltar

    RJMP main
    