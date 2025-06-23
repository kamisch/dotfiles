#!/bin/bash

# Comprehensive test suite for dotfiles setup and sync scripts
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test helper functions
assert_file_exists() {
    if [[ -f "$1" ]]; then
        log_pass "File exists: $1"
    else
        log_fail "File missing: $1"
    fi
}

assert_dir_exists() {
    if [[ -d "$1" ]]; then
        log_pass "Directory exists: $1"
    else
        log_fail "Directory missing: $1"
    fi
}

assert_command_exists() {
    if command -v "$1" >/dev/null 2>&1; then
        log_pass "Command available: $1"
    else
        log_fail "Command missing: $1"
    fi
}

assert_string_in_file() {
    if grep -q "$2" "$1" 2>/dev/null; then
        log_pass "String '$2' found in $1"
    else
        log_fail "String '$2' not found in $1"
    fi
}

assert_dirs_identical() {
    if diff -rq "$1" "$2" >/dev/null 2>&1; then
        log_pass "Directories are identical: $1 <-> $2"
    else
        log_fail "Directories differ: $1 <-> $2"
    fi
}

count_backups() {
    find ~ -maxdepth 2 -name "*.backup.*" 2>/dev/null | wc -l
}

# Test functions
test_initial_setup() {
    log_test "Testing initial setup script execution"
    
    # Run setup script for the first time
    if ./setup.sh; then
        log_pass "Setup script executed successfully"
    else
        log_fail "Setup script failed"
        return 1
    fi
    
    # Check if packages were installed
    assert_command_exists "nvim"
    assert_command_exists "tmux"
    assert_command_exists "git"
    
    # Check if configurations were deployed
    assert_dir_exists "$HOME/.config/nvim"
    assert_dir_exists "$HOME/.config/tmux"
    assert_file_exists "$HOME/.config/nvim/init.lua"
    assert_file_exists "$HOME/.config/tmux/tmux.conf"
    
    # Check if TPM was installed
    assert_dir_exists "$HOME/.tmux/plugins/tpm"
    
    # Check if vim alias was added
    if [[ -f "$HOME/.bashrc" ]]; then
        assert_string_in_file "$HOME/.bashrc" "alias vim=nvim"
    fi
    if [[ -f "$HOME/.zshrc" ]]; then
        assert_string_in_file "$HOME/.zshrc" "alias vim=nvim"
    fi
}

test_idempotent_behavior() {
    log_test "Testing idempotent behavior - second run"
    
    local backup_count_before=$(count_backups)
    
    # Run setup script again
    if ./setup.sh; then
        log_pass "Second setup run completed successfully"
    else
        log_fail "Second setup run failed"
        return 1
    fi
    
    local backup_count_after=$(count_backups)
    
    # Should not create new backups if configs are identical
    if [[ $backup_count_after -eq $backup_count_before ]]; then
        log_pass "No unnecessary backups created on second run"
    else
        log_fail "Unnecessary backups created: $backup_count_before -> $backup_count_after"
    fi
    
    # Configurations should still exist and be correct
    assert_dir_exists "$HOME/.config/nvim"
    assert_dir_exists "$HOME/.config/tmux"
}

test_force_flag() {
    log_test "Testing --force flag behavior"
    
    local backup_count_before=$(count_backups)
    
    # Run with --force flag
    if ./setup.sh --force; then
        log_pass "Force flag execution completed"
    else
        log_fail "Force flag execution failed"
        return 1
    fi
    
    local backup_count_after=$(count_backups)
    
    # Should create backups even if configs are identical
    if [[ $backup_count_after -gt $backup_count_before ]]; then
        log_pass "Force flag created backups as expected"
    else
        log_fail "Force flag did not create expected backups"
    fi
}

test_help_flag() {
    log_test "Testing --help flag"
    
    if ./setup.sh --help >/dev/null 2>&1; then
        log_pass "Help flag works"
    else
        log_fail "Help flag failed"
    fi
}

test_config_modification_detection() {
    log_test "Testing config modification detection"
    
    # Modify a config file
    echo "# Test modification" >> "$HOME/.config/nvim/init.lua"
    
    local backup_count_before=$(count_backups)
    
    # Run setup again - should detect change and backup
    if ./setup.sh; then
        log_pass "Setup detected config modification"
    else
        log_fail "Setup failed after config modification"
        return 1
    fi
    
    local backup_count_after=$(count_backups)
    
    if [[ $backup_count_after -gt $backup_count_before ]]; then
        log_pass "Modified config was backed up"
    else
        log_fail "Modified config was not backed up"
    fi
}

test_sync_to_repo() {
    log_test "Testing sync.sh to-repo functionality"
    
    # Make a change to local config
    echo "# Local change for sync test" >> "$HOME/.config/nvim/init.lua"
    
    # Sync to repo
    if ./sync.sh to-repo; then
        log_pass "Sync to repo completed"
    else
        log_fail "Sync to repo failed"
        return 1
    fi
    
    # Check if change is in repo
    if grep -q "Local change for sync test" "./config/nvim/init.lua"; then
        log_pass "Local change synced to repository"
    else
        log_fail "Local change not synced to repository"
    fi
}

test_sync_from_repo() {
    log_test "Testing sync.sh from-repo functionality"
    
    # Make a change to repo config
    echo "# Repo change for sync test" >> "./config/nvim/init.lua"
    
    # Sync from repo
    if ./sync.sh from-repo; then
        log_pass "Sync from repo completed"
    else
        log_fail "Sync from repo failed"
        return 1
    fi
    
    # Check if change is in local config
    if grep -q "Repo change for sync test" "$HOME/.config/nvim/init.lua"; then
        log_pass "Repo change synced to local config"
    else
        log_fail "Repo change not synced to local config"
    fi
}

test_sync_diff() {
    log_test "Testing sync.sh diff functionality"
    
    # Create a difference
    echo "# Diff test" >> "$HOME/.config/nvim/init.lua"
    
    # Test diff command
    if ./sync.sh diff >/dev/null 2>&1; then
        log_pass "Sync diff command works"
    else
        log_fail "Sync diff command failed"
    fi
}

test_sync_status() {
    log_test "Testing sync.sh status functionality"
    
    # Test status command
    if ./sync.sh status >/dev/null 2>&1; then
        log_pass "Sync status command works"
    else
        log_fail "Sync status command failed"
    fi
}

test_error_handling() {
    log_test "Testing error handling"
    
    # Test invalid sync command
    if ! ./sync.sh invalid-command >/dev/null 2>&1; then
        log_pass "Invalid sync command properly rejected"
    else
        log_fail "Invalid sync command was accepted"
    fi
    
    # Test sync help
    if ./sync.sh help >/dev/null 2>&1; then
        log_pass "Sync help command works"
    else
        log_fail "Sync help command failed"
    fi
}

test_multiple_runs() {
    log_test "Testing multiple consecutive runs"
    
    local initial_backup_count=$(count_backups)
    
    # Run setup multiple times
    for i in {1..3}; do
        log_info "Setup run $i"
        if ! ./setup.sh; then
            log_fail "Setup run $i failed"
            return 1
        fi
    done
    
    local final_backup_count=$(count_backups)
    
    # Should not create excessive backups
    local backup_diff=$((final_backup_count - initial_backup_count))
    if [[ $backup_diff -le 1 ]]; then
        log_pass "Multiple runs did not create excessive backups ($backup_diff new backups)"
    else
        log_fail "Multiple runs created too many backups ($backup_diff new backups)"
    fi
}

test_configuration_integrity() {
    log_test "Testing configuration file integrity"
    
    # Check that essential files have expected content
    if grep -q "NvChad" "$HOME/.config/nvim/init.lua"; then
        log_pass "Nvim config contains expected NvChad reference"
    else
        log_fail "Nvim config missing expected content"
    fi
    
    if grep -q "Ctrl+Space" "$HOME/.config/tmux/tmux.conf" || grep -q "C-Space" "$HOME/.config/tmux/tmux.conf"; then
        log_pass "Tmux config contains expected prefix key"
    else
        log_fail "Tmux config missing expected content"
    fi
    
    # Check that configs match repo configs
    assert_dirs_identical "$HOME/.config/nvim" "./config/nvim"
    assert_dirs_identical "$HOME/.config/tmux" "./config/tmux"
}

# Main test runner
run_all_tests() {
    log_info "Starting comprehensive dotfiles test suite"
    log_info "Test environment: $(uname -a)"
    log_info "Working directory: $(pwd)"
    echo ""
    
    # Clean up any existing configs for fresh test
    rm -rf "$HOME/.config/nvim" "$HOME/.config/tmux" "$HOME/.tmux" 2>/dev/null || true
    rm -f "$HOME/.config"/*.backup.* 2>/dev/null || true
    
    # Run tests in order
    test_initial_setup || return 1
    test_idempotent_behavior
    test_help_flag
    test_config_modification_detection
    test_force_flag
    test_multiple_runs
    test_configuration_integrity
    test_sync_to_repo
    test_sync_from_repo
    test_sync_diff
    test_sync_status
    test_error_handling
    
    echo ""
    log_info "Test Summary:"
    echo "  Total tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi