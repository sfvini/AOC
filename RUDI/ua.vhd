-- Arquitetura e Organizacao de Computadores
-- Autor: Roberto de Matos
-- Unidade aritmética do processador didático Rudi.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ua is
  generic (
    N : natural := 8
  );
  port (
    f    : in std_logic;
    a, b : in std_logic_vector (N - 1 downto 0);
    s    : out std_logic_vector (N - 1 downto 0)
  );
end entity;

architecture behav of ua is
  signal as, bs, ss : signed(N - 1 downto 0);
begin
  as <= signed(a);
  bs <= signed(b);

  with f select
    ss <= as + bs when '0',
    as - bs when others;

  s <= std_logic_vector(ss);

end architecture;
