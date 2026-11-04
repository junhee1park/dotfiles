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

FONT_NAMES=("Cascadia Code" "IBM Plex Mono")
FONT_DISPLAY=$(gum choose "${FONT_NAMES[@]}" "<< Quit" --header "Choose your font" --height 10)
FONT=$(echo "$FONT_DISPLAY" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

if [ -n "$FONT" ] && [ "$FONT" != "<<-quit" ]; then
  DOTFILES_DIR="${0:A:h}"

  git -C "$DOTFILES_DIR" update-index --skip-worktree ghostty/font

  cp "$DOTFILES_DIR/fonts/$FONT" ~/.config/ghostty/font

  pkill -SIGUSR2 ghostty

  # Rex reads its font only at launch, and a running Rex writes its own
  # settings back on quit, so quit it before writing and reopen it after.
  rex_font=$(sed -n 's/^font-family = "\(.*\)"$/\1/p' "$DOTFILES_DIR/fonts/$FONT" | head -1)
  rex_was_running=$(pgrep -xq Rex && echo 1)
  if [[ -n "$rex_was_running" ]]; then
    killall Rex
    while pgrep -xq Rex; do sleep 0.2; done
  fi
  defaults write com.superlogical.rex Workspace.terminalFontName -string "$rex_font"
  [[ -n "$rex_was_running" ]] && open -a "Rex Beta"
  echo "Font changed to $FONT_DISPLAY"
fi
