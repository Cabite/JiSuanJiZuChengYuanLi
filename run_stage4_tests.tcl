# Run stage-4 regressions with Vivado Simulator.
# From Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/run_stage4_tests.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage4_sources.tcl"]

set test_tops [list control_unit_tb pipeline_reg_tb cpu_core_tb]

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
puts "Stage-4 regression completed."
puts "Expected markers: CONTROL_UNIT_TB_PASS, PIPELINE_REG_TB_PASS"
puts "and CPU_CORE_TB_PASS."
puts "============================================================"
