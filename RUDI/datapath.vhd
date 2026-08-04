-- Arquitetura e Organizacao de Computadores
-- Autor: Roberto de Matos
-- Datapath do processador didático Rudi.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
  port (
    clk, rst        : in std_logic;
    operando        : in std_logic_vector (7 downto 0);
    cpu_out         : out std_logic_vector (7 downto 0);
    sel, wr_acc, op : in std_logic
  );
end entity;

architecture behav of datapath is
  component ua is
    generic (
      N : natural := 8
    );
    port (
      f    : in std_logic;
      a, b : in std_logic_vector (N - 1 downto 0);
      s    : out std_logic_vector (N - 1 downto 0)
    );
  end component;

  component regN is
    generic (
      N      : natural   := 8;
      EN_cfg : std_logic := '1' -- Enable config. (1 - ativo em alto)
    );
    port (
      d            : in std_logic_vector (N - 1 downto 0);
      clk, en, rst : in std_logic;
      q            : out std_logic_vector (N - 1 downto 0)
    );
  end component;

  signal acc_out, acc_in, ua_out : std_logic_vector(7 downto 0);

begin

  ua0 : ua
  generic map(
    N => 8
  )
  port map
  (
    f => op,
    a => acc_out,
    b => operando,
    s => ua_out
  );

  acc : regN
  generic map(
    N      => 8,
    EN_cfg => '1'
  )
  port map
  (
    d   => acc_in,
    clk => clk,
    en  => wr_acc,
    rst => rst,
    q   => acc_out
  );

  with sel select
  acc_in <= operando when '0',
  ua_out when others;

  cpu_out <= acc_out;
end architecture;
