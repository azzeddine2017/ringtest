# ringtest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ring Version](https://img.shields.io/badge/Ring-1.21%2B-blue.svg)](https://ring-lang.github.io)
[![Version](https://img.shields.io/badge/version-1.2.0-green.svg)](https://github.com/Azzeddine2017/ringtest)

**ringtest** is a modern, ultra-fast, and comprehensive unit testing framework and test runner for the [Ring programming language](https://ring-lang.github.io).

It brings familiar BDD/TDD-style assertions (`describe`, `it`, `test`, `expect`), parameterized tests (`itEach`), skip/todo/xfail workflows, high-precision performance benchmarking (`benchmark`), lifecycle hooks, rich diagnostic error tips, and automated test discovery with colorful terminal reports, interactive HTML dashboards, and JUnit XML outputs to the Ring ecosystem.

---

## Features

- ⚡ **Ultra Fast**: Zero-overhead test runner executing suites in milliseconds.
- 🎨 **Beautiful ANSI Reporter**: Instant colored feedback (`✓ PASS`, `○ SKIP`, `✗ FAIL`, timings, and clean diffs).
- 🔍 **Automatic Discovery**: Automatically scans and runs all `*_test.ring` and `test_*.ring` files in `./tests`.
- 📊 **Interactive HTML Dashboard**: Generate self-contained dark-mode HTML reports with `--html` (supports status filters, search, and skipped badges).
- 📋 **CI/CD JUnit XML**: Standard JUnit XML reports (`--junit` / `--xml`) with `<skipped/>` tag support for GitHub Actions, GitLab CI, and Jenkins.
- 🔁 **Parameterized / Data-Driven Tests**: Run test cases over tables of data with `itEach` / `testEach`.
- ⏭️ **Skip, Todo & Expected Failure**: Mark tests as `itSkip`, `itTodo`, or `itFailing` / `itXFail`, and skip entire suites with `suite.skipAll()`.
- ⚡ **Built-in Benchmarking**: High-precision performance measurement (`benchmark`) and side-by-side comparison (`benchmarkCompare`).
- 🔄 **Complete Lifecycle Hooks**: Suite-level & Global `beforeAll`, `beforeEach`, `afterEach`, and `afterAll`.
- 💡 **Smart Diagnostics**: Built-in Ring runtime error analysis (R19, R24, R26...) with actionable fix tips.
- 🛡️ **Subprocess Isolation**: Isolated execution so failing tests or crashes don't break the entire test run.
- 🔎 **Test Filtering**: Filter tests by description with `--filter=<text>`.
- 👀 **Watch Mode**: Re-run tests automatically on file changes with `--watch`.
- 📊 **JSON Output**: Machine-readable output for CI/CD integration with `--json`.
- 🎭 **Mocking & Spies**: Built-in mock registry, call recorder, and expectation matchers (`toHaveBeenCalled`, `toHaveBeenCalledTimes`).
- 📦 **Zero External Dependencies**: Pure native Ring implementation.

---

## Installation

### Method 1: Using RingPM (Recommended)
```bash
ringpm install ringtest from Azzeddine2017
```

### Method 2: Global Setup from Source (Pure Ring)
Clone the repository and run the setup installer with Ring on any OS (Windows, Linux, macOS):

```bash
git clone https://github.com/Azzeddine2017/ringtest.git
cd ringtest
ring setup.ring
```

To uninstall:
```bash
ring setup.ring remove
```

---

## Quickstart

### 1. Create a Test File
Create `tests/math_test.ring` — **no `load` line is needed**, the runner already provides `describe`, `it`, `test` and `expect` to every discovered test file:

```ring
describe("Math Operations", func {

    it("should add numbers correctly", func {
        expect(10 + 20).toBe(30)
    })

    test("should compare numerical bounds", func {
        expect(100).toBeGreaterThanOrEqual(100)
        expect(25).toBeLessThan(50)
    })

    it("should catch runtime exceptions", func {
        expect("1 / 0").toThrowError("Zero")
    })
})
```

> **Ordering rule:** `describe(...)` must come **before** any trailing `func`/`class` block in the file. Ring swallows everything that follows a top-level `func`/`class` definition.

### 2. Run Tests
Run `ringtest` from your project root:

```bash
ringtest
```

Or run with HTML and JUnit reporting:
```bash
ringtest --html --junit
```

---

## Assertions Reference

| Assertion | Description | Example |
|---|---|---|
| `.toBe(value)` | Strict equality check | `expect(2 + 2).toBe(4)` |
| `.toEqual(list)` | Deep list/structure equality | `expect([1, [2]]).toEqual([1, [2]])` |
| `.toBeTruthy()` | Asserts value is not null, 0, false, or empty | `expect("hello").toBeTruthy()` |
| `.toBeFalsy()` | Asserts value is null, 0, false, or empty | `expect("").toBeFalsy()` |
| `.toBeNull()` | Asserts value is NULL | `expect(NULL).toBeNull()` |
| `.toBeNotNull()` / `.notToBeNull()` | Asserts value is not NULL | `expect("Ring").toBeNotNull()` |
| `.toBeString()` | Asserts value is a string | `expect("hello").toBeString()` |
| `.toBeNumber()` | Asserts value is a number | `expect(42).toBeNumber()` |
| `.toBeList()` | Asserts value is a list | `expect([1, 2, 3]).toBeList()` |
| `.toBeObject()` | Asserts value is an object instance | `expect(new MyClass).toBeObject()` |
| `.toContain(item)` | Checks substring or list element | `expect(["a", "b"]).toContain("a")` |
| `.toBeGreaterThan(n)` | Numeric strictly greater than | `expect(10).toBeGreaterThan(5)` |
| `.toBeGreaterThanOrEqual(n)` / `.toBeGte(n)` | Numeric greater than or equal | `expect(10).toBeGreaterThanOrEqual(10)` |
| `.toBeLessThan(n)` | Numeric strictly less than | `expect(5).toBeLessThan(10)` |
| `.toBeLessThanOrEqual(n)` / `.toBeLte(n)` | Numeric less than or equal | `expect(5).toBeLessThanOrEqual(5)` |
| `.toBeCloseTo(expected, delta)` | Approximate floating point equality | `expect(0.1 + 0.2).toBeCloseTo(0.3, 0.001)` |
| `.toStartWith(prefix)` | Asserts string starts with prefix | `expect("RingLang").toStartWith("Ring")` |
| `.toEndWith(suffix)` | Asserts string ends with suffix | `expect("document.pdf").toEndWith(".pdf")` |
| `.toBeSorted()` | Asserts list elements are in ascending order | `expect([1, 2, 3, 4]).toBeSorted()` |
| `.toThrow()` | Asserts evaluated code throws an error | `expect("1 / 0").toThrow()` |
| `.toThrowError(substr)` | Asserts error message contains substring | `expect("1 / 0").toThrowError("Zero")` |
| `.notToThrow()` / `.toNotThrow()` | Asserts evaluated code executes without error | `expect("a = 5 + 5").notToThrow()` |
| `.toBeBetween(min, max)` | Numeric range check | `expect(50).toBeBetween(1, 100)` |
| `.toMatch(pattern)` | String pattern matching | `expect("hello123").toMatch("hello")` |
| `.toBeEmpty()` | Asserts string or list is empty | `expect("").toBeEmpty()` |
| `.toHaveLength(n)` | Asserts string/list length | `expect("hello").toHaveLength(5)` |
| `.toHaveBeenCalled()` | Asserts spy/mock was invoked at least once | `expect(myMock).toHaveBeenCalled()` |
| `.toHaveBeenCalledTimes(n)` | Asserts spy/mock was called exact `n` times | `expect(myMock).toHaveBeenCalledTimes(3)` |

---

## Parameterized / Data-Driven Tests (`itEach`)

Run the same test logic against multiple inputs with `itEach` / `testEach`:

```ring
describe("Parameterized Math", func {

    itEach([[1, 2, 3], [10, 20, 30], [5, 5, 10]], "adds %1 + %2 = %3", func a, b, expected {
        expect(a + b).toBe(expected)
    })

    itEach(["apple", "banana", "cherry"], "fruit '%1' is not empty", func fruit {
        expect(len(fruit)).toBeGreaterThan(0)
    })
})
```

---

## Skip, Todo & Expected Failures

Manage test lifecycle and pending work easily:

```ring
describe("Feature Workflows", func {

    # Temporarily skip a test with an optional reason
    itSkip("payment processing integration", "Awaiting gateway credentials")

    # Mark a placeholder test for future implementation
    itTodo("export report to Excel format")

    # Expected failure (XFail) — passes suite when it fails, warns on unexpected pass
    itFailing("unimplemented feature", func {
        expect(10).toBe(999)
    }, "Known bug #42")
})
```

---

## Performance Benchmarking

Measure performance and compare function throughput directly in your test suites:

```ring
describe("Performance Benchmark", func {

    it("measures execution throughput", func {
        res = benchmark("String Concatenation", 1000, func {
            s = ""
            for i = 1 to 50
                s += "a"
            next
        })
        expect(res[:opsPerSec]).toBeGreaterThan(1000)
    })

    it("compares two implementations side-by-side", func {
        benchmarkCompare(
            "List Add", func { a = [] add(a, 1) },
            "List Plus", func { a = [] a + 1 },
            1000
        )
    })
})
```

---

## Lifecycle Hooks

You can define hooks both **inside a suite** (scoped to that suite) or **at the top-level** (global across all suites):

```ring
# Global Hooks
beforeAll(func {
    # Runs once before all suites in the file
})

describe("Database Suite", func {

    beforeAll(func {
        # Runs once before any test in this suite
        ctxSet("dbConnected", true)
    })

    beforeEach(func {
        # Runs before each test in this suite
        ctxIncr("queryCount")
    })

    afterEach(func {
        # Runs after each test in this suite
    })

    afterAll(func {
        # Runs once after all tests in this suite
        ctxSet("dbConnected", false)
    })

    test("should perform transaction", func {
        expect(ctxGet("dbConnected")).toBe(true)
    })
})
```

---

## Shared Context

A test file's top-level variables are isolated from inside `it()`/`test()` callbacks. Use the built-in context API to pass state safely across test boundaries:

| Function | Description |
|---|---|
| `ctxSet(key, value)` | Store a value (any type) |
| `ctxGet(key)` | Read a value — returns `""` when the key is missing |
| `ctxIncr(key)` | Numerically add 1 (safe on a missing key) |
| `ctxAdd(key, n)` | Numerically add `n` |

---

## Mocking & Spying

```ring
# Register a mock function spy
m = mock("calcTax", NULL)
m.setReturn(15.0)

# Invoke spy
m.doCall()
m.doCall()

# Assertions
expect(m).toHaveBeenCalled()
expect(m).toHaveBeenCalledTimes(2)
expect(m.wasCalledTimes(2)).toBeTruthy()

# Clean up
restore("calcTax")
```

---

## Reporting & CI/CD Integration

### 1. Interactive Dark-Mode HTML Report (`--html`)
Generate a self-contained HTML test dashboard with interactive status metrics, real-time search filter, and expandable error diffs saved to `reports/test-report.html`:

```bash
ringtest --html
# Or specify a custom output path:
ringtest --html=custom-dir/report.html
```

### 2. Standard JUnit XML Report (`--junit` / `--xml`)
Generate standard JUnit XML test reports compatible with GitHub Actions, GitLab CI, Jenkins, and Azure DevOps saved to `reports/test-report.xml`:

```bash
ringtest --junit
# Or specify a custom output path:
ringtest --junit=reports/results.xml
```

### 3. Combined Reports
```bash
ringtest --html --junit
```

---

## CLI Options & Usage

```text
Usage:
  ringtest [options] [target_path]

Options:
  -h, --help           Show help documentation
  -v, --version        Display the current ringtest version
  --filter=<text>      Filter executed tests by description
  -w, --watch          Watch mode: re-run tests on file changes
  -j, --json           Output results in machine-readable JSON format
  --html[=<path>]      Generate modern interactive HTML dashboard
  --junit[=<path>]     Generate standard JUnit XML report for CI/CD
  --xml[=<path>]       Alias for --junit

Examples:
  ringtest                           # Discover and run all tests in ./tests
  ringtest tests/                    # Run all tests in 'tests/' folder
  ringtest tests/sample_test.ring    # Run a specific test file
  ringtest --filter=math             # Run only tests matching 'math'
  ringtest --watch                   # Watch mode: auto re-run on changes
  ringtest --html                    # Generate 'reports/test-report.html'
  ringtest --junit                   # Generate 'reports/test-report.xml'
  ringtest --html --junit            # Generate both HTML & JUnit XML reports
  ringtest --html=custom/report.html # Generate HTML report at custom path
```

---

## License

This project is open source and available under the [MIT License](LICENSE).
