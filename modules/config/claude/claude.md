# Claude Code Agent Framework

## Universal Project Standards

**This document defines the mandatory starting framework for ALL projects. Every new project must follow this structure and workflow without exception.**

### Framework vs Project claude.md

This framework document serves as the master template. Each project will have TWO claude.md files:

1. **claude-framework.md** - This document (never modified, copied from master)
2. **claude.md** - Project-specific agent instructions that EXTENDS this framework

## Core Principles

### Code as Liability
- Every line of code introduces potential bugs, maintenance burden, and technical debt
- Generate only necessary code with clear purpose and documentation
- Prioritize simplicity, readability, and testability over cleverness
- All code must be tested before integration

### Agent Responsibilities
1. **Planning before coding** - No implementation without clear specification
2. **Isolation of features** - Each feature in separate git worktree
3. **Test-driven development** - Tests written alongside or before implementation
4. **Documentation as code** - All decisions and changes tracked
5. **Human review gates** - No automatic merging without approval

## Project Structure

**This structure is mandatory for all projects - no exceptions:**

```
project/
├── claude-framework.md # This framework file (copy from master, never edit)
├── claude.md           # Project-specific agent instructions
├── design.md          # Main architecture and design decisions
├── changes.md         # Major change log
├── tests.md           # Test summary and coverage reports
├── knowledge/         # Project knowledge base
│   ├── decisions/     # Architecture decision records (ADRs)
│   ├── patterns/      # Reusable patterns discovered
│   ├── lessons/       # Lessons learned from features
│   └── references/    # External documentation links
├── features/          # Feature specifications
│   └── feature-xxx.md # Individual feature specs
└── worktrees/         # Git worktrees for features
    └── feature-xxx/   # Isolated feature development
```

### Project Initialization Checklist

When starting ANY new project:

1. **Create base structure**
   ```bash
   mkdir -p project/{knowledge/{decisions,patterns,lessons,references},features,worktrees}
   ```

2. **Copy framework file (DO NOT MODIFY)**
   ```bash
   cp /path/to/master/claude-framework.md project/claude-framework.md
   ```

3. **Create project-specific claude.md**
   ```bash
   cat > project/claude.md << 'EOF'
   # Project-Specific Agent Instructions
   
   ## This File Extends claude-framework.md
   
   **ALWAYS read claude-framework.md FIRST for base workflow and standards.**
   
   ## Project Context
   
   ### Project Name: [Name]
   ### Domain: [e.g., e-commerce, healthcare, finance]
   ### Primary Language: [e.g., TypeScript, Python, Go]
   
   ## Project-Specific Constraints
   
   ### Technical Stack
   - Language: [Primary language and version]
   - Framework: [e.g., Next.js, Django, Spring Boot]
   - Database: [e.g., PostgreSQL, MongoDB]
   - Testing: [e.g., Jest, Pytest, JUnit]
   
   ### Coding Standards
   - Style guide: [e.g., Airbnb, Google, PEP8]
   - Linting: [ESLint config, Black, etc.]
   - Type checking: [TypeScript strict, MyPy, etc.]
   
   ### Business Rules
   [Project-specific business logic that affects all features]
   
   ### Performance Requirements
   - API response time: [e.g., <200ms p95]
   - Memory limits: [e.g., 512MB per container]
   - Concurrent users: [e.g., 10,000]
   
   ### Security Requirements
   - Authentication: [e.g., JWT, OAuth2]
   - Authorization: [e.g., RBAC, ABAC]
   - Compliance: [e.g., GDPR, HIPAA]
   
   ### Integration Points
   - External APIs: [List with rate limits]
   - Internal services: [Microservices, queues]
   - Third-party libraries: [Critical dependencies]
   
   ## Project-Specific Patterns
   
   ### Error Handling
   [Project-specific error handling patterns]
   
   ### Logging Standards
   [What to log, format, levels]
   
   ### Database Patterns
   [ORM usage, raw SQL rules, migrations]
   
   ## DO NOT Override Framework Rules
   
   The following from claude-framework.md cannot be overridden:
   - Git worktree isolation for features
   - Test-first development
   - Human review before merge
   - Documentation requirements
   - Knowledge management structure
   EOF
   ```

4. **Initialize tracking documents**
   ```bash
   echo "# Design Document\n\n## Project: [Name]\n## Created: $(date)" > design.md
   echo "# Change Log\n\n## Project Started: $(date)" > changes.md
   echo "# Test Summary\n\n## Coverage Goals\n- Minimum: 80%\n- Target: 90%" > tests.md
   ```

5. **Create first ADR**
   ```bash
   echo "# ADR-001: Use Claude Framework\n\n## Status: Accepted\n\n## Context\nWe need consistent project structure.\n\n## Decision\nUse claude-framework.md as base with project-specific claude.md extensions.\n\n## Consequences\n- Consistent workflow\n- Project-specific customization\n- Clear separation of concerns" > knowledge/decisions/ADR-001-use-framework.md
   ```

### How Agents Should Read Instructions

When working on a project, agents must:

1. **First** - Read `claude-framework.md` for universal workflow and standards
2. **Second** - Read `claude.md` for project-specific requirements
3. **Apply** - Project-specific rules that don't conflict with framework rules
4. **Reject** - Any project-specific rules that violate framework principles

### Hierarchy of Rules

```
claude-framework.md (Universal - Cannot be overridden)
    ↓
claude.md (Project-specific - Extends framework)
    ↓
feature-xxx.md (Feature-specific - Extends both)
```

### Required for Every Project

Each project maintains its own knowledge base that grows with the project:

#### 1. Architecture Decision Records (ADRs)
Location: `knowledge/decisions/`

Format: `ADR-XXX-brief-description.md`
```markdown
# ADR-XXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-YYY]

## Context
[What is the issue that we're seeing that is motivating this decision?]

## Decision
[What is the change that we're proposing and/or doing?]

## Consequences
[What becomes easier or more difficult because of this change?]
```

#### 2. Pattern Library
Location: `knowledge/patterns/`

Document reusable solutions discovered during development:
```markdown
# Pattern: [Name]

## Problem
[What recurring problem does this solve?]

## Solution
[The reusable approach]

## Example
[Code example]

## When to Use
[Conditions where this pattern applies]

## When NOT to Use
[Anti-pattern scenarios]
```

#### 3. Lessons Learned
Location: `knowledge/lessons/`

After each feature, document:
```markdown
# Lessons: [Feature Name]

## What Worked Well
- [Success points]

## What Didn't Work
- [Failure points]

## Time Estimates
- Planned: X days
- Actual: Y days
- Reason for variance: [Explanation]

## Would Do Differently
- [Improvements for next time]

## Reusable Insights
- [Transferable knowledge]
```

#### 4. Reference Links
Location: `knowledge/references/`

Maintain a curated list of project-specific references:
```markdown
# Project References

## APIs
- [Service Name]: [URL] - [Brief description]

## Libraries
- [Library Name]: [Docs URL] - [Why we use it]

## Internal Systems
- [System Name]: [Link] - [Integration points]

## Learning Resources
- [Resource]: [Link] - [Key takeaways]
```

### 1. Feature Request Analysis
When receiving a feature request:
- Analyze requirements and constraints
- Identify potential risks and dependencies
- Estimate complexity and testing requirements
- Document assumptions and clarifications needed

### 2. Feature Planning Phase
Before any implementation:
```markdown
## Feature: [Name]
### Purpose
[Clear description of why this feature is needed]

### Scope
- In scope: [What will be implemented]
- Out of scope: [What won't be implemented]

### Technical Approach
[High-level implementation strategy]

### Risk Assessment
- Performance implications
- Security considerations
- Breaking changes
- Technical debt introduced

### Testing Strategy
- Unit tests required
- Integration tests required
- Edge cases to cover
```

### 3. Git Worktree Creation
```bash
# Create new worktree for feature
git worktree add worktrees/feature-xxx feature/xxx

# Navigate to worktree
cd worktrees/feature-xxx

# Create feature documentation
mkdir -p docs
echo "# Feature: xxx" > docs/feature-xxx.md
```

### 4. Implementation Guidelines

#### Commit Strategy
- Commit frequently with descriptive messages
- Format: `type(scope): description`
- Types: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`
- Example: `feat(auth): add JWT token validation`

#### Code Generation Rules
1. Generate minimal code to satisfy requirements
2. Include error handling for all edge cases
3. Add inline documentation for complex logic
4. Follow project coding standards strictly
5. No copy-paste without understanding

#### Testing Requirements
- Write tests BEFORE or WITH implementation
- Minimum 80% code coverage for new code
- Test happy path, edge cases, and error conditions
- Document test scenarios in test files

### 5. Quality Gates

#### Pre-merge Checklist
- [ ] All tests passing
- [ ] Code coverage meets requirements
- [ ] No linting errors
- [ ] Documentation updated
- [ ] changes.md updated with major changes
- [ ] Human review completed
- [ ] Performance benchmarks acceptable

## Documentation Standards

### design.md Structure
```markdown
# Project Architecture

## Overview
[System overview and goals]

## Core Components
[Major system components and their responsibilities]

## Data Flow
[How data moves through the system]

## Technology Stack
[Languages, frameworks, databases]

## Design Decisions
[Key architectural decisions and rationale]

## Future Considerations
[Scalability, extensibility plans]
```

### changes.md Format
```markdown
# Change Log

## [Date] - Feature/Change Name
### Added
- [New functionality]

### Changed
- [Modified behavior]

### Removed
- [Deprecated features]

### Impact
- [Systems affected]
- [Migration required]
- [Performance implications]
```

### tests.md Format
```markdown
# Test Summary

## Coverage Report
- Overall: X%
- Feature A: X%
- Feature B: X%

## Test Categories
### Unit Tests
[Summary of unit test coverage]

### Integration Tests
[Summary of integration test coverage]

### End-to-End Tests
[Summary of E2E test coverage]

## Known Test Gaps
[Areas requiring additional test coverage]
```

## Subagent Context Protocol

When creating a subagent for a feature:

### Context Package
```markdown
## Feature Context: [Name]

### Objective
[Specific goal for this subagent]

### Constraints
- Technical: [Framework/library constraints]
- Business: [Business logic requirements]
- Performance: [Response time, memory limits]

### Available Resources
- Existing APIs: [List of available endpoints]
- Database schemas: [Relevant tables/collections]
- Shared utilities: [Common functions/modules]

### Success Criteria
- [ ] Implementation complete
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Code reviewed

### References
- Design doc: [Link to relevant design sections]
- Related features: [Links to dependent features]
- External docs: [API docs, library references]
```

## Error Handling Standards

### Code Generation Rules
1. Never suppress errors silently
2. Log errors with context
3. Fail fast with clear error messages
4. Implement graceful degradation where appropriate
5. Document error scenarios in code

### Error Documentation
```javascript
/**
 * @throws {ValidationError} When input validation fails
 * @throws {DatabaseError} When database connection fails
 * @throws {AuthenticationError} When user authentication fails
 */
```

## Review Process

### Self-Review Checklist
Before requesting human review:
- [ ] Code runs without errors
- [ ] All tests pass locally
- [ ] No commented-out code
- [ ] No debug statements
- [ ] Consistent naming conventions
- [ ] Appropriate error handling
- [ ] Performance considerations addressed

### Human Review Focus Areas
1. Business logic correctness
2. Security vulnerabilities
3. Performance bottlenecks
4. Code maintainability
5. Test completeness

## Continuous Improvement

### Retrospective Questions
After each feature:
1. What went well?
2. What could be improved?
3. Were estimates accurate?
4. Any technical debt introduced?
5. Lessons learned for future features?

### Metrics to Track
- Lines of code per feature
- Test coverage percentage
- Bug density (bugs per LOC)
- Time from plan to merge
- Number of review iterations

## Emergency Protocols

### When Things Go Wrong
1. **Stop generating code** if requirements unclear
2. **Rollback** if tests start failing
3. **Document** any workarounds or hacks
4. **Escalate** security or data concerns immediately
5. **Never** push directly to main branch

### Recovery Steps
```bash
# If feature branch corrupted
git worktree remove worktrees/feature-xxx
git branch -D feature/xxx
# Start fresh with lessons learned
```

---

*This framework is your contract with every project. Following it ensures consistent, maintainable, and well-documented software across all endeavors. Every project starts here, no exceptions.*
