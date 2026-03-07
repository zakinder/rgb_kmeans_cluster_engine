library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_square_root is
end entity;

architecture sim of tb_square_root is
    constant DATA_WIDTH : integer := 32;
    constant CLK_PERIOD : time    := 10 ns;
    constant PIPE_LATENCY : integer := DATA_WIDTH / 2;

    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal radicand_in : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal root_out    : std_logic_vector((DATA_WIDTH/2)-1 downto 0);

    type int_array_t is array (natural range <>) of integer;
    signal expected_pipe : int_array_t(0 to PIPE_LATENCY) := (others => 0);

    function isqrt_floor(n : integer) return integer is
        variable r : integer := 0;
    begin
        while (r + 1) * (r + 1) <= n loop
            r := r + 1;
        end loop;
        return r;
    end function;

begin
    clk <= not clk after CLK_PERIOD/2;

    dut : entity work.square_root
        generic map (
            data_width => DATA_WIDTH
        )
        port map (
            clk         => clk,
            rst_n       => rst_n,
            radicand_in => radicand_in,
            root_out    => root_out
        );

    stim_p : process
        variable sample : integer;
    begin
        rst_n <= '0';
        wait for 5 * CLK_PERIOD;
        wait until rising_edge(clk);
        rst_n <= '1';

        -- Exhaustive useful range for RGB Euclidean distance: 0 .. 195075
        for sample in 0 to 195075 loop
            wait until rising_edge(clk);
            radicand_in <= std_logic_vector(to_unsigned(sample, DATA_WIDTH));
            expected_pipe(0) <= isqrt_floor(sample);
            for i in 1 to PIPE_LATENCY loop
                expected_pipe(i) <= expected_pipe(i-1);
            end loop;
        end loop;

        -- Drain pipeline
        for i in 0 to PIPE_LATENCY + 2 loop
            wait until rising_edge(clk);
            radicand_in <= (others => '0');
            expected_pipe(0) <= 0;
            for j in 1 to PIPE_LATENCY loop
                expected_pipe(j) <= expected_pipe(j-1);
            end loop;
        end loop;

        report "tb_square_root completed" severity note;
        wait;
    end process;

    check_p : process(clk)
        variable got_int : integer;
    begin
        if rising_edge(clk) then
            if rst_n = '1' then
                got_int := to_integer(unsigned(root_out));
                assert got_int = expected_pipe(PIPE_LATENCY)
                    report "square_root mismatch: got=" & integer'image(got_int) &
                           " exp=" & integer'image(expected_pipe(PIPE_LATENCY))
                    severity error;
            end if;
        end if;
    end process;
end architecture;
