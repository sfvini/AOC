; ==============================================================================
; PROGRAMA EM ASSEMBLY AVR (ATmega328P): OPERAÇÕES DE 32 BITS
; ==============================================================================

.DSEG                        ; Seleciona o segmento de memória de dados (SRAM)
.ORG SRAM_START              ; Define o endereço inicial da SRAM (0x0100 no ATmega328P)
    
    A: .BYTE 4               ; Reserva 4 bytes para a variável A (32 bits) na SRAM (0x0100 a 0x0103)
    B: .BYTE 4               ; Reserva 4 bytes para a variável B (32 bits) na SRAM (0x0104 a 0x0107)
    C: .BYTE 4               ; Reserva 4 bytes para a variável C (32 bits) na SRAM (0x0108 a 0x010B)

.CSEG                        ; Seleciona o segmento de memória de programa (Flash)

START:
    ; --- 1. Inicialização do Stack Pointer (Pilha) ---
    LDI R16, HIGH(RAMEND)    ; Carrega o byte alto de RAMEND (0x08) no registrador R16
    OUT SPH, R16             ; Grava em SPH (Stack Pointer High)
    LDI R16, LOW(RAMEND)     ; Carrega o byte baixo de RAMEND (0xFF) no registrador R16
    OUT SPL, R16             ; Grava em SPL (Stack Pointer Low) -> SP aponta para 0x08FF
   
    ; --- 2. Inicialização dos Ponteiros de Endereçamento (16 bits) ---
    LDI XL, LOW(A)           ; Carrega o byte baixo do endereço de A em XL (R26)
    LDI XH, HIGH(A)          ; Carrega o byte alto do endereço de A em XH (R27) -> Ponteiro X aponta para A (0x0100)
    
    LDI YL, LOW(B)           ; Carrega o byte baixo do endereço de B em YL (R28)
    LDI YH, HIGH(B)          ; Carrega o byte alto do endereço de B em YH (R29) -> Ponteiro Y aponta para B (0x0104)
    
    LDI ZL, LOW(C)           ; Carrega o byte baixo do endereço de C em ZL (R30)
    LDI ZH, HIGH(C)          ; Carrega o byte alto do endereço de C em ZL (R31) -> Ponteiro Z aponta para C (0x0108)
    
    ; --- 3. Carga dos Valores de Teste de 32 bits (Convenção Little-Endian) ---
    LDI R16, 0x11            ; Byte 0 (LSB - menos significativo) = 0x11
    LDI R17, 0x22            ; Byte 1 = 0x22
    LDI R18, 0x33            ; Byte 2 = 0x33
    LDI R19, 0x44            ; Byte 3 (MSB - mais significativo) = 0x44
    
    ; --- 4. Execução das Sub-rotinas ---
    RCALL init_32bits        ; Chama sub-rotina para gravar R16-R19 nos 4 bytes de A e avançar X em +4
     
    LDI XL, LOW(B)           ; Re-aponta o ponteiro X para o endereço base da variável B
    LDI XH, HIGH(B)
    
    RCALL zera_32bits        ; Chama sub-rotina para preencher os 4 bytes de B com 0x00
    
    LDI XL, LOW(A)           ; Re-aponta o ponteiro X para a variável A (Minuendo)
    LDI XH, HIGH(A)          ; Ponteiro Y já está em B (Subtraendo) e Z em C (Resultado)
    
    RCALL sub_32bits         ; Chama sub-rotina que calcula C = A - B (32 bits)
    
FIM:
    RJMP FIM                 ; Laço infinito para encerramento seguro (impede a CPU de executar memória vazia)

; ==============================================================================
; SUB-ROTINAS MODULARES
; ==============================================================================

; ------------------------------------------------------------------------------
; Sub-rotina: init_32bits
; Descrição : Escreve os registradores R16-R19 nos 4 bytes da SRAM apontados por X
; Entradas  : X = Endereço base da variável | R16..R19 = Valor de 32 bits
; ------------------------------------------------------------------------------
init_32bits:
    ST X+, R16               ; Grava R16 em X e incrementa X em +1 (Byte 0 / LSB)
    ST X+, R17               ; Grava R17 em X e incrementa X em +1 (Byte 1)
    ST X+, R18               ; Grava R18 em X e incrementa X em +1 (Byte 2)
    ST X+, R19               ; Grava R19 em X e incrementa X em +1 (Byte 3 / MSB)

    RET                      ; Desempilha o endereço de retorno e volta ao fluxo principal

; ------------------------------------------------------------------------------
; Sub-rotina: zera_32bits
; Descrição : Preenche 4 bytes contíguos com 0x00 no endereço apontado por X
; Entradas  : X = Endereço base da variável
; Preserva  : Salva o valor original do registrador R16 na pilha
; ------------------------------------------------------------------------------
zera_32bits:
    PUSH R16                 ; Empilha o valor atual de R16 para preservar seu conteúdo
    
    CLR R16                  ; Zera o registrador R16 (R16 = 0x00)
    
    ST X+, R16               ; Grava 0x00 em X e avança X em +1 (Byte 0)
    ST X+, R16               ; Grava 0x00 em X e avança X em +1 (Byte 1)
    ST X+, R16               ; Grava 0x00 na posição X e avança X em +1 (Byte 2)
    ST X+, R16               ; Grava 0x00 na posição X e avança X em +1 (Byte 3)
    
    POP R16                  ; Restaura o valor original de R16 do topo da pilha
    RET                      ; Retorna ao programa principal

; ------------------------------------------------------------------------------
; Sub-rotina: sub_32bits
; Descrição : Calcula C = A - B em 32 bits (onde C é Z, A é X e B é Y)
; Entradas  : X = Ponteiro para A, Y = Ponteiro para B, Z = Ponteiro para C
; Preserva  : Preserva R16, R17 e as flags do Registrador de Status (SREG)
; ------------------------------------------------------------------------------
sub_32bits:
    ; --- Salvamento de Contexto (Empilhamento) ---
    PUSH R16                 ; Salva R16 na pilha
    PUSH R17                 ; Salva R17 na pilha
    
    IN R16, SREG             ; Lê o estado atual das flags do Registrador de Status
    PUSH R16                 ; Salva a cópia do SREG na pilha
    
    ; --- Byte 0 (LSB - Byte Menos Significativo) ---
    LD R16, X+               ; Lê A para R16 e incrementa X em +1
    LD R17, Y+               ; Lê B para R17 e incrementa Y em +1
    SUB R16, R17             ; R16 = A - B (Define a flag Carry 'C' em caso de empréstimo)
    ST Z+, R16               ; Grava o resultado em C e incrementa Z em +1
    
    ; --- Byte 1 ---
    LD R16, X+               ; Lê A e avança X
    LD R17, Y+               ; Lê B e avança Y
    SBC R16, R17             ; R16 = A - B - Carry (Subtrai considerando o empréstimo anterior)
    ST Z+, R16               ; Grava em C e avança Z

    ; --- Byte 2 ---
    LD R16, X+               ; Lê A e avança X
    LD R17, Y+               ; Lê B e avança Y
    SBC R16, R17             ; R16 = A - B - Carry
    ST Z+, R16               ; Grava em C e avança Z

    ; --- Byte 3 (MSB - Byte Mais Significativo) ---
    LD R16, X+               ; Lê A e avança X
    LD R17, Y+               ; Lê B e avança Y
    SBC R16, R17             ; R16 = A - B - Carry
    ST Z+, R16               ; Grava em C e avança Z

    ; --- Restauração de Contexto (Desempilhamento em Ordem Inversa LIFO) ---
    POP R16                  ; Desempilha o estado do SREG salvo anteriormente
    OUT SREG, R16            ; Restaura o registrador SREG
    
    POP R17                  ; Restaura o valor original de R17
    POP R16                  ; Restaura o valor original de R16
    
    RET                      ; Retorna ao programa principal
