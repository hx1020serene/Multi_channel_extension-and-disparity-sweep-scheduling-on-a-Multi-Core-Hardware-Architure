library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity FloatingPointMultiplier_tb is 
end FloatingPointMultiplier_tb; 

architecture Behavioral of FloatingPointMultiplier_tb is 
    -- Component declaration 
    component FloatingPointMultiplier 
        Port (  A : in std_logic_vector(15 downto 0); 
                B : in std_logic_vector(15 downto 0); 
                Product : out std_logic_vector(15 downto 0)); 
    end component; 
    
    -- Signal declarations 
    signal A, B, Product : std_logic_vector(15 downto 0) := (others => '0');
    
begin 
    -- Instantiate the Unit Under Test (UUT) 
    uut: FloatingPointMultiplier Port Map ( 
        A => A, 
        B => B, 
        Product => Product 
    ); 
    
    -- Stimulus process 
    stimulus: process begin 
        wait for 50 ns;
        -- Test case 1 
        A <= "0100001000000000"; -- 3.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 50 ns; 
       
        -- Test case 2 
        A <= "1100001000000000"; -- -3.0 
        B <= "0100001000000000"; -- 3.0 
        wait for 50 ns; 
        

    end process; 
end Behavioral;