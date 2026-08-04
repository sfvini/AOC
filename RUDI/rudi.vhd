-- Arquitetura e Organizacao de Computadores
-- Autor: Roberto de Matos
-- CPU Rudi.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rudi is
  port (
    clk, rst : in std_logic;
    opcode   : in std_logic_vector (1 downto 0);
    operando : in std_logic_vector (7 downto 0);
    cpu_out  : out std_logic_vector (7 downto 0)
  );
end entity;

architecture behav of rudi is

  component decode is
    port (
      opcode          : in std_logic_vector (1 downto 0);
      sel, wr_acc, op : out std_logic
    );
  end component;

  component datapath is
    port (
      clk, rst        : in std_logic;
      operando        : in std_logic_vector (7 downto 0);
      cpu_out         : out std_logic_vector (7 downto 0);
      sel, wr_acc, op : in std_logic
    );
  end component;

  signal sel, wr_acc, op : std_logic;

begin

  decode0: decode
  port map (
    opcode => opcode,       
    sel => sel,
    wr_acc => wr_acc,
    op => op
  );
  
  dp0 : datapath
  port map
  (
    clk      => clk,
    rst      => rst,
    operando => operando,
    cpu_out  => cpu_out,
    sel      => sel,
    wr_acc   => wr_acc,
    op       => op
  );

end architecture;
