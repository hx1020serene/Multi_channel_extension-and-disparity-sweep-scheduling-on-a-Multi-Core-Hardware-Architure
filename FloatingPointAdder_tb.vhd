library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity FloatingPointAdder_tb is 
end FloatingPointAdder_tb; 

architecture Behavioral of FloatingPointAdder_tb is 
    -- Component declaration 
    component FloatingPointAdder 
        Port (  A : in std_logic_vector(15 downto 0); 
                B : in std_logic_vector(15 downto 0); 
                Sum : out std_logic_vector(15 downto 0)); 
    end component; 
    
    -- Signal declarations 
    signal A, B, Sum : std_logic_vector(15 downto 0) := (others => '0');
    
begin 
    -- Instantiate the Unit Under Test (UUT) 
    uut: FloatingPointAdder Port Map ( 
        A => A, 
        B => B, 
        Sum => Sum 
    ); 
    
    -- Stimulus process 
    stimulus: process begin 
        wait for 50 ns;
        -- Test case 1 
        A <= "0100001000000000"; -- 3.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 10 ns; 
        
        -- Test case 2 
        A <= "0100010100000000"; -- 5.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 10 ns; 
        
        -- Test case 3 
        A <= "0100011100000000"; -- 7.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 10 ns; 
        
        -- Test case 4 
        A <= "0100001000000000"; -- 3.0 
        B <= "1100000000000000"; -- -2.0 
        wait for 10 ns; 
        
        -- Test case 5 
        A <= "1100001000000000"; -- -3.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 10 ns; 
        
        -- Test case 6 
        A <= "0100010100000000"; -- 5.0 
        B <= "1100000000000000"; -- -2.0 
        wait for 10 ns; 
        
        -- Test case 7 
        A <= "1100010100000000"; -- -5.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 10 ns; 
        
        -- Test case 8 
        A <= "0100011100000000"; -- 7.0 
        B <= "1100000000000000"; -- -2.0 
        wait for 10 ns; 
        
        -- Test case 9 
        A <= "1100011100000000"; -- -7.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 10 ns; 
        
        -- Test case 10 
        A <= "0100100010000000"; -- 9.0 
        B <= "1100000000000000"; -- -2.0 
        wait for 10 ns; 
        
        -- Test case 11 
        A <= "1100100010000000"; -- -9.0 
        B <= "0100000000000000"; -- 2.0 
        wait for 10 ns; 
        
        -- Test case 12 
        A <= "1100100010000000"; -- -9.0 
        B <= "0100100010000000"; -- 9.0 
        wait for 10 ns; 


        wait; 
    end process; 
end Behavioral;
