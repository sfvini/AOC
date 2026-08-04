-- Arquitetura e Organizacao de Computadores
-- Autor: Roberto de Matos
-- Decodificador do processador didático Rudi.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode is
  port (
    opcode          : in std_logic_vector (1 downto 0);
    sel, wr_acc, op : out std_logic
  );
end entity;

architecture struct of decode is
begin

end architecture;
