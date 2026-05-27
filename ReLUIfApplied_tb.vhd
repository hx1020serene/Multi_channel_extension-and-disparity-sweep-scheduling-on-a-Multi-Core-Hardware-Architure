library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity ReLUIfApplied_tb is 
end ReLUIfApplied_tb; 

architecture Behavioral of ReLUIfApplied_tb is 
    -- Component declaration 
    component ReLUIfApplied 
        generic (
            RESOLUTION : integer := 16;
            CORE_SIZE : integer := 2 
        );
        Port (  clk : in std_logic;
                applied : in std_logic; 
                input : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0); 
                output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0)); 
    end component; 
    
    -- Signal declarations 
    signal clk : std_logic := '0';
    signal applied : std_logic := '0';
    signal input : std_logic_vector(16*2-1 downto 0) := (others => '0');
    signal output : std_logic_vector(16*2-1 downto 0) := (others => '0');
    
begin 
    -- Instantiate the Unit Under Test (UUT) 
    uut: ReLUIfApplied 
        generic Map(
            RESOLUTION => 16,
            CORE_SIZE => 2
        )
        Port Map ( 
        clk => clk,
        applied => applied, 
        input => input, 
        output => output
    ); 
    
    -- Clock generation process (100 MHz clock with 10 ns period)
    clk_process: process
    begin
        -- Generate a 100 MHz clock (10 ns period)
        clk <= '1';
        wait for 5 ns;  -- 5 ns low
        clk <= '0';
        wait for 5 ns;  -- 5 ns high
    end process;
    
    -- Stimulus process 
    stimulus: process begin 
        wait for 50 ns;
        -- Test case 1 
        input <= "10101010101010100101010101010101"; 
        applied <= '1';
        wait for 10 ns; 
        
        -- Test case 2 
        input <= "10101010101010100101010101010101"; 
        applied <= '0';
        wait for 10 ns; 
    end process; 
end Behavioral;