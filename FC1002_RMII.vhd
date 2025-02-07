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
