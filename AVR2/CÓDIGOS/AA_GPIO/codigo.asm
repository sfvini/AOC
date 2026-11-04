.INCLUDE <m328Pdef.inc>     ; Inclui a biblioteca de definições do ATmega328P (mapeamento de registradores)

.EQU AJUSTE  = PB1          ; Define a constante AJUSTE como o pino 1 da Porta B (PB1)
.EQU SELECAO = PB2          ; Define a constante SELECAO como o pino 2 da Porta B (PB2)

setup:
    LDI  R16, 0xFF          ; Carrega o valor 0xFF (binário: 11111111) no registrador de uso geral R16
    OUT  DDRD, R16          ; Configura todos os 8 pinos da PORTD como SAÍDA (escrevendo 1s no Data Direction Register D)

    CBI  DDRB, AJUSTE       ; Configura o pino AJUSTE (PB1) como ENTRADA (limpa o bit correspondente no DDRB para 0)
    SBI  PORTB, AJUSTE      ; Habilita o resistor de PULL-UP interno para o pino AJUSTE (escreve 1 no PORTB enquanto é entrada)
    
    CBI  DDRB, SELECAO      ; Configura o pino SELECAO (PB2) como ENTRADA (limpa o bit correspondente no DDRB para 0)
    SBI  PORTB, SELECAO     ; Habilita o resistor de PULL-UP interno para o pino SELECAO

loop:
    LDI  R16, 0x00          ; Carrega 0x00 no R16. Este será o estado base da PORTD (todos os LEDs/saídas desligados)

    SBIS PINB, AJUSTE       ; Testa o pino AJUSTE. Se estiver em nível ALTO (1, não pressionado), pula a próxima instrução
    ORI  R16, 0x0F          ; (Só executa se pressionado = 0) Faz uma operação OR com 0x0F, ligando os 4 bits menos significativos de R16 (00001111)

    SBIS PINB, SELECAO      ; Testa o pino SELECAO. Se estiver em nível ALTO (1, não pressionado), pula a próxima instrução
    ORI  R16, 0xF0          ; (Só executa se pressionado = 0) Faz uma operação OR com 0xF0, ligando os 4 bits mais significativos de R16 (11110000)

    OUT  PORTD, R16         ; Atualiza a saída da PORTD com o valor final processado em R16
    RJMP loop               ; Salta de volta para o rótulo "loop", criando um ciclo infinito
