# GitHub Portfolio — Goals & Definition of Done

Build and publish 20-50 public GitHub projects showing breadth across languages, frameworks, and AI/agent expertise. All built using agents. These are needed for job search. Also serves as consulting proof.

**Strategy:** Small self-contained example projects. Not novel tools — professional demonstrations of skill. Quickest first, largest last. Wide language/framework coverage.

---

## Definition of Done

### Level 1: POSTABLE (minimum to go public)
- [ ] Clean README: purpose, install, usage, tech stack
- [ ] Code compiles/runs without errors
- [ ] No secrets, credentials, personal data, hardcoded paths
- [ ] Basic tests passing (unit tests at minimum)
- [ ] At least 1 working example or demo
- [ ] MIT license file
- [ ] Sensible .gitignore
- [ ] Conventional project structure for that language/framework
- [ ] No TODO/FIXME/HACK comments left in code
- [ ] Linted (language-appropriate linter passes clean)

### Level 2: POLISHED (come back later — shows maintenance)
- [ ] Comprehensive test suite (unit + integration)
- [ ] CI/CD via GitHub Actions
- [ ] API docs or detailed usage docs
- [ ] Contributing guidelines (CONTRIBUTING.md)
- [ ] Changelog (CHANGELOG.md)
- [ ] Performance benchmarks where applicable
- [ ] Badge row in README (build status, coverage, license)
- [ ] Regular commits over time (not just one big dump)

---

## Quality Bar

This portfolio is for a Senior AI Engineer with 25+ years of experience. The code must reflect that seniority:

- **Architecture matters.** Clean separation of concerns. Interfaces where they add testability. No god functions.
- **Tests are real.** They test behavior, not implementation. They catch regressions. They have good names.
- **Error handling is thorough.** No silent swallows. User-friendly messages. Wrapped errors with context.
- **Code is DRY and elegant.** Refactoring phase is mandatory — not optional polish, it's core quality.
- **Commit history tells a story.** Conventional commits. Logical progression. Not one big dump.
- **README is professional.** Install, usage, examples, architecture. A hiring manager should understand the project in 30 seconds.
- **No Docker unless the project is specifically about Docker.** No Dockerfiles, no docker-compose. Build and run natively. Docker is slow and resource-heavy — keep things lean.
