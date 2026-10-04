# ringtest

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ring Version](https://img.shields.io/badge/Ring-1.21%2B-blue.svg)](https://ring-lang.github.io)
[![Version](https://img.shields.io/badge/version-1.0.4-green.svg)](https://github.com/Azzeddine2017/ringtest)

**ringtest** is a modern, ultra-fast, and lightweight unit testing framework and test runner for the [Ring programming language](https://ring-lang.github.io).

It brings familiar BDD/TDD-style assertions (`describe`, `it`, `test`, `expect`), comprehensive lifecycle hooks, rich diagnostic error tips, and automated test discovery with colorful terminal reports, interactive HTML dashboards, and JUnit XML outputs to the Ring ecosystem.

---

## Features

- ⚡ **Ultra Fast**: Zero-overhead test runner executing suites in milliseconds.
- 🎨 **Beautiful ANSI Reporter**: Instant colored feedback (`✓ PASS`, `✗ FAIL`, timings, and clean diffs).
- 🔍 **Automatic Discovery**: Automatically scans and runs all `*_test.ring` and `test_*.ring` files in `./tests`.
- 📊 **Interactive HTML Dashboard**: Generate self-contained dark-mode HTML reports with `--html`.
- 📋 **CI/CD JUnit XML**: Standard JUnit XML reports (`--junit` / `--xml`) for GitHub Actions, GitLab CI, and Jenkins.
- 🔄 **Complete Lifecycle Hooks**: Suite-level & Global `beforeAll`, `beforeEach`, `afterEach`, and `afterAll`.
- 💡 **Smart Diagnostics**: Built-in Ring runtime error analysis (R19, R24, R26...) with actionable fix tips.
- 🛡️ **Subprocess Isolation**: Isolated execution so failing tests or crashes don't break the entire test run.
- 🔎 **Test Filtering**: Filter tests by description with `--filter=<text>`.
- 👀 **Watch Mode**: Re-run tests automatically on file changes with `--watch`.
- 📊 **JSON Output**: Machine-readable output for CI/CD integration with `--json`.
- 🎭 **Mocking**: Built-in mock registry and call recorder for isolating tests.
- 📦 **Zero External Dependencies**: Pure native Ring implementation.

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
Create `tests/math_test.ring` — **no `load` line is needed**, the runner already provides `describe`, `it`, `test` and `expect` to every discovered test file:

```ring
describe("Math Operations", func {

    it("should add numbers correctly", func {
        expect(10 + 20).toBe(30)
    })

    test("should compare numerical bounds", func {
        expect(100).toBeGreaterThan(50)
        expect(25).toBeLessThan(50)
    })

    it("should catch runtime exceptions", func {
        expect("1 / 0").toThrow()
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

## Mocking

```ring
oMock = mock("targetFunction", NULL)   # register mock
oMock.doCall()                          # record a call
oMock.getCallCount()                    # -> 1
oMock.wasCalled()                       # -> true
getMock("targetFunction")               # -> get the Mock object
restore("targetFunction")               # remove one mock
restoreAll()                            # remove all mocks
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
