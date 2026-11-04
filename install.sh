#!/bin/zsh

# Define the dotfiles directory
DOTFILES_DIR="${0:A:h}"

# Source common utilities
source "$DOTFILES_DIR/scripts/utils.sh"

# List of setup scripts to run
SETUP_SCRIPTS=(
  "mac"
  "dev"
  "utilities"
  "app"
)

# Check if a specific script was provided as an argument
if [ $# -gt 0 ]; then
  # Run only the specified script
  script="$1"

  # Try to find the script in multiple locations
  if [ -f "$DOTFILES_DIR/scripts/${script}.sh" ]; then
    # Found in main scripts directory
    source "$DOTFILES_DIR/scripts/${script}.sh"
  elif [ -f "$DOTFILES_DIR/scripts/dev/${script}.sh" ]; then
    # Found in dev subdirectory
    source "$DOTFILES_DIR/scripts/dev/${script}.sh"
  elif [ -f "$DOTFILES_DIR/scripts/utilities/${script}.sh" ]; then
    # Found in utilities subdirectory
    source "$DOTFILES_DIR/scripts/utilities/${script}.sh"
  else
    print_error "Setup script for ${script} not found!"
    exit 1
  fi
else
  # Run each setup script
  for script in "${SETUP_SCRIPTS[@]}"; do
    if [ -f "$DOTFILES_DIR/scripts/${script}.sh" ]; then
      source "$DOTFILES_DIR/scripts/${script}.sh"
    else
      print_error "Setup script for ${script} not found!"
    fi
    echo # Add a separator between each script output
  done
  echo -e "${GREEN}${BOLD}All installations complete!${NC}"
  echo "Next: sign in to 1Password, turn on Settings > Developer > \"Integrate with 1Password CLI\", then run ./install.sh ssh"
fi
