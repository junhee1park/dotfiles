#!/bin/zsh

print_section "Utilities"

source "$DOTFILES_DIR/scripts/utilities/karabiner.sh"
source "$DOTFILES_DIR/scripts/utilities/hammerspoon.sh"

print_header "AltTab"
brew install --cask alt-tab

print_header "MonitorControl"
brew install --cask monitorcontrol

print_header "Rectangle"
brew install --cask rectangle

print_header "Cleanshot"
brew install --cask cleanshot

print_header "Logi Options plus"
brew install --cask logi-options+

print_header "SoundSource"
brew install --cask soundsource

# Restores the settings that cannot be symlinked - the apps above that keep
# theirs in a defaults domain, and Codex's config.toml.
"$DOTFILES_DIR/sync.sh" import

print_success "Utilities setup complete"
