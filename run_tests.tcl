# run_tests.tcl
# Automated Icarus Verilog simulation for SHA256 Core

set test_list {
    my_tb_sha256_core
}

foreach test $test_list {
    set log "${test}_log.txt"
    puts "Running $test ..."
    
    set compile_cmd "iverilog -o ${test}.out src/rtl/sha256_core.v src/rtl/sha256_k_constants.v src/rtl/sha256_w_mem.v src/tb/${test}.v"
    set run_cmd "vvp ${test}.out > $log"
    
    if {[catch {exec sh -c $compile_cmd} err]} {
        puts "❌ Compile failed: $err"
        continue
    }

    if {[catch {exec sh -c $run_cmd} err]} {
        puts "❌ Simulation failed: $err"
        continue
    }

    # Check the log for FAIL
    set fh [open $log r]
    set contents [read $fh]
    close $fh

    if {[string match *FAIL* $contents]} {
        puts "$test ... FAIL (see $log)"
    } else {
        puts "$test ... PASS"
    }
}
