library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSMOneLine_tb1_K3 is
end FSMOneLine_tb1_K3;

architecture Behavioral of FSMOneLine_tb1_K3 is

    component FSMOneLine
        generic (
            RESOLUTION : integer := 16;
            CORE_SIZE : integer := 4;
            ADDER_TREE_STAGES : integer := 2;
            ADDR_FEATURES : integer := 10;
            ADDR_LEFT : integer := 8;
            ADDR_WEIGHTS1 : integer := 8;
            ADDR_WEIGHTS2 : integer := 4;
            ADDR_BIAS1 : integer := 3;
            ADDR_BIAS2 : integer := 3;
            ADDR_TEMP_FEATURES : integer := 6
        );
        port (
            clk   : in std_logic;
            last_layer_output_channels : in integer := 1; 
            input_data          : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            input_data_weights : in std_logic_vector (RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0);
            output_data         : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            start : in std_logic;
            done : out std_logic;
            mode : in std_logic_vector (3 downto 0);
            nb_of_addresses_to_write : in std_logic_vector (ADDR_FEATURES - 1 downto 0);
            base_Waddress_feat      : in std_logic_vector (ADDR_FEATURES-1 downto 0);
            base_Waddress_left      : in std_logic_vector (ADDR_LEFT-1 downto 0);
            base_Waddress_weights1 : in std_logic_vector (ADDR_WEIGHTS1-1 downto 0);
            base_Waddress_weights2 : in std_logic_vector (ADDR_WEIGHTS2-1 downto 0);
            base_Waddress_bias1     : in std_logic_vector (ADDR_BIAS1-1 downto 0);
            base_Waddress_bias2     : in std_logic_vector (ADDR_BIAS2-1 downto 0);
            base_Raddress_feat      : in std_logic_vector (ADDR_FEATURES-1 downto 0);
            base_Raddress_left      : in std_logic_vector (ADDR_LEFT-1 downto 0);
            base_Raddress_weights1 : in std_logic_vector (ADDR_WEIGHTS1-1 downto 0);
            base_Raddress_weights2 : in std_logic_vector (ADDR_WEIGHTS2-1 downto 0);
            base_Raddress_bias1     : in std_logic_vector (ADDR_BIAS1-1 downto 0);
            base_Raddress_bias2     : in std_logic_vector (ADDR_BIAS2-1 downto 0);
            conv_input_channels_div_by_CORE_SIZE  : in std_logic_vector (15 downto 0);
            conv_output_channels_div_by_CORE_SIZE : in std_logic_vector (15 downto 0);
            conv_horizontal_kernel : in std_logic_vector (3 downto 0);
            conv_vertical_kernel   : in std_logic_vector (3 downto 0);
            conv_nb_of_output_pixels_row : in std_logic_vector (15 downto 0);
            conv_pointer_highest_line    : in std_logic_vector (3 downto 0);
            must_be_written_back : in std_logic_vector (1 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal input_data : std_logic_vector (63 downto 0) := (others => '0');
    signal input_data_weights : std_logic_vector (255 downto 0) := (others => '0');
    signal output_data : std_logic_vector (63 downto 0);
    signal start : std_logic := '0';
    signal done : std_logic := '0';
    signal mode : std_logic_vector (3 downto 0) := (others => '0');
    signal nb_of_addresses_to_write : std_logic_vector (9 downto 0) := (others => '0');
    
    
    signal must_be_written_back : std_logic_vector(1 downto 0) := "00"; 

    -- Addresses init
    signal base_Waddress_feat : std_logic_vector (9 downto 0) := (others => '0');
    signal base_Waddress_left : std_logic_vector (7 downto 0) := (others => '0');
    signal base_Waddress_weights1 : std_logic_vector (7 downto 0) := (others => '0');
    signal base_Waddress_weights2 : std_logic_vector (3 downto 0) := (others => '0');
    signal base_Waddress_bias1 : std_logic_vector (2 downto 0) := (others => '0');
    signal base_Waddress_bias2 : std_logic_vector (2 downto 0) := (others => '0');
    signal base_Raddress_feat : std_logic_vector (9 downto 0) := (others => '0');
    signal base_Raddress_left : std_logic_vector (7 downto 0) := (others => '0');
    signal base_Raddress_weights1 : std_logic_vector (7 downto 0) := (others => '0');
    signal base_Raddress_weights2 : std_logic_vector (3 downto 0) := (others => '0');
    signal base_Raddress_bias1 : std_logic_vector (2 downto 0) := (others => '0');
    signal base_Raddress_bias2 : std_logic_vector (2 downto 0) := (others => '0');
    
    signal conv_input_channels_div_by_CORE_SIZE : std_logic_vector (15 downto 0) := (others => '0');
    signal conv_output_channels_div_by_CORE_SIZE : std_logic_vector (15 downto 0) := (others => '0');
    signal conv_horizontal_kernel : std_logic_vector (3 downto 0) := (others => '0');
    signal conv_vertical_kernel : std_logic_vector (3 downto 0) := (others => '0');
    signal conv_nb_of_output_pixels_row : std_logic_vector (15 downto 0) := (others => '0');
    signal conv_pointer_highest_line : std_logic_vector (3 downto 0) := (others => '0');
    
    signal last_layer_output_channels : integer := 3;

begin

    uut: FSMOneLine
        generic Map(
            RESOLUTION => 16, CORE_SIZE => 4, ADDER_TREE_STAGES => 2,
            ADDR_FEATURES => 10, ADDR_LEFT => 8, ADDR_WEIGHTS1 => 8,
            ADDR_WEIGHTS2 => 4, ADDR_BIAS1 => 3, ADDR_BIAS2 => 3, ADDR_TEMP_FEATURES => 6
        )
        Port Map (
            clk => clk,
            last_layer_output_channels => last_layer_output_channels,
            input_data => input_data,
            input_data_weights => input_data_weights,
            output_data => output_data,
            start => start, done => done, mode => mode,
            nb_of_addresses_to_write => nb_of_addresses_to_write,
            base_Waddress_feat => base_Waddress_feat,
            base_Waddress_left => base_Waddress_left,
            base_Waddress_weights1 => base_Waddress_weights1,
            base_Waddress_weights2 => base_Waddress_weights2,
            base_Waddress_bias1 => base_Waddress_bias1,
            base_Waddress_bias2 => base_Waddress_bias2,
            base_Raddress_feat => base_Raddress_feat,
            base_Raddress_left => base_Raddress_left,
            base_Raddress_weights1 => base_Raddress_weights1,
            base_Raddress_weights2 => base_Raddress_weights2,
            base_Raddress_bias1 => base_Raddress_bias1,
            base_Raddress_bias2 => base_Raddress_bias2,
            conv_input_channels_div_by_CORE_SIZE => conv_input_channels_div_by_CORE_SIZE,
            conv_output_channels_div_by_CORE_SIZE => conv_output_channels_div_by_CORE_SIZE,
            conv_horizontal_kernel => conv_horizontal_kernel,
            conv_vertical_kernel => conv_vertical_kernel,
            conv_nb_of_output_pixels_row => conv_nb_of_output_pixels_row,
            conv_pointer_highest_line => conv_pointer_highest_line,
            must_be_written_back => must_be_written_back 
        );

    -- 100 MHz Clock
    clk_process: process
    begin
        clk <= '1'; wait for 5 ns;
        clk <= '0'; wait for 5 ns;
    end process;

    stimulus: process begin
        wait for 55 ns;
        mode <= "0000";
        start <= '0';
        must_be_written_back <= "00"; 
        wait for 30 ns;

        --------------------------------------------------------------------------------
        -- (1) Write Features Memory (Mode 0001)
        --------------------------------------------------------------------------------
        mode <= "0001";
        nb_of_addresses_to_write <= "0000010000"; 
        
        for i in 0 to 15 loop
            if i = 0 then start <= '1'; else start <= '0'; end if;
            input_data <= x"3C003C003C003C00"; -- 1.0
            wait for 10 ns;
        end loop;
        
        start <= '0'; 
        wait until done = '1'; 
        wait for 30 ns; 

    
                   --------------------------------------------------------------------------------
            -- (2) Write Weights Memory 2 (Mode 0100) - COMPLETE FIX
            --------------------------------------------------------------------------------
            mode <= "0100"; 
            nb_of_addresses_to_write <= "0000000110"; -- 6 addresses
            
            for i in 0 to 5 loop
                if i = 0 then start <= '1'; else start <= '0'; end if;
                
                if (i = 0) or (i = 1) then        
                    input_data <= x"3C003C003C003C00"; -- 1.0
                elsif (i = 2) or (i = 3) then    
                    input_data <= x"4000400040004000"; -- 2.0
                elsif (i = 4) or (i = 5) then    
                    input_data <= x"3800380038003800"; -- 0.5
                end if;
                wait for 10 ns;
            end loop;
            
            start <= '0';
            wait until done = '1';
            wait for 30 ns;



 
        mode <= "0110"; 
        nb_of_addresses_to_write <= "0000000011"; 

        for i in 0 to 2 loop
            if i = 0 then start <= '1'; else start <= '0'; end if;
            if i = 0 then
                input_data <= x"3C003C003C003C00"; -- 1.0
            elsif i = 1 then
                input_data <= x"4000400040004000"; -- 2.0
            else
                input_data <= x"0000000000000000"; -- 0.0
            end if;
            wait for 10 ns;
        end loop;
        
        start <= '0';
        wait until done = '1';
        wait for 30 ns;
        
    
        mode <= "0011"; 
        nb_of_addresses_to_write <= "0000001100"; 

        for i in 0 to 11 loop
            if i = 0 then start <= '1'; else start <= '0'; end if;
         
            input_data_weights <= x"3C003C003C003C003C003C003C003C003C003C003C003C003C003C003C003C00"; 
            wait for 10 ns;
        end loop;

        start <= '0';
        wait until done = '1';
        wait for 30 ns;
        
       
        mode <= "0101"; 
        nb_of_addresses_to_write <= "0000000011";

        for i in 0 to 2 loop
            if i = 0 then start <= '1'; else start <= '0'; end if;
            input_data <= (others => '0'); -- ÉèÎª 0
            wait for 10 ns;
        end loop;
        
        start <= '0';
        wait until done = '1';
        wait for 30 ns;

        --------------------------------------------------------------------------------
        -- (4) EXECUTE Mode 1011 (SIMD Execution)
        --------------------------------------------------------------------------------
        mode <= "1011";
        must_be_written_back <= "00"; 
        
        conv_input_channels_div_by_CORE_SIZE  <= x"0001"; 
        conv_output_channels_div_by_CORE_SIZE <= x"0001"; 
        conv_horizontal_kernel <= "0001"; 
        conv_vertical_kernel   <= "0001";
        conv_nb_of_output_pixels_row <= x"0008"; 
        conv_pointer_highest_line    <= "0000";
        
        last_layer_output_channels <= 3;

        start <= '1';
        wait for 10 ns;
        start <= '0';

        wait for 3000 ns;
        wait;
    end process;

end Behavioral;