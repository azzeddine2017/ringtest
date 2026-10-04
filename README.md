
# ringtest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ring Version](https://img.shields.io/badge/Ring-1.21%2B-blue.svg)](https://ring-lang.github.io)

**ringtest** is a modern, ultra-fast, and lightweight unit testing framework and test runner for the [Ring programming language](https://ring-lang.github.io).

It brings familiar BDD/TDD-style assertions (`describe`, `it`, `expect`) and automated test discovery with colorful terminal reports to the Ring ecosystem.

---

## Features

- ⚡ **Ultra Fast**: Zero-overhead test runner executing suites in milliseconds.
- 🎨 **Beautiful ANSI Reporter**: Instant colored feedback (`✓ PASS`, `✗ FAIL`, timings, and diffs).
- 🔍 **Automatic Discovery**: Automatically scans and runs all `*_test.ring` and `test_*.ring` files.
- 🛡️ **Error Boundary**: Isolated `try/catch` execution so one failing test doesn't crash the entire suite.
- 📦 **Zero External Dependencies**: Pure native Ring implementation.
- 🚀 **CI/CD Ready**: Exits with standard status codes (`0` on success, `1` on failure).
- 🔎 **Test Filtering**: Filter tests by description with `--filter=<text>`.
- 👀 **Watch Mode**: Re-run tests automatically on file changes with `--watch`.
- 📊 **JSON Output**: Machine-readable output for CI/CD integration with `--json`.
- 🔄 **Lifecycle Hooks**: `beforeEach` and `afterEach` support for test setup/cleanup.
- 🎭 **Mocking**: Mock registry and call recorder for isolating tests.

---

## Installation

### Method 1: Using RingPM (Recommended)
```bash
ringpm install ringtest from Azzeddine2017
```

### Method 2: Global Setup from Source
Clone the repository and run the setup script:

**Windows:**
```cmd
git clone https://github.com/Azzeddine2017/ringtest.git
cd ringtest
setup.bat
```

**Linux / macOS:**
```bash
git clone https://github.com/Azzeddine2017/ringtest.git
cd ringtest
chmod +x setup.sh
./setup.sh
```

---

## Quickstart

### 1. Create a Test File
Create `tests/math_test.ring` — **no `load` line is needed**, the runner already
provides `describe`, `it` and `expect` to every discovered test file:

```ring
describe("Math Operations", func {

    it("should add numbers correctly", func {
        expect(10 + 20).toBe(30)
    })

    it("should compare numerical bounds", func {
        expect(100).toBeGreaterThan(50)
        expect(25).toBeLessThan(50)
    })

    it("should catch runtime exceptions", func {
        expect("1 / 0").toThrow()
    })
})
```

> **Ordering rule:** `describe(...)` must come **before** any trailing `func`/`class`
> block in the file. Ring swallows everything that follows a `func`/`class` definition,
> so a suite declared after them never registers.

> **Shared state:** a test file's own top-level variables are **not** visible from
> inside `it()`/`beforeEach` callbacks (the runner evaluates the file in a scope that
> pops). Use the context API instead — see [Shared Context](#shared-context) below.

### 2. Run Tests
Run `ringtest` from your project root:

```bash
ringtest
```

Or execute directly with Ring:
```bash
ring main.ring
```

---

## Assertions Reference

| Assertion | Description | Example |
|---|---|---|
| `.toBe(value)` | Strict equality check | `expect(2 + 2).toBe(4)` |
| `.toEqual(list)` | Deep list/structure equality | `expect([1, [2]]).toEqual([1, [2]])` |
| `.toBeTruthy()` | Asserts value is not null, 0, or empty | `expect("hello").toBeTruthy()` |
| `.toBeFalsy()` | Asserts value is null, 0, false, or empty | `expect("").toBeFalsy()` |
| `.toContain(item)` | Checks substring or list element | `expect(["a", "b"]).toContain("a")` |
| `.toBeGreaterThan(n)` | Numeric greater than | `expect(10).toBeGreaterThan(5)` |
| `.toBeLessThan(n)` | Numeric less than | `expect(5).toBeLessThan(10)` |
| `.toThrow()` | Asserts evaluated string throws an error | `expect("1 / 0").toThrow()` |
| `.toBeBetween(min, max)` | Numeric range check | `expect(50).toBeBetween(1, 100)` |
| `.toMatch(pattern)` | String pattern matching | `expect("hello123").toMatch("hello")` |
| `.toBeEmpty()` | Asserts string or list is empty | `expect("").toBeEmpty()` |
| `.toHaveLength(n)` | Asserts string/list length | `expect("hello").toHaveLength(5)` |

---

## Hooks

Hooks are **global to the test file** and run around every test:

```ring
beforeEach(func {
    ctxIncr("nRuns")
})

afterEach(func {
    # cleanup
})
```

---

## Shared Context

A test file's own top-level variables are **not** reachable from inside `it()` /
`beforeEach` callbacks: the runner evaluates the file in a scope that is discarded when
the evaluation returns. Keep shared state in the framework context instead:

| Function | Description |
|---|---|
| `ctxSet(key, value)` | Store a value (any type) |
| `ctxGet(key)` | Read a value — returns `""` when the key is missing |
| `ctxIncr(key)` | Numerically add 1 (safe on a missing key) |
| `ctxAdd(key, n)` | Numerically add `n` |

```ring
beforeEach(func {
    ctxIncr("nBefore")
})

describe("Counter", func {
    it("counts runs", func {
        expect(ctxGet("nBefore")).toBe(1)
    })
})
```

> Use `ctxIncr`/`ctxAdd` rather than `ctxGet(k) + 1`: Ring's `+` **concatenates** when the
> value is a string, so `"" + 1` becomes `"1"` and a second `+ 1` becomes `"11"`.

The context is cleared before each test file.

---

## Mocking

```ring
oMock = mock("targetFunction", NULL)   # register
oMock.doCall()                          # record a call
oMock.getCallCount()                    # -> 1
oMock.wasCalled()                       # -> true
getMock("targetFunction")               # -> the Mock object
restore("targetFunction")               # remove one
restoreAll()                            # remove all
```

> **Scope:** this is a mock **registry and call recorder**. It does not swap the real
> function's implementation at runtime.

---

## CLI Options

```text
Usage:
  ringtest [options] [target_path]

Options:
  -h, --help        Show help documentation
  -v, --version     Display current version
  --filter=<text>   Filter tests by description
  -w, --watch       Watch mode: re-run tests on file changes
  -j, --json        Output results in JSON format

Examples:
  ringtest                     # Discover and run all tests
  ringtest tests/              # Run all tests in 'tests/' directory
  ringtest tests/math_test.ring # Run a specific test file
  ringtest --filter=math       # Run only tests matching 'math'
  ringtest --watch             # Watch mode
  ringtest --json              # JSON output
```

> `--filter` matches the **individual `it()` description**, not the suite or file name.
> A filter matching nothing reports `0 passed, 0 total` and still exits `0`.

---

## License

This project is open source and available under the [MIT License](LICENSE).


