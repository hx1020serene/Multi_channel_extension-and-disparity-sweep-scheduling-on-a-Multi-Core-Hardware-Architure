library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 

entity FSMOneLine is
    generic (
        RESOLUTION : integer := 16;         
        CORE_SIZE : integer := 4;           
        ADDER_TREE_STAGES : integer := 2;   
        ADDR_FEATURES : integer := 10;      
        ADDR_LEFT : integer := 8;           
        ADDR_WEIGHTS1 : integer := 8;       
        ADDR_WEIGHTS2 : integer := 4;       
        ADDR_BIAS1 : integer := 3;          
        ADDR_BIAS2 : integer := 3;          
        ADDR_TEMP_FEATURES : integer := 6   
       );
    Port (  clk : in std_logic;
            input_data : in std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0) := (others => '0');
            input_data_weights : in std_logic_vector (RESOLUTION*CORE_SIZE*CORE_SIZE-1 downto 0) := (others => '0');
            output_data : out std_logic_vector (RESOLUTION*CORE_SIZE-1 downto 0);
            start : in std_logic;
            done : out std_logic;
            mode : in std_logic_vector (3 downto 0) := (others => '0');
            -- 0000 do nothing  
            -- 0001 for writing features memory
            -- 0010 for writing output left path memory
            -- 0011 for writing weights memory 1
            -- 0100 for writing weights memory 2
            -- 0101 for writing bias memory 1
            -- 0110 for writing bias memory 2
            -- 0111 for convolutional layer 
            -- 1000 for convolutional layer + concatenation 
            -- 1001 for convolutional layer + addition of stereo paths
            -- 1010 for convolutional layer + multiplication of stereo paths
            -- 1011 for final convolutional layers
            last_layer_output_channels : in integer range 1 to CORE_SIZE := 1;

            nb_of_addresses_to_write : in std_logic_vector (ADDR_FEATURES - 1 downto 0) := (others => '0');
            base_Waddress_feat : in std_logic_vector (ADDR_FEATURES-1 downto 0) := (others => '0');
            base_Waddress_left : in std_logic_vector (ADDR_LEFT-1 downto 0) := (others => '0');
            base_Waddress_weights1 : in std_logic_vector (ADDR_WEIGHTS1-1 downto 0) := (others => '0');
            base_Waddress_weights2 : in std_logic_vector (ADDR_WEIGHTS2-1 downto 0) := (others => '0');
            base_Waddress_bias1 : in std_logic_vector (ADDR_BIAS1-1 downto 0) := (others => '0');
            base_Waddress_bias2 : in std_logic_vector (ADDR_BIAS2-1 downto 0) := (others => '0');
            base_Raddress_feat : in std_logic_vector (ADDR_FEATURES-1 downto 0) := (others => '0');
            base_Raddress_left : in std_logic_vector (ADDR_LEFT-1 downto 0) := (others => '0');
            base_Raddress_weights1 : in std_logic_vector (ADDR_WEIGHTS1-1 downto 0) := (others => '0');
            base_Raddress_weights2 : in std_logic_vector (ADDR_WEIGHTS2-1 downto 0) := (others => '0');
            base_Raddress_bias1 : in std_logic_vector (ADDR_BIAS1-1 downto 0) := (others => '0');
            base_Raddress_bias2 : in std_logic_vector (ADDR_BIAS2-1 downto 0) := (others => '0');
            conv_input_channels_div_by_CORE_SIZE : in std_logic_vector (15 downto 0) := (others => '0');
            conv_output_channels_div_by_CORE_SIZE : in std_logic_vector (15 downto 0) := (others => '0');
            conv_horizontal_kernel : in std_logic_vector (3 downto 0) := (others => '0');
            conv_vertical_kernel : in std_logic_vector (3 downto 0) := (others => '0');
            conv_nb_of_output_pixels_row : in std_logic_vector (15 downto 0) := (others => '0');
            conv_pointer_highest_line : in std_logic_vector (3 downto 0) := (others => '0');
            must_be_written_back : in std_logic_vector (1 downto 0) := (others => '0')
            -- 00 for not writing back --> sending to external
            -- 01 for writing back to output left path memory
            -- 10 for writing back to features memory
            );
end FSMOneLine;

architecture Behavioral of FSMOneLine is
    component Datapath
        generic (
            RESOLUTION : integer := 16;     
            CORE_SIZE : integer := 4;
            ADDER_TREE_STAGES : integer := 2;
            ADDR_FEATURES : integer := 10;      
            ADDR_LEFT : integer := 8;           
            ADDR_WEIGHTS1 : integer := 8;       
            ADDR_WEIGHTS2 : integer := 4;       
            ADDR_BIAS1 : integer := 3;          
            ADDR_BIAS2 : integer := 3;          
            ADDR_TEMP_FEATURES : integer := 6        
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
    end component;
    signal applied_ReLU_before_write_back : std_logic := '0';
    signal applied_ReLU_before_SIMD : std_logic := '0';
    signal controller_MUX_ReLU : std_logic := '0';
    signal controller_MUX_features_memory : std_logic := '0';
    signal controller_MUX_main_core : std_logic := '0';
    signal controller_MUX_SIMD_core : std_logic := '0';
    signal controller_MUX_adder : std_logic_vector (1 downto 0) := (others => '0');
    signal features_memory_write_address : std_logic_vector (ADDR_FEATURES-1 downto 0) := (others => '0');
    signal features_memory_read_address : std_logic_vector (ADDR_FEATURES-1 downto 0) := (others => '0');
    signal features_memory_write_enable : std_logic := '0';
    signal left_memory_write_address : std_logic_vector (ADDR_LEFT-1 downto 0) := (others => '0');
    signal left_memory_read_address : std_logic_vector (ADDR_LEFT-1 downto 0) := (others => '0');
    signal left_memory_write_enable : std_logic := '0';
    signal weights1_memory_write_address : std_logic_vector (ADDR_WEIGHTS1-1 downto 0) := (others => '0');
    signal weights1_memory_read_address : std_logic_vector (ADDR_WEIGHTS1-1 downto 0) := (others => '0');
    signal weights1_memory_write_enable : std_logic := '0';
    signal weights2_memory_write_address : std_logic_vector (ADDR_WEIGHTS2-1 downto 0) := (others => '0');
    signal weights2_memory_read_address : std_logic_vector (ADDR_WEIGHTS2-1 downto 0) := (others => '0');
    signal weights2_memory_write_enable : std_logic := '0';
    signal bias1_memory_write_address : std_logic_vector (ADDR_BIAS1-1 downto 0) := (others => '0');
    signal bias1_memory_read_address : std_logic_vector (ADDR_BIAS1-1 downto 0) := (others => '0');
    signal bias1_memory_write_enable : std_logic := '0';
    signal bias2_memory_write_address : std_logic_vector (ADDR_BIAS2-1 downto 0) := (others => '0');
    signal bias2_memory_read_address : std_logic_vector (ADDR_BIAS2-1 downto 0) := (others => '0');
    signal bias2_memory_write_enable : std_logic := '0';
    signal temp_memory_write_address : std_logic_vector (ADDR_TEMP_FEATURES-1 downto 0) := (others => '0');
    signal temp_memory_read_address : std_logic_vector (ADDR_TEMP_FEATURES-1 downto 0) := (others => '0');
    signal temp_memory_write_enable : std_logic := '0';
    signal temp_inputchannel_loop : std_logic_vector (15 downto 0) := (others => '0');
    signal temp_outputchannel_loop : std_logic_vector (15 downto 0) := (others => '0');
    signal temp_horizontalkernel_loop : std_logic_vector (3 downto 0) := (others => '0');
    signal temp_verticalkernel_loop : std_logic_vector (3 downto 0) := (others => '0');
    signal temp_horizontalpixel_loop : std_logic_vector (15 downto 0) := (others => '0');
    signal counter : std_logic_vector (15 downto 0) := (others => '0');
    signal current_outputchannel_loop : std_logic_vector (15 downto 0) := (others => '0');
    signal line_done_1011 : std_logic := '0';  

    signal eff_conv_output_channels_div_by_CS : std_logic_vector(15 downto 0) := (others => '0');
    signal K_eff_for_1011 : std_logic_vector(15 downto 0) := (others => '0');

    constant COMPUTE_CORE_LATENCY : integer := 5;
    constant SIMD_CORE_LATENCY    : integer := 8;

begin

    Main_datapath : Datapath
        generic map (
            RESOLUTION => RESOLUTION,        
            CORE_SIZE  => CORE_SIZE,
            ADDER_TREE_STAGES => ADDER_TREE_STAGES,
            ADDR_FEATURES => ADDR_FEATURES,
            ADDR_LEFT     => ADDR_LEFT,
            ADDR_WEIGHTS1 => ADDR_WEIGHTS1,
            ADDR_WEIGHTS2 => ADDR_WEIGHTS2,
            ADDR_BIAS1    => ADDR_BIAS1,
            ADDR_BIAS2    => ADDR_BIAS2,
            ADDR_TEMP_FEATURES => ADDR_TEMP_FEATURES
        )
        port map (
            clk => clk,
            input_data         => input_data,
            input_data_weights => input_data_weights,
            output_data        => output_data,

            applied_ReLU_before_write_back => applied_ReLU_before_write_back,
            applied_ReLU_before_SIMD       => applied_ReLU_before_SIMD,

            controller_MUX_ReLU            => controller_MUX_ReLU,
            controller_MUX_features_memory => controller_MUX_features_memory,
            controller_MUX_main_core       => controller_MUX_main_core,
            controller_MUX_SIMD_core       => controller_MUX_SIMD_core,
            controller_MUX_adder           => controller_MUX_adder,

            features_memory_write_address => features_memory_write_address,
            features_memory_read_address  => features_memory_read_address,
            features_memory_write_enable  => features_memory_write_enable,

            left_memory_write_address => left_memory_write_address,
            left_memory_read_address  => left_memory_read_address,
            left_memory_write_enable  => left_memory_write_enable,

            weights1_memory_write_address => weights1_memory_write_address,
            weights1_memory_read_address  => weights1_memory_read_address,
            weights1_memory_write_enable  => weights1_memory_write_enable,

            weights2_memory_write_address => weights2_memory_write_address,
            weights2_memory_read_address  => weights2_memory_read_address,
            weights2_memory_write_enable  => weights2_memory_write_enable,

            bias1_memory_write_address => bias1_memory_write_address,
            bias1_memory_read_address  => bias1_memory_read_address,
            bias1_memory_write_enable  => bias1_memory_write_enable,

            bias2_memory_write_address => bias2_memory_write_address,
            bias2_memory_read_address  => bias2_memory_read_address,
            bias2_memory_write_enable  => bias2_memory_write_enable,

            temp_memory_write_address => temp_memory_write_address,
            temp_memory_read_address  => temp_memory_read_address,
            temp_memory_write_enable  => temp_memory_write_enable
        );

    -- Keep original eff_conv... logic
    process(mode, last_layer_output_channels, conv_output_channels_div_by_CORE_SIZE)
    begin
        if (mode = "1011" and last_layer_output_channels > 1) then
            eff_conv_output_channels_div_by_CS <= conv_output_channels_div_by_CORE_SIZE;
        else
            eff_conv_output_channels_div_by_CS <= conv_output_channels_div_by_CORE_SIZE;
        end if;
    end process;

    -- NEW: real K for mode=1011
    process(mode, last_layer_output_channels)
    begin
        if (mode = "1011") then
            K_eff_for_1011 <= std_logic_vector(to_unsigned(last_layer_output_channels, 16));
        else
            K_eff_for_1011 <= (others => '0');
        end if;
    end process;
    
    -- Main FSM process
    process(clk)
    begin
        if rising_edge(clk) then
            if (mode = "0000") then
                features_memory_write_enable <= '0';
                left_memory_write_enable <= '0';
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable <= '0';
                bias2_memory_write_enable <= '0';
                temp_memory_write_enable <= '0';
            end if;
            
            -- 0001 write features
            if (mode = "0001") then
                controller_MUX_features_memory <= '1';
                left_memory_write_enable     <= '0';
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                bias2_memory_write_enable    <= '0';
                temp_memory_write_enable     <= '0';
                if (start = '1') then
                    features_memory_write_address <= base_Waddress_feat;
                    features_memory_write_enable  <= '1';
                    done <= '0';
                else
                    if (unsigned(features_memory_write_address) =
                        unsigned(base_Waddress_feat) + unsigned(nb_of_addresses_to_write) - 1) then
                        features_memory_write_enable <= '0';
                        done <= '1';
                    else
                        features_memory_write_address <= std_logic_vector(unsigned(features_memory_write_address) + 1);
                        features_memory_write_enable  <= '1';
                        done <= '0';
                    end if;
                end if;
            end if;

            -- 0010 write left
            if (mode = "0010") then
                controller_MUX_features_memory <= '1';
                features_memory_write_enable  <= '0';
                weights1_memory_write_enable  <= '0';
                weights2_memory_write_enable  <= '0';
                bias1_memory_write_enable     <= '0';
                bias2_memory_write_enable     <= '0';
                temp_memory_write_enable      <= '0';
                if (start = '1') then
                    left_memory_write_address <= base_Waddress_left;
                    left_memory_write_enable  <= '1';
                    done <= '0';
                else
                    if (unsigned(left_memory_write_address) =
                        unsigned(base_Waddress_left) + unsigned(nb_of_addresses_to_write) - 1) then
                        left_memory_write_enable <= '0';
                        done <= '1';
                    else
                        left_memory_write_address <= std_logic_vector(unsigned(left_memory_write_address) + 1);
                        left_memory_write_enable  <= '1';
                        done <= '0';
                    end if;
                end if;
            end if;

            -- 0011 write weights1
            if (mode = "0011") then
                features_memory_write_enable <= '0';
                left_memory_write_enable     <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                bias2_memory_write_enable    <= '0';
                temp_memory_write_enable     <= '0';
                if (start = '1') then
                    weights1_memory_write_address <= base_Waddress_weights1;
                    weights1_memory_write_enable  <= '1';
                    done <= '0';
                else
                    if (unsigned(weights1_memory_write_address) =
                        unsigned(base_Waddress_weights1) + unsigned(nb_of_addresses_to_write) - 1) then
                        weights1_memory_write_enable <= '0';
                        done <= '1';
                    else
                        weights1_memory_write_address <= std_logic_vector(unsigned(weights1_memory_write_address) + 1);
                        weights1_memory_write_enable  <= '1';
                        done <= '0';
                    end if;
                end if;
            end if;

            -- 0100 write weights2
            if (mode = "0100") then
                features_memory_write_enable <= '0';
                left_memory_write_enable     <= '0';
                weights1_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                bias2_memory_write_enable    <= '0';
                temp_memory_write_enable     <= '0';
                if (start = '1') then
                    weights2_memory_write_address <= base_Waddress_weights2;
                    weights2_memory_write_enable  <= '1';
                    done <= '0';
                else
                    if (unsigned(weights2_memory_write_address) =
                        unsigned(base_Waddress_weights2) + unsigned(nb_of_addresses_to_write) - 1) then
                        weights2_memory_write_enable <= '0';
                        done <= '1';
                    else
                        weights2_memory_write_address <= std_logic_vector(unsigned(weights2_memory_write_address) + 1);
                        weights2_memory_write_enable  <= '1';
                        done <= '0';
                    end if;
                end if;
            end if;

            -- 0101 write bias1
            if (mode = "0101") then
                features_memory_write_enable <= '0';
                left_memory_write_enable     <= '0';
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias2_memory_write_enable    <= '0';
                temp_memory_write_enable     <= '0';
                if (start = '1') then
                    bias1_memory_write_address <= base_Waddress_bias1;
                    bias1_memory_write_enable  <= '1';
                    done <= '0';
                else
                    if (unsigned(bias1_memory_write_address) =
                        unsigned(base_Waddress_bias1) + unsigned(nb_of_addresses_to_write) - 1) then
                        bias1_memory_write_enable <= '0';
                        done <= '1';
                    else
                        bias1_memory_write_address <= std_logic_vector(unsigned(bias1_memory_write_address) + 1);
                        bias1_memory_write_enable  <= '1';
                        done <= '0';
                    end if;
                end if;
            end if;

            -- 0110 write bias2
            if (mode = "0110") then
                features_memory_write_enable <= '0';
                left_memory_write_enable     <= '0';
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                temp_memory_write_enable     <= '0';
                if (start = '1') then
                    bias2_memory_write_address <= base_Waddress_bias2;
                    bias2_memory_write_enable  <= '1';
                    done <= '0';
                else
                    if (unsigned(bias2_memory_write_address) =
                        unsigned(base_Waddress_bias2) + unsigned(nb_of_addresses_to_write) - 1) then
                        bias2_memory_write_enable <= '0';
                        done <= '1';
                    else
                        bias2_memory_write_address <= std_logic_vector(unsigned(bias2_memory_write_address) + 1);
                        bias2_memory_write_enable  <= '1';
                        done <= '0';
                    end if;
                end if;
            end if;
            
            -- 0111: Standard Convolution Mode
            if (mode = "0111") then
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                bias2_memory_write_enable    <= '0';
                controller_MUX_main_core     <= '1';
                controller_MUX_SIMD_core     <= '0';
                controller_MUX_ReLU          <= '1';
                controller_MUX_features_memory <= '0';
                applied_ReLU_before_SIMD       <= '0';
                applied_ReLU_before_write_back <= '1';
        
                if (start = '1') then
                    temp_inputchannel_loop     <= (others => '0');
                    temp_outputchannel_loop    <= (others => '0');
                    temp_horizontalkernel_loop <= (others => '0');
                    temp_verticalkernel_loop   <= (others => '0');
                    temp_horizontalpixel_loop  <= (others => '0');
        
                    weights1_memory_read_address <= base_Raddress_weights1;
                    bias1_memory_read_address    <= std_logic_vector(unsigned(base_Raddress_bias1) - 1);
                    temp_memory_write_enable     <= '0';
                    features_memory_write_enable <= '0';
                    left_memory_write_enable     <= '0';
                    done <= '0';
        
                else
                    if (unsigned(conv_nb_of_output_pixels_row) = unsigned(temp_horizontalpixel_loop) + 1) then
                        if (unsigned(conv_vertical_kernel) = unsigned(temp_verticalkernel_loop) + 1) then
                            if (unsigned(conv_horizontal_kernel) = unsigned(temp_horizontalkernel_loop) + 1) then
                                if (unsigned(conv_input_channels_div_by_CORE_SIZE) = unsigned(temp_inputchannel_loop) + 1) then
                                    if (unsigned(conv_output_channels_div_by_CORE_SIZE) /= unsigned(temp_outputchannel_loop) + 1) then
                                        temp_outputchannel_loop <= std_logic_vector(unsigned(temp_outputchannel_loop) + 1);
                                        temp_inputchannel_loop  <= (others => '0');
                                    end if;
                                else
                                    temp_inputchannel_loop <= std_logic_vector(unsigned(temp_inputchannel_loop) + 1);
                                end if;
                                temp_horizontalkernel_loop <= (others => '0');
                            else
                                temp_horizontalkernel_loop <= std_logic_vector(unsigned(temp_horizontalkernel_loop) + 1);
                            end if;
                            temp_verticalkernel_loop <= (others => '0');
                        else
                            temp_verticalkernel_loop <= std_logic_vector(unsigned(temp_verticalkernel_loop) + 1);
                        end if;
                        temp_horizontalpixel_loop <= (others => '0');
                    else
                        temp_horizontalpixel_loop <= std_logic_vector(unsigned(temp_horizontalpixel_loop) + 1);
                    end if;
        
                    -- === Features Read ===
                    features_memory_read_address <= std_logic_vector(resize(
                        unsigned(base_Raddress_feat)
                      + (unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop))
                        * (unsigned(conv_nb_of_output_pixels_row) + unsigned(conv_horizontal_kernel) - 1)
                        * unsigned(conv_input_channels_div_by_CORE_SIZE)
                      + unsigned(conv_input_channels_div_by_CORE_SIZE)
                        * (unsigned(temp_horizontalpixel_loop) + unsigned(temp_horizontalkernel_loop))
                      + unsigned(temp_inputchannel_loop),
                      features_memory_read_address'length));
        
                    -- === Weights Read ===
                    if (unsigned(temp_horizontalpixel_loop) = unsigned(conv_nb_of_output_pixels_row) - 1) then
                        weights1_memory_read_address <= std_logic_vector(unsigned(weights1_memory_read_address) + 1);
                    end if;
        
                    -- === Temp Memory Write ===
                    if (unsigned(temp_inputchannel_loop)=0 and unsigned(temp_verticalkernel_loop)=0 and 
                        unsigned(temp_horizontalkernel_loop)=0 and 
                        unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES+2) then
                        temp_memory_write_enable <= '1';
                    end if;
        
                    if (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES + 2) then
                        temp_memory_write_address <= (others => '0');
                    else
                        temp_memory_write_address <= std_logic_vector(unsigned(temp_memory_write_address) + 1);
                    end if;
        
                    -- === Bias Read / Adder Control ===
                    if (unsigned(temp_inputchannel_loop)=0 and unsigned(temp_verticalkernel_loop)=0 and 
                        unsigned(temp_horizontalkernel_loop)=0) then
                        if (unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES-1) then
                            bias1_memory_read_address <= std_logic_vector(unsigned(bias1_memory_read_address) + 1);
                        end if;
                        if (unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES) then
                            controller_MUX_adder <= "01";
                        end if;
                    end if;
        
                    -- === Temp Read ===
                    if (unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES) then
                        if ((unsigned(temp_inputchannel_loop)/=0) or (unsigned(temp_verticalkernel_loop)/=0) or (unsigned(temp_horizontalkernel_loop)/=0)) then
                            controller_MUX_adder <= "00";
                        end if;
                    end if;
        
                    if (unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES-1) then
                        temp_memory_read_address <= (others => '0');
                    else
                        temp_memory_read_address <= std_logic_vector(unsigned(temp_memory_read_address) + 1);
                    end if;
        
                    -- === Done Control ===
                    if (must_be_written_back="00") then
                        if (unsigned(temp_inputchannel_loop)=unsigned(conv_input_channels_div_by_CORE_SIZE)-1) and
                           (unsigned(temp_verticalkernel_loop)=unsigned(conv_vertical_kernel)-1) and
                           (unsigned(temp_horizontalkernel_loop)=unsigned(conv_horizontal_kernel)-1) and
                           (unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES) then
                            counter <= std_logic_vector(to_unsigned(1, counter'length));
                        else
                            if (unsigned(counter)=COMPUTE_CORE_LATENCY) then done <= '1'; end if;
                            if (unsigned(counter)=COMPUTE_CORE_LATENCY + unsigned(conv_nb_of_output_pixels_row)) then
                                done <= '0';
                                counter <= (others => '0');
                            end if;
                            if (unsigned(counter)/=0) then
                                counter <= std_logic_vector(unsigned(counter)+1);
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            -- 1000: Convolution + Concatenation
            if (mode = "1000") then
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                bias2_memory_write_enable    <= '0';
                controller_MUX_main_core     <= '1';
                controller_MUX_SIMD_core     <= '0';
                controller_MUX_ReLU          <= '1';
                controller_MUX_features_memory <= '0';
                applied_ReLU_before_SIMD       <= '0';
                applied_ReLU_before_write_back <= '1';
            
                if (start = '1') then
                    temp_inputchannel_loop     <= (others => '0');
                    temp_outputchannel_loop    <= (others => '0');
                    temp_horizontalkernel_loop <= (others => '0');
                    temp_verticalkernel_loop   <= (others => '0');
                    temp_horizontalpixel_loop  <= (others => '0');
            
                    weights1_memory_read_address <= base_Waddress_weights1;
                    bias1_memory_read_address    <= std_logic_vector(unsigned(base_Raddress_bias1) - 1);
                    temp_memory_write_enable <= '0';
                    features_memory_write_enable <= '0';
                    left_memory_write_enable <= '0';
                    done <= '0';
                else
                    if (unsigned(conv_nb_of_output_pixels_row) = unsigned(temp_horizontalpixel_loop) + 1) then
                        if (unsigned(conv_vertical_kernel) = unsigned(temp_verticalkernel_loop) + 1) then
                            if (unsigned(conv_horizontal_kernel) = unsigned(temp_horizontalkernel_loop) + 1) then
                                if (unsigned(conv_input_channels_div_by_CORE_SIZE) = unsigned(temp_inputchannel_loop) + 1) then
                                    if (unsigned(conv_output_channels_div_by_CORE_SIZE) /= unsigned(temp_outputchannel_loop) + 1) then
                                        temp_outputchannel_loop <= std_logic_vector(unsigned(temp_outputchannel_loop) + 1);
                                        temp_inputchannel_loop <= (others => '0');
                                    end if;
                                else
                                    temp_inputchannel_loop <= std_logic_vector(unsigned(temp_inputchannel_loop) + 1);
                                end if;
                                temp_horizontalkernel_loop <= (others => '0');
                            else
                                temp_horizontalkernel_loop <= std_logic_vector(unsigned(temp_horizontalkernel_loop) + 1);
                            end if;
                            temp_verticalkernel_loop <= (others => '0');
                        else
                            temp_verticalkernel_loop <= std_logic_vector(unsigned(temp_verticalkernel_loop) + 1);
                        end if;
                        temp_horizontalpixel_loop <= (others => '0');
                    else
                        temp_horizontalpixel_loop <= std_logic_vector(unsigned(temp_horizontalpixel_loop) + 1);
                    end if;
                    
                    if (2*unsigned(temp_inputchannel_loop) < unsigned(conv_input_channels_div_by_CORE_SIZE)) then
                        if (unsigned(conv_vertical_kernel) > unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop)) then
                            features_memory_read_address <= std_logic_vector(resize(unsigned(base_Raddress_feat) + 
                                (unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop))*(unsigned(conv_nb_of_output_pixels_row) + unsigned(conv_horizontal_kernel) - 1)*shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)
                                + shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)*(unsigned(temp_horizontalpixel_loop) + unsigned(temp_horizontalkernel_loop))
                                + unsigned(temp_inputchannel_loop), features_memory_read_address'length)
                                );
                        else
                            features_memory_read_address <= std_logic_vector(resize(unsigned(base_Raddress_feat) + 
                                (unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop) - unsigned(conv_vertical_kernel))*(unsigned(conv_nb_of_output_pixels_row) + unsigned(conv_horizontal_kernel) - 1)*shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)
                                + shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)*(unsigned(temp_horizontalpixel_loop) + unsigned(temp_horizontalkernel_loop))
                                + unsigned(temp_inputchannel_loop), features_memory_read_address'length)
                                );
                        end if;
                        controller_MUX_Main_core <= '1';
                    else
                        if (unsigned(conv_vertical_kernel) > unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop)) then
                            left_memory_read_address <= std_logic_vector(resize(unsigned(base_Raddress_feat) + 
                                (unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop))*(unsigned(conv_nb_of_output_pixels_row) + unsigned(conv_horizontal_kernel) - 1)*shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)
                                + shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)*(unsigned(temp_horizontalpixel_loop) + unsigned(temp_horizontalkernel_loop))
                                + unsigned(temp_inputchannel_loop) - shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1), features_memory_read_address'length)
                                );
                        else
                            left_memory_read_address <= std_logic_vector(resize(unsigned(base_Raddress_feat) + 
                                (unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop) - unsigned(conv_vertical_kernel))*(unsigned(conv_nb_of_output_pixels_row) + unsigned(conv_horizontal_kernel) - 1)*shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)
                                + shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1)*(unsigned(temp_horizontalpixel_loop) + unsigned(temp_horizontalkernel_loop))
                                + unsigned(temp_inputchannel_loop) - shift_right(unsigned(conv_input_channels_div_by_CORE_SIZE), 1), features_memory_read_address'length)
                                );
                        end if;
                        controller_MUX_Main_core <= '0';
                    end if;
                    
                    if (unsigned(temp_horizontalpixel_loop) = (unsigned(conv_nb_of_output_pixels_row) - 1)) then
                        weights1_memory_read_address <= std_logic_vector(unsigned(weights1_memory_read_address) + 1);
                    end if;
                    
                    if (unsigned(temp_inputchannel_loop) = (temp_inputchannel_loop'range => '0')) then
                        if (unsigned(temp_verticalkernel_loop) = (temp_verticalkernel_loop'range => '0')) then
                            if (unsigned(temp_horizontalkernel_loop) = (temp_horizontalkernel_loop'range => '0')) then
                                if (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES + 2)) then
                                    temp_memory_write_enable <= '1';
                                end if;
                            end if;
                        end if;
                    end if;
                    if (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES + 2)) then
                        temp_memory_write_address <= (temp_memory_write_address'range => '0');
                    else
                        temp_memory_write_address <= std_logic_vector(unsigned(temp_memory_write_address) + 1);
                    end if;
                    
                    if (unsigned(temp_inputchannel_loop) = (temp_inputchannel_loop'range => '0')) then
                        if (unsigned(temp_verticalkernel_loop) = (temp_verticalkernel_loop'range => '0')) then
                            if (unsigned(temp_horizontalkernel_loop) = (temp_horizontalkernel_loop'range => '0')) then
                                if (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES - 1)) then
                                    bias1_memory_read_address <= std_logic_vector(unsigned(bias1_memory_read_address) + 1);
                                end if;
                                if (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES)) then
                                    controller_MUX_adder <= "01";
                                end if;
                            end if;
                        end if;
                    end if;
                    
                    if (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES)) then
                        if ((unsigned(temp_inputchannel_loop) /= (temp_inputchannel_loop'range => '0')) or
                            (unsigned(temp_verticalkernel_loop) /= (temp_verticalkernel_loop'range => '0')) or
                            (unsigned(temp_horizontalkernel_loop) /= (temp_horizontalkernel_loop'range => '0'))) then
                                controller_MUX_adder <= "00";
                        end if;
                    end if;
                    if (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES - 1)) then
                        temp_memory_read_address <= (temp_memory_read_address'range => '0');
                    else
                        temp_memory_read_address <= std_logic_vector(unsigned(temp_memory_read_address) + 1);
                    end if;
                    
                    if (must_be_written_back = "00") then
                        if (unsigned(temp_inputchannel_loop) = unsigned(conv_input_channels_div_by_CORE_SIZE) - 1) and
                           (unsigned(temp_verticalkernel_loop) = unsigned(conv_vertical_kernel) - 1) and
                           (unsigned(temp_horizontalkernel_loop) = unsigned(conv_horizontal_kernel) - 1) and
                           (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES)) then
                            counter <= std_logic_vector(to_unsigned(1, counter'length));
                        else
                            if (unsigned(counter) = 5) then
                                done <= '1';
                            end if;
                            if (unsigned(counter) = 5 + unsigned(conv_nb_of_output_pixels_row)) then    
                                done <= '0';
                                counter <= (counter'range => '0');
                            end if;
                            if (counter /= (counter'range => '0')) then
                                counter <= std_logic_vector(unsigned(counter) + 1);
                            end if;
                        end if;
                    end if;
                    if (must_be_written_back = "10") then
                        if (unsigned(temp_inputchannel_loop) = unsigned(conv_input_channels_div_by_CORE_SIZE) - 1) and
                           (unsigned(temp_verticalkernel_loop) = unsigned(conv_vertical_kernel) - 1) and
                           (unsigned(temp_horizontalkernel_loop) = unsigned(conv_horizontal_kernel) - 1) and
                           (unsigned(temp_horizontalpixel_loop) = (ADDER_TREE_STAGES)) then
                            counter <= std_logic_vector(to_unsigned(1, counter'length));
                            current_outputchannel_loop <= temp_outputchannel_loop;
                        else
                            if (unsigned(counter) = 5) then
                                features_memory_write_enable <= '1';
                                features_memory_write_address <= std_logic_vector(unsigned(base_Waddress_feat) + unsigned(current_outputchannel_loop));
                            end if;
                            if (unsigned(counter) > 5) then
                                features_memory_write_address <= std_logic_vector(unsigned(features_memory_write_address) + unsigned(conv_output_channels_div_by_CORE_SIZE));
                            end if;
                            if (unsigned(counter) = 5 + unsigned(conv_nb_of_output_pixels_row)) then    
                                features_memory_write_enable <= '0';
                                counter <= (counter'range => '0');
                                if (unsigned(current_outputchannel_loop) = (unsigned(conv_output_channels_div_by_CORE_SIZE) - 1)) then
                                    done <= '1';
                                end if;
                            end if;
                            if (counter /= (counter'range => '0')) then
                                counter <= std_logic_vector(unsigned(counter) + 1);
                            else
                                done <= '0';
                            end if;
                        end if;
                    end if;
                end if;
            end if;
            
            -- 1001: Convolution + Addition
            if (mode = "1001") then
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                bias2_memory_write_enable    <= '0';
                controller_MUX_main_core     <= '1';
                controller_MUX_SIMD_core     <= '0';
                controller_MUX_ReLU          <= '1';
                controller_MUX_features_memory <= '0';
                applied_ReLU_before_SIMD       <= '0';
                applied_ReLU_before_write_back <= '1';
            
                if (start = '1') then
                    temp_inputchannel_loop     <= (others => '0');
                    temp_outputchannel_loop    <= (others => '0');
                    temp_horizontalkernel_loop <= (others => '0');
                    temp_verticalkernel_loop   <= (others => '0');
                    temp_horizontalpixel_loop  <= (others => '0');
                    weights1_memory_read_address <= base_Raddress_weights1;
                    done <= '0';
                else
                    features_memory_read_address <= std_logic_vector(resize(
                        unsigned(base_Raddress_feat)
                      + (unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop))
                        * (unsigned(conv_nb_of_output_pixels_row) + unsigned(conv_horizontal_kernel) - 1)
                        * unsigned(conv_input_channels_div_by_CORE_SIZE)
                      + unsigned(conv_input_channels_div_by_CORE_SIZE)
                        * (unsigned(temp_horizontalpixel_loop) + unsigned(temp_horizontalkernel_loop))
                      + unsigned(temp_inputchannel_loop),
                      features_memory_read_address'length));
            
                    if (unsigned(temp_inputchannel_loop)=0 and unsigned(temp_verticalkernel_loop)=0 and 
                        unsigned(temp_horizontalkernel_loop)=0 and 
                        unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES-1) then
                        left_memory_read_address <= std_logic_vector(unsigned(base_Raddress_left) + unsigned(temp_outputchannel_loop));
                    end if;
            
                    if (unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES) then
                        controller_MUX_adder <= "10"; 
                    end if;
            
                    if (must_be_written_back="00") then
                        if (unsigned(counter)=COMPUTE_CORE_LATENCY) then done <= '1'; end if;
                        if (unsigned(counter)=COMPUTE_CORE_LATENCY + unsigned(conv_nb_of_output_pixels_row)) then
                            done <= '0';
                            counter <= (others => '0');
                        end if;
                        if (unsigned(counter)/=0) then
                            counter <= std_logic_vector(unsigned(counter)+1);
                        end if;
                    end if;
                end if;
            end if;
            
            
            -- 1010: Convolution + Multiplication
            if (mode = "1010") then
                weights1_memory_write_enable <= '0';
                weights2_memory_write_enable <= '0';
                bias1_memory_write_enable    <= '0';
                bias2_memory_write_enable    <= '0';
                controller_MUX_main_core     <= '1';
                controller_MUX_SIMD_core     <= '1';  
                controller_MUX_ReLU          <= '0';
                controller_MUX_features_memory <= '0';
                applied_ReLU_before_SIMD       <= '1';
                applied_ReLU_before_write_back <= '1';
            
                if (start = '1') then
                    temp_inputchannel_loop     <= (others => '0');
                    temp_outputchannel_loop    <= (others => '0');
                    temp_horizontalkernel_loop <= (others => '0');
                    temp_verticalkernel_loop   <= (others => '0');
                    temp_horizontalpixel_loop  <= (others => '0');
                    weights1_memory_read_address <= base_Raddress_weights1;
                    done <= '0';
                else
                    features_memory_read_address <= std_logic_vector(resize(
                        unsigned(base_Raddress_feat)
                      + (unsigned(conv_pointer_highest_line) + unsigned(temp_verticalkernel_loop))
                        * (unsigned(conv_nb_of_output_pixels_row) + unsigned(conv_horizontal_kernel) - 1)
                        * unsigned(conv_input_channels_div_by_CORE_SIZE)
                      + unsigned(conv_input_channels_div_by_CORE_SIZE)
                        * (unsigned(temp_horizontalpixel_loop) + unsigned(temp_horizontalkernel_loop))
                      + unsigned(temp_inputchannel_loop),
                      features_memory_read_address'length));
            
                    if (unsigned(temp_inputchannel_loop)=unsigned(conv_input_channels_div_by_CORE_SIZE)-1) and
                       (unsigned(temp_verticalkernel_loop)=unsigned(conv_vertical_kernel)-1) and
                       (unsigned(temp_horizontalkernel_loop)=unsigned(conv_horizontal_kernel)-1) and
                       (unsigned(temp_horizontalpixel_loop)=ADDER_TREE_STAGES+1) then
                        left_memory_read_address <= std_logic_vector(unsigned(base_Raddress_left) + unsigned(temp_outputchannel_loop));
                    end if;
            
                    if (must_be_written_back="00") then
                        if (unsigned(counter)=SIMD_CORE_LATENCY) then done <= '1'; end if;
                        if (unsigned(counter)=SIMD_CORE_LATENCY + unsigned(conv_nb_of_output_pixels_row)) then
                            done <= '0';
                            counter <= (others => '0');
                        end if;
                        if (unsigned(counter)/=0) then
                            counter <= std_logic_vector(unsigned(counter)+1);
                        end if;
                    end if;
                end if;
            end if;
            
---- =========================================================
-- 1011: Final Convolutional Layers (SIMD Core Version) - FINAL ALIGNMENT
-- =========================================================
if (mode = "1011") then
    -- 1. Disable Writes
    features_memory_write_enable <= '0';
    left_memory_write_enable     <= '0';
    weights1_memory_write_enable <= '0';
    weights2_memory_write_enable <= '0';
    bias1_memory_write_enable    <= '0';
    bias2_memory_write_enable    <= '0';
    temp_memory_write_enable     <= '0';

    -- 2. Initialization
    if (start = '1') then
        counter <= (others => '0');
        done    <= '0';
        
        temp_inputchannel_loop     <= (others => '0');
        temp_outputchannel_loop    <= (others => '0');
        temp_horizontalkernel_loop <= (others => '0');
        temp_verticalkernel_loop   <= (others => '0');
        temp_horizontalpixel_loop  <= (others => '0');
        current_outputchannel_loop <= (others => '0');
        
        features_memory_read_address <= base_Raddress_feat;
        weights1_memory_read_address <= base_Raddress_weights1;
        bias1_memory_read_address    <= std_logic_vector(unsigned(base_Raddress_bias1) - 1);
        
        -- SIMD Address Init
        weights2_memory_read_address <= base_Raddress_weights2; 
        bias2_memory_read_address    <= base_Raddress_bias2;
        
        temp_memory_read_address     <= (others => '0');
        temp_memory_write_address    <= (others => '0');

    else
        -- 3. Execution Phase
        
        -- A. Control Signals
        controller_MUX_main_core       <= '1'; 
        controller_MUX_SIMD_core       <= '1'; 
        controller_MUX_ReLU            <= '0'; 
        controller_MUX_features_memory <= '0'; 
        applied_ReLU_before_SIMD       <= '1'; 
        applied_ReLU_before_write_back <= '1';

        -- B. Loop Nest
        if (unsigned(conv_nb_of_output_pixels_row) = unsigned(temp_horizontalpixel_loop) + 1) then
            if (unsigned(conv_input_channels_div_by_CORE_SIZE) = unsigned(temp_inputchannel_loop) + 1) then
                temp_inputchannel_loop <= (others => '0');
            else
                temp_inputchannel_loop <= std_logic_vector(unsigned(temp_inputchannel_loop) + 1);
            end if;
            temp_horizontalpixel_loop <= (others => '0');
        else
            temp_horizontalpixel_loop <= std_logic_vector(unsigned(temp_horizontalpixel_loop) + 1);
        end if;

        -- C. Feature Address
        features_memory_read_address <= std_logic_vector(resize(
            unsigned(base_Raddress_feat) 
            + unsigned(temp_horizontalpixel_loop) * unsigned(conv_input_channels_div_by_CORE_SIZE)
            + unsigned(temp_inputchannel_loop),
            features_memory_read_address'length
        ));

        -- Weights1 Update (Main Core)
        if (unsigned(temp_horizontalpixel_loop) = unsigned(conv_nb_of_output_pixels_row) - 1) then
            weights1_memory_read_address <= std_logic_vector(unsigned(weights1_memory_read_address) + 1);
        end if;

        -- D. Temp Memory Logic
        if (unsigned(temp_inputchannel_loop) = 0) and 
           (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES + 2) then
            temp_memory_write_enable <= '1';
        end if;
        
        if (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES + 2) then
            temp_memory_write_address <= (others => '0');
        else
            temp_memory_write_address <= std_logic_vector(unsigned(temp_memory_write_address) + 1);
        end if;

        -- E. Accumulation MUX
        if (unsigned(temp_inputchannel_loop) = 0) then
            if (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES - 1) then
                 bias1_memory_read_address <= std_logic_vector(unsigned(bias1_memory_read_address) + 1);
            end if;
            if (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES) then
                 controller_MUX_adder <= "01"; 
            end if;
        else
            if (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES) then
                 controller_MUX_adder <= "00"; 
            end if;
            if (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES - 1) then
                temp_memory_read_address <= (others => '0');
            else
                temp_memory_read_address <= std_logic_vector(unsigned(temp_memory_read_address) + 1);
            end if;
        end if;

        -- F. Counter Trigger Logic
        if (unsigned(temp_inputchannel_loop) = unsigned(conv_input_channels_div_by_CORE_SIZE) - 1) and
           (unsigned(temp_horizontalpixel_loop) = ADDER_TREE_STAGES + 1) and 
           (unsigned(counter) = 0) then 
             counter <= std_logic_vector(to_unsigned(1, counter'length));
        end if;

        -- G. Output Pipeline Logic
        if (unsigned(counter) /= 0) then
            counter <= std_logic_vector(unsigned(counter) + 1);

            if (must_be_written_back = "00") then
                
              
                if (unsigned(counter) = 10) then 
                    done <= '1'; 
                end if;
                
                
                if (unsigned(counter) = 10 + unsigned(conv_nb_of_output_pixels_row)) then
                    if (unsigned(current_outputchannel_loop) < to_unsigned(last_layer_output_channels - 1, current_outputchannel_loop'length)) then
                        done <= '0';
                    else
                        done <= '1';
                    end if;
                end if;

                
                if (unsigned(counter) = 10 + unsigned(conv_nb_of_output_pixels_row) + 1) then
                    counter <= (others => '0');
                    
                    if (unsigned(current_outputchannel_loop) < to_unsigned(last_layer_output_channels - 1, current_outputchannel_loop'length)) then
                        current_outputchannel_loop <= std_logic_vector(unsigned(current_outputchannel_loop) + 1);
                        
                       
                        weights2_memory_read_address <= std_logic_vector(unsigned(weights2_memory_read_address) + 2);
                        
                        
                        bias2_memory_read_address <= std_logic_vector(unsigned(bias2_memory_read_address) + 1);
                    else
                        done <= '1';
                    end if;
                end if;

            end if;

            -- Write Back Logic
            -- Write Back Logic (must_be_written_back = "01")
            if (must_be_written_back = "01") then
                -- Window: [9, 9+width-1]
                if (unsigned(counter) >= 9) and 
                   (unsigned(counter) < 9 + unsigned(conv_nb_of_output_pixels_row)) then
                    left_memory_write_enable <= '1';
                else
                    left_memory_write_enable <= '0';
                end if;
            
                -- Address Calculation
                if (unsigned(counter) = 9) then
                    -- ? Per-Channel Block Start Address
                    left_memory_write_address <= std_logic_vector(resize(
                        unsigned(base_Waddress_left) 
                        + unsigned(current_outputchannel_loop) * (unsigned(conv_nb_of_output_pixels_row) + to_unsigned(1, conv_nb_of_output_pixels_row'length)),
                        left_memory_write_address'length
                    )); 
                elsif (unsigned(counter) > 9) then
                    -- Sequential increment within block
                    left_memory_write_address <= std_logic_vector(
                        unsigned(left_memory_write_address) + 1
                    ); 
                end if;
            
                -- Line Finish & Channel Switch
                if (unsigned(counter) = 9 + unsigned(conv_nb_of_output_pixels_row)) then
                    counter <= (others => '0');
                    if (unsigned(current_outputchannel_loop) = to_unsigned(last_layer_output_channels - 1, current_outputchannel_loop'length)) then
                        done <= '1';
                    else
                        current_outputchannel_loop <= std_logic_vector(unsigned(current_outputchannel_loop) + 1);
                    end if;
                end if;
            end if;
             
        end if; -- End Counter

    end if; -- End Execution
end if; -- End Mode 1011

        end if;
    end process;
    
end Behavioral;