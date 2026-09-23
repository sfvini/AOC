.DSEG                     
.ORG SRAM_START             

    A1: .BYTE 10           
    A2: .BYTE 10           
    A3: .BYTE 10            
    A4: .BYTE 3             

.CSEG                       
    LDI XL, LOW(A1)        
    LDI XH, HIGH(A1)      
    
    LDI YL, LOW(A2)        
    LDI YH, HIGH(A2)        

    LDI R16, 1             
    LDI R17, 10            
    
loop1:
    ST X+, R16                                     
    ST Y+, R16              
    INC R16                
    DEC R17            
    BRNE loop1            

    LDI XL, LOW(A1)         
    LDI XH, HIGH(A1)       

    LDI YL, LOW(A2 + 10)    
    LDI YH, HIGH(A2 + 10)

    LDI ZL, LOW(A3)         
    LDI ZH, HIGH(A3)        

    LDI R17, 10             

loop2:
    LD R16, X+              
    LD R18, -Y              
    ADD R16, R18            
    ST Z+, R16           
    DEC R17               
    BRNE loop2              

    LDI YL, LOW(A2)        
    LDI YH, HIGH(A2)      
   
    LDI ZL, LOW(A3)         
    LDI ZH, HIGH(A3)        

    LDI XL, LOW(A4)         
    LDI XH, HIGH(A4)      

    LDD R16, Y+1            
    LDD R18, Z+3            
    ADD R16, R18           
    ST X+, R16             
    
    LDD R16, Y+3            
    LDD R18, Z+4           
    ADD R16, R18          
    ST X+, R16              
    
    LDD R16, Y+5          
    LDD R18, Z+7            
    ADD R16, R18            
    ST X+, R16             

end:
    RJMP end               
.DSEG
.ORG SRAM_START
;    Declare três vetores com 10 posições de 8 bits (A1, A2 e A3) e um vetor de 3 posições de 8 bits (A4).
    A1: .BYTE 10 
    A2: .BYTE 10
    A3: .BYTE 10
    A4: .BYTE 3 
    
.CSEG
;    Inicialize os vetores A1 e A2 com os valores de 1 até 10.
    LDI R27, HIGH(A1)     
    LDI R26, LOW(A1)      

    LDI R29, HIGH(A2)     
    LDI R28, LOW(A2)      

    LDI R16, 1            
    LDI R17, 10           

loop:
    ST X+, R16            
    ST Y+, R16            
    
    INC R16               
    DEC R17               
    BRNE loop    
    
;   Some a primeira posição do A1 com a última do A2 e armazene na primeira do A3. Faça isso para todas as posições. 
    
    
    
    
   
