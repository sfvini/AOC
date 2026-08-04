-- Arquitetura e Organizacao de Computadores
-- Autor: Roberto de Matos
-- Registrador de largura generica com enable  configuravel.

library ieee;
use ieee.std_logic_1164.all;

entity regN is
  generic (
    N      : natural   := 8;
    EN_cfg : std_logic := '1' -- Enable config. (1 - ativo em alto)
  );
  port (
    d            : in std_logic_vector (N - 1 downto 0);
    clk, en, rst : in std_logic;
    q            : out std_logic_vector (N - 1 downto 0)
  );
end entity;

architecture behav of regN is
  signal q_reg, q_next : std_logic_vector(N - 1 downto 0);
begin
  process (clk, rst)
  begin
    if (rst = '1') then
      q_reg <= (others => '0');
    elsif (rising_edge(clk)) then
      q_reg <= q_next;
    end if;
  end process;

  -- Next state 
  q_next <= d when en = EN_cfg else
    q_reg;

  q <= q_reg;
end architecture;
