library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity MUX_3 is
    generic (
        RESOLUTION : integer := 16;         -- Default value for resolution. Has to be 16 to be able to use implemented floating point operations, is just written as a generic for readability and clearness. 
        CORE_SIZE : integer := 4            -- Default value of core size, this is number of rows and number of columns of the square core
       );
    Port (  clk : in std_logic;
            input_controller : in std_logic_vector (1 downto 0);
                                            -- "00" for first input
                                            -- "01" for second input
                                            -- "10" for third input
            input1 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            input2 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            input3 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0));
end MUX_3;

architecture Behavioral of MUX_3 is 
begin 
    process(clk) 
    begin 
        if rising_edge(clk) then 
            case input_controller is
                when "00" => output <= input1;
                when "01" => output <= input2;
                when "10" => output <= input3;
                when others => output <= (others => '0'); 
            end case;
        end if; 
    end process;
    
end Behavioral;