-----------------------------------------------------------------------------
-- FILE : rgb_cluster_core.vhd
-- Author      : Sakinder
-- DESCRIPTION
-- This version contains extensive inline comments explaining the behavior
-- of the module for readability, maintainability, and documentation.
--
-- COMMENT COVERAGE
-- • Entity interface explanation
-- • Generics and configuration parameters
-- • Internal signal roles
-- • Sequential processes and clocking
-- • Pipeline data flow
-- • Computational stages
--
-- Compatible with standard IEEE VHDL tools.
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Module : rgb_cluster_core
-- Description :
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
-- Entity declaration: defines the external interface (ports/generics) of the module
entity rgb_cluster_core is
-- Generic parameters: compile‑time configuration values
generic (
    data_width     : integer := 8);
-- Port definitions: input/output interface signals
port (
    clk            : in std_logic;
    rst_n          : in std_logic;
    pixel_in_rgb           : in channel;
    k_rgb          : in int_rgb;
    threshold      : out integer);
-- End of design block
end rgb_cluster_core;
-- Architecture block: contains internal implementation of the entity
architecture arch of rgb_cluster_core is
type s_pixel is record
    i_red      : integer;
    i_gre      : integer;
    i_blu      : integer;
    red        : integer;
    gre        : integer;
    blu        : integer;
    m1         : integer;
    m2         : integer;
    m3         : integer;
    mac        : integer;
    mac_syn    : integer;
    sum        : std_logic_vector (31 downto 0);
    sum2       : std_logic_vector (31 downto 0);
    rslt       : std_logic_vector (15 downto 0);
    rslt2      : integer;
-- End of design block
end record;
-- Internal signal declaration: used for data transfer between concurrent blocks
    signal rgb_set1       : s_pixel;
-- Begin implementation section
begin
-- Sequential process block: executed on clock or sensitivity list events
process (clk) begin
-- Rising edge clock detection: ensures synchronous sequential logic
    if rising_edge(clk) then
          rgb_set1.i_red      <= to_integer(unsigned(pixel_in_rgb.red(9 downto 2)));
          rgb_set1.i_gre      <= to_integer(unsigned(pixel_in_rgb.green(9 downto 2)));
          rgb_set1.i_blu      <= to_integer(unsigned(pixel_in_rgb.blue(9 downto 2)));
-- End of design block
    end if;
-- End of design block
end process;

-- Sequential process block: executed on clock or sensitivity list events
process (clk) begin
-- Rising edge clock detection: ensures synchronous sequential logic
    if rising_edge(clk) then
          rgb_set1.red          <= abs(k_rgb.red - rgb_set1.i_red);
          rgb_set1.gre          <= abs(k_rgb.gre - rgb_set1.i_gre);
          rgb_set1.blu          <= abs(k_rgb.blu - rgb_set1.i_blu);
-- End of design block
    end if;
-- End of design block
end process;

-- Sequential process block: executed on clock or sensitivity list events
process (clk) begin
-- Rising edge clock detection: ensures synchronous sequential logic
  if rising_edge(clk) then
      rgb_set1.m1    <= (rgb_set1.red * rgb_set1.red);
      rgb_set1.m2    <= (rgb_set1.gre * rgb_set1.gre);
      rgb_set1.m3    <= (rgb_set1.blu * rgb_set1.blu);
-- End of design block
  end if;
-- End of design block
end process;

-- Sequential process block: executed on clock or sensitivity list events
process (clk) begin
-- Rising edge clock detection: ensures synchronous sequential logic
  if rising_edge(clk) then
      rgb_set1.mac   <= rgb_set1.m1 + rgb_set1.m2 + rgb_set1.m3;
-- End of design block
  end if;
-- End of design block
end process;


-- Sequential process block: executed on clock or sensitivity list events
process (clk) begin
-- Rising edge clock detection: ensures synchronous sequential logic
  if rising_edge(clk) then
    rgb_set1.sum <= std_logic_vector(to_unsigned(rgb_set1.mac,32));
-- End of design block
  end if;
-- End of design block
end process;

-- Sequential process block: executed on clock or sensitivity list events
process (clk) begin
-- Rising edge clock detection: ensures synchronous sequential logic
  if rising_edge(clk) then
    rgb_set1.sum2 <= rgb_set1.sum;
-- End of design block
  end if;
-- End of design block
end process;

square_root_inst: square_root
-- Generic parameters: compile‑time configuration values
generic map(
    data_width       => 32)
-- Port definitions: input/output interface signals
port map(
   clock        => clk,
   rst_n        => rst_n,
   radicand_in  => rgb_set1.sum2,
   root_out     => rgb_set1.rslt);
   
   
-- Sequential process block: executed on clock or sensitivity list events
process (clk, rst_n) begin
-- Rising edge clock detection: ensures synchronous sequential logic
  if rising_edge(clk) then
    rgb_set1.rslt2      <= to_integer(unsigned(rgb_set1.rslt));

-- End of design block
  end if;
-- End of design block
end process;

-- Sequential process block: executed on clock or sensitivity list events
process (clk, rst_n) begin
-- Rising edge clock detection: ensures synchronous sequential logic
  if rising_edge(clk) then
    threshold           <= rgb_set1.rslt2;
-- End of design block
  end if;
-- End of design block
end process;

-- End of design block
end architecture;
