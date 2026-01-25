#!/bin/bash

# Test runner script for different environments
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

show_help() {
    echo "Dotfiles Test Runner"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --ubuntu     Test on Ubuntu 22.04 (default)"
    echo "  --alpine     Test on Alpine Linux"
    echo "  --fedora     Test on Fedora Linux"
    echo "  --all        Test on all environments"
    echo "  --local      Test on local environment (no Docker)"
    echo "  --clean      Clean up test containers and images"
    echo "  --help       Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                # Test on Ubuntu"
    echo "  $0 --fedora       # Test on Fedora"
    echo "  $0 --all          # Test on all environments"
    echo "  $0 --local        # Test locally"
    echo "  $0 --clean        # Clean up Docker resources"
    echo ""
}

cleanup_docker() {
    log_info "Cleaning up Docker resources..."
    
    # Stop and remove containers
    docker ps -a --filter "name=dotfiles-test" --format "{{.Names}}" | xargs -r docker rm -f
    
    # Remove images
    docker images --filter "reference=dotfiles-test*" --format "{{.Repository}}:{{.Tag}}" | xargs -r docker rmi -f
    
    log_success "Docker cleanup completed"
}

test_ubuntu() {
    log_info "Testing on Ubuntu 22.04..."
    
    # Build Docker image
    docker build -f tests/Dockerfile.ubuntu -t dotfiles-test-ubuntu .
    
    # Run tests
    if docker run --rm --name dotfiles-test-ubuntu dotfiles-test-ubuntu /home/testuser/dotfiles/tests/test-suite.sh; then
        log_success "Ubuntu tests passed"
        return 0
    else
        log_error "Ubuntu tests failed"
        return 1
    fi
}

test_alpine() {
    log_info "Testing on Alpine Linux..."

    # Build Docker image
    docker build -f tests/Dockerfile.alpine -t dotfiles-test-alpine .

    # Run tests
    if docker run --rm --name dotfiles-test-alpine dotfiles-test-alpine /home/testuser/dotfiles/tests/test-suite.sh; then
        log_success "Alpine tests passed"
        return 0
    else
        log_error "Alpine tests failed"
        return 1
    fi
}

test_fedora() {
    log_info "Testing on Fedora Linux..."

    # Build Docker image
    docker build -f tests/Dockerfile.fedora -t dotfiles-test-fedora .

    # Run tests
    if docker run --rm --name dotfiles-test-fedora dotfiles-test-fedora /home/testuser/dotfiles/tests/test-suite.sh; then
        log_success "Fedora tests passed"
        return 0
    else
        log_error "Fedora tests failed"
        return 1
    fi
}

test_local() {
    log_info "Testing on local environment..."
    log_warning "This will modify your local configuration!"
    
    read -p "Are you sure you want to run tests locally? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Local testing cancelled"
        return 0
    fi
    
    # Backup current config
    BACKUP_DIR="$HOME/.config-test-backup-$(date +%s)"
    log_info "Backing up current config to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    [[ -d "$HOME/.config/nvim" ]] && cp -r "$HOME/.config/nvim" "$BACKUP_DIR/"
    [[ -d "$HOME/.config/tmux" ]] && cp -r "$HOME/.config/tmux" "$BACKUP_DIR/"
    [[ -d "$HOME/.tmux" ]] && cp -r "$HOME/.tmux" "$BACKUP_DIR/"
    
    # Run tests
    if ./tests/test-suite.sh; then
        log_success "Local tests passed"
        TEST_RESULT=0
    else
        log_error "Local tests failed"
        TEST_RESULT=1
    fi
    
    # Restore backup
    log_info "Restoring original configuration..."
    rm -rf "$HOME/.config/nvim" "$HOME/.config/tmux" "$HOME/.tmux" 2>/dev/null || true
    [[ -d "$BACKUP_DIR/nvim" ]] && mv "$BACKUP_DIR/nvim" "$HOME/.config/"
    [[ -d "$BACKUP_DIR/tmux" ]] && mv "$BACKUP_DIR/tmux" "$HOME/.config/"
    [[ -d "$BACKUP_DIR/.tmux" ]] && mv "$BACKUP_DIR/.tmux" "$HOME/"
    rm -rf "$BACKUP_DIR"
    
    return $TEST_RESULT
}

test_all() {
    log_info "Running tests on all environments..."

    local ubuntu_result=0
    local alpine_result=0
    local fedora_result=0

    test_ubuntu || ubuntu_result=1
    test_alpine || alpine_result=1
    test_fedora || fedora_result=1

    echo ""
    log_info "Test Results Summary:"
    if [[ $ubuntu_result -eq 0 ]]; then
        echo -e "  Ubuntu: ${GREEN}PASSED${NC}"
    else
        echo -e "  Ubuntu: ${RED}FAILED${NC}"
    fi

    if [[ $alpine_result -eq 0 ]]; then
        echo -e "  Alpine: ${GREEN}PASSED${NC}"
    else
        echo -e "  Alpine: ${RED}FAILED${NC}"
    fi

    if [[ $fedora_result -eq 0 ]]; then
        echo -e "  Fedora: ${GREEN}PASSED${NC}"
    else
        echo -e "  Fedora: ${RED}FAILED${NC}"
    fi

    if [[ $ubuntu_result -eq 0 && $alpine_result -eq 0 && $fedora_result -eq 0 ]]; then
        log_success "All environment tests passed!"
        return 0
    else
        log_error "Some environment tests failed!"
        return 1
    fi
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        log_info "Please install Docker to run containerized tests"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        log_info "Please start Docker daemon"
        return 1
    fi
    
    return 0
}

main() {
    case "${1:-}" in
        --ubuntu)
            check_docker && test_ubuntu
            ;;
        --alpine)
            check_docker && test_alpine
            ;;
        --fedora)
            check_docker && test_fedora
            ;;
        --all)
            check_docker && test_all
            ;;
        --local)
            test_local
            ;;
        --clean)
            check_docker && cleanup_docker
            ;;
        --help|-h)
            show_help
            ;;
        "")
            # Default to Ubuntu
            check_docker && test_ubuntu
            ;;
        *)
            log_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ensure we're in the right directory
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Run main function
main "$@"