V1PATH="../Digital-files-raw-from-NSSDCA/5631 (VL-1)"
V2PATH="../Digital-files-raw-from-NSSDCA/5388 (VL-2)"

decode:
	for f in $(V1PATH)/* $(V2PATH)/*; do g=`basename "$$f"`; perl decode_reduced_dataset.pl "$$f" > "$$g.decoded"; done

# TODO parse run id and number of scan from files
spectrograms: decode
	mkdir -p spectrograms
	#gnuplot -e 'set term svg; set out "fos.svg"; i=30; fi=10; load "files.plt"; eval select; sh var; call "draw_mass_spectrogram.plt"'

timeplots: decode
	mkdir -p timeplots

clean:
	rm -rf *.decoded
	rm -rf spectrograms
	rm -rf timeplots

PHONY: decode clean
