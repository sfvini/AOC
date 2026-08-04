-- Arquitetura e Organizacao de Computadores
-- Autor: Roberto de Matos
-- CPU Rudi.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_de2_115 is
  port (
    KEY      : in std_logic_vector (3 downto 0);
    SW       : in std_logic_vector (17 downto 0);
    LEDG     : out std_logic_vector (7 downto 0)
  );
end entity;

architecture behav of top_de2_115 is
  
  component rudi is
    port (
      clk, rst : in std_logic;
      opcode   : in std_logic_vector (1 downto 0);
      operando : in std_logic_vector (7 downto 0);
      cpu_out  : out std_logic_vector (7 downto 0)
    );
  end component;
  
  signal reset, exec: std_logic;
begin

  reset <= not KEY(3);  
  exec <= not KEY(0);
					  
  comp : rudi
  port map (
    clk      => exec,
    rst      => reset,
    opcode   => SW(17 downto 16),
    operando => SW(7 downto 0),
    cpu_out  => LEDG
  );	 
	 
end architecture;
