#!/bin/zsh

# Not part of the default install: needs 1Password signed in, with
# Settings > Developer > "Integrate with 1Password CLI" turned on.

print_header "SSH"

print_step "Copy GitHub SSH keys from 1Password"
brew install --cask 1password-cli
mkdir -p ~/.ssh && chmod 700 ~/.ssh
for file item in github_auth "GitHub Authentication" github_sign "GitHub Signing"; do
  op read --force --out-file ~/.ssh/$file "op://Private/$item/private_key?ssh-format=openssh" || return 1
  op read --force --out-file ~/.ssh/$file.pub "op://Private/$item/public_key" || return 1
done

print_step "Create SSH config symlink"
ln -sf "$DOTFILES_DIR/ssh/config" ~/.ssh/config

print_success "SSH setup complete"
