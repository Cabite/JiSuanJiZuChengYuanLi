# Add stage-1 through stage-5 sources to the currently open Lab1 project.
# In Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/add_stage5_sources.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage4_sources.tcl"]

set stage5_rtl_files [list \
    [file join $lab1_dir "rtl" "forwarding_unit.v"]]

set stage5_tb_files [list \
    [file join $lab1_dir "tb" "forwarding_unit_tb.v"] \
    [file join $lab1_dir "tb" "cpu_forwarding_tb.v"]]

set stage5_memory_file \
    [file join $lab1_dir "programs" "stage5_forwarding_test.hex"]

add_files -norecurse -fileset sources_1 $stage5_rtl_files
add_files -norecurse -fileset sources_1 $stage5_memory_file
add_files -norecurse -fileset sim_1 $stage5_tb_files

set_property file_type {Memory File} \
    [get_files -of_objects [get_filesets sources_1] "*stage5_forwarding_test.hex"]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Added stage-5 RTL file:"
foreach f $stage5_rtl_files { puts "  $f" }
puts "Added stage-5 testbenches:"
foreach f $stage5_tb_files { puts "  $f" }
puts "Added stage-5 test program:"
puts "  $stage5_memory_file"
