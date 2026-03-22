# PR Description Template

## Standard Template

```markdown
## Problem
<One sentence: what is wrong or broken. Write from the user/operator perspective.>

## Root Cause
<1–2 sentences: why it is wrong at the code level. Be specific about the file and line if possible.>

## Fix
<One sentence: what this PR changes to address the root cause.>

## Verification
```bash
# Command to reproduce the problem before the fix:
<reproduce command>

# Command to confirm the fix:
<verify command>
```

Fixes #<issue-number>
```

---

## Filled Examples

### gosec G115 — Integer Overflow

```markdown
## Problem
The port conversion in `pkg/forward/forward.go` silently overflows when the configured
port value exceeds `math.MaxInt32`, resulting in an incorrect negative port number being
used for upstream connections.

## Root Cause
`int32(port)` performs an unchecked conversion from `int64`. gosec rule G115 flags this
because values above `2147483647` wrap around to a negative value silently.

## Fix
Added a bounds check before the conversion that returns an error if the value falls outside
the valid `int32` range.

## Verification
```bash
# Before fix: no error, wrong port used
go test -run TestParsePort_Overflow ./pkg/forward -v

# After fix: error returned for out-of-range port
go test -run TestParsePort ./pkg/forward -v
```

Fixes #1234
```

---

### Workqueue Metrics Conflict

```markdown
## Problem
Starting two instances of the controller in the same process causes a panic:
`panic: duplicate metrics collector registration attempted`.

## Root Cause
The workqueue metrics are registered globally in `init()` without checking for prior
registration. When the controller is initialised more than once (e.g., in integration
tests), the second registration panics.

## Fix
Wrapped the metrics registration with `prometheus.MustRegister` replaced by a checked
`prometheus.Register` call that returns `already registered` errors gracefully.

## Verification
```bash
# Reproduce: run integration test suite that initialises controller twice
go test -run TestControllerDoubleInit ./pkg/controller/... -v

# After fix: no panic, second registration is a no-op
go test ./pkg/controller/... -v
```

Closes #5678
```

---

### CRD Schema Fix

```markdown
## Problem
Applying the Kafka CRD with `kubectl apply` returns a validation error:
`spec.versions[0].schema.openAPIV3Schema.properties[spec]: duplicate property "replicas"`.

## Root Cause
The `replicas` field is defined twice in `config/crd/bases/kafka.strimzi.io_kafkas.yaml`
at lines 142 and 287, which violates the OpenAPI v3 uniqueness requirement.

## Fix
Removed the duplicate `replicas` field definition at line 287, keeping the one at line 142
which includes the correct description and validation constraints.

## Verification
```bash
# Before fix: kubectl apply fails
kubectl apply --dry-run=client -f config/crd/bases/kafka.strimzi.io_kafkas.yaml

# After fix: applies cleanly
kubectl apply --dry-run=client -f config/crd/bases/kafka.strimzi.io_kafkas.yaml
```

Fixes #910
```

---

## What Makes a Description Fail

| Problem | Example | Fix |
|---|---|---|
| No root cause | "This PR fixes the overflow bug" | Explain *why* the overflow happens |
| No verification | Description ends after fix | Add the exact command to run |
| Vague problem | "Various improvements to error handling" | Name the specific error and where it occurs |
| Missing issue link | No `Fixes #N` line | Always link the issue |
| Wall of text | 10 sentences explaining context | Cut to the 5 required elements only |
