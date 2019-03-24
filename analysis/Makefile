V1PATH="../Digital-files-raw-from-NSSDCA/5631 (VL-1)"
V2PATH="../Digital-files-raw-from-NSSDCA/5388 (VL-2)"

decode:
	for f in $(V1PATH)/* $(V2PATH)/*; do g=`basename "$$f"`; h="$${g/.PHYS/}"; perl decode_reduced.pl "$$f" > "$$h.decoded"; done

spectrograms: decode
	./plot_all_files.sh

clean:
	rm -rf *.decoded
	rm -rf *.header
	rm -rf spectrograms

PHONY: decode clean spectrograms
