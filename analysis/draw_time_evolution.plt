set xl "scan number"
set xtics out
set mxtics
unset y2l
unset y2tics
set yl "ion current (A)"
set sty data impulses
set termoption noenhanced

set yr [0:*]

set title sprintf("Mass spectrogram from %s (%d), m/z %d ", fn, runid, mz)

# preprocess the data file with awk, the %c hack is needed because 
# gnuplot's call mechanism would eat the literal $
cmd = sprintf("<awk '%c2==%d' %s",36, mz, fn) 
plot cmd u 1:3 w lp tit "Intensity",\
	cmd u 1:(column(3) < 0 ? 0 : 1/0) w p pt 7 lc rgb 'red' tit "Missing data"

