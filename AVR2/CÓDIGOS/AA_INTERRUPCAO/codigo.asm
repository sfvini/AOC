; .INCLUDE <m328pdef.INC>
    
    .equ BT_ON = PD2   ; INT0
    .equ BT_OFF = PD3  ; INT1
    
    .equ L0 = PB0
    .equ L1 = PB1
    .def AUX = R16

.ORG 0x0000
    RJMP SETUP         

.ORG 0x0002
    RJMP I_ON        

.ORG 0x0004
    RJMP I_OFF       

.ORG 0x0034    
       
SETUP:
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; Configura LEDs (Saídas)
    SBI DDRB, L0
    SBI DDRB, L1
    ; LEDs desligam com "1" (estado inicial)
    SBI PORTB, L0
    SBI PORTB, L1

    ; Configura Botões (Entradas com Pull-up interno)
    CBI DDRD, BT_ON
    CBI DDRD, BT_OFF
    ; Ativa resistores Pull-up (mantém nível "1" quando não pressionado)
    SBI PORTD, BT_ON
    SBI PORTD, BT_OFF

; Configura Interrupções Externas (INT0 e INT1)
    LDI AUX, 0x0A       ; 
    STS EICRA, AUX      ; config. INT0 e INT1 sensiveis a borda de descida
    
    SBI EIMSK, INT0     ; habilita a INT0
    SBI EIMSK, INT1     ; habilita a INT1

    ; Habilita a chave geral de interrupções
    SEI

MAIN:
    CBI PORTB, L0      
    LDI R19, 160       
    RCALL delay
    
    SBI PORTB, L0      
    LDI R19, 160       
    RCALL delay
    
    RJMP MAIN          

I_ON:
    PUSH AUX          
    IN AUX, SREG
    PUSH AUX

    CBI PORTB, L1      

    POP AUX            
    OUT SREG, AUX
    POP AUX
    RETI

I_OFF:
    PUSH AUX           
    IN AUX, SREG
    PUSH AUX

    SBI PORTB, L1      

    POP AUX          
    OUT SREG, AUX
    POP AUX
    RETI

; SUB-ROTINA DE ATRASO
delay:
    PUSH R17     
    PUSH R18      
    IN R17, SREG     
    PUSH R17        

    CLR R17
    CLR R18
loop:
    DEC  R17        
    BRNE loop        
    DEC  R18        
    BRNE loop       
    DEC  R19        
    BRNE loop       

    POP R17
    OUT SREG, R17   
    POP R18          
    POP R17         
    RET
    