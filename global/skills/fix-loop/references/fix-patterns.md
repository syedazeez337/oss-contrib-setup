# Fix Patterns — Standard Before/After

Standard fixes for the most common issues in CNCF Go repos.
Each pattern: problem description, before code, after code, verification command.

---

## gosec G115 — Integer overflow in type conversion

**Problem:** Converting a wider integer type to a narrower one without bounds check.
Triggers when `int64`, `uint64`, or `int` is cast to `int32`, `uint32`, `uint16`, `uint8`, etc.

**Before:**
```go
port := int32(someInt64Value)
```

**After:**
```go
if someInt64Value > math.MaxInt32 || someInt64Value < math.MinInt32 {
    return fmt.Errorf("value %d out of int32 range", someInt64Value)
}
port := int32(someInt64Value)
```

Or if the value is a port number (always positive, max 65535):
```go
if someValue < 0 || someValue > math.MaxUint16 {
    return fmt.Errorf("port %d out of range [0, 65535]", someValue)
}
port := uint16(someValue)
```

**Required import:** `"math"` (if using math.MaxInt32)

**Verification:**
```bash
golangci-lint run --timeout 2m path/to/file.go 2>&1 | grep G115
# Should be empty
```

**Test pattern:**
```go
func TestConvert_Overflow(t *testing.T) {
    tests := []struct {
        name    string
        input   int64
        wantErr bool
    }{
        {"valid", 8080, false},
        {"max valid", math.MaxUint16, false},
        {"overflow", math.MaxUint16 + 1, true},
        {"negative", -1, true},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            _, err := ConvertPort(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("ConvertPort(%d) error = %v, wantErr %v", tt.input, err, tt.wantErr)
            }
        })
    }
}
```

---

## gosec G114 — HTTP server without read/write timeout

**Problem:** `http.ListenAndServe` or `http.Server` used without timeout fields set.

**Before:**
```go
http.ListenAndServe(addr, handler)
```

**After:**
```go
srv := &http.Server{
    Addr:         addr,
    Handler:      handler,
    ReadTimeout:  10 * time.Second,
    WriteTimeout: 10 * time.Second,
}
if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
    return err
}
```

Or for `net/http` in a plugin context:
```go
srv := &http.Server{
    Addr:              addr,
    Handler:           mux,
    ReadHeaderTimeout: 10 * time.Second,
}
```

**Required import:** `"time"`

**Verification:**
```bash
golangci-lint run --timeout 2m path/to/file.go 2>&1 | grep G114
```

---

## gosec G301 — Directory created with overly broad permissions

**Problem:** `os.MkdirAll` or `os.Mkdir` called with permissions wider than 0750.

**Before:**
```go
os.MkdirAll(path, 0755)
os.MkdirAll(path, 0777)
```

**After:**
```go
os.MkdirAll(path, 0750)
```

For world-readable paths where that's intentional, add a `//nolint:gosec // G301: public dir by design` comment — but only with justification.

**Verification:**
```bash
golangci-lint run --timeout 2m path/to/file.go 2>&1 | grep G301
```

---

## gosec G304 — File path from tainted variable

**Problem:** `os.Open`, `os.ReadFile`, or similar called with a path derived from user input without sanitisation.

**Before:**
```go
data, err := os.ReadFile(userInput)
```

**After:**
```go
// Option 1: validate against allowed base directory
clean := filepath.Clean(userInput)
if !strings.HasPrefix(clean, allowedBase) {
    return nil, fmt.Errorf("path %q outside allowed directory", userInput)
}
data, err := os.ReadFile(clean)

// Option 2: use embed or hardcoded paths instead of user input
```

**Verification:**
```bash
golangci-lint run --timeout 2m path/to/file.go 2>&1 | grep G304
```

---

## gosec G401/G501 — Weak cryptographic hash

**Problem:** `md5.New()` or `sha1.New()` used for security-sensitive hashing.

**Before:**
```go
import "crypto/md5"
h := md5.Sum(data)
```

**After (for integrity checks — not password hashing):**
```go
import "crypto/sha256"
h := sha256.Sum256(data)
```

**After (for non-security checksums where md5 is intentional):**
```go
import "crypto/md5" //nolint:gosec // G501: md5 used for non-security checksum only
```

---

## duplicate metric registration (workqueue)

**Problem:** Two packages register a metric with the same name, causing a panic on init.

**Pattern:**
```
panic: duplicate metrics collector registration attempted
```

**Fix:** Use `prometheus.MustRegister` with a `prometheus.NewRegistry()` per component, OR check if already registered:

```go
// Before (panics on duplicate):
prometheus.MustRegister(myMetric)

// After (idempotent):
if err := prometheus.Register(myMetric); err != nil {
    if _, ok := err.(prometheus.AlreadyRegisteredError); !ok {
        return err
    }
    // Already registered — use existing
}
```

---

## Missing error check

**Problem:** Error return from a function is ignored.

**Before:**
```go
w.Write(data)
```

**After:**
```go
if _, err := w.Write(data); err != nil {
    return fmt.Errorf("write failed: %w", err)
}
```

---

## unconvert — Unnecessary type conversion

**Problem:** Converting a value to its own type.

**Before:**
```go
x := int(someInt)       // someInt is already int
```

**After:**
```go
x := someInt
```

Auto-fixable with `golangci-lint run --fix`.
