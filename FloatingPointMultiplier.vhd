library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity FloatingPointMultiplier is 
    Port ( A : in std_logic_vector(15 downto 0):= "0000000000000000"; 
           B : in std_logic_vector(15 downto 0):= "0000000000000000"; 
           Product : out std_logic_vector(15 downto 0) := "0000000000000000"); 
end FloatingPointMultiplier; 

architecture Behavioral of FloatingPointMultiplier is 
    
begin 
    process(A, B) 
    variable  mantissa_Product_temp : std_logic_vector(21 downto 0) := (others => '0');
    variable  exponent_Product_temp : std_logic_vector(4 downto 0) := (others => '0');
    variable  exp_temp : integer := 0; 
    variable  sign_Product : std_logic := '0';
    variable  exponent_Product : std_logic_vector(4 downto 0) := (others => '0'); 
    variable  mantissa_Product : std_logic_vector(9 downto 0) := (others => '0');
    begin 
        -- Handle inputs of 0
        if (A(14 downto 0) = "000000000000000") then
            Product <= "0000000000000000";
        else
            if (B(14 downto 0) = "000000000000000") then
                Product <= "0000000000000000";
            else
                -- Handle non-zero inputs
                -- Multiply mantissas 
                mantissa_Product_temp := std_logic_vector(unsigned("1" & A(9 downto 0)) * unsigned("1" & B(9 downto 0))); 
                
                -- Add exponents (subtracting the bias) 
                exp_temp := to_integer(unsigned(A(14 downto 10))) + to_integer(unsigned(B(14 downto 10))) - 15; 
                exponent_Product_temp := std_logic_vector(to_unsigned(exp_temp, 5)); 
                
                -- Determine the sign of the product 
                sign_Product := A(15) xor B(15); 
                
                -- Normalize the product 
                if (mantissa_Product_temp(21) = '1') then 
                    mantissa_Product := mantissa_Product_temp(20 downto 11);
                    exponent_Product := std_logic_vector(unsigned(exponent_Product_temp) + 1); 
                else
                    mantissa_Product := mantissa_Product_temp(19 downto 10); 
                    exponent_Product := exponent_Product_temp; 
                end if; 
                
                -- Assemble the result 
                Product <= sign_Product & exponent_Product & mantissa_Product;
            end if;
        end if;
    
    end process; 
end Behavioral;