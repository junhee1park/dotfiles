#!/bin/zsh

print_header "Rex"

print_step "Create configuration symlinks"
mkdir -p $HOME/.config
rm -rf $HOME/.config/rex
ln -sf "$DOTFILES_DIR/rex" "$HOME/.config/rex"

print_success "Rex setup complete"
