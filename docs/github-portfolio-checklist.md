---
type: reference
name: GitHub Portfolio — Posting Checklist
tags: [lifesys, portfolio, checklist, quality]
---

# GitHub Portfolio — Posting Checklist

Run this checklist on EVERY project before making the repo public.

---

## 🔒 Security & Secrets

- [ ] No API keys, tokens, passwords in code or config
- [ ] No hardcoded paths (e.g. /Users/j/...)
- [ ] No .env file committed (but .env.example exists)
- [ ] .gitignore covers: .env, node_modules, __pycache__, .DS_Store, vendor/, tmp/
- [ ] Git history clean — no secrets in previous commits
- [ ] No personal data (emails, names, addresses) in code or test fixtures

## 📄 Documentation

- [ ] README.md exists with:
  - [ ] Project title and one-line description
  - [ ] Tech stack / dependencies listed
  - [ ] Prerequisites (Go 1.22+, Node 20+, etc.)
  - [ ] Installation steps (copy-pasteable)
  - [ ] Usage examples (with actual commands or code)
  - [ ] How to run tests
  - [ ] License mention
- [ ] Code comments explain WHY, not WHAT (no obvious comments)
- [ ] No leftover TODO/FIXME/HACK/XXX comments
- [ ] No commented-out code blocks

## 🧪 Tests

- [ ] Tests exist and pass
- [ ] Test names describe behavior (not "test1", "test2")
- [ ] Tests cover happy path + at least 1 error case
- [ ] No skipped or pending tests without explanation
- [ ] Tests don't depend on external services (mocked/stubbed)
- [ ] `make test` or equivalent single command runs everything

## 🏗️ Code Quality

- [ ] Linter passes clean (golangci-lint, eslint, rubocop, etc.)
- [ ] Consistent formatting (gofmt, prettier, black, etc.)
- [ ] No dead code or unused imports
- [ ] Error handling present (no silent swallows)
- [ ] Follows language conventions (Go: exported names capitalized, etc.)
- [ ] Package/module structure is conventional for the language
- [ ] Dependencies are pinned (go.sum, package-lock.json, Gemfile.lock)

## 📦 Project Structure

- [ ] LICENSE file (MIT)
- [ ] .gitignore appropriate for language
- [ ] Makefile or equivalent task runner (make build, make test, make run)
- [ ] No generated files committed (binaries, dist/, build/)
- [ ] Reasonable directory structure (not everything in root)

## 🎯 GitHub Presentation

- [ ] Repo description filled in (one line)
- [ ] Topics/tags added (language, framework, type)
- [ ] Default branch is `main`
- [ ] No empty/placeholder commits
- [ ] Commit messages are conventional (feat:, fix:, docs:, test:)
- [ ] Commit history tells a story (not "WIP" "WIP" "WIP")

## 🚀 Runs Successfully

- [ ] Fresh clone → install → build → run works
- [ ] Fresh clone → install → test works
- [ ] No platform-specific assumptions (works on Mac + Linux)
- [ ] README instructions actually work when followed literally
