---
description: Go language conventions and idiomatic patterns — applied to all Go files
paths:
  - "**/*.go"
---

# Go Conventions

## Naming
- Exported identifiers: `PascalCase` with a doc comment (`// FuncName does X`)
- Unexported identifiers: `camelCase`
- Constants: `PascalCase` (exported) or `camelCase` (unexported) — never `SCREAMING_SNAKE`
- Interfaces: single-method interfaces end in `-er` (Reader, Writer, Closer, Lister)
- Test files: `foo_test.go` — use `package foo_test` for black-box, `package foo` for white-box
- Acronyms: `userID`, `httpClient`, `URLPath` — not `userId`, `HttpClient`, `UrlPath`

## Error Handling
- Wrap with context at every return: `fmt.Errorf("parsing config: %w", err)`
- Return errors; never panic in library or controller code
- Never discard error returns with `_` unless explicitly justified with a comment
- Sentinel errors at package level: `var ErrNotFound = errors.New("not found")`
- Custom error types only when callers need to inspect the error with `errors.As`
- Always check `errors.Is` / `errors.As` for wrapped errors, not `==` on raw error values

## Testing
- Table-driven tests are the default pattern:
  ```go
  tests := []struct {
      name    string
      input   X
      want    Y
      wantErr bool
  }{...}
  for _, tc := range tests {
      t.Run(tc.name, func(t *testing.T) {
          t.Parallel()
          // arrange, act, assert
      })
  }
  ```
- Use `t.Helper()` in assertion helper functions
- Use `t.Parallel()` in every subtest that doesn't share state
- No global state in tests — each test sets up and tears down its own fixtures
- `testify/assert` and `testify/require` are fine; prefer `require` when failure should stop the test

## Concurrency
- Channels for ownership transfer; mutexes for shared mutable state
- Only the sender closes a channel, never the receiver
- Always check for nil before sending to a channel that might be closed
- Pass `context.Context` as the first argument in any function that may block or do I/O
- Use `errgroup` for fan-out patterns; avoid bare goroutines in non-trivial code

## Imports
- Three groups separated by blank lines: stdlib → external → internal
- Use `goimports` to manage — never manually sort
- No dot imports (`import . "pkg"`) except in tests where idiomatic
- Alias only when names genuinely conflict

## Anti-Patterns — Never Do These
- No naked returns in functions longer than 5 lines
- No `init()` functions unless the project already uses them throughout
- No global mutable state
- No `interface{}` / `any` unless the function genuinely handles arbitrary types
- No `time.Sleep` in production code paths — use timers, tickers, or context deadlines
- No `log.Fatal` / `os.Exit` outside of `main()`
- No unexported struct fields accessed via reflection in tests
