# LFSR-Based Arbiter Verification

This project explores verification of a 4-requestor LFSR-based arbiter with intentional unfairness. It demonstrates both simulation-based **Property Strengthening** and **formal BMC** using SymbiYosys.

---

## 1. Overview

* **LFSR Arbiter**: Random priority is assigned using an 8-bit maximal-length LFSR (`x^8 + x^6 + x^5 + x^4 + 1`). Req[0] is intentionally disadvantaged for testing.
* **Property Strengthening**: Simulation-based binary search for “bad seeds” that violate bounded starvation (`K = 50`).
* **Bounded Model Checking (BMC)**: Formal verification using `anyconst` (all possible seeds) and `anyseq` (all request sequences).

---

## 2. Files

| File                    | Description                                                            |
| ----------------------- | ---------------------------------------------------------------------- |
| `lfsr_8bit.sv`          | 8-bit maximal-length LFSR module                                       |
| `random_arbiter.sv`     | Arbiter module with LFSR-based priority                                |
| `arbiter_properties.sv` | Property observer (checks bounded starvation)                          |
| `property_test.sv`      | Simulation testbench for selected seeds                                |
| `algorithm_test.sv`     | Simulation testbench implementing Property Strengthening (Algorithm 1) |
| `arbiter_formal.sv`     | Formal verification harness with assertions                            |
| `arbiter_bmc.sby`       | SymbiYosys script for BMC                                              |

---

## 3. Running Simulation

### 3.1 Manual Simulation (`property_test`)

Tests specific seeds and prints when `req[0]` is granted.

```bash
vcs -sverilog -nc lfsr_8bit.sv random_arbiter.sv arbiter_properties.sv properties_test.sv -o simv_property_test
./simv_property_test
```

* Outputs grant times for seeds: `0x01`, `0x42`, `0xAA`, `0xFF`.

---

### 3.2 Property Strengthening (`algorithm_test`)

Runs Algorithm 1-style binary search to find seeds that violate `K = 50` bound.

```bash
vcs -sverilog -nc lfsr_8bit.sv random_arbiter.sv algorithm_test.sv -o simv_algorithm_test
./simv_algorithm_test
```

* Prints iterations, which seeds pass/fail, and identifies problematic seeds efficiently.

---

## 4. Formal Verification (BMC)

Symbolically checks all 255 seeds and arbitrary request sequences using SymbiYosys + Boolector.

```bash
sby -f arbiter_bmc.sby
```

* Produces counterexamples if the bounded starvation property is violated:

  * `engine_0/trace.vcd` → waveform
  * `engine_0/trace_tb.v` → Verilog testbench
  * `engine_0/trace.smtc` → SMT trace
  * `engine_0/trace.yw` → Yosys witness

---

