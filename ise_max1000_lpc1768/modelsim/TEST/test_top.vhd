-- Test dirigido simple del tope de la jerarquia de MEDTH
--
-- Prueba los 3 modos de funcionamiento de la presentacion y
-- las distitas formas de programacion del reloj
-- La secuencia de operaciones es la siguiente:
--
-- Inicialmente el sistema arranca en modo 0 (los displays muestran el reloj)
--
-- Se programa el reloj en diversasormas: pulsacion corta y larga en 'C'
-- e introduciendo los valores numericamente.
-- Se prueba el cambio de modo 12h y 24h
-- Se prueba la salida programacion por timeout
--
-- Posteriormente se prueban los modos de funcionamiento del display
-- Se programa el modo 1 (los displays muestran la temperatura) 
-- Se programa el modo 2 (los displays muestran la humedad) 
-- Se programa el modo 3 (los displays muestran todo en secuencia) 
-- Vuelta al modo 0 
--
-- Escalado: se utilizan los genericos del DUT para escalar los tics de 125 ms y 1 ms
-- del timer, asi como el numero de tics de 5 ms que cuenta el controlador de teclado para los dos segundos
--
-- PLL: para incrementar la velocidad de la simulacion se debe instanciar la arquitectura
-- sim del PLL (en lugar de syn)
--
--    Designer: DTE
--    Versión: 1.0
--    Fecha: 08-01-2018 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library modelsim_lib; -- spies
use modelsim_lib.util.all; 

use work.pack_agente_slave_i2c.all;

entity test_top is
end entity;

architecture test of test_top is

-- Segnales del DUT

  signal clk:              std_logic;
  signal nRst:             std_logic;
  signal SDA:              std_logic;
  signal SCL:              std_logic;
  
  -- Segnales para el esclavo I2C
 
  signal transfer_i2c:     t_transfer_i2c;
  signal put_transfer_i2c: std_logic;

 
 -- Constantes

  constant Tclk:           time := 83.333 ns; -- reloj de 12 MHz
  constant add_i2c:        std_logic_vector(6 downto 0) := "1000000"; -- direccion del esclavo I2C
  
  begin

  -- Reloj de 12 MHz

  process
  begin
    clk <= '0';
    wait for Tclk/2;
    clk <= '1';
    wait for Tclk/2;
  end process;
 
  
  -- MEDTH

  dut: entity work.MEDTH(struct)
       generic map(DIV_125ms   => 2,   -- 1:25/3
                   DIV_1ms     => 99,  -- 1:1000
                   TICS_2s     => 48,  -- 48 tics de 5 ms para 2 tics de 1 s
				   PLL_ARCH    => "sim"-- version PLL para simulacion
                   )
       port map(clk           => clk,
                nRst          => nRst,
                SDA           => SDA,
                SCL           => SCL
                );

  -- Pull-ups para la interfaz I2C

  SDA <= 'H';  
  SCL <= 'H'; 

   
  -- Esclavo I2C

  esclavo_I2C: entity work.agente_slave_i2c(sim_struct)
    generic map(config_item => (slave_id => inespecifico, add => add_i2c)) 
    port map(nRst           => nRst,
           SCL              => SCL,
           SDA              => SDA,
           transfer_i2c     => transfer_i2c,
           put_transfer_i2c => put_transfer_i2c); 
  
-- Secuencia de estimulos

  process
  begin	
    -- Reset
    wait until clk'event and clk = '1';
    wait until clk'event and clk = '1';
    nRst <= '1';
    wait until clk'event and clk = '1';
    wait until clk'event and clk = '1';
    nRst <= '0';
    wait until clk'event and clk = '1';
    wait until clk'event and clk = '1';
    wait until clk'event and clk = '1';
    wait until clk'event and clk = '1';
    nRst <= '1';
    -- Fin de reset
    wait for 10*Tclk;
    wait until clk'event and clk = '1';
    wait for 10 ms;
    wait until clk'event and clk = '1';
	
    -- Fin del test
    assert false
    report "fin del test de MEDTH"
    severity failure;

  end process;
end test;
