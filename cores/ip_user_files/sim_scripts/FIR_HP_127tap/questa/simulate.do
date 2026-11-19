onbreak {quit -f}
onerror {quit -f}

vsim  -lib xil_defaultlib FIR_HP_127tap_opt

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure
view signals

do {FIR_HP_127tap.udo}

run 1000ns

quit -force
