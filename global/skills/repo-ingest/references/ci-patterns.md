# CI Patterns — Known CNCF Repos

Quick reference for repos where we have confirmed merge history.
`repo-ingest` derives this from live files — use this only when CI config is absent or ambiguous.

## coredns/coredns

| Item | Value |
|---|---|
| Lint | `golangci-lint run --timeout 5m` (v2.x, pinned in CI) |
| Test | `go test -race ./... -count=1` |
| Build | `go build -v ./...` |
| Sign-off | DCO — `git commit -s` required, enforced by Probot |
| Commit format | `plugin/name: short description` or `component: description` |
| PR template | Why / Which issues / Docs impact / Breaking changes |
| CI jobs | go.test.yml (race), golangci-lint.yml, codeql-analysis.yml, trivy-scan.yaml |
| Review speed | < 24h for gosec fixes; 2–5 days for features |
| Gotcha | golangci-lint v2.x — lint config uses `linters.default: none` + explicit list |

## cilium/cilium

| Item | Value |
|---|---|
| Lint | `make lint` (requires Docker) or `golangci-lint run --timeout 10m` |
| Test | `go test ./... -count=1` |
| Build | `make build` |
| Sign-off | DCO — `git commit -s` required |
| Commit format | `type/scope: description` — e.g. `fix/ciliumendpoint: prevent overflow` |
| PR template | Problem / Solution / Related issues |
| CI jobs | build, lint, unit-tests, e2e (slow, not required for small fixes) |
| Review speed | 3–7 days |
| Gotcha | PR title must match `type/scope: description` — bot enforces it |

## strimzi/strimzi-kafka-operator

| Item | Value |
|---|---|
| Lint | `./mvnw checkstyle:check` or `./gradlew checkstyle` |
| Test | `./mvnw test` or `./gradlew test` |
| Build | `./mvnw package -DskipTests` |
| Sign-off | CLA — must sign Strimzi CLA before first PR |
| Commit format | Plain English: `Fix duplicate field in CRD schema` |
| PR template | Description / Tests / Related issues |
| CI jobs | java-build, checkstyle, unit-tests |
| Review speed | 2–5 days |
| Gotcha | CLA bot blocks merge until CLA signed |

## kagent-dev/kagent

| Item | Value |
|---|---|
| Lint | `golangci-lint run` |
| Test | `go test ./... -count=1` |
| Build | `go build ./...` |
| Sign-off | none |
| Commit format | Conventional commits: `fix(component): description` |
| Review speed | < 48h (small team, responsive) |

## aquasecurity/trivy-checks

| Item | Value |
|---|---|
| Lint | `golangci-lint run` |
| Test | `go test ./... -count=1` |
| Build | `go build ./...` |
| Sign-off | none |
| Commit format | Plain English |
| Review speed | 3–7 days |
