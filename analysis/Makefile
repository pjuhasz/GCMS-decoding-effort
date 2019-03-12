V1PATH="../Digital-files-raw-from-NSSDCA/5631 (VL-1)"
V2PATH="../Digital-files-raw-from-NSSDCA/5388 (VL-2)"

decode:
	for f in $(V1PATH)/* $(V2PATH)/*; do g=`basename "$$f"`; perl decode_reduced_dataset.pl "$$f" > "$$g.decoded"; done

clean:
	rm -rf *.decoded

PHONY: decode clean
