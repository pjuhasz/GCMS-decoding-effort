#!/bin/bash

dir=spectrograms
mkdir -p $dir
for f in *.decoded; do
	scans=$(grep -m 1 "Number of scans" "$f" | cut -f 2)
	runid=$(grep -m 1 "Run number" "$f" | cut -f 2)
	for i in `seq 1 $scans`; do
		out="$dir/${f/.decoded/}_m_$i.svg"
		gnuplot -e "set term svg size 1000,400 dynamic butt; set out '$out'; fn='$f'; runid=$runid; i=$i; call 'draw_mass_spectrogram.plt'; set out"
	done
	for m in {12..220}; do
		out="$dir/${f/.decoded/}_t_$m.svg"
		gnuplot -e "set term svg size 1000,400 dynamic butt; set out '$out'; fn='$f'; runid=$runid; mz=$m; call 'draw_time_evolution.plt'; set out"
	done
done
