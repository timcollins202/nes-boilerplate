;*****************************************************************
; A Boilerplate Template for NES Applications
;*****************************************************************

;*****************************************************************
; Define NES cartridge header
;*****************************************************************
.segment "HEADER"
INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 0 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID 
.byte $02 ; 16k PRG bank count
.byte $01 ; 8k CHR bank count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding


;*****************************************************************
; Include CHR files
;*****************************************************************
.segment "TILES"
.incbin "title-bg.chr"
.incbin "title-sp.chr"


;*****************************************************************
; Define vectors
;*****************************************************************
.segment "VECTORS"
.word nmi
.word reset
.word irq

;*****************************************************************
; Reserve memory for variables
;*****************************************************************
.segment "ZEROPAGE"
    time:               .res 2  ;time tick counter
    lasttime:           .res 1  ;what time was last time it was checked
    ;put all them variables here

.segment "OAM"
oam: .res 256           ;OAM sprite data

.segment "BSS"
palette: .res 32        ;current palette buffer


;*****************************************************************
; Include external files
;*****************************************************************
.include "neslib.asm"         ;General Purpose NES Library
;.include "constants.inc"      ;Game-specific constants


;*****************************************************************
; RESET - Main application entry point for starup/reset
;*****************************************************************
.segment "CODE"
.proc reset 
    SEI                 ;mask interrupts
    LDA #0
    STA PPU_CONTROL     ;disable NMI
    STA PPU_MASK        ;disable rendering
    STA APU_DM_CONTROL  ;disable DMC IRQ
    LDA #40
    STA JOYPAD2         ;disable APU frame IRQ

    CLD                 ;disable decimal mode
    LDX #$ff
    TXS                 ;initialize stack

    ;wait for first vblank
    BIT PPU_STATUS
wait_vblank:
    BIT PPU_STATUS
    BPL wait_vblank

    ;clear all RAM to 0
    LDA #0
    LDX #0
clear_ram:              ;set all work RAM to 0
    STA $0000, x
    STA $0100, x
    STA $0200, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0600, x
    STA $0700, x
    INX
    BNE clear_ram

    ;place sprites offscreen at Y=255
    LDA #255
    LDX #0
clear_oam:
    STA oam, x 
    INX
    INX
    INX
    INX
    BNE clear_oam

wait_vblank2:
    BIT PPU_STATUS
    BPL wait_vblank2

    ; NES is initialized and ready to begin
	; - enable the NMI for graphical updates and jump to our main program
    LDA #%10001000
    STA PPU_CONTROL
    JMP main
.endproc


;*****************************************************************
; NMI - called every vBlank
;*****************************************************************
.segment "CODE"
.proc nmi
    ;save registers
    PHA
    TXA
    PHA
    TYA
    PHA

    ;do stuff here

    ;restore registers and return
    PLA
    TAY
    PLA
    TAX
    PLA

    RTI
.endproc


;*****************************************************************
; IRQ - Clock Interrupt Routine     (not used)
;*****************************************************************
.segment "CODE"
irq:
	RTI


;*****************************************************************
; MAIN - Main application logic section. Includes the game loop.
;*****************************************************************
.segment "CODE"
.proc main
    ;rendering is currently off

    ;initialize palette table
    LDX #0
paletteloop:
    LDA default_palette, x 
    STA palette, x 
    INX
    CPX #32
    BCC paletteloop

mainloop:
    LDA time
    CMP lasttime        ;make sure time has actually changed
    BEQ mainloop
    STA lasttime        ;time has changed, so update lasttime

    ;loop calls go here
    JSR player_actions

    JMP mainloop
.endproc

;*****************************************************************
; RODATA - Read-only Data
;*****************************************************************
.segment "RODATA"
default_palette:
    ;background
    .byte $0f,$00,$10,$30   
    .byte $0f,$11,$21,$32
    .byte $0f,$05,$16,$27
    .byte $0f,$0b,$1a,$29

    ;sprites
    .byte $0F,$05,$15,$17   
    .byte $0F,$14,$24,$34
    .byte $0F,$1B,$2B,$3B
    .byte $0F,$12,$22,$32
