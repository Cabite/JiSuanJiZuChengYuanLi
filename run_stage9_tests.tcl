# Run stage-9 regressions; stage 8 dynamic prediction remains skipped.
# From Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/run_stage9_tests.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage9_sources.tcl"]

set test_tops [list \
    alu_tb \
    control_unit_tb \
    pipeline_reg_tb \
    forwarding_unit_tb \
    hazard_unit_tb \
    branch_unit_tb \
    branch_predictor_static_tb \
    overflow_status_tb \
    performance_counter_tb \
    cpu_core_tb \
    cpu_forwarding_tb \
    cpu_hazard_tb \
    cpu_control_flow_tb \
    cpu_overflow_performance_tb \
    cpu_mem_wait_performance_tb]

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
puts "Stage-9 regression completed (dynamic stage 8 skipped)."
puts "Expected new markers: OVERFLOW_STATUS_TB_PASS,"
puts "PERFORMANCE_COUNTER_TB_PASS, CPU_OVERFLOW_PERFORMANCE_TB_PASS"
puts "and CPU_MEM_WAIT_PERFORMANCE_TB_PASS."
puts "============================================================"
