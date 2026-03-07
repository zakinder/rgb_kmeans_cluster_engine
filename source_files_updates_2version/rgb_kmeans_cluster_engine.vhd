----------------------------------------------------------------------------------
-- Company      : SA611982
-- Author       : Sakinder Ali
-- Create Date  : 04282019 [04-28-2019]
-- Devices      : FPGA-CPLD-ZYNQ-SOC
-- SA611982-MJ  : 3.1
-- SA611982-MN  : 1
-- Description  : [SA611982-3.1-1][03/07/2026]
-- Notes        : Reformatted architecture, labeled stages/processes, shorter internal names
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rgb_cluster_pkg.all;
entity rgb_kmeans_cluster_engine is
    generic (
        i_data_width : integer := 8
    );
    port (
        clk            : in std_logic;
        rst_n          : in std_logic;
        rgb_streaming_pixels           : in channel;
        centroid_lut_select : in natural;
        centroid_lut_in       : in std_logic_vector(23 downto 0);
        centroid_lut_out      : out std_logic_vector(31 downto 0);
        k_ind_w        : in natural;
        k_ind_r        : in natural;
        pixel_out_rgb           : out channel
    );
end rgb_kmeans_cluster_engine;
architecture rtl of rgb_kmeans_cluster_engine is
    signal sync_eol_d    : std_logic_vector(31 downto 0) := x"00000000";
    signal sync_sof_d    : std_logic_vector(31 downto 0) := x"00000000";
    signal sync_eof_d    : std_logic_vector(31 downto 0) := x"00000000";
    signal sync_vld_d  : std_logic_vector(31 downto 0) := x"00000000";
    signal sel_lut_rgb         : rgb_k_lut(0 to 30);
    signal lut_rgb_d25                : rgb_k_lut(0 to 30);
    constant k_rgb_lut_1_l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (255,240,230), 
    (240,220,210), 
    (240,220,170), 
    (240,210,150),
    (240,210,180),
    (240,200,140),  
    (240,200,160),  
    (240,180,150),  
    (240,150,140), 
    (180,140,160),  
    (180,160,140),  
    (180,170,120),  
    (180,145,100),  
    (180,140, 90),  
    (180,130, 80),
    (150,140,130),  
    (150,120,110),  
    (150,100, 80),  
    (150, 80, 50),  
    (130,120,100),  
    (130,100, 80),  
    (130, 80, 60),  
    (130, 60, 30),
    (120,110,100),  
    (120,100, 90), 
    (120, 80, 70),  
    (120, 60, 30),
    (100, 90, 70),  
    (100, 70, 40),  
    (100, 50, 10)); 
    signal lut2_bank             : rgb_k_range(0 to 30) := (
    (  0,  0,  6),
    ( 90, 90,  0),
    ( 90, 50, 20),
    ( 90, 40, 10),
    ( 90, 40, 10),
    ( 90, 30,  0),
    ( 90, 30,  0),
    ( 90, 20,  0),
    ( 80, 80,  0),
    ( 80, 50, 20),
    ( 80, 40, 10),
    ( 80, 40, 10),
    ( 80, 30,  0),
    ( 80, 30,  0),
    ( 70, 70,  0),
    ( 70, 50, 15),
    ( 70, 30, 15),
    ( 70, 10,  0),
    ( 60, 60,  0),
    ( 60, 30, 20),
    ( 60, 20, 10),
    ( 60, 10,  0),
    ( 40, 40,  0),
    ( 40, 20, 10),
    ( 40, 10,  5),
    ( 40, 10,  0),
    ( 30, 30,  0),
    ( 30, 20, 15),
    ( 30, 15,  0),
    ( 30, 10,  0),
    ( 20, 10,  0));
    signal lut2_wr_bank             : rgb_k_range(0 to 30) := (
    (  0,  0,  6),
    ( 90, 90,  0),
    ( 90, 50, 20),
    ( 90, 40, 10),
    ( 90, 40, 10),
    ( 90, 30,  0),
    ( 90, 30,  0),
    ( 90, 20,  0),
    ( 80, 80,  0),
    ( 80, 50, 20),
    ( 80, 40, 10),
    ( 80, 40, 10),
    ( 80, 30,  0),
    ( 80, 30,  0),
    ( 70, 70,  0),
    ( 70, 50, 15),
    ( 70, 30, 15),
    ( 70, 10,  0),
    ( 60, 60,  0),
    ( 60, 30, 20),
    ( 60, 20, 10),
    ( 60, 10,  0),
    ( 40, 40,  0),
    ( 40, 20, 10),
    ( 40, 10,  5),
    ( 40, 10,  0),
    ( 30, 30,  0),
    ( 30, 20, 15),
    ( 30, 15,  0),
    ( 30, 10,  0),
    ( 20, 10,  0));
    constant k_rgb_lut_22l             : rgb_k_range(0 to 30) := (
    (  0,  0,  6),
    ( 90, 90,  0),
    ( 90, 50, 20),
    ( 90, 40, 10),
    ( 90, 40, 10),
    ( 90, 30,  0),
    ( 90, 30,  0),
    ( 90, 20,  0),
    ( 80, 80,  0),
    ( 80, 50, 20),
    ( 80, 40, 10),
    ( 80, 40, 10),
    ( 80, 30,  0),
    ( 80, 30,  0),
    ( 70, 70,  0),
    ( 70, 50, 15),
    ( 70, 30, 15),
    ( 70, 10,  0),
    ( 60, 60,  0),
    ( 60, 30, 20),
    ( 60, 20, 10),
    ( 60, 10,  0),
    ( 40, 40,  0),
    ( 40, 20, 10),
    ( 40, 10,  5),
    ( 40, 10,  0),
    ( 30, 30,  0),
    ( 30, 20, 15),
    ( 30, 15,  0),
    ( 30, 10,  0),
    ( 20, 10,  0));
    constant k_rgb_lut_0_l             : rgb_k_range(0 to 30) := (
    ( 0,  0,  6),
    (255,255,255),
    (250,250,250),
    (240,240,240),
    (230,230,230),
    (220,220,220),
    (210,210,210),
    (200,200,200),
    (190,190,190),
    (180,180,180),
    (170,170,170),
    (160,160,160),
    (150,150,150),
    (140,140,140),
    (130,130,130),
    (120,120,120),
    (110,110,110),
    (100,100,100),
    ( 90, 90, 90),
    ( 80, 80, 80),
    ( 70, 70, 70),
    ( 60, 60, 60),
    ( 50, 50, 50),
    ( 40, 40, 40),
    ( 30, 30, 30),
    ( 20, 20, 20),
    ( 10, 10, 10),
    (  0,  0,  0),
    (255,255,255),
    (150,150,150),
    (100,100,100));
    signal lut4_bank               : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,100,  0),
    (160,160,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 50, 10),
    (150, 80, 20),
    (140,140,  0),
    (140,100, 40),
    (140, 80, 40),
    (140, 60,  0),
    (120,120,  0),
    (120, 50,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100,100,  0),
    (100, 50,  0),
    (100, 90,  0),
    (100, 25,  0));
    signal lut4_wr_bank               : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,100,  0),
    (160,160,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 50, 10),
    (150, 80, 20),
    (140,140,  0),
    (140,100, 40),
    (140, 80, 40),
    (140, 60,  0),
    (120,120,  0),
    (120, 50,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100,100,  0),
    (100, 50,  0),
    (100, 90,  0),
    (100, 25,  0));
    signal lut3_wr_bank               : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,100,  0),
    (160,160,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 50, 10),
    (150, 80, 20),
    (140,140,  0),
    (140,100, 40),
    (140, 80, 40),
    (140, 60,  0),
    (120,120,  0),
    (120, 50,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100,100,  0),
    (100, 50,  0),
    (100, 90,  0),
    (100, 25,  0));
    signal lut6_wr_bank               : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,100,  0),
    (160,160,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 50, 10),
    (150, 80, 20),
    (140,140,  0),
    (140,100, 40),
    (140, 80, 40),
    (140, 60,  0),
    (120,120,  0),
    (120, 50,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100,100,  0),
    (100, 50,  0),
    (100, 90,  0),
    (100, 25,  0));
    signal lut3_bank               : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,100,  0),
    (160,160,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 50, 10),
    (150, 80, 20),
    (140,140,  0),
    (140,100, 40),
    (140, 80, 40),
    (140, 60,  0),
    (120,120,  0),
    (120, 50,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100,100,  0),
    (100, 50,  0),
    (100, 90,  0),
    (100, 25,  0));
    signal lut6_bank               : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,100,  0),
    (160,160,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 50, 10),
    (150, 80, 20),
    (140,140,  0),
    (140,100, 40),
    (140, 80, 40),
    (140, 60,  0),
    (120,120,  0),
    (120, 50,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100,100,  0),
    (100, 50,  0),
    (100, 90,  0),
    (100, 25,  0));
    constant k_rgb_lut_41l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (255,240,150),
    (240,230,140),
    (220,200,120),
    (255,230, 75),
    (240,220, 75),
    (220,120, 75),
    (200,180,158),
    (180,160,128),
    (160,140,118),
    (140,120, 98),
    (120,100, 88),
    (100, 80, 78),
    (255,210,128),
    (240,190,120),
    (220,170,110),
    (200,150,100),
    (180,130, 80),
    (160,110, 60),
    (140, 90, 40),
    (120, 70, 20),
    (100, 50,  0),
    (255,150, 75),
    (240,100, 75),
    (220, 80, 75),
    (200,140,100),
    (180,120, 80),
    (160,100, 60),
    (140, 80, 40),
    (120, 60, 20),
    (100, 40,  0));
    constant k_rgb_lut_42l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (255,251,242),
    (255,241,232),
    (255,231,202),
    (255,221,182),
    (255,211,122),
    (255,201,142),
    (255,191,132),
    (255,181,122),
    (255,171,112),
    (230,191,172),
    (230,181,162),
    (230, 81, 62),
    (220,181,142),
    (220,171,132),
    (200, 51, 12),
    (200,181, 92),
    (180,161,132),
    (180,151,122),
    (170,151,112),
    (170,141,102),
    (150, 31, 22),
    (150, 71, 42),
    (130, 91, 62),
    (130, 81, 52),
    (120, 81, 42),
    (120, 71, 32),
    (100, 51, 22),
    (100, 51, 22),
    (100, 51, 22),
    ( 40, 21, 12));
    constant k_rgb_lut_43l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (240,220, 75),
    (240,220, 75),
    (240,220, 75),
    (200,180,158),
    (180,160,128),
    (180,160,128),
    (180,160,128),
    (120,100, 88),
    (120,100, 88),
    (240,190,120),
    (240,190,120),
    (240,190,120),
    (200,150,100),
    (200,150,100),
    (160,110, 60),
    (160,110, 60),
    (120, 70, 20),
    (120, 70, 20),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (207,150, 95),
    (161,110, 75),
    (127, 68, 34),
    (140, 80, 40),
    (120, 60, 20),
    (100, 40,  0));
    constant k_rgb_lut_44l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (180,160,128),
    (180,160,128),
    (180,160,128),
    (180,160,128),
    (180,160,128),
    (120,100, 88),
    (120,100, 88),
    (120,100, 88),
    (120,100, 88),
    (200,150,100),
    (200,150,100),
    (200,150,100),
    (200,150,100),
    (120, 70, 20),
    (120, 70, 20),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (207,150, 95),
    (161,110, 75),
    (127, 68, 34),
    (140, 80, 40),
    (120, 60, 20),
    (100, 40,  0));
    constant k_rgb_lut_45l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (255,240,150),
    (220,200,120),
    (220,200,120),
    (220,200,120),
    (220,200,120),
    (220,120, 75),
    (160,140,118),
    (160,140,118),
    (160,140,118),
    (100, 80, 78),
    (100, 80, 78),
    (100, 80, 78),
    (255,240,230),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (207,150, 95),
    (161,110, 75),
    (127, 68, 34),
    (120, 70, 20),
    (100, 50,  0),
    (255,150, 75),
    (240,100, 75),
    (220, 80, 75),
    (200,140,100),
    (180,120, 80),
    (160,100, 60),
    (140, 80, 40),
    (120, 60, 20),
    (100, 40,  0));
    constant k_rgb_lut_46l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (255,240,  0),
    (240,230,  0),
    (220,200,  0),
    (255,230,  0),
    (255,240,  0),
    (246,216,  0),
    (236,192,  0),
    (220,120,  0),
    (207,150,  0),
    (165,100,  0),
    (127, 68,  0),
    (209,168,  0),
    (200,180,  0),
    (180,160,  0),
    (160,140,  0),
    (140,120,  0),
    (120,100,  0),
    (100, 80,  0),
    (240,190,  0),
    (200,150,  0),
    (180,130,  0),
    (160,110,  0),
    (140, 90,  0),
    (240,100,  0),
    (220, 80,  0),
    (180,120,  0),
    (160,100,  0),
    (140, 80,  0),
    (120, 60,  0),
    (100, 40,  0));
    constant k_rgb_lut_47l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (255,251,242),
    (255,241,232),
    (255,231,202),
    (255,221,182),
    (209,168,138),
    (255,201,142),
    (255,191,132),
    (255,181,122),
    (255,240,230),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (220,120, 75),
    (207,150, 95),
    (200,150,100),
    (127, 68, 34),
    (209,168,138),
    (180,151,122),
    (170,151,112),
    (170,141,102),
    (200,150,100),
    (150, 71, 42),
    (130, 91, 62),
    (130, 81, 52),
    (120, 81, 42),
    (120, 71, 32),
    (100, 51, 22),
    (100, 51, 22),
    (100, 51, 22),
    ( 40, 21, 12));
    constant k_rgb_lut_48l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,230,140),
    (240,220, 75),
    (240,220, 75),
    (255,240,230),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (220,120, 75),
    (207,150, 95),
    (165,100, 80),
    (127, 68, 34),
    (209,168,138),
    (240,190,120),
    (240,190,120),
    (240,190,120),
    (200,150,100),
    (200,150,100),
    (160,110, 60),
    (160,110, 60),
    (120, 70, 20),
    (120, 70, 20),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (207,150, 95),
    (161,110, 75),
    (127, 68, 34),
    (140, 80, 40),
    (120, 60, 20),
    (100, 40,  0));
    constant k_rgb_lut_49l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (240,230,140),
    (180,160,128),
    (180,160,128),
    (180,160,128),
    (180,160,128),
    (180,160,128),
    (120,100, 88),
    (120,100, 88),
    (120,100, 88),
    (120,100, 88),
    (200,150,100),
    (200,150,100),
    (200,150,100),
    (200,150,100),
    (120, 70, 20),
    (120, 70, 20),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (207,150, 95),
    (161,110, 75),
    (127, 68, 34),
    (140, 80, 40),
    (120, 60, 20),
    (100, 40,  0));
    constant k_rgb_lut_50l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (255,240,150),
    (220,200,120),
    (220,200,120),
    (220,200,120),
    (209,168,138),
    (220,120, 75),
    (165,100, 80),
    (165,100, 80),
    (165,100, 80),
    (100, 80, 78),
    (100, 80, 78),
    (100, 80, 78),
    (255,240,230),
    (255,240,230),
    (246,216,192),
    (236,192,145),
    (207,150, 95),
    (161,110, 75),
    (127, 68, 34),
    (120, 70, 20),
    (100, 50,  0),
    (255,150, 75),
    (240,100, 75),
    (220, 80, 75),
    (200,140,100),
    (180,120, 80),
    (160,100, 60),
    (140, 80, 40),
    (120, 60, 20),
    (100, 40,  0));
    constant k_rgb_lut_51l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (150,140,130),
    (148,137,120),
    (146,134,110),
    (144,131,100),
    (142,128, 90),
    (140,125, 80),
    (138,122, 70),
    (136,119, 60),
    (134,116, 50),
    (132,113, 40),
    (130,110, 30),
    (128,107, 20),
    (126,104, 10),
    (124,101, 0),
    (122, 98, 10),
    (120, 95, 20),
    (118, 92, 30),
    (116, 89, 40),
    (114, 86, 50),
    (112, 83, 60),
    (110, 80, 70),
    (108, 77, 10),
    (106, 74, 20),
    (104, 71, 30),
    (102, 68, 40),
    (100, 65, 50),
    (100, 62, 20),
    (100, 59, 30),
    (100, 56, 40),
    (100, 53, 0));
    constant k_rgb_lut_52l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,150),
    (200,160,120),
    (170,110, 60),
    (144,131,100),
    (142,128, 90),
    (140,125, 80),
    (138,122, 70),
    (136,119, 60),
    (134,116, 50),
    (132,113, 40),
    (130,110, 30),
    (128,107, 20),
    (126,104, 10),
    (124,101, 0),
    (122, 98, 10),
    (120, 95, 20),
    (118, 92, 30),
    (116, 89, 40),
    (114, 86, 50),
    (112, 83, 60),
    (110, 80, 70),
    (108, 77, 10),
    (106, 74, 20),
    (104, 71, 30),
    (102, 68, 40),
    (100, 65, 50),
    (100, 62, 20),
    (100, 59, 30),
    (100, 56, 40),
    (100, 53, 0));
    constant k_rgb_lut_53l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,150),
    (200,160,120),
    (170,110, 60),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (110, 80, 70),
    (108, 77, 10),
    (106, 74, 20),
    (104, 71, 30),
    (102, 68, 40),
    (100, 65, 50),
    (100, 62, 20),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40));
    constant k_rgb_lut_54l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,150),
    (200,160,120),
    (170,110, 60),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40));
    constant k_rgb_lut_55l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,150),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (144,131,100),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (128,107, 20),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (112, 83, 60),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40),
    (100, 56, 40));
    constant k_rgb_lut_56l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,200,  0),
    (160,160,  0),
    (140,140,  0),
    (120,120,  0),
    (100,100,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 80, 20),
    (160, 70, 10),
    (140,100, 40),
    (140,100, 30),
    (140,100, 20),
    (140,100, 10),
    (120, 80,  0),
    (120, 70,  0),
    (100, 90,  0),
    (100, 80,  0),
    (100, 70,  0));
    constant k_rgb_lut_57l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,240,  0),
    (240,200,  0),
    (240,180,  0),
    (230,230,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,200,  0),
    (160,160,  0),
    (140,140,  0),
    (120,120,  0),
    (100,100,  0),
    (160,120,  0),
    (160,110,  0),
    (160,100,  0),
    (160, 90,  0),
    (160, 80,  0),
    (160, 70,  0),
    (140,100,  0),
    (140,100,  0),
    (140,100,  0),
    (140,100,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100, 90,  0),
    (100, 80,  0),
    (100, 70,  0));
    constant k_rgb_lut_58l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,240,  0),
    (240,200,  0),
    (240,180,  0),
    (230,230,  0),
    (230,160,  0),
    (230,180,  0),
    (255,240,230),-- required brown colors
    (246,216,192),-- required brown colors
    (236,192,145),-- required brown colors
    (220,120, 75),-- required brown colors
    (207,150, 95),-- required brown colors
    (165,100, 80),-- required brown colors
    (127, 68, 34),-- required brown colors
    (209,168,138),-- required brown colors
    (200,150,100),-- required brown colors
    (200,100,100),
    (200,200,  0),
    (160,160,  0),
    (120,120,  0),
    (100,100,  0),
    (160,120,  0),
    (160,110,  0),
    (160,100,  0),
    (160, 90,  0),
    (160, 80,  0),
    (140,100,  0),
    (100, 50, 50),
    (120, 80,  0),
    (100, 90,  0),
    (100, 80,  0));
    constant k_rgb_lut_59l             : rgb_k_range(0 to 30) := (
    (  0,  0,  0),
    (240,200,  0),
    (240,180,  0),
    (230,180,  0),
    (230,170,  0),
    (230,160,  0),
    (230,180,  0),
    (200,160,  0),
    (200,150,  0),
    (200,140,  0),
    (200,130,  0),
    (200,100,  0),
    (160,160,  0),
    (160,120, 70),
    (160,110, 50),
    (160,100, 40),
    (160, 90, 30),
    (160, 50, 10),
    (150, 80, 20),
    (140,140,  0),
    (140,100, 40),
    (140, 80, 40),
    (140, 60,  0),
    (120,120,  0),
    (120, 50,  0),
    (120, 80,  0),
    (120, 70,  0),
    (100,100,  0),
    (100, 50,  0),
    (100, 90,  0),
    (100, 25,  0));
    signal lut_d01                : rgb_k_lut(0 to 30);
    signal lut_d02                : rgb_k_lut(0 to 30);
    signal lut_d03                : rgb_k_lut(0 to 30);
    signal lut_d04                : rgb_k_lut(0 to 30);
    signal lut_d05                : rgb_k_lut(0 to 30);
    signal lut_d06                : rgb_k_lut(0 to 30);
    signal lut_d07                : rgb_k_lut(0 to 30);
    signal lut_d08                : rgb_k_lut(0 to 30);
    signal lut_d09                : rgb_k_lut(0 to 30);
    signal lut_d10                : rgb_k_lut(0 to 30);
    signal lut_d11                : rgb_k_lut(0 to 30);
    signal lut_d12                : rgb_k_lut(0 to 30);
    signal lut_d13                : rgb_k_lut(0 to 30);
    signal lut_d14                : rgb_k_lut(0 to 30);
    signal lut_d15                : rgb_k_lut(0 to 30);
    signal lut_d16                : rgb_k_lut(0 to 30);
    signal lut_d17                : rgb_k_lut(0 to 30);
    signal lut_d18                : rgb_k_lut(0 to 30);
    signal lut_d19                : rgb_k_lut(0 to 30);
    signal lut_d20                : rgb_k_lut(0 to 30);
    signal lut_d21                : rgb_k_lut(0 to 30);
    signal lut_d22                : rgb_k_lut(0 to 30);
    signal lut_d23                : rgb_k_lut(0 to 30);
    signal lut_d24                : rgb_k_lut(0 to 30);
    signal lut_d25                : rgb_k_lut(0 to 30);

    signal lut_pix_d25                   : k_val_rgb(0 to 30);
    signal dist_thr_s0                  : thr_record;
    signal dist_thr_s1                  : thr_record;
    signal dist_thr_s2                  : thr_record;
    signal dist_thr_s3                  : thr_record;
    signal dist_thr_out                  : thr_record;
    signal dist_thr             : integer;
    signal dist_grp1_min       : integer;
    signal dist_grp2_min       : integer;
    signal dist_grp3_min       : integer;
    signal dist_grp4_min       : integer;
    signal dist_grp5_min       : integer;
    signal dist_grp6_min       : integer;
    signal dist_pair1_min        : integer;
    signal dist_pair2_min        : integer;
    signal dist_min_pre         : integer;
    signal dist_min         : integer;
    
    signal pix_min              : integer;
    signal pix_max              : integer;
    signal pix_s0          : channel;
    signal pix_s1          : channel;
    signal pix_s2          : channel;
    signal pix_core_in          : channel;
    signal pix_rgb_u8             : intChannel;
    signal pix_rgb_ord             : intChannel;
    signal ord_max               : integer;
    signal ord_mid               : integer;
    signal ord_min               : integer;
    signal pix_red_u8               : std_logic_vector(7 downto 0);
    signal pix_gre_u8               : std_logic_vector(7 downto 0);
    signal pix_blu_u8               : std_logic_vector(7 downto 0);
    constant K_VALUE             : integer := 11;
    attribute keep : string;
    attribute keep of ord_max : signal is "true";
    attribute keep of ord_mid : signal is "true";
    attribute keep of ord_min : signal is "true";
begin

    ------------------------------------------------------------------------------
    -- Stage 0: stream-control delay lines
    ------------------------------------------------------------------------------
    p_sync_valid : process (clk) begin
    if rising_edge(clk) then
        sync_vld_d(0)  <= rgb_streaming_pixels.valid; -- Insert VALID into delay line
        for i in 0 to 30 loop
          sync_vld_d(i+1)  <= sync_vld_d(i);
        end loop;
    end if;
end process;
    p_sync_eol : process (clk) begin
    if rising_edge(clk) then
        sync_eol_d(0)  <= rgb_streaming_pixels.eol;   -- Insert EOL into delay line
        for i in 0 to 30 loop
          sync_eol_d(i+1)  <= sync_eol_d(i);
        end loop;
    end if;
end process;
    p_sync_sof : process (clk) begin
    if rising_edge(clk) then
        sync_sof_d(0)  <= rgb_streaming_pixels.sof;   -- Insert SOF into delay line
        for i in 0 to 30 loop
          sync_sof_d(i+1)  <= sync_sof_d(i);
        end loop;
    end if;
end process;
    p_sync_eof : process (clk) begin
    if rising_edge(clk) then
        sync_eof_d(0)  <= rgb_streaming_pixels.eof;   -- Insert EOF into delay line
        for i in 0 to 30 loop
          sync_eof_d(i+1)  <= sync_eof_d(i);
        end loop;
    end if;
end process;
        ------------------------------------------------------------------------------
    -- Stage 1: pixel pipeline and RGB ordering
    ------------------------------------------------------------------------------
    p_capture_pix : process (clk) begin
    if rising_edge(clk) then
        pix_s0.red    <= rgb_streaming_pixels.red;
        pix_s0.green  <= rgb_streaming_pixels.green;
        pix_s0.blue   <= rgb_streaming_pixels.blue;
        pix_s0.valid  <= rgb_streaming_pixels.valid;
    end if;
end process;
    p_pipe_pix : process (clk) begin
    if rising_edge(clk) then
        pix_s1    <= pix_s0;
        pix_s2    <= pix_s1;
        pix_core_in    <= pix_s2;
    end if;
end process;
    p_rgb_to_u8 : process (clk) begin
    if rising_edge(clk) then
            pix_rgb_u8.red    <= to_integer(unsigned(pix_s0.red(9 downto 2)));
            pix_rgb_u8.green  <= to_integer(unsigned(pix_s0.green(9 downto 2)));
            pix_rgb_u8.blue   <= to_integer(unsigned(pix_s0.blue(9 downto 2)));
    end if;
end process;
    p_find_pix_max : process (clk) begin
    if rising_edge(clk) then
        if ((pix_rgb_u8.red >= pix_rgb_u8.green) and (pix_rgb_u8.red >= pix_rgb_u8.blue)) then
            pix_max <= pix_rgb_u8.red;
        elsif ((pix_rgb_u8.green >= pix_rgb_u8.red) and (pix_rgb_u8.green >= pix_rgb_u8.blue)) then
            pix_max <= pix_rgb_u8.green;
        else
            pix_max <= pix_rgb_u8.blue;
        end if;
    end if;
end process;
    p_find_pix_min : process (clk) begin
    if rising_edge(clk) then
        if ((pix_rgb_u8.red <= pix_rgb_u8.green) and (pix_rgb_u8.red <= pix_rgb_u8.blue)) then
            pix_min <= pix_rgb_u8.red;
        elsif((pix_rgb_u8.green <= pix_rgb_u8.red) and (pix_rgb_u8.green <= pix_rgb_u8.blue)) then
            pix_min <= pix_rgb_u8.green;
        else
            pix_min <= pix_rgb_u8.blue;
        end if;
    end if;
end process;
    p_find_pix_mid : process (clk) begin
    if rising_edge(clk) then 
        if (pix_rgb_ord.red = pix_max) and (pix_rgb_ord.green = pix_min) then
            ord_max <= pix_rgb_ord.red;
            ord_mid <= pix_rgb_ord.blue;
            ord_min <= pix_rgb_ord.green;
        elsif(pix_rgb_ord.red = pix_max) and (pix_rgb_ord.blue = pix_min)then
            ord_max <= pix_rgb_ord.red;
            ord_mid <= pix_rgb_ord.green;
            ord_min <= pix_rgb_ord.blue;
        elsif(pix_rgb_ord.green = pix_max) and (pix_rgb_ord.blue = pix_min)then
            ord_max <= pix_rgb_ord.green;
            ord_mid <= pix_rgb_ord.red;
            ord_min <= pix_rgb_ord.blue;
        elsif(pix_rgb_ord.green = pix_max) and (pix_rgb_ord.red = pix_min)then
            ord_max <= pix_rgb_ord.green;
            ord_mid <= pix_rgb_ord.blue;
            ord_min <= pix_rgb_ord.red;
        elsif(pix_rgb_ord.blue = pix_max) and (pix_rgb_ord.red = pix_min)then
            ord_max <= pix_rgb_ord.blue;
            ord_mid <= pix_rgb_ord.green;
            ord_min <= pix_rgb_ord.red;
        elsif(pix_rgb_ord.blue = pix_max) and (pix_rgb_ord.green = pix_min)then
            ord_max <= pix_rgb_ord.blue;
            ord_mid <= pix_rgb_ord.red;
            ord_min <= pix_rgb_ord.green;
        end if;
    end if;
end process;
    p_order_rgb_dly : process (clk) begin
    if rising_edge(clk) then
      pix_rgb_ord        <= pix_rgb_u8;
    end if;
end process;
-- best select is 18/17/16
        ------------------------------------------------------------------------------
    -- Stage 2: centroid LUT write/read management
    ------------------------------------------------------------------------------
    p_wr_lut_bank4 : process (clk) begin
    if rising_edge(clk) then
        if (k_ind_w <= 30)then
            lut4_wr_bank(k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); lut4_wr_bank(k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   lut4_wr_bank(k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
    p_wr_lut_bank2 : process (clk) begin
    if rising_edge(clk) then
        if (k_ind_w >= 31 and k_ind_w <= 60) then
            lut2_wr_bank(61-k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); lut2_wr_bank(61-k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   lut2_wr_bank(61-k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
    p_wr_lut_bank3 : process (clk) begin
    if rising_edge(clk) then
        if (k_ind_w >= 61 and k_ind_w <= 90) then
            lut3_wr_bank(91-k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); lut3_wr_bank(91-k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   lut3_wr_bank(91-k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
    p_wr_lut_bank6 : process (clk) begin
    if rising_edge(clk) then
        if (k_ind_w >= 91 and k_ind_w <= 120) then
            lut6_wr_bank(121-k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); lut6_wr_bank(121-k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   lut6_wr_bank(121-k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
    p_lut_readback : process (clk) begin
    if rising_edge(clk) then
        if (k_ind_r <= 30)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(lut4_bank(k_ind_r).max, 8)) & std_logic_vector(to_unsigned(lut4_bank(k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(lut4_bank(k_ind_r).min, 8));
        elsif(k_ind_w >= 31 and k_ind_w <= 60)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(lut2_bank(61-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(lut2_bank(61-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(lut2_bank(61-k_ind_r).min, 8));
        elsif(k_ind_w >= 61 and k_ind_w <= 90)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(lut3_bank(91-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(lut3_bank(91-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(lut3_bank(91-k_ind_r).min, 8));
        elsif(k_ind_w >= 91 and k_ind_w <= 120)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(lut6_bank(121-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(lut6_bank(121-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(lut6_bank(121-k_ind_r).min, 8));
        else
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(lut3_bank(91-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(lut3_bank(91-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(lut3_bank(91-k_ind_r).min, 8));
        end if;
    end if;
end process;
    p_lut_bank_select : process (clk) begin
    if rising_edge(clk) then
        if (k_ind_w <= 90)then
            lut4_bank <= lut4_wr_bank;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= lut2_wr_bank;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 201)then
            lut4_bank <= k_rgb_lut_42l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 202)then
            lut4_bank <= k_rgb_lut_43l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 203)then
            lut4_bank <= k_rgb_lut_41l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 204)then
            lut4_bank <= k_rgb_lut_42l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 205)then
            lut4_bank <= k_rgb_lut_43l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 206)then
            lut4_bank <= k_rgb_lut_44l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 207)then
            lut4_bank <= k_rgb_lut_45l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 208)then
            lut4_bank <= k_rgb_lut_46l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w = 209)then
            lut4_bank <= k_rgb_lut_47l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =210)then
            lut4_bank <= k_rgb_lut_48l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =211)then
            lut4_bank <= k_rgb_lut_49l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =212)then
            lut4_bank <= k_rgb_lut_50l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =213)then
            lut4_bank <= k_rgb_lut_51l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =214)then
            lut4_bank <= k_rgb_lut_52l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =215)then
            lut4_bank <= k_rgb_lut_53l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =216)then
            lut4_bank <= k_rgb_lut_54l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =217)then
            lut4_bank <= k_rgb_lut_55l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =218)then
            lut4_bank <= k_rgb_lut_56l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =219)then
            lut4_bank <= k_rgb_lut_57l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =220)then
            lut4_bank <= k_rgb_lut_58l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        elsif(k_ind_w =221)then
            lut4_bank <= k_rgb_lut_59l;
            lut3_bank <= lut3_wr_bank;
            lut2_bank <= k_rgb_lut_22l;
            lut6_bank <= lut6_wr_bank;
        end if;
    end if;
end process;
-- best select is 0
        ------------------------------------------------------------------------------
    -- Stage 3: active centroid-LUT selection
    ------------------------------------------------------------------------------
    p_select_active_lut : process (clk) begin
    if rising_edge(clk) then
        if (centroid_lut_select   = 0)then
            ---------------------------------------------------------------------------------------------------------
            if ((abs(pix_rgb_ord.red - pix_rgb_ord.green) <= 6) and (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6)) or (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6 and (abs(pix_rgb_ord.red - pix_rgb_ord.green) <= 6)) or (abs(pix_rgb_ord.green - pix_rgb_ord.blue) <= 6  and (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6))then
              for i in 0 to 30 loop
                sel_lut_rgb(i).red <=   k_rgb_lut_0_l(i).max;   sel_lut_rgb(i).gre <=  k_rgb_lut_0_l(i).min;   sel_lut_rgb(i).blu <=  k_rgb_lut_0_l(i).mid;
              end loop;
            elsif (pix_rgb_ord.red = pix_max) then
                if (pix_max - pix_min >= 100) then
                    if (pix_rgb_ord.green = pix_min) then
                      for i in 0 to 30 loop
                        sel_lut_rgb(i).red <=   k_rgb_lut_1_l(i).max;   sel_lut_rgb(i).gre <=  k_rgb_lut_1_l(i).min;   sel_lut_rgb(i).blu <=  k_rgb_lut_1_l(i).mid;
                      end loop;
                    else
                      for i in 0 to 30 loop
                        sel_lut_rgb(i).red <=   k_rgb_lut_1_l(i).max;   sel_lut_rgb(i).gre <=  k_rgb_lut_1_l(i).mid;   sel_lut_rgb(i).blu <=  k_rgb_lut_1_l(i).min;
                      end loop;
                    end if;
                elsif (pix_rgb_ord.red >= 100) then
                    if (pix_rgb_ord.green = pix_min) then
                      for i in 0 to 30 loop
                        sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                      end loop;
                    else
                      for i in 0 to 30 loop
                        sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                      end loop;
                    end if;
                else
                    if (pix_rgb_ord.green = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    end if;                                                        
                end if;
            elsif (pix_rgb_ord.green = pix_max) then
                if (pix_max - pix_min >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   k_rgb_lut_1_l(i).min;   sel_lut_rgb(i).gre <=  k_rgb_lut_1_l(i).max;   sel_lut_rgb(i).blu <=  k_rgb_lut_1_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   k_rgb_lut_1_l(i).mid;   sel_lut_rgb(i).gre <=  k_rgb_lut_1_l(i).max;   sel_lut_rgb(i).blu <=  k_rgb_lut_1_l(i).min;
                          end loop;
                    end if;
                elsif(pix_rgb_ord.green >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                          end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    end if;                                                        
                end if;  
            else
                if (pix_max - pix_min >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   k_rgb_lut_1_l(i).min;   sel_lut_rgb(i).gre <=  k_rgb_lut_1_l(i).mid;   sel_lut_rgb(i).blu <=  k_rgb_lut_1_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   k_rgb_lut_1_l(i).mid;   sel_lut_rgb(i).gre <=  k_rgb_lut_1_l(i).min;   sel_lut_rgb(i).blu <=  k_rgb_lut_1_l(i).max;
                          end loop;
                    end if;
                elsif(pix_rgb_ord.blue >= 100) then
                        if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                          end loop;
                        else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                          end loop;
                        end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 1) then
            ---------------------------------------------------------------------------------------------------------
            if ((abs(pix_rgb_ord.red - pix_rgb_ord.green) <= 6) and (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6)) or (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6 and (abs(pix_rgb_ord.red - pix_rgb_ord.green) <= 6)) or (abs(pix_rgb_ord.green - pix_rgb_ord.blue) <= 6  and (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6))then
                for i in 0 to 30 loop
                    sel_lut_rgb(i).red <=   k_rgb_lut_0_l(i).max;   sel_lut_rgb(i).gre <=  k_rgb_lut_0_l(i).min;   sel_lut_rgb(i).blu <=  k_rgb_lut_0_l(i).mid;
                end loop;
            -- RED MAX
            elsif (pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 100) then
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                          end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 2) then
            ---------------------------------------------------------------------------------------------------------
            if (pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 100) then
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                          end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 3) then
            ---------------------------------------------------------------------------------------------------------
            if (pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 100) then
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                          end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 4) then
            ---------------------------------------------------------------------------------------------------------
            if (pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 100) then
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                          end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 100) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).mid;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    end if;
                else
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).mid;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 5) then
            ---------------------------------------------------------------------------------------------------------
            if (pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 210) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut6_bank(i).max;   sel_lut_rgb(i).gre <=  lut6_bank(i).min;   sel_lut_rgb(i).blu <=  lut6_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut6_bank(i).max;   sel_lut_rgb(i).gre <=  lut6_bank(i).min;   sel_lut_rgb(i).blu <=  lut6_bank(i).mid;
                        end loop;
                    end if;
                elsif(pix_rgb_ord.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).min;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).min;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 210) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut6_bank(i).min;   sel_lut_rgb(i).gre <=  lut6_bank(i).max;   sel_lut_rgb(i).blu <=  lut6_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut6_bank(i).min;   sel_lut_rgb(i).gre <=  lut6_bank(i).max;   sel_lut_rgb(i).blu <=  lut6_bank(i).mid;
                          end loop;
                    end if;
                elsif(pix_rgb_ord.green >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 210) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut6_bank(i).min;   sel_lut_rgb(i).gre <=  lut6_bank(i).mid;   sel_lut_rgb(i).blu <=  lut6_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut6_bank(i).min;   sel_lut_rgb(i).gre <=  lut6_bank(i).mid;   sel_lut_rgb(i).blu <=  lut6_bank(i).max;
                        end loop;
                    end if;
                elsif(pix_rgb_ord.blue >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 6) then
            ---------------------------------------------------------------------------------------------------------
            if (pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).min;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).min;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            ---------------------------------------------------------------------------------------------------------
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                        end loop;
                    else
                        if ((abs(ord_max - ord_mid) <= 20) or (abs(ord_max - ord_min) <= 20))then
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    else
                        if ((abs(ord_max - ord_mid) <= 40) or (abs(ord_max - ord_min) <= 40))then
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                        if ((abs(ord_max - ord_mid) <= 8) or (abs(ord_max - ord_min) <= 8))then
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  abs(lut2_bank(i).mid - 30);   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                            end loop;
                        end if;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 7) then
            ---------------------------------------------------------------------------------------------------------
            -- RED MAX
            if (pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).min;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            ---------------------------------------------------------------------------------------------------------
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            ---------------------------------------------------------------------------------------------------------
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                        end loop;
                    else
                        if ((abs(ord_max - ord_mid) <= 20) or (abs(ord_max - ord_min) <= 20))then
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    else
                        if ((abs(ord_max - ord_mid) <= 40) or (abs(ord_max - ord_min) <= 40))then
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                        if ((abs(ord_max - ord_mid) <= 8) or (abs(ord_max - ord_min) <= 8))then
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  abs(lut2_bank(i).mid - 30);   sel_lut_rgb(i).blu <=  lut2_bank(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                            end loop;
                        end if;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 9) then
            ---------------------------------------------------------------------------------------------------------
            if ((abs(pix_rgb_ord.red - pix_rgb_ord.green) <= 6) and (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6)) or (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6 and (abs(pix_rgb_ord.red - pix_rgb_ord.green) <= 6)) or (abs(pix_rgb_ord.green - pix_rgb_ord.blue) <= 6  and (abs(pix_rgb_ord.red - pix_rgb_ord.blue) <= 6))then
              for i in 0 to 30 loop
                sel_lut_rgb(i).red <=   k_rgb_lut_0_l(i).max;   sel_lut_rgb(i).gre <=  k_rgb_lut_0_l(i).min;   sel_lut_rgb(i).blu <=  k_rgb_lut_0_l(i).mid;
              end loop;
            ---------------------------------------------------------------------------------------------------------
            elsif(pix_rgb_ord.red = pix_max) then
                if (pix_rgb_ord.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).min;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).max;   sel_lut_rgb(i).gre <=  lut3_bank(i).min;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).max;   sel_lut_rgb(i).gre <=  lut4_bank(i).min;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.green = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).max;   sel_lut_rgb(i).gre <=  lut2_bank(i).min;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            -- GREEN MAX
            elsif (pix_rgb_ord.green = pix_max) then
                if(pix_rgb_ord.green >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).max;   sel_lut_rgb(i).blu <=  lut3_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).max;   sel_lut_rgb(i).blu <=  lut4_bank(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).max;   sel_lut_rgb(i).blu <=  lut2_bank(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(pix_rgb_ord.blue >= 170) then
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut3_bank(i).min;   sel_lut_rgb(i).gre <=  lut3_bank(i).mid;   sel_lut_rgb(i).blu <=  lut3_bank(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(pix_rgb_ord.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut4_bank(i).min;   sel_lut_rgb(i).gre <=  lut4_bank(i).mid;   sel_lut_rgb(i).blu <=  lut4_bank(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (pix_rgb_ord.red = pix_min) then
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            sel_lut_rgb(i).red <=   lut2_bank(i).min;   sel_lut_rgb(i).gre <=  lut2_bank(i).mid;   sel_lut_rgb(i).blu <=  lut2_bank(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        end if;
    end if;
end process;
        ------------------------------------------------------------------------------
    -- Stage 5: selected centroid RGB pipeline for output reconstruction
    ------------------------------------------------------------------------------
    p_pipe_sel_lut : process (clk) begin
    if rising_edge(clk) then
      lut_d01      <= sel_lut_rgb;
      lut_d02      <= lut_d01;
      lut_d03      <= lut_d02;
      lut_d04      <= lut_d03;
      lut_d05      <= lut_d04;
      lut_d06      <= lut_d05;
      lut_d07      <= lut_d06;
      lut_d08      <= lut_d07;
      lut_d09      <= lut_d08;
      lut_d10      <= lut_d09;
      lut_d11      <= lut_d10;
      lut_d12      <= lut_d11;
      lut_d13      <= lut_d12;
      lut_d14      <= lut_d13;
      lut_d15      <= lut_d14;
      lut_d16      <= lut_d15;
      lut_d17      <= lut_d16;
      lut_d18      <= lut_d17;
      lut_d19      <= lut_d18;
      lut_d20      <= lut_d19;
      lut_d21      <= lut_d20;
      lut_d22      <= lut_d21;
      lut_d23      <= lut_d22;
      lut_d24      <= lut_d23;
      lut_d25      <= lut_d24;
      lut_rgb_d25  <= lut_d25;
    end if;
end process;
    p_expand_lut_to_10b : process (clk) begin
    if rising_edge(clk) then
        lut_pix_d25(1).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(1).red, 8)) & "00";
        lut_pix_d25(1).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(1).gre, 8)) & "00";
        lut_pix_d25(1).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(1).blu, 8)) & "00";
        lut_pix_d25(2).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(2).red, 8)) & "00";
        lut_pix_d25(2).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(2).gre, 8)) & "00";
        lut_pix_d25(2).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(2).blu, 8)) & "00";
        lut_pix_d25(3).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(3).red, 8)) & "00";
        lut_pix_d25(3).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(3).gre, 8)) & "00";
        lut_pix_d25(3).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(3).blu, 8)) & "00";
        lut_pix_d25(4).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(4).red, 8)) & "00";
        lut_pix_d25(4).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(4).gre, 8)) & "00";
        lut_pix_d25(4).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(4).blu, 8)) & "00";
        lut_pix_d25(5).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(5).red, 8)) & "00";
        lut_pix_d25(5).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(5).gre, 8)) & "00";
        lut_pix_d25(5).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(5).blu, 8)) & "00";
        lut_pix_d25(6).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(6).red, 8)) & "00";
        lut_pix_d25(6).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(6).gre, 8)) & "00";
        lut_pix_d25(6).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(6).blu, 8)) & "00";
        lut_pix_d25(7).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(7).red, 8)) & "00";
        lut_pix_d25(7).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(7).gre, 8)) & "00";
        lut_pix_d25(7).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(7).blu, 8)) & "00";
        lut_pix_d25(8).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(8).red, 8)) & "00";
        lut_pix_d25(8).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(8).gre, 8)) & "00";
        lut_pix_d25(8).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(8).blu, 8)) & "00";
        lut_pix_d25(9).red     <= std_logic_vector(to_unsigned(lut_rgb_d25(9).red, 8)) & "00";
        lut_pix_d25(9).gre     <= std_logic_vector(to_unsigned(lut_rgb_d25(9).gre, 8)) & "00";
        lut_pix_d25(9).blu     <= std_logic_vector(to_unsigned(lut_rgb_d25(9).blu, 8)) & "00";
        lut_pix_d25(10).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(10).red, 8)) & "00";
        lut_pix_d25(10).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(10).gre, 8)) & "00";
        lut_pix_d25(10).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(10).blu, 8)) & "00";
        lut_pix_d25(11).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(11).red, 8)) & "00";
        lut_pix_d25(11).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(11).gre, 8)) & "00";
        lut_pix_d25(11).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(11).blu, 8)) & "00";
        lut_pix_d25(12).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(12).red, 8)) & "00";
        lut_pix_d25(12).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(12).gre, 8)) & "00";
        lut_pix_d25(12).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(12).blu, 8)) & "00";
        lut_pix_d25(13).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(13).red, 8)) & "00";
        lut_pix_d25(13).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(13).gre, 8)) & "00";
        lut_pix_d25(13).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(13).blu, 8)) & "00";
        lut_pix_d25(14).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(14).red, 8)) & "00";
        lut_pix_d25(14).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(14).gre, 8)) & "00";
        lut_pix_d25(14).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(14).blu, 8)) & "00";
        lut_pix_d25(15).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(15).red, 8)) & "00";
        lut_pix_d25(15).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(15).gre, 8)) & "00";
        lut_pix_d25(15).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(15).blu, 8)) & "00";
        lut_pix_d25(16).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(16).red, 8)) & "00";
        lut_pix_d25(16).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(16).gre, 8)) & "00";
        lut_pix_d25(16).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(16).blu, 8)) & "00";
        lut_pix_d25(17).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(17).red, 8)) & "00";
        lut_pix_d25(17).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(17).gre, 8)) & "00";
        lut_pix_d25(17).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(17).blu, 8)) & "00";
        lut_pix_d25(18).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(18).red, 8)) & "00";
        lut_pix_d25(18).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(18).gre, 8)) & "00";
        lut_pix_d25(18).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(18).blu, 8)) & "00";
        lut_pix_d25(19).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(19).red, 8)) & "00";
        lut_pix_d25(19).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(19).gre, 8)) & "00";
        lut_pix_d25(19).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(19).blu, 8)) & "00";
        lut_pix_d25(20).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(20).red, 8)) & "00";
        lut_pix_d25(20).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(20).gre, 8)) & "00";
        lut_pix_d25(20).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(20).blu, 8)) & "00";
        lut_pix_d25(21).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(21).red, 8)) & "00";
        lut_pix_d25(21).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(21).gre, 8)) & "00";
        lut_pix_d25(21).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(21).blu, 8)) & "00";
        lut_pix_d25(22).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(22).red, 8)) & "00";
        lut_pix_d25(22).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(22).gre, 8)) & "00";
        lut_pix_d25(22).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(22).blu, 8)) & "00";
        lut_pix_d25(23).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(23).red, 8)) & "00";
        lut_pix_d25(23).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(23).gre, 8)) & "00";
        lut_pix_d25(23).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(23).blu, 8)) & "00";
        lut_pix_d25(24).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(24).red, 8)) & "00";
        lut_pix_d25(24).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(24).gre, 8)) & "00";
        lut_pix_d25(24).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(24).blu, 8)) & "00";
        lut_pix_d25(25).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(25).red, 8)) & "00";
        lut_pix_d25(25).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(25).gre, 8)) & "00";
        lut_pix_d25(25).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(25).blu, 8)) & "00";
        lut_pix_d25(26).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(26).red, 8)) & "00";
        lut_pix_d25(26).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(26).gre, 8)) & "00";
        lut_pix_d25(26).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(26).blu, 8)) & "00";
        lut_pix_d25(27).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(27).red, 8)) & "00";
        lut_pix_d25(27).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(27).gre, 8)) & "00";
        lut_pix_d25(27).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(27).blu, 8)) & "00";
        lut_pix_d25(28).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(28).red, 8)) & "00";
        lut_pix_d25(28).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(28).gre, 8)) & "00";
        lut_pix_d25(28).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(28).blu, 8)) & "00";
        lut_pix_d25(29).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(29).red, 8)) & "00";
        lut_pix_d25(29).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(29).gre, 8)) & "00";
        lut_pix_d25(29).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(29).blu, 8)) & "00";
        lut_pix_d25(30).red    <= std_logic_vector(to_unsigned(lut_rgb_d25(30).red, 8)) & "00";
        lut_pix_d25(30).gre    <= std_logic_vector(to_unsigned(lut_rgb_d25(30).gre, 8)) & "00";
        lut_pix_d25(30).blu    <= std_logic_vector(to_unsigned(lut_rgb_d25(30).blu, 8)) & "00";
    end if;
end process;
    ------------------------------------------------------------------------------
    -- Stage 4: 30 parallel Euclidean-distance engines
    ------------------------------------------------------------------------------
    color_k1_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(1).red,
            sel_lut_rgb.gre      => sel_lut_rgb(1).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(1).blu,
            dist_thr             => dist_thr_s0.threshold1);
    color_k2_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(2).red,
            sel_lut_rgb.gre      => sel_lut_rgb(2).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(2).blu,
            dist_thr             => dist_thr_s0.threshold2);
    color_k3_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(3).red,
            sel_lut_rgb.gre      => sel_lut_rgb(3).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(3).blu,
            dist_thr             => dist_thr_s0.threshold3);
    color_k4_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(4).red,
            sel_lut_rgb.gre      => sel_lut_rgb(4).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(4).blu,
            dist_thr             => dist_thr_s0.threshold4);
    color_k5_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(5).red,
            sel_lut_rgb.gre      => sel_lut_rgb(5).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(5).blu,
            dist_thr             => dist_thr_s0.threshold5);
    color_k6_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(6).red,
            sel_lut_rgb.gre      => sel_lut_rgb(6).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(6).blu,
            dist_thr             => dist_thr_s0.threshold6);
    color_k7_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(7).red,
            sel_lut_rgb.gre      => sel_lut_rgb(7).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(7).blu,
            dist_thr             => dist_thr_s0.threshold7);
    color_k8_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(8).red,
            sel_lut_rgb.gre      => sel_lut_rgb(8).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(8).blu,
            dist_thr             => dist_thr_s0.threshold8);
    color_k9_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(9).red,
            sel_lut_rgb.gre      => sel_lut_rgb(9).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(9).blu,
            dist_thr             => dist_thr_s0.threshold9);
    color_k10_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(10).red,
            sel_lut_rgb.gre      => sel_lut_rgb(10).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(10).blu,
            dist_thr             => dist_thr_s0.threshold10);
    color_k11_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(11).red,
            sel_lut_rgb.gre      => sel_lut_rgb(11).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(11).blu,
            dist_thr             => dist_thr_s0.threshold11);
    color_k12_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(12).red,
            sel_lut_rgb.gre      => sel_lut_rgb(12).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(12).blu,
            dist_thr             => dist_thr_s0.threshold12);
    color_k13_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(13).red,
            sel_lut_rgb.gre      => sel_lut_rgb(13).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(13).blu,
            dist_thr             => dist_thr_s0.threshold13);
    color_k14_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(14).red,
            sel_lut_rgb.gre      => sel_lut_rgb(14).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(14).blu,
            dist_thr             => dist_thr_s0.threshold14);
    color_k15_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(15).red,
            sel_lut_rgb.gre      => sel_lut_rgb(15).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(15).blu,
            dist_thr             => dist_thr_s0.threshold15);
    color_k16clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(16).red,
            sel_lut_rgb.gre      => sel_lut_rgb(16).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(16).blu,
            dist_thr             => dist_thr_s0.threshold16);
    color_k17_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(17).red,
            sel_lut_rgb.gre      => sel_lut_rgb(17).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(17).blu,
            dist_thr             => dist_thr_s0.threshold17);
    color_k18_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(18).red,
            sel_lut_rgb.gre      => sel_lut_rgb(18).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(18).blu,
            dist_thr             => dist_thr_s0.threshold18);
    color_k19_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(19).red,
            sel_lut_rgb.gre      => sel_lut_rgb(19).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(19).blu,
            dist_thr             => dist_thr_s0.threshold19);
    color_k20_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(20).red,
            sel_lut_rgb.gre      => sel_lut_rgb(20).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(20).blu,
            dist_thr             => dist_thr_s0.threshold20);
    color_k21_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(21).red,
            sel_lut_rgb.gre      => sel_lut_rgb(21).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(21).blu,
            dist_thr             => dist_thr_s0.threshold21);
    color_k22_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(22).red,
            sel_lut_rgb.gre      => sel_lut_rgb(22).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(22).blu,
            dist_thr             => dist_thr_s0.threshold22);
    color_k23_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(23).red,
            sel_lut_rgb.gre      => sel_lut_rgb(23).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(23).blu,
            dist_thr             => dist_thr_s0.threshold23);
    color_k24_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(24).red,
            sel_lut_rgb.gre      => sel_lut_rgb(24).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(24).blu,
            dist_thr             => dist_thr_s0.threshold24);
    color_k25_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(25).red,
            sel_lut_rgb.gre      => sel_lut_rgb(25).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(25).blu,
            dist_thr             => dist_thr_s0.threshold25);
    color_k26_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(26).red,
            sel_lut_rgb.gre      => sel_lut_rgb(26).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(26).blu,
            dist_thr             => dist_thr_s0.threshold26);
    color_k27_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(27).red,
            sel_lut_rgb.gre      => sel_lut_rgb(27).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(27).blu,
            dist_thr             => dist_thr_s0.threshold27);
    color_k28_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(28).red,
            sel_lut_rgb.gre      => sel_lut_rgb(28).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(28).blu,
            dist_thr             => dist_thr_s0.threshold28);
    color_k29_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(29).red,
            sel_lut_rgb.gre      => sel_lut_rgb(29).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(29).blu,
            dist_thr             => dist_thr_s0.threshold29);
    color_k30_clustering_inst : entity work.rgb_cluster_core
        generic map (
            data_width => i_data_width
        )
        port map (
            clk                 => clk,
            rst_n               => rst_n,
            rgb_streaming_pixels => pix_core_in,
            sel_lut_rgb.red      => sel_lut_rgb(30).red,
            sel_lut_rgb.gre      => sel_lut_rgb(30).gre,
            sel_lut_rgb.blu      => sel_lut_rgb(30).blu,
            dist_thr             => dist_thr_s0.threshold30);
        ------------------------------------------------------------------------------
    -- Stage 6: reduction tree for minimum-distance selection
    ------------------------------------------------------------------------------
    p_reduce_dist_l1 : process (clk) begin
    if rising_edge(clk) then
        dist_grp1_min  <= int_min_val(dist_thr_s0.threshold1,dist_thr_s0.threshold2,dist_thr_s0.threshold3,dist_thr_s0.threshold4,dist_thr_s0.threshold5);
        dist_grp2_min  <= int_min_val(dist_thr_s0.threshold6,dist_thr_s0.threshold7,dist_thr_s0.threshold8,dist_thr_s0.threshold9,dist_thr_s0.threshold10);
        dist_grp3_min  <= int_min_val(dist_thr_s0.threshold11,dist_thr_s0.threshold12,dist_thr_s0.threshold13,dist_thr_s0.threshold14,dist_thr_s0.threshold15);
        dist_grp4_min  <= int_min_val(dist_thr_s0.threshold16,dist_thr_s0.threshold17,dist_thr_s0.threshold18,dist_thr_s0.threshold19,dist_thr_s0.threshold20);
        dist_grp5_min  <= int_min_val(dist_thr_s0.threshold21,dist_thr_s0.threshold22,dist_thr_s0.threshold23,dist_thr_s0.threshold24,dist_thr_s0.threshold25);
        dist_grp6_min  <= int_min_val(dist_thr_s0.threshold26,dist_thr_s0.threshold27,dist_thr_s0.threshold28,dist_thr_s0.threshold29,dist_thr_s0.threshold30);
    end if; 
end process;
    p_pipe_dist_l2 : process (clk) begin
    if rising_edge(clk) then
        dist_pair1_min   <= int_min_val(dist_grp1_min,dist_grp2_min,dist_grp3_min);
        dist_pair2_min   <= int_min_val(dist_grp4_min,dist_grp5_min,dist_grp6_min);
    end if;
end process;
    p_reduce_dist_l2 : process (clk) begin
    if rising_edge(clk) then
        dist_min_pre    <= int_min_val(dist_pair1_min,dist_pair2_min);
        dist_min        <= dist_min_pre;
    end if;
end process;
    p_pipe_dist_l3 : process (clk) begin
    if rising_edge(clk) then
        dist_thr_s1 <= dist_thr_s0;
        dist_thr_s2 <= dist_thr_s1;
        dist_thr_s3 <= dist_thr_s2;
        dist_thr_out <= dist_thr_s3;
    end if;
end process;
        ------------------------------------------------------------------------------
    -- Stage 7: output pixel select and stream-control alignment
    ------------------------------------------------------------------------------
    p_select_pixel_out : process (clk) begin
    if rising_edge(clk) then
        if ((dist_thr_out.threshold1  = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(1).red;
            pixel_out_rgb.green   <= lut_pix_d25(1).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(1).blu;
        elsif((dist_thr_out.threshold2 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(2).red;
            pixel_out_rgb.green   <= lut_pix_d25(2).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(2).blu;
        elsif((dist_thr_out.threshold3 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(3).red;
            pixel_out_rgb.green   <= lut_pix_d25(3).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(3).blu;
        elsif((dist_thr_out.threshold4 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(4).red;
            pixel_out_rgb.green   <= lut_pix_d25(4).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(4).blu;
        elsif((dist_thr_out.threshold5 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(5).red;
            pixel_out_rgb.green   <= lut_pix_d25(5).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(5).blu;
        elsif((dist_thr_out.threshold6 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(6).red;
            pixel_out_rgb.green   <= lut_pix_d25(6).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(6).blu;
        elsif((dist_thr_out.threshold7 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(7).red;
            pixel_out_rgb.green   <= lut_pix_d25(7).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(7).blu;
        elsif((dist_thr_out.threshold8 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(8).red;
            pixel_out_rgb.green   <= lut_pix_d25(8).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(8).blu;
        elsif((dist_thr_out.threshold9 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(9).red;
            pixel_out_rgb.green   <= lut_pix_d25(9).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(9).blu;
        elsif((dist_thr_out.threshold10 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(10).red;
            pixel_out_rgb.green   <= lut_pix_d25(10).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(10).blu;
        elsif((dist_thr_out.threshold11 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(11).red;
            pixel_out_rgb.green   <= lut_pix_d25(11).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(11).blu;
        elsif((dist_thr_out.threshold12 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(12).red;
            pixel_out_rgb.green   <= lut_pix_d25(12).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(12).blu;
        elsif((dist_thr_out.threshold13 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(13).red;
            pixel_out_rgb.green   <= lut_pix_d25(13).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(13).blu;
        elsif((dist_thr_out.threshold14 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(14).red;
            pixel_out_rgb.green   <= lut_pix_d25(14).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(14).blu;
        elsif((dist_thr_out.threshold15 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(15).red;
            pixel_out_rgb.green   <= lut_pix_d25(15).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(15).blu;
        elsif((dist_thr_out.threshold16 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(16).red;
            pixel_out_rgb.green   <= lut_pix_d25(16).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(16).blu;
        elsif((dist_thr_out.threshold17 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(17).red;
            pixel_out_rgb.green   <= lut_pix_d25(17).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(17).blu;
        elsif((dist_thr_out.threshold18 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(18).red;
            pixel_out_rgb.green   <= lut_pix_d25(18).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(18).blu;
        elsif((dist_thr_out.threshold19 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(19).red;
            pixel_out_rgb.green   <= lut_pix_d25(19).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(19).blu;
        elsif((dist_thr_out.threshold20 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(20).red;
            pixel_out_rgb.green   <= lut_pix_d25(20).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(20).blu;
        elsif((dist_thr_out.threshold21 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(21).red;
            pixel_out_rgb.green   <= lut_pix_d25(21).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(21).blu;
        elsif((dist_thr_out.threshold22 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(22).red;
            pixel_out_rgb.green   <= lut_pix_d25(22).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(22).blu;
        elsif((dist_thr_out.threshold23 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(23).red;
            pixel_out_rgb.green   <= lut_pix_d25(23).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(23).blu;
        elsif((dist_thr_out.threshold24 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(24).red;
            pixel_out_rgb.green   <= lut_pix_d25(24).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(24).blu;
        elsif((dist_thr_out.threshold25 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(25).red;
            pixel_out_rgb.green   <= lut_pix_d25(25).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(25).blu;
        elsif((dist_thr_out.threshold26 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(26).red;
            pixel_out_rgb.green   <= lut_pix_d25(26).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(26).blu;
        elsif((dist_thr_out.threshold27 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(27).red;
            pixel_out_rgb.green   <= lut_pix_d25(27).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(27).blu;
        elsif((dist_thr_out.threshold28 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(28).red;
            pixel_out_rgb.green   <= lut_pix_d25(28).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(28).blu;
        elsif((dist_thr_out.threshold29 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(29).red;
            pixel_out_rgb.green   <= lut_pix_d25(29).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(29).blu;
        elsif((dist_thr_out.threshold30 = dist_min)) then
            pixel_out_rgb.red     <= lut_pix_d25(30).red;
            pixel_out_rgb.green   <= lut_pix_d25(30).gre;
            pixel_out_rgb.blue    <= lut_pix_d25(30).blu;
        else
            pixel_out_rgb.red     <= (others => '1');
            pixel_out_rgb.green   <= (others => '1');
            pixel_out_rgb.blue    <= (others => '1');
        end if;
    end if;
end process;
pixel_out_rgb.valid <= sync_vld_d(25); -- Align VALID with selected RGB
pixel_out_rgb.eol   <= sync_eol_d(25); -- Align EOL with selected RGB
pixel_out_rgb.sof   <= sync_sof_d(25); -- Align SOF with selected RGB
pixel_out_rgb.eof   <= sync_eof_d(25); -- Align EOF with selected RGB
end architecture rtl;