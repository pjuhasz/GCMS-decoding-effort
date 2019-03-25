V1RAWPATH="../Digital-files-raw-from-NSSDCA/5631 (VL-1)"
V2RAWPATH="../Digital-files-raw-from-NSSDCA/5388 (VL-2)"
V1REDPATH="../Digital-files-raw-from-NSSDCA/5289 (VL-1)"
V2REDPATH="../Digital-files-raw-from-NSSDCA/5967 (VL-2)"

decode:
	for f in $(V1RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl "$$f" > "$$h.decoded"; done
	for f in $(V2RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl "$$f" > "$$h.decoded"; done
	for f in $(V1REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v1_raw.pl "$$f" > "$$h.decoded"; done
	for f in $(V2REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v2_raw.pl "$$f" > "$$h.decoded"; done

headers:
	for f in $(V1RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl -r "$$f" > "$$h.header"; done
	for f in $(V2RAWPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl -r "$$f" > "$$h.header"; done
	for f in $(V1REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v1_raw.pl -r "$$f" > "$$h.header"; done
	for f in $(V2REDPATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_v2_raw.pl -r "$$f" > "$$h.header"; done

spectrograms: decode
	./plot_all_files.sh

clean:
	rm -rf *.decoded
	rm -rf *.header
	rm -rf spectrograms

PHONY: decode headers clean spectrograms
