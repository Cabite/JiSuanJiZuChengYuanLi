# Run all stage-1 self-checking testbenches with Vivado Simulator.
# This script assumes Lab1.xpr is compatible with the installed Vivado version.
# From Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/run_stage1_tests.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage1_sources.tcl"]

set test_tops [list \
    mux_tb \
    pc_reg_tb \
    imm_extend_tb \
    alu_tb \
    regfile_tb]

foreach test_top $test_tops {
    puts "============================================================"
    puts "Running $test_top"
    puts "============================================================"

    set_property top $test_top [get_filesets sim_1]
    update_compile_order -fileset sim_1
    launch_simulation -simset sim_1 -mode behavioral
    run all
    close_sim
}

puts "============================================================"
puts "All stage-1 testbenches completed."
puts "Expected markers: MUX_TB_PASS, PC_REG_TB_PASS,"
puts "IMM_EXTEND_TB_PASS, ALU_TB_PASS, REGFILE_TB_PASS."
puts "============================================================"

