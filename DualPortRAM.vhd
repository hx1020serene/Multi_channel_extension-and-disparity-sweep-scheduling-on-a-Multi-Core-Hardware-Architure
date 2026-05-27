library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-- The purpose of this RAM memory is to always write with the A port, and read with the B port. 
entity DualPortRAM is
    Generic (
        DATA_WIDTH : integer := 8;  
        ADDR_WIDTH : integer := 4   
    );
    Port (
        clk         : in  std_logic;                                
        addr_a      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Adress port A (write)
        data_in_a   : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- Data input port A
        we_a        : in  std_logic;                                -- Write enable port A
        addr_b      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Adress port B (read)
        data_out_b  : out std_logic_vector(DATA_WIDTH-1 downto 0)   -- Data output port B
    );
end DualPortRAM;

architecture Behavioral of DualPortRAM is
    type RAM_Array is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal RAM : RAM_Array := (others => (others => '0')); -- Init RAM met nullen
begin
    -- Write on port A 
    process(clk)
    begin
        if rising_edge(clk) then  
            if we_a = '1' then    
                RAM(to_integer(unsigned(addr_a))) <= data_in_a; -- Write data
                
            end if;
        end if;
    end process;

    -- Read on port B  
    process(clk)
    begin
        if rising_edge(clk) then
            data_out_b <= RAM(to_integer(unsigned(addr_b))); -- Read data
        end if;   
    end process;
end Behavioral;
