# Add stage-1, stage-2 and stage-3 sources to the currently open Lab1 project.
# In Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/add_stage3_sources.tcl

set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir "add_stage2_sources.tcl"]

set stage3_rtl_files [list \
    [file join $lab1_dir "rtl" "if_id_reg.v"] \
    [file join $lab1_dir "rtl" "id_ex_reg.v"] \
    [file join $lab1_dir "rtl" "ex_mem_reg.v"] \
    [file join $lab1_dir "rtl" "mem_wb_reg.v"]]

set stage3_tb_files [list \
    [file join $lab1_dir "tb" "pipeline_reg_tb.v"]]

add_files -norecurse -fileset sources_1 $stage3_rtl_files
add_files -norecurse -fileset sim_1 $stage3_tb_files

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Added stage-3 RTL files:"
foreach f $stage3_rtl_files { puts "  $f" }
puts "Added stage-3 testbench:"
foreach f $stage3_tb_files { puts "  $f" }
