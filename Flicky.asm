; ======================================================================
; Flicky Disassembly, by Dandaman955 (05/10/2015, 19:48.00 - 07/07/2016, 15:45.04)
; If you have contributed to this disassembly, leave your name below.
;
;
;
; Thanks:
; Nemesis      - Modded ASM68K.
; LazloPsylus  - Bringing up the use of the 0 add before the bcd instructions.
; MarkeyJester - AlignFF macro.
;
; NOTES
; - The entire main block of code ($10000-$1C000) is written and run from
;   RAM ($FF0000-$FFC000). This means that Regen will likely have problems
;   when debugging from any addresses there (although there are jumps to
;   subroutines earlier than $10000 that work fine, because they're run
;   from the ROM).
;
;   This also means that since they are roughly parallel addresses (I.E.
;   loc_1101E for instance, would be located at $FF101E in RAM), this
;   disassembly tries to compromise with it, by putting some addresses
;   loaded into RAM (The ones at $10000+) as dc.w's in a table, rather
;   than say hardcoded addresses (so dc.w $F63A would be instead written
;   as dc.w loc_1F63A&$FFFF). This will mostly be seen in places where the
;   moveq instruction sets a data register to -1 ($FFFFFFFF) and overwrites
;   the lower word with said address (I.E. $FFFFF63A would be loaded, and is
;   technically loaded from loc_1F63A, so it shouldn't matter too much).
;
; RAM ADDRESSES
; $FF0000-$FFBFFF - Main game code, executed in RAM.
; $FFC000-$FFC7FF - Object RAM.
; $FFC800-$FFC37F - Bonus stage object RAM.
; $FFCC00         - Top score (stored as BCD).
; $FFD24E         - Bonus stage flag.
; $FFD24F         - Level freeze flag (for depositing chicks).
; $FFD266         - Time you finished the level, in minutes.
; $FFD267         - Time you finished the level, in seconds.
; $FFD28E         - Amount of chicks collected in the special stage.
; $FFD28F         - Amount of chicks collected in the special stage, stored in BCD.
; $FFD82C         - Level number stored as decimal.
; $FFD82D         - Level number stored as hexadecimal.
; $FFD87E         - 1P score (stored as BCD).
; $FFD888-$FFD88A - In-game timer, stored as a BCD. First byte is the minute timer, second
;                 - byte is the second timer and the third byte is the centisecond timer.
;                 - The fourth byte is unused.
; $FFD88D         - Keeps track of how many times you've deposited chicks to the door.
; $FFE630         - Nemesis decompression buffer.
; $FFF7E0         - Palette buffer.
; $FFFA70-$FFFBCB - Subroutine table pointers.
;
; $FFFF70         - Stack pointer.
; $FFFF83-$FFFF8D - Button press array. See button presses below for more information.
; $FFFF8E         - Player 1's held buttons.
; $FFFF8F         - Player 1's pressed buttons.
; $FFFF90         - Player 2's held buttons (unused).
; $FFFF91         - Player 2's pressed buttons (unused).
; $FFFF96         - Mirrored VBlank routine value. Cleared during VBlank.
; $FFFF98         - VBlank routine value. Not cleared during VBlank.
; $FFFFA4         - Vertical scroll value.
; $FFFFA8         - Horizontal scroll value.
; $FFFFC0         - Game mode.
; $FFFFC8         - Z80 stop check. Only used on controllers. 1 - Stopped, 0 - Running.
; $FFFFCA         - Random number. Routine not used in Flicky, and by extension, this address.
; $FFFFFC-$FFFFFF - Checksum init flag.
;
; OBJECT SSTS
;
; 0   - Bit that is set to high if the object is loaded.
; 1   - Object.
; 2   - Bitfield. H0000RD0   H - Flip sprite horizontally. D - Disable sprite display/update. R - Set when animation is reset.
; 6   - Animation script.
; 8   - Animation script table.
; $C  - Mappings address.
; $10 - Current animation frame.
; $11 - Animation frame duration.
; $20 - Horizontal position.
; $24 - Vertical position.
; $38 - Object subtype. TODO
;
;
; BUTTON PRESSES
;
; ======================================================================

RAMBlockSize    EQU  (EndofRAMBlock-StartofRAMBlock) ; NOTE - Had to be included as an equate because it was giving build errors otherwise.

alignFF		macro
		dcb.b	\1-(*%\1),$FF
		endm

align00         macro
                cnop    0,\1
                endm



StartofROM:
Vectors:
                dc.l    $FFFF70,   EntryPoint, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, $FFFA70,   ErrorTrap
                dc.l    $FFFA76,   ErrorTrap, $FFFA7C,   ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
                dc.l    ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
Console:        dc.b    'SEGA MEGA DRIVE '      ; NOTE - A requirement of the TMSS is that the string 'SEGA' or ' SEGA' exists at the start here. This is important!
Date:           dc.b    '(C)SEGA 1991.FEB'
Domestic:       dc.b    'FLICKY                                          '
Overseas:       dc.b    '                FLICKY                          '
Serial:         dc.b    'GM 00001022-00'
Checksum:       dc.w    $B7E0
IOSupport:      dc.b    'J               '
ROMStartLoc:    dc.l    StartofROM
ROMEndLoc:      dc.l    EndofROM-1
RAMStartLoc:    dc.l    $FF0000
RAMEndLoc:      dc.l    $FFFFFF
SRAMSupport:    dc.l    $20202020
SRAMStartLoc:   dc.l    $20202020
SRAMEndLoc:     dc.l    $20202020
Modem:          dc.b    '            '
Notes:          dc.b    '                                        '
Region:         dc.b    'JUE             '
; ----------------------------------------------------------------------
; ======================================================================
; Flicky crash handler.
; ======================================================================

ErrorTrap:
                nop                              ; Do nothing.
                nop                              ; Stall again...
                bra.s   ErrorTrap                ; Loop indefinitely.

; ======================================================================
; Routine to jump to when turned on/reset.
EntryPoint:
                tst.l   ($A10008).l              ; Test Port A & B control.
                bne.s   PortA_Ok                 ; If the console was reset, branch.
                tst.w   ($A1000C).l              ; Test Port C control.
PortA_Ok:
                bne.s   PortC_Ok                 ; If the console was reset, branch.
                lea     SetupValues(pc),a5       ; Load starting address for the setup values into a5.
                movem.w (a5)+,d5-d7              ; d5 - $8000, d6 - $3FFF, d7 - $0100.
                movem.l (a5)+,a0-a4              ; a0 - $A00000, a1 - $A11100, a2 - $A11200, a3 - $C00000, a4 - $C00004
                move.b  -$10FF(a1),d0            ; Get version register.
                andi.b  #$F,d0                   ; Get hardware version.
                beq.s   SkipSecurity             ; If it's the pre-TMSS models, branch.
                move.l  #'SEGA',$2F00(a1)        ; Write the SEGA security ASCII code to the appropriate space ($A14000).
SkipSecurity:
                move.w  (a4),d0                  ; Clear the VDP write-pending flag.
                moveq   #0,d0                    ; Clear d0.
                movea.l d0,a6                    ; Set to write to the USP.
                move.l  a6,usp                   ; Set USP as 0.
                moveq   #$17,d1                  ; $18 VDP registers to initialise.
loc_23E:
                move.b  (a5)+,d5                 ; Get the first VDP register init value, add by $8000 (d5) to get VDP register.
                move.w  d5,(a4)                  ; Initialise the register.
                add.w   d7,d5                    ; Increment by $100 to load the next VDP register base increment value.
                dbf     d1,loc_23e               ; Repeat for the other $17.
                move.l  (a5)+,(a4)               ; Set VDP to VRAM DMA.
                move.w  d0,(a3)                  ; Clear a word of RAM, start DMA.
                move.w  d7,(a1)                  ; Stop the Z80.
                move.w  d7,(a2)                  ; Reset the Z80.
loc_250:
                btst    d0,(a1)                  ; Has the Z80 stopped?
                bne.s   loc_250                  ; If not, loop until it has.
                moveq   #Z80Init_End-Z80Init-1,d2 ; Load instructions length.
loc_256:
                move.b  (a5)+,(a0)+              ; Move a byte of the first instruction into Z80 RAM.
                dbf     d2,loc_256               ; Repeat until finished.
                move.w  d0,(a2)                  ; Disable Z80 reset.
                move.w  d0,(a1)                  ; Start the Z80.
                move.w  d7,(a2)                  ; Reset the Z80.
loc_262:
                move.l  d0,-(a6)                 ; Clear 4 bytes of RAM:- Work backwards.
                dbf     d6,loc_262               ; Repeat until all of the RAM is cleared.
                move.l  (a5)+,(a4)               ; Disable VBlank, DMA and display; set auto increment to $02.
                move.l  (a5)+,(a4)               ; Set VDP to CRAM write.
                moveq   #$1F,d3                  ; Set to fill all palette lines.
loc_26E:
                move.l  d0,(a3)                  ; Clear two palette entries.
                dbf     d3,loc_26e               ; Repeat for the rest of them.
                move.l  (a5)+,(a4)               ; Set VDP to VSRAM write.
                moveq   #$13,d4                  ; Set to clear $50 bytes.
loc_278:
                move.l  d0,(a3)                  ; Clear 4 bytes of VSRAM.
                dbf     d4,loc_278               ; Repeat until it is completely cleared.
                moveq   #3,d5                    ; Set to repeat 3 times.
loc_280:
                move.b  (a5)+,$11(a3)            ; Mute the PSG channels ($C00011).
                dbf     d5,loc_280               ; Repeat until completely set.
                move.w  d0,(a2)                  ; Disable Z80 reset.
                movem.l (a6),d0-a6               ; Clear other registers.
                move.w  #$2700,sr                ; Disable interrupts.
PortC_Ok:
                bra.s   loc_300                  ; Start the game!

; ======================================================================
; Address/Initialisation value table for the MD.
; ======================================================================
SetupValues:                                     ; $294

                dc.w    $8000                    ; d5 - Used for the VDP address register settings.
                dc.w    $3FFF                    ; d6 - Used to clear all 64kb of RAM.
                dc.w    $0100                    ; d7 - Used for setting the appropriate VDP register (increments).

                dc.l    $A00000                  ; a0 - Start of Z80 RAM.
                dc.l    $A11100                  ; a1 - Z80 bus request.
                dc.l    $A11200                  ; a2 - Z80 reset.
                dc.l    $C00000                  ; a3 - VDP data port.
                dc.l    $C00004                  ; a4 - VDP control port.

; ----------------------------------------------------------------------
VDPInitRegisters:
                dc.b    $04, $14, $30, $3C
                dc.b    $07, $6C, $00, $00
                dc.b    $00, $00, $FF, $00
                dc.b    $81, $37, $00, $01
                dc.b    $01, $00, $00, $FF
                dc.b    $FF, $00, $00, $80

                dc.l    $40000080                ; Start of VRAM, DMA.

Z80Init:
                dc.b    $AF, $01, $D9, $1F       ; Z80 init instructions.
                dc.b    $11, $27, $00, $21
                dc.b    $26, $00, $F9, $77
		dc.b    $ED, $B0, $DD, $E1
                dc.b    $FD, $E1, $ED, $47
                dc.b    $ED, $4F, $D1, $E1
                dc.b    $F1, $08, $D9, $C1
                dc.b    $D1, $E1, $F1, $F9
                dc.b    $F3, $ED, $56, $36
                dc.b    $E9, $E9
Z80Init_End:

                dc.w    $8104                    ; Disable display, DMA and VBlank.
                dc.w    $8F02                    ; Sets VDP auto increment to $02.

                dc.l    $C0000000                ; CRAM write address.
                dc.l    $40000010                ; VSRAM write address.

                dc.b    $9F, $BF, $DF, $FF       ; Mutes the PSG channels.

; ======================================================================

loc_300:
                tst.w   ($C00004).l              ; Clear the VDP write-pending flag.
                move.w  #$2700,sr                ; Disable interrupts.
                move.b  ($A10001).l,d0           ; Move version register value into d0.
                andi.b  #$F,d0                   ; Get hardware version.
                beq.s   loc_320                  ; If it's a pre-TMSS model, branch.
                move.l  #'SEGA',($A14000).l      ; Satisfy the TMSS.
loc_320:
                movea.l #ROMEndLoc,a0            ; Get the header entry that denotes the ending address of this ROM.
                move.l  (a0),d1                  ; Move the ending address of this ROM to d1.
                addq.l  #1,d1                    ; Add 1 to process the extra 1 (dbf ends on -1).
                movea.l #ErrorTrap,a0            ; Start checking the bytes from ErrorTrap, onwards.
                sub.l   a0,d1                    ; Get size of ROM to check.
                asr.l   #1,d1                    ; Divide by 2.
                move.w  d1,d2                    ; Copy to d2.
                subq.w  #1,d2                    ; Subtract 1 for the dbf loop (code is ran once before the loop).
                swap    d1                       ; Swap register halves (dbf loops can only be a word in size, so this is an artificial dbf longword implementation).
                moveq   #0,d0                    ; Clear d0.
loc_33c:
                add.w   (a0)+,d0                 ; Start adding the opcode's bytes together, into d0.
                dbf     d2,loc_33c               ; Repeat for the ROM's end address (lower word).
                dbf     d1,loc_33c               ; Repeat for the ROM's end address (higher word).
                cmp.w   Checksum,d0              ; Does it match the checksum's header value?
                beq.s   loc_350                  ; If it does, carry on with the game.
                bra.w   loc_3e4                  ; Otherwise, trap in an endless loop.
loc_350:
                btst    #6,($A1000D).l           ; TODO
                bne.s   loc_3aa                  ; If it has, branch.
                move.w  #$2700,sr                ; Disable interrupts.
                lea     ($A10003).l,a0           ; Load the first data port into a0.
                bsr.w   loc_43a                  ; TODO IMPORTANT
                cmpi.b  #0,d0                    ; Has the TODO bit been sent low?
                beq.s   loc_374                  ; If it has, branch.
                nop                              ; Give the port some time...
                nop                              ; ...
                nop                              ; ...
loc_374:
                moveq   #$40,d0                  ; Set /TH as an output.
                move.b  d0,($A10009).l           ; Init port 1.
                move.b  d0,($A1000B).l           ; Init port 2.
                move.b  d0,($A1000D).l           ; Init port 3.
loc_388:
                lea     ($FF0000).l,a6           ; Load the start of RAM.
                moveq   #0,d7                    ; Clear d7.
                move.w  #$3FFF,d6                ; Set to clear $10000 bytes of RAM.
loc_394:
                move.l  d7,(a6)+                 ; Clear 4 bytes.
                dbf     d6,loc_394               ; Repeat until fully cleared.
                move.l  #'init',($FFFFFFFC).w    ; Set the checksum flag.
                move.l  #$00100000,($FFFFCC00).w ; Set the top score as 100000.
loc_3aa:
                cmpi.l  #'init',($FFFFFFFC).w    ; Has the checksum been ran?
                bne.s   loc_388                  ; If not, branch.
                bsr.w   InitRAMJMPTable          ; Write address pointers into RAM.
                bsr.w   SetupVDPRegs             ; Write VDP setup array into RAM.
                bsr.w   WriteVDPRegs             ; Write stored VDP setup array values into the VDP.
                bsr.w   loc_402                  ; Clear CRAM and VRAM.
                bsr.w   loc_1014                 ; Load the sound driver to the Z80.
                lea     StartofRAMBlock,a0       ; Load start of code block.
                lea     ($FF0000).l,a1           ; Load start of RAM.
                move.w  #RAMBlockSize/4-1,d0     ; Repeat for $C000 bytes (or however large the file size is, depending on whether it was edited or not).
loc_3D8:
                move.l  (a0)+,(a1)+              ; Write first 4 bytes of the code into RAM.
                dbf     d0,loc_3d8               ; Repeat until the whole code block has been written.
                jmp     ($FF0000).l              ; Run code from RAM.

; ======================================================================

loc_3E4:
                bsr.w   loc_402                  ; Clear CRAM and VRAM.
                move.l  #$C0000000,($C00004).l   ; Set VDP to CRAM write.
                moveq   #$3F,d7                  ; Set to fill entire CRAM.
loc_3F4:
                move.w  #$000E,($C00000).l       ; Write red to CRAM.
                dbf     d7,loc_3F4               ; Repeat until filled with red.
loc_400:
                bra.s   loc_400                  ; Loop endlessly.

loc_402:
                move.l  #$C0000000,($C00004).l   ; Set VDP to CRAM write.
                moveq   #$3F,d0                  ; Set to fill entire CRAM.
loc_40E:
                move.w  #0,($C00000).l           ; Clear first palette.
                dbf     d0,loc_40E               ; Repeat until fully cleared.
                move.l  #$40000000,($C00004).l   ; Set VDP to VRAM write, $0000.
                lea     ($C00000).l,a5           ; Move the VDP control port to a5.
                move.w  #0,d6                    ; Clear a6.
                move.w  #$53FF,d7                ; Set to clear $A800 bytes.
loc_432:
                move.w  d6,(a5)                  ; Clear two bytes of VRAM.
                dbf     d7,loc_432               ; Repeat until cleared.
                rts                              ; Return.

; ======================================================================
; TODO IMPORTANT - I suspect this routine tests for invalid button presses
;                  mentioned in the MD development manual.
loc_43a:
                movem.l d1-d2/a1,-(sp)           ; Store used registers to the stack.
                lea     loc_466(pc),a1
                move.b  (a1),6(a0)
                moveq   #0,d0                    ; Clear d0.
                moveq   #8,d1                    ; Set amount of instructions to write.
loc_44A:
                move.b  (a1)+,(a0)
                nop                              ; Delay for a few cycles.
                nop                              ; ''
                move.b  (a0),d2
                and.b   (a1)+,d2
                beq.s   loc_458                  ; If both
                or.b    d1,d0
loc_458:
                lsr.b   #1,d1
                bne.s   loc_44a
                clr.b   6(a0)                    ; Clear set input/output value.
                movem.l (sp)+,d1-d2/a1           ; Restore register values.
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_466:
                dc.b    $40                      ; /T
                dc.b    $0C                      ;
                dc.b    $40
                dc.b    $03

                dc.b    $00
                dc.b    $0C
                dc.b    $00
                dc.b    $03

; ======================================================================

SegaScreen:                                      ; $46E
                bsr.w   loc_872                  ; Clear and initialise some registers and addresses. Load the next game mode upon return.
                lea     Pal_SegaScreen(pc),a5    ; Load the Sega Screen palette into a5.
                bsr.w   loc_1280                 ; Load the palette, art and mappings into the VDP.
                move.w  #$00B4,d1                ; TODO
                moveq   #0,d2                    ; Clear d2.
loc_480:
                bsr.w   WaitforVBlank            ; Wait for VBlank; load palettes from palette buffer into CRAM.
                subq.w  #1,d1                    ; Subtract 1 from the frame counter.
                move.w  d1,d0                    ; Copy value into d0.
                andi.w  #3,d0                    ; Delay for 3 frames (?). TODO
                bne.s   loc_480                  ; If 3 frames haven't passed, loop.
                cmpi.w  #$0028,d2                ; Have all the colours been cycled through?
                bgt.s   loc_4b2                  ; If they have, finish.
                move.w  d2,d3                    ; Copy cycling palette counter into d3.
                addq.w  #2,d2                    ; Add to load the next palette.
                lea     ($FFFFF7E4).w,a1         ; Load first palette line & third entry (in this case, the first blue).
                moveq   #$A,d7                   ; Repeat for all the blues being cycled.
loc_49e:
                cmpi.w  #$0028,d3                ; Has it gone past the final cycling palette entry?
                blt.s   loc_4a6                  ; If not, branch.
                moveq   #0,d3                    ; Reset cycling palette entry value.
loc_4a6:
                move.w  Palcycle_Sega(pc,d3.w),(a1)+ ; Load appropriate colour.
                addq.w  #2,d3                    ; Set to load next colour.
                dbf     d7,loc_49e               ; Load next colour.
                bra.s   loc_480                  ; Repeat until fully cycled.

loc_4b2:
                rts                              ; Return.

; ----------------------------------------------------------------------

Palcycle_Sega:                                   ; $4B4
                incbin  "Misc\SegaCyclingPalette.bin"

; ======================================================================

loc_4dc:                                         ; $4DC
                btst    #7,($FFFFFF8F).w         ; Is start being pressed?
                bne.s   loc_4ec                  ; If it is, branch.
                cmpi.w  #$78,($FFFFFF92).w       ; Has the game mode timer hit $78?
                bcs.s   loc_4f2                  ; If it hasn't, branch.
loc_4ec:
                move.w  #0,($FFFFFFC0).w         ; Load the title screen.
loc_4f2:
                bra.w   loc_1114                 ; TODO

; ======================================================================

Pal_SegaScreen:                                  ; $4F6
                incbin  "Palettes\SegaScreenPalette.bin"


loc_50a:        dc.w    $E316                    ; VRAM address to load mappings to.
                dc.w    $0001                    ; VRAM alignment value.
                dc.b    $0C                      ; X-times to loop.
                dc.b    $04                      ; Y-times to loop.

Eni_SegaScreen                                   ; $510
                incbin  "Mappings\Enigma\SegaScreen.bin"


Nem_SegaScreen                                   ; $51A
                incbin  "Art\Nemesis\SegaScreen.bin"

; ======================================================================
; Interrupt handler used for the level-2 interrupt (External), the
; level-4 interrupt (HBlank) and the level-6 interrupt (VBlank, although
; note that since the pointer is written to RAM, the pointer to this
; address for VBlank is overwritten later).
; ======================================================================

loc_856:
                rte                              ; Return from exception.

; ======================================================================

InitRAMJMPTable:                                 ; $858
                lea     RAMPointerTable(pc),a0   ; Load list of pointers, to be jumped to from RAM.
                lea     ($FFFFFA70).w,a1         ; Load designated level 2 (external) interrupt RAM address.
                move.w  (a0)+,d0                 ; Set to repeat for 40 pointers.
loc_862:
                move.w  #$4EF9,(a1)+             ; Set opcode for jmp (long).
                moveq   #0,d1                    ; Clear d1.
                move.w  (a0)+,d1                 ; Write first pointer.
                move.l  d1,(a1)+                 ; Write the address into RAM.
                dbf     d0,loc_862               ; Repeat for the rest.
                rts                              ; Return.

; ======================================================================

loc_872:
                lea     ($FFFFFF70).w,a6         ; Load VDP array (not stack pointer, as it decrements).
                moveq   #0,d7                    ; Clear d7.
                move.w  #$13,d6                  ; 13 registers to update.
loc_87C:
                move.l  d7,(a6)+                 ; Clear 4 bytes of it.
                dbf     d6,loc_87c               ; Repeat for the rest.
                lea     ($FFFFF7E0).w,a6         ; Load start of palette buffer.
                moveq   #0,d7                    ; Clear d7.
                move.w  #$3F,d6                  ; Set to clear both the palette buffer and the target palette RAM space.
loc_88C:
                move.l  d7,(a6)+                 ; Clear two palette entries worth of data.
                dbf     d6,loc_88c               ; Repeat until fully cleared.
                move.w  #4,($FFFFFF98).w         ; Set VBlank routine.
                addq.w  #4,($FFFFFFC0).w         ; Load next game mode.
                clr.l   ($FFFFF550).w            ; Clear a longword from the sprite table TODO.
                movem.w loc_8d4(pc),d0-d5        ; Load the VDP table values into d0-d5.
                movem.w d0-d5,($FFFFFFD8).w      ; Copy them to this RAM space.
                bsr.w   SetupVDPRegs                  ; Write VDP setup array into RAM.
                btst    #6,($A10001).l           ; Is this being played on a PAL console?
                beq.s   loc_8c0                  ; If not, branch.
                move.b  #$3C,($FFFFFF71).w       ; VDP register $01 storage - bits set: Enable VBlank, DMA and 240 line mode. Disable display.
loc_8C0:
                bsr.w   WriteVDPRegs                  ; Write VDP setup array register values, stored in RAM, into the VDP.
                move.l  #$C0000000,(a6)          ; Set VDP to CRAM write.
                move.w  #0,-4(a6)                ; Set black as the transparent colour.
                bra.w   ClearScreen              ; Clear the screen.

; ----------------------------------------------------------------------

loc_8d4:
                dc.w    $BE00                    ; Sprite table VRAM address      ($FFFFD8).
                dc.w    $B800                    ; HScroll VRAM address           ($FFFFDA).
                dc.w    $B000                    ; Window plane VRAM address      ($FFFFDC).
                dc.w    $C000                    ; Plane A VRAM address           ($FFFFDE).
                dc.w    $E000                    ; Plane B VRAM address           ($FFFFE0).
                dc.w    $0040                    ; Plane mapping increment value  ($FFFFE2).

; ======================================================================
loc_8E0:
                movem.w d0-d2,-(sp)              ; Store registers into the stack.
                move.w  #$400,d0                 ; Set DMA address as $400.
                bsr.s   loc_906                  ; Write it to the VDP.
                movem.w (sp)+,d0-d2              ; Restore register values.
                addi.w  #$400,d2                 ; Set to load the next VRAM address block (+$400).
                subi.w  #$400,d0                 ; Subract 1 from the DMA data length block.
                cmpi.w  #$400,d0                 ; Is it any lower than $400?
                bls.s   loc_906                  ; If it is, just write it to the VDP.
                bra.s   loc_8e0                  ; Otherwise, just loop.

; ----------------------------------------------------------------------
; Unused DMA fill routine, designed to clear VRAM. d0 is the DMA data
; size and d2 is the VRAM address to write to.

loc_8FE:
                moveq   #0,d1                    ; Clear d1.
loc_900:
                cmpi.w  #$400,d0                 ; Is the DMA length larger than $400?
                bhi.s   loc_8e0                  ; If it is, branch.
loc_906:
                lea     ($C00004).l,a6           ; Load the VDP control port into a6.
                subq.w  #1,d0                    ; Subtract 1 from DMA length so that it doesn't over-shoot.
                swap    d1                       ; Swap d1's value (pointless).
                move.w  #$8F01,(a6)              ; Set the VDP auto increment to $01.
                move.w  d0,d1                    ; Copy to d1.
                andi.w  #$FF,d0                  ; Get the low data length byte on its own.
                ori.w   #$9300,d0                ; Set as low DMA size byte.
                move.w  d0,(a6)                  ; Write to the VDP.
                lsr.w   #8,d1                    ; Shift to get the byte on its own.
                ori.w   #$9400,d1                ; Get the high data length byte on its own.
                move.w  d1,(a6)                  ; Write to the VDP.
                swap    d1                       ; Swap register values; get the clear high word on low.
                move.w  #$9780,(a6)              ; Set VDP to DMA fill.
                move.l  #$00200000,d0            ; Set the DMA bit (value is swapped later to form a command; the bit is therefore set).
                move.w  d2,d0                    ; Get the VRAM address to write to.
                lsl.l   #2,d0                    ; Shift left to get the correct VRAM boundary.
                move.w  d2,d0                    ; Restore address value.
                andi.w  #$3FFF,d0                ; Keep within a $4000 byte range.
                ori.w   #$4000,d0                ; Set to VRAM write.
                swap    d0                       ; Swap to form a VDP command.
                move.l  d0,(a6)                  ; Write to the VDP.
                move.b  d1,-4(a6)                ; Write $00 to the VDP; start DMA.
                bsr.w   WaitforDMAFinish         ; Wait for DMA to finish.
                move.w  #$8F02,(a6)              ; Restore the VDP auto increment value to $02.
                rts                              ; Return.

; ======================================================================
                                                 ; TODO - Do this later. It's an unused VRAM copy routine.
loc_954:
                movem.w d0-d2,-(sp)              ; Store used registers onto the stack.
                move.w  #$200,d0
                bsr.s   loc_97c
                movem.w (sp)+,d0-d2
                addi.w  #$200,d2
                addi.w  #$200,d1
                subi.w  #$200,d0
                cmpi.w  #$200,d0
                bls.s   loc_97c
                bra.s   loc_954

; ----------------------------------------------------------------------
; Unused DMA copy routine.
loc_976:
                cmpi.w  #$200,d0
                bhi.s   loc_954
loc_97c:
                lea     ($C00004).l,a6
                swap    d1
                move.w  #$8F01,(a6)
                move.w  d0,d1
                andi.w  #$FF,d0
                ori.w   #$9300,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9400,d1
                move.w  d1,(a6)
                swap    d1
                move.w  d1,d0
                andi.w  #$FF,d0
                ori.w   #$9500,d0
                move.w  d0,(a6)
                lsr.w   #8,d1                    ; Shift to get the byte on its own.
                ori.w   #$9600,d1                ; Get the high address byte on its own.
                move.w  d1,(a6)                  ; Write to the VDP.
                move.w  #$97C0,(a6)              ; Set DMA mode to VRAM copy.
                move.l  #$00300000,d0            ; Set VDP to VRAM DMA copy (also sets an undefined bit, making the final command $XXXX00C0 rather than $XXXX0080).
                move.w  d2,d0                    ; Get the VRAM address to write to.
                lsl.l   #2,d0                    ; Shift left to get the correct VRAM boundary.
                move.w  d2,d0                    ; Restore address value.
                andi.w  #$3FFF,d0                ; Keep within a $4000 byte range.
                ori.w   #$4000,d0                ; Set to VRAM write.
                swap    d0                       ; Swap to convert into a VDP address.
                move.l  d0,(a6)                  ; Write to the VDP; Start DMA.
                bsr.w   WaitforDMAFinish         ; Wait for DMA to finish.
                move.w  #$8F02,(a6)              ; Restore the VDP auto increment to $02.
                rts                              ; Return.

; ======================================================================

WaitforDMAFinish:                                ; $9D8
                move.w  (a6),d0                  ; Move the VDP status register value into d0.
                andi.w  #2,d0                    ; Is DMA fill/copy still running?
                bne.s   WaitforDMAFinish         ; If it is, branch.
                rts                              ; Return.

; ======================================================================
; Unused M68K to VRAM DMA routine.   TODO
loc_9e2:
                movem.w d0-d2,-(sp)
                move.w  #$400,d0
                bsr.s   loc_a12
                movem.w (sp)+,d0-d2
                addi.w  #$400,d1
                addi.w  #$400,d2
                subi.w  #$400,d0
                cmpi.w  #$400,d0
                bls.s   loc_a12
                bra.s   loc_9e2

; Unused M68K to CRAM DMA routine.
loc_a04:
                bsr.s   loc_a1a
                ori.w   #$C000,d0                ; Set the address as CRAM read.
                bra.s   loc_a66

loc_A0C:
                cmpi.w  #$400,d0
                bhi.s   loc_9e2
loc_a12:
                bsr.s   loc_a1a
                ori.w   #$4000,d0                ; Set the address as VRAM read.
                bra.s   loc_a66


loc_a1a:
                lea     ($C00004).l,a6
                lsr.w   #1,d0
                swap    d1
                move.w  d0,d1
                andi.w  #$FF,d0
                ori.w   #$9300,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9400,d1
                move.w  d1,(a6)
                swap    d1
                lsr.w   #1,d1
                move.w  d1,d0
                andi.w  #$FF,d0
                ori.w   #$9500,d0
                move.w  d0,(a6)
                lsr.w   #8,d1
                ori.w   #$9680,d1
                move.w  d1,(a6)
                move.w  #$977F,(a6)
                move.l  #$200000,d0
                move.w  d2,d0
                lsl.l   #2,d0
                move.w  d2,d0
                andi.w  #$3FFF,d0
                rts

loc_a66:
                move.w  d0,(a6)
                swap    d0
                move.w  d0,($FFFFFFAE).w
                move.w  ($FFFFFFAE).w,(a6)
                rts

; ======================================================================


loc_A74:
                moveq   #0,d1                    ; Clear d1.
loc_A76:
                movem.l d3/a5,-(sp)              ; Store both registers' values.
                lea     ($C00004).l,a6           ; Load the VDP control port to a6.
                lea     -4(a6),a5                ; Load the VDP data port into a5.
                move.b  d1,d3                    ; Clear a byte of d3.
                lsl.w   #8,d3                    ; Clear the upper byte of the lower word of d3.
                move.b  d1,d3                    ; Clear a byte of d3.
                move.w  d3,d1                    ; TODO
                swap    d3
                move.w  d1,d3
                clr.l   d1                       ; Clear d1.
                move.w  d2,d1                    ; Move the VRAM address to be converted.
                lsl.l   #2,d1                    ; Shift the address left to get the appropriate division of $4000 (i.e. 3 will have a range of $C000-$FFFF). TODO
                move.w  d2,d1                    ; Overwrite lower word with the address, again.
                andi.w  #$3FFF,d1                ; Keep within a $3FFF range.
                ori.w   #$4000,d1                ; Set to write to VRAM.
                swap    d1                       ; Swap register halves; get full address.
                move.l  d1,(a6)                  ; Set correct VRAM write address location.
                addq.w  #3,d0                    ; TODO
                lsr.w   #2,d0                    ; Divide by 4 to deal with longword writes.
                move.w  d0,d1                    ; Copy to another register to handle tenths.
                lsr.w   #3,d1                    ; Divide by 8 for 8 move instructions.
                bra.s   loc_abe                  ; Set to write to the VDP.

; Draws a tile onto the screen.
loc_aae:
                move.l  d3,(a5)                  ; Write 4 bytes into the VDP.
                move.l  d3,(a5)                  ; ''
                move.l  d3,(a5)                  ; ''
                move.l  d3,(a5)                  ; ''
                move.l  d3,(a5)                  ; ''
                move.l  d3,(a5)                  ; ''
                move.l  d3,(a5)                  ; ''
                move.l  d3,(a5)                  ; ''
loc_ABE:
                dbf     d1,loc_aae               ; Repeat for every tile needed to be written.
                andi.w  #7,d0                    ; Get any number below 8.
                bra.s   loc_aca                   ; Above code handled tenths. Branch to the code that handles ones.

loc_ac8:
                move.l  d3,(a5)                  ; Write 4 bytes into the VDP.
loc_aca:
                dbf     d0,loc_ac8               ; Repeat for every 4 bytes needed to be written.
                movem.l (sp)+,d3/a5              ; Restore register values.
                rts                              ; Return.

; ======================================================================
                      ; TODO - ANNOTATE ME
NemDec:                                          ; $AD4
                movem.l d0-a1/a3-a5,-(sp)        ; Store used registers onto the stack.
                lea     loc_B5A,a3
                lea     ($C00000).l,a4           ; Set to load to the VDP.
                bra.s   NemDec_Main              ; Run the main decompression routine.

; ======================================================================

NemDectoRAM:                                     ; $AE6
                movem.l d0-a1/a3-a5,-(sp)        ; Store used registers onto the stack.
                lea     loc_b70,a3

NemDec_Main:                                     ; $AF0
                lea     ($FFFFE630).w,a1         ; Set RAM address to decompress to.
                move.w  (a0)+,d2                 ; Move the header into d2.
                lsl.w   #1,d2                    ; Is the value signed?
                bcc.s   loc_afe                  ; If it isn't, set the normal decompression mode.
                adda.w  #loc_B64-loc_B5A,a3      ; If it is, set the XOR decompression mode.
loc_afe:
                lsl.w   #2,d2
                movea.w d2,a5                    ; Set as address NOTE NOTE NT
                moveq   #8,d3
                moveq   #0,d2                    ; Clear d2.
                moveq   #0,d4                    ; Clear d4.
                bsr.w   loc_b8a
                bsr.w   loc_c0c
loc_B10:
                moveq   #8,d0
                bsr.w   loc_c16
                cmpi.w  #$FC,d1
                bcc.s   loc_b4c
                add.w   d1,d1
                move.b  (a1,d1.w),d0
                ext.w   d0
                bsr.w   loc_c2a
                move.b  1(a1,d1.w),d1
loc_B2C:
                move.w  d1,d0
                andi.w  #$F,d1
                andi.w  #$F0,d0
                lsr.w   #4,d0
loc_B38:
                lsl.l   #4,d4
                or.b    d1,d4
                subq.w  #1,d3
                bne.s   loc_b46
                jmp     (a3)                     ; TODO

; ======================================================================

loc_B42:
                moveq   #0,d4
                moveq   #8,d3
loc_b46:
                dbf     d0,loc_b38
                bra.s   loc_b10

loc_b4c:
                moveq   #6,d0
                bsr.w   loc_c2a
                moveq   #7,d0
                bsr.w   loc_c26
                bra.s   loc_b2c

; ======================================================================
;
loc_b5a:
                move.l  d4,(a4)
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   loc_b42
                bra.s   loc_b84


; Branched to instead of B5A when XOR mode is set on the decompression to
; VRAM variant.
loc_b64:
                eor.l   d4,d2
                move.l  d2,(a4)
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   loc_b42
                bra.s   loc_b84

; ======================================================================

loc_b70:
                move.l  d4,(a4)+
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   loc_b42
                bra.s   loc_b84


; Branched to instead of B70 when XOR mode is set on the decompression to
; RAM variant.
loc_b7a:
                eor.l   d4,d2
                move.l  d2,(a4)+
                subq.w  #1,a5
                move.w  a5,d4
                bne.s   loc_b42

; ======================================================================

loc_b84:
                movem.l (sp)+,d0-a1/a3-a5        ; Restore register values.
                rts                              ; Return.

; ======================================================================

loc_b8a:
                move.b  (a0)+,d0                 ; Move the compressed byte into d0.
loc_B8C:
                cmpi.b  #-1,d0                   ; Is the section set to end? TODO
                bne.s   loc_b94                  ; If it isn't, branch.
                rts                              ; Return.

loc_b94:
                move.w  d0,d7                    ; Copy to d7.
loc_B96:
                move.b  (a0)+,d0                 ;
                cmpi.b  #$80,d0                  ;
                bcc.s   loc_b8c                  ;
                move.b  d0,d1                    ;
                andi.w  #$F,d7                   ; Get the palette entry nybble.
                andi.w  #$70,d1                  ;
                or.w    d1,d7                    ;
                andi.w  #$F,d0
                move.b  d0,d1
                lsl.w   #8,d1
                or.w    d1,d7
                moveq   #8,d1
                sub.w   d0,d1
                bne.s   loc_bc4
                move.b  (a0)+,d0
                add.w   d0,d0
                move.w  d7,(a1,d0.w)
                bra.s   loc_b96

loc_bc4:
                move.b  (a0)+,d0
                lsl.w   d1,d0
                add.w   d0,d0
                moveq   #1,d5
                lsl.w   d1,d5
                subq.w  #1,d5
loc_BD0:
                move.w  d7,(a1,d0.w)
                addq.w  #2,d0
                dbf     d5,loc_bd0
                bra.s   loc_b96

; ======================================================================

loc_bdc:
                lsl.w   d0,d5
                add.w   d0,d6
                add.w   d0,d0
                and.w   loc_c38(pc,d0.w),d1
                add.w   d1,d5
                move.w  d6,d0
                subq.w  #8,d0
                bcs.s   loc_bfe
                bne.s   loc_bf6
                clr.w   d6
                move.b  d5,(a0)+
                rts

loc_bf6:
                move.w  d5,d6
                lsr.w   d0,d6
                move.b  d6,(a0)+
                move.w  d0,d6
loc_bfe:
                rts

; ======================================================================

loc_c00:
                neg.w   d6
                beq.s   loc_c0a
                addq.w  #8,d6
                lsl.w   d6,d5
                move.b  d5,(a0)+
loc_c0a:
                rts

; ======================================================================

loc_c0c:
                move.b  (a0)+,d5
                asl.w   #8,d5
                move.b  (a0)+,d5
                moveq   #$10,d6
                rts                              ; Return.

; ======================================================================

loc_c16:
                move.w  d6,d7
                sub.w   d0,d7
                move.w  d5,d1
                lsr.w   d7,d1
                add.w   d0,d0
                and.w   loc_c38(pc,d0.w),d1
                rts                              ; Return.

; ======================================================================

loc_c26:
                bsr.s   loc_c16
                lsr.w   #1,d0
loc_c2a:
                sub.w   d0,d6
                cmpi.w  #9,d6
                bcc.s   loc_c38
                addq.w  #8,d6
                asl.w   #8,d5
                move.b  (a0)+,d5
loc_c38:
                rts

; ======================================================================

loc_c3a:
                dc.w    $0001, $0003, $0007, $000F
                dc.w    $001F, $003F, $007F, $00FF
                dc.w    $01FF, $03FF, $07FF, $0FFF
                dc.w    $1FFF, $3FFF, $7FFF, $FFFF

; ======================================================================

loc_c5a:
                move.w  a3,d3
                swap    d4
                bpl.s   loc_c6a
                subq.w  #1,d6
                btst    d6,d5
                beq.s   loc_c6a
                ori.w   #$1000,d3
loc_c6a:
                swap    d4
                bpl.s   loc_c78
                subq.w  #1,d6
                btst    d6,d5
                beq.s   loc_c78
                ori.w   #$800,d3
loc_c78:
                move.w  d5,d1
                move.w  d6,d7
                sub.w   a5,d7
                bcc.s   loc_ca8
                move.w  d7,d6
                addi.w  #$10,d6
                neg.w   d7
                lsl.w   d7,d1
                move.b  (a0),d5
                rol.b   d7,d5
                add.w   d7,d7
                and.w   loc_c38(pc,d7.w),d5
                add.w   d5,d1
loc_C96:
                move.w  a5,d0
                add.w   d0,d0
                and.w   loc_c38(pc,d0.w),d1
                add.w   d3,d1
                move.b  (a0)+,d5
                lsl.w   #8,d5
                move.b  (a0)+,d5
                rts

; ======================================================================

loc_ca8:
                beq.s   loc_cbc
                lsr.w   d7,d1
                move.w  a5,d0
                add.w   d0,d0
                and.w   loc_c38(pc,d0.w),d1
                add.w   d3,d1
                move.w  a5,d0
                bra.w   loc_c2a
loc_CBC:
                moveq   #$10,d6
                bra.s   loc_c96

; ======================================================================
; Compression subroutine that can be used to deompress colours that use
; two palette entries. Used in Flicky for ASCII.
; INPUT
; d0 - Palette entry IDs. Each nybble represents a palette entry.
; d1 - Size of compressed art, divided by 8.
; a0 - Source of compressed art.
;
; OUTPUT
; a4 - Source of decompressed graphics if the write to RAM mode was used.
; ======================================================================
BittoPixelDecompression:                         ; $CC0
                movem.l d0-d6/a0/a4,-(sp)        ; Push register values onto the stack.
                moveq   #0,d4                    ; Clear d4 (Set address increment to 0).
                lea     ($C00000).l,a4           ; Load the VDP data port into a4.
                bra.s   loc_cd4                  ; Jump to the actual handling subroutine.

; ----------------------------------------------------------------------

BittoPixelDecompression_RAM:                     ; Unused. Used to write to RAM. Note that this means that a RAM
                                                 ; address is expected to be written to a4. $CCE
                movem.l d0-d6/a0/a4,-(sp)        ; Push register values onto the stack.
                moveq   #4,d4                    ; Set as address increment (for longwords).
loc_cd4:
                asl.w   #3,d1                    ; Multiply by 8 (Completely arbitrary, although the data length before being branched to was divided by 8 as well).
                subq.w  #1,d1                    ; Subtract 1 for the dbf loop.
                move.b  d0,d2                    ; Load the palette entries into d2.
                move.b  d2,d3                    ; Copy to d3.
                lsr.b   #4,d2                    ; Get upper nybble of the byte, in this case entry 1.
                andi.b  #$F,d3                   ; Get lower nybble of the byte, in this case entry 2.
loc_CE2:
                moveq   #7,d6                    ; Set bit counter value as 7 (highest bit in a byte).
                move.b  (a0)+,d0                 ; Move the first byte of the compressed art into d0.
loc_ce6:
                lsl.l   #4,d5                    ; Shift to get the next nybble.
                btst    d6,d0                    ; Is it set to a 0 or 1?
                beq.s   loc_cf0                  ; If it is set to a 0, branch.
                or.b    d2,d5                    ; Set the pixel as using specified palette entry 1.
                bra.s   loc_cf2                  ; Branch to check the rest of the bits.

loc_cf0:
                or.b    d3,d5                    ; Set the pixel as using specified palette entry 2.
loc_cf2:
                dbf     d6,loc_ce6               ; Repeat for the rest of the bits. d6 decrements, so it's also the value used to check the other bits.
                move.l  d5,(a4)                  ; Move 8 pixels into VRAM.
                adda.l  d4,a4                    ; Add address increment. Useful only for RAM.
                dbf     d1,loc_ce2               ; Repeat for the rest of the compressed art source.
                movem.l (sp)+,d0-d6/a0/a4        ; Restore register values.
                rts                              ; Return.

; ======================================================================
; Slightly modified code, but works the same as it does in the other
; MD games. A compression variant.
; ======================================================================
EniDec:                                          ; $D04
                movem.l d0-d7/a1-a5,-(sp)        ; Store register values to the stack.
                movea.w d0,a3
                move.b  (a0)+,d0
                ext.w   d0
                movea.w d0,a5
                move.b  (a0)+,d0
                ext.w   d0
                ext.l   d0
                ror.l   #1,d0
                ror.w   #1,d0
                move.l  d0,d4
                movea.w (a0)+,a2
                adda.w  a3,a2
                movea.w (a0)+,a4
                adda.w  a3,a4
                bsr.w   loc_c0c
loc_D28:
                moveq   #7,d0
                bsr.w   loc_c16
                move.w  d1,d2
                moveq   #7,d0
                cmpi.w  #$40,d1
                bcc.s   loc_D3c
                moveq   #6,d0
                lsr.w   #1,d2
loc_D3c:
                bsr.w   loc_c2a
                andi.w  #$F,d2
                lsr.w   #4,d1
                add.w   d1,d1
                jmp     loc_D98(pc,d1.w)

; ======================================================================

loc_D4c:
                move.w  a2,(a1)+
                addq.w  #1,a2
                dbf     d2,loc_D4c
                bra.s   loc_D28

; ----------------------------------------------------------------------

loc_D56:
                move.w  a4,(a1)+
                dbf     d2,loc_D56
                bra.s   loc_D28

; ----------------------------------------------------------------------

loc_D5e:
                bsr.w   loc_c5a
loc_D62:
                move.w  d1,(a1)+
                dbf     d2,loc_D62
                bra.s   loc_D28
loc_D6A:
                bsr.w   loc_c5a
loc_D6E:
                move.w  d1,(a1)+
                addq.w  #1,d1
                dbf     d2,loc_D6e
                bra.s   loc_D28

; ----------------------------------------------------------------------

loc_D78:
                bsr.w   loc_c5a
loc_D7C:
                move.w  d1,(a1)+
                subq.w  #1,d1
                dbf     d2,loc_D7c
                bra.s   loc_D28

; ----------------------------------------------------------------------

loc_D86:
                cmpi.w  #$F,d2
                beq.s   loc_Da8
loc_D8C:
                bsr.w   loc_c5a
                move.w  d1,(a1)+
                dbf     d2,loc_D8c
                bra.s   loc_D28

; ======================================================================

loc_D98:
                bra.s   loc_D4c
                bra.s   loc_D4c
                bra.s   loc_D56
                bra.s   loc_D56
                bra.s   loc_D5e
                bra.s   loc_D6a
                bra.s   loc_D78
                bra.s   loc_D86

; ======================================================================

loc_Da8:
                subq.w  #1,a0
                cmpi.w  #$10,d6
                bne.s   loc_Db2
                subq.w  #1,a0
loc_Db2:
                move.w  a0,d0
                lsr.w   #1,d0
                bcc.s   loc_Dba
                addq.w  #1,a0
loc_Dba:
                movem.l (sp)+,d0-d7/a1-a5
                rts

; ======================================================================
; Updates the controller array
; ======================================================================

UpdateControllerArray:                           ; $DC0
                bsr.w   ReadJoypads                  ; Update controller output.
                lea     ($FFFFFF83).w,a0         ; Load pressed button array into a0.
                move.w  ($FFFFFF8E).w,d0         ; Load the output into d0.
                moveq   #$E,d1                   ; Set to test for A's bit.
                moveq   #6,d2                    ; Set to test for the other buttons (except start).
loc_DD0:
                btst    d1,d0                    ; Check if the button is being pressed.
                sne     (a0)+                    ; Set respective array byte to $FF if it is.
                subq.b  #1,d1                    ; Subtract to check for the next button (Order follows A C B R L D U).
                dbf     d2,loc_Dd0               ; Repeat for those buttons.
                moveq   #6,d1                    ; Set to bit test in the ACB range.
                moveq   #2,d2                    ; Set to repeat for only buttons A, B and C.
loc_DDE:
                btst    d1,d0                    ; Test for the appropriate button.
                sne     (a0)+                    ; Set to $FF if it's being pressed.
                subq.b  #1,d1                    ; Load next button.
                dbf     d2,loc_Dde               ; Repeat until A, B and C have been checked.
                andi.b  #$70,d0                  ; Do a test for A, B or C.
                sne     (a0)+                    ; Set the value if either A, B or C are being pressed.
                tst.b   ($FFFFFF87).w            ; Is left being pressed?
                beq.s   loc_Df8                  ; If it isn't, branch.
                clr.b   ($FFFFFF86).w            ; Clear the right button held value (it's checked before left, so there's no check needed for right as well).
loc_Df8:
                rts                              ; Return.

; ======================================================================
ReadJoypads:                                     ; $DFA
                bsr.w   loc_1050                 ; Check to see if the Z80's stopped, if not, stop it.
                lea     ($FFFFFF8E).w,a0         ; Load RAM address to write controller output values to.
                lea     ($A10003).l,a1           ; Load controller 1 port.
                bsr.s   Joypad_Read              ; Read the first controller.
                addq.w  #2,a1                    ; Repeat for the second controller.
                bsr.s   Joypad_Read              ; Read the second controller.
                bra.w   loc_107e                 ; Check to see if the Z80's running, otherwise run it.

Joypad_Read:                                     ; $E12
		move.b	#0,(a1)                  ; Set /TH pin low.
		nop                              ; Delay...
		nop                              ; ...
		move.b	(a1),d0                  ; Get bit outputs XTSA --DU.
		lsl.b	#2,d0                    ; Discard the irrelevant bits (XT).
		andi.b	#$C0,d0                  ; Get only Start and A (Down and Up are also covered when the /TH pin is high).
		move.b	#$40,(a1)                ; Set /TH pin high.
		nop                              ; Delay...
		nop                              ; ...
		move.b	(a1),d1                  ; Get bit outputs XTCB RLDU.
		andi.b	#$3F,d1	                 ; Discard the irrelevant bits (XT).
		or.b	d1,d0                    ; Combine the bits (SACB RLDU).
		not.b	d0                       ; Reverse bit values (Values were 1 by default and set to 0 when a button was pressed (active low). This reverses that).
		move.b	d0,d1                    ; Copy to d1.
		move.b	(a0),d2                  ; Load the last frame's stored controller state.
		eor.b	d2,d0                    ; Ensure buttons pressed last frame cannot be pressed again.
		move.b	d1,(a0)+                 ; Write the held button output to a0.
		and.b	d1,d0                    ; Unset any button bits that were held last frame.
		move.b	d0,(a0)+                 ; Write the pressed button output to a0.
                rts                              ; Return.

; ======================================================================

SetupVDPRegs_Unused:                             ; $E42
                lea     VDPSetupArray2(pc),a1    ; Load the unused VDP setup array into a1.
                bra.s   loc_E4C                  ; Load into RAM.

; ======================================================================

SetupVDPRegs:                                    ; $E48
                lea     VDPSetupArray(pc),a1     ; Load VDP setup array.
loc_E4C:
                lea     ($FFFFFF70).w,a2         ; Load storage area for VDP register values.
                moveq   #$12,d7                  ; $13 registers to load.
loc_E52:
                move.b  (a1)+,(a2)+              ; Write the first register value to RAM.
                dbf     d7,loc_E52               ; Repeat for the rest.
                rts                              ; Return.

; ----------------------------------------------------------------------

VDPSetupArray:                                   ; $E5A
                dc.b    $04, $34, $30, $2C
                dc.b    $07, $5F, $00, $00
                dc.b    $00, $00, $30, $02
                dc.b    $00, $2E, $00, $02
                dc.b    $00, $00, $00
                even
; ----------------------------------------------------------------------
; Unused VDPSetupArray table that has VBlank disabled, a different sprite
; table location ($A800), set to scroll 8 pixels, uses a 40 tile wide
; display, has a different HScroll table address ($AC00) and a shifted
; window plane.
VDPSetupArray2:                                  ; $E6E
                dc.b    $04, $14, $30, $2C
                dc.b    $07, $54, $00, $00
                dc.b    $00, $00, $30, $00
                dc.b    $81, $2B, $00, $02
                dc.b    $01, $00, $00
                even
; ======================================================================
; Write the VDP registers stored in the array, into the VDP.

WriteVDPRegs:                                    ; $E82
                lea     ($FFFFFF70).w,a1         ; Load storage area for VDP registers into a1.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                move.w  #$8000,d7                ; Load VDP register value.
loc_E90:
                move.w  d7,d0                    ; Copy to d0.
                move.b  (a1)+,d0                 ; Load the first register value to d0.
                move.w  d0,(a6)                  ; Write to the VDP.
                addi.w  #$100,d7                 ; Load increment value for next register.
                cmpi.w  #$9300,d7                ; Has it hit the final register?
                bcs.s   loc_E90                  ; If it hasn't, branch.
                rts                              ; Return.

; ======================================================================

ClearScreen:                                     ; $EA2
                move.w  #$B000,d2                ; Load VRAM address to dump to.
                move.w  #$5000,d0                ; Load data length.
                bsr.w   loc_a74                  ; Set to clear VRAM from $B000 to $FFFF.
                clr.l   ($FFFFFFA4).w            ; Clear vertical scroll value.
                clr.l   ($FFFFFFA8).w            ; Clear horizontal scroll value.
                lea     ($FFFFF550).w,a6         ; Load the sprite table buffer into a6. TODO
                moveq   #0,d7                    ; Clear d7
                move.w  #$7F,d6                  ; Set to repeat for $200 bytes.
loc_EC0:
                move.l  d7,(a6)+                 ; Clear 4 bytes.
                dbf     d6,loc_Ec0               ; Repeat until it's completely cleared.
                rts                              ; Return.

; ======================================================================
; Writes plane mappings onto the screen.
; ======================================================================

PlaneMaptoVRAM2:                                 ; $EC8
                lea     ($C00004).l,a2           ; Load the VDP control port into a2.
                lea     ($C00000).l,a3           ; Load the VDP data port into a3.
                move.l  #$800000,d7              ; Set the tile increment value.
loc_EDA:
                move.l  d0,(a2)                  ; Set the VRAM address.
                move.w  d1,d4                    ; Copy the amount of tiles to write across, to d4.
loc_EDE:
                move.w  (a1)+,(a3)               ; Write the first mapping to the VDP.
                dbf     d4,loc_Ede               ; Repeat for the tiles across that line.
                add.l   d7,d0                    ; Increment downwards by 1 tile.
                dbf     d2,loc_Eda               ; Repeat for the next line across.
                rts                              ; Return.

; ======================================================================
; PlaneMaptoVRAM variation, that writes repeating tiles to the planes.
; ======================================================================
PlaneMaptoVRAM3:                                 ; $EEC
                lea     ($C00004).l,a2           ; Load the VDP control port into a2.
                lea     ($C00000).l,a3           ; Load the VDP data port into a3.
                move.l  #$800000,d5              ; Set the tile increment value.
loc_EFE:
                move.l  d0,(a2)                  ; Load the VRAM address into a2.
                move.w  d1,d3                    ; Copy the amount of tiles to write across, to d3.
loc_F02:
                move.w  d4,(a3)                  ; Write the tile onto the screen.
                dbf     d3,loc_F02               ; Repeat for the tiles across that line.
                add.l   d5,d0                    ; Increment downwards by 1 tile.
                dbf     d2,loc_Efe               ; Repeat for the next line across.
                rts                              ; Return.

; ======================================================================
; Convert a VRAM address (write) into a VDP command.
loc_F10:
                asl.w   #5,d0                    ; *20, if the VRAM address is /20.
loc_F12:
                clr.l   d1                       ; Clear d1.
                move.w  d0,d1                    ; Move the VRAM address into d1.
                lsl.l   #2,d1                    ; Get correct VRAM boundary in high word.
                move.w  d0,d1                    ; Refresh address.
                andi.w  #$3FFF,d1                ; Keep within a $4000 byte range.
                ori.w   #$4000,d1                ; Set to VRAM write.
                swap    d1                       ; Swap to form a VDP command.
                move.l  d1,(a6)                  ; Set the VDP.
                rts                              ; Return.

; ======================================================================
; Convert a VRAM address (read) into a VDP command.
loc_F28:
                asl.w   #5,d0                    ; *20, if the VRAM address is /20.
loc_F2A:
                clr.l   d1                       ; Clear d1.
                move.w  d0,d1                    ; Move the VRAM address into d1.
                lsl.l   #2,d1                    ; Get correct VRAM boundary in high word.
                move.w  d0,d1                    ; Refresh address.
                andi.w  #$3FFF,d1                ; Keep within a $4000 byte boundary range.
                swap    d1                       ; Swap words to form a VDP command.
                move.l  d1,(a6)                  ; Write to the VDP.
                rts

; ======================================================================
; Loops until VBlank is ran.

WaitforVBlank:                                   ; $F3C
                move.w  ($FFFFFF98).w,($FFFFFF96).w ; Mirror VBlank routine value.
loc_F42:
                tst.w   ($FFFFFF96).w            ; Has VBlank ran?
                bne.s   loc_F42                  ; If not, loop.
                rts                              ; Return.

; ======================================================================
; Generates a pseudo-random number in $FFFFFFCA with each branch.

RandomNumber:                                    ; $F4A
                move.l  ($FFFFFFCA).w,d1         ; Move the current random number into d1.
                bne.s   loc_F56                  ; If it already has a number, branch.
                move.l  #$2A6D365A,d1            ; Generate a random seed.
loc_F56:
                move.l  d1,d0                    ; Below instructions randomise the number, no reason to comment, really...
                asl.l   #2,d1
                add.l   d0,d1
                asl.l   #3,d1
                add.l   d0,d1
                move.w  d1,d0
                swap    d1
                add.w   d1,d0
                move.w  d0,d1
                swap    d1
                move.l  d1,($FFFFFFCA).w         ; Store in the random number address.
                rts                              ; Return.

; ======================================================================
                        ; TODO - This shit!
loc_F70:
                movem.l d2-d5,-(sp)              ; Store used registers onto the stack.
                moveq   #$40,d0
                cmp.w   d0,d2
                bcs.s   loc_F92                  ; If it is lower, branch.
                tst.w   d3
                beq.s   loc_F82
                cmp.w   d2,d3
                bcs.s   loc_F86
loc_F82:
                move.w  d0,d2
                bra.s   loc_F92

loc_F86:
                sub.w   d3,d2
                neg.w   d2
                add.w   d0,d2
                cmp.w   d2,d0
                bcc.s   loc_F92
                moveq   #0,d2
loc_F92:
                lea     ($FFFFF7E0).w,a0         ; Load the palette buffer into a0.
                lea     ($FFFFF860).w,a1         ; Load the target palette RAM space into a1.
                cmpi.w  #$40,d2
                bne.s   loc_Faa
                moveq   #$1F,d4
loc_FA2:
                move.l  (a1)+,(a0)+
                dbf     d4,loc_Fa2
                bra.s   loc_Fce

loc_Faa:
                moveq   #$3F,d4
loc_FAC:
                move.w  (a1)+,d0
                rol.w   #4,d0
                moveq   #0,d3
                moveq   #2,d5
loc_FB4:
                lsl.w   #4,d3
                rol.w   #4,d0
                move.w  d0,d1
                andi.w  #$F,d1
                mulu.w  d2,d1
                lsr.w   #6,d1
                or.w    d1,d3
                dbf     d5,loc_Fb4
                move.w  d3,(a0)+
                dbf     d4,loc_Fac
loc_Fce:
                move.w  d2,d0
                movem.l (sp)+,d2-d5
                rts

; ======================================================================

loc_Fd6:
                cmpi.w  #$40,d0
                beq.s   loc_Ffe
                lea     ($FFFFF860).w,a0
                lea     ($FFFFF7E0).w,a1
                movem.l ($FFFFFFB8).w,d0-d1
                moveq   #$3F,d2
loc_Fec:
                roxl.l  #1,d1
                roxl.l  #1,d0
                bcc.s   loc_Ff6
                move.w  (a0)+,(a1)+
                bra.s   loc_Ffa

loc_Ff6:
                addq.w  #2,a0
                addq.w  #2,a1
loc_Ffa:
                dbf     d2,loc_Fec
loc_Ffe:
                rts

; ======================================================================

loc_1000:
                lea     ($FFFFF7E0).w,a0         ; Load the palette buffer into a0.
                lea     ($FFFFF860).w,a1         ; Load the target palette RAM space into a1.
                moveq   #$1F,d0                  ; Set to write and clear all palettes.
loc_100A:
                move.l  (a0),(a1)+               ; Write two palettes into a1.
                clr.l   (a0)+                    ; Clear those two palettes in a0.
                dbf     d0,loc_100a              ; Repeat for all of them.
                rts                              ; Return.

; ======================================================================

loc_1014:
                bsr.w   StoptheZ80               ; Stop the Z80.
                bsr.w   ResettheZ80              ; Reset the Z80.
                bsr.w   ClearZ80RAM              ; Clear the Z80's RAM.
                move.w  #Z80SoundDriver_End-Z80SoundDriver-1,d0 ; Set amount of bytes to write.
                moveq   #0,d1                    ; Position relative to start of Z80 RAM to write code to ($A00000+d1).
                moveq   #2,d2                    ; Skip the Z80 reset and start.
                lea     Z80SoundDriver(pc),a0    ; Load the Z80 sound driver address to a0.
                bsr.w   loc_10a6                 ; Write the code to the Z80.
                moveq   #loc_1046_End-loc_1046-1,d0; Set amount of bytes to write.
                move.w  #$1C00,d1                ; Position relative to start of Z80 RAM to write code to ($A00000+d1).
                moveq   #1,d2                    ; Reset the Z80, skip the Z80 start.
                lea     loc_1046(pc),a0          ; TODO
                bsr.w   loc_10a6                 ; Write the code to the Z80.
                clr.w   ($FFFFFFA2).w            ; TODO
                rts                              ; Return.

; ======================================================================
; TODO - Convert to Z80 with AS
loc_1046:
                dc.b    $00, $80, $00, $80
                dc.b    $00, $00, $00, $00
                dc.b    $20
loc_1046_End:
                even

; ======================================================================

loc_1050:
                btst    #0,($A11100).l           ; Has the Z80 stopped?
                sne     ($FFFFFFC8).w            ; If it hasn't, set flag and stop the Z80. TODO
                beq.s   loc_107c                 ; Otherwise, return.

; ======================================================================
; Stops the Z80. Does some unusual ways to waste time, suggesting that
; they were wary about the Z80 when this was made.

StoptheZ80:                                      ; $105E
                movem.w d0,-(sp)                 ; Store d0's value to the stack.
                move.w  #$100,($A11100).l        ; Stop the Z80.
                moveq   #$F,d0                   ; Set a delay.
loc_106C:
                btst    #0,($A11100).l           ; Has the Z80 stopped?
                dbeq    d0,loc_106c              ; If not, branch.
                movem.w (sp)+,d0                 ; Restore d0's value.
loc_107C:
                rts                              ; Return.

; ======================================================================

loc_107e:
                tst.b   ($FFFFFFC8).w            ; Has the Z80 stopped?
                beq.s   loc_108c                 ; If it hasn't, skip starting it. Otherwise, start it.
loc_1084:
                move.w  #0,($A11100).l           ; Start the Z80.
loc_108C:
                rts                              ; Return.

; ======================================================================

ResettheZ80:                                     ; $108E
                move.w  #0,($A11200).l           ; Disable Z80 reset.
                bsr.s   loc_10a4                 ; Delay.
                bsr.s   loc_10a4                 ; Delay.
                bsr.s   loc_10a4                 ; Delay.
                move.w  #$100,($A11200).l        ; Reset the Z80.
loc_10a4:
                rts                              ; Return.

; ======================================================================

loc_10a6:
                movem.l d0-d3/a0-a1,-(sp)        ; Store used registers to the stack.
                bsr.s   StoptheZ80               ; Stop the Z80.
                lea     ($A00000).l,a1           ; Load the start of Z80 RAM.
                adda.w  d1,a1                    ; Get the relative offset.
loc_10B4:
                move.b  (a0)+,d1                 ; Move the first byte.
                moveq   #$F,d3                   ; Set a delay.
loc_10B8:
                move.b  d1,(a1)                  ; Load the value into Z80 RAM.
                cmp.b   (a1),d1                  ; Has the value been loaded?
                beq.s   loc_10C4                 ; If it has, branch.
                dbf     d3,loc_10b8              ; Otherwise, loop until otherwise.
                bra.s   loc_10d4                 ; If it still hasn't loaded on time, branch.

loc_10C4:
                addq.w  #1,a1                    ; Increment Z80 RAM address.
                dbf     d0,loc_10b4              ; Repeat for the rest.
                lsr.w   #1,d2                    ; Shift right.
                bcc.s   loc_10d0                 ; If the bit didn't contain a '1', skip the Z80 reset.
                bsr.s   ResettheZ80              ; Otherwise, reset the Z80.
loc_10d0:
                lsr.w   #1,d2                    ; Shift right again.
                bcs.s   loc_10d6                 ; If the bit was set, skip the Z80 start.
loc_10d4:
                bsr.s   loc_1084                 ; Start the Z80.
loc_10d6:
                movem.l (sp)+,d0-d3/a0-a1        ; Restore register values.
                rts                              ; Return.

; ======================================================================

loc_10dc:                                        ; TODO
                movem.l d1/a0,-(sp)              ; Store used registers onto the stack.
                bsr.w   StoptheZ80               ; Stop the Z80.
                lea     ($A01C04).l,a0
                moveq   #0,d1                    ; Clear d1.
                move.b  d1,(a0)+                 ; Clear TODO.
                move.b  d1,(a0)+                 ; ''
                move.b  d1,(a0)+                 ; ''
                move.b  d1,(a0)                  ; ''
                addq.w  #2,a0
                move.b  d0,(a0)
                bsr.s   loc_1084                 ; Start the Z80.
                movem.l (sp)+,d1/a0              ; Restore register values.
                rts                              ; Return.

; ======================================================================

loc_1100:
                movea.w ($FFFFFFA2).w,a0
                cmpa.w  #8,a0
                bcc.s   loc_1112
                move.b  d0,-$66(a0)
                addq.w  #1,($FFFFFFA2).w
loc_1112:
                rts

; ======================================================================

loc_1114:
                movea.w ($FFFFFFA2).w,a0
                move.w  a0,d0
                beq.s   loc_115a
                move.b  -$67(a0),d0
                subq.w  #1,($FFFFFFA2).w
                bsr.w   StoptheZ80               ; Stop the Z80.
                tst.b   ($A01C0A).l
                bne.s   loc_1138
                move.b  d0,($A01C0A).l
                bra.s   loc_1156

loc_1138:
                tst.b   ($A01C0B).l
                bne.s   loc_1148
                move.b  d0,($A01C0B).l
                bra.s   loc_1156

loc_1148:
                tst.b   ($A01C0C).l
                bne.s   loc_1156
                move.b  d0,($A01C0C).l
loc_1156:
                bsr.w   loc_1084                 ; Start the Z80.
loc_115a:
                bra.w   WaitforVBlank

; ======================================================================
; Clears Z80 RAM. Has similar timing delays to StoptheZ80, also suggesting
; that the developers didn't trust the Z80 bus.

ClearZ80RAM:
                move.w  #$1FFF,d0                ; Load length of Z80 RAM.
                lea     ($A00000).l,a0           ; Load start of Z80 RAM.
loc_1168:
                moveq   #$F,d1                   ; Delay loop counter, as a precaution.
loc_116a:
                move.b  #0,(a0)                  ; Clear a byte of Z80 RAM.
                tst.b   (a0)                     ; Is it clear (timing precaution)?
                dbeq    d1,loc_116a              ; If it isn't, branch.
                addq.l  #1,a0                    ; Add to the next byte.
                dbf     d0,loc_1168              ; Repeat until the rest is clear.
                rts                              ; Return.

; ======================================================================
; TODO IMPORTANT
loc_117c:
                movem.w d1,-(sp)                 ; Store d1's value onto the stack.
                bsr.w   StoptheZ80               ; Stop the Z80.
                move.b  ($A01C0A).l,d1           ;
                bsr.w   loc_1084                 ; Start the Z80.
                cmp.b   d0,d1                    ; Is it the same value as d0?
                movem.w (sp)+,d1                 ; Restore value anyway.
                rts                              ; Return.

; ======================================================================
; NOTE - Palette data in Flicky has a different format. The format of
;        the palettes is as shown (bitfield):
;
;        XXXX BBBN GGGN RRRT
;
;        ...Where XXXX is the value for the palette entry (i.e. 0110 (6)
;        would mean it's written to palette entry 6), B, G and R bits
;        function normally, the T is the terminator which ends the
;        palette data, otherwise it'd move onto the next word and decode
;        it. As for the N bits, when you string both of them together, it
;        determines which palette line the palette goes into. i.e.
;
;        00 - Palette line 0
;        01 - Palette line 1
;        10 - Palette line 2
;        11 - Palette line 3
;
;        So for instance, $6EFE gives you white, palette entry 6, palette
;        line 1 and continues decoding palettes. This is the same decoding
;        method seen in Streets of Rage.
;
; ======================================================================

DecodePalettes:                                  ; $1196
                movem.l d0-d2/a0,-(sp)           ; Store register values.
                lea     ($FFFFF7E0).w,a0         ; Load the start of the palette buffer into a0.
loc_119E:
                move.w  (a5),d0                  ; Load first palette into d0.
                andi.w  #$10,d0                  ; Get the tenth; strip the rest of the bits except for the lower N bit.
                move.w  (a5),d1                  ; Reload the palette value.
                rol.w   #4,d1                    ; Get palette entry value.
                andi.w  #$F,d1                   ; Strip the rest of the bits.
                or.w    d1,d0                    ; Add onto the tenth.
                move.w  (a5),d1                  ; Reload the palette value.
                andi.w  #$100,d1                 ; Get the hundredth; strip the rest of the bits except for the higher N bit.
                lsr.w   #3,d1                    ; Divide to get into the byte range.
                or.w    d1,d0                    ; Add onto the rest of the bits.
                add.w   d0,d0                    ; Multiply by 2 to account for the word size.
                move.w  (a5)+,d2                 ; Reload the palette value.
                move.w  d2,d1                    ; Copy into d1.
                andi.w  #$0EEE,d1                ; Ensure that white is the highest value attainable.
                move.w  d1,(a0,d0.w)             ; Load to the appropriate position in the palette buffer.
                lsr.w   #1,d2                    ; Shift right to check for the presence of the T bit.
                bcc.s   loc_119E                 ; If it's not there, continue decoding palettes.
                movem.l (sp)+,d0-d2/a0           ; Restore register values.
                rts                              ; Return.

; ======================================================================

loc_11D0:
                move.w  #$8100,d0                ; Load VDP register 1's base word into d0.
                move.b  ($FFFFFF71).w,d0         ; Load the register command into d0.
                ori.b   #$40,d0                  ; Set the display bit.
                move.w  d0,(a6)                  ; Turn on the display.
                move.l  #$40000010,($C00004).l   ; Set the VDP to VSRAM write.
                move.l  ($FFFFFFA4).w,-4(a6)     ; Move the VScroll value into the VDP.
                move.w  ($FFFFFFDA).w,d0         ; Move the HScroll VRAM address value to d0.
                bsr.w   loc_F12                  ; Convert into a VRAM address.
                move.l  ($FFFFFFA8).w,d0         ; Move the HScroll value into the VDP.
                neg.w   d0                       ; Negate values to scroll in the correct direction.
                swap    d0                       ; Swap register halves.
                neg.w   d0                       ; Negate the other half.
                swap    d0                       ; Swap back to normal.
                move.l  d0,-4(a6)                ; Move the VScroll value into the VDP.
                rts                              ; Return.

; ======================================================================

loc_1208:
                lea     ($C00004).l,a6
                move.w  d0,d3
                move.w  d0,($FFFFFFE4).w
                lsl.w   #5,d3
                clr.b   d4
loc_1218:
                move.w  d3,d2
                move.w  d4,d1
                moveq   #$20,d0
                add.w   d0,d3
                bsr.w   loc_A76
                addi.b  #$11,d4
                bcc.s   loc_1218
                rts

; ======================================================================

loc_122C:
                movem.l d1-d5/a0,-(sp)           ; Store register values to the stack.
                movea.l a5,a0                    ; Copy palette source to a0.
                bsr.s   loc_124A                 ; Load the dumping and screen-writing variables into the data registers.
                clr.w   d0                       ; Clear starting art tile value.
                lea     ($FFFFC3E0).w,a1         ; Load destination RAM address for the mappings.
                bsr.w   EniDec                   ; Decompress from enigma.
                movea.l a0,a5                    ; Restore address.
                movea.l a1,a0                    ; Copy the decompressed mappings source into a0.
                bsr.s   loc_1260                 ; Dump onto the screen.
                movem.l (sp)+,d1-d5/a0           ; Restore register values.
                rts                              ; Return.

loc_124A:
                lea     ($C00004).l,a6           ; Load the VDP data port into a6.
                move.w  (a0)+,d2                 ; Move the unconverted VRAM address value into d2.
                move.w  (a0)+,d3                 ; Move VRAM alignment value into d3.
                move.w  #$00FF,d4                ; Set d4 as -1 (for dbf loop).
                move.w  d4,d5                    ; Do the same to d5.
                add.b   (a0)+,d4                 ; X-times to loop, -1.
                add.b   (a0)+,d5                 ; Y-times to loop, -1.
                rts                              ; Return.

loc_1260:
                move.w  d2,d0                    ; Move the VRAM address to be calculated into d0.
                bsr.w   loc_F12                  ; Convert it and set as the address.
                move.w  d4,d0                    ; Refresh X-times counter
loc_1268:
                move.w  (a0)+,d1                 ; Load first map tile.
                add.w   d3,d1                    ; Add to align with VRAM.
                move.w  d1,-4(a6)                ; Write onto the screen.
                dbf     d0,loc_1268              ; Repeat until first line of tiles has been written.
                add.w   ($FFFFFFE2).w,d2         ; Add to the address needed to be calculated.
                dbf     d5,loc_1260              ; Repeat for the next line.
                move.w  d3,d0                    ; Move VRAM alignment tile into d0 (for decompressing the art).
                rts                              ; Return.

; ======================================================================
; Loads the palette and mappings, converts d0 into a VDP address and
; decompresses the source stored in a5 from Nemesis. Only used for the
; Sega screen.
loc_1280:
                bsr.w   DecodePalettes           ; Decode the encrypted palette from a5 into its position in the palette buffer.
                bsr.s   loc_122C                 ; Decompress the mappings and write to the screen.
                bsr.w   loc_F10                  ; Convert the previously stored value in d0 into an address.
                movea.l a5,a0                    ; Move the Sega screen's art source into a0.
                bra.w   NemDec                   ; Decompress the art from Nemesis and load into VRAM.

; ======================================================================

loc_1290:
                movem.l a0/a5,-(sp)              ; Store a0 and a5's register values.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                lea     -4(a6),a5                ; Load the VDP data port into a5.
                ori.l   #$FFFF0000,d1            ; Turn into a full address.
                movea.l d1,a0                    ; Set as address.
                clr.l   d1                       ; Clear d1.
                move.w  d2,d1                    ; Move the CRAM address to be converted.
                lsl.l   #2,d1                    ; Shift the address left to get the appropriate palette line to load to.
                move.w  d2,d1                    ; Overwrite lower word with the address, again.
                andi.w  #$3FFF,d1                ; Keep within a $3FFF range.
                ori.w   #$C000,d1                ; Set to CRAM write.
                swap    d1                       ; Swap register halves; get full address.
                move.l  d1,(a6)                  ; Write to the VDP; set VDP mode.
                bra.s   loc_12E6                 ; Write to the VDP.

; ======================================================================

loc_12BC:
                movem.l a0/a5,-(sp)              ; Store a0 and a5's register values.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                lea     -4(a6),a5                ; Load the VDP data port into a5.
                ori.l   #$FFFF0000,d1            ; Turn into a full address.
                movea.l d1,a0                    ; Set as address.
                clr.l   d1                       ; Clear d1.
                move.w  d2,d1                    ; Move the VRAM address to be converted.
                lsl.l   #2,d1                    ; Shift the address left to get the appropriate division of $4000 (i.e. 3 will have a range of $C000-$FFFF).
                move.w  d2,d1                    ; Overwrite lower word with the address, again.
                andi.w  #$3FFF,d1                ; Keep within a $3FFF range.
                ori.w   #$4000,d1                ; Set to write to VRAM.
                swap    d1                       ; Swap register halves; get full address.
                move.l  d1,(a6)                  ; Write to the VDP; set VDP mode.
loc_12E6:
                addq.w  #3,d0                    ; TODO
                lsr.w   #2,d0                    ; Divide by 4 to deal with longword writes.
                move.w  d0,d1                    ; Copy to another register to handle tenths.
                lsr.w   #3,d1                    ; Divide by 8 for 8 move instructions.
                bra.s   loc_1300                 ; Set to write to the VDP.

loc_12F0:
                move.l  (a0)+,(a5)               ; Write 4 bytes into the VDP.
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
loc_1300:
                dbf     d1,loc_12F0              ; Repeat for every $20 bytes needed to be written.
                andi.w  #7,d0                    ; Get any number below 8.
                bra.s   loc_130c                 ; Above code handled tenths. Branch to the code that handles ones.

loc_130A:
                move.l  (a0)+,(a5)               ; Write 4 bytes into the VDP.
loc_130C:
                dbf     d0,loc_130A              ; Repeat for every 4 bytes needed to be written.
                movem.l (sp)+,a0/a5              ; Restore register values.
                rts                              ; Return.

; ======================================================================
; Z80 sound driver.

Z80SoundDriver:                                  ; $1316
                incbin  "Z80SoundDriver.bin"
Z80SoundDriver_End:
; ======================================================================
; Rewritable RAM pointer table.                                              ; TODO - Describe the function of each of these.
; ======================================================================
RAMPointerTable:                                 ; $22FC
                dc.w    (RPT_End-(RAMPointerTable+2))/2-1 ; Amount of addresses to load to RAM, -1.
                dc.w    loc_856                  ; Level 2 (external) interrupt ($FFFA70).
                dc.w    loc_856                  ; HBlank pointer ($FFFA76).
                dc.w    loc_856                  ; VBlank pointer, address replaced later ($FFFA7C).
                dc.w    NemDec                   ; Nemesis decompression into the VDP ($FFFA82).
                dc.w    NemDectoRAM              ; Nemesis decompression into RAM, unused($FFFA88).
                dc.w    BittoPixelDecompression  ; Bit to pixel decompression into the VDP ($FFFA8E).
                dc.w    BittoPixelDecompression_RAM ; Bit to pixel decompression into RAM, unused ($FFFA94).
                dc.w    loc_C0C                  ; ($FFFA9A).
                dc.w    loc_C16                  ; ($FFFAA0).
                dc.w    loc_C26                  ; ($FFFAA6).
                dc.w    loc_C2A                  ; ($FFFAAC).
                dc.w    loc_BDC                  ; ($FFFAB2).
                dc.w    loc_C00                  ; ($FFFAB8).
                dc.w    EniDec                   ; ($FFFABE).
                dc.w    loc_1290                 ; ($FFFAC4).
                dc.w    loc_12BC                 ; ($FFFACA).
                dc.w    loc_1208                 ; Unused ($FFFAD0).
                dc.w    loc_A74                  ; ($FFFAD6).
                dc.w    loc_A76                  ; Same as above, but skips the register clearing instruction ($FFFADC).
                dc.w    WaitforDMAFinish         ; Waits for DMA fill/copy to finish. Unused ($FFFAE2).
                dc.w    loc_8FE                  ; Unused ($FFFAE8).
                dc.w    loc_900                  ; Copy of above, but it skips a register clear instruction for TODO ($FFFAEE).
                dc.w    loc_976                  ; ($FFFAF4).
                dc.w    loc_A04                  ; ($FFFAFA).
                dc.w    loc_A0C                  ; ($FFFB00).
                dc.w    loc_11D0                 ; ($FFFB06).
                dc.w    loc_FD6                  ; ($FFFB0C).
                dc.w    UpdateControllerArray    ; Updates the controller array, and controller RAM ($FFFB12).
                dc.w    ReadJoypads              ; Update controller RAM ($FFFB18).
                dc.w    SetupVDPRegs             ; Writes VDP setup array into RAM ($FFFB1E).
                dc.w    WriteVDPRegs             ; Writes stored VDP setup array values from RAM into the VDP ($FFFB24).
                dc.w    ClearScreen              ; Clears the plane mappings, H/VScroll values and sprite table buffer ($FFFB2A).
                dc.w    loc_1014                 ; ($FFFB30).
                dc.w    StoptheZ80               ; Stops the Z80 ($FFFB36).
                dc.w    loc_1084                 ; Starts the Z80 ($FFFB3C).
                dc.w    loc_1050                 ; Checks to see if the Z80's stopped, and if it hasn't, stop it ($FFFB42).
                dc.w    loc_107E                 ; Checks to see if the Z80's running, and it it isn't, run it ($FFFB48).
                dc.w    ResettheZ80              ; Resets the Z80 ($FFFB4E).
                dc.w    loc_10A6                 ; ($FFFB54).
                dc.w    ClearZ80RAM              ; Clears the Z80 RAM ($FFFB5A).
                dc.w    loc_10DC                 ; ($FFFB60).
                dc.w    loc_1100                 ; ($FFFB66).
                dc.w    loc_1114                 ; ($FFFB6C).
                dc.w    WaitforVBlank            ; Waits for VBlank ($FFFB72).
                dc.w    RandomNumber             ; Generates a random number in $FFFFCA ($FFFB78).
                dc.w    PlaneMaptoVRAM2          ; Writes plane mappings onto the screen ($FFFB7E).
                dc.w    PlaneMaptoVRAM3          ; Writes a repeating tile onto the screen($FFFB84).
                dc.w    loc_F10                  ; ($FFFB8A).
                dc.w    loc_F12                  ; Converts a VRAM address ($FFFB90).
                dc.w    loc_F28                  ; ($FFFB96).
                dc.w    loc_F2A                  ; ($FFFB9C).
                dc.w    loc_117C                 ; ($FFFBA2).
                dc.w    loc_F70                  ; ($FFFBA8).
                dc.w    loc_1000                 ; ($FFFBAE).
                dc.w    loc_872                  ; ($FFFBB4).
                dc.w    DecodePalettes           ; Decodes the palettes into readable CRAM values. Only used by a select few palettes ($FFFBBA).
                dc.w    loc_122C                 ; ($FFFBC0).
                dc.w    loc_1280                 ; Loads the mappings and palette, converts a VDP address and decompresses an art source from Nemesis ($FFFBC6).
RPT_End:
; ======================================================================

loc_2372:
                incbin  "Art\BtP\ASCII.bin"
loc_2372_End:

Padding1:
                alignFF $10000                   ; Pad to $10000.
; ----------------------------------------------------------------------
; ======================================================================
; Start of main code, written into RAM, and ran from there.
; ======================================================================

StartofRAMBlock:                                 ; $10000
                move.w  #$2700,sr                ; Disable interrupts.
                move.l  #VBlank,($FFFFFA7E).w    ; Set VBlank address.
                clr.w   ($FFFFFF96).w            ; Clear VBlank routine.
                move.w  #$40,($FFFFFFC0).w       ; Set to run first game mode (Sega Screen).
                clr.w   ($FFFFFFC4).w            ; Clear unused address 1.
                clr.w   ($FFFFFFC2).w            ; Clear unused address 2.
                bsr.w   loc_10CD4                ; Clear CRAM and VRAM (Except for plane nametables).
                bsr.w   loc_10CF6                ; Load the sound driver instructions into Z80 RAM.
                bsr.w   loc_100FC                ; Load the ASCII art into VRAM.
                lea     ($FFFFD800).w,a6         ; Load start of TODO.
                moveq   #0,d7                    ; Clear d7.
                move.w  #$1FF,d6                 ; Set to repeat for $800 bytes.
loc_10034:
                move.l  d7,(a6)+                 ; Clear 4 bytes.
                dbf     d6,loc_10034             ; Repeat until $800 bytes have been cleared.
                move.l  #$40000010,($C00004).l   ; Set VDP to VSRAM write.
                move.w  #0,($C00000).l           ; Clear 2 bytes.
                move.l  #$40020010,($C00004).l   ; Set VDP to VSRAM write (+$02).
                move.w  #0,($C00000).l           ; Clear 2 bytes.
                bsr.w   loc_113BC                ; Clear H/VScroll values and TODO.
                move.w  #$101,($FFFFD82C).w      ; Set the BCD and hex level round value to 0101.
                move.w  #$2500,sr                ; Enable VBlank.
MainGameLoop:
                movea.w StartofROM+2,sp          ; Restore stack pointer back to $(XXXX)FF70.
                move.w  ($FFFFFFC0).w,d0         ; Set game mode.
                andi.l  #$0000007C,d0            ; Game mode limit.
                jsr     GameModeArray(pc,d0.w)   ; Load appropriate game mode.
                addq.w  #1,($FFFFFF92).w         ; Increment game mode timer.
                bra.s   MainGameLoop             ; Loop, updating game mode.

; ----------------------------------------------------------------------

GameModeArray:
                bra.w   TitleScreen_Load         ; $0  - Title screen variable-loading routine.
                bra.w   TitleScreen_Loop         ; $4  - Title screen loop.
                bra.w   loc_1228e                ; $8  -
                bra.w   loc_122e0                ; $C  -
                bra.w   loc_125be                ; $10 -
                bra.w   loc_125f2                ; $14 -
                bra.w   loc_12656                ; $18 -
                bra.w   loc_1266e                ; $1C -
                bra.w   Level_Load               ; $20 -
                bra.w   loc_12b46                ; $24 -
                bra.w   loc_12f30                ; $28 -
                bra.w   loc_12fdc                ; $2C -
                bra.w   loc_13110                ; $30 -
                bra.w   loc_13162                ; $34 -
                bra.w   loc_139a2                ; $38 - Demo
                bra.w   loc_13a18                ; $3C - Demo
                bra.w   loc_100CC                ; $40 - Sega screen jump.
                bra.w   loc_100D0                ; $44 - Checks if the Sega screen has finished (jump).

; ======================================================================

loc_100CC:
                jmp     SegaScreen               ; Jump to the Sega screen code handler.

; ======================================================================

loc_100D0:
                jmp     loc_4dc                  ; Checks to see if the Sega screen is finished.

; ======================================================================

loc_100d4:
                jsr     ($FFFFFBB4).w            ; Clear and initialise some registers and addresses.
                lea     ($FFFFD000).w,a6         ; TODO IMPORTANT
                moveq   #0,d7                    ; Clear d7.
                move.w  #$1FF,d6                 ; Set to clear $800 bytes.
loc_100E2:
                move.l  d7,(a6)+                 ; Clear 4 bytes.
                dbf     d6,loc_100e2             ; Repeat for the rest.
                bsr.w   loc_113bc                ; Clear TODO.
                bsr.w   loc_110fe                ; Clear TODO object RAM?
                move.w  #$8000,($FFFFD884).w     ; Set mappings incrementer to use priority 1.
                jmp     loc_101a8                ; Dump some compressed graphics into VRAM.

; ======================================================================

loc_100Fc:
                move.w  #$200,d0                 ; Set VRAM address to be converted.
                jsr     ($FFFFFB8A).w            ; Convert it and send it to the VDP.
                lea     loc_16e58,a0             ; Load level stuff's compressed art into a0.
                jsr     ($FFFFFA82).w            ; Decompress from nemesis and load into VRAM.
                move.w  #$400,d0                 ; Set VRAM address to be converted.
                jsr     ($FFFFFB8A).w            ; Convert it and send it to the VDP.
                lea     loc_187d4,a0             ; Load grabbable items' compressed art into a0.
                jsr     ($FFFFFA82).w            ; Decompress from nemesis and load into VRAM.
                move.b  #1,($FFFFD88E).w         ; Set palette entry increment to 1.
loc_10126:
                moveq   #$20,d0                  ; Set to write to VRAM address $20.
                lea     ($C00004).l,a6           ; Load VDP data port into a6.
                jsr     ($FFFFFB8A).w            ; Convert to address.
                lea     loc_2372,a0              ; Load start of compressed ASCII symbols.
                moveq   #$20,d0                  ; Set to use palette entry 2 and 0.
                add.b   ($FFFFD88E).w,d0         ; Add to make it use entry 2 and 1.
                move.w  #(loc_2372_End-loc_2372)/8,d1 ; Get the length of the data, divided by 8.
                jsr     ($FFFFFA8E).w            ; Decompress it.
                moveq   #$30,d0                  ; Set to write to VRAM address $30.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                jsr     ($FFFFFB8A).w            ; Convert to address.
                lea     loc_185fc,a0             ; Load start of compressed ASCII numbers/characters.
                moveq   #$20,d0                  ; Set to use palette entry 2 and 0.
                add.b   ($FFFFD88E).w,d0         ; Add to make it use entry 2 and 1.
                move.w  #(loc_185FC_End-loc_185FC)/8,d1 ; Get the length of the data, divided by 8.
                jsr     ($FFFFFA8E).w            ; Decompress it.
                move.w  #$120,d0                 ; Set to write to VRAM address $120.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                jsr     ($FFFFFB8A).w            ; Convert to an address.
                lea     loc_2372,a0              ; Load the start of the compressed ASCII symbols.
                moveq   #$30,d0                  ; Set to use palette line 3 and 0.
                add.b   ($FFFFD88E).w,d0         ; Set to use palette line 3 and 1.
                move.w  #(loc_2372_End-loc_2372)/8,d1 ; Get the length of the data, divided by 8.
                jsr     ($FFFFFA8E).w            ; Decompress it.
                move.w  #$130,d0                 ; Set to write to VRAM address $130.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                jsr     ($FFFFFB8A).w            ; Convert to an address.
                lea     loc_185fc,a0             ; Load start of compressed ASCII numbers/characters.
                moveq   #$30,d0                  ; Set to use palette line 3 and 0.
                add.b   ($FFFFD88E).w,d0         ; Set to use palette line 3 and 1.
                move.w  #(loc_185FC_End-loc_185FC)/8,d1 ; Get the length of the data, divided by 8.
                jsr     ($FFFFFA8E).w            ; Decompress it.
                rts                              ; Return.

; ======================================================================

loc_101a8:
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                move.w  #$640,d0                 ; Set VRAM address to be converted.
                jsr     ($FFFFFB8A).w            ; Convert it and write it to the VDP.
                lea     loc_1993e,a0             ; Load nemesis compressed points, Iggy, diamond and bonus points model graphics into a0.
                jsr     ($FFFFFA82).w            ; Decompress and load into VRAM.
                move.w  #$693,d0                 ; Set VRAM address to be converted.
                jsr     ($FFFFFB8A).w            ; Convert it and write it to the VDP.
                lea     loc_18754,a0             ; Load nemesis compressed graphics source.      TODO - Possibly the exit sign?
                jsr     ($FFFFFA82).w            ; Decompress it and load into VRAM.
                rts                              ; Return.

; ======================================================================

loc_101d4:
                dc.w    loc_101E0_End-loc_101E0  ; d0 - Size of data in bytes ($1C8 in this case).
                dc.w    $1000                    ; d1 - Relative offset in Z80 RAM ($A00000 + $XXXX)
                dc.w    loc_101E0&$FFFF          ; a0 - Data location.

                dc.w    loc_103A8_End-loc_103A8  ; d0 - Size of data in bytes.
                dc.w    $1200                    ; d1 - Relative offset in Z80 RAM ($A00000 + $XXXX)
                dc.w    loc_103A8&$FFFF          ; a0 - Data location.

; ----------------------------------------------------------------------
; Sound effects pointers. TODO - Convert when using AS!

loc_101E0:
                incbin  "Z80SFXPointers.bin"
loc_101E0_End:
; ----------------------------------------------------------------------
; General pointer list.
loc_103A8:
                incbin  "Z80PointerList.bin"
loc_103A8_End:
; ======================================================================

loc_10CD4:
                move.l  #$C0000000,($C00004).l   ; Set VDP to CRAM write.
                moveq   #$3F,d0                  ; Set to write to 4 palette lines.
loc_10CE0:
                move.w  #0,($C00000).l           ; Clear first palette line.
                dbf     d0,loc_10Ce0             ; Repeat until CRAM is fully cleared.
                moveq   #0,d2                    ; Set VRAM address to dump to.
                move.w  #$A800,d0                ; Set data length.
                jmp     ($FFFFFAD6).w            ; Write onto the screen.

; ======================================================================

loc_10CF6:
                jsr     ($FFFFFB30).w            ; Load the sound driver to the Z80.
                lea     (loc_101d4).l,a1         ; Load the Z80 pointers list into a1.
                bsr.s   loc_10d24                ; Write first set of pointers to the Z80.
                bsr.s   loc_10d24                ; And write the next set of pointers.
                moveq   #8,d0                    ; Set to write only 8 instructions (last $00 is ignored as it is an even).
                move.w  #$1C00,d1                ; Set offset in Z80 RAM to load to.
                moveq   #1,d2                    ; Reset the Z80, skip the Z80 start.
                lea     loc_10d1a(pc),a0         ; Load the Z80 code into a0.
                jsr     ($FFFFFB54).w            ; Write the Z80 code into the Z80.
                clr.w   ($FFFFFFA2).w
                rts                              ; Return.

; ----------------------------------------------------------------------
; TODO - Convert to Z80 when using AS.

loc_10d1a:
                dc.b    $00                      ; nop
                dc.b    $80                      ; add b
                dc.b    $00                      ; nop
                dc.b    $12                      ; ld (de),a
                dc.b    $B4                      ; or h
                dc.b    $00                      ; nop
                dc.b    $E6, $80                 ; and $80
                dc.b    $20, $00                 ; jr nz, $00.

; ======================================================================

loc_10d24:
                moveq   #2,d2                    ; Set to skip Z80 start and reset.
                movem.w (a1)+,d0-d1/a0           ;
                suba.l  #$00010000,a0            ; $FF01E0 is the source location. TODO
                jmp     ($FFFFFB54).w            ; Write the code onto the Z80.

; ======================================================================

loc_10d34:
                move.l  a0,-(sp)
                jsr     ($FFFFFB36).w            ; Stop the Z80.
                move.b  d0,($A01C09).l
                jsr     ($FFFFFB3C).w            ; Start the Z80.
                movea.l (sp)+,a0
                rts

; ======================================================================

loc_10d48:
                tst.b   ($FFFFD2A4).w
                bne.s   loc_10d50
                bsr.s   loc_10d34
loc_10d50:
                rts

; ======================================================================

loc_10d52:
                tst.b   ($FFFFD2A4).w
                beq.s   loc_10d6c
                addq.w  #1,($FFFFD2A2).w
                cmpi.w  #$1E,($FFFFD2A2).w
                bcs.s   loc_10d6c
                clr.w   ($FFFFD2A2).w
                clr.b   ($FFFFD2A4).w
loc_10d6c:
                rts
; ----------------------------------------------------------------------
; ======================================================================
; Unused VRAM conversion subroutine. Put in a VRAM address in d0 and get
; a converted VDP command as an output in d0.
; ======================================================================

loc_10d6e
                movem.l d1,-(sp)                 ; Push d1's value onto the stack.
                clr.l   d1                       ; Clear d1.
                move.w  d0,d1                    ; Push VRAM address value into d1.
                lsl.l   #2,d1                    ; Get correct VRAM boundary.
                move.w  d0,d1                    ; Update VRAM address.
                andi.w  #$3FFF,d1                ; Keep within a $4000 byte range.
                ori.w   #$4000,d1                ; Set to write to VRAM.
                swap    d1                       ; Swap register halves; get VDP command.
                move.l  d1,d0                    ; Store in d0.
                movem.l (sp)+,d1                 ; Restore d1's value.
                rts                              ; Return.

; ======================================================================
; Unused routine.
loc_10d8c
                movea.l a4,a1
                clr.w   d1
loc_10d90:
                clr.w   d2
                move.b  (a0)+,d2
                beq.s   loc_10db6
                bclr    #7,d2
                beq.s   loc_10da8
                subq.b  #1,d2
loc_10d9e:
                move.b  (a0)+,(a1)
                adda.w  d0,a1
                dbf     d2,loc_10d9e
                bra.s   loc_10d90
loc_10da8:
                subq.b  #1,d2
                move.b  (a0)+,d3
loc_10dac:
                move.b  d3,(a1)
                adda.w  d0,a1
                dbf     d2,loc_10dac
                bra.s   loc_10d90

loc_10db6:
                movea.l a4,a1
                addq.w  #1,d1
                adda.w  d1,a1
                cmp.w   d1,d0
                bhi.s   loc_10d90
                rts

loc_10dc2:
                clr.w   d2
                move.b  (a0)+,d2
                beq.s   loc_10de6
                bclr    #7,d2
                beq.s   loc_10dd8
                subq.b  #1,d2
loc_10dd0:
                move.b  (a0)+,(a4)+
                dbf     d2,loc_10dd0
                bra.s   loc_10dc2

loc_10dd8:
                subq.b  #1,d2
                move.b  (a0)+,d3
loc_10ddc:
                move.b  d3,(a4)+
                addq.b  #1,d3
                dbf     d2,loc_10ddc
                bra.s   loc_10dc2

loc_10de6:
                rts

; ======================================================================

loc_10de8:
                movem.l d0-d1,-(sp)              ; Store used registers onto the stack.
                clr.w   d5
                subi.w  #$20,d4
                bcc.s   loc_10e08
                cmpi.w  #$FFF3,d4
                bne.s   loc_10e02
                move.w  #$79,d4
                moveq   #1,d5
                bra.s   loc_10e3c

loc_10e02:
                addi.w  #$C0,d4
                bra.s   loc_10e3c

loc_10e08:
                moveq   #$40,d0
                cmp.w   d0,d4
                bcs.s   loc_10e3c
                sub.w   d0,d4
                moveq   #$40,d1
                moveq   #$50,d0
                cmp.w   d0,d4
                bcs.s   loc_10e1c
                sub.w   d0,d4
                moveq   #$77,d1
loc_10e1c:
                cmpi.w  #$37,d4
                bcs.s   loc_10e3a
                moveq   #1,d5
                cmpi.w  #$46,d4
                bcs.s   loc_10e36
                cmpi.w  #$4B,d4
                bcc.s   loc_10e34
                addq.w  #5,d4
                bra.s   loc_10e36

loc_10e34:
                moveq   #2,d5
loc_10e36:
                subi.w  #$32,d4
loc_10e3a:
                add.w   d1,d4
loc_10e3c:
                addi.w  #$40,d4
                tst.w   d5
                beq.s   loc_10e48
                addi.w  #$AD,d5
loc_10e48:
                addi.w  #$40,d5
                movem.l (sp)+,d0-d1              ; Restore register values.
                rts                              ; Return.

; ----------------------------------------------------------------------
; ======================================================================
; Possibly a leftover debug routine from very early development.
; ======================================================================
loc_10e52:
                trap    #0                       ; Trigger trap exception 0 (Vector doesn't exist now, so it's possibly early development code).
                ror.l   #8,d1                    ; Shift one byte to the right.
                rts                              ; Return.

loc_10e58                                        ; Subroutine seems to start here.
                movem.l d0-d1/d7,-(sp)           ; Store register values onto the stack.
                clr.w   ($FFFFE630).w            ; TODO - I don't know if this can be commented, these addresses might be radically different at the time of development.
                addq.w  #1,($FFFFE634).w
                move.w  ($FFFFE632).w,d7
                subq.w  #1,d7
                bcs.s   loc_10e82
loc_10e6c:
                bsr.s   loc_10e52
                andi.l  #$0000FFFF,d1
                divu.w  ($FFFFE634).w,d1
                swap    d1
                add.w   d1,($FFFFE630).w         ; Redundant, as the higher word that was swapped low was cleared by the andi.
                dbf     d7,loc_10e6c
loc_10e82:
                movem.l (sp)+,d0-d1/d7           ; Restore register values.
                rts                              ; Return.

; ======================================================================

VBlank:                                          ; $10E88
                move.w  #$2700,sr                ; Disable interrupts.
                movem.l d0-a6,-(sp)              ; Store all register values to the stack.
                lea     ($C00004).l,a6           ; Load VDP control port to a6.
                move.w  ($FFFFFF96).w,d0         ; Load the VBlank routine value into d0.
                andi.w  #$C,d0                   ; Keep within a multiple of 4; no more than 4 ($C/4 = 4, including 0) VBlank routines.
                jsr     VBlank_RoutineTable(pc,d0.w) ; Jump to VBlank routine.
                clr.w   ($FFFFFF96).w            ; Clear mirrored VBlank routine so you can return from WaitforVBlank.
                movem.l (sp)+,d0-a6              ; Restore register values.
                rte                              ; Return from the exception.

; ----------------------------------------------------------------------

VBlank_RoutineTable:                             ; $10EAC

                bra.w   loc_10EB8                ; $0
                bra.w   loc_10EBA                ; $4
                bra.w   loc_10EBA                ; $8

; ----------------------------------------------------------------------

loc_10eb8:
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_10eba:
                bsr.w   loc_1132a                ; Update scrolling.
                jsr     ($FFFFFB12).w            ; Update controller array.
                move.w  #$F550,d1                ; RAM address to dump from (sprite table).
                move.w  #$BE00,d2                ; VRAM address to convert and load to.
                move.w  #$0200,d0                ; Amount of bytes to dump.
                jsr     ($FFFFFACA).w            ; Run the subroutine to do that.
                moveq   #$F,d7                   ; Set to repeat for $20 palettes.
                lea     ($FFFFF7E0).w,a0         ; Load palette buffer into a0.
                lea     ($FFFFF860).w,a1         ; Load target palette space into a1.
loc_10EDC:
                cmpm.l  (a0)+,(a1)+              ; Does the value match?
                bne.s   loc_10EEE                ; If they don't, branch.
                dbf     d7,loc_10edc             ; Repeat to check the rest.
                bclr    #0,($FFFFD00C).w         ; Set palette fading as inactive.
                bne.s   loc_10ef4                ; If it was running before, branch.
                bra.s   loc_10F14                ; Skip updating palettes.
loc_10EEE:
                move.b  #1,($FFFFD00C).w         ; Set palette fading as active.
loc_10EF4:
                btst    #6,($A10001).l           ; Is this being played on a PAL console?
                beq.s   loc_10F06                ; If not, branch.
                move.w  #$100,d0                 ; Set to delay for a while.
loc_10F02:
                dbf     d0,loc_10F02             ; Waste time...
loc_10F06:
                move.w  #$F7E0,d1                ; RAM address to dump from.
                moveq   #0,d2                    ; Set palette line to dump to as 0.
                move.w  #$80,d0                  ; Set data length.
                jsr     ($FFFFFAC4).w            ; Dump to CRAM.
loc_10F14:
                move.w  #$8100,d0                ; Load VDP register $01's command word into d0.
                move.b  ($FFFFFF71).w,d0         ; Load VDP register $01's stored value into d0.
                ori.b   #$40,d0                  ; Enable display bit.
                move.w  d0,(a6)                  ; Turn on the display.
                rts                              ; Return.

; ======================================================================
; TODO - Comment this.
loc_10F24:
                add.w   d7,d7
                lsl.w   #6,d6
                add.w   d6,d7
                add.w   d5,d7
                move.w  d7,d5

                                   ; TODO - CalcVRAMAddress?
loc_10F2E:
                lsl.l   #2,d5                    ; Shift to get boundary value in high word.
                lsr.w   #2,d5                    ; Restore address.
                bset    #$E,d5                   ; Set to VRAM write.
                swap    d5                       ; Convert to VDP address.
                rts                              ; Return.

; ======================================================================
; Unused routine to convert the VRAM address and write the command and
; tile into the VDP.
; ======================================================================
loc_10F3a
                bsr.s   loc_10F24                ; Get the converted VRAM address.
                bra.s   loc_10F40                ; Write the command and address to the VDP.

; ======================================================================

loc_10F3e:
                bsr.s   loc_10F2e                ; Get a converted VDP command in d5.
loc_10F40:
                move.l  d5,($C00004).l           ; Set VRAM address.
                move.w  d4,($C00000).l           ; Write the tile to VRAM.
                rts                              ; Return.

; ======================================================================
; Unused subroutine to convert the VRAM address into a VDP command and
; write the source material into the VDP d4 times.
; ======================================================================

loc_10F4e
                lea     ($C00004).l,a4           ; Load the VDP control port into a4.
                lea     ($C00000).l,a3           ; Load the VDP data port into a3.
                lsl.l   #2,d5                    ; Get correct VRAM address boundary.
                lsr.w   #2,d5                    ; Restore to get offset in that boundary.
                bset    #$E,d5                   ; Set to VRAM write.
                swap    d5                       ; Swap to get the full VDP command.
                move.l  d5,(a4)                  ; Write to the VDP.
loc_10F66:
                move.w  (a6)+,(a3)               ; Write the source data into VRAM.
                dbf     d4,loc_10F66             ; Repeat d4 times.
                rts                              ; Return.

; ======================================================================

PlaneMaptoVRAM:                                  ; $10F6E
                bsr.s   loc_10F2e                ; Convert the VRAM address.
loc_10F70:
                lea     ($C00004).l,a4           ; Load VDP control port into a4.
                lea     ($C00000).l,a3           ; Load VDP data port into a3.
                move.l  #$00400000,d0            ; Set as line increment value.
loc_10F82:
                move.l  d5,(a4)                  ; Write converted VRAM address into the control port.
                move.w  d7,d1                    ; Set to write number of tiles horizontally.
loc_10F86:
                move.w  (a6)+,(a3)               ; Write first tile onto the screen (horizontally).
                dbf     d1,loc_10F86             ; Repeat for d1 times horizontally.
                add.l   d0,d5                    ; Increment down a line on screen.
                dbf     d6,loc_10F82             ; Repeat for d6 times vertically.
                rts                              ; Return.

; ======================================================================
loc_10F94:                                    ; TODO
                cmpi.w  #-1,($FFFFD884).w
                bne.s   loc_10FA2
                move.w  #$8020,d4
                bra.s   loc_10FA6

loc_10FA2:
                add.w   ($FFFFD884).w,d4         ; Set the map tile to use priority.
loc_10FA6:
                bsr.s   loc_10F3e                ; Convert the address and write the map tile onto the screen.
                rts                              ; Return.

; ======================================================================
WriteASCIIString:                                ; $10FAA
                moveq   #0,d6                    ; Clear d6.
                move.w  (a6)+,d6                 ; Move the VRAM address into d6.
loc_10FAE:
                moveq   #0,d4                    ; Clear d4.
                moveq   #0,d5                    ; Clear d5.
                move.w  d6,d5                    ; Copy VRAM address to d5.
                move.b  (a6)+,d4                 ; Get first byte.
                beq.s   loc_10Fbe                ; If it's a string terminator ($00), end the string.
                bsr.s   loc_10F94                ; Write onto the screen.
                addq.w  #2,d6                    ; Load next VRAM tile.
                bra.s   loc_10Fae                ; Repeat until a 0 is hit.
loc_10Fbe:
                rts                              ; Return.

; ======================================================================

loc_10Fc0:
                moveq   #0,d6                    ; Clear d6.
                move.w  (a6)+,d6                 ; Load the tile map's VRAM address (to be converted) to d6.
loc_10FC4:
                moveq   #0,d4                    ; Clear d4.
                moveq   #0,d5                    ; Clear d5.
                move.b  (a6)+,d4
                beq.s   loc_10Ff2
                bsr.w   loc_10de8
                move.w  d5,d3
                move.w  d6,d5
                subi.w  #$20,d4
                move.l  d5,-(sp)
                bsr.w   loc_10F3e
                move.l  (sp)+,d5
                subi.w  #$40,d5
                move.w  d3,d4
                subi.w  #$20,d4
                bsr.w   loc_10F3e
                addq.w  #2,d6
                bra.s   loc_10Fc4

loc_10Ff2:
                rts

; ======================================================================

loc_10Ff4:                                       ; TODO - Finish this shit some other time.
                clr.b   ($FFFFD00D).w            ; Clear the written number flag.
                subq.w  #2,d5
loc_10FFA:
                moveq   #0,d1                    ; Clear d1.
                move.b  (a6)+,d1                 ; Move highest bit into d1.
                move.w  d1,d4                    ; Copy to d4.
                lsr.w   #4,d4                    ; Get only the upper nybble (the upper number).
                addq.w  #2,d5
                movem.l d0-d1/d5,-(sp)           ; Store used registers onto the stack.
                bsr.w   loc_11036                ; TODO
                movem.l (sp)+,d0-d1/d5           ; Restore register values.
                andi.w  #$F,d1                   ; Get only the lower nybble (the lower number).
                move.w  d1,d4                    ; Copy to d4.
                addq.w  #2,d5
                movem.l d0-d1/d5,-(sp)           ; Store used registers to the stack.
                bsr.w   loc_11036                ; TODO
                movem.l (sp)+,d0-d1/d5           ; Restore register values.
                dbf     d0,loc_10Ffa             ; Repeat for the 3 other bytes.
                tst.b   ($FFFFD00D).w            ; Have there been any numbers written to the screen?
                bne.s   loc_11034                ; If there has, branch.
                moveq   #$30,d4                  ; Set to write a 0.
                bsr.w   loc_10F94                ; Write it.
loc_11034:
                rts                              ; Return.

; ======================================================================

loc_11036:
                tst.b   d4                       ; Is the byte value 00?
                bne.s   loc_1104c                ; If it isn't, branch.
                tst.b   ($FFFFD00D).w            ; Has there been a number written?
                bne.s   loc_11052                ; If there has, branch.
                tst.b   ($FFFFD29A).w            ; Is this the level select?
                beq.s   loc_1104a                ; If it isn't, branch.
                bsr.w   loc_10F94                ; TODO do this later.
loc_1104a:
                rts                              ; Return.

loc_1104c:
                move.b  #1,($FFFFD00D).w         ; Set the flag denoting a number having been written.
loc_11052:
                addi.w  #$30,d4                  ; Add to get to the numbers VRAM space.
                bsr.w   loc_10F94
                rts                              ; Return.

; ======================================================================

loc_1105c:
                btst    #0,2(a0)
                bne.s   loc_110b8
                move.l  $34(a0),d1
                move.l  $30(a0),d2
                add.l   d1,d2
                cmpi.l  #$00800000,d2
                bge.s   loc_1107c
                addi.l  #$01000000,d2
loc_1107C:
                cmpi.l  #$01800000,d2
                blt.s   loc_1108a
                subi.l  #$01000000,d2
loc_1108a:
                move.l  d2,$30(a0)
                swap    d2
                sub.w   ($FFFFFFA8).w,d2
loc_11094:
                cmpi.w  #$0080,d2
                bge.s   loc_110a0
                addi.w  #$0100,d2
                bra.s   loc_11094
loc_110a0:
                cmpi.w  #$0180,d2
                blt.s   loc_110ac
                subi.w  #$0100,d2
                bra.s   loc_110a0
loc_110ac:
                move.w  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)
loc_110b8:
                rts

; ======================================================================

loc_110ba:
                move.l  $30(a0),d2
                sub.l   ($FFFFFFA8).w,d2
loc_110C2:
                cmpi.l  #$800000,d2
                bge.s   loc_110d2
                addi.l  #$1000000,d2
                bra.s   loc_110c2

loc_110d2:
                cmpi.l  #$1800000,d2
                blt.s   loc_110e2
                subi.l  #$1000000,d2
                bra.s   loc_110d2
loc_110e2:
                move.l  d2,$20(a0)
                move.l  $2C(a0),d3
                add.l   d3,$24(a0)
                rts

; ======================================================================

loc_110f0:
                movea.w a0,a6                    ; Copy address to a6.
                moveq   #$F,d7                   ; Set to clear $40 bytes.
                moveq   #0,d6                    ; Clear d6.
loc_110F6:
                move.l  d6,(a6)+                 ; Clear 4 bytes.
                dbf     d7,loc_110f6             ; Repeat for $40 bytes.
                rts                              ; Return.

; ======================================================================

loc_110fe:                                       ; TODO - ClearObjectRAM?
                movem.l d5/a0,-(sp)              ; Store both register values onto the stack.
                move.w  #$1F,d5                  ; Set to loop $20 times.
                lea     ($FFFFC000).w,a0         ; Load object RAM into a0.
loc_1110A:
                bsr.s   loc_110f0                ; Clear $40 bytes of TODO.
                movea.w a6,a0                    ; Replace a0's address.
                dbf     d5,loc_1110a             ; Repeat $20 times, clear $800 bytes.
                movem.l (sp)+,d5/a0              ; Restore register values.
                rts                              ; Return.

; ======================================================================

loc_11118:
                movea.w a0,a6
                moveq   #$1E,d7
                moveq   #0,d6
loc_1111e:
                move.w  d6,(a6)+
                dbf     d7,loc_1111e
                rts

; ======================================================================
AnimateSprite:                                   ; $11126
                move.w  6(a0),d0                 ; Load the correct animation script.
                movea.l 8(a0),a1                 ; Load the animation table.
                movea.l (a1,d0.w),a1             ; Load the address of the animation script.
                subq.b  #1,$11(a0)               ; Subtract 1 from the animation frame duration.
                bpl.s   loc_11142                ; If there's still time left on the counter, branch.
                move.b  1(a1),$11(a0)            ; Refresh frame counter.
                addq.b  #1,$10(a0)               ; Get next animation.
loc_11142:
                moveq   #0,d0                    ; Clear d0.
                move.b  $10(a0),d0               ; Move current animation frame into d0.
                cmp.b   (a1),d0                  ; Has it hit the last animation?
                bcs.s   loc_11158                ; If it hasn't, branch.
                clr.b   $10(a0)                  ; Reset animation.
                moveq   #0,d0                    ; Clear d0.
                bset    #2,2(a0)                 ; Set the animation as 'reset'.
loc_11158:
                lsl.w   #1,d0                    ; Multiply by 2 for word tables.
                moveq   #-1,d1                   ; Set d1 to $FFFFFFFF.
                move.w  2(a1,d0.w),d1            ; Load next mappings frame.
                move.l  d1,$C(a0)                ; Write into the mappings frame.
                rts                              ; Return.

; ======================================================================
; Converts mappings into sprites readable by the VDP.
; ======================================================================
BuildSprites:                                  ; $11166
                btst    #1,2(a0)               ; Is the disable sprite update/display bit set?
                beq.s   BuildSprites_Main      ; If not, set to load the sprite.
                rts                            ; Return.

BuildSprites_Main:                             ; $11170
                movea.l $C(a0),a1              ; Load the mappings address into a1.
                moveq   #0,d1                  ; Clear d1.
                move.b  (a1)+,d1               ; Load the number of sprites to write, -1.
                move.b  (a1)+,4(a0)
                move.w  $24(a0),d2             ; Move the object's vertical position into d2.
                cmpi.w  #$180,d2               ; Is it higher than $180?
                bhi.s   loc_111d2              ; If it is, don't draw the sprite.
                move.w  $20(a0),d3             ; Move the object's horizontal position into d3.
loc_1118A:
                move.b  (a1)+,d0               ; Move the sprite's relative Y axis displacement into d0.
                ext.w   d0                     ; Extend to a word size.
                add.w   d2,d0                  ; Add the values together to get the first sprite word.
                move.w  d0,(a2)+               ; Write to the sprite table.
                move.b  (a1)+,(a2)+            ; Set sprite size.
                move.b  d6,(a2)+               ; Set link data.
                move.b  (a1)+,d0               ; Set priority, palette line, H/V flip and the upper 3 pattern bits.
                or.b    $13(a0),d0             ; TODO IMPORTANT - What does this do? Fix above when you find out!
                move.b  d0,(a2)+               ; Move to the sprite table.
                move.b  (a1)+,(a2)+            ; Write the pattern bits to the sprite table.
                move.b  (a1)+,d0               ; Load the relative X axis position into d0.
                tst.b   2(a0)                  ; Is the MSB of the object status bit set? TODO name?
                bpl.s   loc_111b0              ; If it isn't, branch.
                bchg    #3,-2(a2)              ; Flip the sprite horizontally.
                move.b  (a1),d0                ; Load the flipped relative x axis position into d0.
loc_111b0:
                addq.w  #1,a1                  ; Load the next set of mappings.
                ext.w   d0                     ; Extend to a word size.
                add.w   d3,d0                  ; Add the horizontal position with it to get the proper horizontal position.
                move.w  d0,d4                  ; Copy to d4.
                subi.w  #$41,d4                ; Subtract 65 pixels.
                cmpi.w  #$17F,d4               ; Is it lower than 383 pixels?
                bcs.s   loc_111ca              ; If it's less, branch.
                subq.w  #6,a2
                dbf     d1,loc_1118a           ; Repeat for the rest of the sprites.
                rts

loc_111ca:
                move.w  d0,(a2)+               ; Write the sprite's horizontal position.
                addq.b  #1,d6
                dbf     d1,loc_1118a           ; Repeat for the rest of the sprites.
loc_111d2:
                rts                            ; Return.

; ======================================================================

loc_111d4:
                lea     ($FFFFC000).w,a0       ; Load the start of object RAM into a0.
                bsr.w   LoadObjects            ; Run the code for one frame.
                bsr.w   loc_11254              ; Load the sprites.
                rts                            ; Return.

; ======================================================================
                                                 ; TODO
CheckObjectRAM:                                  ; $111E2
                tst.b   ($FFFFD24E).w            ; Is this mode the bonus stage?
                bne.s   CheckObjectRAM_BonusStage; If it is, branch.
                lea     ($FFFFC440).w,a0         ;
                bsr.w   LoadObjects              ;
                lea     ($FFFFC200).w,a0         ;
                moveq   #8,d0                    ; Check 9 entries.
loc_111F6:
                bsr.w   LoadObjects              ; Run object's code.
                lea     $40(a0),a0               ; Load next entry.
                dbf     d0,loc_111f6             ; Repeat for all the entries.
                lea     ($FFFFC480).w,a0         ;
                moveq   #$D,d0                   ; Check for $E entries.
loc_11208:
                bsr.w   LoadObjects              ; Run the object's code.
                lea     $40(a0),a0               ; Load the next entry.
                dbf     d0,loc_11208             ; Repeat for all the entries.
                lea     ($FFFFC000).w,a0         ; Load the start of object RAM.
                moveq   #7,d0                    ; Set to check for 8 entries,
loc_1121A:
                bsr.w   LoadObjects              ; Run object's code.
                lea     $40(a0),a0               ; Load the next entry.
                dbf     d0,loc_1121a             ; Repeat for the other entries.
                bra.s   loc_11254                ; TODO

CheckObjectRAM_BonusStage:                       ; TODO finish this shit.
                lea     ($FFFFC580).w,a0
                bsr.w   LoadObjects
                lea     ($FFFFC040).w,a0
                moveq   #$14,d0
loc_11236:
                bsr.w   LoadObjects
                lea     $40(a0),a0
                dbf     d0,loc_11236
                lea     ($FFFFC5C0).w,a0
                moveq   #3,d0
loc_11248:
                bsr.w   LoadObjects
                lea     $40(a0),a0
                dbf     d0,loc_11248

loc_11254:                                       ; TODO - objects?
                move.w  #$F550,($FFFFD000).w     ; Load the sprite table buffer address to $D000.
                move.w  #1,($FFFFD002).w         ; Set link data to 1.
                lea     ($FFFFC000).w,a0         ; Load the start of object RAM.
                moveq   #$1F,d7                  ; Set to test all $20 object entries.
loc_11266:
                move.w  d7,-(sp)                 ; Push the loop counter value onto the stack.
                tst.w   (a0)                     ; Check the byte: Is there an object ID?
                beq.s   loc_11280                ; If there isn't, branch.
                movea.w ($FFFFD000).w,a2         ; Load the start of the sprite table to a2.
                move.w  ($FFFFD002).w,d6         ; Load link data value into d6.
                bsr.w   BuildSprites             ; Convert the mappings into sprites, stored in a2.
                move.w  d6,($FFFFD002).w         ; Restore linking value.
                move.w  a2,($FFFFD000).w         ; Restore sprite table address.
loc_11280:
                lea     $40(a0),a0               ; Load the next entry.
                move.w  (sp)+,d7                 ; Restore loop counter value.
                dbf     d7,loc_11266             ; Repeat for the rest of the objects.
                movea.w ($FFFFD000).w,a2         ; Load the start of the sprite table.
                cmpa.w  #$F550,a2                ; TODO WTF is this shit.
                beq.s   loc_1129a
                clr.b   -5(a2)
                rts                              ; Return.

loc_1129a:
                clr.l   (a2)
loc_1129c:
                rts

; ======================================================================

LoadObjects:                                     ; $1129E
                move.w  d0,-(sp)                 ; Store repeat times to the stack.
                move.w  (a0),d0                  ; Move the object's entry into d0.
                beq.s   loc_112ac                ; If there's no entry to be loaded, branch.
                andi.w  #$7FFC,d0                ; Get the 2nd byte and keep within a multiple of 4.
                jsr     ObjectsList(pc,d0.w)     ; Run object's code.
loc_112ac:
                move.w  (sp)+,d0                 ; Restore repeat times.
                rts                              ; Return.

; ----------------------------------------------------------------------
         ; TODO OBJECT
ObjectsList:                                     ; $112B0
                bra.w   loc_1129c                ; $0 - Null.
                bra.w   loc_1452e                ; $4
                bra.w   loc_1483e                ; $8 - Chirp.
                bra.w   loc_13e70                ;
                bra.w   loc_14ec6                ;
                bra.w   loc_15d58                ; $14 - Iggy.
                bra.w   loc_16312                ; $18 - Gleaming eyes in the catflap.
                bra.w   loc_16422                ; $1C -
                bra.w   loc_16456     ;
                bra.w   loc_164ae
                bra.w   loc_164ec
                bra.w   loc_16648
                bra.w   loc_165ba     ;
                bra.w   loc_16600
                bra.w   loc_166c6
                bra.w   loc_16daa
                bra.w   loc_12172                ; $40 - Characters on the title screen.
                bra.w   loc_121cc                ; $44
                bra.w   loc_1223e                ; $48
                bra.w   loc_12476
                bra.w   loc_134bc
                bra.w   loc_144dc
                bra.w   loc_16dcc                ; $58 - Pause on


; ======================================================================

loc_1130c:
                move.l  ($FFFFD004).w,d0
                move.l  ($FFFFFFA8).w,d1
                add.l   d0,d1
                move.l  d1,($FFFFFFA8).w
                move.l  ($FFFFD008).w,d0
                move.l  ($FFFFFFA4).w,d1
                add.l   d0,d1
                move.l  d1,($FFFFFFA4).w
                rts

; ======================================================================

loc_1132a:                                       ; TODO
                lea     ($C00004).l,a6           ; Load VDP control port to a6.
                lea     ($C00000).l,a5           ; Load VDP data port to a5.
                move.w  ($FFFFFFA8).w,d7         ; Load the
                neg.w   d7                       ; Reverse sign polarity to scroll in the right direction.
                move.w  #$8F20,(a6)              ; Set VDP auto increment to $20.
                move.l  #$78400002,($C00004).l   ; Set VDP to VRAM write, $A840.
                moveq   #$17,d0
loc_1134c:
                move.w  d7,(a5)
                dbf     d0,loc_1134c
                move.l  #$78020002,($C00004).l   ; Set VDP to VRAM write, $B802 (HScroll).
                moveq   #$1B,d0
loc_1135e:
                move.w  d7,(a5)
                dbf     d0,loc_1135e
                move.w  #$8F02,(a6)              ; Set the VDP auto increment value into
                move.w  ($FFFFFFA4).w,d7         ; Load vertical scroll value into d7.
                move.l  #$40000010,($C00004).l   ; Set VDP to VSRAM write.
                move.w  d7,(a5)                  ; Set VDP mode.
                rts                              ; Return.

; ======================================================================
; Deals with the logic of the exit sign's rotating palette (which isn't
; actually a rotating palette, rather it's loading new tiles over them).
; ======================================================================
SignFrameLogic:                                  ; $1137A
                subq.b  #1,1(a0)                 ; Subtract 1 from the sign counter.
                bpl.s   loc_1138a                ; If it hasn't gone under 0, branch.
                move.b  1(a1),1(a0)              ; Otherwise, refresh the counter.
                addq.b  #1,0(a0)                 ; Load next sign frame.       bookmark $1137E
loc_1138A:
                moveq   #0,d0                    ; Clear d0.
                move.b  0(a0),d0                 ; Load the current frame into d0.
                cmp.b   (a1),d0                  ; Has it hit the last sign frame?
                bcs.s   loc_113a0                ; If it hasn't, branch.
                clr.b   0(a0)                    ; Reset sign frame back to 0.
                moveq   #0,d0                    ; Clear d0.
                move.b  #1,2(a0)                 ; Set TODO flag to 1.
loc_113a0:
                asl.w   #2,d0                    ; Multiply by 4 for longword tables.
                movea.l 2(a1,d0.w),a6            ; Load the address for the next sign frame.
                bsr.w   loc_10F70                ; Write to the screen.
                rts                              ; Return.

; ======================================================================
ClearBonusObjectRAM:                             ; $113AC
                lea     ($FFFFC800).w,a0         ; Load the bonus stage's object RAM into a0.
                move.w  #$DF,d0                  ; Set to clear $380 bytes.
loc_113B4:
                clr.l   (a0)+                    ; Clear 4 bytes of object RAM.
                dbf     d0,loc_113b4             ; Repeat for the rest of the allocated RAM.
                rts                              ; Return.

; ======================================================================

loc_113bc:
                clr.l   ($FFFFFFA8).w            ; Clear horizontal scroll value.
                clr.l   ($FFFFFFA4).w            ; Clear vertical scroll value.
                clr.l   ($FFFFD004).w
                clr.l   ($FFFFD008).w
                rts                              ; Return.

; ======================================================================
; Unused code.

loc_113CE:
                movem.w d4/d6-d7/a6,-(sp)
                lea     ($FFFFC800).w,a6
                lsl.w   #5,d6
                add.w   d7,d6
                move.b  d4,(a6,d6.w)
                movem.w (sp)+,d4/d6-d7/a6
                rts

; ======================================================================
; TODO - This makes no sense.
loc_113e4:
                bsr.s   ClearBonusObjectRAM
                lea     ($FFFFC840).w,a0
loc_113ea:
                moveq   #0,d7
                move.b  (a6)+,d7
                beq.s   loc_113fa
                bclr    #7,d7
                bne.s   loc_113fc
                adda.l  d7,a0
                bra.s   loc_113ea
loc_113fa:
                rts

loc_113fc:
                bclr    #6,d7
                bne.s   loc_1140e
                subq.b  #1,d7
loc_11404:
                move.b  #1,(a0)+
                dbf     d7,loc_11404
                bra.s   loc_113ea
loc_1140e:
                movea.w a0,a1
                subq.b  #1,d7
loc_11412:
                move.b  #1,(a1)
                lea     $20(a1),a1
                dbf     d7,loc_11412
                addq.l  #1,a0
                bra.s   loc_113ea

; ======================================================================

loc_11422:
                bsr.s   loc_113e4                ; TODO
                bsr.s   loc_1148a
                bsr.w   loc_119c0
                bsr.w   loc_1194c
                bsr.w   loc_11976
                bsr.w   loc_11b86
                bsr.s   loc_1143a
                rts

; ======================================================================

loc_1143a:
                lea     ($FFFFC800).w,a0
                moveq   #$1F,d0
loc_11440:
                move.b  #$C,(a0)+
                dbf     d0,loc_11440
                lea     ($FFFFCB40).w,a0
                moveq   #$3F,d0
loc_1144E:
                move.b  #$C,(a0)+
                dbf     d0,loc_1144e
                lea     ($FFFFC840).w,a0
                moveq   #$1F,d0
loc_1145C:
                tst.b   (a0)
                beq.s   loc_1146c
                move.b  #3,-$20(a0)
                move.b  #$E,-$40(a0)
loc_1146c:
                addq.l  #1,a0
                dbf     d0,loc_1145c
                lea     ($FFFFCB20).w,a0
                moveq   #$1F,d0
loc_11478:
                tst.b   (a0)
                beq.s   loc_11482
                move.b  #$D,$20(a0)
loc_11482:
                addq.l #1,a0
                dbf     d0,loc_11478
                rts

; ======================================================================

loc_1148a:
                lea     ($FFFFD82E).w,a0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #0,d4                    ; Set to load the door mappings.
                moveq   #0,d0
                bsr.w   loc_11562                ; Load into VRAM.
                lea     ($FFFFD830).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w   loc_11562
                lea     ($FFFFD832).w,a0
                moveq   #0,d0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)+
                moveq   #1,d4
                bsr.w   loc_11562
                lea     ($FFFFD834).w,a0
                move.b  (a6),(a0)+
                move.b  1(a6),(a0)
                moveq   #2,d4
                moveq   #0,d0
                bsr.w   loc_11562
                moveq   #3,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114e0
                subq.b  #1,d0
                bsr.w   loc_11562
loc_114e0:
                moveq   #4,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114ec
                subq.b  #1,d0
                bsr.s   loc_11562
loc_114ec:
                moveq   #5,d4
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_114f8
                subq.b  #1,d0
                bsr.s   loc_11562
loc_114f8:
                lea     ($FFFFC200).w,a0
                moveq   #5,d0
loc_114FE:
                move.w  #4,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                lea     $40(a0),a0
                dbf     d0,loc_114fe
                lea     ($FFFFC480).w,a0
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_1153a
                add.b   d0,($FFFFD883).w
                subq.b  #1,d0
loc_11522:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                clr.b   $3A(a0)
                lea     $40(a0),a0
                dbf     d0,loc_11522
loc_1153a:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_11560
                add.b   d0,($FFFFD883).w
                subq.b  #1,d0
loc_11546:
                move.w  #8,(a0)
                move.b  (a6)+,$3E(a0)
                move.b  (a6)+,$3F(a0)
                move.b  #1,$3A(a0)
                lea     $40(a0),a0
                dbf     d0,loc_11546
loc_11560:
                rts

; ======================================================================

loc_11562:
                moveq   #0,d7                    ; Clear d7.
                moveq   #0,d6                    ; Clear d6.
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                movem.l d0/d4/a6,-(sp)           ; Push the registers onto the stack.
                bsr.w   loc_11b16                ; Dump mappings to Plane A from an address in RAM.
                movem.l (sp)+,d0/d4/a6           ; Restore register values
                dbf     d0,loc_11562             ;
                rts                              ; Return.

; ======================================================================


loc_1157c:
                movem.l d6-d7/a1,-(sp)           ; Store register values.
                cmpi.w  #$80,d7
                bge.s   loc_1158a
                addi.w  #$100,d7
loc_1158a:
                cmpi.w  #$180,d7
                blt.s   loc_11594
                subi.w  #$100,d7
loc_11594:
                lea     ($FFFFC800).w,a1
                move.l  #$0000FFFF,d4
                and.l   d4,d7
                and.l   d4,d6
                subi.w  #$80,d7
                subi.w  #$80,d6
                lsr.w   #3,d7
                lsr.w   #3,d6
                lsl.w   #5,d6
                adda.l  d7,a1
                adda.l  d6,a1
                move.b  (a1),d4
                andi.b  #$F,d4
                movem.l (sp)+,d6-d7/a1           ; Restore register values.
                rts                              ; Return.

; ======================================================================


loc_115c0:
                add.w   $30(a0),d7
                add.w   $24(a0),d6
                cmpi.w  #$80,d7
                bge.s   loc_115d2
                addi.w  #$100,d7
loc_115d2:
                cmpi.w  #$180,d7
                blt.s   loc_115DC
                subi.w  #$100,d7
loc_115DC:
                movem.l d6-d7,-(sp)
                lea     ($FFFFC800).w,a1
                move.l  #$0000FFFF,d4
                and.l   d4,d7
                and.l   d4,d6
                subi.w  #$80,d7
                subi.w  #$80,d6
                lsr.w   #3,d7
                lsr.w   #3,d6
                lsl.w   #5,d6
                adda.l  d7,a1
                adda.l  d6,a1
                move.b  (a1),d4
                movem.l (sp)+,d6-d7
                rts

; ======================================================================

loc_11608:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_1162a
                subq.w  #1,d0
loc_11610:
                moveq   #0,d7
                moveq   #0,d6
                lea     ($FFFFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                dbf     d0,loc_11610
loc_1162a:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_11650
                subq.w  #1,d0
loc_11632:
                moveq   #0,d7
                moveq   #0,d6
                lea     ($FFFFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #7,(a0)
                bset    #6,(a0)
                dbf     d0,loc_11632
loc_11650:
                moveq   #0,d0
                move.b  (a6)+,d0
                beq.s   loc_11672
                subq.w  #1,d0
loc_11658:
                moveq   #0,d7
                moveq   #0,d6
                lea     ($FFFFC800).w,a0
                move.b  (a6)+,d7
                move.b  (a6)+,d6
                adda.l  d7,a0
                lsl.w   #5,d6
                adda.l  d6,a0
                bset    #5,(a0)
                dbf     d0,loc_11658
loc_11672:
                rts

; ======================================================================

loc_11674:
                andi.w  #$00FF,d7
                andi.w  #$00FF,d6
                lsl.w   #3,d7
                lsl.w   #3,d6
                addi.w  #$0080,d7
                addi.w  #$0080,d6
                rts                              ; Return.

; ======================================================================

loc_1168a:
                tst.b   ($FFFFD2A5).w
                bne.s   loc_116bc
                lea     ($FFFFD266).w,a2
                lea     ($FFFFD882).w,a1
                moveq   #3,d0
                move.w  #4,ccr
loc_1169E:
                abcd    -(a2),-(a1)
                dbf     d0,loc_1169e
                bsr.w   loc_11dc2
                move.l  ($FFFFD87E).w,d0
                move.l  ($FFFFCC00).w,d1
                cmp.l   d0,d1
                bge.s   loc_116bc
                move.l  d0,($FFFFCC00).w
                bsr.w   loc_11dd4
loc_116bc:
                rts

; ======================================================================
; Sets the logic for the in-game timer you see at the end of rounds.
; NOTE - While the timer has checks to stop the centisecond and second
; timers from overflowing past 60, the minute timer doesn't, meaning you
; can overflow the whole timer back to 0 if you go over 99:59.59.
; ======================================================================
TimerCounter:                                    ; $116BE
                moveq   #1,d1                    ; Set value to increment by.
                move.b  ($FFFFD88A).w,d0         ; Load the centisecond timer value to d0.
                addi.b  #0,d0                    ; Clear the extend ccr bit.
                abcd    d1,d0                    ; Add by a centisecond.
                move.b  d0,($FFFFD88A).w         ; Update centisecond timer.
                cmpi.b  #$60,d0                  ; Has it hit 60 or over?
                bcs.s   loc_116fe                ; If it hasn't yet, branch.
                clr.b   ($FFFFD88A).w            ; Set the centisecond time to 0.
                move.b  ($FFFFD889).w,d0         ; Load the second timer value to d0.
                addi.b  #0,d0                    ; Clear the extend ccr bit.
                abcd    d1,d0                    ; Increment by a second.
                move.b  d0,($FFFFD889).w         ; Update second timer.
                cmpi.b  #$60,d0                  ; Has it hit 60 seconds?
                bcs.s   loc_116fe                ; If it hasn't, branch.
                clr.b   ($FFFFD889).w            ; Clear centisecond timer.
                move.b  ($FFFFD888).w,d0         ; Load the minute/second segment of the timer.
                addi.b  #0,d0                    ; Clear the extend bit.
                abcd    d1,d0                    ; Add by a minute.
                move.b  d0,($FFFFD888).w         ; Update the minute timer.
loc_116fe:
                rts                              ; Return.

; ======================================================================

loc_11700:
                lea     ($FFFFD82E).w,a0
                move.w  (a0)+,($FFFFC47E).w
                move.w  (a0),($FFFFC3BE).w
                move.w  (a0)+,($FFFFC6BE).w
                move.w  (a0),($FFFFC3FE).w
                move.w  (a0),($FFFFC6FE).w
                move.w  (a0),($FFFFC43E).w
                move.w  (a0),($FFFFC73E).w
                rts

; ======================================================================

loc_11722:
                lea     ($FFFFC480).w,a3
                lea     ($FFFFDE00).w,a4
                bra.s   loc_11734

; ======================================================================

loc_1172c:
                lea     ($FFFFDE00).w,a3
                lea     ($FFFFC480).w,a4
loc_11734:
                move.w  #$7F,d0
loc_11738:
                move.l  (a3)+,(a4)+
                dbf     d0,loc_11738
                rts

; ======================================================================
loc_11740:
                moveq   #0,d0
                move.b  ($FFFFD280).w,d0
                addq.b  #1,d0
                andi.b  #$F,d0
                move.b  d0,($FFFFD280).w
                lsr.w   #2,d0
                lsl.w   #1,d0
                move.w  loc_1175c(pc,d0.w),($FFFFD884).w
                rts

; ----------------------------------------------------------------------

loc_1175c:
                dc.w    $8100
                dc.w    $8000
                dc.w    $FFFF
                dc.w    $8000

; ======================================================================
; Set to reload table art after d7 levels.
loc_11764:
                moveq   #0,d0                    ; Clear d0.
                move.b  ($FFFFD82D).w,d0         ; Load the level number into d0.
loc_1176A:
                cmp.b   d7,d0                    ; Is the level number lower than 24 ($18)?
                bcs.s   loc_11772                ; If it is, branch.
                sub.b   d7,d0                    ; Subtract the level number by 24.
                bra.s   loc_1176a                ; Start again.
loc_11772:
                rts                              ; Return.

; ======================================================================

loc_11774:
                moveq   #0,d0                    ; Clear d0.
                move.b  ($FFFFD82D).w,d0         ; Move the level number value into d0.
loc_1177A:
                cmp.b   d7,d0                    ;
                bls.s   loc_11782                ;
                sub.b   d7,d0                    ;
                bra.s   loc_1177a                ;

loc_11782:
                rts                              ; Return.

; ======================================================================

loc_11784:
                lea     ($FFFFF7E0).w,a0         ; Load the palette buffer into a0.
                lea     ($FFFFF860).w,a1         ; Load the target palette RAM space into a1.
                moveq   #$1F,d0                  ; Set to overwrite all $40 palettes.
loc_1178E:
                move.l  (a0)+,(a1)+              ; Write the first two palettes into the target palette space.
                dbf     d0,loc_1178e             ; Repeat for the rest.
                move.w  #$FFC0,($FFFFFFAC).w     ; TODO
loc_1179A:
                move.w  ($FFFFFFAC).w,d2         ; ''
                addq.w  #2,d2
                beq.s   loc_117be
                cmpi.w  #$40,d2
                ble.s   loc_117aa
                subq.w  #2,d2
loc_117aa:
                move.w  d2,($FFFFFFAC).w
                moveq   #-$40,d3
                jsr     ($FFFFFBA8).w            ; TODO
                jsr     ($FFFFFB0C).w            ; ''
                jsr     ($FFFFFB6C).w            ;
                bra.s   loc_1179a                ;
loc_117be:
                rts                              ; Return.

; ======================================================================

loc_117c0:
                tst.w   (a1)                     ; Is there an object in the RAM space?
                beq.w   loc_11874                ; If there isn't, branch.
                moveq   #0,d0                    ; Clear d0.
                moveq   #0,d1                    ; Clear d1.
                move.b  4(a0),d0                 ; Load TODO into d0.
                cmpi.b  #$FF,d0
                beq.w   loc_11874
                move.b  4(a1),d1                 ; Move TODO into d1.
                cmpi.b  #$FF,d1
                beq.w   loc_11874
                lsl.w   #3,d0
                lsl.w   #3,d1
                move.w  $20(a0),d3               ; Move the object's horizontal position into d3.
                lea     loc_11878(pc),a6         ; Load the TODO address into a6.
                add.w   (a6,d0.w),d3
                move.w  d3,d2
                addq.l  #2,a6
                add.w   (a6,d0.w),d3
                move.w  $20(a1),d5               ; Move TODO's horizontal position into d5.
                add.w   loc_11878(pc,d1.w),d5
                move.w  d5,d4
                add.w   loc_1187a(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   loc_11812
                cmp.w   d3,d4
                bgt.s   loc_11812
                bra.s   loc_1182e

loc_11812:
                cmp.w   d2,d5
                blt.s   loc_1181c
                cmp.w   d3,d5
                bgt.s   loc_1181c
                bra.s   loc_1182e

loc_1181c:
                cmp.w   d4,d2
                blt.s   loc_11826
                cmp.w   d5,d2
                bgt.s   loc_11826
                bra.s   loc_1182e

loc_11826:
                cmp.w   d4,d3
                blt.s   loc_11874
                cmp.w   d5,d3
                bgt.s   loc_11874
loc_1182e:
                move.w  $24(a0),d3
                add.w   loc_1187c(pc,d0.w),d3
                move.w  d3,d2
                add.w   loc_1187e(pc,d0.w),d3
                move.w  $24(a1),d5
                add.w   loc_1187c(pc,d1.w),d5
                move.w  d5,d4
                add.w   loc_1187e(pc,d1.w),d5
                cmp.w   d2,d4
                blt.s   loc_11854
                cmp.w   d3,d4
                bgt.s   loc_11854
                bra.s   loc_11870

loc_11854:
                cmp.w   d2,d5
                blt.s   loc_1185e
                cmp.w   d3,d5
                bgt.s   loc_1185e
                bra.s   loc_11870

loc_1185e:
                cmp.w   d4,d2
                blt.s   loc_11868
                cmp.w   d5,d2
                bgt.s   loc_11868
                bra.s   loc_11870

loc_11868:
                cmp.w   d4,d3
                blt.s   loc_11874
                cmp.w   d5,d3
                bgt.s   loc_11874
loc_11870:
                moveq   #1,d0
                rts

loc_11874:
                moveq   #0,d0
                rts

; ======================================================================
loc_11878:	dc.w $FFFF
loc_1187A:	dc.w 2
loc_1187C:	dc.w $FFEE
loc_1187E:	dc.w $12
		dc.w $FFFF
		dc.w 2
		dc.w $FFF0
		dc.w $10
		dc.w $FFFC
		dc.w 8
		dc.w $FFF2
		dc.w $C
		dc.w $FFF9
		dc.w $E
		dc.w $FFF4
		dc.w $C
		dc.w $FFFC
		dc.w 8
		dc.w $FFFA
		dc.w 6
		dc.w $FFFF
		dc.w 2
		dc.w $FFEE
		dc.w $12
		dc.w $FFFE
		dc.w 4
		dc.w $FFF6
		dc.w 4
		dc.w $FFFC
		dc.w 8
		dc.w $FFF9
		dc.w 7
		dc.w $FFFF
		dc.w 2
		dc.w $FFFA
		dc.w 6
		dc.w $FFFC
		dc.w 8
		dc.w $FFF6
		dc.w $A
		dc.w $FFFC
		dc.w 8
		dc.w $FFFC
		dc.w 2
		dc.w $FFFC
		dc.w 8
		dc.w 3
		dc.w 2
		dc.w $FFFC
		dc.w 2
		dc.w $FFFC
		dc.w 8
		dc.w 4
		dc.w 2
		dc.w $FFFC
		dc.w 8
		dc.w $FFFF
		dc.w 2
		dc.w $FFFD
		dc.w 6
		dc.w $FFFE
		dc.w 4
		dc.w 0
		dc.w 8
		dc.w $FFF8
		dc.w $10
		dc.w $FFF0
		dc.w $10
		dc.w $FFF8
		dc.w $10
		dc.w $FFF0
		dc.w 2
		dc.w $FFFF
		dc.w 2
		dc.w $FFEE
		dc.w $E

; ======================================================================

loc_11910:
                lsl.w   #1,d4                    ; Multiply by 2 for word tables.
                move.w  loc_1191c(pc,d4.w),d4    ; Load the correct map tile.
                bsr.w   loc_10F3e                ; Write to the VDP.
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_1191c:
                dc.w    $220D
                dc.w    $2206
                dc.w    $2207
                dc.w    $2208
                dc.w    $2209
                dc.w    $220A
                dc.w    $220B
                dc.w    $220C
                dc.w    $220D
                dc.w    $220E
                dc.w    $220F
                dc.w    $2210
                dc.w    $2211
                dc.w    $2212
                dc.w    $2213
                dc.w    $2214

; ===============================================================

loc_1193c:
                lsl.w   #1,d4
                movea.l ($FFFFD800).w,a1
                move.w  (a1,d4.w),d4
                bsr.w   loc_10F3e
                rts

; ======================================================================
; Loads mappings from a pointer, and writes them onto an area of Plane B
; (pointer writes roof tiles onto the screen).
; ======================================================================

loc_1194c:
                moveq   #0,d5                    ; Clear d5.
                move.w  #$E000,d5                ; Set to write to the Plane B VRAM space.
                moveq   #7,d0                    ; Set to repeat 8 times.
loc_11954:
                move.w  d0,-(sp)                 ; Push d0's value onto the stack.
                bsr.s   loc_11962                ; Load the mappings and write onto the screen.
                move.w  (sp)+,d0                 ; Restore the register's value.
                addq.w  #8,d5                    ; Add to the VRAM address to load the next set of tiles to dump.
                dbf     d0,loc_11954             ; Repeat 7 more times.
                rts                              ; Return.

loc_11962:
                lea     ($FFFFD808).w,a6         ; Load the correct roof tile mappings table pointers.
                movea.l (a6),a6                  ; Load the appropriate pointer from the table.
                moveq   #3,d7                    ; Set to write 4 tiles across.
                moveq   #1,d6                    ; Set to write 2 tiles down.
                move.l  d5,-(sp)                 ; Store VRAM address value into d5.
                bsr.w   PlaneMaptoVRAM           ; Write onto the screen.
                move.l  (sp)+,d5                 ; Restore VRAM address value.
                rts                              ; Return.

; ======================================================================
; Writes mappings from a pointer stored in RAM to a specific part of
; Plane B (pointer writes ground tiles onto the screen).
; ======================================================================
loc_11976:
                moveq   #0,d5                    ; Clear d5.
                move.w  #$E680,d5                ; Set to load a specific part of Plane B.
                moveq   #7,d0                    ; Set to load 8 groups of 4x2 tiles.
loc_1197E:
                move.w  d0,-(sp)                 ; Store loop value onto the stack.
                bsr.s   loc_1198c                ; Dump mappings from an address to Plane B.
                move.w  (sp)+,d0                 ; Restore register values.
                addq.w  #8,d5                    ; Add to the VRAM address to dump next block.
                dbf     d0,loc_1197e             ; Repeat for the rest of the blocks.
                rts                              ; Return.

loc_1198c:
                lea     ($FFFFD80C).w,a6         ; Load the correct ground tile mappings table pointers.
                movea.l (a6),a6                  ; Load the appropriate pointer from the table.
                moveq   #3,d7                    ; Set to write 4 tiles across.
                moveq   #1,d6                    ; Set to write 2 tiles down.
                move.l  d5,-(sp)                 ; Store VRAM address to the stack.
                bsr.w   PlaneMaptoVRAM           ; Write onto the screen.
                move.l  (sp)+,d5                 ; Restore VRAM address.
                rts                              ; Return.

; ======================================================================
; Unused routine which writes a single repeating BG tile to Plane B.
; Contains noticable differences when compared to the other similar
; routines.
; ======================================================================
loc_119a0
                move.l  #$60800003,($C00004).l   ; Set to VRAM write, to $E080.
                movea.l ($FFFFD804).w,a0         ; Load the specific mappings table pointer into a0.
                move.w  (a0),d1                  ; Load the singular tile into d1.
                move.w  #$2FF,d0                 ; Set to repeat $300 times.
loc_119b4:
                move.w  d1,($C00000).l           ; Write to the VDP.
                dbf     d0,loc_119b4             ; Repeat until $300 BG tiles have been drawn.
                rts                              ; Return.

; ======================================================================

loc_119c0:
                lea     ($FFFFC840).w,a0
                moveq   #0,d1
                moveq   #0,d2
                moveq   #0,d6
                move.w  #$E080,d6
                move.w  d6,d5
                move.w  #$2FF,d0
loc_119D4:
                moveq   #0,d4
                moveq   #0,d5
                move.w  d6,d5
                tst.b   (a0)
                beq.w   loc_119f4
                andi.w  #$1F,d2
                beq.w   loc_11a34
                cmpi.w  #$1F,d2
                beq.w   loc_11a66
                bra.w   loc_11a98
loc_119f4:
                andi.w  #$1F,d2
                beq.w   loc_11aca
                bra.w   loc_11af0

loc_11a00:
                addq.l  #1,a0
                addq.w  #1,d1
                move.w  d1,d2
                addq.w  #2,d6
                dbf     d0,loc_119d4
                lea     ($FFFFC840).w,a0
                moveq   #0,d5
                move.w  #$E080,d5
                moveq   #$1F,d0
loc_11A18:
                tst.b   (a0)+
                bne.s   loc_11a2c
                move.w  #3,d4
                movem.l d5/a0,-(sp)
                bsr.w   loc_1193c
                movem.l (sp)+,d5/a0
loc_11a2c:
                addq.w  #2,d5
                dbf     d0,loc_11a18
                rts

loc_11a34:
                tst.b   -$20(a0)
                beq.s   loc_11a3e
                bset    #0,d4
loc_11a3e:
                tst.b   $20(a0)
                beq.s   loc_11a48
                bset    #1,d4
loc_11a48:
                tst.b   $1F(a0)
                beq.s   loc_11a52
                bset    #2,d4
loc_11a52:
                tst.b   1(a0)
                beq.s   loc_11a5c
                bset    #3,d4
loc_11a5c:
                move.b  d4,(a0)
                bsr.w   loc_11910
                bra.w   loc_11a00

loc_11a66:
                tst.b   -$20(a0)
                beq.s   loc_11a70
                bset    #0,d4
loc_11a70:
                tst.b   $20(a0)
                beq.s   loc_11a7a
                bset    #1,d4
loc_11a7a:
                tst.b   -1(a0)
                beq.s   loc_11a84
                bset    #2,d4
loc_11a84:
                tst.b   -$1F(a0)
                beq.s   loc_11a8e
                bset    #3,d4
loc_11a8e:
                move.b  d4,(a0)
                bsr.w   loc_11910
                bra.w   loc_11a00

loc_11a98:
                tst.b   -$20(a0)
                beq.s   loc_11aa2
                bset    #0,d4
loc_11aa2:
                tst.b   $20(a0)
                beq.s   loc_11aac
                bset    #1,d4
loc_11aac:
                tst.b   -1(a0)
                beq.s   loc_11ab6
                bset    #2,d4
loc_11ab6:
                tst.b   1(a0)
                beq.s   loc_11ac0
                bset    #3,d4
loc_11ac0:
                move.b  d4,(a0)
                bsr.w   loc_11910
                bra.w   loc_11a00

loc_11aca:
                tst.b   -$20(a0)
                beq.s   loc_11ad4
                bset    #0,d4
loc_11ad4:
                tst.b   -1(a0)
                beq.s   loc_11ade
                bset    #1,d4
loc_11ade:
                tst.b   $1F(a0)
                beq.s   loc_11ae8
                bset    #2,d4
loc_11ae8:
                bsr.w   loc_1193c
                bra.w   loc_11a00
loc_11af0:
                tst.b   -$20(a0)
                beq.s   loc_11afa
                bset    #0,d4
loc_11afa:
                tst.b   -$21(a0)
                beq.s   loc_11b04
                bset    #1,d4
loc_11b04:
                tst.b   -1(a0)
                beq.s   loc_11b0e
                bset    #2,d4
loc_11b0e:
                bsr.w   loc_1193c
                bra.w   loc_11a00

; ======================================================================

loc_11b16:
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C000,d5                ; Set to write to a region of Plane A.
                bsr.w   loc_10F24                ; Get a VDP command in d5.
                lsl.w   #2,d4                    ; Multiply by 4 for 4 byte entry tables.
                move.w  loc_11b3c(pc,d4.w),d7    ; Get amount of horizontal tiles to write.
                move.w  loc_11b3c+2(pc,d4.w),d6  ; Get amount of vertical tiles to write.
                lsr.w   #1,d4                    ; Divide by 2 for 2 byte entry tables.
                moveq   #-1,d2                   ; Set d2 to $FFFFFFFF (for address).
                move.w  loc_11b54(pc,d4.w),d2    ; Overwrite lower word with RAM address.
                movea.l d2,a6                    ; Move the RAM address into a6.
                movea.l (a6),a6                  ; Move the mappings address in that RAM address into a6.
                bsr.w   loc_10F70                ; Write onto the screen.
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_11b3c:
                dc.w    $0002
                dc.w    $0002

                dc.w    $0001
                dc.w    $0001

                dc.w    $0001
                dc.w    $0002

                dc.w    $0001
                dc.w    $0002

                dc.w    $0004
                dc.w    $0002

                dc.w    $0003
                dc.w    $0003

loc_11b54:
                dc.w    $FFFFD81C&$FFFF
                dc.w    $FFFFD820&$FFFF
                dc.w    $FFFFD824&$FFFF
                dc.w    $FFFFD810&$FFFF
                dc.w    $FFFFD814&$FFFF
                dc.w    $FFFFD818&$FFFF

; ======================================================================

loc_11b60:
                moveq   #0,d7                    ; Clear d7.
                moveq   #0,d6                    ; Clear d6.
                moveq   #0,d5                    ; Clear d5.
                move.b  ($FFFFD82E).w,d7         ; Load the door's X coordinate to d7.
                move.b  ($FFFFD82F).w,d6         ; Load the door's Y coordinate to d6.
                move.w  #$E000,d5                ; Set to write to plane B's nametable.
                bsr.w   loc_10F24                ; Get a VDP command in d5.
                moveq   #2,d7                    ; Set to draw three tiles across.
                moveq   #2,d6                    ; Set to draw three tiles down.
                lea     OpenDoorMaps,a6          ; Load the open door plane mappings into a6.
                bsr.w   loc_10F70                ; Write onto the screen.
                rts                              ; Return.

;  =====================================================================
loc_11b86:
                lea     ($FFFFD82E).w,a0         ; Load the door's X and Y coordinate word.
                moveq   #0,d7                    ; Clear d7.
                moveq   #0,d6                    ; Clear d6.
                moveq   #0,d5                    ; Clear d5.
                move.b  0(a0),d7                  ; Load the door's X-coordinates into d7.
                move.b  1(a0),d6                 ; Load the door's Y-coordinates into d6.
                subq.b  #1,d6                    ; Set to load above the door.
                move.w  #$E000,d5                ; Set to write in the Plane B screen space.
                bsr.w   loc_10F24                ; Output a VRAM address into d5.
                moveq   #2,d7                    ; Set to write 3 tiles across.
                moveq   #0,d6                    ; Set to write 1 tile down.
                lea     FlickySignMaps,a6        ; Load the Flicky sign mappings into a6.
                btst    #7,($A10001).l           ; Is the console a domestic MD?
                beq.s   loc_11bbc                ; If it is, branch.
                lea     ExitSignMaps,a6          ; Load the exit sign mappings into a6.
loc_11bbc:
                bsr.w   loc_10F70                ; Write onto the screen.
                rts                              ; Return.

; ======================================================================
; Unused?
loc_11bc2
                moveq   #4,d0
                moveq   #5,d3
loc_11BC6:
                move.w  loc_11bdc(pc,d0.w),d1
                move.w  loc_11bdc+2(pc,d0.w),d4
                lsr.w   #1,d0                    ; Set to skip every 2 bytes.
                moveq   #-1,d2                   ; Set d2 to $FFFFFFFF.
                move.w  loc_11bf8(pc,d0.w),d2    ; Overwrite lower word with RAM address.
                lsl.w   #1,d0                    ; Set to skip every 4 bytes.
                movea.l d2,a0                    ; Set as address.
                bra.s   loc_11c06                ;

; ----------------------------------------------------------------------

loc_11bdc:
                dc.w    $0000
                dc.w    $0000

                dc.w    $0000
                dc.w    $0000

                dc.w    $0001
                dc.w    $0001

                dc.w    $0000
                dc.w    $0002

                dc.w    $0013
                dc.w    $0003

                dc.w    $0007
                dc.w    $0004

                dc.w    $0007
                dc.w    $0005
                
loc_11BF8:
                dc.w    $0000, $d82e
                dc.w    $d830, $d834
                dc.w    $d836, $d85e
                dc.w    $d86e

; ======================================================================

loc_11C06:
                tst.b   $2(a0)
                beq.s   loc_11C24


loc_11c0c:
                moveq   #0,d7                    ; Clear d7.
                moveq   #0,d6                    ; Clear d6.
                move.b  0(a0),d7
                move.b  1(a0),d6
                movem.w d0-d4/a0,-(sp)           ; Store used registers to the stack.
                bsr.w   loc_11b16                ; Dump mappings to Plane A from an address in RAM.
                movem.w (sp)+,d0-d4/a0           ; Restore register values.
loc_11C24:
                addq.l  #4,a0
                dbf     d1,loc_11c06
                addq.w  #4,d0
                dbf     d3,loc_11bc6
                tst.b   ($FFFFD830).w
                beq.s   loc_11c3a
                bsr.w   loc_11b86
loc_11c3a:
                rts

; ======================================================================

loc_11c3c:
                lea     ($FFFFD258).w,a0         ; Load a segment of the door variables.
                lea     Jap_ExitSignMap(pc),a1   ; Load the 'FLICKY' sign maps table exclusive to Japan.
                btst    #7,($A10001).l           ; Is the console a domestic MD?
                beq.s   loc_11c52                ; If it is, branch.
                lea     Eng_ExitSignMap(pc),a1   ; Otherwise, load the 'EXIT' sign maps table seen elsewhere.
loc_11c52:
                moveq   #0,d7                    ; Clear d7.
                moveq   #0,d6                    ; Clear d6.
                moveq   #0,d5                    ; Clear d5.
                move.b  ($FFFFD82E).w,d7         ; Load the exit door's X axis grid coordinate.
                move.b  ($FFFFD82F).w,d6         ; Load the exit door's Y axis grid coordinate.
                subq.b  #1,d6                    ; Set to load above the door.
                move.w  #$E000,d5                ; Set to draw to Plane B, at positions d7 and d6.
                bsr.w   loc_10F24                ; Convert d5's VRAM address into a proper VDP command.
                moveq   #2,d7                    ; Set to draw 3 tiles across...
                moveq   #0,d6                    ; ...And 1 tile down.
                bsr.w   SignFrameLogic           ; Run sign logic and draw to the screen.
                rts                              ; Return.

; ----------------------------------------------------------------------

Jap_ExitSignMap:                                 ; $11C74
                dc.b    $04, $04                 ; Number of sign frame entries, and the number of frames until that new entry is loaded.
                dc.l    FlickySignMaps           ; White.
                dc.l    FlickySignMaps+$C        ; Red.
                dc.l    FlickySignMaps+6         ; Black.
                dc.l    FlickySignMaps+$C        ; Red.

; ----------------------------------------------------------------------

Eng_ExitSignMap:                                 ; $11C86
                dc.b    $04, $04                 ; Number of sign frame entries, and the number of frames until that new entry is loaded.
                dc.l    ExitSignMaps             ; White.
                dc.l    ExitSignMaps+$C          ; Red.
                dc.l    ExitSignMaps+6           ; Black.
                dc.l    ExitSignMaps+$C          ; Red.

; ----------------------------------------------------------------------

ExitSignMaps:                                    ; $11C98
                dc.w    $0693, $0694, $0695      ; White 'EXIT' text.
                dc.w    $0696, $0697, $0698      ; Black 'EXIT' text.
                dc.w    $0699, $069A, $069B      ; Red 'EXIT' text.

; ======================================================================

loc_11caa:
                lea     loc_11cb8(pc),a1
                bsr.w   loc_11d38
                bsr.w   TimerCounter             ; Update timer.
                rts

; ----------------------------------------------------------------------

loc_11cb8: 
                dc.b    $04, $0F
                dc.l    loc_1A490
                dc.l    loc_1A46C
                dc.l    loc_1A47E        ; TODO PLANE MAPS
                dc.l    loc_1A490

; ======================================================================

loc_11cca:
                lea     loc_11cd4(pc),a1
                jmp     loc_11d38

; ----------------------------------------------------------------------

loc_11cd4:
                dc.b    $04, $02
                dc.l    DoorMaps
                dc.l    loc_1A490            ; TODO PLANE MAPS
                dc.l    loc_1A47E
                dc.l    loc_1A46C

; ======================================================================


loc_11ce6:
                lea     loc_11cf0(pc),a1
                jmp     loc_11d38

; ----------------------------------------------------------------------

loc_11cf0:
                dc.b    $05, $02
                dc.l    loc_11D06
                dc.l    loc_1A46C
                dc.l    loc_1A47E
                dc.l    loc_1A490
                dc.l    loc_1A4A2

; ----------------------------------------------------------------------

loc_11d06:
                dc.b    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; ======================================================================

loc_11D18:
                lea     loc_11D22(pc),a1
                jmp     loc_11d38

; ----------------------------------------------------------------------
; TODO

loc_11d22:
                dc.b    $05, $01
                dc.l    DoorMaps
                dc.l    loc_1A4A2
                dc.l    loc_1A490
                dc.l    loc_1A47E
                dc.l    loc_1A46C

; ======================================================================

loc_11d38:
                move.b  #1,($FFFFD27B).w
                lea     ($FFFFD254).w,a0
                clr.l   (a0)
                moveq   #0,d7
                moveq   #0,d6
                moveq   #0,d5
                move.b  ($FFFFD82E).w,d7         ; Load the door's X coordinate position.
                move.b  ($FFFFD82F).w,d6         ; Load the door's Y coordinate position.
                move.w  #$C000,d5
                bsr.w   loc_10F24
                moveq   #2,d7
                moveq   #2,d6
loc_11D5E:
                movem.l d5-a4,-(sp)
                bsr.w   SignFrameLogic
                tst.b   2(a0)
                bne.s   loc_11d7e
                bsr.w   CheckObjectRAM
                bsr.w   TimerCounter             ; Update timer.
                jsr     ($FFFFFB6C).w
                movem.l (sp)+,d5-a4
                bra.s   loc_11d5e

loc_11d7e:
                clr.b   ($FFFFD27B).w
                movem.l (sp)+,d5-a4
                rts

; ======================================================================

loc_11d88:
                moveq   #0,d0
                move.b  ($FFFFD882).w,d0
                beq.s   loc_11dc0
                subq.w  #1,d0
                beq.s   loc_11dc0
                subq.w  #1,d0
                move.l  #$46840003,($C00004).l   ; Set VDP to VRAM write, $C684.
                btst    #6,($A10001).l
                beq.s   loc_11db4
                move.l  #$47440003,($C00004).l
loc_11db4:
                move.w  #$4350,($C00000).l
                dbf     d0,loc_11db4
loc_11dc0:
                rts

; ======================================================================

loc_11dc2:
                lea     ($FFFFD87E).w,a6         ; Load 1P's score value into a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C04A,d5                ; Set as VRAM address to convert.
                moveq   #3,d0                    ; Set to draw 4 bytes' worth of numbers.
                bsr.w   loc_10Ff4                ; Write it.
                rts                              ; Return.

; ======================================================================

loc_11dd4:
                lea     ($FFFFCC00).w,a6         ; Load the top score value into a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C068,d5                ; Set as VRAM address to convert.
                moveq   #3,d0                    ; Set to draw 4 bytes' worth of numbers.
                bsr.w   loc_10Ff4                ; Write it.
                rts                              ; Return.

; ======================================================================

loc_11de6:
                lea     ($FFFFD82C).w,a6
                moveq   #0,d5
                move.w  #$C6BA,d5
                btst    #6,($A10001).l
                beq.s   loc_11dfe
                move.w  #$C77A,d5
loc_11dfe:
                moveq   #0,d0
                bsr.w   loc_10Ff4
                rts

; ======================================================================

loc_11e06:
                lea     loc_11e46(pc),a6         ; Load the normal 'RD.' mappings.
                btst    #6,($A10001).l           ; Is this being played on a PAL console?
                beq.s   loc_11E18                ; If it isn't, branch.
                lea     loc_11E4C(pc),a6         ; Otherwise, load the repositioned 'RD.' mappings.
loc_11E18:
                bsr.w   WriteASCIIString         ; Write onto the screen.
loc_11E1C:
                lea     Map_1Player,a6           ; Load the '1P' mappings into a6.
                moveq   #1,d7                    ; Set to write 2 tiles horizontally.
                moveq   #0,d6                    ; Set to write 1 tile vertically.
                moveq   #0,d5                    ; Clear d5, as the VRAM address is held here.
                move.w  #$C048,d5                ; Set as VRAM address to be converted.
                bsr.w   PlaneMaptoVRAM           ; Write onto the screen.
                lea     Map_TopIcon,a6           ; Load the 'TOP' mappings into a6.
                moveq   #2,d7                    ; Set to write 3 tiles horizontally.
                moveq   #0,d6                    ; Set to write 1 tile vertically.
                moveq   #0,d5                    ; Clear d5, as the VRAM address is held here.
                move.w  #$C064,d5                ; Set as VRAM address to be converted.
                bsr.w   PlaneMaptoVRAM           ; Write onto the screen.
                rts                              ; Return.

; ======================================================================

loc_11e46:
                dc.w    $C6B4                    ; VRAM address to write to.
                dc.b    'RD.'                    ; Mappings text.
                dc.b    $00                      ; String terminator.

loc_11e4c:
                dc.w    $C774                    ; VRAM address to write to.
                dc.b    'RD.'                    ; Mappings text.
                dc.b    $00                      ; String terminator.

; ======================================================================

loc_11e52:
                lea     ($FFFFD266).w,a6         ; Load the level's ending time to a6 (minutes).
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C160,d5                ; Set the VRAM address to write to.
                btst    #7,($A10001).l           ; Is the console a Japanese MD?
                beq.s   loc_11e68                ; If it is, branch.
                subq.w  #4,d5                    ; Give some spacing between the letters.
loc_11e68:
                moveq   #0,d0                    ; Set to draw 1 number.
                bsr.w   loc_10Ff4                ; Draw it onto the screen.
                lea     ($FFFFD267).w,a6         ; Load the level's ending time to a6 (seconds).
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C16C,d5                ; Set the VRAM address to write to.
                moveq   #0,d0                    ; Set to draw 1 number.
                bsr.w   loc_10Ff4                ; Draw it onto the screen.
                tst.b   ($FFFFD266).w            ; Has a minute elapsed?
                bne.s   loc_11e94                ; If not, branch.
                lea     ($FFFFD268).w,a6         ; Load the bonus score RAM address into a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C260,d5                ; Set the VRAM address to write to.
                moveq   #3,d0                    ; Set to write 4 numbers.
                bsr.w   loc_10Ff4                ; Draw the numbers onto the screen.
loc_11e94:
                rts

; ======================================================================

loc_11e96:
                lea     loc_11f04(pc),a6         ; Load the 'GAME TIME' text at the results screen.
                btst    #7,($A10001).l           ; Is this being played on a Japanese console?
                beq.s   loc_11ea8                ; If it is, branch.
                lea     loc_11f40(pc),a6         ; Load the repositioned version for the international consoles (Changed to ROUND TIME).
loc_11ea8:
                bsr.w   WriteASCIIString         ; Write to the screen.
                lea     loc_11F10(pc),a6         ; Load the 'MIN.' and 'SEC.'
                btst    #7,($A10001).l           ; Is this being played on a Japanese console?
                beq.s   loc_11ebe                ; If it is, branch.
                lea     loc_11F4E(pc),a6         ; Load the individual 'MIN.' string for international consoles.
loc_11ebe:
                bsr.w   WriteASCIIString         ; Write to the screen.
                btst    #7,($A10001).l           ; Is this being played on a Japanese console?
                beq.s   loc_11ed4                ; If it is, branch.
                lea     loc_11F56(pc),a6
                bsr.w   WriteASCIIString         ; Write to the screen.
loc_11ed4:
                lea     loc_11f1e(pc),a6
                btst    #7,($A10001).l           ; Is this being played on a Japanese console?
                beq.s   loc_11ee6                ; If it is, branch.
                lea     loc_11F5E(pc),a6
loc_11EE6:
                bsr.w   WriteASCIIString         ; Write to the screen.
                tst.b   ($FFFFD266).w            ; Has a minute elapsed?
                bne.s   loc_11EFA                ; If it has, branch.
                lea     loc_11F2C(pc),a6         ; Load the 'PTS.' mappings.
                bsr.w   WriteASCIIString         ; Write to the screen.
                bra.s   loc_11F02                ; Skip loading 'NO BONUS'.

loc_11EFA:
                lea     loc_11F34(pc),a6         ; Load the NO BONUS mappings.
                bsr.w   WriteASCIIString         ; Write to the screen.
loc_11F02:
                rts                              ; Return.

; ----------------------------------------------------------------------
; Japanese result screen map text.
loc_11f04:
                dc.w    $C14A                    ; VRAM address to write to.
                dc.b    'GAME TIME'              ; Mappings text.
                dc.b    $00                      ; String terminator.

loc_11f10:
                dc.w    $C164                    ; VRAM address to write to.
                dc.b    'MIN.  SEC.'             ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_11f1e:
                dc.w    $C24A                    ; VRAM address to write to.
                dc.b    'TIME BONUS'             ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

; ----------------------------------------------------------------------
; Japanese and English shared result screen mappings.

loc_11F2C:
                dc.w    $C272                    ; VRAM address to write to.
                dc.b    'PTS.'                   ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_11f34:
                dc.w    $C268                    ; VRAM address to write to.
                dc.b    'NO BONUS'               ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

; ----------------------------------------------------------------------
; English result screen map text.
loc_11F40:
                dc.w    $C148                    ; VRAM address to write to.
                dc.b    'ROUND TIME'             ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_11F4E:
                dc.w    $C162                    ; VRAM address to write to.
                dc.b    'MIN.'                   ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_11F56:
                dc.w    $C172                    ; VRAM address to write to.
                dc.b    'SEC.'                   ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_11f5e:
                dc.w    $C248                    ; VRAM address to write to.
                dc.b    'TIME BONUS'             ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

; ----------------------------------------------------------------------
; ======================================================================
; Bonus stage results screen.
; ======================================================================
loc_11F6C:
                tst.b   ($FFFFD28E).w            ; Have you collected any chicks in the bonus stage?
                beq.s   loc_11faa                ; If you haven't, branch.
                lea     ($FFFFD28F).w,a6         ; Load the RAM address of the collected bonus stage chicks in BCD, to a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C248,d5                ; Load the position on Plane A to write the number.
                moveq   #0,d0                    ; Set to draw 1 byte.
                bsr.w   loc_10Ff4                ; Write onto the screen.
                lea     ($FFFFD292).w,a6         ; Load the points (? TODO) bonus for the collected chicks.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C266,d5                ; Load the position on Plane A to write to.
                moveq   #1,d0                    ; Set to load 2 bytes worth.
                bsr.w   loc_10Ff4                ; Write onto the screen.
                cmpi.b  #$14,($FFFFD28E).w       ; Have you collected all 20 chicks?
                bne.s   loc_11faa                ; If you haven't, skip the perfect bonus stuff.
                lea     loc_11fac(pc),a6         ; Load the perfect bonus value.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C390,d5                ; Load the position on Plane A to write to.
                moveq   #3,d0                    ; Set to write 4 bytes.
                bsr.w   loc_10Ff4                ; Write onto the screen.
loc_11faa:
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_11fac:
                dc.l    $00010000

; ======================================================================

TitleScreen_Load:                                ; $11FB0
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                move.w  #$740,d0                 ; Set the VRAM address value to be converted.
                jsr     ($FFFFFB8A).w            ; Convert it and write it into the VDP.
                lea     loc_19eee,a0             ; Load the nemesis compressed art into a0.
                jsr     ($FFFFFA82).w            ; Decompress and load into VRAM.
                clr.b   ($FFFFD88E).w            ; Clear palette entry increment.
                bsr.w   loc_10126                ; Reload the ASCII art.
                lea     Pal_Main,a5              ; Load the main palette source into a5.
                jsr     ($FFFFFBBA).w            ; Decode and load into the appropriate position in the palette buffer.
                lea     Pal_TitleScreen(pc),a0   ; Load the title screen palette into a0.
                lea     ($FFFFF840).w,a1         ; Load buffer space for the last palette line.
                moveq   #3,d0                    ; Set to write 8 palettes.
loc_11FE2:
                move.l  (a0)+,(a1)+              ; Load two colours into the palette buffer.
                dbf     d0,loc_11fe2             ; Repeat for the other 6.
                moveq   #5,d0                    ; Set to load 6 text string pointers.
                lea     Map_JapTitle(pc),a0      ; Load the Japanese cast text.
                btst    #7,($A10001).l           ; Is the Mega Drive system running the game a domestic console (not international)?
                beq.s   loc_11ffc                ; If it is, branch.
                lea     Map_EngTitle(pc),a0      ; Load the English cast text.
loc_11ffc:
                movea.l (a0)+,a6                 ; Load the pointer into a6.
                bsr.w   WriteASCIIString         ; Dump onto the screen.
                dbf     d0,loc_11ffc             ; Repeat for the rest.
                move.b  #3,($FFFFD882).w         ;
                move.w  #$101,($FFFFD82C).w      ; Set the BCD and hex level round to 0101.
                move.b  #1,($FFFFD88F).w         ;
                lea     ($FFFFC000).w,a0         ; Load start of object RAM.
                moveq   #0,d1                    ; Clear d1.
                moveq   #3,d0                    ; Set to load 4 objects.
loc_12020:
                move.w  #$40,(a0)                ; Set to load object $40 (title screen characters).
                move.w  d1,$38(a0)               ; Set object subtype.     TODO
                lea     $40(a0),a0               ; Load next object RAM entry.
                addq.w  #1,d1                    ; Load next subtype.
                dbf     d0,loc_12020             ; Repeat for the rest.
                move.w  #$44,(a0)                ; Set to load the 'PUSH START BUTTON' object.
                lea     ($FFFFC140).w,a0         ; Load object entry 5 into a0.
                moveq   #0,d1                    ; Clear d1.
                moveq   #5,d0                    ; Set to load 6 objects.
loc_1203E:
                move.w  #$48,(a0)                ; Set to load the 'FLICKY' letters on the title.
                move.w  d1,$38(a0)               ; Set the subtype (in this case, the individual letters).
                lea     $40(a0),a0               ; Load next object RAM entry.
                addq.w  #1,d1                    ; Set to load next letter.
                dbf     d0,loc_1203e             ; Repeat until they're all loaded.
                btst    #7,($A10001).l           ; Is this a domestic MD model?
                beq.s   loc_12062                ; If it is, branch.
                lea     Map_Trademark(pc),a6     ; Load the trademark mappings source into a6.
                bsr.w   loc_10Fc0                ; Dump them onto the screen.
loc_12062:
                bsr.w   loc_11e1c                ; Write the '1P' and 'TOP' mappings onto the screen.
                bsr.w   loc_11dc2                ; Write the first player's score onto the screen.
                bsr.w   loc_11dd4                ; Write the high score onto the screen.
                bsr.w   CheckObjectRAM           ; Load object code, convert to sprites, etc.
                clr.w   ($FFFFFF92).w            ; Clear the game mode timer.
                move.b  #$85,d0                  ; Load the title screen music ID.
                jsr     ($FFFFFB66).w            ; Play it.
                jsr     ($FFFFFB6C).w            ; ''
                jmp     ($FFFFFB6C).w            ; ''

; ======================================================================

Map_JapTitle:                                    ; $12086
                dc.l    loc_120B6                ; CAST
                dc.l    loc_120BE                ; FLICKY
                dc.l    loc_120C8                ; PIOPIO
                dc.l    loc_120D2                ; NYANNYAN
                dc.l    loc_120DE                ; CHORO
                dc.l    loc_120E6                ; (C) SEGA 1991

Map_EngTitle:                                    ; $1209E
                dc.l    loc_120B6                ; CAST
                dc.l    loc_120BE                ; FLICKY
                dc.l    loc_120F4                ; CHIRP
                dc.l    loc_120FC                ; TIGER
                dc.l    loc_12104                ; IGGY
                dc.l    loc_120E6                ; (C) SEGA 1991

; ----------------------------------------------------------------------


loc_120b6:
                dc.w    $C29C                    ; VRAM address to write to.
                dc.b    'CAST'                   ; Mappings text.
                dc.w    $0000                    ; Padding.

loc_120BE:
                dc.w    $C310                    ; VRAM address to write to.
                dc.b    'FLICKY'                 ; Mappings text.
                dc.w    $0000                    ; Padding.

loc_120C8:
                dc.w    $C328                    ; VRAM address to write to.
                dc.b    'PIOPIO'                 ; Mappings text.
                dc.w    $0000                    ; Padding.

loc_120D2:
                dc.w    $C3D0                    ; VRAM address to write to.
                dc.b    'NYANNYAN'               ; Mappings text.
                dc.w    $0000                    ; Padding.

loc_120DE:
                dc.w    $C3E8                    ; VRAM address to write to.
                dc.b    'CHORO'                  ; Mappings text.
                dc.b    $00                      ; Padding.

loc_120e6:
                dc.w    $C654                    ; VRAM address to write to.
                dc.w    $2720                    ; (C) symbol's VRAM location ($27) and space ($20).
                dc.b    'SEGA 1991'              ; Mappings text.
                dc.b    $00                      ; Padding.

loc_120F4:
                dc.w    $C328                    ; VRAM address to write to.
                dc.b    'CHIRP'                  ; Mappings text.
                dc.b    $00                      ; Padding.

loc_120fc:
                dc.w    $C3D0                    ; VRAM address to write to.
                dc.b    'TIGER'                  ; Mappings text.
                dc.b    $00                      ; Padding.

loc_12104:
                dc.w    $C3E8                    ; VRAM address to write to.
                dc.b    'IGGY'                   ; Mappings text.
                dc.w    $0000                    ; Padding.

; ======================================================================

Pal_TitleScreen:                                 ; $1210C
                incbin  "Palettes\Pal_TitleScreen.bin"

Map_Trademark:                                   ; $1211C
                dc.w    $C0EE                    ; VRAM address.
                dc.b    'TM'                     ; Mappings text.
                dc.w    $00                      ; String terminator.

; ======================================================================

TitleScreen_Loop:                                ; $12122
                btst    #7,($FFFFFF8F).w         ; Is start being pressed?
                beq.s   loc_12146                ; If it isn't, branch.
                bsr.w   loc_11784                ; TODO IMPORTANT
                move.b  #$E0,d0
                bsr.w   loc_10d34                ; TODO again. Hopefully the sound driver.
                move.b  #1,($FFFFD88E).w
                bsr.w   loc_10126                ; Reload the ASCII art.
                move.w  #8,($FFFFFFC0).w         ; Load the next gamemode TODO.
loc_12146:
                cmpi.w  #$400,($FFFFFF92).w      ; Has the gamemode timer hit $400?
                bcs.s   loc_1216a                ; If it's any lower, branch.
                bsr.w   loc_11784                ; TODO IMPORTANT
                move.b  #$E0,d0
                bsr.w   loc_10d34                ; TODO again. Hopefully the sound driver.
                move.b  #1,($FFFFD88E).w
                bsr.w   loc_10126                ; Reload the ASCII art.
                move.w  #$38,($FFFFFFC0).w       ; Load the demo TODO.
loc_1216a:
                bsr.w   CheckObjectRAM           ; Check if any objects exist, and run their code if they do.
                jmp     ($FFFFFB6C).w            ; TODO

; ======================================================================
; Characters on the title screen
; ======================================================================
loc_12172:
                bset    #7,(a0)                  ; Set object as loaded.
                bne.s   loc_1219e                ; If it was loaded before, skip object loading.
                bset    #7,2(a0)                 ; Flip sprite horizontally (face left).
                move.w  $38(a0),d0               ; Load the object's subtype to d0.
                lsl.w   #1,d0                    ; Multiply by 2 to handle word-sized tables.
                move.w  loc_121b4(pc,d0.w),6(a0) ; Load the correct animation script.
                lsl.w   #1,d0                    ; Multiply again by 2 (x4) to handle longword-sized tables.
                move.l  loc_121a4(pc,d0.w),8(a0) ; Load correct character animation script table.
                move.w  loc_121bc(pc,d0.w),$20(a0) ; Set starting horizontal height.
                move.w  loc_121bc+2(pc,d0.w),$24(a0) ; Set starting vertical height.
loc_1219e:
                bsr.w   AnimateSprite            ; Set sprite to animate.
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_121a4:
                dc.l    loc_144AC
                dc.l    loc_14E12
                dc.l    loc_154AE
                dc.l    loc_162BC


loc_121b4:
                dc.w    $0000
                dc.w    $0004
                dc.w    $0004
                dc.w    $0000

loc_121bc:
                dc.w    $00B0
                dc.w    $00F0

                dc.w    $0110
                dc.w    $00EC

                dc.w    $00B0
                dc.w    $0108

                dc.w    $0110
                dc.w    $0100

; ======================================================================
; 'PUSH START BUTTON' object on the title screen.
; ======================================================================
loc_121cc:
                bset    #7,(a0)                  ; Set object as loaded.
                bne.s   loc_121e6                ; If it wasn't before, branch.
                move.l  #loc_1ACDC,$C(a0)        ; TODO mappings?
                move.w  #$F0,$20(a0)             ; Set starting horizontal height.
                move.w  #$120,$24(a0)            ; Set starting vertical height.
loc_121E6:
                move.w  $3C(a0),d0               ; Load object's routine counter value into d0.
                andi.w  #$7C,d0                  ; Limit by $7C routines; keep within a multiple of 4.
                jsr     loc_121f4(pc,d0.w)       ; Jump to that routine.
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_121f4:
                bra.w   loc_121fc

; ----------------------------------------------------------------------

                bra.w   loc_1221e

; ----------------------------------------------------------------------

loc_121fc:
                bset    #7,$3C(a0)               ; Set routine counter so this routine isn't run again.
                bne.s   loc_12210                ; If it was already set, branch.
                bclr    #1,2(a0)                 ; Enable sprite display.
                move.w  #$3C,$3A(a0)             ; Set routine counter timer.
loc_12210:
                subq.w  #1,$3A(a0)               ; Subtract 1 from the timer.
                bne.s   loc_1221c                ; If it hasn't finished, skip over the next routine load.
                move.w  #4,$3C(a0)               ; Set to load next routine on next pass.
loc_1221c:
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_1221E:
                bset    #7,$3C(a0)               ; Set routine counter so this routine isn't run again.
                bne.s   loc_12232                ; If it was already set, branch.
                bset    #1,2(a0)                 ; Disable sprite display.
                move.w  #$14,$3A(a0)             ; Set routine counter timer.
loc_12232:
                subq.w  #1,$3A(a0)               ; Subtract 1 from the timer.
                bne.s   loc_1223c                ; If it hasn't finished, skip over the next routine load.
                clr.w   $3C(a0)                  ;
loc_1223C:
                rts                              ; Return.

; ======================================================================
; 'FLICKY' letters on the title screen.
; ======================================================================

loc_1223e:
                bset    #7,(a0)                  ; Set object as loaded.
                bne.s   loc_1225C                ; If it was already loaded, branch.
                move.w  $38(a0),d0               ; Get object subtype.
                lsl.w   #2,d0                    ; Multiply by 4 for longword tables.
                move.l  loc_1225E(pc,d0.w),$C(a0); Load mappings pointer into its SST.
                move.w  loc_12276(pc,d0.w),$20(a0); Get horizontal position.
                move.w  loc_12276+2(pc,d0.w),$24(a0); Get vertical position.
loc_1225C:
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_1225E:
                dc.l    FlickyFMaps                ; $0 - F
                dc.l    FlickyLMaps                ; $1 - L
                dc.l    FlickyIMaps                ; $2 - I
                dc.l    FlickyCMaps                ; $3 - C
                dc.l    FlickyKMaps                ; $4 - K
                dc.l    FlickyYMaps                ; $5 - Y

loc_12276:
                dc.w    $00D0
                dc.w    $00C0

                dc.w    $00E5
                dc.w    $00C0

                dc.w    $00F7
                dc.w    $00C0

                dc.w    $0107
                dc.w    $00C0

                dc.w    $011C
                dc.w    $00C0

                dc.w    $0133
                dc.w    $00C0

; ======================================================================
                                     ; TODO
loc_1228e:
                moveq   #7,d1
loc_12290:
                jsr     ($FFFFFB6C).w
                dbf     d1,loc_12290
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette address into a5.
                jsr     ($FFFFFBBA).w            ; Load the palettes into the palette buffer.
                clr.l   ($FFFFD87E).w            ; Clear the 1st player's score.
                clr.b   ($FFFFD887).w            ; TODO
                bsr.w   loc_1268e                ; TODO
                bsr.w   Level_PalLoad            ; Load the level's palettes into the palette buffer.
                bsr.w   loc_1230a                ; Dump mappings onto the screen.
                lea     ($FFFFC000).w,a0         ; Load the start of object RAM into a0.
                moveq   #0,d1                    ; Clear d1.
                moveq   #$13,d0                  ; Set amount of characters to load.
loc_122C2:
                move.w  #$004C,(a0)              ; Load the character objects for the help screen.
                move.w  d1,$38(a0)               ; Set object subtype.
                lea     $40(a0),a0               ; Load next object RAM instance.
                addq.w  #1,d1                    ; Load next subtype.
                dbf     d0,loc_122c2             ; Repeat $14 times.
                bsr.w   CheckObjectRAM           ; Check if the code exists, and if it does, run it.
                jsr     ($FFFFFB6C).w
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_122e0:
                btst    #7,($FFFFFF8F).w         ; Is start being pressed?
                beq.s   loc_12306                ; If it isn't, branch.
                move.w  #$18,($FFFFFFC0).w       ; Load the level game mode.
                move.b  ($FFFFFF8E).w,d0         ; Move player 1's held buttons into d0.
                bclr    #7,d0                    ; Clear the start button bit.
                cmpi.b  #$61,d0                  ; Are A, C and up being held?
                bne.s   loc_12302                ; If they're not, skip over the level select game mode change.
                move.w  #$10,($FFFFFFC0).w       ; Set to load the level select.
loc_12302:
                bsr.w   loc_11784                ; TODO - Fade palettes?
loc_12306:
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_1230a:
                moveq   #5,d0                    ; Set amount of text strings to dump.
                lea     Map_JapHelpText(pc),a0   ; Load the Japanese mappings' address.
                btst    #7,($A10001).l           ; Is the Mega Drive running on a domestic console?
                beq.s   loc_1231e                ; If it is, branch.
                lea     Map_EngHelpText(pc),a0   ; Load the English mappings' address.
loc_1231E:
                movea.l (a0)+,a6                 ; Load the pointer for the mappings.
                bsr.w   loc_10Fc0                ; Dump onto the screen.
                dbf     d0,loc_1231e             ; Repeat for all the text.
                lea     ($FFFFD82E).w,a0         ; Load the door's coodinates address to a0.
                moveq   #$E,d7                   ; Set the X position on the screen.
                btst    #7,($A10001).l           ; Is the console being played on a domestic Mega Drive?
                beq.s   loc_1233a                ; If it is, branch.
                moveq   #$F,d7                   ; Set the X position on the screen (slightly right).
loc_1233a:
                moveq   #6,d6                    ; Set the Y coordinate on the screen.
                moveq   #0,d4                    ; Set to write 3x3 tiles.
                move.b  d7,(a0)                  ; Set the horizontal position of the door into storage.
                move.b  d6,1(a0)                 ; Set the horizontal position of the door into storage.
                bsr.w   loc_11b16                ; Dump mappings from an address in RAM (Load door mappings).
                bsr.w   loc_11b86                ; Load the exit sign mappings onto the screen.
                moveq   #5,d7                    ; Load the second door's X position on the screen.
                moveq   #$17,d6                  ; Load the second door's Y position onto the screen.
                moveq   #0,d4                    ; Set to write 3x3 tiles.
                move.b  d7,(a0)                  ; Update the horizontal position storage.
                move.b  d6,1(a0)                 ; Update the vertical position storage.
                bsr.w   loc_11b16                ; Dump mappings to Plane A from an address in RAM (Load door mappings).
                bsr.w   loc_11b86                ; Load the exit sign mappings onto the screen.
                bsr.w   loc_11976                ; Dump mappings to a certain part of Plane B from an address in RAM (TODO).
                bsr.w   loc_1194c                ; Dump mappings to Plane B from an address in RAM (TODO).
                lea     ($C00000).l,a0           ; Load the VDP data port into a0.
                move.l  #$648A0003,($C00004).l   ; Set the VDP to VRAM write, $E48A.
                moveq   #$15,d0                  ; Set amount of platform tiles to draw.
loc_1237A:
                move.w  #$220D,(a0)              ; Draw one platform tile.
                dbf     d0,loc_1237a             ; Repeat to create the platform.
                rts                              ; Return.

; ======================================================================
; Japanese help screen text mappings. No ASCII equivalent, so raw values
; had to be used, unlike Map_EngHelpText.
; ----------------------------------------------------------------------
Map_JapHelpText:                                 ; $12384
                dc.l    loc_1239C
                dc.l    loc_123A4
                dc.l    loc_123AE
                dc.l    loc_123B2
                dc.l    loc_123C2
                dc.l    loc_123DA
loc_1239c:
                dc.w    $C0DA                    ; VRAM address to write to.
                dc.w    $606E, $A765, $6F00      ; Mappings text, terminate the string ($00).

loc_123A4:
                dc.w    $C208                    ; VRAM address to write to.
                dc.w    $8C6E, $626A, $6B72      ; Mappings text.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_123AE:
                dc.w    $C218                    ; VRAM address to write to.
                dc.w    $8C00                    ; Mappings text, terminate the string.

loc_123B2:
                dc.w    $C224                    ; VRAM address to write to.
                dc.w    $7EA4, $7189, $7261      ; Mappings text.
                dc.w    $9372, $67A1, $6A61      ; ''
                dc.w    $1200                    ; Mappings text & string terminator.

loc_123c2:
                dc.w    $C306                    ; VRAM address to write to.
                dc.w    $FABF, $DD8C, $646C      ; Mappings text.
                dc.w    $7311, $EDE4, $DDFD      ; ''
                dc.w    $2026, $20BB, $E6E3      ; ''
                dc.w    $C312                    ; ''
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_123DA:
                dc.w    $C594                    ; VRAM address to write to.
                dc.w    $7E73, $8172, $7189      ; Mappings text.
                dc.w    $7265, $6388, $7311      ; ''
                dc.w    $6962, $7367, $728D      ; ''
                dc.     $2100                    ; Mappings text and string terminator.

; ----------------------------------------------------------------------
; English help screen text mappings.
; ----------------------------------------------------------------------
Map_EngHelpText:                                 ; $123F0
                dc.l    loc_12408
                dc.l    loc_1241A
                dc.l    loc_12422
                dc.l    loc_1242A
                dc.l    loc_1243A
                dc.l    loc_1245C

loc_12408:
                dc.w    $C0D2                    ; VRAM address to write to.
                dc.b    'MAKE YOUR MOVE'         ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_1241A:
                dc.w    $C202                    ; VRAM address to write to.
                dc.b    'HELP'                   ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_12422:

                dc.w    $C20E                    ; VRAM address to write to.
                dc.b    'GUIDE'                  ; Mappings text.
                dc.b    $00                      ; String terminator.

loc_1242a:
                dc.w    $C226                    ; VRAM address to write to.
                dc.b    'TO THE DOOR!'           ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_1243A:
                dc.w    $C2C2                    ; VRAM address to write to.
                dc.b    'PRESS BUTTON TO JUMP AND SHOOT' ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_1245C:
                dc.w    $C592
                dc.b    'RACK UP A SUPER SCORE!' ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

; ======================================================================
; Characters on the help screen.
; ======================================================================
loc_12476:
                bset    #7,(a0)                   ; Set object as loaded.
                bne.s   loc_124B8                ; If it was already loaded, branch.
                move.w  $38(a0),d0               ; Load object subtype.
                bclr    #7,2(a0)                 ; Clear the horizontal flip bit.
                move.b  loc_124ba(pc,d0.w),d1    ; Get the object's horizontal flip table value.
                beq.s   loc_12492                ; If it isn't set to flip, branch.
                bset    #7,2(a0)                 ; Set the object to flip horizontally.
loc_12492:
                lsl.w   #2,d0                    ; Multiply by four to handle longword tables.
                move.l  loc_124ce(pc,d0.w),$C(a0); Load the mappings address into its SST.
                lea     loc_1251e(pc),a1         ; Load the Japanese object coordinates.
                btst    #7,($A10001).l           ; Is the console a domestic MD?
                beq.s   loc_124AC                ; If it is, set to load to the SSTs.
                lea     loc_1256e(pc),a1         ; Otherwise, use the overseas' coordinates.
loc_124AC:
                move.w  (a1,d0.w),$20(a0)        ; Load the horizontal position.
                move.w  2(a1,d0.w),$24(a0)       ; Load the vertical position.
loc_124b8:
                rts                              ; Return.

; ----------------------------------------------------------------------
; TODO - Some of this is wrong, relabel.
loc_124ba:
                dc.b    $00                      ; Chick (with sunglasses).
                dc.b    $00                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $00                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $00                      ; Chick (faces left despite the bit not being set).
                dc.b    $00                      ; Flicky.
                dc.b    $00                      ; Chick.
                dc.b    $00                      ; Flicky flying.
                dc.b    $00                      ; Peg.
                dc.b    $00                      ; Tiger.
                dc.b    $01                      ; Flicky moving.
                dc.b    $01                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $01                      ; Chick.
                dc.b    $01                      ; Chick.

; ----------------------------------------------------------------------
; TODO SCREEN

loc_124ce:
                dc.l    loc_1A848                ; Chick with sunglasses.
                dc.l    loc_1A7F0                ; Chick moving, frame 1.
                dc.l    loc_1A800                ; Chick idling.
                dc.l    loc_1A7D8                ; Chick moving, frame 2.
                dc.l    loc_1A7C8                ; Chick flying.
                dc.l    loc_1A7D8                ; Chick moving, frame 2.
                dc.l    loc_1A7F0                ; Chick moving, frame 1.
                dc.l    loc_1A830                ; Chick with sunglasses flying.
                dc.l    loc_1A898                ; Flicky standing still.
                dc.l    loc_1A7B8                ; Chick flying (TODO).
                dc.l    loc_1A8D0                ; Flicky flying.
                dc.l    loc_1A528                ; Peg thrown.
                dc.l    loc_1A99A                ; Tiger getting hit.
                dc.l    loc_1A8A8                ; Flicky jumping right.
                dc.l    loc_1A7E8
                dc.l    loc_1A848
                dc.l    loc_1A850
                dc.l    loc_1A7F8
                dc.l    loc_1A7F0                ; Chick moving, frame 1.
                dc.l    loc_1A858

; ======================================================================
; Japanese screen coordinates for the sprites.
; ======================================================================
loc_1251e:
                dc.w    $00B4
                dc.w    $00A0

                dc.w    $00C0
                dc.w    $00A0

                dc.w    $00CC
                dc.w    $00A0

                dc.w    $00D8
                dc.w    $00A0

                dc.w    $0120
                dc.w    $00A0

                dc.w    $012C
                dc.w    $00A0

                dc.w    $0138
                dc.w    $00A0

                dc.w    $0144
                dc.w    $00A0

                dc.w    $0098
                dc.w    $00C8

                dc.w    $00D8
                dc.w    $00C8

                dc.w    $00D0
                dc.w    $0100

                dc.w    $0118
                dc.w    $0100

                dc.w    $0118
                dc.w    $0110

                dc.w    $00C0
                dc.w    $0150

                dc.w    $00C8
                dc.w    $0150

                dc.w    $00D0
                dc.w    $0150

                dc.w    $00D8
                dc.w    $0150

                dc.w    $00E0
                dc.w    $0150

                dc.w    $00E8
                dc.w    $0150

                dc.w    $00F0
                dc.w    $0150

; ======================================================================

loc_1256e:
                dc.w    $0094
                dc.w    $00A0

                dc.w    $00A0
                dc.w    $00A0

                dc.w    $00AC
                dc.w    $00A0

                dc.w    $00B8
                dc.w    $00A0

                dc.w    $0148
                dc.w    $00A0

                dc.w    $0154
                dc.w    $00A0

                dc.w    $0160
                dc.w    $00A0

                dc.w    $016C
                dc.w    $00A0

                dc.w    $00B0
                dc.w    $00C8

                dc.w    $00E8
                dc.w    $00C8

                dc.w    $00D0
                dc.w    $0100

                dc.w    $0118
                dc.w    $0100

                dc.w    $0118
                dc.w    $0110

                dc.w    $00C0
                dc.w    $0150

                dc.w    $00C8
                dc.w    $0150

                dc.w    $00D0
                dc.w    $0150

                dc.w    $00D8
                dc.w    $0150

                dc.w    $00E0
                dc.w    $0150

                dc.w    $00E8
                dc.w    $0150

                dc.w    $00F0
                dc.w    $0150

; ======================================================================

loc_125be:
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette source into a5.
                jsr     ($FFFFFBBA).w            ; Decode the palettes and load them into the palette buffer.
                lea     Map_LSRound(pc),a6       ; Load the 'ROUND' mappings into a6.
                bsr.w   WriteASCIIString         ; Dump them onto the screen.
                move.b  #3,($FFFFD882).w
                move.b  #1,($FFFFD29A).w
                jsr     ($FFFFFB6C).w
                jmp     ($FFFFFB6C).w

; ----------------------------------------------------------------------

Map_LSRound:                                       ; $125E8
                dc.w    $C354                      ; VRAM address to write to.
                dc.b    'ROUND '                   ; ASCII string.
                dc.w    $0000                      ; Terminate the string, pad to even.

; ======================================================================

loc_125F2:
                move.b  ($FFFFD82C).w,d1         ; Load the BCD level number value to d1.
                move.b  #1,d2                    ; Set addition value to 1.
                move.b  ($FFFFFF8F).w,d0         ; Load the buttons pressed into d0.
                btst    #0,d0                    ; Is up being pressed?
                beq.s   loc_1261a                ; If it isn't, branch.
                cmpi.b  #$36,d1                  ; Has the round hit 36?
                beq.s   loc_12642                ; If it has, don't add anymore.
                addi.b  #0,d0                    ; Clear the extend CCR bit.
                abcd    d2,d1                    ; Add by 1 (decimal).
                addq.b  #1,($FFFFD82D).w         ; Add to the hex round value.
                move.b  d1,($FFFFD82C).w         ; Copy the decimal add to the BCD address.
                bra.s   loc_12642                ; Skip the down button check.

loc_1261a:
                btst    #1,d0                    ; Is down being pressed?
                beq.s   loc_12636                ; If it isn't, branch.
                cmpi.b  #1,d1                    ; Has the round hit 1?
                beq.s   loc_12642                ; If it is, branch.
                addi.b  #0,d0                    ; Clear the extend CCR bit.
                sbcd    d2,d1                    ; Subtract by 1.
                subq.b  #1,($FFFFD82D).w         ; Subtract from the hex round value.
                move.b  d1,($FFFFD82C).w         ; Copy the decimal subtract from the BCD address.
                bra.s   loc_12642                ; Skip the start button check.

loc_12636:
                btst    #7,d0                    ; Is start being pressed?
                beq.s   loc_12642                ; If it isn't, branch.
                move.w  #$18,($FFFFFFC0).w       ; Load the level game mode.
loc_12642:
                lea     ($FFFFD82C).w,a6         ; Load the level number address to a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C360,d5                ; Set the screen coordinates to write to.
                moveq   #0,d0                    ; Clear d0.
                bsr.w   loc_10Ff4                ; Write the round number onto the screen.
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_12656:
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette into a5.
                jsr     ($FFFFFBBA).w            ; Decode the palette and load it into the palette buffer.
                clr.l   ($FFFFD888).w            ; Clear the in-game timer.
                clr.b   ($FFFFD88D).w            ; Clear the amount of times chicks have been deposited in one level.
                rts                              ; Return.

; ======================================================================

loc_1266e:
                move.w  #$20,($FFFFFFC0).w       ; Set game mode to TODO
                move.b  ($FFFFD82D).w,d0         ; Get level number.
                andi.b  #3,d0                    ; Get the level's number out of a group of 4.
                cmpi.b  #3,d0                    ; Is this the 4th level out of every 4 (except for the first 3, because the first level is read as level 2).
                bne.s   loc_12688                ; If it isn't, branch.
                move.w  #$28,($FFFFFFC0).w       ; Set to load the bonus stage.
loc_12688:
                jsr     ($FFFFFB6C).w            ; TODO
                rts                              ; Return.

; ======================================================================

loc_1268e:
                moveq   #$18,d7                  ; Set to load 6 level pointers depending on the level (see below, level values are in multiples of 4).
                bsr.w   loc_11764                ; Load the right tiles for each group of levels.
                lsr.w   #2,d0                    ; Clear the first two bits.
                lsl.w   #2,d0                    ; Restore to original position (This is to keep it within a multiple of 4).
                lea     BGTileTable_Unk(pc),a0   ; Load the unused level background tiles to a0.
                move.l  (a0,d0.w),d1             ; Get the correct unused background tiles based on the level.
                move.l  d1,($FFFFD804).w         ; Load the unused background tiles pointer into storage.
                lea     BGTileTable(pc),a0       ; Load the level background tile mappings table to a0.
                move.l  (a0,d0.w),d1             ; Get the correct background tiles based on the level.
                move.l  d1,($FFFFD800).w         ; Store them into a RAM address.
                lea     RoofTileTable(pc),a0     ; Load the roof tile maps' pointer table into a0.
                move.l  (a0,d0.w),d1             ; Load the correct tiles based on the level.
                move.l  d1,($FFFFD808).w         ; Write into RAM.
                lea     GroundTileTable(pc),a0   ; Load the ground tile maps' pointer table into a0.
                move.l  (a0,d0.w),d1             ; Load the correct tile maps based on the level.
                move.l  d1,($FFFFD80C).w         ; Store in RAM.
                lea     WallpaperTileTable(pc),a0; Load the wallpaper tile maps' pointer table into a0.
                move.l  (a0,d0.w),d1             ; Load the correct tile maps based on the level.
                move.l  d1,($FFFFD814).w         ; Store in RAM.
                lea     WallpaperTileTable2(pc),a0 ; Load the secondary wallpaper tile tables to a0.
                move.l  (a0,d0.w),d1             ; Load the correct tile maps based on the level.
                move.l  d1,($FFFFD818).w         ; Store in RAM.
                moveq   #$20,d7
                bsr.w   loc_11774
                subq.b  #1,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     loc_12788(pc),a0         ; TODO IMPORTANT
                move.l  (a0,d0.w),d1
                move.l  d1,($FFFFD810).w
                moveq   #$F,d7
                bsr.w   loc_11774
                subq.b  #1,d0
                lsl.w   #2,d0
                lea     loc_127e8(pc),a0          ; bookmark
                move.l  (a0,d0.w),d1
                move.l  d1,($FFFFD828).w
                move.l  #DoorMaps,($FFFFD81C).w
                move.l  #loc_1A292,($FFFFD820).w
                move.l  #loc_1A286,($FFFFD824).w
                rts                              ; Return.

; ======================================================================

BGTileTable_Unk:                                     ; $12728
                dc.l    BGTiles_Unk1
                dc.l    BGTiles_Unk2
                dc.l    BGTiles_Unk3
                dc.l    BGTiles_Unk4
                dc.l    BGTiles_Unk5
                dc.l    BGTiles_Unk6

; ----------------------------------------------------------------------

BGTileTable:                                     ; $12740
                dc.l    BGTiles1
                dc.l    BGTiles2
                dc.l    BGTiles3
                dc.l    BGTiles4
                dc.l    BGTiles5
                dc.l    BGTiles6

; ----------------------------------------------------------------------

RoofTileTable:                                   ; $12758
                dc.l    RoofTiles1
                dc.l    RoofTiles2
                dc.l    RoofTiles3
                dc.l    RoofTiles4
                dc.l    RoofTiles5
                dc.l    RoofTiles6

; ----------------------------------------------------------------------

GroundTileTable:                                   ; $12770
                dc.l    GroundTiles1
                dc.l    GroundTiles2
                dc.l    GroundTiles3
                dc.l    GroundTiles4
                dc.l    GroundTiles5
                dc.l    GroundTiles6

; ----------------------------------------------------------------------

loc_12788:
                dc.l    loc_1A29A
                dc.l    loc_1A2A6
                dc.l    loc_1A2B2
                dc.l    loc_1A2BE
                dc.l    loc_1A2CA
                dc.l    loc_1A29A
                dc.l    loc_1A2A6
                dc.l    loc_1A2B2
                dc.l    loc_1A29A
                dc.l    loc_1A2A6
                dc.l    loc_1A2B2
                dc.l    loc_1A29A

; ----------------------------------------------------------------------

WallpaperTileTable:                              ; $127B8

                dc.l    WallPaperTiles1
                dc.l    WallPaperTiles1
                dc.l    WallPaperTiles2
                dc.l    WallPaperTiles3
                dc.l    WallPaperTiles5
                dc.l    WallPaperTiles4

; ----------------------------------------------------------------------

WallpaperTileTable2:                             ; $127D0
                dc.l    WallpaperScenery1
                dc.l    WallpaperScenery1
                dc.l    WallpaperScenery2
                dc.l    WallpaperScenery3
                dc.l    WallpaperScenery4
                dc.l    WallpaperScenery5

; ----------------------------------------------------------------------

loc_127e8:
                dc.l    loc_1A4E8
                dc.l    loc_1A518
                dc.l    loc_1A548
                dc.l    loc_1A578
                dc.l    loc_1A5A8
                dc.l    loc_1A5D8
                dc.l    loc_1A608
                dc.l    loc_1A638
                dc.l    loc_1A668
                dc.l    loc_1A698
                dc.l    loc_1A6C8
                dc.l    loc_1A6F8
                dc.l    loc_1A728
                dc.l    loc_1A758
                dc.l    loc_1A788

; ======================================================================
Level_PalLoad:                                   ; $12824
                moveq   #$30,d7                  ; Set to load $C level pointers depending on the level (see below, level values are in multiples of 2).
                bsr.w   loc_11764                ; Load the right tiles for each group of levels.
                lsr.w   #2,d0                    ; Clear first two bits.
                lsl.w   #1,d0                    ; Restore the original value, divided by two (table loaded below uses word entries).
                lea     loc_12866(pc),a0         ; Load the level palette pointer value to a0.
                moveq   #-1,d1                   ; Set d1 to $FFFFFFFF.
                move.w  (a0,d0.w),d1             ; Overwrite lower word value to get address of code in RAM.
                movea.l d1,a0                    ; Set as address.
                lea     ($FFFFF800).w,a1         ; Load the section of the palette line buffer dedicated to the level palette (palette line 1).
                moveq   #7,d0                    ; Set to load 16 palettes.
loc_12840:
                move.l  (a0)+,(a1)+              ; Load the first two palettes into the buffer.
                dbf     d0,loc_12840             ; Repeat until cleared completely.
                moveq   #$F,d7                   ; Set to load 4 level pointers depending on the level.
                bsr.w   loc_11774                ; Load the right tiles for each group of levels.
                subq.w  #1,d0                    ; TODO
                lsl.w   #1,d0
                lea     loc_129fe(pc),a0
                lea     ($FFFFF858).w,a1
                moveq   #-1,d1                   ; Set d1 as $FFFFFFFF.
                move.w  (a0,d0.w),d1
                movea.l d1,a0                    ; Set as address.
                move.l  (a0)+,(a1)+              ; Move the first two colours into the palette buffer.
                move.l  (a0)+,(a1)+              ; Move the last two colours into the palette buffer.
                rts                              ; Return.

; ======================================================================

loc_12866:
                dc.w    loc_1287E&$FFFF
                dc.w    loc_1289E&$FFFF
                dc.w    loc_128BE&$FFFF
                dc.w    loc_128DE&$FFFF
                dc.w    loc_128FE&$FFFF
                dc.w    loc_1291E&$FFFF
                dc.w    loc_1293E&$FFFF
                dc.w    loc_1295E&$FFFF
                dc.w    loc_1297E&$FFFF
                dc.w    loc_1299E&$FFFF
                dc.w    loc_129BE&$FFFF
                dc.w    loc_129DE&$FFFF

loc_1287E:
                dc.w    $0000, $0006, $000E, $0CC4
                dc.w    $04AA, $06EE, $0064, $0064
                dc.w    $00A2, $00A2, $06EE, $008C
                dc.w    $08EE, $00AE, $006E, $04CA

loc_1289e:
                dc.w    $0000, $0068, $02AA, $004A
                dc.w    $0EA8, $0444, $0C86, $0CCC
                dc.w    $0EA8, $0AAA, $0000, $00A4
                dc.w    $00AC, $00C6, $0062, $00A8

loc_128be:
                dc.w    $0000, $00EE, $046C, $0E28
                dc.w    $0A0A, $0C2A, $0A8A, $0E4E
                dc.w    $0ACA, $064A, $0CAC, $0888
                dc.w    $0EEE, $0AAA, $0444, $0888

loc_128de:
                dc.w    $0000, $0A86, $000C, $0AAA
                dc.w    $0464, $004A, $0242, $008A
                dc.w    $0000, $0420, $0864, $0C6E
                dc.w    $0CCE, $0E8E, $0A0E, $0CAE

loc_128FE:
                dc.w    $0000, $0E00, $0E60, $0AAA
                dc.w    $0286, $02CA, $0044, $00A8
                dc.w    $0000, $0000, $0000, $00CC
                dc.w    $0EEE, $00EE, $0086, $08EE

loc_1291E:
                dc.w    $0000, $062E, $0EC0, $0E00
                dc.w    $00EE, $0AEE, $0066, $00CA
                dc.w    $0000, $0000, $0000, $0888
                dc.w    $0EEE, $0AAA, $0444, $0888

loc_1293E:
                dc.w    $0000, $0006, $000E, $0CC4
                dc.w    $04A8, $06EE, $0AAA, $08CC
                dc.w    $0CCC, $0AEE, $0000, $00C2
                dc.w    $0EEE, $00E6, $00A0, $04CA

loc_1295E:
                dc.w    $0000, $0048, $008E, $004E
                dc.w    $04E4, $0444, $008A, $0AA2
                dc.w    $00AE, $0882, $0000, $008E
                dc.w    $00EE, $028E, $002A, $00AA

loc_1297E:
                dc.w    $0000, $006A, $00EE, $00E0
                dc.w    $00AE, $00E0, $0086, $0068
                dc.w    $008A, $0066, $00AC, $0888
                dc.w    $0EEE, $0AAA, $0444, $0888

loc_1299E:
                dc.w    $0000, $0EAE, $0E6E, $0E48
                dc.w    $0C06, $004A, $008A, $004E
                dc.w    $0000, $0044, $0000, $00AA
                dc.w    $06CC, $00CC, $0066, $00A8

loc_129BE:
                dc.w    $0000, $0E00, $0E60, $0AAA
                dc.w    $0666, $0A6E, $0000, $0000
                dc.w    $04AE, $0006, $0002, $0EE0
                dc.w    $0EEE, $0EE6, $0E60, $0EEA
                
loc_129DE:
                dc.w    $0000, $062E, $0EC0, $0E00
                dc.w    $00EE, $0AEE, $0000, $0000
                dc.w    $04AE, $000A, $0002, $0A6C
                dc.w    $0EE6, $0C8E, $0406, $0EEC
; ======================================================================

loc_129fe:

                dc.w    loc_12A1C&$FFFF
                dc.w    loc_12A24&$FFFF
                dc.w    loc_12A2C&$FFFF
                dc.w    loc_12A34&$FFFF
                dc.w    loc_12A3C&$FFFF
                dc.w    loc_12A44&$FFFF
                dc.w    loc_12A4C&$FFFF
                dc.w    loc_12A54&$FFFF
                dc.w    loc_12A5C&$FFFF
                dc.w    loc_12A64&$FFFF
                dc.w    loc_12A6C&$FFFF
                dc.w    loc_12A74&$FFFF
                dc.w    loc_12A7C&$FFFF
                dc.w    loc_12A84&$FFFF
                dc.w    loc_12A8C&$FFFF

loc_12a1c:
                dc.w    $00EE, $0060, $0048, $004E

loc_12a24:
                dc.w    $00EE, $0040, $000A, $006A

loc_12A2C:
                dc.w    $0EEE, $0666, $0EE0, $0E44

loc_12a34:
                dc.w    $00AA, $08EE, $00CC, $000E

loc_12a3c:
                dc.w    $00AC, $00EC, $08EE, $0666

loc_12a44:
                dc.w    $08EE, $0AAA, $0CCA, $08C2

loc_12A4C:
                dc.w    $00EE, $0000, $028E, $000E

loc_12a54:
                dc.w    $000A, $0000, $00EE, $022E

loc_12A5C:
                dc.w    $0444, $0AAA, $0EEE, $020E

loc_12a64:
                dc.w    $0EEE, $0AAA, $004A, $008C

loc_12A6C:
                dc.w    $0EEE, $0000, $000E, $0CAE

loc_12A74:
                dc.w    $088E, $0000, $002C, $000A

loc_12A7C:
                dc.w    $0EEE, $0000, $0E22, $0600

loc_12A84:
                dc.w    $0EEE, $0666, $040C, $0A8E

loc_12a8c:
                dc.w    $0EEE, $0222, $0AAA, $0666

; ======================================================================

Level_Load:                                      ; $12A94
                jsr     (loc_100d4).l            ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette address into a5.
                jsr     ($FFFFFBBA).w            ; Load the palettes into the palette buffer.
                bsr.s   loc_12aba
                move.w  #$83,d0                  ; Load the level music ID.
                jsr     ($FFFFFB66).w            ; Play it.
                bsr.w   loc_12e00
                bsr.w   loc_12e2e
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_12aba:
                clr.b   ($FFFFD883).w
                bsr.w   loc_1268e
                bsr.w   Level_PalLoad
                move.w  #1,($FFFFFFA8).w
                moveq   #$30,d7
                bsr.w   loc_11774
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #-1,d1                   ; Set d1 to $FFFFFFFF.
                lea     LevelLayouts,a0             ; Load RAM address table.
                move.w  (a0,d0.w),d1             ; Overwrite lower word with the address.
                movea.l d1,a6                    ; Set as RAM address.
                move.w  d0,-(sp)                 ; Move d0's value onto the stack.
                bsr.w   loc_11422
                move.w  (sp)+,d0
                moveq   #-1,d1
                lea     loc_15508(pc),a0
                move.w  (a0,d0.w),d1
                movea.l d1,a6
                move.w  d0,-(sp)
                bsr.w   loc_11608                ; TODO IMPORTANT - INVESTIGATE
                move.w  (sp)+,d0
                lsl.w   #2,d0
                lea     loc_15b94(pc),a0
                move.l  (a0,d0.w),($FFFFD26E).w
                move.l  4(a0,d0.w),($FFFFD272).w
                tst.b   ($FFFFD886).w
                beq.s   loc_12b20
                clr.b   ($FFFFD886).w
                bsr.w   loc_1172c
loc_12b20:
                bsr.w   loc_12de4
                bsr.w   loc_11b60
                bsr.w   loc_12d1a
                bsr.w   loc_11700
                bsr.w   loc_11e06
                bsr.w   loc_11dc2
                bsr.w   loc_11dd4
                bsr.w   loc_11de6
                bsr.w   loc_11d88
                rts

; ======================================================================

loc_12b46:
                move.w  ($FFFFD2A0).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_12b6a(pc,d0.w)
                btst    #7,($FFFFFF8F).w         ; Is start being pressed?
                beq.s   loc_12B5E                ; If it isn't, branch.
                bsr.w   PauseGame                ; Pause the game.
loc_12B5E:
                bsr.w   loc_12e90
                bsr.w   loc_10d52
                jmp     ($FFFFFB6C).w

; ----------------------------------------------------------------------

loc_12b6a:
                bra.w   loc_12b7e
                bra.w   loc_12b9a
                bra.w   loc_12bdc
                bra.w   loc_12c9a
                bra.w   loc_12cda

; ----------------------------------------------------------------------

loc_12b7e:
                cmpi.l  #$1C000,($FFFFD296).w
                bgt.s   loc_12b8c
                addq.l  #7,($FFFFD296).w
loc_12b8c:
                bsr.w   loc_12d84
                bsr.w   CheckObjectRAM
                bsr.w   TimerCounter
                rts

; ----------------------------------------------------------------------

loc_12b9a:
                bset    #7,($FFFFD2A0).w
                bne.s   loc_12bd2
loc_12BA2:
                tst.b   ($FFFFD2A4).w
                beq.s   loc_12bb2
                bsr.w   loc_10d52
                jsr     ($FFFFFB6C).w

                bra.s   loc_12ba2

loc_12bb2:
                move.b  #$82,d0
                jsr     ($FFFFFB66).w
                move.w  #$8000,($FFFFD884).w
                bsr.w   loc_11e96
                clr.w   ($FFFFFF92).w
                lea     ($FFFFC040).w,a0
                move.w  #4,$3C(a0)
loc_12bd2:
                bsr.w   CheckObjectRAM
                bsr.w   loc_12d42
                rts

; ----------------------------------------------------------------------

loc_12bdc:
                bset    #7,($FFFFD2A0).w
                bne.s   loc_12c2e
                clr.w   ($FFFFFF92).w
                moveq   #$30,d7
                bsr.w   loc_11774
                move.b  d0,d1
                moveq   #0,d0
                move.b  ($FFFFD82D).w,d0
                addq.b  #5,d0
                moveq   #$30,d7
                bsr.w   loc_1176a
                lsr.w   #3,d0
                cmp.b   loc_12c7c(pc,d0.w),d1
                bne.s   loc_12c74
                tst.b   ($FFFFD88F).w
                bne.s   loc_12c70
                lsl.w   #2,d0
                move.l  loc_12c82(pc,d0.w),($FFFFD262).w
                moveq   #$A,d1
loc_12c16:
                jsr     ($FFFFFB6C).w
                dbf     d1,loc_12c16
                lea     ($FFFFC040).w,a0
                move.w  #$54,(a0)
                move.b  #$E1,d0
                jsr     ($FFFFFB66).w
loc_12c2e:
                lea     ($FFFFFF92).w,a0
                cmpi.w  #8,(a0)
                bne.s   loc_12c6a
                clr.w   (a0)
                move.w  #$8000,($FFFFD884).w
                bsr.w   loc_1168a
                movem.l d0/a0,-(sp)
                move.b  #$98,d0
                bsr.w   loc_10d48
                movem.l (sp)+,d0/a0
                addq.b  #1,($FFFFD88C).w
                cmpi.b  #$A,($FFFFD88C).w
                bne.s   loc_12c6a
                clr.b   ($FFFFD88C).w
                clr.b   ($FFFFD88D).w
                bra.s   loc_12c74

loc_12c6a:
                bsr.w   CheckObjectRAM
                rts

loc_12c70:
                clr.b   ($FFFFD88F).w
loc_12c74:
                move.w  #4,($FFFFD2A0).w
                rts

; ----------------------------------------------------------------------

loc_12c7c:
                dc.b    $02, $0A
                dc.b    $12, $1A
                dc.b    $22, $2A

; ======================================================================

loc_12C82:
                dc.l    $00200000
                dc.l    $00001000
                dc.l    $00005000
                dc.l    $00010000
                dc.l    $00050000
                dc.l    $00100000

; ======================================================================

loc_12c9a:
                moveq   #0,d0
                move.b  ($FFFFD82D).w,d0
                addq.b  #5,d0
                moveq   #$30,d7
                bsr.w   loc_1176a
                lsr.w   #3,d0
                lsl.w   #1,d0
                move.w  ($FFFFD888).w,d1
                cmp.w   loc_12cce(pc,d0.w),d1
                bhi.s   loc_12cc0
                cmpi.b  #1,($FFFFD88D).w
                bne.s   loc_12cc0
                bra.s   loc_12cc6

loc_12cc0:
                move.b  #1,($FFFFD88F).w
loc_12cc6:
                move.w  #8,($FFFFD2A0).w
                rts

; ----------------------------------------------------------------------

loc_12cce:
                dc.w    $0025, $0030, $0035, $0040
                dc.w    $0045, $0050

; ======================================================================
loc_12CDA:

                bset    #7,($FFFFD2A0).w
                bne.s   loc_12cfe
                moveq   #$1E,d1
loc_12ce4:
                jsr     ($FFFFFB6C).w
                dbf     d1,loc_12ce4
                move.b  #$84,d0
                jsr     ($FFFFFB66).w
                move.w  #$3C,($FFFFC000).w
                clr.b   ($FFFFD886).w
loc_12cfe:
                bsr.w   loc_111d4
                move.w  #$B4,d1
loc_12d06:
                jsr     ($FFFFFB6C).w
                dbf     d1,loc_12d06
                bsr.w   loc_11784
                move.w  #$40,($FFFFFFC0).w
                rts

; ======================================================================

loc_12d1a:
                moveq   #0,d7
                moveq   #0,d6
                lea     ($FFFFD82E).w,a0
                move.b  (a0),d7
                move.b  1(a0),d6
                bsr.w   loc_11674
                move.w  d7,($FFFFD25E).w
                addi.w  #$17,d7
                move.w  d7,($FFFFD260).w
                addi.w  #$18,d6
                move.w  d6,($FFFFD25C).w
                rts

; ======================================================================

loc_12d42:
                move.w  ($FFFFFF92).w,d0
                cmpi.w  #$FA,d0
                bhi.s   loc_12d56
                bsr.w   loc_11740
                bsr.w   loc_11e52
                rts

loc_12d56:
                addq.b  #1,($FFFFD82D).w
                bne.s   loc_12d60
                addq.b  #1,($FFFFD82D).w
loc_12D60:
                move.b  ($FFFFD82C).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,($FFFFD82C).w
                move.w  #$18,($FFFFFFC0).w
                cmpi.b  #$49,d0
                bne.s   loc_12D82
                move.w  #$30,($FFFFFFC0).w
loc_12D82:
                rts

; ======================================================================

loc_12d84:
                lea     ($FFFFC380).w,a0
                lea     ($FFFFC680).w,a1
                tst.w   (a0)
                bne.s   loc_12d98
                tst.w   (a1)
                bne.s   loc_12d98
                move.w  #$18,(a1)
loc_12d98:
                lea     ($FFFFC3C0).w,a0
                lea     ($FFFFC400).w,a1
                lea     ($FFFFC6C0).w,a2
                lea     ($FFFFC700).w,a3
                tst.w   (a0)
                bne.s   loc_12dbe
                tst.w   (a2)
                bne.s   loc_12dbe
                tst.w   (a3)
                bne.s   loc_12dbe
                move.w  #$18,(a2)
                move.b  #1,$16(a2)
loc_12dbe:
                cmpi.b  #$A,($FFFFD82D).w
                bcs.s   loc_12de2
                tst.w   (a1)
                bne.s   loc_12de2
                tst.w   (a3)
                bne.s   loc_12de2
                tst.w   (a2)
                bne.s   loc_12de2
                move.w  #$18,(a3)
                move.w  #4,$3C(a3)
                move.b  #2,$16(a3)
loc_12de2:
                rts

; ======================================================================

loc_12de4:
                lea     ($FFFFC480).w,a0
                moveq   #0,d1
                moveq   #7,d0
loc_12DEC:
                tst.w   (a0)
                beq.s   loc_12df2
                addq.b  #1,d1
loc_12df2:
                lea     $40(a0),a0
                dbf     d0,loc_12dec
                move.b  d1,($FFFFD883).w
                rts

; ======================================================================

loc_12e00:
                bsr.w   CheckObjectRAM
                jsr     ($FFFFFB6C).w
                moveq   #$3C,d2
loc_12E0A:
                bsr.w   TimerCounter             ; Update the timer.
                jsr     ($FFFFFB6C).w
                dbf     d2,loc_12e0a
                bsr.w   loc_11caa
                move.w  #$C,($FFFFC440).w
                bsr.w   CheckObjectRAM
                jsr     ($FFFFFB6C).w
                bsr.w   loc_11cca
                rts

; ======================================================================

loc_12e2e:
                move.w  #$136,d1
                move.l  #$00014000,d2
                move.b  ($FFFFD82D).w,d0
                cmpi.b  #$20,d0
                bls.s   loc_12e44
                moveq   #$20,d0
loc_12e44:
                subq.w  #5,d1
                addi.l  #$00000200,d2
                dbf     d0,loc_12e44
                move.w  d1,($FFFFD294).w
                move.l  d2,($FFFFD27C).w
                move.l  #$00014000,($FFFFD296).w
                cmpi.b  #$30,($FFFFD82D).w
                bls.s   loc_12e70
                move.l  #$00018000,($FFFFD296).w
loc_12e70:
                moveq   #0,d1
                moveq   #$30,d7
                bsr.w   loc_11774
                subq.b  #1,d0
                lea     loc_15d28(pc),a0
                move.b  (a0,d0.w),d1
                lsl.w   #2,d1
                lea     loc_15d14(pc),a0
                move.l  (a0,d1.w),($FFFFD276).w
                rts

; ======================================================================

loc_12e90:
                move.l  ($FFFFD87E).w,d0
                moveq   #0,d1
                moveq   #4,d7
loc_12E98:
                btst    d1,($FFFFD887).w
                bne.s   loc_12eb2
                move.w  d1,d2
                lsl.w   #2,d2
                cmp.l   loc_12ee0(pc,d2.w),d0
                bcs.s   loc_12eb2
                bset    d1,($FFFFD887).w
                bsr.w   loc_12eba
                bra.s   loc_12eb8
loc_12eb2:
                addq.b  #1,d1
                dbf     d7,loc_12e98
loc_12eb8:
                rts

loc_12eba:
                move.l  d0,-(sp)
                move.b  #1,($FFFFD2A4).w
                move.b  #$97,d0
                jsr     ($FFFFFB36).w
                move.b  d0,($A01C09).l
                jsr     ($FFFFFB3C).w
                move.l  (sp)+,d0
                addq.b  #1,($FFFFD882).w
                bsr.w   loc_11d88
                rts

; ----------------------------------------------------------------------

loc_12ee0:
                dc.l    $00030000
                dc.l    $00080000
                dc.l    $00160000
                dc.l    $00240000
                dc.l    $00320000

; ======================================================================
; Pause the game.
; ======================================================================
PauseGame:                                       ; $12EF4
                jsr     ($FFFFFB36).w            ; Stop the Z80.
                move.b  #1,($A01C10).l
                jsr     ($FFFFFB3C).w            ; Start the Z80.
                move.w  #$58,($FFFFC000).w       ; Load the pause object.
loc_12F0A:
                bsr.w   loc_111d4
                jsr     ($FFFFFB6C).w
                btst    #7,($FFFFFF8F).w
                beq.s   loc_12f0a
                jsr     ($FFFFFB36).w
                move.b  #$80,($A01C10).l
                jsr     ($FFFFFB3C).w
                clr.w   ($FFFFC000).w
                rts

; ======================================================================

loc_12f30:
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                move.w  #$8F02,($C00004).l       ; Set the VDP auto increment to $02.
                lea     Pal_Main,a5              ; Load the main palette into a5.
                jsr     ($FFFFFBBA).w            ; Decode the palettes and write them into the palette buffer.
                move.w  #$2C,($FFFFF82E).w       ; TODO
                bsr.w   ClearBonusObjectRAM      ; Clear the allocated object RAM.
                bsr.w   loc_1268e                ; TODO
                bsr.w   Level_PalLoad                ; TODO
                move.b  #1,($FFFFD24E).w         ; Set the bonus stage flag.
                move.b  #$14,($FFFFD883).w
                bsr.w   loc_1194c                ; Dump mappings to Plane B from an address in RAM (Load roof tiles).
                bsr.w   loc_11976                ; Dump mappings to a certain part of Plane B from an address in RAM (TODO).
                lea     ($FFFFCAA0).w,a0         ; TODO
                moveq   #$1F,d0
loc_12F72:
                move.b  #1,(a0)+
                dbf     d0,loc_12f72
                lea     ($C00000).l,a0           ; Load the VDP data port into a0.
                move.l  #$65400003,($C00004).l   ; Set VDP to VRAM write, $E540.
                moveq   #$1F,d0                  ; Set to write $20 tiles.
loc_12F8C:
                move.w  #$220D,(a0)              ; Set to map the first 'platform' tile.
                dbf     d0,loc_12f8c             ; Repeat $1F tiles.
                lea     loc_12fcc(pc),a6         ; Set to write BONUS.
                bsr.w   WriteASCIIString         ; Write onto the screen.
                lea     loc_12fd4(pc),a6         ; Set to write STAGE.
                bsr.w   WriteASCIIString         ; Write onto the screen.
                bsr.w   loc_1303c                ; TODO - no more comments
                bsr.w   loc_11e06
                bsr.w   loc_11dc2
                bsr.w   loc_11dd4
                bsr.w   loc_11de6
                bsr.w   loc_11d88
                move.b  #$81,d0
                jsr     ($FFFFFB66).w
                jsr     ($FFFFFB6C).w
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_12fcc:
                dc.w    $C0D4                    ; Write to Plane A.
                dc.b    'BONUS'                  ; Text string.
                dc.b    $00                      ; String terminator.

loc_12fd4:
                dc.w    $C0E0                    ; Write to Plane A.
                dc.b    'ROUND'                  ; Text string.
                dc.b    $00                      ; String terminator.

; ======================================================================

loc_12fdc:
                move.w  ($FFFFD2A6).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_13000(pc,d0.w)
                btst    #7,($FFFFFF8F).w
                beq.s   loc_12FF4
                bsr.w   PauseGame                ; Pause the game
loc_12FF4:
                bsr.w   loc_12e90
                bsr.w   loc_10d52
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_13000:
                bra.w   loc_13008
                bra.w   loc_1300e

; ----------------------------------------------------------------------

loc_13008:
                bsr.w   CheckObjectRAM
                rts

; ----------------------------------------------------------------------

loc_1300e:
                bset    #7,($FFFFD2A6).w
                bne.s   loc_13032
loc_13016:
                tst.b   ($FFFFD2A4).w
                beq.s   loc_13026
                bsr.w   loc_10d52
                jsr     ($FFFFFB6C).w
                bra.s   loc_13016

loc_13026:
                move.b  #$82,d0
                jsr     ($FFFFFB66).w
                bsr.w   loc_1691c
loc_13032:
                bsr.w   CheckObjectRAM
                bsr.w   loc_130d4
                rts

; ======================================================================

loc_1303c:
                lea     ($FFFFC580).w,a0
                move.w  #$C,(a0)
                move.w  #$D11,$3E(a0)
                move.w  #$2C,($FFFFC040).w
                lea     ($FFFFC640).w,a0
                move.w  #$30,(a0)
                lea     $40(a0),a0
                move.w  #$30,(a0)
                move.b  #1,$16(a0)
                lea     ($FFFFC5C0).w,a0
                move.w  #$34,(a0)
                lea     $40(a0),a0
                move.w  #$34,(a0)
                move.b  #1,$16(a0)
                lea     ($FFFFC080).w,a0
                moveq   #0,d1
                moveq   #$13,d0
loc_13084:
                move.w  #$38,(a0)
                move.b  d1,$38(a0)
                btst    #2,d1
                beq.s   loc_13098
                move.b  #1,$39(a0)
loc_13098:
                lea     $40(a0),a0
                addq.b  #1,d1
                dbf     d0,loc_13084
                moveq   #0,d0
                move.b  ($FFFFD82D).w,d0
                moveq   #$30,d7
                bsr.w   loc_11764
                subq.b  #3,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     loc_169f4(pc),a0
                move.l  (a0,d0.w),($FFFFD282).w
                lea     loc_16a9c(pc),a0
                move.l  (a0,d0.w),($FFFFD286).w
                lea     loc_16c34(pc),a0
                move.l  (a0,d0.w),($FFFFD28A).w
                rts

; ======================================================================

loc_130d4:
                move.b  #1,($FFFFD27B).w
                move.w  ($FFFFFF92).w,d0         ; Move the game mode timer into d0.
                cmpi.w  #$FA,d0
                bhi.s   loc_130ee
                bsr.w   loc_11740
                bsr.w   loc_11f6c
                rts

loc_130ee:
                addq.b  #1,($FFFFD82D).w
                bne.s   loc_130f8
                addq.b  #1,($FFFFD82D).w
loc_130f8:
                move.b  ($FFFFD82C).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,($FFFFD82C).w
                move.w  #$18,($FFFFFFC0).w
                rts

; ======================================================================

loc_13110:
                jsr     (loc_100d4).l            ; Clear some variables, load some compressed art, set to load next game mode.
                clr.b   ($FFFFD88E).w
                bsr.w   loc_10126
                lea     Pal_Main,a5
                jsr     ($FFFFFBBA).w
                move.w  #$800,($FFFFF7E0).w
                bsr.w   loc_13566
                move.w  #$2700,sr
                moveq   #2,d2
                move.w  #loc_135E8_End-loc_135E8,d0 ; Data length.
                move.w  #$125B,d1                ; Relative address in Z80 RAM.
                lea     loc_135e8,a0             ; Data location.
                jsr     ($FFFFFB54).w
                move.w  #$2500,sr
                move.b  #$81,d0                  ; Music?
                jsr     ($FFFFFB66).w
                clr.w   ($FFFFFF92).w
                jsr     ($FFFFFB6C).w
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_13162:
                move.w  ($FFFFD29E).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_13176(pc,d0.w)
                bsr.w   CheckObjectRAM
                jmp     ($FFFFFB6C).w

; ----------------------------------------------------------------------

loc_13176:
                bra.w   loc_13182
                bra.w   loc_1321a
                bra.w   loc_13492

; ----------------------------------------------------------------------

loc_13182:
                bsr.w   loc_131d6
                cmpi.w  #$C8,($FFFFFF92).w
                bne.s   loc_131d4
                move.w  #4,($FFFFD29E).w
                move.w  #$8100,($FFFFD884).w
                move.w  #$0EEE,($FFFFF7E6).w
                bsr.w   loc_131da
                move.l  #$EFFFFFFF,($FFFFFFB8).w
                move.l  #$FFFFFFFF,($FFFFFFBC).w
                bsr.w   loc_11784
                lea     ($C00000).l,a0
                move.l  #$40000003,($C00004).l
                move.w  #$3FF,d0
loc_131cc:
                move.w  #0,(a0)
                dbf     d0,loc_131cc
loc_131d4:
                rts

loc_131d6:
                bsr.w   loc_11740
loc_131DA:
                lea     loc_131ec(pc),a6              ; TODO credits stuff.
                bsr.w   WriteASCIIString
                lea     loc_13200(pc),a6
                bsr.w   WriteASCIIString
                rts

; ----------------------------------------------------------------------

loc_131ec:
                dc.w    $C290                    ; VRAM address to write to.
                dc.b    'CONGRATULATIONS!'       ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_13200:
                dc.w    $C38A                    ; VRAM address to write to.
                dc.b    'YOU ARE A SUPER PLAYER.'; Mappings text.
                dc.b    $00                      ; String terminator.

; ----------------------------------------------------------------------


loc_1321a:
                bset    #7,($FFFFD29E).w
                bne.s   loc_1325a
                lea     Pal_Main,a5
                jsr     ($FFFFFBBA).w
                move.w  #$0EEE,($FFFFF7E6).w
                clr.l   ($FFFFFFB8).w
                clr.l   ($FFFFFFBC).w
                move.w  #$4000,($FFFFD00A).w
                lea     ($FFFFC000).w,a0
                moveq   #0,d1
                moveq   #4,d0
loc_13248:
                move.w  #$50,(a0)
                move.w  d1,$38(a0)
                lea     $40(a0),a0
                addq.w  #1,d1
                dbf     d0,loc_13248
loc_1325a:
                bsr.w   loc_1130c
                addq.b  #1,($FFFFD29D).w
                cmpi.b  #$20,($FFFFD29D).w
                bne.s   loc_1328c
                clr.b   ($FFFFD29D).w
                bsr.w   loc_1328e
                addq.b  #1,($FFFFD29C).w
                cmpi.b  #$5D,($FFFFD29C).w
                bne.s   loc_1328c
                move.w  #8,($FFFFD29E).w
                lea     ($FFFFC000).w,a0
                move.w  #$44,(a0)
loc_1328c:
                rts

loc_1328e:
                moveq   #0,d0
                moveq   #0,d5
                move.w  ($FFFFFFA4).w,d0
                andi.w  #$00FF,d0
                lsr.w   #3,d0
                subq.w  #2,d0
                bpl.s   loc_132a4
                addi.w  #$20,d0
loc_132a4:
                lsl.w   #6,d0
                addi.w  #$C008,d0
                move.w  d0,d5
                move.w  d5,d6
                bsr.w   loc_10F2e
                move.l  d5,($C00004).l
                moveq   #$1F,d1
loc_132BA:
                move.w  #0,($C00000).l
                dbf     d1,loc_132ba
                moveq   #0,d1
                move.b  ($FFFFD29C).w,d1
                lsl.w   #1,d1                 ; Multiply by two to handle word-sized tables.
                moveq   #-1,d2                ; Set d2 as $FFFFFFFF.
                lea     CreditsTextPointers(pc),a6 ; Load the credits table into a6.
                move.w  (a6,d1.w),d2          ; Load correct credits TODO over lower word, signifying its place in the RAM.
                movea.l d2,a6                 ; retrun
                bsr.w   loc_10Fae
                rts

; ======================================================================

CreditsTextPointers:                                                 ; $132E0.
                dc.w    loc_1339E&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_133AA&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_133B8&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_133C6&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_133D4&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF       *
                dc.w    loc_1339C&$FFFF, loc_133DE&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_133EE&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_133FA&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1340C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1341C&$FFFF, loc_1339C&$FFFF, loc_13426&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_13466&$FFFF, loc_1339C&$FFFF
                dc.w    loc_13470&$FFFF, loc_1339C&$FFFF, loc_1343A&$FFFF, loc_1339C&$FFFF
                dc.w    loc_13454&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_13478&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF, loc_1339C&$FFFF
                dc.w    loc_1339C&$FFFF, loc_1339C&$FFFF

; ----------------------------------------------------------------------

loc_1339C:
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_1339e:
                dc.b    '     STAFF'             ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_133AA:
                dc.b    '    DIRECTOR'           ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_133B8:
                dc.b    '     K.FUZZY'           ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_133C6:
                dc.b    '    DESIGNER'           ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_133D4:
                dc.b    '     YUMI'              ; ASCII string.
                dc.b    $00                      ; Terminate the string.

loc_133de:
                dc.b    '    PROGRAMMER'         ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_133EE:
                dc.b    '     O.SAMU'            ; ASCII string.
                dc.b    $00                      ; Terminate the string.

loc_133fa:
                dc.b    '    SOUND DESIGN'       ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_1340C:
                dc.b    '     T@S MUSIC'         ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_1341C:
                dc.b    '      AND'              ; ASCII string.
                dc.b    $00                      ; Terminate the string.

loc_13426:
                dc.b    '    SPECIAL THANKS'     ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_1343A:
                dc.b    '     ARCADE FLICKY STAFF' ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_13454:
                dc.b    '     TEST PLAYERS'      ; ASCII string.
                dc.b    $00                      ; Terminate the string.


loc_13466:
                dc.b    '     LEE'               ; ASCII string.
                dc.w    $0000                    ; Terminate the string, pad to even.

loc_13470:
                dc.b    '     BO'                ; ASCII string.
                dc.b    $00                      ; Terminate the string.

loc_13478:
                dc.b    'CHALLENGE THE NEXT STAGE.' ; ASCII string.
                dc.b    $00                      ; Terminate the string.

; ======================================================================

loc_13492:
                btst    #7,($FFFFFF8F).w
                beq.s   loc_134ba
                bsr.w   loc_11784
                move.b  #1,($FFFFD88E).w
                bsr.w   loc_10126
                move.w  #$18,($FFFFFFC0).w
                move.w  #$2700,sr
                bsr.w   loc_10CF6
                move.w  #$2500,sr
loc_134ba:
                rts

; ======================================================================

loc_134bc:
                bset    #7,(a0)
                bne.s   loc_134e2
                bset    #1,2(a0)
                move.w  $38(a0),d0
                move.b  loc_13516(pc,d0.w),$3A(a0)
                lsl.w   #1,d0
                move.w  loc_1350c(pc,d0.w),6(a0)
                lsl.w   #1,d0
                move.l  loc_134f8(pc,d0.w),8(a0)
loc_134e2:
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     loc_134f0(pc,d0.w)
                rts

; ----------------------------------------------------------------------

loc_134f0:
                bra.w   loc_1351c
                bra.w   loc_1352e

; ----------------------------------------------------------------------

loc_134f8:
                dc.l    loc_144AC
                dc.l    loc_14E12
                dc.l    loc_14E22
                dc.l    loc_154AE
                dc.l    loc_162BC

; ----------------------------------------------------------------------

loc_1350c:
                dc.w    $0004, $0000
                dc.w    $0000, $0008
                dc.w    $0010

; ----------------------------------------------------------------------

loc_13516:
                dc.b    $0D, $17, $21
                dc.b    $2B, $3D, $00

; ======================================================================

loc_1351c:
                move.b  ($FFFFD29C).w,d0
                cmp.b   $3A(a0),d0
                bne.s   loc_1352c
                move.w  #4,$3C(a0)
loc_1352c:
                rts

; ----------------------------------------------------------------------

loc_1352e:
                bset    #7,$3C(a0)
                bne.s   loc_13550
                move.w  #$E4,$30(a0)
                move.w  #$178,$24(a0)
                move.l  #$FFFFC000,$2C(a0)
                bclr    #1,2(a0)
loc_13550:
                bsr.w   loc_1105c
                cmpi.w  #$78,$24(a0)
                bgt.s   loc_13560
                bsr.w   loc_110f0
loc_13560:
                bsr.w   AnimateSprite
                rts

; ======================================================================

loc_13566:
                moveq   #9,d0
                moveq   #0,d1
loc_1356A:
                moveq   #0,d5
                movem.l d0-d1,-(sp)
                lsl.w   #1,d1
                move.w  loc_135d4(pc,d1.w),d5
                moveq   #-1,d2
                move.w  loc_13598(pc,d1.w),d2
                movea.l d2,a6
                lsl.w   #1,d1
                move.w  loc_135ac(pc,d1.w),d7
                move.w  loc_135ae(pc,d1.w),d6
                bsr.w   PlaneMaptoVRAM
                movem.l (sp)+,d0-d1
                addq.w  #1,d1
                dbf     d0,loc_1356a
                rts

; ======================================================================
; RAM table TODO
loc_13598:
                dc.w    WallpaperScenery1&$FFFF
                dc.w    WallpaperTiles1&$FFFF
                dc.w    WallpaperTiles2&$FFFF
                dc.w    WallpaperTiles2&$FFFF
                dc.w    WallpaperTiles2&$FFFF
                dc.w    WallpaperTiles2&$FFFF
                dc.w    WallpaperTiles2&$FFFF
                dc.w    WallpaperTiles2&$FFFF
                dc.w    WallpaperScenery1&$FFFF
                dc.w    WallpaperTiles1&$FFFF

; ======================================================================
loc_135AC:	dc.w 3			; DATA XREF: sub_13566+1Ar
loc_135AE:	dc.w 3			; DATA XREF: sub_13566+1Er
		dc.w 4
		dc.w 2
		dc.w 4
		dc.w 2
		dc.w 4
		dc.w 2
		dc.w 4
		dc.w 2
		dc.w 4
		dc.w 2
		dc.w 4
		dc.w 2
		dc.w 4
		dc.w 2
		dc.w 3
		dc.w 3
		dc.w 4
		dc.w 2
loc_135D4:	dc.w $E132		; DATA XREF: sub_13566+Cr
		dc.w $E4B2
		dc.w $E642
		dc.w $E64C
		dc.w $E656
		dc.w $E660
		dc.w $E66A
		dc.w $E674
		dc.w $E446
		dc.w $E146

; ======================================================================

loc_135e8:
                incbin  "loc_135E8.bin"
loc_135E8_End:

; ======================================================================

loc_139a2:
                jsr     (loc_100d4).l            ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette's address into a5.
                jsr     ($FFFFFBBA).w            ; Decode it and write it into the palette buffer.
                move.w  ($FFFFD890).w,d0
                andi.w  #3,d0
                move.b  loc_13a08(pc,d0.w),($FFFFD82D).w
                move.b  loc_13a0c(pc,d0.w),($FFFFD82C).w
                lsl.w   #1,d0
                move.w  loc_13a10(pc,d0.w),($FFFFD2AA).w
                moveq   #-1,d1
                move.w  ($FFFFD2AA).w,d1
                movea.l d1,a0
                move.b  (a0),($FFFFD2A8).w
                move.b  1(a0),($FFFFD2AC).w
                addq.w  #1,($FFFFD890).w
                bsr.w   loc_12aba
                clr.l   ($FFFFD888).w
                clr.b   ($FFFFD88D).w
                move.b  #1,($FFFFD2A5).w
                move.w  #$44,($FFFFC000).w
                bsr.w   loc_12e00
                bsr.w   loc_12e2e
                jmp     ($FFFFFB6C).w

; ----------------------------------------------------------------------

loc_13a08:
                dc.b    $01, $0A, $14, $18
loc_13a0c:
                dc.b    $01, $10, $20, $24

; ----------------------------------------------------------------------

loc_13a10:
                dc.w    loc_13A82&$FFFF
                dc.w    loc_13B82&$FFFF
                dc.w    loc_13C52&$FFFF
                dc.w    loc_13D70&$FFFF

; ======================================================================

loc_13A18:
                btst    #7,($FFFFFF8F).w
                beq.s   loc_13a2a
                bsr.w   loc_11784
                move.w  #0,($FFFFFFC0).w
loc_13a2a:
                bsr.w   loc_13a5e
                cmpi.l  #$0001C000,($FFFFD296).w
                bgt.s   loc_13a3c
                addq.l  #7,($FFFFD296).w
loc_13a3c:
                bsr.w   loc_12d84
                bsr.w   CheckObjectRAM
                bsr.w   TimerCounter
                bclr    #0,($FFFFD886).w
                beq.s   loc_13a5a
                bsr.w   loc_11784
                move.w  #$40,($FFFFFFC0).w
loc_13a5a:
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_13a5e:
                moveq   #-1,d0
                move.w  ($FFFFD2AA).w,d0
                movea.l d0,a0
                move.b  (a0),($FFFFFF8E).w
                subq.b  #1,($FFFFD2AC).w
                bne.s   loc_13a80
                addq.l  #2,a0
                move.b  (a0),($FFFFD2A8).w
                move.b  1(a0),($FFFFD2AC).w
                move.w  a0,($FFFFD2AA).w
loc_13a80:
                rts

; ======================================================================
loc_13a82:
                incbin  "loc_13A82.bin"

loc_13b82:
                incbin  "loc_13B82.bin"

loc_13C52:
                incbin  "loc_13C52.bin"

loc_13d70:
                incbin  "loc_13D70.bin"

; ======================================================================

loc_13e70:
                bset    #7,(a0)                  ; Set the object as loaded.
                bne.s   loc_13ea0                ; If it was already loaded, branch.
                move.l  #loc_144AC,8(a0)
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   loc_11674
                addi.w  #$C,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.b  #3,$3A(a0)
loc_13ea0:
                tst.b   ($FFFFD27B).w
                bne.s   loc_13edc
                tst.b   ($FFFFD24F).w
                bne.s   loc_13eb6
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_13ede(pc,d0.w)
loc_13eb6:
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #4,d0
                bcc.s   loc_13ece
                tst.b   ($FFFFD24F).w
                bne.s   loc_13ece
                bsr.w   loc_14476
loc_13ece:
                bsr.w   loc_14272
                tst.b   ($FFFFD24E).w
                bne.s   loc_13edc
                bsr.w   loc_11c3c
loc_13edc:
                rts

; ======================================================================

loc_13ede:
                bra.w   loc_13eea
                bra.w   loc_1438c
                bra.w   loc_143fc

; ----------------------------------------------------------------------

loc_13eea:
                move.b  #$1E,5(a0)
                bsr.s   loc_13f26
                bsr.w   loc_142d6
                tst.b   ($FFFFD24F).w
                bne.s   loc_13f00
                bsr.w   loc_1130c
loc_13f00:
                bsr.w   loc_1105c
                bsr.w   loc_1407e
                bsr.w   loc_14128
                bsr.w   loc_14318
                move.l  $34(a0),d0
                beq.s   loc_13f24
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   loc_13f24
                clr.b   $39(a0)
loc_13f24:
                rts

; ======================================================================

loc_13f26:
                move.b  ($FFFFFF8E).w,d0
                andi.b  #$C,d0
                beq.w   loc_13faa
                btst    #3,d0
                bne.w   loc_13fce
                btst    #2,d0
                bne.w   loc_13fec
loc_13F42:
                move.l  $30(a0),d2
                move.l  d1,$34(a0)
                tst.b   ($FFFFD24E).w
                bne.s   loc_13f54
                move.l  d1,($FFFFD004).w
loc_13f54:
                bsr.w   loc_14038
                tst.b   $38(a0)
                bne.w   loc_1400a
                btst    #0,$3A(a0)
                beq.s   loc_13f98
                move.b  ($FFFFFF8E).w,d0
                andi.b  #$70,d0
                beq.s   loc_13f98
                move.l  a0,-(sp)
                move.b  #$91,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                move.b  #1,$38(a0)
                move.l  #$FFFD7000,$2C(a0)
                bclr    #0,$3A(a0)
                bclr    #1,$3A(a0)
loc_13f98:
                move.b  ($FFFFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   loc_13fa8
                move.b  #3,$3A(a0)
loc_13fa8:
                rts

loc_13faa:
                move.l  $34(a0),d1
                tst.b   $38(a0)
                bne.s   loc_13f42
                tst.l   d1
                beq.s   loc_13fca
                tst.l   d1
                bmi.s   loc_13fc4
                subi.l  #$00000600,d1
                bra.s   loc_13fca

loc_13fc4:
                addi.l  #$00000600,d1
loc_13fca:
                bra.w   loc_13f42

loc_13fce:
                move.l  $34(a0),d1
                cmpi.l  #$00018000,d1
                bge.s   loc_13fe2
                addi.l  #$00001800,d1
                bra.s   loc_13fe8

loc_13fe2:
                move.l  #$00018000,d1
loc_13fe8:
                bra.w   loc_13f42

loc_13fec:
                move.l  $34(a0),d1
                cmpi.l  #$FFFE8000,d1
                ble.s   loc_14000
                subi.l  #$00001800,d1
                bra.s   loc_14006

loc_14000:
                move.l  #$FFFE8000,d1
loc_14006:
                bra.w   loc_13f42

loc_1400a:
                cmpi.l  #$00030000,$2C(a0)
                bge.s   loc_1401c
                addi.l  #$00001000,$2C(a0)
loc_1401c:
                move.b  ($FFFFFF8E).w,d0
                andi.b  #$70,d0
                bne.s   loc_1402c
                move.b  #3,$3A(a0)
loc_1402c:
                rts

; ----------------------------------------------------------------------

loc_1402e                                        ; Unused code.
                clr.b   $38(a0)
                clr.l   $2C(a0)
                rts

; ======================================================================

loc_14038:
                btst    #1,$3A(a0)
                beq.s   loc_1407c
                move.b  ($FFFFFF8E).w,d0
                andi.b  #$70,d0
                beq.s   loc_1407c
                tst.b   $3B(a0)
                beq.s   loc_1407c
                movea.l ($FFFFD250).w,a1
                move.w  #4,$34(a1)
                tst.b   $39(a0)
                beq.s   loc_14066
                move.w  #$FFFC,$34(a1)
loc_14066:
                move.w  #8,$3C(a1)
                move.l  $30(a0),$30(a1)
                clr.b   $3B(a0)
                bclr    #1,$3A(a0)
loc_1407c:
                rts

; ======================================================================

loc_1407e:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                tst.b   $38(a0)
                bne.s   loc_1409e
                addq.w  #1,d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_1409c
                move.b  #1,$38(a0)
loc_1409c:
                rts

loc_1409e:
                tst.l   $34(a0)
                bne.s   loc_140da
                tst.l   $2C(a0)
                bpl.s   loc_140bc
                subi.w  #$E,d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_140ba
                clr.l   $2C(a0)
loc_140ba:
                rts

loc_140bc:
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_140d8
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
loc_140d8:
                rts

; ======================================================================

loc_140da:
                tst.l   $2C(a0)
                bpl.s   loc_140fe
                subi.w  #$E,d6
                addq.w  #4,d7
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_140f8
                subq.w  #8,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_140fc
loc_140f8:
                clr.l   $2C(a0)
loc_140fc:
                rts

loc_140fe:
                subq.w  #4,d7
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_14112
                addq.w  #8,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14126
loc_14112:
                clr.b   $38(a0)
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
loc_14126:
                rts

; ======================================================================

loc_14128:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.l  $34(a0),d5
                tst.b   $38(a0)
                bne.s   loc_1419a
                subi.w  #$A,d6
                tst.l   d5
                beq.s   loc_1416e
                tst.l   d5
                bpl.s   loc_14170
                subq.w  #6,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_1416e
                move.l  $34(a0),d0
                subi.l  #$00003000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   loc_14168
                move.l  #$FFFE0200,d0
loc_14168:
                neg.l   d0
                move.l  d0,$34(a0)
loc_1416e:
                rts

loc_14170:
                addq.w  #6,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14198
                move.l  $34(a0),d0
                addi.l  #$00003000,d0
                cmpi.l  #$0001FE00,d0
                ble.s   loc_14192
                move.l  #$0001FE00,d0
loc_14192:
                neg.l   d0
                move.l  d0,$34(a0)
loc_14198:
                rts

; ======================================================================

loc_1419a:
                subq.w  #8,d6
                tst.l   d5
                beq.w   loc_14248
                tst.l   d5
                bpl.s   loc_141dc
                subq.w  #6,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_141da
                btst    #1,d4
                bne.s   loc_141BC
                btst    #0,d4
                beq.s   loc_14212
loc_141BC:
                move.l  $34(a0),d0
                subi.l  #$00003000,d0
                cmpi.l  #$FFFE0200,d0
                bge.s   loc_141d4
                move.l  #$FFFE0200,d0
loc_141d4:
                neg.l   d0
                move.l  d0,$34(a0)
loc_141da:
                rts

loc_141dc:
                addq.w  #6,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14210
                btst    #1,d4
                bne.s   loc_141f2
                btst    #0,d4
                beq.s   loc_14212
loc_141f2:
                move.l  $34(a0),d0
                addi.l  #$00003000,d0
                cmpi.l  #$0001FE00,d0
                ble.s   loc_1420a
                move.l  #$0001FE00,d0
loc_1420a:
                neg.l   d0
                move.l  d0,$34(a0)
loc_14210:
                rts

loc_14212:
                tst.l   $2C(a0)
                bpl.s   loc_14232
                move.w  d6,d0
                andi.w  #7,d0
                cmpi.w  #3,d0
                blt.s   loc_14230
                addi.w  #$10,d6
                move.w  d6,$24(a0)
                clr.l   $2C(a0)
loc_14230:
                rts

loc_14232:
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                clr.l   $2C(a0)
                clr.b   $38(a0)
                rts

loc_14248:
                addq.w  #6,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_1425c
                move.l  #$FFFF4000,$34(a0)
                bra.s   loc_14270

loc_1425c:
                subi.w  #$C,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14270
                move.l  #$0000C000,$34(a0)
loc_14270:
                rts

; ======================================================================

loc_14272:
                lea     ($FFFFD206).w,a2
                lea     ($FFFFD1FE).w,a1
                lea     ($FFFFD20A).w,a4
                lea     ($FFFFD202).w,a3
                moveq   #$3F,d0
loc_14284:
                move.l  (a1),(a2)
                move.l  (a3),(a4)
                subq.l  #8,a1
                subq.l  #8,a2
                subq.l  #8,a3
                subq.l  #8,a4
                dbf     d0,loc_14284
                lea     ($FFFFD24E).w,a2
                lea     ($FFFFD24D).w,a1
                moveq   #$3F,d0
loc_1429e:
                move.b  -(a1),-(a2)
                dbf     d0,loc_1429e
                move.l  $30(a0),($FFFFD00E).w
                move.l  $24(a0),($FFFFD012).w
                moveq   #0,d0
                tst.b   $38(a0)
                beq.s   loc_142bc
                bset    #7,d0
loc_142bc:
                move.l  $34(a0),d7
                beq.s   loc_142d0
                tst.l   d7
                bpl.s   loc_142cc
                bset    #1,d0
                bra.s   loc_142d0

loc_142cc:
                bset    #0,d0
loc_142d0:
                move.b  d0,($FFFFD20E).w
                rts

; ======================================================================

loc_142d6:
                tst.b   ($FFFFD27A).w
                beq.s   loc_14316
                tst.b   $38(a0)
                bne.s   loc_14316
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                cmp.w   ($FFFFD25C).w,d6
                bne.s   loc_14316
                cmp.w   ($FFFFD25E).w,d7
                blt.s   loc_14316
                cmp.w   ($FFFFD260).w,d7
                bgt.s   loc_14316
                move.b  #1,($FFFFD24F).w
                clr.l   $34(a0)
                clr.l   ($FFFFD004).w
                addq.b  #1,($FFFFD88D).w
                move.l  a0,-(sp)
                bsr.w   loc_11ce6
                movea.l (sp)+,a0
loc_14316:
                rts

; ======================================================================

loc_14318:
                bclr    #7,2(a0)
                move.l  $34(a0),d0
                move.b  ($FFFFFF8E).w,d1
                tst.b   $38(a0)
                bne.s   loc_14366
                tst.l   d0
                beq.s   loc_1435c
                tst.l   d0
                bpl.s   loc_14342
                bset    #7,2(a0)
                btst    #2,d1
                bne.s   loc_14352
                bra.s   loc_14348

loc_14342:
                btst    #3,d1
                bne.s   loc_14352
loc_14348:
                move.l  #loc_1A8A0,$C(a0)
                rts

loc_14352:
                clr.w   6(a0)
                bsr.w   AnimateSprite
                rts

loc_1435c:
                move.l  #loc_1A898,$C(a0)
                rts

loc_14366:
                tst.l   d0
                beq.s   loc_14380
                move.w  #8,6(a0)
                tst.l   d0
                bpl.s   loc_1437A
                bset    #7,2(a0)
loc_1437A:
                bsr.w   AnimateSprite
                rts

loc_14380:
                move.w  #4,6(a0)
                bsr.w   AnimateSprite
                rts

; ======================================================================

loc_1438c:
                bset    #7,$3C(a0)
                bne.s   loc_143ae
                move.l  a0,-(sp)
                move.b  #$87,d0
                jsr     ($FFFFFB66).w
                movea.l (sp)+,a0
                clr.b   5(a0)
                clr.l   $34(a0)
                move.w  #$C,6(a0)
loc_143ae:
                addi.l  #$00001000,$2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_143e4
                tst.l   $2C(a0)
                bpl.s   loc_143de
                subq.w  #8,d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_143de
                clr.l   $2C(a0)
loc_143de:
                bsr.w   AnimateSprite
                rts

loc_143e4:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)
                rts

; ======================================================================

loc_143fc:
                bset    #7,$3C(a0)
                bne.s   loc_14418
                clr.b   5(a0)
                clr.b   $10(a0)
                bclr    #2,2(a0)
                move.b  #3,$39(a0)
loc_14418:
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
                bclr    #2,2(a0)
                beq.s   loc_14430
                subq.b  #1,$39(a0)
                bsr.w   loc_14464
loc_14430:
                tst.b   $39(a0)
                bne.s   loc_14462
                subq.b  #1,($FFFFD882).w
                beq.s   loc_1445c
                move.b  #1,($FFFFD886).w
                bsr.w   loc_11722
                move.w  #$20,($FFFFFFC0).w
                moveq   #$3C,d2
loc_1444E:
                bsr.w   TimerCounter
                jsr     ($FFFFFB6C).w
                dbf     d2,loc_1444e
                bra.s   loc_14462

loc_1445c:
                move.w  #$10,($FFFFD2A0).w
loc_14462:
                rts

loc_14464:
                lea     ($FFFFC380).w,a1
                moveq   #2,d0
loc_1446a:
                clr.w   (a1)
                lea     $40(a1),a1
                dbf     d0,loc_1446a
                rts

; ======================================================================

loc_14476:
                lea     ($FFFFC380).w,a1
                moveq   #2,d1
loc_1447C:
                btst    #0,5(a1)
                beq.s   loc_144a2
                movem.w d1,-(sp)
                bsr.w   loc_117c0
                movem.w (sp)+,d1
                tst.b   d0
                beq.s   loc_144a2
                move.w  #4,$3C(a0)
                move.b  #1,($FFFFD26D).w
                bra.s   loc_144AA

loc_144a2:
                lea     $40(a1),a1
                dbf     d1,loc_1447c
loc_144AA:
                rts

; ======================================================================

loc_144ac:
                dc.l    loc_144BC                ; Flicky running.
                dc.l    loc_144C2
                dc.l    loc_144C8
                dc.l    loc_144CE

; ----------------------------------------------------------------------

loc_144bc:
                dc.b    $02, $02                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A8A8&$FFFF          ; Flicky jumping.
                dc.w    loc_1A8B0&$FFFF          ; Flicky running.

; ----------------------------------------------------------------------

loc_144c2:
                dc.b    $02, $02                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A8B8&$FFFF
                dc.w    loc_1A8C0&$FFFF

; ----------------------------------------------------------------------

loc_144c8:
                dc.b    $02, $02
                dc.w    loc_1A8C8&$FFFF
                dc.w    loc_1A8D0&$FFFF

loc_144ce:
                dc.b    $06, $03
                dc.w    loc_1A878&$FFFF
                dc.w    loc_1A880&$FFFF
                dc.w    loc_1A888&$FFFF
                dc.w    loc_1A890&$FFFF
                dc.w    loc_1A888&$FFFF
                dc.w    loc_1A890&$FFFF

; ======================================================================

loc_144dc:
                bset    #7,(a0)
                bne.s   loc_14504
                move.b  ($FFFFD834).w,d7
                move.b  ($FFFFD835).w,d6
                bsr.w   loc_11674
                addq.w  #8,d7
                addi.w  #$18,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #loc_14524,8(a0)
loc_14504:
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                jsr     loc_14516(pc,d0.w)
                bsr.w   loc_1105c
                rts
                
; ----------------------------------------------------------------------

loc_14516:
                bra.w   loc_1451e
                bra.w   loc_14522
                
; ----------------------------------------------------------------------

loc_1451e:
                bsr.w   AnimateSprite

; ----------------------------------------------------------------------

loc_14522:
                rts

; ----------------------------------------------------------------------

loc_14524:
                dc.l    loc_14528
                
; ----------------------------------------------------------------------


loc_14528:
                dc.b    $02, $08
                dc.w    loc_1AD82&$FFFF
                dc.w    loc_1AD8A&$FFFF

; ======================================================================

loc_1452e:
                bset    #7,(a0)
                bne.s   loc_1455e
                move.l  ($FFFFD828).w,d0
                move.l  d0,$C(a0)
                move.b  #$60,$13(a0)
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   loc_11674
                addq.w  #8,d7
                addq.w  #8,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
loc_1455e:
                tst.b   ($FFFFD27B).w
                bne.s   loc_1457a
                tst.b   ($FFFFD24F).w            ; Has everything been set to stop (depositing flickies)?
                bne.s   loc_1457a                ; If it has, branch.
                tst.b   ($FFFFD26D).w
                bne.s   loc_1457a
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1457c(pc,d0.w)
loc_1457a:
                rts

; ----------------------------------------------------------------------

loc_1457c:
                bra.w   loc_14588
                bra.w   loc_145bc
                bra.w   loc_14610

; ----------------------------------------------------------------------

loc_14588:
                move.b  #1,5(a0)
                lea     ($FFFFC440).w,a1
                tst.l   $2C(a1)
                bmi.s   loc_145b6
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_145b6
                tst.b   $3B(a1)
                bne.s   loc_145b6
                move.w  #4,$3C(a0)
                move.b  #1,$3B(a1)
                move.l  a0,($FFFFD250).w
loc_145b6:
                bsr.w   loc_1105c
                rts

; ----------------------------------------------------------------------

loc_145bc:
                bset    #7,$3C(a0)
                bne.s   loc_145d0
                move.l  a0,-(sp)
                move.b  #$92,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
loc_145d0:
                clr.b   5(a0)
                lea     ($FFFFC440).w,a1
                move.l  $30(a1),d7
                move.l  $24(a1),d6
                tst.b   $38(a1)
                beq.s   loc_145ee
                addi.l  #$00060000,d6
                bra.s   loc_14602

loc_145ee:
                tst.b   $39(a1)
                bne.s   loc_145fc
                addi.l  #$00080000,d7
                bra.s   loc_14602

loc_145fc:
                subi.l  #$00080000,d7
loc_14602:
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                bsr.w   loc_1105c
                rts

; ----------------------------------------------------------------------

loc_14610:
                bset    #7,$3C(a0)
                bne.s   loc_14650
                move.l  a0,-(sp)
                move.b  #$96,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                move.b  #$18,5(a0)
                move.l  #loc_14730,8(a0)
                clr.b   $3B(a0)
                moveq   #0,d0
                move.b  ($FFFFD82D).w,d0
loc_1463C:
                cmpi.b  #$F,d0
                bls.s   loc_14648
                subi.b  #$F,d0
                bra.s   loc_1463c

loc_14648:
                subq.b  #1,d0
                lsl.w   #2,d0
                move.w  d0,6(a0)
loc_14650:
                bsr.w   loc_14688
                tst.l   $34(a0)
                bne.s   loc_1465c
                clr.w   (a0)
loc_1465c:
                bsr.w   loc_14662
                rts

loc_14662:
                move.w  $20(a0),d7
                move.w  d7,d6
                lea     ($FFFFC440).w,a1
                move.w  $20(a1),d5
                move.w  d5,d4
                sub.w   d7,d5
                cmpi.w  #$7C,d5
                bge.s   loc_14684
                sub.w   d4,d6
                cmpi.w  #$7C,d6
                bge.s  loc_14684
                bra.s  loc_14686

loc_14684:
                clr.w  (a0)
loc_14686:
                rts

loc_14688:
                move.l  $34(a0),d7
                move.l  $2C(a0),d6
                bclr    #7,2(a0)
                tst.l   d7
                bpl.s   loc_146A0
                bset    #7,2(a0)
loc_146A0:
                bsr.w   AnimateSprite
                tst.b   $38(a0)
                bne.s   loc_146be
                tst.l   d7
                bpl.s   loc_146b6
                addi.l  #$0000800,d7
                bra.s   loc_146bc

loc_146b6:
                subi.l  #$00000800,d7
loc_146bc:
                bra.s   loc_146c4
loc_146be:
                addi.l  #$00001000,d6
loc_146c4:
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_146fa
                clr.l   $2C(a0)
                clr.b   $38(a0)
                move.w  d6,d5
                andi.w  #$FFF8,d5
                move.w  d5,$24(a0)
                clr.w   $26(a0)
                bra.s   loc_14700

loc_146fa:
                move.b  #1,$38(a0)
loc_14700:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #4,d6
                tst.l   $34(a0)
                bpl.s   loc_14720
                subq.w  #4,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_1471e
                neg.l   $34(a0)
loc_1471e:
                rts

loc_14720:
                addq.w  #4,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_1472e
                neg.l   $34(a0)
loc_1472e:
                rts

; ----------------------------------------------------------------------
                                ; TODO   RAM table stuff!
loc_14730:
                dc.l    loc_1476C
                dc.l    loc_1477A
                dc.l    loc_14788
                dc.l    loc_14796
                dc.l    loc_147A4
                dc.l    loc_147B2
                dc.l    loc_147C0
                dc.l    loc_147CE
                dc.l    loc_147DC
                dc.l    loc_147EA
                dc.l    loc_147F8
                dc.l    loc_14806
                dc.l    loc_14814
                dc.l    loc_14822
                dc.l    loc_14830

; ----------------------------------------------------------------------

loc_1476c: 
                dc.b    $06, $01
                dc.w    loc_1A4E8&$FFFF
                dc.w    loc_1A4F8&$FFFF
                dc.w    loc_1A508&$FFFF
                dc.w    loc_1A4F0&$FFFF
                dc.w    loc_1A510&$FFFF
                dc.w    loc_1A500&$FFFF

; ----------------------------------------------------------------------

loc_1477a:
                dc.b    $06, $01
                dc.w    loc_1A518&$FFFF
                dc.w    loc_1A528&$FFFF
                dc.w    loc_1A538&$FFFF
                dc.w    loc_1A520&$FFFF
                dc.w    loc_1A540&$FFFF
                dc.w    loc_1A530&$FFFF
                
; ----------------------------------------------------------------------

loc_14788:
                dc.b    $06, $01
                dc.w    loc_1A548&$FFFF
                dc.w    loc_1A558&$FFFF
                dc.w    loc_1A568&$FFFF
                dc.w    loc_1A550&$FFFF
                dc.w    loc_1A570&$FFFF
                dc.w    loc_1A560&$FFFF
                
; ----------------------------------------------------------------------

loc_14796:
                dc.b    $06, $01
                dc.w    loc_1A578&$FFFF
                dc.w    loc_1A588&$FFFF
                dc.w    loc_1A598&$FFFF
                dc.w    loc_1A580&$FFFF
                dc.w    loc_1A5A0&$FFFF
                dc.w    loc_1A590&$FFFF

; ----------------------------------------------------------------------

loc_147a4:
                dc.b    $06, $01
                dc.w    loc_1A5A8&$FFFF
                dc.w    loc_1A5B8&$FFFF
                dc.w    loc_1A5C8&$FFFF
                dc.w    loc_1A5B0&$FFFF
                dc.w    loc_1A5D0&$FFFF
                dc.w    loc_1A5C0&$FFFF
                
; ----------------------------------------------------------------------

loc_147b2:

                dc.b    $06, $01
                dc.w    loc_1A5D8&$FFFF
                dc.w    loc_1A5E8&$FFFF
                dc.w    loc_1A5F8&$FFFF
                dc.w    loc_1A5E0&$FFFF
                dc.w    loc_1A600&$FFFF
                dc.w    loc_1A5F0&$FFFF

; ----------------------------------------------------------------------

loc_147c0:

                dc.b    $06, $01
                dc.w    loc_1A608&$FFFF
                dc.w    loc_1A618&$FFFF
                dc.w    loc_1A628&$FFFF
                dc.w    loc_1A610&$FFFF
                dc.w    loc_1A630&$FFFF
                dc.w    loc_1A620&$FFFF
                
; ----------------------------------------------------------------------

loc_147ce:
                dc.b    $06, $01
                dc.w    loc_1A638&$FFFF
                dc.w    loc_1A648&$FFFF
                dc.w    loc_1A658&$FFFF
                dc.w    loc_1A640&$FFFF
                dc.w    loc_1A660&$FFFF
                dc.w    loc_1A650&$FFFF
                
; ----------------------------------------------------------------------

loc_147dc:
                dc.b    $06, $01
                dc.w    loc_1A668&$FFFF
                dc.w    loc_1A678&$FFFF
                dc.w    loc_1A688&$FFFF
                dc.w    loc_1A670&$FFFF
                dc.w    loc_1A690&$FFFF
                dc.w    loc_1A680&$FFFF

; ----------------------------------------------------------------------
loc_147ea:
                dc.b    $06, $01
                dc.w    loc_1A698&$FFFF
                dc.w    loc_1A6A8&$FFFF
                dc.w    loc_1A6B8&$FFFF
                dc.w    loc_1A6A0&$FFFF
                dc.w    loc_1A6C0&$FFFF
                dc.w    loc_1A6B0&$FFFF

; ----------------------------------------------------------------------
loc_147f8
                dc.b    $06, $01
                dc.w    loc_1A6C8&$FFFF
                dc.w    loc_1A6D8&$FFFF
                dc.w    loc_1A6E8&$FFFF
                dc.w    loc_1A6D0&$FFFF
                dc.w    loc_1A6F0&$FFFF
                dc.w    loc_1A6E0&$FFFF

; ----------------------------------------------------------------------
loc_14806:
                dc.b    $06, $01
                dc.w    loc_1A6F8&$FFFF
                dc.w    loc_1A708&$FFFF
                dc.w    loc_1A718&$FFFF
                dc.w    loc_1A700&$FFFF
                dc.w    loc_1A720&$FFFF
                dc.w    loc_1A710&$FFFF

; ----------------------------------------------------------------------

loc_14814:
                dc.b    $06, $01
                dc.w    loc_1A728&$FFFF
                dc.w    loc_1A738&$FFFF
                dc.w    loc_1A748&$FFFF
                dc.w    loc_1A730&$FFFF
                dc.w    loc_1A750&$FFFF
                dc.w    loc_1A740&$FFFF

; ----------------------------------------------------------------------

loc_14822:
                dc.b    $06, $01
                dc.w    loc_1A758&$FFFF
                dc.w    loc_1A768&$FFFF
                dc.w    loc_1A778&$FFFF
                dc.w    loc_1A760&$FFFF
                dc.w    loc_1A780&$FFFF
                dc.w    loc_1A770&$FFFF

; ----------------------------------------------------------------------

loc_14830:
                dc.b    $06, $01
                dc.w    loc_1A788&$FFFF
                dc.w    loc_1A798&$FFFF
                dc.w    loc_1A7A8&$FFFF
                dc.w    loc_1A790&$FFFF
                dc.w    loc_1A7B0&$FFFF
                dc.w    loc_1A7A0&$FFFF

; ----------------------------------------------------------------------


; ======================================================================
; Chirp.
; ======================================================================
loc_1483e:
                bset    #7,(a0)                  ; Set object as loaded.
                bne.s   loc_14874                ; If it was already loaded, branch.
                move.l  #loc_14E12,8(a0)         ; Set to load the normal Chirp mappings.     TODO NOT MAPPINGS MAYBE RAM TABLE
                tst.b   $3A(a0)                  ; Is the chick a sunglasses chick?
                beq.s   loc_1485a                ; If it isn't, branch.
                move.l  #loc_14E22,8(a0)         ; Load the shades Chirp mappings.
loc_1485a:
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   loc_11674
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
loc_14874:
                tst.b   ($FFFFD27B).w
                bne.s   loc_14898
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_1489a(pc,d0.w)
                move.l  $34(a0),d0
                beq.s   loc_14898
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   loc_14898
                clr.b   $39(a0)
loc_14898:
                rts

; ----------------------------------------------------------------------

loc_1489a:
                bra.w   loc_148aa
                bra.w   loc_14918
                bra.w   loc_14b42
                bra.w   loc_14d86

; ----------------------------------------------------------------------

loc_148aa:
                tst.b   ($FFFFD24F).w
                bne.s   loc_14916
                bset    #7,$3C(a0)
                bne.s   loc_148C6
                move.b  #$30,$3B(a0)
                move.l  #$FFFFE000,$2C(a0)
loc_148C6:
                clr.w   6(a0)
                subq.b  #1,$3B(a0)
                bne.s   loc_148DA
                neg.l   $2C(a0)
                move.b  #$30,$3B(a0)
loc_148DA:
                lea     ($FFFFC440).w,a1
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_1490e
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,($FFFFD27A).w
                move.b  ($FFFFD27A).w,$38(a0)
                move.l  #$10,($FFFFD262).w
                bsr.w   loc_1168a
loc_1490e:
                bsr.w   AnimateSprite
                bsr.w   loc_1105c
loc_14916:
                rts

; ----------------------------------------------------------------------

loc_14918:
                bset    #7,$3C(a0)
                bne.s   loc_14928
                clr.l   $34(a0)
                clr.l   $2C(a0)
loc_14928:
                tst.b   ($FFFFD26D).w
                beq.s   loc_14940
                clr.b   $38(a0)
                subq.b  #1,($FFFFD27A).w
                move.w  #8,$3C(a0)
                bra.w   loc_14a12
loc_14940:
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                moveq   #-1,d1                   ; Set d1 to $FFFFFFFF.
                lea     loc_14a58(pc),a1         ; Load the TODO table address into a1.
                move.w  (a1,d0.w),d1             ; Get correct pointer.
                movea.l d1,a1                    ; Set as address.
                move.l  (a1),$30(a0)
                move.l  4(a1),$24(a0)
                bsr.w   loc_110ba
                lea     loc_14a6a(pc),a1
                move.w  (a1,d0.w),d1
                movea.l d1,a1
                moveq   #0,d1
                move.b  (a1),d1
                move.w  d1,-(sp)
                tst.b   ($FFFFD24F).w
                bne.s   loc_1497c
                bsr.w   loc_14af0
loc_1497c:
                move.w  (sp)+,d1
                tst.b   ($FFFFD24F).w
                beq.s   loc_149f2
                lea     ($FFFFC440).w,a1
                move.w  $30(a1),d7
                move.w  $24(a1),d6
                cmp.w   $30(a0),d7
                bne.s   loc_149f2
                cmp.w   $24(a0),d6
                bne.s   loc_149f2
                move.l  a0,-(sp)
                move.b  #$94,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                clr.w   (a0)
                bsr.w   loc_14a7c
                subq.b  #1,($FFFFD883).w
                bne.s   loc_149ce
                move.b  #1,($FFFFD281).w
                clr.w   ($FFFFFF92).w
                move.b  ($FFFFD888).w,($FFFFD266).w
                move.b  ($FFFFD889).w,($FFFFD267).w
                bsr.w   loc_14dd4
loc_149ce:
                move.l  a0,-(sp)
                moveq   #2,d1
loc_149D2:
                jsr     ($FFFFFB6C).w
                dbf     d1,loc_149d2
                movea.l (sp)+,a0
                clr.b   $38(a0)
                subq.b  #1,($FFFFD27A).w
                bne.s   loc_149f2
                clr.b   ($FFFFD24F).w
                move.l  a0,-(sp)
                bsr.w   loc_11d18
                movea.l (sp)+,a0
loc_149f2:
                tst.b   ($FFFFD281).w
                beq.s   loc_14a12
                move.b  #1,($FFFFD24F).w
                move.w  #$C,($FFFFD2A0).w
                cmpi.b  #1,($FFFFD88D).w
                beq.s   loc_14a12
                move.b  #1,($FFFFD88F).w

loc_14a12:
                bclr    #7,2(a0)
                clr.b   $39(a0)
                move.b  d1,d0
                andi.b  #3,d0
                bne.s   loc_14a2a
                clr.w   6(a0)
                bra.s   loc_14a4e
loc_14a2a:
                btst    #0,d1
                bne.s   loc_14a3c
                bset    #7,2(a0)
                move.b  #1,$39(a0)
loc_14a3c:
                tst.b   d1
                bmi.s   loc_14a48
                move.w  #8,6(a0)
                bra.s   loc_14a4e

loc_14a48:
                move.w  #4,6(a0)
loc_14a4e:
                bsr.w   AnimateSprite
                bsr.w   loc_110ba
                rts

; ======================================================================
loc_14a58:
                dc.b    $00, $00
                dc.w    $FFFFD036&$FFFF
                dc.w    $FFFFD05E&$FFFF
                dc.w    $FFFFD086&$FFFF
                dc.w    $FFFFD0AE&$FFFF
                dc.w    $FFFFD0D6&$FFFF
                dc.w    $FFFFD0FE&$FFFF
                dc.w    $FFFFD126&$FFFF
                dc.w    $FFFFD14E&$FFFF

; ----------------------------------------------------------------------

loc_14a6a:
                dc.b    $00, $00
                dc.w    $FFFFD213&$FFFF
                dc.w    $FFFFD218&$FFFF
                dc.w    $FFFFD21D&$FFFF
                dc.w    $FFFFD222&$FFFF
                dc.w    $FFFFD227&$FFFF
                dc.w    $FFFFD22C&$FFFF
                dc.w    $FFFFD231&$FFFF
                dc.w    $FFFFD236&$FFFF

; ======================================================================

loc_14A7C:
                moveq   #0,d0
                move.b  $38(a0),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  loc_14ac0(pc,d0.w),d0
                move.l  d0,($FFFFD262).w
                bsr.w   loc_1168a
                moveq   #0,d0
                move.b  $38(a0),d0
                move.b  d0,d1
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #-1,d2
                lea     loc_14ae0(pc),a2         ; Load object RAM slots into a2.
                move.w  (a2,d0.w),d2             ; Get the correct slot.
                movea.l d2,a2                    ; Set as address.
                move.w  #$20,(a2)                ; Write the TODO object to it.
                move.b  d1,$3A(a2)
                lea     ($FFFFC440).w,a1
                move.w  $30(a1),d7
                move.w  d7,$30(a2)
                rts

; ----------------------------------------------------------------------
                                 ; TODO
loc_14ac0:
                dc.l    $00000100
                dc.l    $00000200
                dc.l    $00000300
                dc.l    $00000400
                dc.l    $00000500
                dc.l    $00001000
                dc.l    $00002000
                dc.l    $00005000

; ----------------------------------------------------------------------
loc_14ae0:
                dc.w    $C100
                dc.w    $C140
                dc.w    $C180
                dc.w    $C1C0
                dc.w    $C100
                dc.w    $C140
                dc.w    $C180
                dc.w    $C1C0

; ======================================================================

loc_14af0:
                lea     ($FFFFC380).w,a1
                moveq   #1,d0
loc_14AF6:
                move.w  d0,-(sp)
                btst    #1,5(a1)
                beq.s   loc_14b30
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_14b30
                move.b  $38(a0),d0
                lea     ($FFFFC480).w,a2
                moveq   #7,d1
loc_14B12:
                cmp.b   $38(a2),d0
                bhi.s   loc_14b26
                clr.b   $38(a2)
                subq.b  #1,($FFFFD27A).w
                move.w  #8,$3C(a2)
loc_14b26:
                lea     $40(a2),a2
                dbf     d1,loc_14b12
                bra.s   loc_14b3c

loc_14b30:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_14af6
                rts

loc_14b3c:
                move.w  (sp)+,d0
                rts

loc_14b40       ; Dead code.
                rts

; ----------------------------------------------------------------------

loc_14b42:
                tst.b   $3A(a0)
                bne.w   loc_14c6a
                bset    #7,$3C(a0)
                bne.s   loc_14b76
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     loc_14c4a(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   loc_14b70
                neg.l   $34(a0)
loc_14b70:
                move.w  #8,6(a0)
loc_14b76:
                bsr.w   loc_1105c
                tst.l   $2C(a0)
                bne.w   loc_14bf8
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_14ba4
                addi.l  #$00001000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   loc_14bf6

loc_14ba4:
                move.l  $34(a0),d0
                beq.s   loc_14bba
                tst.b   $39(a0)
                bne.s   loc_14bc6
                subi.l  #$00000400,$34(a0)
                bra.s   loc_14bdc

loc_14bba:
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   loc_14bf6

loc_14bc6:
                addi.l  #$00000400,$34(a0)
                bra.s   loc_14bdc

loc_14bd0                                        ; Unused code.
                clr.l   $34(a0)
                move.w  #$C,$3C(a0)
                bra.s   loc_14bf6

loc_14bdc:
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   loc_14be8
                neg.w   d0
loc_14be8:
                add.w   d0,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14bf6
                neg.l   $34(a0)
loc_14bf6:
                bra.s   loc_14c2e

loc_14bf8:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14c20
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   loc_14c2e

loc_14c20:
                addi.l  #$00001000,$2C(a0)
                move.w  #4,6(a0)
loc_14c2e:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_14c40
                bset    #7,2(a0)
loc_14c40:
                bsr.w   AnimateSprite
                bsr.w   loc_14d52
                rts

; ======================================================================

loc_14c4a:
                dc.l    $0000A000          
                dc.l    $0000C000         
                dc.l    $0000E000
                dc.l    $00010000
                dc.l    $00012000
                dc.l    $00014000
                dc.l    $00016000
                dc.l    $00018000

; ======================================================================

loc_14c6a:
                bset    #7,$3C(a0)
                bne.s   loc_14c96
                moveq   #0,d0
                move.w  a0,d0
                subi.w  #$C480,d0
                lsr.w   #4,d0
                lea     loc_14d32(pc),a1
                move.l  (a1,d0.w),$34(a0)
                tst.b   $39(a0)
                beq.s   loc_14c90
                neg.l   $34(a0)
loc_14c90:
                move.w  #8,6(a0)
loc_14c96:
                bsr.w   loc_1105c
                tst.l   $2C(a0)
                bne.w   loc_14ce0
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #1,d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_14cc4
                addi.l  #$00001000,$2C(a0)
                move.w  #4,6(a0)
                bra.s   loc_14cde

loc_14cc4:
                subq.w  #6,d6
                moveq   #4,d0
                tst.l   $34(a0)
                bpl.s   loc_14cd0
                neg.w   d0
loc_14cd0:
                add.w   d0,d7
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14cde
                neg.l   $34(a0)
loc_14cde:
                bra.s   loc_14d16

loc_14ce0:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_14d08
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,6(a0)
                bra.s   loc_14d16

loc_14d08:
                addi.l  #$00001000,$2C(a0)
                move.w  #4,6(a0)
loc_14d16:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_14d28
                bset    #7,2(a0)
loc_14d28:
                bsr.w   AnimateSprite
                bsr.w   loc_14d52
                rts

; ======================================================================

loc_14d32:
                dc.l    $0000C000
                dc.l    $0000D000
                dc.l    $0000E000
                dc.l    $0000F000
                dc.l    $00010000
                dc.l    $00011000
                dc.l    $00012000
                dc.l    $00013000

; ======================================================================

loc_14d52:
                lea     ($FFFFC440).w,a1
                move.w  $3C(a1),d0
                andi.w  #$7C,d0
                bne.s   loc_14d84
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_14d84
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                move.w  #4,$3C(a0)
                addq.b  #1,($FFFFD27A).w
                move.b  ($FFFFD27A).w,$38(a0)
loc_14d84:
                rts

; ----------------------------------------------------------------------

loc_14d86:
                bsr.w   loc_1105c
                bset    #7,$3C(a0)
                bne.s   loc_14da2
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)
loc_14da2:
                bsr.w   loc_1105c
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_14DB8
                bset    #7,2(a0)
loc_14DB8:
                bsr.w   AnimateSprite
                bclr    #2,2(a0)
                beq.s   loc_14dd0
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)
loc_14dd0:
                bsr.s   loc_14d52
                rts

; ======================================================================

loc_14dd4:
                clr.l   ($FFFFD268).w
                tst.b   ($FFFFD266).w
                bne.s   loc_14df8
                moveq   #0,d0
                move.b  ($FFFFD267).w,d0
                lsr.w   #4,d0
                lsl.w   #2,d0
                move.l  loc_14dfa(pc,d0.w),d0
                move.l  d0,($FFFFD268).w
                move.l  d0,($FFFFD262).w
                bsr.w   loc_1168a
loc_14df8:
                rts

; ======================================================================

loc_14dfa:
                dc.l    $00020000
                dc.l    $00020000
                dc.l    $00010000
                dc.l    $00005000
                dc.l    $00003000
                dc.l    $00001000

; ----------------------------------------------------------------------
loc_14e12:
                dc.l    loc_14E32
                dc.l    loc_14E96
                dc.l    loc_14EA2
                dc.l    loc_14EB2

; ----------------------------------------------------------------------

loc_14e22:
                dc.l    loc_14E64
                dc.l    loc_14E9C
                dc.l    loc_14EAA
                dc.l    loc_14EBC

; ----------------------------------------------------------------------

loc_14e32:
                dc.b    $18, $04                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A7B8&$FFFF
                dc.w    loc_1A7C0&$FFFF
                dc.w    loc_1A7B8&$FFFF
                dc.w    loc_1A7C0&$FFFF
                dc.w    loc_1A7B8&$FFFF
                dc.w    loc_1A7C0&$FFFF
                dc.w    loc_1A7B8&$FFFF
                dc.w    loc_1A7C0&$FFFF
                dc.w    loc_1A7B8&$FFFF
                dc.w    loc_1A7C0&$FFFF
                dc.w    loc_1A7B8&$FFFF
                dc.w    loc_1A7C0&$FFFF
                dc.w    loc_1A7C8&$FFFF
                dc.w    loc_1A7D0&$FFFF
                dc.w    loc_1A7C8&$FFFF
                dc.w    loc_1A7D0&$FFFF
                dc.w    loc_1A7C8&$FFFF
                dc.w    loc_1A7D0&$FFFF
                dc.w    loc_1A7C8&$FFFF
                dc.w    loc_1A7D0&$FFFF
                dc.w    loc_1A7C8&$FFFF
                dc.w    loc_1A7D0&$FFFF
                dc.w    loc_1A7C8&$FFFF
                dc.w    loc_1A7D0&$FFFF

; ----------------------------------------------------------------------

loc_14e64:
                dc.b    $18, $04                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A818&$FFFF
                dc.w    loc_1A820&$FFFF
                dc.w    loc_1A818&$FFFF
                dc.w    loc_1A820&$FFFF
                dc.w    loc_1A818&$FFFF
                dc.w    loc_1A820&$FFFF
                dc.w    loc_1A818&$FFFF
                dc.w    loc_1A820&$FFFF
                dc.w    loc_1A818&$FFFF
                dc.w    loc_1A820&$FFFF
                dc.w    loc_1A818&$FFFF
                dc.w    loc_1A820&$FFFF
                dc.w    loc_1A828&$FFFF
                dc.w    loc_1A830&$FFFF
                dc.w    loc_1A828&$FFFF
                dc.w    loc_1A830&$FFFF
                dc.w    loc_1A828&$FFFF
                dc.w    loc_1A830&$FFFF
                dc.w    loc_1A828&$FFFF
                dc.w    loc_1A830&$FFFF
                dc.w    loc_1A828&$FFFF
                dc.w    loc_1A830&$FFFF
                dc.w    loc_1A828&$FFFF
                dc.w    loc_1A830&$FFFF

; ----------------------------------------------------------------------

loc_14e96:
                dc.b    $02, $03                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A7D8&$FFFF
                dc.w    loc_1A7E0&$FFFF

; ----------------------------------------------------------------------

loc_14e9c:
                dc.b    $02, $03                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A838&$FFFF
                dc.w    loc_1A840&$FFFF

; ----------------------------------------------------------------------

loc_14ea2:
                dc.b    $03, $04                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A7E8&$FFFF
                dc.w    loc_1A7F0&$FFFF
                dc.w    loc_1A7F8&$FFFF

; ----------------------------------------------------------------------

loc_14eaa:

                dc.b    $03, $04                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A848&$FFFF
                dc.w    loc_1A850&$FFFF
                dc.w    loc_1A858&$FFFF

; ----------------------------------------------------------------------

loc_14eb2:
                dc.b    $04, $0A                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A800&$FFFF
                dc.w    loc_1A800&$FFFF
                dc.w    loc_1A808&$FFFF
                dc.w    loc_1A810&$FFFF

; ----------------------------------------------------------------------

loc_14ebc:
                dc.b    $04, $0A                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A860&$FFFF
                dc.w    loc_1A860&$FFFF
                dc.w    loc_1A868&$FFFF
                dc.w    loc_1A870&$FFFF

; ======================================================================

loc_14ec6:
                bset    #7,(a0)
                bne.s   loc_14efa
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   loc_11674
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #loc_154AE,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)
loc_14efa:
                tst.b   ($FFFFD27B).w
                bne.s   loc_14f2e
                tst.b   ($FFFFD24F).w
                bne.s   loc_14f2e
                tst.b   ($FFFFD26D).w
                bne.s   loc_14f2e
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_14f44(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7FFC,d0
                cmpi.w  #$14,d0
                beq.s   loc_14f2e
                cmpi.w  #$1C,d0
                beq.s   loc_14f2e
                bsr.w   loc_1540a
loc_14f2e:
                move.l  $34(a0),d0
                beq.s   loc_14f42
                move.b  #1,$39(a0)
                tst.l   d0
                bmi.s   loc_14f42
                clr.b   $39(a0)
loc_14f42:
                rts

; ----------------------------------------------------------------------

loc_14f44:
                bra.w   loc_14f64
                bra.w   loc_14fd2
                bra.w   loc_15068
                bra.w   loc_1515a
                bra.w   loc_15256
                bra.w   loc_152b4
                bra.w   loc_152f6
                bra.w   loc_153a4

; ----------------------------------------------------------------------

loc_14f64:
                bset    #7,$3C(a0)
                bne.s   loc_14f80
                clr.w   6(a0)
                bclr    #2,2(a0)
                clr.b   $10(a0)
                move.b  #6,5(a0)
loc_14f80:
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
                bclr    #2,2(a0)
                beq.s   loc_14fd0
                move.w  #8,$3C(a0)
                lea     ($FFFFC440).w,a1
                move.w  $20(a0),d7
                move.w  $20(a1),d6
                clr.b   $39(a0)
                cmp.w   d7,d6
                bgt.s   loc_14fb0
                move.b  #1,$39(a0)
loc_14fb0:
                cmpi.w  #$30,($FFFFD888).w
                bhi.s   loc_14fd0
                cmpi.b  #$31,($FFFFD82D).w
                bhi.s   loc_14fd0
                clr.b   $39(a0)
                tst.b   $16(a0)
                beq.s   loc_14fd0
                move.b  #1,$39(a0)
loc_14fd0:
                rts

; ----------------------------------------------------------------------

loc_14fd2:
                bset    #7,$3C(a0)
                bne.s   loc_15004
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #loc_1A918,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15004
                bset    #7,2(a0)
loc_15004:
                bsr.w   loc_1105c
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     ($FFFFC440).w,a1
                move.w  $20(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   loc_1502e
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_1502e:
                tst.b   $39(a0)
                bne.s   loc_1504e
                cmp.w   d7,d5
                bgt.s   loc_15040
                move.w  #$10,$3C(a0)
                rts

loc_15040:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_1504e:
                cmp.w   d7,d5
                blt.s   loc_1505a
                move.w  #$10,$3C(a0)
                rts

loc_1505a:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

; ----------------------------------------------------------------------

loc_15068:
                bset    #7,$3C(a0)
                bne.s   loc_15094
                move.b  #7,5(a0)
                move.l  ($FFFFD296).w,$34(a0)
                tst.b   $16(a0)
                beq.s   loc_1508a
                move.l  #$14000,$34(a0)
loc_1508a:
                tst.b   $39(a0)
                beq.s   loc_15094
                neg.l   $34(a0)
loc_15094:
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   loc_150ac
                subq.w  #8,d7
                bra.s   loc_150ae
loc_150ac:
                addq.w  #8,d7
loc_150ae:
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_150ba
                neg.l   $34(a0)
loc_150ba:
                moveq   #0,d7
                moveq   #1,d6
                bsr.w   loc_115c0
                btst    #7,d4
                bne.s   loc_150ea
                tst.l   $34(a0)
                bpl.s   loc_150dc
                btst    #2,d4
                bne.s   loc_150da
                move.w  #4,$3C(a0)
loc_150da:
                bra.s   loc_15114
loc_150dc:
                btst    #3,d4
                bne.s   loc_150e8
                move.w  #4,$3C(a0)
loc_150e8:
                bra.s   loc_15114
loc_150ea:
                tst.b   $39(a0)
                bne.s   loc_150f8
                btst    #6,d4
                bne.s   loc_15114
                bra.s   loc_150fe

loc_150f8:
                btst    #6,d4
                beq.s   loc_15114
loc_150fe:
                lea     ($FFFFC440).w,a1
                move.w  $24(a0),d6
                cmp.w   $24(a1),d6
                blt.s   loc_15114
                beq.s   loc_15132
                move.w  #$18,$3C(a0)
loc_15114:
                bclr    #7,2(a0)
                tst.l   $34(a0)
                bpl.s   loc_12126
                bset    #7,2(a0)
loc_12126:
                move.w  #4,6(a0)
                bsr.w   AnimateSprite
                rts

; ======================================================================

loc_15132:
                cmpi.w  #$30,($FFFFD888).w
                bls.s   loc_15114
                move.w  $20(a1),d7
                tst.b   $39(a0)
                beq.s   loc_1514c
                cmp.w   $20(a0),d7
                blt.s   loc_15114
                bra.s   loc_15152

loc_1514c:
                cmp.w   $20(a0),d7
                bgt.s   loc_15114
loc_15152:
                move.w  #$18,$3C(a0)
                bra.s   loc_15114

; ======================================================================

loc_1515a:
                tst.b   $3B(a0)
                bne.w   loc_1524c
                bset    #7,$3C(a0)
                bne.s   loc_151b4
                move.b  #7,5(a0)
                move.b  $3A(a0),d0
                beq.s   loc_1518c
                cmpi.b  #1,d0
                beq.s   loc_1519a
                move.l  ($FFFFD276).w,$34(a0)
                move.l  #$FFFF8000,$2C(a0)
                bra.s   loc_151AA

loc_1518c:
                move.l  ($FFFFD26E).w,$34(a0)
                move.l  ($FFFFD272).w,$2C(a0)
                bra.s   loc_151aa

loc_1519A:
                move.l  #$1A000,$34(a0)
                move.l  #$FFFF0000,$2C(a0)
loc_151AA:
                tst.b   $39(a0)
                beq.s   loc_151b4
                neg.l   $34(a0)
loc_151b4:
                addi.l  #$1000,$2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_1520c
                subq.w  #8,d6
                tst.l   $34(a0)
                bpl.s   loc_151dc
                subq.w  #8,d7
                bra.s   loc_151de
loc_151dc:
                addq.w  #8,d7
loc_151de:
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_151ec
                neg.l   $34(a0)
                bra.s   loc_15222
loc_151ec:
                tst.l   $2C(a0)
                bpl.s   loc_1520a
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subi.w  #$D,d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_1520a
                clr.l   $2C(a0)
loc_1520a:
                bra.s   loc_15222

loc_1520c:
                clr.l   $2C(a0)
                andi.w  #$FFF8,d6
                clr.w   $26(a0)
                move.w  d6,$24(a0)
                move.w  #8,$3C(a0)
loc_15222:
                move.l  #loc_1A970,$C(a0)
                tst.l   $2C(a0)
                bmi.s   loc_15238
                move.l  #loc_1A97E,$C(a0)
loc_15238:
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_1524A
                bset    #7,2(a0)
loc_1524A:
                rts

loc_1524c:
                subq.b  #1,$3B(a0)
                bsr.w   loc_1105c
                rts

; ----------------------------------------------------------------------

loc_15256:
                tst.b   $3B(a0)
                bne.s   loc_152aa
                bset    #7,$3C(a0)
                bne.s   loc_1527a
                move.b  #7,5(a0)
                bclr    #2,2(a0)
                move.w  #$C,6(a0)
                clr.b   $10(a0)
loc_1527a:
                bsr.w   loc_1105c
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15290
                bset    #7,2(a0)
loc_15290:
                bsr.w   AnimateSprite
                bclr    #2,2(a0)
                beq.s   loc_152a8
                bchg    #0,$39(a0)
                move.w  #8,$3C(a0)
loc_152a8:
                rts

loc_152aa:
                subq.b  #1,$3B(a0)
                bsr.w   loc_1105c
                rts

; ======================================================================

loc_152b4:
                bset    #7,$3C(a0)
                bne.s   loc_152e4
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                tst.b   $16(a0)
                bne.s   loc_152D6
                addi.l  #$1000,($FFFFD296).w
loc_152D6:
                clr.b   5(a0)
                move.w  #8,6(a0)
                subq.b  #1,($FFFFD26C).w
loc_152e4:
                bsr.w   loc_14688
                tst.l   $34(a0)
                bne.s   loc_152f4
                move.w  #$1C,$3C(a0)
loc_152f4:
                rts

; ----------------------------------------------------------------------

loc_152f6:
                bset    #7,$3C(a0)
                bne.s   loc_15328
                move.b  #7,5(a0)
                clr.l   $34(a0)
                move.b  #$14,$3B(a0)
                move.l  #loc_1A918,$C(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_15328
                bset    #7,2(a0)
loc_15328:
                bsr.w   loc_1105c
                move.w  $20(a0),d7
                move.w  $24(a0),d6
                lea     ($FFFFC440).w,a1
                move.w  $20(a1),d5
                move.w  $24(a1),d4
                cmp.w   d6,d4
                beq.s   loc_15360
                bgt.s   loc_15352
                clr.b   $3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15352:
                move.b  #2,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15360:
                tst.b   $39(a0)
                bne.s   loc_15380
                cmp.w   d7,d5
                bgt.s   loc_15372
                move.w  #$10,$3C(a0)
                rts

loc_15372:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts

loc_15380:
                cmp.w   d7,d5
                blt.s   loc_1538c
                move.w  #$10,$3C(a0)
                rts

loc_1538c:
                move.b  #1,$3A(a0)
                move.w  #$C,$3C(a0)
                rts
; Unused?
loc_1539a:
                subq.b  #1,$3B(a0)
                bsr.w   loc_1105c
                rts

; ----------------------------------------------------------------------

loc_153a4:
                bset    #7,$3C(a0)
                bne.s   loc_153c8
                clr.b   5(a0)
                bclr    #2,2(a0)
                move.w  #$10,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)
loc_153c8:
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
                btst    #2,2(a0)
                beq.s   loc_15408
                move.b  ($FFFFD88A).w,d0
                andi.b  #$F0,d0
                bne.s   loc_15404
                lea     ($FFFFC740).w,a1
                tst.b   $16(a0)
                beq.s   loc_153f0
                lea     $40(a1),a1
loc_153f0:
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)
loc_15404:
                bsr.w   loc_11118
loc_15408:
                rts

; ======================================================================

loc_1540a:
                lea     ($FFFFC200).w,a1
                moveq   #5,d0
loc_15410:
                move.w  d0,-(sp)
                btst    #3,5(a1)
                beq.s   loc_1548e
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_1548e
                move.w  #$14,$3C(a0)
                clr.b   5(a0)
                move.l  $34(a1),d7
                move.l  $2C(a1),d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                addq.b  #1,$3B(a1)
                moveq   #0,d0
                move.b  $3B(a1),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  loc_1549e(pc,d0.w),d0
                move.l  d0,($FFFFD262).w
                move.l  a1,-(sp)
                bsr.w   loc_1168a
                movea.l (sp)+,a1
                lea     ($FFFFC0C0).w,a2
                moveq   #3,d0
loc_15460:
                tst.b   (a2)
                bne.s   loc_15484
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   loc_1549a

loc_15484:
                lea     -$40(a2),a2
                dbf     d0,loc_15460
                bra.s   loc_1549a

loc_1548e:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_15410
                rts

loc_1549a:
                move.w  (sp)+,d0
                rts

; ----------------------------------------------------------------------

loc_1549e:
                dc.l    $00000200
                dc.l    $00000400
                dc.l    $00000800
                dc.l    $00001600

; ----------------------------------------------------------------------
loc_154ae:
                dc.l    loc_154C2
                dc.l    loc_154D0
                dc.l    loc_154E2
                dc.l    loc_154F4
                dc.l    loc_154FE

; ----------------------------------------------------------------------

loc_154c2:
                dc.b    $06, $0C
                dc.w    loc_1A8F8&$FFFF
                dc.w    loc_1A900&$FFFF
                dc.w    loc_1A8F8&$FFFF
                dc.w    loc_1A900&$FFFF
                dc.w    loc_1A908&$FFFF
                dc.w    loc_1A910&$FFFF

; ----------------------------------------------------------------------

loc_154d0:
                dc.b    $08, $01
                dc.w    loc_1A918&$FFFF
                dc.w    loc_1A926&$FFFF
                dc.w    loc_1A93A&$FFFF
                dc.w    loc_1A94E&$FFFF
                dc.w    loc_1A94E&$FFFF
                dc.w    loc_1A95C&$FFFF
                dc.w    loc_1A93A&$FFFF
                dc.w    loc_1A926&$FFFF

; ----------------------------------------------------------------------

loc_154e2:
                dc.b    $08, $01  
                
                dc.w    loc_1A992&$FFFF
                dc.w    loc_1A99A&$FFFF
                dc.w    loc_1A9AE&$FFFF
                dc.w    loc_1A9B6&$FFFF
                dc.w    loc_1A9CA&$FFFF
                dc.w    loc_1A9D2&$FFFF
                dc.w    loc_1A9E6&$FFFF
                dc.w    loc_1A9EE&$FFFF

; ----------------------------------------------------------------------

loc_154f4:

                dc.b    $04, $05
                dc.w    loc_1AA02&$FFFF
                dc.w    loc_1AA02&$FFFF
                dc.w    loc_1AA0A&$FFFF
                dc.w    loc_1AA12&$FFFF

; ----------------------------------------------------------------------

loc_154fe:
                dc.b    $04, $06
                dc.w    loc_1AA7E&$FFFF
                dc.w    loc_1AA7E&$FFFF
                dc.w    loc_1AA86&$FFFF
                dc.w    loc_1AA8E&$FFFF

; ======================================================================

loc_15508:
                dc.w    loc_15568&$FFFF
                dc.w    loc_155A4&$FFFF
                dc.w    loc_155A4&$FFFF
                dc.w    loc_155C0&$FFFF
                dc.w    loc_155DC&$FFFF
                dc.w    loc_15610&$FFFF
                dc.w    loc_15610&$FFFF
                dc.w    loc_15624&$FFFF
                dc.w    loc_15646&$FFFF
                dc.w    loc_1566A&$FFFF
                dc.w    loc_1566A&$FFFF
                dc.w    loc_156A2&$FFFF
                dc.w    loc_156CE&$FFFF
                dc.w    loc_15714&$FFFF
                dc.w    loc_15714&$FFFF
                dc.w    loc_15740&$FFFF
                dc.w    loc_1576E&$FFFF
                dc.w    loc_157D2&$FFFF
                dc.w    loc_157D2&$FFFF
                dc.w    loc_157FA&$FFFF
                dc.w    loc_15822&$FFFF
                dc.w    loc_1584E&$FFFF
                dc.w    loc_1584E&$FFFF
                dc.w    loc_15886&$FFFF
                dc.w    loc_158A6&$FFFF
                dc.w    loc_158C6&$FFFF
                dc.w    loc_158C6&$FFFF
                dc.w    loc_158E2&$FFFF
                dc.w    loc_1590E&$FFFF
                dc.w    loc_1592A&$FFFF
                dc.w    loc_1592A&$FFFF
                dc.w    loc_15942&$FFFF
                dc.w    loc_15962&$FFFF
                dc.w    loc_15982&$FFFF
                dc.w    loc_15982&$FFFF
                dc.w    loc_159B6&$FFFF
                dc.w    loc_159DE&$FFFF
                dc.w    loc_15A02&$FFFF
                dc.w    loc_15A02&$FFFF
                dc.w    loc_15A2E&$FFFF
                dc.w    loc_15A46&$FFFF
                dc.w    loc_15AE6&$FFFF
                dc.w    loc_15AE6&$FFFF
                dc.w    loc_15B02&$FFFF
                dc.w    loc_15B1C&$FFFF
                dc.w    loc_15B52&$FFFF
                dc.w    loc_15B52&$FFFF
                dc.w    loc_15B70&$FFFF

; ----------------------------------------------------------------------

loc_15568:
                incbin  "loc_15568.bin"

loc_155a4:
                incbin  "loc_155A4.bin"

loc_155c0:
                incbin  "loc_155C0.bin"

loc_155dc:
                incbin  "loc_155DC.bin"

loc_15610:
                incbin  "loc_15610.bin"

loc_15624:
                incbin  "loc_15624.bin"

loc_15646:
                incbin  "loc_15646.bin"

loc_1566a:
                incbin  "loc_1566A.bin"

loc_156a2:
                incbin  "loc_156A2.bin"

loc_156ce:
                incbin  "loc_156CE.bin"

loc_15714:
                incbin  "loc_15714.bin"

loc_15740:
                incbin  "loc_15740.bin"

loc_1576e:
                incbin  "loc_1576E.bin"

loc_157d2:
                incbin  "loc_157D2.bin"

loc_157fa:
                incbin  "loc_157FA.bin"

loc_15822:
                incbin  "loc_15822.bin"

loc_1584e:
                incbin  "loc_1584E.bin"

loc_15886:
                incbin  "loc_15886.bin"

loc_158a6:
                incbin  "loc_158A6.bin"

loc_158c6:
                incbin  "loc_158C6.bin"

loc_158e2:
                incbin  "loc_158E2.bin"

loc_1590e:
                incbin  "loc_1590E.bin"

loc_1592a:
                incbin  "loc_1592A.bin"

loc_15942:
                incbin  "loc_15942.bin"

loc_15962:
                incbin  "loc_15962.bin"

loc_15982:
                incbin  "loc_15982.bin"

loc_159b6:
                incbin  "loc_159B6.bin"

loc_159de:
                incbin  "loc_159DE.bin"

loc_15a02:
                incbin  "loc_15A02.bin"

loc_15a2e:
                incbin  "loc_15A2E.bin"

loc_15a46:
                incbin  "loc_15A46.bin"

loc_15ae6:
                incbin  "loc_15AE6.bin"

loc_15B02:
                incbin  "loc_15B02.bin"
                
loc_15B1C:
                incbin  "loc_15B1C.bin"

loc_15b52:
                incbin  "loc_15B52.bin"

loc_15B70:
                incbin  "loc_15B70.bin"

; ======================================================================

loc_15b94:
		dc.w 1
		dc.w $4000
		dc.w $FFFE
		dc.w 0
		dc.w 1
		dc.w 0
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w 0
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w $4000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w $4000
		dc.w $FFFE
		dc.w 0
		dc.w 1
		dc.w $4000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w $4000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w $4000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w $8000
		dc.w $FFFD
		dc.w $E000
		dc.w 1
		dc.w $4000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w $4000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $4800
		dc.w $FFFD
		dc.w $9000
		dc.w 0
		dc.w $C000
		dc.w $FFFD
		dc.w $E000
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w 0
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w 0
		dc.w $FFFE
		dc.w 0
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w $5000
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w $5000
		dc.w 1
		dc.w 0
		dc.w $FFFD
		dc.w $9000
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w $C000
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $7000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w $A000
		dc.w $FFFD
		dc.w $C000
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w 0
		dc.w $FFFD
		dc.w $C000
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $C000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $C000
		dc.w $FFFD
		dc.w $8000
		dc.w 1
		dc.w 0
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w 0
		dc.w 1
		dc.w 0
		dc.w $FFFE
		dc.w 0
		dc.w 1
		dc.w 0
		dc.w $FFFE
		dc.w 0
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w $3000
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w $4000
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w 0
		dc.w 0
		dc.w $A000
		dc.w $FFFD
		dc.w 0
		dc.w 0
		dc.w $C000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $8000
		dc.w $FFFD
		dc.w $8000
		dc.w 0
		dc.w $6000
		dc.w $FFFD
		dc.w $2000
		dc.w 1
		dc.w 0
		dc.w $FFFE
		dc.w 0
		dc.w 1
		dc.w 0
		dc.w $FFFD
		dc.w 0
		dc.w 0
		dc.w $C000
		dc.w $FFFD
		dc.w $4000
		dc.w 0
		dc.w $6000
		dc.w $FFFD
		dc.w $2000
		dc.w 0
		dc.w $6000
		dc.w $FFFD
		dc.w $2000
		dc.w 0
		dc.w $C000
		dc.w $FFFD
		dc.w $4000

loc_15d14:
        	dc.l $10000		; DATA XREF: ROM:00012E84o
		dc.l $14000
		dc.l $12000
		dc.l $E000
		dc.l $16000



loc_15d28:
	dc.b 0			; DATA XREF: ROM:00012E7Ao
		dc.b   0
		dc.b   0
		dc.b   1
		dc.b   4
		dc.b   0
		dc.b   0
		dc.b   2
		dc.b   2
		dc.b   2
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   3
		dc.b   0
		dc.b   2
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b 0
		dc.b   3
		dc.b   0
		dc.b   2
		dc.b   0
		dc.b   2
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   1
		dc.b   0
		dc.b   4
		dc.b   0
		dc.b   3
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b   0
		dc.b 0
		dc.b   3
		dc.b   0
		dc.b   0

; ======================================================================
; Iggy
; ======================================================================
loc_15d58:
                bset    #7,(a0)
                bne.s   loc_15d8c
                moveq   #0,d7
                moveq   #0,d6
                move.b  $3E(a0),d7
                move.b  $3F(a0),d6
                bsr.w   loc_11674
                addq.w  #8,d7
                addi.w  #$10,d6
                move.w  d7,$30(a0)
                move.w  d6,$24(a0)
                move.l  #loc_162BC,8(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)
loc_15d8c:
                tst.b   ($FFFFD27B).w
                bne.s   loc_15dc0
                tst.b   ($FFFFD24F).w
                bne.s   loc_15dc0
                tst.b   ($FFFFD26D).w
                bne.s   loc_15dc0
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_15dc2(pc,d0.w)
                move.w  $3C(a0),d0
                andi.w  #$7C,d0
                cmpi.w  #$C,d0
                beq.s   loc_15dc0
                cmpi.w  #$10,d0
                beq.s   loc_15dc0
                bsr.w   loc_16218
loc_15dc0:
                rts

; ----------------------------------------------------------------------

loc_15dc2:
                bra.w   loc_15dd6
                bra.w   loc_15e04
                bra.w   loc_160c8
                bra.w   loc_16188
                bra.w   loc_161bc

; ----------------------------------------------------------------------

loc_15dd6:
                bset    #7,$3C(a0)
                bne.s   loc_15df2
                move.b  #4,5(a0)
                move.l  #loc_1AB74,$C(a0)
                move.b  #$A,$3B(a0)
loc_15df2:
                bsr.w   loc_1105c
                subq.b  #1,$3B(a0)
                bne.s   loc_15e02
                move.w  #4,$3C(a0)
loc_15e02:
                rts

; ----------------------------------------------------------------------

loc_15e04:
                bset    #7,$3C(a0)
                bne.s   loc_15e12
                move.b  #5,5(a0)
loc_15e12:
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #2,d0
                jsr     loc_15e20(pc,d0.w)
                rts

; ----------------------------------------------------------------------

loc_15e20:
                bra.w   loc_15e40
                bra.w   loc_15ee6
                bra.w   loc_15ee6
                bra.w   loc_15ee6
                bra.w   loc_15f9e
                bra.w   loc_15f9e
                bra.w   loc_16036
                bra.w   loc_160c8

; ----------------------------------------------------------------------

loc_15e40:
                clr.w   6(a0)
                bclr    #7,2(a0)
                move.l  ($FFFFD27C).w,$34(a0)
                clr.l   $2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_15e86
                addq.w  #4,d7
                subq.w  #4,d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_15ea8
                moveq   #0,d7
                moveq   #-4,d6
                bsr.w   loc_115c0
                tst.b   d4
                bne.s   loc_15ed6
                bsr.w   AnimateSprite
                rts

loc_15e86:
                move.b  #6,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                subq.w  #1,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #loc_1AC04,$C(a0)
                rts

loc_15ea8:
                move.b  #5,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                addq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1ABCC,$C(a0)
                rts

loc_15ed6:
                move.w  #8,$3C(a0)
                move.l  #loc_1AC4C,$C(a0)
                rts

; ----------------------------------------------------------------------

loc_15ee6:
                move.w  #4,6(a0)
                bset    #7,2(a0)
                move.l  ($FFFFD27C).w,d0
                neg.l   d0
                move.l  d0,$34(a0)
                clr.l   $2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_15f32
                subq.w  #4,d7
                addq.w  #4,d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_15f5a
                moveq   #0,d7
                moveq   #4,d6
                bsr.w   loc_115c0
                tst.b   d4
                bne.s   loc_15f8e
                bsr.w   AnimateSprite
                rts

; ======================================================================

loc_15f32:
                move.b  #5,$3A(a0)
                move.w  $30(a0),d7
                andi.w  #$FFF8,d7
                addq.w  #8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                move.l  #loc_1AC20,$C(a0)
                bclr    #7,2(a0)
                rts

; ======================================================================

loc_15f5a:
                move.b  #6,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                subq.w  #4,$20(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1ABE8,$C(a0)
                bclr    #7,2(a0)
                rts

; ======================================================================

loc_15f8e:
                move.w  #8,$3C(a0)
                move.l  #loc_1AC64,$C(a0)
                rts

; ----------------------------------------------------------------------

loc_15f9e:
                move.w  #8,6(a0)
                bclr    #7,2(a0)
                clr.l   $34(a0)
                move.l  ($FFFFD27C).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_15fde
                subq.w  #4,d7
                subq.w  #4,d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_16004
                bsr.w   AnimateSprite
                rts

loc_15fde:
                clr.b   $3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                addq.w  #8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1AC2E,$C(a0)
                bclr    #7,2(a0)
                rts

; ======================================================================

loc_16004:
                move.b  #3,$3A(a0)
                andi.w  #$FFF8,d7
                addq.w  #7,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1ABDA,$C(a0)
                bclr    #7,2(a0)
                rts

; ----------------------------------------------------------------------

loc_16036:
                move.w  #$C,6(a0)
                bset    #7,2(a0)
                clr.l   $34(a0)
                move.l  ($FFFFD27C).w,$2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                bsr.w   loc_1157c
                tst.b   d4
                beq.s   loc_16072
                addq.w  #4,d7
                addq.w  #4,d6
                bsr.w   loc_1157c
                tst.b   d4
                bne.s   loc_1609a
                bsr.w   AnimateSprite
                rts

; ======================================================================

loc_16072:
                move.b  #3,$3A(a0)
                move.w  $24(a0),d6
                andi.w  #$FFF8,d6
                subq.w  #1,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1AC12,$C(a0)
                bclr    #7,2(a0)
                rts

; ======================================================================

loc_1609a:
                move.b  #0,$3A(a0)
                andi.w  #$FFF8,d7
                move.w  d7,$30(a0)
                clr.w   $32(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1ABF6,$C(a0)
                bclr    #7,2(a0)
                rts

; ----------------------------------------------------------------------

loc_160c8:
                bset    #7,$3C(a0)
                bne.s   loc_160d6
                move.b  #5,5(a0)
loc_160d6:
                btst    #1,$3A(a0)
                bne.s   loc_16136
                move.w  #$10,6(a0)
                clr.l   $34(a0)
                move.l  ($FFFFD27C).w,d0
                neg.l   d0
                move.l  d0,$2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                bsr.w   loc_1157c
                bne.s   loc_1610c
                bsr.w   AnimateSprite
                rts

loc_1610c:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                addq.w  #7,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1AC64,$C(a0)
                rts

loc_16136:
                move.w  #$14,6(a0)
                clr.l   $34(a0)
                move.l  ($FFFFD27C).w,$2C(a0)
                bsr.w   loc_1105c
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                addq.w  #8,d6
                bsr.w   loc_1157c
                bne.s   loc_16160
                bsr.w   AnimateSprite
                rts

loc_16160:
                move.w  #4,$3C(a0)
                bchg    #0,$3A(a0)
                bchg    #1,$3A(a0)
                andi.w  #$FFF8,d6
                move.w  d6,$24(a0)
                clr.w   $26(a0)
                move.l  #loc_1AC4C,$C(a0)
                rts

; ----------------------------------------------------------------------

loc_16188:
                bset    #7,$3C(a0)
                bne.s   loc_161aa
                move.l  a0,-(sp)
                move.b  #$93,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                move.w  #$18,6(a0)
                subq.b  #1,($FFFFD26C).w
                clr.b   5(a0)
loc_161aa:
                bsr.w   loc_14688
                tst.l   $34(a0)
                bne.s   loc_161ba
                move.w  #$10,$3C(a0)
loc_161ba:
                rts

; ----------------------------------------------------------------------

loc_161bc:
                bset    #7,$3C(a0)
                bne.s   loc_161e0
                bclr    #2,2(a0)
                move.w  #$1C,6(a0)
                clr.b   $10(a0)
                move.l  #$FFFFC000,$2C(a0)    ; TODO - Object slot to load to?
                clr.b   5(a0)
loc_161e0:
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
                btst    #2,2(a0)
                beq.s   loc_16216
                move.b  ($FFFFD88A).w,d0
                andi.b  #$F0,d0
                bne.s   loc_16212
                lea     ($FFFFC7C0).w,a1
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a1)
                move.w  d6,$24(a1)
                move.w  #$28,(a1)
loc_16212:
                bsr.w   loc_11118
loc_16216:
                rts

; ======================================================================

loc_16218:
                lea     ($FFFFC200).w,a1
loc_1621C:
                moveq   #5,d0
loc_1621E:
                move.w  d0,-(sp)
                btst    #4,5(a1)
                beq.s   loc_1629c
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_1629c
                move.w  #$C,$3C(a0)
                clr.b   5(a0)
                move.l  $34(a1),d7
                move.l  $2C(a1),d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                addq.b  #1,$3B(a1)
                moveq   #0,d0
                move.b  $3B(a1),d0
                subq.b  #1,d0
                lsl.w   #2,d0
                move.l  loc_162ac(pc,d0.w),d0
                move.l  d0,($FFFFD262).w
                move.l  a1,-(sp)
                bsr.w   loc_1168a
                movea.l (sp)+,a1
                lea     ($FFFFC0C0).w,a2
                moveq   #3,d0
loc_1626E:
                tst.b   (a2)
                bne.s   loc_16292
                move.w  #$1C,(a2)
                move.b  $3B(a1),d1
                move.b  d1,$3A(a2)
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                subq.w  #8,d6
                move.w  d7,$30(a2)
                move.w  d6,$24(a2)
                bra.s   loc_162a8
loc_16292:
                lea     -$40(a2),a2
                dbf     d0,loc_1626e
                bra.s   loc_162a8

loc_1629c:
                lea     $40(a1),a1
                move.w  (sp)+,d0
                dbf     d0,loc_1621E
                rts

loc_162a8:
                move.w  (sp)+,d0
                rts

; ======================================================================

loc_162ac:
                dc.l    $00000200
                dc.l    $00000400
                dc.l    $00000800
                dc.l    $00001600

; ======================================================================

loc_162bc:
                dc.l    loc_162DC
                dc.l    loc_162E6
                dc.l    loc_162F0
                dc.l    loc_162F6
                dc.l    loc_162FC
                dc.l    loc_16302
                dc.l    loc_16308
                dc.l    loc_154FE

; ----------------------------------------------------------------------

loc_162dc:
                dc.b    $04, $01
                dc.w    loc_1AB7C&$FFFF
                dc.w    loc_1AB84&$FFFF
                dc.w    loc_1AB8C&$FFFF
                dc.w    loc_1AB84&$FFFF

; ----------------------------------------------------------------------

loc_162e6:
                dc.b    $04, $01
                dc.w    loc_1AB94&$FFFF
                dc.w    loc_1AB9C&$FFFF
                dc.w    loc_1ABA4&$FFFF
                dc.w    loc_1AB9C&$FFFF

; ----------------------------------------------------------------------

loc_162f0:
                dc.b    $02, $01
                dc.w    loc_1ABAC&$FFFF
                dc.w    loc_1ABB4&$FFFF

; ----------------------------------------------------------------------

loc_162f6:
                dc.b    $02, $01
                dc.w    loc_1ABBC&$FFFF
                dc.w    loc_1ABC4&$FFFF

; ----------------------------------------------------------------------

loc_162fc:
                dc.b    $02, $01
                dc.w    loc_1AC3C&$FFFF
                dc.w    loc_1AC44&$FFFF

; ----------------------------------------------------------------------

loc_16302:
                dc.b    $02, $01
                dc.w    loc_1AC54&$FFFF
                dc.w    loc_1AC5C&$FFFF

; ----------------------------------------------------------------------

loc_16308:
                dc.b    $04, $01
                dc.w    loc_1AC6C&$FFFF
                dc.w    loc_1AC7A&$FFFF
                dc.w    loc_1AC88&$FFFF
                dc.w    loc_1AC96&$FFFF

; ======================================================================
; Gleaming eyes in the catflap.
; ======================================================================
loc_16312:
                bset    #7,(a0)                  ; Set the object as loaded.
                bne.s   loc_1633e                ; If it was already loaded, branch.
                move.b  $3E(a0),d7               ;
                move.b  $3F(a0),d6               ;
                bsr.w   loc_11674                ;
                addq.w  #8,d7                    ;
                addi.w  #$10,d6                  ;
                move.w  d7,$30(a0)               ;
                move.w  d6,$24(a0)               ;
                tst.b   ($FFFFD26C).w            ;
                beq.s   loc_1633E                ;
                move.w  ($FFFFD294).w,$38(a0)    ;
loc_1633E:
                move.l  #loc_163E0,8(a0)
                tst.b   ($FFFFD24F).w
                bne.s   loc_1635c
                tst.b   ($FFFFD27B).w
                bne.s   loc_1635c
                moveq   #$7C,d0                  ; Set routine counter variable as $7C.
                and.w   $3C(a0),d0               ; And by routine to get values 0 or 4.
                jsr     loc_1635e(pc,d0.w)       ; Jump to that routine.
loc_1635c:
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_1635e:
                bra.w   loc_16366                ; $0
                bra.w   loc_16396                ; $4

; ----------------------------------------------------------------------

loc_16366:
                bset    #7,$3C(a0)               ; Set routine as ran.
                bne.s   loc_16378                ; If it's already ran, branch.
                addq.b  #1,($FFFFD26C).w         ;
                bset    #1,2(a0)                 ; Turn off object's display.
loc_16378:
                bsr.w   loc_1105c                ;
                tst.w   $38(a0)                  ;
                bne.s   loc_16390                ;
                bclr    #1,2(a0)                 ; Turn on object's display.
                move.w  #4,$3C(a0)               ; Set to load the next routine.
                rts

loc_16390:
                subq.w  #1,$38(a0)               ;
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_16396:
                bset    #7,$3C(a0)
                bne.s   loc_163AC
                bclr    #2,2(a0)
                clr.b   $10(a0)
                clr.w   6(a0)
loc_163AC:
                bsr.w   loc_1105C
                bsr.w   AnimateSprite
                bclr    #2,2(a0)
                beq.s   loc_163DE
                movea.l a0,a1
                suba.l  #$00000300,a1
                move.b  $16(a0),d0
                move.w  #$10,(a1)
                move.b  d0,$16(a1)
                cmpi.b  #2,d0
                bne.s   loc_163DA
                move.w  #$14,(a1)
loc_163DA:
                bsr.w   loc_11118
loc_163DE:
                rts

; ----------------------------------------------------------------------
loc_163E0:
                dc.l    loc_163E4

; ----------------------------------------------------------------------

loc_163E4:
                dc.b    $1C, $04
                dc.w    loc_1AAEC&$FFFF
                dc.w    loc_1AAEC&$FFFF
                dc.w    loc_1AAEC&$FFFF
                dc.w    loc_1AAF4&$FFFF
                dc.w    loc_1AAF4&$FFFF
                dc.w    loc_1AAF4&$FFFF
                dc.w    loc_1AAFC&$FFFF
                dc.w    loc_1AB04&$FFFF
                dc.w    loc_1AB0C&$FFFF
                dc.w    loc_1AB14&$FFFF
                dc.w    loc_1AB1C&$FFFF
                dc.w    loc_1AB14&$FFFF
                dc.w    loc_1AB0C&$FFFF
                dc.w    loc_1AB04&$FFFF
                dc.w    loc_1AAFC&$FFFF
                dc.w    loc_1AB04&$FFFF
                dc.w    loc_1AB0C&$FFFF
                dc.w    loc_1AB14&$FFFF
                dc.w    loc_1AB1C&$FFFF
                dc.w    loc_1AB14&$FFFF
                dc.w    loc_1AB0C&$FFFF
                dc.w    loc_1AB04&$FFFF
                dc.w    loc_1AAFC&$FFFF
                dc.w    loc_1AB04&$FFFF
                dc.w    loc_1AB0C&$FFFF
                dc.w    loc_1AB14&$FFFF
                dc.w    loc_1AB1C&$FFFF
                dc.w    loc_1AB14&$FFFF
                dc.w    loc_1AB0C&$FFFF
                dc.w    loc_1AB04&$FFFF

; ======================================================================

loc_16422:
                bset    #7,(a0)                  ; Set object as loaded.
                bne.s   loc_16442                ; If it was already loaded, branch.
                moveq   #0,d0                    ; Clear d0.
                move.b  $3A(a0),d0               ; Load the TODO into d0.
                subq.b  #1,d0                    ;
                lsl.w   #1,d0                    ;
                moveq   #-1,d1                   ; Set d1 to $FFFFFFFF.
                move.w  loc_16450(pc,d0.w),d1    ; Load the position in RAM the TODO are located, corresponding with its position in ROM.
                move.l  d1,$C(a0)                ;
                move.w  #$3C,$38(a0)             ;
loc_16442:
                bsr.w   loc_1105c
                subq.w  #1,$38(a0)
                bne.s   loc_1644e
                clr.w   (a0)
loc_1644e:
                rts

; ----------------------------------------------------------------------

loc_16450:
                dc.w    loc_1AB2C&$FFFF
                dc.w    loc_1AB3C&$FFFF
                dc.w    loc_1AB4C&$FFFF

; ======================================================================

loc_16456:
                bset    #7,(a0)
                bne.s   loc_16490
                move.b  $3A(a0),d0
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #-1,d1
                move.w  loc_1649e(pc,d0.w),d1
                move.l  d1,$C(a0)
                lsl.w   #2,d0
                move.w  ($FFFFD25C).w,d6
                cmpi.w  #$F0,d6
                bcs.s   loc_16482
                sub.w   d0,d6
                subi.w  #$18,d6
                bra.s   loc_16486

loc_16482:
                add.w   d0,d6
                addq.w  #8,d6
loc_16486:
                move.w  d6,$24(a0)
                move.w  #$1E,$38(a0)
loc_16490:
                bsr.w   loc_1105c
                subq.w  #1,$38(a0)
                bne.s   loc_1649c
                clr.w   (a0)
loc_1649c:
                rts

; ----------------------------------------------------------------------

loc_1649e:
                dc.w    loc_1AB24&$FFFF
                dc.w    loc_1AB2C&$FFFF
                dc.w    loc_1AB34&$FFFF
                dc.w    loc_1AB3C&$FFFF
                dc.w    loc_1AB44&$FFFF
                dc.w    loc_1AB54&$FFFF
                dc.w    loc_1AB5C&$FFFF
                dc.w    loc_1AB6C&$FFFF

; ======================================================================

loc_164ae:
                bset    #7,(a0)
                bne.s   loc_164cc
                moveq   #0,d0
                move.b  $3A(a0),d0
                lsl.w   #1,d0
                moveq   #-1,d1
                move.w  loc_164da(pc,d0.w),d1
                move.l  d1,$C(a0)
                move.w  #$3C,$38(a0)
loc_164cc:
                bsr.w   loc_1105c
                subq.w  #1,$38(a0)
                bne.s   loc_164d8
                clr.w   (a0)
loc_164d8:
                rts

; ----------------------------------------------------------------------

loc_164da:
                dc.w    loc_1AB24&$FFFF
                dc.w    loc_1AB2C&$FFFF
                dc.w    loc_1AB34&$FFFF
                dc.w    loc_1AB3C&$FFFF
                dc.w    loc_1AB44&$FFFF
                dc.w    loc_1AB4C&$FFFF
                dc.w    loc_1AB54&$FFFF
                dc.w    loc_1AB5C&$FFFF
                dc.w    loc_1AB64&$FFFF

; ======================================================================

loc_164ec:
                bset    #7,(a0)
                bne.s   loc_1651a
                clr.b   5(a0)
                clr.l   $34(a0)
                clr.l   $2C(a0)
                addq.w  #7,$24(a0)
                move.l  #loc_165AC,8(a0)
                clr.w   6(a0)
                move.w  #$12C,$38(a0)
                bclr    #7,2(a0)
loc_1651a:
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
                lea     ($FFFFC440).w,a1
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_1657c
                move.l  a0,-(sp)
                move.b  #$98,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                lea     ($FFFFC0C0).w,a2
                moveq   #3,d0
loc_16540:
                tst.w   (a2)
                bne.s   loc_16574
                move.w  $30(a0),d7
                move.w  $24(a0),d6
                move.w  d7,$30(a2)
                subq.w  #8,d6
                move.w  d6,$24(a2)
                moveq   #0,d7
                move.b  ($FFFFD27A).w,d7
                move.b  d7,$3A(a2)
                move.w  #$24,(a2)
                lsl.w   #2,d7
                move.l  loc_16588(pc,d7.w),d7
                move.l  d7,($FFFFD262).w
                bsr.w   loc_1168a
                bra.s   loc_16582

loc_16574:
                lea     -$40(a2),a2
                dbf     d0,loc_16540
loc_1657c:
                subq.w  #1,$38(a0)
                bne.s   loc_16586
loc_16582:
                bsr.w   loc_11118
loc_16586:
                rts

; ----------------------------------------------------------------------

loc_16588:
                dc.l    $00000100
                dc.l    $00000200
                dc.l    $00000300
                dc.l    $00000400
                dc.l    $00000500
                dc.l    $00000800
                dc.l    $00001000
                dc.l    $00002000
                dc.l    $00003000

; ----------------------------------------------------------------------

loc_165ac:
                dc.l    loc_165B0

; ----------------------------------------------------------------------

loc_165b0:
                dc.b    $04, $05
                dc.w    loc_1A8D8&$FFFF
                dc.w    loc_1A8E0&$FFFF
                dc.w    loc_1A8E8&$FFFF
                dc.w    loc_1A8F0&$FFFF

; ======================================================================

loc_165ba:
                bset    #7,(a0)
                bne.s   loc_165f0
                move.w  #$140,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   loc_165de
                move.w  #$C0,$30(a0)
                bset    #7,2(a0)
loc_165de:
                move.w  #$150,$24(a0)
                move.l  #loc_1669A,8(a0)
                clr.w   6(a0)
loc_165f0:
                tst.b   ($FFFFD27B).w
                bne.s   loc_165fe
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
loc_165fe:
                rts

; ======================================================================

loc_16600:
                bset    #7,(a0)
                bne.s   loc_16638
                move.w  #$130,$30(a0)
                bclr    #7,2(a0)
                tst.b   $16(a0)
                beq.s   loc_16624
                move.w  #$D0,$30(a0)
                bset    #7,2(a0)
loc_16624:
                move.w  #$150,$24(a0)
                move.l  #loc_1669A,8(a0)
                move.w  #4,6(a0)
loc_16638:
                tst.b   ($FFFFD27B).w
                bne.s   loc_16646
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
loc_16646:
                rts

; ======================================================================

loc_16648:
                lea     ($FFFFC580).w,a1
                move.l  $30(a1),d7
                move.l  $24(a1),d6
                move.l  d7,$30(a0)
                move.l  d6,$24(a0)
                addi.w  #$A,$24(a0)
                tst.b   $39(a1)
                beq.s   loc_16674
                bclr    #7,2(a0)
                subq.w  #8,$30(a0)
                bra.s   loc_1667e

loc_16674:
                bset    #7,2(a0)
                addq.w  #8,$30(a0)
loc_1667e:
                bsr.w   loc_1105c
                move.l  #loc_1AAD6,$C(a0)
                tst.l   $34(a1)
                beq.s   loc_16698
                move.l  #loc_1AAE4,$C(a0)
loc_16698:
                rts

; ----------------------------------------------------------------------

loc_1669a:
                dc.l    loc_166A2
                dc.l    loc_166B4

; ----------------------------------------------------------------------

loc_166a2:
                dc.b    $08, $07
                dc.w    loc_1AA96&$FFFF
                dc.w    loc_1AAA4&$FFFF
                dc.w    loc_1AAB2&$FFFF
                dc.w    loc_1AABA&$FFFF
                dc.w    loc_1AAC8&$FFFF
                dc.w    loc_1AABA&$FFFF
                dc.w    loc_1AAB2&$FFFF
                dc.w    loc_1AAA4&$FFFF

; ----------------------------------------------------------------------

loc_166b4:
                dc.b    $08, $07
                dc.w    loc_1AA1A&$FFFF
                dc.w    loc_1AA2E&$FFFF
                dc.w    loc_1AA42&$FFFF
                dc.w    loc_1AA56&$FFFF
                dc.w    loc_1AA6A&$FFFF
                dc.w    loc_1AA56&$FFFF
                dc.w    loc_1AA42&$FFFF
                dc.w    loc_1AA2E&$FFFF

; ======================================================================

loc_166c6:
                bset    #7,(a0)
                bne.s   loc_166EC
                bset    #1,2(a0)
                move.l  #loc_14E12,8(a0)
                movea.l ($FFFFD282).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
loc_166E6:
                move.w  (a1,d0.w),$3A(a0)
loc_166EC:
                moveq   #$7C,d0
                and.w   $3C(a0),d0
                jsr     loc_166fc(pc,d0.w)
                bsr.w   AnimateSprite
                rts

; ----------------------------------------------------------------------

loc_166fc:
                bra.w   loc_16708
                bra.w   loc_16782
                bra.w   loc_167d6

; ----------------------------------------------------------------------

loc_16708:
                tst.w   $3A(a0)
                bne.s   loc_16778
                bset    #7,$3C(a0)
                bne.s   loc_16756
                bclr    #1,2(a0)
                move.w  #4,6(a0)
                move.w  #$150,$24(a0)
                move.w  #$80,$30(a0)
                move.l  #$00008000,$34(a0)
                bclr    #7,2(a0)
                tst.b   $39(a0)
                beq.s   loc_16756
                move.w  #$17F,$30(a0)
                move.l  #$FFFF8000,$34(a0)
                bset    #7,2(a0)
loc_16756:
                bsr.w   loc_1105C
                lea     ($FFFFC640).w,a1
                tst.b   $39(a0)
                bne.s   loc_16768
                lea     $40(a1),a1
loc_16768:
                bsr.w   loc_117C0
                tst.b   d0
                beq.s   loc_16776
                move.w  #4,$3C(a0)
loc_16776:
                rts

; ----------------------------------------------------------------------

loc_16778:
                subq.w  #1,$3A(a0)
                bsr.w   loc_1105c
                rts

; ----------------------------------------------------------------------

loc_16782:
                bset    #7,$3C(a0)
                bne.s   loc_167b8
                movea.l ($FFFFD286).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
                move.b  (a1,d0.w),d7
                move.b  1(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                moveq   #$C,d0
                lsl.l   d0,d7
                lsl.l   d0,d6
                move.l  d7,$34(a0)
                move.l  d6,$2C(a0)
                bsr.w   loc_16892
loc_167b8:
                addi.l  #$00001000,$2C(a0)
                bne.s   loc_167c8
                move.w  #8,$3C(a0)
loc_167c8:
                bsr.w   loc_16854
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
                rts

; ----------------------------------------------------------------------

loc_167d6:
                bset    #7,$3C(a0)
                bne.s   loc_16806
                clr.w   6(a0)
                move.l  $34(a0),d7
                bpl.s   loc_167f0
                neg.l   d7
                lsr.l   #1,d7
                neg.l   d7
                bra.s   loc_167f2

loc_167f0:
                lsr.l   #1,d7
loc_167f2:
                move.l  d7,$34(a0)
                cmpi.w  #$FFFF,$3A(a0)
                beq.s   loc_16806
                addq.b  #1,$3E(a0)
                bsr.w   loc_16892
loc_16806:
                cmpi.l  #$00018000,$2C(a0)
                bgt.s   loc_16818
                addi.l  #$400,$2C(a0)
loc_16818:
                bsr.w   loc_16854
                bsr.w   loc_1105c
                bsr.w   loc_168e2
                cmpi.w  #$180,$24(a0)
                bcs.s   loc_16834
                bsr.w   loc_110f0
                subq.b  #1,($FFFFD883).w
loc_16834:
                bsr.w   AnimateSprite
                tst.b   ($FFFFD883).w
                bne.s   loc_16852
                clr.w   ($FFFFFF92).w
                move.b  #1,($FFFFD281).w
                move.w  #4,($FFFFD2A6).w
                bsr.w   loc_16988
loc_16852:
                rts
; ======================================================================

loc_16854:
                move.w  $3A(a0),d0
                cmpi.w  #-1,d0
                beq.s   loc_16890
                subq.w  #1,d0
                bne.s   loc_1686c
                addq.b  #1,$3E(a0)
                bsr.w   loc_16892
                bra.s   loc_16854

loc_1686c:
                move.w  d0,$3A(a0)
                move.l  $34(a0),d7
                move.l  $1C(a0),d6
                bmi.s   loc_16884
                cmp.l   d6,d7
                bge.s   loc_16882
                add.l   $18(a0),d7
loc_16882:
                bra.s   loc_1688c

loc_16884:
                cmp.l   d6,d7
                ble.s   loc_1688c
                add.l   $18(a0),d7
loc_1688c:
                move.l  d7,$34(a0)
loc_16890:
                rts

loc_16892:
                moveq   #0,d0
                move.b  $38(a0),d0
                movea.l ($FFFFD28A).w,a1
                move.b  (a1,d0.w),d0
                lsl.w   #2,d0
                lea     loc_16d18(pc),a1
                movea.l (a1,d0.w),a1
                moveq   #0,d0
                move.b  $3E(a0),d0
                lsl.w   #2,d0
                move.w  (a1,d0.w),$3A(a0)
                move.b  2(a1,d0.w),d7
                move.b  3(a1,d0.w),d6
                ext.w   d7
                ext.l   d7
                ext.w   d6
                ext.l   d6
                lsl.l   #8,d7
                moveq   #$C,d0
                lsl.l   d0,d6
                tst.b   $39(a0)
                beq.s   loc_168d8
                neg.l   d7
                neg.l   d6
loc_168d8:
                move.l  d7,$18(a0)
                move.l  d6,$1C(a0)
                rts

; ======================================================================

loc_168e2:
                lea     ($FFFFC040).w,a1
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_1691a
                move.l  a0,-(sp)
                move.b  #$90,d0
                bsr.w   loc_10d48
                movea.l (sp)+,a0
                bsr.w   loc_110f0
                subq.b  #1,($FFFFD883).w
                addq.b  #1,($FFFFD28E).w
                moveq   #1,d0
                move.b  ($FFFFD28F).w,d1
                addi.b  #0,d1
                abcd    d0,d1
                move.b  d1,($FFFFD28F).w
                bsr.w   loc_169d4
loc_1691a:
                rts

; ======================================================================

loc_1691c:
                tst.b   ($FFFFD28E).w
                beq.s   loc_16944
                lea     loc_1694c(pc),a6
                bsr.w   WriteASCIIString
                cmpi.b  #$14,($FFFFD28E).w
                bne.s   loc_16942
                lea     loc_16964(pc),a6
                bsr.w   WriteASCIIString
                lea     loc_16974(pc),a6
                bsr.w   WriteASCIIString
loc_16942:
                rts
loc_16944:
                lea     loc_1697c(pc),a6
                bra.w   WriteASCIIString

; ----------------------------------------------------------------------

loc_1694c:
                dc.w    $C24E                    ; VRAM address to write to.
                dc.b    $3B, $20                 ; Hex byte for the multiplication table and a space.
                dc.b    '250 PTS.=      PTS.'    ; Mappings text.
                dc.b    $00                      ; String terminator.

loc_16964:
                dc.w    $C312                    ; VRAM address to write to.
                dc.b    'PERFECT BONUS'          ; Mappings text.
                dc.b    $00                      ; String terminator.

loc_16974:
                dc.w    $C3A2                    ; VRAM address to write to.
                dc.b    'PTS.'                   ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

loc_1697c:
                dc.w    $C316                    ; VRAM address to write to.
                dc.b    'NO BONUS'               ; Mappings text.
                dc.w    $0000                    ; String terminator, pad to even.

; ===========================================================================

loc_16988:
                moveq   #0,d0
                move.b  ($FFFFD28E).w,d0
                beq.s   loc_169d2
                subq.w  #1,d0
loc_16992:
                move.l  #$00000250,($FFFFD262).w
                lea     ($FFFFD266).w,a2
                lea     ($FFFFD294).w,a1
                moveq   #3,d1
                move.w  #4,ccr
loc_169a8:
                abcd    -(a2),-(a1)
                dbf     d1,loc_169a8
                dbf     d0,loc_16992
                move.l  ($FFFFD290).w,d0
                move.l  d0,($FFFFD262).w
                bsr.w   loc_1168a
                cmpi.b  #$14,($FFFFD28E).w
                bne.s   loc_169d2
                move.l  #$10000,($FFFFD262).w
                bsr.w   loc_1168a
loc_169d2:
                rts

; ======================================================================

loc_169d4:
                moveq   #0,d0
                move.b  ($FFFFD28E).w,d0
                subq.w  #1,d0
                move.l  #$414C0003,($C00004).l
loc_169e6:
                move.w  #$E351,($C00000).l
                dbf     d0,loc_169e6
                rts

; ======================================================================

loc_169f4:
                dc.l    loc_16A24
                dc.l    loc_16A24
                dc.l    loc_16A24
                dc.l    loc_16A4C
                dc.l    loc_16A74
                dc.l    loc_16A74
                dc.l    loc_16A74
                dc.l    loc_16A74
                dc.l    loc_16A74
                dc.l    loc_16A74
                dc.l    loc_16A74
                dc.l    loc_16A74

; ----------------------------------------------------------------------

loc_16a24:
                dc.w    $0000, $000F, $001E, $002D
                dc.w    $006E, $007D, $008C, $009B
                dc.w    $00DC, $00EB, $00FA, $0109
                dc.w    $014A, $0159, $0168, $0177
                dc.w    $01B8, $01C7, $01D6, $01E5

loc_16a4c:
                dc.w    $001E, $002D, $003C, $004B
                dc.w    $0000, $000F, $001E, $002D
                dc.w    $00FA, $0109, $0118, $0127
                dc.w    $00DC, $00EB, $00FA, $0109
                dc.w    $01B8, $01C7, $01D6, $01E5


loc_16a74:
                dc.w    $0000, $000F, $001E, $002D
                dc.w    $0064, $0073, $0082, $0091
                dc.w    $00C8, $00D7, $00E6, $00F5
                dc.w    $012C, $013B, $014A, $0159
                dc.w    $0190, $019F, $01AE, $01BD

; ======================================================================

loc_16a9c:
                dc.l    loc_16ACC
                dc.l    loc_16AF4
                dc.l    loc_16B1C
                dc.l    loc_16B44
                dc.l    loc_16B6C
                dc.l    loc_16B94
                dc.l    loc_16BBC
                dc.l    loc_16B94
                dc.l    loc_16ACC
                dc.l    loc_16BE4
                dc.l    loc_16C0C
                dc.l    loc_16B94

; ----------------------------------------------------------------------

loc_16acc:
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $F2B4
                dc.w    $F2B4
                dc.w    $F2B4
                dc.w    $F2B4
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $F2B4
                dc.w    $F2B4
                dc.w    $F2B4
                dc.w    $F2B4
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $0EB4
                dc.w    $0EB4


loc_16af4:
                dc.w    $0EB4
                dc.w    $0CB4
                dc.w    $0AB4
                dc.w    $08B4
                dc.w    $F2B4
                dc.w    $F4B4
                dc.w    $F6B4
                dc.w    $F8B4
                dc.w    $0EB4
                dc.w    $0CB4
                dc.w    $0AB4
                dc.w    $08B4
                dc.w    $F2B4
                dc.w    $F4B4
                dc.w    $F6B4
                dc.w    $F8B4
                dc.w    $0EB4
                dc.w    $0CB4
                dc.w    $0AB4
                dc.w    $08B4

loc_16B1C:
                dc.w    $0EB4
                dc.w    $0EB8
                dc.w    $0EBC
                dc.w    $0EC0
                dc.w    $F2B4
                dc.w    $F2B8
                dc.w    $F2BC
                dc.w    $F2C0
                dc.w    $0EB4
                dc.w    $0EB8
                dc.w    $0EBC
                dc.w    $0EC0
                dc.w    $F2B4
                dc.w    $F2B8
                dc.w    $F2BC
                dc.w    $F2C0
                dc.w    $0EB4
                dc.w    $0EB8
                dc.w    $0EBC
                dc.w    $0EC0


loc_16b44:
                dc.w    $0AB4
                dc.w    $0AB4
                dc.w    $0AB4
                dc.w    $0AB4
                dc.w    $F6B4
                dc.w    $F6B4
                dc.w    $F6B4
                dc.w    $F6B4
                dc.w    $0AB4
                dc.w    $0AB4
                dc.w    $0AB4
                dc.w    $0AB4
                dc.w    $F6B4
                dc.w    $F6B4
                dc.w    $F6B4
                dc.w    $F6B4
                dc.w    $05B4
                dc.w    $08B4
                dc.w    $0BB4
                dc.w    $0EB4


loc_16b6c:
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $DEB4
                dc.w    $DEB4
                dc.w    $DEB4
                dc.w    $DEB4
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $DEB4
                dc.w    $DEB4
                dc.w    $DEB4
                dc.w    $DEB4
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $22B4
                dc.w    $22B4



loc_16b94:
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $F7B4
                dc.w    $F7B4
                dc.w    $F7B4
                dc.w    $F7B4
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $F7B4
                dc.w    $F7B4
                dc.w    $F7B4
                dc.w    $F7B4
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $09B4
                dc.w    $09B4


loc_16bbc:
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $EEB4
                dc.w    $EEB4
                dc.w    $EEB4
                dc.w    $EEB4
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $EEB4
                dc.w    $EEB4
                dc.w    $EEB4
                dc.w    $EEB4
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $12B4
                dc.w    $12B4


loc_16be4:
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $20B4
                dc.w    $20B4
                dc.w    $20B4
                dc.w    $20B4
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $20B4
                dc.w    $20B4
                dc.w    $20B4
                dc.w    $20B4
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $E0B4
                dc.w    $E0B4
         
loc_16C0C:
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $C0B4
                dc.w    $C0B4
                dc.w    $C0B4
                dc.w    $C0B4
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $C0B4
                dc.w    $C0B4
                dc.w    $C0B4
                dc.w    $C0B4
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $40B4
                dc.w    $40B4

; ======================================================================

loc_16c34:
                dc.l    loc_16C64
                dc.l    loc_16C64
                dc.l    loc_16C64
                dc.l    loc_16C64
                dc.l    loc_16C78
                dc.l    loc_16C8C
                dc.l    loc_16CA0
                dc.l    loc_16CB4
                dc.l    loc_16CC8
                dc.l    loc_16CDC
                dc.l    loc_16CF0
                dc.l    loc_16D04

; ----------------------------------------------------------------------

loc_16c64:
                dc.b    $00, $00, $00, $00
                dc.b    $00, $00, $00, $00
                dc.b    $00, $00, $00, $00
                dc.b    $00, $00, $00, $00
                dc.b    $00, $00, $00, $00

loc_16c78:
                dc.b    $01, $01, $01, $01
                dc.b    $01, $01, $01, $01
                dc.b    $01, $01, $01, $01
                dc.b    $01, $01, $01, $01
                dc.b    $01, $01, $01, $01

loc_16c8c:
                dc.b    $02, $02, $02, $02
                dc.b    $02, $02, $02, $02
                dc.b    $02, $02, $02, $02
                dc.b    $02, $02, $02, $02
                dc.b    $02, $02, $02, $02

loc_16ca0:
                dc.b    $03, $03, $03, $03
                dc.b    $03, $03, $03, $03
                dc.b    $03, $03, $03, $03
                dc.b    $03, $03, $03, $03
                dc.b    $03, $03, $03, $03

loc_16cb4:
                dc.b    $04, $04, $04, $04
                dc.b    $04, $04, $04, $04
                dc.b    $04, $04, $04, $04
                dc.b    $04, $04, $04, $04
                dc.b    $04, $04, $04, $04

loc_16cc8:
                dc.b    $05, $05, $05, $05
                dc.b    $05, $05, $05, $05
                dc.b    $05, $05, $05, $05
                dc.b    $05, $05, $05, $05
                dc.b    $05, $05, $05, $05

loc_16cdc:
                dc.b    $06, $06, $06, $06
                dc.b    $06, $06, $06, $06
                dc.b    $06, $06, $06, $06
                dc.b    $06, $06, $06, $06
                dc.b    $06, $06, $06, $06

loc_16cf0:
                dc.b    $07, $07, $07, $07
                dc.b    $07, $07, $07, $07
                dc.b    $07, $07, $07, $07
                dc.b    $07, $07, $07, $07
                dc.b    $07, $07, $07, $07

loc_16d04:
                dc.b    $08, $08, $08, $08
                dc.b    $08, $08, $08, $08
                dc.b    $08, $08, $08, $08
                dc.b    $08, $08, $08, $08
                dc.b    $08, $08, $08, $08

; ======================================================================

loc_16d18:
                dc.l    loc_16D3C
                dc.l    loc_16D3E
                dc.l    loc_16D48
                dc.l    loc_16D5A
                dc.l    loc_16D68
                dc.l    loc_16D7A
                dc.l    loc_16D8C
                dc.l    loc_16D92
                dc.l    loc_16DA0

; ----------------------------------------------------------------------

loc_16D3C:
		dc.w $FFFF
loc_16D3E:
		dc.w $12C
		dc.w $F4E8
		dc.w $12C
		dc.w $310
		dc.w $FFFF

loc_16D48:
        	dc.w $12C
		dc.w $FEF8
		dc.w $14
		dc.w $C10
		dc.w $40
		dc.w $FAF0
		dc.w $12C
		dc.w $610
		dc.w $FFFF

loc_16D5A:
		dc.w $12C
		dc.w 0
		dc.w $58
		dc.w 0
		dc.w $12C
		dc.w $C0DE
		dc.w $FFFF

loc_16D68:
        	dc.w $12C
		dc.w $FEF8
		dc.w $30
		dc.w $1220
		dc.w $3A
		dc.w $EEE0
		dc.w $12C
		dc.w $620
		dc.w $FFFF

loc_16D7A:
        	dc.w $12C
		dc.w 0
		dc.w $32
		dc.w 0
		dc.w $18
		dc.w $E4E0
		dc.w $12C
		dc.w $1C0C
		dc.w $FFFF

loc_16D8C:
        	dc.w $12C
		dc.w $D1C
		dc.w $FFFF

loc_16D92:
        	dc.w $12C
		dc.w $F2E0
		dc.w $28
		dc.w $FCE0
		dc.w $12C
		dc.w $320
		dc.w $FFFF

loc_16DA0:
        	dc.w $12C
		dc.w $FEF8
		dc.w $12C
		dc.w $320
		dc.w $FFFF

; ======================================================================

loc_16daa:
                bset    #7,(a0)
                bne.s   loc_16dca
                move.w  #$D8,$20(a0)
                move.w  #$118,$24(a0)
                move.l  #loc_1ACA4,$C(a0)
                move.b  #1,($FFFFD27B).w
loc_16dca:
                rts

; ======================================================================
; Pause text on the screen.
; ======================================================================
loc_16dcc:
                bset    #7,(a0)                  ; Set the object as loaded.
                bne.s   loc_16DE6                ; If it's already been loaded, skip initialisation.
                move.l  #Map_Pause,$C(a0)        ; Load the 'PAUSE' mappings into the SST.
                move.w  #$F0,$20(a0)             ; Set the horizontal screen position.
                move.w  #$108,$24(a0)            ; Set the vertical screen position.
loc_16DE6:
                rts                              ; Return.

; ======================================================================

; TODO - End of code?

Pal_Main:                                        ; $16DE8
                incbin  "Palettes\Main.bin"

; ======================================================================
; TODO IMPORTANT IMPORTANT

loc_16e58:
                incbin  "Art\Nemesis\loc_16E58.bin"


; ======================================================================

loc_185FC:
                incbin  "Art\BtP\ASCII2.bin"
loc_185FC_End:
; ======================================================================

; EXIT SIGN? TODO

loc_18754:
                incbin  "Art\Nemesis\loc_18754.bin"

; =====================================================================
; Grabbable object compressed art.

loc_187D4:
                incbin  "Art\Nemesis\loc_187D4.bin"

; ======================================================================
; Points, Iggy, diamond and bonus points model graphics.

loc_1993e:
                incbin  "Art\Nemesis\VariousArt.bin"
; ======================================================================
; FLICKY TITLE SCREEN FONT

loc_19EEE:
                incbin  "Art\Nemesis\TitleFontArt.bin"

; ======================================================================

BGTiles_Unk1:                                          ; $1A196
                dc.w    $2200
BGTiles_Unk2:
                dc.w    $2201
BGTiles_Unk3:
                dc.w    $2202
BGTiles_Unk4:
                dc.w    $2203
BGTiles_Unk5:
                dc.w    $2204
BGTiles_Unk6:
                dc.w    $0000

; ======================================================================

RoofTiles1:                                         ; $1A1A2
                dc.w    $222B
                dc.w    $222C
                dc.w    $222D
                dc.w    $222E
                dc.w    $222F
                dc.w    $2230
                dc.w    $2231
                dc.w    $2232
RoofTiles2:
                dc.w    $2233
                dc.w    $2234
                dc.w    $2235
                dc.w    $2236
                dc.w    $2237
                dc.w    $2238
                dc.w    $2239
                dc.w    $223A
RoofTiles3:
                dc.w    $223B
                dc.w    $223C
                dc.w    $223D
                dc.w    $223E
                dc.w    $223F
                dc.w    $2240
                dc.w    $2241
                dc.w    $2242
RoofTiles4:
                dc.w    $2243
                dc.w    $2244
                dc.w    $2245
                dc.w    $2246
                dc.w    $2247
                dc.w    $2248
                dc.w    $2249
                dc.w    $224A
RoofTiles5:
                dc.w    $224B
                dc.w    $224C
                dc.w    $224D
                dc.w    $224E
                dc.w    $224F
                dc.w    $2250
                dc.w    $2251
                dc.w    $2252
RoofTiles6:
                dc.w    $2253
                dc.w    $2205
                dc.w    $2205
                dc.w    $2205
                dc.w    $2254
                dc.w    $2255
                dc.w    $2256
                dc.w    $2257

; ======================================================================

GroundTiles1:                                    ; $1A202
                dc.w    $2258
                dc.w    $2258
                dc.w    $2258
                dc.w    $2258
                dc.w    $2258
                dc.w    $2258
                dc.w    $2258
                dc.w    $2258
GroundTiles2:
                dc.w    $2259
                dc.w    $225A
                dc.w    $225B
                dc.w    $225C
                dc.w    $225D
                dc.w    $225E
                dc.w    $225F
                dc.w    $2260
GroundTiles3:
                dc.w    $2261
                dc.w    $2262
                dc.w    $2263
                dc.w    $2264
                dc.w    $2265
                dc.w    $2240
                dc.w    $2241
                dc.w    $2266
GroundTiles4:
                dc.w    $2267
                dc.w    $2268
                dc.w    $2269
                dc.w    $226A
                dc.w    $226B
                dc.w    $226C
                dc.w    $226D
                dc.w    $226E
GroundTiles5:
                dc.w    $226F
                dc.w    $2270
                dc.w    $2271
                dc.w    $2272
                dc.w    $2273
                dc.w    $2274
                dc.w    $2275
                dc.w    $2276
GroundTiles6:
                dc.w    $2277
                dc.w    $2277
                dc.w    $2277
                dc.w    $2277
                dc.w    $2278
                dc.w    $2279
                dc.w    $227A
                dc.w    $227B

; ======================================================================
; 'FLICKY' sign used instead of the 'EXIT' sign, in the Japanese version.
FlickySignMaps:                                  ; $1A262
                dc.w    $029E, $029F, $02A0      ; White 'FLICKY' text.
                dc.w    $02A1, $02A2, $02A3      ; Black 'FLICKY' text.
                dc.w    $02A4, $02A5, $02A6      ; Red 'FLICKY' text.

; ======================================================================

DoorMaps:                                        ; $1A274
                dc.w    $62A7
                dc.w    $62A8
                dc.w    $62A9
                dc.w    $62AA
                dc.w    $62AB
                dc.w    $62AC
                dc.w    $62AD
                dc.w    $62AE
                dc.w    $62AF

loc_1a286:
                dc.w    $62B0
                dc.w    $62B1
                dc.w    $62B2
                dc.w    $62B3
                dc.w    $62B4
                dc.w    $62B5

loc_1a292:
                dc.w    $629A
                dc.w    $629B
                dc.w    $629C
                dc.w    $629D

loc_1A29A:
                dc.w    $627C
                dc.w    $627D
                dc.w    $627E
                dc.w    $627F
                dc.w    $6280
                dc.w    $6281

loc_1A2A6:
                dc.w    $6282
                dc.w    $6283
                dc.w    $6284
                dc.w    $6285
                dc.w    $6286
                dc.w    $6287

loc_1A2B2:
                dc.w    $6288
                dc.w    $6289
                dc.w    $628A
                dc.w    $628B
                dc.w    $628C
                dc.w    $628D
         
loc_1A2BE:
                dc.w    $628E
                dc.w    $628F
                dc.w    $6290
                dc.w    $6291
                dc.w    $6292
                dc.w    $6293

loc_1A2CA:
                dc.w    $6294
                dc.w    $6295
                dc.w    $6296
                dc.w    $6297
                dc.w    $6298
                dc.w    $6299

; ======================================================================

BGTiles1:                                         ; $1A2D6
                dc.w    $2200
                dc.w    $2215
                dc.w    $2216
                dc.w    $2217
                dc.w    $2218
                dc.w    $2217
                dc.w    $2216
                dc.w    $2217
BGTiles2:
                dc.w    $2201
                dc.w    $2219
                dc.w    $221A
                dc.w    $221B
                dc.w    $221C
                dc.w    $221B
                dc.w    $221A
                dc.w    $221B
BGTiles3:
                dc.w    $2202
                dc.w    $221D
                dc.w    $221E
                dc.w    $221F
                dc.w    $2220
                dc.w    $221F
                dc.w    $221E
                dc.w    $221F
BGTiles4:
                dc.w    $2203
                dc.w    $2221
                dc.w    $2222
                dc.w    $2223
                dc.w    $2224
                dc.w    $2223
                dc.w    $2222
                dc.w    $2223
BGTiles5:
                dc.w    $2204
                dc.w    $2225
                dc.w    $2226
                dc.w    $2227
                dc.w    $2228
                dc.w    $2227
                dc.w    $2226
                dc.w    $2227
BGTiles6:
                dc.w    $2205
                dc.w    $2229
                dc.w    $2205
                dc.w    $2205
                dc.w    $222A
                dc.w    $2205
                dc.w    $2205
                dc.w    $2205

; ======================================================================
; Wallpaper scenery.
WallpaperTiles1:                                 ; $1A336

                dc.w    $02B6
                dc.w    $02B7
                dc.w    $02B8
                dc.w    $02B9
                dc.w    $02BA
                dc.w    $02BB
                dc.w    $02BC
                dc.w    $02BD
                dc.w    $02BE
                dc.w    $02BF
                dc.w    $02C0
                dc.w    $02C1
                dc.w    $02C2
                dc.w    $02C3
                dc.w    $02C4
WallpaperScenery1:                               ; $1A354
                dc.w    $02C5
                dc.w    $02C6
                dc.w    $02C7
                dc.w    $0205
                dc.w    $02C8
                dc.w    $02C9
                dc.w    $02CA
                dc.w    $02CB
                dc.w    $02CC
                dc.w    $02CD
                dc.w    $02CE
                dc.w    $02CF
                dc.w    $02D0
                dc.w    $02D1
                dc.w    $02D2
                dc.w    $02D3

WallPaperTiles2:                                 ; $1A374

                dc.w    $0205
                dc.w    $0205
                dc.w    $02D4
                dc.w    $02D5
                dc.w    $02D6
                dc.w    $02D7
                dc.w    $02D8
                dc.w    $02D9
                dc.w    $02DA
                dc.w    $02DB
                dc.w    $02DC
                dc.w    $02DD
                dc.w    $02DE
                dc.w    $0205
                dc.w    $0205
WallpaperScenery2:
                dc.w    $02DF
                dc.w    $02E0
                dc.w    $02E1
                dc.w    $0205
                dc.w    $02E2
                dc.w    $02E3
                dc.w    $02E4
                dc.w    $0205
                dc.w    $02E5
                dc.w    $02E6
                dc.w    $02E7
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205
WallpaperScenery3:
                dc.w    $02E8
                dc.w    $02E9
                dc.w    $02EA
                dc.w    $0205
                dc.w    $02EB
                dc.w    $02EC
                dc.w    $02ED
                dc.w    $0205
                dc.w    $02EE
                dc.w    $02EF
                dc.w    $02F0
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205

WallPaperTiles3:
                dc.w    $02F1
                dc.w    $02F2
                dc.w    $02F3
                dc.w    $02F4
                dc.w    $02F5
                dc.w    $02F6
                dc.w    $02F7
                dc.w    $02F8
                dc.w    $02F9
                dc.w    $02FA
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205
                dc.w    $0205

WallPaperScenery4
                dc.w    $02FB
                dc.w    $02FC
                dc.w    $02FD
                dc.w    $02FE
                dc.w    $02FF
                dc.w    $0300
                dc.w    $0301
                dc.w    $0302
                dc.w    $0303
                dc.w    $0304
                dc.w    $0305
                dc.w    $0306
                dc.w    $0307
                dc.w    $0308
                dc.w    $0309
                dc.w    $030A
WallPaperTiles4:
                dc.w    $030B
                dc.w    $030C
                dc.w    $030D
                dc.w    $030E
                dc.w    $030F
                dc.w    $0310
                dc.w    $0311
                dc.w    $0312
                dc.w    $0313
                dc.w    $0314
                dc.w    $0315
                dc.w    $0316
                dc.w    $0317
                dc.w    $0318
                dc.w    $0319
WallPaperScenery5:
                dc.w    $031A
                dc.w    $031B
                dc.w    $031C
                dc.w    $031D
                dc.w    $031E
                dc.w    $031F
                dc.w    $0320
                dc.w    $0321
                dc.w    $0322
                dc.w    $0323
                dc.w    $0324
                dc.w    $0325
                dc.w    $0326
                dc.w    $0327
                dc.w    $0328
                dc.w    $0329

WallpaperTiles5:
                dc.w    $032A
                dc.w    $032A
                dc.w    $032A
                dc.w    $0000
                dc.w    $0000
                dc.w    $0000
                dc.w    $032A
                dc.w    $032A
                dc.w    $032A
                dc.w    $032A
                dc.w    $032A
                dc.w    $032A
                dc.w    $032A
                dc.w    $032A
                dc.w    $0000

; ======================================================================

loc_1A46C:
                dc.w    $632B
                dc.w    $632C
                dc.w    $632D
                dc.w    $632E
                dc.w    $632F
                dc.w    $6330
                dc.w    $6331
                dc.w    $6332
                dc.w    $6333

loc_1a47e:

                dc.w    $6334
                dc.w    $6335
                dc.w    $6336
                dc.w    $6337
                dc.w    $6335
                dc.w    $6338
                dc.w    $6339
                dc.w    $6335
                dc.w    $633A

loc_1a490:

                dc.w    $633B
                dc.w    $6205
                dc.w    $633C
                dc.w    $633D
                dc.w    $6205
                dc.w    $633E
                dc.w    $633F
                dc.w    $6205
                dc.w    $6340

loc_1a4a2:
                dc.w    $6341
                dc.w    $6205
                dc.w    $6342
                dc.w    $6343
                dc.w    $6205
                dc.w    $6344
                dc.w    $6345
                dc.w    $6205
                dc.w    $6346

; ======================================================================

OpenDoorMaps:                                    ; $1A4B4
                dc.w    $0347, $0348, $0349
                dc.w    $034A, $034B, $034C
                dc.w    $034D, $034E, $034F

; ----------------------------------------------------------------------
; Unknown mappings. loc_1A4C6
                dc.w    $0351, $4350

; ======================================================================

Map_1Player:                                     ; '1P' mappings on the screen. $1A4CA
                dc.w    $8352                    ; '1'
                dc.w    $8353                    ; 'P'

Map_2Player:
                                                 ; Unused/Leftover '2P' mappings. $1A4CE
                dc.w    $8354                    ; '2'
                dc.w    $8353                    ; 'P'

Map_TopIcon:                                     ; 'TOP' mappings on the screen. $1A4
                dc.w    $8355                    ; 'T'
                dc.w    $8356                    ; 'O'
                dc.w    $8353                    ; 'P'

; Unknown

loc_1a4d8

                dc.l    $00000000
                dc.l    $002A00F8
                dc.l    $00000000
                dc.l    $030000F8

; ======================================================================

loc_1a4e8:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $6456
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a4f0:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $7456
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a4f8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6458
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a500:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C58
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a508:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7458
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a510:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C58
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a518:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $645A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------
loc_1A520:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $745A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a528:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $645C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a530:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C5C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a538:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $745C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a540:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C5C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a548:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $645E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a550:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $745E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a558:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6460
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a560:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C60
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a568:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7460
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a570:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C60
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a578:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $6462
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a580:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $7462
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a588:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6464
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a590:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C64
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a598:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7464
                dc.b    $FC, $FC

; ----------------------------------------------------------------------


loc_1a5a0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C64
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a5a8:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $6466
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a5b0:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $7466
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a5b8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6468
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a5c0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C68
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a5c8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7468
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a5d0
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C68
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a5d8:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $646A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a5e0:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $746A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a5e8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $646C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a5f0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C6C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a5f8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $746C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a600:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C6C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a608:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $646E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a610:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $746E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a618:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6470
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a620:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C70
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a628:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7470
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a630:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C70
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a638:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $6472
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a640:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $7472
                dc.b    $F8, $F8

; ----------------------------------------------------------------------
loc_1A648:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6474
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a650:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C74
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a658:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7474
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a660:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C74
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a668:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $6476
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a670:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $7476
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a678:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6478
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a680:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C78
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a688:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7478
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a690:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C78
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a698:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $647A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------
loc_1A6A0:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $747A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a6a8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $647C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6b0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C7C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6b8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $747C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6c0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C7C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6c8:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $647E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a6d0:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $747E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a6d8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6480
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6e0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C80
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6e8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7480
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6f0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C80
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a6f8:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $6482
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a700:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $7482
                dc.b    $F8, $F8

; ----------------------------------------------------------------------
loc_1A708:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6484
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a710:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C84
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a718:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7484
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a720:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C84
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a728:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $6486
                dc.b    $F8, $F8

; ----------------------------------------------------------------------
loc_1A730:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $7486
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a738:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6488
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a740:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C88
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a748:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7488
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a750:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C88
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a758:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $648A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a760:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $748A
                dc.b    $F8, $F8

; ----------------------------------------------------------------------
loc_1A768:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $648C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a770:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C8C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a778:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $748C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a780:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C8C
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a788:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $648E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------
loc_1A790:
                dc.b    $00, $04
                dc.b    $F8, $04
                dc.w    $748E
                dc.b    $F8, $F8

; ----------------------------------------------------------------------

loc_1a798:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6490
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a7a0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $6C90
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a7a8:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7490
                dc.b    $FC, $FC

; ----------------------------------------------------------------------

loc_1a7b0:
                dc.b    $00, $04
                dc.b    $F4, $01
                dc.w    $7C90
                dc.b    $FC, $FC

; ======================================================================

loc_1a7b8:

                dc.b    $00, $03
                dc.b    $F0, $05
                dc.w    $4436
                dc.b    $F8, $F8


loc_1a7c0:
                dc.b    $00, $03
                dc.b    $F0, $05
                dc.w    $443A
                dc.b    $F8, $F8

loc_1a7c8:
                dc.b    $00, $03
                dc.b    $F0, $05
                dc.w    $4C36
                dc.b    $F8, $F8


loc_1a7d0:
                dc.b    $00, $03
                dc.b    $F0, $05
                dc.w    $4C3A
                dc.b    $F8, $F8

; ======================================================================

loc_1a7d8:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $443E                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a7e0:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4442                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.


; ----------------------------------------------------------------------

loc_1a7e8:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4446                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a7f0:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $444A                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a7f8:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $444E                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a800:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $4452                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a808:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $4454                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a810:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $4C52                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a818:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $03

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4492                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a820:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $03

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4496                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a828:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $03

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4C92                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a830:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $03

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4C96                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a838:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $449A                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a840:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $449E                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a848:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44A2                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a850:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44A6                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a858:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44AA                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a860:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $44AE                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

loc_1a868:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $44B0                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

loc_1A870:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $4CAE                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------
loc_1A878:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4400                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a880:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4404                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.
                
; ----------------------------------------------------------------------

loc_1a888:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4408                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a890:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $440C                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ======================================================================

loc_1a898:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $00                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $4410                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ======================================================================

loc_1a8a0:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $01                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4416                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ======================================================================

loc_1a8a8:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $00                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $441A                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a8b0:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $00                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $4420                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ===========================================================================

loc_1A8B8:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $01                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4426                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ===========================================================================

loc_1A8C0:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $01                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $442A                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ===========================================================================

loc_1a8c8:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $02                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $442E                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ===========================================================================
loc_1a8d0:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $02                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $4432                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ===========================================================================

loc_1a8d8:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $07                      ; TODO MAPS

                dc.b    $F8                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $04B2                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

loc_1A8E0:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $07                      ; TODO MAPS

                dc.b    $F8                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $04B3                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

loc_1A8E8:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $07                      ; TODO MAPS

                dc.b    $F8                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $04B4                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

loc_1A8F0:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $07                      ; TODO MAPS

                dc.b    $F8                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $0686                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------
loc_1A8F8:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $08                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44B5                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a900:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $08                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44B9                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1A908
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $08                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44BD                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

loc_1a910:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $08                      ; TODO MAPS

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44C1                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1a918:
                dc.b    $01                      ; Number of sprites to load, -1.
                dc.b    $05                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $02                      ; Set sprite size.
                dc.w    $44C5                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $44C8                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $04                      ; Flipped relative X axis positioning.

loc_1a926:

                dc.b    $02                      ; Number of sprites to load, -1.
                dc.b    $05                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $02                      ; Set sprite size.
                dc.w    $44CA                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $44CD                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $04                      ; Flipped relative X axis positioning.


                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $44CF                    ; Art tile.
                dc.b    $04                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

loc_1a93a:
                dc.b    $02                      ; Number of sprites to load, -1.
                dc.b    $05                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $02                      ; Set sprite size.
                dc.w    $44D0                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $44D3                    ; Art tile.
                dc.b    $04                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

                dc.b    $F8                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $44D4                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $04                      ; Flipped relative X axis positioning.


loc_1a94e:

                dc.b    $01                      ; Number of sprites to load, -1.
                dc.b    $05                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $44D5                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

                dc.b    $F8                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $44DB                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $04                      ; Flipped relative X axis positioning.


loc_1A95C:
                dc.b    $02                      ; Number of sprites to load, -1.
                dc.b    $05                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $02                      ; Set sprite size.
                dc.w    $44DC                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $44DF                    ; Art tile.
                dc.b    $04                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

                dc.b    $F8                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $44E1                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $04                      ; Flipped relative X axis positioning.

loc_1a970:
                dc.b    $01                      ; Number of sprites to load, -1.
                dc.b    $12                      ; TODO MAPS

                dc.b    $EB                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $44E2                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

                dc.b    $FB                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $44E8                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $04                      ; Flipped relative X axis positioning.


loc_1a97e:
                dc.b    $02                      ; Number of sprites to load, -1.
                dc.b    $12                      ; TODO MAPS

                dc.b    $EB                      ; Relative Y-axis positioning.
                dc.b    $05                      ; Set sprite size.
                dc.w    $44E9                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

                dc.b    $F3                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $44ED                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $04                      ; Flipped relative X axis positioning.

                dc.b    $FB                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.w    $44EF                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

; ======================================================================

loc_1a992:

                dc.b    $00
                dc.b    $FF

                dc.b    $E8
                dc.b    $06
                dc.w    $44F0
                dc.b    $F8
                dc.b    $F8

loc_1a99a:

                dc.b    $02
                dc.b    $FF

                dc.b    $EE
                dc.b    $05
                dc.w    $44F6
                dc.b    $FA
                dc.b    $F6

                dc.b    $F6
                dc.b    $00
                dc.w    $44FA
                dc.b    $F2
                dc.b    $06

                dc.b    $FE
                dc.b    $00
                dc.w    $44FB
                dc.b    $FA
                dc.b    $FE

loc_1a9ae:

                dc.b    $00
                dc.b    $FF

                dc.b    $F4
                dc.b    $09
                dc.w    $44FC
                dc.b    $F4
                dc.b    $F4

loc_1a9b6:

                dc.b    $02
                dc.b    $FF

                dc.b    $E8
                dc.b    $02
                dc.w    $4502
                dc.b    $FA
                dc.b    $FE

                dc.b    $F0
                dc.b    $00
                dc.w    $54FA
                dc.b    $F2
                dc.b    $06

                dc.b    $F0
                dc.b    $01
                dc.w    $54F8
                dc.b    $02
                dc.b    $F6

loc_1a9ca:

                dc.b    $00
                dc.b    $FF

                dc.b    $EB
                dc.b    $06
                dc.w    $54F0
                dc.b    $F8
                dc.b    $F8

loc_1a9d2:

                dc.b    $02
                dc.b    $FF

                dc.b    $E8
                dc.b    $02
                dc.w    $4D02
                dc.b    $FE
                dc.b    $FA

                dc.b    $F0
                dc.b    $01
                dc.w    $5CF8
                dc.b    $F6
                dc.b    $02

                dc.b    $F0
                dc.b    $00
                dc.w    $5CFA
                dc.b    $06
                dc.b    $F2


loc_1a9e6:

                dc.b    $00
                dc.b    $FF

                dc.b    $F4
                dc.b    $09
                dc.w    $4CFC
                dc.b    $F4
                dc.b    $F4

loc_1a9ee:

                dc.b    $02
                dc.b    $FF

                dc.b    $EE
                dc.b    $05
                dc.w    $4CF6
                dc.b    $F6
                dc.b    $FA

                dc.b    $F6
                dc.b    $00
                dc.w    $4CFA
                dc.b    $06
                dc.b    $F2

                dc.b    $FE
                dc.b    $00
                dc.w    $4CFB
                dc.b    $FE
                dc.b    $FA

; ======================================================================

loc_1AA02:
                dc.b    $00
                dc.b    $05

                dc.b    $E8
                dc.b    $06
                dc.w    $4505
                dc.b    $F8
                dc.b    $F8

loc_1aa0a:
                dc.b    $00
                dc.b    $05

                dc.b    $E8
                dc.b    $06
                dc.w    $44F0
                dc.b    $F8
                dc.b    $F8

loc_1aa12:
                dc.b    $00
                dc.b    $05

                dc.b    $E8
                dc.b    $06
                dc.w    $4D05
                dc.b    $F8
                dc.b    $F8

; ======================================================================

loc_1aa1a:
                dc.b    $02
                dc.b    $05

                dc.b    $DC
                dc.b    $02
                dc.w    $44CA
                dc.b    $FC
                dc.b    $FC

                dc.b    $E4
                dc.b    $01
                dc.w    $44CD
                dc.b    $F4
                dc.b    $04

                dc.b    $E4
                dc.b    $00
                dc.w    $44CF
                dc.b    $04
                dc.b    $F4

loc_1aa2e:

                dc.b    $02
                dc.b    $05

                dc.b    $DE
                dc.b    $02
                dc.w    $44CA
                dc.b    $FC
                dc.b    $FC

                dc.b    $E6
                dc.b    $01
                dc.w    $44CD
                dc.b    $F4
                dc.b    $04

                dc.b    $E6
                dc.b    $00
                dc.w    $44CF
                dc.b    $04
                dc.b    $F4

loc_1aa42:

                dc.b    $02
                dc.b    $05

                dc.b    $E4
                dc.b    $02
                dc.w    $44CA
                dc.b    $FC
                dc.b    $FC

                dc.b    $EC
                dc.b    $01
                dc.w    $44CD
                dc.b    $F4
                dc.b    $04

                dc.b    $EC
                dc.b    $00
                dc.w    $44CF
                dc.b    $04
                dc.b    $F4

loc_1aa56:

                dc.b    $02
                dc.b    $05

                dc.b    $E8
                dc.b    $02
                dc.w    $44D0
                dc.b    $FC
                dc.b    $FC

                dc.b    $F0
                dc.b    $00
                dc.w    $44D3
                dc.b    $04
                dc.b    $F4

                dc.b    $F8
                dc.b    $00
                dc.w    $44D4
                dc.b    $F4
                dc.b    $04


loc_1aa6a:

                dc.b    $02
                dc.b    $05

                dc.b    $EA
                dc.b    $02
                dc.w    $44D0
                dc.b    $FC
                dc.b    $FC

                dc.b    $F2
                dc.b    $00
                dc.w    $44D3
                dc.b    $04
                dc.b    $F4

                dc.b    $FA
                dc.b    $00
                dc.w    $44D4
                dc.b    $F4
                dc.b    $04

; ======================================================================

loc_1aa7e:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $00
                dc.w    $450B
                dc.b    $FC
                dc.b    $FC

loc_1aa86:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $00
                dc.w    $450C
                dc.b    $FC
                dc.b    $FC

loc_1aa8e:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $00
                dc.w    $450D
                dc.b    $FC
                dc.b    $FC
; ======================================================================

loc_1aa96:
                dc.b    $01
                dc.b    $10
                dc.b    $F0
                dc.b    $08
                dc.w    $650E
                dc.b    $F0
                dc.b    $F8

                dc.b    $F8
                dc.b    $08
                dc.w    $6511
                dc.b    $F8
                dc.b    $F0

loc_1aaa4:

                dc.b    $01
                dc.b    $10
                dc.b    $F0
                dc.b    $08
                dc.w    $6514
                dc.b    $F0
                dc.b    $F8

                dc.b    $F8
                dc.b    $08
                dc.w    $6517
                dc.b    $F8
                dc.b    $F0

loc_1aab2:

                dc.b    $00
                dc.b    $10
                dc.b    $F0
                dc.b    $0D
                dc.w    $651A
                dc.b    $F0
                dc.b    $F0

loc_1aaba:

                dc.b    $01
                dc.b    $10
                dc.b    $F0
                dc.b    $08
                dc.w    $6D14
                dc.b    $F8
                dc.b    $F0

                dc.b    $F8
                dc.b    $08
                dc.w    $6D17
                dc.b    $F0
                dc.b    $F8

loc_1aac8:

                dc.b    $01
                dc.b    $10
                dc.b    $F0
                dc.b    $08
                dc.w    $6D0E
                dc.b    $F8
                dc.b    $F0

                dc.b    $F8
                dc.b    $08
                dc.w    $6D11
                dc.b    $F0
                dc.b    $F8

; ======================================================================

loc_1aad6:
                dc.b    $01
                dc.b    $11
                dc.b    $F0
                dc.b    $04
                dc.w    $0522
                dc.b    $F8
                dc.b    $F8

                dc.b    $F8
                dc.b    $00
                dc.w    $0524
                dc.b    $F8
                dc.b    $00

; ======================================================================

loc_1aae4:
                dc.b    $00
                dc.b    $11

                dc.b    $F0
                dc.b    $05
                dc.w    $0525
                dc.b    $F8
                dc.b    $F8

; ======================================================================

loc_1aaec:
                dc.b    $00
                dc.b    $00

                dc.b    $F3
                dc.b    $00
                dc.w    $0529
                dc.b    $FD
                dc.b    $FB

loc_1aaf4:
                dc.b    $00
                dc.b    $00

                dc.b    $F3
                dc.b    $00
                dc.w    $052A
                dc.b    $FD
                dc.b    $FB

loc_1aafc:
                dc.b    $00
                dc.b    $00

                dc.b    $F3
                dc.b    $00
                dc.w    $052B
                dc.b    $FD
                dc.b    $FB

loc_1ab04:
                dc.b    $00
                dc.b    $00

                dc.b    $F3
                dc.b    $00
                dc.w    $052B
                dc.b    $FD
                dc.b    $FB

loc_1ab0c:
                dc.b    $00
                dc.b    $00

                dc.b    $F3
                dc.b    $00
                dc.w    $052C
                dc.b    $FD
                dc.b    $FB

loc_1ab14:
                dc.b    $00
                dc.b    $00

                dc.b    $F3
                dc.b    $00
                dc.w    $052D
                dc.b    $FD
                dc.b    $FB

loc_1ab1c:
                dc.b    $00
                dc.b    $00

                dc.b    $F3
                dc.b    $00
                dc.w    $052E
                dc.b    $FD
                dc.b    $FB

; ======================================================================

loc_1ab24:

                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $0640
                dc.b    $F4
                dc.b    $F4

loc_1ab2c:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $0643
                dc.b    $F4
                dc.b    $F4



loc_1ab34:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $0646
                dc.b    $F4
                dc.b    $F4

loc_1ab3c:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $0649
                dc.b    $F4
                dc.b    $F4


loc_1ab44:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $064C
                dc.b    $F4
                dc.b    $F4


loc_1ab4c:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $064F
                dc.b    $F4
                dc.b    $F4

loc_1ab54:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $0652
                dc.b    $F2
                dc.b    $F6

loc_1ab5c:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $0655
                dc.b    $F2
                dc.b    $F6

loc_1ab64:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $0658
                dc.b    $F2
                dc.b    $F6

loc_1ab6c:
                dc.b    $00
                dc.b    $FF

                dc.b    $F8
                dc.b    $08
                dc.w    $065B
                dc.b    $F2
                dc.b    $F6

; ======================================================================

loc_1ab74:

                dc.b    $00
                dc.b    $09

                dc.b    $F0
                dc.b    $01
                dc.w    $465E
                dc.b    $FC
                dc.b    $FC

; ======================================================================

loc_1ab7c:

                dc.b    $00
                dc.b    $0A

                dc.b    $F8
                dc.b    $04
                dc.w    $4660
                dc.b    $F8
                dc.b    $F8

loc_1ab84:

                dc.b    $00
                dc.b    $0A

                dc.b    $F8
                dc.b    $04
                dc.w    $4662
                dc.b    $F8
                dc.b    $F8

loc_1ab8c:
                dc.b    $00
                dc.b    $0A

                dc.b    $F8
                dc.b    $04
                dc.w    $4664
                dc.b    $F8
                dc.b    $F8

; ----------------------------------------------------------------------

loc_1ab94:
                dc.b    $00
                dc.b    $0B

                dc.b    $00
                dc.b    $04
                dc.w    $4666
                dc.b    $F8
                dc.b    $F8

loc_1ab9c:
                dc.b    $00
                dc.b    $0B

                dc.b    $00
                dc.b    $04
                dc.w    $4668
                dc.b    $F8
                dc.b    $F8

loc_1aba4:
                dc.b    $00
                dc.b    $0B

                dc.b    $00
                dc.b    $04
                dc.w    $466A
                dc.b    $F8
                dc.b    $F8

; ----------------------------------------------------------------------

loc_1abac:

                dc.b    $00
                dc.b    $0C

                dc.b    $F8
                dc.b    $01
                dc.w    $466C
                dc.b    $F8
                dc.b    $00

loc_1abb4:

                dc.b    $00
                dc.b    $0C

                dc.b    $F8
                dc.b    $01
                dc.w    $466E
                dc.b    $F8
                dc.b    $00

; ----------------------------------------------------------------------

loc_1abbc:
                dc.b    $00
                dc.b    $0D

                dc.b    $F8
                dc.b    $01
                dc.w    $566C
                dc.b    $F8
                dc.b    $00

; ----------------------------------------------------------------------

loc_1abc4:
                dc.b    $00
                dc.b    $0D

                dc.b    $F8
                dc.b    $01
                dc.w    $566E
                dc.b    $F8
                dc.b    $00

; ----------------------------------------------------------------------

loc_1abcc:
                dc.b    $01
                dc.b    $FF

                dc.b    $F0
                dc.b    $01
                dc.w    $4670
                dc.b    $F8
                dc.b    $00

                dc.b    $F8
                dc.b    $00
                dc.w    $4672
                dc.b    $F0
                dc.b    $08

; ----------------------------------------------------------------------

loc_1abda:
                dc.b    $01
                dc.b    $FF

                dc.b    $00
                dc.b    $04
                dc.w    $4673
                dc.b    $F0
                dc.b    $00

                dc.b    $08
                dc.b    $00
                dc.w    $4675
                dc.b    $F8
                dc.b    $00

; ----------------------------------------------------------------------

loc_1abe8:
                dc.b    $01
                dc.b    $FF

                dc.b    $00
                dc.b    $04
                dc.w    $4676
                dc.b    $00
                dc.b    $F0

                dc.b    $08
                dc.b    $00
                dc.w    $5E70
                dc.b    $00
                dc.b    $F8

; ----------------------------------------------------------------------

loc_1abf6:
                dc.b    $01
                dc.b    $FF

                dc.b    $F0
                dc.b    $01
                dc.w    $4678
                dc.b    $00
                dc.b    $F8

                dc.b    $F8
                dc.b    $00
                dc.w    $5E73
                dc.b    $08
                dc.b    $F0

; ----------------------------------------------------------------------

loc_1ac04:
                dc.b    $01
                dc.b    $FF

                dc.b    $F8
                dc.b    $04
                dc.w    $467A
                dc.b    $F8
                dc.b    $F8

                dc.b    $00
                dc.b    $00
                dc.w    $467C
                dc.b    $00
                dc.b    $F8

; ----------------------------------------------------------------------

loc_1ac12:
                dc.b    $01
                dc.b    $FF

                dc.b    $F8
                dc.b    $01
                dc.w    $467D
                dc.b    $00
                dc.b    $F8

                dc.b    $00
                dc.b    $00
                dc.w    $467F
                dc.b    $F8
                dc.b    $00

; ----------------------------------------------------------------------

loc_1ac20:
                dc.b    $01
                dc.b    $FF

                dc.b    $F8
                dc.b    $01
                dc.w    $5E7B
                dc.b    $F8
                dc.b    $00

                dc.b    $00
                dc.b    $00
                dc.w    $5E7A
                dc.b    $00
                dc.b    $F8

; ----------------------------------------------------------------------

loc_1ac2e:
                dc.b    $01
                dc.b    $FF

                dc.b    $F8
                dc.b    $04
                dc.w    $4680
                dc.b    $F8
                dc.b    $F8

                dc.b    $00
                dc.b    $00
                dc.w    $5E7D
                dc.b    $F8
                dc.b    $00


loc_1ac3c:
                dc.b    $00
                dc.b    $0E

                dc.b    $F8
                dc.b    $01
                dc.w    $4682
                dc.b    $FC
                dc.b    $FC

; ----------------------------------------------------------------------

loc_1AC44:
                dc.b    $00
                dc.b    $0E

                dc.b    $F8
                dc.b    $01
                dc.w    $4E82
                dc.b    $FC
                dc.b    $FC

; ----------------------------------------------------------------------


loc_1ac4c:
                dc.b    $00
                dc.b    $09

                dc.b    $F0
                dc.b    $01
                dc.w    $4684
                dc.b    $FC
                dc.b    $FC

; ----------------------------------------------------------------------

loc_1ac54:
                dc.b    $00
                dc.b    $0E

                dc.b    $F8
                dc.b    $01
                dc.w    $5682
                dc.b    $FC
                dc.b    $FC

; ----------------------------------------------------------------------

loc_1ac5c:
                dc.b    $00
                dc.b    $0E

                dc.b    $F8
                dc.b    $01
                dc.w    $5E82
                dc.b    $FC
                dc.b    $FC

; ----------------------------------------------------------------------

loc_1ac64:
                dc.b    $00
                dc.b    $0F

                dc.b    $00
                dc.b    $01
                dc.w    $5684
                dc.b    $FC
                dc.b    $FC

; ----------------------------------------------------------------------

loc_1ac6c:
                dc.b    $01
                dc.b    $FF

                dc.b    $F6
                dc.b    $04
                dc.w    $467A
                dc.b    $F6
                dc.b    $FA

                dc.b    $FE
                dc.b    $00
                dc.w    $467C
                dc.b    $FE
                dc.b    $FA

; ----------------------------------------------------------------------

loc_1ac7a:
                dc.b    $01
                dc.b    $FF

                dc.b    $F0
                dc.b    $01
                dc.w    $467D
                dc.b    $FC
                dc.b    $FC

                dc.b    $F8
                dc.b    $00
                dc.w    $467F
                dc.b    $F4
                dc.b    $04

; ----------------------------------------------------------------------

loc_1ac88:
                dc.b    $01
                dc.b    $FF

                dc.b    $F0
                dc.b    $01
                dc.w    $5E7B
                dc.b    $FC
                dc.b    $FC

                dc.b    $F8
                dc.b    $00
                dc.w    $5E7A
                dc.b    $04
                dc.b    $F4

; ----------------------------------------------------------------------

loc_1ac96:
                dc.b    $01
                dc.b    $FF

                dc.b    $F3
                dc.b    $04
                dc.w    $4680
                dc.b    $FB
                dc.b    $F5

                dc.b    $FB
                dc.b    $00
                dc.w    $5E7D
                dc.b    $FB
                dc.b    $FD

; ======================================================================

loc_1aca4:
                dc.b    $08
                dc.b    $FF

                dc.b    $00
                dc.b    $00
                dc.w    $8047
                dc.b    $00
                dc.b    $F8

                dc.b    $00
                dc.b    $00
                dc.w    $8041
                dc.b    $08
                dc.b    $F0

                dc.b    $00
                dc.b    $00
                dc.w    $804D
                dc.b    $10
                dc.b    $E8

                dc.b    $00
                dc.b    $00
                dc.w    $8045
                dc.b    $18
                dc.b    $E0

                dc.b    $00
                dc.b    $00
                dc.w    $8020
                dc.b    $20
                dc.b    $D8

                dc.b    $00
                dc.b    $00
                dc.w    $804F
                dc.b    $28
                dc.b    $D0

                dc.b    $00
                dc.b    $00
                dc.w    $8056
                dc.b    $30
                dc.b    $C8

                dc.b    $00
                dc.b    $00
                dc.w    $8045
                dc.b    $38
                dc.b    $C0

                dc.b    $00
                dc.b    $00
                dc.w    $8052
                dc.b    $40
                dc.b    $B8

; ======================================================================

loc_1ACDC:
                dc.b    $0D
                dc.b    $FF

                dc.b    $00
                dc.b    $00
                dc.w    $8050
                dc.b    $C8
                dc.b    $30

                dc.b    $00
                dc.b    $00
                dc.w    $8055
                dc.b    $D0
                dc.b    $28

                dc.b    $00
                dc.b    $00
                dc.w    $8053
                dc.b    $D8
                dc.b    $20

                dc.b    $00
                dc.b    $00
                dc.w    $8048
                dc.b    $E0
                dc.b    $18

                dc.b    $00
                dc.b    $04
                dc.w    $8053
                dc.b    $F0
                dc.b    $00

                dc.b    $00
                dc.b    $00
                dc.w    $8041
                dc.b    $00
                dc.b    $F8

                dc.b    $00
                dc.b    $00
                dc.w    $8052
                dc.b    $08
                dc.b    $F0

                dc.b    $00
                dc.b    $00
                dc.w    $8054
                dc.b    $10
                dc.b    $E8

                dc.b    $00
                dc.b    $00
                dc.w    $8042
                dc.b    $20
                dc.b    $D8

                dc.b    $00
                dc.b    $00
                dc.w    $8055
                dc.b    $28
                dc.b    $D0

                dc.b    $00
                dc.b    $00
                dc.w    $8054
                dc.b    $30
                dc.b    $C8

                dc.b    $00
                dc.b    $00
                dc.w    $8054
                dc.b    $38
                dc.b    $C0

                dc.b    $00
                dc.b    $00
                dc.w    $804F
                dc.b    $40
                dc.b    $B8

                dc.b    $00
                dc.b    $00
                dc.w    $804E
                dc.b    $48
                dc.b    $B0

; ======================================================================
; Pause object mappings
; ======================================================================
Map_Pause:                                       ; $1AD32
                dc.b    $04                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $00                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.b    $80,'P'                  ; Art tile.
                dc.b    $00                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

                dc.b    $00                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.b    $80,'A'                  ; Art tile.
                dc.b    $08                      ; Relative X axis positioning.
                dc.b    $F0                      ; Flipped relative X axis positioning.

                dc.b    $00                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.b    $80,'U'                  ; Art tile.
                dc.b    $10                      ; Relative X axis positioning.
                dc.b    $E8                      ; Flipped relative X axis positioning.

                dc.b    $00                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.b    $80,'S'                  ; Art tile.
                dc.b    $18                      ; Relative X axis positioning.
                dc.b    $E0                      ; Flipped relative X axis positioning.

                dc.b    $00                      ; Relative Y-axis positioning.
                dc.b    $00                      ; Set sprite size.
                dc.b    $80,'E'                  ; Art tile.
                dc.b    $20                      ; Relative X axis positioning.
                dc.b    $D8                      ; Flipped relative X axis positioning.

; ======================================================================
; 'FLICKY' F mappings.

FlickyFMaps:                                     ; $1AD52
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E0                      ; Relative Y-axis positioning.
                dc.b    $0B                      ; Set sprite size.
                dc.w    $6740                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

FlickyLMaps:                                     ; $1AD5A
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $0A                      ; Set sprite size.
                dc.w    $674C                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

FlickyIMaps:                                     ; $1AD62
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $6755                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.


FlickyCMaps:                                     ; $1AD6A
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $0A                      ; Set sprite size.
                dc.w    $675B                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

FlickyKMaps:                                     ; $1AD72
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $0A                      ; Set sprite size.
                dc.w    $6764                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

FlickyYMaps:                                     ; $1AD7A
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E0                      ; Relative Y-axis positioning.
                dc.b    $0B                      ; Set sprite size.
                dc.w    $676D                    ; Art tile.
                dc.b    $F4                      ; Relative X axis positioning.
                dc.b    $F4                      ; Flipped relative X axis positioning.

; ======================================================================

loc_1ad82:

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $4687                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1ad8a:
                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $FF                      ; TODO MAPS

                dc.b    $E8                      ; Relative Y-axis positioning.
                dc.b    $06                      ; Set sprite size.
                dc.w    $468D                    ; Art tile.
                dc.b    $F8                      ; Relative X axis positioning.
                dc.b    $F8                      ; Flipped relative X axis positioning.

; ======================================================================
LevelLayouts:                                    ; $1AD92
                dc.w    loc_1ADF2&$FFFF          ; Round 1.
                dc.w    loc_1AE40&$FFFF          ; Round 2.
                dc.w    loc_1AE40&$FFFF          ; Bonus stage filler.
                dc.w    loc_1AE7C&$FFFF          ; Round 4.
                dc.w    loc_1AEDC&$FFFF          ; Round 5.
                dc.w    loc_1AF20&$FFFF          ; Round 6.
                dc.w    loc_1AF20&$FFFF          ; Bonus stage filler.
                dc.w    loc_1AF6C&$FFFF          ; Round 8.
                dc.w    loc_1AFBE&$FFFF          ; Round 9.
                dc.w    loc_1B012&$FFFF          ; Round 10.
                dc.w    loc_1B012&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B070&$FFFF          ; Round 12.
                dc.w    loc_1B0B0&$FFFF          ; Round 13.
                dc.w    loc_1B108&$FFFF          ; Round 14.
                dc.w    loc_1B108&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B152&$FFFF          ; Round 16.
                dc.w    loc_1B1A0&$FFFF          ; Round 17.
                dc.w    loc_1B1F8&$FFFF          ; Round 18.
                dc.w    loc_1B1F8&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B242&$FFFF          ; Round 20.
                dc.w    loc_1B2A4&$FFFF          ; Round 21.
                dc.w    loc_1B2E8&$FFFF          ; Round 22.
                dc.w    loc_1B2E8&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B346&$FFFF          ; Round 24.
                dc.w    loc_1B3A2&$FFFF          ; Round 25.
                dc.w    loc_1B3EE&$FFFF          ; Round 26.
                dc.w    loc_1B3EE&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B43C&$FFFF          ; Round 28.
                dc.w    loc_1B486&$FFFF          ; Round 29.
                dc.w    loc_1B4C8&$FFFF          ; Round 30.
                dc.w    loc_1B4C8&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B522&$FFFF          ; Round 32.
                dc.w    loc_1B56C&$FFFF          ; Round 33.
                dc.w    loc_1B5AE&$FFFF          ; Round 34.
                dc.w    loc_1B5AE&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B602&$FFFF          ; Round 36.
                dc.w    loc_1B66C&$FFFF          ; Round 37.
                dc.w    loc_1B6C0&$FFFF          ; Round 38.
                dc.w    loc_1B6C0&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B700&$FFFF          ; Round 40.
                dc.w    loc_1B74E&$FFFF          ; Round 41.
                dc.w    loc_1B7B4&$FFFF          ; Round 42.
                dc.w    loc_1B7B4&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B81C&$FFFF          ; Round 44.
                dc.w    loc_1B85E&$FFFF          ; Round 45.
                dc.w    loc_1B8C8&$FFFF          ; Round 46.
                dc.w    loc_1B8C8&$FFFF          ; Bonus stage filler.
                dc.w    loc_1B91C&$FFFF          ; Round 48.

; ----------------------------------------------------------------------
loc_1ADF2:
                incbin  "Misc\Level Layouts\Round1.bin"

loc_1ae40:
                incbin  "Misc\Level Layouts\Round2.bin"

loc_1ae7c:
                incbin  "Misc\Level Layouts\Round4.bin"

loc_1aedc:
                incbin  "Misc\Level Layouts\Round5.bin"

loc_1af20:
                incbin  "Misc\Level Layouts\Round6.bin"

loc_1af6c:
                incbin  "Misc\Level Layouts\Round8.bin"

loc_1afbe:
                incbin  "Misc\Level Layouts\Round9.bin"

loc_1B012:
                incbin  "Misc\Level Layouts\Round10.bin"

loc_1B070:
                incbin  "Misc\Level Layouts\Round12.bin"

loc_1B0b0:
                incbin  "Misc\Level Layouts\Round13.bin"

loc_1B108:
                incbin  "Misc\Level Layouts\Round14.bin"

loc_1B152:
                incbin  "Misc\Level Layouts\Round16.bin"

loc_1B1a0:
                incbin  "Misc\Level Layouts\Round17.bin"

loc_1B1f8:
                incbin  "Misc\Level Layouts\Round18.bin"

loc_1B242:
                incbin  "Misc\Level Layouts\Round20.bin"

loc_1B2a4:
                incbin  "Misc\Level Layouts\Round21.bin"

loc_1B2e8:
                incbin  "Misc\Level Layouts\Round22.bin"

loc_1B346:
                incbin  "Misc\Level Layouts\Round24.bin"

loc_1B3a2:
                incbin  "Misc\Level Layouts\Round25.bin"

loc_1B3ee:
                incbin  "Misc\Level Layouts\Round26.bin"

loc_1B43C:
                incbin  "Misc\Level Layouts\Round28.bin"

loc_1B486:
                incbin  "Misc\Level Layouts\Round29.bin"

loc_1B4C8:
                incbin  "Misc\Level Layouts\Round30.bin"

loc_1B522:
                incbin  "Misc\Level Layouts\Round32.bin"

loc_1B56c:
                incbin  "Misc\Level Layouts\Round33.bin"

loc_1B5ae:
                incbin  "Misc\Level Layouts\Round34.bin"

loc_1B602:
                incbin  "Misc\Level Layouts\Round36.bin"

loc_1B66c:
                incbin  "Misc\Level Layouts\Round37.bin"

loc_1B6c0:
                incbin  "Misc\Level Layouts\Round38.bin"

loc_1B700:
                incbin  "Misc\Level Layouts\Round40.bin"

loc_1B74E:
                incbin  "Misc\Level Layouts\Round41.bin"

loc_1B7B4:
                incbin  "Misc\Level Layouts\Round42.bin"

loc_1B81C:
                incbin  "Misc\Level Layouts\Round44.bin"

loc_1B85E:
                incbin  "Misc\Level Layouts\Round45.bin"

loc_1B8C8:
                incbin  "Misc\Level Layouts\Round46.bin"

loc_1B91C:
                incbin  "Misc\Level Layouts\Round48.bin"

; ======================================================================

Padding2:       
                alignFF $1C000

EndofRAMBlock:
                alignFF $20000                   ; Pad to 128KB.

EndofROM


                END








