## Objective

To functionally verify the `secworks/sha256` open-source core using a directed, random, and corner-case testbench that validates core functionality, control interface behavior, and output correctness for representative message inputs.

---

## Verification Environment

| Component      | Description                                                                    |
| -------------- | ------------------------------------------------------------------------------ |
| **DUT**        | `sha256_core.v`, `sha256_k_constants.v`, `sha256_w_mem.v` from secworks/sha256 |
| **Testbench**  | Self-checking Verilog TB `my_tb_sha256_core.v`                                 |
| **Automation** | `run_tests.tcl` automates compile, run, and pass/fail log scanning             |
| **Simulator**  | Icarus Verilog (`iverilog`, `vvp`)                                             |

---

## Testbench Features

* Fully self-checking (prints formatted verification table).
* Directed, random, and corner-case tests.
* Supports both `mode = 1` and `mode = 0`.
* Checks for `digest_valid`, compares against expected digest, and reports **PASS/FAIL**.
* Produces structured table and summary with total tests, failures, and runtime.

---

## Test Cases Executed

| ID | Name            | Type   | Description                       | Expected Behavior / Purpose                       |
| -- | --------------- | ------ | --------------------------------- | ------------------------------------------------- |
| 1  | **abc**         | Single | Standard SHA-256 vector for “abc” | Validates core against canonical test vector      |
| 2  | **empty**       | Single | Empty message block               | Verifies padding and digest for zero-length input |
| 3  | **hello+msg2**  | Multi  | Two-block chained message         | Validates multi-block chaining and `next` control |
| 4  | **random_1**    | Random | Random input                      | Ensures digest_valid and data stability           |
| 5  | **random_2**    | Random | Random input                      | Ensures digest_valid and data stability           |
| 6  | **random_3**    | Random | Random input                      | Ensures digest_valid and data stability           |
| 7  | **zero**        | Corner | All-zero 512-bit block            | Checks core operation with zero data              |
| 8  | **all_ones**    | Corner | All-ones 512-bit block            | Checks core operation with all-1 input            |
| 9  | **alternating** | Corner | Alternating pattern (1010...)     | Checks pattern sensitivity / stability            |
| 10 | **abc_mode0**   | Single | “abc” vector in mode = 0          | Verifies alternate-mode digest computation        |

---

## Functionalities Verified

| # | Functionality                                     | Description                         | Coverage Source |
| - | ------------------------------------------------- | ----------------------------------- | --------------- |
| 1 | **Single-block message hashing**                  | Correct digest for standard vectors | Tests 1 & 2     |
| 2 | **Empty-message handling**                        | Proper padding and expected digest  | Test 2          |
| 3 | **Multi-block chaining (`next`)**                 | Correct intermediate state handling | Test 3          |
| 4 | **Random-input robustness**                       | Valid digest, no unknown bits       | Tests 4-6       |
| 5 | **Corner-case: all-zero input**                   | Edge data pattern                   | Test 7          |
| 6 | **Corner-case: all-ones input**                   | Edge data pattern                   | Test 8          |
| 7 | **Corner-case: alternating pattern**              | Patterned input integrity           | Test 9          |
| 8 | **Mode control (mode 0 vs 1)**                    | Alternate mode digest path          | Test 10         |
| 9 | **Interface handshake (`ready`, `digest_valid`)** | Proper sequencing and data validity | All tests       |

**Total functionalities verified:** 9 (within required 5–10 range).
**Total test cases executed:** 10.

---

## Execution and Results

**Command:**

```bash
tclsh run_tests.tcl
```

**Output Summary (from sample run):**

```
Total tests: 10
Total failures: 0
RESULT: ALL TESTS PASSED
```

Each test row includes ID, name, type, truncated expected/actual digest, valid flag, result, simulation time, and duration.

---

## Deliverables

| File                         | Purpose                   |
| ---------------------------- | ------------------------- |
| `src/tb/my_tb_sha256_core.v` | Main testbench            |
| `run_tests.tcl`              | Compile/run automation    |
| `my_tb_sha256_core_log.txt`  | Example simulation log    |
| `README.md`                  | Documentation (this file) |

---

## Conclusion

The provided testbench successfully validates the **secworks/sha256** core across directed, random, and corner-case scenarios.
All ten tests passed with no functional mismatches, demonstrating correct digest generation, control-signal timing, and mode handling.
