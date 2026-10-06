# Guia de Programação em Assembly AVR

---

## 1. Unidade Lógica e Aritmética (ULA) e Banco de Registradores

A ULA do AVR conecta-se diretamente a um banco de **32 registradores de propósito geral de 8 bits** (`R0` a `R31`). Esta arquitetura baseada em registradores (*register-to-register*) elimina o gargalo do acumulador único tradicional, permitindo que a ULA execute operações aritméticas ou lógicas entre dois registradores e armazene o resultado em um único ciclo de clock.

Apesar de todos os registradores possuírem 8 bits de largura, a arquitetura impõe restrições funcionais e especializações dependendo do grupo de registradores:

*   **Faixa `R0` a `R15` (Registradores Puros)**:
    *   **Restrição Crítica**: Não possuem suporte elétrico para operações com valores imediatos (*constantes*). Instruções que operam com constantes embutidas (como `LDI`, `CPI`, `SUBI`, `SBCI`, `ANDI`, `ORI`) **não aceitam** registradores desta faixa.
    *   `R0`: Utilizado como registrador de destino implícito pela instrução de leitura da memória Flash (`LPM`).
    *   `R1:R0`: Par de registradores que armazena obrigatoriamente o resultado de 16 bits de operações de multiplicação (`MUL`, `MULS`, `MULSU`).
*   **Faixa `R16` a `R31` (Registradores com Suporte a Imediatos)**:
    *   Possuem lógica interna dedicada para decodificar constantes de 8 bits diretamente da palavra de instrução. São os registradores padrão para carga inicial de dados e operações lógicas/aritméticas com constantes.
*   **Pares Ponteiro de 16 bits (`X`, `Y`, `Z`)**:
    *   Os últimos seis registradores do banco são combinados em pares de 8 bits para formar registradores de endereçamento indireto de 16 bits:
        *   **Ponteiro X**: Formado obrigatoriamente pela junção de `R27` (parte alta, `XH`) e `R26` (parte baixa, `XL`).
        *   **Ponteiro Y**: Formado obrigatoriamente pela junção de `R29` (parte alta, `YH`) e `R28` (parte baixa, `YL`).
        *   **Ponteiro Z**: Formado obrigatoriamente pela junção de `R31` (parte alta, `ZH`) e `R30` (parte baixa, `ZL`). Suporta também o endereçamento de tabelas de constantes salvas na memória Flash.
---

## 2. Mapeamento de Memória do ATmega328P

A arquitetura do ATmega328P organiza seus recursos em dois espaços principais de endereçamento:

### 2.1 Espaço de Memória de Programa Flash (`.CSEG`)
*   **Capacidade Total**: 32 KB organizada em 16.384 palavras de 16 bits (endereços `0x0000` a `0x3FFF`).
*   **Vetor de Reset (`0x0000`)**: Primeiro endereço executado após energização ou reset do sistema.
*   **Tabela de Interrupções (`0x0002` a `0x0032`)**: Endereços reservados para desvios automáticos provocados por periféricos (timers, interrupções externas, ADCs, comunicação serial).
*   **Armazenamento de Constantes**: Tabelas de dados constantes mantidas na Flash são lidas via ponteiro `Z` através da instrução `LPM` (*Load Program Memory*).

### 2.2 Espaço de Memória de Dados SRAM (`.DSEG`)
O espaço contíguo de dados abrange 2.304 posições (endereços `0x0000` a `0x08FF`), dividido estruturalmente em quatro regiões:

| Faixa de Endereços Hexadecimal | Intervalo Decimal | Categoria de Hardware | Função e Recursos |
| :--- | :--- | :--- | :--- |
| `0x0000` a `0x001F` | 0 a 31 | Registradores Gerais | Banco de 32 registradores de trabalho da CPU (`R0` a `R31`). |
| `0x0020` a `0x005F` | 32 a 95 | E/S Padrão | 64 registradores de periféricos acessíveis por instruções `IN` / `OUT`. |
| `0x0060` a `0x00FF` | 96 a 255 | E/S Estendida | 160 registradores de periféricos avançados (acessíveis via `LDS` / `STS`). |
| `0x0100` a `0x08FF` | 256 a 2304 | SRAM Interna | 2048 bytes de memória RAM estática para variáveis do usuário e Pilha. |

---

## 3. Os 5 Modos de Endereçamento da Memória SRAM

Para ler e escrever dados na SRAM, a arquitetura AVR oferece cinco modos de endereçamento indireto e direto:

1.  **Endereçamento Direto (`LDS` / `STS`)**:
    *   O endereço exato de 16 bits da posição da SRAM é codificado dentro da própria instrução (ocupa 32 bits / 2 palavras na Flash).
    *   Não utiliza e não altera os registradores ponteiro $X$, $Y$ ou $Z$.
2.  **Endereçamento Indireto Simples (`LD` / `ST`)**:
    *   O acesso à SRAM ocorre utilizando o endereço previamente carregado em um dos registradores ponteiro ($X$, $Y$ ou $Z$).
    *   O valor do ponteiro permanece estático (inalterado) após a operação.
3.  **Endereçamento Indireto com Pós-Incremento (`LD Rd, X+` / `ST X+, Rr`)**:
    *   Efetua a leitura ou escrita no endereço apontado pelo ponteiro ($X$, $Y$ ou $Z$) e, imediatamente após o acesso, incrementa o valor do ponteiro em $+1$.
    *   Ideal para varredura sequencial de vetores do início para o fim.
4.  **Endereçamento Indireto com Pré-Decremento (`LD Rd, -X` / `ST -X, Rr`)**:
    *   Decrementa o valor do ponteiro ($X$, $Y$ ou $Z$) em $-1$ **antes** de realizar a operação e efetua a leitura/escrita no novo endereço.
    *   Ideal para varredura inversa de vetores ou implementação de estruturas de dados tipo pilha.
5.  **Endereçamento Indireto com Deslocamento (`LDD` / `STD`)**:
    *   Soma um valor constante de deslocamento (*offset*) $q$ ($0 \le q \le 63$) ao endereço base contido no ponteiro.
    *   **Restrição Crítica**: Suportado **apenas pelos ponteiros $Y$ e $Z$** (o ponteiro $X$ não aceita deslocamento). O ponteiro base permanece inalterado na memória.

### Tabela Comparativa dos Modos de Endereçamento da SRAM

| Modo de Endereçamento | Sintaxe de Leitura | Sintaxe de Escrita | Ponteiros Aceitos | Modificação no Ponteiro | Tamanho da Instrução |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Direto** | `LDS Rd, k` | `STS k, Rr` | Nenhum (Endereço fixo $k$) | Não se aplica | 2 palavras (32 bits) |
| **2. Indireto Simples** | `LD Rd, Index` | `ST Index, Rr` | $X$, $Y$, $Z$ | Nenhuma (Estático) | 1 palavra (16 bits) |
| **3. Pós-Incremento** | `LD Rd, Index+` | `ST Index+, Rr` | $X$, $Y$, $Z$ | Soma $+1$ **após** o acesso | 1 palavra (16 bits) |
| **4. Pré-Decremento** | `LD Rd, -Index` | `ST -Index, Rr` | $X$, $Y$, $Z$ | Subtrai $-1$ **antes** do acesso | 1 palavra (16 bits) |
| **5. Deslocamento** | `LDD Rd, Y+q` / `Z+q` | `STD Y+q, Rr` / `Z+q` | **Apenas $Y$ e $Z$** | Nenhuma (Ponteiro fixo na base) | 1 palavra (16 bits) |

---

## 4. Mecânica da Pilha, Stack Pointer e Registrador de Status (`SREG`)

### 4.1 O Registrador Stack Pointer (`SP`) e Operações da Pilha
A Pilha (*Stack*) é uma estrutura de dados alocada na SRAM que cresce **dos maiores endereços em direção aos menores**. O registrador `SP` (composto pelos registradores de E/S `SPH` e `SPL`) aponta para o topo atual da pilha.

| Instrução | Variação do Stack Pointer (`SP`) | Mecânica Interna da Operação |
| :--- | :--- | :--- |
| `PUSH Rr` | **Decrementa em 1** (`SP` $\leftarrow$ `SP - 1`) | Escreve o byte de `Rr` na posição atual de `SP` e decrementa `SP`. |
| `POP Rd` | **Incrementa em 1** (`SP` $\leftarrow$ `SP + 1`) | Incrementa `SP` e lê o byte armazenado no novo topo para `Rd`. |
| `RCALL` / `CALL` | **Decrementa em 2** (`SP` $\leftarrow$ `SP - 2`) | Empilha os 2 bytes do endereço de retorno (*Program Counter*) e salta. |
| `RET` / `RETI` | **Incrementa em 2** (`SP` $\leftarrow$ `SP + 2`) | Desempilha 2 bytes da pilha, carrega no *Program Counter* e retorna. |

### 4.2 O Registrador de Status (`SREG`)
O registrador `SREG` (endereço de E/S `0x3F`) monitora os resultados das operações executadas pela ULA:

*   **Bit 7 — `I` (*Global Interrupt Enable*)**: Chave geral para habilitação de interrupções.
*   **Bit 6 — `T` (*Bit Copy Storage*)**: Armazenamento temporário de bit para instruções `BST` e `BLD`.
*   **Bit 5 — `H` (*Half Carry Flag*)**: Indica transporte do bit 3 para o bit 4 (utilizado em aritmética BCD).
*   **Bit 4 — `S` (*Sign Bit*)**: Sinal real em complemento de dois ($S = N \\oplus V$).
*   **Bit 3 — `V` (*Overflow Flag*)**: Indica estouro de capacidade em operações com sinal.
*   **Bit 2 — `N` (*Negative Flag*)**: Indica que o resultado da operação é negativo (bit 7 = 1).
*   **Bit 1 — `Z` (*Zero Flag*)**: Indica que o resultado da operação foi exatamente zero.
*   **Bit 0 — `C` (*Carry Flag*)**: Indica transporte (*vai-um*) em adições ou empréstimo em subtrações.

> **Regra Fundamental das Flags**: Instruções de movimentação de dados (`LDI`, `MOV`, `LDS`, `STS`, `LD`, `ST`, `PUSH`, `POP`, `IN`, `OUT`) **NÃO alteram nenhuma flag do SREG**. Instruções aritméticas e lógicas (`ADD`, `SUB`, `CP`, `AND`, `OR`) atualizam as flags de condição.

---

## 5. Tabelas Consolidadas de Referência: Diretivas e Instruções AVR

### 5.1 Tabela de Diretivas do Montador (`avrasm2`)

| Diretiva | Segmento | Descrição e Aplicação |
| :--- | :--- | :--- |
| `.INCLUDE` | Geral | Inclui arquivo de cabeçalho padrão com mapeamento de periféricos (`.INCLUDE <m328Pdef.inc>`). |
| `.CSEG` | Código | Seleciona a memória Flash para armazenamento de instruções de programa. |
| `.DSEG` | Dados | Seleciona a memória SRAM para alocação de variáveis. |
| `.ESEG` | EEPROM | Seleciona a memória EEPROM para dados não-voláteis. |
| `.ORG` | Todos | Define o endereço absoluto de origem para o código ou variáveis (`.ORG 0x0000` ou `.ORG SRAM_START`). |
| `.BYTE` | Dados | Reserva um bloco de bytes contíguos não inicializados na SRAM (`vetor: .BYTE 10`). |
| `.DB` | Código | Grava bytes constantes diretamente na memória Flash de programa (`tabela: .DB 1, 2, 3, 4`). |
| `.DW` | Código | Grava palavras de 16 bits constantes na memória Flash (`dados: .DW 0x1234`). |
| `.DEF` | Geral | Define um nome simbólico amigável para um registrador (`.DEF temp = R16`). |
| `.EQU` | Geral | Define uma constante simbólica imutável atribuída a uma expressão (`.EQU LED = PB5`). |
| `.SET` | Geral | Define uma constante simbólica que pode ser redefinida ao longo do arquivo. |

### 5.2 Tabela Completa de Instruções do ATmega328P por Categoria

| Categoria | Mnemônico | Operando | Operação / Descrição | Flags Afetadas | Ciclos de Clock |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Transferência de Dados** | `LDI` | `Rd, K` | Carrega constante $K$ ($0..255$) em `Rd` (`R16`–`R31`). | Nenhuma | 1 |
| | `MOV` | `Rd, Rr` | Copia o conteúdo de `Rr` para `Rd`. | Nenhuma | 1 |
| | `MOVW` | `Rd, Rr` | Copia par de registradores de 16 bits. | Nenhuma | 1 |
| | `LDS` | `Rd, k` | Lê da SRAM no endereço direto $k$ para `Rd`. | Nenhuma | 2 |
| | `STS` | `k, Rr` | Grava `Rr` na SRAM no endereço direto $k$. | Nenhuma | 2 |
| | `LD` | `Rd, Index` | Lê da SRAM usando ponteiro ($X$, $Y$ ou $Z$, com/sem incremento/decremento). | Nenhuma | 1 ou 2 |
| | `ST` | `Index, Rr` | Grava na SRAM usando ponteiro ($X$, $Y$ ou $Z$, com/sem incremento/decremento). | Nenhuma | 1 ou 2 |
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
| | `ADIW` | `Rdl, K` | Soma constante ($0..63$) a par de 16 bits (`R24`, $X$, $Y$, $Z$). | `Z, C, N, V, S` | 2 |
| | `SBIW` | `Rdl, K` | Subtrai constante ($0..63$) de par de 16 bits (`R24`, $X$, $Y$, $Z$). | `Z, C, N, V, S` | 2 |
| **Lógica** | `AND` / `ANDI` | `Rd, Rr/K` | Operação lógica E bit a bit (*AND*). | `Z, N, V=0, S` | 1 |
| | `OR` / `ORI` | `Rd, Rr/K` | Operação lógica OU bit a bit (*OR*). | `Z, N, V=0, S` | 1 |
| | `EOR` / `CLR` | `Rd, Rr` | OU Exclusivo (*XOR*) / Zera registrador (`CLR Rd`). | `Z=1, N=0, V=0, S=0` | 1 |
| **Controle e Desvios**| `CP` / `CPI` | `Rd, Rr/K` | Compara dois registradores ou registrador com constante. | `Z, C, N, V, S, H` | 1 |
| | `BREQ` | `label` | Salta se igual (`Z == 1`). | Nenhuma | 1 ou 2 |
| | `BRNE` | `label` | Salta se diferente (`Z == 0`). | Nenhuma | 1 ou 2 |
| | `RJMP` | `label` | Salta incondicionalmente (alcance $\\pm 2\\text{K}$ palavras). | Nenhuma | 2 |
| | `RCALL` | `label` | Chama sub-rotina empilhando endereço de retorno. | Nenhuma | 3 ou 4 |
| | `RET` | Nenhum | Retorna de sub-rotina desempilhando endereço. | Nenhuma | 4 ou 5 |
| | `SBI` / `CBI` | `P, b` | Liga (1) / Desliga (0) o bit $b$ no registrador de E/S $P$. | Nenhuma | 2 |
