
----------------------------------------------------------------------------------
-- RGB CLUSTER CORE
-- Computes Euclidean distance between streaming pixel and centroid:
-- sqrt( (R - kR)^2 + (G - kG)^2 + (B - kB)^2 )
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rgb_cluster_pkg.all;

entity rgb_cluster_core is
    generic ( data_width : integer := 8 );
    port (
        clk                          : in std_logic;
        rst_n                        : in std_logic;
        rgb_streaming_pixels         : in channel;
        k_lut_rgb_max_mid_min_indexs : in int_rgb;
        euclidean_distance_threshold : out integer
    );
end rgb_cluster_core;

architecture arch of rgb_cluster_core is
    signal euclidean_distance_rgb_pixels : s_pixel; -- Pipeline record
begin

    ------------------------------------------------------------------------------
    -- STAGE 0 — INPUT CAPTURE
    -- Extract 8 MSBs from 10-bit pixel channels
    ------------------------------------------------------------------------------
    stage0_input_capture : process (clk)
    begin
        if rising_edge(clk) then
            euclidean_distance_rgb_pixels.red_input_stream   <= to_integer(unsigned(rgb_streaming_pixels.red(9 downto 2)));
            euclidean_distance_rgb_pixels.green_input_stream <= to_integer(unsigned(rgb_streaming_pixels.green(9 downto 2)));
            euclidean_distance_rgb_pixels.blue_input_stream  <= to_integer(unsigned(rgb_streaming_pixels.blue(9 downto 2)));
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- STAGE 1 — ABS DIFFERENCE
    ------------------------------------------------------------------------------
    stage1_abs_diff : process (clk)
    begin
        if rising_edge(clk) then
            euclidean_distance_rgb_pixels.red_diff   <= abs(k_lut_rgb_max_mid_min_indexs.red - euclidean_distance_rgb_pixels.red_input_stream);
            euclidean_distance_rgb_pixels.green_diff <= abs(k_lut_rgb_max_mid_min_indexs.green - euclidean_distance_rgb_pixels.green_input_stream);
            euclidean_distance_rgb_pixels.blue_diff  <= abs(k_lut_rgb_max_mid_min_indexs.blue - euclidean_distance_rgb_pixels.blue_input_stream);
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- STAGE 2 — SQUARE DIFFERENCES
    ------------------------------------------------------------------------------
    stage2_square : process (clk)
    begin
        if rising_edge(clk) then
            euclidean_distance_rgb_pixels.red_diff_sqr   <= euclidean_distance_rgb_pixels.red_diff   * euclidean_distance_rgb_pixels.red_diff;
            euclidean_distance_rgb_pixels.green_diff_sqr <= euclidean_distance_rgb_pixels.green_diff * euclidean_distance_rgb_pixels.green_diff;
            euclidean_distance_rgb_pixels.blue_diff_sqr  <= euclidean_distance_rgb_pixels.blue_diff  * euclidean_distance_rgb_pixels.blue_diff;
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- STAGE 3 — SUM OF SQUARED DIFFERENCES
    ------------------------------------------------------------------------------
    stage3_sum_squares : process (clk)
    begin
        if rising_edge(clk) then
            euclidean_distance_rgb_pixels.summed_per_rgb_differences_squared_pixel_channels <=
                euclidean_distance_rgb_pixels.red_diff_sqr +
                euclidean_distance_rgb_pixels.green_diff_sqr +
                euclidean_distance_rgb_pixels.blue_diff_sqr;
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- Convert SUM → std_logic_vector
    ------------------------------------------------------------------------------
    stage3_sum_to_slv : process (clk)
    begin
        if rising_edge(clk) then
            euclidean_distance_rgb_pixels.sum <=
                std_logic_vector(to_unsigned(
                    euclidean_distance_rgb_pixels.summed_per_rgb_differences_squared_pixel_channels, 32));
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- STAGE 4 — PREPARE RADICAND FOR SQUARE ROOT
    ------------------------------------------------------------------------------
    stage4_radicand : process (clk)
    begin
        if rising_edge(clk) then
            euclidean_distance_rgb_pixels.radicand <= euclidean_distance_rgb_pixels.sum;
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- STAGE 4 — SQUARE ROOT PIPELINE
    ------------------------------------------------------------------------------
    square_root_inst : entity work.square_root
        generic map ( data_width => 32 )
        port map (
            clk         => clk,
            rst_n       => rst_n,
            radicand_in => euclidean_distance_rgb_pixels.radicand,
            root_out    => euclidean_distance_rgb_pixels.root_out
        );

    ------------------------------------------------------------------------------
    -- STAGE 4B — Convert sqrt output to integer
    ------------------------------------------------------------------------------
    stage4b_sqrt_to_int : process (clk, rst_n)
    begin
        if rising_edge(clk) then
            euclidean_distance_rgb_pixels.square_root_out <=
                to_integer(unsigned(euclidean_distance_rgb_pixels.root_out));
        end if;
    end process;

    ------------------------------------------------------------------------------
    -- STAGE 5 — FINAL THRESHOLD OUTPUT
    ------------------------------------------------------------------------------
    stage5_output_threshold : process (clk, rst_n)
    begin
        if rising_edge(clk) then
            euclidean_distance_threshold <= euclidean_distance_rgb_pixels.square_root_out;
        end if;
    end process;

end architecture;
