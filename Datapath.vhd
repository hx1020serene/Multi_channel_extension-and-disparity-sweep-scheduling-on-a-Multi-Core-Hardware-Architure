library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity Datapath is
    generic (
        RESOLUTION : integer := 16;         -- Default value for resolution. Has to be 16 to be able to use implemented floating point operations, is just written as a generic for readability and clearness. 
        CORE_SIZE : integer := 4;           -- Default value of core size, this is number of rows and number of columns of the square core
        ADDER_TREE_STAGES : integer := 2;   -- Default value of number of stages of adder tree. 
        -- Note that this code only works for CORE_SIZE == 2**ADDER_TREE_STAGES
        ADDR_FEATURES : integer := 10;      -- Default value for address size of features memory.
        ADDR_LEFT : integer := 8;           -- Default value for address size of output left path memory.
        ADDR_WEIGHTS1 : integer := 8;       -- Default value for address size of weights 1 memory.
        ADDR_WEIGHTS2 : integer := 4;       -- Default value for address size of weights 2 memory.
        ADDR_BIAS1 : integer := 3;          -- Default value for address size of bias 1 memory.
        ADDR_BIAS2 : integer := 3;          -- Default value for address size of bias 2 memory.
        ADDR_TEMP_FEATURES : integer := 6   -- Default value for address size of temporal features memory.
       );
    Port (  clk : in std_logic;
            input_data : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            input_data_weights : in std_logic_vector (RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0);
            output_data : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            applied_ReLU_before_write_back : in std_logic;
            applied_ReLU_before_SIMD : in std_logic;
            controller_MUX_ReLU : in std_logic;
            controller_MUX_features_memory : in std_logic;
            controller_MUX_main_core : in std_logic;
            controller_MUX_SIMD_core : in std_logic;
            controller_MUX_adder : in std_logic_vector (1 downto 0);
            features_memory_write_address : in std_logic_vector (ADDR_FEATURES-1 downto 0);
            features_memory_read_address : in std_logic_vector (ADDR_FEATURES-1 downto 0);
            features_memory_write_enable : in std_logic;
            left_memory_write_address : in std_logic_vector (ADDR_LEFT-1 downto 0);
            left_memory_read_address : in std_logic_vector (ADDR_LEFT-1 downto 0);
            left_memory_write_enable : in std_logic;
            weights1_memory_write_address : in std_logic_vector (ADDR_WEIGHTS1-1 downto 0);
            weights1_memory_read_address : in std_logic_vector (ADDR_WEIGHTS1-1 downto 0);
            weights1_memory_write_enable : in std_logic;
            weights2_memory_write_address : in std_logic_vector (ADDR_WEIGHTS2-1 downto 0);
            weights2_memory_read_address : in std_logic_vector (ADDR_WEIGHTS2-1 downto 0);
            weights2_memory_write_enable : in std_logic;
            bias1_memory_write_address : in std_logic_vector (ADDR_BIAS1-1 downto 0);
            bias1_memory_read_address : in std_logic_vector (ADDR_BIAS1-1 downto 0);
            bias1_memory_write_enable : in std_logic;
            bias2_memory_write_address : in std_logic_vector (ADDR_BIAS2-1 downto 0);
            bias2_memory_read_address : in std_logic_vector (ADDR_BIAS2-1 downto 0);
            bias2_memory_write_enable : in std_logic;
            temp_memory_write_address : in std_logic_vector (ADDR_TEMP_FEATURES-1 downto 0);
            temp_memory_read_address : in std_logic_vector (ADDR_TEMP_FEATURES-1 downto 0);
            temp_memory_write_enable : in std_logic
            );
end Datapath;

architecture Behavioral of Datapath is
    component ComputeCore
        generic (
            RESOLUTION : integer := 16;    
            CORE_SIZE : integer := 4;
            ADDER_TREE_STAGES : integer := 2      
        );
        Port (  clk : in std_logic;
                input_features : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                weights : in std_logic_vector (RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0);
                output_features : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0)
        );
    end component;
    component SIMDCore
        generic (
            RESOLUTION : integer := 16;    
            CORE_SIZE : integer := 4     
        );
        Port (  clk : in std_logic;
                input_features : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                weights : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                output_features : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0)
        );
    end component;
    component AdderCore
        generic (
            RESOLUTION : integer := 16;    
            CORE_SIZE : integer := 4     
        );
        Port (  clk : in std_logic;
                input1 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                input2 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0)
        );
    end component;
    component MUX_2
        generic (
            RESOLUTION : integer := 16;    
            CORE_SIZE : integer := 4     
        );
        Port (  clk : in std_logic;
                input_controller : in std_logic;
                input1 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                input2 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0)
        );
    end component;
    component MUX_3
        generic (
            RESOLUTION : integer := 16;    
            CORE_SIZE : integer := 4     
        );
        Port (  clk : in std_logic;
                input_controller : in std_logic_vector (1 downto 0);
                input1 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                input2 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                input3 : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0)
        );
    end component;
    component ReLUIfApplied
        generic (
            RESOLUTION : integer := 16;    
            CORE_SIZE : integer := 4     
        );
        Port (  clk : in std_logic;
                applied : in std_logic;
                input : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
                output : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0)
        );
    end component;
    component DualPortRAM
        generic (
            DATA_WIDTH : integer := 8;    
            ADDR_WIDTH : integer := 4     
        );
        Port (  clk         : in  std_logic;                                
                addr_a      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
                data_in_a   : in  std_logic_vector(DATA_WIDTH-1 downto 0);  
                we_a        : in  std_logic;                                
                addr_b      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  
                data_out_b  : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;
    signal input_features_main_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal output_features_main_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal weights_main_core : std_logic_vector(RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0) := (others => '0');
    signal input_data_weights_reg : std_logic_vector(RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0) := (others => '0');
    signal input_data_reg : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    --signal input_features_simd_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal output_features_simd_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal weights_simd_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal input2_adder_after_main_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal output_adder_after_main_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal input2_adder_after_simd_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal output_adder_after_simd_core : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal input_ReLU_before_write_back : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal output_ReLU_before_write_back : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal output_ReLU_before_SIMD : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal input_features_memory : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal left_memory_out : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal features_memory_out : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal weights2_memory_out : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal temp_features_memory_out : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
    signal bias1_memory_out : std_logic_vector(RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
begin
    MainCore : ComputeCore
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE,
            ADDER_TREE_STAGES => ADDER_TREE_STAGES          
        )
        Port map (
        clk => clk,
        input_features => input_features_main_core,
        weights => weights_main_core,
        output_features => output_features_main_core
        );
        
    SecondCore : SIMDCore
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input_features => output_ReLU_before_SIMD,
        weights => weights_simd_core,
        output_features => output_features_simd_core
        );
        
    AdderAfterMainCore : AdderCore
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input1 => output_features_main_core,
        input2 => input2_adder_after_main_core,
        output => output_adder_after_main_core
        );
        
    AdderAfterSIMDCore : AdderCore
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input1 => output_features_simd_core,
        input2 => input2_adder_after_simd_core,
        output => output_adder_after_simd_core
        );
        
    ReLU_before_write_back : ReLUIfApplied
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        applied => applied_ReLU_before_write_back,
        input => input_ReLU_before_write_back,
        output => output_ReLU_before_write_back
        );
        
    ReLU_before_SIMD : ReLUIfApplied
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        applied => applied_ReLU_before_SIMD,
        input => output_adder_after_main_core,
        output => output_ReLU_before_SIMD
        );
        
    MUX_before_ReLU : MUX_2
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input_controller => controller_MUX_ReLU,
        input1 => output_adder_after_simd_core,
        input2 => output_adder_after_main_core,
        output => input_ReLU_before_write_back
        );
        
    MUX_before_features_memory : MUX_2
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input_controller => controller_MUX_features_memory,
        input1 => output_ReLU_before_write_back,
        input2 => input_data,
        output => input_features_memory
        );
        
    MUX_before_main_core : MUX_2
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input_controller => controller_MUX_main_core,
        input1 => left_memory_out,
        input2 => features_memory_out,
        output => input_features_main_core
        );
        
    MUX_before_SIMD_core : MUX_2
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input_controller => controller_MUX_SIMD_core,
        input1 => left_memory_out,
        input2 => weights2_memory_out,
        output => weights_simd_core
        );
        
    MUX_before_adder : MUX_3
        generic map (
            RESOLUTION => RESOLUTION,       
            CORE_SIZE => CORE_SIZE         
        )
        Port map (
        clk => clk,
        input_controller => controller_MUX_adder,
        input1 => temp_features_memory_out,  -- when "00" => output <= input1;
        input2 => bias1_memory_out,    -- when "01" => output <= input2;
        input3 => left_memory_out,   --when "10" => output <= input3;
        output => input2_adder_after_main_core
        );
        
     Features_memory : DualPortRAM   
        generic map (
            DATA_WIDTH => RESOLUTION*CORE_SIZE,       
            ADDR_WIDTH => ADDR_FEATURES         
        )
        Port map (
        clk => clk,
        addr_a => features_memory_write_address,
        data_in_a => input_features_memory,
        we_a => features_memory_write_enable,
        addr_b => features_memory_read_address,
        data_out_b => features_memory_out
        );
        
    Output_left_memory : DualPortRAM   
        generic map (
            DATA_WIDTH => RESOLUTION*CORE_SIZE,       
            ADDR_WIDTH => ADDR_LEFT         
        )
        Port map (
        clk => clk,
        addr_a => left_memory_write_address,
        data_in_a => input_features_memory,
        we_a => left_memory_write_enable,
        addr_b => left_memory_read_address,
        data_out_b => left_memory_out
        );
        
    weights1_memory : DualPortRAM   
        generic map (
            DATA_WIDTH => RESOLUTION*CORE_SIZE*CORE_SIZE,       
            ADDR_WIDTH => ADDR_WEIGHTS1                  
        )
        Port map (
        clk => clk,
        addr_a => weights1_memory_write_address,    
        data_in_a => input_data_weights_reg,     
        we_a => weights1_memory_write_enable,     
        addr_b => weights1_memory_read_address,
        data_out_b => weights_main_core
        );
        
        
    weights2_memory : DualPortRAM   
        generic map (
            DATA_WIDTH => RESOLUTION*CORE_SIZE,       
            ADDR_WIDTH => ADDR_WEIGHTS2         
        )
        Port map (
        clk => clk,
        addr_a => weights2_memory_write_address,
        data_in_a => input_data_reg,
        we_a => weights2_memory_write_enable,
        addr_b => weights2_memory_read_address,
        data_out_b => weights2_memory_out
        );
        
    bias1_memory : DualPortRAM   
        generic map (
            DATA_WIDTH => RESOLUTION*CORE_SIZE,       
            ADDR_WIDTH => ADDR_BIAS1            
        )
        Port map (
        clk => clk,
        addr_a => bias1_memory_write_address,    
        data_in_a => input_data_reg,            
        we_a => bias1_memory_write_enable,    
        addr_b => bias1_memory_read_address,  
        data_out_b => bias1_memory_out       
        );
        
    bias2_memory : DualPortRAM   
        generic map (
            DATA_WIDTH => RESOLUTION*CORE_SIZE,       
            ADDR_WIDTH => ADDR_BIAS2         
        )
        Port map (
        clk => clk,
        addr_a => bias2_memory_write_address,
        data_in_a => input_data_reg,
        we_a => bias2_memory_write_enable,
        addr_b => bias2_memory_read_address,
        data_out_b => input2_adder_after_simd_core
        );
        
    temp_features_memory : DualPortRAM   
        generic map (
            DATA_WIDTH => RESOLUTION*CORE_SIZE,       
            ADDR_WIDTH => ADDR_TEMP_FEATURES         
        )
        Port map (
        clk => clk,
        addr_a => temp_memory_write_address,
        data_in_a => output_adder_after_main_core,
        we_a => temp_memory_write_enable,
        addr_b => temp_memory_read_address,
        data_out_b => temp_features_memory_out
        );
        
    process(clk)  
    begin  
        if rising_edge(clk) then   
            output_data <= output_ReLU_before_write_back;
            input_data_weights_reg <= input_data_weights;
            input_data_reg <= input_data;
        end if;
    end process;
    
  
    
end Behavioral;