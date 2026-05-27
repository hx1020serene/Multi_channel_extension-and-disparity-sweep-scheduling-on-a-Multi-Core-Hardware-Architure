library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity ReLUIfApplied is
    generic (
        RESOLUTION : integer := 16;         -- Default value for resolution. Has to be 16 to be able to use implemented floating point operations, is just written as a generic for readability and clearness. 
        CORE_SIZE : integer := 4            -- Default value of core size, this is number of rows and number of columns of the square core
       );
    Port (  clk : in std_logic;
            applied : in std_logic;
            input : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0));
end ReLUIfApplied;

architecture Behavioral of ReLUifApplied is 
    --signal temp_out : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0'); 
begin 
    --process(clk) 
    --begin 
   --     if rising_edge(clk) then 
    --        for i in 0 to CORE_SIZE-1 loop 
    --            if (input(RESOLUTION*(i+1)-1) = '1' and applied = '1') then 
    --                temp_out(RESOLUTION*(i+1)-1 downto RESOLUTION*i) <= (others => '0'); 
    --            elsif (input(RESOLUTION*(i+1)-1) = '0' or applied = '0') then 
    --                temp_out(RESOLUTION*(i+1)-1 downto RESOLUTION*i) <= input(RESOLUTION*(i+1)-1 downto RESOLUTION*i); 
    --            end if; 
    --        end loop; 
    --        output <= temp_out;
    --    end if; 
    --end process;
    process(clk)
    begin
        if rising_edge(clk) then
            for i in 0 to CORE_SIZE-1 loop
                if (input(RESOLUTION*(i+1)-1) = '1' and applied = '1') then
                    output(RESOLUTION*(i+1)-1 downto RESOLUTION*i) <= (others => '0');
                else
                    output(RESOLUTION*(i+1)-1 downto RESOLUTION*i) <= input(RESOLUTION*(i+1)-1 downto RESOLUTION*i);
                end if;
            end loop;
        end if;
    end process;
    
end Behavioral;