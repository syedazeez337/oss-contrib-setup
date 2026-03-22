# Go Diagnostics Reference

## Race Detector

```bash
# Run tests with race detection (always do this for concurrent code)
go test -race ./...
go test -race -run TestConcurrentAccess ./pkg/cache/... -v -count=1

# Build with race detector for manual testing
go build -race ./cmd/server
./server  # will report races to stderr
```

Race detector output tells you:
- Which goroutine wrote the data
- Which goroutine read it concurrently
- The exact file and line for both

Fix races with: sync.Mutex, sync.RWMutex, channels, sync/atomic, or sync.Once.

---

## Delve Debugger

```bash
# Install
go install github.com/go-delve/delve/cmd/dlv@latest

# Debug a test
dlv test ./pkg/forward -- -test.run TestParsePort -test.v

# Debug a binary
dlv exec ./bin/server

# Common commands inside dlv:
# b pkg/forward/forward.go:47  — set breakpoint at line
# c                             — continue
# n                             — next line
# s                             — step into
# p varname                     — print variable
# bt                            — backtrace
# locals                        — print all local variables
# exit                          — quit
```

---

## pprof — Performance Debugging

```bash
# CPU profile
go test -cpuprofile=cpu.out -bench=BenchmarkName ./pkg/...
go tool pprof cpu.out
# In pprof: top10, list FuncName, web

# Memory profile
go test -memprofile=mem.out -bench=BenchmarkName ./pkg/...
go tool pprof mem.out

# Heap profile from running server (if pprof endpoint enabled)
go tool pprof http://localhost:6060/debug/pprof/heap
```

---

## Common Panic Patterns

| Panic message | Root cause | Fix |
|---|---|---|
| `nil pointer dereference` | Accessing a field on a nil pointer or interface | Add nil check before dereference |
| `index out of range [N] with length M` | Slice/array access beyond bounds | Bounds check before indexing |
| `interface conversion: interface {} is nil, not T` | Type assertion on nil interface | Use comma-ok: `v, ok := x.(T)` |
| `assignment to entry in nil map` | Writing to an uninitialized map | Initialize: `m = make(map[K]V)` |
| `send on closed channel` | Writing to a channel after it's been closed | Track channel lifecycle; close from sender only |
| `concurrent map read and map write` | Unsynchronized map access | Use sync.RWMutex or sync.Map |
| `stack overflow` | Infinite recursion | Find the base case; add depth limit |
| `duplicate metrics collector` | Prometheus metric registered twice | Use `prometheus.Register` with error check |

---

## Build and Module Issues

```bash
# Check what version of a dependency is actually being used
go list -m all | grep <package>

# Why is a dependency included?
go mod why <package>

# Show the full dependency graph for a package
go mod graph | grep <package>

# Upgrade a specific dependency
go get <package>@latest

# Tidy after changes
go mod tidy

# Verify module integrity
go mod verify

# List all packages in the build
go list ./...

# Show build tags in effect
go list -f '{{.GoFiles}}' ./pkg/...
```

---

## Test Debugging

```bash
# Verbose output for a specific test
go test -run TestName ./pkg/... -v -count=1

# Run test multiple times (find flakiness)
go test -run TestName ./pkg/... -count=10

# Timeout control
go test -timeout 30s ./...

# Show test binary output even on pass
go test -v ./...

# Disable test result caching
go test -count=1 ./...

# Run benchmarks
go test -bench=BenchmarkName -benchmem ./pkg/...

# Generate coverage
go test -coverprofile=cov.out ./...
go tool cover -html=cov.out   # opens browser
go tool cover -func=cov.out   # text summary
```

---

## Goroutine Dump

When a program hangs or deadlocks:

```bash
# Send SIGQUIT to dump all goroutine stacks
kill -SIGQUIT <pid>

# Or in tests — set a timeout
go test -timeout 10s ./...
# On timeout, Go prints all goroutine stacks automatically
```

Read the dump: look for goroutines blocked on:
- `chan receive` — waiting for data that never comes
- `chan send` — writing to a full channel with no reader
- `sync.Mutex.Lock` — deadlock on a mutex
- `syscall.Read` / `syscall.Write` — blocked I/O

---

## golangci-lint Debugging

```bash
# Show which linters are enabled
golangci-lint linters

# Run only specific linters
golangci-lint run --disable-all --enable gosec,govet,errcheck

# Show linter output with file context
golangci-lint run --out-format=line-number

# Fix auto-fixable issues
golangci-lint run --fix

# Debug why a rule fires
golangci-lint run --verbose 2>&1 | grep G115
```
