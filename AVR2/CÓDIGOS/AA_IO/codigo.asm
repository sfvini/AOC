.INCLUDE <m328Pdef.inc>     ; Inclui a biblioteca de definições de registradores do ATmega328P

; --- Segmento de Dados (Memória SRAM) ---
.DSEG                       ; Inicia o segmento de dados (Data Segment)
.ORG SRAM_START             ; Define a origem no endereço inicial da SRAM (0x0100 no ATmega328P)

    Count: .BYTE 1          ; Reserva 1 byte na memória SRAM e o associa ao rótulo "Count"

; --- Segmento de Código (Memória Flash) ---
.CSEG                       ; Inicia o segmento de código (Code Segment)
.ORG 0x0000                 ; Define a origem no vetor de Reset (endereço 0x0000)
    RJMP START              ; Salta para a rotina de inicialização (START)

START:
    ; Inicialização do Stack Pointer (Pilha) - Necessário para RCALL, PUSH, POP
    LDI R16, HIGH(RAMEND)   ; Carrega o byte mais significativo do fim da SRAM
    OUT SPH, R16            ; Escreve no registrador Stack Pointer High
    LDI R16, LOW(RAMEND)    ; Carrega o byte menos significativo do fim da SRAM
    OUT SPL, R16            ; Escreve no registrador Stack Pointer Low

    ; Inicialização das "Flags" (GPIOR0 é um registrador de propósito geral, muito usado para flags booleanas)
    CBI GPIOR0, 7           ; Zera o bit 7 do registrador GPIOR0
    CBI GPIOR0, 2           ; Zera o bit 2 do registrador GPIOR0

LOOP:
    ; Simula a leitura de um botão lendo uma flag (bit 3 do GPIOR0)
    SBIC GPIOR0, 3          ; Salta a próxima instrução se o bit 3 de GPIOR0 for 0 (botão solto)
    RJMP BOTAO_PRESS        ; Se o bit 3 for 1, não salta e vem para cá (vai para rotina de botão pressionado)

BOTAO_NAO_PRESS:
    ; Ação quando o botão não está pressionado (mantém flags desativadas)
    CBI GPIOR0, 7           ; Garante que o bit 7 de GPIOR0 seja 0
    CBI GPIOR0, 2           ; Garante que o bit 2 de GPIOR0 seja 0

    RJMP LOOP               ; Retorna ao início do laço

BOTAO_PRESS:
    ; Ação quando o botão está pressionado (comportamento estilo "Pisca-Pisca" usando flags)
    SBI GPIOR0, 7           ; Seta (coloca em 1) o bit 7 de GPIOR0
    SBI GPIOR0, 2           ; Seta (coloca em 1) o bit 2 de GPIOR0

    RCALL ATRASO            ; Chama a sub-rotina de atraso

    CBI GPIOR0, 7           ; Zera o bit 7 de GPIOR0
    CBI GPIOR0, 2           ; Zera o bit 2 de GPIOR0

    RCALL ATRASO            ; Chama a sub-rotina de atraso

    RJMP LOOP               ; Retorna ao início do laço

; --- SUB-ROTINA DE ATRASO ---
ATRASO:
    ; 1. Salvar contexto na Pilha
    PUSH R16                ; Salva R16
    PUSH R17                ; Salva R17
    PUSH R18                ; Salva R18
    IN R16, SREG            ; Lê o registrador de status (SREG)
    PUSH R16                ; Salva o SREG na pilha

    ; 2. Configurar o contador externo usando a variável "Count" na SRAM
    LDI R16, 20             ; Carrega o valor 20 em R16 (Loop externo)
    STS Count, R16          ; Salva este valor na variável "Count" na memória SRAM

LOOP_ATRASO_EXT:
    LDI R17, 200            ; Carrega 200 no R17 (Loop intermediário)
LOOP_ATRASO_MID:
    LDI R18, 250            ; Carrega 250 no R18 (Loop interno)
LOOP_ATRASO_INT:
    DEC R18                 ; Decrementa R18
    BRNE LOOP_ATRASO_INT    ; Se R18 não for 0, repete o loop interno

    DEC R17                 ; Decrementa R17
    BRNE LOOP_ATRASO_MID    ; Se R17 não for 0, repete o loop intermediário

    ; Decremento do loop externo acessando a SRAM
    LDS R16, Count          ; Lê o valor atual de "Count" da SRAM para o R16
    DEC R16                 ; Decrementa R16
    STS Count, R16          ; Salva o novo valor de volta na variável "Count" na SRAM
    BRNE LOOP_ATRASO_EXT    ; Se "Count" não for 0, repete todo o ciclo externo

    ; 3. Restaurar contexto da Pilha
    POP R16                 ; Recupera o SREG salvo
    OUT SREG, R16           ; Restaura o SREG
    POP R18                 ; Recupera R18
    POP R17                 ; Recupera R17
    POP R16                 ; Recupera R16

    RET                     ; Retorna para o ponto onde a sub-rotina foi chamada
