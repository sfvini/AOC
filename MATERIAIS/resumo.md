# Guia Prático de Programação em Assembly AVR para ATmega328P

A programação em linguagem Assembly para a arquitetura AVR de 8 bits, especificamente para o microcontrolador ATmega328P, oferece controle absoluto sobre a execução do processador, a organização da memória e a manipulação de periféricos de Entrada e Saída (E/S). O desenvolvimento em baixo nível exige o domínio da sintaxe do montador, das diretivas de alocação, dos modos de endereçamento da SRAM, do controle do Registrador de Status (`SREG`) e da mecânica de Pilha (*Stack*) para a construção de sub-rotinas modulares. Este documento apresenta uma síntese técnica detalhada da programação em Assembly AVR, fundamentada nas especificações oficiais do ATmega328P, acompanhada por programas de referência integralmente comentados linha a linha.

---

## 1. Estrutura do Arquivo Fonte, Diretivas do Montador e Mapeamento de Memória

O processo de compilação e montagem transforma o código-fonte em linguagem Assembly (`.ASM`) nos códigos de operação de máquina (*opcodes*) de 16 bits executados pelo núcleo do microcontrolador AVR.

### 1.1 Sintaxe de Linha e Estrutura do Arquivo Fonte

No montador padrão (`avrasm2`), cada linha do arquivo de código-fonte é estruturada em até quatro campos funcionais:

```assembly
[Rótulo:]  Instrução ou Diretiva  [Operandos]  [; Comentários]
```

A especificação de cada campo segue regras bem definidas:

*   **Rótulo (*Label*)**: Identificador opcional terminado em dois-pontos (`:`). Associa um nome simbólico ao endereço de memória de programa (Flash) ou de dados (SRAM) onde a instrução ou variável está alocada.
*   **Instruções vs. Diretivas**: 
    *   **Instrução**: Comando traduzido diretamente em um *opcode* executável pela CPU (ex.: `ADD`, `LDS`, `RCALL`).
    *   **Diretiva**: Ordem direcionada ao programa montador (*assembler*) durante o tempo de compilação. Não gera código executável diretamente, mas gerencia a alocação de memória e definição de símbolos.
*   **Operandos**: Registradores, endereços ou constantes numéricas manipulados pela instrução ou diretiva.
*   **Comentários**: Todo texto subsequente ao caractere ponto e vírgula (`;`) ou barra dupla (`//`) é ignorado pelo montador, servindo exclusivamente para documentação.

### 1.2 Diretivas Fundamentais do Montador

As diretivas orientam como a memória é reservada e como as constantes são mapeadas antes da gravação no microcontrolador.

| Diretiva | Segmento | Descrição Funcional | Exemplo de Aplicação |
| :--- | :--- | :--- | :--- |
| `.INCLUDE` | Geral | Inclui o arquivo de cabeçalho padrão com as definições do chip. | `.INCLUDE <m328Pdef.inc>` |
| `.CSEG` | Código | Seleciona o segmento de memória de programa Flash (*Code Segment*). | `.CSEG` |
| `.DSEG` | Dados | Seleciona o segmento de memória de dados SRAM (*Data Segment*). | `.DSEG` |
| `.ESEG` | EEPROM | Seleciona o segmento de memória não-volátil EEPROM (*EEPROM Segment*). | `.ESEG` |
| `.ORG` | Todos | Define o endereço de origem (*Origin*) das instruções ou variáveis. | `.ORG SRAM_START` |
| `.BYTE` | Dados | Reserva um bloco de bytes não inicializados na SRAM. | `A1: .BYTE 10` |
| `.DB` | Código | Grava bytes constantes diretamente na memória Flash. | `tabela: .DB 1, 2, 3, 4` |
| `.DW` | Código | Grava palavras (*words* de 16 bits) constantes na memória Flash. | `dados: .DW 0x1234` |
| `.DEF` | Geral | Define um nome simbólico (apelido) para um registrador de uso geral. | `.DEF temp = R16` |
| `.EQU` | Geral | Define uma constante simbólica imutável atribuída a uma expressão. | `.EQU LED = PB5` |
| `.SET` | Geral | Define uma constante simbólica redefinível ao longo do código. | `.SET conta = 0` |

### 1.3 Mapeamento de Memória do ATmega328P

O ATmega328P é fundamentado na arquitetura Harvard Modificada, possuindo barramentos e espaços de endereçamento separados para código e dados:

1.  **Memória de Programa Flash (`.CSEG`)**:
    *   Tamanho total: 32 KB organizada em 16K palavras de 16 bits (endereços de `0x0000` a `0x3FFF`).
    *   Endereço `0x0000`: Vetor de Reset. Armazena tradicionalmente a instrução de salto inicial (`RJMP START`).
    *   Endereços `0x0002` a `0x0032`: Vetores de Interrupção do sistema.
2.  **Memória de Dados SRAM (`.DSEG`)**:
    *   O espaço de endereçamento contíguo da memória de dados abrange de `0x0000` a `0x08FF` (2304 posições):
        *   `0x0000` a `0x001F` (32 bytes): Registradores de Uso Geral (`R0` a `R31`).
        *   `0x0020` a `0x005F` (64 bytes): Registradores de Entrada/Saída padrão (E/S).
        *   `0x0060` a `0x00FF` (160 bytes): Registradores de E/S Estendida.
        *   `0x0100` a `0x08FF` (2048 bytes): SRAM Interna do Usuário (`SRAM_START` = `0x0100`, `RAMEND` = `0x08FF`).

```
    [ Espaço de Endereçamento de Dados SRAM - ATmega328P ]
    +----------------------------------------------------+
    | 0x0000 - 0x001F : 32 Registradores de Uso Geral   |
    |                   (R0 até R31)                     |
    +----------------------------------------------------+
    | 0x0020 - 0x005F : 64 Registradores de E/S Padrão   |
    |                   (PORTB, DDRB, SREG, SPL, SPH...) |
    +----------------------------------------------------+
    | 0x0060 - 0x00FF : 160 Registradores de E/S Ext.   |
    +----------------------------------------------------+
    | 0x0100 - 0x08FF : 2048 Bytes de SRAM Interna       |
    |                   (SRAM_START até RAMEND)          |
    +----------------------------------------------------+
```

### 1.4 Regras e Restrições do Banco de Registradores (`R0`–`R31`)

Os 32 registradores de propósito geral de 8 bits oferecem acesso em um único ciclo de clock para a Unidade Lógica e Aritmética (ULA). Contudo, a arquitetura impõe restrições funcionais dependendo da faixa de registradores:

*   **Faixa `R0` a `R15` (Registradores Puros)**:
    *   **Restrição crítica**: Não aceitam operações com valores imediatos (*constants*). Instruções como `LDI`, `CPI`, `SUBI`, `SBCI`, `ANDI` e `ORI` **não compilam** se aplicadas a registradores entre `R0` e `R15`.
    *   Registradores `R0` e `R1` possuem funções especiais: `R0` armazena o dado lido da Flash via `LPM`, e o par `R1:R0` guarda o resultado de 16 bits de multiplicações (`MUL`).
*   **Faixa `R16` a `R31` (Registradores com Suporte a Imediatos)**:
    *   Possuem circuitos internos dedicados para decodificar constantes de 8 bits fornecidas diretamente na instrução (`LDI R16, 0xFF`).
*   **Registradores Ponteiro de 16 bits (`X`, `Y`, `Z`)**:
    *   Os últimos seis registradores são combinados em pares de 8 bits para formar ponteiros de 16 bits para endereçamento da SRAM:
        *   **Ponteiro X**: Formado obrigatoriamente por `R27` (parte alta, `XH`) e `R26` (parte baixa, `XL`).
        *   **Ponteiro Y**: Formado obrigatoriamente por `R29` (parte alta, `YH`) e `R28` (parte baixa, `YL`).
        *   **Ponteiro Z**: Formado obrigatoriamente por `R31` (parte alta, `ZH`) e `R30` (parte baixa, `ZL`).

### 1.5 Estrutura Básica de Alocação e Código Comentado

O código a seguir exemplifica a declaração de variáveis na SRAM e a estrutura inicial em memória Flash:

```assembly
.INCLUDE <m328Pdef.inc>     ; Inclui o arquivo de cabeçalho padrão com definições de I/O e SRAM_START

.DSEG                       ; Seleciona a seção de memória de dados (SRAM)
.ORG SRAM_START             ; Define a origem da alocação no endereço 0x0100 (início da SRAM do usuário)

    var1: .BYTE 1           ; Aloca 1 byte na SRAM no endereço 0x0100 (rotulado como var1)
    var2: .BYTE 2           ; Aloca 2 bytes contíguos na SRAM a partir de 0x0101 (var2 = 0x0101, var2+1 = 0x0102)

.CSEG                       ; Seleciona a seção de memória de código (Flash)
.ORG 0x0000                 ; Define o endereço inicial na memória Flash (Vetor de Reset)

start:                      ; Rótulo de início da execução do programa
    LDI R16, 0xFF           ; Carrega o valor constante 0xFF no registrador de trabalho R16
    STS var1, R16           ; Armazena o conteúdo de R16 na posição var1 (0x0100) da SRAM

    LDI XL, LOW(var2)       ; Extrai os 8 bits menos significativos do endereço var2 (0x01) e carrega em XL (R26)
    LDI XH, HIGH(var2)      ; Extrai os 8 bits mais significativos do endereço var2 (0x01) e carrega em XH (R27)
    ST X, R16               ; Escreve o conteúdo de R16 no endereço apontado por X (0x0101)

fim:
    RJMP fim                ; Salto relativo contínuo para o rótulo 'fim' (loop infinito de encerramento)
```

---

## 2. Os 5 Modos de Endereçamento da Memória SRAM

A arquitetura AVR disponibiliza cinco modos distintos para acessar a memória de dados SRAM. A escolha do modo ideal otimiza tanto a velocidade de execução quanto o tamanho do código executável.

### 2.1 Endereçamento Direto (`LDS` / `STS`)

No modo direto, o endereço absoluto de 16 bits da posição da SRAM está codificado diretamente dentro da própria instrução (ocupando 32 bits / 2 palavras de memória de programa).

*   **Sintaxe**: `LDS Rd, k` (Carrega do endereço `k` para `Rd`) e `STS k, Rr` (Grava de `Rr` no endereço `k`).
*   **Propriedades**: Não exige e não altera nenhum registrador ponteiro.
*   **Uso ideal**: Acesso a variáveis escalares simples e isoladas na SRAM.

```assembly
LDS R16, 0x0100             ; Lê o byte armazenado no endereço fixo 0x0100 e armazena em R16
STS 0x0104, R16             ; Escreve o valor do registrador R16 no endereço absoluto 0x0104
```

### 2.2 Endereçamento Indireto Simples (`LD` / `ST`)

O endereço da SRAM a ser acessado está previamente carregado em um dos pares de registradores ponteiro ($X$, $Y$ ou $Z$).

*   **Sintaxe**: `LD Rd, index` e `ST index, Rr` (onde `index` pode ser `X`, `Y` ou `Z`).
*   **Propriedades**: O valor armazenado no ponteiro **não sofre nenhuma alteração** após o acesso.
*   **Uso ideal**: Acesso repetido a uma posição de memória cujo endereço foi calculado dinamicamente.

```assembly
LDI XL, LOW(0x0100)         ; Carrega os 8 bits menos significativos do endereço em XL (R26)
LDI XH, HIGH(0x0100)        ; Carrega os 8 bits mais significativos do endereço em XH (R27) -> X = 0x0100
LD R16, X                   ; Lê a SRAM no endereço apontado por X (0x0100). Ponteiro X não se altera
ST X, R17                   ; Grava R17 no endereço apontado por X (0x0100). Ponteiro X permanece em 0x0100
```

### 2.3 Endereçamento Indireto com Pós-Incremento (`LD Rd, X+` / `ST X+, Rr`)

Acessa a SRAM no endereço apontado pelo ponteiro ($X$, $Y$ ou $Z$) e, **imediatamente após o acesso**, incrementa automaticamente o ponteiro em $+1$.

*   **Sintaxe**: `LD Rd, X+`, `LD Rd, Y+`, `LD Rd, Z+` / `ST X+, Rr`, `ST Y+, Rr`, `ST Z+, Rr`.
*   **Dinâmica Temporal**: "Lê/Escreve no endereço atual $\rightarrow$ Soma $+1$ ao ponteiro".
*   **Uso ideal**: Varredura sequencial de vetores do início em direção ao fim (endereços crescentes).

```assembly
LD R16, X+                  ; 1. Lê o dado no endereço atualmente apontado por X
                            ; 2. Incrementa o ponteiro X em +1 (X = X + 1) automaticamente
```

### 2.4 Endereçamento Indireto com Pré-Decremento (`LD Rd, -X` / `ST -X, Rr`)

Decrementa automaticamente o valor do ponteiro ($X$, $Y$ ou $Z$) em $-1$ **antes de realizar o acesso** e, em seguida, efetua a leitura ou escrita na nova posição.

*   **Sintaxe**: `LD Rd, -X`, `LD Rd, -Y`, `LD Rd, -Z` / `ST -X, Rr`, `ST -Y, Rr`, `ST -Z, Rr`.
*   **Dinâmica Temporal**: "Subtrai $-1$ do ponteiro $\rightarrow$ Lê/Escreve no novo endereço".
*   **Uso ideal**: Varredura inversa de vetores (do fim para o início) ou implementação manual de pilhas.

```assembly
LD R16, -X                  ; 1. Decrementa o ponteiro X em -1 (X = X - 1) primeiro
                            ; 2. Lê o dado armazenado no novo endereço apontado por X
```

### 2.5 Endereçamento Indireto com Deslocamento (`LDD` / `STD`)

Acessa a memória somando uma constante de deslocamento (*offset*) $q$ ao endereço contido no ponteiro. **O valor armazenado no ponteiro permanece estático na base**.

*   **Sintaxe**: `LDD Rd, Y+q` ou `LDD Rd, Z+q` / `STD Y+q, Rr` ou `STD Z+q, Rr` (onde $0 \le q \le 63$).
*   **Restrição Crítica de Hardware**: Funciona **exclusivamente com os ponteiros $Y$ e $Z$**. O ponteiro $X$ **não suporta** as instruções `LDD` / `STD`.
*   **Uso ideal**: Acesso a campos de estruturas de dados (*structs*) ou elementos de vetores mantendo o ponteiro fixo na base.

```assembly
LDI YL, LOW(0x0100)         ; Carrega byte baixo do endereço base em YL (R28)
LDI YH, HIGH(0x0100)        ; Carrega byte alto do endereço base em YH (R29) -> Ponteiro Y fixo em 0x0100
LDD R16, Y+0                ; Lê a posição 0x0100 (Y+0)
LDD R17, Y+4                ; Lê a posição 0x0104 (Y+4). O ponteiro Y continua valendo 0x0100
STD Y+8, R16                ; Grava R16 na posição 0x0108 (Y+8). Ponteiro Y permanece em 0x0100
```

### 2.6 Tabela Comparativa Consolidada dos Modos de Endereçamento

| Modo de Endereçamento | Instrução de Leitura | Instrução de Escrita | Ponteiros Aceitos | Alteração no Ponteiro | Tamanho da Instrução |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Direto** | `LDS Rd, k` | `STS k, Rr` | Nenhum (Endereço fixo `k`) | Não se aplica | 2 palavras (32 bits) |
| **2. Indireto Simples** | `LD Rd, Index` | `ST Index, Rr` | $X$, $Y$, $Z$ | Nenhuma | 1 palavra (16 bits) |
| **3. Pós-Incremento** | `LD Rd, Index+` | `ST Index+, Rr` | $X$, $Y$, $Z$ | Soma $+1$ **após** o acesso | 1 palavra (16 bits) |
| **4. Pré-Decremento** | `LD Rd, -Index` | `ST -Index, Rr` | $X$, $Y$, $Z$ | Subtrai $-1$ **antes** do acesso | 1 palavra (16 bits) |
| **5. Deslocamento** | `LDD Rd, Y+q` / `Z+q` | `STD Y+q, Rr` / `Z+q` | **Apenas $Y$ e $Z$** (Ponteiro $X$ **NÃO**) | Nenhuma (Ponteiro fica estático na base) | 1 palavra (16 bits) |

---

## 3. Conjunto de Instruções, Registrador de Status e Controle de Fluxo

A criação de algoritmos condicionais e laços de repetição em Assembly depende da avaliação das flags do Registrador de Status e de instruções de salto.

### 3.1 Registrador de Status (`SREG`)

O registrador `SREG` (endereço de E/S `0x3F`) armazena os sinalizadores (*flags*) atualizados pela Unidade Lógica e Aritmética (ULA) após operações.

```
    Bit:    7    6    5    4    3    2    1    0
         +----+----+----+----+----+----+----+----+
  SREG:  | I  | T  | H  | S  | V  | N  | Z  | C  |
         +----+----+----+----+----+----+----+----+
```

*   **Bit 7 — `I` (*Global Interrupt Enable*)**: Habilita (1) ou desabilita (0) as interrupções globais do sistema.
*   **Bit 6 — `T` (*Bit Copy Storage*)**: Bit de transferência temporária utilizado pelas instruções `BST` e `BLD`.
*   **Bit 5 — `H` (*Half Carry Flag*)**: Indica transporte do bit 3 para o bit 4 (utilizado em aritmética BCD).
*   **Bit 4 — `S` (*Sign Bit*)**: Sinal real da operação em complemento de dois ($S = N \oplus V$).
*   **Bit 3 — `V` (*Two's Complement Overflow Flag*)**: Indica estouro de capacidade em operações com sinal.
*   **Bit 2 — `N` (*Negative Flag*)**: Reflete o bit mais significativo (bit 7) do resultado (1 se negativo).
*   **Bit 1 — `Z` (*Zero Flag*)**: Indica que o resultado da última operação foi exatamente zero (1 se zero).
*   **Bit 0 — `C` (*Carry Flag*)**: Indica transporte (*carry*) em adições ou empréstimo (*borrow*) em subtrações.

> **Regra de Modificação de Flags**: Instruções de movimentação de dados (`LDI`, `MOV`, `LDS`, `STS`, `LD`, `ST`, `PUSH`, `POP`, `IN`, `OUT`) **não alteram as flags do SREG**. Instruções aritméticas (`ADD`, `ADC`, `SUB`, `SBC`, `CP`, `CPI`) atualizam as flags de condição.

### 3.2 Padrões de Laços de Repetição (Loops) Totalmente Comentados

Abaixo são apresentados os três padrões universais para implementação de laços em Assembly AVR.

#### Padrão 1: Loop Contado Regressivo (`DEC` + `BRNE`)

Este é o padrão de loop mais eficiente na arquitetura AVR. Um registrador contador é decrementado a cada iteração até atingir zero (`Z = 1`).

```assembly
    LDI R17, 10             ; Carrega o registrador R17 com o número total de iterações (10)

loop_regressivo:
    ; ... [ Bloco de instruções a ser executado no loop ] ...

    DEC R17                 ; Subtrai 1 de R17. Quando R17 atinge 0, ativa a flag Z=1 no SREG
                            ; NOTA: A instrução DEC NÃO altera a flag Carry (C)!
    BRNE loop_regressivo    ; Salta para 'loop_regressivo' se a flag Z == 0 (enquanto R17 != 0)
```

#### Padrão 2: Loop Condicional com Comparação (`CPI` + `BRNE`)

Utilizado quando a condição de saída depende da comparação com um valor limite específico.

```assembly
    CLR R16                 ; Zera o registrador R16 (R16 = 0)

loop_comparacao:
    INC R16                 ; Soma +1 ao registrador R16

    CPI R16, 5              ; Compara o conteúdo de R16 com a constante 5 (atualiza SREG sem alterar R16)
    BRNE loop_comparacao    ; Salta de volta para 'loop_comparacao' enquanto R16 for diferente de 5
```

#### Padrão 3: Loop Infinito (`RJMP`)

Utilizado ao término do programa principal para travar o processador em um laço seguro.

```assembly
fim_programa:
    RJMP fim_programa       ; Salto relativo incondicional contínuo para o próprio rótulo
```

---

## 4. Mecânica de Pilha, Stack Pointer e Sub-rotinas Modulares

A implementação de chamadas de sub-rotina (`RCALL` / `RET`) exige a alocação e o gerenciamento correto da **Pilha (*Stack*)** na memória SRAM.

### 4.1 Estrutura da Pilha e o Registrador Stack Pointer (`SP`)

A Pilha é uma estrutura de dados LIFO (*Last-In, First-Out*) alocada na SRAM para armazenar endereços de retorno de funções e preservar registradores de trabalho.

*   **Direção do Crescimento**: Na arquitetura AVR, a pilha cresce **de cima para baixo** (dos endereços mais altos da SRAM em direção aos endereços menores).
*   **Stack Pointer (`SP`)**: Registrador de E/S de 16 bits dividido em `SPH` (endereço `0x3E`) e `SPL` (endereço `0x3D`). Aponta para o topo atual da pilha.
*   **Inicialização Padrão**: Deve ser configurado no início do programa para apontar para o último endereço da SRAM (`RAMEND` = `0x08FF` no ATmega328P).

```assembly
; Configuração Padrão e Obrigatória do Stack Pointer
LDI R16, HIGH(RAMEND)       ; Carrega a parte alta do endereço final da RAM (0x08) em R16
OUT SPH, R16                ; Escreve no registrador SPH
LDI R16, LOW(RAMEND)        ; Carrega a parte baixa do endereço final da RAM (0xFF) em R16
OUT SPL, R16                ; Escreve no registrador SPL -> SP aponta para 0x08FF
```

### 4.2 Operações da Pilha e Variação do Stack Pointer

| Instrução | Operandos | Variação do Stack Pointer (`SP`) | Descrição Detalhada da Operação |
| :--- | :--- | :--- | :--- |
| `PUSH` | `Rr` | **Decrementa em 1** (`SP` $\leftarrow$ `SP - 1`) | Copia o conteúdo de 1 byte de `Rr` para a posição apontada por `SP` e decrementa `SP`. |
| `POP` | `Rd` | **Incrementa em 1** (`SP` $\leftarrow$ `SP + 1`) | Incrementa `SP` em 1 e copia o byte armazenado no novo topo da pilha para `Rd`. |
| `RCALL` / `CALL` | `k` | **Decrementa em 2** (`SP` $\leftarrow$ `SP - 2`) | Empilha o endereço de retorno de 2 bytes (`PC + 1`) e salta para a sub-rotina. |
| `RET` / `RETI` | Nenhum | **Incrementa em 2** (`SP` $\leftarrow$ `SP + 2`) | Desempilha 2 bytes da pilha, carrega-os no *Program Counter* (`PC`) e retorna. |

### 4.3 Prática do Salvamento e Restauração de Contexto

Uma sub-rotina deve salvar o estado dos registradores de trabalho e do `SREG` no início e restaurá-los na **ordem rigorosamente inversa** antes de retornar.

```assembly
subrotina_exemplo:
    ; --- 1. Salvamento de Contexto (PUSH) ---
    PUSH R16                ; Salva o valor original do registrador R16 na pilha
    PUSH R17                ; Salva o valor original do registrador R17 na pilha
    IN R16, SREG            ; Lê as flags de estado atuais do SREG para R16
    PUSH R16                ; Salva a cópia do SREG na pilha

    ; --- 2. Corpo e Execução do Trabalho da Sub-rotina ---
    ; ... [ Operações lógicas ou aritméticas ] ...

    ; --- 3. Restauração de Contexto (POP na Ordem Inversa) ---
    POP R16                 ; Desempilha a cópia das flags do SREG
    OUT SREG, R16           ; Restaura o SREG original do sistema
    POP R17                 ; Restaura o valor original do registrador R17
    POP R16                 ; Restaura o valor original do registrador R16

    RET                     ; Retorna ao programa principal
```

---

## 5. Programas Práticos de Referência Comentados Linha a Linha

Esta seção reúne quatro programas completos em Assembly AVR, cobrindo operações com 32 bits, manipulação de vetores, sub-rotinas modulares e controle de I/O com temporização.

### 5.1 Aplicação 1: Soma de Variáveis de 32 bits ($C = A + B$) em 4 Modos de Endereçamento

O programa a seguir executa a soma de duas variáveis de 32 bits ($4\text{ bytes}$) na SRAM a partir do endereço `0x0100`, demonstrando individualmente a implementação via **Endereçamento Direto**, **Indireto Simples**, **Pós-Incremento** e **Deslocamento**.

```assembly
; ==============================================================================
; PROGRAMA 1: Soma de 32 bits (C = A + B) em 4 Modos de Endereçamento
; Arquitetura: ATmega328P | Montador: avrasm2
; Mapeamento SRAM: A (0x0100..0x0103), B (0x0104..0x0107), C (0x0108..0x010B)
; ==============================================================================

.INCLUDE <m328Pdef.inc>     ; Inclui arquivo de cabeçalho padrão para o ATmega328P

.DSEG                       ; Seleciona a seção de memória de dados (SRAM)
.ORG SRAM_START             ; Define o início do bloco em 0x0100
    A: .BYTE 4              ; Aloca 4 bytes para a variável A (0x0100 a 0x0103)
    B: .BYTE 4              ; Aloca 4 bytes para a variável B (0x0104 a 0x0107)
    C: .BYTE 4              ; Aloca 4 bytes para a variável C (0x0108 a 0x010B)

.CSEG                       ; Seleciona a seção de memória de código (Flash)
.ORG 0x0000                 ; Endereço de origem do Vetor de Reset
    RJMP START              ; Salta para o início do programa principal

START:
    ; Inicialização Padrão do Stack Pointer
    LDI R16, HIGH(RAMEND)   ; Carrega 0x08 em R16
    OUT SPH, R16            ; Escreve em SPH
    LDI R16, LOW(RAMEND)    ; Carrega 0xFF em R16
    OUT SPL, R16            ; Escreve em SPL

; ==============================================================================
; IMPLEMENTAÇÃO 1: Endereçamento Direto (LDS / STS)
; ==============================================================================
    ; Byte 0 (LSB - Byte Menos Significativo)
    LDS R16, A              ; Carrega o Byte 0 de A (0x0100) para R16
    LDS R17, B              ; Carrega o Byte 0 de B (0x0104) para R17
    ADD R16, R17            ; Soma simples (ADD) no primeiro byte. Atualiza a flag Carry
    STS C, R16              ; Grava o resultado no Byte 0 de C (0x0108)

    ; Byte 1
    LDS R16, A+1            ; Carrega o Byte 1 de A (0x0101) para R16
    LDS R17, B+1            ; Carrega o Byte 1 de B (0x0105) para R17
    ADC R16, R17            ; Soma com Carry (ADC) para propagar o transporte anterior
    STS C+1, R16            ; Grava o resultado no Byte 1 de C (0x0109)

    ; Byte 2
    LDS R16, A+2            ; Carrega o Byte 2 de A (0x0102) para R16
    LDS R17, B+2            ; Carrega o Byte 2 de B (0x0106) para R17
    ADC R16, R17            ; Soma com Carry (ADC)
    STS C+2, R16            ; Grava o resultado no Byte 2 de C (0x010A)

    ; Byte 3 (MSB - Byte Mais Significativo)
    LDS R16, A+3            ; Carrega o Byte 3 de A (0x0103) para R16
    LDS R17, B+3            ; Carrega o Byte 3 de B (0x0107) para R17
    ADC R16, R17            ; Soma com Carry (ADC)
    STS C+3, R16            ; Grava o resultado no Byte 3 de C (0x010B)

; ==============================================================================
; IMPLEMENTAÇÃO 2: Endereçamento Indireto Simples (LD / ST com ADIW)
; ==============================================================================
    ; Configura os ponteiros X (para A), Y (para B) e Z (para C)
    LDI XL, LOW(A)          ; XL (R26) recebe o byte baixo de A (0x00)
    LDI XH, HIGH(A)         ; XH (R27) recebe o byte alto de A (0x01) -> X aponta para 0x0100
    LDI YL, LOW(B)          ; YL (R28) recebe o byte baixo de B (0x04)
    LDI YH, HIGH(B)         ; YH (R29) recebe o byte alto de B (0x01) -> Y aponta para 0x0104
    LDI ZL, LOW(C)          ; ZL (R30) recebe o byte baixo de C (0x08)
    LDI ZH, HIGH(C)         ; ZH (R31) recebe o byte alto de C (0x01) -> Z aponta para 0x0108

    ; Byte 0 (LSB)
    LD R16, X               ; Lê A[0] apontado por X para R16
    LD R17, Y               ; Lê B[0] apontado por Y para R17
    ADD R16, R17            ; Soma simples (ADD)
    ST Z, R16               ; Grava C[0] apontado por Z

    ; Avança ponteiros manualmente (+1 byte) usando ADIW
    ADIW XL, 1              ; Incrementa o par X (R27:R26) em +1 (X aponta para A+1)
    ADIW YL, 1              ; Incrementa o par Y (R29:R28) em +1 (Y aponta para B+1)
    ADIW ZL, 1              ; Incrementa o par Z (R31:R30) em +1 (Z aponta para C+1)

    ; Byte 1
    LD R16, X               ; Lê A[1]
    LD R17, Y               ; Lê B[1]
    ADC R16, R17            ; Soma com Carry (ADC)
    ST Z, R16               ; Grava C[1]

    ADIW XL, 1              ; Incrementa X em +1 (X aponta para A+2)
    ADIW YL, 1              ; Incrementa Y em +1 (Y aponta para B+2)
    ADIW ZL, 1              ; Incrementa Z em +1 (Z aponta para C+2)

    ; Byte 2
    LD R16, X               ; Lê A[2]
    LD R17, Y               ; Lê B[2]
    ADC R16, R17            ; Soma com Carry (ADC)
    ST Z, R16               ; Grava C[2]

    ADIW XL, 1              ; Incrementa X em +1 (X aponta para A+3)
    ADIW YL, 1              ; Incrementa Y em +1 (Y aponta para B+3)
    ADIW ZL, 1              ; Incrementa Z em +1 (Z aponta para C+3)

    ; Byte 3 (MSB)
    LD R16, X               ; Lê A[3]
    LD R17, Y               ; Lê B[3]
    ADC R16, R17            ; Soma com Carry (ADC)
    ST Z, R16               ; Grava C[3]

; ==============================================================================
; IMPLEMENTAÇÃO 3: Endereçamento Indireto com Pós-Incremento (LD X+ / ST Z+)
; ==============================================================================
    ; Reinicializa ponteiros no início das variáveis
    LDI XL, LOW(A) \ LDI XH, HIGH(A)   ; X aponta para base de A (0x0100)
    LDI YL, LOW(B) \ LDI YH, HIGH(B)   ; Y aponta para base de B (0x0104)
    LDI ZL, LOW(C) \ LDI ZH, HIGH(C)   ; Z aponta para base de C (0x0108)

    ; Byte 0 (LSB)
    LD R16, X+              ; Lê A[0] e incrementa X em +1 automaticamente
    LD R17, Y+              ; Lê B[0] e incrementa Y em +1 automaticamente
    ADD R16, R17            ; Soma simples
    ST Z+, R16              ; Grava C[0] e incrementa Z em +1 automaticamente

    ; Byte 1
    LD R16, X+              ; Lê A[1] e incrementa X em +1
    LD R17, Y+              ; Lê B[1] e incrementa Y em +1
    ADC R16, R17            ; Soma com Carry (ADC)
    ST Z+, R16              ; Grava C[1] e incrementa Z em +1

    ; Byte 2
    LD R16, X+              ; Lê A[2] e incrementa X em +1
    LD R17, Y+              ; Lê B[2] e incrementa Y em +1
    ADC R16, R17            ; Soma com Carry (ADC)
    ST Z+, R16              ; Grava C[2] e incrementa Z em +1

    ; Byte 3 (MSB)
    LD R16, X+              ; Lê A[3] e incrementa X em +1
    LD R17, Y+              ; Lê B[3] e incrementa Y em +1
    ADC R16, R17            ; Soma com Carry (ADC)
    ST Z+, R16              ; Grava C[3] e incrementa Z em +1

; ==============================================================================
; IMPLEMENTAÇÃO 4: Endereçamento Indireto com Deslocamento (LDD / STD)
; ==============================================================================
    ; Fixa um único ponteiro Y no endereço base da primeira variável (A = 0x0100)
    LDI YL, LOW(A)          ; YL recebe byte baixo de A
    LDI YH, HIGH(A)         ; YH recebe byte alto de A -> Ponteiro Y fixo em 0x0100

    ; Byte 0 (LSB): A está em Y+0, B está em Y+4, C está em Y+8
    LDD R16, Y+0            ; Lê A[0] no deslocamento Y+0 (0x0100)
    LDD R17, Y+4            ; Lê B[0] no deslocamento Y+4 (0x0104)
    ADD R16, R17            ; Soma simples
    STD Y+8, R16            ; Grava C[0] no deslocamento Y+8 (0x0108)

    ; Byte 1: A está em Y+1, B está em Y+5, C está em Y+9
    LDD R16, Y+1            ; Lê A[1] no deslocamento Y+1 (0x0101)
    LDD R17, Y+5            ; Lê B[1] no deslocamento Y+5 (0x0105)
    ADC R16, R17            ; Soma com Carry
    STD Y+9, R16            ; Grava C[1] no deslocamento Y+9 (0x0109)

    ; Byte 2: A está em Y+2, B está em Y+6, C está em Y+10
    LDD R16, Y+2            ; Lê A[2] no deslocamento Y+2 (0x0102)
    LDD R17, Y+6            ; Lê B[2] no deslocamento Y+6 (0x0106)
    ADC R16, R17            ; Soma com Carry
    STD Y+10, R16           ; Grava C[2] no deslocamento Y+10 (0x010A)

    ; Byte 3 (MSB): A está em Y+3, B está em Y+7, C está em Y+11
    LDD R16, Y+3            ; Lê A[3] no deslocamento Y+3 (0x0103)
    LDD R17, Y+7            ; Lê B[3] no deslocamento Y+7 (0x0107)
    ADC R16, R17            ; Soma com Carry
    STD Y+11, R16           ; Grava C[3] no deslocamento Y+11 (0x010B)

FIM_PROG1:
    RJMP FIM_PROG1          ; Loop infinito de encerramento
```

### 5.2 Aplicação 2: Processamento Avançado de Vetores na SRAM

O programa a seguir aloca e manipula quatro vetores na SRAM ($A_1, A_2, A_3, A_4$), aplicando preenchimento sequencial com pós-incremento, soma cruzada invertida combinando pós-incremento e pré-decremento, e acessos diretos via deslocamento (`LDD`).

```assembly
; ==============================================================================
; PROGRAMA 2: Processamento Avançado de Vetores na SRAM
; Aloca: A1 (10 bytes), A2 (10 bytes), A3 (10 bytes) e A4 (3 bytes)
; Operações:
;   1. Preenche A1 e A2 com a sequência de 1 a 10 (via pós-incremento).
;   2. Soma A1[i] com A2[9-i] (inverso) e guarda em A3[i] (pós-inc e pré-dec).
;   3. Soma A2[1]+A3[3], A2[3]+A3[4], A2[5]+A3[7] e guarda em A4 (via deslocamento).
; ==============================================================================

.INCLUDE <m328Pdef.inc>     ; Inclui definições do ATmega328P

.DSEG                       ; Segmento de memória de dados SRAM
.ORG SRAM_START             ; Endereço base 0x0100
    A1: .BYTE 10            ; Reserva 10 bytes para A1 (0x0100 a 0x0109)
    A2: .BYTE 10            ; Reserva 10 bytes para A2 (0x010A a 0x0113)
    A3: .BYTE 10            ; Reserva 10 bytes para A3 (0x0114 a 0x011D)
    A4: .BYTE 3             ; Reserva 3 bytes para A4  (0x011E a 0x0120)

.CSEG                       ; Segmento de memória de código Flash
.ORG 0x0000                 ; Vetor de Reset
    RJMP START              ; Salta para o início do programa

START:
    ; Inicialização do Stack Pointer
    LDI R16, HIGH(RAMEND) \ OUT SPH, R16   ; Configura parte alta do SP (0x08)
    LDI R16, LOW(RAMEND)  \ OUT SPL, R16   ; Configura parte baixa do SP (0xFF)

; ==============================================================================
; BLOCO 1: Preenchimento dos Vetores A1 e A2 com os valores de 1 a 10
; ==============================================================================
    LDI XL, LOW(A1) \ LDI XH, HIGH(A1)     ; Ponteiro X aponta para o início de A1 (0x0100)
    LDI YL, LOW(A2) \ LDI YH, HIGH(A2)     ; Ponteiro Y aponta para o início de A2 (0x010A)

    LDI R16, 1              ; R16 = 1 (Primeiro valor a ser gravado)
    LDI R17, 10             ; R17 = 10 (Contador de iterações do loop)

loop1:
    ST X+, R16              ; Escreve R16 em A1[i] e avança ponteiro X em +1
    ST Y+, R16              ; Escreve R16 em A2[i] e avança ponteiro Y em +1
    INC R16                 ; Incrementa o valor (gera a sequência 1, 2, 3... 10)
    DEC R17                 ; Decrementa o contador de iterações
    BRNE loop1              ; Repete o laço enquanto R17 != 0 (10 vezes)

; ==============================================================================
; BLOCO 2: Soma Invertida (A1[i] + A2[9-i] -> A3[i])
; ==============================================================================
    ; Reposiciona o ponteiro X no início de A1 (0x0100)
    LDI XL, LOW(A1) \ LDI XH, HIGH(A1)

    ; Posiciona o ponteiro Y exatamente 1 byte APÓS o fim de A2 (A2 + 10 = 0x0114)
    ; O primeiro pré-decremento (-Y) recuará Y para 0x0113 (A2[9], a última posição de A2!)
    LDI YL, LOW(A2 + 10) \ LDI YH, HIGH(A2 + 10)

    ; Configura o ponteiro Z no início de A3 (0x0114)
    LDI ZL, LOW(A3) \ LDI ZH, HIGH(A3)

    LDI R17, 10             ; Reinicia o contador para 10 iterações

loop2:
    LD R16, X+              ; Lê A1[i] e avança X do início para o fim
    LD R18, -Y              ; Decrementa Y PRIMEIRO (-1) e lê A2 de trás para frente (A2[9] até A2[0])
    ADD R16, R18            ; R16 = A1[i] + A2[9-i]
    ST Z+, R16              ; Grava o resultado em A3[i] e avança o ponteiro Z
    DEC R17                 ; Decrementa o contador de iterações
    BRNE loop2              ; Repete para as 10 posições

; ==============================================================================
; BLOCO 3: Somas Específicas com Deslocamento (LDD) Salvas em A4
; ==============================================================================
    LDI YL, LOW(A2) \ LDI YH, HIGH(A2)     ; Y fixado na base de A2 (0x010A)
    LDI ZL, LOW(A3) \ LDI ZH, HIGH(A3)     ; Z fixado na base de A3 (0x0114)
    LDI XL, LOW(A4) \ LDI XH, HIGH(A4)     ; X aponta para a base de A4 (0x011E)

    ; --- Operação 1: A2[1] + A3[3] -> A4[0] ---
    LDD R16, Y+1            ; Lê A2 com offset +1 (A2[1]) para R16 (Ponteiro Y permanece em 0x010A)
    LDD R18, Z+3            ; Lê A3 com offset +3 (A3[3]) para R18 (Ponteiro Z permanece em 0x0114)
    ADD R16, R18            ; Soma as duas posições (R16 = A2[1] + A3[3])
    ST X+, R16              ; Armazena em A4[0] e avança X (+1) para A4[1]

    ; --- Operação 2: A2[3] + A3[4] -> A4[1] ---
    LDD R16, Y+3            ; Lê A2 com offset +3 (A2[3]) para R16
    LDD R18, Z+4            ; Lê A3 com offset +4 (A3[4]) para R18
    ADD R16, R18            ; Soma as duas posições (R16 = A2[3] + A3[4])
    ST X+, R16              ; Armazena em A4[1] e avança X (+1) para A4[2]

    ; --- Operação 3: A2[5] + A3[7] -> A4[2] ---
    LDD R16, Y+5            ; Lê A2 com offset +5 (A2[5]) para R16
    LDD R18, Z+7            ; Lê A3 com offset +7 (A3[7]) para R18
    ADD R16, R18            ; Soma as duas posições (R16 = A2[5] + A3[7])
    ST X+, R16              ; Armazena em A4[2]

FIM_PROG2:
    RJMP FIM_PROG2          ; Loop infinito de término
```

### 5.3 Aplicação 3: Biblioteca de Sub-rotinas Modulares de 32 bits com Loops e Contexto

O programa a seguir constrói uma biblioteca modular composta por três sub-rotinas para manipulação de variáveis de 32 bits: `init_32bits`, `zera_32bits` (com laço de repetição) e `sub_32bits` (subtração com laço de repetição, `CLC`, `SBC` e salvamento do `SREG` e registradores).

```assembly
; ==============================================================================
; PROGRAMA 3: Biblioteca Modular de Sub-rotinas de 32 bits
; Sub-rotinas:
;   - init_32bits: Grava R16-R19 na variável de 32 bits apontada por X.
;   - zera_32bits: Preenche 4 bytes com 0x00 utilizando laço de repetição.
;   - sub_32bits : Subtrai duas variáveis de 32 bits (Z = X - Y) utilizando
;                  laço de repetição, CLC, SBC e salvamento de contexto.
; ==============================================================================

.INCLUDE <m328Pdef.inc>     ; Definições padrão do ATmega328P

.DSEG                       ; Segmento de memória de dados SRAM
.ORG SRAM_START             ; Endereço 0x0100
    A: .BYTE 4              ; Variável A de 32 bits (0x0100 a 0x0103)
    B: .BYTE 4              ; Variável B de 32 bits (0x0104 a 0x0107)
    C: .BYTE 4              ; Variável C de 32 bits (0x0108 a 0x010B)

.CSEG                       ; Segmento de memória de código Flash
.ORG 0x0000                 ; Vetor de Reset
    RJMP START              ; Salta para o início do programa

START:
    ; 1. Inicialização do Stack Pointer
    LDI R16, HIGH(RAMEND) \ OUT SPH, R16   ; Parte alta do SP (0x08)
    LDI R16, LOW(RAMEND)  \ OUT SPL, R16   ; Parte baixa do SP (0xFF)

    ; 2. Teste da Sub-rotina init_32bits: Inicializar A com 0x44332211
    LDI XL, LOW(A) \ LDI XH, HIGH(A)       ; Ponteiro X aponta para a base de A
    LDI R16, 0x11                          ; Byte 0 (LSB)
    LDI R17, 0x22                          ; Byte 1
    LDI R18, 0x33                          ; Byte 2
    LDI R19, 0x44                          ; Byte 3 (MSB)
    RCALL init_32bits                      ; Executa inicialização de A

    ; 3. Teste da Sub-rotina zera_32bits: Zerar a variável B
    LDI XL, LOW(B) \ LDI XH, HIGH(B)       ; Redefine o ponteiro X para apontar para B
    RCALL zera_32bits                      ; Preenche B com 0x00000000

    ; 4. Teste da Sub-rotina sub_32bits: Executar C = A - B
    LDI XL, LOW(A) \ LDI XH, HIGH(A)       ; X aponta para A (Minuendo)
    LDI YL, LOW(B) \ LDI YH, HIGH(B)       ; Y aponta para B (Subtraendo)
    LDI ZL, LOW(C) \ LDI ZH, HIGH(C)       ; Z aponta para C (Resultado)
    RCALL sub_32bits                       ; Executa a subtração de 32 bits

FIM_MAIN:
    RJMP FIM_MAIN                          ; Loop infinito do programa principal

; ==============================================================================
; SUB-ROTINA: init_32bits
; Parâmetros de Entrada: X (Ponteiro para a variável), R16-R19 (Valores 32 bits)
; ==============================================================================
init_32bits:
    ST X+, R16              ; Grava Byte 0 (LSB) e avança ponteiro X em +1
    ST X+, R17              ; Grava Byte 1 e avança ponteiro X em +1
    ST X+, R18              ; Grava Byte 2 e avança ponteiro X em +1
    ST X+, R19              ; Grava Byte 3 (MSB) e avança ponteiro X em +1
    RET                     ; Retorna à instrução seguinte ao RCALL

; ==============================================================================
; SUB-ROTINA: zera_32bits (Implementada com Laço de Repetição)
; Parâmetros de Entrada: X (Ponteiro para a variável a ser zerada)
; ==============================================================================
zera_32bits:
    ; Salvamento de Contexto
    PUSH R16                ; Salva R16 na pilha
    PUSH R17                ; Salva R17 (utilizado como contador) na pilha

    CLR R16                 ; R16 = 0x00
    LDI R17, 4              ; Contador = 4 bytes (32 bits)

loop_zera:
    ST X+, R16              ; Grava 0x00 na SRAM e avança ponteiro X em +1
    DEC R17                 ; Decrementa o contador de bytes
    BRNE loop_zera          ; Repete o laço até zerar os 4 bytes

    ; Restauração de Contexto (Ordem Inversa ao PUSH)
    POP R17                 ; Restaura o contador R17 original
    POP R16                 ; Restaura o registrador de trabalho R16
    RET                     ; Retorna da sub-rotina

; ==============================================================================
; SUB-ROTINA: sub_32bits (Subtração Z = X - Y com Loop e Preservação de Contexto)
; Parâmetros de Entrada: X (Minuendo), Y (Subtraendo), Z (Resultado)
; ==============================================================================
sub_32bits:
    ; Salvamento Rigoroso de Contexto
    PUSH R16                ; Salva registrador de trabalho R16
    PUSH R17                ; Salva registrador de trabalho R17
    PUSH R18                ; Salva registrador contador R18
    IN R16, SREG            ; Lê as flags de estado atuais do SREG
    PUSH R16                ; Salva a cópia do SREG na pilha

    LDI R18, 4              ; Configura contador para 4 bytes (32 bits)
    CLC                     ; Limpa a flag Carry (C = 0). Permite utilizar SBC
                            ; desde o primeiro byte sem erro de empréstimo!

loop_subtrai:
    LD R16, X+              ; Lê byte do Minuendo e avança ponteiro X
    LD R17, Y+              ; Lê byte do Subtraendo e avança ponteiro Y
    SBC R16, R17            ; R16 = R16 - R17 - Carry (No 1º byte Carry é 0 pelo CLC)
    ST Z+, R16              ; Grava resultado em Z e avança ponteiro Z
    
    DEC R18                 ; Decrementa contador (DEC NÃO afeta a flag Carry!)
    BRNE loop_subtrai       ; Repete o laço mantendo a flag Carry intacta para o próximo byte

    ; Restauração Rigorosa de Contexto (Ordem Inversa ao PUSH)
    POP R16                 ; Desempilha a cópia das flags do SREG
    OUT SREG, R16           ; Restaura as flags do SREG do sistema
    POP R18                 ; Restaura o registrador R18
    POP R17                 ; Restaura o registrador R17
    POP R16                 ; Restaura o registrador R16
    RET                     ; Retorna à instrução seguinte ao RCALL
```

### 5.4 Aplicação 4: Controle de I/O e Sub-rotina de Atraso Temporal (*Delay*)

O programa a seguir demonstra a manipulação de registradores de E/S (`DDRB`, `PORTB`) para piscar um LED no pino PB5 (pino 13 do Arduino Uno), utilizando uma sub-rotina de atraso configurável via parâmetros e com salvamento integral de contexto.

```assembly
; ==============================================================================
; PROGRAMA 4: Pisca-LED em PB5 com Sub-rotina de Atraso Configurável
; Frequência do Processador: 16 MHz
; Parâmetro da Sub-rotina 'delay': R19 define o tempo aproximado de atraso
;   - R19 = 16  --> ~200 ms
;   - R19 = 80  --> ~1 segundo
; ==============================================================================

.INCLUDE <m328Pdef.inc>     ; Definições padrão do ATmega328P

.EQU LED = PB5               ; Associa o nome 'LED' ao bit PB5 (pino 5 do PORTB)

.CSEG                       ; Segmento de memória de código Flash
.ORG 0x0000                 ; Vetor de Reset
    RJMP START              ; Salta para o início do programa

START:
    ; 1. Inicialização do Stack Pointer
    LDI R16, HIGH(RAMEND) \ OUT SPH, R16   ; Configura parte alta do SP (0x08)
    LDI R16, LOW(RAMEND)  \ OUT SPL, R16   ; Configura parte baixa do SP (0xFF)

    ; 2. Configura pino PB5 como saída digital
    SBI DDRB, LED           ; Coloca em nível alto (1) o bit PB5 no registrador de direção DDRB

MAIN_LOOP:
    ; Liga LED
    SBI PORTB, LED          ; Coloca o pino PB5 em nível alto (5V)
    LDI R19, 16             ; Parâmetro: R19 = 16 (aproximadamente 200ms de atraso)
    RCALL delay             ; Chama a sub-rotina de atraso

    ; Desliga LED
    CBI PORTB, LED          ; Coloca o pino PB5 em nível baixo (0V)
    LDI R19, 16             ; Parâmetro: R19 = 16 (aproximadamente 200ms de atraso)
    RCALL delay             ; Chama a sub-rotina de atraso

    RJMP MAIN_LOOP          ; Repete o ciclo continuamente

; ==============================================================================
; SUB-ROTINA: delay
; Parâmetro de Entrada: R19 (Fator de multiplicação do tempo)
; Preserva integralmente o estado dos registradores de trabalho e do SREG
; ==============================================================================
delay:
    ; Salvamento de Contexto na Pilha
    PUSH R17                ; Salva R17
    PUSH R18                ; Salva R18
    PUSH R19                ; Salva R19 (parâmetro)
    IN R17, SREG            ; Lê as flags do SREG
    PUSH R17                ; Salva as flags do SREG na pilha

    ; Inicializa registradores internos para os laços aninhados
    CLR R17                 ; R17 = 0 (256 passagens no laço interno)
    CLR R18                 ; R18 = 0 (256 passagens no laço intermediário)

loop_atraso:
    DEC R17                 ; Decrementa R17 (laço mais interno)
    BRNE loop_atraso        ; Salta para 'loop_atraso' enquanto R17 != 0
    DEC R18                 ; Decrementa R18 (laço intermediário)
    BRNE loop_atraso        ; Salta para 'loop_atraso' enquanto R18 != 0
    DEC R19                 ; Decrementa R19 (laço externo, definido pelo parâmetro)
    BRNE loop_atraso        ; Salta para 'loop_atraso' enquanto R19 != 0

    ; Restauração de Contexto na Ordem Inversa
    POP R17                 ; Recupera as flags salvas do SREG
    OUT SREG, R17           ; Restaura o SREG do sistema
    POP R19                 ; Restaura R19
    POP R18                 ; Restaura R18
    POP R17                 ; Restaura R17
    RET                     ; Retorna ao programa principal
```

---

## 6. Tabela de Consulta Rápida do Conjunto de Instruções AVR

A tabela a seguir consolida o conjunto de instruções do ATmega328P, organizadas por categoria, incluindo sintaxe, funcionalidade, flags afetadas no `SREG` e ciclos de máquina consumidos.

| Categoria | Mnemônico | Operando | Descrição da Operação | Flags Afetadas | Ciclos de Clock |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Transferência** | `LDI` | `Rd, K` | Carrega constante $K$ ($0..255$) em `Rd` (`R16`–`R31`). | Nenhuma | 1 |
| | `MOV` | `Rd, Rr` | Copia conteúdo de `Rr` para `Rd`. | Nenhuma | 1 |
| | `MOVW` | `Rd, Rr` | Copia palavra de 16 bits entre pares de registradores. | Nenhuma | 1 |
| | `LDS` | `Rd, k` | Lê da SRAM no endereço direto $k$ para `Rd`. | Nenhuma | 2 |
| | `STS` | `k, Rr` | Grava `Rr` na SRAM no endereço direto $k$. | Nenhuma | 2 |
| | `LD` | `Rd, Index` | Lê da SRAM utilizando ponteiro ($X$, $Y$ ou $Z$). | Nenhuma | 1 ou 2 |
| | `ST` | `Index, Rr` | Grava na SRAM utilizando ponteiro ($X$, $Y$ ou $Z$). | Nenhuma | 1 ou 2 |
| | `LDD` | `Rd, Y+q` | Lê da SRAM com deslocamento $q$ ($0..63$) usando $Y$ ou $Z$. | Nenhuma | 2 |
| | `STD` | `Y+q, Rr` | Grava na SRAM com deslocamento $q$ ($0..63$) usando $Y$ ou $Z$. | Nenhuma | 2 |
| | `IN` | `Rd, P` | Lê do registrador de E/S $P$ ($0..63$) para `Rd`. | Nenhuma | 1 |
| | `OUT` | `P, Rr` | Escreve conteúdo de `Rr` no registrador de E/S $P$. | Nenhuma | 1 |
| | `PUSH` | `Rr` | Empilha o conteúdo de `Rr` na Pilha (`SP - 1`). | Nenhuma | 1 ou 2 |
| | `POP` | `Rd` | Desempilha valor da Pilha para `Rd` (`SP + 1`). | Nenhuma | 1 ou 2 |
| **Aritmética** | `ADD` | `Rd, Rr` | Soma dois registradores (`Rd = Rd + Rr`). | `Z, C, N, V, S, H` | 1 |
| | `ADC` | `Rd, Rr` | Soma dois registradores com Carry (`Rd = Rd + Rr + C`). | `Z, C, N, V, S, H` | 1 |
| | `SUB` | `Rd, Rr` | Subtrai dois registradores (`Rd = Rd - Rr`). | `Z, C, N, V, S, H` | 1 |
| | `SBC` | `Rd, Rr` | Subtrai dois registradores com Borrow (`Rd = Rd - Rr - C`). | `Z, C, N, V, S, H` | 1 |
| | `INC` | `Rd` | Incrementa registrador em $+1$ (`Rd = Rd + 1`). | `Z, N, V, S` (**NÃO** afeta `C`) | 1 |
| | `DEC` | `Rd` | Decrementa registrador em $-1$ (`Rd = Rd - 1`). | `Z, N, V, S` (**NÃO** afeta `C`) | 1 |
| | `ADIW` | `Rdl, K` | Soma constante ($0..63$) a par de 16b (`R24`, $X$, $Y$, $Z$). | `Z, C, N, V, S` | 2 |
| | `SBIW` | `Rdl, K` | Subtrai constante ($0..63$) de par de 16b (`R24`, $X$, $Y$, $Z$). | `Z, C, N, V, S` | 2 |
| **Lógica** | `AND` / `ANDI` | `Rd, Rr/K` | Operação lógica E bit a bit (*AND*). | `Z, N, V=0, S` | 1 |
| | `OR` / `ORI` | `Rd, Rr/K` | Operação lógica OU bit a bit (*OR*). | `Z, N, V=0, S` | 1 |
| | `EOR` | `Rd, Rr` | Operação OU Exclusivo (*XOR*). `EOR R16, R16` zera R16. | `Z, N, V=0, S` | 1 |
| | `CLR` | `Rd` | Zera registrador (`Rd = 0x00`). | `Z=1, N=0, V=0, S=0` | 1 |
| **Controle/Desvios**| `CP` / `CPI` | `Rd, Rr/K` | Compara dois registradores ou registrador com constante. | `Z, C, N, V, S, H` | 1 |
| | `BREQ` | `label` | Salta se igual (`Z == 1`). | Nenhuma | 1 ou 2 |
| | `BRNE` | `label` | Salta se diferente (`Z == 0`). | Nenhuma | 1 ou 2 |
| | `RJMP` | `label` | Salta incondicionalmente (alcance $\pm 2\text{K}$ palavras). | Nenhuma | 2 |
| | `RCALL` | `label` | Chama sub-rotina empilhando endereço de retorno. | Nenhuma | 3 ou 4 |
| | `RET` | Nenhum | Retorna de sub-rotina desempilhando endereço. | Nenhuma | 4 ou 5 |
| | `SBI` / `CBI` | `P, b` | Liga (1) / Desliga (0) o bit $b$ no registrador de E/S $P$. | Nenhuma | 2 |
