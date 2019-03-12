
set ytics nomirror
set y2tics
set xtics out
set mxtics
set xl "m/z"
set yl "ion current (A)"
set y2l "ion current (A)"
set sty data impulses
set termoption noenhanced

set title "Mass spectrogram from ".fn.", scan ".i

plot fn u 2:3 ev :::i-1::i-1 lw 2 tit "All ions", \
	fn u 2:(column(2) > 47 ? column(3) : 0) ev :::i-1::i-1 axes x1y2 lw 2 tit "Peaks < 47 deleted"
