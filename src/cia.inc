#importonce

// All constants defined here are for the CIA 2 chip, which interfaces with
// the CPUs NMI line.
.const timer_a_control = $dd0e
.const timer_b_control = $dd0f

.const timer_a_val_register = $dd04
.const timer_b_val_register = $dd06

.const cia_nmi_service_register = $dd0d
.const cia_timer_register = $dd0d



