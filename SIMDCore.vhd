library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity SIMDCore is
    generic (
        RESOLUTION : integer := 16;         -- Default value for resolution. Has to be 16 to be able to use implemented floating point operations, is just written as a generic for readability and clearness. 
        CORE_SIZE : integer := 4           -- Default value of core size, this is number of rows and number of columns of the square core
       );
    Port (  clk : in std_logic;
            input_features : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            weights : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            output_features : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0));
end SIMDCore;

architecture Behavioral of SIMDCore is
    component FloatingPointMultiplier
        Port (  A : in std_logic_vector(RESOLUTION-1 downto 0); 
                B : in std_logic_vector(RESOLUTION-1 downto 0); 
                Product : out std_logic_vector(RESOLUTION-1 downto 0)
        );
    end component;
    signal temp_result_reg : std_logic_vector(RESOLUTION*(2*CORE_SIZE-2)-1 downto 0) := (others => '0');
    signal temp_result : std_logic_vector(RESOLUTION*(2*CORE_SIZE-2)-1 downto 0) := (others => '0');
begin
    -- Instantiations of multipliers
    multipliers : for i in 0 to CORE_SIZE-1 generate
        U : FloatingPointMultiplier
            Port map (
            A => input_features((i+1)*RESOLUTION-1 downto RESOLUTION*i),
            B => weights((i+1)*RESOLUTION-1 downto RESOLUTION*i),
            Product => temp_result((i+1)*RESOLUTION-1 downto RESOLUTION*i)
            );
    end generate multipliers;
    process(clk)
    begin
        if rising_edge(clk) then
            temp_result_reg <= temp_result;
            output_features <= temp_result(RESOLUTION*CORE_SIZE-1 downto 0);
        end if;
    end process;
    
end Behavioral;