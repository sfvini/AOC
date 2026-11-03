# Resumo e Template: Assembly AVR (ATmega328p)

Este documento contém os conceitos fundamentais, principais instruções e templates estruturais para programação em Assembly no microcontrolador ATmega328p, cobrindo GPIO e Interrupções.

---

## 1. Conceitos Fundamentais e Instruções de I/O

Os registradores de I/O são a interface entre o microcontrolador e o mundo externo. 

### Principais Instruções
*   **`in Rd, A`**: Lê um registrador de I/O para um registrador geral.
*   **`out A, Rr`**: Escreve de um registrador geral para um registrador de I/O.
*   **`cbi A, b`**: Zera (0) um bit específico de um registrador de I/O.
*   **`sbi A, b`**: Seta (1) um bit específico de um registrador de I/O.
*   **`sbic A, b`**: Pula a próxima instrução se o bit for zero (0).
*   **`sbis A, b`**: Pula a próxima instrução se o bit for um (1).

### Diretiva `.INCLUDE`
Usada para incluir arquivos de definição, mapeando endereços de memória para nomes legíveis (ex: `DDRB`, `PORTB`).
*   **Sintaxe:** `.INCLUDE <m328Pdef.INC>`

---

## 2. Portas de I/O (GPIO)

O controle de cada porta (B, C ou D) é feito por três registradores:

1.  **DDRx (Direção):** `1` = Saída | `0` = Entrada.
2.  **PORTx (Dados):** 
    *   Se Saída: `1` = 5V (HIGH) | `0` = 0V (LOW).
    *   Se Entrada: `1` = Ativa Pull-up interno | `0` = Alta impedância (Hi-Z).
3.  **PINx (Leitura):** Lê o estado físico atual do pino (nível lógico).

---

## 3. Interrupções e seus Registradores (Exemplo: INT0/INT1)

As interrupções pausam o fluxo principal para atender eventos imediatos. Para usar interrupções externas, você precisa configurar:

1.  **EICRA:** Define o gatilho da interrupção (Nível baixo, Qualquer mudança, Borda de descida, Borda de subida).
2.  **EIMSK:** Habilita a máscara da interrupção específica (ex: ativa o bit de INT0).
3.  **SREG (Bit I):** A chave geral de interrupções da CPU. Deve ser ativada usando a instrução `SEI`.

**Regra de Ouro (Contexto):** Toda Rotina de Serviço de Interrupção (ISR) deve obrigatoriamente salvar o estado do registrador `SREG` e dos registradores de uso geral afetados no início, e restaurá-los antes de finalizar com `RETI`.

---

## 4. Templates de Código Estrutural

### Template Básico (GPIO Simples)

```assembly
; ==========================================
; CABEÇALHO E INCLUDES
; ==========================================
.INCLUDE <m328Pdef.INC>

; Definições de nomes (Opcional)
; .equ NOME = PINO
; .def REG_AUX = R16

; ==========================================
; VETORES DE RESET E INTERRUPÇÃO
; ==========================================
.ORG 0x0000
    RJMP setup

; ==========================================
; INÍCIO DO PROGRAMA PRINCIPAL
; ==========================================
.ORG 0x0034 ; Endereço após a tabela de vetores

setup:
    ; 1. Configurar DDRx (Entradas e Saídas)
    ; 2. Configurar PORTx (Estado inicial e Pull-ups)
    
main:
    ; 1. Lógica principal do seu programa
    ; 2. Leituras de PINx
    ; 3. Escritas em PORTx
    
    RJMP main ; Loop infinito

; ==========================================
; SUB-ROTINAS (Se houver)
; ==========================================
subrotina_exemplo:
    ; ...
    RET
```

### Template Avançado (Com Interrupções)

```assembly
; ==========================================
; CABEÇALHO E INCLUDES
; ==========================================
.INCLUDE <m328Pdef.INC>

; ==========================================
; VETORES DE INTERRUPÇÃO
; ==========================================
.ORG 0x0000
    RJMP setup      ; Vetor de Reset

; Adicione aqui o vetor da sua interrupção específica
; Exemplo para INT0:
.ORG 0x0002
    RJMP isr_int0   ; Salta para a rotina da INT0

; ==========================================
; INÍCIO DO PROGRAMA PRINCIPAL
; ==========================================
.ORG 0x0034

setup:
    ; 1. Configurar I/O (DDRx, PORTx)
    ; 2. Configurar os registradores da Interrupção (ex: EICRA, EIMSK)
    
    SEI             ; 3. Habilita as interrupções globais

main:
    ; Lógica principal que será interrompida quando o evento ocorrer
    RJMP main

; ==========================================
; ROTINAS DE SERVIÇO DE INTERRUPÇÃO (ISR)
; ==========================================
isr_int0:
    ; --- 1. Salvar Contexto ---
    PUSH R16        ; Salva R16 (se for usá-lo)
    IN R16, SREG    ; Copia SREG para R16
    PUSH R16        ; Salva SREG na pilha

    ; --- 2. Lógica da Interrupção ---
    ; (Trate o evento aqui o mais rápido possível)

    ; --- 3. Restaurar Contexto ---
    POP R16         ; Recupera valor antigo do SREG
    OUT SREG, R16   ; Restaura SREG
    POP R16         ; Restaura R16
    
    RETI            ; Retorna para o programa principal
```