# SHA256 Core Functional Verification

## Objective

To **functionally verify** the `secworks/sha256` open-source SHA-256 core through a comprehensive suite of **directed**, **random**, **corner-case**, and **intentional fail-case** testbenches.
The goal is to validate correct functional behavior, interface timing, and error detection capability across all operational scenarios.

---

## Project Structure

```
sha256/
├─ src/
│  ├─ rtl/
│  │  ├─ sha256.v
│  │  ├─ sha256_core.v
│  │  ├─ sha256_k_constants.v
│  │  └─ sha256_w_mem.v
│  └─ tb/
│     ├─ my_tb_sha256_core.v         # Monolithic testbench
│     ├─ tb_sha256.v
│     ├─ tb_sha256_core.v
│     ├─ tb_sha256_w_mem.v
│     └─ my_tbs/                     # Modular verification suite
│        ├─ tb_sha256_single.v
│        ├─ tb_sha256_multi.v
│        ├─ tb_sha256_random.v
│        ├─ tb_sha256_corner.v
│        ├─ tb_sha256_mode.v
│        ├─ tb_sha256_failcase.v     # Intentional fail-case scenarios
├─ logs/                             # Simulation logs
├─ run_tests.tcl                     # TCL automation script
└─ README.md
```

---

## Verification Environment

| Component      | Description                                                                      |
| -------------- | -------------------------------------------------------------------------------- |
| **DUT**        | `sha256_core.v`, `sha256_k_constants.v`, `sha256_w_mem.v` from `secworks/sha256` |
| **Testbench**  | Self-checking Verilog TBs — either monolithic or split into modular variants     |
| **Automation** | `run_tests.tcl` automates compile, run, and log consolidation                    |
| **Simulator**  | Icarus Verilog (`iverilog`, `vvp`)                                               |

---

## Testbench Features

* Fully **self-checking** testbenches with structured verification output.
* Unified display format: tables with test ID, name, type, expected vs actual digest.
* Supports all functional modes (`mode=0` and `mode=1`).
* Includes **random**, **corner**, **multi-block**, and **fail-case** stress testing.
* Validates both functional correctness and control interface handshake (`ready`, `digest_valid`).
* Generates individual logs and an aggregated summary in `logs/combined_log.txt`.

---

## Test Cases Executed

| ID | Name                 | Type     | Description                             | Expected Behavior / Purpose                       |
| -- | -------------------- | -------- | --------------------------------------- | ------------------------------------------------- |
| 1  | **abc**              | Single   | Standard SHA-256 vector for “abc”       | Verifies canonical digest correctness             |
| 2  | **empty**            | Single   | Empty message block                     | Checks padding and digest for zero-length input   |
| 3  | **hello+msg2**       | Multi    | Two-block chained message               | Validates multi-block chaining (`next` control)   |
| 4  | **random_1**         | Random   | Random 512-bit input                    | Ensures digest_valid asserts and digest is stable |
| 5  | **random_2**         | Random   | Random 512-bit input                    | Ensures digest_valid asserts and digest is stable |
| 6  | **random_3**         | Random   | Random 512-bit input                    | Ensures digest_valid asserts and digest is stable |
| 7  | **zero**             | Corner   | All-zero 512-bit block                  | Edge case for zero data                           |
| 8  | **all_ones**         | Corner   | All-ones 512-bit block                  | Edge case for all-one input                       |
| 9  | **alternating**      | Corner   | Alternating pattern (1010...)           | Pattern sensitivity test                          |
| 10 | **abc_mode0**        | Mode 0   | “abc” vector in `mode=0` configuration  | Checks alternate hash path                        |
| 11 | **abc_wrong_exp**    | Failcase | Known vector with wrong expected digest | Forces intentional mismatch                       |
| 12 | **zero_block_wrong** | Failcase | Zero input with wrong expected digest   | Validates mismatch detection                      |
| 13 | **x_block**          | Failcase | Uninitialized (‘X’) input               | Tests robustness to undefined values              |
| 14 | **bad_protocol**     | Failcase | Asserts `next` before `ready`           | Checks control violation handling                 |
| 15 | **multi_reversed**   | Failcase | Reversed / invalid chaining order       | Confirms invalid sequence detection               |

---

## Functionalities Verified

| # | Functionality                           | Description                                   | Coverage Source      |
| - | --------------------------------------- | --------------------------------------------- | -------------------- |
| 1 | **Single-block message hashing**        | Correct digest for standard test vectors      | `tb_sha256_single`   |
| 2 | **Empty-message handling**              | Padding and digest for zero-length inputs     | `tb_sha256_single`   |
| 3 | **Multi-block chaining (`next`)**       | Correct intermediate state operation          | `tb_sha256_multi`    |
| 4 | **Random input robustness**             | Handles arbitrary 512-bit inputs              | `tb_sha256_random`   |
| 5 | **Corner data patterns**                | All-zero, all-one, alternating input handling | `tb_sha256_corner`   |
| 6 | **Mode control (`mode=0` vs `mode=1`)** | Alternate path operation                      | `tb_sha256_mode`     |
| 7 | **Interface handshake validation**      | Proper `ready` / `digest_valid` protocol      | All testbenches      |
| 8 | **Error detection / mismatch capture**  | Intentional digest mismatches & bad sequences | `tb_sha256_failcase` |

**Total functionalities verified:** 8
**Total test cases executed:** 15

---

## Failcase Scenarios (`tb_sha256_failcase.v`)

| Case Name          | Failure Type                   | Expected Outcome             |
| ------------------ | ------------------------------ | ---------------------------- |
| `abc_wrong_exp`    | Wrong expected digest          | FAIL detected correctly      |
| `zero_block_wrong` | Wrong expected digest          | FAIL detected correctly      |
| `x_block`          | Uninitialized block            | FAIL due to undefined digest |
| `bad_protocol`     | `next` asserted before `ready` | FAIL or invalid digest_valid |
| `multi_reversed`   | Invalid block order            | FAIL detected correctly      |

**Purpose:** Ensures the testbench correctly detects digest mismatches, X-propagation, and protocol violations — validating the reliability of the verification environment itself.

---

## Logs & Automation

* Individual testbench logs: stored in `logs/`.
* Combined results: `logs/combined_log.txt`.
* Run all tests automatically:

```bash
tclsh run_tests.tcl
```

**Example summary output:**

```
===== SUMMARY =====
Total tests: 6
Total failures: 1

RESULT: FAIL (as expected for failcase)
```

---

## Deliverables

| File                         | Purpose                                                             |
| ---------------------------- | ------------------------------------------------------------------- |
| `src/tb/my_tb_sha256_core.v` | Monolithic testbench                                                |
| `src/tb/my_tbs/*.v`          | Modular testbenches (single, multi, random, corner, mode, failcase) |
| `run_tests.tcl`              | TCL automation script                                               |
| `logs/`                      | Simulation output and summary logs                                  |
| `README.md`                  | This documentation                                                  |

---

## Conclusion

This verification environment thoroughly validates the **secworks/sha256** core across **functional**, **random**, **corner**, and **negative (failcase)** scenarios.
The suite ensures that the core behaves correctly under nominal conditions and that the testbench infrastructure properly identifies **protocol or digest mismatches** when they occur.
