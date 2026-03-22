# Repo-Specific Preflight Requirements

Per-repo CI requirements and sign-off rules that override the general preflight defaults.

---

## coredns/coredns

**Lint command:**
```bash
go vet ./...
golangci-lint run
```

**Test command:**
```bash
go test ./...
```

**Sign-off:** DCO required — every commit must have `Signed-off-by: Name <email>`
```bash
git commit -s -m "fix(forward): prevent G115 overflow in port conversion"
```

**CI jobs that must pass:** `build`, `test`, `lint`, `fuzz` (if fuzz tests exist)

**Review checklist quirk:** Maintainers check that the `plugin/` directory docs are updated
if the plugin behaviour changes. Update `plugin/<name>/README.md` if applicable.

---

## cilium/cilium

**Lint command:**
```bash
make lint
# If Docker unavailable:
golangci-lint run --timeout 10m --config .golangci.yml
```

**Test command:**
```bash
go test ./pkg/... -count=1
# Targeted:
go test ./pkg/<affected>/ -v -count=1
```

**Sign-off:** DCO required — `git commit -s`

**PR title format:** `<type>/<scope>: <description>` enforced by bot
- Type: `fix`, `feat`, `doc`, `test`, `chore`, `refactor`
- Example: `fix/workqueue: prevent duplicate metrics registration`

**CI jobs that must pass:** `build`, `tests`, `lint`, `check-log-calls`
- `check-log-calls` validates structured logging format — use `log.WithField`, not `log.Printf`

**Scope guidance:** PRs touching `pkg/` only do not need to update docs.
PRs changing API behaviour need `Documentation/` update.

---

## strimzi/strimzi-kafka-operator

**Lint command:**
```bash
# Java components:
./mvnw checkstyle:check

# Go operator (if applicable):
golangci-lint run
```

**Test command:**
```bash
./mvnw test
# Or for a specific module:
./mvnw test -pl <module>
```

**Sign-off:** CLA required — comment `I have read the CLA Document and I hereby sign the CLA`
on your first PR. The CLA bot will guide you.

**PR title format:** Conventional commits, enforced by bot
- Example: `fix(crd): remove duplicate replicas field from Kafka schema`

**CI jobs that must pass:** `build`, `unit-tests`, `checkstyle`

---

## kagent-dev/kagent

**Lint command:**
```bash
golangci-lint run
# or:
make lint
```

**Test command:**
```bash
go test ./...
```

**Sign-off:** Not strictly enforced but appreciated

**Notes:** Small team — maintainers often review within hours. Keep PRs focused.
Check `Makefile` for available targets before running commands.

---

## Default Go Project (all others)

When contributing to a repo not in this list, run this sequence before opening a PR:

```bash
# 1. Verify it builds
go build ./...

# 2. Run tests
go test ./... -count=1

# 3. Run vet
go vet ./...

# 4. Run golangci-lint if config exists
[ -f .golangci.yml ] && golangci-lint run --timeout 5m

# 5. Check for sign-off requirement
grep -ri "sign" CONTRIBUTING.md | head -5
```
