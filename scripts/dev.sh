#!/bin/zsh

print_section "Development Tools"

source "$DOTFILES_DIR/scripts/dev/zsh.sh"
source "$DOTFILES_DIR/scripts/dev/git.sh"
source "$DOTFILES_DIR/scripts/dev/node.sh"
source "$DOTFILES_DIR/scripts/dev/ruby.sh"
source "$DOTFILES_DIR/scripts/dev/ghostty.sh"
source "$DOTFILES_DIR/scripts/dev/rex.sh"
source "$DOTFILES_DIR/scripts/dev/tmux.sh"
source "$DOTFILES_DIR/scripts/dev/neovim.sh"
source "$DOTFILES_DIR/scripts/dev/lazygit.sh"
source "$DOTFILES_DIR/scripts/dev/btop.sh"
source "$DOTFILES_DIR/scripts/dev/ai.sh"

print_header "GitHub CLI"
brew install gh

print_header "dasel"
brew install dasel

print_header "terminal-notifier"
brew install terminal-notifier

print_success "Development tools setup complete"
