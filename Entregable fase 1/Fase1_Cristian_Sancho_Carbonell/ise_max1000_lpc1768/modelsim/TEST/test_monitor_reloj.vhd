library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.pack_test_reloj.all;

entity test_monitor_reloj is
port(clk:         in std_logic;
     nRst:        in std_logic;
     tic_025s:    in std_logic;
     tic_1s:      in std_logic;
     ena_cmd:     in std_logic;
     cmd_tecla:   in std_logic_vector(3 downto 0);
     pulso_largo: in std_logic;
     modo:        in std_logic;
     info:        in std_logic_vector(1 downto 0);
     segundos:    in std_logic_vector(7 downto 0);
     minutos:     in std_logic_vector(7 downto 0);
     horas:       in std_logic_vector(7 downto 0);
     AM_PM:       in std_logic
    );
end entity;

architecture test of test_monitor_reloj is

begin


  -- MONITOR 1
  -- Verificacion de valor válido en los campos segundos, minutos y horas
  process(clk, nRst)
    variable ena_assert: boolean := false;
 
  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and tic_1s = '1' and ena_assert then
      assert segundos(3 downto 0) < 10
      report "Error: valor inválido en unidades de segundo"
      severity error;

      assert segundos(7 downto 4) < 6
      report "Error: valor inválido en decenas de segundo"
      severity error;

      assert minutos(3 downto 0) < 10
      report "Error: valor inválido en unidades de minuto"
      severity error;

      assert minutos(7 downto 4) < 6
      report "Error: valor inválido en decenas de minuto"
      severity error;

      if modo = '0' and horas(7 downto 4) = 1 then
        assert horas(3 downto 0) < 2
        report "Error: valor inválido en unidades de hora"
        severity error;

      elsif modo = '0' then
        assert horas(3 downto 0) < 10
        report "Error: valor inválido en unidades de horas"
        severity error;

      elsif modo = '1' and horas(7 downto 4) = 2 then
        assert horas(3 downto 0) < 4
        report "Error: valor inválido en unidades de hora"
        severity error;

      elsif modo = '1' then
        assert horas(3 downto 0) < 10
        report "Error: valor inválido en unidades de horas"
        severity error;
      
      end if;

      if modo = '0' then
        assert horas(7 downto 4) < 2
        report "Error: valor inválido en decenas de horas"
        severity error;

      elsif modo = '1' then
        assert horas(7 downto 4) < 3
        report "Error: valor inválido en decenas de horas"
        severity error;

      end if;
    end if;
  end process;

  
  -- MONITOR 2
  -- Verifica el correcto incremento de la hora y que el reloj se detiene cuando se programa
  process(clk, nRst)
    variable hora_T1:    std_logic_vector(23 downto 0);
    variable ena_assert: boolean := false;
    variable info_T1: std_logic_vector(1 downto 0);
    variable programado: std_logic := '1';
	
  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      if tic_1s = '1' and info = 0 and info_T1 = 0 and (horas&minutos&segundos) /= 0 and programado = '0' then
        assert (hora_to_natural(hora_T1) + 1) = hora_to_natural(horas&minutos&segundos)

        report "Error de discontinuidad horaria"
        severity error;

      elsif tic_1s = '1' and info = 0 and info_T1 = 0 and programado = '0' then
        assert (hora_T1 = X"115959" and modo = '0') or (hora_T1 = X"235959" and modo = '1')

        report "Error de discontinuidad horaria"
        severity error;





      elsif info_T1 /= 0 then
        assert segundos = 0
        report "Error: el reloj se mueve sin motivo"
        severity error;

      end if;


	  
      if info /= 0 or (ena_cmd = '1' and cmd_tecla = X"D") then
		programado := '1';
		
	  elsif tic_1s = '1' then
		programado := '0';
		
	  end if;
	  
	  if tic_1s = '1' then
		hora_T1 := horas&minutos&segundos;
	  end if;

      info_T1 := info;


    end if;
  end process;


  -- MONITOR 3
  -- Funcionamiento correcto de AM-PM
  process(clk, nRst)
    variable ena_cmd_T1: std_logic;
    variable tecla_T1:   std_logic_vector(3 downto 0);
    variable AM_PM_T1:   std_logic;

    variable modo_T1:    std_logic;
    variable ena_assert: boolean := false;

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1'  and tic_1s = '1' and ena_assert then
      if info = 0 and modo = '0' then
        if (horas&minutos&segundos) = 0  then

          assert AM_PM_T1 /= AM_PM
          report "Error en cambio de AM-PM: no cambia"
          severity error;

        else

          assert AM_PM_T1 = AM_PM
          report "Error en AM-PM: cambia cuando no debe"
          severity error;   

       end if;

      elsif info = 0 and modo = '1' then
        if (horas&minutos& segundos) < X"120000" then

          assert AM_PM = '0'
          report "Error en el valor de AM-PM en modo 24 horas"
          severity error;

        else

          assert AM_PM = '1'
          report "Error en el valor de AM-PM en modo 24 horas"
          severity error;   

        end if;

      elsif modo /= modo_T1 and modo = '0' then
        if horas < X"12" then

          assert AM_PM = '0'
          report "Error en el valor de AM-PM tras cambio de formato de 24 a 12"
          severity error;

        else

          assert AM_PM = '1'
          report "Error en el valor de AM-PM tras cambio de formato de 24 a 12"
          severity error;

        end if;

      end if;
      ena_cmd_T1 := ena_cmd;
      tecla_T1 := cmd_tecla;
      AM_PM_T1 := AM_PM;

      modo_T1 := modo;

    end if;
  end process; 

  
  -- MONITOR 4
  -- Funcionamiento correcto de cambio de modo
  process(clk, nRst)
    variable ena_cmd_T1: std_logic;
    variable tecla_T1:   std_logic_vector(3 downto 0);
    variable hora_T1:    std_logic_vector(23 downto 0);
    variable AM_PM_T1: std_logic;
    variable ena_assert: boolean := false;
    variable info_T1:      std_logic_vector(1 downto 0);

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      if ena_cmd_T1 = '1'  and tecla_T1 = X"D" then
        if modo = '1' then
          if AM_PM_T1 = '0' then 
            assert hora_T1 = (horas&minutos&X"00")
            report "Error en cambio de formato de hora de 12 a 24"
            severity error;

          else
            assert (hora_to_natural(hora_T1) + 12*3600) = hora_to_natural(horas&minutos&X"00")
            report "Error en cambio de formato de hora de 12 a 24"
            severity error;

          end if;

        elsif hora_T1 < X"120000" then
            assert hora_T1 = (horas&minutos&X"00")
            report "Error en cambio de formato de hora de 24 a 12"
            severity error;

        else
          assert (hora_to_natural(hora_T1) - 12*3600) = hora_to_natural(horas&minutos&X"00")
          report "Error en cambio de formato de hora de 24 a 12"
          severity error;

        end if;
      end if;
      ena_cmd_T1 := ena_cmd;
      tecla_T1 := cmd_tecla;
      hora_T1 := horas&minutos&X"00";
      AM_PM_T1 := AM_PM;

    end if;
  end process;

  
  -- MONITOR 5
  -- Verificación del comando de pasar a modo de programación de reloj
  process(clk, nRst)
    variable cmd_tecla_T1:   std_logic_vector(3 downto 0);
    variable ena_assert:     boolean := false;
    variable pulso_largo_T1: std_logic;
    variable info_T1:        std_logic_vector(1 downto 0);

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      if pulso_largo_T1 = '1' and cmd_tecla_T1 = X"A" and info_T1 = 0 then
        assert  info = 2

        report "Error: ignorado comando de paso a modo de programación"
        severity error;
      end if;

      cmd_tecla_T1 := cmd_tecla;
      pulso_largo_T1 := pulso_largo;
      info_T1 := info;

    end if;
  end process;   

 
  -- MONITOR 6
  -- Verificación del comando de fin de programación de reloj
  process(clk, nRst)
    variable cmd_tecla_T1: std_logic_vector(3 downto 0);
    variable ena_assert:   boolean := false;
    variable ena_cmd_T1:   std_logic;
    variable info_T1:      std_logic_vector(1 downto 0);

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      if ena_cmd_T1 = '1' and cmd_tecla_T1 = X"A" and info_T1 /= 0 then
        assert  info = 0
        report "Error: ignorado comando de fin de modo de programación"
        severity error;
      end if;


      cmd_tecla_T1 := cmd_tecla;
      ena_cmd_T1 := ena_cmd;
      info_T1 := info;

    end if;
  end process;

  
  -- MONITOR 7
  -- Verificación de time-out
  process(clk, nRst)
    variable info_T1:    std_logic_vector(1 downto 0);
    variable cnt: natural := 0;
    variable ena_assert: boolean := false;

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;
      cnt := 0;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      info_T1 := info;

      if info_T1 = 0 or ena_cmd = '1' or pulso_largo = '1' then
        cnt := 0;

      elsif cnt = 7 then
        cnt := 0;
        assert info = 0
        report "Error: ignorado time-out de fin de programación"
        severity error;

      elsif tic_1s = '1' and ena_cmd = '0' then
        cnt := cnt + 1;       

      end if;
    end if;
  end process;
  

  -- MONITOR 8
  -- Verificación de comando de cambio de campo
  process(clk, nRst)
    variable info_T1:    std_logic_vector(1 downto 0);
    variable ena_assert: boolean := false;
    variable ena_cmd_T1: std_logic;
    variable cmd_tecla_T1: std_logic_vector(3 downto 0);

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0'then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      if ena_cmd_T1 = '1' and cmd_tecla_T1 = X"B" and info_T1 /= 0 then
        if info_T1 = 1 then
          assert info = 2

          report "Error en el funcionamiento del comando de paso de edicion de horas"
          severity error;

        else
          assert info = 1

          report "Error en el funcionamiento del comando de paso a edicion de minutos"
          severity error;

        end if;

      end if;
      cmd_tecla_T1 := cmd_tecla;
      ena_cmd_T1 := ena_cmd;
      info_T1 := info;

    end if;
  end process;

  
  -- MONITOR 9
  -- Verificación de incremento de campo
  process(clk, nRst)
    variable hora_T1: std_logic_vector(15 downto 0);
    variable ena_assert:     boolean := false;
    variable pulso_largo_T1: std_logic;
    variable tic_025s_T1:     std_logic;
    variable cmd_tecla_T1:   std_logic_vector(3 downto 0);
    variable info_T1: std_logic_vector(1 downto 0);
    variable ena_cmd_T1: std_logic;

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      if ((pulso_largo_T1 = '1' and cmd_tecla_T1 = X"C" and tic_025s_T1 = '1') or 
		  (ena_cmd_T1 = '1' and cmd_tecla_T1 = X"C")) and info_T1 /= 0 then
		  
		-- minutos  
        if info_T1 = 1 then
		  if minutos /= 0 then -- si minutos no es "00"

			if minutos(3 downto 0) /= 0 then  -- Si minutos no es "X0"
				assert ((hora_T1(7 downto 0) + 1) = minutos) and horas = hora_T1(15 downto 8) 
				report "Error en incremento de minutos "
				severity error;
				
			else  -- Minutos es "X0"
				assert ((hora_T1(7 downto 4) + 1) = minutos(7 downto 4)) and
                     hora_T1(3 downto 0) = 9  and horas = hora_T1(15 downto 8)
				report "Error en incremento de minutos "
				severity error;
				
			end if;

  		  elsif info_T1 = 1 then  -- Minutos es "00"
			assert hora_T1(7 downto 0) = X"59" and horas = hora_T1(15 downto 8)
			report "Error en incremento de minutos "
			severity error;

  		  end if;
		  
		-- horas  
		else  
		  if horas /= 0 then
		  
			if horas(3 downto 0) /= 0 then
				assert ((hora_T1(15 downto 8) + 1) = horas) and minutos = hora_T1(7 downto 0)
				report "Error en incremento de horas"
				severity error;

			else
				assert ((hora_T1(15 downto 12) + 1) = horas(7 downto 4)) and 
                     hora_T1(11 downto 8) = 9  and minutos = hora_T1(7 downto 0)
				report "Error en incremento de horas"
				severity error;

			end if;

          elsif modo = '0' then  -- horas es "00"
			assert hora_T1(15 downto 8) = X"11" and minutos = hora_T1(7 downto 0)
			report "Error en incremento de horas"
			severity error;

          else		-- horas es "00"
			assert hora_T1(15 downto 8) = X"23" and minutos = hora_T1(7 downto 0)
			report "Error en incremento de horas"
			severity error;
		  
        end if;
      end if;
	 end if;
	 
      hora_T1 := horas&minutos;
      pulso_largo_T1 := pulso_largo;
      tic_025s_T1 := tic_025s;
      cmd_tecla_T1 := cmd_tecla;
      info_T1 := info;
      ena_cmd_T1 := ena_cmd;

    end if;
  end process;


  -- MONITOR 10
  -- Verificación de la edicion directa de campo
  process(clk, nRst)
    variable hora_T1: std_logic_vector(15 downto 0);
    variable ena_assert:     boolean := false;
    variable cmd_tecla_T1:   std_logic_vector(3 downto 0);
    variable dato_ant:   std_logic_vector(3 downto 0);
    variable info_T1: std_logic_vector(1 downto 0);
    variable ena_cmd_T1: std_logic;

  begin
    if nRst'event and nRst = '0' then
      ena_assert := false;

    elsif nRst'event and nRst = '1' and nRst'last_value = '0' then
      ena_assert := true;

    elsif clk'event and clk = '1' and ena_assert then
      if ena_cmd_T1 = '1' and cmd_tecla_T1 < 10 and info_T1 /= 0 then
		-- minutos  
        if info_T1 = 1 then
		  if ((dato_ant&cmd_tecla_T1) < X"60" and cmd_tecla_T1 < 10) then
			assert minutos = (dato_ant&cmd_tecla_T1)
			report "Error de escritura directa de minutos"
			severity error;
			
		  end if;
		  
		-- horas  
		else  
		  if modo = '1' and (dato_ant&cmd_tecla_T1) < X"24" and cmd_tecla_T1(3 downto 0) < 10 then
			assert horas = (dato_ant&cmd_tecla_T1)
			report "Error de escritura directa de horas"
			severity error;
			
		  elsif modo = '0' and (dato_ant&cmd_tecla_T1) < X"12" and cmd_tecla_T1(3 downto 0) < 10 then
			assert horas = (dato_ant&cmd_tecla_T1)
			report "Error de escritura directa de horas"
			severity error;

		  end if;
        end if;
		
		dato_ant := cmd_tecla_T1;
	  elsif ena_cmd_T1 = '1' and info_T1 /= 0 then
		dato_ant := X"0";

      end if;
	 
      hora_T1 := horas&minutos;
      cmd_tecla_T1 := cmd_tecla;
      info_T1 := info;
      ena_cmd_T1 := ena_cmd;

    end if;
  end process;

  
end test;
