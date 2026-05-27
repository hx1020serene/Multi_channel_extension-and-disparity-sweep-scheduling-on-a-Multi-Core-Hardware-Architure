library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity FloatingPointAdder is 
    Port ( A : in std_logic_vector(15 downto 0) := "0000000000000000";  
           B : in std_logic_vector(15 downto 0) := "0000000000000000";  
           Sum : out std_logic_vector(15 downto 0) := "0000000000000000"
           ); 
end FloatingPointAdder; 

architecture Behavioral of FloatingPointAdder is 
    
begin 
    process(A, B) 
    variable exponent_Sum : std_logic_vector(4 downto 0) := (others => '0'); 
    variable mantissa_A_temp, mantissa_B_temp : std_logic_vector(11 downto 0) := (others => '0'); 
    variable mantissa_Sum_temp : std_logic_vector(11 downto 0) := (others => '0'); 
    variable sign_A, sign_B, sign_Sum : std_logic := '0';
    variable exp_diff : integer := 0;
    begin 
        -- Handle inputs of 0
        if (A(14 downto 0) = "000000000000000") then
            Sum <= B;
        else
            if (B(14 downto 0) = "000000000000000") then
                Sum <= A;
            else
                -- Handle non-zero inputs
                -- Align exponents 
                exp_diff := to_integer(unsigned(A(14 downto 10))) - to_integer(unsigned(B(14 downto 10))); 
                if (exp_diff > 0) then 
                    mantissa_B_temp := std_logic_vector(shift_right(unsigned("01" & B(9 downto 0)), exp_diff)); 
                    mantissa_A_temp := "01" & A(9 downto 0);
                    exponent_Sum := A(14 downto 10); 
                elsif (exp_diff < 0) then 
                    mantissa_A_temp := std_logic_vector(shift_right(unsigned("01" & A(9 downto 0)), -exp_diff)); 
                    mantissa_B_temp := "01" & B(9 downto 0);
                    exponent_Sum := B(14 downto 10); 
                else 
                    mantissa_A_temp := "01" & A(9 downto 0);
                    mantissa_B_temp := "01" & B(9 downto 0);
                    exponent_Sum := B(14 downto 10); -- or exponent_A, they are the same at this point 
                end if;
                
                -- Add mantissas 
                if (A(15) = B(15)) then 
                    mantissa_Sum_temp := std_logic_vector(unsigned(mantissa_A_temp) + unsigned(mantissa_B_temp)); 
                    sign_Sum := A(15); 
                    -- Normalize result 
                    if (mantissa_Sum_temp(11) = '1') then 
                        Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) + 1) & mantissa_Sum_temp(10 downto 1); 
                    else
                        Sum <= sign_Sum & exponent_Sum & mantissa_Sum_temp(9 downto 0); 
                    end if; 
                else 
                    if (unsigned(mantissa_A_temp) > unsigned(mantissa_B_temp)) then 
                        mantissa_Sum_temp := std_logic_vector(unsigned(mantissa_A_temp) - unsigned(mantissa_B_temp)); 
                        sign_Sum := A(15); 
                    else 
                        mantissa_Sum_temp := std_logic_vector(unsigned(mantissa_B_temp) - unsigned(mantissa_A_temp)); 
                        sign_Sum := B(15); 
                    end if; 
                    -- Normalize result 
                    if (mantissa_Sum_temp(10) = '1') then 
                        Sum <= sign_Sum & exponent_Sum & mantissa_Sum_temp(9 downto 0); 
                    else
                        if (mantissa_Sum_temp(9) = '1') then
                            if (unsigned(exponent_Sum) >= 1) then
                                Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 1) & mantissa_Sum_temp(8 downto 0) & "0"; 
                            else
                                Sum <= "0000000000000000";
                            end if;
                        else
                            if (mantissa_Sum_temp(8) = '1') then
                                if (unsigned(exponent_Sum) >= 2) then
                                    Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 2) & mantissa_Sum_temp(7 downto 0) & "00"; 
                                else
                                    Sum <= "0000000000000000";
                                end if;
                            else
                                if (mantissa_Sum_temp(7) = '1') then
                                    if (unsigned(exponent_Sum) >= 3) then
                                        Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 3) & mantissa_Sum_temp(6 downto 0) & "000"; 
                                    else
                                        Sum <= "0000000000000000";
                                    end if;
                                else
                                    if (mantissa_Sum_temp(6) = '1') then
                                        if (unsigned(exponent_Sum) >= 4) then
                                            Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 4) & mantissa_Sum_temp(5 downto 0) & "0000"; 
                                        else
                                            Sum <= "0000000000000000";
                                        end if;
                                    else
                                        if (mantissa_Sum_temp(5) = '1') then
                                            if (unsigned(exponent_Sum) >= 5) then
                                                Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 5) & mantissa_Sum_temp(4 downto 0) & "00000"; 
                                            else
                                                Sum <= "0000000000000000";
                                            end if;
                                        else
                                            if (mantissa_Sum_temp(4) = '1') then
                                                if (unsigned(exponent_Sum) >= 6) then
                                                    Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 6) & mantissa_Sum_temp(3 downto 0) & "000000"; 
                                                else
                                                    Sum <= "0000000000000000";
                                                end if;
                                            else
                                                if (mantissa_Sum_temp(3) = '1') then
                                                    if (unsigned(exponent_Sum) >= 7) then
                                                        Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 7) & mantissa_Sum_temp(2 downto 0) & "0000000"; 
                                                    else
                                                        Sum <= "0000000000000000";
                                                    end if;
                                                else
                                                    if (mantissa_Sum_temp(2) = '1') then
                                                        if (unsigned(exponent_Sum) >= 8) then
                                                            Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 8) & mantissa_Sum_temp(1 downto 0) & "00000000"; 
                                                        else
                                                            Sum <= "0000000000000000";
                                                        end if;
                                                    else
                                                        if (mantissa_Sum_temp(1) = '1') then
                                                            if (unsigned(exponent_Sum) >= 9) then
                                                                Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 9) & mantissa_Sum_temp(0) & "000000000"; 
                                                            else
                                                                Sum <= "0000000000000000";
                                                            end if;
                                                        else
                                                            if (mantissa_Sum_temp(0) = '1') then
                                                                if (unsigned(exponent_Sum) >= 10) then
                                                                    Sum <= sign_Sum & std_logic_vector(unsigned(exponent_Sum) - 10) & "0000000000"; 
                                                                else
                                                                    Sum <= "0000000000000000";
                                                                end if;
                                                            else
                                                                Sum <= "0000000000000000";
                                                            end if;
                                                        end if;
                                                    end if;
                                                end if;
                                            end if;
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if; 
                end if;
            end if;
        end if;
        
    end process; 
end Behavioral;
