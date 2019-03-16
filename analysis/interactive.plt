call 'files.plt'

# interactive modes
# 0 mass spectrograms
# 1 time evolution plot
mode = 0

#initial state
i = 1
fi = 1
mz = 12

drawmass = "eval select; call 'draw_mass_spectrogram.plt'"
drawtime = "eval select; call 'draw_time_evolution.plt'"

bind m "mode = 1 - mode; if (mode==0) {eval drawmass} else {eval drawtime}"

bind Down  "fi = fi - 1; if (mode==0) {eval drawmass} else {eval drawtime}"
bind Up    "fi = fi + 1; if (mode==0) {eval drawmass} else {eval drawtime}"
bind Left  "if (mode==0) {i = i - 1; eval drawmass} else {mz = mz - 1; eval drawtime}"
bind Right "if (mode==0) {i = i + 1; eval drawmass} else {mz = mz + 1; eval drawtime}"

if (mode==0) {eval drawmass} else {eval drawtime}
