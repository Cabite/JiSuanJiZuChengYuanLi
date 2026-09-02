# Run the stage-2 self-checking testbenches with Vivado Simulator.
# From Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/run_stage2_tests.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage2_sources.tcl"]

set test_tops [list control_unit_tb memory_tb single_instruction_demo_tb]

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
puts "Stage-2 testbenches completed."
puts "Expected markers: CONTROL_UNIT_TB_PASS, MEMORY_TB_PASS and"
puts "SINGLE_INSTRUCTION_DEMO_PASS."
puts "============================================================"
