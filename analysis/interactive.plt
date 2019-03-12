files = "\
	DR005388_F00001.PHYS.decoded\
	DR005388_F00002.PHYS.decoded\
	DR005388_F00003.PHYS.decoded\
	DR005388_F00004.PHYS.decoded\
	DR005388_F00005.PHYS.decoded\
	DR005388_F00006.PHYS.decoded\
	DR005388_F00007.PHYS.decoded\
	DR005388_F00008.PHYS.decoded\
	DR005388_F00009.PHYS.decoded\
	DR005388_F00010.PHYS.decoded\
	DR005631_F00001.PHYS.decoded\
	DR005631_F00002.PHYS.decoded\
	DR005631_F00003.PHYS.decoded\
	DR005631_F00004.PHYS.decoded\
	DR005631_F00005.PHYS.decoded\
	DR005631_F00006.PHYS.decoded\
"

i = 1
fi = 1
fn = word(files, fi)

bind h "fi = fi - 1; fn = word(files, fi); call 'draw_mass_spectrogram.plt'"
bind l "fi = fi + 1; fn = word(files, fi); call 'draw_mass_spectrogram.plt'"
bind j "i = i - 1; call 'draw_mass_spectrogram.plt'"
bind k "i = i + 1; call 'draw_mass_spectrogram.plt'"

call 'draw_mass_spectrogram.plt'
