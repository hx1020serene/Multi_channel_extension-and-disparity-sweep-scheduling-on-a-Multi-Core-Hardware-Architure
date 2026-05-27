library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity ComputeCore is
    generic (
        RESOLUTION : integer := 16;         -- Default value for resolution. Has to be 16 to be able to use implemented floating point operations, is just written as a generic for readability and clearness. 
        CORE_SIZE : integer := 4;           -- Default value of core size, this is number of rows and number of columns of the square core
        ADDER_TREE_STAGES : integer := 2    -- Default value of number of stages of adder tree. 
        -- Note that this code only works for CORE_SIZE == 2**ADDER_TREE_STAGES
       );
    Port (  clk : in std_logic;
            input_features : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            weights : in std_logic_vector (RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0);
            output_features : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0));
end ComputeCore;

architecture Behavioral of ComputeCore is
    component FloatingPointMultiplier
        Port (  A : in std_logic_vector(RESOLUTION-1 downto 0); 
                B : in std_logic_vector(RESOLUTION-1 downto 0); 
                Product : out std_logic_vector(RESOLUTION-1 downto 0)
        );
    end component;
    component FloatingPointAdder
        Port (  A : in std_logic_vector(RESOLUTION-1 downto 0); 
                B : in std_logic_vector(RESOLUTION-1 downto 0); 
                Sum : out std_logic_vector(RESOLUTION-1 downto 0)
        );
    end component;
    signal temp_result_reg : std_logic_vector(RESOLUTION*CORE_SIZE*(2*CORE_SIZE-2)-1 downto 0) := (others => '0');
    signal temp_result : std_logic_vector(RESOLUTION*CORE_SIZE*(2*CORE_SIZE-2)-1 downto 0) := (others => '0');
    signal temp_out : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
begin
    -- Instantiations of multipliers
    multipliers : for i in 0 to CORE_SIZE*CORE_SIZE-1 generate
        U : FloatingPointMultiplier
            Port map (
            A => input_features((1+(i/CORE_SIZE))*RESOLUTION-1 downto RESOLUTION*(i/CORE_SIZE)),
            B => weights((i+1)*RESOLUTION-1 downto RESOLUTION*i),
            Product => temp_result((i+1)*RESOLUTION-1 downto RESOLUTION*i)
            );
    end generate multipliers;
    -- Instantiations of adders
    adders : for i in 0 to CORE_SIZE-1 generate
        adders_per_column : for j in 1 to ADDER_TREE_STAGES-1 generate
            adders_per_stage_in_given_column : for z in 0 to (2**(ADDER_TREE_STAGES-j))-1 generate
                V : FloatingPointAdder
                    Port map (
                    A => temp_result_reg(RESOLUTION*(CORE_SIZE*(2*z+2**(ADDER_TREE_STAGES+1)-2**(ADDER_TREE_STAGES-j+2))+i+1)-1 downto RESOLUTION*(CORE_SIZE*(2*z+2**(ADDER_TREE_STAGES+1)-2**(ADDER_TREE_STAGES-j+2))+i)),
                    B => temp_result_reg(RESOLUTION*(CORE_SIZE*(2*z+1+2**(ADDER_TREE_STAGES+1)-2**(ADDER_TREE_STAGES-j+2))+i+1)-1 downto RESOLUTION*(CORE_SIZE*(2*z+1+2**(ADDER_TREE_STAGES+1)-2**(ADDER_TREE_STAGES-j+2))+i)),
                    Sum => temp_result(RESOLUTION*(CORE_SIZE*(z+2**(ADDER_TREE_STAGES+1)-2**(ADDER_TREE_STAGES-j+1))+i+1)-1 downto RESOLUTION*(CORE_SIZE*(z+2**(ADDER_TREE_STAGES+1)-2**(ADDER_TREE_STAGES-j+1))+i))
                    );
                end generate adders_per_stage_in_given_column;
        end generate adders_per_column;
    end generate adders;
    -- Instantiations of adders to output
    adders_out : for i in 0 to CORE_SIZE-1 generate
        V : FloatingPointAdder
            Port map (
            A => temp_result_reg(RESOLUTION*(CORE_SIZE*(2**(ADDER_TREE_STAGES+1)-4)+i+1)-1 downto RESOLUTION*(CORE_SIZE*(2**(ADDER_TREE_STAGES+1)-4)+i)),
            B => temp_result_reg(RESOLUTION*(CORE_SIZE*(1+2**(ADDER_TREE_STAGES+1)-4)+i+1)-1 downto RESOLUTION*(CORE_SIZE*(1+2**(ADDER_TREE_STAGES+1)-4)+i)),
            Sum => temp_out(RESOLUTION*(i+1)-1 downto RESOLUTION*i)
            );
    end generate adders_out;
    process(clk)
    begin
        if rising_edge(clk) then
            temp_result_reg <= temp_result;
            output_features <= temp_out;
        end if;
    end process;
    
end Behavioral;