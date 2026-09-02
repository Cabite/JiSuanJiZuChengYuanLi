# Add stage-1 through stage-7 sources to the currently open Lab1 project.
# In Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/add_stage7_sources.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage6_sources.tcl"]

set stage7_rtl_files [list \
    [file join $lab1_dir "rtl" "branch_unit.v"] \
    [file join $lab1_dir "rtl" "branch_predictor.v"]]

set stage7_tb_files [list \
    [file join $lab1_dir "tb" "branch_unit_tb.v"] \
    [file join $lab1_dir "tb" "branch_predictor_static_tb.v"] \
    [file join $lab1_dir "tb" "cpu_control_flow_tb.v"]]

set stage7_memory_file \
    [file join $lab1_dir "programs" "stage7_control_test.hex"]

add_files -norecurse -fileset sources_1 $stage7_rtl_files
add_files -norecurse -fileset sources_1 $stage7_memory_file
add_files -norecurse -fileset sim_1 $stage7_tb_files

set_property file_type {Memory File} \
    [get_files -of_objects [get_filesets sources_1] "*stage7_control_test.hex"]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Added stage-7 RTL files:"
foreach f $stage7_rtl_files { puts "  $f" }
puts "Added stage-7 testbenches:"
foreach f $stage7_tb_files { puts "  $f" }
puts "Added stage-7 test program:"
puts "  $stage7_memory_file"
