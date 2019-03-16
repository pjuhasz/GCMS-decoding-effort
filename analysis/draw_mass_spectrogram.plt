
set ytics nomirror
set y2tics
set xtics out
set mxtics
set xl "m/z"
set yl "ion current (A)"
set y2l "ion current (A)"
set sty data impulses
set termoption noenhanced

set yr [0:*]
set y2r [0:*]

set title sprintf("Mass spectrogram from %s (%d), scan %d ", fn, runid, i)

plot fn u 2:3 ev :::i-1::i-1 lw 2 tit "All ions", \
	fn u 2:(column(2) > 47 ? column(3) : 0) ev :::i-1::i-1 axes x1y2 lw 2 tit "Peaks < 47 deleted", \
	fn u 2:(column(3) < 0 ? 0 : 1/0) ev :::i-1::i-1 w p pt 7 lc rgb 'red' tit "Missing data"