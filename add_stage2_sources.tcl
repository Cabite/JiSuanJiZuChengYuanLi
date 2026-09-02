# Add stage-1 and stage-2 sources to the currently open Lab1 project.
# In Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/add_stage2_sources.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage1_sources.tcl"]

set stage2_rtl_files [list \
    [file join $lab1_dir "rtl" "control_unit.v"] \
    [file join $lab1_dir "rtl" "imem.v"] \
    [file join $lab1_dir "rtl" "dmem.v"]]

set stage2_tb_files [list \
    [file join $lab1_dir "tb" "control_unit_tb.v"] \
    [file join $lab1_dir "tb" "memory_tb.v"] \
    [file join $lab1_dir "tb" "single_instruction_demo_tb.v"]]

set memory_file [file join $lab1_dir "programs" "stage2_imem_test.hex"]
set demo_memory_file [file join $lab1_dir "programs" "single_instruction_demo.hex"]

add_files -norecurse -fileset sources_1 $stage2_rtl_files
add_files -norecurse -fileset sources_1 $memory_file
add_files -norecurse -fileset sources_1 $demo_memory_file
add_files -norecurse -fileset sim_1 $stage2_tb_files

set_property file_type {Memory File} [get_files -of_objects [get_filesets sources_1] "*stage2_imem_test.hex"]
set_property file_type {Memory File} [get_files -of_objects [get_filesets sources_1] "*single_instruction_demo.hex"]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Added stage-2 RTL files:"
foreach f $stage2_rtl_files { puts "  $f" }
puts "Added stage-2 testbenches:"
foreach f $stage2_tb_files { puts "  $f" }
puts "Added instruction-memory test data:"
puts "  $memory_file"
puts "  $demo_memory_file"
