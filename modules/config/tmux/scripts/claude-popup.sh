#!/bin/bash

# Simple Claude Code Popup Script for Tmux
# Just opens Claude Code in a popup

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Claude Code is available
check_claude_availability() {
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}Error: Claude Code is not installed or not in PATH${NC}"
        echo "Please install Claude Code first: https://claude.ai/code"
        echo ""
        echo "Press any key to close..."
        read -n 1
        exit 1
    fi
}

# Show welcome message
show_welcome() {
    clear
    echo -e "${BLUE}╭─────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${BLUE}│${NC}                   ${GREEN}Claude Code Assistant${NC}                   ${BLUE}│${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}•${NC} Ask questions and get AI assistance                     ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}•${NC} Press Ctrl+C or type 'exit' to close                   ${BLUE}│${NC}"
    echo -e "${BLUE}╰─────────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

# Main execution
main() {
    check_claude_availability
    show_welcome
    sleep 1
    
    # Just run Claude Code directly
    claude
}

# Run main function
main "$@"
