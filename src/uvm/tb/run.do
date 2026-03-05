#=============================================================================
# run.do — ModelSim Intel FPGA ASE 20.1  (no DPI — standard ASE workaround)
#=============================================================================

set UVM_HOME "C:/intelFPGA_lite/20.1/modelsim_ase/verilog_src/uvm-1.2/src"

# ---- Clean and create work library ----
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# ---- Compile UVM package (with UVM_NO_DPI) ----
echo ">> Compiling UVM 1.2 package..."
vlog -work work \
    -sv \
    +incdir+$UVM_HOME \
    +define+UVM_NO_DPI \
    $UVM_HOME/uvm_pkg.sv

# ---- Compile RTL ----
echo ">> Compiling RTL..."
vlog -work work \
    ../rtl/sha256_k_constants.v \
    ../rtl/sha256_w_mem.v \
    ../rtl/sha256_core.v

# ---- Compile UVM Testbench ----
echo ">> Compiling UVM Testbench..."
vlog -work work \
    -sv \
    +incdir+. \
    +incdir+$UVM_HOME \
    +define+UVM_NO_DPI \
    +define+UVM_NO_DEPRECATED \
    tb_top.sv

# ---- Simulate (no -sv_lib needed) ----
echo ">> Starting simulation..."
vsim -lib work \
     work.tb_top \
     +UVM_TESTNAME=sha256_test \
     +UVM_VERBOSITY=UVM_MEDIUM \
     -voptargs=+acc \
     -do "log -r /*; run -all; quit -f;"