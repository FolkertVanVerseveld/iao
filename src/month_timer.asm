:BasicUpstart2(initialize_month_timer)
#import "pseudo.lib"
#import "cia.inc"

.const timer_a_max_val = $ffff // 65535 ticks at 1Mhz = 65 ms
.const timer_b_val = 77 // Number of 65ms ticks (77*.065 = 5 s)

.pc = * "Month Timer Init"

initialize_month_timer:
    // Probably dead code when this is no longer standalone.
    lda #$35
    sta $1

    mov #$7f : $dc0d

    // Load the NMI handler into the NMI vector.
    lda #<nmi_handler
    sta $fffa
    lda #>nmi_handler
    sta $fffb

    lda #<dummy
    sta $fffc
    sta $fffe
    lda #>dummy
    sta $fffd
    sta $ffff

    mov16 #timer_a_max_val : timer_a_val_register
    mov16 #timer_b_val     : timer_b_val_register

    // Enable Timer B interrupt
    mov16 #%10000010 : cia_nmi_service_register

    // Bit 4 (load start value), 3 (restart upon underflow),
    // Bit 0 (start timer)
    mov16 #%00010001 : timer_a_control


    // Timer counts timer A underflows (6, 5), load start value (4),
    // start timer (0).
    mov16 #%01010001 : timer_b_control

    // Acknowledge any CIA 2 NMI interrupts.
    lda cia_nmi_service_register


loop:
    jmp loop

dummy:
    rti

.pc = * "Month timer handler"

nmi_handler:
    cia_nmi

    

    imn_aic
