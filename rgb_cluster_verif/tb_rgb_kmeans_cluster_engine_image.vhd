library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.rgb_cluster_pkg.all;

entity tb_rgb_kmeans_cluster_engine_image is
end entity;

architecture sim of tb_rgb_kmeans_cluster_engine_image is
    constant CLK_PERIOD : time := 10 ns;
    constant INPUT_FILE  : string := "input_pixels.txt";
    constant OUTPUT_FILE : string := "dut_output_pixels.txt";

    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';

    signal rgb_streaming_pixels : channel := (
        valid => '0', sof => '0', eol => '0', eof => '0',
        xcnt => 0, ycnt => 0,
        red => (others => '0'), green => (others => '0'), blue => (others => '0')
    );

    signal centroid_lut_select : natural := 0;
    signal centroid_lut_in      : std_logic_vector(23 downto 0) := (others => '0');
    signal centroid_lut_out     : std_logic_vector(31 downto 0);
    signal k_ind_w              : natural := 0;
    signal k_ind_r              : natural := 0;
    signal pixel_out_rgb        : channel;

    shared variable frame_width  : integer := 0;
    shared variable frame_height : integer := 0;

    procedure program_centroid(
        constant index : in natural;
        constant r8    : in integer;
        constant g8    : in integer;
        constant b8    : in integer
    ) is
    begin
        wait until rising_edge(clk);
        k_ind_w <= index;
        centroid_lut_in <= std_logic_vector(to_unsigned(r8, 8)) &
                           std_logic_vector(to_unsigned(g8, 8)) &
                           std_logic_vector(to_unsigned(b8, 8));
    end procedure;

begin
    clk <= not clk after CLK_PERIOD/2;

    dut : entity work.rgb_kmeans_cluster_engine
        generic map (
            i_data_width => 8
        )
        port map (
            clk                  => clk,
            rst_n                => rst_n,
            rgb_streaming_pixels => rgb_streaming_pixels,
            centroid_lut_select  => centroid_lut_select,
            centroid_lut_in      => centroid_lut_in,
            centroid_lut_out     => centroid_lut_out,
            k_ind_w              => k_ind_w,
            k_ind_r              => k_ind_r,
            pixel_out_rgb        => pixel_out_rgb
        );

    stim_p : process
        file f_in : text open read_mode is INPUT_FILE;
        variable l : line;
        variable x, y, r8, g8, b8 : integer;
        variable header_done : boolean := false;
    begin
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        wait until rising_edge(clk);
        rst_n <= '1';

        -- Example centroid programming. Adjust indices/bank selection to match your chosen LUT bank.
        centroid_lut_select <= 0;
        program_centroid(0, 255, 255, 255);
        program_centroid(1, 192, 192, 192);
        program_centroid(2, 128, 128, 128);
        program_centroid(3, 64,  64,  64);
        program_centroid(4, 0,   0,   0);

        while not endfile(f_in) loop
            readline(f_in, l);
            if l'length = 0 then
                next;
            end if;
            if l.all(1) = '#' then
                next;
            end if;

            if not header_done then
                read(l, frame_width);
                read(l, frame_height);
                header_done := true;
            else
                read(l, x);
                read(l, y);
                read(l, r8);
                read(l, g8);
                read(l, b8);

                wait until rising_edge(clk);
                rgb_streaming_pixels.valid <= '1';
                rgb_streaming_pixels.sof   <= '1' when (x = 0 and y = 0) else '0';
                rgb_streaming_pixels.eol   <= '1' when (x = frame_width - 1) else '0';
                rgb_streaming_pixels.eof   <= '1' when (x = frame_width - 1 and y = frame_height - 1) else '0';
                rgb_streaming_pixels.xcnt  <= x;
                rgb_streaming_pixels.ycnt  <= y;
                rgb_streaming_pixels.red   <= std_logic_vector(to_unsigned(r8 * 4, 10));
                rgb_streaming_pixels.green <= std_logic_vector(to_unsigned(g8 * 4, 10));
                rgb_streaming_pixels.blue  <= std_logic_vector(to_unsigned(b8 * 4, 10));
            end if;
        end loop;

        wait until rising_edge(clk);
        rgb_streaming_pixels.valid <= '0';
        rgb_streaming_pixels.sof   <= '0';
        rgb_streaming_pixels.eol   <= '0';
        rgb_streaming_pixels.eof   <= '0';

        -- allow pipeline to drain
        for i in 0 to 128 loop
            wait until rising_edge(clk);
        end loop;

        report "tb_rgb_kmeans_cluster_engine_image stimulus completed" severity note;
        wait;
    end process;

    capture_p : process
        file f_out : text open write_mode is OUTPUT_FILE;
        variable l : line;
    begin
        wait until rst_n = '1';
        write(l, string'("# x y r g b valid sof eol eof"));
        writeline(f_out, l);

        loop
            wait until rising_edge(clk);
            if pixel_out_rgb.valid = '1' then
                write(l, pixel_out_rgb.xcnt);
                write(l, string'(" "));
                write(l, pixel_out_rgb.ycnt);
                write(l, string'(" "));
                write(l, to_integer(unsigned(pixel_out_rgb.red(9 downto 2))));
                write(l, string'(" "));
                write(l, to_integer(unsigned(pixel_out_rgb.green(9 downto 2))));
                write(l, string'(" "));
                write(l, to_integer(unsigned(pixel_out_rgb.blue(9 downto 2))));
                write(l, string'(" "));
                write(l, pixel_out_rgb.valid);
                write(l, string'(" "));
                write(l, pixel_out_rgb.sof);
                write(l, string'(" "));
                write(l, pixel_out_rgb.eol);
                write(l, string'(" "));
                write(l, pixel_out_rgb.eof);
                writeline(f_out, l);
            end if;
        end loop;
    end process;
end architecture;
