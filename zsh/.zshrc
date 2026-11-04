# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Auto load nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# work
alias deploy="~/workspace/dotfiles/work/deploy.sh"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Blog CLI completion
fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit

# Add ~/.local/bin to PATH
export PATH="$HOME/.local/bin:$PATH"

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

eval "$(fzf --zsh)"

# ripgrep: search hidden files (dotfiles) by default
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# agent-browser: save session state only on close, not every 30s
# periodic autosave flashes a temporary tab and steals focus in headed Chrome
# https://github.com/vercel-labs/agent-browser/issues/1688
export AGENT_BROWSER_AUTOSAVE_INTERVAL_MS=0

# Rex supports OSC 8 links, but Claude Code doesn't recognize TERM_PROGRAM=rex yet
[[ "$TERM_PROGRAM" == "rex" ]] && export FORCE_HYPERLINK=1

# Claude Code drops to 256 colors inside tmux unless told the outer terminal
# passes RGB through, which tmux.conf already sets up
export CLAUDE_CODE_TMUX_TRUECOLOR=1

# gwt shell integration
eval "$(command gwt shell init zsh)"
