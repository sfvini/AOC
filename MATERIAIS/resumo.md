# Arquitetura e Organização de Computadores: Manual Consolidado da Arquitetura AVR (ATmega328P)

Este documento constitui um compêndio analítico e prático sobre Arquitetura e Organização de Computadores, centrado na arquitetura de microcontroladores AVR de 8 bits e na família ATmega328P. O objetivo é integrar a fundamentação teórica de hardware ao aprendizado de baixo nível em linguagem Assembly, abrangendo a estrutura da CPU, a hierarquia de memória, os modos de endereçamento, o conjunto de instruções, a mecânica da pilha e a construção de sub-rotinas modulares.

---

## 1. Fundamentos Teóricos de Arquitetura de Computadores

A arquitetura de computadores define o comportamento funcional de um sistema do ponto de vista do programador e do projetista de hardware, estabelecendo a interface entre o software de baixo nível e a eletrônica física.

### 1.1 Modelo de von Neumann vs. Arquitetura Harvard

Os sistemas de computação dividem-se fundamentalmente em duas filosofias de organização de barramentos e memória:

*   **Arquitetura de von Neumann**: Caracteriza-se pela utilização de um barramento único e uma memória compartilhada tanto para o armazenamento de instruções (programa) quanto para dados. A principal limitação deste modelo é o gargalo de von Neumann: a CPU não consegue buscar uma instrução e ler/escrever dados na memória simultaneamente, pois ambos disputam o mesmo barramento físico.
*   **Arquitetura Harvard**: Mantém memórias e barramentos fisicamente separados para instruções e dados. A CPU possui um barramento de instrução (com seu próprio endereço e barramento de dados) e um barramento de dados dedicado (SRAM/registradores).
*   **Arquitetura Harvard Modificada (Caso AVR)**: O microcontrolador ATmega328P adota uma arquitetura Harvard modificada. Embora os barramentos de memória de programa (Flash) e memória de dados (SRAM) sejam fisicamente distintos — permitindo a busca simultânea de instruções e leitura de dados —, a arquitetura disponibiliza instruções especiais (como `LPM` — *Load Program Memory*) que permitem à CPU ler constantes e tabelas gravadas na memória de programa através do ponteiro $Z$.

### 1.2 Filosofias de Projeto: CISC vs. RISC

A organização do conjunto de instruções determina a complexidade do hardware interno da Unidade Central de Processamento (CPU):

| Característica | CISC (*Complex Instruction Set Computer*) | RISC (*Reduced Instruction Set Computer*) |
| :--- | :--- | :--- |
| **Instruções** | Elevado número de instruções complexas e de tamanho variável. | Conjunto reduzido de instruções simples e de tamanho fixo (16 ou 32 bits no AVR). |
| **Execução** | Instruções levam múltiplos ciclos de clock para serem concluídas. | A maioria das instruções executa em exatamente **1 ciclo de clock**. |
| **Acesso à Memória** | Instruções aritméticas podem acessar operandos diretamente na memória RAM. | Arquitetura **LOAD-STORE**: operações aritméticas ocorrem exclusivamente entre registradores. |
| **Registradores** | Poucos registradores de uso geral. | Banco denso de registradores de uso geral (32 registradores no AVR). |
| **Hardware** | Unidade de controle microprogramada e circuitos complexos. | Unidade de controle hardwired (decodificação rápida por lógica combinacional). |

No modelo CISC, uma operação de multiplicação entre posições de memória pode ser expressa em uma única instrução como `MULT 0, 3`. No modelo RISC adotado pelo AVR, a mesma operação exige o carregamento prévio dos dados para o banco de registradores, o cálculo na Unidade Lógica e Aritmética (ULA) e o armazenamento posterior na memória:

```assembly
LOAD A, 0       ; Carrega dado do endereço 0 para registrador A
LOAD B, 3       ; Carrega dado do endereço 3 para registrador B
MULT A, B       ; Multiplica registrador A por B na ULA
STORE 0, A      ; Guarda o resultado de volta na memória no endereço 0
```

### 1.3 Organização Interna da CPU e Pipeline de Execução

A CPU do AVR é composta por três blocos centrais: a **Unidade Lógica e Aritmética (ULA)**, o **Banco de Registradores de Uso Geral (Register File)** e a **Unidade de Controle com Decodificador de Instruções**.

O desempenho de 16 MIPS a uma frequência de clock de 16 MHz é alcançado mediante o mecanismo de **Pipeline de 1 Nível**. O tamanho fixo das instruções de 16 bits na memória Flash permite que a fase de busca (*Fetch*) da instrução $N+1$ ocorra simultaneamente à fase de execução (*Execute*) da instrução $N$.

```
Ciclo de Clock    :    T1        T2        T3        T4
Instrução N       : | Fetch  | Execute |
Instrução N+1     :          | Fetch   | Execute |
Instrução N+2     :                    | Fetch   | Execute |
```

A cada ciclo de relógio de $62,5\text{ ns}$ (a 16 MHz), a ULA lê até dois registradores de 8 bits, executa a operação aritmética ou lógica e grava o resultado de volta no registrador de destino no mesmo ciclo.

---

## 2. Visão Geral e Especificações do Microcontrolador ATmega328P

O ATmega328P é um microcontrolador CMOS de 8 bits de baixo consumo, baseado na arquitetura AVR RISC estendida.

### 2.1 Principais Características de Hardware

*   **Arquitetura**: RISC de 8 bits com arquitetura Harvard Modificada.
*   **Frequência de Operação**: Até $20\text{ MHz}$ (tipicamente $16\text{ MHz}$ na placa Arduino Uno).
*   **Desempenho**: Próximo de $1\text{ MIPS/MHz}$ (aproximadamente $16\text{ MIPS}$ a $16\text{ MHz}$).
*   **Banco de Registradores**: 32 registradores de trabalho de 8 bits ($R0$ a $R31$).
*   **Linhas de I/O**: 23 pinos de Entrada/Saída de uso geral (GPIO) organizados nos Portos B, C e D.
*   **Periféricos Integrados**:
    *   3 Temporizadores/Contadores (Timer0 e Timer2 de 8 bits; Timer1 de 16 bits) com modos PWM e comparadores.
    *   Conversor Analógico-Digital (ADC) de 10 bits com 6 canais (invólucro DIP-28) ou 8 canais (TQFP/QFN).
    *   Interface Serial USART programável.
    *   Barramento Serial SPI e TWI (compatível com $I^2C$).
    *   Comparador Analógico e *Watchdog Timer* programável com oscilador interno.

### 2.2 Comparativo de Variantes da Família (ATmega48A/88A/168A/328P)

Embora compartilhem o mesmo núcleo AVR e mapa periférico, os modelos da família diferem na capacidade de memória e no suporte a Bootloader:

| Modelo | Flash de Programa | SRAM Interna | EEPROM | Seção de Bootloader Dedicada | Suporte a Read-While-Write (RWW) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **ATmega48A/PA** | 4 KB ($2\text{K}\times 16$) | 512 Bytes | 256 Bytes | Não possui | Não (instrução `SPM` roda de qualquer parte) |
| **ATmega88A/PA** | 8 KB ($4\text{K}\times 16$) | 1 KB | 512 Bytes | Possui (256 a 2048 palavras) | Sim (suporta auto-programação real) |
| **ATmega168A/PA** | 16 KB ($8\text{K}\times 16$) | 1 KB | 512 Bytes | Possui (256 a 2048 palavras) | Sim (suporta auto-programação real) |
| **ATmega328P** | 32 KB ($16\text{K}\times 16$) | 2 KB | 1 KB | Possui (256 a 2048 palavras) | Sim (suporta auto-programação real) |

---

## 3. Mapeamento e Hierarquia de Memória

O ATmega328P possui três espaços de memória fisicamente separados: Memória Flash de Programa, Memória de Dados SRAM e Memória EEPROM.

### 3.1 Memória de Programa (Flash)

*   **Capacidade**: $32\text{ KB}$ organizados como $16\text{K}\times 16\text{ bits}$ (palavras de 16 bits).
*   **Durabilidade**: Garantia de no mínimo 10.000 ciclos de gravação/apagamento.
*   **Divisão Espacial**:
    *   **Seção de Aplicação (*Application Flash Section*)**: Onde reside o código do programa do usuário.
    *   **Seção de Boot (*Boot Flash Section*)**: Localizada nos endereços superiores ($256$ a $2048$ palavras). Suporta o mecanismo de auto-programação real em sistema (*Read-While-Write*), onde a instrução `SPM` (*Store Program Memory*) que grava na Flash deve obrigatoriamente rodar da seção de Boot.
*   **Vetor de Reset**: O ponteiro de programa (PC) inicia a execução no endereço `0x0000` após o Reset.

### 3.2 Memória de Dados (SRAM) e Espaço de Endereçamento

A memória de dados é de 8 bits e unifica os registradores de uso geral, os registradores de Entrada e Saída (I/O) e a SRAM interna em um único mapa contíguo de endereços:

```
Endereço Hexadecimal      Conteúdo da Memória de Dados (SRAM)
0x0000 - 0x001F           32 Registradores de Uso Geral (R0 a R31)
0x0020 - 0x005F           64 Registradores de I/O Padrão (I/O 0x00 a 0x3F)
0x0060 - 0x00FF           160 Registradores de I/O Estendidos
0x0100 - 0x08FF           SRAM Interna (2048 Bytes = 2 KB)
                          [SRAM_START = 0x0100 | RAMEND = 0x08FF]
```

*Nota de mapeamento*: Os registradores de I/O possuem dois endereços associados. Por exemplo, o registrador de status `SREG` possui o endereço de I/O `0x3F` (usado com instruções `IN`/`OUT`) e o endereço de memória de dados `0x005F` (calculado somando `0x20` ao endereço de I/O, acessível via `LDS`/`STS`).

### 3.3 Memória EEPROM

*   **Capacidade**: $1\text{ KB}$ ($1024\text{ bytes}$), mapeada em espaço de endereçamento isolado (`0x000` a `0x3FF`).
*   **Uso**: Armazenamento não-volátil de dados de configuração que devem persistir após o desligamento da alimentação. Exige leitura e escrita controladas via registradores de I/O específicos (`EEAR`, `EEDR`, `EECR`).

---

## 4. Banco de Registradores e Registradores Ponteiro

O banco de registradores de uso geral é composto por 32 registradores de 8 bits ($R0$ a $R31$), otimizados para operações diretas da ULA.

### 4.1 Divisão e Restrições dos Registradores

*   **Registradores $R0$ a $R15$**: Registradores de uso geral puros. **Não suportam operandos imediatos** (constantes diretas no código). Instruções como `LDI`, `CPI`, `ANDI`, `ORI`, `SUBI` e `SBCI` **não compilam** com os registradores de $R0$ a $R15$.
*   **Registradores $R16$ a $R31$**: Registradores de uso geral com suporte total a instruções de carregamento imediato, comparação e operações lógicas/aritméticas com constantes.

### 4.2 Registradores Ponteiro de 16 Bits ($X$, $Y$, $Z$)

Como os registradores individuais possuem apenas 8 bits (capacidade máxima de representar valores de $0$ a $255$), a CPU combina os últimos 6 registradores em 3 pares de 16 bits para funcionar como ponteiros de memória para a SRAM (endereços `0x0000` a `0x08FF`):

| Nome do Ponteiro | Registrador High (MSB) | Registrador Low (LSB) | Par de 16 Bits | Funcionalidades Específicas |
| :---: | :---: | :---: | :---: | :--- |
| **X** | $XH$ ($R27$) | $XL$ ($R26$) | $R27:R26$ | Leitura e escrita rápida com pós-incremento e pré-decremento. **Não suporta deslocamento/offset ($LDD$/$STD$)**. |
| **Y** | $YH$ ($R29$) | $YL$ ($R28$) | $R29:R28$ | Suporta pós-incremento, pré-decremento e **deslocamento com offset ($LDD$/$STD$ de 0 a 63)**. |
| **Z** | $ZH$ ($R31$) | $ZL$ ($R30$) | $R31:R30$ | O ponteiro mais versátil. Suporta deslocamento ($LDD$/$STD$), **leitura de constante na Flash (`LPM`)** e **desvios indiretos (`IJMP`/`ICALL`)**. |

### 4.3 Funções `HIGH()` e `LOW()`

Para carregar um endereço de memória de 16 bits (como a constante `SRAM_START` = `0x0100`) em um par ponteiro, o montador precisa fatiar o endereço em dois bytes de 8 bits, pois a instrução `LDI` só carrega 8 bits por vez:

```assembly
; Configurando o Ponteiro X (R27:R26) para o endereço de A (0x0100)
LDI R26, LOW(A)   ; LOW(0x0100)  -> carrega 0x00 em XL (R26)
LDI R27, HIGH(A)  ; HIGH(0x0100) -> carrega 0x01 em XH (R27)
```

---

## 5. Registrador de Status (SREG) e Manipulação de Flags

O Registrador de Status (`SREG`, localizado no endereço de I/O `0x3F`) reflete os resultados das operações aritméticas e lógicas executadas recente na ULA.

```
Bit    :   7   6   5   4   3   2   1   0
SREG   : | I | T | H | S | V | N | Z | C |
```

### 5.1 Definição dos Bits do SREG

1.  **I (*Global Interrupt Enable*)**: Habilita (1) ou desabilita (0) todas as interrupções do sistema.
2.  **T (*Bit Copy Storage*)**: Bit temporário usado pelas instruções de cópia de bit `BST` (*Bit Store*) e `BLD` (*Bit Load*).
3.  **H (*Half Carry Flag*)**: Sinaliza transporte (vai-um) do bit 3 para o bit 4. Essencial para aritmética BCD.
4.  **S (*Sign Bit*)**: Bit de sinal, definido como $S = N \oplus V$ (XOR lógico entre Negativo e Overflow).
5.  **V (*Two's Complement Overflow Flag*)**: Sinaliza estouro de capacidade em operações com sinal em complemento de dois.
6.  **N (*Negative Flag*)**: Reflete o bit mais significativo (bit 7) do resultado. Se o bit 7 for 1, $N = 1$.
7.  **Z (*Zero Flag*)**: Torna-se 1 quando o resultado de uma operação é exatamente zero.
8.  **C (*Carry Flag*)**: Sinaliza transporte (vai-um) na adição ou empréstimo (*borrow*) na subtração.

### 5.2 Comportamento de Alteração de Flags por Instrução

Compreender quais instruções afetam ou preservam as flags é crucial em testes e na lógica de programas:

*   **Instruções Aritméticas e Lógicas Padrão (`ADD`, `ADC`, `SUB`, `SBC`, `AND`, `OR`, `EOR`)**: Alteram todas as flags matemáticas ($Z, C, N, V, S, H$).
*   **Instruções de Incremento/Decremento (`INC`, `DEC`)**: Alteram $Z, N, V, S$, mas **NÃO alteram a Carry Flag ($C$)**. Esta propriedade permite usar `DEC` em contadores de loops de múltiplos bytes sem corromper o Carry mantido entre as somas/subtrações.
*   **Instruções de Par de Registradores (`ADIW`, `SBIW`)**: Alteram $Z, C, N, V, S$ (afetam a flag $C$).
*   **Instruções de Transferência e Memória (`LDI`, `MOV`, `MOVW`, `LDS`, `STS`, `LD`, `ST`, `LDD`, `STD`, `PUSH`, `POP`, `IN`, `OUT`)**: **NÃO alteram nenhuma flag do SREG**.

---

## 6. Ferramentas de Desenvolvimento e Diretivas do Montador

O código fonte em Assembly AVR (extensão `.asm` ou `.s`) é traduzido para código de máquina binário (`.hex`) por um montador (*Assembler*, como o `avrasm2` ou o compilador XC8 integrado ao MPLAB X IDE / Microchip Studio).

### 6.1 Principais Diretivas do Montador

As diretivas são instruções destinadas ao montador e não geram código de máquina diretamente para a CPU:

*   `.INCLUDE <m328pdef.inc>`: Inclui o arquivo de cabeçalho padrão contendo as definições dos nomes dos registradores de I/O e constantes do ATmega328P.
*   `.DSEG` (*Data Segment*): Seleciona o segmento de memória de dados (SRAM).
*   `.CSEG` (*Code Segment*): Seleciona o segmento de memória de código (Flash).
*   `.ESEG` (*EEPROM Segment*): Seleciona o segmento de memória EEPROM.
*   `.ORG <endereço>` (*Origin*): Define o endereço inicial absoluto para alocação de memória de código ou dados.
*   `.BYTE <quantidade>`: Reserva um bloco de bytes contínuos na SRAM sem inicializar valores (usado apenas no `.DSEG`).
*   `.EQU <símbolo> = <valor>`: Define uma constante simbólica não modificável.
*   `.DEF <símbolo> = <registrador>`: Atribui um nome amigável a um registrador (ex: `.DEF contador = R16`).
*   `.DB` (*Define Byte*) / `.DW` (*Define Word*): Aloca constantes de byte ou palavras de 16 bits na memória Flash (`.CSEG`).

---

## 7. Modos de Endereçamento da Memória de Dados (SRAM)

O AVR possui 5 modos principais de acesso à memória SRAM de dados.

### 7.1 Endereçamento Direto (`lds` / `sts`)

O endereço de 16 bits da SRAM está codificado diretamente no segundo termo de 16 bits da própria instrução. Ocupa 2 palavras de memória (32 bits) e leva 2 ciclos de clock.

```assembly
LDS R16, 0x0100   ; R16 <- SRAM[0x0100] (Carrega direto)
STS 0x0104, R16   ; SRAM[0x0104] <- R16 (Armazena direto)
```

### 7.2 Endereçamento Indireto Simples (`ld` / `st`)

O endereço da memória de dados está contido em um dos registradores ponteiro ($X$, $Y$ ou $Z$). O valor do ponteiro não é alterado após a execução.

```assembly
; Considerando X (R27:R26) contendo 0x0100
LD R16, X         ; R16 <- SRAM[X]  (Lê a posição 0x0100; X continua em 0x0100)
ST Y, R17         ; SRAM[Y] <- R17  (Grava na posição Y; Y não muda)
```

### 7.3 Endereçamento Indireto com Pós-Incremento (`ld r, X+` / `st Z+, r`)

A CPU lê ou escreve no endereço contido no ponteiro e, **imediatamente após o acesso**, incrementa o valor do ponteiro em $+1$ de forma automática. Ideal para varrer vetores do início para o fim.

```assembly
LD R16, X+        ; Passo 1: R16 <- SRAM[X]
                  ; Passo 2: X <- X + 1
ST Z+, R18        ; Passo 1: SRAM[Z] <- R18
                  ; Passo 2: Z <- Z + 1
```

### 7.4 Endereçamento Indireto com Pré-Decremento (`ld r, -Y` / `st -X, r`)

A CPU **subtrai $-1$ do ponteiro em primeiro lugar** e, em seguida, realiza a leitura ou escrita no novo endereço resultante. Ideal para varrer vetores de trás para frente ou manipular estruturas de pilha.

```assembly
LD R16, -Y        ; Passo 1: Y <- Y - 1
                  ; Passo 2: R16 <- SRAM[Y]
ST -X, R17        ; Passo 1: X <- X - 1
                  ; Passo 2: SRAM[X] <- R17
```

### 7.5 Endereçamento Indireto com Deslocamento / Offset (`ldd` / `std`)

Suportado **exclusivamente pelos ponteiros $Y$ e $Z$**. A CPU calcula o endereço de acesso somando um deslocamento constante $q$ ($0 \le q \le 63$) ao valor do ponteiro. **O valor armazenado no ponteiro permanece inalterado**.

```assembly
; Considerando Y apontando para a base da estrutura (0x0100)
LDD R16, Y+1      ; Lê o byte no endereço (Y + 1 = 0x0101) para R16. Y continua em 0x0100
LDD R17, Y+5      ; Lê o byte no endereço (Y + 5 = 0x0105) para R17. Y continua em 0x0100
STD Y+8, R16      ; Grava R16 no endereço (Y + 8 = 0x0108). Y continua em 0x0100
```

---

## 8. Tabela Consolidada do Conjunto de Instruções AVR

A tabela abaixo resume as principais instruções do microcontrolador ATmega328P, suas operações, impacto em flags e ciclos de clock executados no hardware:

| Mnemônico | Operandos | Descrição da Operação | Flags Afetadas | Ciclos de Clock |
| :--- | :--- | :--- | :--- | :---: |
| **LDI** | $Rd, K$ | Carrega constante $K$ ($0..255$) em $Rd$ ($Rd \in [R16..R31]$) | Nenhum | 1 |
| **MOV** | $Rd, Rr$ | Copia registrador: $Rd \leftarrow Rr$ | Nenhum | 1 |
| **MOVW** | $Rd, Rr$ | Copia par de registradores ($Rd \in [R0, R2..R30]$, $Rr \in [R0, R2..R30]$) | Nenhum | 1 |
| **LDS** | $Rd, k$ | Carrega direto da SRAM de 16 bits: $Rd \leftarrow \text{SRAM}[k]$ | Nenhum | 2 |
| **STS** | $k, Rr$ | Armazena direto na SRAM de 16 bits: $\text{SRAM}[k] \leftarrow Rr$ | Nenhum | 2 |
| **LD** | $Rd, X\|Y\|Z$ | Carrega indireto: $Rd \leftarrow \text{SRAM}[\text{Ponteiro}]$ ($X+, -X$, etc.) | Nenhum | 2 |
| **ST** | $X\|Y\|Z, Rr$ | Armazena indireto: $\text{SRAM}[\text{Ponteiro}] \leftarrow Rr$ | Nenhum | 2 |
| **LDD** | $Rd, Y+q\|Z+q$ | Carrega com deslocamento: $Rd \leftarrow \text{SRAM}[\text{Ponteiro} + q]$ ($q \in [0..63]$) | Nenhum | 2 |
| **STD** | $Y+q\|Z+q, Rr$ | Armazena com deslocamento: $\text{SRAM}[\text{Ponteiro} + q] \leftarrow Rr$ ($q \in [0..63]$) | Nenhum | 2 |
| **LPM** | $Rd, Z$ | Lê constante da Memória Flash de Programa: $Rd \leftarrow \text{Flash}[Z]$ | Nenhum | 3 |
| **IN** | $Rd, P$ | Lê do registrador de I/O $P$ ($0..63$) para $Rd$ | Nenhum | 1 |
| **OUT** | $P, Rr$ | Escreve o registrador $Rr$ no registrador de I/O $P$ ($0..63$) | Nenhum | 1 |
| **PUSH** | $Rr$ | Empilha registrador: $\text{SRAM}[SP] \leftarrow Rr; SP \leftarrow SP - 1$ | Nenhum | 2 |
| **POP** | $Rd$ | Desempilha registrador: $SP \leftarrow SP + 1; Rd \leftarrow \text{SRAM}[SP]$ | Nenhum | 2 |
| **ADD** | $Rd, Rr$ | Soma sem carry: $Rd \leftarrow Rd + Rr$ | $Z, C, N, V, S, H$ | 1 |
| **ADC** | $Rd, Rr$ | Soma com carry: $Rd \leftarrow Rd + Rr + C$ | $Z, C, N, V, S, H$ | 1 |
| **SUB** | $Rd, Rr$ | Subtração sem carry: $Rd \leftarrow Rd - Rr$ | $Z, C, N, V, S, H$ | 1 |
| **SBC** | $Rd, Rr$ | Subtração com carry: $Rd \leftarrow Rd - Rr - C$ | $Z, C, N, V, S, H$ | 1 |
| **SUBI** | $Rd, K$ | Subtrai constante imediata: $Rd \leftarrow Rd - K$ ($Rd \in [R16..R31]$) | $Z, C, N, V, S, H$ | 1 |
| **SBCI** | $Rd, K$ | Subtrai constante com carry: $Rd \leftarrow Rd - K - C$ | $Z, C, N, V, S, H$ | 1 |
| **ADIW** | $Rd, K$ | Soma imediato ($K \in [0..63]$) a par de 16 bits ($Rd \in [R24, R26, R28, R30]$) | $Z, C, N, V, S$ | 2 |
| **SBIW** | $Rd, K$ | Subtrai imediato ($K \in [0..63]$) de par de 16 bits ($Rd \in [R24, R26, R28, R30]$) | $Z, C, N, V, S$ | 2 |
| **INC** | $Rd$ | Incrementa registrador: $Rd \leftarrow Rd + 1$ (NÃO altera flag $C$) | $Z, N, V, S$ | 1 |
| **DEC** | $Rd$ | Decrementa registrador: $Rd \leftarrow Rd - 1$ (NÃO altera flag $C$) | $Z, N, V, S$ | 1 |
| **AND / ANDI** | $Rd, Rr / K$ | Operação lógica E (bit a bit) | $Z, N, V=0, S$ | 1 |
| **OR / ORI** | $Rd, Rr / K$ | Operação lógica OU (bit a bit) | $Z, N, V=0, S$ | 1 |
| **EOR** | $Rd, Rr$ | Operação lógica OU Exclusivo (XOR). `EOR R16, R16` zera o registrador | $Z, N, V=0, S$ | 1 |
| **CLR** | $Rd$ | Zera registrador: $Rd \leftarrow 0$ | $Z=1, N=0, V=0, S=0$ | 1 |
| **CP / CPI** | $Rd, Rr / K$ | Compara registradores ou com imediato (subtração invisível) | $Z, C, N, V, S, H$ | 1 |
| **BRNE** | $label$ | Salta para rótulo se $Z = 0$ (Branch if Not Equal) | Nenhum | 1 ou 2 |
| **BREQ** | $label$ | Salta para rótulo se $Z = 1$ (Branch if Equal) | Nenhum | 1 ou 2 |
| **RJMP** | $label$ | Salto relativo incondicional | Nenhum | 2 |
| **RCALL** | $label$ | Chamada relativa de sub-rotina (empilha PC de 16 bits) | Nenhum | 3 |
| **RET** | Nenhum | Retorno de sub-rotina (desempilha PC de 16 bits) | Nenhum | 4 |

---

## 9. Aritmética de Múltiplos Bytes e Organização Little-Endian

A CPU de 8 bits do AVR processa números maiores que 8 bits (como variáveis de 16 bits ou 32 bits) fatiando as operações byte a byte.

### 9.1 Formato Little-Endian

O microcontrolador AVR utiliza a ordem **Little-Endian**:
*   O **byte menos significativo (LSB — Byte 0)** é sempre armazenado no **menor endereço de memória** (no rótulo da variável).
*   O **byte mais significativo (MSB — Byte 3 em 32 bits)** é armazenado no **maior endereço de memória**.

Representação na memória de uma variável de 32 bits $A = \text{0x12345678}$ alocada a partir de `0x0100`:

```
Endereço da SRAM :   0x0100      0x0101      0x0102      0x0103
Conteúdo (Hex)   :  [  0x78  ]  [  0x56  ]  [  0x34  ]  [  0x12  ]
Posição do Byte  :   Byte 0      Byte 1      Byte 2      Byte 3
                     (LSB)                               (MSB)
```

### 9.2 Propagação de Carry e Borrow

Para somar ou subtrair variáveis de 32 bits:
1.  **Primeiro Byte (Byte 0 — LSB)**: Executa-se `ADD` (ou `SUB`). Se a operação ultrapassar 255 (ou requerer empréstimo), a flag de Carry ($C$) no `SREG` é ajustada para 1.
2.  **Bytes Seguintes (Bytes 1, 2 e 3 — MSB)**: Executa-se `ADC` (*Add with Carry*) ou `SBC` (*Subtract with Carry*). Essas instruções adicionam ou subtraem o valor da flag $C$ gerada na etapa anterior, garantindo a exatidão matemática através de todas as casas.

---

## 10. Pilha (Stack), Sub-rotinas e Salvamento de Contexto

A Pilha é uma região dinâmica da memória SRAM destinada ao armazenamento temporário de registradores de trabalho e endereços de retorno de sub-rotinas e interrupções.

### 10.1 Mecânica da Pilha e Ponteiro de Pilha (SP)

*   **Localização**: A pilha é alocada no final da memória SRAM e **cresce para baixo** (dos endereços maiores em direção aos menores).
*   **Registrador SP**: O ponteiro de pilha é composto pelos registradores de I/O `SPH` (`0x3E`) e `SPL` (`0x3D`).
*   **Inicialização da Pilha**: Deve ser realizada obrigatoriamente no início da rotina de Reset configurando o SP para o endereço `RAMEND` (`0x08FF` no ATmega328P):

```assembly
LDI R16, HIGH(RAMEND)
OUT SPH, R16
LDI R16, LOW(RAMEND)
OUT SPL, R16
```

### 10.2 Funcionamento das Instruções de Pilha

*   `PUSH Rr`: A CPU escreve o byte do registrador na posição apontada por $SP$ e **pós-decrementa** o $SP$ em $-1$ ($SP \leftarrow SP - 1$).
*   `POP Rd`: A CPU **pré-incrementa** o $SP$ em $+1$ ($SP \leftarrow SP + 1$) e lê o byte da SRAM para $Rd$.
*   `RCALL label`: A CPU empilha os 2 bytes do endereço de retorno (Program Counter - PC) na pilha (decrementando o $SP$ em $-2$) e salta para o rótulo.
*   `RET`: A CPU desempilha os 2 bytes do endereço de retorno da pilha (incrementando o $SP$ em $+2$) e restaura o PC, retornando a execução para a instrução imediatamente posterior ao `RCALL`.

### 10.3 Salvamento de Contexto e Passagem de Parâmetros

Quando uma sub-rotina modifica registradores de trabalho ou afeta as flags do sistema através de operações matemáticas, ela deve **preservar o contexto** do programa chamador empilhando os registradores modificados e o registrador de status `SREG`.

Regra fundamental da pilha: **A restauração do contexto via `POP` deve ocorrer exatamente na ordem inversa dos empilhamentos (`PUSH`)**.

```assembly
minha_subrotina:
    ; 1. Salvamento de Contexto
    PUSH R16            ; Salva R16 na pilha
    PUSH R17            ; Salva R17 na pilha
    IN R16, SREG        ; Copia as flags do SREG para R16
    PUSH R16            ; Salva o SREG na pilha

    ; 2. Corpo da Sub-rotina (Processamento)
    ; ... (instruções da sub-rotina) ...

    ; 3. Restauração de Contexto (Ordem Inversa!)
    POP R16             ; Recupera o SREG antigo
    OUT SREG, R16       ; Restaura as flags do SREG no sistema
    POP R17             ; Restaura R17
    POP R16             ; Restaura R16

    RET                 ; Retorna para o programa principal
```

---

## 11. Programas e Exemplos de Código Assembly AVR Totalmente Comentados

Nesta seção, apresentamos implementações completas e totalmente comentadas linha a linha, cobrindo todos os tópicos fundamentais da disciplina.

### 11.1 Soma de Variáveis de 32 Bits nos 4 Modos de Endereçamento

Programa completo para realizar a operação $C = A + B$ com variáveis de 32 bits (4 bytes cada) alocadas sequencialmente na SRAM a partir de `SRAM_START` (`0x0100`).

```assembly
.INCLUDE <m328pdef.inc>     ; Inclui mapeamento de registradores do ATmega328P

.DSEG                       ; Seleciona segmento de dados (SRAM)
.ORG SRAM_START             ; Define endereço inicial como 0x0100
    A: .BYTE 4              ; Aloca 4 bytes para A (0x0100 a 0x0103)
    B: .BYTE 4              ; Aloca 4 bytes para B (0x0104 a 0x0107)
    C: .BYTE 4              ; Aloca 4 bytes para C (0x0108 a 0x010B)

.CSEG                       ; Seleciona segmento de código (Flash)
.ORG 0x0000                 ; Endereço de Reset
    RJMP START              ; Salta para o início do programa principal

START:
    ; Inicialização da Pilha (Stack Pointer)
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16

    ; =========================================================================
    ; IMPLEMENTAÇÃO 1: ENDEREÇAMENTO DIRETO (LDS / STS)
    ; =========================================================================
    ; Byte 0 (LSB) - Soma simples
    LDS R16, A              ; Carrega A[0] para R16
    LDS R17, B              ; Carrega B[0] para R17
    ADD R16, R17            ; R16 = A[0] + B[0]
    STS C, R16              ; Guarda o resultado em C[0]

    ; Byte 1 - Soma com Carry
    LDS R16, A+1            ; Carrega A[1] para R16
    LDS R17, B+1            ; Carrega B[1] para R17
    ADC R16, R17            ; R16 = A[1] + B[1] + Carry
    STS C+1, R16            ; Guarda o resultado em C[1]

    ; Byte 2 - Soma com Carry
    LDS R16, A+2            ; Carrega A[2] para R16
    LDS R17, B+2            ; Carrega B[2] para R17
    ADC R16, R17            ; R16 = A[2] + B[2] + Carry
    STS C+2, R16            ; Guarda o resultado em C[2]

    ; Byte 3 (MSB) - Soma com Carry
    LDS R16, A+3            ; Carrega A[3] para R16
    LDS R17, B+3            ; Carrega B[3] para R17
    ADC R16, R17            ; R16 = A[3] + B[3] + Carry
    STS C+3, R16            ; Guarda o resultado em C[3]

    ; =========================================================================
    ; IMPLEMENTAÇÃO 2: ENDEREÇAMENTO INDIRETO SIMPLES (LD / ST com ADIW)
    ; =========================================================================
    ; Aponta X para A, Y para B e Z para C
    LDI R27, HIGH(A)        ; Carrega byte alto do endereço de A em XH (R27)
    LDI R26, LOW(A)         ; Carrega byte baixo do endereço de A em XL (R26)
    LDI R29, HIGH(B)        ; Carrega byte alto do endereço de B em YH (R29)
    LDI R28, LOW(B)         ; Carrega byte baixo do endereço de B em YL (R28)
    LDI R31, HIGH(C)        ; Carrega byte alto do endereço de C em ZH (R31)
    LDI R30, LOW(C)         ; Carrega byte baixo do endereço de C em ZL (R30)

    ; Byte 0 (LSB)
    LD R16, X               ; Lê A[0] apontado por X
    LD R17, Y               ; Lê B[0] apontado por Y
    ADD R16, R17            ; Soma os bytes menos significativos
    ST Z, R16               ; Grava em C[0] apontado por Z

    ; Avança ponteiros manualmente para o Byte 1
    ADIW R26, 1             ; Incrementa ponteiro X (R27:R26) em +1
    ADIW R28, 1             ; Incrementa ponteiro Y (R29:R28) em +1
    ADIW R30, 1             ; Incrementa ponteiro Z (R31:R30) em +1

    ; Byte 1
    LD R16, X               ; Lê A[1]
    LD R17, Y               ; Lê B[1]
    ADC R16, R17            ; Soma com Carry
    ST Z, R16               ; Grava em C[1]

    ; Avança ponteiros para o Byte 2
    ADIW R26, 1             ; Incrementa X em +1
    ADIW R28, 1             ; Incrementa Y em +1
    ADIW R30, 1             ; Incrementa Z em +1

    ; Byte 2
    LD R16, X               ; Lê A[2]
    LD R17, Y               ; Lê B[2]
    ADC R16, R17            ; Soma com Carry
    ST Z, R16               ; Grava em C[2]

    ; Avança ponteiros para o Byte 3
    ADIW R26, 1             ; Incrementa X em +1
    ADIW R28, 1             ; Incrementa Y em +1
    ADIW R30, 1             ; Incrementa Z em +1

    ; Byte 3 (MSB)
    LD R16, X               ; Lê A[3]
    LD R17, Y               ; Lê B[3]
    ADC R16, R17            ; Soma com Carry
    ST Z, R16               ; Grava em C[3]

    ; =========================================================================
    ; IMPLEMENTAÇÃO 3: ENDEREÇAMENTO INDIRETO COM PÓS-INCREMENTO (X+, Y+, Z+)
    ; =========================================================================
    ; Reinicializa ponteiros para a base das variáveis
    LDI R27, HIGH(A)
    LDI R26, LOW(A)
    LDI R29, HIGH(B)
    LDI R28, LOW(B)
    LDI R31, HIGH(C)
    LDI R30, LOW(C)

    ; Byte 0 (LSB)
    LD R16, X+              ; Lê A[0] e avança X para A[1]
    LD R17, Y+              ; Lê B[0] e avança Y para B[1]
    ADD R16, R17            ; Soma LSB
    ST Z+, R16              ; Grava em C[0] e avança Z para C[1]

    ; Byte 1
    LD R16, X+              ; Lê A[1] e avança X para A[2]
    LD R17, Y+              ; Lê B[1] e avança Y para B[2]
    ADC R16, R17            ; Soma com Carry
    ST Z+, R16              ; Grava em C[1] e avança Z para C[2]

    ; Byte 2
    LD R16, X+              ; Lê A[2] e avança X para A[3]
    LD R17, Y+              ; Lê B[2] e avança Y para B[3]
    ADC R16, R17            ; Soma com Carry
    ST Z+, R16              ; Grava em C[2] e avança Z para C[3]

    ; Byte 3 (MSB)
    LD R16, X+              ; Lê A[3] e avança X
    LD R17, Y+              ; Lê B[3] e avança Y
    ADC R16, R17            ; Soma com Carry
    ST Z+, R16              ; Grava em C[3] e avança Z

    ; =========================================================================
    ; IMPLEMENTAÇÃO 4: ENDEREÇAMENTO INDIRETO COM DESLOCAMENTO (LDD / STD)
    ; =========================================================================
    ; Mapeamento sequencial na SRAM a partir de Y (endereço de A = 0x0100):
    ; A: Y+0 a Y+3 | B: Y+4 a Y+7 | C: Y+8 a Y+11
    LDI R29, HIGH(A)        ; Carrega byte alto de A em YH
    LDI R28, LOW(A)         ; Carrega byte baixo de A em YL (Y aponta para 0x0100)

    ; Byte 0 (LSB)
    LDD R16, Y+0            ; Lê A[0] (offset +0)
    LDD R17, Y+4            ; Lê B[0] (offset +4)
    ADD R16, R17            ; Soma LSB
    STD Y+8, R16            ; Grava em C[0] (offset +8)

    ; Byte 1
    LDD R16, Y+1            ; Lê A[1] (offset +1)
    LDD R17, Y+5            ; Lê B[1] (offset +5)
    ADC R16, R17            ; Soma com Carry
    STD Y+9, R16            ; Grava em C[1] (offset +9)

    ; Byte 2
    LDD R16, Y+2            ; Lê A[2] (offset +2)
    LDD R17, Y+6            ; Lê B[2] (offset +6)
    ADC R16, R17            ; Soma com Carry
    STD Y+10, R16           ; Grava em C[2] (offset +10)

    ; Byte 3 (MSB)
    LDD R16, Y+3            ; Lê A[3] (offset +3)
    LDD R17, Y+7            ; Lê B[3] (offset +7)
    ADC R16, R17            ; Soma com Carry
    STD Y+11, R16           ; Grava em C[3] (offset +11)

FIM_PROGRAMA:
    RJMP FIM_PROGRAMA       ; Laço infinito para encerrar a execução de forma segura
```

---

### 11.2 Programa Modular Completo com Sub-rotinas e Salvamento de Contexto

Este programa demonstra a estrutura modular completa de uma aplicação em Assembly AVR, utilizando chamadas de sub-rotinas (`RCALL`), inicialização de variáveis, zeramento de memória e operação de subtração de 32 bits ($C = A - B$) com preservação do registrador de status `SREG`.

```assembly
.INCLUDE <m328pdef.inc>     ; Inclui definições padrão do ATmega328P

.DSEG                       ; Segmento de dados (SRAM)
.ORG SRAM_START             ; Endereço 0x0100
    A: .BYTE 4              ; Variável A de 32 bits (0x0100 a 0x0103)
    B: .BYTE 4              ; Variável B de 32 bits (0x0104 a 0x0107)
    C: .BYTE 4              ; Variável C de 32 bits (0x0108 a 0x010B)

.CSEG                       ; Segmento de código (Flash)
.ORG 0x0000                 ; Endereço de Reset
    RJMP START              ; Salta para a inicialização

START:
    ; 1. Inicialização Obrigatória da Pilha (Stack Pointer)
    LDI R16, HIGH(RAMEND)   ; Carrega byte alto do topo da SRAM (0x08)
    OUT SPH, R16            ; Escreve no registrador SPH
    LDI R16, LOW(RAMEND)    ; Carrega byte baixo do topo da SRAM (0xFF)
    OUT SPL, R16            ; Escreve no registrador SPL

    ; 2. Teste 1: Inicializar a variável A com o valor 0x44332211
    LDI XL, LOW(A)          ; Aponta ponteiro X para a variável A
    LDI XH, HIGH(A)
    LDI R16, 0x11           ; Passa Byte 0 (LSB) no registrador R16
    LDI R17, 0x22           ; Passa Byte 1 no registrador R17
    LDI R18, 0x33           ; Passa Byte 2 no registrador R18
    LDI R19, 0x44           ; Passa Byte 3 (MSB) no registrador R19
    RCALL init_32bits       ; Chama sub-rotina para gravar na memória

    ; 3. Teste 2: Zerar a variável B
    LDI XL, LOW(B)          ; Recarrega ponteiro X para apontar para B
    LDI XH, HIGH(B)
    RCALL zera_32bits       ; Chama sub-rotina para preencher B com zeros

    ; 4. Teste 3: Subtrair B de A e guardar em C (C = A - B)
    LDI XL, LOW(A)          ; X aponta para o minuendo (A)
    LDI XH, HIGH(A)
    LDI YL, LOW(B)          ; Y aponta para o subtraendo (B)
    LDI YH, HIGH(B)
    LDI ZL, LOW(C)          ; Z aponta para o resultado (C)
    LDI ZH, HIGH(C)
    RCALL sub_32bits        ; Chama sub-rotina de subtração de 32 bits

FIM_MAIN:
    RJMP FIM_MAIN           ; Loop infinito para conter a execução do programa

; ==============================================================================
; SUB-ROTINA: init_32bits
; Descrição: Grava os valores contidos em R16, R17, R18 e R19 na SRAM
; Parâmetros: X (ponteiro de destino), R16-R19 (dados a gravar)
; ==============================================================================
init_32bits:
    ST X+, R16              ; Grava Byte 0 (LSB) e incrementa X
    ST X+, R17              ; Grava Byte 1 e incrementa X
    ST X+, R18              ; Grava Byte 2 e incrementa X
    ST X+, R19              ; Grava Byte 3 (MSB) e incrementa X
    RET                     ; Retorna ao programa principal

; ==============================================================================
; SUB-ROTINA: zera_32bits
; Descrição: Preenche 4 bytes consecutivos da SRAM com o valor zero
; Parâmetros: X (ponteiro para a variável a ser zerada)
; ==============================================================================
zera_32bits:
    PUSH R16                ; Salva contexto do registrador R16 na pilha
    CLR R16                 ; R16 = 0
    ST X+, R16              ; Grava 0 em Byte 0 e incrementa X
    ST X+, R16              ; Grava 0 em Byte 1 e incrementa X
    ST X+, R16              ; Grava 0 em Byte 2 e incrementa X
    ST X+, R16              ; Grava 0 em Byte 3 e incrementa X
    POP R16                 ; Restaura contexto do registrador R16 da pilha
    RET                     ; Retorna ao programa principal

; ==============================================================================
; SUB-ROTINA: sub_32bits
; Descrição: Executa a subtração de 32 bits: Z = X - Y (C = A - B)
; Parâmetros: X (Minuendo), Y (Subtraendo), Z (Resultado)
; Preservação de Contexto: Salva R16, R17 e o registrador de status SREG
; ==============================================================================
sub_32bits:
    ; --- Salvamento de Contexto ---
    PUSH R16                ; Salva R16 na pilha
    PUSH R17                ; Salva R17 na pilha
    IN R16, SREG            ; Lê as flags atuais do SREG
    PUSH R16                ; Salva as flags na pilha

    ; --- Byte 0 (Subtração Simples LSB) ---
    LD R16, X+              ; Lê Byte 0 de A para R16 e avança X
    LD R17, Y+              ; Lê Byte 0 de B para R17 e avança Y
    SUB R16, R17            ; R16 = A[0] - B[0]
    ST Z+, R16              ; Guarda em C[0] e avança Z

    ; --- Byte 1 (Subtração com Borrow) ---
    LD R16, X+              ; Lê Byte 1 de A para R16 e avança X
    LD R17, Y+              ; Lê Byte 1 de B para R17 e avança Y
    SBC R16, R17            ; R16 = A[1] - B[1] - Carry
    ST Z+, R16              ; Guarda em C[1] e avança Z

    ; --- Byte 2 (Subtração com Borrow) ---
    LD R16, X+              ; Lê Byte 2 de A para R16 e avança X
    LD R17, Y+              ; Lê Byte 2 de B para R17 e avança Y
    SBC R16, R17            ; R16 = A[2] - B[2] - Carry
    ST Z+, R16              ; Guarda em C[2] e avança Z

    ; --- Byte 3 (Subtração com Borrow MSB) ---
    LD R16, X+              ; Lê Byte 3 de A para R16 e avança X
    LD R17, Y+              ; Lê Byte 3 de B para R17 e avança Y
    SBC R16, R17            ; R16 = A[3] - B[3] - Carry
    ST Z+, R16              ; Guarda em C[3] e avança Z

    ; --- Restauração de Contexto (Ordem Inversa) ---
    POP R16                 ; Desempilha o valor antigo do SREG
    OUT SREG, R16           ; Restaura as flags do SREG no sistema
    POP R17                 ; Restaura R17
    POP R16                 ; Restaura R16

    RET                     ; Retorna ao programa chamador
```

---

## 12. Armadilhas e Erros Comuns de Programação em Assembly AVR

A lista a seguir compila as falhas mais frequentes cometidas no desenvolvimento e depuração de código Assembly AVR em avaliações e aplicações práticas:

1.  **Tentativa de uso de constantes imediatas em $R0..R15$**: Executar `LDI R5, 10` ou `CPI R2, 0x05` gera erro de compilação. Operandos imediatos só funcionam de $R16$ a $R31$.
2.  **Confusão entre `INC`/`DEC` e as flags de Carry**: A instrução `INC` ou `DEC` **não altera a Carry Flag ($C$)**. Em laços de repetição de múltiplos bytes, utilize `DEC` para o contador sem receio de corromper o Carry mantido entre as somas/subtrações.
3.  **Esquecimento da propagação de Carry**: Fazer somas de múltiplos bytes usando apenas `ADD` para todas as posições em vez de migrar para `ADC` a partir do segundo byte resulta em cálculos matemáticos incorretos.
4.  **Tentativa de usar deslocamento ($LDD$/$STD$) no Ponteiro $X$**: O hardware do AVR não possui suporte a offset no ponteiro $X$. Deslocamentos só são aceitos nos ponteiros $Y$ e $Z$.
5.  **Não inicializar o Ponteiro de Pilha ($SP$)**: Executar `RCALL`, `PUSH` ou `POP` sem configurar `SPH` e `SPL` para `RAMEND` faz a CPU operar com ponteiro de pilha zerado, sobrescrevendo registradores de I/O e travando a execução.
6.  **Desbalanceamento da Pilha**: Fazer um `PUSH` dentro de uma sub-rotina sem executar o respectivo `POP` antes da instrução `RET`. A instrução `RET` lerá os dados empilhados achando que constituem o endereço de retorno do Program Counter (PC), fazendo a CPU saltar para posições aleatórias da memória.
7.  **Inversão na ordem de restauração de contexto**: Desempilhar dados na mesma ordem em que foram empilhados. A pilha opera no modelo LIFO (*Last In, First Out*). Se a sequência foi `PUSH R16` $\rightarrow$ `PUSH R17`, a restauração deve ser obrigatoriamente `POP R17` $\rightarrow$ `POP R16`.
8.  **Ausência de laço infinito no final do programa principal (*Fall-through*)**: Não inserir uma barreira como `FIM: RJMP FIM` no final do fluxo principal faz a CPU "escorregar" para dentro do código das sub-rotinas sem ter havido uma chamada `RCALL`, corrompendo a pilha ao encontrar a instrução `RET`.
