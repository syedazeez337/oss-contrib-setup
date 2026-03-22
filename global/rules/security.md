---
description: Security rules for Go code — gosec patterns and secure coding conventions
paths:
  - "**/*.go"
---

# Security Rules

## gosec — The High-Value Patterns

These are the exact findings that produce merged PRs. Know them by heart.

### G114 — net/http serve without timeouts
```go
// BAD — gosec G114
http.ListenAndServe(addr, handler)
http.ListenAndServeTLS(addr, cert, key, handler)

// GOOD
srv := &http.Server{
    Addr:         addr,
    Handler:      handler,
    ReadTimeout:  5 * time.Second,
    WriteTimeout: 10 * time.Second,
    IdleTimeout:  120 * time.Second,
}
if err := srv.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
    return fmt.Errorf("server exited: %w", err)
}
```

### G115 — Integer overflow in type conversion
```go
// BAD — gosec G115
var i int64 = getValue()
small := int32(i)   // silent overflow if i > MaxInt32
port  := uint16(n)  // silent truncation

// GOOD
var i int64 = getValue()
if i > math.MaxInt32 || i < math.MinInt32 {
    return fmt.Errorf("value %d overflows int32", i)
}
small := int32(i)
```

### G301 — Directory created with excessive permissions
```go
// BAD — gosec G301
os.MkdirAll(path, 0777)
os.Mkdir(path, 0755)

// GOOD
os.MkdirAll(path, 0750)  // group read+execute, no world access
os.MkdirAll(path, 0700)  // private directory
```

### G304 — File path from taint input (path traversal)
```go
// BAD — gosec G304
data, err := os.ReadFile(userInput)

// GOOD
clean := filepath.Clean(userInput)
if !strings.HasPrefix(clean, allowedBaseDir+string(filepath.Separator)) {
    return fmt.Errorf("path %q is outside allowed directory", clean)
}
data, err := os.ReadFile(clean)
```

### G401 / G501 — Weak cryptographic primitives
```go
// BAD — MD5/SHA1 for security purposes
h := md5.New()
h := sha1.New()

// GOOD — use SHA-256 or better
h := sha256.New()
// Exception: MD5/SHA1 are fine for non-security checksums (content hashing, etags)
// Always add a comment explaining the non-security use
```

## General Secure Coding Rules
- Never log secrets, tokens, passwords, or PII — use placeholder: `log.Info("token", "value", "[REDACTED]")`
- Never hardcode credentials — use environment variables validated at startup
- Use `crypto/rand` for security-sensitive random values; `math/rand` is never acceptable for security
- Validate all inputs at package/API boundaries; trust nothing from external callers
- Prefer `os.ReadFile` / `os.WriteFile` over manual `Open` + `Read` + `Close` chains
- HTTP clients used in tests: always set a timeout — `&http.Client{Timeout: 5 * time.Second}`

## When Proposing gosec Fixes
- Reference the exact rule number in the PR title: `fix(pkg): address gosec G115 in port conversion`
- Explain the security impact in one sentence in the PR body
- Add a test that exercises the boundary condition the fix protects
- Do not "fix" gosec findings that are false positives by adding `//nolint:gosec` without a comment explaining why
