vsim -voptargs=+acc work.test_cpu
view structure wave signals

do wave.do

log -r *
run -all

