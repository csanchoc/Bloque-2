-- Fichero control_i2c.vhd
-- Modelo VHDL 2002 de un circuito que genera las segnales de control para los modulos de la arquitectura
-- de una interfaz FAST I2C
-- El reloj del circuito es de 50 MHz (Tclk = 20 ns)

-- Especificación funcional y detalles de la implementación:

-- 1.- Interfaz externo (entradas ini, ena_byte, nWR_byte_1 y salidas fin_tx, tx_ok y fin_byte)
-- Especificacion: El modulo controla la realizacion de escrituras o lecturas de un numero indeterminado de bytes sobre el
-- bus I2C. El modulo indica su disponibilidad para la realizacion de una transferencia mediante la salida fin_tx, que esta 
-- activa tras el reset asincrono, se desactiva durante el transcurso de la transaccion y se vuelve a activar cuando dicha 
-- transaccion se completa. La salida tx_ok, indica, a nivel alto, que la transaccion se ha realizado con exito. Su valor 
-- debe testearse cuando se activa fin_tx. Cuando la entrada ini se activa, a nivel alto, durante al menos un periodo de reloj, 
-- estando la salida fin_tx a 1 y la entrada ena_byte a 1, el modulo comienza a secuenciar una transferencia. La entrada nWR_byte_1 
-- corresponde al bit de menor peso del byte de direccion (tipo de operacion); su valor solo resulta relevante en el primer flanco
-- de reloj en que ini esta activa. Cada vez que se completa la transferencia de un byte, el modulo activa  la salida fin_byte; entonces, 
-- si ena_byte vale 1, la transferencia continua, si vale 0, se genera la secuencia de STOP para finalizarla. La entrada ena_byte 
-- debe desactivarse durante la transferencia del ultimo byte de una transaccion (por ejemplo, en el ciclo de reloj siguiente al de la 
-- activacion de fin_byte en el penultimo byte de la transaccion) 

-- 2.- Interfaz con el registro de salida SDA (reg_out_SDA)
-- Especificacion: El modulo de control genera segnales para ordenar 
--     a.- la condicion de start, la preparacion de stop y la generacion de AK (puesta a 0 de SDA): reset_SDA 
--     b.- la condicion de stop (puesta a 1 de SDA): preset_SDA
--     c.- desplazamiento de bit a la linea SDA: desplaza_reg_out_SDA
--     d.- la carga del siguiente byte a transmitir: carga_reg_out_SDA
--
-- Detalles de implementacion: Las segnales anteriores se generan en base a la informacion de temporizacion 
-- proveniente del modulo gen_SCL:
--     a.- ena_out_SDA: controla la generacion de la orden de desplazamiento, de ACK y la preparacion de STOP
--     b.- ena_stop_i2c: controla la orden de STOP
--     c.- ena_in_SDA: en el estado de lectura de ACK se emplea para evolucionar al estado de carga de un nuevo byte 
--     
-- 3.- Interfaz con el registro de entrada SDA (reg_in_SDA)
--
--     a.- reset_reg_in_SDA: es una salida que se pone a nivel alto al inicio de una transacción (en el puso de ini) para
--         el registro donde se leen los bytes de la transaccion.
--
--     b.- leer_bit_SDA: es una salida que indica al registro de desplazamiento que lee los bytes transferidos que debe capturar
--         un nuevo bit.
--         Detalles de implementacion: leer_bit_SDA coincide con la segnal ena_in_SDA en todos los pulsos de reloj salvo en el 
--         correspondiente  al ACK, en el que se suprime.
--         Detalles de implementación: innecesarios
--  
-- 4.- Interfaz con el generador de SCL (gen_SCL)
-- Especificacion: La salida ena_SCL se activa inmediatamente despues de la recepcion de un pulso en ini, habilitando entonces la 
-- generacion de SCL y se desactiva tras la indicación del flanco de subida del reloj SCL (SCL_up = '1') cuando se cierra la 
-- transaccion.
--
--
-- 5.- Detalles de implementacion del modulo: EL modulo se materializa mediante un automata que integra un contador de pulsos que 
--     permite determinar el fin del envio de un byte y observar el ACK correspondiente
--
-- Nota: el modelo del automata integra el modelo del contador, el control de las salidas fin_byte, fin_tx y tx_ok y segnales de
--       estado que determinan si el byte en curso se lee o escribe, para simplificar el codigo y facilitar su legibilidad.
--
--    Designer: DTE
--    Versión: 1.0
--    Fecha: 24-11-2016

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ctrl_i2c is
port(clk:           in std_logic;
     nRst:          in std_logic;

     -- Entradas de control externo
     ini:           in std_logic;                    -- Orden de inicio de transaccion
     ena_byte:      in std_logic;                    -- Orden de continuacion de transaccion
     nWR_byte_1:    in std_logic;                    -- nW/R, ('0' escribir un byte, '1' leer) 

     -- Entradas de temporizacion del bus I2C
     ena_in_SDA:    in std_logic;                    -- Habilita lectura de SDA
     ena_out_SDA:   in std_logic;                    -- Habilita escritura de SDA
     ena_stop_i2c:  in std_logic;                    -- Habilita señalización de stop
     ena_start_i2c: in std_logic;                    -- Indica disponibilidad para una nueva transaccion
     SCL_up:        in std_logic;                    -- Flancos de subida de SCL

     -- Entrada SDA filtrada
     SDA:           in std_logic;                    -- linea SDA filtrada

     -- Salidas para el control externo
     fin_tx:        buffer std_logic;                -- Fin de transaccion  
     tx_ok:         buffer std_logic;                -- Transaccion completada correctamente
     fin_byte:      buffer std_logic;                -- Fin de escritura/lectura de byte

     -- Salida de control del generador de temporizaciones y SCL
     ena_SCL:       buffer std_logic;                -- Habilitación de generación de SCL

     -- Salidas de control del registro de escritura de SDA
     carga_reg_out_SDA:    buffer std_logic;         -- Orden de carga de dato
     reset_SDA:            buffer std_logic;         -- Reset de salida a linea SDA
     preset_SDA:           buffer std_logic;         -- Set de salida a linea SDA
     desplaza_reg_out_SDA: buffer std_logic;         -- Habilitacion de escritura de bit

     -- Salidas de control del registro de lectura de SDA
     leer_bit_SDA:         buffer std_logic;         -- Habilitacion de lectura de bit
     reset_reg_in_SDA:     buffer std_logic);        -- Reset del registro de lectura

end entity;

architecture rtl of ctrl_i2c is
-- Estado del gestor del bus y segnales de control derivadas
  type t_estado is (libre, cargar_byte, tx_byte, ACK, inhabilitar_SCL, stop);
  signal estado: t_estado;

-- Contador del numero de pulsos y bytes
  signal cnt_pulsos_SCL:   std_logic_vector(3 downto 0);

-- Tipo de operacion (lectura o escritura)
  signal nWR_1: std_logic; 
  signal nWR:   std_logic; 

-- Segnal auxiliar para simplificar codigo de modelado de ACK de lectura
  signal ACK_lectura: std_logic;

begin
  -- Maquina de estados para el control de transacciones
  process(clk, nRst)
  begin
    if nRst = '0' then
      estado         <= libre;
      cnt_pulsos_SCL <= "0000";                       -- Cuenta pulsos de SCL
      fin_tx         <= '1';                                  
      tx_ok          <= '0';                                   
      nWR_1          <= '0';
      nWR            <= '0';        
      fin_byte       <= '0';

    elsif clk'event and clk = '1' then
      case estado is
        when libre =>                                 -- Preparado para transmitir
          if ini = '1' then                           -- Orden de start
            estado <= cargar_byte;                    -- Cargar el primer byte (Add + nW/R)
            fin_tx <= '0';
            tx_ok  <= '0';
            nWR_1 <= nWR_byte_1;                      -- Registra el tipo de operacion (para restantes bytes)
            nWR    <= '0';                            -- En el primer byte, el master "escribe" sea nW o R

          end if;

        when cargar_byte =>                           -- Carga byte (cargar_Reg_out_SDA <= '1') antes de 1er pulso SCL
          estado <= tx_byte;
          cnt_pulsos_SCL <= "0000";                   -- Inicializa
          fin_byte <= '0';                            -- se desactiva el flag de fin de byte

        when tx_byte =>                               -- Espera hasta que se completa la transmisión
          if cnt_pulsos_SCL = 8 then                  -- de un byte para ir a comprobación de ACK
            estado <= ACK;

          elsif ena_in_SDA = '1' then                 -- En cada pulso de SCL incrementa la cuenta
            cnt_pulsos_SCL <= cnt_pulsos_SCL + 1;

          end if;

        when ACK =>
          if SDA = '0' and ena_in_SDA = '1' then         -- ACK recibido
            fin_byte <= '1';                             -- Indica en la interfaz que se ha terminado de recibir o enviar un byte
            if ena_byte = '0' and nWR = '0' then         -- Si es el ultimo byte de una escritura
              estado <= inhabilitar_SCL;                 -- se procede a liberar SCL
              tx_ok <= '1';                              -- Escritura correcta

            else                                         -- En el resto de casos, se procede con el 
              estado <= cargar_byte;                     -- siguiente byte
              nWR    <= nWR_1;                           -- Despues de Add + nW_R, se establece el tipo de operación

            end if;
   
          elsif SDA = '1' and ena_in_SDA = '1' then      -- NACK
            if ena_byte = '0' and nWR = '1' then         -- Si es el ultimo byte de una lectura => OK
              tx_ok <= '1';                              -- Si no, tx_ok valdrá '0'
              fin_byte <= '1';                           -- Indica en la interfaz que se ha terminado de recibir o enviar un byte

            end if;
            estado <= inhabilitar_SCL;                   -- En cualquiera de los dos casos 
                                                         -- se procede a liberar SCL          
          end if;

        when inhabilitar_SCL =>                          -- Despues del pulso de ACK de SCL, se 
          fin_byte <= '0';                               -- se desactiva el flag de fin de byte
          if SCL_up = '1' then                           -- libera la línea y se procede a cerrar
            estado <= stop;                              -- señalando un stop

          end if;
     
        when stop => 
          if ena_start_i2c = '1' then                 -- Cuando transcurre el tiempo que permite
            estado  <= libre;                         -- realizar un nuevo start, se va al estado
            fin_tx  <= '1';                           -- "libre"

          end if;
      end case;
    end if;
  end process;
  --************************************************************************************************************

  -- Control del generador de SCL:

  ena_SCL <= '1' when estado = cargar_byte or estado = tx_byte or estado = ACK else -- Se habilita tras ini
             '1' when estado = inhabilitar_SCL                                 else -- Se inhabilita cuando SCL_up vale 1
             '0';                                                                   -- en el flanco de subida de SCL despues de ACK
  --************************************************************************************************************

  -- Control del registro de salida: 

  carga_reg_out_SDA    <= not nWR when estado = cargar_byte       -- Carga el byte a transmitir... 
                          else '0';                               -- ...preservando el valor de SDA (bit mas alto del registro)

  reset_SDA <= ini         when estado = libre           else     -- Condicion de start  (ini cuando estado = libre)
               ena_out_SDA when estado = inhabilitar_SCL else     -- Preparacion de stop (cambio de SDA cuando estado = inhabilitar)
               ena_out_SDA when ACK_lectura = '1'        else     -- ACK a byte leido
               '0';

  ACK_lectura <= (nWR and ena_byte) when estado = ACK else        -- en una operacion de lectura deben asentirse todos los bytes leidos
                 '0';                                             -- menos el ultimo

  preset_SDA <= ena_stop_i2c when estado = stop                   -- Condición de stop(segnalizacion de gen_SCL cuando estado = stop)
                else '0';                                         -- Nota 1: estado = stop es redundante -se deja por claridad
                                                                  -- Nota 2: reset_SDA y preset_SDA solo 
                                                                  -- afectan al bit de mayor peso del registro de 
                                                                  -- desplazamiento de salida 

  desplaza_reg_out_SDA <= ena_out_SDA when estado = tx_byte or estado = ACK -- Se desplaza el dato cuando lo indica la segnal de gen_SCL
                          else '0';                                         -- Nota: el estado es redundante -se deja por claridad
                                                                            -- Nota: Esta segnal de control tiene menos prioridas
                                                                            -- que reset_SDA y preset_SDA
  --************************************************************************************************************

  -- Control del registro de entrada:

  leer_bit_SDA <= ena_in_SDA when estado /= ACK else              -- Se capturan todos los valores menos el ACK
                  '0';

  reset_reg_in_SDA <= ini when estado = libre else                -- Se resete al principio de cualquier tx
                      '0'; 

end rtl;