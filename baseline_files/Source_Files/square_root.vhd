library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity square_root is
   generic (
      data_width : integer := 32
   );
   port (
      clk          : in  std_logic;
      rst_n        : in  std_logic;
      radicand_in : in  std_logic_vector(data_width-1 downto 0);
      root_out    : out std_logic_vector((data_width/2)-1 downto 0)
   );
end entity square_root;

architecture square_root_pipe_rtl of square_root is

   constant ALU_WIDTH      : integer := (data_width / 2) + 2;
   constant PIPE_STAGES    : integer := data_width / 2;
   constant ALU_HEAD_WIDTH : integer := 3;

   type t_input_pipe_array is
      array (PIPE_STAGES-1 downto 0) of unsigned(data_width-1 downto 0);

   type t_alu_pipe_array is
      array (PIPE_STAGES-1 downto 0) of unsigned(ALU_WIDTH-1 downto 0);

   type t_root_pipe_array is
      array (PIPE_STAGES-1 downto 0) of unsigned((data_width/2)-1 downto 0);

   signal input_pipe     : t_input_pipe_array;
   signal remainder_pipe : t_input_pipe_array;
   signal root_pipe      : t_root_pipe_array;
   signal op_subtract    : std_logic_vector(PIPE_STAGES-1 downto 0);

begin

   ---------------------------------------------------------------------------
   -- Pipelined non‑restoring square‑root computation
   ---------------------------------------------------------------------------
   sqrt_p : process (clk, rst_n)
      variable alu_remainder_in : t_alu_pipe_array;
      variable alu_root_in      : t_alu_pipe_array;
      variable alu_result       : t_alu_pipe_array;
   begin
      if rst_n = '0' then
         input_pipe        <= (others => (others => '0'));
         remainder_pipe    <= (others => (others => '0'));
         root_pipe         <= (others => (others => '0'));
         op_subtract       <= (others => '0');

         alu_remainder_in  := (others => (others => '0'));
         alu_root_in       := (others => (others => '0'));
         alu_result        := (others => (others => '0'));

      elsif rising_edge(clk) then

         --------------------------------------------------------------------
         -- Stage 0: Initialize remainder and trial root
         --------------------------------------------------------------------
         alu_remainder_in(0) := (others => '0');
         alu_remainder_in(0)(1 downto 0) :=
            unsigned(radicand_in(data_width-1 downto data_width-2));

         alu_root_in(0) := (others => '0');
         alu_root_in(0)(0) := '1';

         alu_result(0) := alu_remainder_in(0) - alu_root_in(0);

         input_pipe(0) <= shift_left(unsigned(radicand_in), 2);

         remainder_pipe(0) <= (others => '0');
         remainder_pipe(0)(data_width-1 downto data_width-2) <=
            alu_result(0)(1 downto 0);

         root_pipe(0) <= (others => '0');
         root_pipe(0)(0) <= not alu_result(0)(2);

         op_subtract(0) <= not alu_result(0)(2);

         --------------------------------------------------------------------
         -- Remaining pipeline stages
         --------------------------------------------------------------------
         for i in 1 to PIPE_STAGES-1 loop

            alu_remainder_in(i) := (others => '0');
            alu_remainder_in(i)(ALU_HEAD_WIDTH + i - 1 downto 2) :=
               remainder_pipe(i-1)(data_width - i downto data_width - (2*i));
            alu_remainder_in(i)(1 downto 0) :=
               input_pipe(i-1)(data_width-1 downto data_width-2);

            alu_root_in(i) := (others => '0');
            alu_root_in(i)(ALU_HEAD_WIDTH + i - 2 downto 2) :=
               root_pipe(i-1)(i-1 downto 0);
            alu_root_in(i)(1) := not root_pipe(i-1)(0);
            alu_root_in(i)(0) := '1';

            if op_subtract(i-1) = '1' then
               alu_result(i) := alu_remainder_in(i) - alu_root_in(i);
            else
               alu_result(i) := alu_remainder_in(i) + alu_root_in(i);
            end if;

            input_pipe(i) <= shift_left(input_pipe(i-1), 2);

            remainder_pipe(i) <= (others => '0');
            remainder_pipe(i)(data_width-i-1 downto data_width-(2*i)-2) <=
               alu_result(i)(i+1 downto 0);

            root_pipe(i) <= shift_left(root_pipe(i-1), 1);
            root_pipe(i)(0) <= not alu_result(i)(i+2);

            op_subtract(i) <= not alu_result(i)(i+2);

         end loop;
      end if;
   end process sqrt_p;

   ---------------------------------------------------------------------------
   -- Final square‑root output
   ---------------------------------------------------------------------------
   root_out <= std_logic_vector(root_pipe(PIPE_STAGES-1));

end architecture square_root_pipe_rtl;
