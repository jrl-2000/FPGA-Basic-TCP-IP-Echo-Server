
----------------
-- Basic TCP/IP Echo Server Host
----------------
-- Using Open Source FC1002_RMII IP Core from FPGA-cores.com
-- RMII connecting the PHY to the MAC


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity BasicTCPechoTop is
    Port ( 
        CLK100MHZ   : in  std_logic;
        
        -----------------
        -- LEDs
        -----------------
        LED         : out std_logic_vector(15 downto 0);
        
        -----------------
        -- Quad SPI Flash
        -----------------
        QSPI_DQ     : inout std_logic_vector(3 downto 0);
        QSPI_MISO   : in  std_logic;
        QSPI_CSN    : out std_logic; 
        
        --------------------
        -- SMSC Ethernet PHY
        --------------------
        ETH_MDC     : out std_logic;
        ETH_MDIO    : inout std_logic;
        ETH_RSTN    : out std_logic;
        ETH_CRSDV   : in  std_logic;
        ETH_RXERR   : in  std_logic;
        ETH_RXD     : in  std_logic_vector(1 downto 0);
        ETH_TXEN    : out std_logic;
        ETH_TXD     : out std_logic_vector(1 downto 0);
        ETH_REFCLK  : out std_logic            
    );
end BasicTCPechoTop;

architecture IMPL of BasicTCPechoTop is
        
    -----------------------------------------------
    -- Components
    -----------------------------------------------
    component FC1002_RMII is
    port (
        --Sys/Common
        Clk             : in  std_logic; --100 MHz
        Reset           : in  std_logic; --Active high
        UseDHCP         : in  std_logic; --'1' to use DHCP
        IP_Addr         : in  std_logic_vector(31 downto 0); --IP address if not using DHCP
        IP_Ok           : out std_logic; --DHCP ready

        --MAC/RMII
        RMII_CLK_50M    : out std_logic; --RMII continous 50 MHz reference clock
        RMII_RST_N      : out std_logic; --Phy reset, active low
        RMII_CRS_DV     : in  std_logic; --Carrier sense/Receive data valid
        RMII_RXD0       : in  std_logic; --Receive data bit 0
        RMII_RXD1       : in  std_logic; --Receive data bit 1
        RMII_RXERR      : in  std_logic; --Receive error, optional
        RMII_TXEN       : out std_logic; --Transmit enable
        RMII_TXD0       : out std_logic; --Transmit data bit 0
        RMII_TXD1       : out std_logic; --Transmit data bit 1
        RMII_MDC        : out std_logic; --Management clock
        RMII_MDIO       : inout std_logic; --Management data

        --SPI/Boot Control
        SPI_CSn         : out std_logic; --Chip select
        SPI_SCK         : out std_logic; --Serial clock
        SPI_MOSI        : out std_logic; --Master out slave in
        SPI_MISO        : in  std_logic; --Master in slave out

        --Logic Analyzer
        LA0_TrigIn      : in  std_logic; --Trigger input
        LA0_Clk         : in  std_logic; --Clock
        LA0_TrigOut     : out std_logic; --Trigger out
        LA0_Signals     : in  std_logic_vector(31 downto 0); --Signals
        LA0_SampleEn    : in  std_logic; --Sample enable

        --TCP Basic Server
        TCP0_Service    : in  std_logic_vector(15 downto 0); --Service
        TCP0_ServerPort : in  std_logic_vector(15 downto 0); --TCP local server port
        TCP0_Connected  : out std_logic; --Client connected
        TCP0_AllAcked   : out std_logic; --All outgoing data acked
        TCP0_nTxFree    : out std_logic_vector(15 downto 0); --Number of free bytes in outgoing buffer
        TCP0_nRxData    : out std_logic_vector(15 downto 0); --Number of bytes in receiving buffer
        TCP0_TxData     : in  std_logic_vector(7 downto 0); --Transmit data
        TCP0_TxValid    : in  std_logic; --Transmit data valid
        TCP0_TxReady    : out std_logic; --Transmit data ready
        TCP0_RxData     : out std_logic_vector(7 downto 0); --Receive data
        TCP0_RxValid    : out std_logic; --Receive data valid
        TCP0_RxReady    : in  std_logic  --Receive data ready
    );
    end component;

    -----------------------------------------------
    -- Signals
    -----------------------------------------------
    signal IP_Ok            : std_logic := '0';
     
    signal TCP0_Connected   : std_logic;
    signal TCP0_AllAcked    : std_logic;
            
    signal TCP0_TxData      : std_logic_vector(7 downto 0);  
    signal TCP0_TxValid     : std_logic;
    signal TCP0_TxReady     : std_logic;
        
    signal TCP0_RxData      : std_logic_vector(7 downto 0);
    signal TCP0_RxValid     : std_logic;
    signal TCP0_RxReady     : std_logic;
        
    signal LA0_TrigIn       : std_logic;
    signal LA0_Clk          : std_logic;
    signal LA0_TrigOut      : std_logic;
    signal LA0_Signals      : std_logic_vector(31 downto 0);
    signal LA0_SampleEn     : std_logic;
    
   
begin

    AliveProcess_100 : process( CLK100MHZ ) is
        constant C_100_MS   : integer := 10_000_000;
        variable ClkCnt     : integer range 0 to C_100_MS := 0;
        variable LED_i      : std_logic_vector(15 downto 0) := x"000" & "0001";
    begin
        if rising_edge(CLK100MHZ) then
            
            if ClkCnt = C_100_MS then
                ClkCnt := 0;
                LED_i := LED_i(14 downto 0) & LED_i(15);
            else
                ClkCnt := ClkCnt + 1;
            end if;
                
            LED <= LED_i;
            
        end if;
        
    end process;

    i_FC_1002_RMII  : FC1002_RMII
    port map (
        --Sys/Common
        Clk             => CLK100MHZ,       -- 100 MHz
        Reset           => '0',             -- Active high
        UseDHCP         => '0',             -- DHCP Off Use Fixed IP
        IP_Addr         => x"00000000",   -- e.g. INSERT OWN IP HERE!
        IP_Ok           => IP_Ok,           -- '1' when DHCP has solved IP

         --MAC/RMII
        RMII_CLK_50M    => ETH_REFCLK,      -- RMII continous 50 MHz reference clock
        RMII_RST_N      => ETH_RSTN,        -- Phy reset, active low
        RMII_CRS_DV     => ETH_CRSDV,       -- Carrier sense/Receive data valid
        RMII_RXD0       => ETH_RXD(0),      -- Receive data bit 0
        RMII_RXD1       => ETH_RXD(1),      -- Receive data bit 1
        RMII_RXERR      => ETH_RXERR,       -- Receive error, optional
        RMII_TXEN       => ETH_TXEN,        -- Transmit enable
        RMII_TXD0       => ETH_TXD(0),      -- Transmit data bit 0
        RMII_TXD1       => ETH_TXD(1),      -- Transmit data bit 1
        RMII_MDC        => ETH_MDC,         -- Management clock
        RMII_MDIO       => ETH_MDIO,        -- Management data

        --SPI/Boot Control
        SPI_CSn         => QSPI_CSN,
        SPI_SCK         => open, --??qspi_sck,
        SPI_MOSI        => QSPI_DQ(0),
        SPI_MISO        => QSPI_DQ(1),

        --Logic Analyzer
        LA0_TrigIn      => LA0_TrigIn,   
        LA0_Clk         => LA0_Clk,      
        LA0_TrigOut     => LA0_TrigOut,  
        LA0_Signals     => LA0_Signals,  
        LA0_SampleEn    => LA0_SampleEn, 

        --TCP Basic Server
        TCP0_Service    => x"0112",
        TCP0_ServerPort => x"E001",
        TCP0_Connected  => TCP0_Connected,
        TCP0_AllAcked   => open,
        TCP0_nTxFree    => open,
        TCP0_nRxData    => open,
        TCP0_TxData     => TCP0_TxData, 
        TCP0_TxValid    => TCP0_TxValid,
        TCP0_TxReady    => TCP0_TxReady,
        TCP0_RxData     => TCP0_RxData, 
        TCP0_RxValid    => TCP0_RxValid,
        TCP0_RxReady    => TCP0_RxReady
    );
    
    
    ---------------
    -- Loopback TCP
    ---------------
    --  AXI Stream
    TCP0_TxData     <= TCP0_RxData;
    TCP0_TxValid    <= TCP0_RxValid;
    TCP0_RxReady    <= TCP0_TxReady;
    
    LA0_Clk <= CLK100MHZ;
    
    -- Create some data for the Logic Analyzer
    ILATestP : process ( CLK100MHZ ) is
        variable f0         : unsigned(7 downto 0) := to_unsigned(2,8);
        variable f1         : unsigned(7 downto 0) := to_unsigned(2,8);
        variable v          : unsigned(15 downto 0) := to_unsigned(0,16);
        variable vf         : unsigned(15 downto 0) := to_unsigned(0,16);
        variable highbit    : std_logic := '0';
        variable up         : boolean := TRUE;
        variable up1        : boolean := TRUE;
        variable wait_ms    : integer range 0 to 100 := 0;
        variable clk_cnt    : integer range 0 to 100_000 := 0;
    begin
    
        if rising_edge( CLK100MHZ ) then
            
            LA0_SampleEn    <= '1';
            LA0_TrigIn      <= '0';
            --LA0_Signals(27 downto 0) <= std_logic_vector( f0 & vf(15 downto 6) & v(15 downto 6) );
            LA0_Signals(7 downto 0) <= TCP0_RxData;
            LA0_Signals(31 downto 24) <= TCP0_TxData;

        
            if wait_ms > 0 then
                if clk_cnt = 100_000 then
                    clk_cnt:=0;
                    wait_ms := wait_ms - 1;
                else
                    clk_cnt := clk_cnt + 1;
                end if;
            else
                
                v := v + (f0&"000") + f1;
                
                if v(v'high) = '0' and highbit = '1' then
                    if up then
                        if f0 = 20 then
                            up := FALSE;
                            wait_ms := 100;
                        else
                            f0 := f0 + 1;
                        end if;
                    else
                        if f0 = 2 then
                            up := TRUE;
                            LA0_TrigIn <= '1';
                            
                            f1 := f1 + 1;
                            
                        else
                            f0 := f0 - 1;
                        end if;
                    end if;
                end if;
                
            end if;
                    
            highbit := v(v'high);
            
        end if;
    
    end process;
    
end IMPL;