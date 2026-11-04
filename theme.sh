#!/bin/zsh

# Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo "gum is not installed. Would you like to install it? (y/n)"
  read -r response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Installing gum via Homebrew..."
    brew install gum
  else
    echo "gum is required to run this script."
    exit 1
  fi
fi

THEME_NAMES=("Tokyo Night Moon" "Tokyo Night Night" "Catppuccin Mocha" "Gruvbox Material" "Gruvbox Material Hard" "GitHub Dark Default" "Kanagawa Dragon")
THEME_DISPLAY=$(gum choose "${THEME_NAMES[@]}" "<< Quit" --header "Choose your theme" --height 10)
THEME=$(echo "$THEME_DISPLAY" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

if [ -n "$THEME" ] && [ "$THEME" != "<<-quit" ]; then
  DOTFILES_DIR="${0:A:h}"

  git -C "$DOTFILES_DIR" update-index --skip-worktree tmux/tmux.theme.conf
  git -C "$DOTFILES_DIR" update-index --skip-worktree ghostty/theme
  git -C "$DOTFILES_DIR" update-index --skip-worktree btop/themes/current.theme

  cp "$DOTFILES_DIR/themes/$THEME/tmux.conf" ~/.tmux/tmux.theme.conf
  cp "$DOTFILES_DIR/themes/$THEME/neovim.lua" ~/.config/nvim/lua/plugins/theme.lua
  cp "$DOTFILES_DIR/themes/$THEME/ghostty" ~/.config/ghostty/theme
  cp "$DOTFILES_DIR/themes/$THEME/btop.theme" ~/.config/btop/themes/current.theme

  tmux source ~/.tmux.conf
  pkill -SIGUSR2 ghostty
  # Rex puts its CLI on PATH only inside its own panes, and names the themes
  # after their Ghostty files, which spell it "TokyoNight".
  rex="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
  if [[ -x "$rex" ]]; then
    "$rex" -C "$(scutil --get ComputerName)" do client.theme.change name="${THEME_DISPLAY/Tokyo Night/TokyoNight}" >/dev/null ||
      echo "Rex theme not changed"
  fi
  echo "Theme changed to $THEME_DISPLAY"
fi
