# Repository Profiles

Per-repo quirks, CONTRIBUTING conventions, lint commands, and review speed benchmarks.

---

## coredns/coredns
- **Review speed:** Very fast — gosec PRs merged in < 24h
- **Lint command:** `go vet ./... && golangci-lint run`
- **Test command:** `go test ./...`
- **CONTRIBUTING:** `CONTRIBUTING.md` at repo root — follow DCO sign-off requirement
- **Sign-off:** Required — add `-s` flag: `git commit -s`
- **PR title:** No strict format enforced, but conventional commits are welcome
- **CI:** GitHub Actions — must pass `build`, `test`, `lint` jobs
- **Maintainer activity:** Very active (daily commits)
- **Winning patterns:** gosec G114/G115 in `plugin/*/` directories

---

## cilium/cilium
- **Review speed:** Slower — 3–10 days typical; complex PRs can take weeks
- **Lint command:** `make lint` (runs in Docker — requires Docker installed)
  - Faster alternative: `golangci-lint run --timeout 10m`
- **Test command:** `make tests` or `go test ./pkg/... -count=1`
- **CONTRIBUTING:** `Documentation/contributing/development/` — detailed
- **Sign-off:** Required — `git commit -s`
- **PR title:** Must follow `<type>/<scope>: <description>` format checked by bot
- **CI:** Very thorough — multiple CI jobs; don't open until local lint passes
- **Maintainer activity:** Very active (multiple commits per day)
- **Winning patterns:** gosec in `pkg/*/`, workqueue metrics in `pkg/workqueue/`
- **Caveat:** Large codebase — grep extensively before editing to avoid touching the wrong layer

---

## strimzi/strimzi-kafka-operator
- **Review speed:** Moderate — 5–14 days
- **Lint command:** `mvn checkstyle:check` (Java) or `./mvnw validate`
- **Test command:** `mvn test` or `./mvnw test`
- **CONTRIBUTING:** `CONTRIBUTING.md` — requires CLA sign
- **Sign-off:** CLA bot required (sign once via GitHub comment)
- **PR title:** Conventional commits enforced by bot
- **CI:** GitHub Actions — Maven build + checkstyle must pass
- **Maintainer activity:** Active
- **Winning patterns:** CRD schema issues in `api/src/main/resources/`, Helm chart in `helm-charts/`
- **Note:** Java project — most of the fixes are in YAML (CRD schemas) or Go operator code

---

## kagent-dev/kagent
- **Review speed:** Fast — small team, often same-day
- **Lint command:** `golangci-lint run` or `make lint`
- **Test command:** `go test ./...`
- **CONTRIBUTING:** Check `CONTRIBUTING.md` or GitHub Discussions
- **Sign-off:** Not strictly enforced
- **PR title:** Conventional commits preferred
- **Maintainer activity:** Active
- **Winning patterns:** Go bugs in agent/ or cmd/ directories

---

## clastix/kamaji
- **Review speed:** Moderate — 3–7 days
- **Lint command:** `golangci-lint run`
- **Test command:** `go test ./...`
- **CONTRIBUTING:** `CONTRIBUTING.md` at root
- **Maintainer activity:** Active

---

## fluvio-community/fluvio
- **Review speed:** Moderate
- **Lint command:** `cargo clippy --all-targets` (Rust)
- **Note:** Primarily Rust — only contribute to Go components if present
- **Winning patterns:** Documentation, config validation

---

## aquasecurity/trivy-checks
- **Review speed:** Moderate — 5–10 days
- **Lint command:** `golangci-lint run`
- **Test command:** `go test ./...`
- **CONTRIBUTING:** `CONTRIBUTING.md`
- **Winning patterns:** Rego policy corrections, Go check fixes
