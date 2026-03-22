# Go Test Patterns Reference

## TestMain — Setup and Teardown

Use when tests in a package require shared setup (database connection, temp directory, etc.):

```go
func TestMain(m *testing.M) {
    // setup
    tempDir, err := os.MkdirTemp("", "test-*")
    if err != nil {
        log.Fatalf("setup failed: %v", err)
    }

    code := m.Run()

    // teardown
    os.RemoveAll(tempDir)
    os.Exit(code)
}
```

---

## Subtests and Cleanup

```go
func TestWithCleanup(t *testing.T) {
    t.Run("creates temp file", func(t *testing.T) {
        t.Parallel()

        f, err := os.CreateTemp("", "test-*")
        if err != nil {
            t.Fatalf("creating temp file: %v", err)
        }
        t.Cleanup(func() { os.Remove(f.Name()) })

        // test body
    })
}
```

`t.Cleanup` is preferred over `defer` in tests — it runs even after `t.FailNow()`.

---

## Assertion Helpers

```go
func assertNoError(t *testing.T, err error) {
    t.Helper()  // required — makes failures report at the call site
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual[T comparable](t *testing.T, got, want T) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}
```

---

## Testing HTTP Handlers

```go
func TestHandlerName(t *testing.T) {
    tests := []struct {
        name       string
        method     string
        body       string
        wantStatus int
        wantBody   string
    }{
        {name: "valid request", method: http.MethodPost, body: `{"port":8080}`, wantStatus: 200},
        {name: "invalid port",  method: http.MethodPost, body: `{"port":99999}`, wantStatus: 400},
    }
    for _, tc := range tests {
        t.Run(tc.name, func(t *testing.T) {
            t.Parallel()

            req := httptest.NewRequest(tc.method, "/path", strings.NewReader(tc.body))
            req.Header.Set("Content-Type", "application/json")
            w := httptest.NewRecorder()

            handler := NewHandler() // the handler under test
            handler.ServeHTTP(w, req)

            if w.Code != tc.wantStatus {
                t.Errorf("status = %d, want %d; body: %s", w.Code, tc.wantStatus, w.Body.String())
            }
        })
    }
}
```

---

## Testing with Interfaces and Fakes

Prefer fakes over mocks for CNCF project PRs — maintainers often reject mock frameworks:

```go
// Define a fake that implements the interface
type fakeClient struct {
    responses map[string]string
    callCount int
}

func (f *fakeClient) Get(key string) (string, error) {
    f.callCount++
    v, ok := f.responses[key]
    if !ok {
        return "", fmt.Errorf("key %q not found", key)
    }
    return v, nil
}

// Use in test
func TestServiceGet(t *testing.T) {
    client := &fakeClient{
        responses: map[string]string{"key1": "value1"},
    }
    svc := NewService(client)
    // ...
}
```

---

## Benchmarks

```go
func BenchmarkConvertPort(b *testing.B) {
    for i := 0; i < b.N; i++ {
        _, _ = ConvertPort(int64(8080))
    }
}

// With memory allocation tracking
func BenchmarkConvertPortAlloc(b *testing.B) {
    b.ReportAllocs()
    for i := 0; i < b.N; i++ {
        _, _ = ConvertPort(int64(8080))
    }
}
```

Run:
```bash
go test -bench=BenchmarkConvertPort -benchmem -benchtime=5s ./pkg/forward
```

---

## Golden File Tests

For tests where the expected output is large (generated YAML, JSON, Markdown):

```go
func TestGenerateConfig(t *testing.T) {
    got := GenerateConfig(defaultOptions)

    golden := filepath.Join("testdata", t.Name()+".golden")
    if *update {  // run with -update flag to regenerate
        os.WriteFile(golden, []byte(got), 0600)
    }

    want, err := os.ReadFile(golden)
    if err != nil {
        t.Fatalf("reading golden file: %v", err)
    }
    if got != string(want) {
        t.Errorf("output mismatch\ngot:\n%s\nwant:\n%s", got, want)
    }
}

var update = flag.Bool("update", false, "update golden files")
```

Store golden files in `testdata/` — it is `.gitignore`-free by Go convention.

---

## Testing Context Cancellation

```go
func TestWithContextCancel(t *testing.T) {
    ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
    defer cancel()

    done := make(chan struct{})
    go func() {
        defer close(done)
        err := LongRunningOperation(ctx)
        if !errors.Is(err, context.DeadlineExceeded) {
            t.Errorf("expected DeadlineExceeded, got %v", err)
        }
    }()

    select {
    case <-done:
        // ok
    case <-time.After(500 * time.Millisecond):
        t.Error("operation did not respect context deadline")
    }
}
```
