--------------------------------------------------------------------------------
-- End-to-End Testbench with NON-UNIFORM Features
--
-- Purpose: Verify that different disparities produce DIFFERENT results.
-- With uniform features, d=1 == d=2 (same sliding window data).
-- With non-uniform features, d=0 /= d=1 /= d=2, proving the sliding
-- window actually reads from different positions.
--
-- Feature layout (FL', 10 pixels, C/N=2, interleaved):
--   pixel 0 = 1.0  (addr 0,1)    pixel 5 = 6.0  (addr 10,11)
--   pixel 1 = 2.0  (addr 2,3)    pixel 6 = 7.0  (addr 12,13)
--   pixel 2 = 3.0  (addr 4,5)    pixel 7 = 8.0  (addr 14,15)
--   pixel 3 = 4.0  (addr 6,7)    pixel 8 = 9.0  (addr 16,17)
--   pixel 4 = 5.0  (addr 8,9)    pixel 9 = 10.0 (addr 18,19)
--
-- Sliding window reads (FX=3, OX=6, input width = OX+FX-1 = 8 pixels):
--   d=0: pixels 0-7  = {1, 2, 3, 4, 5, 6, 7, 8}
--   d=1: pixels 1-8  = {2, 3, 4, 5, 6, 7, 8, 9}
--   d=2: pixels 2-9  = {3, 4, 5, 6, 7, 8, 9, 10}
-- All three windows contain DIFFERENT data -> DIFFERENT conv results.
--
-- Verification criteria:
--   1. All outputs non-zero (data path works)
--   2. d=0 output /= d=1 output (different windows -> different results)
--   3. d=1 output /= d=2 output (same reasoning)
--   This was IMPOSSIBLE to verify with uniform features.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity FSMOneLine_tb_e2e_nonuniform is
end FSMOneLine_tb_e2e_nonuniform;

architecture Behavioral of FSMOneLine_tb_e2e_nonuniform is

    constant RESOLUTION : integer := 16;
    constant CORE_SIZE  : integer := 4;
    constant ADDER_TREE_STAGES : integer := 2;
    constant ADDR_FEATURES : integer := 10;
    constant ADDR_LEFT     : integer := 8;
    constant ADDR_WEIGHTS1 : integer := 8;
    constant ADDR_WEIGHTS2 : integer := 4;
    constant ADDR_BIAS1    : integer := 3;
    constant ADDR_BIAS2    : integer := 3;
    constant ADDR_TEMP     : integer := 6;

    constant CLK_PERIOD : time := 10 ns;

    -- Conv_A parameters
    constant FX_A      : integer := 3;
    constant FY_A      : integer := 1;
    constant C_A_DIV_N : integer := 2;
    constant K_A_DIV_N : integer := 1;
    constant OX_A      : integer := 6;
    constant D_MAX     : integer := 3;

    -- Conv_B parameters (Mode 1011, 3x1 kernel)
    constant FX_B      : integer := 3;
    constant FY_B      : integer := 1;
    constant C_B_DIV_N : integer := K_A_DIV_N;
    constant K_B_DIV_N : integer := 1;
    constant OX_B      : integer := OX_A - FX_B + 1;  -- = 4

    -- Conv_C parameters
    constant K_C       : integer := 1;

    -- Derived sizes
    constant FLP_WIDTH  : integer := OX_A + FX_A - 1 + D_MAX - 1;  -- = 10
    constant FLP_ADDRS  : integer := FLP_WIDTH * C_A_DIV_N;         -- = 20
    constant W_A_ADDRS  : integer := FX_A * C_A_DIV_N * K_A_DIV_N;  -- = 6
    constant LEFT_ADDRS : integer := K_A_DIV_N * OX_A;              -- = 6
    constant WB_BASE    : integer := FLP_ADDRS;                     -- = 20
    constant RESULT_SIZE: integer := K_A_DIV_N * OX_A;              -- = 6
    constant W_B_1011_ADDRS : integer := FX_B * FY_B * C_B_DIV_N * K_B_DIV_N;  -- = 3
    constant W_C_1011_ADDRS : integer := C_B_DIV_N;  -- = 1

    -- ================================================================
    -- NON-UNIFORM FEATURE DATA
    -- 10 pixels, each pixel stored at 2 addresses (C/N=2)
    -- pixel i has value (i+1).0 in fp16
    -- ================================================================
    type feat_array_t is array (0 to FLP_ADDRS-1) of integer;
    constant FEAT_VALS : feat_array_t := (
        -- pixel 0: 1.0     pixel 1: 2.0     pixel 2: 3.0
        16#3C00#, 16#3C00#, 16#4000#, 16#4000#, 16#4200#, 16#4200#,
        -- pixel 3: 4.0     pixel 4: 5.0     pixel 5: 6.0
        16#4400#, 16#4400#, 16#4500#, 16#4500#, 16#4600#, 16#4600#,
        -- pixel 6: 7.0     pixel 7: 8.0     pixel 8: 9.0
        16#4700#, 16#4700#, 16#4800#, 16#4800#, 16#4880#, 16#4880#,
        -- pixel 9: 10.0
        16#4900#, 16#4900#
    );

    -- left_partial: 1.0 to 6.0 (same as before)
    type left_array_t is array (0 to 5) of integer;
    constant LEFT_VALS : left_array_t := (
        16#3C00#, 16#4000#, 16#4200#, 16#4400#, 16#4500#, 16#4600#
    );

    -- Weights: 1.0 so conv = sum of features (easy to reason about)
    constant W_A_R_VAL : integer := 16#3C00#;  -- 1.0
    constant W_B_VAL   : integer := 16#3C00#;  -- 1.0
    constant W_C_VAL   : integer := 16#3C00#;  -- 1.0

    -- DUT signals
    signal clk        : std_logic := '0';
    signal start      : std_logic := '0';
    signal done       : std_logic := '0';
    signal mode       : std_logic_vector(3 downto 0) := "0000";
    signal input_data : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal input_data_weights : std_logic_vector(RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0) := (others => '0');
    signal output_data : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0);

    signal nb_of_addresses_to_write : std_logic_vector(ADDR_FEATURES-1 downto 0) := (others => '0');
    signal base_Waddress_feat    : std_logic_vector(ADDR_FEATURES-1 downto 0) := (others => '0');
    signal base_Waddress_left    : std_logic_vector(ADDR_LEFT-1 downto 0) := (others => '0');
    signal base_Waddress_weights1: std_logic_vector(ADDR_WEIGHTS1-1 downto 0) := (others => '0');
    signal base_Waddress_weights2: std_logic_vector(ADDR_WEIGHTS2-1 downto 0) := (others => '0');
    signal base_Waddress_bias1   : std_logic_vector(ADDR_BIAS1-1 downto 0) := (others => '0');
    signal base_Waddress_bias2   : std_logic_vector(ADDR_BIAS2-1 downto 0) := (others => '0');
    signal base_Raddress_feat    : std_logic_vector(ADDR_FEATURES-1 downto 0) := (others => '0');
    signal base_Raddress_left    : std_logic_vector(ADDR_LEFT-1 downto 0) := (others => '0');
    signal base_Raddress_weights1: std_logic_vector(ADDR_WEIGHTS1-1 downto 0) := (others => '0');
    signal base_Raddress_weights2: std_logic_vector(ADDR_WEIGHTS2-1 downto 0) := (others => '0');
    signal base_Raddress_bias1   : std_logic_vector(ADDR_BIAS1-1 downto 0) := (others => '0');
    signal base_Raddress_bias2   : std_logic_vector(ADDR_BIAS2-1 downto 0) := (others => '0');
    signal conv_input_channels_div_by_CORE_SIZE  : std_logic_vector(15 downto 0) := (others => '0');
    signal conv_output_channels_div_by_CORE_SIZE : std_logic_vector(15 downto 0) := (others => '0');
    signal conv_horizontal_kernel : std_logic_vector(3 downto 0) := (others => '0');
    signal conv_vertical_kernel   : std_logic_vector(3 downto 0) := (others => '0');
    signal conv_nb_of_output_pixels_row : std_logic_vector(15 downto 0) := (others => '0');
    signal conv_pointer_highest_line : std_logic_vector(3 downto 0) := (others => '0');
    signal must_be_written_back : std_logic_vector(1 downto 0) := "00";
    signal last_layer_output_channels : integer range 1 to CORE_SIZE := 1;
    signal conv_disparity_max : std_logic_vector(15 downto 0) := x"0001";

    -- Helper functions
    function make_data(val : integer) return std_logic_vector is
        variable result : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    begin
        for i in 0 to CORE_SIZE-1 loop
            result((i+1)*RESOLUTION-1 downto i*RESOLUTION) :=
                std_logic_vector(to_unsigned(val, RESOLUTION));
        end loop;
        return result;
    end function;

    function make_weights(val : integer) return std_logic_vector is
        variable result : std_logic_vector(RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0) := (others => '0');
    begin
        for i in 0 to CORE_SIZE*CORE_SIZE-1 loop
            result((i+1)*RESOLUTION-1 downto i*RESOLUTION) :=
                std_logic_vector(to_unsigned(val, RESOLUTION));
        end loop;
        return result;
    end function;

    function get_ch0(data : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(data(RESOLUTION-1 downto 0)));
    end function;

begin

    clk <= not clk after CLK_PERIOD / 2;

    DUT: entity work.FSMOneLine
        generic map (
            RESOLUTION => RESOLUTION,
            CORE_SIZE  => CORE_SIZE,
            ADDER_TREE_STAGES => ADDER_TREE_STAGES,
            ADDR_FEATURES => ADDR_FEATURES,
            ADDR_LEFT     => ADDR_LEFT,
            ADDR_WEIGHTS1 => ADDR_WEIGHTS1,
            ADDR_WEIGHTS2 => ADDR_WEIGHTS2,
            ADDR_BIAS1    => ADDR_BIAS1,
            ADDR_BIAS2    => ADDR_BIAS2,
            ADDR_TEMP_FEATURES => ADDR_TEMP
        )
        port map (
            clk => clk,
            input_data => input_data,
            input_data_weights => input_data_weights,
            output_data => output_data,
            start => start,
            done => done,
            mode => mode,
            last_layer_output_channels => last_layer_output_channels,
            nb_of_addresses_to_write => nb_of_addresses_to_write,
            base_Waddress_feat     => base_Waddress_feat,
            base_Waddress_left     => base_Waddress_left,
            base_Waddress_weights1 => base_Waddress_weights1,
            base_Waddress_weights2 => base_Waddress_weights2,
            base_Waddress_bias1    => base_Waddress_bias1,
            base_Waddress_bias2    => base_Waddress_bias2,
            base_Raddress_feat     => base_Raddress_feat,
            base_Raddress_left     => base_Raddress_left,
            base_Raddress_weights1 => base_Raddress_weights1,
            base_Raddress_weights2 => base_Raddress_weights2,
            base_Raddress_bias1    => base_Raddress_bias1,
            base_Raddress_bias2    => base_Raddress_bias2,
            conv_input_channels_div_by_CORE_SIZE  => conv_input_channels_div_by_CORE_SIZE,
            conv_output_channels_div_by_CORE_SIZE => conv_output_channels_div_by_CORE_SIZE,
            conv_horizontal_kernel     => conv_horizontal_kernel,
            conv_vertical_kernel       => conv_vertical_kernel,
            conv_nb_of_output_pixels_row => conv_nb_of_output_pixels_row,
            conv_pointer_highest_line  => conv_pointer_highest_line,
            must_be_written_back       => must_be_written_back,
            conv_disparity_max         => conv_disparity_max
        );

    stim_proc: process
        variable L : line;
        variable val_ch0 : integer;
        -- Store outputs for comparison
        type score_array_t is array (0 to D_MAX-1, 0 to OX_B-1) of integer;
        variable scores : score_array_t := (others => (others => 0));
        variable all_nonzero : boolean := true;
        variable d0_ne_d1 : boolean := false;
        variable d1_ne_d2 : boolean := false;
    begin
        -- ============================================================
        -- PHASE 0+1: Load all input data
        -- ============================================================
        write(L, string'("============================================"));
        writeline(output, L);
        write(L, string'("  NON-UNIFORM FEATURES END-TO-END TEST"));
        writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);

        -- Step 1: Load W_A_right = 1.0 into Weights1
        write(L, string'("  1. W_A_right (1.0) -> Weights1"));
        writeline(output, L);
        mode <= "0011";
        base_Waddress_weights1 <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(W_A_ADDRS, ADDR_FEATURES));
        input_data_weights <= make_weights(W_A_R_VAL);
        start <= '1'; wait for CLK_PERIOD; start <= '0';
        wait until done = '1'; wait for CLK_PERIOD;
        write(L, string'("      Done.")); writeline(output, L);

        -- Step 2: Load zero bias
        write(L, string'("  2. Zero bias -> Bias1"));
        writeline(output, L);
        mode <= "0101";
        base_Waddress_bias1 <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(1, ADDR_FEATURES));
        input_data <= (others => '0');
        start <= '1'; wait for CLK_PERIOD; start <= '0';
        wait until done = '1'; wait for CLK_PERIOD;
        write(L, string'("      Done.")); writeline(output, L);

        -- Step 3: Load NON-UNIFORM FL' (per-pixel distinct values)
        write(L, string'("  3. FL' -> Features Memory [0..19] (NON-UNIFORM!)"));
        writeline(output, L);
        write(L, string'("     pixel 0=1.0, 1=2.0, 2=3.0, ..., 9=10.0"));
        writeline(output, L);
        mode <= "0001";
        base_Waddress_feat <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(FLP_ADDRS, ADDR_FEATURES));
        for i in 0 to FLP_ADDRS-1 loop
            input_data <= make_data(FEAT_VALS(i));
            if (i = 0) then
                start <= '1'; wait for CLK_PERIOD; start <= '0';
            end if;
            wait for CLK_PERIOD;
        end loop;
        wait until done = '1'; wait for CLK_PERIOD;
        write(L, string'("      Done.")); writeline(output, L);

        -- Step 4: Load left_partial
        write(L, string'("  4. left_partial -> Left Memory (1.0..6.0)"));
        writeline(output, L);
        mode <= "0010";
        base_Waddress_left <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(LEFT_ADDRS, ADDR_FEATURES));
        for i in 0 to LEFT_ADDRS-1 loop
            input_data <= make_data(LEFT_VALS(i));
            if (i = 0) then
                start <= '1'; wait for CLK_PERIOD; start <= '0';
            end if;
            wait for CLK_PERIOD;
        end loop;
        wait until done = '1'; wait for CLK_PERIOD;
        write(L, string'("      Done.")); writeline(output, L);

        write(L, string'("")); writeline(output, L);
        write(L, string'("  Sliding window will read:"));
        writeline(output, L);
        write(L, string'("    d=0: pixels 0-7  = {1,2,3,4,5,6,7,8}"));
        writeline(output, L);
        write(L, string'("    d=1: pixels 1-8  = {2,3,4,5,6,7,8,9}"));
        writeline(output, L);
        write(L, string'("    d=2: pixels 2-9  = {3,4,5,6,7,8,9,10}"));
        writeline(output, L);
        write(L, string'("  All DIFFERENT -> outputs MUST differ!"));
        writeline(output, L);

        -- ============================================================
        -- PHASE 2a: Mode 1110 wb="10"
        -- ============================================================
        write(L, string'("")); writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);
        write(L, string'("  PHASE 2a: Mode 1110 (D_max=3, wb=10)"));
        writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);

        mode <= "1110";
        must_be_written_back <= "10";
        conv_horizontal_kernel <= std_logic_vector(to_unsigned(FX_A, 4));
        conv_vertical_kernel   <= std_logic_vector(to_unsigned(FY_A, 4));
        conv_input_channels_div_by_CORE_SIZE  <= std_logic_vector(to_unsigned(C_A_DIV_N, 16));
        conv_output_channels_div_by_CORE_SIZE <= std_logic_vector(to_unsigned(K_A_DIV_N, 16));
        conv_nb_of_output_pixels_row <= std_logic_vector(to_unsigned(OX_A, 16));
        conv_pointer_highest_line <= (others => '0');
        conv_disparity_max <= std_logic_vector(to_unsigned(D_MAX, 16));
        base_Raddress_feat     <= (others => '0');
        base_Raddress_left     <= (others => '0');
        base_Raddress_weights1 <= (others => '0');
        base_Raddress_bias1    <= (others => '0');
        base_Waddress_feat <= std_logic_vector(to_unsigned(WB_BASE, ADDR_FEATURES));

        start <= '1'; wait for CLK_PERIOD; start <= '0';
        wait until done = '1'; wait for CLK_PERIOD;
        write(L, string'("  Phase 2a DONE.")); writeline(output, L);

        -- ============================================================
        -- PHASE 2b: Mode 1011 (Conv_B 3x1 + Conv_C 1x1)
        -- ============================================================
        write(L, string'("")); writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);
        write(L, string'("  PHASE 2b: Mode 1011 (Conv_B 3x1 + Conv_C 1x1)"));
        writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);

        -- Load W_B (3x1, value 1.0)
        mode <= "0011";
        base_Waddress_weights1 <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(W_B_1011_ADDRS, ADDR_FEATURES));
        input_data_weights <= make_weights(W_B_VAL);
        start <= '1'; wait for CLK_PERIOD; start <= '0';
        wait until done = '1'; wait for CLK_PERIOD;

        -- Load bias_B = 0
        mode <= "0101";
        base_Waddress_bias1 <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(1, ADDR_FEATURES));
        input_data <= (others => '0');
        start <= '1'; wait for CLK_PERIOD; start <= '0';
        wait until done = '1'; wait for CLK_PERIOD;

        -- Load W_C (1x1, value 1.0)
        mode <= "0100";
        base_Waddress_weights2 <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(W_C_1011_ADDRS, ADDR_FEATURES));
        input_data <= make_data(W_C_VAL);
        start <= '1'; wait for CLK_PERIOD; start <= '0';
        wait until done = '1'; wait for CLK_PERIOD;

        -- Load bias_C = 0
        mode <= "0110";
        base_Waddress_bias2 <= (others => '0');
        nb_of_addresses_to_write <= std_logic_vector(to_unsigned(1, ADDR_FEATURES));
        input_data <= (others => '0');
        start <= '1'; wait for CLK_PERIOD; start <= '0';
        wait until done = '1'; wait for CLK_PERIOD;

        write(L, string'("  Weights loaded (W_B 3x1, W_C 1x1, biases=0)"));
        writeline(output, L);

        -- Run Mode 1011 for each disparity and store results
        for d_idx in 0 to D_MAX-1 loop
            write(L, string'("")); writeline(output, L);
            write(L, string'("  --- d="));
            write(L, d_idx);
            write(L, string'(" (reading from addr "));
            write(L, WB_BASE + d_idx * RESULT_SIZE);
            write(L, string'(") ---"));
            writeline(output, L);

            mode <= "1011";
            must_be_written_back <= "00";
            conv_horizontal_kernel <= std_logic_vector(to_unsigned(FX_B, 4));
            conv_vertical_kernel   <= std_logic_vector(to_unsigned(FY_B, 4));
            conv_input_channels_div_by_CORE_SIZE  <= std_logic_vector(to_unsigned(C_B_DIV_N, 16));
            conv_output_channels_div_by_CORE_SIZE <= std_logic_vector(to_unsigned(K_B_DIV_N, 16));
            conv_nb_of_output_pixels_row <= std_logic_vector(to_unsigned(OX_B, 16));
            conv_pointer_highest_line <= (others => '0');
            last_layer_output_channels <= K_C;
            base_Raddress_feat <= std_logic_vector(to_unsigned(
                WB_BASE + d_idx * RESULT_SIZE, ADDR_FEATURES));
            base_Raddress_weights1 <= (others => '0');
            base_Raddress_bias1    <= (others => '0');
            base_Raddress_weights2 <= (others => '0');
            base_Raddress_bias2    <= (others => '0');

            start <= '1'; wait for CLK_PERIOD; start <= '0';
            wait until done = '1';
            wait for CLK_PERIOD/2;

            for i in 0 to OX_B-1 loop
                val_ch0 := get_ch0(output_data);
                scores(d_idx, i) := val_ch0;

                write(L, string'("    score["));
                write(L, i);
                write(L, string'("] = 0x"));
                hwrite(L, std_logic_vector(to_unsigned(val_ch0, 16)));
                write(L, string'(" ("));
                write(L, val_ch0);
                write(L, string'(")"));
                if val_ch0 = 0 then
                    write(L, string'(" *** ZERO ***"));
                    all_nonzero := false;
                end if;
                writeline(output, L);
                wait for CLK_PERIOD;
            end loop;

            wait for CLK_PERIOD * 5;
        end loop;

        -- ============================================================
        -- COMPARISON: d=0 vs d=1 vs d=2
        -- ============================================================
        write(L, string'("")); writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);
        write(L, string'("  COMPARISON ACROSS DISPARITIES"));
        writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);

        -- Check d=0 vs d=1
        d0_ne_d1 := false;
        for i in 0 to OX_B-1 loop
            if scores(0, i) /= scores(1, i) then
                d0_ne_d1 := true;
            end if;
        end loop;

        write(L, string'("  d=0 vs d=1: "));
        if d0_ne_d1 then
            write(L, string'("DIFFERENT (expected with non-uniform features)"));
        else
            write(L, string'("IDENTICAL *** UNEXPECTED - sliding window may be broken ***"));
        end if;
        writeline(output, L);

        -- Show per-pixel comparison
        for i in 0 to OX_B-1 loop
            write(L, string'("    pixel "));
            write(L, i);
            write(L, string'(": d0=0x"));
            hwrite(L, std_logic_vector(to_unsigned(scores(0, i), 16)));
            write(L, string'("  d1=0x"));
            hwrite(L, std_logic_vector(to_unsigned(scores(1, i), 16)));
            if scores(0, i) /= scores(1, i) then
                write(L, string'("  DIFF"));
            else
                write(L, string'("  same"));
            end if;
            writeline(output, L);
        end loop;

        -- Check d=1 vs d=2
        d1_ne_d2 := false;
        for i in 0 to OX_B-1 loop
            if scores(1, i) /= scores(2, i) then
                d1_ne_d2 := true;
            end if;
        end loop;

        write(L, string'("")); writeline(output, L);
        write(L, string'("  d=1 vs d=2: "));
        if d1_ne_d2 then
            write(L, string'("DIFFERENT (expected with non-uniform features)"));
        else
            write(L, string'("IDENTICAL *** UNEXPECTED - sliding window may be broken ***"));
        end if;
        writeline(output, L);

        for i in 0 to OX_B-1 loop
            write(L, string'("    pixel "));
            write(L, i);
            write(L, string'(": d1=0x"));
            hwrite(L, std_logic_vector(to_unsigned(scores(1, i), 16)));
            write(L, string'("  d2=0x"));
            hwrite(L, std_logic_vector(to_unsigned(scores(2, i), 16)));
            if scores(1, i) /= scores(2, i) then
                write(L, string'("  DIFF"));
            else
                write(L, string'("  same"));
            end if;
            writeline(output, L);
        end loop;

        -- ============================================================
        -- FINAL VERDICT
        -- ============================================================
        write(L, string'("")); writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);
        write(L, string'("  FINAL VERDICT"));
        writeline(output, L);
        write(L, string'("============================================"));
        writeline(output, L);

        write(L, string'("  All outputs non-zero: "));
        if all_nonzero then
            write(L, string'("PASS"));
        else
            write(L, string'("FAIL"));
        end if;
        writeline(output, L);

        write(L, string'("  d=0 /= d=1 (sliding window): "));
        if d0_ne_d1 then
            write(L, string'("PASS"));
        else
            write(L, string'("FAIL"));
        end if;
        writeline(output, L);

        write(L, string'("  d=1 /= d=2 (sliding window): "));
        if d1_ne_d2 then
            write(L, string'("PASS"));
        else
            write(L, string'("FAIL"));
        end if;
        writeline(output, L);

        write(L, string'("")); writeline(output, L);
        if all_nonzero and d0_ne_d1 and d1_ne_d2 then
            write(L, string'("  >>> ALL PASS: Non-uniform features verified! <<<"));
            writeline(output, L);
            write(L, string'("  >>> Sliding window reads DIFFERENT data per disparity <<<"));
        else
            write(L, string'("  >>> SOME TESTS FAILED - check above <<<"));
        end if;
        writeline(output, L);

        write(L, string'("============================================"));
        writeline(output, L);

        wait for CLK_PERIOD * 10;
        assert false report "Simulation finished" severity failure;
        wait;
    end process;

end Behavioral;