# initialize simulation

vsim -gui work.test_top(test)

# add signals to wave window

add wave -position inserpoint -divider "I/O signals" \
sim:/test_top/clk \
sim:/test_top/nRst \
sim:/test_top/SDA \
sim:/test_top/SCL 

add wave -position insertpoint -divider "Procesador Medida"  \
sim:/test_top/dut/THPROC/clk \
sim:/test_top/dut/THPROC/nRst \
sim:/test_top/dut/THPROC/tic_0_25s \
sim:/test_top/dut/THPROC/we \
sim:/test_top/dut/THPROC/rd \
sim:/test_top/dut/THPROC/add \
sim:/test_top/dut/THPROC/dato_w \
sim:/test_top/dut/THPROC/dato_r \
sim:/test_top/dut/THPROC/dato_leido \
sim:/test_top/dut/THPROC/estado 

# run simulation

run -all