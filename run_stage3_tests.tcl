# Run the stage-3 self-checking testbench with Vivado Simulator.
# From Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/run_stage3_tests.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage3_sources.tcl"]

set_property top pipeline_reg_tb [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim

puts "============================================================"
puts "Stage-3 testbench completed."
puts "Expected marker: PIPELINE_REG_TB_PASS"
puts "============================================================"
