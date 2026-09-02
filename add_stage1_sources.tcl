# Add all stage-1 RTL and simulation sources to the currently open Lab1 project.
# In Vivado Tcl Console, run:
#   source D:/Projects/Courses/jizushiyan/xiaoxueqi/Lab1/add_stage1_sources.tcl

set lab1_dir [file normalize [file dirname [info script]]]
set project_file [file join $lab1_dir "Lab1.xpr"]

if {[llength [get_projects -quiet]] == 0} {
    open_project $project_file
}

set rtl_files [list \
    [file join $lab1_dir "rtl" "cpu_defs.vh"] \
    [file join $lab1_dir "rtl" "mux2.v"] \
    [file join $lab1_dir "rtl" "mux3.v"] \
    [file join $lab1_dir "rtl" "pc_reg.v"] \
    [file join $lab1_dir "rtl" "imm_extend.v"] \
    [file join $lab1_dir "rtl" "alu.v"] \
    [file join $lab1_dir "rtl" "regfile.v"]]

set tb_files [list \
    [file join $lab1_dir "tb" "mux_tb.v"] \
    [file join $lab1_dir "tb" "pc_reg_tb.v"] \
    [file join $lab1_dir "tb" "imm_extend_tb.v"] \
    [file join $lab1_dir "tb" "alu_tb.v"] \
    [file join $lab1_dir "tb" "regfile_tb.v"]]

add_files -norecurse -fileset sources_1 $rtl_files
add_files -norecurse -fileset sim_1 $tb_files

set_property file_type {Verilog Header} [get_files -of_objects [get_filesets sources_1] "*cpu_defs.vh"]
set_property include_dirs [list [file join $lab1_dir "rtl"]] [get_filesets sources_1]
set_property include_dirs [list [file join $lab1_dir "rtl"]] [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Added stage-1 RTL files:"
foreach f $rtl_files { puts "  $f" }
puts "Added stage-1 testbenches:"
foreach f $tb_files { puts "  $f" }
puts "Set one testbench as sim_1 top before running simulation."

