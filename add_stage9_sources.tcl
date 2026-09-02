# Add stage-1 through stage-7 and stage-9 sources (stage 8 intentionally skipped).
# In Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/add_stage9_sources.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage7_sources.tcl"]

set stage9_rtl_files [list \
    [file join $lab1_dir "rtl" "overflow_status.v"] \
    [file join $lab1_dir "rtl" "performance_counter.v"]]

set stage9_tb_files [list \
    [file join $lab1_dir "tb" "overflow_status_tb.v"] \
    [file join $lab1_dir "tb" "performance_counter_tb.v"] \
    [file join $lab1_dir "tb" "cpu_overflow_performance_tb.v"] \
    [file join $lab1_dir "tb" "cpu_mem_wait_performance_tb.v"]]

set stage9_memory_files [list \
    [file join $lab1_dir "programs" "stage9_overflow_test.hex"] \
    [file join $lab1_dir "programs" "stage9_memwait_test.hex"]]

add_files -norecurse -fileset sources_1 $stage9_rtl_files
add_files -norecurse -fileset sources_1 $stage9_memory_files
add_files -norecurse -fileset sim_1 $stage9_tb_files

foreach memory_file $stage9_memory_files {
    set_property file_type {Memory File} [get_files $memory_file]
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Added stage-9 RTL files:"
foreach f $stage9_rtl_files { puts "  $f" }
puts "Added stage-9 testbenches:"
foreach f $stage9_tb_files { puts "  $f" }
puts "Added stage-9 test programs:"
foreach f $stage9_memory_files { puts "  $f" }
