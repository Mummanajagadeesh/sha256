# run_tests.tcl
# Automated Icarus Verilog simulation for SHA256 Core (split TBs, logs folder)

# Create logs folder if it doesn't exist
if {![file exists "logs"]} {
    file mkdir "logs"
}

set test_list {
    tb_sha256_single
    tb_sha256_multi
    tb_sha256_random
    tb_sha256_corner
    tb_sha256_mode
}

# Open combined log
set combined_log [open "logs/combined_log.txt" w]

set total_failures 0

foreach test $test_list {
    set log "logs/${test}_log.txt"
    puts "Running $test ..."

    # Compile RTL + TB
    set compile_cmd "iverilog -o ${test}.out src/rtl/sha256_core.v src/rtl/sha256_k_constants.v src/rtl/sha256_w_mem.v src/tb/my_tbs/${test}.v"
    set run_cmd "vvp ${test}.out > $log"

    if {[catch {exec sh -c $compile_cmd} err]} {
        puts "❌ Compile failed: $err"
        puts $combined_log "❌ $test compile failed: $err"
        incr total_failures
        continue
    }

    if {[catch {exec sh -c $run_cmd} err]} {
        puts "❌ Simulation failed: $err"
        puts $combined_log "❌ $test simulation failed: $err"
        incr total_failures
        continue
    }

    # Append log to combined log
    set fh [open $log r]
    set contents [read $fh]
    close $fh
    puts $combined_log "\n===== $test LOG =====\n$contents\n"

    # Check for FAIL
    if {[string match *FAIL* $contents]} {
        puts "$test ... ❌ FAIL (see $log)"
        incr total_failures
    } else {
        puts "$test ... ✅ PASS"
    }
}

# Summary
puts $combined_log "\n===== SUMMARY ====="
puts $combined_log "Total tests: [llength $test_list]"
puts $combined_log "Total failures: $total_failures"

puts "\n===== FINAL SUMMARY ====="
puts "Total tests run: [llength $test_list]"
puts "Total failures: $total_failures"

if {$total_failures == 0} {
    puts "RESULT: ALL TESTS PASSED ✅"
} else {
    puts "RESULT: SOME TESTS FAILED ❌"
}

close $combined_log
