----------------------------------------------------------------------------------
-- Company      : SA611982
-- Author       : Sakinder Ali
-- Create Date  : 04282019 [04-28-2019]
-- Devices      : FPGA-CPLD-ZYNQ-SOC
-- SA611982-MJ  : 3.1
-- SA611982-MN  : 1
-- Description  : [SA611982-3.1-1][03/07/2026]
-- Notes        : Pipelined Non-Restoring Square Root Unit
--                Process-labeled, fully commented version
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity square_root is
    generic (
        data_width : integer := 32
    );
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        radicand_in : in  std_logic_vector(data_width - 1 downto 0);
        root_out    : out std_logic_vector((data_width/2) - 1 downto 0)
    );
end entity square_root;

architecture square_root_pipe_rtl of square_root is

    -- ALU width = half-width + 2 bits for non-restoring headroom
    constant ALU_WIDTH      : integer := (data_width / 2) + 2;

    -- Number of pipeline stages = half the input width
    constant PIPE_STAGES    : integer := data_width / 2;

    -- Width of ALU head (sign + trial bit region)
    constant ALU_HEAD_WIDTH : integer := 3;

    -- Pipeline arrays
    type t_input_pipe_array  is array (PIPE_STAGES - 1 downto 0) of unsigned(data_width - 1 downto 0);
    type t_alu_pipe_array    is array (PIPE_STAGES - 1 downto 0) of unsigned(ALU_WIDTH - 1 downto 0);
    type t_root_pipe_array   is array (PIPE_STAGES - 1 downto 0) of unsigned((data_width/2) - 1 downto 0);

    -- Pipeline signals
    signal input_pipe    : t_input_pipe_array;   -- Shifted radicand bits per stage
    signal remainder_pipe: t_input_pipe_array;   -- Remainder accumulation per stage
    signal root_pipe     : t_root_pipe_array;    -- Partial root per stage
    signal op_subtract   : std_logic_vector(PIPE_STAGES - 1 downto 0); -- ALU op: 1=sub, 0=add

begin

    ----------------------------------------------------------------------------------
    -- PROCESS: sqrt_p
    -- PURPOSE: Implements pipelined non-restoring square root algorithm.
    --          Each stage performs:
    --              - Trial subtraction/addition
    --              - Remainder update
    --              - Root bit decision
    --              - Radicand shift for next stage
    ----------------------------------------------------------------------------------
    sqrt_p : process (clk, rst_n)
        -- ALU variable arrays (local to process)
        variable alu_remainder_in : t_alu_pipe_array; -- ALU operand A
        variable alu_root_in      : t_alu_pipe_array; -- ALU operand B (trial root)
        variable alu_result       : t_alu_pipe_array; -- ALU output
    begin

        if rst_n = '0' then
            -- Reset all pipeline registers
            input_pipe      <= (others => (others => '0'));
            remainder_pipe  <= (others => (others => '0'));
            root_pipe       <= (others => (others => '0'));
            op_subtract     <= (others => '0');

            -- Reset ALU variables
            alu_remainder_in := (others => (others => '0'));
            alu_root_in      := (others => (others => '0'));
            alu_result       := (others => (others => '0'));

        elsif rising_edge(clk) then

            ----------------------------------------------------------------------
            -- STAGE 0: Initialize ALU operands from MSBs of radicand
            ----------------------------------------------------------------------
            alu_remainder_in(0) := (others => '0');
            alu_remainder_in(0)(1 downto 0) :=
                unsigned(radicand_in(data_width - 1 downto data_width - 2)); -- Top 2 bits

            alu_root_in(0) := (others => '0');
            alu_root_in(0)(0) := '1'; -- Trial root = 1

            -- Trial subtraction
            alu_result(0) := alu_remainder_in(0) - alu_root_in(0);

            -- Pipeline register updates
            input_pipe(0) <= shift_left(unsigned(radicand_in), 2); -- Shift radicand by 2 bits
            remainder_pipe(0) <= (others => '0');
            remainder_pipe(0)(data_width - 1 downto data_width - 2) :=
                alu_result(0)(1 downto 0); -- New remainder bits

            root_pipe(0) <= (others => '0');
            root_pipe(0)(0) <= not alu_result(0)(2); -- Root bit decision

            op_subtract(0) <= not alu_result(0)(2); -- Next stage op

            ----------------------------------------------------------------------
            -- PIPELINE STAGES 1 → N-1
            ----------------------------------------------------------------------
            for i in 1 to PIPE_STAGES - 1 loop

                -- Build ALU remainder operand
                alu_remainder_in(i) := (others => '0');
                alu_remainder_in(i)(ALU_HEAD_WIDTH + i - 1 downto 2) :=
                    remainder_pipe(i - 1)(data_width - i downto data_width - (2 * i));
                alu_remainder_in(i)(1 downto 0) :=
                    input_pipe(i - 1)(data_width - 1 downto data_width - 2);

                -- Build ALU trial root operand
                alu_root_in(i) := (others => '0');
                alu_root_in(i)(ALU_HEAD_WIDTH + i - 2 downto 2) :=
                    root_pipe(i - 1)(i - 1 downto 0);
                alu_root_in(i)(1) := not root_pipe(i - 1)(0);
                alu_root_in(i)(0) := '1';

                -- ALU operation: subtract or add
                if op_subtract(i - 1) = '1' then
                    alu_result(i) := alu_remainder_in(i) - alu_root_in(i);
                else
                    alu_result(i) := alu_remainder_in(i) + alu_root_in(i);
                end if;

                -- Update pipeline registers
                input_pipe(i) <= shift_left(input_pipe(i - 1), 2);

                remainder_pipe(i) <= (others => '0');
                remainder_pipe(i)(data_width - i - 1 downto data_width - (2 * i) - 2) :=
                    alu_result(i)(i + 1 downto 0);

                root_pipe(i) <= shift_left(root_pipe(i - 1), 1);
                root_pipe(i)(0) <= not alu_result(i)(i + 2);

                op_subtract(i) <= not alu_result(i)(i + 2);

            end loop;

        end if;
    end process sqrt_p;

    -- Final output from last pipeline stage
    root_out <= std_logic_vector(root_pipe(PIPE_STAGES - 1));

end architecture square_root_pipe_rtl;
