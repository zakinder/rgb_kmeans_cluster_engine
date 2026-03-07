-----------------------------------------------------------------------------
-- Module: rgb_cluster_core
-- Author: Sakinder
-- Description: 
-- Refined version of original clustering module.
--
-- Function: 
--   Performs RGB color clustering for real-time image processing.
--   Incoming pixel RGB values are compared with centroid lookup tables
--   and assigned to the nearest cluster.
--
-- Key Processing Steps: 
--   1. Receive RGB pixel stream
--   2. Compare pixel against K cluster centroids
--   3. Compute distance / similarity metric
--   4. Select closest centroid
--   5. Output clustered RGB value
--
-- Notes: 
--   Signal names simplified for readability.
--   Functional behavior unchanged.
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fixed_pkg.all;
use work.float_pkg.all;
use work.constants_package.all;
use work.vpf_records.all;
use work.ports_package.all;
entity rgb_cluster_core is
generic (
    data_width: integer: = 8);
port (
    clk: in std_logic;
    rst_n: in std_logic;
    pixel_in_rgb: in channel;
    k_rgb: in int_rgb;
    threshold: out integer);
end rgb_cluster_core;
architecture arch of rgb_cluster_core is
type s_pixel is record
    i_red: integer;
    i_gre: integer;
    i_blu: integer;
    red: integer;
    gre: integer;
    blu: integer;
    m1: integer;
    m2: integer;
    m3: integer;
    mac: integer;
    mac_syn: integer;
    sum: std_logic_vector (31 downto 0);
    sum2: std_logic_vector (31 downto 0);
    rslt: std_logic_vector (15 downto 0);
    rslt2: integer;
end record;
    signal rgb_set1: s_pixel;
begin
process (clk) begin
    if rising_edge(clk) then
          rgb_set1.i_red <= to_integer(unsigned(pixel_in_rgb.red(9 downto 2)));
          rgb_set1.i_gre <= to_integer(unsigned(pixel_in_rgb.green(9 downto 2)));
          rgb_set1.i_blu <= to_integer(unsigned(pixel_in_rgb.blue(9 downto 2)));
    end if;
end process;

process (clk) begin
    if rising_edge(clk) then
          rgb_set1.red <= abs(k_rgb.red - rgb_set1.i_red);
          rgb_set1.gre <= abs(k_rgb.gre - rgb_set1.i_gre);
          rgb_set1.blu <= abs(k_rgb.blu - rgb_set1.i_blu);
    end if;
end process;

process (clk) begin
  if rising_edge(clk) then
      rgb_set1.m1 <= (rgb_set1.red * rgb_set1.red);
      rgb_set1.m2 <= (rgb_set1.gre * rgb_set1.gre);
      rgb_set1.m3 <= (rgb_set1.blu * rgb_set1.blu);
  end if;
end process;

process (clk) begin
  if rising_edge(clk) then
      rgb_set1.mac <= rgb_set1.m1 + rgb_set1.m2 + rgb_set1.m3;
  end if;
end process;

process (clk) begin
  if rising_edge(clk) then
    rgb_set1.sum <= std_logic_vector(to_unsigned(rgb_set1.mac,32));
  end if;
end process;

process (clk) begin
  if rising_edge(clk) then
    rgb_set1.sum2 <= rgb_set1.sum;
  end if;
end process;

square_root_inst: square_root
generic map(
    data_width => 32)
port map(
   clock => clk,
   rst_n => rst_n,
   radicand_in => rgb_set1.sum2,
   root_out => rgb_set1.rslt);

process (clk, rst_n) begin
  if rising_edge(clk) then
    rgb_set1.rslt2 <= to_integer(unsigned(rgb_set1.rslt));

  end if;
end process;

process (clk, rst_n) begin
  if rising_edge(clk) then
    threshold <= rgb_set1.rslt2;
  end if;
end process;

end architecture;
