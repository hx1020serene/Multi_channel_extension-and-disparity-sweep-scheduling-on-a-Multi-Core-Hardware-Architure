library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity MUX_2 is
    generic (
        RESOLUTION : integer := 16;         -- Default value for resolution. Has to be 16 to be able to use implemented floating point operations, is just written as a generic for readability and clearness. 
        CORE_SIZE : integer := 4            -- Default value of core size, this is number of rows and number of columns of the square core
       );
    Port (  clk : in std_logic;
            input_controller : in std_logic;
                                            -- "0" for first input
                                            -- "1" for second input
            input1 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            input2 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0));
end MUX_2;

architecture Behavioral of MUX_2 is 
begin 
    process(clk) 
    begin 
        if rising_edge(clk) then 
            case input_controller is
                when '0' => output <= input1;
                when '1' => output <= input2;
                when others => output <= (others => '0'); 
            end case;
        end if; 
    end process;
    
end Behavioral;