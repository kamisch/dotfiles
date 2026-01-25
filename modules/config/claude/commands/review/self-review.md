# Self Review

Perform a comprehensive self-review of recent code changes including syntax validation, pre-commit hooks, tests, and generate a structured code review summary.

## Usage Examples

### Basic Usage
"Run /review:self-review"
"Self review my changes"
"Review the changes I just made"

### After Making Changes
"I've finished the feature, run a self review"
"Check my work before I commit"

## Instructions for Claude

Perform a systematic self-review of recent code changes by executing the following phases:

### Phase 1: Identify Changed Files

```bash
# Get list of changed files (staged and unstaged)
git diff --name-only HEAD
git status --porcelain
```

Categorize files by type:
- Shell scripts (*.sh)
- Python files (*.py)
- JavaScript/TypeScript (*.js, *.ts, *.jsx, *.tsx)
- Configuration files (Dockerfile*, *.yml, *.yaml, *.json)
- Other source files

### Phase 2: Pre-commit Hooks Check

Check for and run pre-commit if configured:

```bash
# Check for pre-commit config
ls -la .pre-commit-config.yaml 2>/dev/null
ls -la .git/hooks/pre-commit 2>/dev/null

# If pre-commit is installed and configured, run it
command -v pre-commit && pre-commit run --files [changed_files]
```

If no pre-commit is configured, note this in the review.

### Phase 3: Syntax Validation

Validate syntax based on file type:

**Shell Scripts:**
```bash
bash -n script.sh && echo "OK" || echo "FAIL"
```

**Python Files:**
```bash
python -m py_compile file.py && echo "OK" || echo "FAIL"
```

**JavaScript/TypeScript:**
```bash
# If eslint available
npx eslint --no-eslintrc --parser-options=ecmaVersion:2020 file.js 2>/dev/null
# Or basic node syntax check
node --check file.js 2>/dev/null
```

**JSON Files:**
```bash
python -m json.tool file.json > /dev/null && echo "OK" || echo "FAIL"
# Or: jq . file.json > /dev/null
```

**YAML Files:**
```bash
python -c "import yaml; yaml.safe_load(open('file.yaml'))" && echo "OK" || echo "FAIL"
```

**Dockerfiles:**
```bash
# If hadolint available
hadolint Dockerfile 2>/dev/null || echo "hadolint not available"
```

### Phase 4: Run Tests

Detect and run available test suites:

```bash
# Check for test infrastructure
ls -la tests/ test/ spec/ __tests__/ 2>/dev/null
ls -la pytest.ini setup.cfg pyproject.toml package.json Makefile 2>/dev/null

# Run appropriate test command based on project type
# Python: pytest, python -m unittest
# JavaScript: npm test, yarn test
# Shell: ./tests/run-tests.sh, bats
# Make: make test
```

If Docker tests exist, note availability but don't run automatically (they may be slow).

### Phase 5: Generate Review Summary

Create a structured code review report:

```markdown
## Code Review Summary

### Files Changed
| File | Type | Status |
|------|------|--------|
| path/to/file.sh | Shell | Modified |

### Validation Results

| Check | Status | Details |
|-------|--------|---------|
| Pre-commit hooks | Pass/Fail/N/A | Details |
| Syntax validation | Pass/Fail | X files checked |
| Unit tests | Pass/Fail/N/A | X passed, Y failed |

### Issues Found

| Severity | File | Issue |
|----------|------|-------|
| High | file.py | Description |
| Medium | file.js | Description |
| Low | file.sh | Description |

### Pre-existing Issues
Note any issues that existed before the changes.

### Recommendations
- List actionable recommendations
- Suggest improvements

### Summary
Brief overall assessment of the changes.
```

### Review Criteria

When reviewing changes, check for:

1. **Correctness**
   - Logic errors
   - Edge cases not handled
   - Missing error handling

2. **Consistency**
   - Follows existing code patterns
   - Naming conventions
   - Code style

3. **Completeness**
   - All related files updated
   - Tests updated if needed
   - Documentation updated if needed

4. **Security**
   - No hardcoded secrets
   - Input validation
   - Safe command execution

5. **Best Practices**
   - DRY (Don't Repeat Yourself)
   - KISS (Keep It Simple)
   - Proper error messages

### Output Format

Present findings in a clear, actionable format:

1. **Start with validation results** - Quick pass/fail summary
2. **List issues by severity** - Critical/High/Medium/Low
3. **Separate pre-existing issues** - Don't blame current changes for old problems
4. **End with recommendations** - Actionable next steps

### Notes

- Run all validation checks in parallel when possible
- Don't fail the review for missing optional tools (hadolint, eslint, etc.)
- Clearly distinguish between blocking issues and suggestions
- If tests require Docker, note availability but suggest manual run
