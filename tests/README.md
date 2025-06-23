# Dotfiles Testing

Comprehensive test suite for validating dotfiles setup and synchronization scripts across different environments.

## Test Coverage

### Setup Script (`setup.sh`) Tests
- ✅ **Initial Installation**: Verifies packages are installed and configs deployed
- ✅ **Idempotent Behavior**: Ensures repeated runs don't cause side effects
- ✅ **Force Flag**: Tests `--force` flag functionality
- ✅ **Help Flag**: Validates `--help` command works
- ✅ **Config Detection**: Tests detection of modified configurations
- ✅ **Multiple Runs**: Ensures multiple consecutive runs are safe
- ✅ **Backup Strategy**: Validates smart backup creation

### Sync Script (`sync.sh`) Tests
- ✅ **To-Repo Sync**: Tests local → repository synchronization
- ✅ **From-Repo Sync**: Tests repository → local synchronization
- ✅ **Diff Command**: Validates difference detection
- ✅ **Status Command**: Tests git status functionality
- ✅ **Error Handling**: Validates proper error handling

### Integration Tests
- ✅ **Configuration Integrity**: Ensures deployed configs match repository
- ✅ **Package Installation**: Verifies required packages are installed
- ✅ **Shell Integration**: Tests vim alias setup
- ✅ **Plugin Manager**: Validates TPM installation

## Test Environments

### Docker Environments
- **Ubuntu 22.04**: Primary Linux distribution test
- **Alpine Linux**: Lightweight Linux distribution test

### Local Environment
- **Host System**: Direct testing on the host system (with backup/restore)

## Running Tests

### Quick Start
```bash
# Test on Ubuntu (default)
./tests/run-tests.sh

# Test on all environments
./tests/run-tests.sh --all

# Test locally (with backup/restore)
./tests/run-tests.sh --local
```

### All Test Options
```bash
# Individual environments
./tests/run-tests.sh --ubuntu     # Ubuntu 22.04
./tests/run-tests.sh --alpine     # Alpine Linux
./tests/run-tests.sh --local      # Local system

# Multiple environments
./tests/run-tests.sh --all         # All Docker environments

# Maintenance
./tests/run-tests.sh --clean       # Clean up Docker resources
./tests/run-tests.sh --help        # Show help
```

### Direct Test Suite
```bash
# Run test suite directly (for development)
./tests/test-suite.sh
```

## Test Structure

### Test Files
```
tests/
├── Dockerfile.ubuntu      # Ubuntu test environment
├── Dockerfile.alpine      # Alpine test environment
├── test-suite.sh          # Core test suite
├── run-tests.sh           # Test runner
└── README.md              # This file
```

### Test Functions
- `test_initial_setup()` - First-time setup validation
- `test_idempotent_behavior()` - Repeated run safety
- `test_force_flag()` - Force reinstall behavior
- `test_config_modification_detection()` - Change detection
- `test_sync_to_repo()` - Local to repo sync
- `test_sync_from_repo()` - Repo to local sync
- `test_multiple_runs()` - Consecutive execution safety
- `test_configuration_integrity()` - Config validation

## Continuous Integration

### GitHub Actions
The repository includes GitHub Actions workflow (`.github/workflows/test.yml`) that:
- Tests on Ubuntu and Alpine environments
- Validates script syntax
- Checks repository structure
- Runs on every push and pull request

### CI Status
Tests run automatically on:
- Push to `master` or `main` branch
- Pull requests
- Manual workflow dispatch

## Test Output

### Successful Test Run
```
[TEST] Testing initial setup script execution
[PASS] Setup script executed successfully
[PASS] Command available: nvim
[PASS] Command available: tmux
[PASS] Directory exists: /home/testuser/.config/nvim
...
[INFO] Test Summary:
  Total tests: 45
  Passed: 45
  Failed: 0
All tests passed!
```

### Failed Test Example
```
[TEST] Testing configuration file integrity
[FAIL] Nvim config missing expected content
[FAIL] Directories differ: /home/testuser/.config/tmux <-> ./config/tmux
...
[INFO] Test Summary:
  Total tests: 45
  Passed: 43
  Failed: 2
Some tests failed!
```

## Development

### Adding New Tests
1. Add test function to `test-suite.sh`
2. Call function in `run_all_tests()`
3. Test locally before committing

### Test Helper Functions
- `assert_file_exists(path)` - Check file existence
- `assert_dir_exists(path)` - Check directory existence
- `assert_command_exists(cmd)` - Check command availability
- `assert_string_in_file(file, string)` - Check file content
- `assert_dirs_identical(dir1, dir2)` - Compare directories

### Docker Environment Customization
Modify `Dockerfile.ubuntu` or `Dockerfile.alpine` to:
- Add new test dependencies
- Change base image versions
- Customize user setup

## Troubleshooting

### Docker Issues
```bash
# Check Docker installation
docker --version

# Check Docker daemon
docker info

# Clean up resources
./tests/run-tests.sh --clean
```

### Test Failures
```bash
# Run with verbose output
bash -x ./tests/test-suite.sh

# Test individual components
./setup.sh --help
./sync.sh help

# Check file permissions
ls -la setup.sh sync.sh tests/*.sh
```

### Local Testing Precautions
- **Always backup**: Local testing modifies your actual config
- **Test in VM**: Consider using a virtual machine for local tests
- **Review changes**: Check what will be modified before running

## Contributing

When contributing to the dotfiles:
1. Run tests locally first: `./tests/run-tests.sh --all`
2. Add tests for new features
3. Ensure CI passes on GitHub
4. Update test documentation if needed

## Performance

### Typical Test Times
- Ubuntu environment: ~2-3 minutes
- Alpine environment: ~1-2 minutes
- Local testing: ~30 seconds

### Resource Usage
- CPU: Minimal during execution
- Memory: ~100MB per Docker container
- Disk: ~500MB for all Docker images combined