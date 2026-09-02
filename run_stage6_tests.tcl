# Run stage-6 regressions with Vivado Simulator.
# From Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/run_stage6_tests.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage6_sources.tcl"]

set test_tops [list \
    control_unit_tb \
    pipeline_reg_tb \
    forwarding_unit_tb \
    hazard_unit_tb \
    cpu_core_tb \
    cpu_forwarding_tb \
    cpu_hazard_tb]

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
puts "Stage-6 regression completed."
puts "Expected new markers: HAZARD_UNIT_TB_PASS and CPU_HAZARD_TB_PASS."
puts "All earlier stage markers must also pass."
puts "============================================================"
