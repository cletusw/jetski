restart
isim force add clk 1 -time 0 -value 0 -time 10ns -repeat 20ns
put rst 1
run 30ns
put rst 0

run 500ns