-- Este modulo realiza el disparo de una captura de temperatura y humedad, escribiendo en
-- el puntero del sensor (direccion I2C x40) la direccion del registro de temperatura (x00);
-- el disparo consiste, por tanto en una escritura I2C de 2 bytes, que se realiza coincidiendo 
-- con la ocurrencia de un tic que tiene un periodo de 0.25 segundos.
-- En el siguiente tic se lee la temperatura y la humedad en una lectura I2C de 4 bytes; el valor 
-- leido de ambas magnitudes se convierte a BCD y se entrega por las salidas temp_BCD, sgn_T y humd_BCD.

--    Designer: DTE
--    Versi�n: 1.0
--    Fecha: 25-11-2016 
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity procesador_medida is
port(clk:         in     std_logic;
     nRst:        in     std_logic;

     -- Temporizacion
     tic_0_25s:   in     std_logic;
    
     -- Interfaz periferico I2C
     we:          buffer std_logic;
     rd:          buffer std_logic;
     add:         buffer std_logic_vector(1 downto 0);
     dato_w:      buffer std_logic_vector(7 downto 0);
     dato_r:      in     std_logic_vector(7 downto 0);

     -- Interfaz presentacion
     dato_leido:    buffer std_logic_vector(15 downto 0)
    );          

end entity;

architecture rtl of procesador_medida is
 
--  type   t_estado is (espera_tic, escritura1, escritura2, escritura3, escritura4, 
--                     escritura5, comando_escritura, chequeo_fin_escr, lectura1, 
--                      lectura2, comando_lectura, chequeo_fin_lec, lectura3, lectura4);
  type   t_estado is (espera_tic, escritura1, escritura2, escritura3, escritura4,
		      comando_escritura, chequeo_fin_escr);


  signal estado: t_estado;

 
 begin
  -- Automata de prueba
  -- Realiza una operacion de escritura y una de lectura cada 0.25 segundos
  process(clk, nRst)
  begin
    if nRst = '0' then
      estado <= espera_tic;
      we <= '0';
      rd <= '0';
      add <= "11"; -- apunta al registro de configuracion/status
      dato_w <= X"00"; 
--      dato_leido <= X"0000";
    elsif clk'event and clk = '1' then
      case(estado) is
        when espera_tic =>
--          if dato_r(0) = '1' and tic_0_25s = '1' then -- bit 0 status = 1-> listo para nueva operacion (no es necesario activar rd)
 	  if tic_0_25s = '1' then
            we <= '1'; -- escritura
            add <= "00"; -- @FIFO de salida
            dato_w <= "1000000" & '0'; -- 0x40 (dir. I2C del esclavo, cambiarla por la real) & 0 (operacion de escritura I2C)
            estado <= escritura1;
          end if;
        when escritura1 =>
          -- adaptar valor y n� de escriturasa la aplicacion
          dato_w <= "00000000";
          estado <= escritura2;
        when escritura2 =>
          -- adaptar valor y n� de escriturasa la aplicacion
          dato_w <= "00000000";
          estado <= escritura3;
        when escritura3 =>
          -- adaptar valor y n� de escriturasa la aplicacion
          dato_w <= "00000000";
          estado <= escritura4;
        when escritura4 =>
          -- adaptar valor y n� de escriturasa la aplicacion
--          dato_w <= "00000000";
--          estado <= escritura5;
          add <= "11"; -- apunta al registro de configuracion/status
          dato_w <= x"05"; -- start transaction
          estado <= comando_escritura;
--       when escritura5 =>
--          add <= "11"; -- apunta al registro de configuracion/status
--          dato_w <= x"05"; -- start transaction
--          estado <= comando_escritura;
        when comando_escritura =>
          we <= '0';
          estado <= chequeo_fin_escr;
        when chequeo_fin_escr =>
--          if dato_r(0) = '1' then -- bit 0 status = 1-> listo para nueva operacion (no es necesario activar rd)
            we <= '1';
--            add <= "00";
            add <= "11";
            dato_w <= "1000000" & '1'; -- 0x40 (dir. I2C del esclavo, cambiarla por la real) & 1 (operacion de lectura I2C)
 	    estado <= espera_tic;	
--           estado <= lectura1;
--          end if;
 --         add <= "01";
  --        dato_w <= "00000010"; -- se leen 2 datos, adaptar a la aplicacion
--          estado <= lectura2;
--        when lectura2 =>
--          add <= "11";
--          dato_w <= x"05";
--          estado <= comando_lectura;
--        when comando_lectura => 
--          we <= '0';
--          estado <= chequeo_fin_lec;
--        when chequeo_fin_lec =>    
--          if dato_r(0) = '1' then
--            add <= "00";
--            rd <= '1'; 
--            estado <= lectura3;
--          end if;
--        when lectura3 =>
--          dato_leido(7 downto 0) <= dato_r; -- lee primer dato
--          estado <= lectura4;
--        when lectura4 =>
--          dato_leido(15 downto 8) <= dato_r; -- lee segundo dato, dato_leido no se usa (adaptar a la aplicacion)
--          rd <= '0';
--          add <= "11";
--          estado <= espera_tic;
      end case;
    end if;
  end process;
end rtl;