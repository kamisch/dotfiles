# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set theme to cloud
ZSH_THEME="cloud"

# Essential plugins for productivity
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    command-not-found
    colored-man-pages
    extract
    web-search
    copypath
    copyfile
    dirhistory
)

# Load zsh-completions
autoload -U compinit && compinit

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

# Enable autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# NPM global packages
export PATH="$HOME/.npm-global/bin:$PATH"

# NPM aliases and shortcuts
alias npi='npm install'
alias npd='npm install --save-dev'
alias npu='npm uninstall'
alias nps='npm start'
alias npt='npm test'
alias npb='npm run build'
alias npl='npm run lint'
alias npf='npm run format'
alias npr='npm run'
alias npg='npm list -g --depth=0'
alias npo='npm outdated'
alias npc='npm run clean'
alias npw='npm run watch'
alias npd='npm run dev'

# Node version management
alias nvml='nvm list'
alias nvmu='nvm use'
alias nvmi='nvm install'
alias nvmc='nvm current'
alias nvmr='nvm run'

# Yarn alternatives (if yarn is available)
if command -v yarn &> /dev/null; then
    alias yi='yarn install'
    alias ya='yarn add'
    alias yad='yarn add --dev'
    alias yr='yarn remove'
    alias ys='yarn start'
    alias yt='yarn test'
    alias yb='yarn build'
    alias yu='yarn upgrade'
fi

# Use nvim as default vim
alias vim=nvim

# Snap binaries PATH
export PATH="/snap/bin:$PATH"
