library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rgb_cluster_pkg.all;

entity tb_rgb_cluster_core is
end entity;

architecture sim of tb_rgb_cluster_core is
    constant CLK_PERIOD : time := 10 ns;
    constant PIPE_LATENCY : integer := 6; -- adjust after measuring actual DUT latency if needed

    signal clk  : std_logic := '0';
    signal rst_n: std_logic := '0';

    signal rgb_streaming_pixels : channel := (
        valid => '0', sof => '0', eol => '0', eof => '0',
        xcnt => 0, ycnt => 0,
        red => (others => '0'), green => (others => '0'), blue => (others => '0')
    );

    signal centroid : int_rgb := (red => 0, green => 0, blue => 0);
    signal euclidean_distance_threshold : integer;

    type int_array_t is array (natural range <>) of integer;
    signal expected_pipe : int_array_t(0 to PIPE_LATENCY) := (others => 0);
    signal valid_pipe    : std_logic_vector(0 to PIPE_LATENCY) := (others => '0');

    function abs_i(v : integer) return integer is
    begin
        if v < 0 then
            return -v;
        else
            return v;
        end if;
    end function;

    function isqrt_floor(n : integer) return integer is
        variable r : integer := 0;
    begin
        while (r + 1) * (r + 1) <= n loop
            r := r + 1;
        end loop;
        return r;
    end function;

    function ref_dist(
        r8 : integer; g8 : integer; b8 : integer;
        kr : integer; kg : integer; kb : integer
    ) return integer is
        variable dr, dg, db : integer;
    begin
        dr := abs_i(r8 - kr);
        dg := abs_i(g8 - kg);
        db := abs_i(b8 - kb);
        return isqrt_floor(dr*dr + dg*dg + db*db);
    end function;

    procedure drive_pixel(
        constant x  : in integer;
        constant y  : in integer;
        constant r8 : in integer;
        constant g8 : in integer;
        constant b8 : in integer;
        constant kr : in integer;
        constant kg : in integer;
        constant kb : in integer
    ) is
    begin
        wait until rising_edge(clk);
        rgb_streaming_pixels.valid <= '1';
        rgb_streaming_pixels.sof   <= '0';
        rgb_streaming_pixels.eol   <= '0';
        rgb_streaming_pixels.eof   <= '0';
        rgb_streaming_pixels.xcnt  <= x;
        rgb_streaming_pixels.ycnt  <= y;
        rgb_streaming_pixels.red   <= std_logic_vector(to_unsigned(r8 * 4, 10));
        rgb_streaming_pixels.green <= std_logic_vector(to_unsigned(g8 * 4, 10));
        rgb_streaming_pixels.blue  <= std_logic_vector(to_unsigned(b8 * 4, 10));
        centroid.red   <= kr;
        centroid.green <= kg;
        centroid.blue  <= kb;

        expected_pipe(0) <= ref_dist(r8, g8, b8, kr, kg, kb);
        valid_pipe(0)    <= '1';
        for i in 1 to PIPE_LATENCY loop
            expected_pipe(i) <= expected_pipe(i-1);
            valid_pipe(i)    <= valid_pipe(i-1);
        end loop;
    end procedure;

begin
    clk <= not clk after CLK_PERIOD/2;

    dut : entity work.rgb_cluster_core
        generic map (
            data_width => 8
        )
        port map (
            clk                          => clk,
            rst_n                        => rst_n,
            rgb_streaming_pixels         => rgb_streaming_pixels,
            k_lut_rgb_max_mid_min_indexs => centroid,
            euclidean_distance_threshold => euclidean_distance_threshold
        );

    stim_p : process
    begin
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        wait until rising_edge(clk);
        rst_n <= '1';

        drive_pixel(0, 0, 0,   0,   0,   0,   0,   0);
        drive_pixel(1, 0, 255, 0,   0,   255, 0,   0);
        drive_pixel(2, 0, 255, 255, 255, 0,   0,   0);
        drive_pixel(3, 0, 120, 45,  32,  100, 40,  30);
        drive_pixel(4, 0, 17,  199, 83,  20,  180, 70);
        drive_pixel(5, 0, 80,  80,  80,  90,  70,  60);

        -- random-like directed sweep
        for i in 0 to 63 loop
            drive_pixel(
                i, 1,
                (i * 37) mod 256,
                (i * 73) mod 256,
                (i * 19) mod 256,
                (i * 29) mod 256,
                (i * 11) mod 256,
                (i * 53) mod 256
            );
        end loop;

        -- drain
        for i in 0 to PIPE_LATENCY + 3 loop
            wait until rising_edge(clk);
            rgb_streaming_pixels.valid <= '0';
            valid_pipe(0) <= '0';
            for j in 1 to PIPE_LATENCY loop
                expected_pipe(j) <= expected_pipe(j-1);
                valid_pipe(j)    <= valid_pipe(j-1);
            end loop;
        end loop;

        report "tb_rgb_cluster_core completed" severity note;
        wait;
    end process;

    check_p : process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '1' and valid_pipe(PIPE_LATENCY) = '1' then
                assert euclidean_distance_threshold = expected_pipe(PIPE_LATENCY)
                    report "rgb_cluster_core mismatch: got=" & integer'image(euclidean_distance_threshold) &
                           " exp=" & integer'image(expected_pipe(PIPE_LATENCY))
                    severity error;
            end if;
        end if;
    end process;
end architecture;
