----------------------------------------------------------------------------------
-- Company      : SA611982
-- Author       : Sakinder Ali
-- Create Date  : 04282019 [04-28-2019]
-- Devices      : FPGA-CPLD-ZYNQ-SOC
-- SA611982-MJ  : 3.1
-- SA611982-MN  : 1
-- Description  : [SA611982-3.1-1][03/07/2026]
-- Notes        : RGB K-Means Clustering Package
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rgb_cluster_pkg is

    ------------------------------------------------------------------------------
    -- Streaming pixel channel (AXI-like)
    ------------------------------------------------------------------------------
    type channel is record
        valid : std_logic;                     -- Pixel valid
        sof   : std_logic;                     -- Start of frame
        eol   : std_logic;                     -- End of line
        eof   : std_logic;                     -- End of frame
        xcnt  : integer;                       -- X coordinate
        ycnt  : integer;                       -- Y coordinate
        red   : std_logic_vector(9 downto 0);  -- 10-bit red
        green : std_logic_vector(9 downto 0);  -- 10-bit green
        blue  : std_logic_vector(9 downto 0);  -- 10-bit blue
    end record;

    ------------------------------------------------------------------------------
    -- Internal integer channel (post-shift)
    ------------------------------------------------------------------------------
    type intChannel is record
        red   : natural;
        green : natural;
        blue  : natural;
        valid : std_logic;
    end record;

    ------------------------------------------------------------------------------
    -- Integer RGB record
    ------------------------------------------------------------------------------
    type int_rgb is record
        red : integer;
        green : integer;
        blue : integer;
    end record;

    ------------------------------------------------------------------------------
    -- LUT entry for centroid
    ------------------------------------------------------------------------------
    type k_lut is record
        red : natural;
        green : natural;
        blue : natural;
    end record;

    type rgb_k_lut is array (natural range <>) of k_lut;

    ------------------------------------------------------------------------------
    -- Range record for centroid grouping
    ------------------------------------------------------------------------------
    type k_range is record
        max : natural;
        mid : natural;
        min : natural;
    end record;

    type rgb_k_range is array (natural range <>) of k_range;

    ------------------------------------------------------------------------------
    -- Raw RGB values for centroid output
    ------------------------------------------------------------------------------
    type k_val is record
        red : std_logic_vector(9 downto 0);
        green : std_logic_vector(9 downto 0);
        blue : std_logic_vector(9 downto 0);
    end record;

    type k_val_rgb is array (natural range <>) of k_val;

    ------------------------------------------------------------------------------
    -- Threshold record (for multi-cluster engines)
    ------------------------------------------------------------------------------
    type thr_record is record
        threshold1  : integer; threshold2  : integer; threshold3  : integer;
        threshold4  : integer; threshold5  : integer; threshold6  : integer;
        threshold7  : integer; threshold8  : integer; threshold9  : integer;
        threshold10 : integer; threshold11 : integer; threshold12 : integer;
        threshold13 : integer; threshold14 : integer; threshold15 : integer;
        threshold16 : integer; threshold17 : integer; threshold18 : integer;
        threshold19 : integer; threshold20 : integer; threshold21 : integer;
        threshold22 : integer; threshold23 : integer; threshold24 : integer;
        threshold25 : integer; threshold26 : integer; threshold27 : integer;
        threshold28 : integer; threshold29 : integer; threshold30 : integer;
    end record;

    ------------------------------------------------------------------------------
    -- Pixel processing structure for Euclidean distance pipeline
    ------------------------------------------------------------------------------
    type s_pixel is record
        red_input_stream   : integer;                 -- Stage 0: R input
        green_input_stream : integer;                 -- Stage 0: G input
        blue_input_stream  : integer;                 -- Stage 0: B input

        red_diff           : integer;                 -- Stage 1: |R - kR|
        green_diff         : integer;                 -- Stage 1: |G - kG|
        blue_diff          : integer;                 -- Stage 1: |B - kB|

        red_diff_sqr       : integer;                 -- Stage 2: (R diff)^2
        green_diff_sqr     : integer;                 -- Stage 2: (G diff)^2
        blue_diff_sqr      : integer;                 -- Stage 2: (B diff)^2

        summed_per_rgb_differences_squared_pixel_channels : integer; -- Stage 3 sum

        sum                : std_logic_vector(31 downto 0); -- Stage 3 sum (SLV)
        radicand           : std_logic_vector(31 downto 0); -- Stage 4 input to sqrt
        root_out           : std_logic_vector(15 downto 0); -- Stage 4 sqrt output
        square_root_out    : integer;                        -- Stage 4 integer sqrt
    end record;

    ------------------------------------------------------------------------------
    -- Utility function:
    ------------------------------------------------------------------------------

    function int_min_val(l, m : integer)                            return integer;
    function int_min_val(l, m, r: integer)                          return integer;
    function int_min_val(l, m, r, f: integer)                       return integer;
    function int_min_val(l, m, r, f, e: integer)                    return integer;
    ------------------------------------------------------------------------------
    -- Component declarations
    ------------------------------------------------------------------------------
    component square_root is
        generic ( data_width : integer := 32 );
        port (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            radicand_in : in  std_logic_vector(data_width - 1 downto 0);
            root_out    : out std_logic_vector((data_width/2) - 1 downto 0)
        );
    end component;

    component rgb_cluster_core is
        generic ( data_width : integer );
        port (
            clk                          : in std_logic;
            rst_n                        : in std_logic;
            rgb_streaming_pixels         : in channel; -- Incoming pixel
            k_lut_rgb_max_mid_min_indexs : in int_rgb; -- Centroid (kR,kG,kB)
            euclidean_distance_threshold : out integer
        );
    end component;

end package rgb_cluster_pkg;

----------------------------------------------------------------------------------
-- PACKAGE BODY
----------------------------------------------------------------------------------
package body rgb_cluster_pkg is
    function int_min_val(l, m: integer) return integer is
    begin
       if l <= m then
           return l;
       else
           return m;
       end if;
    end;
    
    function int_min_val(l, m, r: integer) return integer is
    begin
       if l <= r and l <= m then
           return l;
       elsif m <= l and m <= r then
           return m;
       else
           return r;
       end if;
    end;
    
    function int_min_val(l, m, r, f : integer) return integer is
    begin
       if l <= r and l <= m and l <= f then
           return l;
       elsif m <= l and m <= r and m <= f then
           return m;
       elsif r <= l and r <= m and r <= f then
           return r;
       else
           return f;
       end if;
    end;
    
    function int_min_val(l, m, r, f, e : integer) return integer is
    begin
       if l <= r and l <= m and l <= e and l <= f then
           return l;
       elsif m <= l and m <= r and m <= e and m <= f then
           return m;
       elsif r <= l and r <= m and r <= e and r <= f then
           return r;
       elsif f <= l and f <= m and f <= e and f <= r then
           return f;
       else
           return e;
       end if;
    end;
end package body rgb_cluster_pkg;
