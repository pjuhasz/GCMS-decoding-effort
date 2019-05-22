call 'files.plt'

# interactive modes
# 0 mass spectrograms
# 1 time evolution plot
mode = 0

#initial state
i = 1
fi = 1
mz = 12
logs = 0

limitcmd(var, limit) = sprintf("if (%s < %d) { %s = %d }", var, limit, var, limit)

drawmass = "eval select; call 'draw_mass_spectrogram.plt'"
drawtime = "eval select; call 'draw_time_evolution.plt'"
drawcmd = "if (mode==0) {eval drawmass} else {eval drawtime}"

bind m "mode = 1 - mode; eval drawcmd"
bind l "logs = 1 - logs; eval drawcmd"

bind Down  "fi = fi - 1; eval limitcmd(\"fi\", 1); eval drawcmd"
bind Up    "fi = fi + 1; eval drawcmd"
bind Left  "if (mode==0) {i = i - 1; eval limitcmd(\"i\", 1); eval drawmass} else {mz = mz - 1; eval limitcmd(\"mz\", 12); eval drawtime}"
bind Right "if (mode==0) {i = i + 1; eval drawmass} else {mz = mz + 1; eval drawtime}"

eval drawcmd
