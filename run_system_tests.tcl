set lab1_dir [file normalize [file dirname [info script]]]
source [file join $lab1_dir add_system_sources.tcl]
launch_simulation -simset sim_1 -mode behavioral
run all
puts "Inspect simulation result for CPU_SYSTEM_TB_PASS (two benchmark runs)."
# Leave the completed simulation open so its waveforms can be inspected.
