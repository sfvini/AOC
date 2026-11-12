.INCLUDE <m328Pdef.inc>     ; Inclui a biblioteca de definições do ATmega328P

.EQU RST     = PB1          ; Define a constante RST como o pino 1 da Porta B (PB1) - Botão Reset
.EQU INC_DEC = PB2          ; Define a constante INC_DEC como o pino 2 da Porta B (PB2) - Botão de incremento/decremento

.DEF AUX     = R16          ; Apelida o registrador R16 como AUX (uso geral)
.DEF COUNT_B = R17          ; Apelida o registrador R17 como COUNT_B (vai contar de 0 a 15)
.DEF COUNT_C = R18          ; Apelida o registrador R18 como COUNT_C (vai contar de 15 a 0)

setup:
    LDI  AUX, 0xFF          ; Carrega 0xFF (tudo 1) em AUX
    OUT  DDRD, AUX          ; Configura todos os pinos da PORTD como SAÍDA (vai exibir os contadores)

    CBI  DDRB, RST          ; Configura o pino RST (PB1) como ENTRADA
    SBI  PORTB, RST         ; Habilita o resistor de Pull-up interno no pino RST (mantém em 1 quando solto)
    
    CBI  DDRB, INC_DEC      ; Configura o pino INC_DEC (PB2) como ENTRADA
    SBI  PORTB, INC_DEC     ; Habilita o resistor de Pull-up interno no pino INC_DEC
    
    CLR  COUNT_B            ; Zera o contador B (inicia em 0)
    LDI  COUNT_C, 15        ; Carrega 15 (0x0F) no contador C (inicia no máximo)

    ; Preparar estado inicial da saída (PORTD exibe COUNT_C nos 4 bits mais significativos e COUNT_B nos 4 menos significativos)
    MOV  AUX, COUNT_C       ; Copia o valor de COUNT_C para AUX
    SWAP AUX                ; Troca os 4 bits altos com os 4 baixos de AUX (ex: 0x0F vira 0xF0)
    OR   AUX, COUNT_B       ; Faz operação OR com COUNT_B (junta os dois valores num só byte, ex: 0xF0 OR 0x00 = 0xF0)
    OUT  PORTD, AUX         ; Escreve o byte combinado na PORTD (estado inicial dos LEDs/displays)

main:
    ; Verifica botão de Reset
    SBIC PINB, RST          ; Testa o pino RST. Se for 0 (botão pressionado), não pula. Se 1 (solto), pula a próxima instrução
    RJMP inc_dec            ; Como o botão está solto, salta para checar o outro botão

    ; Executa o Reset (se passou pelo SBIC, RST foi pressionado)
    CLR  COUNT_B            ; Zera o contador B
    LDI  COUNT_C, 15        ; Restaura o contador C para 15
    RJMP atualizar_saida    ; Salta para atualizar a saída imediatamente

inc_dec:
    ; Verifica botão de Incremento/Decremento
    SBIC PINB, INC_DEC      ; Testa o pino INC_DEC. Se solto (1), pula a próxima instrução
    RJMP main               ; Botão solto, volta para o início do laço (main)

    ; Executa se o botão INC_DEC foi pressionado
    CPI  COUNT_B, 15        ; Compara COUNT_B com o limite máximo (15)
    BREQ espera_soltar      ; Se for igual a 15, não faz nada e salta para aguardar soltar o botão (Branch if Equal)

    ; Atualiza os contadores
    INC  COUNT_B            ; Incrementa COUNT_B (+1)
    DEC  COUNT_C            ; Decrementa COUNT_C (-1)

atualizar_saida:
    ; Junta os contadores em um byte e envia para a saída
    MOV  AUX, COUNT_C       ; Copia COUNT_C para AUX
    SWAP AUX                ; Desloca COUNT_C para os 4 bits mais significativos (Nibble alto)
    OR   AUX, COUNT_B       ; Adiciona COUNT_B nos 4 bits menos significativos (Nibble baixo)
    OUT  PORTD, AUX         ; Atualiza a porta D com a nova combinação de valores

espera_soltar:
    ; Anti-repetição (Evita incrementar dezenas de vezes com apenas 1 clique devido à velocidade do clock)
    SBIS PINB, INC_DEC      ; Testa o pino INC_DEC. Se for 1 (botão solto), pula o RJMP
    RJMP espera_soltar      ; Se continua pressionado (0), fica travado aqui neste loop

    RJMP main               ; Quando finalmente soltar o botão, volta para o laço principal
