# Add the 16-instruction static-prediction system to the existing project.
set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage9_sources.tcl"]
add_files -norecurse -fileset sources_1 [file join $lab1_dir rtl cpu_system_top.v]
add_files -norecurse -fileset sim_1 [file join $lab1_dir tb cpu_system_tb.v]
foreach name {system_test.hex system_data.hex} {
    set memory_file [file join $lab1_dir programs $name]
    add_files -norecurse -fileset sources_1 $memory_file
    set_property file_type {Memory File} [get_files $memory_file]
}
set_property top cpu_system_top [get_filesets sources_1]
set_property top cpu_system_tb [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "System sources added: 16 instructions, static prediction only."
