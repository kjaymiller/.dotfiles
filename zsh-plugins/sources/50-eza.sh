# eza: theme lives in ~/.config/eza/theme.yml
# Fedora's /etc/profile.d/colorls.sh exports a system LS_COLORS, and eza
# applies LS_COLORS *after* the theme file — so its di/ln/ex/pi/so/bd/cd/or
# codes and *.ext globs clobber the plum theme. Unset it so theme.yml is
# the single source of truth (ls is aliased to eza anyway).
unset LS_COLORS
