----------------------------------------------------------------------------------
-- Company      : SA611982
-- Author       : Sakinder Ali
-- Create Date  : 04282019 [04-28-2019]
-- Devices      : FPGA-CPLD-ZYNQ-SOC
-- SA611982-MJ  : 3.1
-- SA611982-MN  : 1
-- Description  :[SA611982-3.1-1][03/07/2026]:
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rgb_cluster_pkg.all;
entity rgb_kmeans_cluster_engine is
generic (
    i_data_width   : integer := 8);
port (
    clk            : in std_logic;
    rst_n          : in std_logic;
    rgb_streaming_pixels           : in channel;
    centroid_lut_select : in natural;
    centroid_lut_in       : in std_logic_vector(23 downto 0);
    centroid_lut_out      : out std_logic_vector(31 downto 0);
    k_ind_w        : in natural;
    k_ind_r        : in natural;
    pixel_out_rgb           : out channel);
end rgb_kmeans_cluster_engine;
architecture arch of rgb_kmeans_cluster_engine is
    signal rgbSyncEol    : std_logic_vector(31 downto 0) := x"00000000";
    signal rgbSyncSof    : std_logic_vector(31 downto 0) := x"00000000";
    signal rgbSyncEof    : std_logic_vector(31 downto 0) := x"00000000";
    signal rgbSyncValid  : std_logic_vector(31 downto 0) := x"00000000";
    signal k_lut_update_rgb_max_mid_min_indexs         : rgb_k_lut(0 to 30);
    signal rgb_preloaded_lut_max_mid_min_pixels_index                : rgb_k_lut(0 to 30);
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
    signal k_rgb_lut_2_l             : rgb_k_range(0 to 30) := (
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
    signal k_rgb_lut_2ll             : rgb_k_range(0 to 30) := (
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
    signal k_rgb_lut_4_l               : rgb_k_range(0 to 30) := (
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
    signal k_rgb_lut_4ll               : rgb_k_range(0 to 30) := (
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
    signal k_rgb_lut_3ll               : rgb_k_range(0 to 30) := (
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
    signal k_rgb_lut_6ll               : rgb_k_range(0 to 30) := (
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
    signal k_rgb_lut_3_l               : rgb_k_range(0 to 30) := (
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
    signal k_rgb_lut_6_l               : rgb_k_range(0 to 30) := (
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
    signal k1_rgb                : rgb_k_lut(0 to 30);
    signal k2_rgb                : rgb_k_lut(0 to 30);
    signal k3_rgb                : rgb_k_lut(0 to 30);
    signal k4_rgb                : rgb_k_lut(0 to 30);
    signal k5_rgb                : rgb_k_lut(0 to 30);
    signal k6_rgb                : rgb_k_lut(0 to 30);
    signal k7_rgb                : rgb_k_lut(0 to 30);
    signal k8_rgb                : rgb_k_lut(0 to 30);
    signal k9_rgb                : rgb_k_lut(0 to 30);
    signal k10rgb                : rgb_k_lut(0 to 30);
    signal k11rgb                : rgb_k_lut(0 to 30);
    signal k12rgb                : rgb_k_lut(0 to 30);
    signal k13rgb                : rgb_k_lut(0 to 30);
    signal k14rgb                : rgb_k_lut(0 to 30);
    signal k15rgb                : rgb_k_lut(0 to 30);
    signal k16rgb                : rgb_k_lut(0 to 30);
    signal k17rgb                : rgb_k_lut(0 to 30);
    signal k18rgb                : rgb_k_lut(0 to 30);
    signal k19rgb                : rgb_k_lut(0 to 30);
    signal k20rgb                : rgb_k_lut(0 to 30);
    signal k21rgb                : rgb_k_lut(0 to 30);
    signal k22rgb                : rgb_k_lut(0 to 30);
    signal k23rgb                : rgb_k_lut(0 to 30);
    signal k24rgb                : rgb_k_lut(0 to 30);
    signal k25rgb                : rgb_k_lut(0 to 30);

    signal rgb_preloaded_lut_pixels_index                   : k_val_rgb(0 to 30);
    signal euclidean_distance_thresholds                  : thr_record;
    signal euclidean_distance_thrs_2_pipln                  : thr_record;
    signal euclidean_distance_thrs_3_pipln                  : thr_record;
    signal euclidean_distance_thrs_4_pipln                  : thr_record;
    signal euclidean_distance                  : thr_record;
    signal euclidean_distance_threshold             : integer;
    signal distance_list1_thresholds       : integer;
    signal distance_list2_thresholds       : integer;
    signal distance_list3_thresholds       : integer;
    signal distance_list4_thresholds       : integer;
    signal distance_list5_thresholds       : integer;
    signal distance_list6_thresholds       : integer;
    signal distance1_thresholds        : integer;
    signal distance2_thresholds        : integer;
    signal most_min_distances         : integer;
    signal most_min_distances_threshold         : integer;
    
    signal rgb_min_pixels              : integer;
    signal rgb_max_pixels              : integer;
    signal rgb_streaming          : channel;
    signal rgb_line1_stream          : channel;
    signal rgb_line2_stream          : channel;
    signal incoming_rgb_streaming_pixels          : channel;
    signal incoming_pixels_max_min_rgb_selection             : intChannel;
    signal incoming_pixels_max_mid_min_rgb_selection             : intChannel;
    signal rgb_max               : integer;
    signal rgb_mid               : integer;
    signal rgb_min               : integer;
    signal rgb_red               : std_logic_vector(7 downto 0);
    signal rgb_gre               : std_logic_vector(7 downto 0);
    signal rgb_blu               : std_logic_vector(7 downto 0);
    constant K_VALUE             : integer := 11;
    attribute keep : string;
    attribute keep of rgb_max : signal is "true";
    attribute keep of rgb_mid : signal is "true";
    attribute keep of rgb_min : signal is "true";
begin
process (clk) begin
    if rising_edge(clk) then
        rgbSyncValid(0)  <= rgb_streaming_pixels.valid;
        for i in 0 to 30 loop
          rgbSyncValid(i+1)  <= rgbSyncValid(i);
        end loop;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncEol(0)  <= rgb_streaming_pixels.eol;
        for i in 0 to 30 loop
          rgbSyncEol(i+1)  <= rgbSyncEol(i);
        end loop;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncSof(0)  <= rgb_streaming_pixels.sof;
        for i in 0 to 30 loop
          rgbSyncSof(i+1)  <= rgbSyncSof(i);
        end loop;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncEof(0)  <= rgb_streaming_pixels.eof;
        for i in 0 to 30 loop
          rgbSyncEof(i+1)  <= rgbSyncEof(i);
        end loop;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
        rgb_streaming.red    <= rgb_streaming_pixels.red;
        rgb_streaming.green  <= rgb_streaming_pixels.green;
        rgb_streaming.blue   <= rgb_streaming_pixels.blue;
        rgb_streaming.valid  <= rgb_streaming_pixels.valid;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
        rgb_line1_stream    <= rgb_streaming;
        rgb_line2_stream    <= rgb_line1_stream;
        incoming_rgb_streaming_pixels    <= rgb_line2_stream;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
            incoming_pixels_max_min_rgb_selection.red    <= to_integer(unsigned(rgb_streaming.red(9 downto 2)));
            incoming_pixels_max_min_rgb_selection.green  <= to_integer(unsigned(rgb_streaming.green(9 downto 2)));
            incoming_pixels_max_min_rgb_selection.blue   <= to_integer(unsigned(rgb_streaming.blue(9 downto 2)));
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        if ((incoming_pixels_max_min_rgb_selection.red >= incoming_pixels_max_min_rgb_selection.green) and (incoming_pixels_max_min_rgb_selection.red >= incoming_pixels_max_min_rgb_selection.blue)) then
            rgb_max_pixels <= incoming_pixels_max_min_rgb_selection.red;
        elsif ((incoming_pixels_max_min_rgb_selection.green >= incoming_pixels_max_min_rgb_selection.red) and (incoming_pixels_max_min_rgb_selection.green >= incoming_pixels_max_min_rgb_selection.blue)) then
            rgb_max_pixels <= incoming_pixels_max_min_rgb_selection.green;
        else
            rgb_max_pixels <= incoming_pixels_max_min_rgb_selection.blue;
        end if;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        if ((incoming_pixels_max_min_rgb_selection.red <= incoming_pixels_max_min_rgb_selection.green) and (incoming_pixels_max_min_rgb_selection.red <= incoming_pixels_max_min_rgb_selection.blue)) then
            rgb_min_pixels <= incoming_pixels_max_min_rgb_selection.red;
        elsif((incoming_pixels_max_min_rgb_selection.green <= incoming_pixels_max_min_rgb_selection.red) and (incoming_pixels_max_min_rgb_selection.green <= incoming_pixels_max_min_rgb_selection.blue)) then
            rgb_min_pixels <= incoming_pixels_max_min_rgb_selection.green;
        else
            rgb_min_pixels <= incoming_pixels_max_min_rgb_selection.blue;
        end if;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) and (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
            rgb_max <= incoming_pixels_max_mid_min_rgb_selection.red;
            rgb_mid <= incoming_pixels_max_mid_min_rgb_selection.blue;
            rgb_min <= incoming_pixels_max_mid_min_rgb_selection.green;
        elsif(incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) and (incoming_pixels_max_mid_min_rgb_selection.blue = rgb_min_pixels)then
            rgb_max <= incoming_pixels_max_mid_min_rgb_selection.red;
            rgb_mid <= incoming_pixels_max_mid_min_rgb_selection.green;
            rgb_min <= incoming_pixels_max_mid_min_rgb_selection.blue;
        elsif(incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) and (incoming_pixels_max_mid_min_rgb_selection.blue = rgb_min_pixels)then
            rgb_max <= incoming_pixels_max_mid_min_rgb_selection.green;
            rgb_mid <= incoming_pixels_max_mid_min_rgb_selection.red;
            rgb_min <= incoming_pixels_max_mid_min_rgb_selection.blue;
        elsif(incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) and (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels)then
            rgb_max <= incoming_pixels_max_mid_min_rgb_selection.green;
            rgb_mid <= incoming_pixels_max_mid_min_rgb_selection.blue;
            rgb_min <= incoming_pixels_max_mid_min_rgb_selection.red;
        elsif(incoming_pixels_max_mid_min_rgb_selection.blue = rgb_max_pixels) and (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels)then
            rgb_max <= incoming_pixels_max_mid_min_rgb_selection.blue;
            rgb_mid <= incoming_pixels_max_mid_min_rgb_selection.green;
            rgb_min <= incoming_pixels_max_mid_min_rgb_selection.red;
        elsif(incoming_pixels_max_mid_min_rgb_selection.blue = rgb_max_pixels) and (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels)then
            rgb_max <= incoming_pixels_max_mid_min_rgb_selection.blue;
            rgb_mid <= incoming_pixels_max_mid_min_rgb_selection.red;
            rgb_min <= incoming_pixels_max_mid_min_rgb_selection.green;
        end if;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
      incoming_pixels_max_mid_min_rgb_selection        <= incoming_pixels_max_min_rgb_selection;
    end if;
end process;
-- best select is 18/17/16
process (clk)begin
    if rising_edge(clk) then
        if (k_ind_w <= 30)then
            k_rgb_lut_4ll(k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); k_rgb_lut_4ll(k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   k_rgb_lut_4ll(k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
        if (k_ind_w >= 31 and k_ind_w <= 60) then
            k_rgb_lut_2ll(61-k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); k_rgb_lut_2ll(61-k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   k_rgb_lut_2ll(61-k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
        if (k_ind_w >= 61 and k_ind_w <= 90) then
            k_rgb_lut_3ll(91-k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); k_rgb_lut_3ll(91-k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   k_rgb_lut_3ll(91-k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
        if (k_ind_w >= 91 and k_ind_w <= 120) then
            k_rgb_lut_6ll(121-k_ind_w).max  <= to_integer((unsigned(centroid_lut_in(23 downto 16)))); k_rgb_lut_6ll(121-k_ind_w).mid <= to_integer((unsigned(centroid_lut_in(15 downto 8))));   k_rgb_lut_6ll(121-k_ind_w).min <= to_integer((unsigned(centroid_lut_in(7 downto 0))));
        end if;
    end if;
end process;
process(clk)begin
    if rising_edge(clk) then
        if (k_ind_r <= 30)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(k_rgb_lut_4_l(k_ind_r).max, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_4_l(k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_4_l(k_ind_r).min, 8));
        elsif(k_ind_w >= 31 and k_ind_w <= 60)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(k_rgb_lut_2_l(61-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_2_l(61-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_2_l(61-k_ind_r).min, 8));
        elsif(k_ind_w >= 61 and k_ind_w <= 90)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(k_rgb_lut_3_l(91-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_3_l(91-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_3_l(91-k_ind_r).min, 8));
        elsif(k_ind_w >= 91 and k_ind_w <= 120)then
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(k_rgb_lut_6_l(121-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_6_l(121-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_6_l(121-k_ind_r).min, 8));
        else
            centroid_lut_out                 <= x"00" & std_logic_vector(to_unsigned(k_rgb_lut_3_l(91-k_ind_r).max, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_3_l(91-k_ind_r).mid, 8)) & std_logic_vector(to_unsigned(k_rgb_lut_3_l(91-k_ind_r).min, 8));
        end if;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
        if (k_ind_w <= 90)then
            k_rgb_lut_4_l <= k_rgb_lut_4ll;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_2ll;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 201)then
            k_rgb_lut_4_l <= k_rgb_lut_42l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 202)then
            k_rgb_lut_4_l <= k_rgb_lut_43l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 203)then
            k_rgb_lut_4_l <= k_rgb_lut_41l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 204)then
            k_rgb_lut_4_l <= k_rgb_lut_42l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 205)then
            k_rgb_lut_4_l <= k_rgb_lut_43l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 206)then
            k_rgb_lut_4_l <= k_rgb_lut_44l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 207)then
            k_rgb_lut_4_l <= k_rgb_lut_45l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 208)then
            k_rgb_lut_4_l <= k_rgb_lut_46l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w = 209)then
            k_rgb_lut_4_l <= k_rgb_lut_47l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =210)then
            k_rgb_lut_4_l <= k_rgb_lut_48l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =211)then
            k_rgb_lut_4_l <= k_rgb_lut_49l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =212)then
            k_rgb_lut_4_l <= k_rgb_lut_50l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =213)then
            k_rgb_lut_4_l <= k_rgb_lut_51l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =214)then
            k_rgb_lut_4_l <= k_rgb_lut_52l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =215)then
            k_rgb_lut_4_l <= k_rgb_lut_53l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =216)then
            k_rgb_lut_4_l <= k_rgb_lut_54l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =217)then
            k_rgb_lut_4_l <= k_rgb_lut_55l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =218)then
            k_rgb_lut_4_l <= k_rgb_lut_56l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =219)then
            k_rgb_lut_4_l <= k_rgb_lut_57l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =220)then
            k_rgb_lut_4_l <= k_rgb_lut_58l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        elsif(k_ind_w =221)then
            k_rgb_lut_4_l <= k_rgb_lut_59l;
            k_rgb_lut_3_l <= k_rgb_lut_3ll;
            k_rgb_lut_2_l <= k_rgb_lut_22l;
            k_rgb_lut_6_l <= k_rgb_lut_6ll;
        end if;
    end if;
end process;
-- best select is 0
process (clk)begin
    if rising_edge(clk) then
        if (centroid_lut_select   = 0)then
            ---------------------------------------------------------------------------------------------------------
            if ((abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.green) <= 6) and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6)) or (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6 and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.green) <= 6)) or (abs(incoming_pixels_max_mid_min_rgb_selection.green - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6  and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6))then
              for i in 0 to 30 loop
                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_0_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_0_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_0_l(i).mid;
              end loop;
            elsif (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (rgb_max_pixels - rgb_min_pixels >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                      for i in 0 to 30 loop
                        k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_1_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_1_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_1_l(i).mid;
                      end loop;
                    else
                      for i in 0 to 30 loop
                        k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_1_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_1_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_1_l(i).min;
                      end loop;
                    end if;
                elsif (incoming_pixels_max_mid_min_rgb_selection.red >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                      for i in 0 to 30 loop
                        k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                      end loop;
                    else
                      for i in 0 to 30 loop
                        k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                      end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    end if;                                                        
                end if;
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if (rgb_max_pixels - rgb_min_pixels >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_1_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_1_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_1_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_1_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_1_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_1_l(i).min;
                          end loop;
                    end if;
                elsif(incoming_pixels_max_mid_min_rgb_selection.green >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                          end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    end if;                                                        
                end if;  
            else
                if (rgb_max_pixels - rgb_min_pixels >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_1_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_1_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_1_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_1_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_1_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_1_l(i).max;
                          end loop;
                    end if;
                elsif(incoming_pixels_max_mid_min_rgb_selection.blue >= 100) then
                        if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                          end loop;
                        else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                          end loop;
                        end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 1) then
            ---------------------------------------------------------------------------------------------------------
            if ((abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.green) <= 6) and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6)) or (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6 and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.green) <= 6)) or (abs(incoming_pixels_max_mid_min_rgb_selection.green - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6  and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6))then
                for i in 0 to 30 loop
                    k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_0_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_0_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_0_l(i).mid;
                end loop;
            -- RED MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                          end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 2) then
            ---------------------------------------------------------------------------------------------------------
            if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                          end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 3) then
            ---------------------------------------------------------------------------------------------------------
            if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                          end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 4) then
            ---------------------------------------------------------------------------------------------------------
            if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    end if;                                                        
                end if;
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                          end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 100) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    end if;
                else
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 5) then
            ---------------------------------------------------------------------------------------------------------
            if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 210) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_6_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_6_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_6_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_6_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_6_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_6_l(i).mid;
                        end loop;
                    end if;
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 210) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_6_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_6_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_6_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_6_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_6_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_6_l(i).mid;
                          end loop;
                    end if;
                elsif(incoming_pixels_max_mid_min_rgb_selection.green >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 210) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_6_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_6_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_6_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_6_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_6_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_6_l(i).max;
                        end loop;
                    end if;
                elsif(incoming_pixels_max_mid_min_rgb_selection.blue >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 6) then
            ---------------------------------------------------------------------------------------------------------
            if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            ---------------------------------------------------------------------------------------------------------
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                        end loop;
                    else
                        if ((abs(rgb_max - rgb_mid) <= 20) or (abs(rgb_max - rgb_min) <= 20))then
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    else
                        if ((abs(rgb_max - rgb_mid) <= 40) or (abs(rgb_max - rgb_min) <= 40))then
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                        if ((abs(rgb_max - rgb_mid) <= 8) or (abs(rgb_max - rgb_min) <= 8))then
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  abs(k_rgb_lut_2_l(i).mid - 30);   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                            end loop;
                        end if;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 7) then
            ---------------------------------------------------------------------------------------------------------
            -- RED MAX
            if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).min;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            ---------------------------------------------------------------------------------------------------------
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            ---------------------------------------------------------------------------------------------------------
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                        end loop;
                    else
                        if ((abs(rgb_max - rgb_mid) <= 20) or (abs(rgb_max - rgb_min) <= 20))then
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    else
                        if ((abs(rgb_max - rgb_mid) <= 40) or (abs(rgb_max - rgb_min) <= 40))then
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                            end loop;
                        end if;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                        if ((abs(rgb_max - rgb_mid) <= 8) or (abs(rgb_max - rgb_min) <= 8))then
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  abs(k_rgb_lut_2_l(i).mid - 30);   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).min;
                            end loop;
                        else
                            for i in 0 to 30 loop
                                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                            end loop;
                        end if;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        elsif(centroid_lut_select = 8) then
            ---------------------------------------------------------------------------------------------------------
            if ((abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.green) <= 6) and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6)) or (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6 and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.green) <= 6)) or (abs(incoming_pixels_max_mid_min_rgb_selection.green - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6  and (abs(incoming_pixels_max_mid_min_rgb_selection.red - incoming_pixels_max_mid_min_rgb_selection.blue) <= 6))then
              for i in 0 to 30 loop
                k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_0_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_0_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_0_l(i).mid;
              end loop;
            ---------------------------------------------------------------------------------------------------------
            elsif(incoming_pixels_max_mid_min_rgb_selection.red = rgb_max_pixels) then
                if (incoming_pixels_max_mid_min_rgb_selection.red >= 170) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.green = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                end if;
            -- GREEN MAX
            elsif (incoming_pixels_max_mid_min_rgb_selection.green = rgb_max_pixels) then
                if(incoming_pixels_max_mid_min_rgb_selection.green >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).mid;
                          end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).max;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).mid;
                          end loop;
                    end if;                                                        
                end if;
            else
            -- BLUE MAX
                if(incoming_pixels_max_mid_min_rgb_selection.blue >= 170) then
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_3_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_3_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_3_l(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                elsif(incoming_pixels_max_mid_min_rgb_selection.red >= 85) then
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    else
                        for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_4_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_4_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_4_l(i).max;
                        end loop;
                    end if;
                    -------------------------------------------------------------------------------------------------
                else
                    -------------------------------------------------------------------------------------------------
                    if (incoming_pixels_max_mid_min_rgb_selection.red = rgb_min_pixels) then
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    else
                          for i in 0 to 30 loop
                            k_lut_update_rgb_max_mid_min_indexs(i).red <=   k_rgb_lut_2_l(i).min;   k_lut_update_rgb_max_mid_min_indexs(i).green <=  k_rgb_lut_2_l(i).mid;   k_lut_update_rgb_max_mid_min_indexs(i).blue <=  k_rgb_lut_2_l(i).max;
                          end loop;
                    end if;                                                        
                end if;                                                            
            end if;
            ---------------------------------------------------------------------------------------------------------
        end if;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
      k1_rgb      <= k_lut_update_rgb_max_mid_min_indexs;
      k2_rgb      <= k1_rgb;
      k3_rgb      <= k2_rgb;
      k4_rgb      <= k3_rgb;
      k5_rgb      <= k4_rgb;
      k6_rgb      <= k5_rgb;
      k7_rgb      <= k6_rgb;
      k8_rgb      <= k7_rgb;
      k9_rgb      <= k8_rgb;
      k10rgb      <= k9_rgb;
      k11rgb      <= k10rgb;
      k12rgb      <= k11rgb;
      k13rgb      <= k12rgb;
      k14rgb      <= k13rgb;
      k15rgb      <= k14rgb;
      k16rgb      <= k15rgb;
      k17rgb      <= k16rgb;
      k18rgb      <= k17rgb;
      k19rgb      <= k18rgb;
      k20rgb      <= k19rgb;
      k21rgb      <= k20rgb;
      k22rgb      <= k21rgb;
      k23rgb      <= k22rgb;
      k24rgb      <= k23rgb;
      k25rgb      <= k24rgb;
      rgb_preloaded_lut_max_mid_min_pixels_index  <= k25rgb;
    end if;
end process;
process (clk)begin
    if rising_edge(clk) then
        rgb_preloaded_lut_pixels_index(1).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(1).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(1).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(1).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(1).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(1).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(2).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(2).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(2).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(2).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(2).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(2).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(3).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(3).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(3).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(3).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(3).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(3).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(4).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(4).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(4).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(4).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(4).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(4).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(5).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(5).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(5).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(5).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(5).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(5).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(6).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(6).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(6).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(6).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(6).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(6).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(7).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(7).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(7).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(7).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(7).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(7).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(8).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(8).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(8).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(8).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(8).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(8).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(9).red     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(9).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(9).green     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(9).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(9).blue     <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(9).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(10).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(10).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(10).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(10).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(10).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(10).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(11).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(11).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(11).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(11).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(11).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(11).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(12).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(12).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(12).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(12).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(12).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(12).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(13).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(13).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(13).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(13).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(13).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(13).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(14).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(14).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(14).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(14).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(14).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(14).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(15).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(15).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(15).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(15).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(15).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(15).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(16).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(16).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(16).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(16).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(16).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(16).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(17).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(17).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(17).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(17).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(17).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(17).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(18).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(18).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(18).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(18).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(18).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(18).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(19).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(19).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(19).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(19).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(19).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(19).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(20).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(20).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(20).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(20).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(20).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(20).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(21).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(21).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(21).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(21).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(21).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(21).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(22).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(22).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(22).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(22).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(22).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(22).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(23).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(23).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(23).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(23).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(23).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(23).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(24).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(24).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(24).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(24).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(24).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(24).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(25).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(25).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(25).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(25).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(25).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(25).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(26).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(26).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(26).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(26).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(26).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(26).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(27).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(27).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(27).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(27).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(27).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(27).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(28).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(28).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(28).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(28).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(28).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(28).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(29).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(29).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(29).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(29).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(29).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(29).blue, 8)) & "00";
        rgb_preloaded_lut_pixels_index(30).red    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(30).red, 8)) & "00";
        rgb_preloaded_lut_pixels_index(30).green    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(30).green, 8)) & "00";
        rgb_preloaded_lut_pixels_index(30).blue    <= std_logic_vector(to_unsigned(rgb_preloaded_lut_max_mid_min_pixels_index(30).blue, 8)) & "00";
    end if;
end process;
color_k1_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(1).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(1).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(1).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold1);
color_k2_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(2).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(2).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(2).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold2);
color_k3_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(3).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(3).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(3).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold3);
color_k4_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(4).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(4).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(4).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold4);
color_k5_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(5).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(5).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(5).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold5);
color_k6_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(6).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(6).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(6).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold6);
color_k7_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(7).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(7).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(7).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold7);
color_k8_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(8).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(8).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(8).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold8);
color_k9_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(9).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(9).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(9).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold9);
color_k10_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(10).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(10).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(10).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold10);
color_k11_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(11).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(11).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(11).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold11);
color_k12_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(12).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(12).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(12).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold12);
color_k13_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(13).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(13).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(13).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold13);
color_k14_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(14).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(14).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(14).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold14);
color_k15_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(15).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(15).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(15).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold15);
color_k16clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(16).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(16).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(16).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold16);
color_k17_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(17).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(17).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(17).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold17);
color_k18_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(18).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(18).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(18).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold18);
color_k19_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(19).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(19).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(19).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold19);
color_k20_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(20).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(20).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(20).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold20);
color_k21_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(21).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(21).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(21).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold21);
color_k22_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(22).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(22).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(22).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold22);
color_k23_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(23).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(23).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(23).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold23);
color_k24_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(24).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(24).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(24).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold24);
color_k25_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(25).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(25).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(25).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold25);
color_k26_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(26).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(26).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(26).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold26);
color_k27_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(27).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(27).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(27).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold27);
color_k28_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(28).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(28).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(28).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold28);
color_k29_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels        => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(29).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(29).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(29).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold29);
color_k30_clustering_inst: entity work.rgb_cluster_core
generic map(
    data_width        => i_data_width)
port map(
    clk                => clk,
    rst_n              => rst_n,
    rgb_streaming_pixels               => incoming_rgb_streaming_pixels,
    k_lut_rgb_max_mid_min_indexs.red          => k_lut_update_rgb_max_mid_min_indexs(30).red,
    k_lut_rgb_max_mid_min_indexs.green          => k_lut_update_rgb_max_mid_min_indexs(30).green,
    k_lut_rgb_max_mid_min_indexs.blue          => k_lut_update_rgb_max_mid_min_indexs(30).blue,
    euclidean_distance_threshold          => euclidean_distance_thresholds.threshold30);
process (clk) begin
    if rising_edge(clk) then
        distance_list1_thresholds  <= int_min_val(euclidean_distance_thresholds.threshold1,euclidean_distance_thresholds.threshold2,euclidean_distance_thresholds.threshold3,euclidean_distance_thresholds.threshold4,euclidean_distance_thresholds.threshold5);
        distance_list2_thresholds  <= int_min_val(euclidean_distance_thresholds.threshold6,euclidean_distance_thresholds.threshold7,euclidean_distance_thresholds.threshold8,euclidean_distance_thresholds.threshold9,euclidean_distance_thresholds.threshold10);
        distance_list3_thresholds  <= int_min_val(euclidean_distance_thresholds.threshold11,euclidean_distance_thresholds.threshold12,euclidean_distance_thresholds.threshold13,euclidean_distance_thresholds.threshold14,euclidean_distance_thresholds.threshold15);
        distance_list4_thresholds  <= int_min_val(euclidean_distance_thresholds.threshold16,euclidean_distance_thresholds.threshold17,euclidean_distance_thresholds.threshold18,euclidean_distance_thresholds.threshold19,euclidean_distance_thresholds.threshold20);
        distance_list5_thresholds  <= int_min_val(euclidean_distance_thresholds.threshold21,euclidean_distance_thresholds.threshold22,euclidean_distance_thresholds.threshold23,euclidean_distance_thresholds.threshold24,euclidean_distance_thresholds.threshold25);
        distance_list6_thresholds  <= int_min_val(euclidean_distance_thresholds.threshold26,euclidean_distance_thresholds.threshold27,euclidean_distance_thresholds.threshold28,euclidean_distance_thresholds.threshold29,euclidean_distance_thresholds.threshold30);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then
        distance1_thresholds   <= int_min_val(distance_list1_thresholds,distance_list2_thresholds,distance_list3_thresholds);
        distance2_thresholds   <= int_min_val(distance_list4_thresholds,distance_list5_thresholds,distance_list6_thresholds);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        most_min_distances    <= int_min_val(distance1_thresholds,distance2_thresholds);
        most_min_distances_threshold        <= most_min_distances;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        euclidean_distance_thrs_2_pipln <= euclidean_distance_thresholds;
        euclidean_distance_thrs_3_pipln <= euclidean_distance_thrs_2_pipln;
        euclidean_distance_thrs_4_pipln <= euclidean_distance_thrs_3_pipln;
        euclidean_distance <= euclidean_distance_thrs_4_pipln;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        if ((euclidean_distance.threshold1  = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(1).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(1).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(1).blue;
        elsif((euclidean_distance.threshold2 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(2).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(2).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(2).blue;
        elsif((euclidean_distance.threshold3 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(3).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(3).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(3).blue;
        elsif((euclidean_distance.threshold4 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(4).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(4).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(4).blue;
        elsif((euclidean_distance.threshold5 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(5).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(5).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(5).blue;
        elsif((euclidean_distance.threshold6 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(6).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(6).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(6).blue;
        elsif((euclidean_distance.threshold7 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(7).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(7).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(7).blue;
        elsif((euclidean_distance.threshold8 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(8).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(8).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(8).blue;
        elsif((euclidean_distance.threshold9 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(9).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(9).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(9).blue;
        elsif((euclidean_distance.threshold10 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(10).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(10).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(10).blue;
        elsif((euclidean_distance.threshold11 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(11).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(11).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(11).blue;
        elsif((euclidean_distance.threshold12 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(12).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(12).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(12).blue;
        elsif((euclidean_distance.threshold13 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(13).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(13).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(13).blue;
        elsif((euclidean_distance.threshold14 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(14).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(14).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(14).blue;
        elsif((euclidean_distance.threshold15 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(15).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(15).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(15).blue;
        elsif((euclidean_distance.threshold16 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(16).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(16).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(16).blue;
        elsif((euclidean_distance.threshold17 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(17).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(17).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(17).blue;
        elsif((euclidean_distance.threshold18 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(18).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(18).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(18).blue;
        elsif((euclidean_distance.threshold19 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(19).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(19).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(19).blue;
        elsif((euclidean_distance.threshold20 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(20).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(20).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(20).blue;
        elsif((euclidean_distance.threshold21 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(21).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(21).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(21).blue;
        elsif((euclidean_distance.threshold22 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(22).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(22).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(22).blue;
        elsif((euclidean_distance.threshold23 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(23).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(23).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(23).blue;
        elsif((euclidean_distance.threshold24 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(24).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(24).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(24).blue;
        elsif((euclidean_distance.threshold25 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(25).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(25).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(25).blue;
        elsif((euclidean_distance.threshold26 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(26).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(26).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(26).blue;
        elsif((euclidean_distance.threshold27 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(27).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(27).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(27).blue;
        elsif((euclidean_distance.threshold28 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(28).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(28).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(28).blue;
        elsif((euclidean_distance.threshold29 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(29).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(29).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(29).blue;
        elsif((euclidean_distance.threshold30 = most_min_distances_threshold)) then
            pixel_out_rgb.red     <= rgb_preloaded_lut_pixels_index(30).red;
            pixel_out_rgb.green   <= rgb_preloaded_lut_pixels_index(30).green;
            pixel_out_rgb.blue    <= rgb_preloaded_lut_pixels_index(30).blue;
        else
            pixel_out_rgb.red     <= (others => '1');
            pixel_out_rgb.green   <= (others => '1');
            pixel_out_rgb.blue    <= (others => '1');
        end if;
    end if;
end process;
pixel_out_rgb.valid <= rgbSyncValid(25);
pixel_out_rgb.eol   <= rgbSyncEol(25);
pixel_out_rgb.sof   <= rgbSyncSof(25);
pixel_out_rgb.eof   <= rgbSyncEof(25);
end architecture;