V1REDPATH="../Digital-files-raw-from-NSSDCA/5631 (VL-1)"
V2REDPATH="../Digital-files-raw-from-NSSDCA/5388 (VL-2)"
V1RAWPATH="../Digital-files-raw-from-NSSDCA/5289 (VL-1)"
V2RAWPATH="../Digital-files-raw-from-NSSDCA/5967 (VL-2)"

decode:
	for f in $(V1REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl "$$f" > "$$h.decoded"; done
	for f in $(V2REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl "$$f" > "$$h.decoded"; done
	for f in $(V1RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v1_raw.pl "$$f" > "$$h.decoded"; done
	for f in $(V2RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v2_raw.pl "$$f" > "$$h.decoded"; done

csvs:
	for f in $(V1REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl -t -s, "$$f" > "$$h.csv"; done
	for f in $(V2REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl -t -s, "$$f" > "$$h.csv"; done
	for f in $(V1RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v1_raw.pl -t -s, "$$f" > "$$h.csv"; done
	for f in $(V2RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v2_raw.pl -t -s, "$$f" > "$$h.csv"; done

headers:
	for f in $(V1REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl -r "$$f" > "$$h.header"; done
	for f in $(V2REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl -r "$$f" > "$$h.header"; done
	for f in $(V1RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v1_raw.pl -r "$$f" > "$$h.header"; done
	for f in $(V2RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v2_raw.pl -r "$$f" > "$$h.header"; done

frames:
	for f in $(V1RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v1_raw.pl -f -H "$$f" > "$$h.frames"; done

convert: decode
	for f in $(V1RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; r="$$h.decoded"; perl convert_raw.pl -c "$$r" > "$$h.converted"; done
	for f in $(V2RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; r="$$h.decoded"; perl convert_raw.pl -c "$$r" > "$$h.converted"; done

spectrograms: decode
	./plot_all_files.sh

clean:
	rm -rf DR*.decoded
	rm -rf DR*.header
	rm -rf DR*.converted
	rm -rf DR*.csv
	rm -rf spectrograms

PHONY: decode headers clean spectrograms csvs
