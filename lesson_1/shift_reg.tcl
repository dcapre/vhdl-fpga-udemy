transcript off                             ;# Turns off commands echoing on transcript
vcom shift_reg.vhd                         ;# Compiles VHDL file
vcom test_shift_reg.vhd

vsim test_shift_reg -voptargs=+acc         ;# Run simulation, Note: For ModelSim SE-64 2020.4 use "-voptargs=+acc" to run un full debug mode, 
                                           ;# this will allow the tcl script to load properly.
# Add signals to wave window
add wave sim:/test_shift_reg/dev_to_test/* ;# Add all DUT signals to waveform window
  
run 350 ns                                 ;# Run sim for 350 nanoseconds