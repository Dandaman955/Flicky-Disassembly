; ======================================================================
; Flicky Disassembly, by Dandaman955 (05/10/2015, 19:48.00 - ?)
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
;
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
                dc.b    'SEGA MEGA DRIVE '      ; NOTE - A requirement of the TMSS is that the string 'SEGA' or ' SEGA' exists at the start here. This is important!
                dc.b    '(C)SEGA 1991.FEB'
                dc.b    'FLICKY                                          '
                dc.b    '                FLICKY                          '
                dc.b    'GM 00001022-00'
Checksum:       dc.w    $B7E0
                dc.b    'J               '
                dc.l    StartofROM
ROMEndLoc       dc.l    EndofROM-1
                dc.l    $FF0000
                dc.l    $FFFFFF
                dc.b    '                                                                '       ; TODO MODEM
                dc.b    'JUE             '
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
                bne.s   PortA_Ok                 ; If it's 'ok', branch.
                tst.w   ($A1000C).l              ; Test Port C control.
PortA_Ok:
                bne.s   PortC_Ok                 ; If it's 'ok', branch.
                lea     SetupValues(pc),a5       ; Load starting address for the setup values into a5.
                movem.w (a5)+,d5-d7              ; d5 - $8000, d6 - $3FFF, d7 - $0100.
                movem.l (a5)+,a0-a4              ; a0 - $A00000, a1 - $A11100, a2 - $A11200, a3 - $C00000, a4 - $C00004
                move.b  -$10FF(a1),d0            ; Get version register.
                andi.b  #$F,d0                   ; Get hardware version.
                beq.s   SkipSecurity             ; If it's the pre-TMSS models, branch.
                move.l  #'SEGA',$2F00(a1)        ; Write SEGA to the appropriate space ($A14000); satisfy the TMSS.
SkipSecurity:
                move.w  (a4),d0                  ; Check to see if the VDP works.
                moveq   #0,d0                    ; Clear d0.
                movea.l d0,a6                    ; Set to write to the USP.
                move.l  a6,usp                   ; Set USP as 0.
                moveq   #$17,d1                  ; $18 VDP registers to initialise.
loc_23E:
                move.b  (a5)+,d5                 ; Get the first VDP register init value, add by $8000 (d5) to get VDP register.
                move.w  d5,(a4)                  ; Initialise the register.
                add.w   d7,d5                    ; Increment by $100 to load next value.
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
                move.b  (a5)+,$11(a3)            ; Set PSG volumes ($C00011).
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
                dc.b    $00, $00, $FF, $00          ; TODO - Maybe describe the individual regs, or include a link to the VDP wiki?
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

                dc.b    $9F, $BF, $DF, $FF       ; PSG volumes.

; ======================================================================

loc_300:
                tst.w   ($C00004).l              ; Test to see if the VDP works (?).
                move.w  #$2700,sr                ; Disable interrupts.
                move.b  ($A10001).l,d0           ; Move version register value into d0.
                andi.b  #$F,d0                   ; Get hardware version.
                beq.s   loc_320                  ; If it's a pre-TMSS model, branch.
                move.l  #'SEGA',($A14000).l      ; Satisfy the TMSS.
loc_320:
                movea.l #ROMEndLoc,a0            ; Get the header entry that denotes the ending address of this ROM.
                move.l  (a0),d1                  ; Move the ending address of this ROM to d1..
                addq.l  #1,d1                    ; Add 1 to process the extra 1 (dbf ends on 0).
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
                bsr.w   loc_43a
                cmpi.b  #0,d0                    ; Has the TODO bit been sent low?
                beq.s   loc_374                  ; If it has, branch.
                nop                              ; Give the port some time...
                nop                              ; ...
                nop                              ; ...
loc_374:
                moveq   #$40,d0                  ; Set as output.
                move.b  d0,($A10009).l           ; Init controller 1.
                move.b  d0,($A1000B).l           ; Init controller 2.
                move.b  d0,($A1000D).l           ; Init controller 3.
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
                bsr.w   loc_858                  ; Write address pointers into RAM.
                bsr.w   loc_e48                  ; Write VDP setup array into RAM.
                bsr.w   loc_e82                  ; Write stored VDP setup array values into the VDP.
                bsr.w   loc_402                  ; Clear CRAM and VRAM.
                bsr.w   loc_1014                 ; Load the sound driver to the Z80.
                lea     loc_10000,a0             ; Load start of code block.
                lea     ($FF0000).l,a1           ; Load start of RAM.
                move.w  #EndofROM-loc_10000/4-1,d0 ; Repeat for $C000 bytes (or however large the file size is, depending on whether it was edited or not).
loc_3D8:
                move.l  (a0)+,(a1)+              ; Write first 4 bytes of the code into RAM.
                dbf     d0,loc_3d8               ; Repeat until the whole code block has been written.
                jmp     ($FF0000).l              ; Run code from RAM.

; ======================================================================

loc_3e4:
                bsr.w   loc_402                  ; Clear CRAM and VRAM.
                move.l  #$C0000000,($C00004).l   ; Set VDP to CRAM write.
                moveq   #$3F,d7                  ; Set to fill entire CRAM.
loc_3F4:
                move.w  #$000E,($C00000).l       ; Write red to CRAM.
                dbf     d7,loc_3f4               ; Repeat until filled with red.
loc_400:
                bra.s   loc_400                  ; Loop endlessly.

loc_402:
                move.l  #$C0000000,($C00004).l   ; Set VDP to CRAM write.
                moveq   #$3F,d0                  ; Set to fill entire CRAM.
loc_40E:
                move.w  #0,($C00000).l           ; Clear first palette.
                dbf     d0,loc_40e               ; Repeat until fully cleared.
                move.l  #$40000000,($C00004).l   ; Set VDP to VRAM write, $0000.
                lea     ($C00000).l,a5           ; Move the VDP control port to a5.
                move.w  #0,d6                    ; Clear a6.
                move.w  #$53FF,d7                ; Set to clear $A800 bytes.
loc_432:
                move.w  d6,(a5)                  ; Clear two bytes of VRAM.
                dbf     d7,loc_432               ; Repeat until cleared.
                rts                              ; Return.

; ======================================================================

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
                beq.s   loc_458
                or.b    d1,d0
loc_458:
                lsr.b   #1,d1
                bne.s   loc_44a
                clr.b   6(a0)
                movem.l (sp)+,d1-d2/a1           ; Restore register values.
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_466:
                dc.b    $40, $0C
                dc.b    $40, $03
                dc.b    $00, $0C
                dc.b    $00, $03

; ======================================================================

SegaScreen:                                      ; $46E
                bsr.w   loc_872                  ; Clear and initialise some registers and addresses.
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

loc_858:                                         ; $858
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
                dbf     d6,loc_87c
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
                bsr.w   loc_e48                  ; Write VDP setup array into RAM.
                btst    #6,($A10001).l           ; Is this being played on a PAL console?
                beq.s   loc_8c0                  ; If not, branch.
                move.b  #$3C,($FFFFFF71).w       ; VDP register $01 storage - bits set: Enable VBlank, DMA and 240 line mode. Disable display.
loc_8C0:
                bsr.w   loc_e82                  ; Write VDP setup array register values, stored in RAM, into the VDP.
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
; Unused M68K to VRAM DMA routine.
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
                ori.w   #$C000,d0
                bra.s   loc_a66

loc_A0C:
                cmpi.w  #$400,d0
                bhi.s   loc_9e2
loc_a12:
                bsr.s   loc_a1a
                ori.w   #$4000,d0
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
                dbf     d1,loc_aae               ; Repeat for every $20 bytes needed to be written.
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
                lea     loc_b5a,a3
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
                adda.w  #$A,a3                   ; If it is, set the XOR decompression mode.
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
                asl.w   #3,d1                    ; Multiply by 8 (each pass decompresses a longword, and 8 longwords make a tile).
                subq.w  #1,d1                    ; Subtract 1 for the dbf loop.
                move.b  d0,d2                    ; Load the palette entries into d2.
                move.b  d2,d3                    ; Copy to d3.
                lsr.b   #4,d2                    ; Get upper nybble of the byte, in this case entry 1.
                andi.b  #$F,d3                   ; Get lower nybble of the byte, in this case entry 2.
loc_CE2:
                moveq   #7,d6                    ; Set bit counter value as 7.
                move.b  (a0)+,d0                 ; Move the first byte of the compressed art into d0.
loc_ce6:
                lsl.l   #4,d5                    ; Clear the first nybble.
                btst    d6,d0                    ; Is it set to a 0 or 1?
                beq.s   loc_cf0                  ; If it is set to a 0, branch.
                or.b    d2,d5                    ; Set the pixel as using palette entry 1.
                bra.s   loc_cf2                  ; Branch to check the rest of the bits.

loc_cf0:
                or.b    d3,d5                    ; Set the pixel as using palette entry 2.
loc_cf2:
                dbf     d6,loc_ce6               ; Repeat for the rest of the bits.
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
                bcc.s   loc_d3c
                moveq   #6,d0
                lsr.w   #1,d2
loc_d3c:
                bsr.w   loc_c2a
                andi.w  #$F,d2
                lsr.w   #4,d1
                add.w   d1,d1
                jmp     loc_d98(pc,d1.w)

; ======================================================================

loc_d4c:
                move.w  a2,(a1)+
                addq.w  #1,a2
                dbf     d2,loc_d4c
                bra.s   loc_d28

; ----------------------------------------------------------------------

loc_d56:
                move.w  a4,(a1)+
                dbf     d2,loc_d56
                bra.s   loc_d28

; ----------------------------------------------------------------------

loc_d5e:
                bsr.w   loc_c5a
loc_d62:
                move.w  d1,(a1)+
                dbf     d2,loc_d62
                bra.s   loc_d28
loc_D6A:
                bsr.w   loc_c5a
loc_D6E:
                move.w  d1,(a1)+
                addq.w  #1,d1
                dbf     d2,loc_d6e
                bra.s   loc_d28

; ----------------------------------------------------------------------

loc_d78:
                bsr.w   loc_c5a
loc_D7C:
                move.w  d1,(a1)+
                subq.w  #1,d1
                dbf     d2,loc_d7c
                bra.s   loc_d28

; ----------------------------------------------------------------------

loc_d86:
                cmpi.w  #$F,d2
                beq.s   loc_da8
loc_D8C:
                bsr.w   loc_c5a
                move.w  d1,(a1)+
                dbf     d2,loc_d8c
                bra.s   loc_d28

; ======================================================================

loc_d98:
                bra.s   loc_d4c
                bra.s   loc_d4c
                bra.s   loc_d56
                bra.s   loc_d56
                bra.s   loc_d5e
                bra.s   loc_d6a
                bra.s   loc_d78
                bra.s   loc_d86

; ======================================================================

loc_da8:
                subq.w  #1,a0
                cmpi.w  #$10,d6
                bne.s   loc_db2
                subq.w  #1,a0
loc_db2:
                move.w  a0,d0
                lsr.w   #1,d0
                bcc.s   loc_dba
                addq.w  #1,a0
loc_dba:
                movem.l (sp)+,d0-d7/a1-a5
                rts

; ======================================================================
; Updates the controller array.
; ======================================================================

loc_dc0:                                         ; TODO
                bsr.w   loc_dfa                  ; Update controller output.
                lea     ($FFFFFF83).w,a0         ; Load pressed button array into a0.
                move.w  ($FFFFFF8E).w,d0         ; Load the output into d0.
                moveq   #$E,d1                   ; Set to test for A's bit.
                moveq   #6,d2                    ; Set to test for the other buttons (except start).
loc_DD0:
                btst    d1,d0                    ; Check if the button is being pressed.
                sne     (a0)+                    ; Set respective array byte to $FF if it is.
                subq.b  #1,d1                    ; Subtract to check for the next button (Order follows A C B R L D U).
                dbf     d2,loc_dd0               ; Repeat for those buttons.
                moveq   #6,d1                    ; Set to bit test in the ACB range.
                moveq   #2,d2                    ; Set to repeat for only buttons A, B and C.
loc_DDE:
                btst    d1,d0                    ; Test for the appropriate button.
                sne     (a0)+                    ; Set to $FF if it's being pressed.
                subq.b  #1,d1                    ; Load next button.
                dbf     d2,loc_dde               ; Repeat until A, B and C have been checked.
                andi.b  #$70,d0                  ; Do a test for A, B or C.
                sne     (a0)+                    ; Set the value if either A, B or C are being pressed.
                tst.b   ($FFFFFF87).w            ; Is left being pressed?
                beq.s   loc_df8                  ; If it isn't, branch.
                clr.b   ($FFFFFF86).w            ; Clear the right button held value (it's checked before left, so there's no check needed for right as well).
loc_df8:
                rts                              ; Return.

; ======================================================================
                                                ; TODO - Annotate! Give this a label as well!
loc_dfa:                                        ; $DFA
                bsr.w   loc_1050                ; Check to see if the Z80's stopped, if not, stop it.
                lea     ($FFFFFF8E).w,a0        ; Load RAM address to write controller output values to.
                lea     ($A10003).l,a1          ; Load controller 1 port.
                bsr.s   loc_e12                 ; Read the first controller.
                addq.w  #2,a1                   ; Repeat for the second controller.
                bsr.s   loc_e12                 ; Read the second controller.
                bra.w   loc_107e                ; Check to see if the Z80's running, otherwise run it.

loc_e12:
                move.b  #0,(a1)
                nop
                nop
                move.b  (a1),d0
                lsl.b   #2,d0
                andi.b  #$C0,d0
                move.b  #$40,(a1)
                nop
                nop
                move.b  (a1),d1
                andi.b  #$3F,d1
                or.b    d1,d0
                not.b   d0
                move.b  d0,d1
                move.b  (a0),d2
                eor.b   d2,d0
                move.b  d1,(a0)+
                and.b   d1,d0
                move.b  d0,(a0)+
                rts

; ======================================================================

loc_e42:
                lea     VDPSetupArray2(pc),a1    ; Load the unused VDP setup array into a1.
                bra.s   loc_e4c                  ; Load into RAM.

; ======================================================================

loc_e48:
                lea     VDPSetupArray(pc),a1     ; Load VDP setup array.
loc_E4C:
                lea     ($FFFFFF70).w,a2         ; Load storage area for VDP register values.
                moveq   #$12,d7                  ; $13 registers to load.
loc_E52:
                move.b  (a1)+,(a2)+              ; Write the first register value to RAM.
                dbf     d7,loc_e52               ; Repeat for the rest.
                rts                              ; Return.

; ----------------------------------------------------------------------

VDPSetupArray:
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

loc_E82:
                lea     ($FFFFFF70).w,a1         ; Load storage area for VDP registers into a1.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                move.w  #$8000,d7                ; Load VDP register value.
loc_E90:
                move.w  d7,d0                    ; Copy to d0.
                move.b  (a1)+,d0                 ; Load the first register value to d0.
                move.w  d0,(a6)                  ; Write to the VDP.
                addi.w  #$100,d7                 ; Load increment value for next register.
                cmpi.w  #$9300,d7                ; Has it hit the final register?
                bcs.s   loc_e90                  ; If it hasn't, branch.
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
                dbf     d6,loc_ec0               ; Repeat until it's completely cleared.
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
                dbf     d4,loc_ede               ; Repeat for the tiles across that line.
                add.l   d7,d0                    ; Increment downwards by 1 tile.
                dbf     d2,loc_eda               ; Repeat for the next line across.
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
                dbf     d3,loc_f02               ; Repeat for the tiles across that line.
                add.l   d5,d0                    ; Increment downwards by 1 tile.
                dbf     d2,loc_efe               ; Repeat for the next line across.
                rts                              ; Return.

; ======================================================================
; Convert a VRAM address (write) into a VDP command.
loc_f10:
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

WaitforVBlank:                                   ; $F3C
                move.w  ($FFFFFF98).w,($FFFFFF96).w ; Mirror VBlank routine value.
loc_F42:
                tst.w   ($FFFFFF96).w            ; Has VBlank ran?
                bne.s   loc_f42                  ; If not, loop.
                rts                              ; Return.

; ======================================================================

loc_f4a:
                move.l  ($FFFFFFCA).w,d1
                bne.s   loc_f56
                move.l  #$2A6D365A,d1
loc_f56:
                move.l  d1,d0
                asl.l   #2,d1
                add.l   d0,d1
                asl.l   #3,d1
                add.l   d0,d1
                move.w  d1,d0
                swap    d1
                add.w   d1,d0
                move.w  d0,d1
                swap    d1
                move.l  d1,($FFFFFFCA).w
                rts

; ======================================================================
                        ; TODO - This shit!
loc_f70:
                movem.l d2-d5,-(sp)              ; Store used registers onto the stack.
                moveq   #$40,d0
                cmp.w   d0,d2
                bcs.s   loc_f92                  ; If it is lower, branch.
                tst.w   d3
                beq.s   loc_f82
                cmp.w   d2,d3
                bcs.s   loc_f86
loc_f82:
                move.w  d0,d2
                bra.s   loc_f92

loc_f86:
                sub.w   d3,d2
                neg.w   d2
                add.w   d0,d2
                cmp.w   d2,d0
                bcc.s   loc_f92
                moveq   #0,d2
loc_f92:
                lea     ($FFFFF7E0).w,a0         ; Load the palette buffer into a0.
                lea     ($FFFFF860).w,a1         ; Load the target palette RAM space into a1.
                cmpi.w  #$40,d2
                bne.s   loc_faa
                moveq   #$1F,d4
loc_FA2:
                move.l  (a1)+,(a0)+
                dbf     d4,loc_fa2
                bra.s   loc_fce

loc_faa:
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
                dbf     d5,loc_fb4
                move.w  d3,(a0)+
                dbf     d4,loc_fac
loc_fce:
                move.w  d2,d0
                movem.l (sp)+,d2-d5
                rts

; ======================================================================

loc_fd6:
                cmpi.w  #$40,d0
                beq.s   loc_ffe
                lea     ($FFFFF860).w,a0
                lea     ($FFFFF7E0).w,a1
                movem.l ($FFFFFFB8).w,d0-d1
                moveq   #$3F,d2
loc_fec:
                roxl.l  #1,d1
                roxl.l  #1,d0
                bcc.s   loc_ff6
                move.w  (a0)+,(a1)+
                bra.s   loc_ffa

loc_ff6:
                addq.w  #2,a0
                addq.w  #2,a1
loc_ffa:
                dbf     d2,loc_fec
loc_ffe:
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
                move.w  #$FE5,d0                 ; Set amount of bytes to write TODO IMPORTANT - change to dynamic length, perhaps?.
                moveq   #0,d1                    ; Position relative to start of Z80 RAM to write code to ($A00000+d1).
                moveq   #2,d2                    ; Skip the Z80 reset and start.
                lea     loc_1316(pc),a0          ; Load the Z80 sound driver address to a0.
                bsr.w   loc_10a6                 ; Write the code to the Z80.
                moveq   #8,d0                    ; Set amount of bytes to write TODO - change to dynamic length, perhaps?.
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
                dc.b    $20, $00

; ======================================================================

loc_1050:
                btst    #0,($A11100).l           ; Has the Z80 stopped?
                sne     ($FFFFFFC8).w            ; If it hasn't, set flag and stop the Z80.
                beq.s   loc_107c                 ; Otherwise, return.

; ======================================================================

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
                beq.s   loc_10c4                 ; If it has, branch.
                dbf     d3,loc_10b8              ; Otherwise, loop until otherwise.
                bra.s   loc_10d4                 ; If it still hasn't loaded on time, branch.

loc_10c4:
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

loc_10dc:
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
                bcc.s   loc_119e                 ; If it's not there, continue decoding palettes.
                movem.l (sp)+,d0-d2/a0           ; Restore register values.
                rts                              ; Return.

; ======================================================================

loc_11d0:
                move.w  #$8100,d0                ; Load VDP register 1's base word into d0.
                move.b  ($FFFFFF71).w,d0         ; Load the register command into d0.
                ori.b   #$40,d0                  ; Set the display bit.
                move.w  d0,(a6)                  ; Turn on the display.
                move.l  #$40000010,($C00004).l   ; Set the VDP to VSRAM write.
                move.l  ($FFFFFFA4).w,-4(a6)     ; Move the VScroll value into the VDP.
                move.w  ($FFFFFFDA).w,d0         ; Move the HScroll VRAM address value to d0.
                bsr.w   loc_f12                  ; Convert into a VRAM address.
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
                bsr.w   loc_a76
                addi.b  #$11,d4
                bcc.s   loc_1218
                rts

; ======================================================================

loc_122c:
                movem.l d1-d5/a0,-(sp)           ; Store register values to the stack.
                movea.l a5,a0                    ; Copy palette source to a0.
                bsr.s   loc_124a                 ; Load the dumping and screen-writing variables into the data registers.
                clr.w   d0                       ; Clear starting art tile value.
                lea     ($FFFFC3E0).w,a1         ; Load destination RAM address for the mappings.
                bsr.w   EniDec                   ; Decompress from enigma.
                movea.l a0,a5                    ; Restore address.
                movea.l a1,a0                    ; Copy the decompressed mappings source into a0.
                bsr.s   loc_1260                 ; Dump onto the screen.
                movem.l (sp)+,d1-d5/a0           ; Restore register values.
                rts                              ; Return.

loc_124a:
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
                bsr.w   loc_f12                  ; Convert it and set as the address.
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

loc_1280:
                bsr.w   DecodePalettes           ; Decode the encrypted palette from a5 into its position in the palette buffer.
                bsr.s   loc_122c                 ; Decompress the mappings and write to the screen.
                bsr.w   loc_f10                  ; Convert the previously stored value in d0 into an address.
                movea.l a5,a0                    ; Move the Sega screen's art source into a0.
                bra.w   NemDec                   ; Decompress the art from nemesis and load into VRAM.

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
                bra.s   loc_12e6                 ; Write to the VDP.

; ======================================================================

loc_12bc:
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

loc_12f0:
                move.l  (a0)+,(a5)               ; Write 4 bytes into the VDP.
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
                move.l  (a0)+,(a5)               ; ''
loc_1300:
                dbf     d1,loc_12f0              ; Repeat for every $20 bytes needed to be written.
                andi.w  #7,d0                    ; Get any number below 8.
                bra.s   loc_130c                 ; Above code handled tenths. Branch to the code that handles ones.

loc_130a:
                move.l  (a0)+,(a5)               ; Write 4 bytes into the VDP.
loc_130c:
                dbf     d0,loc_130a              ; Repeat for every 4 bytes needed to be written.
                movem.l (sp)+,a0/a5              ; Restore register values.
                rts                              ; Return.

; ======================================================================
; TODO - It's a fucking sound driver!
loc_1316:
                incbin  "Z80Stuff.bin"
; ======================================================================
; Rewritable RAM pointer table.                                              ; TODO - Describe the function of each of these.
; ======================================================================
RAMPointerTable:                                 ; $22FC
                dc.w    $0039                    ; Amount of addresses to load to RAM, -1.
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
                dc.w    loc_DC0                  ; Updates the controller array, and controller RAM ($FFFB12).
                dc.w    loc_DFA                  ; Update controller RAM ($FFFB18).
                dc.w    loc_E48                  ; Writes VDP setup array into RAM ($FFFB1E).
                dc.w    loc_E82                  ; Writes stored VDP setup array values from RAM into the VDP ($FFFB24).
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
                dc.w    loc_F4A                  ; ($FFFB78).
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
                dc.w    DecodePalettes           ; ($FFFBBA).
                dc.w    loc_122C                 ; ($FFFBC0).
                dc.w    loc_1280                 ; ($FFFBC6).

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

loc_10000:
                move.w  #$2700,sr                ; Disable interrupts.
                move.l  #VBlank,($FFFFFA7E).w    ; Set VBlank address.
                clr.w   ($FFFFFF96).w            ; Clear VBlank routine.
                move.w  #$40,($FFFFFFC0).w       ; Set to run first game mode (Sega Screen).
                clr.w   ($FFFFFFC4).w            ; Clear unused address 1.
                clr.w   ($FFFFFFC2).w            ; Clear unused address 2.
                bsr.w   loc_10cd4                ; Clear CRAM and VRAM (Except for plane nametables).
                bsr.w   loc_10cf6                ; Load the sound driver instructions into Z80 RAM.
                bsr.w   loc_100fc                ; Load the ASCII art into VRAM.
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
                bsr.w   loc_113bc                ; Clear H/VScroll values and TODO.
                move.w  #$101,($FFFFD82C).w      ; Set the BCD and hex level round value to 0101.
                move.w  #$2500,sr                ; Enable VBlank.
MainGameLoop
                movea.w StartofROM+2,sp          ; Restore stack pointer back to $(XXXX)FF70.
                move.w  ($FFFFFFC0).w,d0         ; Set game mode.
                andi.l  #$0000007C,d0            ; Game mode limit.
                jsr     GameModeArray(pc,d0.w)   ; Load appropriate game mode.
                addq.w  #1,($FFFFFF92).w         ; Increment game mode timer.
                bra.s   MainGameLoop             ; Loop, updating game mode.

; ----------------------------------------------------------------------

GameModeArray:
                bra.w   TitleScreen_Load         ; $0
                bra.w   TitleScreen_Loop         ; $4
                bra.w   loc_1228e                ; $8
                bra.w   loc_122e0                ; $C
                bra.w   loc_125be                ; $10
                bra.w   loc_125f2                ; $14
                bra.w   loc_12656                ; $18
                bra.w   loc_1266e                ; $1C
                bra.w   Level_Load               ; $20
                bra.w   loc_12b46                ;
                bra.w   loc_12f30                ;
                bra.w   loc_12fdc                ; $2C
                bra.w   loc_13110      ;
                bra.w   loc_13162
                bra.w   loc_139a2                ; Demo
                bra.w   loc_13a18                ; ''
                bra.w   loc_100CC      ;
                bra.w   loc_100D0

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

loc_100fc:
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
                move.w  #$2B,d1                                                                  ; Change length! TODO
                jsr     ($FFFFFA8E).w            ; Decompress it.
                move.w  #$120,d0                 ; Set to write to VRAM address $120.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                jsr     ($FFFFFB8A).w            ; Convert to an address.
                lea     loc_2372,a0              ; Load the start of the compressed ASCII symbols.
                moveq   #$30,d0                  ; Set to use palette line 3 and 0.
                add.b   ($FFFFD88E).w,d0         ; Set to use palette line 3 and 1.
                move.w  #$B3,d1                  ; TODO LENGTH
                jsr     ($FFFFFA8E).w            ; Decompress it.
                move.w  #$130,d0                 ; Set to write to VRAM address $130.
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                jsr     ($FFFFFB8A).w            ; Convert to an address.
                lea     loc_185fc,a0             ; Load start of compressed ASCII numbers/characters.
                moveq   #$30,d0                  ; Set to use palette line 3 and 0.
                add.b   ($FFFFD88E).w,d0         ; Set to use palette line 3 and 1.
                move.w  #$2B,d1                                                                  ; Change length! TODO
                jsr     ($FFFFFA8E).w            ; Decompress it.
                rts                              ; Return.

; ======================================================================

loc_101a8:
                lea     ($C00004).l,a6           ; Load VDP control port into a6.
                move.w  #$640,d0                 ; Set VRAM address to be converted.
                jsr     ($FFFFFB8A).w            ; Convert it and write it to the VDP.
                lea     loc_1993e,a0             ; Load nemesis compressed graphics source.      TODO - Possibly the score graphics?
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
                dc.w    loc_101E0                ; a0 - Data location.

                dc.w    loc_103A8_End-loc_103A8  ; d0 - Size of data in bytes.
                dc.w    $1200                    ; d1 - Relative offset in Z80 RAM ($A00000 + $XXXX)
                dc.w    loc_103A8                ; a0 - Data location.

; ----------------------------------------------------------------------
; Sound effects pointers. TODO - Convert when using AS!

loc_101E0:
                include "Z80SFX.bin"
loc_101E0_End:
; ----------------------------------------------------------------------
; General pointer list.
loc_103A8:
                include "Z80PointerList.bin"
loc_103A8_End:
; ======================================================================

loc_10cd4:
                move.l  #$C0000000,($C00004).l   ; Set VDP to CRAM write.
                moveq   #$3F,d0                  ; Set to write to 4 palette lines.
loc_10CE0:
                move.w  #0,($C00000).l           ; Clear first palette line.
                dbf     d0,loc_10ce0             ; Repeat until CRAM is fully cleared.
                moveq   #0,d2                    ; Set VRAM address to dump to.
                move.w  #$A800,d0                ; Set data length.
                jmp     ($FFFFFAD6).w            ; Write onto the screen.

; ======================================================================

loc_10cf6:
                jsr     ($FFFFFB30).w            ; Load the sound driver to the Z80.
                lea     loc_101d4,a1             ; Load the Z80 pointers list into a1.
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
                suba.l  #00010000,a0             ; $FF01E0 is the source location. TODO
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
                clr.w   ($FFFFE630).w            ; TODO - I don't know if this can be commented, these addresses might be radically different.
                addq.w  #1,($FFFFE634).w
                move.w  ($FFFFE632).w,d7
                subq.w  #1,d7
                bcs.s   loc_10e82
loc_10e6c:
                bsr.s   loc_10e52
                andi.l  #$0000FFFF,d1
                divu.w  ($FFFFE634).w,d1
                swap    d1
                add.w   d1,($FFFFE630).w
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
                bne.s   loc_10eee                ; If they don't, branch.
                dbf     d7,loc_10edc             ; Repeat to check the rest.
                bclr    #0,($FFFFD00C).w         ; Set palette fading as inactive.
                bne.s   loc_10ef4                ; If it was running before, branch.
                bra.s   loc_10f14                ; Skip updating palettes.
loc_10eee:
                move.b  #1,($FFFFD00C).w         ; Set palette fading as active.
loc_10ef4:
                btst    #6,($A10001).l           ; Is this being played on a PAL console?
                beq.s   loc_10f06                ; If not, branch.
                move.w  #$100,d0                 ; Set to delay for a while.
loc_10f02:
                dbf     d0,loc_10f02             ; Waste time...
loc_10f06:
                move.w  #$F7E0,d1                ; RAM address to dump from.
                moveq   #0,d2                    ; Set palette line to dump to as 0.
                move.w  #$80,d0                  ; Set data length.
                jsr     ($FFFFFAC4).w            ; Dump to CRAM.
loc_10f14:
                move.w  #$8100,d0                ; Load VDP register $01's command word into d0.
                move.b  ($FFFFFF71).w,d0         ; Load VDP register $01's stored value into d0.
                ori.b   #$40,d0                  ; Enable display bit.
                move.w  d0,(a6)                  ; Turn on the display.
                rts                              ; Return.

; ======================================================================
; TODO - Comment this.
loc_10f24:
                add.w   d7,d7
                lsl.w   #6,d6
                add.w   d6,d7
                add.w   d5,d7
                move.w  d7,d5

                                   ; TODO - CalcVRAMAddress?
loc_10f2e:
                lsl.l   #2,d5                    ; Shift to get boundary value in high word.
                lsr.w   #2,d5                    ; Restore address.
                bset    #$E,d5                   ; Set to VRAM write.
                swap    d5                       ; Convert to VDP address.
                rts                              ; Return.

; ======================================================================
; Unused routine to convert the VRAM address and write the command and
; tile into the VDP.
; ======================================================================
loc_10f3a
                bsr.s   loc_10f24                ; Get the converted VRAM address.
                bra.s   loc_10f40                ; Write the command and address to the VDP.

; ======================================================================

loc_10f3e:
                bsr.s   loc_10f2e                ; Get a converted VDP command in d5.
loc_10F40:
                move.l  d5,($C00004).l           ; Set VRAM address.
                move.w  d4,($C00000).l           ; Write the tile to VRAM.
                rts                              ; Return.

; ======================================================================
; Unused subroutine to convert the VRAM address into a VDP command and
; write the source material into the VDP d4 times.
; ======================================================================

loc_10f4e
                lea     ($C00004).l,a4           ; Load the VDP control port into a4.
                lea     ($C00000).l,a3           ; Load the VDP data port into a3.
                lsl.l   #2,d5                    ; Get correct VRAM address boundary.
                lsr.w   #2,d5                    ; Restore to get offset in that boundary.
                bset    #$E,d5                   ; Set to VRAM write.
                swap    d5                       ; Swap to get the full VDP command.
                move.l  d5,(a4)                  ; Write to the VDP.
loc_10F66:
                move.w  (a6)+,(a3)               ; Write the source data into VRAM.
                dbf     d4,loc_10f66             ; Repeat d4 times.
                rts                              ; Return.

; ======================================================================

PlaneMaptoVRAM:                                  ; $10F6E
                bsr.s   loc_10f2e                ; Convert the VRAM address.
loc_10F70:
                lea     ($C00004).l,a4           ; Load VDP control port into a4.
                lea     ($C00000).l,a3           ; Load VDP data port into a3.
                move.l  #$00400000,d0            ; Set as line increment value.
loc_10F82:
                move.l  d5,(a4)                  ; Write converted VRAM address into the control port.
                move.w  d7,d1                    ; Set to write number of tiles horizontally.
loc_10F86:
                move.w  (a6)+,(a3)               ; Write first tile onto the screen (horizontally).
                dbf     d1,loc_10f86             ; Repeat for d1 times horizontally.
                add.l   d0,d5                    ; Increment down a line on screen.
                dbf     d6,loc_10f82             ; Repeat for d6 times vertically.
                rts                              ; Return.

; ======================================================================
loc_10f94:                                    ; TODO
                cmpi.w  #-1,($FFFFD884).w
                bne.s   loc_10fa2
                move.w  #$8020,d4
                bra.s   loc_10fa6

loc_10fa2:
                add.w   ($FFFFD884).w,d4         ; Set the map tile to use priority.
loc_10FA6:
                bsr.s   loc_10f3e                ; Convert the address and write the map tile onto the screen.
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
                beq.s   loc_10fbe                ; If it's a string terminator ($00), end the string.
                bsr.s   loc_10f94                ; Write onto the screen.
                addq.w  #2,d6                    ; Load next VRAM tile.
                bra.s   loc_10fae                ; Repeat until a 0 is hit.
loc_10fbe:
                rts                              ; Return.

; ======================================================================

loc_10fc0:
                moveq   #0,d6                    ; Clear d6.
                move.w  (a6)+,d6                 ; Load the tile map's VRAM address (to be converted) to d6.
loc_10FC4:
                moveq   #0,d4                    ; Clear d4.
                moveq   #0,d5                    ; Clear d5.
                move.b  (a6)+,d4
                beq.s   loc_10ff2
                bsr.w   loc_10de8
                move.w  d5,d3
                move.w  d6,d5
                subi.w  #$20,d4
                move.l  d5,-(sp)
                bsr.w   loc_10f3e
                move.l  (sp)+,d5
                subi.w  #$40,d5
                move.w  d3,d4
                subi.w  #$20,d4
                bsr.w   loc_10f3e
                addq.w  #2,d6
                bra.s   loc_10fc4

loc_10ff2:
                rts

; ======================================================================

loc_10ff4:                                       ; TODO - Finish this shit some other time.
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
                dbf     d0,loc_10ffa             ; Repeat for the 3 other bytes.
                tst.b   ($FFFFD00D).w            ; Have there been any numbers written to the screen?
                bne.s   loc_11034                ; If there has, branch.
                moveq   #$30,d4                  ; Set to write a 0.
                bsr.w   loc_10f94                ; Write it.
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
                bsr.w   loc_10f94                ; TODO do this later.
loc_1104a:
                rts                              ; Return.

loc_1104c:
                move.b  #1,($FFFFD00D).w         ; Set the flag denoting a number having been written.
loc_11052:
                addi.w  #$30,d4                  ; Add to get to the numbers VRAM space.
                bsr.w   loc_10f94
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
; TODO - Give this a name.
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
loc_1118A:                                     ; TODO TEMP LABELLING!
                move.b  (a1)+,d0               ; Move the TODO into d0.
                ext.w   d0                     ; Extend to a word size.
                add.w   d2,d0                  ; Add the values together to get the first sprite word.
                move.w  d0,(a2)+               ; Write to the sprite table.
                move.b  (a1)+,(a2)+            ; Set sprite size.
                move.b  d6,(a2)+               ; Set link data.
                move.b  (a1)+,d0               ; Set priority, palette line, H/V flip and the upper 3 pattern bits.
                or.b    $13(a0),d0             ; TODO IMPORTANT - What does this do? Fix above when you find out!
                move.b  d0,(a2)+               ; Move to the sprite table.
                move.b  (a1)+,(a2)+            ; Write the pattern bits to the sprite table.
                move.b  (a1)+,d0               ;
                tst.b   2(a0)                  ; Is the MSB of the object status bit set? TODO name?
                bpl.s   loc_111b0              ; If it isn't, branch.
                bchg    #3,-2(a2)              ; Flip the sprite horizontally.
                move.b  (a1),d0                ;
loc_111b0:
                addq.w  #1,a1
                ext.w   d0
                add.w   d3,d0                  ; Add the horizontal position of the sprite to TODO
                move.w  d0,d4
                subi.w  #$41,d4
                cmpi.w  #$17F,d4               ; Is it lower than $17F?
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
loc_112d8 60 00 52 12                      bra.w   loc_164ec
loc_112dc 60 00 53 6a                      bra.w   loc_16648
loc_112e0 60 00 52 d8                      bra.w   loc_165ba     ;
loc_112e4 60 00 53 1a                      bra.w   loc_16600
loc_112e8 60 00 53 dc                      bra.w   loc_166c6
loc_112ec 60 00 5a bc                      bra.w   loc_16daa
                bra.w   loc_12172                ; $40 - Characters on the title screen.
                bra.w   loc_121cc                ; $44
                bra.w   loc_1223e                ; $48
                bra.w   loc_12476
loc_11300 60 00 21 ba                      bra.w   loc_134bc
loc_11304 60 00 31 d6                      bra.w   loc_144dc
loc_11308 60 00 5a c2                      bra.w   loc_16dcc


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
                move.l  #$40000200,($C00004).l   ; Set VDP to VRAM write, $0000 (Has a 2 in it, for some reason).
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
                addq.b  #1,(a0)                  ; Load next sign frame.
loc_1138A:
                moveq   #0,d0                    ; Clear d0.
                move.b  (a0),d0                  ; Load the current frame into d0.
                cmp.b   (a1),d0                  ; Has it hit the last sign frame?
                bcs.s   loc_113a0                ; If it hasn't, branch.
                clr.b   (a0)                     ; Reset sign frame back to 0.
                moveq   #0,d0                    ; Clear d0.
                move.b  #1,2(a0)                 ; Set TODO flag to 1.
loc_113a0:
                asl.w   #2,d0                    ; Multiply by 4 for longword tables.
                movea.l 2(a1,d0.w),a6            ; Load the address for the next sign frame.
                bsr.w   loc_10f70                ; Write to the screen.
                rts                              ; Return.

; ======================================================================
; TODO
ClearBonusObjectRAM:                             ; $113AC
                lea     ($FFFFC800).w,a0         ; Load the bonus stage's object RAM into a0.
                move.w  #$E0,d0                  ; Set to clear $380 bytes.
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
                tst.b   (a0)
loc_1145C:
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
                move.b  1(a6),(a0)
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
loc_114FE:
                moveq   #5,d0
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
                blt.s   loc_115dc
                subi.w  #$100,d7
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
                abcd    (a2)-,(a1)-
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
                moveq   #$C0,d3
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
                move.w  $20(a0),d3
                lea     loc_11878(pc),a6
                add.w   (a6,d0.w),d3
                move.w  d3,d2
                addq.l  #2,a6
                add.w   (a6,d0.w),d3
                move.w  $20(a1),d5
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

loc_11878: ff ff                            .short 0xffff
loc_1187a: 00 02
loc_1187C:ff ee                      ori.b #-18,d2
loc_1187e: 00 12 ff ff                      ori.b #-1,(a2)
loc_11882 00 02 ff f0                      ori.b #-16,d2
loc_11886 00 10 ff fc                      ori.b #-4,(a0)
loc_1188a 00 08                            .short loc_8
loc_1188c ff f2                            .short 0xfff2
loc_1188e 00 0c                            .short loc_c
loc_11890 ff f9                            .short 0xfff9
loc_11892 00 0e                            .short loc_e
loc_11894 ff f4                            .short 0xfff4
loc_11896 00 0c                            .short loc_c
loc_11898 ff fc                            .short 0xfffc
loc_1189a 00 08                            .short loc_8
loc_1189c ff fa                            .short 0xfffa
loc_1189e 00 06 ff ff                      ori.b #-1,d6
loc_118a2 00 02 ff ee                      ori.b #-18,d2
loc_118a6 00 12 ff fe                      ori.b #-2,(a2)
loc_118aa 00 04 ff f6                      ori.b #-10,d4
loc_118ae 00 04 ff fc                      ori.b #-4,d4
loc_118b2 00 08                            .short loc_8
loc_118b4 ff f9                            .short 0xfff9
loc_118b6 00 07 ff ff                      ori.b #-1,d7
loc_118ba 00 02 ff fa                      ori.b #-6,d2
loc_118be 00 06 ff fc                      ori.b #-4,d6
loc_118c2 00 08                            .short loc_8
loc_118c4 ff f6                            .short 0xfff6
loc_118c6 00 0a                            .short loc_a
loc_118c8 ff fc                            .short 0xfffc
loc_118ca 00 08                            .short loc_8
loc_118cc ff fc                            .short 0xfffc
loc_118ce 00 02 ff fc                      ori.b #-4,d2
loc_118d2 00 08                            .short loc_8
loc_118d4 00 03 00 02                      ori.b #2,d3
loc_118d8 ff fc                            .short 0xfffc
loc_118da 00 02 ff fc                      ori.b #-4,d2
loc_118de 00 08                            .short loc_8
loc_118e0 00 04 00 02                      ori.b #2,d4
loc_118e4 ff fc                            .short 0xfffc
loc_118e6 00 08                            .short loc_8
loc_118e8 ff ff                            .short 0xffff
loc_118ea 00 02 ff fd                      ori.b #-3,d2
loc_118ee 00 06 ff fe                      ori.b #-2,d6
loc_118f2 00 04 00 00                      ori.b #0,d4
loc_118f6 00 08                            .short loc_8
loc_118f8 ff f8                            .short 0xfff8
loc_118fa 00 10 ff f0                      ori.b #-16,(a0)
loc_118fe 00 10 ff f8                      ori.b #-8,(a0)
loc_11902 00 10 ff f0                      ori.b #-16,(a0)
loc_11906 00 02 ff ff                      ori.b #-1,d2
loc_1190a 00 02 ff ee                      ori.b #-18,d2
loc_1190e 00 0e                            .short loc_e

; ======================================================================

loc_11910:
                lsl.w   #1,d4                    ; Multiply by 2 for word tables.
                move.w  loc_1191c(pc,d4.w),d4    ; Load the correct map tile.
                bsr.w   loc_10f3e                ; Write to the VDP.
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
                bsr.w   loc_10f3e
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
loc_1117E:
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
                move.w  #$3FF,d0                 ; Set to repeat $400 times.
loc_119b4:
                move.w  d1,($C00000).l           ; Write to the VDP.
                dbf     d0,loc_119b4             ; Repeat until $400 BG tiles have been drawn.
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
                bsr.w   loc_10f24                ; Get a VDP command in d5.
                lsl.w   #2,d4                    ; Multiply by 4 for 4 byte entry tables.
                move.w  loc_11b3c(pc,d4.w),d7    ; Get amount of horizontal tiles to write.
                move.w  loc_11b3c+2(pc,d4.w),d6  ; Get amount of vertical tiles to write.
                lsr.w   #1,d4                    ; Divide by 2 for 2 byte entry tables.
                moveq   #-1,d2                   ; Set d2 to $FFFFFFFF (for address).
                move.w  loc_11b54(pc,d4.w),d2    ; Overwrite lower word with RAM address.
                movea.l d2,a6                    ; Move the RAM address into a6.
                movea.l (a6),a6                  ; Move the mappings address in that RAM address into a6.
                bsr.w   loc_10f70                ; Write onto the screen.
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
                bsr.w   loc_10f24                ; Get a VDP command in d5.
                moveq   #2,d7                    ; Set to draw three tiles across.
                moveq   #2,d6                    ; Set to draw three tiles down.
                lea     OpenDoorMaps,a6          ; Load the open door plane mappings into a6.
                bsr.w   loc_10f70                ; Write onto the screen.
                rts                              ; Return.

;  =====================================================================
loc_11b86:
                lea     ($FFFFD82E).w,a0         ; Load the door's X and Y coordinate word.
                moveq   #0,d7                    ; Clear d7.
                moveq   #0,d6                    ; Clear d6.
                moveq   #0,d5                    ; Clear d5.
                move.b  (a0),d7                  ; Load the door's X-coordinates into d7.
                move.b  1(a0),d6                 ; Load the door's Y-coordinates into d6.
                subq.b  #1,d6                    ; Set to load above the door.
                move.w  #$E000,d5                ; Set to write in the Plane B screen space.
                bsr.w   loc_10f24                ; Output a VRAM address into d5.
                moveq   #2,d7                    ; Set to write 3 tiles across.
                moveq   #0,d6                    ; Set to write 1 tile down.
                lea     FlickySignMaps,a6        ; Load the Flicky sign mappings into a6.
                btst    #7,($A10001).l           ; Is the console a domestic MD?
                beq.s   loc_11bbc                ; If it is, branch.
                lea     ExitSignMaps,a6          ; Load the exit sign mappings into a6.
loc_11bbc:
                bsr.w   loc_10f70                ; Write onto the screen.
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



loc_11bf8 00 00 d8 2e                      ori.b #46,d0
loc_11bfc d8 30 d8 34                      add.b (a0)(0000000000000034,a5:l),d4
loc_11c00 d8 36 d8 5e                      add.b (a6)(000000000000005e,a5:l),d4
loc_11c04 d8 6e

; ======================================================================

loc_11C06:
                tst.b   $2(a0)
                beq.s   loc_11C24


loc_11c0c:
                moveq   #0,d7                    ; Clear d7.
                moveq   #0,d6                    ; Clear d6.
                move.b  (a0),d7
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
                bsr.w   loc_10f24                ; Convert d5's VRAM address into a proper VDP command.
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

loc_11cb8: 04 0f
                dc.l    loc_1A490
                dc.l    loc_1A46C
                dc.l    loc_1A47E        ; TODO PLANE MAPS
                dc.l    loc_1A490

; ======================================================================

loc_11cca:
                lea     loc_11cd4(pc),a1
                jmp     loc_11d38

; ----------------------------------------------------------------------

loc_11cd4 04 02
                dc.l    DoorMaps
                dc.l    loc_1A490            ; TODO PLANE MAPS
                dc.l    loc_1A47E
                dc.l    loc_1A46C

; ======================================================================


loc_11ce6:
                lea     loc_11cf0(pc),a1
                jmp     loc_11d38
                
; ----------------------------------------------------------------------

loc_11cf0 05 02
                dc.l    loc_11D06               
                dc.l    loc_1A46C
                dc.l    loc_1A47E
                dc.l    loc_1A490
                dc.l    loc_1A4A2

; ----------------------------------------------------------------------

loc_11d06:
00 00 00 00                      ori.b #0,d0
loc_11d0a 00 00 00 00                      ori.b #0,d0
loc_11d0e 00 00 00 00                      ori.b #0,d0
loc_11d12 00 00 00 00                      ori.b #0,d0
loc_11d16 00 00

; ======================================================================

loc_11D18:
                lea     loc_11D22(pc),a1
                jmp     loc_11d38

; ----------------------------------------------------------------------
; TODO

loc_11d22 05 01                            btst d2,d1
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
                move.b  ($FFFFD82E).w,d7
                move.b  ($FFFFD82F).w,d6
                move.w  #$C000,d5
                bsr.w   loc_10f24
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
                bsr.w   loc_10ff4                ; Write it.
                rts                              ; Return.

; ======================================================================

loc_11dd4:
                lea     ($FFFFCC00).w,a6         ; Load the top score value into a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C068,d5                ; Set as VRAM address to convert.
                moveq   #3,d0                    ; Set to draw 4 bytes' worth of numbers.
                bsr.w   loc_10ff4                ; Write it.
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
                bsr.w   loc_10ff4
                rts

; ======================================================================

loc_11e06:
                lea     loc_11e46(pc),a6         ; Load the normal 'RD.' mappings.
                btst    #6,($A10001).l           ; Is this being played on a PAL console?
                beq.s   loc_11e18                ; If it isn't, branch.
                lea     loc_11e4c(pc),a6         ; Otherwise, load the repositioned 'RD.' mappings.
                bsr.w   WriteASCIIString         ; Write onto the screen.
loc_11e1c:
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
                bsr.w   loc_10ff4                ; Draw it onto the screen.
                lea     ($FFFFD267).w,a6         ; Load the level's ending time to a6 (seconds).
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C16C,d5                ; Set the VRAM address to write to.
                moveq   #0,d0                    ; Set to draw 1 number.
                bsr.w   loc_10ff4                ; Draw it onto the screen.
                tst.b   ($FFFFD266).w            ; Has a minute elapsed?
                bne.s   loc_11e94                ; If not, branch.
                lea     ($FFFFD268).w,a6         ; Load the bonus score RAM address into a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C260,d5                ; Set the VRAM address to write to.
                moveq   #3,d0                    ; Set to write 4 numbers.
                bsr.w   loc_10ff4                ; Draw the numbers onto the screen.
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
                bne.s   loc_11efa                ; If it has, branch.
                lea     loc_11f2c(pc),a6         ; Load the 'PTS.' mappings.
                bsr.w   WriteASCIIString         ; Write to the screen.
                bra.s   loc_11f02                ; Skip loading 'NO BONUS'.

                lea     loc_11f34(pc),a6         ; Load the NO BONUS mappings.
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
                dc.w    $0000`                   ; String terminator, pad to even.

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
                bsr.w   loc_10ff4                ; Write onto the screen.
                lea     ($FFFFD292).w,a6         ; Load the points (? TODO) bonus for the collected chicks.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C266,d5                ; Load the position on Plane A to write to.
                moveq   #1,d0                    ; Set to load 2 bytes worth.
                bsr.w   loc_10ff4                ; Write onto the screen.
                cmpi.b  #$14,($FFFFD28E).w       ; Have you collected all 20 chicks?
                bne.s   loc_11faa                ; If you haven't, skip the perfect bonus stuff.
                lea     loc_11fac(pc),a6         ; Load the perfect bonus value.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C390,d5                ; Load the position on Plane A to write to.
                moveq   #3,d0                    ; Set to write 4 bytes.
                bsr.w   loc_10ff4                ; Write onto the screen.
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
                bsr.w   loc_10fc0                ; Dump them onto the screen.
loc_12062:
                bsr.w   loc_11e1c                ; Write the '1P' and 'TOP' mappings onto the screen.
                bsr.w   loc_11dc2                ; Write the first player's score onto the screen.
                bsr.w   loc_11dd4                ; Write the high score onto the screen.
                bsr.w   CheckObjectRAM           ; Load object code, convert to sprites, etc.
                clr.w   ($FFFFFF92).w            ; Clear the game mode timer.
                move.b  #$85,d0                  ; TODO?
                jsr     ($FFFFFB66).w            ; ^ Possibly sound driver related. Check in a minute.
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
                dc.w    $C328                    ; VRAM address to write to.
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
                include "Palettes\Pal_TitleScreen.bin"

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
                dc.l    loc_154AE                      ori.b #-82,d1
loc_121b0 00 01 62 bc                      ori.b #-68,d1
loc_121b4: 00 00 00 04                      ori.b #4,d0
loc_121b8 00 04 00 00                      ori.b #0,d4
loc_121bc:

00 b0 00 f0

01 10 00 ec

loc_121c4 00 b0 01 08

01 10 01 00          ori.l #17301776,(a0,d0.w)

; ======================================================================
; 'PUSH START BUTTON' object on the title screen.
; ======================================================================
loc_121cc:
                bset    #7,(a0)                  ; Set object as loaded.
                bne.s   loc_121e6                ; If it wasn't before, branch.
                move.l  #loc_1ACDC,$C(a0)        ; TODO mappings?
                move.w  #$F0,$20(a0)             ; Set starting horizontal height.
                move.w  #$120,$24(a0)            ; Set starting vertical height.
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
                move.w  #4,$3C(a0)               ; Set to load next routine on next pass.
loc_1223C:
                rts                              ; Return.

; ======================================================================
; 'FLICKY' letters on the title screen.
; ======================================================================

loc_1223e:
                bset    #7,(a0)                  ; Set object as loaded.
                bne.s   loc_1225c                ; If it was already loaded, branch.
                move.w  $38(a0),d0               ; Get object subtype.
                lsl.w   #2,d0                    ; Multiply by 4 for longword tables.
                move.l  loc_1225e(pc,d0.w),$C(a0); Load mappings pointer into its SST.
                move.w  loc_12276(pc,d0.w),$20(a0); Get horizontal position.
                move.w  loc_12276+2(pc,d0.w),$24(a0); Get vertical position.
                rts                              ; Return.

; ----------------------------------------------------------------------

loc_1225e:
                dc.l    loc_1AD52                ; $0
                dc.l    loc_1AD5A                ; $1
                dc.l    loc_1AD62                ; $2
                dc.l    loc_1AD6A                ; $3
                dc.l    loc_1AD72                ; $4
                dc.l    loc_1AD7A                ; $5

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
                bsr.w   loc_12824                ; TODO
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
                bsr.w   loc_10fc0                ; Dump onto the screen.
                dbf     d0,loc_1231e             ; Repeat for all the text.
                lea     ($FFFFD82E).w,a0         ; TODO - What the fuck is this?
                moveq   #$E,d7
                btst    #7,($A10001).l           ; Is the console being played on a domestic Mega Drive?
                beq.s   loc_1233a                ; If it is, branch.
                moveq   #$F,d7
loc_1233a:
                moveq   #6,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
                bsr.w   loc_11b16                ; Dump mappings from an address in RAM (Load door mappings).
                bsr.w   loc_11b86                ; Load the exit sign mappings onto the screen.
                moveq   #5,d7
                moveq   #$17,d6
                moveq   #0,d4
                move.b  d7,(a0)
                move.b  d6,1(a0)
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
; Japanese help screen text mappings. TODO - Sort this out a little more, maybe?
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
                dc.w    $C224,                   ; VRAM address to write to.
                dc.w    $7EA4, $7189, $7261      ; Mappings text.
                dc.w    $9372, $67A1, $6A61      ; ''
                dc.w    $1200                    ; Mappings text & string terminator.

loc_123c2:
                dc.w    $C306                    ; VRAM address to write to.
                dc.w    $FABF, $DD8C, $646C      ; Mappings text.
                dc.w    $7311, $EDE4, $DDFD      ; ''
                dc.w    $2026, $20BB ,$E6E3      ; ''
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
; TODO - Do this some other fucking time.
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
                bset    #7(a0)                   ; Set object as loaded.
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
                beq.s   loc_124ac                ; If it is, set to load to the SSTs.
                lea     loc_1256e(pc),a1         ; Otherwise, use the overseas' coordinates.
                move.w  (a1,d0.w),$20(a0)        ; Load the horizontal position.
                move.w  2(a1,d0.w),$24(a0)       ; Load the vertical position.
loc_124b8:
                rts                              ; Return.

; ----------------------------------------------------------------------

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
; TODO

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
                dc.l    loc_1A8A8                ;
loc_12506 00 01 a7 e8                      ori.b #-24,d1
                dc.l    loc_1A848
loc_1250e 00 01 a8 50                      ori.b #$50,d1
loc_12512 00 01 a7 f8                      ori.b #-8,d1
                dc.l    loc_1A7F0                ; Chick moving, frame 1.
loc_1251a 00 01 a8 58                      ori.b #$58,d1

loc_1251e: 00 b4 00 a0 00 c0 00 a0          ori.l #10485952,(a4)(ffffffffffffffa0,d0.w)
loc_12526 00 cc                            .short 0x00cc
loc_12528 00 a0 00 d8 00 a0                ori.l #14155936,(a0)-
loc_1252e 01 20                            btst d0,(a0)-
loc_12530 00 a0 01 2c 00 a0                ori.l #19660960,(a0)-
loc_12536 01 38 00 a0                      btst d0,loc_0a0
loc_1253a 01 44                            bchg d0,d4
loc_1253c 00 a0 00 98 00 c8                ori.l #9961672,(a0)-
loc_12542 00 d8                            .short 0x00d8
loc_12544 00 c8                            .short 0x00c8
loc_12546 00 d0                            .short 0x00d0
loc_12548 01 00                            btst d0,d0
loc_1254a 01 18                            btst d0,(a0)+
loc_1254c 01 00                            btst d0,d0
loc_1254e 01 18                            btst d0,(a0)+
loc_12550 01 10                            btst d0,(a0)
loc_12552 00 c0                            .short 0x00c0
loc_12554 01 50                            bchg d0,(a0)
loc_12556 00 c8                            .short 0x00c8
loc_12558 01 50                            bchg d0,(a0)
loc_1255a 00 d0                            .short 0x00d0
loc_1255c 01 50                            bchg d0,(a0)
loc_1255e 00 d8                            .short 0x00d8
loc_12560 01 50                            bchg d0,(a0)
loc_12562 00 e0                            .short 0x00e0
loc_12564 01 50                            bchg d0,(a0)
loc_12566 00 e8                            .short 0x00e8
loc_12568 01 50                            bchg d0,(a0)
loc_1256a 00 f0                            .short 0x00f0
loc_1256c 01 50                            bchg d0,(a0)
loc_1256e 00 94 00 a0 00 a0                ori.l #10485920,(a4)
loc_12574 00 a0 00 ac 00 a0                ori.l #11272352,(a0)-
loc_1257a 00 b8 00 a0 01 48 00 a0          ori.l #10486088,loc_0a0
loc_12582 01 54                            bchg d0,(a4)
loc_12584 00 a0 01 60 00 a0                ori.l #23068832,(a0)-
loc_1258a 01 6c 00 a0                      bchg d0,(a4)(160)
loc_1258e 00 b0 00 c8 00 e8 00 c8          ori.l #13107432,(a0)(ffffffffffffffc8,d0.w)
loc_12596 00 d0                            .short 0x00d0
loc_12598 01 00                            btst d0,d0
loc_1259a 01 18                            btst d0,(a0)+
loc_1259c 01 00                            btst d0,d0
loc_1259e 01 18                            btst d0,(a0)+
loc_125a0 01 10                            btst d0,(a0)
loc_125a2 00 c0                            .short 0x00c0
loc_125a4 01 50                            bchg d0,(a0)
loc_125a6 00 c8                            .short 0x00c8
loc_125a8 01 50                            bchg d0,(a0)
loc_125aa 00 d0                            .short 0x00d0
loc_125ac 01 50                            bchg d0,(a0)
loc_125ae 00 d8                            .short 0x00d8
loc_125b0 01 50                            bchg d0,(a0)
loc_125b2 00 e0                            .short 0x00e0
loc_125b4 01 50                            bchg d0,(a0)
loc_125b6 00 e8                            .short 0x00e8
loc_125b8 01 50                            bchg d0,(a0)
loc_125ba 00 f0                            .short 0x00f0
loc_125bc 01 50                            bchg d0,(a0)

; ======================================================================

loc_125be:
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette source into a5.
                jsr     ($FFFFFBBA).w            ; Decode the palettes and load them into the palette buffer.
                lea     Map_LSRound(pc),a6       ; Load the 'ROUND' mappings into a6.
                bsr.w   WriteASCIIString                ; Dump them onto the screen.
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
                cmpi.b  #36,d1                   ; Has the round hit 36?
                beq.s   loc_12642                ; If it has, don't add anymore.
                addi.b  #0,d0                    ; Clear the extend CCR bit.
                abcd    d2,d1                    ; Add by 1 (decimal).
                addq.b  #1,($FFFFD82D).w         ; Add to the hex round value.
                move.b  d1,($FFFFD82C).w         ; Copy the decimal add to the BCD address.
                bra.s   loc_12642

loc_1261a:
                btst    #1,d0                    ; Is down being pressed?
                beq.s   loc_12636                ; If it isn't, branch.
                cmpi.b  #1,d1                    ; Has the round hit 1?
                beq.s   loc_12642                ; If it is, branch.
                addi.b  #0,d0                    ; Clear the extend CCR bit.
                sbcd    d2,d1                    ; Subtract by 1.
                addq.b  #1,($FFFFD82D).w         ; Subtract from the hex round value.
                move.b  d1,($FFFFD82C).w         ; Copy the decimal subtract from the BCD address.
                bra.s   loc_12642

loc_12636:
                btst    #7,d0                    ; Is start being pressed?
                beq.s   loc_12642                ; If it isn't, branch.
                move.w  #$18,($FFFFFFC0).w       ; Load the level game mode.
loc_12642:
                lea     ($FFFFD82C).w,a6         ; Load the level number address to a6.
                moveq   #0,d5                    ; Clear d5.
                move.w  #$C360,d5                ; Set the screen coordinates to write to.
                moveq   #0,d0                    ; Clear d0.
                bsr.w   loc_10ff4                ; Write the round number onto the screen.
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
                lea     loc_127d0(pc),a0         ;
                move.l  (a0,d0.w),d1             ;
                move.l  d1,($FFFFD818).w
                moveq   #$20,d7
                bsr.w   loc_11774
                subq.b  #1,d0
                lsr.w   #2,d0
                lsl.w   #2,d0
                lea     loc_12788(pc),a0
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

loc_12788: 00 01 a2 9a                      ori.b #-102,d1
loc_1278c 00 01 a2 a6                      ori.b #-90,d1
loc_12790 00 01 a2 b2                      ori.b #-78,d1
loc_12794 00 01 a2 be                      ori.b #-66,d1
loc_12798 00 01 a2 ca                      ori.b #-54,d1
loc_1279c 00 01 a2 9a                      ori.b #-102,d1
loc_127a0 00 01 a2 a6                      ori.b #-90,d1
loc_127a4 00 01 a2 b2                      ori.b #-78,d1
loc_127a8 00 01 a2 9a                      ori.b #-102,d1
loc_127ac 00 01 a2 a6                      ori.b #-90,d1
loc_127b0 00 01 a2 b2                      ori.b #-78,d1
loc_127b4 00 01 a2 9a                      ori.b #-102,d1

; ----------------------------------------------------------------------

WallpaperTileTable:                              ; $127B8

                dc.l    WallPaperTiles1
                dc.l    WallPaperTiles1
                dc.l    WallPaperTiles2
                dc.l    WallPaperTiles3
                dc.l    WallPaperTiles5
                dc.l    WallPaperTiles4

; ----------------------------------------------------------------------

loc_127d0: 00 01 a3 54                      ori.b #84,d1
loc_127d4 00 01 a3 54                      ori.b #84,d1
loc_127d8 00 01 a3 92                      ori.b #-110,d1
loc_127dc 00 01 a3 b2                      ori.b #-78,d1
loc_127e0 00 01 a3 f0                      ori.b #-16,d1
loc_127e4 00 01 a4 2e                      ori.b #46,d1

; ----------------------------------------------------------------------

loc_127e8: 00 01 a4 e8                      ori.b #-24,d1
loc_127ec 00 01 a5 18                      ori.b #$18d1
loc_127f0 00 01 a5 48                      ori.b #72,d1
loc_127f4 00 01 a5 78                      ori.b #120,d1
loc_127f8 00 01 a5 a8                      ori.b #-88,d1
loc_127fc 00 01 a5 d8                      ori.b #-40,d1
loc_12800 00 01 a6 08                      ori.b #8,d1
loc_12804 00 01 a6 38                      ori.b #$38,d1
loc_12808 00 01 a6 68                      ori.b #104,d1
loc_1280c 00 01 a6 98                      ori.b #-104,d1
loc_12810 00 01 a6 c8                      ori.b #-56,d1
loc_12814 00 01 a6 f8                      ori.b #-8,d1
loc_12818 00 01 a7 28                      ori.b #$28,d1
loc_1281c 00 01 a7 58                      ori.b #$58,d1
loc_12820 00 01 a7 88                      ori.b #-120,d1

; ======================================================================

loc_12824:
                moveq   #$30,d7
                bsr.w   loc_11764
                lsr.w   #2,d0
                lsl.w   #1,d0
                lea     loc_12866(pc),a0
                moveq   #-1,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                lea     ($FFFFF800).w,a1
                moveq   #7,d0
loc_12840:
                move.l  (a0)+,(a1)+
                dbf     d0,loc_12840
                moveq   #$F,d7
                bsr.w   loc_11774
                subq.w  #1,d0
                lsl.w   #1,d0
                lea     loc_129fe(pc),a0
                lea     ($FFFFF858).w,a1
                moveq   #-1,d1
                move.w  (a0,d0.w),d1
                movea.l d1,a0
                move.l  (a0)+,(a1)+
                move.l  (a0)+,(a1)+
                rts                              ; Return.

; ======================================================================

loc_12866: 28 7e                            .short 0x287e
loc_12868 28 9e                            move.l  (a6)+,(a4)
loc_1286a 28 be                            .short 0x28be
loc_1286c 28 de                            move.l  (a6)+,(a4)+
loc_1286e 28 fe                            .short 0x28fe
loc_12870 29 1e                            move.l  (a6)+,(a4)-
loc_12872 29 3e                            .short 0x293e
loc_12874 29 5e 29 7e                      move.l  (a6)+,(a4)(10622)
loc_12878 29 9e 29 be 29 de 00 00 00 06    move.l  (a6)+,@(0000000029de0000)@6,d2:l)
loc_12882 00 0e                            .short loc_e
loc_12884 0c c4                            .short 0x0cc4
loc_12886 04 aa 06 ee 00 64 00 64          subi.l #116260964,(a2)(100)
loc_1288e 00 a2 00 a2 06 ee                ori.l #10618606,(a2)-
loc_12894 00 8c                            .short 0x008c
loc_12896 08 ee 00 ae 00 6e                bset    #-82,(a6)(110)
loc_1289c 04 ca                            .short 0x04ca
loc_1289e 00 00 00 68                      ori.b #104,d0
loc_128a2 02 aa 00 4a 0e a8 04 44          andi.l #4853416,(a2)(1092)
loc_128aa 0c 86 0c cc 0e a8                cmpi.l #214699688,d6
loc_128b0 0a aa 00 00 00 a4 00 ac          eori.l #164,(a2)(172)
loc_128b8 00 c6                            .short 0x00c6
loc_128ba 00 62 00 a8                      ori.w #168,(a2)-
loc_128be 00 00 00 ee                      ori.b #-18,d0
loc_128c2 04 6c 0e 28 0a 0a                subi.w  #3624,(a4)(2570)
loc_128c8 0c 2a 0a 8a 0e 4e                cmpi.b  #-118,(a2)(3662)
loc_128ce 0a ca                            .short 0x0aca
loc_128d0 06 4a                            .short 0x064a
loc_128d2 0c ac 08 88 0e ee 0a aa          cmpi.l #143134446,(a4)(2730)
loc_128da 04 44 08 88                      subi.w  #2184,d4
loc_128de 00 00 0a 86                      ori.b #-122,d0
loc_128e2 00 0c                            .short loc_c
loc_128e4 0a aa 04 64 00 4a 02 42          eori.l #73662538,(a2)(578)
loc_128ec 00 8a                            .short 0x008a
loc_128ee 00 00 04 20                      ori.b #$20,d0
loc_128f2 08 64 0c 6e                      bchg #110,(a4)-
loc_128f6 0c ce                            .short 0x0cce
loc_128f8 0e 8e                            .short 0x0e8e
loc_128fa 0a 0e                            .short 0x0a0e
loc_128fc 0c ae 00 00 0e 00 0e 60          cmpi.l #3584,(a6)(3680)
loc_12904 0a aa 02 86 02 ca 00 44          eori.l #42336970,(a2)(68)
loc_1290c 00 a8 00 00 00 00 00 00          ori.l #0,(a0)
loc_12914 00 cc                            .short 0x00cc
loc_12916 0e ee                            .short 0x0eee
loc_12918 00 ee                            .short 0x00ee
loc_1291a 00 86 08 ee 00 00                ori.l #149815296,d6
loc_12920 06 2e 0e c0 0e 00                addi.b #-64,(a6)(3584)
loc_12926 00 ee                            .short 0x00ee
loc_12928 0a ee                            .short 0x0aee
loc_1292a 00 66 00 ca                      ori.w #202,(a6)-
loc_1292e 00 00 00 00                      ori.b #0,d0
loc_12932 00 00 08 88                      ori.b #-120,d0
loc_12936 0e ee                            .short 0x0eee
loc_12938 0a aa 04 44 08 88 00 00          eori.l #71567496,(a2)(0)
loc_12940 00 06 00 0e                      ori.b #$E,d6
loc_12944 0c c4                            .short 0x0cc4
loc_12946 04 a8 06 ee 0a aa 08 cc          subi.l #116263594,(a0)(2252)
loc_1294e 0c cc                            .short 0x0ccc
loc_12950 0a ee                            .short 0x0aee
loc_12952 00 00 00 c2                      ori.b #-62,d0
loc_12956 0e ee                            .short 0x0eee
loc_12958 00 e6                            .short 0x00e6
loc_1295a 00 a0 04 ca 00 00                ori.l #80347136,(a0)-
loc_12960 00 48                            .short 0x0048
loc_12962 00 8e                            .short 0x008e
loc_12964 00 4e                            .short 0x004e
loc_12966 04 e4                            .short 0x04e4
loc_12968 04 44 00 8a                      subi.w  #138,d4
loc_1296c 0a a2 00 ae 08 82                eori.l #11405442,(a2)-
loc_12972 00 00 00 8e                      ori.b #-114,d0
loc_12976 00 ee                            .short 0x00ee
loc_12978 02 8e                            .short 0x028e
loc_1297a 00 2a 00 aa 00 00                ori.b #-86,(a2)(0)
loc_12980 00 6a 00 ee 00 e0                ori.w #238,(a2)(224)
loc_12986 00 ae 00 e0 00 86 00 68          ori.l #14680198,(a6)(104)
loc_1298e 00 8a                            .short 0x008a
loc_12990 00 66 00 ac                      ori.w #172,(a6)-
loc_12994 08 88                            .short 0x0888
loc_12996 0e ee                            .short 0x0eee
loc_12998 0a aa 04 44 08 88 00 00          eori.l #71567496,(a2)(0)
loc_129a0 0e ae                            .short 0x0eae
loc_129a2 0e 6e                            .short 0x0e6e
loc_129a4 0e 48                            .short 0x0e48
loc_129a6 0c 06 00 4a                      cmpi.b  #74,d6
loc_129aa 00 8a                            .short 0x008a
loc_129ac 00 4e                            .short 0x004e
loc_129ae 00 00 00 44                      ori.b #$44,d0
loc_129b2 00 00 00 aa                      ori.b #-86,d0
loc_129b6 06 cc                            .short 0x06cc
loc_129b8 00 cc                            .short 0x00cc
loc_129ba 00 66 00 a8                      ori.w #168,(a6)-
loc_129be 00 00 0e 00                      ori.b #0,d0
loc_129c2 0e 60                            .short 0x0e60
loc_129c4 0a aa 06 66 0a 6e 00 00          eori.l #107350638,(a2)(0)
loc_129cc 00 00 04 ae                      ori.b #-82,d0
loc_129d0 00 06 00 02                      ori.b #2,d6
loc_129d4 0e e0                            .short 0x0ee0
loc_129d6 0e ee                            .short 0x0eee
loc_129d8 0e e6                            .short 0x0ee6
loc_129da 0e 60                            .short 0x0e60
loc_129dc 0e ea                            .short 0x0eea
loc_129de 00 00 06 2e                      ori.b #46,d0
loc_129e2 0e c0                            .short 0x0ec0
loc_129e4 0e 00                            .short 0x0e00
loc_129e6 00 ee                            .short 0x00ee
loc_129e8 0a ee                            .short 0x0aee
loc_129ea 00 00 00 00                      ori.b #0,d0
loc_129ee 04 ae 00 0a 00 02 0a 6c          subi.l #655362,(a6)(2668)
loc_129f6 0e e6                            .short 0x0ee6
loc_129f8 0c 8e                            .short 0x0c8e
loc_129fa 04 06 0e ec                      subi.b #-20,d6

; ======================================================================

loc_129fe: 2a 1c                            move.l  (a4)+,d5
loc_12a00 2a 24                            move.l  (a4)-,d5
loc_12a02 2a 2c 2a 34                      move.l  (a4)(10804),d5
loc_12a06 2a 3c 2a 44 2a 4c                move.l  #709110348,d5
loc_12a0c 2a 54                            movea.l (a4),a5
loc_12a0e 2a 5c                            movea.l (a4)+,a5
loc_12a10 2a 64                            movea.l (a4)-,a5
loc_12a12 2a 6c 2a 74                      movea.l (a4)(10868),a5
loc_12a16 2a 7c 2a 84 2a 8c                movea.l #713304716,a5
loc_12a1c 00 ee                            .short 0x00ee
loc_12a1e 00 60 00 48                      ori.w #72,(a0)-
loc_12a22 00 4e                            .short 0x004e
loc_12a24 00 ee                            .short 0x00ee
loc_12a26 00 40 00 0a                      ori.w #$A,d0
loc_12a2a 00 6a 0e ee 06 66                ori.w #3822,(a2)(1638)
loc_12a30 0e e0                            .short 0x0ee0
loc_12a32 0e 44                            .short 0x0e44
loc_12a34 00 aa 08 ee 00 cc 00 0e          ori.l #149815500,(a2)(14)
loc_12a3c 00 ac 00 ec 08 ee 06 66          ori.l #15468782,(a4)(1638)
loc_12a44 08 ee 0a aa 0c ca                bset    #-86,(a6)(3274)
loc_12a4a 08 c2 00 ee                      bset    #-18,d2
loc_12a4e 00 00 02 8e                      ori.b #-114,d0
loc_12a52 00 0e                            .short loc_e
loc_12a54 00 0a                            .short loc_a
loc_12a56 00 00 00 ee                      ori.b #-18,d0
loc_12a5a 02 2e 04 44 0a aa                andi.b  #$44,(a6)(2730)
loc_12a60 0e ee                            .short 0x0eee
loc_12a62 02 0e                            .short 0x020e
loc_12a64 0e ee                            .short 0x0eee
loc_12a66 0a aa 00 4a 00 8c 0e ee          eori.l #4849804,(a2)(3822)
loc_12a6e 00 00 00 0e                      ori.b #$E,d0
loc_12a72 0c ae 08 8e 00 00 00 2c          cmpi.l #143523840,(a6)(44)
loc_12a7a 00 0a                            .short loc_a
loc_12a7c 0e ee                            .short 0x0eee
loc_12a7e 00 00 0e 22                      ori.b #34,d0
loc_12a82 06 00 0e ee                      addi.b #-18,d0
loc_12a86 06 66 04 0c                      addi.w  #1036,(a6)-
loc_12a8a 0a 8e                            .short 0x0a8e
loc_12a8c 0e ee                            .short 0x0eee
loc_12a8e 02 22 0a aa                      andi.b  #-86,(a2)-
loc_12a92 06 66

; ======================================================================
                            
Level_Load:                                      ; $12A94
                jsr     loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette address into a5.
                jsr     ($FFFFFBBA).w            ; Load the palettes into the palette buffer.
                bsr.s   loc_12aba
                move.w  #$83,d0
                jsr     ($FFFFFB66).w
                bsr.w   loc_12e00
                bsr.w   loc_12e2e
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_12aba:
                clr.b   ($FFFFD883).w
                bsr.w   loc_1268e
                bsr.w   loc_12824
                move.w  #1,($FFFFFFA8).w
                moveq   #$30,d7
                bsr.w   loc_11774
                subq.b  #1,d0
                lsl.w   #1,d0
                moveq   #-1,d1                   ; Set d1 to $FFFFFFFF.
                lea     loc_1ad92,a0             ; Load RAM address table.
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
loc_12b28 61 00 01 f0                      bsr.w   loc_12d1a
loc_12b2c 61 00 eb d2                      bsr.w   loc_11700
loc_12b30 61 00 f2 d4                      bsr.w   loc_11e06
loc_12b34 61 00 f2 8c                      bsr.w   loc_11dc2
loc_12b38 61 00 f2 9a                      bsr.w   loc_11dd4
loc_12b3c 61 00 f2 a8                      bsr.w   loc_11de6
loc_12b40 61 00 f2 46                      bsr.w   loc_11d88
loc_12b44 4e 75                            rts
loc_12b46 30 38 d2 a0                      move.w  ($FFFFD2A0).w,d0
loc_12b4a 02 40 7f fc                      andi.w  #$7FFC,d0
loc_12b4e 4e bb 00 1a                      jsr     (pc)(loc_12b6a,d0.w)
loc_12b52 08 38 00 07 ff 8f                btst    #7,($FFFFFF8F).w
loc_12b58 67 04                            beq.s   loc_12b5e
loc_12b5a 61 00 03 98                      bsr.w   loc_12ef4
loc_12b5e 61 00 03 30                      bsr.w   loc_12e90
loc_12b62 61 00 e1 ee                      bsr.w   loc_10d52
loc_12b66 4e f8 fb 6c                      jmp     ($FFFFFB6C).w
loc_12b6a 60 00 00 12                      bra.w   loc_12b7e
loc_12b6e 60 00 00 2a                      bra.w   loc_12b9a
loc_12b72 60 00 00 68                      bra.w   loc_12bdc
loc_12b76 60 00 01 22                      bra.w   loc_12c9a
loc_12b7a 60 00 01 5e                      bra.w   loc_12cda
loc_12b7e 0c b8 00 01 c0 00 d2 96          cmpi.l #114688,($FFFFD296).w
loc_12b86 6e 04                            bgt.s   loc_12b8c
loc_12b88 5e b8 d2 96                      addq.l #7,($FFFFD296).w
loc_12b8c 61 00 01 f6                      bsr.w   loc_12d84
loc_12b90 61 00 e6 50                      bsr.w   CheckObjectRAM
loc_12b94 61 00 eb 28                      bsr.w   TimerCounter
loc_12b98 4e 75                            rts
loc_12b9a 08 f8 00 07 d2 a0                bset    #7,($FFFFD2A0).w
loc_12ba0 66 30                            bne.s   loc_12bd2
loc_12ba2 4a 38 d2 a4                      tst.b   ($FFFFD2A4).w
loc_12ba6 67 0a                            beq.s   loc_12bb2
loc_12ba8 61 00 e1 a8                      bsr.w   loc_10d52
loc_12bac 4e b8 fb 6c                      jsr     ($FFFFFB6C).w
loc_12bb0 60 f0                            bra.s   loc_12ba2
loc_12bb2 10 3c 00 82                      move.b  #-126,d0
loc_12bb6 4e b8 fb 66                      jsr     ($FFFFFB66).w
loc_12bba 31 fc 80 00 d8 84                move.w  #-32768,($FFFFD884).w
loc_12bc0 61 00 f2 d4                      bsr.w   loc_11e96
loc_12bc4 42 78 ff 92                      clr.w   ($FFFFFF92).w
loc_12bc8 41 f8 c0 40                      lea     ($FFFFC040,a0
loc_12bcc 31 7c 00 04 00 3c                move.w  #4,$3C(a0)
loc_12bd2 61 00 e6 0e                      bsr.w   CheckObjectRAM
loc_12bd6 61 00 01 6a                      bsr.w   loc_12d42
loc_12bda 4e 75                            rts
loc_12bdc 08 f8 00 07 d2 a0                bset    #7,($FFFFD2A0).w
loc_12be2 66 4a                            bne.s   loc_12c2e
loc_12be4 42 78 ff 92                      clr.w   ($FFFFFF92).w
loc_12be8 7e 30                            moveq   #$30,d7
loc_12bea 61 00 eb 88                      bsr.w   loc_11774
loc_12bee 12 00                            move.b  d0,d1
loc_12bf0 70 00                            moveq   #0,d0
loc_12bf2 10 38 d8 2d                      move.b  ($FFFFD82D).w,d0
loc_12bf6 5a 00                            addq.b  #5,d0
loc_12bf8 7e 30                            moveq   #$30,d7
loc_12bfa 61 00 eb 6e                      bsr.w   loc_1176a
loc_12bfe e6 48                            lsr.w   #3,d0
loc_12c00 b2 3b 00 7a                      cmp.b (pc)(loc_12c7c,d0.w),d1
loc_12c04 66 6e                            bne.s   loc_12c74
loc_12c06 4a 38 d8 8f                      tst.b   ($FFFFD88F).w
loc_12c0a 66 64                            bne.s   loc_12c70
loc_12c0c e5 48                            lsl.w   #2,d0
loc_12c0e 21 fb 00 72 d2 62                move.l  (pc)(loc_12c82,d0.w),($FFFFD262).w
loc_12c14 72 0a                            moveq   #$A,d1
loc_12c16 4e b8 fb 6c                      jsr     ($FFFFFB6C).w
loc_12c1a 51 c9 ff fa                      dbf     d1,loc_12c16
loc_12c1e 41 f8 c0 40                      lea     ($FFFFC040,a0
loc_12c22 30 bc 00 54                      move.w  #84,(a0)
loc_12c26 10 3c 00 e1                      move.b  #-31,d0
loc_12c2a 4e b8 fb 66                      jsr     ($FFFFFB66).w
loc_12c2e 41 f8 ff 92                      lea     ($FFFFFF92).w,a0
loc_12c32 0c 50 00 08                      cmpi.w  #8,(a0)
loc_12c36 66 32                            bne.s   loc_12c6a
loc_12c38 42 50                            clr.w   (a0)
loc_12c3a 31 fc 80 00 d8 84                move.w  #-32768,($FFFFD884).w
loc_12c40 61 00 ea 48                      bsr.w   loc_1168a
loc_12c44 48 e7 80 80                      movem.l d0/a0,-(sp)
loc_12c48 10 3c 00 98                      move.b  #-104,d0
loc_12c4c 61 00 e0 fa                      bsr.w   loc_10d48
loc_12c50 4c df 01 01                      movem.l (sp)+,d0/a0
loc_12c54 52 38 d8 8c                      addq.b  #1,($FFFFd88c
loc_12c58 0c 38 00 0a d8 8c                cmpi.b  #$A,($FFFFd88c
loc_12c5e 66 0a                            bne.s   loc_12c6a
loc_12c60 42 38 d8 8c                      clr.b ($FFFFd88c
loc_12c64 42 38 d8 8d                      clr.b ($FFFFD88D).w
loc_12c68 60 0a                            bra.s   loc_12c74
loc_12c6a 61 00 e5 76                      bsr.w   CheckObjectRAM
loc_12c6e 4e 75                            rts
loc_12c70 42 38 d8 8f                      clr.b ($FFFFD88F).w
loc_12c74 31 fc 00 04 d2 a0                move.w  #4,($FFFFD2A0).w
loc_12c7a 4e 75                            rts
loc_12c7c 02 0a                            .short 0x020a
loc_12c7e 12 1a                            move.b  (a2)+,d1
loc_12c80 22 2a 00 20                      move.l  (a2)(32),d1
loc_12c84 00 00 00 00                      ori.b #0,d0
loc_12c88 10 00                            move.b  d0,d0
loc_12c8a 00 00 50 00                      ori.b #0,d0
loc_12c8e 00 01 00 00                      ori.b #0,d1
loc_12c92 00 05 00 00                      ori.b #0,d5
loc_12c96 00 10 00 00                      ori.b #0,(a0)
loc_12c9a 70 00                            moveq   #0,d0
loc_12c9c 10 38 d8 2d                      move.b  ($FFFFD82D).w,d0
loc_12ca0 5a 00                            addq.b  #5,d0
loc_12ca2 7e 30                            moveq   #$30,d7
loc_12ca4 61 00 ea c4                      bsr.w   loc_1176a
loc_12ca8 e6 48                            lsr.w   #3,d0
loc_12caa e3 48                            lsl.w   #1,d0
loc_12cac 32 38 d8 88                      move.w  ($FFFFD888).w,d1
loc_12cb0 b2 7b 00 1c                      cmp.w (pc)(loc_12cce,d0.w),d1
loc_12cb4 62 0a                            bhi.s   loc_12cc0
loc_12cb6 0c 38 00 01 d8 8d                cmpi.b  #1,($FFFFD88D).w
loc_12cbc 66 02                            bne.s   loc_12cc0
loc_12cbe 60 06                            bra.s   loc_12cc6
loc_12cc0 11 fc 00 01 d8 8f                move.b  #1,($FFFFD88F).w
loc_12cc6 31 fc 00 08 d2 a0                move.w  #8,($FFFFD2A0).w
loc_12ccc 4e 75                            rts
loc_12cce 00 25 00 30                      ori.b #$30,(a5)-
loc_12cd2 00 35 00 40 00 45                ori.b #$40,(a5)(0000000000000045,d0.w)
loc_12cd8 00 50 08 f8                      ori.w #2296,(a0)
loc_12cdc 00 07 d2 a0                      ori.b #-96,d7
loc_12ce0 66 1c                            bne.s   loc_12cfe
loc_12ce2 72 1e                            moveq   #$1E,d1
loc_12ce4 4e b8 fb 6c                      jsr     ($FFFFFB6C).w
loc_12ce8 51 c9 ff fa                      dbf     d1,loc_12ce4
loc_12cec 10 3c 00 84                      move.b  #-124,d0
loc_12cf0 4e b8 fb 66                      jsr     ($FFFFFB66).w
loc_12cf4 31 fc 00 3c c0 00                move.w  #$3C,($FFFFC000).w
loc_12cfa 42 38 d8 86                      clr.b ($FFFFD886).w
loc_12cfe 61 00 e4 d4                      bsr.w   loc_111d4
loc_12d02 32 3c 00 b4                      move.w  #180,d1
loc_12d06 4e b8 fb 6c                      jsr     ($FFFFFB6C).w
loc_12d0a 51 c9 ff fa                      dbf     d1,loc_12d06
loc_12d0e 61 00 ea 74                      bsr.w   loc_11784
loc_12d12 31 fc 00 40 ff c0                move.w  #$40,($FFFFFFC0).w
loc_12d18 4e 75                            rts
loc_12d1a 7e 00                            moveq   #0,d7
loc_12d1c 7c 00                            moveq   #0,d6
loc_12d1e 41 f8 d8 2e                      lea     ($FFFFD82E).w,a0
loc_12d22 1e 10                            move.b  (a0),d7
loc_12d24 1c 28 00 01                      move.b 1(a0),d6
loc_12d28 61 00 e9 4a                      bsr.w   loc_11674
loc_12d2c 31 c7 d2 5e                      move.w  d7,($FFFFd25e
loc_12d30 06 47 00 17                      addi.w  #23,d7
loc_12d34 31 c7 d2 60                      move.w  d7,($FFFFd260
loc_12d38 06 46 00 18                      addi.w  #$18d6
loc_12d3c 31 c6 d2 5c                      move.w  d6,($FFFFD25C).w
loc_12d40 4e 75                            rts
loc_12d42 30 38 ff 92                      move.w  ($FFFFFF92).w,d0
loc_12d46 0c 40 00 fa                      cmpi.w  #250,d0
loc_12d4a 62 0a                            bhi.s   loc_12d56
loc_12d4c 61 00 e9 f2                      bsr.w   loc_11740
loc_12d50 61 00 f1 00                      bsr.w   loc_11e52
loc_12d54 4e 75                            rts
loc_12d56 52 38 d8 2d                      addq.b  #1,($FFFFD82D).w
loc_12d5a 66 04                            bne.s   loc_12d60
loc_12d5c 52 38 d8 2d                      addq.b  #1,($FFFFD82D).w
loc_12d60 10 38 d8 2c                      move.b  ($FFFFD82C).w,d0
loc_12d64 72 01                            moveq   #1,d1
loc_12d66 06 00 00 00                      addi.b #0,d0
loc_12d6a c1 01                            abcd d1,d0
loc_12d6c 11 c0 d8 2c                      move.b  d0,($FFFFd82c
loc_12d70 31 fc 00 18 ff c0                move.w  #$18,($FFFFFFC0).w
loc_12d76 0c 00 00 49                      cmpi.b  #73,d0
loc_12d7a 66 06                            bne.s   loc_12d82
loc_12d7c 31 fc 00 30 ff c0                move.w  #$30,($FFFFFFC0).w
loc_12d82 4e 75                            rts

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

loc_12ee0: 00 03 00 00                      ori.b #0,d3
loc_12ee4 00 08                            .short loc_8
loc_12ee6 00 00 00 16                      ori.b #22,d0
loc_12eea 00 00 00 24                      ori.b #36,d0
loc_12eee 00 00 00 32                      ori.b #50,d0
loc_12ef2 00 00

loc_12EF4:

                jsr     ($FFFFFB36).w
                move.b  #1,($A01C10).l
                jsr     ($FFFFFB3C).w
                move.w  #$58,($FFFFC000).w
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
                bsr.w   loc_12824                ; TODO
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
                move.l  #$40000300,($C00004).l   ; Set VDP to VRAM write, $0000.
                moveq   #$1F,d0                  ; Set to write $20 tiles.
loc_12F8C:
                move.w  #$220D,(a0)              ; Set to map the first 'platform' tile.
                dbf     d0,loc_12f8c             ; Repeat $1F tiles.
                lea     loc_12fcc(pc),a6         ; Set to write BONUS.
                bsr.w   WriteASCIIString                ; Write onto the screen.
                lea     loc_12fd4(pc),a6         ; Set to write STAGE.
                bsr.w   WriteASCIIString                ; Write onto the screen.
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
                dc.b    'STAGE'                  ; Text string.
                dc.b    $00                      ; String terminator.

; ======================================================================

loc_12fdc:
                move.w  ($FFFFD2A6).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_13000(pc,d0.w)
                btst    #7,($FFFFFF8F).w
                beq.s   loc_12ff4
                bsr.w   loc_12ef4
                bsr.w   loc_12e90
                bsr.w   loc_10d52
                jmp     ($FFFFFB6C).w

; ======================================================================

loc_13000: 60 00 00 06                      bra.w   loc_13008
loc_13004 60 00 00 08                      bra.w   loc_1300e
loc_13008 61 00 e1 d8                      bsr.w   CheckObjectRAM
loc_1300c 4e 75                            rts
loc_1300e 08 f8 00 07 d2 a6                bset    #7,($FFFFd2a6
loc_13014 66 1c                            bne.s   loc_13032
loc_13016 4a 38 d2 a4                      tst.b   ($FFFFD2A4).w
loc_1301a 67 0a                            beq.s   loc_13026
loc_1301c 61 00 dd 34                      bsr.w   loc_10d52
loc_13020 4e b8 fb 6c                      jsr     ($FFFFFB6C).w
loc_13024 60 f0                            bra.s   loc_13016
loc_13026 10 3c 00 82                      move.b  #-126,d0
loc_1302a 4e b8 fb 66                      jsr     ($FFFFFB66).w
loc_1302e 61 00 38 ec                      bsr.w   loc_1691c
loc_13032 61 00 e1 ae                      bsr.w   CheckObjectRAM
loc_13036 61 00 00 9c                      bsr.w   loc_130d4
loc_1303a 4e 75                            rts

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
                move.l  (a0,d0.w),($FFFFD82A).w
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

loc_130ee: 52 38 d8 2d                      addq.b  #1,($FFFFD82D).w
loc_130f2 66 04                            bne.s   loc_130f8
loc_130f4 52 38 d8 2d                      addq.b  #1,($FFFFD82D).w
loc_130f8 10 38 d8 2c                      move.b  ($FFFFD82C).w,d0
loc_130fc 72 01                            moveq   #1,d1
loc_130fe 06 00 00 00                      addi.b #0,d0
loc_13102 c1 01                            abcd d1,d0
loc_13104 11 c0 d8 2c                      move.b  d0,($FFFFd82c
loc_13108 31 fc 00 18 ff c0                move.w  #$18,($FFFFFFC0).w
loc_1310e 4e 75                            rts

; ======================================================================

loc_13110:
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                clr.b   ($FFFFD88E).w
                bsr.w   loc_10126
                lea     Pal_Main,a5
                jsr     ($FFFFFBBA).w
                move.w  #$800,($FFFFF7E0).w
                bsr.w   loc_13566
                move.w  #$2700,sr
                moveq   #2,d2
                move.w  #$3BA,d0
                move.w  #$125B,d1
                lea     loc_135e8,a0
                jsr     ($FFFFFB54).w
                move.w  #$2500,sr
                move.b  #$81,d0
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
                bsr.w   loc_10f2e
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
                bsr.w   loc_10fae
                rts

; ======================================================================

CreditsTextPointers:                                                 ; $132E0.
                dc.w    loc_1339E, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_133AA, loc_1339C, loc_1339C
                dc.w    loc_133B8, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_133C6
                dc.w    loc_1339C, loc_1339C, loc_133D4, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C       *
                dc.w    loc_1339C, loc_133DE, loc_1339C, loc_1339C
                dc.w    loc_133EE, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_133FA
                dc.w    loc_1339C, loc_1339C, loc_1340C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1341C, loc_1339C, loc_13426
                dc.w    loc_1339C, loc_1339C, loc_13466, loc_1339C
                dc.w    loc_13470, loc_1339C, loc_1343A, loc_1339C
                dc.w    loc_13454, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_13478
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C, loc_1339C, loc_1339C
                dc.w    loc_1339C, loc_1339C

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
                bsr.w   loc_10cf6
                move.w  #$2500,sr
loc_134ba:
                rts

; ======================================================================

loc_134bc 08 d0 00 07                      bset    #7,(a0)
loc_134c0 66 20                            bne.s   loc_134e2
loc_134c2 08 e8 00 01 00 02                bset    #1,2(a0)
loc_134c8 30 28 00 38                      move.w  $38(a0),d0
loc_134cc 11 7b 00 48 00 3a                move.b  (pc)(loc_13516,d0.w),$3A(a0)
loc_134d2 e3 48                            lsl.w   #1,d0
loc_134d4 31 7b 00 36 00 06                move.w  (pc)(loc_1350c,d0.w),6(a0)
loc_134da e3 48                            lsl.w   #1,d0
loc_134dc 21 7b 00 1a 00 08                move.l  (pc)(loc_134f8,d0.w),8(a0)
loc_134e2 30 28 00 3c                      move.w  $3C(a0),d0
loc_134e6 02 40 7f fc                      andi.w  #$7FFC,d0
loc_134ea 4e bb 00 04                      jsr     (pc)(loc_134f0,d0.w)
loc_134ee 4e 75                            rts
loc_134f0 60 00 00 2a                      bra.w   loc_1351c
loc_134f4 60 00 00 38                      bra.w   loc_1352e
loc_134f8 00 01 44 ac                      ori.b #-84,d1
loc_134fc 00 01 4e 12                      ori.b #18,d1
loc_13500 00 01 4e 22                      ori.b #34,d1
loc_13504 00 01 54 ae                      ori.b #-82,d1
loc_13508 00 01 62 bc                      ori.b #-68,d1
loc_1350c 00 04 00 00                      ori.b #0,d4
loc_13510 00 00 00 08                      ori.b #8,d0
loc_13514 00 10 0d 17                      ori.b #23,(a0)
loc_13518 21 2b 3d 00                      move.l  (a3)(15616),(a0)-
loc_1351c 10 38 d2 9c                      move.b  ($FFFFD29C).w,d0
loc_13520 b0 28 00 3a                      cmp.b $3A(a0),d0
loc_13524 66 06                            bne.s   loc_1352c
loc_13526 31 7c 00 04 00 3c                move.w  #4,$3C(a0)
loc_1352c 4e 75                            rts
loc_1352e 08 e8 00 07 00 3c                bset    #7,$3C(a0)
loc_13534 66 1a                            bne.s   loc_13550
loc_13536 31 7c 00 e4 00 30                move.w  #228,$30(a0)
loc_1353c 31 7c 01 78 00 24                move.w  #376,$24(a0)
loc_13542 21 7c ff ff c0 00 00 2c          move.l  #-16384,$2C(a0)
loc_1354a 08 a8 00 01 00 02                bclr    #1,2(a0)
loc_13550 61 00 db 0a                      bsr.w   loc_1105c
loc_13554 0c 68 00 78 00 24                cmpi.w  #120,$24(a0)
loc_1355a 6e 04                            bgt.s   loc_13560
loc_1355c 61 00 db 92                      bsr.w   loc_110f0
loc_13560 61 00 db c4                      bsr.w   AnimateSprite
loc_13564 4e 75                            rts

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
loc_13598: a3 54                            .short 0xa354
loc_1359a a3 36                            .short 0xa336
loc_1359c a3 74                            .short 0xa374
loc_1359e a3 74                            .short 0xa374
loc_135a0 a3 74                            .short 0xa374
loc_135a2 a3 74                            .short 0xa374
loc_135a4 a3 74                            .short 0xa374
loc_135a6 a3 74                            .short 0xa374
loc_135a8 a3 54                            .short 0xa354
loc_135aa a3 36                            .short 0xa336

; ======================================================================

loc_135ac: 00 03 00 03                      ori.b #3,d3
loc_135b0 00 04 00 02                      ori.b #2,d4
loc_135b4 00 04 00 02                      ori.b #2,d4
loc_135b8 00 04 00 02                      ori.b #2,d4
loc_135bc 00 04 00 02                      ori.b #2,d4
loc_135c0 00 04 00 02                      ori.b #2,d4
loc_135c4 00 04 00 02                      ori.b #2,d4
loc_135c8 00 04 00 02                      ori.b #2,d4
loc_135cc 00 03 00 03                      ori.b #3,d3
loc_135d0 00 04 00 02                      ori.b #2,d4
loc_135d4 e1 32                            roxlb d0,d2
loc_135d6 e4 b2                            roxrl d2,d2
loc_135d8 e6 42                            asrw #3,d2
loc_135da e6 4c                            lsr.w   #3,d4
loc_135dc e6 56                            roxrw #3,d6
loc_135de e6 60                            asrw d3,d0
loc_135e0 e6 6a                            lsr.w d3,d2
loc_135e2 e6 74                            roxrw d3,d4
loc_135e4 e4 46                            asrw #2,d6
loc_135e6 e1 46                            asl.w #8,d6

; ======================================================================

loc_135e8: b1 15                            eor.b d0,(a5)
loc_135ea 07 00                            btst d3,d0
loc_135ec 02 00 b0 15                      andi.b  #21,d0
loc_135f0 00 00 89 12                      ori.b #18,d0
loc_135f4 f5 06                            .short 0xf506
loc_135f6 26 13                            move.l  (a3),d3
loc_135f8 f5 11                            .short 0xf511
loc_135fa db 13                            add.b d5,(a3)
loc_135fc f5 1c                            .short 0xf51c
loc_135fe 33 14                            move.w  (a4),(a1)-
loc_13600 e9 0e                            lsl.b #4,d6
loc_13602 21 15                            move.l  (a5),(a0)-
loc_13604 f5 10                            .short 0xf510
loc_13606 7d 12                            .short 0x7d12
loc_13608 f5 08                            .short 0xf508
loc_1360a 80 04                            or.b d4,d0
loc_1360c f0 18                            .short 0xf018
loc_1360e 01 03                            btst d0,d3
loc_13610 03 ef 00 f6                      bset d1,(sp)(246)
loc_13614 8f 12                            or.b d7,(a2)
loc_13616 ea 61                            asrw d5,d1
loc_13618 02 e6                            .short 0x02e6
loc_1361a ef 00                            aslb #7,d0
loc_1361c 80 60                            or.w (a0)-,d0
loc_1361e f8 d7                            .short 0xf8d7
loc_13620 12 c5                            move.b  d5,(a1)+
loc_13622 c6 c7                            mulu.w d7,d3
loc_13624 f8 d7                            .short 0xf8d7
loc_13626 12 c3                            move.b  d3,(a1)+
loc_13628 c4 c6                            mulu.w d6,d2
loc_1362a c8 c9                            .short 0xc8c9
loc_1362c c8 c7                            mulu.w d7,d4
loc_1362e c8 80                            and.l   d0,d4
loc_13630 bf 80                            eor.l d7,d0
loc_13632 c1 80                            .short 0xc180
loc_13634 c6 c5                            mulu.w d5,d3
loc_13636 c6 80                            and.l   d0,d3
loc_13638 c1 c4                            mulsw d4,d0
loc_1363a c3 bf                            .short 0xc3bf
loc_1363c c1 c3                            mulsw d3,d0
loc_1363e c6 80                            and.l   d0,d3
loc_13640 cb c9                            .short 0xcbc9
loc_13642 f8 0e                            .short 0xf80e
loc_13644 13 c3 0c c1 c3 c4                move.b  d3,0x0cc1c3c4
loc_1364a c6 80                            and.l   d0,d3
loc_1364c cb c9                            .short 0xcbc9
loc_1364e f8 0e                            .short 0xf80e
loc_13650 13 c6 0c c8 c9 cb                move.b  d6,0x0cc8c9cb
loc_13656 cd c9                            .short 0xcdc9
loc_13658 cd d0                            mulsw (a0),d6
loc_1365a cf cb                            .short 0xcfcb
loc_1365c cd cf                            .short 0xcdcf
loc_1365e d2 80                            add.l d0,d1
loc_13660 24 f6 91 12 bf 0c                move.l  (a6,a1.w)@(ffffffffffffbf0c),(a2)+
loc_13666 80 c8                            .short 0x80c8
loc_13668 30 c7                            move.w  d7,(a0)+
loc_1366a 0c c8                            .short 0x0cc8
loc_1366c c7 c8                            .short 0xc7c8
loc_1366e 80 48                            .short 0x8048
loc_13670 bf 0c                            cmpmb (a4)+,(sp)+
loc_13672 80 c8                            .short 0x80c8
loc_13674 30 c7                            move.w  d7,(a0)+
loc_13676 0c c8                            .short 0x0cc8
loc_13678 c4 c1                            mulu.w d1,d2
loc_1367a 80 48                            .short 0x8048
loc_1367c c3 0c                            abcd (a4)-,(a1)-
loc_1367e c4 c6                            mulu.w d6,d2
loc_13680 c3 bf                            .short 0xc3bf
loc_13682 80 cb                            .short 0x80cb
loc_13684 c9 c8                            .short 0xc9c8
loc_13686 c9 cb                            .short 0xc9cb
loc_13688 c8 c4                            mulu.w d4,d4
loc_1368a 80 c6                            divu.w d6,d0
loc_1368c c8 c9                            .short 0xc8c9
loc_1368e 80 c1                            divu.w d1,d0
loc_13690 80 c4                            divu.w d4,d0
loc_13692 80 c3                            divu.w d3,d0
loc_13694 c4 c6                            mulu.w d6,d2
loc_13696 bf c1                            cmpal d1,sp
loc_13698 c3 c4                            mulsw d4,d1
loc_1369a f9 c8                            .short 0xf9c8
loc_1369c c7 c8                            .short 0xc7c8
loc_1369e c9 cb                            .short 0xc9cb
loc_136a0 80 c4                            divu.w d4,d0
loc_136a2 80 c1                            divu.w d1,d0
loc_136a4 80 cd                            .short 0x80cd
loc_136a6 cc cd                            .short 0xcccd
loc_136a8 80 24                            or.b (a4)-,d0
loc_136aa bf 0c                            cmpmb (a4)+,(sp)+
loc_136ac 80 cb                            .short 0x80cb
loc_136ae ca cb                            .short 0xcacb
loc_136b0 80 24                            or.b (a4)-,d0
loc_136b2 f9 ef                            .short 0xf9ef
loc_136b4 01 b3 0c 80                      bclr d0,(a3)(ffffffffffffff80,d0:l:4)
loc_136b8 b3 80                            eor.l d1,d0
loc_136ba b3 80                            eor.l d1,d0
loc_136bc b3 80                            eor.l d1,d0
loc_136be ac 18                            .short 0xac18
loc_136c0 b3 06                            eor.b d1,d6
loc_136c2 80 b3 80 ac                      orl (a3)(ffffffffffffffac,a0.w),d0
loc_136c6 0c 80 b3 18 ac b3                cmpi.l #-1290228557,d0
loc_136cc 06 80 b3 80 ac 0c                addi.l  #-1283412980,d0
loc_136d2 80 b3 18 e8                      orl (a3)(ffffffffffffffe8,d1:l),d0
loc_136d6 06 ac b3 0c b3 ac 18 b3          addi.l  #-1291013204,(a4)(6323)
loc_136de ac b5                            .short 0xacb5
loc_136e0 0c b5 ac 18 b5 ae b3 0c          cmpi.l #-1407666770,(a5)@0,a3.w:2)
loc_136e8 b3 ae 18 b3                      eor.l d1,(a6)(6323)
loc_136ec ac b3                            .short 0xacb3
loc_136ee 0c b3 ac 18 b3 b5 b1 0c          cmpi.l #-1407667275,(a3)@0,a3.w)
loc_136f6 b1 b5 18 b1                      eor.l d0,(a5)(ffffffffffffffb1,d1:l)
loc_136fa b3 ae 0c ae                      eor.l d1,(a6)(3246)
loc_136fe b3 18                            eor.b d1,(a0)+
loc_13700 b3 f7 00 02                      cmpal (sp)2,d0.w),a1
loc_13704 31 13                            move.w  (a3),(a0)-
loc_13706 ac 0c                            .short 0xac0c
loc_13708 b8 ac b8 ac                      cmp.l (a4)(-18260),d4
loc_1370c b8 ac b8 b1                      cmp.l (a4)(-18255),d4
loc_13710 bd b1 bd b1 bd b1 bd b3          eor.l d6,@(ffffffffbdb1bdb3,a3:l:4)@0)
loc_13718 bf b3 bf b3 bf b3 bf b0 bb b0 bc b0  eor.l d7,@(ffffffffbfb3bfb0,a3:l:8)@(ffffffffbbb0bcb0)
loc_13724 bc b0 bc f8                      cmp.l (a0)(fffffffffffffff8,a3:l:4),d6
loc_13728 be 13                            cmp.b (a3),d7
loc_1372a b3 ba                            .short 0xb3ba
loc_1372c b3 ba                            .short 0xb3ba
loc_1372e ac b8                            .short 0xacb8
loc_13730 ac b8                            .short 0xacb8
loc_13732 b0 b1 b3 b8 f8 be 13 ae          cmp.l @(fffffffff8be13ae,a3.w:2),d0
loc_1373a ba ae ba b3                      cmp.l (a6)(-17741),d5
loc_1373e 0c ae 06 ae b3 0c ae b3          cmpi.l #112112396,(a6)(-20813)
loc_13746 18 b3 f6 31                      move.b  (a3)(0000000000000031,sp.w:8),(a4)
loc_1374a 13 b1 18 b5 06 c1                move.b  (a1)(ffffffffffffffb5,d1:l),(a1)(ffffffffffffffc1,d0.w:8)
loc_13750 b4 c0                            cmpa.w d0,a2
loc_13752 b5 18                            eor.b d2,(a0)+
loc_13754 b5 0c                            cmpmb (a4)+,(a2)+
loc_13756 b4 b3 18 b3                      cmp.l (a3)(ffffffffffffffb3,d1:l),d2
loc_1375a 06 bf                            .short 0x06bf
loc_1375c b2 be                            .short 0xb2be
loc_1375e b3 18                            eor.b d1,(a0)+
loc_13760 b3 0c                            cmpmb (a4)+,(a1)+
loc_13762 b8 ae ba ae                      cmp.l (a6)(-17746),d4
loc_13766 ba f9 ef 03 b3 60                cmpa.w 0xef03b360,a5
loc_1376c f8 0b                            .short 0xf80b
loc_1376e 14 b5 b3 b3 f8 0b 14 b1 b3 b3 ac 3c  move.b @(fffffffff80b14b1,a3.w:2)@(ffffffffb3b3ac3c),(a2)
loc_1377a 0c b0 b3 b1 30 30 b3 b3 f8 26 14 ae 30 b3 f8 26  cmpi.l #-1280233424,@(fffffffff82614ae,a3.w:2)@(0000000030b3f826)
loc_1378a 14 ae 3c 0c                      move.b  (a6)(15372),(a2)
loc_1378e b1 b5 b3 18                      eor.l d0,(a5,a3.w:2)
loc_13792 18 18                            move.b  (a0)+,d4
loc_13794 18 f6 df 13 ac 30 b3 ac          move.b  (a6,a5:l:8)@(ffffffffac30b3ac),(a4)+
loc_1379c 24 0c                            move.l  a4,d2
loc_1379e ae b0                            .short 0xaeb0
loc_137a0 b3 18                            eor.b d1,(a0)+
loc_137a2 ac 30                            .short 0xac30
loc_137a4 b3 b1 24 0c                      eor.l d1,(a1)c,d2.w:4)
loc_137a8 b3 b5 b8 18                      eor.l d1,(a5)(0000000000000018,a3:l)
loc_137ac b3 30 30 ac                      eor.b d1,(a0)(ffffffffffffffac,d3.w)
loc_137b0 ac b1                            .short 0xacb1
loc_137b2 f9 ac                            .short 0xf9ac
loc_137b4 3c ae 0c b0                      move.w  (a6)(3248),(a6)
loc_137b8 b3 b1 48 18                      eor.l d1,(a1)(0000000000000018,d4:l)
loc_137bc ac 48                            .short 0xac48
loc_137be 18 f9 ef 00 e4 02                move.b 0xef00e402,(a4)+
loc_137c4 01 03                            btst d0,d3
loc_137c6 03 03                            btst d1,d3
loc_137c8 cf 06                            abcd d6,d7
loc_137ca cb cd                            .short 0xcbcd
loc_137cc cf d0                            mulsw (a0),d7
loc_137ce cb cf                            .short 0xcbcf
loc_137d0 d0 d2                            adda.w (a2),a0
loc_137d2 cf d0                            mulsw (a0),d7
loc_137d4 d2 d4                            adda.w (a4),a1
loc_137d6 d3 d4                            adda.l (a4),a1
loc_137d8 d5 80                            addxl d0,d2
loc_137da 0c d4                            .short 0x0cd4
loc_137dc 06 d5                            .short 0x06d5
loc_137de d7 80                            addxl d0,d3
loc_137e0 d4 80                            add.l d0,d2
loc_137e2 dc 80                            add.l d0,d6
loc_137e4 d4 80                            add.l d0,d2
loc_137e6 d7 80                            addxl d0,d3
loc_137e8 d4 80                            add.l d0,d2
loc_137ea f7 01                            .short 0xf701
loc_137ec 03 4c 14 f8                      movepl (a4)(5368),d1
loc_137f0 dc 14                            add.b (a4),d6
loc_137f2 80 de                            divu.w (a6)+,d0
loc_137f4 80 d7                            divu.w (sp),d0
loc_137f6 80 db                            divu.w (a3)+,d0
loc_137f8 80 d7                            divu.w (sp),d0
loc_137fa 80 80                            orl d0,d0
loc_137fc 0c d4                            .short 0x0cd4
loc_137fe 06 d5                            .short 0x06d5
loc_13800 d7 80                            addxl d0,d3
loc_13802 d4 80                            add.l d0,d2
loc_13804 dc 80                            add.l d0,d6
loc_13806 d4 80                            add.l d0,d2
loc_13808 d7 80                            addxl d0,d3
loc_1380a d4 80                            add.l d0,d2
loc_1380c f8 dc                            .short 0xf8dc
loc_1380e 14 80                            move.b  d0,(a2)
loc_13810 12 d7                            move.b  (sp),(a1)+
loc_13812 06 d6                            .short 0x06d6
loc_13814 d7 d9                            adda.l (a1)+,a3
loc_13816 db d7                            adda.l (sp),a5
loc_13818 f7 00                            .short 0xf700
loc_1381a 02 4c                            .short 0x024c
loc_1381c 14 80                            move.b  d0,(a2)
loc_1381e 0c d4                            .short 0x0cd4
loc_13820 d4 cb                            adda.w a3,a2
loc_13822 80 d4                            divu.w (a4),d0
loc_13824 d4 cb                            adda.w a3,a2
loc_13826 80 d5                            divu.w (a5),d0
loc_13828 d5 cd                            adda.l a5,a2
loc_1382a 80 d5                            divu.w (a5),d0
loc_1382c d5 cd                            adda.l a5,a2
loc_1382e 80 d7                            divu.w (sp),d0
loc_13830 d7 d2                            adda.l (a2),a3
loc_13832 80 d7                            divu.w (sp),d0
loc_13834 d7 d2                            adda.l (a2),a3
loc_13836 80 d7                            divu.w (sp),d0
loc_13838 d7 d0                            adda.l (a0),a3
loc_1383a 80 d7                            divu.w (sp),d0
loc_1383c d7 d0                            adda.l (a0),a3
loc_1383e f8 f6                            .short 0xf8f6
loc_13840 14 d4                            move.b  (a4),(a2)+
loc_13842 0c d3                            .short 0x0cd3
loc_13844 d4 d5                            adda.w (a5),a2
loc_13846 d7 80                            addxl d0,d3
loc_13848 d0 03                            add.b d3,d0
loc_1384a d1 d2                            adda.l (a2),a0
loc_1384c d3 d4                            adda.l (a4),a1
loc_1384e d5 d6                            adda.l (a6),a2
loc_13850 d7 f8 f6 14                      adda.l ($FFFFf614,a3
loc_13854 de de                            adda.w (a6)+,sp
loc_13856 de 80                            add.l d0,d7
loc_13858 d5 03                            addxb d3,d2
loc_1385a d7 d8                            adda.l (a0)+,a3
loc_1385c d9 da                            adda.l (a2)+,a4
loc_1385e db dc                            adda.l (a4)+,a5
loc_13860 dd de                            adda.l (a6)+,a6
loc_13862 0c 80 df 18 f6 4c                cmpi.l #-552012212,d0
loc_13868 14 80                            move.b  d0,(a2)
loc_1386a 0c d5                            .short 0x0cd5
loc_1386c 06 d7                            .short 0x06d7
loc_1386e d9 80                            addxl d0,d4
loc_13870 d5 80                            addxl d0,d2
loc_13872 dc 80                            add.l d0,d6
loc_13874 d5 80                            addxl d0,d2
loc_13876 d9 80                            addxl d0,d4
loc_13878 d5 80                            addxl d0,d2
loc_1387a 80 0c                            .short 0x800c
loc_1387c d7 06                            addxb d6,d3
loc_1387e d9 db                            adda.l (a3)+,a4
loc_13880 80 d7                            divu.w (sp),d0
loc_13882 f9 d9                            .short 0xf9d9
loc_13884 0c 80 d9 d8 d0 06                cmpi.l #-640102394,d0
loc_1388a d5 d9                            adda.l (a1)+,a2
loc_1388c dc d9                            adda.w (a1)+,a6
loc_1388e 0c d8                            .short 0x0cd8
loc_13890 d7 80                            addxl d0,d3
loc_13892 d7 d6                            adda.l (a6),a3
loc_13894 d0 06                            add.b d6,d0
loc_13896 d4 d7                            adda.w (sp),a2
loc_13898 dc d7                            adda.w (sp),a6
loc_1389a 0c dc                            .short 0x0cdc
loc_1389c de 06                            add.b d6,d7
loc_1389e de de                            adda.w (a6)+,sp
loc_138a0 80 de                            divu.w (a6)+,d0
loc_138a2 de de                            adda.w (a6)+,sp
loc_138a4 80 de                            divu.w (a6)+,d0
loc_138a6 de de                            adda.w (a6)+,sp
loc_138a8 80 de                            divu.w (a6)+,d0
loc_138aa de de                            adda.w (a6)+,sp
loc_138ac 80 f9 ef 01 80 60                divu.w 0xef018060,d0
loc_138b2 80 60                            or.w (a0)-,d0
loc_138b4 80 80                            orl d0,d0
loc_138b6 80 80                            orl d0,d0
loc_138b8 80 80                            orl d0,d0
loc_138ba 80 c8                            .short 0x80c8
loc_138bc 48 c7                            ext.l d7
loc_138be 0c c8                            .short 0x0cc8
loc_138c0 c7 c8                            .short 0xc7c8
loc_138c2 d3 d4                            adda.l (a4),a1
loc_138c4 d3 d4                            adda.l (a4),a1
loc_138c6 bf 04                            eor.b d7,d4
loc_138c8 c1 c3                            mulsw d3,d0
loc_138ca c4 c5                            mulu.w d5,d2
loc_138cc c6 c8                            .short 0xc6c8
loc_138ce 48 c7                            ext.l d7
loc_138d0 0c c8                            .short 0x0cc8
loc_138d2 c4 c1                            mulu.w d1,d2
loc_138d4 d3 d4                            adda.l (a4),a1
loc_138d6 d0 cd                            adda.w a5,a0
loc_138d8 bd 04                            eor.b d6,d4
loc_138da bf c1                            cmpal d1,sp
loc_138dc c3 c4                            mulsw d4,d1
loc_138de c6 cb                            .short 0xc6cb
loc_138e0 0c 80 cb 80 c9 80                cmpi.l #-880752256,d0
loc_138e6 cb 80                            .short 0xcb80
loc_138e8 c8 80                            and.l   d0,d4
loc_138ea c4 80                            and.l   d0,d2
loc_138ec c8 80                            and.l   d0,d4
loc_138ee c4 80                            and.l   d0,d2
loc_138f0 c9 80                            .short 0xc980
loc_138f2 c1 80                            .short 0xc180
loc_138f4 c4 80                            and.l   d0,d2
loc_138f6 c9 80                            .short 0xc980
loc_138f8 cb 80                            .short 0xcb80
loc_138fa cb 80                            .short 0xcb80
loc_138fc cb 80                            .short 0xcb80
loc_138fe cb 80                            .short 0xcb80
loc_13900 c4 0c                            .short 0xc40c
loc_13902 c6 c4                            mulu.w d4,d3
loc_13904 c3 c4                            mulsw d4,d1
loc_13906 80 bf                            .short 0x80bf
loc_13908 80 bd                            .short 0x80bd
loc_1390a 80 c6                            divu.w d6,d0
loc_1390c c5 c6                            mulsw d6,d2
loc_1390e 80 bd                            .short 0x80bd
loc_13910 c1 bf                            .short 0xc1bf
loc_13912 ba bd                            .short 0xbabd
loc_13914 bf c3                            cmpal d3,sp
loc_13916 80 c6                            divu.w d6,d0
loc_13918 c3 f8 a4 15                      mulsw ($FFFFa415,d1
loc_1391c bf 0c                            cmpmb (a4)+,(sp)+
loc_1391e bd bf                            .short 0xbdbf
loc_13920 c1 c3                            mulsw d3,d0
loc_13922 80 c6                            divu.w d6,d0
loc_13924 c3 f8 a4 15                      mulsw ($FFFFa415,d1
loc_13928 80 60                            or.w (a0)-,d0
loc_1392a 80 48                            .short 0x8048
loc_1392c c3 18                            and.b d1,(a0)+
loc_1392e f6 25                            .short 0xf625
loc_13930 15 c4                            .short 0x15c4
loc_13932 c3 c4                            mulsw d4,d1
loc_13934 c6 c8                            .short 0xc6c8
loc_13936 80 bf                            .short 0x80bf
loc_13938 80 80                            orl d0,d0
loc_1393a 60 80                            bra.s   loc_138bc
loc_1393c f9 f2                            .short 0xf9f2
loc_1393e 2c 72 72 32                      movea.l (a2)(0000000000000032,d7.w:2),a6
loc_13942 32 1f                            move.w  (sp)+,d1
loc_13944 11 1f                            move.b  (sp)+,(a0)-
loc_13946 0f 00                            btst d7,d0
loc_13948 0e 00                            .short 0x0e00
loc_1394a 0f 00                            btst d7,d0
loc_1394c 09 00                            btst d4,d0
loc_1394e 09 06                            btst d4,d6
loc_13950 36 06                            move.w  d6,d3
loc_13952 36 15                            move.w  (a5),d3
loc_13954 80 14                            or.b (a4),d0
loc_13956 80 38 3a 31                      or.b loc_3a31,d0
loc_1395a 31 31 1f 1f 5f 5f 12 0e          move.w  (a1)@(000000005f5f120e,d1:l:8),(a0)-
loc_13962 0a 0a                            .short 0x0a0a
loc_13964 00 04 04 03                      ori.b #3,d4
loc_13968 2f 2f 2f 2f                      move.l  (sp)(12079),-(sp)
loc_1396c 24 2d 0e 80                      move.l  (a5)(3712),d2
loc_13970 37 3a 31 31                      move.w  (pc)(loc_16aa3),(a3)-
loc_13974 31 1f                            move.w  (sp)+,(a0)-
loc_13976 1f 5f 5f 12                      move.b  (sp)+,(sp)(24338)
loc_1397a 0e 0a                            .short 0x0e0a
loc_1397c 0a 00 04 04                      eori.b #4,d0
loc_13980 03 2f 2f 2f                      btst d1,(sp)(12079)
loc_13984 2f 24                            move.l  (a4)-,-(sp)
loc_13986 2d 0e                            move.l  a6,(a6)-
loc_13988 80 3c 32 33                      or.b #51,d0
loc_1398c 72 43                            moveq   #67,d1
loc_1398e 1f 18                            move.b  (a0)+,-(sp)
loc_13990 1f 5e 07 1f                      move.b  (a6)+,(sp)(1823)
loc_13994 07 1f                            btst d3,(sp)+
loc_13996 00 00 00 00                      ori.b #0,d0
loc_1399a 1f 0f                            .short 0x1f0f
loc_1399c 1f 1f                            move.b  (sp)+,-(sp)
loc_1399e 1b 80 0c 80                      move.b  d0,(a5)(ffffffffffffff80,d0:l:4)

; ======================================================================

loc_139a2:
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
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
                dc.w    loc_13A82
                dc.w    loc_13B82
                dc.w    loc_13C52
                dc.w    loc_13D70

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

loc_13a82: 00 12 08 01                      ori.b #1,(a2)
loc_13a86 0a 15 4a 12                      eori.b #18,(a5)
loc_13a8a 42 01                            clr.b d1
loc_13a8c 44 02                            negb d2
loc_13a8e 04 0e                            .short 0x040e
loc_13a90 00 1c 40 0a                      ori.b #$A,(a4)+
loc_13a94 00 0a                            .short loc_a
loc_13a96 04 0d                            .short 0x040d
loc_13a98 00 0c                            .short loc_c
loc_13a9a 04 04 05 0e                      subi.b #$E,d4
loc_13a9e 04 05 00 02                      subi.b #2,d5
loc_13aa2 0a 14 08 01                      eori.b #1,(a4)
loc_13aa6 00 27 08 01                      ori.b #1,-(sp)
loc_13aaa 0a 16 04 0d                      eori.b #$D,(a6)
loc_13aae 00 1b 08 01                      ori.b #1,(a3)+
loc_13ab2 0a 0b                            .short 0x0a0b
loc_13ab4 4a 06                            tst.b   d6
loc_13ab6 42 01                            clr.b d1
loc_13ab8 44 0a                            .short 0x440a
loc_13aba 04 11 00 22                      subi.b #34,(a1)
loc_13abe 08 01 0a 07                      btst    #7,d1
loc_13ac2 08 01 00 29                      btst    #41,d1
loc_13ac6 04 06 00 0f                      subi.b #$F,d6
loc_13aca 40 18                            negxb (a0)+
loc_13acc 00 0f                            .short loc_f
loc_13ace 04 0b                            .short 0x040b
loc_13ad0 44 0d                            .short 0x440d
loc_13ad2 04 01 00 08                      subi.b #8,d1
loc_13ad6 0a 0d                            .short 0x0a0d
loc_13ad8 08 01 00 06                      btst    #6,d1
loc_13adc 04 2e 44 0b 04 01                subi.b #11,(a6)(1025)
loc_13ae2 00 2a 0a 0c 00 0d                ori.b #$C,(a2)(13)
loc_13ae8 04 18 00 33                      subi.b #51,(a0)+
loc_13aec 04 2a 44 06 40 04                subi.b #6,(a2)(16388)
loc_13af2 0a 13 08 01                      eori.b #1,(a3)
loc_13af6 00 3f                            .short 0x003f
loc_13af8 08 01 0a 0b                      btst    #11,d1
loc_13afc 08 03 0a 01                      btst    #1,d3
loc_13b00 02 01 04 09                      andi.b  #9,d1
loc_13b04 00 6b 0a 02 4a 08                ori.w #2562,(a3)(18952)
loc_13b0a 0a 25 4a 04                      eori.b #4,(a5)-
loc_13b0e 42 01                            clr.b d1
loc_13b10 40 01                            negxb d1
loc_13b12 44 17                            negb (sp)
loc_13b14 40 03                            negxb d3
loc_13b16 00 0a                            .short loc_a
loc_13b18 04 0f                            .short 0x040f
loc_13b1a 44 09                            .short 0x4409
loc_13b1c 04 15 00 0d                      subi.b #$D,(a5)
loc_13b20 0a 1b 08 01                      eori.b #1,(a3)+
loc_13b24 00 08                            .short loc_8
loc_13b26 08 01 4a 0c                      btst    #$C,d1
loc_13b2a 0a 27 02 02                      eori.b #2,-(sp)
loc_13b2e 04 0e                            .short 0x040e
loc_13b30 00 25 40 09                      ori.b #9,(a5)-
loc_13b34 44 03                            negb d3
loc_13b36 45 04                            chkl d4,d2
loc_13b38 44 03                            negb d3
loc_13b3a 00 1c 08 01                      ori.b #1,(a4)+
loc_13b3e 0a 07 4a 07                      eori.b #7,d7
loc_13b42 0a 03 02 01                      eori.b #1,d3
loc_13b46 04 01 05 10                      subi.b #$10,d1
loc_13b4a 04 02 00 0e                      subi.b #$E,d2
loc_13b4e 08 01 0a 13                      btst    #$13,d1
loc_13b52 4a 06                            tst.b   d6
loc_13b54 0a 02 02 01                      eori.b #1,d2
loc_13b58 04 15 00 07                      subi.b #7,(a5)
loc_13b5c 08 01 0a 38                      btst    #$38,d1
loc_13b60 02 01 04 3c                      andi.b  #$3C,d1
loc_13b64 44 07                            negb d7
loc_13b66 04 16 00 23                      subi.b #35,(a6)
loc_13b6a 0a 2c 06 01 04 0a                eori.b #1,(a4)(1034)
loc_13b70 00 38 00 00 00 00                ori.b #0,loc_000
loc_13b76 00 00 00 00                      ori.b #0,d0
loc_13b7a 00 00 00 00                      ori.b #0,d0
loc_13b7e 00 00 00 00                      ori.b #0,d0


loc_13b82: 00 12 08 01                      ori.b #1,(a2)
loc_13b86 0a 09                            .short 0x0a09
loc_13b88 4a 11                            tst.b   (a1)
loc_13b8a 0a 17 00 14                      eori.b #$14,(sp)
loc_13b8e 40 04                            negxb d4
loc_13b90 4a 0b                            .short 0x4a0b
loc_13b92 0a 5a 00 1c                      eori.w #$1C,(a2)+
loc_13b96 0a 0c                            .short 0x0a0c
loc_13b98 00 09                            .short loc_9
loc_13b9a 04 03 05 02                      subi.b #2,d3
loc_13b9e 04 09                            .short 0x0409
loc_13ba0 00 1e 04 07                      ori.b #7,(a6)+
loc_13ba4 00 03 08 01                      ori.b #1,d3
loc_13ba8 0a 0f                            .short 0x0a0f
loc_13baa 06 02 04 0d                      addi.b #$D,d2
loc_13bae 44 05                            negb d5
loc_13bb0 40 0b                            .short 0x400b
loc_13bb2 00 23 04 08                      ori.b #8,(a3)-
loc_13bb6 00 09                            .short loc_9
loc_13bb8 04 0e                            .short 0x040e
loc_13bba 44 1f                            negb (sp)+
loc_13bbc 00 0d                            .short loc_d
loc_13bbe 04 10 44 0f                      subi.b #$F,(a0)
loc_13bc2 04 1c 00 17                      subi.b #23,(a4)+
loc_13bc6 0a 1b 08 02                      eori.b #2,(a3)+
loc_13bca 00 46 04 10                      ori.w #1040,d6
loc_13bce 00 2b 04 0e 40 0c                ori.b #$E,(a3)(16396)
loc_13bd4 00 1f 0a 0b                      ori.b #11,(sp)+
loc_13bd8 4a 12                            tst.b   (a2)
loc_13bda 0a 35 4a 17 48 02                eori.b #23,(a5)2,d4:l)
loc_13be0 40 01                            negxb d1
loc_13be2 00 03 04 10                      ori.b #$10,d3
loc_13be6 00 21 04 04                      ori.b #4,(a1)-
loc_13bea 05 07                            btst d2,d7
loc_13bec 45 08                            .short 0x4508
loc_13bee 44 03                            negb d3
loc_13bf0 40 08                            .short 0x4008
loc_13bf2 48 01                            nbcd d1
loc_13bf4 4a 0d                            .short 0x4a0d
loc_13bf6 0a 05 00 0b                      eori.b #11,d5
loc_13bfa 04 0a                            .short 0x040a
loc_13bfc 00 07 04 08                      ori.b #8,d7
loc_13c00 00 33 04 20 00 03                ori.b #$20,(a3)3,d0.w)
loc_13c06 0a 12 00 0a                      eori.b #$A,(a2)
loc_13c0a 04 0a                            .short 0x040a
loc_13c0c 05 01                            btst d2,d1
loc_13c0e 00 01 0a 10                      ori.b #$10,d1
loc_13c12 02 01 00 17                      andi.b  #23,d1
loc_13c16 0a 17 08 01                      eori.b #1,(sp)
loc_13c1a 00 04 08 02                      ori.b #2,d4
loc_13c1e 0a 07 4a 0d                      eori.b #$D,d7
loc_13c22 42 01                            clr.b d1
loc_13c24 44 07                            negb d7
loc_13c26 45 02                            chkl d2,d2
loc_13c28 44 03                            negb d3
loc_13c2a 40 01                            negxb d1
loc_13c2c 00 19 08 01                      ori.b #1,(a1)+
loc_13c30 0a 07 02 01                      eori.b #1,d7
loc_13c34 04 06 44 05                      subi.b #5,d6
loc_13c38 40 03                            negxb d3
loc_13c3a 00 08                            .short loc_8
loc_13c3c 0a 1e 00 10                      eori.b #$10,(a6)+
loc_13c40 0a 13 08 01                      eori.b #1,(a3)
loc_13c44 00 1a 04 14                      ori.b #$14,(a2)+
loc_13c48 00 1f 04 03                      ori.b #3,(sp)+
loc_13c4c 05 04                            btst d2,d4
loc_13c4e 04 0c                            .short 0x040c
loc_13c50 00 43

loc_13C52:
04 2c                      ori.w #1068,d3
loc_13c54 24 0c                            move.l  a4,d2
loc_13c56 04 08                            .short 0x0408
loc_13c58 0a 0e                            .short 0x0a0e
loc_13c5a 00 0c                            .short loc_c
loc_13c5c 04 1b 24 09                      subi.b #9,(a3)+
loc_13c60 20 01                            move.l  d1,d0
loc_13c62 08 03 0a 18                      btst    #$18d3
loc_13c66 08 02 00 0f                      btst    #$F,d2
loc_13c6a 05 15                            btst d2,(a5)
loc_13c6c 25 0b                            move.l  a3,(a2)-
loc_13c6e 05 22                            btst d2,(a2)-
loc_13c70 04 01 00 08                      subi.b #8,d1
loc_13c74 08 13 00 12                      btst    #18,(a3)
loc_13c78 04 09                            .short 0x0409
loc_13c7a 00 0a                            .short loc_a
loc_13c7c 20 0b                            move.l  a3,d0
loc_13c7e 00 08                            .short loc_8
loc_13c80 08 0c                            .short 0x080c
loc_13c82 00 12 08 14                      ori.b #$14,(a2)
loc_13c86 00 07 04 09                      ori.b #9,d7
loc_13c8a 05 10                            btst d2,(a0)
loc_13c8c 04 02 00 0c                      subi.b #$C,d2
loc_13c90 08 08                            .short 0x0808
loc_13c92 00 20 08 12                      ori.b #18,(a0)-
loc_13c96 00 0a                            .short loc_a
loc_13c98 04 03 05 09                      subi.b #9,d3
loc_13c9c 04 03 00 1c                      subi.b #$1C,d3
loc_13ca0 08 16 00 1a                      btst    #26,(a6)
loc_13ca4 08 0e                            .short 0x080e
loc_13ca6 00 0a                            .short loc_a
loc_13ca8 04 0a                            .short 0x040a
loc_13caa 00 26 20 0c                      ori.b #$C,(a6)-
loc_13cae 00 04 04 03                      ori.b #3,d4
loc_13cb2 05 08 04 03                      movepw (a0)(1027),d2
loc_13cb6 00 0c                            .short loc_c
loc_13cb8 08 0c                            .short 0x080c
loc_13cba 00 14 04 02                      ori.b #2,(a4)
loc_13cbe 05 22                            btst d2,(a2)-
loc_13cc0 04 03 06 01                      subi.b #1,d3
loc_13cc4 02 02 0a 0d                      andi.b  #$D,d2
loc_13cc8 08 01 00 11                      btst    #$11,d1
loc_13ccc 04 03 05 05                      subi.b #5,d3
loc_13cd0 04 02 00 08                      subi.b #8,d2
loc_13cd4 08 0c                            .short 0x080c
loc_13cd6 00 1f 08 60                      ori.b #$60,(sp)+
loc_13cda 00 09                            .short loc_9
loc_13cdc 04 03 05 04                      subi.b #4,d3
loc_13ce0 04 02 00 1e                      subi.b #$1E,d2
loc_13ce4 20 01                            move.l  d1,d0
loc_13ce6 28 09                            move.l  a1,d4
loc_13ce8 08 13 09 01                      btst    #1,(a3)
loc_13cec 05 0f 00 02                      movepw (sp)(2),d2
loc_13cf0 08 03 2a 13                      btst    #$13,d3
loc_13cf4 0a 01 08 03                      eori.b #3,d1
loc_13cf8 00 0a                            .short loc_a
loc_13cfa 20 0c                            move.l  a4,d0
loc_13cfc 00 08                            .short loc_8
loc_13cfe 08 2c 00 09 04 09                btst    #9,(a4)(1033)
loc_13d04 00 01 20 0f                      ori.b #$F,d1
loc_13d08 00 38 20 01 24 0d                ori.b #1,loc_240d
loc_13d0e 25 01                            move.l  d1,(a2)-
loc_13d10 24 01                            move.l  d1,d2
loc_13d12 20 01                            move.l  d1,d0
loc_13d14 00 21 20 0f                      ori.b #$F,(a1)-
loc_13d18 00 1f 20 0a                      ori.b #$A,(sp)+
loc_13d1c 28 03                            move.l  d3,d4
loc_13d1e 08 18 00 1e                      btst    #$1E,(a0)+
loc_13d22 08 18 28 05                      btst    #5,(a0)+
loc_13d26 20 01                            move.l  d1,d0
loc_13d28 25 08                            move.l  a0,(a2)-
loc_13d2a 05 06                            btst d2,d6
loc_13d2c 00 1a 20 05                      ori.b #5,(a2)+
loc_13d30 24 02                            move.l  d2,d2
loc_13d32 20 0c                            move.l  a4,d0
loc_13d34 00 0d                            .short loc_d
loc_13d36 05 16                            btst d2,(a6)
loc_13d38 01 01                            btst d0,d1
loc_13d3a 09 03                            btst d4,d3
loc_13d3c 08 01 00 0c                      btst    #$C,d1
loc_13d40 05 08 01 01                      movepw (a0)(257),d2
loc_13d44 08 2e 09 01 01 01                btst    #1,(a6)(257)
loc_13d4a 25 09                            move.l  a1,(a2)-
loc_13d4c 20 02                            move.l  d2,d0
loc_13d4e 00 0e                            .short loc_e
loc_13d50 04 0e                            .short 0x040e
loc_13d52 00 59 05 1e                      ori.w #1310,(a1)+
loc_13d56 01 01                            btst d0,d1
loc_13d58 09 02                            btst d4,d2
loc_13d5a 08 08                            .short 0x0808
loc_13d5c 09 01                            btst d4,d1
loc_13d5e 00 0f                            .short loc_f
loc_13d60 04 12 00 10                      subi.b #$10,(a2)
loc_13d64 04 26 00 24                      subi.b #36,(a6)-
loc_13d68 00 00 00 00                      ori.b #0,d0
loc_13d6c 00 00 00 00                      ori.b #0,d0



loc_13d70: 00 13 0a 48                      ori.b #72,(a3)
loc_13d74 02 02 00 01                      andi.b  #1,d2
loc_13d78 04 01 44 07                      subi.b #7,d1
loc_13d7c 40 08                            .short 0x4008
loc_13d7e 00 2e 04 0e 44 03                ori.b #$E,(a6)(17411)
loc_13d84 40 06                            negxb d6
loc_13d86 4a 03                            tst.b   d3
loc_13d88 0a 11 08 01                      eori.b #1,(a1)
loc_13d8c 00 1c 04 0a                      ori.b #$A,(a4)+
loc_13d90 00 02 40 08                      ori.b #8,d2
loc_13d94 00 14 0a 09                      ori.b #9,(a4)
loc_13d98 00 11 04 0c                      ori.b #$C,(a1)
loc_13d9c 44 0d                            .short 0x440d
loc_13d9e 04 07 00 4f                      subi.b #79,d7
loc_13da2 04 1b 00 0a                      subi.b #$A,(a3)+
loc_13da6 04 04 45 03                      subi.b #3,d4
loc_13daa 44 04                            negb d4
loc_13dac 40 04                            negxb d4
loc_13dae 00 01 04 09                      ori.b #9,d1
loc_13db2 00 15 0a 08                      ori.b #8,(a5)
loc_13db6 00 08                            .short loc_8
loc_13db8 40 13                            negxb (a3)
loc_13dba 00 1e 04 07                      ori.b #7,(a6)+
loc_13dbe 00 05 0a 0a                      ori.b #$A,d5
loc_13dc2 02 01 00 01                      andi.b  #1,d1
loc_13dc6 40 0e                            .short 0x400e
loc_13dc8 04 0b                            .short 0x040b
loc_13dca 00 16 04 10                      ori.b #$10,(a6)
loc_13dce 00 0d                            .short loc_d
loc_13dd0 0a 0b                            .short 0x0a0b
loc_13dd2 00 17 0a 11                      ori.b #$11,(sp)
loc_13dd6 00 48                            .short 0x0048
loc_13dd8 02 03 0a 2c                      andi.b  #44,d3
loc_13ddc 02 02 06 01                      andi.b  #1,d2
loc_13de0 04 09                            .short 0x0409
loc_13de2 00 02 40 23                      ori.b #35,d2
loc_13de6 00 08                            .short loc_8
loc_13de8 04 0f                            .short 0x040f
loc_13dea 44 06                            negb d6
loc_13dec 40 03                            negxb d3
loc_13dee 42 01                            clr.b d1
loc_13df0 4a 07                            tst.b   d7
loc_13df2 42 01                            clr.b d1
loc_13df4 00 13 02 01                      ori.b #1,(a3)
loc_13df8 0a 05 02 01                      eori.b #1,d5
loc_13dfc 00 0f                            .short loc_f
loc_13dfe 02 02 00 03                      andi.b  #3,d2
loc_13e02 40 09                            .short 0x4009
loc_13e04 42 06                            clr.b d6
loc_13e06 40 03                            negxb d3
loc_13e08 00 0f                            .short loc_f
loc_13e0a 04 0a                            .short 0x040a
loc_13e0c 00 0d                            .short loc_d
loc_13e0e 0a 36 4a 13 42 02                eori.b #$13,(a6)2,d4.w:2)
loc_13e14 06 01 04 0a                      addi.b #$A,d1
loc_13e18 00 12 04 05                      ori.b #5,(a2)
loc_13e1c 44 07                            negb d7
loc_13e1e 40 02                            negxb d2
loc_13e20 00 07 0a 16                      ori.b #22,d7
loc_13e24 00 05 04 0a                      ori.b #$A,d5
loc_13e28 00 0b                            .short loc_b
loc_13e2a 02 05 00 03                      andi.b  #3,d5
loc_13e2e 04 04 00 10                      subi.b #$10,d4
loc_13e32 40 1b                            negxb (a3)+
loc_13e34 00 23 0a 0e                      ori.b #$E,(a3)-
loc_13e38 02 01 00 02                      andi.b  #2,d1
loc_13e3c 02 01 0a 0b                      andi.b  #11,d1
loc_13e40 4a 03                            tst.b   d3
loc_13e42 40 05                            negxb d5
loc_13e44 00 0b                            .short loc_b
loc_13e46 0a 06 02 01                      eori.b #1,d6
loc_13e4a 00 0b                            .short loc_b
loc_13e4c 04 08                            .short 0x0408
loc_13e4e 00 14 40 0e                      ori.b #$E,(a4)
loc_13e52 0a 1a 00 15                      eori.b #21,(a2)+
loc_13e56 04 03 05 14                      subi.b #$14,d3
loc_13e5a 04 08                            .short 0x0408
loc_13e5c 00 4a                            .short 0x004a
loc_13e5e 40 06                            negxb d6
loc_13e60 00 34 04 10 00 10                ori.b #$10,(a4)(0000000000000010,d0.w)
loc_13e66 0a 08                            .short 0x0a08
loc_13e68 08 01 00 39                      btst    #57,d1
loc_13e6c 00 00 00 00                      ori.b #0,d0

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
loc_13eb6: 30 28 00 3c                      move.w  $3C(a0),d0
loc_13eba 02 40 00 7c                      andi.w  #$7C,d0
loc_13ebe 0c 40 00 04                      cmpi.w  #4,d0
loc_13ec2 64 0a                            bcc.s   loc_13ece
loc_13ec4 4a 38 d2 4f                      tst.b   ($FFFFD24F).w
loc_13ec8 66 04                            bne.s   loc_13ece
loc_13eca 61 00 05 aa                      bsr.w   loc_14476
loc_13ece 61 00 03 a2                      bsr.w   loc_14272
loc_13ed2 4a 38 d2 4e                      tst.b   ($FFFFd24e
loc_13ed6 66 04                            bne.s   loc_13edc
loc_13ed8 61 00 dd 62                      bsr.w   loc_11c3c
loc_13edc: 4e 75                            rts

; ======================================================================


loc_13ede: 60 00 00 0a                      bra.w   loc_13eea
loc_13ee2 60 00 04 a8                      bra.w   loc_1438c
loc_13ee6 60 00 05 14                      bra.w   loc_143fc
loc_13eea 11 7c 00 1e 00 05                move.b  #$1E,5(a0)
loc_13ef0 61 34                            bsr.s   loc_13f26
loc_13ef2 61 00 03 e2                      bsr.w   loc_142d6
loc_13ef6 4a 38 d2 4f                      tst.b   ($FFFFD24F).w
loc_13efa 66 04                            bne.s   loc_13f00
loc_13efc 61 00 d4 0e                      bsr.w   loc_1130c
loc_13f00 61 00 d1 5a                      bsr.w   loc_1105c
loc_13f04 61 00 01 78                      bsr.w   loc_1407e
loc_13f08 61 00 02 1e                      bsr.w   loc_14128
loc_13f0c 61 00 04 0a                      bsr.w   loc_14318
loc_13f10 20 28 00 34                      move.l  $34(a0),d0
loc_13f14 67 0e                            beq.s   loc_13f24
loc_13f16 11 7c 00 01 00 39                move.b  #1,$39(a0)
loc_13f1c 4a 80                            tst.l   d0
loc_13f1e 6b 04                            bmi.s   loc_13f24
loc_13f20 42 28 00 39                      clr.b   $39(a0)
loc_13f24 4e 75                            rts
loc_13f26 10 38 ff 8e                      move.b  ($FFFFFF8e,d0
loc_13f2a 02 00 00 0c                      andi.b  #$C,d0
loc_13f2e 67 00 00 7a                      beq.w loc_13faa
loc_13f32 08 00 00 03                      btst    #3,d0
loc_13f36 66 00 00 96                      bne.w   loc_13fce
loc_13f3a 08 00 00 02                      btst    #2,d0
loc_13f3e 66 00 00 ac                      bne.w   loc_13fec
loc_13f42 24 28 00 30                      move.l  $30(a0),d2
loc_13f46 21 41 00 34                      move.l  d1,$34(a0)
loc_13f4a 4a 38 d2 4e                      tst.b   ($FFFFd24e
loc_13f4e 66 04                            bne.s   loc_13f54
loc_13f50 21 c1 d0 04                      move.l  d1,($FFFFd004
loc_13f54 61 00 00 e2                      bsr.w   loc_14038
loc_13f58 4a 28 00 38                      tst.b   $38(a0)
loc_13f5c 66 00 00 ac                      bne.w   loc_1400a
loc_13f60 08 28 00 00 00 3a                btst    #0,$3A(a0)
loc_13f66 67 30                            beq.s   loc_13f98
loc_13f68 10 38 ff 8e                      move.b  ($FFFFFF8e,d0
loc_13f6c 02 00 00 70                      andi.b  #112,d0
loc_13f70 67 26                            beq.s   loc_13f98
loc_13f72 2f 08                            move.l  a0,-(sp)
loc_13f74 10 3c 00 91                      move.b  #-111,d0
loc_13f78 61 00 cd ce                      bsr.w   loc_10d48
loc_13f7c 20 5f                            movea.l (sp)+,a0
loc_13f7e 11 7c 00 01 00 38                move.b  #1,$38(a0)
loc_13f84 21 7c ff fd 70 00 00 2c          move.l  #-167936,$2C(a0)
loc_13f8c 08 a8 00 00 00 3a                bclr    #0,$3A(a0)
loc_13f92 08 a8 00 01 00 3a                bclr    #1,$3A(a0)
loc_13f98 10 38 ff 8e                      move.b  ($FFFFFF8e,d0
loc_13f9c 02 00 00 70                      andi.b  #112,d0
loc_13fa0 66 06                            bne.s   loc_13fa8
loc_13fa2 11 7c 00 03 00 3a                move.b  #3,$3A(a0)
loc_13fa8 4e 75                            rts
loc_13faa 22 28 00 34                      move.l  $34(a0),d1
loc_13fae 4a 28 00 38                      tst.b   $38(a0)
loc_13fb2 66 8e                            bne.s   loc_13f42
loc_13fb4 4a 81                            tst.l   d1
loc_13fb6 67 12                            beq.s   loc_13fca
loc_13fb8 4a 81                            tst.l   d1
loc_13fba 6b 08                            bmi.s   loc_13fc4
loc_13fbc 04 81 00 00 06 00                subi.l #1536,d1
loc_13fc2 60 06                            bra.s   loc_13fca
loc_13fc4 06 81 00 00 06 00                addi.l  #1536,d1
loc_13fca 60 00 ff 76                      bra.w   loc_13f42
loc_13fce 22 28 00 34                      move.l  $34(a0),d1
loc_13fd2 0c 81 00 01 80 00                cmpi.l #98304,d1
loc_13fd8 6c 08                            bge.s   loc_13fe2
loc_13fda 06 81 00 00 18 00                addi.l  #6144,d1
loc_13fe0 60 06                            bra.s   loc_13fe8
loc_13fe2 22 3c 00 01 80 00                move.l  #98304,d1
loc_13fe8 60 00 ff 58                      bra.w   loc_13f42
loc_13fec 22 28 00 34                      move.l  $34(a0),d1
loc_13ff0 0c 81 ff fe 80 00                cmpi.l #-98304,d1
loc_13ff6 6f 08                            ble.s   loc_14000
loc_13ff8 04 81 00 00 18 00                subi.l #6144,d1
loc_13ffe 60 06                            bra.s   loc_14006
loc_14000 22 3c ff fe 80 00                move.l  #-98304,d1
loc_14006 60 00 ff 3a                      bra.w   loc_13f42
loc_1400a 0c a8 00 03 00 00 00 2c          cmpi.l #196608,$2C(a0)
loc_14012 6c 08                            bge.s   loc_1401c
loc_14014 06 a8 00 00 10 00 00 2c          addi.l  #4096,$2C(a0)
loc_1401c 10 38 ff 8e                      move.b  ($FFFFFF8e,d0
loc_14020 02 00 00 70                      andi.b  #112,d0
loc_14024 66 06                            bne.s   loc_1402c
loc_14026 11 7c 00 03 00 3a                move.b  #3,$3A(a0)
loc_1402c 4e 75                            rts
loc_1402e 42 28 00 38                      clr.b   $38(a0)
loc_14032 42 a8 00 2c                      clr.l   $2C(a0)
loc_14036 4e 75                            rts
loc_14038 08 28 00 01 00 3a                btst    #1,$3A(a0)
loc_1403e 67 3c                            beq.s   loc_1407c
loc_14040 10 38 ff 8e                      move.b  ($FFFFFF8e,d0
loc_14044 02 00 00 70                      andi.b  #112,d0
loc_14048 67 32                            beq.s   loc_1407c
loc_1404a 4a 28 00 3b                      tst.b   $3B(a0)
loc_1404e 67 2c                            beq.s   loc_1407c
loc_14050 22 78 d2 50                      movea.l ($FFFFd250,a1
loc_14054 33 7c 00 04 00 34                move.w  #4,$34(a1)
loc_1405a 4a 28 00 39                      tst.b   $39(a0)
loc_1405e 67 06                            beq.s   loc_14066
loc_14060 33 7c ff fc 00 34                move.w  #-4,$34(a1)
loc_14066 33 7c 00 08 00 3c                move.w  #8,$3C(a1)
loc_1406c 23 68 00 30 00 30                move.l  $30(a0),$30(a1)
loc_14072 42 28 00 3b                      clr.b $3B(a0)
loc_14076 08 a8 00 01 00 3a                bclr    #1,$3A(a0)
loc_1407c 4e 75                            rts
loc_1407e 3e 28 00 30                      move.w  $30(a0),d7
loc_14082 3c 28 00 24                      move.w  $24(a0),d6
loc_14086 4a 28 00 38                      tst.b   $38(a0)
loc_1408a 66 12                            bne.s   loc_1409e
loc_1408c 52 46                            addq.w  #1,d6
loc_1408e 61 00 d4 ec                      bsr.w   loc_1157c
loc_14092 4a 04                            tst.b   d4
loc_14094 66 06                            bne.s   loc_1409c
loc_14096 11 7c 00 01 00 38                move.b  #1,$38(a0)
loc_1409c 4e 75                            rts
loc_1409e 4a a8 00 34                      tst.l   $34(a0)
loc_140a2 66 36                            bne.s   loc_140da
loc_140a4 4a a8 00 2c                      tst.l   $2C(a0)
loc_140a8 6a 12                            bpl.s   loc_140bc
loc_140aa 04 46 00 0e                      subi.w  #$E,d6
loc_140ae 61 00 d4 cc                      bsr.w   loc_1157c
loc_140b2 4a 04                            tst.b   d4
loc_140b4 67 04                            beq.s   loc_140ba
loc_140b6 42 a8 00 2c                      clr.l   $2C(a0)
loc_140ba 4e 75                            rts
loc_140bc 61 00 d4 be                      bsr.w   loc_1157c
loc_140c0 4a 04                            tst.b   d4
loc_140c2 67 14                            beq.s   loc_140d8
loc_140c4 42 28 00 38                      clr.b   $38(a0)
loc_140c8 42 a8 00 2c                      clr.l   $2C(a0)
loc_140cc 02 46 ff f8                      andi.w  #$FFF8,d6
loc_140d0 42 68 00 26                      clr.w   $26(a0)
loc_140d4 31 46 00 24                      move.w  d6,$24(a0)
loc_140d8 4e 75                            rts
loc_140da 4a a8 00 2c                      tst.l   $2C(a0)
loc_140de 6a 1e                            bpl.s   loc_140fe
loc_140e0 04 46 00 0e                      subi.w  #$E,d6
loc_140e4 58 47                            addq.w  #4,d7
loc_140e6 61 00 d4 94                      bsr.w   loc_1157c
loc_140ea 4a 04                            tst.b   d4
loc_140ec 66 0a                            bne.s   loc_140f8
loc_140ee 51 47                            subq.w  #8,d7
loc_140f0 61 00 d4 8a                      bsr.w   loc_1157c
loc_140f4 4a 04                            tst.b   d4
loc_140f6 67 04                            beq.s   loc_140fc
loc_140f8 42 a8 00 2c                      clr.l   $2C(a0)
loc_140fc 4e 75                            rts
loc_140fe 59 47                            subq.w  #4,d7
loc_14100 61 00 d4 7a                      bsr.w   loc_1157c
loc_14104 4a 04                            tst.b   d4
loc_14106 66 0a                            bne.s   loc_14112
loc_14108 50 47                            addq.w  #8,d7
loc_1410a 61 00 d4 70                      bsr.w   loc_1157c
loc_1410e 4a 04                            tst.b   d4
loc_14110 67 14                            beq.s   loc_14126
loc_14112 42 28 00 38                      clr.b   $38(a0)
loc_14116 42 a8 00 2c                      clr.l   $2C(a0)
loc_1411a 02 46 ff f8                      andi.w  #$FFF8,d6
loc_1411e 42 68 00 26                      clr.w   $26(a0)
loc_14122 31 46 00 24                      move.w  d6,$24(a0)
loc_14126 4e 75                            rts
loc_14128 3e 28 00 30                      move.w  $30(a0),d7
loc_1412c 3c 28 00 24                      move.w  $24(a0),d6
loc_14130 2a 28 00 34                      move.l  $34(a0),d5
loc_14134 4a 28 00 38                      tst.b   $38(a0)
loc_14138 66 60                            bne.s   loc_1419a
loc_1413a 04 46 00 0a                      subi.w  #$A,d6
loc_1413e 4a 85                            tst.l   d5
loc_14140 67 2c                            beq.s   loc_1416e
loc_14142 4a 85                            tst.l   d5
loc_14144 6a 2a                            bpl.s   loc_14170
loc_14146 5d 47                            subq.w  #6,d7
loc_14148 61 00 d4 32                      bsr.w   loc_1157c
loc_1414c 4a 04                            tst.b   d4
loc_1414e 67 1e                            beq.s   loc_1416e
loc_14150 20 28 00 34                      move.l  $34(a0),d0
loc_14154 04 80 00 00 30 00                subi.l #12288,d0
loc_1415a 0c 80 ff fe 02 00                cmpi.l #-130560,d0
loc_14160 6c 06                            bge.s   loc_14168
loc_14162 20 3c ff fe 02 00                move.l  #-130560,d0
loc_14168 44 80                            neg.l   d0
loc_1416a 21 40 00 34                      move.l  d0,$34(a0)
loc_1416e 4e 75                            rts
loc_14170 5c 47                            addq.w  #6,d7
loc_14172 61 00 d4 08                      bsr.w   loc_1157c
loc_14176 4a 04                            tst.b   d4
loc_14178 67 1e                            beq.s   loc_14198
loc_1417a 20 28 00 34                      move.l  $34(a0),d0
loc_1417e 06 80 00 00 30 00                addi.l  #12288,d0
loc_14184 0c 80 00 01 fe 00                cmpi.l #130560,d0
loc_1418a 6f 06                            ble.s   loc_14192
loc_1418c 20 3c 00 01 fe 00                move.l  #130560,d0
loc_14192 44 80                            neg.l   d0
loc_14194 21 40 00 34                      move.l  d0,$34(a0)
loc_14198 4e 75                            rts
loc_1419a 51 46                            subq.w  #8,d6
loc_1419c 4a 85                            tst.l   d5
loc_1419e 67 00 00 a8                      beq.w loc_14248
loc_141a2 4a 85                            tst.l   d5
loc_141a4 6a 36                            bpl.s   loc_141dc
loc_141a6 5d 47                            subq.w  #6,d7
loc_141a8 61 00 d3 d2                      bsr.w   loc_1157c
loc_141ac 4a 04                            tst.b   d4
loc_141ae 67 2a                            beq.s   loc_141da
loc_141b0 08 04 00 01                      btst    #1,d4
loc_141b4 66 06                            bne.s   loc_141bc
loc_141b6 08 04 00 00                      btst    #0,d4
loc_141ba 67 56                            beq.s   loc_14212
loc_141bc 20 28 00 34                      move.l  $34(a0),d0
loc_141c0 04 80 00 00 30 00                subi.l #12288,d0
loc_141c6 0c 80 ff fe 02 00                cmpi.l #-130560,d0
loc_141cc 6c 06                            bge.s   loc_141d4
loc_141ce 20 3c ff fe 02 00                move.l  #-130560,d0
loc_141d4 44 80                            neg.l   d0
loc_141d6 21 40 00 34                      move.l  d0,$34(a0)
loc_141da 4e 75                            rts
loc_141dc 5c 47                            addq.w  #6,d7
loc_141de 61 00 d3 9c                      bsr.w   loc_1157c
loc_141e2 4a 04                            tst.b   d4
loc_141e4 67 2a                            beq.s   loc_14210
loc_141e6 08 04 00 01                      btst    #1,d4
loc_141ea 66 06                            bne.s   loc_141f2
loc_141ec 08 04 00 00                      btst    #0,d4
loc_141f0 67 20                            beq.s   loc_14212
loc_141f2 20 28 00 34                      move.l  $34(a0),d0
loc_141f6 06 80 00 00 30 00                addi.l  #12288,d0
loc_141fc 0c 80 00 01 fe 00                cmpi.l #130560,d0
loc_14202 6f 06                            ble.s   loc_1420a
loc_14204 20 3c 00 01 fe 00                move.l  #130560,d0
loc_1420a 44 80                            neg.l   d0
loc_1420c 21 40 00 34                      move.l  d0,$34(a0)
loc_14210 4e 75                            rts
loc_14212 4a a8 00 2c                      tst.l   $2C(a0)
loc_14216 6a 1a                            bpl.s   loc_14232
loc_14218 30 06                            move.w  d6,d0
loc_1421a 02 40 00 07                      andi.w  #7,d0
loc_1421e 0c 40 00 03                      cmpi.w  #3,d0
loc_14222 6d 0c                            blt.s   loc_14230
loc_14224 06 46 00 10                      addi.w  #$10,d6
loc_14228 31 46 00 24                      move.w  d6,$24(a0)
loc_1422c 42 a8 00 2c                      clr.l   $2C(a0)
loc_14230 4e 75                            rts
loc_14232 02 46 ff f8                      andi.w  #$FFF8,d6
loc_14236 31 46 00 24                      move.w  d6,$24(a0)
loc_1423a 42 68 00 26                      clr.w   $26(a0)
loc_1423e 42 a8 00 2c                      clr.l   $2C(a0)
loc_14242 42 28 00 38                      clr.b   $38(a0)
loc_14246 4e 75                            rts
loc_14248 5c 47                            addq.w  #6,d7
loc_1424a 61 00 d3 30                      bsr.w   loc_1157c
loc_1424e 4a 04                            tst.b   d4
loc_14250 67 0a                            beq.s   loc_1425c
loc_14252 21 7c ff ff 40 00 00 34          move.l  #-49152,$34(a0)
loc_1425a 60 14                            bra.s   loc_14270
loc_1425c 04 47 00 0c                      subi.w  #$C,d7
loc_14260 61 00 d3 1a                      bsr.w   loc_1157c
loc_14264 4a 04                            tst.b   d4
loc_14266 67 08                            beq.s   loc_14270
loc_14268 21 7c 00 00 c0 00 00 34          move.l  #49152,$34(a0)
loc_14270 4e 75                            rts
loc_14272 45 f8 d2 06                      lea     ($FFFFd206,a2
loc_14276 43 f8 d1 fe                      lea     ($FFFFd1fe,a1
loc_1427a 49 f8 d2 0a                      lea     ($FFFFd20a,a4
loc_1427e 47 f8 d2 02                      lea     ($FFFFd202,a3
loc_14282 70 3f                            moveq   #$3F,d0
loc_14284 24 91                            move.l  (a1),(a2)
loc_14286 28 93                            move.l  (a3),(a4)
loc_14288 51 89                            subql #8,a1
loc_1428a 51 8a                            subql #8,a2
loc_1428c 51 8b                            subql #8,a3
loc_1428e 51 8c                            subql #8,a4
loc_14290 51 c8 ff f2                      dbf     d0,loc_14284
loc_14294 45 f8 d2 4e                      lea     ($FFFFd24e,a2
loc_14298 43 f8 d2 4d                      lea     ($FFFFd24d,a1
loc_1429c 70 3f                            moveq   #$3F,d0
loc_1429e 15 21                            move.b  (a1)-,(a2)-
loc_142a0 51 c8 ff fc                      dbf     d0,loc_1429e
loc_142a4 21 e8 00 30 d0 0e                move.l  $30(a0),($FFFFd00e
loc_142aa 21 e8 00 24 d0 12                move.l  $24(a0),($FFFFd012
loc_142b0 70 00                            moveq   #0,d0
loc_142b2 4a 28 00 38                      tst.b   $38(a0)
loc_142b6 67 04                            beq.s   loc_142bc
loc_142b8 08 c0 00 07                      bset    #7,d0
loc_142bc 2e 28 00 34                      move.l  $34(a0),d7
loc_142c0 67 0e                            beq.s   loc_142d0
loc_142c2 4a 87                            tst.l   d7
loc_142c4 6a 06                            bpl.s   loc_142cc
loc_142c6 08 c0 00 01                      bset    #1,d0
loc_142ca 60 04                            bra.s   loc_142d0
loc_142cc 08 c0 00 00                      bset    #0,d0
loc_142d0 11 c0 d2 0e                      move.b  d0,($FFFFd20e
loc_142d4 4e 75                            rts
loc_142d6 4a 38 d2 7a                      tst.b   ($FFFFD27A).w
loc_142da 67 3a                            beq.s   loc_14316
loc_142dc 4a 28 00 38                      tst.b   $38(a0)
loc_142e0 66 34                            bne.s   loc_14316
loc_142e2 3e 28 00 30                      move.w  $30(a0),d7
loc_142e6 3c 28 00 24                      move.w  $24(a0),d6
loc_142ea bc 78 d2 5c                      cmp.w ($FFFFD25C).w,d6
loc_142ee 66 26                            bne.s   loc_14316
loc_142f0 be 78 d2 5e                      cmp.w ($FFFFd25e,d7
loc_142f4 6d 20                            blt.s   loc_14316
loc_142f6 be 78 d2 60                      cmp.w ($FFFFd260,d7
loc_142fa 6e 1a                            bgt.s   loc_14316
loc_142fc 11 fc 00 01 d2 4f                move.b  #1,($FFFFD24F).w
loc_14302 42 a8 00 34                      clr.l   $34(a0)
loc_14306 42 b8 d0 04                      clr.l ($FFFFd004
loc_1430a 52 38 d8 8d                      addq.b  #1,($FFFFD88D).w
loc_1430e 2f 08                            move.l  a0,-(sp)
loc_14310 61 00 d9 d4                      bsr.w   loc_11ce6
loc_14314 20 5f                            movea.l (sp)+,a0
loc_14316 4e 75                            rts
loc_14318 08 a8 00 07 00 02                bclr    #7,2(a0)
loc_1431e 20 28 00 34                      move.l  $34(a0),d0
loc_14322 12 38 ff 8e                      move.b  ($FFFFFF8e,d1
loc_14326 4a 28 00 38                      tst.b   $38(a0)
loc_1432a 66 3a                            bne.s   loc_14366
loc_1432c 4a 80                            tst.l   d0
loc_1432e 67 2c                            beq.s   loc_1435c
loc_14330 4a 80                            tst.l   d0
loc_14332 6a 0e                            bpl.s   loc_14342
loc_14334 08 e8 00 07 00 02                bset    #7,2(a0)
loc_1433a 08 01 00 02                      btst    #2,d1
loc_1433e 66 12                            bne.s   loc_14352
loc_14340 60 06                            bra.s   loc_14348
loc_14342 08 01 00 03                      btst    #3,d1
loc_14346 66 0a                            bne.s   loc_14352
loc_14348 21 7c 00 01 a8 a0 00 0c          move.l  #108704,$C(a0)
loc_14350 4e 75                            rts
loc_14352 42 68 00 06                      clr.w 6(a0)
loc_14356 61 00 cd ce                      bsr.w   AnimateSprite
loc_1435a 4e 75                            rts
loc_1435c 21 7c 00 01 a8 98 00 0c          move.l  #108696,$C(a0)
loc_14364 4e 75                            rts
loc_14366 4a 80                            tst.l   d0
loc_14368 67 16                            beq.s   loc_14380
loc_1436a 31 7c 00 08 00 06                move.w  #8,6(a0)
loc_14370 4a 80                            tst.l   d0
loc_14372 6a 06                            bpl.s   loc_1437a
loc_14374 08 e8 00 07 00 02                bset    #7,2(a0)
loc_1437a 61 00 cd aa                      bsr.w   AnimateSprite
loc_1437e 4e 75                            rts
loc_14380 31 7c 00 04 00 06                move.w  #4,6(a0)
loc_14386 61 00 cd 9e                      bsr.w   AnimateSprite
loc_1438a 4e 75                            rts
loc_1438c 08 e8 00 07 00 3c                bset    #7,$3C(a0)
loc_14392 66 1a                            bne.s   loc_143ae
loc_14394 2f 08                            move.l  a0,-(sp)
loc_14396 10 3c 00 87                      move.b  #-121,d0
loc_1439a 4e b8 fb 66                      jsr     ($FFFFFB66).w
loc_1439e 20 5f                            movea.l (sp)+,a0
loc_143a0 42 28 00 05                      clr.b 5(a0)
loc_143a4 42 a8 00 34                      clr.l   $34(a0)
loc_143a8 31 7c 00 0c 00 06                move.w  #$C,6(a0)
loc_143ae 06 a8 00 00 10 00 00 2c          addi.l  #4096,$2C(a0)
loc_143b6 61 00 cc a4                      bsr.w   loc_1105c
loc_143ba 3e 28 00 30                      move.w  $30(a0),d7
loc_143be 3c 28 00 24                      move.w  $24(a0),d6
loc_143c2 61 00 d1 b8                      bsr.w   loc_1157c
loc_143c6 4a 04                            tst.b   d4
loc_143c8 66 1a                            bne.s   loc_143e4
loc_143ca 4a a8 00 2c                      tst.l   $2C(a0)
loc_143ce 6a 0e                            bpl.s   loc_143de
loc_143d0 51 46                            subq.w  #8,d6
loc_143d2 61 00 d1 a8                      bsr.w   loc_1157c
loc_143d6 4a 04                            tst.b   d4
loc_143d8 67 04                            beq.s   loc_143de
loc_143da 42 a8 00 2c                      clr.l   $2C(a0)
loc_143de 61 00 cd 46                      bsr.w   AnimateSprite
loc_143e2 4e 75                            rts
loc_143e4 42 a8 00 2c                      clr.l   $2C(a0)
loc_143e8 02 46 ff f8                      andi.w  #$FFF8,d6
loc_143ec 42 68 00 26                      clr.w   $26(a0)
loc_143f0 31 46 00 24                      move.w  d6,$24(a0)
loc_143f4 31 7c 00 08 00 3c                move.w  #8,$3C(a0)
loc_143fa 4e 75                            rts
loc_143fc 08 e8 00 07 00 3c                bset    #7,$3C(a0)
loc_14402 66 14                            bne.s   loc_14418
loc_14404 42 28 00 05                      clr.b 5(a0)
loc_14408 42 28 00 10                      clr.b   $10(a0)
loc_1440c 08 a8 00 02 00 02                bclr    #2,2(a0)
loc_14412 11 7c 00 03 00 39                move.b  #3,$39(a0)
loc_14418 61 00 cc 42                      bsr.w   loc_1105c
loc_1441c 61 00 cd 08                      bsr.w   AnimateSprite
loc_14420 08 a8 00 02 00 02                bclr    #2,2(a0)
loc_14426 67 08                            beq.s   loc_14430
loc_14428 53 28 00 39                      subq.b  #1,$39(a0)
loc_1442c 61 00 00 36                      bsr.w   loc_14464
loc_14430 4a 28 00 39                      tst.b   $39(a0)
loc_14434 66 2c                            bne.s   loc_14462
loc_14436 53 38 d8 82                      subq.b  #1,($FFFFD882).w
loc_1443a 67 20                            beq.s   loc_1445c
loc_1443c 11 fc 00 01 d8 86                move.b  #1,($FFFFD886).w
loc_14442 61 00 d2 de                      bsr.w   loc_11722
loc_14446 31 fc 00 20 ff c0                move.w  #$20,($FFFFFFC0).w
loc_1444c 74 3c                            moveq   #$3C,d2
loc_1444e 61 00 d2 6e                      bsr.w   TimerCounter
loc_14452 4e b8 fb 6c                      jsr     ($FFFFFB6C).w
loc_14456 51 ca ff f6                      dbf     d2,loc_1444e
loc_1445a 60 06                            bra.s   loc_14462
loc_1445c 31 fc 00 10 d2 a0                move.w  #$10,($FFFFD2A0).w
loc_14462 4e 75                            rts
loc_14464 43 f8 c3 80                      lea     ($FFFFC380,a1
loc_14468 70 02                            moveq   #2,d0
loc_1446a 42 51                            clr.w   (a1)
loc_1446c 43 e9 00 40                      lea     $40(a1),a1
loc_14470 51 c8 ff f8                      dbf     d0,loc_1446a
loc_14474 4e 75                            rts
loc_14476 43 f8 c3 80                      lea     ($FFFFC380,a1
loc_1447a 72 02                            moveq   #2,d1
loc_1447c 08 29 00 00 00 05                btst    #0,5(a1)
loc_14482 67 1e                            beq.s   loc_144a2
loc_14484 48 a7 40 00                      movem.w d1,-(sp)
loc_14488 61 00 d3 36                      bsr.w   loc_117c0
loc_1448c 4c 9f 00 02                      movem.w (sp)+,d1
loc_14490 4a 00                            tst.b   d0
loc_14492 67 0e                            beq.s   loc_144a2
loc_14494 31 7c 00 04 00 3c                move.w  #4,$3C(a0)
loc_1449a 11 fc 00 01 d2 6d                move.b  #1,($FFFFD26D).w
loc_144a0 60 08                            bra.s   loc_144aa
loc_144a2 43 e9 00 40                      lea     $40(a1),a1
loc_144a6 51 c9 ff d4                      dbf     d1,loc_1447c
loc_144aa 4e 75                            rts

; ======================================================================

loc_144ac:
                dc.l    loc_144BC                ; Flicky running.
                dc.l    loc_144C2
                dc.l    loc_144C8
                dc.l    loc_144CE

; ----------------------------------------------------------------------

loc_144bc:
                dc.b    $02, $02                 ; Animation table entries and animation frame duration.
                dc.w    loc_1A8A8&$FFFF          ; TODO Find this stuff out.
                dc.w    loc_1A8B0&$FFFF

; ----------------------------------------------------------------------

loc_144c2:
02 02 a8 b8                      andi.b  #-72,d2
loc_144c6 a8 c0                            .short 0xa8c0

loc_144c8: 02 02 a8 c8                      andi.b  #-56,d2
loc_144cc a8 d0                            .short 0xa8d0

loc_144ce: 06 03 a8 78                      addi.b #120,d3
loc_144d2 a8 80                            .short 0xa880
loc_144d4 a8 88                            .short 0xa888
loc_144d6 a8 90                            .short 0xa890
loc_144d8 a8 88                            .short 0xa888
loc_144da a8 90                            .short 0xa890

; ======================================================================

loc_144dc 08 d0 00 07                      bset    #7,(a0)
loc_144e0 66 22                            bne.s   loc_14504
loc_144e2 1e 38 d8 34                      move.b  ($FFFFD834).w,d7
loc_144e6 1c 38 d8 35                      move.b  ($FFFFd835,d6
loc_144ea 61 00 d1 88                      bsr.w   loc_11674
loc_144ee 50 47                            addq.w  #8,d7
loc_144f0 06 46 00 18                      addi.w  #$18d6
loc_144f4 31 47 00 30                      move.w  d7,$30(a0)
loc_144f8 31 46 00 24                      move.w  d6,$24(a0)
loc_144fc 21 7c 00 01 45 24 00 08          move.l  #83236,8(a0)
loc_14504 30 28 00 3c                      move.w  $3C(a0),d0
loc_14508 02 40 7f fc                      andi.w  #$7FFC,d0
loc_1450c 4e bb 00 08                      jsr     (pc)(loc_14516,d0.w)
loc_14510 61 00 cb 4a                      bsr.w   loc_1105c
loc_14514 4e 75                            rts
loc_14516 60 00 00 06                      bra.w   loc_1451e
loc_1451a 60 00 00 06                      bra.w   loc_14522
loc_1451e 61 00 cc 06                      bsr.w   AnimateSprite
loc_14522 4e 75                            rts
loc_14524 00 01 45 28                      ori.b #$28,d1
loc_14528 02 08                            .short 0x0208
loc_1452a ad 82                            .short 0xad82
loc_1452c ad 8a                            .short 0xad8a

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
                move.b  #$185(a0)
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
                bpl.s   loc_146a0
                bset    #7,2(a0)
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
loc_14730: 00 01 47 6c                      ori.b #108,d1
loc_14734 00 01 47 7a                      ori.b #122,d1
loc_14738 00 01 47 88                      ori.b #-120,d1
loc_1473c 00 01 47 96                      ori.b #-106,d1
loc_14740 00 01 47 a4                      ori.b #-92,d1
loc_14744 00 01 47 b2                      ori.b #-78,d1
loc_14748 00 01 47 c0                      ori.b #-64,d1
loc_1474c 00 01 47 ce                      ori.b #-50,d1
loc_14750 00 01 47 dc                      ori.b #-36,d1
loc_14754 00 01 47 ea                      ori.b #-22,d1
loc_14758 00 01 47 f8                      ori.b #-8,d1
loc_1475c 00 01 48 06                      ori.b #6,d1
loc_14760 00 01 48 14                      ori.b #$14,d1
loc_14764 00 01 48 22                      ori.b #34,d1
loc_14768 00 01 48 30                      ori.b #$30,d1
loc_1476c 06 01 a4 e8                      addi.b #-24,d1
loc_14770 a4 f8                            .short 0xa4f8
loc_14772 a5 08                            .short 0xa508
loc_14774 a4 f0                            .short 0xa4f0
loc_14776 a5 10                            .short 0xa510
loc_14778 a5 00                            .short 0xa500
loc_1477a 06 01 a5 18                      addi.b #$18d1
loc_1477e a5 28                            .short 0xa528
loc_14780 a5 38                            .short 0xa538
loc_14782 a5 20                            .short 0xa520
loc_14784 a5 40                            .short 0xa540
loc_14786 a5 30                            .short 0xa530
loc_14788 06 01 a5 48                      addi.b #72,d1
loc_1478c a5 58                            .short 0xa558
loc_1478e a5 68                            .short 0xa568
loc_14790 a5 50                            .short 0xa550
loc_14792 a5 70                            .short 0xa570
loc_14794 a5 60                            .short 0xa560
loc_14796 06 01 a5 78                      addi.b #120,d1
loc_1479a a5 88                            .short 0xa588
loc_1479c a5 98                            .short 0xa598
loc_1479e a5 80                            .short 0xa580
loc_147a0 a5 a0                            .short 0xa5a0
loc_147a2 a5 90                            .short 0xa590
loc_147a4 06 01 a5 a8                      addi.b #-88,d1
loc_147a8 a5 b8                            .short 0xa5b8
loc_147aa a5 c8                            .short 0xa5c8
loc_147ac a5 b0                            .short 0xa5b0
loc_147ae a5 d0                            .short 0xa5d0
loc_147b0 a5 c0                            .short 0xa5c0
loc_147b2 06 01 a5 d8                      addi.b #-40,d1
loc_147b6 a5 e8                            .short 0xa5e8
loc_147b8 a5 f8                            .short 0xa5f8
loc_147ba a5 e0                            .short 0xa5e0
loc_147bc a6 00                            .short 0xa600
loc_147be a5 f0                            .short 0xa5f0
loc_147c0 06 01 a6 08                      addi.b #8,d1
loc_147c4 a6 18                            .short 0xa618
loc_147c6 a6 28                            .short 0xa628
loc_147c8 a6 10                            .short 0xa610
loc_147ca a6 30                            .short 0xa630
loc_147cc a6 20                            .short 0xa620
loc_147ce 06 01 a6 38                      addi.b #$38,d1
loc_147d2 a6 48                            .short 0xa648
loc_147d4 a6 58                            .short 0xa658
loc_147d6 a6 40                            .short 0xa640
loc_147d8 a6 60                            .short 0xa660
loc_147da a6 50                            .short 0xa650
loc_147dc 06 01 a6 68                      addi.b #104,d1
loc_147e0 a6 78                            .short 0xa678
loc_147e2 a6 88                            .short 0xa688
loc_147e4 a6 70                            .short 0xa670
loc_147e6 a6 90                            .short 0xa690
loc_147e8 a6 80                            .short 0xa680
loc_147ea 06 01 a6 98                      addi.b #-104,d1
loc_147ee a6 a8                            .short 0xa6a8
loc_147f0 a6 b8                            .short 0xa6b8
loc_147f2 a6 a0                            .short 0xa6a0
loc_147f4 a6 c0                            .short 0xa6c0
loc_147f6 a6 b0                            .short 0xa6b0
loc_147f8 06 01 a6 c8                      addi.b #-56,d1
loc_147fc a6 d8                            .short 0xa6d8
loc_147fe a6 e8                            .short 0xa6e8
loc_14800 a6 d0                            .short 0xa6d0
loc_14802 a6 f0                            .short 0xa6f0
loc_14804 a6 e0                            .short 0xa6e0
loc_14806 06 01 a6 f8                      addi.b #-8,d1
loc_1480a a7 08                            .short 0xa708
loc_1480c a7 18                            .short 0xa718
loc_1480e a7 00                            .short 0xa700
loc_14810 a7 20                            .short 0xa720
loc_14812 a7 10                            .short 0xa710
loc_14814 06 01 a7 28                      addi.b #$28,d1
loc_14818 a7 38                            .short 0xa738
loc_1481a a7 48                            .short 0xa748
loc_1481c a7 30                            .short 0xa730
loc_1481e a7 50                            .short 0xa750
loc_14820 a7 40                            .short 0xa740
loc_14822 06 01 a7 58                      addi.b #$58,d1
loc_14826 a7 68                            .short 0xa768
loc_14828 a7 78                            .short 0xa778
loc_1482a a7 60                            .short 0xa760
loc_1482c a7 80                            .short 0xa780
loc_1482e a7 70                            .short 0xa770
loc_14830 06 01 a7 88                      addi.b #-120,d1
loc_14834 a7 98                            .short 0xa798
loc_14836 a7 a8                            .short 0xa7a8
loc_14838 a7 90                            .short 0xa790
loc_1483a a7 b0                            .short 0xa7b0
loc_1483c a7 a0                            .short 0xa7a0

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
                bne.s   loc_148c6
                move.b  #$30,$3B(a0)
                move.l  #$FFFFE000,$2C(a0)
                clr.w   6(a0)
                subq.b  #1,$3B(a0)
                bne.s   loc_148da
                neg.l   $2C(a0)
                move.b  #$30,$3B(a0)
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
; TODO RAM TABLE
loc_14a58: 00 00 d0 36                      ori.b #54,d0
loc_14a5c d0 5e                            add.w (a6)+,d0
loc_14a5e d0 86                            add.l d6,d0
loc_14a60 d0 ae d0 d6                      add.l (a6)(-12074),d0
loc_14a64 d0 fe                            .short 0xd0fe
loc_14a66 d1 26                            add.b d0,(a6)-
loc_14a68 d1 4e                            addxw (a6)-,(a0)-


loc_14a6a: 00 00 d2 13                      ori.b #$13,d0
loc_14a6e d2 18                            add.b (a0)+,d1
loc_14a70 d2 1d                            add.b (a5)+,d1
loc_14a72 d2 22                            add.b (a2)-,d1
loc_14a74 d2 27                            add.b -(sp),d1
loc_14a76 d2 2c d2 31                      add.b (a4)(-11727),d1
loc_14a7a d2 36

; ======================================================================

loc_14A7C:
                moveq   #0,d0
                add.b   (a6,d7.w),d1
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
                beq.s   loc_14db8
                bset    #7,2(a0)
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
; TODO RAM TABLES BELOW
loc_14e12: 00 01 4e 32                      ori.b #50,d1
loc_14e16 00 01 4e 96                      ori.b #-106,d1
loc_14e1a 00 01 4e a2                      ori.b #-94,d1
loc_14e1e 00 01 4e b2                      ori.b #-78,d1

loc_14e22: 00 01 4e 64                      ori.b #100,d1
loc_14e26 00 01 4e 9c                      ori.b #-100,d1
loc_14e2a 00 01 4e aa                      ori.b #-86,d1
loc_14e2e 00 01 4e bc                      ori.b #-68,d1

loc_14e32 18 04                            move.b  d4,d4
loc_14e34 a7 b8                            .short 0xa7b8
loc_14e36 a7 c0                            .short 0xa7c0
loc_14e38 a7 b8                            .short 0xa7b8
loc_14e3a a7 c0                            .short 0xa7c0
loc_14e3c a7 b8                            .short 0xa7b8
loc_14e3e a7 c0                            .short 0xa7c0
loc_14e40 a7 b8                            .short 0xa7b8
loc_14e42 a7 c0                            .short 0xa7c0
loc_14e44 a7 b8                            .short 0xa7b8
loc_14e46 a7 c0                            .short 0xa7c0
loc_14e48 a7 b8                            .short 0xa7b8
loc_14e4a a7 c0                            .short 0xa7c0
loc_14e4c a7 c8                            .short 0xa7c8
loc_14e4e a7 d0                            .short 0xa7d0
loc_14e50 a7 c8                            .short 0xa7c8
loc_14e52 a7 d0                            .short 0xa7d0
loc_14e54 a7 c8                            .short 0xa7c8
loc_14e56 a7 d0                            .short 0xa7d0
loc_14e58 a7 c8                            .short 0xa7c8
loc_14e5a a7 d0                            .short 0xa7d0
loc_14e5c a7 c8                            .short 0xa7c8
loc_14e5e a7 d0                            .short 0xa7d0
loc_14e60 a7 c8                            .short 0xa7c8
loc_14e62 a7 d0                            .short 0xa7d0
loc_14e64 18 04                            move.b  d4,d4
loc_14e66 a8 18                            .short 0xa818
loc_14e68 a8 20                            .short 0xa820
loc_14e6a a8 18                            .short 0xa818
loc_14e6c a8 20                            .short 0xa820
loc_14e6e a8 18                            .short 0xa818
loc_14e70 a8 20                            .short 0xa820
loc_14e72 a8 18                            .short 0xa818
loc_14e74 a8 20                            .short 0xa820
loc_14e76 a8 18                            .short 0xa818
loc_14e78 a8 20                            .short 0xa820
loc_14e7a a8 18                            .short 0xa818
loc_14e7c a8 20                            .short 0xa820
loc_14e7e a8 28                            .short 0xa828
loc_14e80 a8 30                            .short 0xa830
loc_14e82 a8 28                            .short 0xa828
loc_14e84 a8 30                            .short 0xa830
loc_14e86 a8 28                            .short 0xa828
loc_14e88 a8 30                            .short 0xa830
loc_14e8a a8 28                            .short 0xa828
loc_14e8c a8 30                            .short 0xa830
loc_14e8e a8 28                            .short 0xa828
loc_14e90 a8 30                            .short 0xa830
loc_14e92 a8 28                            .short 0xa828
loc_14e94 a8 30                            .short 0xa830
loc_14e96 02 03 a7 d8                      andi.b  #-40,d3
loc_14e9a a7 e0                            .short 0xa7e0
loc_14e9c 02 03 a8 38                      andi.b  #$38,d3
loc_14ea0 a8 40                            .short 0xa840
loc_14ea2 03 04                            btst d1,d4
loc_14ea4 a7 e8                            .short 0xa7e8
loc_14ea6 a7 f0                            .short 0xa7f0
loc_14ea8 a7 f8                            .short 0xa7f8
loc_14eaa 03 04                            btst d1,d4
loc_14eac a8 48                            .short 0xa848
loc_14eae a8 50                            .short 0xa850
loc_14eb0 a8 58                            .short 0xa858
loc_14eb2 04 0a                            .short 0x040a
loc_14eb4 a8 00                            .short 0xa800
loc_14eb6 a8 00                            .short 0xa800
loc_14eb8 a8 08                            .short 0xa808
loc_14eba a8 10                            .short 0xa810
loc_14ebc 04 0a                            .short 0x040a
loc_14ebe a8 60                            .short 0xa860
loc_14ec0 a8 60                            .short 0xa860
loc_14ec2 a8 68                            .short 0xa868
loc_14ec4 a8 70                            .short 0xa870

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
                bpl.s   loc_15126
                bset    #7,2(a0)
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
                bra.s   loc_151aa

loc_1518c:
                move.l  ($FFFFD26E).w,$34(a0)
                move.l  ($FFFFD272).w,$2C(a0)
                bra.s   loc_151aa
                move.l  #$1A000,$34(a0)
                move.l  #$FFFF0000,$2C(a0)
loc_151aa:
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
                beq.s   loc_1524a
                bset    #7,2(a0)
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
                bne.s   loc_152d6
                addi.l  #$1000,($FFFFD296).w
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
; TODO RAM TABLE
loc_154ae: 00 01 54 c2                      ori.b #-62,d1
loc_154b2 00 01 54 d0                      ori.b #-48,d1
loc_154b6 00 01 54 e2                      ori.b #-30,d1
loc_154ba 00 01 54 f4                      ori.b #-12,d1
loc_154be 00 01 54 fe                      ori.b #-2,d1
loc_154c2 06 0c                            .short 0x060c
loc_154c4 a8 f8                            .short 0xa8f8
loc_154c6 a9 00                            .short 0xa900
loc_154c8 a8 f8                            .short 0xa8f8
loc_154ca a9 00                            .short 0xa900
loc_154cc a9 08                            .short 0xa908
loc_154ce a9 10                            .short 0xa910
loc_154d0 08 01 a9 18                      btst    #$18d1
loc_154d4 a9 26                            .short 0xa926
loc_154d6 a9 3a                            .short 0xa93a
loc_154d8 a9 4e                            .short 0xa94e
loc_154da a9 4e                            .short 0xa94e
loc_154dc a9 5c                            .short 0xa95c
loc_154de a9 3a                            .short 0xa93a
loc_154e0 a9 26                            .short 0xa926
loc_154e2 08 01 a9 92                      btst    #-110,d1
loc_154e6 a9 9a                            .short 0xa99a
loc_154e8 a9 ae                            .short 0xa9ae
loc_154ea a9 b6                            .short 0xa9b6
loc_154ec a9 ca                            .short 0xa9ca
loc_154ee a9 d2                            .short 0xa9d2
loc_154f0 a9 e6                            .short 0xa9e6
loc_154f2 a9 ee                            .short 0xa9ee
loc_154f4 04 05 aa 02                      subi.b #2,d5
loc_154f8 aa 02                            .short 0xaa02
loc_154fa aa 0a                            .short 0xaa0a
loc_154fc aa 12                            .short 0xaa12
loc_154fe 04 06 aa 7e                      subi.b #126,d6
loc_15502 aa 7e                            .short 0xaa7e
loc_15504 aa 86                            .short 0xaa86
loc_15506 aa 8e                            .short 0xaa8e

; ======================================================================

loc_15508:
                dc.w    loc_15568
                dc.w    loc_155A4
                dc.w    loc_155A4
                dc.w    loc_155C0
                dc.w    loc_155DC
                dc.w    loc_15610
                dc.w    loc_15610
                dc.w    loc_15624
                dc.w    loc_15646
                dc.w    loc_1566A
                dc.w    loc_1566A
                dc.w    loc_156A2
                dc.w    loc_156CE
                dc.w    loc_15714
                dc.w    loc_15714
                dc.w    loc_15740
                dc.w    loc_1576E
                dc.w    loc_157D2
                dc.w    loc_157D2
                dc.w    loc_157FA
                dc.w    loc_15822
                dc.w    loc_1584E
                dc.w    loc_1584E
                dc.w    loc_15886
                dc.w    loc_158A6
                dc.w    loc_158C6
                dc.w    loc_158C6
                dc.w    loc_158E2
                dc.w    loc_1590E
                dc.w    loc_1592A
                dc.w    loc_1592A
                dc.w    loc_15942
                dc.w    loc_15962
                dc.w    loc_15982
                dc.w    loc_15982
                dc.w    loc_159B6
                dc.w    loc_159DE
                dc.w    loc_15A02
                dc.w    loc_15A02
                dc.w    loc_15A2E
                dc.w    loc_15A46
                dc.w    loc_15AE6
                dc.w    loc_15AE6
                dc.w    loc_15B02
                dc.w    loc_15B1C
                dc.w    loc_15B52
                dc.w    loc_15B52
                dc.w    loc_15B70

; ----------------------------------------------------------------------

loc_15568:

07 05                      subq.w  #5,(a0)@0,d0.w:8)
loc_1556a 0a 05 10 05                      eori.b #5,d5
loc_1556e 16 15                            move.b  (a5),d3
loc_15570 07 15                            btst d3,(a5)
loc_15572 0d 15                            btst d6,(a5)
loc_15574 13 15                            move.b  (a5),(a1)-
loc_15576 1a 07                            move.b  d7,d5
loc_15578 1a 0a                            .short 0x1a0a
loc_1557a 1a 10                            move.b  (a0),d5
loc_1557c 1a 16                            move.b  (a6),d5
loc_1557e 0a 07 0a 0d                      eori.b #$D,d7
loc_15582 0a 13 0a 1a                      eori.b #26,(a3)
loc_15586 0e 0e                            .short 0x0e0e
loc_15588 08 0d                            .short 0x080d
loc_1558a 0c 0e                            .short 0x0c0e
loc_1558c 0e 0d                            .short 0x0e0d
loc_1558e 12 0e                            .short 0x120e
loc_15590 14 0d                            .short 0x140d
loc_15592 19 1e                            move.b  (a6)+,(a4)-
loc_15594 05 1d                            btst d2,(a5)+
loc_15596 09 1e                            btst d4,(a6)+
loc_15598 0b 1d                            btst d5,(a5)+
loc_1559a 0f 1e                            btst d7,(a6)+
loc_1559c 11 1d                            move.b  (a5)+,(a0)-
loc_1559e 15 1e                            move.b  (a6)+,(a2)-
loc_155a0 17 1d                            move.b  (a5)+,(a3)-
loc_155a2 19 00                            move.b  d0,(a4)-



loc_155a4: 03 0d 14 1d                      movepw (a5)(5149),d1
loc_155a8 1a 1d                            move.b  (a5)+,d5
loc_155aa 0e 03                            .short 0x0e03
loc_155ac 02 0e                            .short 0x020e
loc_155ae 02 1a 12 14                      andi.b  #$14,(a2)+
loc_155b2 06 0f                            .short 0x060f
loc_155b4 13 10                            move.b  (a0),(a1)-
loc_155b6 09 10                            btst d4,(a0)
loc_155b8 19 11                            move.b  (a1),(a4)-
loc_155ba 15 19                            move.b  (a1)+,(a2)-
loc_155bc 0f 18                            btst d7,(a0)+
loc_155be 13 00                            move.b  d0,(a1)-




loc_155c0: 03 0c 0e 0c                      movepw (a4)(3596),d1
loc_155c4 14 0c                            .short 0x140c
loc_155c6 1a 03                            move.b  d3,d5
loc_155c8 13 0e                            .short 0x130e
loc_155ca 13 14                            move.b  (a4),(a1)-
loc_155cc 13 1a                            move.b  (a2)+,(a1)-
loc_155ce 06 1a 0d 1a                      addi.b #26,(a2)+
loc_155d2 13 1a                            move.b  (a2)+,(a1)-
loc_155d4 19 1b                            move.b  (a3)+,(a4)-
loc_155d6 09 1b                            btst d4,(a3)+
loc_155d8 0f 1b                            btst d7,(a3)+
loc_155da 15 00                            move.b  d0,(a2)-




loc_155dc: 05 07                            btst d2,d7
loc_155de 0a 07 1a 0f                      eori.b #$F,d7
loc_155e2 16 17                            move.b  (sp),d3
loc_155e4 12 1f                            move.b  (sp)+,d1
loc_155e6 0e 05                            .short 0x0e05
loc_155e8 00 0e                            .short loc_e
loc_155ea 08 12 10 16                      btst    #22,(a2)
loc_155ee 18 0a                            .short 0x180a
loc_155f0 18 1a                            move.b  (a2)+,d4
loc_155f2 0e 05                            .short 0x0e05
loc_155f4 11 05                            move.b  d5,(a0)-
loc_155f6 19 06                            move.b  d6,(a4)-
loc_155f8 0b 06                            btst d5,d6
loc_155fa 13 0d                            .short 0x130d
loc_155fc 15 0d                            .short 0x150d
loc_155fe 19 0e                            .short 0x190e
loc_15600 07 0e 17 15                      movepw (a6)(5909),d3
loc_15604 11 16                            move.b  (a6),(a0)-
loc_15606 0b 17                            btst d5,(sp)
loc_15608 19 18                            move.b  (a0)+,(a4)-
loc_1560a 13 1d                            move.b  (a5)+,(a1)-
loc_1560c 19 1e                            move.b  (a6)+,(a4)-
loc_1560e 0f 00                            btst d7,d0




loc_15610: 06 06 0e 0b                      addi.b #11,d6
loc_15614 14 10                            move.b  (a0),d2
loc_15616 1a 16                            move.b  (a6),d5
loc_15618 1e 1b                            move.b  (a3)+,d7
loc_1561a 14 00                            move.b  d0,d2
loc_1561c 1a 00                            move.b  d0,d5
loc_1561e 02 08                            .short 0x0208
loc_15620 13 09                            .short 0x1309
loc_15622 0f 00                            btst d7,d0




loc_15624: 05 04                            btst d2,d4
loc_15626 0c 06 14 11                      cmpi.b  #$11,d6
loc_1562a 1a 13                            move.b  (a3),d5
loc_1562c 08 17 14 06                      btst    #6,(sp)
loc_15630 03 0c 0a 1a                      movepw (a4)(2586),d1
loc_15634 0b 0e 16 1a                      movepw (a6)(5658),d5
loc_15638 1b 10                            move.b  (a0),(a5)-
loc_1563a 1a 14                            move.b  (a4),d5
loc_1563c 04 0d                            .short 0x040d
loc_1563e 0d 0d 19 0e                      movepw (a5)(6414),d6
loc_15642 09 0e 15 00                      movepw (a6)(5376),d4


loc_15646: 04 19 10 0d                      subi.b #$D,(a1)+
loc_1564a 0b 09 15 1d                      movepw (a1)(5405),d5
loc_1564e 1a 04                            move.b  d4,d5
loc_15650 02 1a 16 15                      andi.b  #21,(a2)+
loc_15654 12 0b                            .short 0x120b
loc_15656 06 10 08 06                      addi.b #6,(a0)
loc_1565a 14 06                            move.b  d6,d2
loc_1565c 19 07                            move.b  d7,(a4)-
loc_1565e 11 07                            move.b  d7,(a0)-
loc_15660 16 19                            move.b  (a1)+,d3
loc_15662 14 19                            move.b  (a1)+,d2
loc_15664 19 1a                            move.b  (a2)+,(a4)-
loc_15666 11 1a                            move.b  (a2)+,(a0)-
loc_15668 16 00                            move.b  d0,d3


loc_1566a: 06 07 0c 07                      addi.b #7,d7
loc_1566e 12 13                            move.b  (a3),d1
loc_15670 07 13                            btst d3,(a3)
loc_15672 0d 13                            btst d6,(a3)
loc_15674 13 13                            move.b  (a3),(a1)-
loc_15676 1a 0a                            .short 0x1a0a
loc_15678 06 06 06 0c                      addi.b #$C,d6
loc_1567c 06 12 06 1a                      addi.b #26,(a2)
loc_15680 0c 07 0c 0d                      cmpi.b  #$D,d7
loc_15684 0c 13 19 08                      cmpi.b  #8,(a3)
loc_15688 18 0e                            .short 0x180e
loc_1568a 18 14                            move.b  (a4),d4
loc_1568c 0a 00 0b 00                      eori.b #0,d0
loc_15690 17 0f                            .short 0x170f
loc_15692 0c 0f                            .short 0x0c0f
loc_15694 12 0f                            .short 0x120f
loc_15696 19 10                            move.b  (a0),(a4)-
loc_15698 08 10 0e 10                      btst    #$10,(a0)
loc_1569c 14 1f                            move.b  (sp)+,d2
loc_1569e 0f 1f                            btst d7,(sp)+
loc_156a0 19 00                            move.b  d0,(a4)-


loc_156a2: 05 01                            btst d2,d1
loc_156a4 09 08 1a 0a                      movepw (a0)(6666),d4
loc_156a8 16 0c                            .short 0x160c
loc_156aa 11 10                            move.b  (a0),(a0)-
loc_156ac 0d 05                            btst d6,d5
loc_156ae 0f 0d 13 11                      movepw (a5)(4881),d7
loc_156b2 15 16                            move.b  (a6),(a2)-
loc_156b4 17 1a                            move.b  (a2)+,(a3)-
loc_156b6 1e 09                            .short 0x1e09
loc_156b8 0a 0d                            .short 0x0a0d
loc_156ba 19 0e                            .short 0x190e
loc_156bc 15 0f                            .short 0x150f
loc_156be 0c 0f                            .short 0x0c0f
loc_156c0 10 10                            move.b  (a0),d0
loc_156c2 05 10                            btst d2,(a0)
loc_156c4 0e 11                            .short 0x0e11
loc_156c6 12 11                            move.b  (a1),d1
loc_156c8 17 13                            move.b  (a3),(a3)-
loc_156ca 08 14 05 00                      btst    #0,(a4)
loc_156ce: 08 02 11 06                      btst    #6,d2
loc_156d2 07 06                            btst d3,d6
loc_156d4 1a 0e                            .short 0x1a0e
loc_156d6 16 12                            move.b  (a2),d3
loc_156d8 11 1a                            move.b  (a2)+,(a0)-
loc_156da 1a 1e                            move.b  (a6)+,d5
loc_156dc 15 15                            move.b  (a5),(a2)-
loc_156de 09 09 01 15                      movepw (a1)(277),d4
loc_156e2 05 1a                            btst d2,(a2)+
loc_156e4 06 0d                            .short 0x060d
loc_156e6 0d 11                            btst d6,(a1)
loc_156e8 11 16                            move.b  (a6),(a0)-
loc_156ea 19 1a                            move.b  (a2)+,(a4)-
loc_156ec 1d 11                            move.b  (a1),(a6)-
loc_156ee 19 0d                            .short 0x190d
loc_156f0 14 09                            .short 0x1409
loc_156f2 10 00                            move.b  d0,d0
loc_156f4 08 00 16 03                      btst    #3,d0
loc_156f8 19 04                            move.b  d4,(a4)-
loc_156fa 12 08                            .short 0x1208
loc_156fc 0c 09                            .short 0x0c09
loc_156fe 08 0c                            .short 0x080c
loc_15700 15 0c                            .short 0x150c
loc_15702 19 0d                            .short 0x190d
loc_15704 12 12                            move.b  (a2),d1
loc_15706 15 13                            move.b  (a3),(a2)-
loc_15708 12 13                            move.b  (a3),d1
loc_1570a 17 1b                            move.b  (a3)+,(a3)-
loc_1570c 19 1c                            move.b  (a4)+,(a4)-
loc_1570e 12 1f                            move.b  (sp)+,d1
loc_15710 14 1f                            move.b  (sp)+,d2
loc_15712 19 00                            move.b  d0,(a4)-


loc_15714: 04 04 10 09                      subi.b #9,d4
loc_15718 0a 1a 1a 1f                      eori.b #$1F,(a2)+
loc_1571c 16 04                            move.b  d4,d3
loc_1571e 00 16 05 1a                      ori.b #26,(a6)
loc_15722 16 0a                            .short 0x160a
loc_15724 1b 10                            move.b  (a0),(a5)-
loc_15726 0c 04 19 05                      cmpi.b  #5,d4
loc_1572a 11 09                            .short 0x1109
loc_1572c 19 0a                            .short 0x190a
loc_1572e 0b 0e 19 0f                      movepw (a6)(6415),d5
loc_15732 06 15 19 16                      addi.b #22,(a5)
loc_15736 0b 19                            btst d5,(a1)+
loc_15738 19 1a                            move.b  (a2)+,(a4)-
loc_1573a 11 1e                            move.b  (a6)+,(a0)-
loc_1573c 19 1f                            move.b  (sp)+,(a4)-
loc_1573e 17 00                            move.b  d0,(a3)-



loc_15740: 07 03                            btst d3,d3
loc_15742 0b 04                            btst d5,d4
loc_15744 16 09                            .short 0x1609
loc_15746 1a 12                            move.b  (a2),d5
loc_15748 15 16                            move.b  (a6),(a2)-
loc_1574a 11 1c                            move.b  (a4)+,(a0)-
loc_1574c 1a 15                            move.b  (a5),d5
loc_1574e 07 06                            btst d3,d6
loc_15750 00 0b                            .short loc_b
loc_15752 02 16 09 11                      andi.b  #$11,(a6)
loc_15756 1a 11                            move.b  (a1),d5
loc_15758 0f 07                            btst d7,d7
loc_1575a 0b 1a                            btst d5,(a2)+
loc_1575c 08 01 15 02                      btst    #2,d1
loc_15760 0c 07 19 08                      cmpi.b  #8,d7
loc_15764 17 0f                            .short 0x170f
loc_15766 0a 0f                            .short 0x0a0f
loc_15768 19 10                            move.b  (a0),(a4)-
loc_1576a 08 10 16 00                      btst    #0,(a0)



loc_1576e: 0a 02 12 06                      eori.b #6,d2
loc_15772 0e 0a                            .short 0x0e0a
loc_15774 0a 0a                            .short 0x0a0a
loc_15776 1a 0e                            .short 0x1a0e
loc_15778 16 1a                            move.b  (a2)+,d3
loc_1577a 1a 1e                            move.b  (a6)+,d5
loc_1577c 16 12                            move.b  (a2),d3
loc_1577e 12 16                            move.b  (a6),d1
loc_15780 0e 1a                            .short 0x0e1a
loc_15782 0a 0a                            .short 0x0a0a
loc_15784 01 16                            btst d0,(a6)
loc_15786 05 0a 05 1a                      movepw (a2)(1306),d2
loc_1578a 09 0e 0d 12                      movepw (a6)(3346),d4
loc_1578e 11 16                            move.b  (a6),(a0)-
loc_15790 15 0a                            .short 0x150a
loc_15792 1d 12                            move.b  (a2),(a6)-
loc_15794 15 1a                            move.b  (a2)+,(a2)-
loc_15796 19 0e                            .short 0x190e
loc_15798 1c 00                            move.b  d0,d6
loc_1579a 07 00                            btst d3,d0
loc_1579c 17 03                            move.b  d3,(a3)-
loc_1579e 11 03                            move.b  d3,(a0)-
loc_157a0 19 04                            move.b  d4,(a4)-
loc_157a2 0b 04                            btst d5,d4
loc_157a4 13 07                            move.b  d7,(a1)-
loc_157a6 19 08                            .short 0x1908
loc_157a8 0f 0b 11 0b                      movepw (a3)(4363),d7
loc_157ac 19 0c                            .short 0x190c
loc_157ae 0b 0c 13 0f                      movepw (a4)(4879),d5
loc_157b2 15 0f                            .short 0x150f
loc_157b4 19 10                            move.b  (a0),(a4)-
loc_157b6 07 10                            btst d3,(a0)
loc_157b8 17 13                            move.b  (a3),(a3)-
loc_157ba 11 13                            move.b  (a3),(a0)-
loc_157bc 19 14                            move.b  (a4),(a4)-
loc_157be 0b 14                            btst d5,(a4)
loc_157c0 13 17                            move.b  (sp),(a1)-
loc_157c2 19 18                            move.b  (a0)+,(a4)-
loc_157c4 0f 1b                            btst d7,(a3)+
loc_157c6 11 1b                            move.b  (a3)+,(a0)-
loc_157c8 19 1c                            move.b  (a4)+,(a4)-
loc_157ca 0b 1c                            btst d5,(a4)+
loc_157cc 13 1f                            move.b  (sp)+,(a1)-
loc_157ce 15 1f                            move.b  (sp)+,(a2)-
loc_157d0 19 00                            move.b  d0,(a4)-




loc_157d2: 04 03 0a 0f                      subi.b #$F,d3
loc_157d6 1a 14                            move.b  (a4),d5
loc_157d8 16 1d                            move.b  (a5)+,d3
loc_157da 10 04                            move.b  d4,d0
loc_157dc 02 10 0b 16                      andi.b  #22,(a0)
loc_157e0 10 1a                            move.b  (a2)+,d0
loc_157e2 1c 0a                            .short 0x1c0a
loc_157e4 0a 03 0f 04                      eori.b #4,d3
loc_157e8 0b 09 19 0a                      movepw (a1)(6410),d5
loc_157ec 17 0f                            .short 0x170f
loc_157ee 19 10                            move.b  (a0),(a4)-
loc_157f0 09 14                            btst d4,(a4)
loc_157f2 19 15                            move.b  (a5),(a4)-
loc_157f4 17 0a                            .short 0x170a
loc_157f6 0f 0b 0b 00                      movepw (a3)(2816),d7



loc_157fa: 05 0d 0c 0e                      movepw (a5)(3086),d2
loc_157fe 1a 19                            move.b  (a1)+,d5
loc_15800 0c 19 12 19                      cmpi.b  #25,(a1)+
loc_15804 1a 05                            move.b  d5,d5
loc_15806 0a 16 12 0c                      eori.b #$C,(a6)
loc_1580a 1f 0c                            .short 0x1f0c
loc_1580c 1f 12                            move.b  (a2),-(sp)
loc_1580e 1e 16                            move.b  (a6),d7
loc_15810 08 00 15 01                      btst    #1,d0
loc_15814 13 03                            move.b  d3,(a1)-
loc_15816 0b 06                            btst d5,d6
loc_15818 07 13                            btst d3,(a3)
loc_1581a 17 14                            move.b  (a4),(a3)-
loc_1581c 13 15                            move.b  (a5),(a1)-
loc_1581e 0b 16                            btst d5,(a6)
loc_15820 07 00                            btst d3,d0


loc_15822: 05 00                            btst d2,d0
loc_15824 1a 03                            move.b  d3,d5
loc_15826 15 06                            move.b  d6,(a2)-
loc_15828 10 09                            .short 0x1009
loc_1582a 0c 0c                            .short 0x0c0c
loc_1582c 08 05 13 08                      btst    #8,d5
loc_15830 16 0c                            .short 0x160c
loc_15832 19 10                            move.b  (a0),(a4)-
loc_15834 1c 15                            move.b  (a5),d6
loc_15836 1f 1a                            move.b  (a2)+,-(sp)
loc_15838 0a 09                            .short 0x0a09
loc_1583a 14 0a                            .short 0x140a
loc_1583c 11 0f                            .short 0x110f
loc_1583e 07 0f 0b 0f                      movepw (sp)(2831),d3
loc_15842 0f 10                            btst d7,(a0)
loc_15844 05 10                            btst d2,(a0)
loc_15846 09 10                            btst d4,(a0)
loc_15848 0d 14                            btst d6,(a4)
loc_1584a 19 15                            move.b  (a5),(a4)-
loc_1584c 16 00                            move.b  d0,d3


loc_1584e: 07 00                            btst d3,d0
loc_15850 11 04                            move.b  d4,(a0)-
loc_15852 0a 0f                            .short 0x0a0f
loc_15854 15 15                            move.b  (a5),(a2)-
loc_15856 10 15                            move.b  (a5),d0
loc_15858 1a 1a                            move.b  (a2)+,d5
loc_1585a 0a 1b 16 07                      eori.b #7,(a3)+
loc_1585e 04 16 05 0a                      subi.b #$A,(a6)
loc_15862 0a 10 0a 1a                      eori.b #26,(a0)
loc_15866 10 15                            move.b  (a5),d0
loc_15868 1b 0a                            .short 0x1b0a
loc_1586a 1f 11                            move.b  (a1),-(sp)
loc_1586c 0c 05 15 05                      cmpi.b  #5,d5
loc_15870 19 06                            move.b  d6,(a4)-
loc_15872 0b 07                            btst d5,d7
loc_15874 17 09                            .short 0x1709
loc_15876 0f 0a 05 0d                      movepw (a2)(1293),d7
loc_1587a 19 0e                            .short 0x190e
loc_1587c 16 15                            move.b  (a5),d3
loc_1587e 0f 16                            btst d7,(a6)
loc_15880 05 19                            btst d2,(a1)+
loc_15882 15 1a                            move.b  (a2)+,(a2)-
loc_15884 0b 00                            btst d5,d0



loc_15886: 05 02                            btst d2,d2
loc_15888 14 05                            move.b  d5,d2
loc_1588a 0f 07                            btst d7,d7
loc_1588c 1a 08                            .short 0x1a08
loc_1588e 0a 1f 1a 05                      eori.b #5,(sp)+
loc_15892 00 1a 17 0a                      ori.b #$A,(a2)+
loc_15896 18 1a                            move.b  (a2)+,d4
loc_15898 1a 0f                            .short 0x1a0f
loc_1589a 1d 14                            move.b  (a4),(a6)-
loc_1589c 04 0b                            .short 0x040b
loc_1589e 19 0c                            .short 0x190c
loc_158a0 17 13                            move.b  (a3),(a3)-
loc_158a2 19 14                            move.b  (a4),(a4)-
loc_158a4 17 00                            move.b  d0,(a3)-


loc_158a6: 05 1e                            btst d2,(a6)+
loc_158a8 1a 02                            move.b  d2,d5
loc_158aa 11 0c                            .short 0x110c
loc_158ac 15 1d                            move.b  (a5)+,(a2)-
loc_158ae 15 1b                            move.b  (a3)+,(a2)-
loc_158b0 11 03                            move.b  d3,(a0)-
loc_158b2 01 1a                            btst d0,(a2)+
loc_158b4 0d 0d 1e 09                      movepw (a5)(7689),d6
loc_158b8 06 07 0c 08                      addi.b #8,d7
loc_158bc 0a 15 10 16                      eori.b #22,(a5)
loc_158c0 0e 1a                            .short 0x0e1a
loc_158c2 19 1b                            move.b  (a3)+,(a4)-
loc_158c4 16 00                            move.b  d0,d3


loc_158c6: 06 0f                            .short 0x060f
loc_158c8 15 02                            move.b  d2,(a2)-
loc_158ca 1a 06                            move.b  d6,d5
loc_158cc 15 0a                            .short 0x150a
loc_158ce 11 0e                            .short 0x110e
loc_158d0 0d 13                            btst d6,(a3)
loc_158d2 09 02                            btst d4,d2
loc_158d4 14 09                            .short 0x1409
loc_158d6 1a 1a                            move.b  (a2)+,d5
loc_158d8 04 15 19 16                      subi.b #22,(a5)
loc_158dc 16 17                            move.b  (sp),d3
loc_158de 04 18 01 00                      subi.b #0,(a0)+


loc_158e2: 05 00                            btst d2,d0
loc_158e4 09 00                            btst d4,d0
loc_158e6 11 00                            move.b  d0,(a0)-
loc_158e8 1a 0f                            .short 0x1a0f
loc_158ea 0d 0f 15 05                      movepw (sp)(5381),d6
loc_158ee 10 0d                            .short 0x100d
loc_158f0 10 15                            move.b  (a5),d0
loc_158f2 1f 09                            .short 0x1f09
loc_158f4 1f 11                            move.b  (a1),-(sp)
loc_158f6 1f 1a                            move.b  (a2)+,-(sp)
loc_158f8 0a 08                            .short 0x0a08
loc_158fa 0c 08                            .short 0x0c08
loc_158fc 14 09                            .short 0x1409
loc_158fe 0a 09                            .short 0x0a09
loc_15900 12 17                            move.b  (sp),d1
loc_15902 08 17 10 17                      btst    #23,(sp)
loc_15906 19 18                            move.b  (a0)+,(a4)-
loc_15908 06 18 0e 18                      addi.b #$18(a0)+
loc_1590c 16 00                            move.b  d0,d3


loc_1590e: 04 05 15 09                      subi.b #9,d5
loc_15912 0f 1f                            btst d7,(sp)+
loc_15914 0a 00 1a 02                      eori.b #2,d0
loc_15918 1d 0a                            .short 0x1d0a
loc_1591a 1f 1a                            move.b  (a2)+,-(sp)
loc_1591c 06 12 09 12                      addi.b #18,(a2)
loc_15920 14 13                            move.b  (a3),d2
loc_15922 06 13 10 19                      addi.b #25,(a3)
loc_15926 19 1a                            move.b  (a2)+,(a4)-
loc_15928 16 00                            move.b  d0,d3


loc_1592a: 08 01 09 05                      btst    #5,d1
loc_1592e 14 0b                            .short 0x140b
loc_15930 0f 11                            btst d7,(a1)
loc_15932 09 0f 1a 15                      movepw (sp)(6677),d4
loc_15936 14 1b                            move.b  (a3)+,d2
loc_15938 0f 1f                            btst d7,(sp)+
loc_1593a 1a 02                            move.b  d2,d5
loc_1593c 00 09                            .short loc_9
loc_1593e 10 09                            .short 0x1009
loc_15940 00 00

loc_15942:
04 03                      ori.b #3,d0
loc_15944 1a 0c                            .short 0x1a0c
loc_15946 0a 0c                            .short 0x0a0c
loc_15948 10 0d                            .short 0x100d
loc_1594a 15 04                            move.b  d4,(a2)-
loc_1594c 11 15                            move.b  (a5),(a0)-
loc_1594e 12 0a                            .short 0x120a
loc_15950 12 10                            move.b  (a0),d1
loc_15952 1b 1a                            move.b  (a2)+,(a5)-
loc_15954 06 13 14 13                      addi.b #$13,(a3)
loc_15958 19 14                            move.b  (a4),(a4)-
loc_1595a 11 14                            move.b  (a4),(a0)-
loc_1595c 16 09                            .short 0x1609
loc_1595e 14 0a                            .short 0x140a
loc_15960 11 00                            move.b  d0,(a0)-



loc_15962: 04 00 13 0a                      subi.b #$A,d0
loc_15966 13 0e                            .short 0x130e
loc_15968 1a 0e                            .short 0x1a0e
loc_1596a 0c 04 11 1a                      cmpi.b  #26,d4
loc_1596e 15 13                            move.b  (a3),(a2)-
loc_15970 1f 13                            move.b  (a3),-(sp)
loc_15972 11 0c                            .short 0x110c
loc_15974 06 0a                            .short 0x060a
loc_15976 12 0b                            .short 0x120b
loc_15978 06 0f                            .short 0x060f
loc_1597a 19 10                            move.b  (a0),(a4)-
loc_1597c 0d 1b                            btst d6,(a3)+
loc_1597e 19 1c                            move.b  (a4)+,(a4)-
loc_15980 14 00                            move.b  d0,d2



loc_15982: 08 06 07 06                      btst    #6,d6
loc_15986 0d 06                            btst d6,d6
loc_15988 13 06                            move.b  d6,(a1)-
loc_1598a 1a 16                            move.b  (a6),d5
loc_1598c 0a 16 10 16                      eori.b #22,(a6)
loc_15990 16 1d                            move.b  (a5)+,d3
loc_15992 07 08 0a 0a                      movepw (a0)(2570),d3
loc_15996 0a 10 0a 16                      eori.b #22,(a0)
loc_1599a 1a 07                            move.b  d7,d5
loc_1599c 1a 0d                            .short 0x1a0d
loc_1599e 1a 13                            move.b  (a3),d5
loc_159a0 1a 1a                            move.b  (a2)+,d5
loc_159a2 02 07 08 05                      andi.b  #5,d7
loc_159a6 19 06                            move.b  d6,(a4)-
loc_159a8 14 0a                            .short 0x140a
loc_159aa 19 0b                            .short 0x190b
loc_159ac 17 15                            move.b  (a5),(a3)-
loc_159ae 19 16                            move.b  (a6),(a4)-
loc_159b0 17 1a                            move.b  (a2)+,(a3)-
loc_159b2 19 1b                            move.b  (a3)+,(a4)-
loc_159b4 14 00                            move.b  d0,d2


loc_159b6: 08 05 0c 05                      btst    #5,d5
loc_159ba 13 0e                            .short 0x130e
loc_159bc 0c 0e                            .short 0x0c0e
loc_159be 13 0e                            .short 0x130e
loc_159c0 1a 14                            move.b  (a4),d5
loc_159c2 0c 14 13 18                      cmpi.b  #$18(a4)
loc_159c6 1a 08                            .short 0x1a08
loc_159c8 08 1a 0c 0c                      btst    #$C,(a2)+
loc_159cc 0c 13 12 0c                      cmpi.b  #$C,(a3)
loc_159d0 12 13                            move.b  (a3),d1
loc_159d2 12 1a                            move.b  (a2)+,d1
loc_159d4 1b 0c                            .short 0x1b0c
loc_159d6 1b 13                            move.b  (a3),(a5)-
loc_159d8 02 1b 16 1c                      andi.b  #$1C,(a3)+
loc_159dc 14 00                            move.b  d0,d2


loc_159de: 04 09                            .short 0x0409
loc_159e0 1a 09                            .short 0x1a09
loc_159e2 08 11 16 1d                      btst    #29,(a1)
loc_159e6 1a 08                            .short 0x1a08
loc_159e8 02 13 03 0c                      andi.b  #$C,(a3)
loc_159ec 0e 16                            .short 0x0e16
loc_159ee 12 0c                            .short 0x120c
loc_159f0 16 1a                            move.b  (a2)+,d3
loc_159f2 17 08                            .short 0x1708
loc_159f4 17 13                            move.b  (a3),(a3)-
loc_159f6 1d 0c                            .short 0x1d0c
loc_159f8 04 0e                            .short 0x040e
loc_159fa 19 0f                            .short 0x190f
loc_159fc 17 11                            move.b  (a1),(a3)-
loc_159fe 0b 12                            btst d5,(a2)
loc_15a00 05 00                            btst d2,d0



loc_15a02: 06 01 14 02                      addi.b #2,d1
loc_15a06 1a 0b                            .short 0x1a0b
loc_15a08 14 0e                            .short 0x140e
loc_15a0a 1a 17                            move.b  (sp),d5
loc_15a0c 14 18                            move.b  (a0)+,d2
loc_15a0e 1a 06                            move.b  d6,d5
loc_15a10 07 1a                            btst d3,(a2)+
loc_15a12 08 14 11 1a                      btst    #26,(a4)
loc_15a16 14 14                            move.b  (a4),d2
loc_15a18 1d 1a                            move.b  (a2)+,(a6)-
loc_15a1a 1e 14                            move.b  (a4),d7
loc_15a1c 08 00 15 09                      btst    #9,d0
loc_15a20 19 0a                            .short 0x190a
loc_15a22 15 0f                            .short 0x150f
loc_15a24 19 10                            move.b  (a0),(a4)-
loc_15a26 0e 15                            .short 0x0e15
loc_15a28 19 16                            move.b  (a6),(a4)-
loc_15a2a 15 1f                            move.b  (sp)+,(a2)-
loc_15a2c 19 00                            move.b  d0,(a4)-


loc_15a2e: 04 0b                            .short 0x040b
loc_15a30 08 14 0d 14                      btst    #$14,(a4)
loc_15a34 16 0a                            .short 0x160a
loc_15a36 11 02                            move.b  d2,(a0)-
loc_15a38 0b 11                            btst d5,(a1)
loc_15a3a 0b 1a                            btst d5,(a2)+
loc_15a3c 04 00 17 06                      subi.b #6,d0
loc_15a40 07 07                            btst d3,d7
loc_15a42 05 1f                            btst d2,(sp)+
loc_15a44 19 00                            move.b  d0,(a4)-
loc_15a46: 12 03                            move.b  d3,d1


loc_15a48 08 03 10 03                      btst    #3,d3
loc_15a4c 1a 07                            move.b  d7,d5
loc_15a4e 0c 07 14 0b                      cmpi.b  #11,d7
loc_15a52 08 0b                            .short 0x080b
loc_15a54 10 0b                            .short 0x100b
loc_15a56 1a 1b                            move.b  (a3)+,d5
loc_15a58 1a 0f                            .short 0x1a0f
loc_15a5a 0c 0f                            .short 0x0c0f
loc_15a5c 14 13                            move.b  (a3),d2
loc_15a5e 08 13 10 13                      btst    #$13,(a3)
loc_15a62 1a 17                            move.b  (sp),d5
loc_15a64 0c 17 14 1b                      cmpi.b  #27,(sp)
loc_15a68 08 1b 10 14                      btst    #$14,(a3)+
loc_15a6c 01 0c 01 14                      movepw (a4)(276),d0
loc_15a70 05 08 05 10                      movepw (a0)(1296),d2
loc_15a74 05 1a                            btst d2,(a2)+
loc_15a76 09 0c 09 14                      movepw (a4)(2324),d4
loc_15a7a 0d 08 0d 10                      movepw (a0)(3344),d6
loc_15a7e 0d 1a                            btst d6,(a2)+
loc_15a80 11 0c                            .short 0x110c
loc_15a82 11 14                            move.b  (a4),(a0)-
loc_15a84 15 08                            .short 0x1508
loc_15a86 15 10                            move.b  (a0),(a2)-
loc_15a88 15 1a                            move.b  (a2)+,(a2)-
loc_15a8a 19 0c                            .short 0x190c
loc_15a8c 19 14                            move.b  (a4),(a4)-
loc_15a8e 1d 08                            .short 0x1d08
loc_15a90 1d 10                            move.b  (a0),(a6)-
loc_15a92 1d 1a                            move.b  (a2)+,(a6)-
loc_15a94 28 00                            move.l  d0,d4
loc_15a96 05 00                            btst d2,d0
loc_15a98 0d 00                            btst d6,d0
loc_15a9a 15 04                            move.b  d4,(a2)-
loc_15a9c 0f 04                            btst d7,d4
loc_15a9e 19 05                            move.b  d5,(a4)-
loc_15aa0 09 05                            btst d4,d5
loc_15aa2 11 07                            move.b  d7,(a0)-
loc_15aa4 0b 07                            btst d5,d7
loc_15aa6 13 07                            move.b  d7,(a1)-
loc_15aa8 19 08                            .short 0x1908
loc_15aaa 05 08 0d 08                      movepw (a0)(3336),d2
loc_15aae 15 0b                            .short 0x150b
loc_15ab0 0f 0b 19 0c                      movepw (a3)(6412),d7
loc_15ab4 09 0c 11 0f                      movepw (a4)(4367),d4
loc_15ab8 0b 0f 13 0f                      movepw (sp)(4879),d5
loc_15abc 19 10                            move.b  (a0),(a4)-
loc_15abe 05 10                            btst d2,(a0)
loc_15ac0 0d 10                            btst d6,(a0)
loc_15ac2 15 13                            move.b  (a3),(a2)-
loc_15ac4 0f 13                            btst d7,(a3)
loc_15ac6 19 14                            move.b  (a4),(a4)-
loc_15ac8 09 14                            btst d4,(a4)
loc_15aca 11 18                            move.b  (a0)+,(a0)-
loc_15acc 0b 17                            btst d5,(sp)
loc_15ace 13 17                            move.b  (sp),(a1)-
loc_15ad0 19 19                            move.b  (a1)+,(a4)-
loc_15ad2 05 18                            btst d2,(a0)+
loc_15ad4 0d 18                            btst d6,(a0)+
loc_15ad6 15 1b                            move.b  (a3)+,(a2)-
loc_15ad8 0f 1b                            btst d7,(a3)+
loc_15ada 19 1c                            move.b  (a4)+,(a4)-
loc_15adc 09 1c                            btst d4,(a4)+
loc_15ade 11 1f                            move.b  (sp)+,(a0)-
loc_15ae0 0b 1f                            btst d5,(sp)+
loc_15ae2 13 1f                            move.b  (sp)+,(a1)-
loc_15ae4 19 00                            move.b  d0,(a4)-



loc_15ae6: 00 0c                            .short loc_c
loc_15ae8 01 0c 09 0c                      movepw (a4)(2316),d0
loc_15aec 11 0c                            .short 0x110c
loc_15aee 19 0c                            .short 0x190c
loc_15af0 04 13 0c 13                      subi.b #$13,(a3)
loc_15af4 14 13                            move.b  (a3),d2
loc_15af6 1c 13                            move.b  (a3),d6
loc_15af8 07 1a                            btst d3,(a2)+
loc_15afa 0f 1a                            btst d7,(a2)+
loc_15afc 17 1a                            move.b  (a2)+,(a3)-
loc_15afe 1f 1a                            move.b  (a2)+,-(sp)
loc_15b00 00 00


loc_15B02:
02 0b                      ori.b #11,d0
loc_15b04 1a 19                            move.b  (a1)+,d5
loc_15b06 1a 03                            move.b  d3,d5
loc_15b08 02 13 0e 1a                      andi.b  #26,(a3)
loc_15b0c 18 0c                            .short 0x180c
loc_15b0e 06 03 19 04                      addi.b #4,d3
loc_15b12 14 0f                            .short 0x140f
loc_15b14 19 10                            move.b  (a0),(a4)-
loc_15b16 06 18 19 19                      addi.b #25,(a0)+
loc_15b1a 0d 00                            btst d6,d0
loc_15b1c: 07 01                            btst d3,d1
loc_15b1e 11 03                            move.b  d3,(a0)-
loc_15b20 1a 09                            .short 0x1a09
loc_15b22 0b 0a 16 0e                      movepw (a2)(5646),d5
loc_15b26 1a 12                            move.b  (a2),d5
loc_15b28 10 19                            move.b  (a1)+,d0
loc_15b2a 0b 06                            btst d5,d6
loc_15b2c 07 0b 0e 10                      movepw (a3)(3600),d3
loc_15b30 16 16                            move.b  (a6),d3
loc_15b32 17 0b                            .short 0x170b
loc_15b34 1d 1a                            move.b  (a2)+,(a6)-
loc_15b36 1f 11                            move.b  (a1),-(sp)
loc_15b38 0c 01 09 01                      cmpi.b  #1,d1
loc_15b3c 15 07                            move.b  d7,(a2)-
loc_15b3e 19 08                            .short 0x1908
loc_15b40 0f 0f 0f 0f                      movepw (sp)(3855),d7
loc_15b44 19 11                            move.b  (a1),(a4)-
loc_15b46 09 11                            btst d4,(a1)
loc_15b48 11 17                            move.b  (sp),(a0)-
loc_15b4a 19 19                            move.b  (a1)+,(a4)-
loc_15b4c 0f 1f                            btst d7,(sp)+
loc_15b4e 10 1f                            move.b  (sp)+,d0
loc_15b50 19 00                            move.b  d0,(a4)-



loc_15b52: 07 02                            btst d3,d2
loc_15b54 13 05                            move.b  d5,(a1)-
loc_15b56 0c 06 1a 09                      cmpi.b  #9,d6
loc_15b5a 16 0c                            .short 0x160c
loc_15b5c 0f 0d 1a 1f                      movepw (a5)(6687),d7
loc_15b60 1a 06                            move.b  d6,d5
loc_15b62 00 1a 13 0f                      ori.b #$F,(a2)+
loc_15b66 16 16                            move.b  (a6),d3
loc_15b68 19 1a                            move.b  (a2)+,(a4)-
loc_15b6a 1a 0c                            .short 0x1a0c
loc_15b6c 1d 13                            move.b  (a3),(a6)-
loc_15b6e 00 00


loc_15B70: 04 0f                      ori.b #$F,d0
loc_15b72 0c 13 1a 18                      cmpi.b  #$18(a3)
loc_15b76 13 1f                            move.b  (sp)+,(a1)-
loc_15b78 0c 04 01 0c                      cmpi.b  #$C,d4
loc_15b7c 08 13 0d 1a                      btst    #26,(a3)
loc_15b80 11 0c                            .short 0x110c
loc_15b82 08 02 12 03                      btst    #3,d2
loc_15b86 10 0b                            .short 0x100b
loc_15b88 0b 0f 12 0f                      movepw (sp)(4623),d5
loc_15b8c 19 11                            move.b  (a1),(a4)-
loc_15b8e 10 11                            move.b  (a1),d0
loc_15b90 16 16                            move.b  (a6),d3
loc_15b92 09 00                            btst d4,d0

loc_15b94 00 01 40 00                      ori.b #0,d1
loc_15b98 ff fe                            .short 0xfffe
loc_15b9a 00 00 00 01                      ori.b #1,d0
loc_15b9e 00 00 ff fd                      ori.b #-3,d0
loc_15ba2 80 00                            or.b d0,d0
loc_15ba4 00 01 00 00                      ori.b #0,d1
loc_15ba8 ff fd                            .short 0xfffd
loc_15baa 80 00                            or.b d0,d0
loc_15bac 00 01 40 00                      ori.b #0,d1
loc_15bb0 ff fd                            .short 0xfffd
loc_15bb2 80 00                            or.b d0,d0
loc_15bb4 00 01 40 00                      ori.b #0,d1
loc_15bb8 ff fe                            .short 0xfffe
loc_15bba 00 00 00 01                      ori.b #1,d0
loc_15bbe 40 00                            negxb d0
loc_15bc0 ff fd                            .short 0xfffd
loc_15bc2 80 00                            or.b d0,d0
loc_15bc4 00 01 40 00                      ori.b #0,d1
loc_15bc8 ff fd                            .short 0xfffd
loc_15bca 80 00                            or.b d0,d0
loc_15bcc 00 01 40 00                      ori.b #0,d1
loc_15bd0 ff fd                            .short 0xfffd
loc_15bd2 80 00                            or.b d0,d0
loc_15bd4 00 01 80 00                      ori.b #0,d1
loc_15bd8 ff fd                            .short 0xfffd
loc_15bda e0 00                            asrb #8,d0
loc_15bdc 00 01 40 00                      ori.b #0,d1
loc_15be0 ff fd                            .short 0xfffd
loc_15be2 80 00                            or.b d0,d0
loc_15be4 00 01 40 00                      ori.b #0,d1
loc_15be8 ff fd                            .short 0xfffd
loc_15bea 80 00                            or.b d0,d0
loc_15bec 00 00 48 00                      ori.b #0,d0
loc_15bf0 ff fd                            .short 0xfffd
loc_15bf2 90 00                            sub.b d0,d0
loc_15bf4 00 00 c0 00                      ori.b #0,d0
loc_15bf8 ff fd                            .short 0xfffd
loc_15bfa e0 00                            asrb #8,d0
loc_15bfc 00 00 80 00                      ori.b #0,d0
loc_15c00 ff fd                            .short 0xfffd
loc_15c02 80 00                            or.b d0,d0
loc_15c04 00 00 80 00                      ori.b #0,d0
loc_15c08 ff fd                            .short 0xfffd
loc_15c0a 80 00                            or.b d0,d0
loc_15c0c 00 01 00 00                      ori.b #0,d1
loc_15c10 ff fd                            .short 0xfffd
loc_15c12 80 00                            or.b d0,d0
loc_15c14 00 01 00 00                      ori.b #0,d1
loc_15c18 ff fe                            .short 0xfffe
loc_15c1a 00 00 00 00                      ori.b #0,d0
loc_15c1e a0 00                            .short 0xa000
loc_15c20 ff fd                            .short 0xfffd
loc_15c22 50 00                            addq.b  #8,d0
loc_15c24 00 00 a0 00                      ori.b #0,d0
loc_15c28 ff fd                            .short 0xfffd
loc_15c2a 50 00                            addq.b  #8,d0
loc_15c2c 00 01 00 00                      ori.b #0,d1
loc_15c30 ff fd                            .short 0xfffd
loc_15c32 90 00                            sub.b d0,d0
loc_15c34 00 00 80 00                      ori.b #0,d0
loc_15c38 ff fd                            .short 0xfffd
loc_15c3a c0 00                            and.b d0,d0
loc_15c3c 00 00 a0 00                      ori.b #0,d0
loc_15c40 ff fd                            .short 0xfffd
loc_15c42 80 00                            or.b d0,d0
loc_15c44 00 00 a0 00                      ori.b #0,d0
loc_15c48 ff fd                            .short 0xfffd
loc_15c4a 80 00                            or.b d0,d0
loc_15c4c 00 00 70 00                      ori.b #0,d0
loc_15c50 ff fd                            .short 0xfffd
loc_15c52 80 00                            or.b d0,d0
loc_15c54 00 01 a0 00                      ori.b #0,d1
loc_15c58 ff fd                            .short 0xfffd
loc_15c5a c0 00                            and.b d0,d0
loc_15c5c 00 00 80 00                      ori.b #0,d0
loc_15c60 ff fd                            .short 0xfffd
loc_15c62 80 00                            or.b d0,d0
loc_15c64 00 00 80 00                      ori.b #0,d0
loc_15c68 ff fd                            .short 0xfffd
loc_15c6a 80 00                            or.b d0,d0
loc_15c6c 00 01 00 00                      ori.b #0,d1
loc_15c70 ff fd                            .short 0xfffd
loc_15c72 c0 00                            and.b d0,d0
loc_15c74 00 00 a0 00                      ori.b #0,d0
loc_15c78 ff fd                            .short 0xfffd
loc_15c7a 80 00                            or.b d0,d0
loc_15c7c 00 00 c0 00                      ori.b #0,d0
loc_15c80 ff fd                            .short 0xfffd
loc_15c82 80 00                            or.b d0,d0
loc_15c84 00 00 c0 00                      ori.b #0,d0
loc_15c88 ff fd                            .short 0xfffd
loc_15c8a 80 00                            or.b d0,d0
loc_15c8c 00 01 00 00                      ori.b #0,d1
loc_15c90 ff fd                            .short 0xfffd
loc_15c92 80 00                            or.b d0,d0
loc_15c94 00 00 80 00                      ori.b #0,d0
loc_15c98 ff fd                            .short 0xfffd
loc_15c9a 00 00 00 01                      ori.b #1,d0
loc_15c9e 00 00 ff fe                      ori.b #-2,d0
loc_15ca2 00 00 00 01                      ori.b #1,d0
loc_15ca6 00 00 ff fe                      ori.b #-2,d0
loc_15caa 00 00 00 00                      ori.b #0,d0
loc_15cae 80 00                            or.b d0,d0
loc_15cb0 ff fd                            .short 0xfffd
loc_15cb2 30 00                            move.w  d0,d0
loc_15cb4 00 00 a0 00                      ori.b #0,d0
loc_15cb8 ff fd                            .short 0xfffd
loc_15cba 40 00                            negxb d0
loc_15cbc 00 00 a0 00                      ori.b #0,d0
loc_15cc0 ff fd                            .short 0xfffd
loc_15cc2 00 00 00 00                      ori.b #0,d0
loc_15cc6 a0 00                            .short 0xa000
loc_15cc8 ff fd                            .short 0xfffd
loc_15cca 00 00 00 00                      ori.b #0,d0
loc_15cce c0 00                            and.b d0,d0
loc_15cd0 ff fd                            .short 0xfffd
loc_15cd2 80 00                            or.b d0,d0
loc_15cd4 00 00 80 00                      ori.b #0,d0
loc_15cd8 ff fd                            .short 0xfffd
loc_15cda 80 00                            or.b d0,d0
loc_15cdc 00 00 60 00                      ori.b #0,d0
loc_15ce0 ff fd                            .short 0xfffd
loc_15ce2 20 00                            move.l  d0,d0
loc_15ce4 00 01 00 00                      ori.b #0,d1
loc_15ce8 ff fe                            .short 0xfffe
loc_15cea 00 00 00 01                      ori.b #1,d0
loc_15cee 00 00 ff fd                      ori.b #-3,d0
loc_15cf2 00 00 00 00                      ori.b #0,d0
loc_15cf6 c0 00                            and.b d0,d0
loc_15cf8 ff fd                            .short 0xfffd
loc_15cfa 40 00                            negxb d0
loc_15cfc 00 00 60 00                      ori.b #0,d0
loc_15d00 ff fd                            .short 0xfffd
loc_15d02 20 00                            move.l  d0,d0
loc_15d04 00 00 60 00                      ori.b #0,d0
loc_15d08 ff fd                            .short 0xfffd
loc_15d0a 20 00                            move.l  d0,d0
loc_15d0c 00 00 c0 00                      ori.b #0,d0
loc_15d10 ff fd                            .short 0xfffd
loc_15d12 40 00                            negxb d0


loc_15d14: 00 01 00 00                      ori.b #0,d1
loc_15d18 00 01 40 00                      ori.b #0,d1
loc_15d1c 00 01 20 00                      ori.b #0,d1
loc_15d20 00 00 e0 00                      ori.b #0,d0
loc_15d24 00 01 60 00                      ori.b #0,d1



loc_15d28: 00 00 00 01                      ori.b #1,d0
loc_15d2c 04 00 00 02                      subi.b #2,d0
loc_15d30 02 02 00 00                      andi.b  #0,d2
loc_15d34 00 03 00 02                      ori.b #2,d3
loc_15d38 00 00 00 00                      ori.b #0,d0
loc_15d3c 00 03 00 02                      ori.b #2,d3
loc_15d40 00 02 00 00                      ori.b #0,d2
loc_15d44 00 00 00 01                      ori.b #1,d0
loc_15d48 00 04 00 03                      ori.b #3,d4
loc_15d4c 00 00 00 00                      ori.b #0,d0
loc_15d50 00 00 00 00                      ori.b #0,d0
loc_15d54 00 03 00 00                      ori.b #0,d3

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
                rts

; ======================================================================

loc_16218:
                lea     ($FFFFC200).w,a1
                moveq   #5,d0
loc_1621C:
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
                dbf     d0,loc_1621e
                rts

loc_162a8:
                move.w  (sp)+,d0
                rts

; ======================================================================

loc_162ac: 00 00 02 00                      ori.b #0,d0
loc_162b0 00 00 04 00                      ori.b #0,d0
loc_162b4 00 00 08 00                      ori.b #0,d0
loc_162b8 00 00 16 00                      ori.b #0,d0

; ======================================================================

loc_162bc: 00 01 62 dc                      ori.b #-36,d1
loc_162c0 00 01 62 e6                      ori.b #-26,d1
loc_162c4 00 01 62 f0                      ori.b #-16,d1
loc_162c8 00 01 62 f6                      ori.b #-10,d1
loc_162cc 00 01 62 fc                      ori.b #-4,d1
loc_162d0 00 01 63 02                      ori.b #2,d1
loc_162d4 00 01 63 08                      ori.b #8,d1
loc_162d8 00 01 54 fe                      ori.b #-2,d1
loc_162dc 04 01 ab 7c                      subi.b #$7C,d1
loc_162e0 ab 84                            .short 0xab84
loc_162e2 ab 8c                            .short 0xab8c
loc_162e4 ab 84                            .short 0xab84
loc_162e6 04 01 ab 94                      subi.b #-108,d1
loc_162ea ab 9c                            .short 0xab9c
loc_162ec ab a4                            .short 0xaba4
loc_162ee ab 9c                            .short 0xab9c
loc_162f0 02 01 ab ac                      andi.b  #-84,d1
loc_162f4 ab b4                            .short 0xabb4
loc_162f6 02 01 ab bc                      andi.b  #-68,d1
loc_162fa ab c4                            .short 0xabc4
loc_162fc 02 01 ac 3c                      andi.b  #$3C,d1
loc_16300 ac 44                            .short 0xac44
loc_16302 02 01 ac 54                      andi.b  #84,d1
loc_16306 ac 5c                            .short 0xac5c
loc_16308 04 01 ac 6c                      subi.b #108,d1
loc_1630c ac 7a                            .short 0xac7a
loc_1630e ac 88                            .short 0xac88
loc_16310 ac 96                            .short 0xac96

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
                beq.s   loc_1633e                ;
                move.w  ($FFFFD294).w,$38(a0)    ;
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
                bne.s   loc_163ac
                bclr    #2,2(a0)
                clr.b   $10(a0)
                clr.w   6(a0)
loc_163ac:
                bsr.w   loc_1105c
                bsr.w   AnimateSprite
                bclr    #2,2(a0)
                beq.s   loc_163de
                movea.l a0,a1
                suba.l  #$00000300,a1
                move.b  $16(a0),d0
                move.w  #$10,(a1)
                move.b  d0,$16(a1)
                cmpi.b  #2,d0
                bne.s   loc_163da
                move.w  #$14,(a1)
                bsr.w   loc_11118
                rts

; ----------------------------------------------------------------------
; TODO RAM TABLE
loc_163e0:
                dc.l    loc_163E4

loc_163e4: 1c 04                            move.b  d4,d6
loc_163e6 aa ec                            .short 0xaaec
loc_163e8 aa ec                            .short 0xaaec
loc_163ea aa ec                            .short 0xaaec
loc_163ec aa f4                            .short 0xaaf4
loc_163ee aa f4                            .short 0xaaf4
loc_163f0 aa f4                            .short 0xaaf4
loc_163f2 aa fc                            .short 0xaafc
loc_163f4 ab 04                            .short 0xab04
loc_163f6 ab 0c                            .short 0xab0c
loc_163f8 ab 14                            .short 0xab14
loc_163fa ab 1c                            .short 0xab1c
loc_163fc ab 14                            .short 0xab14
loc_163fe ab 0c                            .short 0xab0c
loc_16400 ab 04                            .short 0xab04
loc_16402 aa fc                            .short 0xaafc
loc_16404 ab 04                            .short 0xab04
loc_16406 ab 0c                            .short 0xab0c
loc_16408 ab 14                            .short 0xab14
loc_1640a ab 1c                            .short 0xab1c
loc_1640c ab 14                            .short 0xab14
loc_1640e ab 0c                            .short 0xab0c
loc_16410 ab 04                            .short 0xab04
loc_16412 aa fc                            .short 0xaafc
loc_16414 ab 04                            .short 0xab04
loc_16416 ab 0c                            .short 0xab0c
loc_16418 ab 14                            .short 0xab14
loc_1641a ab 1c                            .short 0xab1c
loc_1641c ab 14                            .short 0xab14
loc_1641e ab 0c                            .short 0xab0c
loc_16420 ab 04                            .short 0xab04

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

loc_164ec 08 d0 00 07                      bset    #7,(a0)
loc_164f0 66 28                            bne.s   loc_1651a
loc_164f2 42 28 00 05                      clr.b 5(a0)
loc_164f6 42 a8 00 34                      clr.l   $34(a0)
loc_164fa 42 a8 00 2c                      clr.l   $2C(a0)
loc_164fe 5e 68 00 24                      addq.w  #7,$24(a0)
loc_16502 21 7c 00 01 65 ac 00 08          move.l  #91564,8(a0)
loc_1650a 42 68 00 06                      clr.w 6(a0)
loc_1650e 31 7c 01 2c 00 38                move.w  #300,$38(a0)
loc_16514 08 a8 00 07 00 02                bclr    #7,2(a0)
loc_1651a 61 00 ab 40                      bsr.w   loc_1105c
loc_1651e 61 00 ac 06                      bsr.w   AnimateSprite
loc_16522 43 f8 c4 40                      lea     ($FFFFC440).w,a1
loc_16526 61 00 b2 98                      bsr.w   loc_117c0
loc_1652a 4a 00                            tst.b   d0
loc_1652c 67 4e                            beq.s   loc_1657c
loc_1652e 2f 08                            move.l  a0,-(sp)
loc_16530 10 3c 00 98                      move.b  #-104,d0
loc_16534 61 00 a8 12                      bsr.w   loc_10d48
loc_16538 20 5f                            movea.l (sp)+,a0
loc_1653a 45 f8 c0 c0                      lea     ($FFFFC0C0).w,a2
loc_1653e 70 03                            moveq   #3,d0
loc_16540 4a 52                            tst.w   (a2)
loc_16542 66 30                            bne.s   loc_16574
loc_16544 3e 28 00 30                      move.w  $30(a0),d7
loc_16548 3c 28 00 24                      move.w  $24(a0),d6
loc_1654c 35 47 00 30                      move.w  d7,$30(a2)
loc_16550 51 46                            subq.w  #8,d6
loc_16552 35 46 00 24                      move.w  d6,$24(a2)
loc_16556 7e 00                            moveq   #0,d7
loc_16558 1e 38 d2 7a                      move.b  ($FFFFD27A).w,d7
loc_1655c 15 47 00 3a                      move.b  d7,$3A(a2)
loc_16560 34 bc 00 24                      move.w  #36,(a2)
loc_16564 e5 4f                            lsl.w   #2,d7
loc_16566 2e 3b 70 20                      move.l  (pc)(loc_16588,d7.w),d7
loc_1656a 21 c7 d2 62                      move.l  d7,($FFFFD262).w
loc_1656e 61 00 b1 1a                      bsr.w   loc_1168a
loc_16572 60 0e                            bra.s   loc_16582
loc_16574 45 ea ff c0                      lea     -$40(a2),a2
loc_16578 51 c8 ff c6                      dbf     d0,loc_16540
loc_1657c 53 68 00 38                      subq.w  #1,$38(a0)
loc_16580 66 04                            bne.s   loc_16586
loc_16582 61 00 ab 94                      bsr.w   loc_11118
loc_16586 4e 75                            rts
loc_16588 00 00 01 00                      ori.b #0,d0
loc_1658c 00 00 02 00                      ori.b #0,d0
loc_16590 00 00 03 00                      ori.b #0,d0
loc_16594 00 00 04 00                      ori.b #0,d0
loc_16598 00 00 05 00                      ori.b #0,d0
loc_1659c 00 00 08 00                      ori.b #0,d0
loc_165a0 00 00 10 00                      ori.b #0,d0
loc_165a4 00 00 20 00                      ori.b #0,d0
loc_165a8 00 00 30 00                      ori.b #0,d0
loc_165ac 00 01 65 b0                      ori.b #-80,d1
loc_165b0 04 05 a8 d8                      subi.b #-40,d5
loc_165b4 a8 e0                            .short 0xa8e0
loc_165b6 a8 e8                            .short 0xa8e8
loc_165b8 a8 f0                            .short 0xa8f0
loc_165ba 08 d0 00 07                      bset    #7,(a0)
loc_165be 66 30                            bne.s   loc_165f0
loc_165c0 31 7c 01 40 00 30                move.w  #320,$30(a0)
loc_165c6 08 a8 00 07 00 02                bclr    #7,2(a0)
loc_165cc 4a 28 00 16                      tst.b   $16(a0)
loc_165d0 67 0c                            beq.s   loc_165de
loc_165d2 31 7c 00 c0 00 30                move.w  #192,$30(a0)
loc_165d8 08 e8 00 07 00 02                bset    #7,2(a0)
loc_165de 31 7c 01 50 00 24                move.w  #336,$24(a0)
loc_165e4 21 7c 00 01 66 9a 00 08          move.l  #91802,8(a0)
loc_165ec 42 68 00 06                      clr.w 6(a0)
loc_165f0 4a 38 d2 7b                      tst.b   ($FFFFD27B).w
loc_165f4 66 08                            bne.s   loc_165fe
loc_165f6 61 00 aa 64                      bsr.w   loc_1105c
loc_165fa 61 00 ab 2a                      bsr.w   AnimateSprite
loc_165fe 4e 75                            rts
loc_16600 08 d0 00 07                      bset    #7,(a0)
loc_16604 66 32                            bne.s   loc_16638
loc_16606 31 7c 01 30 00 30                move.w  #304,$30(a0)
loc_1660c 08 a8 00 07 00 02                bclr    #7,2(a0)
loc_16612 4a 28 00 16                      tst.b   $16(a0)
loc_16616 67 0c                            beq.s   loc_16624
loc_16618 31 7c 00 d0 00 30                move.w  #208,$30(a0)
loc_1661e 08 e8 00 07 00 02                bset    #7,2(a0)
loc_16624 31 7c 01 50 00 24                move.w  #336,$24(a0)
loc_1662a 21 7c 00 01 66 9a 00 08          move.l  #91802,8(a0)
loc_16632 31 7c 00 04 00 06                move.w  #4,6(a0)
loc_16638 4a 38 d2 7b                      tst.b   ($FFFFD27B).w
loc_1663c 66 08                            bne.s   loc_16646
loc_1663e 61 00 aa 1c                      bsr.w   loc_1105c
loc_16642 61 00 aa e2                      bsr.w   AnimateSprite
loc_16646 4e 75                            rts
loc_16648 43 f8 c5 80                      lea     ($FFFFC580,a1
loc_1664c 2e 29 00 30                      move.l  $30(a1),d7
loc_16650 2c 29 00 24                      move.l  $24(a1),d6
loc_16654 21 47 00 30                      move.l  d7,$30(a0)
loc_16658 21 46 00 24                      move.l  d6,$24(a0)
loc_1665c 06 68 00 0a 00 24                addi.w  #$A,$24(a0)
loc_16662 4a 29 00 39                      tst.b   (a1)(57)
loc_16666 67 0c                            beq.s   loc_16674
loc_16668 08 a8 00 07 00 02                bclr    #7,2(a0)
loc_1666e 51 68 00 30                      subq.w  #8,$30(a0)
loc_16672 60 0a                            bra.s   loc_1667e
loc_16674 08 e8 00 07 00 02                bset    #7,2(a0)
loc_1667a 50 68 00 30                      addq.w  #8,$30(a0)
loc_1667e 61 00 a9 dc                      bsr.w   loc_1105c
loc_16682 21 7c 00 01 aa d6 00 0c          move.l  #109270,$C(a0)
loc_1668a 4a a9 00 34                      tst.l   $34(a1)
loc_1668e 67 08                            beq.s   loc_16698
loc_16690 21 7c 00 01 aa e4 00 0c          move.l  #109284,$C(a0)
loc_16698 4e 75                            rts
loc_1669a 00 01 66 a2                      ori.b #-94,d1
loc_1669e 00 01 66 b4                      ori.b #-76,d1
loc_166a2 08 07 aa 96                      btst    #-106,d7
loc_166a6 aa a4                            .short 0xaaa4
loc_166a8 aa b2                            .short 0xaab2
loc_166aa aa ba                            .short 0xaaba
loc_166ac aa c8                            .short 0xaac8
loc_166ae aa ba                            .short 0xaaba
loc_166b0 aa b2                            .short 0xaab2
loc_166b2 aa a4                            .short 0xaaa4
loc_166b4 08 07 aa 1a                      btst    #26,d7
loc_166b8 aa 2e                            .short 0xaa2e
loc_166ba aa 42                            .short 0xaa42
loc_166bc aa 56                            .short 0xaa56
loc_166be aa 6a                            .short 0xaa6a
loc_166c0 aa 56                            .short 0xaa56
loc_166c2 aa 42                            .short 0xaa42
loc_166c4 aa 2e                            .short 0xaa2e
loc_166c6 08 d0 00 07                      bset    #7,(a0)
loc_166ca 66 20                            bne.s   loc_166ec
loc_166cc 08 e8 00 01 00 02                bset    #1,2(a0)
loc_166d2 21 7c 00 01 4e 12 00 08          move.l  #85522,8(a0)
loc_166da 22 78 d2 82                      movea.l ($FFFFd282,a1
loc_166de 70 00                            moveq   #0,d0
loc_166e0 10 28 00 38                      move.b  $38(a0),d0
loc_166e4 e3 48                            lsl.w   #1,d0
loc_166e6 31 71 00 00 00 3a                move.w  (a1,d0.w),$3A(a0)
loc_166ec 70 7c                            moveq   #$7C,d0
loc_166ee c0 68 00 3c                      and.w   $3C(a0),d0
loc_166f2 4e bb 00 08                      jsr     (pc)(loc_166fc,d0.w)
loc_166f6 61 00 aa 2e                      bsr.w   AnimateSprite
loc_166fa 4e 75                            rts
loc_166fc 60 00 00 0a                      bra.w   loc_16708
loc_16700 60 00 00 80                      bra.w   loc_16782
loc_16704 60 00 00 d0                      bra.w   loc_167d6
loc_16708 4a 68 00 3a                      tst.w   $3A(a0)
loc_1670c 66 6a                            bne.s   loc_16778
loc_1670e 08 e8 00 07 00 3c                bset    #7,$3C(a0)
loc_16714 66 40                            bne.s   loc_16756
loc_16716 08 a8 00 01 00 02                bclr    #1,2(a0)
loc_1671c 31 7c 00 04 00 06                move.w  #4,6(a0)
loc_16722 31 7c 01 50 00 24                move.w  #336,$24(a0)
loc_16728 31 7c 00 80 00 30                move.w  #$80,$30(a0)
loc_1672e 21 7c 00 00 80 00 00 34          move.l  #32768,$34(a0)
loc_16736 08 a8 00 07 00 02                bclr    #7,2(a0)
loc_1673c 4a 28 00 39                      tst.b   $39(a0)
loc_16740 67 14                            beq.s   loc_16756
loc_16742 31 7c 01 7f 00 30                move.w  #383,$30(a0)
loc_16748 21 7c ff ff 80 00 00 34          move.l  #-32768,$34(a0)
loc_16750 08 e8 00 07 00 02                bset    #7,2(a0)
loc_16756 61 00 a9 04                      bsr.w   loc_1105c
loc_1675a 43 f8 c6 40                      lea     ($FFFFC640,a1
loc_1675e 4a 28 00 39                      tst.b   $39(a0)
loc_16762 66 04                            bne.s   loc_16768
loc_16764 43 e9 00 40                      lea     $40(a1),a1
loc_16768 61 00 b0 56                      bsr.w   loc_117c0
loc_1676c 4a 00                            tst.b   d0
loc_1676e 67 06                            beq.s   loc_16776
loc_16770 31 7c 00 04 00 3c                move.w  #4,$3C(a0)
loc_16776 4e 75                            rts
loc_16778 53 68 00 3a                      subq.w  #1,$3A(a0)
loc_1677c 61 00 a8 de                      bsr.w   loc_1105c
loc_16780 4e 75                            rts
loc_16782 08 e8 00 07 00 3c                bset    #7,$3C(a0)
loc_16788 66 2e                            bne.s   loc_167b8
loc_1678a 22 78 d2 86                      movea.l ($FFFFd286,a1
loc_1678e 70 00                            moveq   #0,d0
loc_16790 10 28 00 38                      move.b  $38(a0),d0
loc_16794 e3 48                            lsl.w   #1,d0
loc_16796 1e 31 00 00                      move.b  (a1,d0.w),d7
loc_1679a 1c 31 00 01                      move.b  (a1)1,d0.w),d6
loc_1679e 48 87                            ext.w d7
loc_167a0 48 c7                            ext.l d7
loc_167a2 48 86                            ext.w d6
loc_167a4 48 c6                            ext.l d6
loc_167a6 70 0c                            moveq   #$C,d0
loc_167a8 e1 af                            lsl.l d0,d7
loc_167aa e1 ae                            lsl.l d0,d6
loc_167ac 21 47 00 34                      move.l  d7,$34(a0)
loc_167b0 21 46 00 2c                      move.l  d6,$2C(a0)
loc_167b4 61 00 00 dc                      bsr.w   loc_16892
loc_167b8 06 a8 00 00 10 00 00 2c          addi.l  #4096,$2C(a0)
loc_167c0 66 06                            bne.s   loc_167c8
loc_167c2 31 7c 00 08 00 3c                move.w  #8,$3C(a0)
loc_167c8 61 00 00 8a                      bsr.w   loc_16854
loc_167cc 61 00 a8 8e                      bsr.w   loc_1105c
loc_167d0 61 00 a9 54                      bsr.w   AnimateSprite
loc_167d4 4e 75                            rts
loc_167d6 08 e8 00 07 00 3c                bset    #7,$3C(a0)
loc_167dc 66 28                            bne.s   loc_16806
loc_167de 42 68 00 06                      clr.w 6(a0)
loc_167e2 2e 28 00 34                      move.l  $34(a0),d7
loc_167e6 6a 08                            bpl.s   loc_167f0
loc_167e8 44 87                            neg.l   d7
loc_167ea e2 8f                            lsrl #1,d7
loc_167ec 44 87                            neg.l   d7
loc_167ee 60 02                            bra.s   loc_167f2
loc_167f0 e2 8f                            lsrl #1,d7
loc_167f2 21 47 00 34                      move.l  d7,$34(a0)
loc_167f6 0c 68 ff ff 00 3a                cmpi.w  #-1,$3A(a0)
loc_167fc 67 08                            beq.s   loc_16806
loc_167fe 52 28 00 3e                      addq.b  #1,$3E(a0)
loc_16802 61 00 00 8e                      bsr.w   loc_16892
loc_16806 0c a8 00 01 80 00 00 2c          cmpi.l #98304,$2C(a0)
loc_1680e 6e 08                            bgt.s   loc_16818
loc_16810 06 a8 00 00 04 00 00 2c          addi.l  #$400,$2C(a0)
loc_16818 61 00 00 3a                      bsr.w   loc_16854
loc_1681c 61 00 a8 3e                      bsr.w   loc_1105c
loc_16820 61 00 00 c0                      bsr.w   loc_168e2
loc_16824 0c 68 01 80 00 24                cmpi.w  #$180,$24(a0)
loc_1682a 65 08                            bcs.s   loc_16834
loc_1682c 61 00 a8 c2                      bsr.w   loc_110f0
loc_16830 53 38 d8 83                      subq.b  #1,($FFFFD883).w
loc_16834 61 00 a8 f0                      bsr.w   AnimateSprite
loc_16838 4a 38 d8 83                      tst.b   ($FFFFD883).w
loc_1683c 66 14                            bne.s   loc_16852
loc_1683e 42 78 ff 92                      clr.w   ($FFFFFF92).w
loc_16842 11 fc 00 01 d2 81                move.b  #1,($FFFFD281).w
loc_16848 31 fc 00 04 d2 a6                move.w  #4,($FFFFd2a6
loc_1684e 61 00 01 38                      bsr.w   loc_16988
loc_16852 4e 75                            rts
loc_16854 30 28 00 3a                      move.w  $3A(a0),d0
loc_16858 0c 40 ff ff                      cmpi.w  #-1,d0
loc_1685c 67 32                            beq.s   loc_16890
loc_1685e 53 40                            subq.w  #1,d0
loc_16860 66 0a                            bne.s   loc_1686c
loc_16862 52 28 00 3e                      addq.b  #1,$3E(a0)
loc_16866 61 00 00 2a                      bsr.w   loc_16892
loc_1686a 60 e8                            bra.s   loc_16854
loc_1686c 31 40 00 3a                      move.w  d0,$3A(a0)
loc_16870 2e 28 00 34                      move.l  $34(a0),d7
loc_16874 2c 28 00 1c                      move.l  (a0)(28),d6
loc_16878 6b 0a                            bmi.s   loc_16884
loc_1687a be 86                            cmp.l   d6,d7
loc_1687c 6c 04                            bge.s   loc_16882
loc_1687e de a8 00 18                      add.l (a0)(24),d7
loc_16882 60 08                            bra.s   loc_1688c
loc_16884 be 86                            cmp.l   d6,d7
loc_16886 6f 04                            ble.s   loc_1688c
loc_16888 de a8 00 18                      add.l (a0)(24),d7
loc_1688c 21 47 00 34                      move.l  d7,$34(a0)
loc_16890 4e 75                            rts
loc_16892 70 00                            moveq   #0,d0
loc_16894 10 28 00 38                      move.b  $38(a0),d0
loc_16898 22 78 d2 8a                      movea.l ($FFFFd28a,a1
loc_1689c 10 31 00 00                      move.b  (a1,d0.w),d0
loc_168a0 e5 48                            lsl.w   #2,d0
loc_168a2 43 fa 04 74                      lea     (pc)(loc_16d18),a1
loc_168a6 22 71 00 00                      movea.l (a1,d0.w),a1
loc_168aa 70 00                            moveq   #0,d0
loc_168ac 10 28 00 3e                      move.b  $3E(a0),d0
loc_168b0 e5 48                            lsl.w   #2,d0
loc_168b2 31 71 00 00 00 3a                move.w  (a1,d0.w),$3A(a0)
loc_168b8 1e 31 00 02                      move.b  (a1)2,d0.w),d7
loc_168bc 1c 31 00 03                      move.b  (a1)3,d0.w),d6
loc_168c0 48 87                            ext.w d7
loc_168c2 48 c7                            ext.l d7
loc_168c4 48 86                            ext.w d6
loc_168c6 48 c6                            ext.l d6
loc_168c8 e1 8f                            lsl.l #8,d7
loc_168ca 70 0c                            moveq   #$C,d0
loc_168cc e1 ae                            lsl.l d0,d6
loc_168ce 4a 28 00 39                      tst.b   $39(a0)
loc_168d2 67 04                            beq.s   loc_168d8
loc_168d4 44 87                            neg.l   d7
loc_168d6 44 86                            neg.l   d6
loc_168d8 21 47 00 18                      move.l  d7,(a0)(24)
loc_168dc 21 46 00 1c                      move.l  d6,(a0)(28)
loc_168e0 4e 75                            rts
loc_168e2 43 f8 c0 40                      lea     ($FFFFC040,a1
loc_168e6 61 00 ae d8                      bsr.w   loc_117c0
loc_168ea 4a 00                            tst.b   d0
loc_168ec 67 2c                            beq.s   loc_1691a
loc_168ee 2f 08                            move.l  a0,-(sp)
loc_168f0 10 3c 00 90                      move.b  #-112,d0
loc_168f4 61 00 a4 52                      bsr.w   loc_10d48
loc_168f8 20 5f                            movea.l (sp)+,a0
loc_168fa 61 00 a7 f4                      bsr.w   loc_110f0
loc_168fe 53 38 d8 83                      subq.b  #1,($FFFFD883).w
loc_16902 52 38 d2 8e                      addq.b  #1,($FFFFD28E).w
loc_16906 70 01                            moveq   #1,d0
loc_16908 12 38 d2 8f                      move.b  ($FFFFd28f,d1
loc_1690c 06 01 00 00                      addi.b #0,d1
loc_16910 c3 00                            abcd d0,d1
loc_16912 11 c1 d2 8f                      move.b  d1,($FFFFd28f
loc_16916 61 00 00 bc                      bsr.w   loc_169d4
loc_1691a 4e 75                            rts
loc_1691c 4a 38 d2 8e                      tst.b   ($FFFFD28E).w
loc_16920 67 22                            beq.s   loc_16944
loc_16922 4d fa 00 28                      lea     (pc)(loc_1694c),a6
loc_16926 61 00 a6 82                      bsr.w   WriteASCIIString
loc_1692a 0c 38 00 14 d2 8e                cmpi.b  #$14,($FFFFD28E).w
loc_16930 66 10                            bne.s   loc_16942
loc_16932 4d fa 00 30                      lea     (pc)(loc_16964),a6
loc_16936 61 00 a6 72                      bsr.w   WriteASCIIString
loc_1693a 4d fa 00 38                      lea     (pc)(loc_16974),a6
loc_1693e 61 00 a6 6a                      bsr.w   WriteASCIIString
loc_16942 4e 75                            rts
loc_16944 4d fa 00 36                      lea     (pc)(loc_1697c),a6
loc_16948 60 00 a6 60                      bra.w   WriteASCIIString
loc_1694c c2 4e                            .short 0xc24e
loc_1694e 3b 20                            move.w  (a0)-,(a5)-
loc_16950 32 35 30 20                      move.w  (a5)(0000000000000020,d3.w),d1
loc_16954 50 54                            addq.w  #8,(a4)
loc_16956 53 2e 3d 20                      subq.b  #1,(a6)(15648)
loc_1695a 20 20                            move.l  (a0)-,d0
loc_1695c 20 20                            move.l  (a0)-,d0
loc_1695e 20 50                            movea.l (a0),a0
loc_16960 54 53                            addq.w  #2,(a3)
loc_16962 2e 00                            move.l  d0,d7
loc_16964 c3 12                            and.b d1,(a2)
loc_16966 50 45                            addq.w  #8,d5
loc_16968 52 46                            addq.w  #1,d6
loc_1696a 45 43                            .short 0x4543
loc_1696c 54 20                            addq.b  #2,(a0)-
loc_1696e 42 4f                            .short 0x424f
loc_16970 4e 55 53 00                      linkw a5,#21248
loc_16974 c3 a2                            and.l   d1,(a2)-
loc_16976 50 54                            addq.w  #8,(a4)
loc_16978 53 2e 00 00                      subq.b  #1,(a6)(0)
loc_1697c c3 16                            and.b d1,(a6)
loc_1697e 4e 4f                            trap #15
loc_16980 20 42                            movea.l d2,a0
loc_16982 4f 4e                            .short 0x4f4e
loc_16984 55 53                            subq.w  #2,(a3)
loc_16986 00 00 70 00                      ori.b #0,d0
loc_1698a 10 38 d2 8e                      move.b  ($FFFFD28E).w,d0
loc_1698e 67 42                            beq.s   loc_169d2
loc_16990 53 40                            subq.w  #1,d0
loc_16992 21 fc 00 00 02 50 d2 62          move.l  #592,($FFFFD262).w
loc_1699a 45 f8 d2 66                      lea     ($FFFFD266).w,a2
loc_1699e 43 f8 d2 94                      lea     ($FFFFD294).w,a1
loc_169a2 72 03                            moveq   #3,d1
loc_169a4 44 fc 00 04                      move.w  #4,ccr
loc_169a8 c3 0a                            abcd (a2)-,(a1)-
loc_169aa 51 c9 ff fc                      dbf     d1,loc_169a8
loc_169ae 51 c8 ff e2                      dbf     d0,loc_16992
loc_169b2 20 38 d2 90                      move.l  ($FFFFd290,d0
loc_169b6 21 c0 d2 62                      move.l  d0,($FFFFD262).w
loc_169ba 61 00 ac ce                      bsr.w   loc_1168a
loc_169be 0c 38 00 14 d2 8e                cmpi.b  #$14,($FFFFD28E).w
loc_169c4 66 0c                            bne.s   loc_169d2
loc_169c6 21 fc 00 01 00 00 d2 62          move.l  #65536,($FFFFD262).w
loc_169ce 61 00 ac ba                      bsr.w   loc_1168a
loc_169d2 4e 75                            rts
loc_169d4 70 00                            moveq   #0,d0
loc_169d6 10 38 d2 8e                      move.b  ($FFFFD28E).w,d0
loc_169da 53 40                            subq.w  #1,d0
loc_169dc 23 fc 41 4c 00 03 00 c0 00 04    move.l  #1095499779,($C00004).l
loc_169e6 33 fc e3 51 00 c0 00 00          move.w  #-7343,($C00000).l
loc_169ee 51 c8 ff f6                      dbf     d0,loc_169e6
loc_169f2 4e 75                            rts





loc_169f4: 00 01 6a 24                      ori.b #36,d1
loc_169f8 00 01 6a 24                      ori.b #36,d1
loc_169fc 00 01 6a 24                      ori.b #36,d1
loc_16a00 00 01 6a 4c                      ori.b #76,d1
loc_16a04 00 01 6a 74                      ori.b #116,d1
loc_16a08 00 01 6a 74                      ori.b #116,d1
loc_16a0c 00 01 6a 74                      ori.b #116,d1
loc_16a10 00 01 6a 74                      ori.b #116,d1
loc_16a14 00 01 6a 74                      ori.b #116,d1
loc_16a18 00 01 6a 74                      ori.b #116,d1
loc_16a1c 00 01 6a 74                      ori.b #116,d1
loc_16a20 00 01 6a 74                      ori.b #116,d1
loc_16a24 00 00 00 0f                      ori.b #$F,d0
loc_16a28 00 1e 00 2d                      ori.b #45,(a6)+
loc_16a2c 00 6e 00 7d 00 8c                ori.w #125,(a6)(140)
loc_16a32 00 9b 00 dc 00 eb                ori.l #14418155,(a3)+
loc_16a38 00 fa                            .short 0x00fa
loc_16a3a 01 09 01 4a                      movepw (a1)(330),d0
loc_16a3e 01 59                            bchg d0,(a1)+
loc_16a40 01 68 01 77                      bchg d0,(a0)(375)
loc_16a44 01 b8 01 c7                      bclr d0,loc_1c7
loc_16a48 01 d6                            bset d0,(a6)
loc_16a4a 01 e5                            bset d0,(a5)-
loc_16a4c 00 1e 00 2d                      ori.b #45,(a6)+
loc_16a50 00 3c 00 4b                      ori.b #75,ccr
loc_16a54 00 00 00 0f                      ori.b #$F,d0
loc_16a58 00 1e 00 2d                      ori.b #45,(a6)+
loc_16a5c 00 fa                            .short 0x00fa
loc_16a5e 01 09 01 18                      movepw (a1)(280),d0
loc_16a62 01 27                            btst d0,-(sp)
loc_16a64 00 dc                            .short 0x00dc
loc_16a66 00 eb                            .short 0x00eb
loc_16a68 00 fa                            .short 0x00fa
loc_16a6a 01 09 01 b8                      movepw (a1)(440),d0
loc_16a6e 01 c7                            bset d0,d7
loc_16a70 01 d6                            bset d0,(a6)
loc_16a72 01 e5                            bset d0,(a5)-
loc_16a74 00 00 00 0f                      ori.b #$F,d0
loc_16a78 00 1e 00 2d                      ori.b #45,(a6)+
loc_16a7c 00 64 00 73                      ori.w #115,(a4)-
loc_16a80 00 82 00 91 00 c8                ori.l #9502920,d2
loc_16a86 00 d7                            .short 0x00d7
loc_16a88 00 e6                            .short 0x00e6
loc_16a8a 00 f5                            .short 0x00f5
loc_16a8c 01 2c 01 3b                      btst d0,(a4)(315)
loc_16a90 01 4a 01 59                      movepl (a2)(345),d0
loc_16a94 01 90                            bclr d0,(a0)
loc_16a96 01 9f                            bclr d0,(sp)+
loc_16a98 01 ae 01 bd                      bclr d0,(a6)(445)


loc_16a9c: 00 01 6a cc                      ori.b #-52,d1
loc_16aa0 00 01 6a f4                      ori.b #-12,d1
loc_16aa4 00 01 6b 1c                      ori.b #$1C,d1
loc_16aa8 00 01 6b 44                      ori.b #$44,d1
loc_16aac 00 01 6b 6c                      ori.b #108,d1
loc_16ab0 00 01 6b 94                      ori.b #-108,d1
loc_16ab4 00 01 6b bc                      ori.b #-68,d1
loc_16ab8 00 01 6b 94                      ori.b #-108,d1
loc_16abc 00 01 6a cc                      ori.b #-52,d1
loc_16ac0 00 01 6b e4                      ori.b #-28,d1
loc_16ac4 00 01 6c 0c                      ori.b #$C,d1
loc_16ac8 00 01 6b 94                      ori.b #-108,d1
loc_16acc 0e b4                            .short 0x0eb4
loc_16ace 0e b4                            .short 0x0eb4
loc_16ad0 0e b4                            .short 0x0eb4
loc_16ad2 0e b4                            .short 0x0eb4
loc_16ad4 f2 b4                            .short 0xf2b4
loc_16ad6 f2 b4                            .short 0xf2b4
loc_16ad8 f2 b4                            .short 0xf2b4
loc_16ada f2 b4                            .short 0xf2b4
loc_16adc 0e b4                            .short 0x0eb4
loc_16ade 0e b4                            .short 0x0eb4
loc_16ae0 0e b4                            .short 0x0eb4
loc_16ae2 0e b4                            .short 0x0eb4
loc_16ae4 f2 b4                            .short 0xf2b4
loc_16ae6 f2 b4                            .short 0xf2b4
loc_16ae8 f2 b4                            .short 0xf2b4
loc_16aea f2 b4                            .short 0xf2b4
loc_16aec 0e b4                            .short 0x0eb4
loc_16aee 0e b4                            .short 0x0eb4
loc_16af0 0e b4                            .short 0x0eb4
loc_16af2 0e b4                            .short 0x0eb4
loc_16af4 0e b4                            .short 0x0eb4
loc_16af6 0c b4 0a b4 08 b4 f2 b4          cmpi.l #179570868,(a4)(ffffffffffffffb4,sp.w:2)
loc_16afe f4 b4                            .short 0xf4b4
loc_16b00 f6 b4                            .short 0xf6b4
loc_16b02 f8 b4                            .short 0xf8b4
loc_16b04 0e b4                            .short 0x0eb4
loc_16b06 0c b4 0a b4 08 b4 f2 b4          cmpi.l #179570868,(a4)(ffffffffffffffb4,sp.w:2)
loc_16b0e f4 b4                            .short 0xf4b4
loc_16b10 f6 b4                            .short 0xf6b4
loc_16b12 f8 b4                            .short 0xf8b4
loc_16b14 0e b4                            .short 0x0eb4
loc_16b16 0c b4 0a b4 08 b4 0e b4          cmpi.l #179570868,(a4)(ffffffffffffffb4,d0:l:8)
loc_16b1e 0e b8                            .short 0x0eb8
loc_16b20 0e bc                            .short 0x0ebc
loc_16b22 0e c0                            .short 0x0ec0
loc_16b24 f2 b4                            .short 0xf2b4
loc_16b26 f2 b8                            .short 0xf2b8
loc_16b28 f2 bc                            .short 0xf2bc
loc_16b2a f2 c0 0e b4 0e b8                fbfl 0x0eb579e4
loc_16b30 0e bc                            .short 0x0ebc
loc_16b32 0e c0                            .short 0x0ec0
loc_16b34 f2 b4                            .short 0xf2b4
loc_16b36 f2 b8                            .short 0xf2b8
loc_16b38 f2 bc                            .short 0xf2bc
loc_16b3a f2 c0 0e b4 0e b8                fbfl 0x0eb579f4
loc_16b40 0e bc                            .short 0x0ebc
loc_16b42 0e c0                            .short 0x0ec0
loc_16b44 0a b4 0a b4 0a b4 0a b4          eori.l #179571380,(a4)(ffffffffffffffb4,d0:l:2)
loc_16b4c f6 b4                            .short 0xf6b4
loc_16b4e f6 b4                            .short 0xf6b4
loc_16b50 f6 b4                            .short 0xf6b4
loc_16b52 f6 b4                            .short 0xf6b4
loc_16b54 0a b4 0a b4 0a b4 0a b4          eori.l #179571380,(a4)(ffffffffffffffb4,d0:l:2)
loc_16b5c f6 b4                            .short 0xf6b4
loc_16b5e f6 b4                            .short 0xf6b4
loc_16b60 f6 b4                            .short 0xf6b4
loc_16b62 f6 b4                            .short 0xf6b4
loc_16b64 05 b4 08 b4                      bclr d2,(a4)(ffffffffffffffb4,d0:l)
loc_16b68 0b b4 0e b4                      bclr d5,(a4)(ffffffffffffffb4,d0:l:8)
loc_16b6c 22 b4 22 b4                      move.l  (a4)(ffffffffffffffb4,d2.w:2),(a1)
loc_16b70 22 b4 22 b4                      move.l  (a4)(ffffffffffffffb4,d2.w:2),(a1)
loc_16b74 de b4 de b4                      add.l (a4)(ffffffffffffffb4,a5:l:8),d7
loc_16b78 de b4 de b4                      add.l (a4)(ffffffffffffffb4,a5:l:8),d7
loc_16b7c 22 b4 22 b4                      move.l  (a4)(ffffffffffffffb4,d2.w:2),(a1)
loc_16b80 22 b4 22 b4                      move.l  (a4)(ffffffffffffffb4,d2.w:2),(a1)
loc_16b84 de b4 de b4                      add.l (a4)(ffffffffffffffb4,a5:l:8),d7
loc_16b88 de b4 de b4                      add.l (a4)(ffffffffffffffb4,a5:l:8),d7
loc_16b8c 22 b4 22 b4                      move.l  (a4)(ffffffffffffffb4,d2.w:2),(a1)
loc_16b90 22 b4 22 b4                      move.l  (a4)(ffffffffffffffb4,d2.w:2),(a1)
loc_16b94 09 b4 09 b4 09 b4 09 b4          bclr d4,@(0000000009b409b4)@0,d0:l)
loc_16b9c f7 b4                            .short 0xf7b4
loc_16b9e f7 b4                            .short 0xf7b4
loc_16ba0 f7 b4                            .short 0xf7b4
loc_16ba2 f7 b4                            .short 0xf7b4
loc_16ba4 09 b4 09 b4 09 b4 09 b4          bclr d4,@(0000000009b409b4)@0,d0:l)
loc_16bac f7 b4                            .short 0xf7b4
loc_16bae f7 b4                            .short 0xf7b4
loc_16bb0 f7 b4                            .short 0xf7b4
loc_16bb2 f7 b4                            .short 0xf7b4
loc_16bb4 09 b4 09 b4 09 b4 09 b4          bclr d4,@(0000000009b409b4)@0,d0:l)
loc_16bbc 12 b4 12 b4                      move.b  (a4)(ffffffffffffffb4,d1.w:2),(a1)
loc_16bc0 12 b4 12 b4                      move.b  (a4)(ffffffffffffffb4,d1.w:2),(a1)
loc_16bc4 ee b4                            roxrl d7,d4
loc_16bc6 ee b4                            roxrl d7,d4
loc_16bc8 ee b4                            roxrl d7,d4
loc_16bca ee b4                            roxrl d7,d4
loc_16bcc 12 b4 12 b4                      move.b  (a4)(ffffffffffffffb4,d1.w:2),(a1)
loc_16bd0 12 b4 12 b4                      move.b  (a4)(ffffffffffffffb4,d1.w:2),(a1)
loc_16bd4 ee b4                            roxrl d7,d4
loc_16bd6 ee b4                            roxrl d7,d4
loc_16bd8 ee b4                            roxrl d7,d4
loc_16bda ee b4                            roxrl d7,d4
loc_16bdc 12 b4 12 b4                      move.b  (a4)(ffffffffffffffb4,d1.w:2),(a1)
loc_16be0 12 b4 12 b4                      move.b  (a4)(ffffffffffffffb4,d1.w:2),(a1)
loc_16be4 e0 b4                            roxrl d0,d4
loc_16be6 e0 b4                            roxrl d0,d4
loc_16be8 e0 b4                            roxrl d0,d4
loc_16bea e0 b4                            roxrl d0,d4
loc_16bec 20 b4 20 b4                      move.l  (a4)(ffffffffffffffb4,d2.w),(a0)
loc_16bf0 20 b4 20 b4                      move.l  (a4)(ffffffffffffffb4,d2.w),(a0)
loc_16bf4 e0 b4                            roxrl d0,d4
loc_16bf6 e0 b4                            roxrl d0,d4
loc_16bf8 e0 b4                            roxrl d0,d4
loc_16bfa e0 b4                            roxrl d0,d4
loc_16bfc 20 b4 20 b4                      move.l  (a4)(ffffffffffffffb4,d2.w),(a0)
loc_16c00 20 b4 20 b4                      move.l  (a4)(ffffffffffffffb4,d2.w),(a0)
loc_16c04 e0 b4                            roxrl d0,d4
loc_16c06 e0 b4                            roxrl d0,d4
loc_16c08 e0 b4                            roxrl d0,d4
loc_16c0a e0 b4                            roxrl d0,d4
loc_16c0c 40 b4 40 b4                      negxl (a4)(ffffffffffffffb4,d4.w)
loc_16c10 40 b4 40 b4                      negxl (a4)(ffffffffffffffb4,d4.w)
loc_16c14 c0 b4 c0 b4                      and.l (a4)(ffffffffffffffb4,a4.w),d0
loc_16c18 c0 b4 c0 b4                      and.l (a4)(ffffffffffffffb4,a4.w),d0
loc_16c1c 40 b4 40 b4                      negxl (a4)(ffffffffffffffb4,d4.w)
loc_16c20 40 b4 40 b4                      negxl (a4)(ffffffffffffffb4,d4.w)
loc_16c24 c0 b4 c0 b4                      and.l (a4)(ffffffffffffffb4,a4.w),d0
loc_16c28 c0 b4 c0 b4                      and.l (a4)(ffffffffffffffb4,a4.w),d0
loc_16c2c 40 b4 40 b4                      negxl (a4)(ffffffffffffffb4,d4.w)
loc_16c30 40 b4 40 b4                      negxl (a4)(ffffffffffffffb4,d4.w)


loc_16c34: 00 01 6c 64                      ori.b #100,d1
loc_16c38 00 01 6c 64                      ori.b #100,d1
loc_16c3c 00 01 6c 64                      ori.b #100,d1
loc_16c40 00 01 6c 64                      ori.b #100,d1
loc_16c44 00 01 6c 78                      ori.b #120,d1
loc_16c48 00 01 6c 8c                      ori.b #-116,d1
loc_16c4c 00 01 6c a0                      ori.b #-96,d1
loc_16c50 00 01 6c b4                      ori.b #-76,d1
loc_16c54 00 01 6c c8                      ori.b #-56,d1
loc_16c58 00 01 6c dc                      ori.b #-36,d1
loc_16c5c 00 01 6c f0                      ori.b #-16,d1
loc_16c60 00 01 6d 04                      ori.b #4,d1
loc_16c64 00 00 00 00                      ori.b #0,d0
loc_16c68 00 00 00 00                      ori.b #0,d0
loc_16c6c 00 00 00 00                      ori.b #0,d0
loc_16c70 00 00 00 00                      ori.b #0,d0
loc_16c74 00 00 00 00                      ori.b #0,d0
loc_16c78 01 01                            btst d0,d1
loc_16c7a 01 01                            btst d0,d1
loc_16c7c 01 01                            btst d0,d1
loc_16c7e 01 01                            btst d0,d1
loc_16c80 01 01                            btst d0,d1
loc_16c82 01 01                            btst d0,d1
loc_16c84 01 01                            btst d0,d1
loc_16c86 01 01                            btst d0,d1
loc_16c88 01 01                            btst d0,d1
loc_16c8a 01 01                            btst d0,d1
loc_16c8c 02 02 02 02                      andi.b  #2,d2
loc_16c90 02 02 02 02                      andi.b  #2,d2
loc_16c94 02 02 02 02                      andi.b  #2,d2
loc_16c98 02 02 02 02                      andi.b  #2,d2
loc_16c9c 02 02 02 02                      andi.b  #2,d2
loc_16ca0 03 03                            btst d1,d3
loc_16ca2 03 03                            btst d1,d3
loc_16ca4 03 03                            btst d1,d3
loc_16ca6 03 03                            btst d1,d3
loc_16ca8 03 03                            btst d1,d3
loc_16caa 03 03                            btst d1,d3
loc_16cac 03 03                            btst d1,d3
loc_16cae 03 03                            btst d1,d3
loc_16cb0 03 03                            btst d1,d3
loc_16cb2 03 03                            btst d1,d3
loc_16cb4 04 04 04 04                      subi.b #4,d4
loc_16cb8 04 04 04 04                      subi.b #4,d4
loc_16cbc 04 04 04 04                      subi.b #4,d4
loc_16cc0 04 04 04 04                      subi.b #4,d4
loc_16cc4 04 04 04 04                      subi.b #4,d4
loc_16cc8 05 05                            btst d2,d5
loc_16cca 05 05                            btst d2,d5
loc_16ccc 05 05                            btst d2,d5
loc_16cce 05 05                            btst d2,d5
loc_16cd0 05 05                            btst d2,d5
loc_16cd2 05 05                            btst d2,d5
loc_16cd4 05 05                            btst d2,d5
loc_16cd6 05 05                            btst d2,d5
loc_16cd8 05 05                            btst d2,d5
loc_16cda 05 05                            btst d2,d5
loc_16cdc 06 06 06 06                      addi.b #6,d6
loc_16ce0 06 06 06 06                      addi.b #6,d6
loc_16ce4 06 06 06 06                      addi.b #6,d6
loc_16ce8 06 06 06 06                      addi.b #6,d6
loc_16cec 06 06 06 06                      addi.b #6,d6
loc_16cf0 07 07                            btst d3,d7
loc_16cf2 07 07                            btst d3,d7
loc_16cf4 07 07                            btst d3,d7
loc_16cf6 07 07                            btst d3,d7
loc_16cf8 07 07                            btst d3,d7
loc_16cfa 07 07                            btst d3,d7
loc_16cfc 07 07                            btst d3,d7
loc_16cfe 07 07                            btst d3,d7
loc_16d00 07 07                            btst d3,d7
loc_16d02 07 07                            btst d3,d7
loc_16d04 08 08                            .short 0x0808
loc_16d06 08 08                            .short 0x0808
loc_16d08 08 08                            .short 0x0808
loc_16d0a 08 08                            .short 0x0808
loc_16d0c 08 08                            .short 0x0808
loc_16d0e 08 08                            .short 0x0808
loc_16d10 08 08                            .short 0x0808
loc_16d12 08 08                            .short 0x0808
loc_16d14 08 08                            .short 0x0808
loc_16d16 08 08                            .short 0x0808
loc_16d18 00 01 6d 3c                      ori.b #$3C,d1
loc_16d1c 00 01 6d 3e                      ori.b #62,d1
loc_16d20 00 01 6d 48                      ori.b #72,d1
loc_16d24 00 01 6d 5a                      ori.b #90,d1
loc_16d28 00 01 6d 68                      ori.b #104,d1
loc_16d2c 00 01 6d 7a                      ori.b #122,d1
loc_16d30 00 01 6d 8c                      ori.b #-116,d1
loc_16d34 00 01 6d 92                      ori.b #-110,d1
loc_16d38 00 01 6d a0                      ori.b #-96,d1
loc_16d3c ff ff                            .short 0xffff
loc_16d3e 01 2c f4 e8                      btst d0,(a4)(-2840)
loc_16d42 01 2c 03 10                      btst d0,(a4)(784)
loc_16d46 ff ff                            .short 0xffff
loc_16d48 01 2c fe f8                      btst d0,(a4)(-264)
loc_16d4c 00 14 0c 10                      ori.b #$10,(a4)
loc_16d50 00 40 fa f0                      ori.w #-1296,d0
loc_16d54 01 2c 06 10                      btst d0,(a4)(1552)
loc_16d58 ff ff                            .short 0xffff
loc_16d5a 01 2c 00 00                      btst d0,(a4)(0)
loc_16d5e 00 58 00 00                      ori.w #0,(a0)+
loc_16d62 01 2c c0 de                      btst d0,(a4)(-16162)
loc_16d66 ff ff                            .short 0xffff
loc_16d68 01 2c fe f8                      btst d0,(a4)(-264)
loc_16d6c 00 30 12 20 00 3a                ori.b #$20,(a0)(000000000000003a,d0.w)
loc_16d72 ee e0                            .short 0xeee0
loc_16d74 01 2c 06 20                      btst d0,(a4)(1568)
loc_16d78 ff ff                            .short 0xffff
loc_16d7a 01 2c 00 00                      btst d0,(a4)(0)
loc_16d7e 00 32 00 00 00 18                ori.b #0,(a2)(0000000000000018,d0.w)
loc_16d84 e4 e0                            roxrw (a0)-
loc_16d86 01 2c 1c 0c                      btst d0,(a4)(7180)
loc_16d8a ff ff                            .short 0xffff
loc_16d8c 01 2c 0d 1c                      btst d0,(a4)(3356)
loc_16d90 ff ff                            .short 0xffff
loc_16d92 01 2c f2 e0                      btst d0,(a4)(-3360)
loc_16d96 00 28 fc e0 01 2c                ori.b #-32,(a0)(300)
loc_16d9c 03 20                            btst d1,(a0)-
loc_16d9e ff ff                            .short 0xffff
loc_16da0 01 2c fe f8                      btst d0,(a4)(-264)
loc_16da4 01 2c 03 20                      btst d0,(a4)(800)
loc_16da8 ff ff                            .short 0xffff
loc_16daa 08 d0 00 07                      bset    #7,(a0)
loc_16dae 66 1a                            bne.s   loc_16dca
loc_16db0 31 7c 00 d8 00 20                move.w  #216,$20(a0)
loc_16db6 31 7c 01 18 00 24                move.w  #280,$24(a0)
loc_16dbc 21 7c 00 01 ac a4 00 0c          move.l  #109732,$C(a0)
loc_16dc4 11 fc 00 01 d2 7b                move.b  #1,($FFFFD27B).w
loc_16dca 4e 75                            rts
loc_16dcc 08 d0 00 07                      bset    #7,(a0)
loc_16dd0 66 14                            bne.s   loc_16de6
loc_16dd2 21 7c 00 01 ad 32 00 0c          move.l  #109874,$C(a0)
loc_16dda 31 7c 00 f0 00 20                move.w  #$F0,$20(a0)
loc_16de0 31 7c 01 08 00 24                move.w  #264,$24(a0)
loc_16de6 4e 75                            rts

; TODO - End of code?

Pal_Main:                                        ; $16DE8
                incbin  "Palettes\Main.bin"




loc_16e58: 81 57                            or.w d0,(sp)
loc_16e5a 80 03                            or.b d3,d0
loc_16e5c 00 14 03 24                      ori.b #36,(a4)
loc_16e60 06 35 13 45 16 55                addi.b #69,(a5)(0000000000000055,d1.w:8)
loc_16e66 15 66 32 74                      move.b  (a6)-,(a2)(12916)
loc_16e6a 05 81                            bclr d2,d1
loc_16e6c 04 04 16 2f                      subi.b #47,d4
loc_16e70 27 6e 38 e6 82 05                move.l  (a6)(14566),(a3)(-32251)
loc_16e76 10 17                            move.b  (sp),d0
loc_16e78 6f 83                            ble.s   loc_16dfd
loc_16e7a 04 02 16 30                      subi.b #$30,d2
loc_16e7e 28 e2                            move.l  (a2)-,(a4)+
loc_16e80 78 ee                            moveq   #-18,d4
loc_16e82 84 06                            or.b d6,d2
loc_16e84 31 18                            move.w  (a0)+,(a0)-
loc_16e86 f1 85                            .short 0xf185
loc_16e88 05 11                            btst d2,(a1)
loc_16e8a 18 e7                            move.b -(sp),(a4)+
loc_16e8c 86 05                            or.b d5,d3
loc_16e8e 14 17                            move.b  (sp),d2
loc_16e90 6c 28                            bge.s   loc_16eba
loc_16e92 eb 87                            asl.l #5,d7
loc_16e94 04 07 17 6a                      subi.b #106,d7
loc_16e98 28 e9 88 08                      move.l  (a1)(-30712),(a4)+
loc_16e9c e3 89                            lsl.l #1,d1
loc_16e9e 07 6d 18 ed                      bchg d3,(a5)(6381)
loc_16ea2 8a 06                            or.b d6,d5
loc_16ea4 33 18                            move.w  (a0)+,(a1)-
loc_16ea6 ea 28                            lsr.b d5,d0
loc_16ea8 ec 8b                            lsrl #6,d3
loc_16eaa 08 e8 8c 05 12 17                bset    #5,(a0)(4631)
loc_16eb0 70 8d                            moveq   #-115,d0
loc_16eb2 07 6b 8e 06                      bchg d3,(a3)(-29178)
loc_16eb6 34 8f                            move.w sp,(a2)
loc_16eb8 06 2e 17 72 ff e3                addi.b #114,(a6)(-29)
loc_16ebe fd 4f                            .short 0xfd4f
loc_16ec0 1f 6f 1d e6 82 f1                move.b  (sp)(7654),(sp)(-32015)
loc_16ec6 79 de                            .short 0x79de
loc_16ec8 10 73                            .short 0x1073
loc_16eca 1a 55                            .short 0x1a55
loc_16ecc 0f 98                            bclr d7,(a0)+
loc_16ece 20 bc ef 17 84 3b                move.l  #-283671493,(a0)
loc_16ed4 ee fc                            .short 0xeefc
loc_16ed6 f5 df                            .short 0xf5df
loc_16ed8 ae e4                            .short 0xaee4
loc_16eda d7 35 cd 75 ae 6b 8f 91          add.b d3,(a5)(ffffffffae6b8f91)@0)
loc_16ee2 f2 3b                            .short 0xf23b
loc_16ee4 8f 95                            orl d7,(a5)
loc_16ee6 b9 1d                            eor.b d4,(a5)+
loc_16ee8 c7 c8                            .short 0xc7c8
loc_16eea ff 7f                            .short 0xff7f
loc_16eec 0d 7c                            .short 0x0d7c
loc_16eee a0 77                            .short 0xa077
loc_16ef0 7e 76                            moveq   #118,d7
loc_16ef2 e1 0e                            lsl.b #8,d6
loc_16ef4 5f bd                            .short 0x5fbd
loc_16ef6 b9 bf                            .short 0xb9bf
loc_16ef8 65 ae                            bcs.s   loc_16ea8
loc_16efa e8 28                            lsr.b d4,d0
loc_16efc fd 96                            .short 0xfd96
loc_16efe bb a1                            eor.l d5,(a1)-
loc_16f00 77 ef                            .short 0x77ef
loc_16f02 6e 6b                            bgt.s   loc_16f6f
loc_16f04 bf 3b                            .short 0xbf3b
loc_16f06 70 85                            moveq   #-123,d0
loc_16f08 db ce                            adda.l a6,a5
loc_16f0a 1a 6b                            .short 0x1a6b
loc_16f0c 51 fc                            .short 0x51fc
loc_16f0e c1 fc 11 fe                      mulsw #4606,d0
loc_16f12 11 cc                            .short 0x11cc
loc_16f14 3f d8                            .short 0x3fd8
loc_16f16 a3 fd                            .short 0xa3fd
loc_16f18 9f f1 fe 77                      suba.l (a1)(0000000000000077,sp:l:8),sp
loc_16f1c 2b 6e 9d f6 be d7                move.l  (a6)(-25098),(a5)(-16681)
loc_16f22 d5 2b fe 95                      add.b d2,(a3)(-363)
loc_16f26 75 55                            .short 0x7555
loc_16f28 55 55                            subq.w  #2,(a5)
loc_16f2a d3 5f                            add.w   d1,(sp)+
loc_16f2c 47 2e 8f ce                      chkl (a6)(-28722),d3
loc_16f30 b6 03                            cmp.b d3,d3
loc_16f32 05 55                            bchg d2,(a5)
loc_16f34 55 05                            subq.b  #2,d5
loc_16f36 1d f1                            .short 0x1df1
loc_16f38 56 2f da db                      addq.b  #3,(sp)(-9509)
loc_16f3c 52 aa aa d7                      addq.l #1,(a2)(-21801)
loc_16f40 01 83                            bclr d0,d3
loc_16f42 60 30                            bra.s   loc_16f74
loc_16f44 55 55                            subq.w  #2,(a5)
loc_16f46 55 05                            subq.b  #2,d5
loc_16f48 1d f1                            .short 0x1df1
loc_16f4a 3f f1                            .short 0x3ff1
loc_16f4c 8f f3 0c 7f                      divsw (a3)(000000000000007f,d0:l:4),d7
loc_16f50 ae a3                            .short 0xaea3
loc_16f52 1f eb                            .short 0x1feb
loc_16f54 8a 7f                            .short 0x8a7f
loc_16f56 55 46                            subq.w  #2,d6
loc_16f58 11 be                            .short 0x11be
loc_16f5a 3c 47                            movea.w d7,a6
loc_16f5c 80 c3                            divu.w d3,d0
loc_16f5e 65 71                            bcs.s   loc_16fd1
loc_16f60 d4 b6 c7 f6 ed 4f e2 a9 96 5f    add.l @(ffffffffed4fe2a9)@(ffffffffffff965f),d2
loc_16f6a d3 3f                            .short 0xd33f
loc_16f6c eb 1e                            rol.b #5,d6
loc_16f6e 3f b7 56 c7 55 a9 1c 8a          move.w  (sp)(ffffffffffffffc7,d5.w:8),@(0000000000001c8a,d5.w:4)@0)
loc_16f76 a4 78                            .short 0xa478
loc_16f78 0e 23                            .short 0x0e23
loc_16f7a c0 61                            and.w (a1)-,d0
loc_16f7c b2 b8 ea 5b                      cmp.l ($FFFFea5b,d1
loc_16f80 63 aa                            bls.s   loc_16f2c
loc_16f82 d4 8e                            add.l a6,d2
loc_16f84 45 5c                            .short 0x455c
loc_16f86 23 be                            .short 0x23be
loc_16f88 2d fe                            .short 0x2dfe
loc_16f8a 33 fe                            .short 0x33fe
loc_16f8c b3 7f                            .short 0xb37f
loc_16f8e 1d 5b f8 e0                      move.b  (a3)+,(a6)(-1824)
loc_16f92 bf aa a0 a3                      eor.l d7,(a2)(-24413)
loc_16f96 7c 70                            moveq   #112,d6
loc_16f98 6c 01                            bge.s   loc_16f9b
loc_16f9a 65 1a                            bcs.s   loc_16fb6
loc_16f9c 5b a5                            subql #5,(a5)-
loc_16f9e 5b f8 e7 fd                      smi ($FFFFe7fd
loc_16fa2 50 4b                            addq.w  #8,a3
loc_16fa4 97 f8 cf fa                      suba.l ($FFFFCffa,a3
loc_16fa8 cd fc 75 b7                      mulsw #30135,d6
loc_16fac 4d 79                            .short 0x4d79
loc_16fae d5 b0 18 36                      add.l d2,(a0)(0000000000000036,d1:l)
loc_16fb2 00 b2 8d 2d d2 b6 7d ea a0 a3 be 27  ori.l #-1926376778,@(ffffffffffffa0a3)@(ffffffffffffbe27)
loc_16fbe dd ff                            .short 0xddff
loc_16fc0 6c 7f                            bge.s   loc_17041
loc_16fc2 ce b8 ff 9e                      and.l ($FFFFFF9e,d7
loc_16fc6 9f e5                            suba.l (a5)-,sp
loc_16fc8 5c 23                            addq.b  #6,(a3)-
loc_16fca 7c 78                            moveq   #120,d6
loc_16fcc 8f 00                            sbcd d0,d7
loc_16fce 43 64                            .short 0x4364
loc_16fd0 e3 4c                            lsl.w   #1,d4
loc_16fd2 75 1f                            .short 0x751f
loc_16fd4 4a e3                            tas (a3)-
loc_16fd6 fe 7a                            .short 0xfe7a
loc_16fd8 7f 95                            .short 0x7f95
loc_16fda 4b 2e ef fb                      chkl (a6)(-4101),d5
loc_16fde 63 fe                            bls.s   loc_16fde
loc_16fe0 75 c7                            .short 0x75c7
loc_16fe2 51 f4 d2 33                      sf (a4)(0000000000000033,a5.w:2)
loc_16fe6 e7 05                            aslb #3,d5
loc_16fe8 52 3c                            .short 0x523c
loc_16fea 07 11                            btst d3,(a1)
loc_16fec e0 08                            lsr.b #8,d0
loc_16fee 6c 9c                            bge.s   loc_16f8c
loc_16ff0 69 8e                            bvss loc_16f80
loc_16ff2 a3 e9                            .short 0xa3e9
loc_16ff4 5c 75 1f 4d                      addq.w  #6,(a5)@0)
loc_16ff8 23 3e                            .short 0x233e
loc_16ffa 70 55                            moveq   #85,d0
loc_16ffc e8 ce                            .short 0xe8ce
loc_16ffe 5d 19                            subq.b  #6,(a1)+
loc_17000 cb 6f 1d c8                      and.w d5,(sp)(7624)
loc_17004 68 2f                            bvcs loc_17035
loc_17006 17 9d e1 34 e6 34 aa 1d          move.b  (a5)+,(a3)(ffffffffe634aa1d)@0,a6.w)
loc_1700e db 82                            addxl d2,d5
loc_17010 0b ce f1 78                      movepl d5,(a6)(-3720)
loc_17014 b8 ef fd 77                      cmpa.w (sp)(-649),a4
loc_17018 2f d7                            .short 0x2fd7
loc_1701a 5e 68 2f 17                      addq.w  #7,(a0)(12055)
loc_1701e 9d e1                            suba.l (a1)-,a6
loc_17020 07 31 a5 50                      btst d3,(a1)
loc_17024 f9 82                            .short 0xf982
loc_17026 0b ce f1 78                      movepl d5,(a6)(-3720)
loc_1702a 43 bd                            .short 0x43bd
loc_1702c 92 ef d7 5e                      subaw (sp)(-10402),a1
loc_17030 68 2f                            bvcs loc_17061
loc_17032 17 9d e1 07 31 a5 50 f9          move.b  (a5)+,(a3)@(0000000031a550f9,a6.w)
loc_1703a 82 0b                            .short 0x820b
loc_1703c ce f1 78 43                      mulu.w (a1)(0000000000000043,d7:l),d7
loc_17040 bf f5 dc bf                      cmpal (a5)(ffffffffffffffbf,a5:l:4),sp
loc_17044 5d 72 1a 0b                      subq.w  #6,(a2)b,d1:l:2)
loc_17048 c5 e7                            mulsw -(sp),d2
loc_1704a 78 4d                            moveq   #77,d4
loc_1704c 39 8d 2a 87                      move.w  a5,(a4)(ffffffffffffff87,d2:l:2)
loc_17050 76 e0                            moveq   #-32,d3
loc_17052 82 f3 bc 5e                      divu.w (a3)(000000000000005e,a3:l:4),d1
loc_17056 2e 3b ee fc                      move.l  (pc)(loc_17054,a6:l:8),d7
loc_1705a f5 cd                            .short 0xf5cd
loc_1705c 7b 5c                            .short 0x7b5c
loc_1705e d7 35 d3 d2 e6 b8                add.b d3,@0)@(ffffffffffffe6b8)
loc_17064 f9 1f                            .short 0xf91f
loc_17066 23 bb 41 ca dc 8e e3 b9 0f 97 e7 93  move.l %z(pc)@(ffffffffffffdc8e),@(000000000f97e793,a6.w:2)@0)
loc_17072 f5 c9                            .short 0xf5c9
loc_17074 a5 cd                            .short 0xa5cd
loc_17076 73 5c                            .short 0x735c
loc_17078 d7 5a                            add.w   d3,(a2)+
loc_1707a e6 b8                            ror.l d3,d0
loc_1707c f9 1f                            .short 0xf91f
loc_1707e 23 b8 f9 56 e3 b8 ee 6e 47 70    move.l  ($FFFFf956,@(ffffffffee6e4770,a6.w:2)
loc_17088 fc f2                            .short 0xfcf2
loc_1708a 69 73                            bvss loc_170ff
loc_1708c 5c d7                            sge (sp)
loc_1708e 35 d6                            .short 0x35d6
loc_17090 b9 ae 3e 47                      eor.l d4,(a6)(15943)
loc_17094 c8 ee 3e 56                      mulu.w (a6)(15958),d4
loc_17098 e4 77                            roxrw d2,d7
loc_1709a 1f 23                            move.b  (a3)-,-(sp)
loc_1709c e5 f9 e4 fd 72 68                roxlw 0xe4fd7268
loc_170a2 8d 73 5d a1 dd 6b                or.w d6,@(ffffffffffffdd6b,d5:l:4)@0)
loc_170a8 9a e3                            subaw (a3)-,a5
loc_170aa b9 0f                            cmpmb (sp)+,(a4)+
loc_170ac 91 dc                            suba.l (a4)+,a0
loc_170ae 7c ac                            moveq   #-84,d6
loc_170b0 97 1d                            sub.b d3,(a5)+
loc_170b2 c7 c8                            .short 0xc7c8
loc_170b4 ff 7e                            .short 0xff7e
loc_170b6 2e bf                            .short 0x2ebf
loc_170b8 f5 df                            .short 0xf5df
loc_170ba bf 3f                            .short 0xbf3f
loc_170bc f7 b6                            .short 0xf7b6
loc_170be 8d c9                            .short 0x8dc9
loc_170c0 4e 12                            .short 0x4e12
loc_170c2 3e 42                            movea.w d2,sp
loc_170c4 ef ce                            .short 0xefce
loc_170c6 a7 26                            .short 0xa726
loc_170c8 bb f3 b7 1d                      cmpal (a3)@0,a3.w:8),a5
loc_170cc df 9e                            add.l d7,(a6)+
loc_170ce e1 f9 e9 68 3f 7e                asl.w 0xe9683f7e
loc_170d4 21 fc fd 77 56 1a ee 82          move.l  #-42510822,($FFFFee82
loc_170dc ce 1a                            and.b (a2)+,d7
loc_170de ee 87                            asr.l #7,d7
loc_170e0 ef f5                            .short 0xeff5
loc_170e2 dc df                            adda.w (sp)+,a6
loc_170e4 bf 10                            eor.b d7,(a0)
loc_170e6 ba 7f                            .short 0xba7f
loc_170e8 9e 96                            sub.l (a6),d7
loc_170ea 83 f7 e7 fe fc b9 2d 79 0f ef    divsw @(fffffffffcb92d79)@(0000000000000fef),d1
loc_170f4 b7 ef ce ef                      cmpal (sp)(-12561),a3
loc_170f8 cf 70 fc f4                      and.w d7,(a0)(fffffffffffffff4,sp:l:4)
loc_170fc bf 3c                            .short 0xbf3c
loc_170fe 3f 3b 70 85                      move.w  (pc)(loc_17085,d7.w),-(sp)
loc_17102 c2 ef d6 dc                      mulu.w (sp)(-10532),d1
loc_17106 da 7e                            .short 0xda7e
loc_17108 8b 5d                            or.w d5,(a5)+
loc_1710a d0 3d                            .short 0xd03d
loc_1710c 17 7e                            .short 0x177e
loc_1710e bb a0                            eor.l d5,(a0)-
loc_17110 39 16                            move.w  (a6),(a4)-
loc_17112 bb a7                            eor.l d5,-(sp)
loc_17114 fa f1                            .short 0xfaf1
loc_17116 0f e7                            bset d7,-(sp)
loc_17118 a0 92                            .short 0xa092
loc_1711a 16 52                            .short 0x1652
loc_1711c e6 1f                            ror.b #3,d7
loc_1711e 9e 4b                            sub.w a3,d7
loc_17120 b4 1f                            cmp.b (sp)+,d2
loc_17122 be bf                            .short 0xbebf
loc_17124 41 fb e1 28 7f 05                lea     (pc)(loc_1f02b,a6.w),a0
loc_1712a 47 0b                            .short 0x470b
loc_1712c b9 bf                            .short 0xb9bf
loc_1712e 7f 0d                            .short 0x7f0d
loc_17130 39 2f 34 85                      move.w  (sp)(13445),(a4)-
loc_17134 ff ae                            .short 0xffae
loc_17136 1c df                            move.b  (sp)+,(a6)+
loc_17138 ae 1c                            .short 0xae1c
loc_1713a c3 77 ef 14                      and.w d1,(sp)@0,a6:l:8)
loc_1713e 6e fd                            bgt.s   loc_1713d
loc_17140 e7 35                            roxlb d3,d5
loc_17142 da 29 ff 04                      add.b (a1)(-252),d5
loc_17146 7f 38                            .short 0x7f38
loc_17148 7f b8                            .short 0x7fb8
loc_1714a 7e f8                            moveq   #-8,d7
loc_1714c 7f 85                            .short 0x7f85
loc_1714e 47 f8 7f 85                      lea loc_7f85,a3
loc_17152 a7 22                            .short 0xa722
loc_17154 c9 3f                            .short 0xc93f
loc_17156 78 2f                            moveq   #47,d4
loc_17158 d0 20                            add.b (a0)-,d0
loc_1715a e6 fc                            .short 0xe6fc
loc_1715c f2 0e                            .short 0xf20e
loc_1715e 60 97                            bra.s   loc_170f7
loc_17160 7f 31                            .short 0x7f31
loc_17162 45 f0 fd e7 ee 3f 6d b7 f7 5d    lea @(ffffffffffffee3f)@(000000006db7f75d),a2
loc_1716c a6 47                            .short 0xa647
loc_1716e c5 3c                            .short 0xc53c
loc_17170 2d 02                            move.l  d2,(a6)-
loc_17172 b5 f5 4c 27                      cmpal (a5)(0000000000000027,d4:l:4),a2
loc_17176 db 9e                            add.l d5,(a6)+
loc_17178 de c1                            adda.w d1,sp
loc_1717a fb 6f                            .short 0xfb6f
loc_1717c db fe                            .short 0xdbfe
loc_1717e f3 4e                            .short 0xf34e
loc_17180 56 be                            .short 0x56be
loc_17182 13 24                            move.b  (a4)-,(a1)-
loc_17184 c1 bf                            .short 0xc1bf
loc_17186 86 78 0e 23                      or.w loc_e23,d3
loc_1718a 23 e2 1f ca db 9a                move.l  (a2)-,0x1fcadb9a
loc_17190 a7 f2                            .short 0xa7f2
loc_17192 bb 6d c5 3c                      eor.w d5,(a5)(-15044)
loc_17196 2d 83 50 61                      move.l  d3,(a6)(0000000000000061,d5.w)
loc_1719a 52 af fa 87                      addq.l #1,(sp)(-1401)
loc_1719e fd f5                            .short 0xfdf5
loc_171a0 fe fb                            .short 0xfefb
loc_171a2 91 91                            sub.l d0,(a1)
loc_171a4 df 09                            addxb (a1)-,-(sp)
loc_171a6 df 84                            addxl d4,d7
loc_171a8 d3 88                            addxl (a0)-,(a1)-
loc_171aa ff a6                            .short 0xffa6
loc_171ac 64 7c                            bcc.s   loc_1722a
loc_171ae 43 f9 5b 73 57 55                lea 0x5b735755,a1
loc_171b4 56 2a 92 15                      addq.b  #3,(a2)(-28139)
loc_171b8 89 0a                            sbcd (a2)-,(a4)-
loc_171ba a4 aa                            .short 0xa4aa
loc_171bc a2 39                            .short 0xa239
loc_171be 45 55                            .short 0x4555
loc_171c0 54 d2                            scc (a2)
loc_171c2 3b d2                            .short 0x3bd2
loc_171c4 3b d5                            .short 0x3bd5
loc_171c6 46 38 5b f4                      not.b loc_5bf4
loc_171ca 8c 47                            or.w d7,d6
loc_171cc a8 cb                            .short 0xa8cb
loc_171ce 1b 78 d2 d8 d3 2b                move.b  ($FFFFd2d8,(a5)(-11477)
loc_171d4 d4 c9                            adda.w a1,a2
loc_171d6 4a 78 8c 6d                      tst.w   ($FFFF8c6d
loc_171da 41 4c                            .short 0x414c
loc_171dc 46 36 a6 20                      not.b (a6)(0000000000000020,a2.w:8)
loc_171e0 ad 4c                            .short 0xad4c
loc_171e2 4e 02                            .short 0x4e02
loc_171e4 f8 02                            .short 0xf802
loc_171e6 55 3c                            .short 0x553c
loc_171e8 70 b7                            moveq   #-73,d0
loc_171ea 12 aa 8c 70                      move.b  (a2)(-29584),(a1)
loc_171ee 0e d8                            .short 0x0ed8
loc_171f0 e0 aa                            lsrl d0,d2
loc_171f2 31 c2 df a4                      move.w  d2,($FFFFdfa4
loc_171f6 ae a5                            .short 0xaea5
loc_171f8 51 8e                            subql #8,a6
loc_171fa 16 c7                            move.b  d7,(a3)+
loc_171fc 7a a8                            moveq   #-88,d5
loc_171fe c7 03                            abcd d3,d3
loc_17200 d8 3f                            .short 0xd83f
loc_17202 48 3f                            .short 0x483f
loc_17204 48 7a 86 38                      pea (pc)(loc_f83e)
loc_17208 29 ea                            .short 0x29ea
loc_1720a 3d 50 1b 20                      move.w  (a0),(a6)(6944)
loc_1720e 31 7c 8b 2c 68 3a                move.w  #-29908,(a0)(26682)
loc_17214 cd ff                            .short 0xcdff
loc_17216 a8 d8                            .short 0xa8d8
loc_17218 e0 31                            roxrb d0,d1
loc_1721a 25 6d 47 a8 74 a9                move.l  (a5)(18344),(a2)(29865)
loc_17220 ea 51                            roxrw #5,d1
loc_17222 c5 6e 25 5b                      and.w d2,(a6)(9563)
loc_17226 74 9e                            moveq   #-98,d2
loc_17228 a3 d4                            .short 0xa3d4
loc_1722a a7 a9                            .short 0xa7a9
loc_1722c 46 38 5b f4                      not.b loc_5bf4
loc_17230 95 d4                            suba.l (a4),a2
loc_17232 b5 d4                            cmpal (a4),a2
loc_17234 7a 93                            moveq   #-109,d5
loc_17236 ad 23                            .short 0xad23
loc_17238 b3 fc 66 40 8f 01                cmpal #1715506945,a1
loc_1723e c4 7f                            .short 0xc47f
loc_17240 b3 1f                            eor.b d1,(sp)+
loc_17242 b3 18                            eor.b d1,(a0)+
loc_17244 0f d9                            bset d7,(a1)+
loc_17246 9f 11                            sub.b d7,(a1)
loc_17248 e0 38                            ror.b d0,d0
loc_1724a 8c a0                            orl (a0)-,d6
loc_1724c 78 02                            moveq   #2,d4
loc_1724e 80 fe                            .short 0x80fe
loc_17250 1c 05                            move.b  d5,d6
loc_17252 09 a0                            bclr d4,(a0)-
loc_17254 c4 0a                            .short 0xc40a
loc_17256 01 0f 08 04                      movepw (sp)(2052),d0
loc_1725a 62 80                            bhi.s   loc_171dc
loc_1725c 4a 34 02 51                      tst.b   (a4)(0000000000000051,d0.w:2)
loc_17260 26 94                            move.l  (a4),(a3)
loc_17262 4b 24                            chkl (a4)-,d5
loc_17264 75 14                            .short 0x7514
loc_17266 1c e1                            move.b  (a1)-,(a6)+
loc_17268 fc 36                            .short 0xfc36
loc_1726a 83 11                            or.b d1,(a1)
loc_1726c a0 81                            .short 0xa081
loc_1726e 02 64 10 c1                      andi.w  #4289,(a4)-
loc_17272 a8 82                            .short 0xa882
loc_17274 04 c9                            .short 0x04c9
loc_17276 44 10                            negb (a0)
loc_17278 9a 51                            sub.w (a1),d5
loc_1727a 05 e5                            bset d2,(a5)-
loc_1727c 8b d0                            divsw (a0),d5
loc_1727e 40 77 11 90                      negxw @0,d1.w)
loc_17282 21 81 f1 1f ec c6 03 f6          move.l  d1,(a0)@(ffffffffecc603f6,sp.w)
loc_1728a 63 f6                            bls.s   loc_17282
loc_1728c 67 c4                            beq.s   loc_17252
loc_1728e 20 47                            movea.l d7,a0
loc_17290 c4 20                            and.b (a0)-,d2
loc_17292 4c 50                            .short 0x4c50
loc_17294 4c 06                            .short 0x4c06
loc_17296 10 6e                            .short 0x106e
loc_17298 24 08                            move.l  a0,d2
loc_1729a 78 20                            moveq   #$20,d4
loc_1729c dd 82                            addxl d2,d6
loc_1729e 04 74 72 40 94 0e                subi.w  #29248,(a4)e,a1.w:4)
loc_172a4 10 23                            move.b  (a3)-,d0
loc_172a6 a0 43                            .short 0xa043
loc_172a8 4a 1f                            tst.b   (sp)+
loc_172aa 35 2f 1b 12                      move.w  (sp)(6930),(a2)-
loc_172ae 88 2f 67 41                      or.b (sp)(26433),d4
loc_172b2 7c de                            moveq   #-34,d6
loc_172b4 f9 a0                            .short 0xf9a0
loc_172b6 74 9d                            moveq   #-99,d2
loc_172b8 10 3a 32 3a                      move.b  (pc)(loc_1a4f4),d0
loc_172bc 07 49 d2 f6                      movepl (a1)(-11530),d3
loc_172c0 eb 7d                            rol.w d5,d5
loc_172c2 9a 9a                            sub.l (a2)+,d5
loc_172c4 f0 94                            .short 0xf094
loc_172c6 6b c2                            bmi.s   loc_1728a
loc_172c8 3c ef 7b 23                      move.w  (sp)(31523),(a6)+
loc_172cc 84 64                            or.w (a4)-,d2
loc_172ce 70 94                            moveq   #-108,d0
loc_172d0 34 70 8e 8d                      movea.w (a0)(ffffffffffffff8d,a0:l:8),a2
loc_172d4 7d 27                            .short 0x7d27
loc_172d6 02 14 7c 4e                      andi.b  #78,(a4)
loc_172da 18 0c                            .short 0x180c
loc_172dc 02 04 e2 09                      andi.b  #9,d4
loc_172e0 04 09                            .short 0x0409
loc_172e2 80 78 3a 04                      or.w loc_3a04,d0
loc_172e6 c0 38 a2 04                      and.b ($FFFFa204,d0
loc_172ea 20 81                            move.l  d1,(a0)
loc_172ec 1d 07                            move.b  d7,(a6)-
loc_172ee 31 d1 06 2f                      move.w  (a1),loc_62f
loc_172f2 1f 18                            move.b  (a0)+,-(sp)
loc_172f4 94 14                            sub.b (a4),d2
loc_172f6 40 b2 87 f0 db f8 5f e3          negxl @(ffffffffdbf85fe3)
loc_172fe 1f d3                            .short 0x1fd3
loc_17300 05 1b                            btst d2,(a3)+
loc_17302 61 8f                            bsr.s   loc_17293
loc_17304 f8 46                            .short 0xf846
loc_17306 ec 2f                            lsr.b d6,d7
loc_17308 9e f3 2c a1                      subaw (a3)(ffffffffffffffa1,d2:l:4),sp
loc_1730c 5e e3                            sgt (a3)-
loc_1730e fe 9a                            .short 0xfe9a
loc_17310 13 40 e0 21                      move.b  d0,(a1)(-8159)
loc_17314 79 6e                            .short 0x796e
loc_17316 10 c2                            move.b  d2,(a0)+
loc_17318 f2 6d                            .short 0xf26d
loc_1731a ea 70                            roxrw d5,d0
loc_1731c c2 b0 1f e3 4f e9 88 1c 18 b7    and.l @(0000000000004fe9)@(ffffffff881c18b7),d1
loc_17326 16 e5                            move.b  (a5)-,(a3)+
loc_17328 c9 07                            abcd d7,d4
loc_1732a f0 d0                            .short 0xf0d0
loc_1732c ff 85                            .short 0xff85
loc_1732e 3e e1                            move.w  (a1)-,(sp)+
loc_17330 dd 6f d2 9e                      add.w   d6,(sp)(-11618)
loc_17334 02 27 16 25                      andi.b  #37,-(sp)
loc_17338 68 b1                            bvcs loc_172eb
loc_1733a 1c 4f                            .short 0x1c4f
loc_1733c 03 8d bb 87                      movepw d1,(a5)(-17529)
loc_17340 74 ff                            moveq   #-1,d2
loc_17342 45 38 34 0e                      chkl loc_340e,d2
loc_17346 13 81 c1 a1 38 08                move.b  d1,@(0000000000003808,a4.w)@0)
loc_1734c 31 1c                            move.w  (a4)+,(a0)-
loc_1734e 1a 03                            move.b  d3,d5
loc_17350 fa 69                            .short 0xfa69
loc_17352 dc 7f                            .short 0xdc7f
loc_17354 a2 9c                            .short 0xa29c
loc_17356 1a 0d                            .short 0x1a0d
loc_17358 09 c1                            bset d4,d1
loc_1735a a0 d0                            .short 0xa0d0
loc_1735c 9c 04                            sub.b d4,d6
loc_1735e 0e 0d                            .short 0x0e0d
loc_17360 03 24                            btst d1,(a4)-
loc_17362 fe 98                            .short 0xfe98
loc_17364 ee 3c                            ror.b d7,d4
loc_17366 0f 9c                            bclr d7,(a4)+
loc_17368 13 45 58 9a                      move.b  d5,(a1)(22682)
loc_1736c 33 c0 e2 30 b4 48                move.w  d0,0xe230b448
loc_17372 7f 4c                            .short 0x7f4c
loc_17374 7f 8f                            .short 0x7f8f
loc_17376 9b f4 a4 d8                      suba.l (a4)(ffffffffffffffd8,a2.w:4),a5
loc_1737a 9d 10                            sub.b d6,(a0)
loc_1737c f1 3a                            .short 0xf13a
loc_1737e 21 e2 74 4b                      move.l  (a2)-,loc_744b
loc_17382 51 15                            subq.b  #8,(a5)
loc_17384 55 8b                            subql #2,a3
loc_17386 52 64                            addq.w  #1,(a4)-
loc_17388 f9 3a                            .short 0xf93a
loc_1738a b4 2b 02 0e                      cmp.b (a3)(526),d2
loc_1738e d0 c4                            adda.w d4,a0
loc_17390 dd 4e                            addxw (a6)-,(a6)-
loc_17392 18 bd                            .short 0x18bd
loc_17394 a1 4b                            .short 0xa14b
loc_17396 d6 ce                            adda.w a6,a3
loc_17398 70 26                            moveq   #38,d0
loc_1739a 73 c5                            .short 0x73c5
loc_1739c 0a a4 8a 55 24 9d                eori.l #-1974131555,(a4)-
loc_173a2 05 22                            btst d2,(a2)-
loc_173a4 fc 41                            .short 0xfc41
loc_173a6 28 78 cd 28                      movea.l ($FFFFCd28,a4
loc_173aa 78 cd                            moveq   #-51,d4
loc_173ac 28 78 cd 28                      movea.l ($FFFFCd28,a4
loc_173b0 a6 f9                            .short 0xa6f9
loc_173b2 3e 45                            movea.w d5,sp
loc_173b4 a9 02                            .short 0xa902
loc_173b6 07 ab aa ab                      bclr d3,(a3)(-21845)
loc_173ba e4 ea 9c e5                      roxrw (a2)(-25371)
loc_173be fa 22                            .short 0xfa22
loc_173c0 fd 90                            .short 0xfd90
loc_173c2 c4 a0                            and.l (a0)-,d2
loc_173c4 d0 c4                            adda.w d4,a0
loc_173c6 6a b7                            bpl.s   loc_1737f
loc_173c8 4a cf                            .short 0x4acf
loc_173ca 12 81                            move.b  d1,(a1)
loc_173cc 36 e0                            move.w  (a0)-,(a3)+
loc_173ce 8d fc 3f f1                      divsw #16369,d6
loc_173d2 16 38 04 de                      move.b loc_4de,d3
loc_173d6 43 56                            .short 0x4356
loc_173d8 29 3e                            .short 0x293e
loc_173da 90 4a                            sub.w a2,d0
loc_173dc 78 94                            moveq   #-108,d4
loc_173de 0a 77 8b db fa 67                eori.w #-29733,(sp)(0000000000000067,sp:l:2)
loc_173e4 fe 22                            .short 0xfe22
loc_173e6 fe 11                            .short 0xfe11
loc_173e8 47 16                            chkl (a6),d3
loc_173ea 7c 9d                            moveq   #-99,d6
loc_173ec 66 f9                            bne.s   loc_173e7
loc_173ee 3a e5                            move.w  (a5)-,(a5)+
loc_173f0 fc 22                            .short 0xfc22
loc_173f2 e7 40                            asl.w #3,d0
loc_173f4 81 02                            sbcd d2,d0
loc_173f6 0f e8 b7 f4                      bset d7,(a0)(-18444)
loc_173fa 59 05                            subq.b  #4,d5
loc_173fc e1 2c                            lsl.b d0,d4
loc_173fe 81 09                            sbcd (a1)-,(a0)-
loc_17400 8a c4                            divu.w d4,d5
loc_17402 09 b0 32 32                      bclr d4,(a0)(0000000000000032,d3.w:2)
loc_17406 42 80                            clr.l d0
loc_17408 82 08                            .short 0x8208
loc_1740a 6e 08                            bgt.s   loc_17414
loc_1740c 39 82 04 34                      move.w  d2,(a4)(0000000000000034,d0.w:4)
loc_17410 34 17                            move.w  (sp),d2
loc_17412 d5 2a 40 81                      add.b d2,(a2)(16513)
loc_17416 02 1f d3 3f                      andi.b  #$3F,(sp)+
loc_1741a d9 a1                            add.l d4,(a1)-
loc_1741c 40 40                            negxw d0
loc_1741e 41 90                            chkw (a0),d0
loc_17420 73 1a                            .short 0x731a
loc_17422 0b cf 74 d0                      movepl d5,(sp)(29904)
loc_17426 21 a2 cc 81                      move.l  (a2)-,(a0)(ffffffffffffff81,a4:l:4)
loc_1742a 4c 98 86 10                      movem.w (a0)+,d4/a1-a2/sp
loc_1742e 24 28 08 11                      move.l  (a0)(2065),d2
loc_17432 de 7c c2 f1                      add.w #-15631,d7
loc_17436 cc dc                            mulu.w (a4)+,d6
loc_17438 d3 40                            addxw d0,d1
loc_1743a 8a 4c                            .short 0x8a4c
loc_1743c 40 87                            negxl d7
loc_1743e 10 c0                            move.b  d0,(a0)+
loc_17440 71 19                            .short 0x7119
loc_17442 02 18 02 32                      andi.b  #50,(a0)+
loc_17446 04 0a                            .short 0x040a
loc_17448 64 65                            bcc.s   loc_174af
loc_1744a 32 ff                            .short 0x32ff
loc_1744c 0c 07 f5 c3                      cmpi.b  #-61,d7
loc_17450 ae 54                            .short 0xae54
loc_17452 8d 23                            or.b d6,(a3)-
loc_17454 d7 01                            addxb d1,d3
loc_17456 fb 3b                            .short 0xfb3b
loc_17458 10 20                            move.b  (a0)-,d0
loc_1745a 59 10                            subq.b  #4,(a0)
loc_1745c ff 0c                            .short 0xff0c
loc_1745e 07 f5 c3 ae 5f b6 8e c8          bset d3,@(0000000000005fb6)@(ffffffffffff8ec8,a4.w:2)
loc_17466 13 60 64 64                      move.b  (a0)-,(a1)(25700)
loc_1746a 08 13 13 17                      btst    #23,(a3)
loc_1746e f8 60                            .short 0xf860
loc_17470 3f ae 1d 72 a4 69                move.w  (a6)(7538),(sp)(0000000000000069,a2.w:4)
loc_17476 1d 91 80 20                      move.b  (a1),(a6)(0000000000000020,a0.w)
loc_1747a 46 56                            notw (a6)
loc_1747c 20 56                            movea.l (a6),a0
loc_1747e 20 43                            movea.l d3,a0
loc_17480 fc 30                            .short 0xfc30
loc_17482 1f d7                            .short 0x1fd7
loc_17484 0e b9                            .short 0x0eb9
loc_17486 7f 91                            .short 0x7f91
loc_17488 55 55                            subq.w  #2,(a5)
loc_1748a 6d 0c                            blt.s   loc_17498
loc_1748c a0 aa                            .short 0xa0aa
loc_1748e aa aa                            .short 0xaaaa
loc_17490 71 ca                            .short 0x71ca
loc_17492 2a aa aa ab                      move.l  (a2)(-21845),(a5)
loc_17496 64 c9                            bcc.s   loc_17461
loc_17498 14 e3                            move.b  (a3)-,(a2)+
loc_1749a 94 55                            sub.w (a5),d2
loc_1749c 55 55                            subq.w  #2,(a5)
loc_1749e 41 54                            .short 0x4154
loc_174a0 81 4c                            .short 0x814c
loc_174a2 82 02                            or.b d2,d1
loc_174a4 62 08                            bhi.s   loc_174ae
loc_174a6 0a 64 0a a4                      eori.w #2724,(a4)-
loc_174aa ab 6f                            .short 0xab6f
loc_174ac e2 fe                            .short 0xe2fe
loc_174ae 90 6e 55 17                      sub.w (a6)(21783),d0
loc_174b2 8f f8 8b d5                      divsw ($FFFF8bd5,d7
loc_174b6 46 e1                            move.w  (a1)-,sr
loc_174b8 fa 5f                            .short 0xfa5f
loc_174ba e2 2f                            lsr.b d1,d7
loc_174bc 75 f0                            .short 0x75f0
loc_174be 6d e6                            blt.s   loc_174a6
loc_174c0 50 1f                            addq.b  #8,(sp)+
loc_174c2 a2 62                            .short 0xa262
loc_174c4 df 32 05 0b cc 81 42 ff          add.b d7,(a2,d0.w:4)@(ffffffffcc8142ff)
loc_174cc d9 27                            add.b d4,-(sp)
loc_174ce 12 f7 34 39                      move.b  (sp)(0000000000000039,d3.w:4),(a1)+
loc_174d2 a0 20                            .short 0xa020
loc_174d4 46 43                            notw d3
loc_174d6 79 36                            .short 0x7936
loc_174d8 10 20                            move.b  (a0)-,d0
loc_174da 47 84                            chkw d4,d3
loc_174dc 08 11 f1 27                      btst    #39,(a1)
loc_174e0 f0 91                            .short 0xf091
loc_174e2 7b a0                            .short 0x7ba0
loc_174e4 90 48                            sub.w a0,d0
loc_174e6 24 c8                            move.l  a0,(a2)+
loc_174e8 12 1e                            move.b  (a6)+,d1
loc_174ea 00 82 36 10 21 78                ori.l #907026808,d2
loc_174f0 28 08                            move.l  a0,d4
loc_174f2 11 c1 38 93                      move.b  d1,loc_3893
loc_174f6 7a f7                            moveq   #-9,d5
loc_174f8 24 12                            move.l  (a2),d2
loc_174fa 09 0d c4 09                      movepw (a5)(-15351),d4
loc_174fe 89 01                            sbcd d1,d4
loc_17500 0f d9                            bset d7,(a1)+
loc_17502 82 86                            orl d6,d1
loc_17504 03 8a 02 04                      movepw d1,(a2)(516)
loc_17508 38 bf                            .short 0x38bf
loc_1750a 64 90                            bcc.s   loc_1749c
loc_1750c 41 c5                            .short 0x41c5
loc_1750e 0b 10                            btst d5,(a0)
loc_17510 28 5e                            movea.l (a6)+,a4
loc_17512 64 0a                            bcc.s   loc_1751e
loc_17514 17 b1 6f 99 40 7e                move.b @0,d6:l:8)@0),(a3)(000000000000007e,d4.w)
loc_1751a 8a f8 36 fe                      divu.w loc_36fe,d5
loc_1751e ec 37                            roxrb d6,d7
loc_17520 7e 88                            moveq   #-120,d7
loc_17522 43 88                            .short 0x4388
loc_17524 ca 04                            and.b d4,d5
loc_17526 08 f0 81 02 3c 37                bset    #2,(a0)(0000000000000037,d3:l:4)
loc_1752c 93 61                            sub.w   d1,(a1)-
loc_1752e 01 02                            btst d0,d2
loc_17530 32 9c                            move.w  (a4)+,(a1)
loc_17532 39 bb 93 f8 77 94 1a 18 02 80    move.w %z(pc)(0000000077941a18),(a4)(ffffffffffffff80,d0.w:2)
loc_1753c 81 36 10 21                      or.b d0,(a6)(0000000000000021,d1.w)
loc_17540 7e 00                            moveq   #0,d7
loc_17542 82 4c                            .short 0x824c
loc_17544 81 21                            or.b d0,(a1)-
loc_17546 c1 20                            and.b d0,(a0)-
loc_17548 90 43                            sub.w   d3,d0
loc_1754a ee fe                            .short 0xeefe
loc_1754c 1a 7e                            .short 0x1a7e
loc_1754e 89 a1                            orl d4,(a1)-
loc_17550 80 28 08 10                      or.b (a0)(2064),d0
loc_17554 c0 14                            and.b (a4),d0
loc_17556 30 18                            move.w  (a0)+,d0
loc_17558 20 21                            move.l  (a1)-,d0
loc_1755a fb 34                            .short 0xfb34
loc_1755c 20 4c                            movea.l a4,a0
loc_1755e 49 04                            chkl d4,d4
loc_17560 82 42                            or.w d2,d1
loc_17562 fe e4                            .short 0xfee4
loc_17564 c5 31 4c 53                      and.b d2,(a1)(0000000000000053,d4:l:4)
loc_17568 1f fa                            .short 0x1ffa
loc_1756a 88 88                            .short 0x8888
loc_1756c 88 88                            .short 0x8888
loc_1756e ff d3                            .short 0xffd3
loc_17570 b9 7f                            .short 0xb97f
loc_17572 a6 71                            .short 0xa671
loc_17574 b1 0f                            cmpmb (sp)+,(a0)+
loc_17576 14 c5                            move.b  d5,(a2)+
loc_17578 31 47 ff a8                      move.w  d7,(a0)(-88)
loc_1757c 88 88                            .short 0x8888
loc_1757e 88 8f                            .short 0x888f
loc_17580 fd 3b                            .short 0xfd3b
loc_17582 94 7f                            .short 0x947f
loc_17584 4d 09                            .short 0x4d09
loc_17586 a0 70                            .short 0xa070
loc_17588 4c 53                            .short 0x4c53
loc_1758a 12 c5                            move.b  d5,(a1)+
loc_1758c 31 ff                            .short 0x31ff
loc_1758e a8 88                            .short 0xa888
loc_17590 88 88                            .short 0x8888
loc_17592 8f fd                            .short 0x8ffd
loc_17594 3b 95 3f a6 20 70 62 4c          move.w  (a5),@(0000000000002070)@(000000000000624c,d3:l:8)
loc_1759c 52 89                            addq.l #1,a1
loc_1759e 8a 63                            or.w (a3)-,d5
loc_175a0 ff 51                            .short 0xff51
loc_175a2 11 11                            move.b  (a1),(a0)-
loc_175a4 11 1f                            move.b  (sp)+,(a0)-
loc_175a6 fa 77                            .short 0xfa77
loc_175a8 29 ff                            .short 0x29ff
loc_175aa 4c 15                            .short 0x4c15
loc_175ac a3 48                            .short 0xa348
loc_175ae 9e 02                            sub.b d2,d7
loc_175b0 27 16                            move.l  (a6),(a3)-
loc_175b2 25 68 b1 1c 4f 00                move.l  (a0)(-20196),(a2)(20224)
loc_175b8 51 b1 0f e9 9f 71                subql #8,@(ffffffffffff9f71)@0)
loc_175be e0 7c                            ror.w d0,d4
loc_175c0 e0 9a                            ror.l #8,d2
loc_175c2 2a c4                            move.l  d4,(a5)+
loc_175c4 d1 32 18 1c                      add.b d0,(a2)(000000000000001c,d1:l)
loc_175c8 4c ad 13 ee fe 9e                movem.w (a5)(-354),d1-d3/d5-a1/a4
loc_175ce ff e9                            .short 0xffe9
loc_175d0 9f f4 55 55                      suba.l (a4)@0),sp
loc_175d4 7f 6d                            .short 0x7f6d
loc_175d6 3f db                            .short 0x3fdb
loc_175d8 57 fa                            .short 0x57fa
loc_175da 27 bb 04 b6 f9 96 44 ac          move.l  (pc)(loc_17592,d0.w:4),@0)@(00000000000044ac,sp:l)
loc_175e2 99 22                            sub.b d4,(a2)-
loc_175e4 9f f4 4f fa 23 f4 56 fd 12 cf    suba.l @(0000000023f456fd)@(00000000000012cf),sp
loc_175ee 71 ff                            .short 0x71ff
loc_175f0 44 f7 29 ff 44 53 57 30 eb 5e 69 ff  move.w @(0000000044535730)@(ffffffffeb5e69ff),ccr
loc_175fc 07 24                            btst d3,(a4)-
loc_175fe 55 aa 64 8d                      subql #2,(a2)(25741)
loc_17602 85 70 cb f6 f3 fd ba ae 06 98    or.w d2,@(fffffffff3fdbaae)@(0000000000000698)
loc_1760c 0c 0d                            .short 0x0c0d
loc_1760e 30 55                            movea.w (a5),a0
loc_17610 1a ab a9 55                      move.b  (a3)(-22187),(a5)
loc_17614 67 85                            beq.s   loc_1759b
loc_17616 70 51                            moveq   #81,d0
loc_17618 fb 29                            .short 0xfb29
loc_1761a fe c9                            .short 0xfec9
loc_1761c 55 5b                            subq.w  #2,(a3)+
loc_1761e f8 68                            .short 0xf868
loc_17620 7f c3                            .short 0x7fc3
loc_17622 45 55                            .short 0x4555
loc_17624 b7 4d                            cmpmw (a5)+,(a3)+
loc_17626 ba 54                            cmp.w (a4),d5
loc_17628 ff ef                            .short 0xffef
loc_1762a fd 1d                            .short 0xfd1d
loc_1762c 4a bf                            .short 0x4abf
loc_1762e d6 3e                            .short 0xd63e
loc_17630 e5 ff                            .short 0xe5ff
loc_17632 97 f9 a1 fd 17 25                suba.l 0xa1fd1725,a3
loc_17638 5f ea a9 29                      sle (a2)(-22231)
loc_1763c 7f cb                            .short 0x7fcb
loc_1763e fe df                            .short 0xfedf
loc_17640 f1 55                            prestore (a5)
loc_17642 1f f5                            .short 0x1ff5
loc_17644 5c bf                            .short 0x5cbf
loc_17646 e5 ff                            .short 0xe5ff
loc_17648 6f f8                            ble.s   loc_17642
loc_1764a aa ff                            .short 0xaaff
loc_1764c d5 57                            add.w   d2,(sp)
loc_1764e fe 46                            .short 0xfe46
loc_17650 53 c0                            sls d0
loc_17652 13 7e                            .short 0x137e
loc_17654 cc 77 31 1c                      and.w (sp)@0,d3.w),d6
loc_17658 02 0b                            .short 0x020b
loc_1765a c2 0d                            .short 0xc20d
loc_1765c c2 f6 43 45                      mulu.w (a6)@0),d1
loc_17660 1f d2                            .short 0x1fd2
loc_17662 48 10                            nbcd (a0)
loc_17664 20 40                            movea.l d0,a0
loc_17666 86 03                            or.b d3,d3
loc_17668 f6 60                            .short 0xf660
loc_1766a 82 02                            or.b d2,d1
loc_1766c 32 46                            movea.w d6,a1
loc_1766e 43 dc                            .short 0x43dc
loc_17670 3f a2 77 9a 32 4f                move.w  (a2)-,@0,d7.w:8)@(000000000000324f)
loc_17676 f4 49                            .short 0xf449
loc_17678 fa 24                            .short 0xfa24
loc_1767a 21 80 e2 04                      move.l  d0,(a0)4,a6.w:2)
loc_1767e 7f b3                            .short 0x7fb3
loc_17680 3c 07                            move.w  d7,d6
loc_17682 10 48                            .short 0x1048
loc_17684 1a 02                            move.b  d2,d5
loc_17686 bc 21                            cmp.b (a1)-,d6
loc_17688 de 10                            add.b (a0),d7
loc_1768a d1 5b                            add.w   d0,(a3)+
loc_1768c f6 49                            .short 0xf649
loc_1768e 04 80 21 82 ff 4c                subi.l #562233164,d0
loc_17694 7e cd                            moveq   #-51,d7
loc_17696 09 0c 92 1c                      movepw (a4)(-28132),d4
loc_1769a c1 0d                            abcd (a5)-,(a0)-
loc_1769c 06 e0                            .short 0x06e0
loc_1769e 93 43                            subxw d3,d1
loc_176a0 41 ff                            .short 0x41ff
loc_176a2 5f f8 af f8                      sle ($FFFFaff8
loc_176a6 54 7f                            .short 0x547f
loc_176a8 85 47                            .short 0x8547
loc_176aa fc 7f                            .short 0xfc7f
loc_176ac ea b3                            roxrl d5,d3
loc_176ae 86 50                            or.w (a0),d3
loc_176b0 55 55                            subq.w  #2,(a5)
loc_176b2 c8 aa 48 56                      and.l (a2)(18518),d4
loc_176b6 24 2a 92 aa                      move.l  (a2)(-27990),d2
loc_176ba aa aa                            .short 0xaaaa
loc_176bc 99 54                            sub.w   d4,(a4)
loc_176be 92 a4                            sub.l (a4)-,d1
loc_176c0 99 12                            sub.b d4,(a2)
loc_176c2 aa aa                            .short 0xaaaa
loc_176c4 96 44                            sub.w   d4,d3
loc_176c6 aa aa                            .short 0xaaaa
loc_176c8 7f c7                            .short 0x7fc7
loc_176ca 37 3c 0d c6                      move.w  #3526,(a3)-
loc_176ce 1c e1                            move.b  (a1)-,(a6)+
loc_176d0 c1 73 ac ca                      and.w d0,(a3)(ffffffffffffffca,a2:l:4)
loc_176d4 2a b5 2e bb                      move.l  (a5)(ffffffffffffffbb,d2:l:8),(a5)
loc_176d8 dc 60                            add.w (a0)-,d6
loc_176da 6f 38                            ble.s   loc_17714
loc_176dc e0 1e                            ror.b #8,d6
loc_176de 7c e4                            moveq   #-28,d6
loc_176e0 1d 6d 12 55 ca 2a                move.b  (a5)(4693),(a6)(-13782)
loc_176e6 b9 13                            eor.b d4,(a3)
loc_176e8 7e da                            moveq   #-38,d7
loc_176ea 2d fc                            .short 0x2dfc
loc_176ec 36 8f                            move.w sp,(a3)
loc_176ee 5c 58                            addq.w  #6,(a0)+
loc_176f0 8c 96                            orl (a6),d6
loc_176f2 36 2a 95 4b                      move.w  (a2)(-27317),d3
loc_176f6 2f db                            .short 0x2fdb
loc_176f8 13 7f                            .short 0x137f
loc_176fa 0d a3                            bclr d6,(a3)-
loc_176fc 4e 79                            .short 0x4e79
loc_176fe 92 b4 66 55                      sub.l (a4)(0000000000000055,d6.w:8),d1
loc_17702 26 2a 95 48                      move.l  (a2)(-27320),d3
loc_17706 14 c8                            .short 0x14c8
loc_17708 14 e3                            move.b  (a3)-,(a2)+
loc_1770a b3 9c                            eor.l d1,(a4)+
loc_1770c 87 f8 c1 47                      divsw ($FFFFC147,d3
loc_17710 ac 98                            .short 0xac98
loc_17712 95 55                            sub.w   d2,(a5)
loc_17714 6c 43                            bge.s   loc_17759
loc_17716 f6 a7                            .short 0xf6a7
loc_17718 fe 31                            .short 0xfe31
loc_1771a fb 7a                            .short 0xfb7a
loc_1771c ea 18                            ror.b #5,d0
loc_1771e 1b 8c                            .short 0x1b8c
loc_17720 39 c3                            .short 0x39c3
loc_17722 82 e7                            divu.w -(sp),d1
loc_17724 59 94                            subql #4,(a4)
loc_17726 55 6a 5b 37                      subq.w  #2,(a2)(23351)
loc_1772a 3f 10                            move.w  (a0),-(sp)
loc_1772c d4 dc                            adda.w (a4)+,a2
loc_1772e f8 07                            .short 0xf807
loc_17730 9f 39 07 59 95 0a                sub.b d7,0x0759950a
loc_17736 64 0a                            bcc.s   loc_17742
loc_17738 64 09                            bcc.s   loc_17743
loc_1773a 8a 38 1c 55                      or.b loc_1c55,d5
loc_1773e 72 8d                            moveq   #-115,d1
loc_17740 4a a5                            tst.l (a5)-
loc_17742 52 05                            addq.b  #1,d5
loc_17744 32 04                            move.w  d4,d1
loc_17746 22 0a                            move.l  a2,d1
loc_17748 80 8e                            .short 0x808e
loc_1774a 2c 46                            movea.l d6,a6
loc_1774c 4c 46                            .short 0x4c46
loc_1774e 53 88                            subql #1,a0
loc_17750 2a 91                            move.l  (a1),(a5)
loc_17752 95 4a                            subxw (a2)-,(a2)-
loc_17754 a5 6a                            .short 0xa56a
loc_17756 15 8a                            .short 0x158a
loc_17758 84 d4                            divu.w (a4),d2
loc_1775a 62 32                            bhi.s   loc_1778e
loc_1775c a9 54                            .short 0xa954
loc_1775e 8c 98                            orl (a0)+,d6
loc_17760 8c aa 56 d9                      orl (a2)(22233),d6
loc_17764 fa 52                            .short 0xfa52
loc_17766 7f f1                            .short 0x7ff1
loc_17768 e3 fc                            .short 0xe3fc
loc_1776a 62 a9                            bhi.s   loc_17715
loc_1776c 54 aa 55 23                      addq.l #2,(a2)(21795)
loc_17770 26 23                            move.l  (a3)-,d3
loc_17772 29 f5                            .short 0x29f5
loc_17774 f3 9f                            .short 0xf39f
loc_17776 f8 c7                            .short 0xf8c7
loc_17778 f1 eb                            .short 0xf1eb
loc_1777a a8 c8                            .short 0xa8c8
loc_1777c de 65                            add.w (a5)-,d7
loc_1777e 6e 2d                            bgt.s   loc_177ad
loc_17780 46 5c                            notw (a4)+
loc_17782 e4 08                            lsr.b #2,d0
loc_17784 14 66                            .short 0x1466
loc_17786 59 61                            subq.w  #4,(a1)-
loc_17788 5c 31 dc ed                      addq.b  #6,(a1)(ffffffffffffffed,a5:l:4)
loc_1778c a9 5c                            .short 0xa95c
loc_1778e f8 ab                            .short 0xf8ab
loc_17790 ce 47                            and.w d7,d7
loc_17792 a9 a2                            .short 0xa9a2
loc_17794 40 b2 2a e0                      negxl (a2)(ffffffffffffffe0,d2:l:2)
loc_17798 0a 27 fa 55                      eori.b #85,-(sp)
loc_1779c 55 af 3a aa                      subql #2,(sp)(15018)
loc_177a0 82 88                            .short 0x8288
loc_177a2 c2 33 20 53                      and.b (a3)(0000000000000053,d2.w),d1
loc_177a6 20 55                            movea.l (a5),a0
loc_177a8 2a d1                            move.l  (a1),(a5)+
loc_177aa 58 aa 55 29                      addq.l #4,(a2)(21801)
loc_177ae 91 91                            sub.l d0,(a1)
loc_177b0 c6 64                            and.w (a4)-,d3
loc_177b2 0a 64 0a a5                      eori.w #2725,(a4)-
loc_177b6 52 62                            addq.w  #1,(a2)-
loc_177b8 a9 1b                            .short 0xa91b
loc_177ba 97 e9 76 10                      suba.l (a1)(30224),a3
loc_177be 7f e9                            .short 0x7fe9
loc_177c0 e2 9f                            ror.l #1,d7
loc_177c2 a5 a1                            .short 0xa5a1
loc_177c4 19 19                            move.b  (a1)+,(a4)-
loc_177c6 54 aa 55 25                      addq.l #2,(a2)(21797)
loc_177ca cb f8 a7 fe                      mulsw ($FFFFa7fe,d5
loc_177ce 31 fb 7c 9f f6 66                move.w  (pc)(loc_1776f,d7:l:4),($FFFFf666
loc_177d4 e5 fb                            .short 0xe5fb
loc_177d6 50 e5                            st (a5)-
loc_177d8 19 b9 45 55 6a 5b 39 bf 66 ed 12 11 27 ac 49 eb  move.b 0x45556a5b,@(0000000066ed1211)@(0000000027ac49eb,d3:l)
loc_177e8 12 75                            .short 0x1275
loc_177ea 9e 16                            sub.b (a6),d7
loc_177ec 29 d0                            .short 0x29d0
loc_177ee a3 c5                            .short 0xa3c5
loc_177f0 48 cf                            .short 0x48cf
loc_177f2 0a fe                            .short 0x0afe
loc_177f4 cd 55                            and.w d6,(a5)
loc_177f6 56 dc                            sne (a4)+
loc_177f8 51 28 e0 29                      subq.b  #8,(a0)(-8151)
loc_177fc 11 11                            move.b  (a1),(a0)-
loc_177fe c4 65                            and.w (a5)-,d2
loc_17800 11 15                            move.b  (a5),(a0)-
loc_17802 55 c0                            scs d0
loc_17804 c8 e8 b3 89                      mulu.w (a0)(-19575),d4
loc_17808 45 a9 16 fe                      chkw (a1)(5886),d2
loc_1780c 1a ab 94 6a                      move.b  (a3)(-27542),(a5)
loc_17810 e5 1a                            rol.b #2,d2
loc_17812 b9 7e                            .short 0xb97e
loc_17814 d5 9f                            add.l d2,(sp)+
loc_17816 f6 70                            .short 0xf670
loc_17818 7c 53                            moveq   #83,d6
loc_1781a 61 02                            bsr.s   loc_1781e
loc_1781c 55 59                            subq.w  #2,(a1)+
loc_1781e c4 9e                            and.l (a6)+,d2
loc_17820 71 27                            .short 0x7127
loc_17822 11 21                            move.b  (a1)-,(a0)-
loc_17824 12 73                            .short 0x1273
loc_17826 fd 9b                            .short 0xfd9b
loc_17828 e5 fb                            .short 0xe5fb
loc_1782a 75 3f                            .short 0x753f
loc_1782c e9 cf                            .short 0xe9cf
loc_1782e f6 ad                            .short 0xf6ad
loc_17830 15 55 a9 7f                      move.b  (a5),(a2)(-22145)
loc_17834 19 7f                            .short 0x197f
loc_17836 a6 7f                            .short 0xa67f
loc_17838 b5 5a                            eor.w d2,(a2)+
loc_1783a 54 aa 40 a6                      addq.l #2,(a2)(16550)
loc_1783e 43 06                            chkl d6,d1
loc_17840 a4 68                            .short 0xa468
loc_17842 0a 3b                            .short 0x0a3b
loc_17844 2b f9                            .short 0x2bf9
loc_17846 8c b8 ec 55                      orl ($FFFFec55,d6
loc_1784a 23 26                            move.l  (a6)-,(a1)-
loc_1784c 20 40                            movea.l d0,a0
loc_1784e a7 80                            .short 0xa780
loc_17850 e3 6e                            lsl.w d1,d6
loc_17852 2f cc                            .short 0x2fcc
loc_17854 7e 97                            moveq   #-105,d7
loc_17856 08 ec fc de 13 e3                bset    #-34,(a4)(5091)
loc_1785c 05 62                            bchg d2,(a2)-
loc_1785e c8 95                            and.l (a5),d4
loc_17860 89 b8 cc a7                      orl d4,($FFFFCca7
loc_17864 f9 82                            .short 0xf982
loc_17866 b7 58                            eor.w d3,(a0)+
loc_17868 28 ec 62 56                      move.l  (a4)(25174),(a4)+
loc_1786c 2a 94                            move.l  (a4),(a5)
loc_1786e e2 0a                            lsr.b #1,d2
loc_17870 b1 eb 3f e9                      cmpal (a3)(16361),a0
loc_17874 ad 3f                            .short 0xad3f
loc_17876 4b 42                            .short 0x4b42
loc_17878 32 32 a9 54                      move.w  (a2)@0),d1
loc_1787c aa 4d                            .short 0xaa4d
loc_1787e 16 fd                            .short 0x16fd
loc_17880 ac ff                            .short 0xacff
loc_17882 a6 a7                            .short 0xa6a7
loc_17884 77 f9                            .short 0x77f9
loc_17886 73 ff                            .short 0x73ff
loc_17888 39 eb                            .short 0x39eb
loc_1788a fe 39                            .short 0xfe39
loc_1788c e7 fc                            .short 0xe7fc
loc_1788e 79 fe                            .short 0x79fe
loc_17890 de dd                            adda.w (a5)+,sp
loc_17892 8a a1                            orl (a1)-,d5
loc_17894 c3 8e                            exg d1,a6
loc_17896 a1 fe                            .short 0xa1fe
loc_17898 7d 3f                            .short 0x7d3f
loc_1789a 8f ac ff 8f                      orl d7,(a4)(-113)
loc_1789e a1 fe                            .short 0xa1fe
loc_178a0 de 7d                            .short 0xde7d
loc_178a2 8a b6 cf 5e 7a b4                orl (a6)@(0000000000007ab4),d5
loc_178a8 d7 a2                            add.l d3,(a2)-
loc_178aa ad bb                            .short 0xadbb
loc_178ac 27 fb                            .short 0x27fb
loc_178ae 73 cf                            .short 0x73cf
loc_178b0 f8 67                            .short 0xf867
loc_178b2 af f8                            .short 0xaff8
loc_178b4 79 ff                            .short 0x79ff
loc_178b6 8c 7e                            .short 0x8c7e
loc_178b8 7b 12                            .short 0x7b12
loc_178ba 04 aa 3b 2d fb 79 ff 0f          subi.l #992869241,(a2)(-241)
loc_178c2 43 fe                            .short 0x43fe
loc_178c4 1e b3 ff 1e 9f e2                move.b  (a3)@(ffffffffffff9fe2,sp:l:8),(sp)
loc_178ca 90 eb 14 9e                      subaw (a3)(5278),a0
loc_178ce c5 ae ca ec                      and.l   d2,(a6)(-13588)
loc_178d2 53 d8                            sls (a0)+
loc_178d4 28 dd                            move.l  (a5)+,(a4)+
loc_178d6 6a 28                            bpl.s   loc_17900
loc_178d8 3a c5                            move.w  d5,(a5)+
loc_178da 27 45 a2 e5                      move.l  d5,(a3)(-23835)
loc_178de 4a d2                            tas (a2)
loc_178e0 74 1d                            moveq   #29,d2
loc_178e2 62 8a                            bhi.s   loc_1786e
loc_178e4 74 14                            moveq   #$14,d2
loc_178e6 14 3d                            .short 0x143d
loc_178e8 96 d8                            subaw (a0)+,a3
loc_178ea ad 43                            .short 0xad43
loc_178ec d8 74 14 3d                      add.w (a4)(000000000000003d,d1.w:4),d4
loc_178f0 99 50                            sub.w   d4,(a0)
loc_178f2 e8 ad                            lsrl d4,d5
loc_178f4 fa 51                            .short 0xfa51
loc_178f6 19 f3                            .short 0x19f3
loc_178f8 ad 79                            .short 0xad79
loc_178fa eb ce                            .short 0xebce
loc_178fc a7 ce                            .short 0xa7ce
loc_178fe 22 df                            move.l  (sp)+,(a1)+
loc_17900 a5 51                            .short 0xa551
loc_17902 11 fa 51 19 c5 62                move.b  (pc)(loc_1ca1d),($FFFFC562
loc_17908 b9 46                            eor.w d4,d6
loc_1790a b1 9c                            eor.l d0,(a4)+
loc_1790c 47 e9 44 54                      lea     (a1)(17492),a3
loc_17910 e2 22                            asrb d1,d2
loc_17912 22 7c f6 e7 56 89                movea.l #-152611191,a1
loc_17918 f3 9c                            .short 0xf39c
loc_1791a 44 4f                            .short 0x444f
loc_1791c 9f 28 9c 55                      sub.b d7,(a0)(-25515)
loc_17920 ba 43                            cmp.w   d3,d5
loc_17922 cf 52                            and.w d7,(a2)
loc_17924 d7 55                            add.w   d3,(a5)
loc_17926 75 29                            .short 0x7529
loc_17928 ea 0e                            lsr.b #5,d6
loc_1792a dd 2a 1c 74                      add.b d6,(a2)(7284)
loc_1792e 87 9b                            orl d3,(a3)+
loc_17930 ab ae                            .short 0xabae
loc_17932 4f 57                            .short 0x4f57
loc_17934 9b 8e                            subxl (a6)-,(a5)-
loc_17936 90 ea 6e 1c                      subaw (a2)(28188),a0
loc_1793a 39 ea                            .short 0x39ea
loc_1793c b6 a5                            cmp.l (a5)-,d3
loc_1793e 67 3d                            beq.s   loc_1797d
loc_17940 46 e1                            move.w  (a1)-,sr
loc_17942 cf 56                            and.w d7,(a6)
loc_17944 4e 6e                            move.l %usp,a6
loc_17946 7f f7                            .short 0x7ff7
loc_17948 ff a4                            .short 0xffa4
loc_1794a f9 8d                            .short 0xf98d
loc_1794c 02 0d                            .short 0x020d
loc_1794e 4c 81                            .short 0x4c81
loc_17950 1e 8c                            .short 0x1e8c
loc_17952 f4 09                            .short 0xf409
loc_17954 6a 04                            bpl.s   loc_1795a
loc_17956 9d 02                            subxb d2,d6
loc_17958 38 f1 8f 8c                      move.w @0)@0,a0:l:8),(a4)+
loc_1795c 61 fb                            bsr.s   loc_17959
loc_1795e 41 fb 4b db 73 a4 f5 50          lea %z(pc)@(0000000073a4f550),a0
loc_17966 23 6c 08 c8 68 f3                move.l  (a4)(2248),(a1)(26867)
loc_1796c bd e6                            cmpal (a6)-,a6
loc_1796e 81 f7 c4 63                      divsw (sp)(0000000000000063,a4.w:4),d0
loc_17972 cf 0f                            abcd -(sp),-(sp)
loc_17974 fa 7f                            .short 0xfa7f
loc_17976 44 ff                            .short 0x44ff
loc_17978 8e d4                            divu.w (a4),d7
loc_1797a 3d 88 db 2c 8d 79                move.w  a0,(a6)(ffffffffffff8d79)@0,a5:l:2)
loc_17980 be e7                            cmpa.w -(sp),sp
loc_17982 6a 6e                            bpl.s   loc_179f2
loc_17984 a2 2c                            .short 0xa22c
loc_17986 f7 55                            .short 0xf755
loc_17988 c2 55                            and.w (a5),d1
loc_1798a d2 db                            adda.w (a3)+,a1
loc_1798c 17 73 5f d2 28 22 8e d4          move.b @0)@(0000000000002822),(a3)(-28972)
loc_17994 aa 04                            .short 0xaa04
loc_17996 34 a0                            move.w  (a0)-,(a2)
loc_17998 7a 32                            moveq   #50,d5
loc_1799a 0a 1a 35 fb                      eori.b #-5,(a2)+
loc_1799e 11 9d 92 6e                      move.b  (a5)+,(a0)(000000000000006e,a1.w:2)
loc_179a2 bb 1e                            eor.b d5,(a6)+
loc_179a4 14 1b                            move.b  (a3)+,d2
loc_179a6 15 b6 21 f5 a8 bc f9 9d b7 59    move.b @(ffffffffa8bcf99d)@0),(a2)@0)
loc_179b0 32 40                            movea.w d0,a1
loc_179b2 8e 1f                            or.b (sp)+,d7
loc_179b4 66 54                            bne.s   loc_17a0a
loc_179b6 34 fd                            .short 0x34fd
loc_179b8 b2 cf                            cmpa.w sp,a1
loc_179ba 74 d3                            moveq   #-45,d2
loc_179bc a6 69                            .short 0xa669
loc_179be d6 7f                            .short 0xd67f
loc_179c0 f4 f1                            .short 0xf4f1
loc_179c2 88 f1 df 5d                      divu.w (a1)@0),d4
loc_179c6 86 87                            orl d7,d3
loc_179c8 79 de                            .short 0x79de
loc_179ca cf 7b                            .short 0xcf7b
loc_179cc d9 d5                            adda.l (a5),a4
loc_179ce 28 86                            move.l  d6,(a4)
loc_179d0 9b 3f                            .short 0x9b3f
loc_179d2 48 3f                            .short 0x483f
loc_179d4 69 1f                            bvss loc_179f5
loc_179d6 18 fe                            .short 0x18fe
loc_179d8 d1 92                            add.l d0,(a2)
loc_179da 68 77                            bvcs loc_17a53
loc_179dc b2 33 a2 a9                      cmp.b (a3)(ffffffffffffffa9,a2.w:2),d1
loc_179e0 a1 a5                            .short 0xa1a5
loc_179e2 10 ff                            .short 0x10ff
loc_179e4 e9 fc                            .short 0xe9fc
loc_179e6 3e c6                            move.w  d6,(sp)+
loc_179e8 ed c3                            .short 0xedc3
loc_179ea 8c f6 e1 f9 b3 da 5f 9b          divu.w @(ffffffffb3da5f9b)@0),d6
loc_179f2 53 2d a5 d0                      subq.b  #1,(a5)(-23088)
loc_179f6 d8 02                            add.b d2,d4
loc_179f8 fd c7                            .short 0xfdc7
loc_179fa 47 18                            chkl (a0)+,d3
loc_179fc 2f e4                            .short 0x2fe4
loc_179fe 19 71 f3 6d e3 c3 b6 7c          move.b  (a1)(ffffffffffffe3c3)@0),(a4)(-18820)
loc_17a06 7d 18                            .short 0x7d18
loc_17a08 6d 3c                            blt.s   loc_17a46
loc_17a0a 07 e6                            bset d3,(a6)-
loc_17a0c cb 68 25 9f                      and.w d5,(a0)(9631)
loc_17a10 41 6d                            .short 0x416d
loc_17a12 fe c1                            .short 0xfec1
loc_17a14 02 fc                            .short 0x02fc
loc_17a16 c7 ea c8 17                      mulsw (a2)(-14313),d3
loc_17a1a 40 e2                            move.w sr,(a2)-
loc_17a1c e8 55                            roxrw #4,d5
loc_17a1e c8 aa 55 21                      and.l (a2)(21793),d4
loc_17a22 c7 32 50 46                      and.b d3,(a2)(0000000000000046,d5.w)
loc_17a26 5d 05                            subq.b  #6,d5
loc_17a28 52 32 a9 54                      addq.b  #1,(a2)@0)
loc_17a2c aa 4c                            .short 0xaa4c
loc_17a2e 4d d0                            lea     (a0),a6
loc_17a30 64 c4                            bcc.s   loc_179f6
loc_17a32 64 08                            bcc.s   loc_17a3c
loc_17a34 c8 10                            and.b (a0),d4
loc_17a36 26 20                            move.l  (a0)-,d3
loc_17a38 4d d1                            lea     (a1),a6
loc_17a3a 32 53                            movea.w (a3),a1
loc_17a3c 2a 95                            move.l  (a5),(a5)
loc_17a3e 48 14                            nbcd (a4)
loc_17a40 c8 11                            and.b (a1),d4
loc_17a42 91 f1 f4 7e                      suba.l (a1)(000000000000007e,sp.w:4),a0
loc_17a46 60 66                            bra.s   loc_17aae
loc_17a48 3a 07                            move.w  d7,d5
loc_17a4a ec f3                            .short 0xecf3
loc_17a4c fc c7                            .short 0xfcc7
loc_17a4e ea c1                            .short 0xeac1
loc_17a50 19 54 95 56                      move.b  (a4),(a4)(-27306)
loc_17a54 a5 fa                            .short 0xa5fa
loc_17a56 8e 83                            orl d3,d7
loc_17a58 fe 18                            .short 0xfe18
loc_17a5a e8 1f                            ror.b #4,d7
loc_17a5c fa 55                            .short 0xfa55
loc_17a5e 85 b7 d7 8a c9 5b                orl d2,@0,a5.w:8)@(ffffffffffffc95b)
loc_17a64 eb 41                            asl.w #5,d1
loc_17a66 79 ef                            .short 0x79ef
loc_17a68 8a 1e                            or.b (a6)+,d5
loc_17a6a f6 82                            .short 0xf682
loc_17a6c 9f e8 8e 06                      suba.l (a0)(-29178),sp
loc_17a70 87 bd                            .short 0x87bd
loc_17a72 91 bf                            .short 0x91bf
loc_17a74 6d cc                            blt.s   loc_17a42
loc_17a76 ed cc                            .short 0xedcc
loc_17a78 1e b7 ec 9f                      move.b  (sp)(ffffffffffffff9f,a6:l:4),(sp)
loc_17a7c e8 9b                            ror.l #4,d3
loc_17a7e 7d 77                            .short 0x7d77
loc_17a80 b4 27                            cmp.b -(sp),d2
loc_17a82 03 87                            bclr d1,d7
loc_17a84 f1 b7                            .short 0xf1b7
loc_17a86 8f e0                            divsw (a0)-,d7
loc_17a88 ce 26                            and.b (a6)-,d7
loc_17a8a ec f0                            .short 0xecf0
loc_17a8c d4 aa bf b2                      add.l (a2)(-16462),d2
loc_17a90 6f e1                            ble.s   loc_17a73
loc_17a92 34 15                            move.w  (a5),d2
loc_17a94 56 02                            addq.b  #3,d2
loc_17a96 13 de 3f a4 d0 1b                move.b  (a6)+,0x3fa4d01b
loc_17a9c eb 06                            aslb #5,d6
loc_17a9e 81 c2                            divsw d2,d0
loc_17aa0 b0 9f                            cmp.l (sp)+,d0
loc_17aa2 e8 8f                            lsrl #4,d7
loc_17aa4 f6 43                            .short 0xf643
loc_17aa6 79 c2                            .short 0x79c2
loc_17aa8 3a af 68 ab                      move.w  (sp)(26795),(a5)
loc_17aac 3a ab 45 b1                      move.w  (a3)(17841),(a5)
loc_17ab0 67 14                            beq.s   loc_17ac6
loc_17ab2 7c 59                            moveq   #89,d6
loc_17ab4 28 35 35 e3 57 f0 5b f6 e4 aa    move.l @(00000000000057f0)@(000000005bf6e4aa),d4
loc_17abe df b4 9f 8e f2 70                add.l d7,@0)@(fffffffffffff270,a1:l:8)
loc_17ac4 8e 9a                            orl (a2)+,d7
loc_17ac6 a9 ab                            .short 0xa9ab
loc_17ac8 ac df                            .short 0xacdf
loc_17aca 76 50                            moveq   #$50,d3
loc_17acc 9d f0 3a 31                      suba.l (a0)(0000000000000031,d3:l:2),a6
loc_17ad0 78 aa                            moveq   #-86,d4
loc_17ad2 af 5b                            .short 0xaf5b
loc_17ad4 a0 c4                            .short 0xa0c4
loc_17ad6 6e 3d                            bgt.s   loc_17b15
loc_17ad8 fb 17                            .short 0xfb17
loc_17ada 62 ec                            bhi.s   loc_17ac8
loc_17adc 55 53                            subq.w  #2,(a3)
loc_17ade 79 e3                            .short 0x79e3
loc_17ae0 07 1f                            btst d3,(sp)+
loc_17ae2 b6 df                            cmpa.w (sp)+,a3
loc_17ae4 a9 55                            .short 0xa955
loc_17ae6 54 ff                            .short 0x54ff
loc_17ae8 8e 35 2d 75 46 97 d1 c4          or.b (a5)(000000004697d1c4)@0),d7
loc_17af0 2b 01                            move.l  d1,(a5)-
loc_17af2 86 3a 93 7a                      or.b (pc)(loc_10e6e),d3
loc_17af6 60 36                            bra.s   loc_17b2e
loc_17af8 2b 20                            move.l  (a0)-,(a5)-
loc_17afa 4a a2                            tst.l (a2)-
loc_17afc b6 ad ca 86                      cmp.l (a5)(-13690),d3
loc_17b00 94 17                            sub.b (sp),d2
loc_17b02 8d f4 3d e4 c8 38                divsw @(ffffffffffffc838)@0),d6
loc_17b08 b7 9a                            eor.l d3,(a2)+
loc_17b0a 1a 5a                            .short 0x1a5a
loc_17b0c f5 b6                            .short 0xf5b6
loc_17b0e e3 80                            asl.l #1,d0
loc_17b10 4e 24                            .short 0x4e24
loc_17b12 05 02                            btst d2,d2
loc_17b14 10 20                            move.b  (a0)-,d0
loc_17b16 82 18                            or.b (a0)+,d1
loc_17b18 21 de 11 92                      move.l  (a6)+,loc_1192
loc_17b1c 7b 95                            .short 0x7b95
loc_17b1e 5a 1b                            addq.b  #5,(a3)+
loc_17b20 37 a6 a2 f1                      move.w  (a6)-,(a3)(fffffffffffffff1,a2.w:2)
loc_17b24 de 28 78 5a                      add.b (a0)(30810),d7
loc_17b28 f1 79 b9 de 37 32                prestore 0xb9de3732
loc_17b2e 04 b2 04 09 34 6f f3 ae 54 4a 36 c6  subi.l #67712111,@(000000000000544a)@(00000000000036c6,sp.w:2)
loc_17b3a a3 d0                            .short 0xa3d0
loc_17b3c 20 40                            movea.l d0,a0
loc_17b3e 93 40                            subxw d0,d1
loc_17b40 87 7a                            .short 0x877a
loc_17b42 e5 cc                            .short 0xe5cc
loc_17b44 77 fe                            .short 0x77fe
loc_17b46 e4 27                            asrb d2,d7
loc_17b48 6c d3                            bge.s   loc_17b1d
loc_17b4a 6a aa                            bpl.s   loc_17af6
loc_17b4c ad 53                            .short 0xad53
loc_17b4e 24 cb                            move.l  a3,(a2)+
loc_17b50 b5 72 da ab                      eor.w d2,(a2)(ffffffffffffffab,a5:l:2)
loc_17b54 6c eb                            bge.s   loc_17b41
loc_17b56 99 7f                            .short 0x997f
loc_17b58 62 09                            bhi.s   loc_17b63
loc_17b5a f9 85                            .short 0xf985
loc_17b5c fc c2                            .short 0xfcc2
loc_17b5e f1 aa                            .short 0xf1aa
loc_17b60 f1 9e                            .short 0xf19e
loc_17b62 79 12                            .short 0x7912
loc_17b64 db f3 0a aa                      adda.l (a3)(ffffffffffffffaa,d0:l:2),a5
loc_17b68 aa a9                            .short 0xaaa9
loc_17b6a b6 bc 7b 67 9e da                cmp.l #2070388442,d3
loc_17b70 e6 59                            ror.w #3,d1
loc_17b72 66 aa                            bne.s   loc_17b1e
loc_17b74 aa 36                            .short 0xaa36
loc_17b76 9e d3                            subaw (a3),sp
loc_17b78 d3 b4 f6 8e                      add.l d1,(a4)(ffffffffffffff8e,sp.w:8)
loc_17b7c 3a 16                            move.w  (a6),d5
loc_17b7e 59 aa a8 d0                      subql #4,(a2)(-22320)
loc_17b82 f8 db                            .short 0xf8db
loc_17b84 4a e8 34 b6                      tas (a0)(13494)
loc_17b88 cf d4                            mulsw (a4),d7
loc_17b8a 2a ac ff d2                      move.l  (a4)(-46),(a5)
loc_17b8e 7d a7                            .short 0x7da7
loc_17b90 b5 54                            eor.w d2,(a4)
loc_17b92 ff 51                            .short 0xff51
loc_17b94 7f 1a                            .short 0x7f1a
loc_17b96 1e d9                            move.b  (a1)+,(sp)+
loc_17b98 ed 6f                            lsl.w d6,d7
loc_17b9a dc b7 f6 53                      add.l (sp)(0000000000000053,sp.w:8),d6
loc_17b9e 6a aa                            bpl.s   loc_17b4a
loc_17ba0 d7 b4 ff 7d db 6d 36 b6          add.l d3,(a4)(ffffffffdb6d36b6)@0)
loc_17ba8 ad 2d                            .short 0xad2d
loc_17baa b5 57                            eor.w d2,(sp)
loc_17bac b5 72 ed d1                      eor.w d2,@0)@0)
loc_17bb0 b6 fe                            .short 0xb6fe
loc_17bb2 61 34                            bsr.s   loc_17be8
loc_17bb4 6d ab                            blt.s   loc_17b61
loc_17bb6 96 dc                            subaw (a4)+,a3
loc_17bb8 b6 aa a6 5b                      cmp.l (a2)(-22949),d3
loc_17bbc 4f f7 17 aa aa aa a9 a7          lea @(ffffffffffffaaaa,d1.w:8)@(ffffffffffffa9a7),sp
loc_17bc4 ea 2f                            lsr.b d5,d7
loc_17bc6 fc c2                            .short 0xfcc2
loc_17bc8 6d 55                            blt.s   loc_17c1f
loc_17bca c9 36 aa ad                      and.b d4,(a6)(ffffffffffffffad,a2:l:2)
loc_17bce bf 31 b6 7b                      eor.b d7,(a1)(000000000000007b,a3.w:8)
loc_17bd2 72 da                            moveq   #-38,d1
loc_17bd4 ab fc                            .short 0xabfc
loc_17bd6 99 ee 55 9e                      suba.l (a6)(21918),a4
loc_17bda df d4                            adda.l (a4),sp
loc_17bdc 6d 1f                            blt.s   loc_17bfd
loc_17bde 98 db                            subaw (a3)+,a4
loc_17be0 64 1d                            bcc.s   loc_17bff
loc_17be2 b3 da                            cmpal (a2)+,a1
loc_17be4 a8 3b                            .short 0xa83b
loc_17be6 67 b4                            beq.s   loc_17b9c
loc_17be8 d3 6e 49 b7                      add.w   d1,(a6)(18871)
loc_17bec 24 e3                            move.l  (a3)-,(a2)+
loc_17bee da 3f                            .short 0xda3f
loc_17bf0 30 7d                            .short 0x307d
loc_17bf2 a9 c7                            .short 0xa9c7
loc_17bf4 3e da                            move.w  (a2)+,(sp)+
loc_17bf6 f1 8e                            .short 0xf18e
loc_17bf8 39 f1                            .short 0x39f1
loc_17bfa 8e 3d                            .short 0x8e3d
loc_17bfc a3 f5                            .short 0xa3f5
loc_17bfe 0a 7b                            .short 0x0a7b
loc_17c00 52 7d                            .short 0x527d
loc_17c02 a8 dd                            .short 0xa8dd
loc_17c04 b7 b7 1d ea aa aa ab 34          eor.l d3,@(ffffffffffffaaaa)@(ffffffffffffab34)
loc_17c0c c9 15                            and.b d4,(a5)
loc_17c0e 72 45                            moveq   #69,d1
loc_17c10 aa 38                            .short 0xaa38
loc_17c12 fe 09                            .short 0xfe09
loc_17c14 a7 f1                            .short 0xa7f1
loc_17c16 cd 3f                            .short 0xcd3f
loc_17c18 8c 94                            orl (a4),d6
loc_17c1a 1b a6 9d 28 ce a1                move.b  (a6)-,(a5)(ffffffffffffcea1,a1:l:4)
loc_17c20 03 a1                            bclr d1,(a1)-
loc_17c22 de 11                            add.b (a1),d7
loc_17c24 55 d0                            scs (a0)
loc_17c26 ff 6e                            .short 0xff6e
loc_17c28 8b 3a                            .short 0x8b3a
loc_17c2a 35 27                            move.w -(sp),(a2)-
loc_17c2c 41 41                            .short 0x4141
loc_17c2e 49 d1                            lea     (a1),a4
loc_17c30 02 52 7b 8e                      andi.w  #31630,(a2)
loc_17c34 8c 93                            orl (a3),d6
loc_17c36 a2 ff                            .short 0xa2ff
loc_17c38 19 45 2b 41                      move.b  d5,(a4)(11073)
loc_17c3c 99 d1                            suba.l (a1),a4
loc_17c3e 76 5a                            moveq   #90,d3
loc_17c40 8d 2c ed 2c                      or.b d6,(a4)(-4820)
loc_17c44 e7 41                            asl.w #3,d1
loc_17c46 9d 5d                            sub.w   d6,(a5)+
loc_17c48 45 2c 94 14                      chkl (a4)(-27628),d2
loc_17c4c 3a 66                            movea.w (a6)-,a5
loc_17c4e 10 26                            move.b  (a6)-,d0
loc_17c50 c1 98                            and.l   d0,(a0)+
loc_17c52 dc 72 64 6c                      add.w (a2)(000000000000006c,d6.w:4),d6
loc_17c56 eb 2b                            lsl.b d5,d3
loc_17c58 5f af ae db                      subql #7,(sp)(-20773)
loc_17c5c 9c 20                            sub.b (a0)-,d6
loc_17c5e 49 b8 47 41                      chkw loc_4741,d4
loc_17c62 78 e9                            moveq   #-23,d4
loc_17c64 46 bd                            .short 0x46bd
loc_17c66 43 de                            .short 0x43de
loc_17c68 ec 83                            asr.l #6,d3
loc_17c6a 50 e9 46 bc                      st (a1)(18108)
loc_17c6e e9 a8                            lsl.l d4,d0
loc_17c70 dd 92                            add.l d6,(a2)
loc_17c72 7b 2f                            .short 0x7b2f
loc_17c74 76 41                            moveq   #65,d3
loc_17c76 a8 23                            .short 0xa823
loc_17c78 73 29                            .short 0x7329
loc_17c7a a2 b7                            .short 0xa2b7
loc_17c7c fa 86                            .short 0xfa86
loc_17c7e 63 a3                            bls.s   loc_17c23
loc_17c80 31 d0 33 6c                      move.w  (a0),loc_336c
loc_17c84 c7 e6                            mulsw (a6)-,d3
loc_17c86 c6 6d 98 fd                      and.w (a5)(-26371),d3
loc_17c8a 59 f4 0c c7                      svs (a4)(ffffffffffffffc7,d0:l:4)
loc_17c8e e6 cf                            .short 0xe6cf
loc_17c90 a0 fb                            .short 0xa0fb
loc_17c92 0f 35 3e a1                      btst d7,(a5)(ffffffffffffffa1,d3:l:8)
loc_17c96 9a 0e                            .short 0x9a0e
loc_17c98 ae 8a                            .short 0xae8a
loc_17c9a fe 6e                            .short 0xfe6e
loc_17c9c df 9b                            add.l d7,(a3)+
loc_17c9e 1f ba 1d 03 33 e8 1d 8d          move.b  (pc)(loc_199a3),@(0000000000001d8d)
loc_17ca6 f9 bb                            .short 0xf9bb
loc_17ca8 66 3f                            bne.s   loc_17ce9
loc_17caa 37 6e a4 fd d4 f3                move.w  (a6)(-23299),(a3)(-11021)
loc_17cb0 1d 19                            move.b  (a1)+,(a6)-
loc_17cb2 9f 54                            sub.w   d7,(a4)
loc_17cb4 fa ba                            .short 0xfaba
loc_17cb6 27 98 fc dd                      move.l  (a0)+,(a3)(ffffffffffffffdd,sp:l:4)
loc_17cba bf 36 33 6f cd f5 04 34 cd 91    eor.b d7,(a6)(ffffffffffffcdf5)@(000000000434cd91)
loc_17cc4 73 45                            .short 0x7345
loc_17cc6 56 d5                            sne (a5)
loc_17cc8 67 e7                            beq.s   loc_17cb1
loc_17cca 9b c7                            suba.l d7,a5
loc_17ccc 06 78 94 de 24 b3                addi.w  #-27426,loc_24b3
loc_17cd2 71 1e                            .short 0x711e
loc_17cd4 b4 71 fb 50                      cmp.w (a1),d2
loc_17cd8 fc ff                            .short 0xfcff
loc_17cda b3 e7                            cmpal -(sp),a1
loc_17cdc c2 78 58 ac                      and.w loc_58ac,d1
loc_17ce0 40 ac 56 a5                      negxl (a4)(22181)
loc_17ce4 51 ff                            .short 0x51ff
loc_17ce6 a2 ba                            .short 0xa2ba
loc_17ce8 ab ce                            .short 0xabce
loc_17cea f6 c2                            .short 0xf6c2
loc_17cec 2f 52 8b d4                      move.l  (a2),(sp)(-29740)
loc_17cf0 a2 ea                            .short 0xa2ea
loc_17cf2 69 42                            bvss loc_17d36
loc_17cf4 05 4b d6 00                      movepl (a3)(-10752),d2
loc_17cf8 95 8b                            subxl (a3)-,(a2)-
loc_17cfa 6d 9f                            blt.s   loc_17c9b
loc_17cfc 1b 39 e8 cf 57 b1                move.b 0xe8cf57b1,(a5)-
loc_17d02 53 fa                            .short 0x53fa
loc_17d04 ea b9                            ror.l d5,d1
loc_17d06 16 db                            move.b  (a3)+,(a3)+
loc_17d08 11 ed 62 18 9e d0                move.b  (a5)(25112),($FFFF9ed0
loc_17d0e 43 11                            chkl (a1),d1
loc_17d10 a1 94                            .short 0xa194
loc_17d12 df b7 00 94                      add.l d7,(sp)(ffffffffffffff94,d0.w)
loc_17d16 05 52                            bchg d2,(a2)
loc_17d18 c7 69 94 5c                      and.w d3,(a1)(-27556)
loc_17d1c f4 db                            .short 0xf4db
loc_17d1e 3c 5b                            movea.w (a3)+,a6
loc_17d20 6d 74                            blt.s   loc_17d96
loc_17d22 1b 6b a2 b6 28 da                move.b  (a3)(-23882),(a5)(10458)
loc_17d28 62 8a                            bhi.s   loc_17cb4
loc_17d2a a7 fc                            .short 0xa7fc
loc_17d2c ec 72                            roxrw d6,d2
loc_17d2e cd 4f                            exg a6,sp
loc_17d30 fb e7                            .short 0xfbe7
loc_17d32 fd 5c                            .short 0xfd5c
loc_17d34 6e 6f                            bgt.s   loc_17da5
loc_17d36 d2 0c                            .short 0xd20c
loc_17d38 cf 16                            and.b d7,(a6)
loc_17d3a c5 4f                            exg a2,sp
loc_17d3c 19 f6                            .short 0x19f6
loc_17d3e 7f 39                            .short 0x7f39
loc_17d40 7f ff                            .short 0x7fff
loc_17d42 ff 5f                            .short 0xff5f
loc_17d44 e2 66                            asrw d1,d6
loc_17d46 22 aa bf ce                      move.l  (a2)(-16434),(a1)
loc_17d4a 56 fe                            .short 0x56fe
loc_17d4c fc 47                            .short 0xfc47
loc_17d4e f9 47                            .short 0xf947
loc_17d50 f8 9d                            .short 0xf89d
loc_17d52 6b f9                            bmi.s   loc_17d4d
loc_17d54 b9 df                            cmpal (sp)+,a4
loc_17d56 d5 3f                            .short 0xd53f
loc_17d58 dd 35 3f 74 cf 64 e8 fd          add.b d6,(a5)(ffffffffcf64e8fd)@0)
loc_17d60 d1 a7                            add.l d0,-(sp)
loc_17d62 f2 85 e7 da                      fbole loc_1653e
loc_17d66 7f ba                            .short 0x7fba
loc_17d68 ed 3f                            rol.b d6,d7
loc_17d6a dd 37 56 59                      add.b d6,(sp)(0000000000000059,d5.w:8)
loc_17d6e 9b 91                            sub.l d5,(a1)
loc_17d70 e6 ce                            .short 0xe6ce
loc_17d72 4b d8                            .short 0x4bd8
loc_17d74 1f 77 ea c3 ee 6f                move.b  (sp)(ffffffffffffffc3,a6:l:2),(sp)(-4497)
loc_17d7a dd 24                            add.b d6,(a4)-
loc_17d7c fa 87                            .short 0xfa87
loc_17d7e 43 67                            .short 0x4367
loc_17d80 3e 8b                            move.w  a3,(sp)
loc_17d82 76 22                            moveq   #34,d3
loc_17d84 a7 fe                            .short 0xa7fe
loc_17d86 ba 3b 1b 34 cb f7 53 ec          cmp.b (pc)(0xffffffffcbf8d174)@0,d1:l:2),d5
loc_17d8e 3e a1                            move.w  (a1)-,(sp)
loc_17d90 d8 79 82 fe d0 2b                add.w 0x82fed02b,d4
loc_17d96 d5 ff                            .short 0xd5ff
loc_17d98 95 78 ec 9b                      sub.w   d2,($FFFFec9b
loc_17d9c a9 e7                            .short 0xa9e7
loc_17d9e 97 63                            sub.w   d3,(a3)-
loc_17da0 db a9 ed d4                      add.l d5,(a1)(-4652)
loc_17da4 1f 27                            move.b -(sp),-(sp)
loc_17da6 b6 79 67 37 6f dd                cmp.w 0x67376fdd,d3
loc_17dac 6b ff                            bmi.s   loc_17dad
loc_17dae d7 fe                            .short 0xd7fe
loc_17db0 ba 91                            cmp.l (a1),d5
loc_17db2 bb 3a                            .short 0xbb3a
loc_17db4 1b 33 49 f5 23 7f ad 16          move.b @(00000000237fad16)@0),(a5)-
loc_17dbc 7d 07                            .short 0x7d07
loc_17dbe 9d bb                            .short 0x9dbb
loc_17dc0 2d 7e                            .short 0x2d7e
loc_17dc2 75 4c                            .short 0x754c
loc_17dc4 d6 bd                            .short 0xd6bd
loc_17dc6 5c dd                            sge (a5)+
loc_17dc8 08 db 7b 1f                      bset    #$1F,(a3)+
loc_17dcc 68 cc                            bvcs loc_17d9a
loc_17dce 86 61                            or.w (a1)-,d3
loc_17dd0 cb f7 56 fd                      mulsw (sp)(fffffffffffffffd,d5.w:8),d5
loc_17dd4 d3 66                            add.w   d1,(a6)-
loc_17dd6 59 ed ea 19                      svs (a5)(-5607)
loc_17dda 8d a0                            orl d6,(a0)-
loc_17ddc 86 63                            or.w (a3)-,d3
loc_17dde 0f ed 61 fb                      bset d7,(a5)(25083)
loc_17de2 af dd                            .short 0xafdd
loc_17de4 e6 bd                            ror.l d3,d5
loc_17de6 9d 0d                            subxb (a5)-,(a6)-
loc_17de8 d8 77 8e c3                      add.w (sp)(ffffffffffffffc3,a0:l:8),d4
loc_17dec ea e8                            .short 0xeae8
loc_17dee d7 b7 f9 5d                      add.l d3,(sp)@0)
loc_17df2 0e 46                            .short 0x0e46
loc_17df4 f7 8e                            .short 0xf78e
loc_17df6 c4 a3                            and.l (a3)-,d2
loc_17df8 7e ad                            moveq   #-83,d7
loc_17dfa 4f f3 b5 cc                      lea @0)@0),sp
loc_17dfe 6b af                            bmi.s   loc_17daf
loc_17e00 54 f5 db f3 b9 b7 e7 46 73 ec 3f fb  scc @(ffffffffb9b7e746)@(0000000073ec3ffb)
loc_17e0c cf f8 e7 ae                      mulsw ($FFFFe7ae,d7
loc_17e10 6e 79                            bgt.s   loc_17e8b
loc_17e12 cf a5                            and.l   d7,(a5)-
loc_17e14 54 6a b3 9f                      addq.w  #2,(a2)(-19553)
loc_17e18 f1 ed                            .short 0xf1ed
loc_17e1a ba 68 72 fd                      cmp.w (a0)(29437),d5
loc_17e1e 6b ec                            bmi.s   loc_17e0c
loc_17e20 90 ec 6c d7                      subaw (a4)(27863),a0
loc_17e24 33 ff                            .short 0x33ff
loc_17e26 ba d7                            cmpa.w (sp),a5
loc_17e28 ff a7                            .short 0xffa7
loc_17e2a ff aa                            .short 0xffaa
loc_17e2c f5 07                            .short 0xf507
loc_17e2e 67 fc                            beq.s   loc_17e2c
loc_17e30 eb b3                            roxl.l d5,d3
loc_17e32 d9 c3                            adda.l  d3,a4
loc_17e34 d5 c3                            adda.l  d3,a2
loc_17e36 d5 c6                            adda.l  d6,a2
loc_17e38 bd 53                            eor.w d6,(a3)
loc_17e3a 7c cd                            moveq   #-51,d6
loc_17e3c ed d3                            .short 0xedd3
loc_17e3e 37 55 cb f6                      move.w  (a5),(a3)(-13322)
loc_17e42 f5 d5                            .short 0xf5d5
loc_17e44 37 1f                            move.w  (sp)+,(a3)-
loc_17e46 d7 51                            add.w   d3,(a1)
loc_17e48 fb 73                            .short 0xfb73
loc_17e4a 7c 9d                            moveq   #-99,d6
loc_17e4c 56 dd                            sne (a5)+
loc_17e4e 2a aa ba 97                      move.l  (a2)(-17769),(a5)
loc_17e52 f5 bb                            .short 0xf5bb
loc_17e54 87 56                            or.w d3,(a6)
loc_17e56 bc e4                            cmpa.w (a4)-,a6
loc_17e58 28 fa c3 8c                      move.l  (pc)(loc_141e6),(a4)+
loc_17e5c e8 ad                            lsrl d4,d5
loc_17e5e fd 75                            .short 0xfd75
loc_17e60 5c b5 db f3 a1 cf f3 a7 98 71 fb d7  addq.l #6,@(ffffffffa1cff3a7)@(ffffffff9871fbd7)
loc_17e6c 3e 96                            move.w  (a6),(sp)
loc_17e6e fe 39                            .short 0xfe39
loc_17e70 bd b5 28 fd                      eor.l d6,(a5)(fffffffffffffffd,d2:l)
loc_17e74 eb f5                            .short 0xebf5
loc_17e76 1f 63 75 35                      move.b  (a3)-,(sp)(30005)
loc_17e7a 25 d5                            .short 0x25d5
loc_17e7c fb 7b                            .short 0xfb7b
loc_17e7e f5 2f                            .short 0xf52f
loc_17e80 4e 4f                            trap #15
loc_17e82 5c f5 bd b3 19 d7 31 f9 d7 41 d4 79  sge @(0000000019d731f9,a3:l:4)@(ffffffffd741d479)
loc_17e8e d0 3f                            .short 0xd03f
loc_17e90 ef 5e                            rol.w #7,d6
loc_17e92 f5 ff                            .short 0xf5ff
loc_17e94 b2 9f                            cmp.l (sp)+,d1
loc_17e96 f5 1b                            .short 0xf51b
loc_17e98 42 fc                            .short 0x42fc
loc_17e9a f1 37 eb 46 b6 d6                psave (sp)@(ffffffffffffb6d6)
loc_17ea0 34 04                            move.w  d4,d2
loc_17ea2 da e0                            adda.w (a0)-,a5
loc_17ea4 0a d0                            .short 0x0ad0
loc_17ea6 32 3c 5f 3e                      move.w  #24382,d1
loc_17eaa dc d7                            adda.w (sp),a6
loc_17eac fe 9f                            .short 0xfe9f
loc_17eae ae 97                            .short 0xae97
loc_17eb0 e7 b8                            roll d3,d0
loc_17eb2 10 20                            move.b  (a0)-,d0
loc_17eb4 50 b4 8a 70                      addq.l #8,(a4)(0000000000000070,a0:l:2)
loc_17eb8 4d 70                            .short 0x4d70
loc_17eba 64 08                            bcc.s   loc_17ec4
loc_17ebc d0 1f                            add.b (sp)+,d0
loc_17ebe 98 ed fc c6                      subaw (a5)(-826),a4
loc_17ec2 7c 6b                            moveq   #107,d6
loc_17ec4 ff 4d                            .short 0xff4d
loc_17ec6 38 69 2d 25                      movea.w (a1)(11557),a4
loc_17eca a4 0f                            .short 0xa40f
loc_17ecc f4 4d                            .short 0xf44d
loc_17ece 70 96                            moveq   #-106,d0
loc_17ed0 83 f4 57 09                      divsw (a4,d5.w:8)@0),d1
loc_17ed4 69 bc                            bvss loc_17e92
loc_17ed6 40 7e                            .short 0x407e
loc_17ed8 c9 07                            abcd d7,d4
loc_17eda e6 3a                            ror.b d3,d2
loc_17edc bf 31 b6 2b                      eor.b d7,(a1)(000000000000002b,a3.w:8)
loc_17ee0 fd 43                            .short 0xfd43
loc_17ee2 fd 66                            .short 0xfd66
loc_17ee4 b9 59                            eor.w d4,(a1)+
loc_17ee6 15 27                            move.b -(sp),(a2)-
loc_17ee8 b9 61                            eor.w d4,(a1)-
loc_17eea 3e d9                            move.w  (a1)+,(sp)+
loc_17eec 04 d7                            .short 0x04d7
loc_17eee c7 16                            and.b d3,(a6)
loc_17ef0 82 15                            or.b (a5),d1
loc_17ef2 ed 01                            aslb #6,d1
loc_17ef4 0b da                            bset d5,(a2)+
loc_17ef6 02 eb                            .short 0x02eb
loc_17ef8 5d 03                            subq.b  #6,d3
loc_17efa 83 5c                            or.w d1,(a4)+
loc_17efc 2e 10                            move.l  (a0),d7
loc_17efe 6b b4                            bmi.s   loc_17eb4
loc_17f00 95 d0                            suba.l (a0),a2
loc_17f02 6d 7a                            blt.s   loc_17f7e
loc_17f04 17 e7                            .short 0x17e7
loc_17f06 78 f6                            moveq   #-10,d4
loc_17f08 eb df                            .short 0xebdf
loc_17f0a ae 1a                            .short 0xae1a
loc_17f0c d0 24                            add.b (a4)-,d0
loc_17f0e 8f 78 41 a3                      or.w d7,loc_41a3
loc_17f12 41 3f                            .short 0x413f
loc_17f14 84 70 38 08                      or.w (a0)8,d3:l),d2
loc_17f18 1e bb 40 b5                      move.b  (pc)(loc_17ecf,d4.w),(sp)
loc_17f1c 8d 62                            or.w d6,(a2)-
loc_17f1e 05 04                            btst d2,d4
loc_17f20 3f ce                            .short 0x3fce
loc_17f22 c0 8f                            .short 0xc08f
loc_17f24 5c 06                            addq.b  #6,d6
loc_17f26 b8 60                            cmp.w (a0)-,d4
loc_17f28 2e 81                            move.l  d1,(sp)
loc_17f2a a3 40                            .short 0xa340
loc_17f2c c8 23                            and.b (a3)-,d4
loc_17f2e 11 f3 11 ee 9c 2f 08 3f a2 08    move.b @(ffffffffffff9c2f)@(000000000000083f),($FFFFa208
loc_17f38 20 43                            movea.l d3,a0
loc_17f3a 23 41 7e bc                      move.l  d1,(a1)(32444)
loc_17f3e dc 22                            add.b (a2)-,d6
loc_17f40 a5 af                            .short 0xa5af
loc_17f42 aa 1c                            .short 0xaa1c
loc_17f44 2e 6b e1 f9                      movea.l (a3)(-7687),sp
loc_17f48 d6 c3                            adda.w d3,a3
loc_17f4a f3 b9                            .short 0xf3b9
loc_17f4c 7e 75                            moveq   #117,d7
loc_17f4e ba 88                            cmp.l a0,d5
loc_17f50 6b 2e                            bmi.s   loc_17f80
loc_17f52 a6 fc                            .short 0xa6fc
loc_17f54 e8 d7                            .short 0xe8d7
loc_17f56 32 1f                            move.w  (sp)+,d1
loc_17f58 ad 62                            .short 0xad62
loc_17f5a d3 58                            add.w   d1,(a0)+
loc_17f5c d6 da                            adda.w (a2)+,a3
loc_17f5e db 46                            addxw d6,d5
loc_17f60 d0 5d                            add.w (a5)+,d0
loc_17f62 04 6e 68 4d 02 43                subi.w  #26701,(a6)(579)
loc_17f68 ab 5c                            .short 0xab5c
loc_17f6a 09 0f 59 ef                      movepw (sp)(23023),d4
loc_17f6e 4b 93                            chkw (a3),d5
loc_17f70 59 de                            svs (a6)+
loc_17f72 34 21                            move.w  (a1)-,d2
loc_17f74 af 4e                            .short 0xaf4e
loc_17f76 2d 7a 15 df 9d 3f                move.l  (pc)(loc_19557),(a6)(-25281)
loc_17f7c d7 40                            addxw d0,d3
loc_17f7e 7e 74                            moveq   #116,d7
loc_17f80 68 09                            bvcs loc_17f8b
loc_17f82 b5 8d                            cmpm.l (a5)+,(a2)+
loc_17f84 06 b9 93 60 30 3c 0c a7 81 eb    addi.l  #-1822412740,0x0ca781eb
loc_17f8e 62 6d                            bhi.s   loc_17ffd
loc_17f90 60 ac                            bra.s   loc_17f3e
loc_17f92 55 23                            subq.b  #2,(a3)-
loc_17f94 43 c0                            .short 0x43c0
loc_17f96 e0 30                            roxrb d0,d0
loc_17f98 3e 6d 0b 42                      movea.w (a5)(2882),sp
loc_17f9c ba 5b                            cmp.w (a3)+,d5
loc_17f9e 71 2d                            .short 0x712d
loc_17fa0 3f 3b 73 68 42 e8                move.w  (pc)(loc_1c28a),-(sp)
loc_17fa6 31 69 01 09 a0 49                move.w  (a1)(265),(a0)(-24503)
loc_17fac df 0b                            addxb (a3)-,-(sp)
loc_17fae 21 94 1b 00                      move.l  (a4),(a0,d1:l:2)
loc_17fb2 50 6e ad 2f                      addq.w  #8,(a6)(-21201)
loc_17fb6 d7 c6                            adda.l  d6,a3
loc_17fb8 f3 40                            .short 0xf340
loc_17fba 96 4d                            sub.w a5,d3
loc_17fbc 69 0b                            bvss loc_17fc9
loc_17fbe 6b be                            bmi.s   loc_17f7e
loc_17fc0 77 84                            .short 0x7784
loc_17fc2 6f d6                            ble.s   loc_17f9a
loc_17fc4 6b 91                            bmi.s   loc_17f57
loc_17fc6 ff 53                            .short 0xff53
loc_17fc8 ff b1                            .short 0xffb1
loc_17fca 7f d2                            .short 0x7fd2
loc_17fcc 47 c4                            .short 0x47c4
loc_17fce 40 15                            negxb (a5)
loc_17fd0 e3 9a                            roll #1,d2
loc_17fd2 08 10 d0 20                      btst    #$20,(a0)
loc_17fd6 43 43                            .short 0x4343
loc_17fd8 bd bf                            .short 0xbdbf
loc_17fda f9 ff                            .short 0xf9ff
loc_17fdc 4f fe                            .short 0x4ffe
loc_17fde c7 17                            and.b d3,(sp)
loc_17fe0 e7 f1 8a 08                      rol.w (a1)8,a0:l:2)
loc_17fe4 5e 12                            addq.b  #7,(a2)
loc_17fe6 01 18                            btst d0,(a0)+
loc_17fe8 a0 5b                            .short 0xa05b
loc_17fea 88 60                            or.w (a0)-,d4
loc_17fec 77 c3                            .short 0x77c3
loc_17fee 70 ff                            moveq   #-1,d0
loc_17ff0 66 bf                            bne.s   loc_17fb1
loc_17ff2 fa 7f                            .short 0xfa7f
loc_17ff4 f7 56                            .short 0xf756
loc_17ff6 2f 1d                            move.l  (a5)+,-(sp)
loc_17ff8 ba cc                            cmpa.w a4,a5
loc_17ffa 84 26                            or.b (a6)-,d2
loc_17ffc 41 2a 93 c4                      chkl (a2)(-27708),d0
loc_18000 25 b1 1f cc 6f ea 1f fb 47 fe    move.l @0)@0),@(0000000000001ffb)@(00000000000047fe)
loc_1800a c4 84                            and.l   d4,d2
loc_1800c ad 41                            .short 0xad41
loc_1800e 2b 66 72 39                      move.l  (a6)-,(a5)(29241)
loc_18012 09 1c                            btst d4,(a4)+
loc_18014 8e 42                            or.w d2,d7
loc_18016 53 fd                            .short 0x53fd
loc_18018 60 cf                            bra.s   loc_17fe9
loc_1801a 80 fd                            .short 0x80fd
loc_1801c 60 a4                            bra.s   loc_17fc2
loc_1801e 84 9e                            orl (a6)+,d2
loc_18020 47 21                            chkl (a1)-,d3
loc_18022 c1 e4                            mulsw (a4)-,d0
loc_18024 aa a2                            .short 0xaaa2
loc_18026 42 56                            clr.w   (a6)
loc_18028 96 52                            sub.w (a2),d3
loc_1802a 05 23                            btst d2,(a3)-
loc_1802c b8 15                            cmp.b (a5),d4
loc_1802e d8 4a                            add.w a2,d4
loc_18030 e2 1c                            ror.b #1,d4
loc_18032 a5 74                            .short 0xa574
loc_18034 ae 92                            .short 0xae92
loc_18036 aa d6                            .short 0xaad6
loc_18038 53 91                            subql #1,(a1)
loc_1803a c8 48                            .short 0xc848
loc_1803c e5 32                            roxlb d2,d2
loc_1803e 17 4e                            .short 0x174e
loc_18040 57 0b                            subq.b  #3,a3
loc_18042 a7 25                            .short 0xa725
loc_18044 59 ca d2 12                      dbvs d2,loc_15258
loc_18048 b4 95                            cmp.l (a5),d2
loc_1804a 55 55                            subq.w  #2,(a5)
loc_1804c 54 e5                            scc (a5)-
loc_1804e 5f d6                            sle (a6)
loc_18050 1c 87                            move.b  d7,(a6)
loc_18052 0c f8                            .short 0x0cf8
loc_18054 09 36 62 53                      btst d4,(a6)(0000000000000053,d6.w:2)
loc_18058 e1 c8                            .short 0xe1c8
loc_1805a e4 54                            roxrw #2,d4
loc_1805c 81 34 84 60                      or.b d0,(a4)(0000000000000060,a0.w:4)
loc_18060 53 e4                            sls (a4)-
loc_18062 30 b7 eb 14                      move.w  (sp)@0,a6:l:2),(a0)
loc_18066 48 4a                            .short 0x484a
loc_18068 d2 12                            add.b (a2),d1
loc_1806a 39 0e                            move.w  a6,(a4)-
loc_1806c 17 69 c8 85 20 10                move.b  (a1)(-14203),(a3)(8208)
loc_18072 21 5d 18 15                      move.l  (a5)+,(a0)(6165)
loc_18076 c4 92                            and.l (a2),d2
loc_18078 05 22                            btst d2,(a2)-
loc_1807a ba 5f                            cmp.w (sp)+,d5
loc_1807c af 12                            .short 0xaf12
loc_1807e b8 b8 5c d2                      cmp.l loc_5cd2,d4
loc_18082 a0 e0                            .short 0xa0e0
loc_18084 7c 29                            moveq   #41,d6
loc_18086 2b bf                            .short 0x2bbf
loc_18088 58 38 0b 84                      addq.b  #4,loc_b84
loc_1808c ae 69                            .short 0xae69
loc_1808e 31 0f                            move.w sp,(a0)-
loc_18090 d6 09                            .short 0xd609
loc_18092 02 e0                            .short 0x02e0
loc_18094 24 38 09 0f                      move.l loc_90f,d2
loc_18098 d6 19                            add.b (a1)+,d3
loc_1809a 4b 39 09 4f 3e 02                chkl 0x094f3e02,d5
loc_180a0 e2 fd                            .short 0xe2fd
loc_180a2 60 cc                            bra.s   loc_18070
loc_180a4 20 93                            move.l  (a3),(a0)
loc_180a6 6d 94                            blt.s   loc_1803c
loc_180a8 0a 4d                            .short 0x0a4d
loc_180aa 70 e1                            moveq   #-31,d0
loc_180ac 62 6e                            bhi.s   loc_1811c
loc_180ae 42 5b                            clr.w   (a3)+
loc_180b0 79 4b                            .short 0x794b
loc_180b2 69 cb                            bvss loc_1807f
loc_180b4 68 b8                            bvcs loc_1806e
loc_180b6 66 2e                            bne.s   loc_180e6
loc_180b8 d2 fd                            .short 0xd2fd
loc_180ba 20 57                            movea.l (sp),a0
loc_180bc fe b0                            .short 0xfeb0
loc_180be 40 b6 a7 eb 13 7f 40 85 e3 f3    negxl @(000000000000137f)@(000000004085e3f3)
loc_180c8 d2 ba 58 71                      add.l (pc)(loc_1d93b),d1
loc_180cc d6 4f                            add.w sp,d3
loc_180ce ca 42                            and.w d2,d5
loc_180d0 e9 34                            roxlb d4,d4
loc_180d2 48 5c                            .short 0x485c
loc_180d4 77 24                            .short 0x7724
loc_180d6 45 d2                            lea     (a2),a2
loc_180d8 12 b8 23 5c                      move.b loc_235c,(a1)
loc_180dc 77 91                            .short 0x7791
loc_180de 91 e0                            suba.l (a0)-,a0
loc_180e0 dc 0e                            .short 0xdc0e
loc_180e2 5d 05                            subq.b  #6,d5
loc_180e4 c2 9c                            and.l (a4)+,d1
loc_180e6 07 41                            bchg d3,d1
loc_180e8 cb 36 e0 7c                      and.b d5,(a6)(000000000000007c,a6.w)
loc_180ec 1a 47                            .short 0x1a47
loc_180ee 29 c8                            .short 0x29c8
loc_180f0 e4 aa                            lsrl d2,d2
loc_180f2 ad 2c                            .short 0xad2c
loc_180f4 a5 39                            .short 0xa539
loc_180f6 09 34 84 84                      btst d4,(a4)(ffffffffffffff84,a0.w:4)
loc_180fa 9b 84                            subxl d4,d5
loc_180fc e4 2e                            lsr.b d2,d6
loc_180fe ce e6                            mulu.w (a6)-,d7
loc_18100 e1 76                            roxlw d0,d6
loc_18102 d2 9c                            add.l (a4)+,d1
loc_18104 81 4a                            .short 0x814a
loc_18106 b2 12                            cmp.b (a2),d1
loc_18108 3b a5 a4 b4                      move.w  (a5)-,(a5)(ffffffffffffffb4,a2.w:4)
loc_1810c e0 2e                            lsr.b d0,d6
loc_1810e 94 0a                            .short 0x940a
loc_18110 0d 2b 8a e2                      btst d6,(a3)(-29982)
loc_18114 e0 24                            asrb d0,d4
loc_18116 57 48                            subq.w  #3,a0
loc_18118 a4 dc                            .short 0xa4dc
loc_1811a 33 39 34 b3 39 09                move.w 0x34b33909,(a1)-
loc_18120 1f 06                            move.b  d6,-(sp)
loc_18122 94 f8 69 74                      subaw loc_6974,a2
loc_18126 ae e0                            .short 0xaee0
loc_18128 41 08                            .short 0x4108
loc_1812a 15 01                            move.b  d1,(a2)-
loc_1812c 02 90 96 bf de 0e                andi.l #-1765810674,(a0)
loc_18132 1d 12                            move.b  (a2),(a6)-
loc_18134 b7 eb 14 e4                      cmpal (a3)(5348),a3
loc_18138 72 39                            moveq   #57,d1
loc_1813a 09 1c                            btst d4,(a4)+
loc_1813c 9b 80                            subxl d0,d5
loc_1813e 93 48                            subxw (a0)-,(a1)-
loc_18140 4a 7c                            .short 0x4a7c
loc_18142 07 f3 28 28                      bset d3,(a3)(0000000000000028,d2:l)
loc_18146 24 38 52 54                      move.l loc_5254,d2
loc_1814a 39 1f                            move.w  (sp)+,(a4)-
loc_1814c f7 1a                            .short 0xf71a
loc_1814e 47 25                            chkl (a5)-,d3
loc_18150 5b 67                            subq.w  #5,-(sp)
loc_18152 96 6b 69 57                      sub.w (a3)(26967),d3
loc_18156 84 dc                            divu.w (a4)+,d2
loc_18158 4a ce                            .short 0x4ace
loc_1815a 25 94 94 49                      move.l  (a4),(a2)(0000000000000049,a1.w:4)
loc_1815e a4 d2                            .short 0xa4d2
loc_18160 69 5a                            bvss loc_181bc
loc_18162 59 48                            subq.w  #4,a0
loc_18164 e5 39                            rol.b d2,d1
loc_18166 1c a7                            move.b -(sp),(a6)
loc_18168 29 e6                            .short 0x29e6
loc_1816a 25 68 89 5a e1 9d                move.l  (a0)(-30374),(a2)(-7779)
loc_18170 65 9d                            bcs.s   loc_1810f
loc_18172 64 24                            bcc.s   loc_18198
loc_18174 2e 12                            move.l  (a2),d7
loc_18176 17 09                            .short 0x1709
loc_18178 0b a4                            bclr d5,(a4)-
loc_1817a 2e 21                            move.l  (a1)-,d7
loc_1817c 23 29 5d c0                      move.l  (a1)(24000),(a1)-
loc_18180 72 21                            moveq   #33,d1
loc_18182 70 c0                            moveq   #-64,d0
loc_18184 ca e0                            mulu.w (a0)-,d5
loc_18186 ff ef                            .short 0xffef
loc_18188 76 90                            moveq   #-112,d3
loc_1818a b8 70 39 72 1f ac ba 44 7c 0a    cmp.w (a0)(000000001facba44)@(0000000000007c0a),d4
loc_18194 e9 11                            roxlb #4,d1
loc_18196 f1 70 23 2b 8a 42 42 42 57 7e    prestore (a0)(ffffffffffff8a42,d2.w:2)@(000000004242577e)
loc_181a0 b0 70 39 09                      cmp.w (a0,d3:l)@0),d0
loc_181a4 66 72                            bne.s   loc_18218
loc_181a6 39 0c                            move.w  a4,(a4)-
loc_181a8 e5 39                            rol.b d2,d1
loc_181aa 1c 8e                            .short 0x1c8e
loc_181ac 56 80                            addq.l #3,d0
loc_181ae 95 a0                            sub.l d2,(a0)-
loc_181b0 d7 65                            add.w   d3,(a5)-
loc_181b2 72 89                            moveq   #-119,d1
loc_181b4 35 d3                            .short 0x35d3
loc_181b6 91 97                            sub.l d0,(sp)
loc_181b8 eb 32                            roxlb d5,d2
loc_181ba fd 61                            .short 0xfd61
loc_181bc 94 8e                            sub.l a6,d2
loc_181be 4e 64                            move.l  a4,%usp
loc_181c0 24 25                            move.l  (a5)-,d2
loc_181c2 d0 d7                            adda.w (sp),a0
loc_181c4 69 70                            bvss loc_18236
loc_181c6 95 dc                            suba.l (a4)+,a2
loc_181c8 0b 42                            bchg d5,d2
loc_181ca 9d d0                            suba.l (a0),a6
loc_181cc 91 70 c0 68                      sub.w   d0,(a0)(0000000000000068,a4.w)
loc_181d0 2e c0                            move.l  d0,(sp)+
loc_181d2 16 b8 4a ec                      move.b loc_4aec,(a3)
loc_181d6 01 6f b8 f4                      bchg d0,(sp)(-18188)
loc_181da 2b 9c 15 c3 4b a4 fc 06          move.l  (a4)+,@0)@(000000004ba4fc06)
loc_181e2 03 f9 98 48 e5 01                bset d1,0x9848e501
loc_181e8 a4 8a                            .short 0xa48a
loc_181ea 45 0d                            .short 0x450d
loc_181ec 38 5c                            movea.w (a4)+,a4
loc_181ee 42 e8                            .short 0x42e8
loc_181f0 1e db                            move.b  (a3)+,(sp)+
loc_181f2 bf 98                            eor.l d7,(a0)+
loc_181f4 1c e4                            move.b  (a4)-,(a6)+
loc_181f6 2e 12                            move.l  (a2),d7
loc_181f8 3f d6                            .short 0x3fd6
loc_181fa 5d c1                            slt d1
loc_181fc a5 75                            .short 0xa575
loc_181fe 64 55                            bcc.s   loc_18255
loc_18200 e0 25                            asrb d0,d5
loc_18202 95 24                            sub.b d2,(a4)-
loc_18204 7f ac                            .short 0x7fac
loc_18206 14 90                            move.b  (a0),(a2)
loc_18208 91 c8                            suba.l a0,a0
loc_1820a 70 5b                            moveq   #91,d0
loc_1820c a5 62                            .short 0xa562
loc_1820e bb 46                            eor.w d5,d6
loc_18210 e0 9a                            ror.l #8,d2
loc_18212 4f 85                            chkw d5,d7
loc_18214 ed 21                            aslb d6,d1
loc_18216 21 74 0e 42 5c 8f                move.l  (a4)(0000000000000042,d0:l:8),(a0)(23695)
loc_1821c 4e 52 86 b1                      linkw a2,#-31055
loc_18220 a2 0c                            .short 0xa20c
loc_18222 3f 3c 48 30                      move.w  #18480,-(sp)
loc_18226 18 6b                            .short 0x186b
loc_18228 3d 2e dd 20                      move.w  (a6)(-8928),(a6)-
loc_1822c 52 d3                            shi (a3)
loc_1822e f8 3b                            .short 0xf83b
loc_18230 f7 02                            .short 0xf702
loc_18232 80 24                            or.b (a4)-,d0
loc_18234 10 48                            .short 0x1048
loc_18236 68 97                            bvcs loc_181cf
loc_18238 69 01                            bvss loc_1823b
loc_1823a fa e2                            .short 0xfae2
loc_1823c 12 c2                            move.b  d2,(a1)+
loc_1823e ee 05                            asrb #7,d5
loc_18240 28 5c                            movea.l (a4)+,a4
loc_18242 d0 10                            add.b (a0),d0
loc_18244 4d 2e 42 d6                      chkl (a6)(17110),d6
loc_18248 81 05                            sbcd d5,d0
loc_1824a c9 71 ef 40                      and.w d4,(a1)
loc_1824e 52 43                            addq.w  #1,d3
loc_18250 2b b0 10 49 14 85                move.l  (a0)(0000000000000049,d1.w),(a5)(ffffffffffffff85,d1.w:4)
loc_18256 c4 2e 12 23                      and.b (a6)(4643),d2
loc_1825a ba 65                            cmp.w (a5)-,d5
loc_1825c c0 10                            and.b (a0),d0
loc_1825e 90 90                            sub.l (a0),d0
loc_18260 90 b8 48 e5                      sub.l loc_48e5,d0
loc_18264 95 1b                            sub.b d2,(a3)+
loc_18266 81 e6                            divsw (a6)-,d0
loc_18268 df ac ca 56                      add.l d7,(a4)(-13738)
loc_1826c 94 e4                            subaw (a4)-,a2
loc_1826e 72 3e                            moveq   #62,d1
loc_18270 42 47                            clr.w d7
loc_18272 0b 85                            bclr d5,d5
loc_18274 d2 81                            add.l d1,d1
loc_18276 c2 e2                            mulu.w (a2)-,d1
loc_18278 38 4e                            movea.w a6,a4
loc_1827a 47 29 c8 49                      chkl (a1)(-14263),d3
loc_1827e a4 24                            .short 0xa424
loc_18280 24 d2                            move.l  (a2),(a2)+
loc_18282 5b 4b                            subq.w  #5,a3
loc_18284 f3 c7                            .short 0xf3c7
loc_18286 74 87                            moveq   #-121,d2
loc_18288 e8 84                            asr.l #4,d4
loc_1828a ae 90                            .short 0xae90
loc_1828c d3 f7 8d 23 e0 d2 69 56 4d 9b    adda.l (sp)(ffffffffffffe0d2,a0:l:4)@(0000000069564d9b),a1
loc_18296 49 b3 68 5a                      chkw (a3)(000000000000005a,d6:l),d4
loc_1829a 43 46                            .short 0x4346
loc_1829c 93 48                            subxw (a0)-,(a1)-
loc_1829e 48 48                            .short 0x4848
loc_182a0 49 a4                            chkw (a4)-,d4
loc_182a2 d9 89                            addxl (a1)-,(a4)-
loc_182a4 09 35 04 84                      btst d4,(a5)(ffffffffffffff84,d0.w:4)
loc_182a8 86 62                            or.w (a2)-,d3
loc_182aa 56 cd b3 cb                      dbne d5,loc_13677
loc_182ae 3a cb                            move.w  a3,(a5)+
loc_182b0 29 57 31 2b                      move.l  (sp),(a4)(12587)
loc_182b4 66 24                            bne.s   loc_182da
loc_182b6 aa a7                            .short 0xaaa7
loc_182b8 0c a0 3f e2 aa aa                cmpi.l #1071819434,(a0)-
loc_182be aa bf                            .short 0xaabf
loc_182c0 f2 1f                            .short 0xf21f
loc_182c2 e4 3f                            ror.b d2,d7
loc_182c4 e8 c4                            .short 0xe8c4
loc_182c6 20 e9 40 81                      move.l  (a1)(16513),(a0)+
loc_182ca 1f 61 bd 02                      move.b  (a1)-,(sp)(-17150)
loc_182ce 1a 1d                            move.b  (a5)+,d5
loc_182d0 02 04 71 40                      andi.b  #$40,d4
loc_182d4 8e 1c                            or.b (a4)+,d7
loc_182d6 47 14                            chkl (a4),d3
loc_182d8 a5 fb                            .short 0xa5fb
loc_182da fc 67                            .short 0xfc67
loc_182dc e3 92                            roxl.l #1,d2
loc_182de 2a 2d 51 72                      move.l  (a5)(20850),d5
loc_182e2 48 e3 1c 23                      movem.l d3-d5/a2/a6-sp,(a3)-
loc_182e6 8c 7f                            .short 0x8c7f
loc_182e8 c8 3f                            .short 0xc83f
loc_182ea c3 1f                            and.b d1,(sp)+
loc_182ec f3 8e                            .short 0xf38e
loc_182ee b3 d9                            cmpal (a1)+,a1
loc_182f0 16 d8                            move.b  (a0)+,(a3)+
loc_182f2 db 99                            add.l d5,(a1)+
loc_182f4 22 35 6e 71                      move.l  (a5)(0000000000000071,d6:l:8),d1
loc_182f8 1d 9b a8 8b                      move.b  (a3)+,(a6)(ffffffffffffff8b,a2:l)
loc_182fc 1b d9                            .short 0x1bd9
loc_182fe 0d c2                            bset d6,d2
loc_18300 1b d0                            .short 0x1bd0
loc_18302 dd 2d b1 b6                      add.b d6,(a5)(-20042)
loc_18306 36 e6                            move.w  (a6)-,(a3)+
loc_18308 bf a5                            eor.l d7,(a5)-
loc_1830a 90 5e                            sub.w (a6)+,d0
loc_1830c e1 15                            roxlb #8,d5
loc_1830e 2a 99                            move.l  (a1)+,(a5)
loc_18310 5f 92                            subql #7,(a2)
loc_18312 64 8b                            bcc.s   loc_1829f
loc_18314 93 d1                            suba.l (a1),a1
loc_18316 ef 7a                            rol.w d7,d2
loc_18318 28 a4                            move.l  (a4)-,(a4)
loc_1831a f6 44                            .short 0xf644
loc_1831c 7e d9                            moveq   #-39,d7
loc_1831e af 9a                            .short 0xaf9a
loc_18320 45 c7                            .short 0x45c7
loc_18322 33 9b ee b2                      move.w  (a3)+,(a1)(ffffffffffffffb2,a6:l:8)
loc_18326 59 c3                            svs d3
loc_18328 ec 7a                            ror.w d6,d2
loc_1832a 25 a8 71 fd b2 9a                move.l  (a0)(29181),(a2)(ffffffffffffff9a,a3.w:2)
loc_18330 0d c6                            bset d6,d6
loc_18332 8f 1e                            or.b d7,(a6)+
loc_18334 99 c7                            suba.l d7,a4
loc_18336 ac d2                            .short 0xacd2
loc_18338 83 fc 91 c6                      divsw #-28218,d1
loc_1833c 38 47                            movea.w d7,a4
loc_1833e c5 52                            and.w d2,(a2)
loc_18340 b7 aa e4 95                      eor.l d3,(a2)(-7019)
loc_18344 4f 19                            chkl (a1)+,d7
loc_18346 f8 ef                            .short 0xf8ef
loc_18348 1a 86                            move.b  d6,(a5)
loc_1834a 23 63 21 a0                      move.l  (a3)-,(a1)(8608)
loc_1834e 43 bc 3d ec                      chkw #15852,d1
loc_18352 f1 0e                            .short 0xf10e
loc_18354 b5 d8                            cmpal (a0)+,a2
loc_18356 86 94                            orl (a4),d3
loc_18358 8f f9 14 ff c9 1f                divsw 0x14ffc91f,d7
loc_1835e e0 9c                            ror.l #8,d4
loc_18360 47 4a                            .short 0x474a
loc_18362 32 3e                            .short 0x323e
loc_18364 c0 82                            and.l   d2,d0
loc_18366 21 0d                            move.l  a5,(a0)-
loc_18368 0e 21                            .short 0x0e21
loc_1836a 02 3b                            .short 0x023b
loc_1836c 23 87 68 d1                      move.l  d7,(a1)(ffffffffffffffd1,d6:l)
loc_18370 1e fa 22 aa                      move.b  (pc)(loc_1a61c),(sp)+
loc_18374 aa aa                            .short 0xaaaa
loc_18376 c7 fa 71 ff                      mulsw (pc)(loc_1f577),d3
loc_1837a 21 ff                            .short 0x21ff
loc_1837c 46 27                            not.b -(sp)
loc_1837e fc 76                            .short 0xfc76
loc_18380 eb 38                            rol.b d5,d0
loc_18382 84 6d 8d ba                      or.w (a5)(-29254),d2
loc_18386 68 35                            bvcs loc_183bd
loc_18388 5f 1c                            subq.b  #7,(a4)+
loc_1838a 6f d8                            ble.s   loc_18364
loc_1838c e1 2d                            lsl.b d0,d5
loc_1838e 43 8b                            .short 0x438b
loc_18390 20 43                            movea.l d3,a0
loc_18392 43 7a                            .short 0x437a
loc_18394 32 4d                            movea.w a5,a1
loc_18396 04 5b 62 1e                      subi.w  #25118,(a3)+
loc_1839a e3 41                            asl.w #1,d1
loc_1839c 1e 99                            move.b  (a1)+,(sp)
loc_1839e a3 9e                            .short 0xa39e
loc_183a0 c7 45                            exg d3,d5
loc_183a2 09 49 c4 20                      movepl (a1)(-15328),d4
loc_183a6 fd b3                            .short 0xfdb3
loc_183a8 5f 57                            subq.w  #7,(sp)
loc_183aa 1b a2 cf ba c8 c8 e6 82 f6 a1    move.b  (a2)-,@(ffffffffc8c8e682,a4:l:8)@(fffffffffffff6a1)
loc_183b4 a0 8e                            .short 0xa08e
loc_183b6 c5 3b                            .short 0xc53b
loc_183b8 c4 50                            and.w (a0),d2
loc_183ba d1 d9                            adda.l (a1)+,a0
loc_183bc eb 1a                            rol.b #5,d2
loc_183be 1a 51                            .short 0x1a51
loc_183c0 0f fe                            .short 0x0ffe
loc_183c2 98 ef 8f 8c                      subaw (sp)(-28788),a4
loc_183c6 4f 63                            .short 0x4f63
loc_183c8 44 5e                            neg.w (a6)+
loc_183ca 10 e2                            move.b  (a2)-,(a0)+
loc_183cc 6f 7d                            ble.s   loc_1844b
loc_183ce 5d 6c 9b 10                      subq.w  #6,(a4)(-25840)
loc_183d2 e3 fe                            .short 0xe3fe
loc_183d4 4c a2                            .short 0x4ca2
loc_183d6 43 f8 87 1d                      lea     ($FFFF871d,a1
loc_183da d6 d4                            adda.w (a4),a3
loc_183dc 96 d8                            subaw (a0)+,a3
loc_183de 11 a2 69 38 84 7a bd a8          move.b  (a2)-,(a0)(ffffffff847abda8,d6:l)
loc_183e6 9b e3                            suba.l (a3)-,a5
loc_183e8 8c 48                            .short 0x8c48
loc_183ea ff 89                            .short 0xff89
loc_183ec 3e 68 cf a6                      movea.w (a0)(-12378),sp
loc_183f0 dd 73 46 8c                      add.w   d6,(a3)(ffffffffffffff8c,d4.w:8)
loc_183f4 f7 4d                            .short 0xf74d
loc_183f6 06 a8 92 07 14 7a 35 2a          addi.l  #-1845029766,(a0)(13610)
loc_183fe 81 2c f4 54                      or.b d0,(a4)(-2988)
loc_18402 b6 c4                            cmpa.w d4,a3
loc_18404 68 a1                            bvcs loc_183a7
loc_18406 a4 de                            .short 0xa4de
loc_18408 b4 70 8f 47 a2 b2 52 a8          cmp.w (a0)@(ffffffffa2b252a8),d2
loc_18410 36 46                            movea.w d6,a3
loc_18412 77 d5                            .short 0x77d5
loc_18414 c2 46                            and.w d6,d1
loc_18416 cf 7d                            .short 0xcf7d
loc_18418 53 1a                            subq.b  #1,(a2)+
loc_1841a 38 47                            movea.w d7,a4
loc_1841c a0 21                            .short 0xa021
loc_1841e 4a c5                            tas d5
loc_18420 92 b7 d9 1d                      sub.l (sp)@0,a5:l),d1
loc_18424 6a 94                            bpl.s   loc_183ba
loc_18426 49 ff                            .short 0x49ff
loc_18428 10 ca                            .short 0x10ca
loc_1842a 3e 3b c1 4f 65 af 09 67          move.w  (pc)(loc_1842c)@(0000000065af0967),d7
loc_18432 be ae b6 4d                      cmp.l (a6)(-18867),d7
loc_18436 88 df                            divu.w (sp)+,d4
loc_18438 c4 05                            and.b d5,d2
loc_1843a 13 8f                            .short 0x138f
loc_1843c 10 fd                            .short 0x10fd
loc_1843e 24 e2                            move.l  (a2)-,(a2)+
loc_18440 99 25                            sub.b d4,(a5)-
loc_18442 62 12                            bhi.s   loc_18456
loc_18444 a9 58                            .short 0xa958
loc_18446 ba d6                            cmpa.w (a6),a5
loc_18448 89 44                            .short 0x8944
loc_1844a 8f 14                            or.b d7,(a4)
loc_1844c ff 49                            .short 0xff49
loc_1844e 5b e3                            smi (a3)-
loc_18450 57 ca 91 b2                      dbeq d2,loc_11604
loc_18454 2a 46                            movea.l d6,a5
loc_18456 c8 64                            and.w (a4)-,d4
loc_18458 94 bf                            .short 0x94bf
loc_1845a ac 52                            .short 0xac52
loc_1845c b1 09                            cmpmb (a1)+,(a0)+
loc_1845e 5a 2a 5a 34                      addq.b  #5,(a2)(23092)
loc_18462 4c 91 6c 4f                      movem.w (a1),d0-d3/d6/a2-a3/a5-a6
loc_18466 4b e8 94 5b                      lea     (a0)(-27557),a5
loc_1846a 25 2a 82 35                      move.l  (a2)(-32203),(a2)-
loc_1846e 48 d5 d5 41                      movem.l d0/d6/a0/a2/a4/a6-sp,(a5)
loc_18472 3d 2f a2 51                      move.w  (sp)(-23983),(a6)-
loc_18476 4d 2b 7d a2                      chkl (a3)(32162),d6
loc_1847a eb 58                            rol.w #5,d0
loc_1847c d1 2b fa 49                      add.b d0,(a3)(-1463)
loc_18480 f1 45                            .short 0xf145
loc_18482 1d 29 5a 46                      move.b  (a1)(23110),(a6)-
loc_18486 d7 e4                            adda.l (a4)-,a3
loc_18488 f1 55                            prestore (a5)
loc_1848a b2 52                            cmp.w (a2),d1
loc_1848c 33 fd                            .short 0x33fd
loc_1848e 20 a2                            move.l  (a2)-,(a0)
loc_18490 63 0f                            bls.s   loc_184a1
loc_18492 db 9f                            add.l d5,(sp)+
loc_18494 f6 8d                            .short 0xf68d
loc_18496 ff 71                            .short 0xff71
loc_18498 03 7b                            .short 0x037b
loc_1849a bf 51                            eor.w d7,(a1)
loc_1849c 03 e3                            bset d1,(a3)-
loc_1849e 8b fe                            .short 0x8bfe
loc_184a0 a0 f8                            .short 0xa0f8
loc_184a2 e0 f7 7e 62                      asrw (sp)(0000000000000062,d7:l:8)
loc_184a6 da 9b                            add.l (a3)+,d5
loc_184a8 79 ea                            .short 0x79ea
loc_184aa 84 7f                            .short 0x847f
loc_184ac 31 d9 f9 df                      move.w  (a1)+,($FFFFf9df
loc_184b0 ed 6b                            lsl.w d6,d3
loc_184b2 1f d8                            .short 0x1fd8
loc_184b4 0f 77 ee 2e                      bchg d7,(sp)(000000000000002e,a6:l:8)
loc_184b8 78 0f                            moveq   #$F,d4
loc_184ba dc 0d                            .short 0xdc0d
loc_184bc e3 f7 02 03                      lsl.w (sp)3,d0.w:2)
loc_184c0 51 ea 51 d5                      sf (a2)(20949)
loc_184c4 af ab                            .short 0xafab
loc_184c6 5d dc                            slt (a4)+
loc_184c8 7f da                            .short 0x7fda
loc_184ca 38 7e                            .short 0x387e
loc_184cc e1 ce                            .short 0xe1ce
loc_184ce 1f a8 b9 cf f5 0f 1e 33 fc c5    move.b  (a0)(-17969),(sp)@(000000001e33fcc5,sp.w:4)
loc_184d8 cf 0e                            abcd (a6)-,-(sp)
loc_184da 36 d5                            move.w  (a5),(a3)+
loc_184dc 6d 47                            blt.s   loc_18525
loc_184de bc f9 75 1d dc 67                cmpa.w 0x751ddc67,a6
loc_184e4 41 f9 8d f3 d6 b6                lea 0x8df3d6b6,a0
loc_184ea a0 d6                            .short 0xa0d6
loc_184ec 70 3a                            moveq   #58,d0
loc_184ee 0d 67                            bchg d6,-(sp)
loc_184f0 1c 9e                            move.b  (a6)+,(a6)
loc_184f2 7a db                            moveq   #-37,d5
loc_184f4 8e e9 76 7f                      divu.w (a1)(30335),d7
loc_184f8 cb 7a                            .short 0xcb7a
loc_184fa af fc                            .short 0xaffc
loc_184fc bf eb ff 75                      cmpal (a3)(-139),sp
loc_18500 de 7f                            .short 0xde7f
loc_18502 98 d7                            subaw (sp),a4
loc_18504 9e ff                            .short 0x9eff
loc_18506 cc 0a                            .short 0xcc0a
loc_18508 5b 5a                            subq.w  #5,(a2)+
loc_1850a ce 07                            and.b d7,d7
loc_1850c ac 50                            .short 0xac50
loc_1850e e2 7a                            ror.w d1,d2
loc_18510 c5 0d                            abcd (a5)-,(a2)-
loc_18512 d4 f5 cf 3d 6d 4d 71 9e          adda.w (a5)(000000006d4d719e)@0,a4:l:8),a2
loc_1851a ac e2                            .short 0xace2
loc_1851c 7a b9                            moveq   #-71,d5
loc_1851e fb 4f                            .short 0xfb4f
loc_18520 9c 6d 09 3d                      sub.w (a5)(2365),d6
loc_18524 1f 63 68 37                      move.b  (a3)-,(sp)(26679)
loc_18528 1e 82                            move.b  d2,(sp)
loc_1852a f0 87 c3 5f                      pbac loc_1488b
loc_1852e eb 23                            aslb d5,d3
loc_18530 0f eb ff d7                      bset d7,(a3)(-41)
loc_18534 8f f5 3c 7f                      divsw (a5)(000000000000007f,d3:l:4),d7
loc_18538 a9 bc                            .short 0xa9bc
loc_1853a 6e 08                            bgt.s   loc_18544
loc_1853c fd 6f                            .short 0xfd6f
loc_1853e d6 37 0f e0 8d c1                add.b @(ffffffffffff8dc1),d3
loc_18544 35 fe                            .short 0x35fe
loc_18546 b3 5f                            eor.w d1,(sp)+
loc_18548 eb 1f                            rol.b #5,d7
loc_1854a 8e 71 84 73                      or.w (a1)(0000000000000073,a0.w:4),d7
loc_1854e d5 3e                            .short 0xd53e
loc_18550 3d bc fa 8e fd a3 9c df 66 96 dd a3  move.w  #-1394,@(ffffffffffff9cdf,sp:l:4)@(000000006696dda3)
loc_1855c 5e 2f d0 f5                      addq.b  #7,(sp)(-12043)
loc_18560 fe b3                            .short 0xfeb3
loc_18562 5c 8f                            addq.l #6,sp
loc_18564 1f da                            .short 0x1fda
loc_18566 d1 31 80 e3                      add.b d0,(a1)(ffffffffffffffe3,a0.w)
loc_1856a 2e 32 de 9c                      move.l  (a2)(ffffffffffffff9c,a5:l:8),d7
loc_1856e 61 07                            bsr.s   loc_18577
loc_18570 1a 31 02 56                      move.b  (a1)(0000000000000056,d0.w:2),d5
loc_18574 c7 8f                            exg d3,sp
loc_18576 47 d3                            lea     (a3),a3
loc_18578 8f 13                            or.b d7,(a3)
loc_1857a 89 a6                            orl d4,(a6)-
loc_1857c 26 f4 bc b5                      move.l  (a4)(ffffffffffffffb5,a3:l:4),(a3)+
loc_18580 1f e8                            .short 0x1fe8
loc_18582 92 0c                            .short 0x920c
loc_18584 ec e6                            .short 0xece6
loc_18586 e1 c3                            .short 0xe1c3
loc_18588 87 67                            or.w d3,-(sp)
loc_1858a 0f 37 67 3f f3 9f f1 e7 d3 62 fe 28  btst d7,(sp)(fffffffff39ff1e7)@(ffffffffd362fe28,d6.w:8)
loc_18596 2a 63                            movea.l (a3)-,a5
loc_18598 ab c4                            .short 0xabc4
loc_1859a a9 89                            .short 0xa989
loc_1859c 5b 10                            subq.b  #5,(a0)
loc_1859e 4b 6c                            .short 0x4b6c
loc_185a0 6a 54                            bpl.s   loc_185f6
loc_185a2 c4 8c                            .short 0xc48c
loc_185a4 8c a9 fb 7c                      orl (a1)(-1156),d6
loc_185a8 79 e8                            .short 0x79e8
loc_185aa 74 e7                            moveq   #-25,d2
loc_185ac fd be                            .short 0xfdbe
loc_185ae 34 26                            move.w  (a6)-,d2
loc_185b0 20 58                            movea.l (a0)+,a0
loc_185b2 d0 ab 8b 10                      add.l (a3)(-29936),d0
loc_185b6 2b 60 78 d7                      move.l  (a0)-,(a5)(30935)
loc_185ba 1a 16                            move.b  (a6),d5
loc_185bc af d2                            .short 0xafd2
loc_185be 50 87                            addq.l #8,d7
loc_185c0 3d 0e                            move.w  a6,(a6)-
loc_185c2 9c e0                            subaw (a0)-,a6
loc_185c4 a9 fb                            .short 0xa9fb
loc_185c6 7c 4a                            moveq   #74,d6
loc_185c8 98 82                            sub.l d2,d4
loc_185ca 9e 20                            sub.b (a0)-,d7
loc_185cc 94 81                            sub.l d1,d2
loc_185ce 1e 20                            move.b  (a0)-,d7
loc_185d0 81 19                            or.b d0,(a1)+
loc_185d2 53 13                            subq.b  #1,(a3)
loc_185d4 c0 ca                            .short 0xc0ca
loc_185d6 9f b7 c5 41                      sub.l d7,(sp)@0)
loc_185da 53 f8 e5 4c                      sls ($FFFFe54c
loc_185de 70 32                            moveq   #50,d0
loc_185e0 18 ae 58 d4                      move.b  (a6)(22740),(a4)
loc_185e4 a9 8d                            .short 0xa98d
loc_185e6 4a 9e                            tst.l (a6)+
loc_185e8 3a b1 e7 a5 9f 1f                move.w @(ffffffffffff9f1f)@0,a6.w:8),(a5)
loc_185ee db f8 e0 30                      adda.l ($FFFFe030,a5
loc_185f2 04 aa a6 43 00 43 c7 f6          subi.l #-1505558461,(a2)(-14346)
loc_185fa fe 20                            .short 0xfe20



loc_185fc: 00 7c c6 e6                      ori.w #-14618,sr
loc_18600 d6 ce                            adda.w a6,a3
loc_18602 c6 7c 00 18                      and.w #$18d3
loc_18606 38 18                            move.w  (a0)+,d4
loc_18608 18 18                            move.b  (a0)+,d4
loc_1860a 18 3c 00 7c                      move.b  #$7C,d4
loc_1860e c6 c6                            mulu.w d6,d3
loc_18610 06 7c                            .short 0x067c
loc_18612 c0 fe                            .short 0xc0fe
loc_18614 00 7c c6 06                      ori.w #-14842,sr
loc_18618 3c 06                            move.w  d6,d6
loc_1861a c6 7c 00 0c                      and.w #$C,d3
loc_1861e 1c 3c 6c cc                      move.b  #-52,d6
loc_18622 fe 0c                            .short 0xfe0c
loc_18624 00 fc                            .short 0x00fc
loc_18626 c0 c0                            mulu.w d0,d0
loc_18628 fc 06                            .short 0xfc06
loc_1862a c6 7c 00 7c                      and.w #$7C,d3
loc_1862e c6 c0                            mulu.w d0,d3
loc_18630 fc c6                            .short 0xfcc6
loc_18632 c6 7c 00 fe                      and.w #254,d3
loc_18636 c6 0c                            .short 0xc60c
loc_18638 18 30 30 30                      move.b  (a0)(0000000000000030,d3.w),d4
loc_1863c 00 7c c6 c6                      ori.w #-14650,sr
loc_18640 7c c6                            moveq   #-58,d6
loc_18642 c6 7c 00 7c                      and.w #$7C,d3
loc_18646 c6 c6                            mulu.w d6,d3
loc_18648 7e 06                            moveq   #6,d7
loc_1864a c6 7c 00 18                      and.w #$18d3
loc_1864e 18 00                            move.b  d0,d4
loc_18650 18 18                            move.b  (a0)+,d4
loc_18652 00 00 00 82                      ori.b #-126,d0
loc_18656 44 28 10 28                      negb (a0)(4136)
loc_1865a 44 82                            neg.l   d2
loc_1865c 00 06 18 60                      ori.b #$60,d6
loc_18660 80 60                            or.w (a0)-,d0
loc_18662 18 06                            move.b  d6,d4
loc_18664 00 00 00 fe                      ori.b #-2,d0
loc_18668 00 fe                            .short 0x00fe
loc_1866a 00 00 00 c0                      ori.b #-64,d0
loc_1866e 30 0c                            move.w  a4,d0
loc_18670 02 0c                            .short 0x020c
loc_18672 30 c0                            move.w  d0,(a0)+
loc_18674 00 7c c6 06                      ori.w #-14842,sr
loc_18678 1c 30 00 30                      move.b  (a0)(0000000000000030,d0.w),d6
loc_1867c 00 0e                            .short loc_e
loc_1867e 0c 18 00 00                      cmpi.b  #0,(a0)+
loc_18682 00 00 00 38                      ori.b #$38,d0
loc_18686 7c e2                            moveq   #-30,d6
loc_18688 e2 fe                            .short 0xe2fe
loc_1868a e2 e2                            lsr.w (a2)-
loc_1868c 00 fc                            .short 0x00fc
loc_1868e e2 e2                            lsr.w (a2)-
loc_18690 fc e2                            .short 0xfce2
loc_18692 e2 fc                            .short 0xe2fc
loc_18694 00 7c e2 e0                      ori.w #-7456,sr
loc_18698 e0 e0                            asrw (a0)-
loc_1869a e2 7c                            ror.w d1,d4
loc_1869c 00 f8                            .short 0x00f8
loc_1869e e4 e2                            roxrw (a2)-
loc_186a0 e2 e2                            lsr.w (a2)-
loc_186a2 e4 f8 00 fe                      roxrw loc_0fe
loc_186a6 e0 e0                            asrw (a0)-
loc_186a8 fc e0                            .short 0xfce0
loc_186aa e0 fe                            .short 0xe0fe
loc_186ac 00 fe                            .short 0x00fe
loc_186ae e0 e0                            asrw (a0)-
loc_186b0 fc e0                            .short 0xfce0
loc_186b2 e0 e0                            asrw (a0)-
loc_186b4 00 3c 62 e0                      ori.b #-32,ccr
loc_186b8 e0 ee 66 3a                      asrw (a6)(26170)
loc_186bc 00 e2                            .short 0x00e2
loc_186be e2 e2                            lsr.w (a2)-
loc_186c0 fe e2                            .short 0xfee2
loc_186c2 e2 e2                            lsr.w (a2)-
loc_186c4 00 7c 38 38                      ori.w #14392,sr
loc_186c8 38 38 38 7c                      move.w loc_387c,d4
loc_186cc 00 3e                            .short 0x003e
loc_186ce 1c 1c                            move.b  (a4)+,d6
loc_186d0 1c 1c                            move.b  (a4)+,d6
loc_186d2 9c 78 00 e2                      sub.w loc_0e2,d6
loc_186d6 e4 e8 f4 e4                      roxrw (a0)(-2844)
loc_186da e2 e2                            lsr.w (a2)-
loc_186dc 00 e0                            .short 0x00e0
loc_186de e0 e0                            asrw (a0)-
loc_186e0 e0 e0                            asrw (a0)-
loc_186e2 e2 fe                            .short 0xe2fe
loc_186e4 00 e2                            .short 0x00e2
loc_186e6 f6 fe                            .short 0xf6fe
loc_186e8 ea ea                            .short 0xeaea
loc_186ea ea ea                            .short 0xeaea
loc_186ec 00 f2                            .short 0x00f2
loc_186ee f2 fa                            .short 0xf2fa
loc_186f0 ea ee                            .short 0xeaee
loc_186f2 e6 e6                            ror.w (a6)-
loc_186f4 00 7c e2 e2                      ori.w #-7454,sr
loc_186f8 e2 e2                            lsr.w (a2)-
loc_186fa e2 7c                            ror.w d1,d4
loc_186fc 00 fc                            .short 0x00fc
loc_186fe e2 e2                            lsr.w (a2)-
loc_18700 e2 fc                            .short 0xe2fc
loc_18702 e0 e0                            asrw (a0)-
loc_18704 00 7c e2 e2                      ori.w #-7454,sr
loc_18708 e2 ea e6 7e                      lsr.w (a2)(-6530)
loc_1870c 00 fc                            .short 0x00fc
loc_1870e e2 e2                            lsr.w (a2)-
loc_18710 e2 fc                            .short 0xe2fc
loc_18712 e4 e6                            roxrw (a6)-
loc_18714 00 7c e2 e0                      ori.w #-7456,sr
loc_18718 7c 02                            moveq   #2,d6
loc_1871a e2 7c                            ror.w d1,d4
loc_1871c 00 fe                            .short 0x00fe
loc_1871e 38 38 38 38                      move.w loc_3838,d4
loc_18722 38 38 00 e2                      move.w loc_0e2,d4
loc_18726 e2 e2                            lsr.w (a2)-
loc_18728 e2 e2                            lsr.w (a2)-
loc_1872a e2 7c                            ror.w d1,d4
loc_1872c 00 e2                            .short 0x00e2
loc_1872e e2 62                            asrw d1,d2
loc_18730 62 24                            bhi.s   loc_18756
loc_18732 3c 38 00 e2                      move.w loc_0e2,d6
loc_18736 ea ea                            .short 0xeaea
loc_18738 ea ea                            .short 0xeaea
loc_1873a 7e 12                            moveq   #18,d7
loc_1873c 00 e2                            .short 0x00e2
loc_1873e f4 78                            .short 0xf478
loc_18740 3c 3e                            .short 0x3c3e
loc_18742 4e 86                            .short 0x4e86
loc_18744 00 e2                            .short 0x00e2
loc_18746 e2 74                            roxrw d1,d4
loc_18748 78 38                            moveq   #$38,d4
loc_1874a 38 38 00 fe                      move.w loc_0fe,d4
loc_1874e 0e 1c                            .short 0x0e1c
loc_18750 38 70 e0 fe                      movea.w (a0)(fffffffffffffffe,a6.w),a4

; EXIT SIGN

loc_18754: 00 09                            .short loc_9
loc_18756 81 03                            sbcd d3,d0
loc_18758 05 35 1d 82 04 09                btst d2,@0,d1:l:4)@(0000000000000409)
loc_1875e 35 1e                            move.w  (a6)+,(a2)-
loc_18760 83 04                            sbcd d4,d1
loc_18762 08 37 7c 84 02 00                btst    #-124,(sp,d0.w:2)
loc_18768 14 0c                            .short 0x140c
loc_1876a 25 1c                            move.l  (a4)+,(a2)-
loc_1876c 34 0d                            move.w  a5,d2
loc_1876e 47 7d                            .short 0x477d
loc_18770 63 03                            bls.s   loc_18775
loc_18772 73 02                            .short 0x7302
loc_18774 ff 4b                            .short 0xff4b
loc_18776 3c 4e                            movea.w a6,a6
loc_18778 4b f6 cb f1 29 29 3f 24          lea @(0000000029293f24)@0),a5
loc_18780 7f 4b                            .short 0x7f4b
loc_18782 93 93                            sub.l d1,(a3)
loc_18784 b2 7e                            .short 0xb27e
loc_18786 8b 92                            orl d5,(a2)
loc_18788 49 f9 23 f4 49 23                lea 0x23f44923,a4
loc_1878e f8 5f                            .short 0xf85f
loc_18790 65 cb                            bcs.s   loc_1875d
loc_18792 97 29 2f ea                      sub.b d3,(a1)(12266)
loc_18796 74 b9                            moveq   #-71,d2
loc_18798 5f 76 be 95                      subq.w  #7,(a6)(ffffffffffffff95,a3:l:8)
loc_1879c 25 4f c8 9f                      move.l sp,(a2)(-14177)
loc_187a0 d1 e5                            adda.l (a5)-,a0
loc_187a2 cb b4 fd 0f 29 4f c8 9f          and.l   d5,(a4)@(00000000294fc89f,sp:l:4)
loc_187aa a1 49                            .short 0xa149
loc_187ac 1f c1                            .short 0x1fc1
loc_187ae fb 5d                            .short 0xfb5d
loc_187b0 75 d4                            .short 0x75d4
loc_187b2 97 f5 3e 11                      suba.l (a5)(0000000000000011,d3:l:8),a3
loc_187b6 90 fe                            .short 0x90fe
loc_187b8 6c 3f                            bge.s   loc_187f9
loc_187ba 84 24                            or.b (a4)-,d2
loc_187bc a0 fc                            .short 0xa0fc
loc_187be 99 fd                            .short 0x99fd
loc_187c0 3e 46                            movea.w d6,sp
loc_187c2 46 c1                            move.w  d1,sr
loc_187c4 fa 3e                            .short 0xfa3e
loc_187c6 41 07                            chkl d7,d0
loc_187c8 e4 cf                            .short 0xe4cf
loc_187ca d1 a4                            add.l d0,(a4)-
loc_187cc 8f e1                            divsw (a1)-,d7
loc_187ce fd 87                            .short 0xfd87
loc_187d0 0e 1c                            .short 0x0e1c
loc_187d2 2d 00                            move.l  d0,(a6)-
loc_187d4: 01 2f 80 05                      btst d0,(sp)(-32763)
loc_187d8 14 15                            move.b  (a5),d2
loc_187da 0e 24                            .short 0x0e24
loc_187dc 06 34 04 45 0b 55                addi.b #69,(a4)@0)
loc_187e2 0a 66 2f 73                      eori.w #12147,(a6)-
loc_187e6 00 81 06 31 17 71                ori.l #103880561,d1
loc_187ec 28 f5 82 05                      move.l  (a5)5,a0.w:2),(a4)+
loc_187f0 0f 16                            btst d7,(a6)
loc_187f2 35 28 f4 83                      move.w  (a0)(-2941),(a2)-
loc_187f6 06 2e 18 eb 84 05                addi.b #-21,(a6)(-31739)
loc_187fc 11 16                            move.b  (a6),(a0)-
loc_187fe 34 28 ee 85                      move.w  (a0)(-4475),d2
loc_18802 04 03 16 30                      subi.b #$30,d3
loc_18806 28 ea 86 04                      move.l  (a2)(-31228),(a4)+
loc_1880a 02 15 13 27                      andi.b  #39,(a5)
loc_1880e 6e 38                            bgt.s   loc_18848
loc_18810 f2 48                            .short 0xf248
loc_18812 ef 87                            asl.l #7,d7
loc_18814 08 ed 18 f3 88 07                bset    #-13,(a5)(-30713)
loc_1881a 72 89                            moveq   #-119,d1
loc_1881c 05 16                            btst d2,(a6)
loc_1881e 17 70 8a 05 10 17                move.b  (a0)5,a0:l:2),(a3)(4119)
loc_18824 73 8b                            .short 0x738b
loc_18826 05 12                            btst d2,(a2)
loc_18828 18 f0 8c 06                      move.b  (a0)6,a0:l:4),(a4)+
loc_1882c 2a 16                            move.l  (a6),d5
loc_1882e 36 27                            move.w -(sp),d3
loc_18830 74 8d                            moveq   #-115,d2
loc_18832 06 33 8e 06 32 17                addi.b #6,(a3)(0000000000000017,d3.w:2)
loc_18838 6f 28                            ble.s   loc_18862
loc_1883a f1 8f                            .short 0xf18f
loc_1883c 06 2b 18 ec 28 f6                addi.b #-20,(a3)(10486)
loc_18842 ff 01                            .short 0xff01
loc_18844 5c 53                            addq.w  #6,(a3)
loc_18846 f6 2c                            .short 0xf62c
loc_18848 ff d8                            .short 0xffd8
loc_1884a b3 f1 e0 f6                      cmpal (a1)(fffffffffffffff6,a6.w),a1
loc_1884e 87 2e 1c 9b                      or.b d3,(a6)(7323)
loc_18852 b7 95                            eor.l d3,(a5)
loc_18854 a1 c9                            .short 0xa1c9
loc_18856 bc f1 d1 b9 3c a2 f6 e5          cmpa.w @(000000003ca2f6e5,a5.w)@0),a6
loc_1885e a9 1b                            .short 0xa91b
loc_18860 6b 8f                            bmi.s   loc_187f1
loc_18862 06 d7                            .short 0x06d7
loc_18864 1e 08                            .short 0x1e08
loc_18866 fc 4e                            .short 0xfc4e
loc_18868 cb 79 3d 5c 80 a3                and.w d5,0x3d5c80a3
loc_1886e dc f4 c7 55                      adda.w (a4)@0),a6
loc_18872 f1 d5                            .short 0xf1d5
loc_18874 38 6a 9c 39                      movea.w (a2)(-25543),a4
loc_18878 41 21                            chkl (a1)-,d0
loc_1887a 6e 5d                            bgt.s   loc_188d9
loc_1887c a9 1c                            .short 0xa91c
loc_1887e 7c d2                            moveq   #-46,d6
loc_18880 24 fe                            .short 0x24fe
loc_18882 48 5a                            .short 0x485a
loc_18884 f2 4b                            .short 0xf24b
loc_18886 63 aa                            bls.s   loc_18832
loc_18888 5b 1d                            subq.b  #5,(a5)+
loc_1888a 50 f5 59 3d 5c 80 01 7c          st (a5)(000000005c80017c)@0,d5:l)
loc_18892 53 f6 2c ff                      sls (a6)(ffffffffffffffff,d2:l:4)
loc_18896 d8 b3 ff 62 d0 e5 c3 93          add.l (a3)(ffffffffffffd0e5)@(ffffffffffffc393),d4
loc_1889e 76 f2                            moveq   #-14,d3
loc_188a0 b4 39 37 9b f4 4d                cmp.b 0x379bf44d,d2
loc_188a6 74 4d                            moveq   #77,d2
loc_188a8 4b 93                            chkw (a3),d5
loc_188aa 6b 8f                            bmi.s   loc_1883b
loc_188ac 06 d7                            .short 0x06d7
loc_188ae 1e 08                            .short 0x1e08
loc_188b0 f3 c6                            .short 0xf3c6
loc_188b2 cb 2d 40 0f                      and.b d5,(a5)(16399)
loc_188b6 73 d3                            .short 0x73d3
loc_188b8 1d 57 ea f4                      move.b  (sp),(a6)(-5388)
loc_188bc e3 aa                            lsl.l d1,d2
loc_188be 70 e5                            moveq   #-27,d0
loc_188c0 04 85 b9 76 a4 5f                subi.l #-1183407009,d5
loc_188c6 e6 91                            roxrl #3,d1
loc_188c8 d5 65                            add.w   d2,(a5)-
loc_188ca aa ed                            .short 0xaaed
loc_188cc 8e a9 6c 75                      orl (a1)(27765),d7
loc_188d0 4c 4d                            .short 0x4c4d
loc_188d2 eb 79                            rol.w d5,d1
loc_188d4 00 00 4d 51                      ori.b #81,d0
loc_188d8 fe ac                            .short 0xfeac
loc_188da fc 6d                            .short 0xfc6d
loc_188dc c5 b9 3f d5 b9 7e                and.l   d2,0x3fd5b97e
loc_188e2 c9 a1                            and.l   d4,(a1)-
loc_188e4 ae 3c                            .short 0xae3c
loc_188e6 9b b7 f3 18                      sub.l d5,(sp,sp.w:2)
loc_188ea c5 3d                            .short 0xc53d
loc_188ec 62 d8                            bhi.s   loc_188c6
loc_188ee ea 5c                            ror.w #5,d4
loc_188f0 99 e6                            suba.l (a6)-,a4
loc_188f2 fe 0c                            .short 0xfe0c
loc_188f4 f3 2e 2a d4                      fsave (a6)(10964)
loc_188f8 00 1e e7 a6                      ori.b #-90,(a6)+
loc_188fc 3a af 8e b6                      move.w  (sp)(-29002),(a5)
loc_18900 6c 75                            bge.s   loc_18977
loc_18902 e4 9e                            ror.l #2,d6
loc_18904 9c 93                            sub.l (a3),d6
loc_18906 1d 60 98 fe                      move.b  (a0)-,(a6)(-26370)
loc_1890a 63 b5                            bls.s   loc_188c1
loc_1890c 3d 56 5a e2                      move.w  (a6),(a6)(23266)
loc_18910 96 c1                            subaw d1,a3
loc_18912 e9 8c                            lsl.l #4,d4
loc_18914 de 8f                            add.l sp,d7
loc_18916 00 06 b0 a6                      ori.b #-90,d6
loc_1891a a8 ff                            .short 0xa8ff
loc_1891c 56 e5                            sne (a5)-
loc_1891e fb 16                            .short 0xfb16
loc_18920 e4 ff                            .short 0xe4ff
loc_18922 56 87                            addq.l #3,d7
loc_18924 ec 9b                            ror.l #6,d3
loc_18926 b7 f6 2d c7 5c 5b 1f 48          cmpal @0)@(000000005c5b1f48),a3
loc_1892e a6 05                            .short 0xa605
loc_18930 c9 30 e0 93                      and.b d4,(a0)(ffffffffffffff93,a6.w)
loc_18934 e2 bf                            ror.l d1,d7
loc_18936 46 b0 01 1e ee 49                notl (a0)@(ffffffffffffee49,d0.w)
loc_1893c 8e ab e2 fe                      orl (a3)(-7426),d7
loc_18940 49 8e                            .short 0x498e
loc_18942 bc 93                            cmp.l (a3),d6
loc_18944 d2 09                            .short 0xd209
loc_18946 8f e6                            divsw (a6)-,d7
loc_18948 3b 51 fc 57                      move.w  (a1),(a5)(-937)
loc_1894c e9 8d                            lsl.l #4,d5
loc_1894e 2c e2                            move.l  (a2)-,(a6)+
loc_18950 f4 4b                            .short 0xf44b
loc_18952 6a bc                            bpl.s   loc_18910
loc_18954 48 d6 f0 00                      movem.l a4-sp,(a6)
loc_18958 00 05 f1 47                      ori.b #71,d5
loc_1895c fa b5                            .short 0xfab5
loc_1895e cf c6                            mulsw d6,d7
loc_18960 cf 6e be 17                      and.w d7,(a6)(-16873)
loc_18964 37 5d a1 73                      move.w  (a5)+,(a3)(-24205)
loc_18968 42 eb                            .short 0x42eb
loc_1896a 42 e6                            .short 0x42e6
loc_1896c f3 c7                            .short 0xf3c7
loc_1896e 46 f3 ee 4c                      move.w  (a3)(000000000000004c,a6:l:8),sr
loc_18972 5f 85                            subql #7,d5
loc_18974 ef 5e                            rol.w #7,d6
loc_18976 2f b3 7a f0 6b b8 f0 47 f1 b2    move.l  (a3)(fffffffffffffff0,d7:l:2),@(fffffffff047f1b2,d6:l:2)
loc_18980 ee c5                            .short 0xeec5
loc_18982 ea 25                            asrb d5,d5
loc_18984 c4 c8                            .short 0xc4c8
loc_18986 00 00 14 7b                      ori.b #123,d0
loc_1898a 9e 98                            sub.l (a0)+,d7
loc_1898c ea bb                            ror.l d5,d3
loc_1898e 62 fb                            bhi.s   loc_1898b
loc_18990 93 87                            subxl d7,d1
loc_18992 5a 42                            addq.w  #5,d2
loc_18994 dd 69 0b 5d                      add.w   d6,(a1)(2909)
loc_18998 04 8e                            .short 0x048e
loc_1899a 3e 69 87 9a                      movea.w (a1)(-30822),sp
loc_1899e 13 f1 0b 7e 2a b7 aa 5b 8d c9 c5 eb 7d ca  move.b  (a1)(000000002ab7aa5b)@(ffffffffffff8dc9),0xc5eb7dca
loc_189ac 2b cb                            .short 0x2bcb
loc_189ae 00 1c fe 28                      ori.b #$28,(a4)+
loc_189b2 ff 56                            .short 0xff56
loc_189b4 bb 1b                            eor.b d5,(a3)+
loc_189b6 3e cd                            move.w  a5,(sp)+
loc_189b8 77 0b                            .short 0x770b
loc_189ba ac d7                            .short 0xacd7
loc_189bc 5a 17                            addq.b  #5,(sp)
loc_189be 41 ae b4 2e                      chkw (a6)(-19410),d0
loc_189c2 83 79 f7 37 6f ed                or.w d1,0xf7376fed
loc_189c8 13 18                            move.b  (a0)+,(a1)-
loc_189ca dc 6a 2a 92                      add.w (a2)(10898),d6
loc_189ce ea 71                            roxrw d5,d1
loc_189d0 6e be                            bgt.s   loc_18990
loc_189d2 2f 4e 3a b5                      move.l  a6,(sp)(15029)
loc_189d6 de 8a                            add.l a2,d7
loc_189d8 78 76                            moveq   #118,d4
loc_189da 2f a3 d3 1d                      move.l  (a3)-,(sp)@0,a5.w:2)
loc_189de 57 6c 5f 72                      subq.w  #3,(a4)(24434)
loc_189e2 70 eb                            moveq   #-21,d0
loc_189e4 4e 1d                            .short 0x4e1d
loc_189e6 69 c2                            bvss loc_189aa
loc_189e8 e8 24                            asrb d4,d4
loc_189ea 5f e7                            sle -(sp)
loc_189ec 4b 9c                            chkw (a4)+,d5
loc_189ee 71 f3                            .short 0x71f3
loc_189f0 7d ce                            .short 0x7dce
loc_189f2 b9 f8 bf ae                      cmpal ($FFFFbfae,a4
loc_189f6 78 fe                            moveq   #-2,d4
loc_189f8 a7 1b                            .short 0xa71b
loc_189fa a8 4f                            .short 0xa84f
loc_189fc c7 f5 38 cd                      mulsw (a5)(ffffffffffffffcd,d3:l),d3
loc_18a00 f8 fe                            .short 0xf8fe
loc_18a02 a7 1a                            .short 0xa71a
loc_18a04 47 d3                            lea     (a3),a3
loc_18a06 d6 91                            add.l (a1),d3
loc_18a08 85 df                            divsw (sp)+,d2
loc_18a0a b2 d2                            cmpa.w (a2),a1
loc_18a0c ee 6f                            lsr.w d7,d7
loc_18a0e b9 d1                            cmpal (a1),a4
loc_18a10 00 00 d7 07                      ori.b #7,d0
loc_18a14 dc fc 52 e7                      adda.w #21223,a6
loc_18a18 e3 66                            asl.w d1,d6
loc_18a1a bb 5e                            eor.w d5,(a6)+
loc_18a1c 2d 77 a6 2d 77 a5                move.l  (sp)(000000000000002d,a2.w:8),(a6)(30629)
loc_18a22 cd 77 ec 9a                      and.w d6,(sp)(ffffffffffffff9a,a6:l:4)
loc_18a26 ef 4e                            lsl.w   #7,d6
loc_18a28 d4 bb 5e d5                      add.l (pc)(loc_189ff,d5:l:8),d2
loc_18a2c dd a8 bd ea                      add.l d6,(a0)(-16918)
loc_18a30 b9 e9 d7 8b                      cmpal (a1)(-10357),a4
loc_18a34 d3 d5                            adda.l (a5),a1
loc_18a36 eb d7                            .short 0xebd7
loc_18a38 15 3f                            .short 0x153f
loc_18a3a 1b cd                            .short 0x1bcd
loc_18a3c 58 00                            addq.b  #4,d0
loc_18a3e 00 18 ea be                      ori.b #-66,(a0)+
loc_18a42 3a a6                            move.w  (a6)-,(a5)
loc_18a44 37 63 67 b7                      move.w  (a3)-,(a3)(26551)
loc_18a48 5f 0b                            subq.b  #7,a3
loc_18a4a 9b ae d0 b9                      sub.l d5,(a6)(-12103)
loc_18a4e ba ed 0b 9b                      cmpa.w (a5)(2971),a5
loc_18a52 b7 58                            eor.w d3,(a0)+
loc_18a54 a7 6e                            .short 0xa76e
loc_18a56 a5 16                            .short 0xa516
loc_18a58 d6 69 ca fe                      add.w (a1)(-13570),d3
loc_18a5c 2a c7                            move.l  d7,(a5)+
loc_18a5e 82 f1 e0 bc                      divu.w (a1)(ffffffffffffffbc,a6.w),d1
loc_18a62 6d 8a                            blt.s   loc_189ee
loc_18a64 f8 ab                            .short 0xf8ab
loc_18a66 19 85 e0 00                      move.b  d5,(a4,a6.w)
loc_18a6a 00 52 e0 fb                      ori.w #-7941,(a2)
loc_18a6e 9f 8a                            subxl (a2)-,-(sp)
loc_18a70 5c fe                            .short 0x5cfe
loc_18a72 2d 76 b8 d9 ae f4                move.l  (a6)(ffffffffffffffd9,a3:l),(a6)(-20748)
loc_18a78 c5 ae f4 b9                      and.l   d2,(a6)(-2887)
loc_18a7c ae fd                            .short 0xaefd
loc_18a7e 93 5d                            sub.w   d1,(a5)+
loc_18a80 e9 da                            .short 0xe9da
loc_18a82 97 6b da bb                      sub.w   d3,(a3)(-9541)
loc_18a86 b5 17                            eor.b d2,(sp)
loc_18a88 bd 5a                            eor.w d6,(a2)+
loc_18a8a ae e7                            .short 0xaee7
loc_18a8c e2 b7                            roxrl d1,d7
loc_18a8e db 15                            add.b d5,(a5)
loc_18a90 dc fc 57 d4                      adda.w #22484,a6
loc_18a94 00 00 01 8e                      ori.b #-114,d0
loc_18a98 ab e3                            .short 0xabe3
loc_18a9a aa 63                            .short 0xaa63
loc_18a9c 73 ec                            .short 0x73ec
loc_18a9e f6 eb                            .short 0xf6eb
loc_18aa0 e1 73                            roxlw d0,d3
loc_18aa2 75 da                            .short 0x75da
loc_18aa4 17 37 5d a1 73 76                move.b @(0000000000007376,d5:l:4)@0),(a3)-
loc_18aaa be d0                            cmpa.w (a0),sp
loc_18aac 4e dd                            .short 0x4edd
loc_18aae 62 9a                            bhi.s   loc_18a4a
loc_18ab0 ce 2d ca fe                      and.b (a5)(-13570),d7
loc_18ab4 2a c6                            move.l  d6,(a5)+
loc_18ab6 d8 af f5 2b                      add.l (sp)(-2773),d4
loc_18aba c6 d8                            mulu.w (a0)+,d3
loc_18abc af 8a                            .short 0xaf8a
loc_18abe b1 2b c9 5e                      eor.b d0,(a3)(-13986)
loc_18ac2 41 dc                            .short 0x41dc
loc_18ac4 51 fe                            .short 0x51fe
loc_18ac6 ad 73                            .short 0xad73
loc_18ac8 f1 b6                            .short 0xf1b6
loc_18aca 2d d7                            .short 0x2dd7
loc_18acc c2 e6                            mulu.w (a6)-,d1
loc_18ace eb b4                            roxl.l d5,d4
loc_18ad0 2e 68 5d 68                      movea.l (a0)(23912),sp
loc_18ad4 5c de                            sge (a6)+
loc_18ad6 6f d1                            ble.s   loc_18aa9
loc_18ad8 bc fb 91 f7 60 a7 e2 be 36 67 f1 e0  cmpa.w %z(pc)(0000000060a7e2be)@(000000003667f1e0),a6
loc_18ae4 d7 3f                            .short 0xd73f
loc_18ae6 8d 93                            orl d6,(a3)
loc_18ae8 4e 29                            .short 0x4e29
loc_18aea 3e b5 dc e7                      move.w  (a5)(ffffffffffffffe7,a5:l:4),(sp)
loc_18aee ba e4                            cmpa.w (a4)-,a5
loc_18af0 c7 55                            and.w d3,(a5)
loc_18af2 db 17                            add.b d5,(sp)
loc_18af4 dc 9c                            add.l (a4)+,d6
loc_18af6 3a d2                            move.w  (a2),(a5)+
loc_18af8 16 eb 48 5a                      move.b  (a3)(18522),(a3)+
loc_18afc e8 24                            asrb d4,d4
loc_18afe 5f e6                            sle (a6)-
loc_18b00 98 79 a1 5c f5 be                sub.w 0xa15cf5be,d4
loc_18b06 fe 2a                            .short 0xfe2a
loc_18b08 b7 17                            eor.b d3,(sp)
loc_18b0a a7 17                            .short 0xa717
loc_18b0c dc 98                            add.l (a0)+,d6
loc_18b0e e8 bb                            ror.l d4,d3
loc_18b10 a6 ab                            .short 0xa6ab
loc_18b12 82 71 47 fa b5 cf c6 d8 b7 5f    or.w @(ffffffffb5cfc6d8)@(ffffffffffffb75f),d1
loc_18b1c 0b 9b                            bclr d5,(a3)+
loc_18b1e ae d0                            .short 0xaed0
loc_18b20 b9 a1                            eor.l d4,(a1)-
loc_18b22 75 a1                            .short 0x75a1
loc_18b24 73 79                            .short 0x7379
loc_18b26 e3 a3                            asl.l d1,d3
loc_18b28 79 e9                            .short 0x79e9
loc_18b2a 04 c5                            .short 0x04c5
loc_18b2c f8 2b                            .short 0xf82b
loc_18b2e 8a f1 e0 98                      divu.w (a1)(ffffffffffffff98,a6.w),d5
loc_18b32 dd c1                            adda.l  d1,a6
loc_18b34 1f 76 36 4b b4 7a                move.b  (a6)(000000000000004b,d3.w:8),(sp)(-19334)
loc_18b3a e7 70                            roxlw d3,d0
loc_18b3c 7d 2e                            .short 0x7d2e
loc_18b3e 5e 3a                            .short 0x5e3a
loc_18b40 ae d8                            .short 0xaed8
loc_18b42 be e4                            cmpa.w (a4)-,sp
loc_18b44 e1 d6                            asl.w (a6)
loc_18b46 90 b7 5a 42                      sub.l (sp)(0000000000000042,d5:l:2),d0
loc_18b4a d7 41                            addxw d1,d3
loc_18b4c 23 8f 9a 61                      move.l sp,(a1)(0000000000000061,a1:l:2)
loc_18b50 e6 84                            asr.l #3,d4
loc_18b52 fc 57                            .short 0xfc57
loc_18b54 8d f6 c5 56 bb 15                divsw (a6)@(ffffffffffffbb15),d6
loc_18b5a e3 73                            roxlw d1,d3
loc_18b5c d7 a5                            add.l d3,(a5)-
loc_18b5e cb 98                            and.l   d5,(a0)+
loc_18b60 00 25 c1 f7                      ori.b #-9,(a5)-
loc_18b64 dc cf                            adda.w sp,a6
loc_18b66 c6 97                            and.l (sp),d3
loc_18b68 3d cf                            .short 0x3dcf
loc_18b6a e3 d6                            lsl.w (a6)
loc_18b6c f7 3f                            .short 0xf73f
loc_18b6e d6 e7                            adda.w -(sp),a3
loc_18b70 b9 fe                            .short 0xb9fe
loc_18b72 b7 3e                            .short 0xb73e
loc_18b74 97 6b ea fb                      sub.w   d3,(a3)(-5381)
loc_18b78 9f c5                            suba.l d5,sp
loc_18b7a f8 bd                            .short 0xf8bd
loc_18b7c b1 b6 3e 8e                      eor.l d0,(a6)(ffffffffffffff8e,d3:l:8)
loc_18b80 8d de                            divsw (a6)+,d6
loc_18b82 ae d2                            .short 0xaed2
loc_18b84 e5 69                            lsl.w d2,d1
loc_18b86 7e e0                            moveq   #-32,d7
loc_18b88 03 ae 7f 1d                      bclr d1,(a6)(32541)
loc_18b8c 5c fc                            .short 0x5cfc
loc_18b8e 6d c7                            blt.s   loc_18b57
loc_18b90 5a 3f                            .short 0x5a3f
loc_18b92 d6 ec 6d e9                      adda.w (a4)(28137),a3
loc_18b96 8f 5f                            or.w d7,(sp)+
loc_18b98 0b b5 fd 1d                      bclr d5,(a5)@0,sp:l:4)
loc_18b9c a1 77                            .short 0xa177
loc_18b9e a7 5d                            .short 0xa75d
loc_18ba0 a1 76                            .short 0xa176
loc_18ba2 be 7a c6 9a                      cmp.w (pc)(loc_1523e),d7
loc_18ba6 f9 ea                            .short 0xf9ea
loc_18ba8 51 fe                            .short 0x51fe
loc_18baa 14 c0                            move.b  d0,(a2)+
loc_18bac 00 5f 70 7d                      ori.w #28797,(sp)+
loc_18bb0 f7 2a                            .short 0xf72a
loc_18bb2 e7 aa                            lsl.l d3,d2
loc_18bb4 e7 dc                            rol.w (a4)+
loc_18bb6 bb 9f                            eor.l d5,(sp)+
loc_18bb8 73 e9                            .short 0x73e9
loc_18bba ad 2e                            .short 0xad2e
loc_18bbc 7d da                            .short 0x7dda
loc_18bbe f1 7d                            .short 0xf17d
loc_18bc0 cf 76 3f b2 6e 3e 98 b8 f8 fa    and.w d7,@(000000006e3e98b8,d3:l:8)@(fffffffffffff8fa)
loc_18bca 53 42                            subq.w  #1,d2
loc_18bcc a7 17                            .short 0xa717
loc_18bce d2 24                            add.b (a4)-,d1
loc_18bd0 ee bc                            ror.l d7,d4
loc_18bd2 69 12                            bvss loc_18be6
loc_18bd4 6b 80                            bmi.s   loc_18b56
loc_18bd6 14 b9 fc 75 73 f1                move.b 0xfc7573f1,(a2)
loc_18bdc b7 1d                            eor.b d3,(a5)+
loc_18bde 68 ff                            bvcs loc_18bdf
loc_18be0 5b b1 b7 a6 3d 7c 2e d7          subql #5,@(0000000000003d7c)@(0000000000002ed7,a3.w:8)
loc_18be8 f4 76                            .short 0xf476
loc_18bea 85 de                            divsw (a6)+,d2
loc_18bec 9d 76 85 da f9 eb                sub.w   d6,@0)@(fffffffffffff9eb)
loc_18bf2 1a 6b                            .short 0x1a6b
loc_18bf4 e7 a9                            lsl.l d3,d1
loc_18bf6 47 1f                            chkl (sp)+,d3
loc_18bf8 d9 4c                            addxw (a4)-,(a4)-
loc_18bfa 0a 3e                            .short 0x0a3e
loc_18bfc fc 40                            .short 0xfc40
loc_18bfe 00 05 e0 b3                      ori.b #-77,d5
loc_18c02 b1 ac e0 6b                      eor.l d0,(a4)(-8085)
loc_18c06 3d 17                            move.w  (sp),(a6)-
loc_18c08 84 92                            orl (a2),d2
loc_18c0a 26 46                            movea.l d6,a3
loc_18c0c df b4 36 2e                      add.l d7,(a4)(000000000000002e,d3.w:8)
loc_18c10 a8 a7                            .short 0xa8a7
loc_18c12 54 55                            addq.w  #2,(a5)
loc_18c14 3b ce                            .short 0x3bce
loc_18c16 f2 00 0c 15                      flog10x a63,a60
loc_18c1a 6c 17                            bge.s   loc_18c33
loc_18c1c 08 9a f4 35                      bclr    #53,(a2)+
loc_18c20 c7 05                            abcd d5,d3
loc_18c22 99 1e                            sub.b d4,(a6)+
loc_18c24 8c 7f                            .short 0x8c7f
loc_18c26 c4 74 7f 6a 4e 8f ed 5b          and.w (a4)(0000000000004e8f)@(ffffffffffffed5b),d2
loc_18c2e 02 bc                            .short 0x02bc
loc_18c30 ef 20                            aslb d7,d0
loc_18c32 00 0d                            .short loc_d
loc_18c34 82 ce                            .short 0x82ce
loc_18c36 c6 b3 81 ac f4 5e                and.l @(fffffffffffff45e)@0,a0.w),d3
loc_18c3c 12 59                            .short 0x1259
loc_18c3e 91 a4                            sub.l d0,(a4)-
loc_18c40 7a 92                            moveq   #-110,d5
loc_18c42 26 51                            movea.l (a1),a3
loc_18c44 4c 0a                            .short 0x4c0a
loc_18c46 2a 32 bc 80                      move.l  (a2)(ffffffffffffff80,a3:l:4),d5
loc_18c4a 00 60 ab 60                      ori.w #-21664,(a0)-
loc_18c4e b8 44                            cmp.w   d4,d4
loc_18c50 d7 a1                            add.l d3,(a1)-
loc_18c52 ae 38                            .short 0xae38
loc_18c54 2c cb                            move.l  a3,(a6)+
loc_18c56 04 fd                            .short 0x04fd
loc_18c58 ac 5a                            .short 0xac5a
loc_18c5a 3d 51 68 99                      move.w  (a1),(a6)(26777)
loc_18c5e 60 c6                            bra.s   loc_18c26
loc_18c60 47 79                            .short 0x4779
loc_18c62 00 00 08 6a                      ori.b #106,d0
loc_18c66 c1 58                            and.w d0,(a0)+
loc_18c68 2b 06                            move.l  d6,(a5)-
loc_18c6a 8e 04                            or.b d4,d7
loc_18c6c 6d fb                            blt.s   loc_18c69
loc_18c6e 42 6e e3 26                      clr.w   (a6)(-7386)
loc_18c72 c3 43                            exg d1,d3
loc_18c74 4f da                            .short 0x4fda
loc_18c76 a8 c9                            .short 0xa8c9
loc_18c78 51 3b                            .short 0x513b
loc_18c7a e2 00                            asrb #1,d0
loc_18c7c 1d 4b                            .short 0x1d4b
loc_18c7e d2 c6                            adda.w d6,a1
loc_18c80 91 b4 0d 34 b1 45 b0 28          sub.l d0,(a4)(ffffffffb145b028)@0,d0:l:4)
loc_18c88 a6 0a                            .short 0xa60a
loc_18c8a d0 d6                            adda.w (a6),a0
loc_18c8c 71 35                            .short 0x7135
loc_18c8e e0 a2                            asr.l d0,d2
loc_18c90 17 98 00 05                      move.b  (a0)+,(a3)5,d0.w)
loc_18c94 1a b0 56 0a                      move.b  (a0)a,d5.w:8),(a5)
loc_18c98 c1 66                            and.w d0,(a6)-
loc_18c9a 46 b8 99 21                      notl ($FFFF9921
loc_18c9e e8 68                            lsr.w d4,d0
loc_18ca0 7a 1a                            moveq   #26,d5
loc_18ca2 ce 26                            and.b (a6)-,d7
loc_18ca4 b2 32 51 80                      cmp.b @0,d5.w),d1
loc_18ca8 00 a7 52 f4 b1 a4                ori.l #1391767972,-(sp)
loc_18cae 6d 03                            blt.s   loc_18cb3
loc_18cb0 4d 2c 46 d8                      chkl (a4)(18136),d6
loc_18cb4 14 50                            .short 0x1450
loc_18cb6 c9 47                            exg d4,d7
loc_18cb8 13 59 c4 d6                      move.b  (a1)+,(a1)(-15146)
loc_18cbc 71 51                            .short 0x7151
loc_18cbe 00 00 01 46                      ori.b #70,d0
loc_18cc2 ac 15                            .short 0xac15
loc_18cc4 82 b0 bc d0                      orl (a0)(ffffffffffffffd0,a3:l:4),d1
loc_18cc8 e3 82                            asl.l #1,d2
loc_18cca 17 72 1e 86 b2 c1                move.b  (a2)(ffffffffffffff86,d1:l:8),(a3)(-19775)
loc_18cd0 3c 08                            move.w  a0,d6
loc_18cd2 ef 35                            roxlb d7,d5
loc_18cd4 68 00 1d 4b                      bvcw loc_1aa21
loc_18cd8 d2 c6                            adda.w d6,a1
loc_18cda 91 b4 0d 34 b1 26 04 71          sub.l d0,(a4)(ffffffffb1260471)@0,d0:l:4)
loc_18ce2 63 25                            bls.s   loc_18d09
loc_18ce4 1c 4d                            .short 0x1c4d
loc_18ce6 7a 1a                            moveq   #26,d5
loc_18ce8 f0 51                            .short 0xf051
loc_18cea 0b cc 00 02                      movepl d5,(a4)(2)
loc_18cee 8d 58                            or.w d6,(a0)+
loc_18cf0 2b 05                            move.l  d5,(a5)-
loc_18cf2 61 79                            bsr.s   loc_18d6d
loc_18cf4 a7 ed                            .short 0xa7ed
loc_18cf6 50 fb                            .short 0x50fb
loc_18cf8 90 b4 35 f5 28 8d 71 39          sub.l @(00000000288d7139)@0),d0
loc_18d00 2a 60                            movea.l (a0)-,a5
loc_18d02 01 d4                            bset d0,(a4)
loc_18d04 bd 2c 69 1b                      eor.b d6,(a4)(26907)
loc_18d08 40 d3                            move.w sr,(a3)
loc_18d0a 4b 12                            chkl (a2),d5
loc_18d0c 60 47                            bra.s   loc_18d55
loc_18d0e 16 32 51 c4                      move.b @0)@0),d3
loc_18d12 d7 a1                            add.l d3,(a1)-
loc_18d14 af 05                            .short 0xaf05
loc_18d16 10 00                            move.b  d0,d0
loc_18d18 00 00 51 de                      ori.b #-34,d0
loc_18d1c 77 92                            .short 0x7792
loc_18d1e fa 90                            .short 0xfa90
loc_18d20 fb 90                            .short 0xfb90
loc_18d22 b4 35 f5 2a 6b c0 af 90          cmp.b (a5)(0000000000006bc0,sp.w:4)@(ffffffffffffaf90),d2
loc_18d2a 00 0f                            .short loc_f
loc_18d2c da a1                            add.l (a1)-,d5
loc_18d2e e9 63                            asl.w d4,d3
loc_18d30 63 8d                            bls.s   loc_18cbf
loc_18d32 a0 6c                            .short 0xa06c
loc_18d34 7a 58                            moveq   #$58,d5
loc_18d36 a2 e2                            .short 0xa2e2
loc_18d38 c0 90                            and.l (a0),d0
loc_18d3a e2 4b                            lsr.w   #1,d3
loc_18d3c d0 d7                            adda.w (sp),a0
loc_18d3e d4 b2 35 4a ff 00                add.l (a2)@(ffffffffffffff00),d2
loc_18d44 00 14 fd ab                      ori.b #-85,(a4)
loc_18d48 61 68                            bsr.s   loc_18db2
loc_18d4a e0 e3                            asrw (a3)-
loc_18d4c b4 34 83 8e 36 89                cmp.b @0)@(0000000000003689,a0.w:2),d2
loc_18d52 1b b0 8f 81 b8 8e                move.b @0,a0:l:8)@0),(a5)(ffffffffffffff8e,a3:l)
loc_18d58 24 6e 38 e1                      movea.l (a6)(14561),a2
loc_18d5c 12 3a 68 7a                      move.b  (pc)(loc_1f5d8),d1
loc_18d60 61 42                            bsr.s   loc_18da4
loc_18d62 fd a9                            .short 0xfda9
loc_18d64 45 c5                            .short 0x45c5
loc_18d66 81 26                            or.b d0,(a6)-
loc_18d68 14 92                            move.b  (a2),(a2)
loc_18d6a cf 49                            exg sp,a1
loc_18d6c 00 03 7e d5                      ori.b #-43,d3
loc_18d70 b0 d3                            cmpa.w (a3),a0
loc_18d72 07 1c                            btst d3,(a4)+
loc_18d74 34 81                            move.w  d1,(a2)
loc_18d76 b8 ed a5 8d                      cmpa.w (a5)(-23155),a4
loc_18d7a c7 19                            and.b d3,(a1)+
loc_18d7c 14 49                            .short 0x1449
loc_18d7e 8b 02                            sbcd d2,d5
loc_18d80 43 d0                            lea     (a0),a1
loc_18d82 d8 ff                            .short 0xd8ff
loc_18d84 68 74                            bvcs loc_18dfa
loc_18d86 89 1e                            or.b d4,(a6)+
loc_18d88 86 51                            or.w (a1),d3
loc_18d8a 71 60                            .short 0x7160
loc_18d8c 48 6e 36 d0                      pea (a6)(14032)
loc_18d90 bb af aa b5                      eor.l d5,(sp)(-21835)
loc_18d94 6d 7e                            blt.s   loc_18e14
loc_18d96 69 9b                            bvss loc_18d33
loc_18d98 b3 5e                            eor.w d1,(a6)+
loc_18d9a 74 cd                            moveq   #-51,d2
loc_18d9c 3f 7c bf 15 f8 d5                move.w  #-16619,(sp)(-1835)
loc_18da2 7d 40                            .short 0x7d40
loc_18da4 53 35 66 af                      subq.b  #1,(a5)(ffffffffffffffaf,d6.w:8)
loc_18da8 15 ef                            .short 0x15ef
loc_18daa 56 f0 00 0d                      sne (a0)d,d0.w)
loc_18dae b2 aa ae a7                      cmp.l (a2)(-20825),d1
loc_18db2 66 ec                            bne.s   loc_18da0
loc_18db4 f6 a6                            .short 0xf6a6
loc_18db6 59 d3                            svs (a3)
loc_18db8 34 df                            move.w  (sp)+,(a2)+
loc_18dba 9a 7e                            .short 0x9a7e
loc_18dbc fb f3                            .short 0xfbf3
loc_18dbe ae fe                            .short 0xaefe
loc_18dc0 72 6f                            moveq   #111,d1
loc_18dc2 00 01 4c bd                      ori.b #-67,d1
loc_18dc6 93 f7 ca ae                      suba.l (sp)(ffffffffffffffae,a4:l:2),a1
loc_18dca a5 57                            .short 0xa557
loc_18dcc 52 ab a9 55                      addq.l #1,(a3)(-22187)
loc_18dd0 d4 aa ea 57                      add.l (a2)(-5545),d2
loc_18dd4 ef f2                            .short 0xeff2
loc_18dd6 5f 8a                            subql #7,a2
loc_18dd8 eb be                            roll d5,d6
loc_18dda bb eb be bb                      cmpal (a3)(-16709),a5
loc_18dde eb be                            roll d5,d6
loc_18de0 b0 00                            cmp.b d0,d0
loc_18de2 0e c9                            .short 0x0ec9
loc_18de4 59 76 2b 2e c5 d7 97 63          subq.w  #4,(a6)(ffffffffffffc5d7)@(ffffffffffff9763,d2:l:2)
loc_18dec 57 55                            subq.w  #3,(a5)
loc_18dee 79 57                            .short 0x7957
loc_18df0 95 2b aa b7                      sub.b d2,(a3)(-21833)
loc_18df4 65 4a                            bcs.s   loc_18e40
loc_18df6 ea ad                            lsrl d5,d5
loc_18df8 55 80                            subql #2,d0
loc_18dfa 00 77 ef 13 6d e9 b6 f4          ori.w #-4333,@(ffffffffffffb6f4)@0)
loc_18e02 db 7a                            .short 0xdb7a
loc_18e04 6d bd                            blt.s   loc_18dc3
loc_18e06 32 ab 7a ea                      move.w  (a3)(31466),(a1)
loc_18e0a de bf                            .short 0xdebf
loc_18e0c 6d 95                            blt.s   loc_18da3
loc_18e0e 95 79 6c d9 56 ea                sub.w   d2,0x6cd956ea
loc_18e14 9b 2a dd 53                      sub.b d5,(a2)(-8877)
loc_18e18 65 5d                            bcs.s   loc_18e77
loc_18e1a 2a 4f                            movea.l sp,a5
loc_18e1c 15 e5                            .short 0x15e5
loc_18e1e 7d 60                            .short 0x7d60
loc_18e20 01 56                            bchg d0,(a6)
loc_18e22 4b aa 9b d2                      chkw (a2)(-25646),d5
loc_18e26 a7 57                            .short 0xa757
loc_18e28 53 55                            subq.w  #1,(a5)
loc_18e2a 4a f2 d9 d9                      tas @0)@0)
loc_18e2e 57 e3                            seq (a3)-
loc_18e30 b5 3f                            .short 0xb53f
loc_18e32 9d d2                            suba.l (a2),a6
loc_18e34 bf 1e                            eor.b d7,(a6)+
loc_18e36 94 af 7f 46                      sub.l (sp)(32582),d2
loc_18e3a ec de                            .short 0xecde
loc_18e3c 00 01 d9 af                      ori.b #-81,d1
loc_18e40 6a d2                            bpl.s   loc_18e14
loc_18e42 aa 55                            .short 0xaa55
loc_18e44 9a 55                            sub.w (a5),d5
loc_18e46 4a b3 4a a9                      tst.l (a3)(ffffffffffffffa9,d4:l:2)
loc_18e4a 56 69 d3 35                      addq.w  #3,(a1)(-11467)
loc_18e4e d5 f9 d4 ab f5 b9                adda.l 0xd4abf5b9,a2
loc_18e54 54 aa ea 56                      addq.l #2,(a2)(-5546)
loc_18e58 55 2b 2a 95                      subq.b  #2,(a3)(10901)
loc_18e5c 95 4a                            subxw (a2)-,(a2)-
loc_18e5e ca a5                            and.l (a5)-,d5
loc_18e60 6f a9                            ble.s   loc_18e0b
loc_18e62 7e 35                            moveq   #53,d7
loc_18e64 00 03 aa 55                      ori.b #85,d3
loc_18e68 79 66                            .short 0x7966
loc_18e6a 95 65                            sub.w   d2,(a5)-
loc_18e6c 5d 4e                            subq.w  #6,a6
loc_18e6e db 2c f6 cb                      add.b d5,(a4)(-2357)
loc_18e72 6c b3                            bge.s   loc_18e27
loc_18e74 aa 95                            .short 0xaa95
loc_18e76 78 e7                            moveq   #-25,d4
loc_18e78 53 aa a6 59                      subql #1,(a2)(-22951)
loc_18e7c ed 4d                            lsl.w   #6,d5
loc_18e7e 9d 9d                            sub.l d6,(a5)+
loc_18e80 54 d9                            scc (a1)+
loc_18e82 2a 00                            move.l  d0,d5
loc_18e84 01 4f 14 fc                      movepl (sp)(5372),d0
loc_18e88 ee cd                            .short 0xeecd
loc_18e8a fa d5                            .short 0xfad5
loc_18e8c f4 a6                            .short 0xf4a6
loc_18e8e 6a cf                            bpl.s   loc_18e5f
loc_18e90 25 e7                            .short 0x25e7
loc_18e92 95 69 fa dc                      sub.w   d2,(a1)(-1316)
loc_18e96 93 f7 9e 2b                      suba.l (sp)(000000000000002b,a1:l:8),a1
loc_18e9a db f3 aa fd                      adda.l (a3)(fffffffffffffffd,a2:l:2),a5
loc_18e9e 6b 67                            bmi.s   loc_18f07
loc_18ea0 4e 8d                            .short 0x4e8d
loc_18ea2 96 6a af 2c                      sub.w (a2)(-20692),d3
loc_18ea6 d7 97                            add.l d3,(sp)
loc_18ea8 eb 53                            roxlw #5,d3
loc_18eaa f7 80                            .short 0xf780
loc_18eac 00 aa bf 3b 92 ea ce ac          ori.l #-1086614806,(a2)(-12628)
loc_18eb4 af ab                            .short 0xafab
loc_18eb6 2f ce                            .short 0x2fce
loc_18eb8 e5 f9 da 7e b7 2a                roxlw 0xda7eb72a
loc_18ebe f2 ce 95 67 56 79                fbnel 0xffffffff9568e539
loc_18ec4 57 93                            subql #3,(a3)
loc_18ec6 aa a5                            .short 0xaaa5
loc_18ec8 59 e5                            svs (a5)-
loc_18eca 9a ea fc e8                      subaw (a2)(-792),a5
loc_18ece 00 00 ac ff                      ori.b #-1,d0
loc_18ed2 78 99                            moveq   #-103,d4
loc_18ed4 f4 5e                            .short 0xf45e
loc_18ed6 7b 2f                            .short 0x7b2f
loc_18ed8 f5 ae                            .short 0xf5ae
loc_18eda af f9                            .short 0xaff9
loc_18edc cd fc f0 df                      mulsw #-3873,d6
loc_18ee0 ad 77                            .short 0xad77
loc_18ee2 4c e9 9b b6 fd eb                movem.l (a1)(-533),d1-d2/d4-d5/d7-a1/a3-a4/sp
loc_18ee8 aa cd                            .short 0xaacd
loc_18eea 5f 9d                            subql #7,(a5)+
loc_18eec 57 ef ab 6f                      seq (sp)(-21649)
loc_18ef0 df 80                            addxl d0,d7
loc_18ef2 bf ce                            cmpal a6,sp
loc_18ef4 af 37                            .short 0xaf37
loc_18ef6 66 99                            bne.s   loc_18e91
loc_18ef8 d3 35 7e 76                      add.b d1,(a5)(0000000000000076,d7:l:8)
loc_18efc a5 67                            .short 0xa567
loc_18efe b3 65                            eor.w d1,(a5)-
loc_18f00 4c fa 3a bc b3 fd                movem.l (pc)(loc_14301),d2-d5/d7/a1/a3-a5
loc_18f06 e3 ab                            lsl.l d1,d3
loc_18f08 cb f9 ae af 2b eb                mulsw 0xaeaf2beb,d5
loc_18f0e ca fa c0 02                      mulu.w (pc)(loc_14f12),d5
loc_18f12 ba 95                            cmp.l (a5),d5
loc_18f14 d9 55                            add.w   d4,(a5)
loc_18f16 f9 df                            .short 0xf9df
loc_18f18 92 b2 ad 79 56 ac ab 56          sub.l (a2)(0000000056acab56)@0),d1
loc_18f20 55 ba                            .short 0x55ba
loc_18f22 aa d7                            .short 0xaad7
loc_18f24 57 62                            subq.w  #3,(a2)-
loc_18f26 f3 bf                            .short 0xf3bf
loc_18f28 2b eb                            .short 0x2beb
loc_18f2a ca fa f2 55                      mulu.w (pc)(loc_18181),d5
loc_18f2e 79 2a                            .short 0x792a
loc_18f30 bc 80                            cmp.l   d0,d6
loc_18f32 00 52 ba 95                      ori.w #-17771,(a2)
loc_18f36 5d 4d                            subq.w  #6,a5
loc_18f38 e3 f9 dd b7 f6 65                lsl.w 0xddb7f665
loc_18f3e 9f 66                            sub.w   d7,(a6)-
loc_18f40 55 d3                            scs (a3)
loc_18f42 b3 27                            eor.b d1,-(sp)
loc_18f44 56 d5                            sne (a5)
loc_18f46 e4 ba                            ror.l d2,d2
loc_18f48 f7 a5                            .short 0xf7a5
loc_18f4a 7b c0                            .short 0x7bc0
loc_18f4c 00 3b                            .short 0x003b
loc_18f4e 35 f6                            .short 0x35f6
loc_18f50 66 95                            bne.s   loc_18ee7
loc_18f52 ef cd                            .short 0xefcd
loc_18f54 2b cb                            .short 0x2bcb
loc_18f56 b1 3f                            .short 0xb13f
loc_18f58 7e 9f                            moveq   #-97,d7
loc_18f5a bf 5d                            eor.w d7,(a5)+
loc_18f5c 5d 8a                            subql #6,a2
loc_18f5e d8 76 2b d9                      add.w @0)@0),d4
loc_18f62 7e cb                            moveq   #-53,d7
loc_18f64 f6 5f                            .short 0xf65f
loc_18f66 b2 eb a8 00                      cmpa.w (a3)(-22528),a1
loc_18f6a 00 f6                            .short 0x00f6
loc_18f6c a6 6e                            .short 0xa66e
loc_18f6e fd fe                            .short 0xfdfe
loc_18f70 6e ab                            bgt.s   loc_18f1d
loc_18f72 db 3e                            .short 0xdb3e
loc_18f74 ca 55                            and.w (a5),d5
loc_18f76 fb fc                            .short 0xfbfc
loc_18f78 ab a5                            .short 0xaba5
loc_18f7a 5e db                            sgt (a3)+
loc_18f7c eb 75                            roxlw d5,d5
loc_18f7e 5f bf                            .short 0x5fbf
loc_18f80 4e 80                            .short 0x4e80
loc_18f82 00 00 76 6d                      ori.b #109,d0
loc_18f86 b5 33 ad 2a a6 79 25 54          eor.b d2,(a3)(ffffffffffffa679,a2:l:4)@(0000000000002554)
loc_18f8e cf 24                            and.b d7,(a4)-
loc_18f90 db 3c                            .short 0xdb3c
loc_18f92 97 56                            sub.w   d3,(a6)
loc_18f94 79 2b                            .short 0x792b
loc_18f96 f3 b9                            .short 0xf3b9
loc_18f98 5f f9 d5 76 67 4a                sle 0xd576674a
loc_18f9e 9b 7e                            .short 0x9b7e
loc_18fa0 75 52                            .short 0x7552
loc_18fa2 a7 6f                            .short 0xa76f
loc_18fa4 cd d5                            mulsw (a5),d6
loc_18fa6 3b 7e                            .short 0x3b7e
loc_18fa8 7b 36                            .short 0x7b36
loc_18faa fc d7                            .short 0xfcd7
loc_18fac fa d0                            .short 0xfad0
loc_18fae 02 b6 5d 54 a9 75 3b 3a f3 ca 95 53 3c bb  andi.l #1565829493,(a6)(fffffffff3ca9553,d3:l:2)@(0000000000003cbb)
loc_18fbc 33 76 7e 3d 94 cf                move.w  (a6)(000000000000003d,d7:l:8),(a1)(-27441)
loc_18fc2 f7 d9                            .short 0xf7d9
loc_18fc4 d2 ac fc 73                      add.l (a4)(-909),d1
loc_18fc8 a6 d4                            .short 0xa6d4
loc_18fca fd 6d                            .short 0xfd6d
loc_18fcc 36 6f de 00                      movea.w (sp)(-8704),a3
loc_18fd0 00 a5 77 d6 ad ea                ori.l #2010557930,(a5)-
loc_18fd6 d9 5b                            add.w   d4,(a3)+
loc_18fd8 2b 65 65 5a                      move.l  (a5)-,(a5)(25946)
loc_18fdc bc 6f ca fd                      cmp.w (sp)(-13571),d6
loc_18fe0 ea af                            lsrl d5,d7
loc_18fe2 25 57 92 ab                      move.l  (sp),(a2)(-27989)
loc_18fe6 c9 55                            and.w d4,(a5)
loc_18fe8 e4 ad                            lsrl d2,d5
loc_18fea e0 00                            asrb #8,d0
loc_18fec 13 7b 78 f6 3b 2e                move.b  (pc)(loc_18fe4,d7:l),(a1)(15150)
loc_18ff2 cc ab 76 5d                      and.l (a3)(30301),d6
loc_18ff6 9b 65                            sub.w   d5,(a5)-
loc_18ff8 4c bb 3a 3b 2a fa                movem.w (pc)(loc_18ff6,d2:l:2),d0-d1/d3-d5/a1/a3-a5
loc_18ffe 26 5b                            movea.l (a3)+,a3
loc_19000 2b 20                            move.l  (a0)-,(a5)-
loc_19002 00 0e                            .short loc_e
loc_19004 de 9e                            add.l (a6)+,d7
loc_19006 db da                            adda.l (a2)+,a5
loc_19008 be 99                            cmp.l (a1)+,d7
loc_1900a 35 7d                            .short 0x357d
loc_1900c 32 6a ff 7c                      movea.w (a2)(-132),a1
loc_19010 d5 f4 c9 ab e9 93 7f 3f 7a b2    adda.l @(ffffffffffffe993,a4:l)@(000000007f3f7ab2),a2
loc_1901a f6 4e                            .short 0xf64e
loc_1901c 95 a7                            sub.l d2,-(sp)
loc_1901e 4a d3                            tas (a3)
loc_19020 c6 b4 e9 5a 74 ad                and.l (a4)@(00000000000074ad),d3
loc_19026 3f 7e                            .short 0x3f7e
loc_19028 00 0a                            .short loc_a
loc_1902a ec de                            .short 0xecde
loc_1902c d5 ed 5e fa                      adda.l (a5)(24314),a2
loc_19030 57 56                            subq.w  #3,(a6)
loc_19032 5b 78 f4 df                      subq.w  #5,($FFFFf4df
loc_19036 55 79 57 b6 fd ab                subq.w  #2,0x57b6fdab
loc_1903c a5 79                            .short 0xa579
loc_1903e 6d 95                            blt.s   loc_18fd5
loc_19040 55 ba                            .short 0x55ba
loc_19042 be 95                            cmp.l (a5),d7
loc_19044 a5 75                            .short 0xa575
loc_19046 56 00                            addq.b  #3,d0
loc_19048 00 53 35 e5                      ori.w #13797,(a3)
loc_1904c f9 d6                            .short 0xf9d6
loc_1904e cf 2e 8d f9                      and.b d7,(a6)(-29191)
loc_19052 df 64                            add.w   d7,(a4)-
loc_19054 fd f2                            .short 0xfdf2
loc_19056 57 e2                            seq (a2)-
loc_19058 bf 61                            eor.w d7,(a1)-
loc_1905a 9d ff                            .short 0x9dff
loc_1905c 9d c9                            suba.l a1,a6
loc_1905e 7d 32                            .short 0x7d32
loc_19060 cd bd                            .short 0xcdbd
loc_19062 bf 3a                            .short 0xbf3a
loc_19064 df be                            .short 0xdfbe
loc_19066 4f 1a                            chkl (a2)+,d7
loc_19068 d3 d8                            adda.l (a0)+,a1
loc_1906a 00 15 9d 37                      ori.b #55,(a5)
loc_1906e a6 59                            .short 0xa659
loc_19070 ed f9                            .short 0xedf9
loc_19072 d7 6f af 6c                      add.w   d3,(sp)(-20628)
loc_19076 e9 fb                            .short 0xe9fb
loc_19078 ea f6                            .short 0xeaf6
loc_1907a ca bf                            .short 0xcabf
loc_1907c df 57                            add.w   d7,(sp)
loc_1907e 56 55                            addq.w  #3,(a5)
loc_19080 ff 3b                            .short 0xff3b
loc_19082 37 57 fc ec                      move.w  (sp),(a3)(-788)
loc_19086 dd d9                            adda.l (a1)+,a6
loc_19088 90 00                            sub.b d0,d0
loc_1908a 0e 8b                            .short 0x0e8b
loc_1908c f6 5d                            .short 0xf65d
loc_1908e 7b d7                            .short 0x7bd7
loc_19090 5e f5 d7 bd 75 ef 5d 7b          sgt @(0000000075ef5d7b)@0,a5.w:8)
loc_19098 d7 ed d1 7f                      adda.l (a5)(-11905),a3
loc_1909c cf 6d f5 ba                      and.w d7,(a5)(-2630)
loc_190a0 b7 6f ad d5                      eor.w d3,(sp)(-21035)
loc_190a4 bb 7d                            .short 0xbb7d
loc_190a6 6e ad                            bgt.s   loc_19055
loc_190a8 db fd                            .short 0xdbfd
loc_190aa 9b 7d                            .short 0x9b7d
loc_190ac 6b f6                            bmi.s   loc_190a4
loc_190ae 00 2b d9 3b 1d 5b                ori.b #59,(a3)(7515)
loc_190b4 56 ee ca 9d                      sne (a6)(-13667)
loc_190b8 5d 2b df 5d                      subq.b  #6,(a3)(-8355)
loc_190bc 4e af f7 d5                      jsr     (sp)(-2091)
loc_190c0 d5 5f                            add.w   d2,(sp)+
loc_190c2 f7 bb                            .short 0xf7bb
loc_190c4 3f bd                            .short 0x3fbd
loc_190c6 5d 2b fd f5                      subq.b  #6,(a3)(-523)
loc_190ca 6d 5e                            blt.s   loc_1912a
loc_190cc fa d7                            .short 0xfad7
loc_190ce d8 00                            add.b d0,d4
loc_190d0 0e c9                            .short 0x0ec9
loc_190d2 5b d5                            smi (a5)
loc_190d4 bd 79 ec bc f6 5e                eor.w d6,0xecbcf65e
loc_190da 7b 2f                            .short 0x7b2f
loc_190dc 3d 95 bc 65                      move.w  (a5),(a6)(0000000000000065,a3:l:4)
loc_190e0 7e 57                            moveq   #87,d7
loc_190e2 d5 9a                            add.l d2,(a2)+
loc_190e4 aa cd                            .short 0xaacd
loc_190e6 55 66                            subq.w  #2,(a6)-
loc_190e8 aa b3                            .short 0xaab3
loc_190ea 56 40                            addq.w  #3,d0
loc_190ec 00 03 b3 f1                      ori.b #-15,d3
loc_190f0 6c f6                            bge.s   loc_190e8
loc_190f2 de ec ff 79                      adda.w (a4)(-135),sp
loc_190f6 95 33 fe 66                      sub.b d2,(a3)(0000000000000066,sp:l:8)
loc_190fa 74 cb                            moveq   #-53,d2
loc_190fc f7 99                            .short 0xf799
loc_190fe bb 7e                            .short 0xbb7e
loc_19100 d9 a6                            add.l d4,(a6)-
loc_19102 fc c0                            .short 0xfcc0
loc_19104 00 06 cd 5d                      ori.b #$5D,d6
loc_19108 8e af f9 cd                      orl (sp)(-1587),d7
loc_1910c 5f ef 92 bf                      sle (sp)(-27969)
loc_19110 14 af c5 3f                      move.b  (sp)(-15041),(a2)
loc_19114 7e 05                            moveq   #5,d7
loc_19116 6e fd                            bgt.s   loc_19115
loc_19118 6b b7                            bmi.s   loc_190d1
loc_1911a e6 ec dd be                      ror.w (a4)(-8770)
loc_1911e b7 66                            eor.w d3,(a6)-
loc_19120 ed f5                            .short 0xedf5
loc_19122 fe b5                            .short 0xfeb5
loc_19124 db eb 5f b0                      adda.l (a3)(24496),a5
loc_19128 0b fd                            .short 0x0bfd
loc_1912a 6a f3                            bpl.s   loc_1911f
loc_1912c a6 6b                            .short 0xa66b
loc_1912e ce 95                            and.l (a5),d7
loc_19130 e4 99                            ror.l #2,d1
loc_19132 d7 be                            .short 0xd7be
loc_19134 b6 af c6 bc                      cmp.l (sp)(-14660),d3
loc_19138 dd fc ea dd 5f f3                adda.l #-354590733,a6
loc_1913e 9a bf                            .short 0x9abf
loc_19140 e7 37                            roxlb d3,d7
loc_19142 f3 f2                            .short 0xf3f2
loc_19144 be b0 00 00                      cmp.l (a0,d0.w),d7
loc_19148 05 60                            bchg d2,(a0)-
loc_1914a be a5                            cmp.l (a5)-,d7
loc_1914c 9c 60                            sub.w (a0)-,d6
loc_1914e 90 38 d9 3f                      sub.b ($FFFFd93f,d0
loc_19152 74 da                            moveq   #-38,d2
loc_19154 73 37                            .short 0x7337
loc_19156 7f 10                            .short 0x7f10
loc_19158 dc 5f                            add.w (sp)+,d6
loc_1915a b5 8b                            cmpm.l (a3)+,(a2)+
loc_1915c 7e d6                            moveq   #-42,d7
loc_1915e 2b 2c 16 77                      move.l  (a4)(5751),(a5)-
loc_19162 90 00                            sub.b d0,d0
loc_19164 3b 05                            move.w  d5,(a5)-
loc_19166 75 2c                            .short 0x752c
loc_19168 e0 6b                            lsr.w d0,d3
loc_1916a 8d 8d                            .short 0x8d8d
loc_1916c 7f aa                            .short 0x7faa
loc_1916e 59 f3 8a 1f                      svs (a3)(000000000000001f,a0:l:2)
loc_19172 ed 1a                            rol.b #6,d2
loc_19174 3d 44 d1 ea                      move.w  d4,(a6)(-11798)
loc_19178 49 a8 ef 20                      chkw (a0)(-4320),d4
loc_1917c 00 0b                            .short loc_b
loc_1917e c1 7d                            .short 0xc17d
loc_19180 4b 38 c1 20                      chkl ($FFFFC120,d5
loc_19184 71 b2                            .short 0x71b2
loc_19186 7e e9                            moveq   #-23,d7
loc_19188 0f 99                            bclr d7,(a1)+
loc_1918a b4 7f                            .short 0xb47f
loc_1918c 6a d1                            bpl.s   loc_1915f
loc_1918e ea 8b                            lsrl #5,d3
loc_19190 60 47                            bra.s   loc_191d9
loc_19192 15 99 1a c8                      move.b  (a1)+,(a2)(ffffffffffffffc8,d1:l:2)
loc_19196 00 03 b0 57                      ori.b #87,d3
loc_1919a 52 ce 06 b8                      dbhi d6,loc_19854
loc_1919e d8 d7                            adda.w (sp),a4
loc_191a0 fa a5                            .short 0xfaa5
loc_191a2 9f 35 f5 45                      sub.b d7,(a5)@0)
loc_191a6 22 47                            movea.l d7,a1
loc_191a8 14 89                            .short 0x1489
loc_191aa 60 84                            bra.s   loc_19130
loc_191ac 6a 20                            bpl.s   loc_191ce
loc_191ae 00 01 46 ac                      ori.b #-84,d1
loc_191b2 15 82 b0 68                      move.b  d2,(a2)(0000000000000068,a3.w)
loc_191b6 e0 46                            asrw #8,d6
loc_191b8 df b4 26 ee                      add.l d7,(a4)(ffffffffffffffee,d2.w:8)
loc_191bc 32 6c 34 34                      movea.w (a4)(13364),a1
loc_191c0 fd aa                            .short 0xfdaa
loc_191c2 8c 95                            orl (a5),d6
loc_191c4 13 be                            .short 0x13be
loc_191c6 20 01                            move.l  d1,d0
loc_191c8 d4 be                            .short 0xd4be
loc_191ca e3 48                            lsl.w   #1,d0
loc_191cc fe a9                            .short 0xfea9
loc_191ce 34 e7                            move.w -(sp),(a2)+
loc_191d0 16 c0                            move.b  d0,(a3)+
loc_191d2 b4 6c 0a 29                      cmp.w (a4)(2601),d2
loc_191d6 a1 ac                            .short 0xa1ac
loc_191d8 e2 6b                            lsr.w d1,d3
loc_191da c1 44                            exg d0,d4
loc_191dc 2f 30 00 0a                      move.l  (a0)a,d0.w),-(sp)
loc_191e0 35 60 ac 15                      move.w  (a0)-,(a2)(-21483)
loc_191e4 82 cc                            .short 0x82cc
loc_191e6 8d 71 32 43                      or.w d6,(a1)(0000000000000043,d3.w:2)
loc_191ea d0 d0                            adda.w (a0),a0
loc_191ec f4 35                            .short 0xf435
loc_191ee 9c 4d                            sub.w a5,d6
loc_191f0 64 64                            bcc.s   loc_19256
loc_191f2 a3 00                            .short 0xa300
loc_191f4 01 4e a5 f7                      movepl (a6)(-23049),d0
loc_191f8 1a 47                            .short 0x1a47
loc_191fa f5 49                            .short 0xf549
loc_191fc a7 33                            .short 0xa733
loc_191fe 6c 0b                            bge.s   loc_1920b
loc_19200 46 39 c5 0e 26 b3                not.b 0xc50e26b3
loc_19206 89 ac e2 a2                      orl d4,(a4)(-7518)
loc_1920a 00 00 02 8d                      ori.b #-115,d0
loc_1920e 58 2b 05 61                      addq.b  #4,(a3)(1377)
loc_19212 79 a1                            .short 0x79a1
loc_19214 c7 04                            abcd d4,d3
loc_19216 2e e4                            move.l  (a4)-,(sp)+
loc_19218 3d 0d                            move.w  a5,(a6)-
loc_1921a 65 82                            bcs.s   loc_1919e
loc_1921c 78 11                            moveq   #$11,d4
loc_1921e de 6a d0 00                      add.w (a2)(-12288),d7
loc_19222 3a 97                            move.w  (sp),(a5)
loc_19224 dc 69 fb a4                      add.w (a1)(-1116),d6
loc_19228 d3 9a                            add.l d1,(a2)+
loc_1922a 60 47                            bra.s   loc_19273
loc_1922c 16 32 51 c4                      move.b @0)@0),d3
loc_19230 d7 a1                            add.l d3,(a1)-
loc_19232 af 05                            .short 0xaf05
loc_19234 10 bc c0 00                      move.b  #0,(a0)
loc_19238 28 d5                            move.l  (a5),(a4)+
loc_1923a 82 b0 56 17                      orl (a0)(0000000000000017,d5.w:8),d1
loc_1923e 9a 7e                            .short 0x9a7e
loc_19240 d5 0f                            addxb -(sp),(a2)-
loc_19242 b9 0b                            cmpmb (a3)+,(a4)+
loc_19244 43 5f                            .short 0x435f
loc_19246 52 88                            addq.l #1,a0
loc_19248 d7 13                            add.b d3,(a3)
loc_1924a 92 a6                            sub.l (a6)-,d1
loc_1924c 00 1d 4b ee                      ori.b #-18,(a5)+
loc_19250 34 fd                            .short 0x34fd
loc_19252 d2 69 cd 30                      add.w (a1)(-13008),d1
loc_19256 23 8b 19 28 e2 6b                move.l  a3,(a1)(ffffffffffffe26b,d1:l)
loc_1925c d0 d7                            adda.w (sp),a0
loc_1925e 82 88                            .short 0x8288
loc_19260 00 00 00 28                      ori.b #$28,d0
loc_19264 ef 3b                            rol.b d7,d3
loc_19266 c9 7d                            .short 0xc97d
loc_19268 48 7d                            .short 0x487d
loc_1926a c8 5a                            and.w (a2)+,d4
loc_1926c 1a fa 95 35                      move.b  (pc)(loc_127a3),(a5)+
loc_19270 e0 57                            roxrw #8,d7
loc_19272 c8 00                            and.b d0,d4
loc_19274 07 ed 50 ff                      bset d3,(a5)(20735)
loc_19278 74 c7                            moveq   #-57,d2
loc_1927a a7 36                            .short 0xa736
loc_1927c 3e e2                            move.w  (a2)-,(sp)+
loc_1927e 8b 8b                            .short 0x8b8b
loc_19280 02 43 89 2f                      andi.w  #-30417,d3
loc_19284 43 5f                            .short 0x435f
loc_19286 52 c8 d5 2b                      dbhi d0,loc_167b3
loc_1928a fc 00                            .short 0xfc00
loc_1928c 00 53 f6 ad                      ori.w #-2387,(a3)
loc_19290 86 98                            orl (a0)+,d3
loc_19292 3b fb                            .short 0x3bfb
loc_19294 4e 3e                            .short 0x4e3e
loc_19296 71 e6                            .short 0x71e6
loc_19298 ec 23                            asrb d6,d3
loc_1929a 28 9b                            move.l  (a3)+,(a4)
loc_1929c 88 e3                            divu.w (a3)-,d4
loc_1929e 83 8e                            .short 0x838e
loc_192a0 38 44                            movea.w d4,a4
loc_192a2 8e 9a                            orl (a2)+,d7
loc_192a4 1e 98                            move.b  (a0)+,(sp)
loc_192a6 50 bf                            .short 0x50bf
loc_192a8 6a 51                            bpl.s   loc_192fb
loc_192aa 71 60                            .short 0x7160
loc_192ac 49 85                            chkw d5,d4
loc_192ae 24 b3 d2 40                      move.l  (a3)(0000000000000040,a5.w:2),(a2)
loc_192b2 00 df                            .short 0x00df
loc_192b4 b5 6c 34 c1                      eor.w d2,(a4)(13505)
loc_192b8 df da                            adda.l (a2)+,sp
loc_192ba 77 3d                            .short 0x773d
loc_192bc 39 b8 e3 22 89 37 ed 50 f4 36 3f da 1d 22  move.w  ($FFFFe322,(a4)(ffffffffed50f436)@(000000003fda1d22,a0:l)
loc_192ca 47 a1                            chkw (a1)-,d3
loc_192cc 94 5c                            sub.w (a4)+,d2
loc_192ce 58 12                            addq.b  #4,(a2)
loc_192d0 1b 8d                            .short 0x1b8d
loc_192d2 b4 2e e0 1d                      cmp.b (a6)(-8163),d2
loc_192d6 f9 df                            .short 0xf9df
loc_192d8 47 7e                            .short 0x477e
loc_192da b7 f6 4e dd                      cmpal (a6)(ffffffffffffffdd,d4:l:8),a3
loc_192de aa 4d                            .short 0xaa4d
loc_192e0 ea 20                            asrb d5,d0
loc_192e2 02 ff                            .short 0x02ff
loc_192e4 8e ef f3 bb                      divu.w (sp)(-3141),d7
loc_192e8 bd 37 28 80                      eor.b d6,(sp)(ffffffffffffff80,d2:l)
loc_192ec 0b f4 e0 ef                      bset d5,(a4)(ffffffffffffffef,a6.w)
loc_192f0 d9 7e                            .short 0xd97e
loc_192f2 a5 da                            .short 0xa5da
loc_192f4 ee 47                            asrw #7,d7
loc_192f6 cd 44                            exg d6,d4
loc_192f8 00 00 52 0a                      ori.b #$A,d0
loc_192fc 28 c1                            move.l  d1,(a4)+
loc_192fe 73 38                            .short 0x7338
loc_19300 31 4b 73 6e                      move.w  a3,(a0)(29550)
loc_19304 b4 18                            cmp.b (a0)+,d2
loc_19306 a4 56                            .short 0xa456
loc_19308 83 4f                            .short 0x834f
loc_1930a 62 42                            bhi.s   loc_1934e
loc_1930c e8 9e                            ror.l #4,d6
loc_1930e 40 00                            negxb d0
loc_19310 00 68 2a 05 06 f2                ori.w #10757,(a0)(1778)
loc_19316 83 79 41 8a d0 28                or.w d1,0x418ad028
loc_1931c 31 5a 13 83                      move.w  (a2)+,(a0)(4995)
loc_19320 a4 55                            .short 0xa455
loc_19322 4e 0e                            .short 0x4e0e
loc_19324 fd e1                            .short 0xfde1
loc_19326 41 d0                            lea     (a0),a0
loc_19328 dd 00                            addxb d0,d6
loc_1932a 00 00 08 2a                      ori.b #42,d0
loc_1932e 7c d3                            moveq   #-45,d6
loc_19330 c9 3c                            .short 0xc93c
loc_19332 92 70 b3 6e 85 9a 7b 13          sub.w (a0)(ffffffffffff859a)@(0000000000007b13),d1
loc_1933a 4f a2                            chkw (a2)-,d7
loc_1933c 79 00                            .short 0x7900
loc_1933e 00 01 a0 a8                      ori.b #-88,d1
loc_19342 14 18                            move.b  (a0)+,d2
loc_19344 a0 65                            .short 0xa065
loc_19346 06 23 9f 37                      addi.b #55,(a3)-
loc_1934a 14 2d 38 38                      move.b  (a5)(14392),d2
loc_1934e a1 62                            .short 0xa162
loc_19350 94 1d                            sub.b (a5)+,d2
loc_19352 22 aa 70 77                      move.l  (a2)(28791),(a1)
loc_19356 ef 0a                            lsl.b #7,d2
loc_19358 0e 86                            .short 0x0e86
loc_1935a e8 00                            asrb #4,d0
loc_1935c 00 17 c1 45                      ori.b #69,(sp)
loc_19360 18 2e 67 02                      move.b  (a6)(26370),d4
loc_19364 77 f5                            .short 0x77f5
loc_19366 9d ba                            .short 0x9dba
loc_19368 d0 27                            add.b -(sp),d0
loc_1936a 6e b4                            bgt.s   loc_19320
loc_1936c 09 d3                            bset d4,(a3)
loc_1936e d8 a4                            add.l (a4)-,d4
loc_19370 c5 fb c6 96                      mulsw (pc)(loc_19308,a4.w:8),d2
loc_19374 e8 36                            roxrb d4,d6
loc_19376 e8 26                            asrb d4,d6
loc_19378 c5 04                            abcd d4,d2
loc_1937a fd d0                            .short 0xfdd0
loc_1937c 00 34 15 02 82 6e                ori.b #2,(a4)(000000000000006e,a0.w:2)
loc_19382 82 6e 82 5a                      or.w (a6)(-32166),d1
loc_19386 05 04                            btst d2,d4
loc_19388 b4 27                            cmp.b -(sp),d2
loc_1938a 06 2a a7 06 e8 50                addi.b #6,(a2)(-6064)
loc_19390 6d d0                            blt.s   loc_19362
loc_19392 00 00 00 82                      ori.b #-126,d0
loc_19396 88 e0                            divu.w (a0)-,d4
loc_19398 b9 9c                            eor.l d4,(a4)+
loc_1939a db bd                            .short 0xdbbd
loc_1939c a7 0b                            .short 0xa70b
loc_1939e 13 b7 42 c4 e9 ec 52 74          move.b  (sp)(ffffffffffffffc4,d4.w:2),@(0000000000005274)@0)
loc_193a6 ff 78                            .short 0xff78
loc_193a8 de 50                            add.w (a0),d7
loc_193aa 6d dc                            blt.s   loc_19388
loc_193ac db 62                            add.w   d5,(a2)-
loc_193ae 82 7e                            .short 0x827e
loc_193b0 e8 00                            asrb #4,d0
loc_193b2 1a 0a                            .short 0x1a0a
loc_193b4 81 41                            .short 0x8141
loc_193b6 21 38 26 ee                      move.l loc_26ee,(a0)-
loc_193ba 6d 0b                            blt.s   loc_193c7
loc_193bc 4e 0d                            .short 0x4e0d
loc_193be 0b 4e 0c 55                      movepl (a6)(3157),d5
loc_193c2 4e 0d                            .short 0x4e0d
loc_193c4 d0 a0                            add.l (a0)-,d0
loc_193c6 db a5                            add.l d5,(a5)-
loc_193c8 06 e7                            .short 0x06e7
loc_193ca e1 04                            aslb #8,d4
loc_193cc 84 e0                            divu.w (a0)-,d2
loc_193ce 90 a8 a0 90                      sub.l (a0)(-24432),d0
loc_193d2 a8 a0                            .short 0xa8a0
loc_193d4 00 01 64 a9                      ori.b #-87,d1
loc_193d8 d0 da                            adda.w (a2)+,a0
loc_193da 53 91                            subql #1,(a1)
loc_193dc b7 f5 9d e1 df 4d                cmpal @(ffffffffffffdf4d)@0),a3
loc_193e2 c7 69 d2 44                      and.w d3,(a1)(-11708)
loc_193e6 76 84                            moveq   #-124,d3
loc_193e8 e9 ba                            roll d4,d2
loc_193ea d0 9c                            add.l (a4)+,d0
loc_193ec 3c 3c b6 ef                      move.w  #-18705,d6
loc_193f0 e9 2f                            lsl.b d4,d7
loc_193f2 2e 6d 34 96                      movea.l (a5)(13462),sp
loc_193f6 e4 f0 32 42                      roxrw (a0)(0000000000000042,d3.w:2)
loc_193fa 91 1a                            sub.b d0,(a2)+
loc_193fc 4e 44                            trap #4
loc_193fe 93 92                            sub.l d1,(a2)
loc_19400 e6 ad                            lsrl d3,d5
loc_19402 d8 07                            add.b d7,d4
loc_19404 12 8a                            .short 0x128a
loc_19406 4a 9a                            tst.l (a2)+
loc_19408 bc 15                            cmp.b (a5),d6
loc_1940a 35 14                            move.w  (a4),(a2)-
loc_1940c af 20                            .short 0xaf20
loc_1940e 01 28 a9 24                      btst d0,(a0)(-22236)
loc_19412 f0 71                            .short 0xf071
loc_19414 3a 53                            movea.w (a3),a5
loc_19416 69 13                            bvss loc_1942b
loc_19418 88 5e                            or.w (a6)+,d4
loc_1941a 40 00                            negxb d0
loc_1941c 18 95                            move.b  (a5),(a4)
loc_1941e 3a 1b                            move.w  (a3)+,d5
loc_19420 4a 72 37 7f 9a 9f ab ff b1 1d a7 e0  tst.w   (a2)(ffffffff9a9fabff)@(ffffffffb11da7e0)
loc_1942c 47 68                            .short 0x4768
loc_1942e 7f 5a                            .short 0x7f5a
loc_19430 d0 9f                            add.l (sp)+,d0
loc_19432 ea fc                            .short 0xeafc
loc_19434 aa fe                            .short 0xaafe
loc_19436 b6 d4                            cmpa.w (a4),a3
loc_19438 97 97                            sub.l d3,(sp)
loc_1943a 36 9a                            move.w  (a2)+,(a3)
loc_1943c 78 4d                            moveq   #77,d4
loc_1943e a4 52                            .short 0xa452
loc_19440 32 37 4e 58                      move.w  (sp)(0000000000000058,d4:l:8),d1
loc_19444 13 b7 4a a6 dc b9                move.b  (sp)(ffffffffffffffa6,d4:l:2),(a1)(ffffffffffffffb9,a5:l:4)
loc_1944a ab 76                            .short 0xab76
loc_1944c 00 38 af 2b e5 79                ori.b #43,($FFFFe579
loc_19452 5e 40                            addq.w  #7,d0
loc_19454 00 52 59 38                      ori.w #22840,(a2)
loc_19458 9a 44                            sub.w   d4,d5
loc_1945a d2 29 4e f2                      add.b (a1)(20210),d1
loc_1945e 17 90 00 42                      move.b  (a0),(a3)(0000000000000042,d0.w)
loc_19462 fa af                            .short 0xfaaf
loc_19464 a8 00                            .short 0xa800
loc_19466 00 0c                            .short loc_c
loc_19468 4a 9d                            tst.l (a5)+
loc_1946a 0d a5                            bclr d6,(a5)-
loc_1946c 39 1b                            move.w  (a3)+,(a4)-
loc_1946e bf ed fa bf                      cmpal (a5)(-1345),sp
loc_19472 fb 11                            .short 0xfb11
loc_19474 d8 bf                            .short 0xd8bf
loc_19476 56 47                            addq.w  #3,d7
loc_19478 68 7f                            bvcs loc_194f9
loc_1947a 5a d0                            spl (a0)
loc_1947c 9f ea fc a9                      suba.l (a2)(-855),sp
loc_19480 fd 6a                            .short 0xfd6a
loc_19482 9d 2f 28 24                      sub.b d6,(sp)(10276)
loc_19486 dc 52                            add.w (a2),d6
loc_19488 29 4d de 46                      move.l  a5,(a4)(-8634)
loc_1948c 4e dd                            .short 0x4edd
loc_1948e 2a 8f                            move.l sp,(a5)
loc_19490 fa d2                            .short 0xfad2
loc_19492 a8 e9                            .short 0xa8e9
loc_19494 b9 aa 39 ab                      eor.l d4,(a2)(14763)
loc_19498 76 01                            moveq   #1,d3
loc_1949a 8a f2 bc af                      divu.w (a2)(ffffffffffffffaf,a3:l:4),d5
loc_1949e 28 2b 65 6c                      move.l  (a3)(25964),d4
loc_194a2 a8 00                            .short 0xa800
loc_194a4 15 22                            move.b  (a2)-,(a2)-
loc_194a6 91 48                            subxw (a0)-,(a0)-
loc_194a8 a5 35                            .short 0xa535
loc_194aa 48 af 21 79 00 00                movem.w d0/d3-d6/a0/a5,(sp)(0)
loc_194b0 0a 25 4d 72                      eori.b #114,(a5)-
loc_194b4 9c 9b                            sub.l (a3)+,d6
loc_194b6 bd c5                            cmpal d5,a6
loc_194b8 fa b9                            .short 0xfab9
loc_194ba bb bc                            .short 0xbbbc
loc_194bc dd fa b2 3b                      adda.l (pc)(loc_146f9),a6
loc_194c0 3b be                            .short 0x3bbe
loc_194c2 ce 2f d5 cd                      and.b (sp)(-10803),d7
loc_194c6 bb d2                            cmpal (a2),a5
loc_194c8 5b a4                            subql #5,(a4)-
loc_194ca 52 74 e9 e5 81 53                addq.w  #1,@(ffffffffffff8153)@0)
loc_194d0 bc ca                            cmpa.w a2,a6
loc_194d2 85 e1                            divsw (a1)-,d2
loc_194d4 b9 de                            cmpal (a6)+,a4
loc_194d6 14 dc                            move.b  (a4)+,(a2)+
loc_194d8 a9 12                            .short 0xa912
loc_194da a4 40                            .short 0xa440
loc_194dc 00 00 71 de                      ori.b #-34,d0
loc_194e0 77 cd                            .short 0x77cd
loc_194e2 5b 97                            subql #5,(sp)
loc_194e4 69 ae                            bvss loc_19494
loc_194e6 13 5c 27 04                      move.b  (a4)+,(a1)(9988)
loc_194ea 9e c8                            subaw a0,sp
loc_194ec 5d 10                            subq.b  #6,(a0)
loc_194ee b9 80                            eor.l d4,d0
loc_194f0 00 00 04 25                      ori.b #37,d0
loc_194f4 4a 72 29 14                      tst.w   (a2)@0,d2:l)
loc_194f8 a6 b9                            .short 0xa6b9
loc_194fa 19 24                            move.b  (a4)-,(a4)-
loc_194fc b7 21                            eor.b d3,(a1)-
loc_194fe cd a6                            and.l   d6,(a6)-
loc_19500 00 00 0a 12                      ori.b #18,d0
loc_19504 a7 43                            .short 0xa743
loc_19506 69 4e                            bvss loc_19556
loc_19508 46 ef eb 50                      move.w  (sp)(-5296),sr
loc_1950c bf 57                            eor.w d7,(sp)
loc_1950e ba 9d                            cmp.l (a5)+,d5
loc_19510 e7 6a                            lsl.w d3,d2
loc_19512 7e ac                            moveq   #-84,d7
loc_19514 8e d0                            divu.w (a0),d7
loc_19516 a7 7d                            .short 0xa77d
loc_19518 a1 42                            .short 0xa142
loc_1951a fd 5e                            .short 0xfd5e
loc_1951c e7 7f                            rol.w d3,d7
loc_1951e 59 a5                            subql #4,(a5)-
loc_19520 df 27                            add.b d7,-(sp)
loc_19522 4d db                            .short 0x4ddb
loc_19524 8e 6e 9c 88                      or.w (a6)(-25464),d7
loc_19528 c9 d3                            mulsw (a3),d4
loc_1952a 91 93                            sub.l d0,(a3)
loc_1952c 78 19                            moveq   #25,d4
loc_1952e 24 a6                            move.l  (a6)-,(a2)
loc_19530 b2 c0                            cmpa.w d0,a1
loc_19532 2c af 9a a6                      move.l  (sp)(-25946),(a6)
loc_19536 a9 aa                            .short 0xa9aa
loc_19538 70 59                            moveq   #89,d0
loc_1953a 6c be                            bge.s   loc_194fa
loc_1953c 8b e6                            divsw (a6)-,d5
loc_1953e 00 00 00 10                      ori.b #$10,d0
loc_19542 a4 b9                            .short 0xa4b9
loc_19544 6e 49                            bgt.s   loc_1958f
loc_19546 9d 24                            sub.b d6,(a4)-
loc_19548 ed c6                            .short 0xedc6
loc_1954a e2 95                            roxrl #1,d5
loc_1954c 25 35 48 d5                      move.l  (a5)(ffffffffffffffd5,d4:l),(a2)-
loc_19550 22 00                            move.l  d0,d1
loc_19552 5e 4a                            addq.w  #7,a2
loc_19554 9a e5                            subaw (a5)-,a5
loc_19556 34 f2 62 fd                      move.w  (a2)(fffffffffffffffd,d6.w:2),(a2)+
loc_1955a 59 37 7b 7e ac 8d bb d8 bf 56    subq.b  #4,(sp)(ffffffffac8dbbd8)@(ffffffffffffbf56)
loc_19564 49 e4                            .short 0x49e4
loc_19566 b9 4e                            cmpmw (a6)+,(a4)+
loc_19568 f2 74                            .short 0xf274
loc_1956a 8a 53                            or.w (a3),d5
loc_1956c 3f 2f 09 d0                      move.w  (sp)(2512),-(sp)
loc_19570 8e 7e                            .short 0x8e7e
loc_19572 1f d6                            .short 0x1fd6
loc_19574 95 08                            subxb (a0)-,(a2)-
loc_19576 e5 34                            roxlb d2,d4
loc_19578 90 00                            sub.b d0,d0
loc_1957a 00 01 aa 46                      ori.b #70,d1
loc_1957e ad cb                            .short 0xadcb
loc_19580 f2 43                            .short 0xf243
loc_19582 b4 d2                            cmpa.w (a2),a2
loc_19584 d0 9a                            add.l (a2)+,d0
loc_19586 5a 13                            addq.b  #5,(a3)
loc_19588 83 6e d9 a7                      or.w d1,(a6)(-9817)
loc_1958c d1 a7                            add.l d0,-(sp)
loc_1958e cd 0a                            abcd (a2)-,(a6)-
loc_19590 f9 5e                            .short 0xf95e
loc_19592 77 95                            .short 0x7795
loc_19594 e5 52                            roxlw #2,d2
loc_19596 a6 00                            .short 0xa600
loc_19598 01 72 51 2c a4 28                bchg d0,(a2)(ffffffffffffa428)@0,d5.w)
loc_1959e 4a 98                            tst.l (a0)+
loc_195a0 00 00 a2 54                      ori.b #84,d0
loc_195a4 d7 29 c9 bb                      add.b d3,(a1)(-13893)
loc_195a8 dc 5f                            add.w (sp)+,d6
loc_195aa ab 9b                            .short 0xab9b
loc_195ac bb cd                            cmpal a5,a5
loc_195ae df ab 23 b3                      add.l d7,(a3)(9139)
loc_195b2 bb ec e2 fd                      cmpal (a4)(-7427),a5
loc_195b6 5c db                            sge (a3)+
loc_195b8 bd 25                            eor.b d6,(a5)-
loc_195ba ba 45                            cmp.w   d5,d5
loc_195bc 26 fe                            .short 0x26fe
loc_195be b4 a7                            cmp.l -(sp),d2
loc_195c0 20 00                            move.l  d0,d0
loc_195c2 3b ce                            .short 0x3bce
loc_195c4 f9 ab                            .short 0xf9ab
loc_195c6 72 ed                            moveq   #-19,d1
loc_195c8 35 c2                            .short 0x35c2
loc_195ca 6b 84                            bmi.s   loc_19550
loc_195cc e0 93                            roxrl #8,d3
loc_195ce d9 0b                            addxb (a3)-,(a4)-
loc_195d0 a2 17                            .short 0xa217
loc_195d2 30 00                            move.w  d0,d0
loc_195d4 00 28 a4 08 4b 75                ori.b #8,(a0)(19317)
loc_195da e4 b9                            ror.l d2,d1
loc_195dc 9a 11                            sub.b (a1),d5
loc_195de cd d2                            mulsw (a2),d6
loc_195e0 28 c8                            move.l  a0,(a4)+
loc_195e2 00 1c 73 94                      ori.b #-108,(a4)+
loc_195e6 e3 bb                            roll d1,d3
loc_195e8 c2 71 9c 9d                      and.w (a1)(ffffffffffffff9d,a1:l:4),d1
loc_195ec b9 53                            eor.w d4,(a3)
loc_195ee bc aa 00 00                      cmp.l (a2)(0),d6
loc_195f2 02 8d                            .short 0x028d
loc_195f4 52 39 2e 72 4d c6                addq.b  #1,0x2e724dc6
loc_195fa 92 23                            sub.b (a3)-,d1
loc_195fc b2 4e                            cmp.w a6,d1
loc_195fe d0 49                            add.w a1,d0
loc_19600 15 a0 93 a8 90 ba                move.b  (a0)-,@(ffffffffffff90ba,a1.w:2)
loc_19606 2c aa 20 a9                      move.l  (a2)(8361),(a6)
loc_1960a ae 53                            .short 0xae53
loc_1960c 49 1c                            chkl (a4)+,d4
loc_1960e 89 88                            .short 0x8988
loc_19610 ca 44                            and.w d4,d5
loc_19612 d5 1c                            add.b d2,(a4)+
loc_19614 a6 b9                            .short 0xa6b9
loc_19616 4d 53                            .short 0x4d53
loc_19618 bc 97                            cmp.l (sp),d6
loc_1961a 33 00                            move.w  d0,(a1)-
loc_1961c 50 ef 39 2e                      st (sp)(14638)
loc_19620 53 92                            subql #1,(a2)
loc_19622 4a 72 26 99                      tst.w   (a2)(ffffffffffffff99,d2.w:8)
loc_19626 ee 74                            roxrw d7,d4
loc_19628 ec 65                            asrw d6,d5
loc_1962a 27 4e 16 9b                      move.l  a6,(a3)(5787)
loc_1962e a7 0b                            .short 0xa70b
loc_19630 14 9d                            move.b  (a5)+,(a2)
loc_19632 22 ab 73 bf                      move.l  (a3)(29631),(a1)
loc_19636 78 4d                            moveq   #77,d4
loc_19638 02 a8 92 6a dc bf 24 dd          andi.l #-1838490433,(a0)(9437)
loc_19640 22 6d d2 9b                      movea.l (a5)(-11621),a1
loc_19644 b7 4a                            cmpmw (a2)+,(a3)+
loc_19646 6e dd                            bgt.s   loc_19625
loc_19648 24 91                            move.l  (a1),(a2)
loc_1964a 49 52                            .short 0x4952
loc_1964c 51 f8 11 80                      sf loc_1180
loc_19650 03 a4                            bclr d1,(a4)-
loc_19652 a9 a1                            .short 0xa9a1
loc_19654 4a 68 5b 41                      tst.w   (a0)(23361)
loc_19658 0b 62                            bchg d5,(a2)-
loc_1965a 5f ef 3f ad                      sle (sp)(16301)
loc_1965e 0e a9                            .short 0x0ea9
loc_19660 1e ea 4b c8                      move.b  (a2)(19400),(sp)+
loc_19664 ca 5d                            and.w (a5)+,d5
loc_19666 e7 fe                            .short 0xe7fe
loc_19668 63 23                            bls.s   loc_1968d
loc_1966a ef 39                            rol.b d7,d1
loc_1966c cb 74 8c 83                      and.w d5,(a4)(ffffffffffffff83,a0:l:4)
loc_19670 8d 52                            or.w d6,(a2)
loc_19672 35 cc                            .short 0x35cc
loc_19674 d6 50                            add.w (a0),d3
loc_19676 29 21                            move.l  (a1)-,(a4)-
loc_19678 40 bc                            .short 0x40bc
loc_1967a 3a b9 f7 d2 7f aa                move.w 0xf7d27faa,(a5)
loc_19680 29 52 45 0d                      move.l  (a2),(a4)(17677)
loc_19684 ce a8 a1 36                      and.l (a0)(-24266),d7
loc_19688 e8 52                            roxrw #4,d2
loc_1968a 62 d8                            bhi.s   loc_19664
loc_1968c 97 30 00 00                      sub.b d3,(a0,d0.w)
loc_19690 09 13                            btst d4,(a3)
loc_19692 a4 b9                            .short 0xa4b9
loc_19694 10 06                            move.b  d6,d0
loc_19696 e2 39                            ror.b d1,d1
loc_19698 50 ea 71 80                      st (a2)(29056)
loc_1969c 00 00 21 5e                      ori.b #94,d0
loc_196a0 6d 53                            blt.s   loc_196f5
loc_196a2 8a 4d                            .short 0x8a4d
loc_196a4 de b9 4d bb da a7                add.l 0x4dbbdaa7,d7
loc_196aa 4d 45                            .short 0x4d45
loc_196ac 2b cd                            .short 0x2bcd
loc_196ae 46 40                            notw d0
loc_196b0 00 16 52 24                      ori.b #36,(a6)
loc_196b4 9c a6                            sub.l (a6)-,d6
loc_196b6 c5 54                            and.w d2,(a4)
loc_196b8 cc 9d                            and.l (a5)+,d6
loc_196ba b4 0f                            .short 0xb40f
loc_196bc 75 0a                            .short 0x750a
loc_196be a8 1c                            .short 0xa81c
loc_196c0 cc a1                            and.l (a1)-,d6
loc_196c2 38 4c                            movea.w a4,a4
loc_196c4 ca 13                            and.b (a3),d5
loc_196c6 81 19                            or.b d0,(a1)+
loc_196c8 50 aa 86 04                      addq.l #8,(a2)(-31228)
loc_196cc ed a0                            asl.l d6,d0
loc_196ce 64 c5                            bcc.s   loc_19695
loc_196d0 54 d6                            scc (a6)
loc_196d2 52 20                            addq.b  #1,(a0)-
loc_196d4 00 12 be 6a                      ori.b #106,(a2)
loc_196d8 ef 68                            lsl.w d7,d0
loc_196da 16 09                            .short 0x1609
loc_196dc 09 ae 72 5c                      bclr d4,(a6)(29276)
loc_196e0 e4 b8                            ror.l d2,d0
loc_196e2 16 09                            .short 0x1609
loc_196e4 0f 26                            btst d7,(a6)-
loc_196e6 9a a4                            sub.l (a4)-,d5
loc_196e8 00 00 00 00                      ori.b #0,d0
loc_196ec 14 3b c8 e5                      move.b  (pc)(loc_196d3,a4:l),d2
loc_196f0 43 a8 a5 ba                      chkw (a0)(-23110),d1
loc_196f4 46 47                            notw d7
loc_196f6 de 7f                            .short 0xde7f
loc_196f8 e6 32                            roxrb d3,d2
loc_196fa 97 79 95 25 e4 65                sub.w   d3,0x9525e465
loc_19700 d5 23                            add.b d2,(a3)-
loc_19702 dd 57                            add.w   d6,(sp)
loc_19704 f5 a0                            .short 0xf5a0
loc_19706 be 88                            cmp.l a0,d7
loc_19708 5b 12                            subq.b  #5,(a2)
loc_1970a 16 d0                            move.b  (a0),(a3)+
loc_1970c 42 94                            clr.l (a4)
loc_1970e d5 3b                            .short 0xd53b
loc_19710 e4 00                            asrb #2,d0
loc_19712 00 00 2f 92                      ori.b #-110,d0
loc_19716 8a 4b                            .short 0x8a4b
loc_19718 dc 85                            add.l d5,d6
loc_1971a 22 34 99 d9                      move.l @0)@0),d1
loc_1971e 3c 0a                            move.w  a2,d6
loc_19720 c9 ba                            .short 0xc9ba
loc_19722 a4 29                            .short 0xa429
loc_19724 6c b9                            bge.s   loc_196df
loc_19726 d4 29 22 93                      add.b (a1)(8851),d2
loc_1972a 49 0a                            .short 0x490a
loc_1972c 92 25                            sub.b (a5)-,d1
loc_1972e c8 c9                            .short 0xc8c9
loc_19730 67 35                            beq.s   loc_19767
loc_19732 14 af 20 a9                      move.b  (sp)(8361),(a2)
loc_19736 80 00                            or.b d0,d0
loc_19738 27 1a                            move.l  (a2)+,(a3)-
loc_1973a 1c 88                            .short 0x1c88
loc_1973c d0 bc 09 37 1c 9a                add.l #154606746,d0
loc_19742 c4 76 26 81                      and.w (a6)(ffffffffffffff81,d2.w:8),d2
loc_19746 5a 13                            addq.b  #5,(a3)
loc_19748 74 0a                            moveq   #$A,d2
loc_1974a d0 29 38 a4                      add.b (a1)(14500),d0
loc_1974e 55 4d                            subq.w  #2,a5
loc_19750 df cc                            adda.l a4,sp
loc_19752 93 8a                            subxl (a2)-,(a1)-
loc_19754 05 51                            bchg d2,(a1)
loc_19756 34 d5                            move.w  (a5),(a2)+
loc_19758 b9 72 dc 92                      eor.w d4,(a2)(ffffffffffffff92,a5:l:4)
loc_1975c 23 24                            move.l  (a4)-,(a1)-
loc_1975e 99 92                            sub.l d4,(a2)
loc_19760 11 cd                            .short 0x11cd
loc_19762 37 2c a4 a2                      move.w  (a4)(-23390),(a3)-
loc_19766 3f 02                            move.w  d2,-(sp)
loc_19768 56 09                            .short 0x5609
loc_1976a 86 98                            orl (a0)+,d3
loc_1976c 50 f4 e1 a6 11 fd cc 7a          st @(00000000000011fd)@(ffffffffffffcc7a,a6.w)
loc_19774 a3 c2                            .short 0xa3c2
loc_19776 38 53                            movea.w (a3),a4
loc_19778 fa a9                            .short 0xfaa9
loc_1977a a2 b4                            .short 0xa2b4
loc_1977c 5f ed 58 ff                      sle (a5)(22783)
loc_19780 68 6e                            bvcs loc_197f0
loc_19782 38 f0 89 b8 ff 68 6d fb          move.w @(ffffffffff686dfb,a0:l),(a4)+
loc_1978a 50 02                            addq.b  #8,d2
loc_1978c 1e 86                            move.b  d6,(sp)
loc_1978e 91 e1                            suba.l (a1)-,a0
loc_19790 15 e8                            .short 0x15e8
loc_19792 00 01 7c 15                      ori.b #21,d1
loc_19796 fb 94                            .short 0xfb94
loc_19798 e7 fb                            .short 0xe7fb
loc_1979a 94 e7                            subaw -(sp),a2
loc_1979c c1 5c                            and.w d0,(a4)+
loc_1979e c0 00                            and.b d0,d0
loc_197a0 0e 0a                            .short 0x0e0a
loc_197a2 fd ca                            .short 0xfdca
loc_197a4 73 fd                            .short 0x73fd
loc_197a6 ca 73 fd ca 73 e0                and.w @0)@(00000000000073e0),d5
loc_197ac 00 00 0e 01                      ori.b #1,d0
loc_197b0 39 df                            .short 0x39df
loc_197b2 0b e0                            bset d5,(a0)-
loc_197b4 be 1d                            cmp.b (a5)+,d7
loc_197b6 ab b5                            .short 0xabb5
loc_197b8 20 9f                            move.l  (sp)+,(a0)
loc_197ba a8 5f                            .short 0xa85f
loc_197bc 23 e4 bf d4 53 f7                move.l  (a4)-,0xbfd453f7
loc_197c2 29 cf                            .short 0x29cf
loc_197c4 f7 2e                            .short 0xf72e
loc_197c6 85 39 fe e7 b7 85                or.b d2,0xfee7b785
loc_197cc 39 f0                            .short 0x39f0
loc_197ce 85 2c dc e9                      or.b d2,(a4)(-8983)
loc_197d2 fa 85                            .short 0xfa85
loc_197d4 f2 3e                            .short 0xf23e
loc_197d6 4b fd                            .short 0x4bfd
loc_197d8 40 01                            negxb d1
loc_197da 38 2b f7 29                      move.w  (a3)(-2263),d4
loc_197de cf f7 29 cf 82 b9 80 dc          mulsw @0)@(ffffffff82b980dc),d7
loc_197e6 15 fc                            .short 0x15fc
loc_197e8 96 e7                            subaw -(sp),a3
loc_197ea fc 96                            .short 0xfc96
loc_197ec fd 57                            .short 0xfd57
loc_197ee 05 73 00 01                      bchg d2,(a3)1,d0.w)
loc_197f2 6b ff                            bmi.s   loc_197f3
loc_197f4 72 90                            moveq   #-112,d1
loc_197f6 fe cb                            .short 0xfecb
loc_197f8 bf 55                            eor.w d7,(a5)
loc_197fa fb 90                            .short 0xfb90
loc_197fc 00 00 58 37                      ori.b #55,d0
loc_19800 ea ad                            lsrl d5,d5
loc_19802 7c 2f                            moveq   #47,d6
loc_19804 82 f8 76 ae                      divu.w loc_76ae,d1
loc_19808 d4 82                            add.l d2,d2
loc_1980a 7e a1                            moveq   #-95,d7
loc_1980c 7c 8f                            moveq   #-113,d6
loc_1980e 92 ff                            .short 0x92ff
loc_19810 51 4f                            subq.w  #8,sp
loc_19812 dc a7                            add.l -(sp),d6
loc_19814 3f e4                            .short 0x3fe4
loc_19816 d2 14                            add.b (a4),d1
loc_19818 fd 57                            .short 0xfd57
loc_1981a ea 7b                            ror.w d5,d3
loc_1981c 78 3b                            moveq   #59,d4
loc_1981e f7 54                            .short 0xf754
loc_19820 b2 bf                            .short 0xb2bf
loc_19822 50 be                            .short 0x50be
loc_19824 47 c9                            .short 0x47c9
loc_19826 7f a8                            .short 0x7fa8
loc_19828 01 38 2b f9                      btst d0,loc_2bf9
loc_1982c 2d fa                            .short 0x2dfa
loc_1982e af dc                            .short 0xafdc
loc_19830 a7 3e                            .short 0xa73e
loc_19832 0a e6                            .short 0x0ae6
loc_19834 00 00 0a 7f                      ori.b #$7F,d0
loc_19838 e7 ff                            .short 0xe7ff
loc_1983a 3f fa                            .short 0x3ffa
loc_1983c 00 00 00 00                      ori.b #0,d0
loc_19840 01 ff                            .short 0x01ff
loc_19842 9f fc ff ea f8 5f                suba.l #-1378209,sp
loc_19848 05 f0 ed 5d                      bset d2,(a0)@0)
loc_1984c a9 04                            .short 0xa904
loc_1984e fd 42                            .short 0xfd42
loc_19850 f9 1f                            .short 0xf91f
loc_19852 25 fe                            .short 0x25fe
loc_19854 a0 00                            .short 0xa000
loc_19856 00 a7 fe 7f f3 ff                ori.l #-25168897,-(sp)
loc_1985c ab 5f                            .short 0xab5f
loc_1985e 0b fb                            .short 0x0bfb
loc_19860 78 2e                            moveq   #46,d4
loc_19862 14 b2 bf 50                      move.b  (a2),(a2)
loc_19866 be 47                            cmp.w   d7,d7
loc_19868 c9 7f                            .short 0xc97f
loc_1986a a8 00                            .short 0xa800
loc_1986c 00 13 ff 3f                      ori.b #$3F,(a3)
loc_19870 f9 ff                            .short 0xf9ff
loc_19872 d0 00                            add.b d0,d0
loc_19874 00 3f                            .short 0x003f
loc_19876 eb 17                            roxlb #5,d7
loc_19878 d1 f4 7d 1f 17 c5 f1 7c          adda.l (a4)@(0000000017c5f17c,d7:l:4),a0
loc_19880 5f 17                            subq.b  #7,(sp)
loc_19882 d1 f4 7d 1f 17 c5 f1 7c          adda.l (a4)@(0000000017c5f17c,d7:l:4),a0
loc_1988a 5f 17                            subq.b  #7,(sp)
loc_1988c d1 f4 7d 1f 17 c5 f1 7c          adda.l (a4)@(0000000017c5f17c,d7:l:4),a0
loc_19894 5f 17                            subq.b  #7,(sp)
loc_19896 d1 f4 7d 1f ff 58 df 1b          adda.l (a4)@(ffffffffff58df1b,d7:l:4),a0
loc_1989e e3 7c                            rol.w d1,d4
loc_198a0 6f 8d                            ble.s   loc_1982f
loc_198a2 f1 17                            psave (sp)
loc_198a4 c5 f1 7c 5f                      mulsw (a1)(000000000000005f,d7:l:4),d2
loc_198a8 dc fa 3e 8f                      adda.w (pc)(loc_1d739),a6
loc_198ac 8b b4 7e 89                      orl d5,(a4)(ffffffffffffff89,d7:l:8)
loc_198b0 dc 00                            add.b d0,d6
loc_198b2 0d ff                            .short 0x0dff
loc_198b4 58 be                            .short 0x58be
loc_198b6 8f a3                            orl d7,(a3)-
loc_198b8 e8 fe                            .short 0xe8fe
loc_198ba e7 c5                            .short 0xe7c5
loc_198bc f1 7d                            .short 0xf17d
loc_198be 22 fa 3e 8f                      move.l  (pc)(loc_1d74f),(a1)+
loc_198c2 6d 1f                            blt.s   loc_198e3
loc_198c4 17 c5                            .short 0x17c5
loc_198c6 a2 fa                            .short 0xa2fa
loc_198c8 3d 7a 3e 2b d1 f7                move.w  (pc)(loc_1d6f5),(a6)(-11785)
loc_198ce c4 00                            and.b d0,d2
loc_198d0 00 1f f5 a3                      ori.b #-93,(sp)+
loc_198d4 e2 b8                            ror.l d1,d0
loc_198d6 be 2b 7d 1f                      cmp.b (a3)(32031),d7
loc_198da 14 7c                            .short 0x147c
loc_198dc 5f a3                            subql #7,(a3)-
loc_198de 3e 8f                            move.w sp,(sp)
loc_198e0 a3 e2                            .short 0xa3e2
loc_198e2 e7 c5                            .short 0xe7c5
loc_198e4 f1 7c                            .short 0xf17c
loc_198e6 59 f4 d1 bf 68 00 00 00 00 4d 15 dc  svs @(0000000068000000)@(00000000004d15dc,a5.w)
loc_198f2 be e5                            cmpa.w (a5)-,sp
loc_198f4 fe d0                            .short 0xfed0
loc_198f6 00 be                            .short 0x00be
loc_198f8 e4 fe                            .short 0xe4fe
loc_198fa 23 47 1d 31                      move.l  d7,(a1)(7473)
loc_198fe 8b bf                            .short 0x8bbf
loc_19900 88 df                            divu.w (sp)+,d4
loc_19902 c4 00                            and.b d0,d2
loc_19904 27 72 44 b4 26 fe                move.l  (a2)(ffffffffffffffb4,d4.w:4),(a3)(9982)
loc_1990a b3 a2                            eor.l d1,(a2)-
loc_1990c 5a 13                            addq.b  #5,(a3)
loc_1990e 7f 10                            .short 0x7f10
loc_19910 00 9f a8 4e 4f fc                ori.l #-1471262724,(sp)+
loc_19916 c3 db                            mulsw (a3)+,d1
loc_19918 fa 4e                            .short 0xfa4e
loc_1991a e4 ff                            .short 0xe4ff
loc_1991c cc 3d                            .short 0xcc3d
loc_1991e bf 90                            eor.l d7,(a0)
loc_19920 00 4e                            .short 0x004e
loc_19922 e4 8b                            lsrl #2,d3
loc_19924 f4 7b                            .short 0xf47b
loc_19926 7f 49                            .short 0x7f49
loc_19928 d1 7e                            .short 0xd17e
loc_1992a 8f 6f e2 00                      or.w d7,(sp)(-7680)
loc_1992e 13 b9 23 db a7 6b 7f 5d          move.b 0x23dba76b,(a1)@0)
loc_19936 d1 ed d3 b5                      adda.l (a5)(-11339),a0
loc_1993a bf 88                            cmpm.l (a0)+,(sp)+
loc_1993c c0 00                            and.b d0,d0


; POINTS

loc_1993e: 80 53                            or.w (a3),d0
loc_19940 80 03                            or.b d3,d0
loc_19942 00 14 04 25                      ori.b #37,(a4)
loc_19946 0e 35                            .short 0x0e35
loc_19948 13 45 19 55                      move.b  d5,(a1)(6485)
loc_1994c 16 66                            .short 0x1666
loc_1994e 34 74 05 81                      movea.w @0,d0.w:4)@0),a2
loc_19952 05 0f 16 38                      movepw (sp)(5688),d2
loc_19956 82 05                            or.b d5,d1
loc_19958 17 17                            move.b  (sp),(a3)-
loc_1995a 73 83                            .short 0x7383
loc_1995c 05 12                            btst d2,(a2)
loc_1995e 17 74 84 05 14 85                move.b  (a4)5,a0.w:4),(a3)(5253)
loc_19964 07 75 86 05                      bchg d3,(a5)5,a0.w:8)
loc_19968 18 87                            move.b  d7,(a4)
loc_1996a 05 15                            btst d2,(a5)
loc_1996c 16 37 26 35                      move.b  (sp)(0000000000000035,d2.w:8),d3
loc_19970 38 f3 88 27                      move.w  (a3)(0000000000000027,a0:l),(a4)+
loc_19974 72 38                            moveq   #$38,d1
loc_19976 f4 89                            .short 0xf489
loc_19978 08 f0 8a 08 f7 8b 04 06 17 76    bset    #8,@0,sp.w:8)@(0000000004061776)
loc_19982 8d 07                            sbcd d7,d6
loc_19984 77 8e                            .short 0x778e
loc_19986 04 08                            .short 0x0408
loc_19988 8f 03                            sbcd d3,d7
loc_1998a 01 16                            btst d0,(a6)
loc_1998c 36 38 f5 58                      move.w  ($FFFFf558,d3
loc_19990 f2 78                            .short 0xf278
loc_19992 f1 ff                            .short 0xf1ff
loc_19994 4f ef 08 1f                      lea     (sp)(2079),sp
loc_19998 cf 42                            exg d7,d2
loc_1999a 9b e6                            suba.l (a6)-,a5
loc_1999c ba 55                            cmp.w (a5),d5
loc_1999e 72 6d                            moveq   #109,d1
loc_199a0 03 6f cc 1f                      bchg d1,(sp)(-13281)
loc_199a4 cf 5b                            and.w d7,(a3)+
loc_199a6 c7 51                            and.w d3,(a1)
loc_199a8 aa 55                            .short 0xaa55
loc_199aa d5 55                            add.w   d2,(a5)
loc_199ac 75 5d                            .short 0x755d
loc_199ae 54 e4                            scc (a4)-
loc_199b0 79 11                            .short 0x7911
loc_199b2 fe e1                            .short 0xfee1
loc_199b4 16 2a ab a1                      move.b  (a2)(-21599),d3
loc_199b8 58 b7 ff a0 79 02                addq.l #4,@(0000000000007902,sp:l:8)
loc_199be 3c e7                            move.w -(sp),(a6)+
loc_199c0 bd b7 d3 54                      eor.l d6,(sp)@0)
loc_199c4 29 a8 80 7d 0c 69                move.l  (a0)(-32643),(a4)(0000000000000069,d0:l:4)
loc_199ca e3 a8                            lsl.l d1,d0
loc_199cc d5 2a ea aa                      add.b d2,(a2)(-5462)
loc_199d0 ba ae aa 72                      cmp.l (a6)(-21902),d5
loc_199d4 3c 88                            move.w  a0,(a6)
loc_199d6 ff 70                            .short 0xff70
loc_199d8 8b 15                            or.b d5,(a5)
loc_199da 55 d0                            scs (a0)
loc_199dc ac 5b                            .short 0xac5b
loc_199de ff d0                            .short 0xffd0
loc_199e0 3c 81                            move.w  d1,(a6)
loc_199e2 1e 73                            .short 0x1e73
loc_199e4 de db                            adda.w (a3)+,sp
loc_199e6 db 79 91 bb a0 1f                add.w   d5,0x91bba01f
loc_199ec 43 1a                            chkl (a2)+,d1
loc_199ee 78 ea                            moveq   #-22,d4
loc_199f0 35 4a ba aa                      move.w  a2,(a2)(-17750)
loc_199f4 ae ab                            .short 0xaeab
loc_199f6 aa 9c                            .short 0xaa9c
loc_199f8 8f 22                            or.b d7,(a2)-
loc_199fa 3f dc                            .short 0x3fdc
loc_199fc 22 c5                            move.l  d5,(a1)+
loc_199fe 55 74 2b 16 ff f4                subq.w  #2,(a4)@(fffffffffffffff4,d2:l:2)
loc_19a04 0f 20                            btst d7,(a0)-
loc_19a06 5d be                            .short 0x5dbe
loc_19a08 6b 6d                            bmi.s   loc_19a77
loc_19a0a f4 ac                            .short 0xf4ac
loc_19a0c c8 dd                            mulu.w (a5)+,d4
loc_19a0e d0 3f                            .short 0xd03f
loc_19a10 5f f9 83 1a 78 ea                sle 0x831a78ea
loc_19a16 35 4a ba aa                      move.w  a2,(a2)(-17750)
loc_19a1a ae ab                            .short 0xaeab
loc_19a1c aa 9c                            .short 0xaa9c
loc_19a1e 8f 22                            or.b d7,(a2)-
loc_19a20 3f dc                            .short 0x3fdc
loc_19a22 22 c5                            move.l  d5,(a1)+
loc_19a24 55 74 2b 16 ff f4                subq.w  #2,(a4)@(fffffffffffffff4,d2:l:2)
loc_19a2a 0f 20                            btst d7,(a0)-
loc_19a2c 47 9e                            chkw (a6)+,d3
loc_19a2e 75 ce                            .short 0x75ce
loc_19a30 b3 de                            cmpal (a6)+,a1
loc_19a32 64 6e                            bcc.s   loc_19aa2
loc_19a34 e8 07                            asrb #4,d7
loc_19a36 d0 c6                            adda.w d6,a0
loc_19a38 9e 3a 8d 52                      sub.b (pc)(loc_1278c),d7
loc_19a3c ae aa                            .short 0xaeaa
loc_19a3e ab aa                            .short 0xabaa
loc_19a40 ea a7                            asr.l d5,d7
loc_19a42 23 c8 8f f7 08 b1                move.l  a0,0x8ff708b1
loc_19a48 55 5d                            subq.w  #2,(a5)+
loc_19a4a 0a c5                            .short 0x0ac5
loc_19a4c bf fd                            .short 0xbffd
loc_19a4e 03 c8 11 e7                      movepl d1,(a0)(4583)
loc_19a52 9d ed bd b7                      suba.l (a5)(-16969),a6
loc_19a56 71 4d                            .short 0x714d
loc_19a58 d2 01                            add.b d1,d1
loc_19a5a f4 31                            .short 0xf431
loc_19a5c a7 8e                            .short 0xa78e
loc_19a5e a3 54                            .short 0xa354
loc_19a60 ab aa                            .short 0xabaa
loc_19a62 aa ea                            .short 0xaaea
loc_19a64 ba a9 c8 f2                      cmp.l (a1)(-14094),d5
loc_19a68 23 fd                            .short 0x23fd
loc_19a6a c2 2c 55 57                      and.b (a4)(21847),d1
loc_19a6e 42 b1 68 1f                      clr.l (a1)(000000000000001f,d6:l)
loc_19a72 de 10                            add.b (a0),d7
loc_19a74 3f 9e 85 37 cd 74 aa e4 da 06 df 98  move.w  (a6)+,(sp)(ffffffffcd74aae4)@(ffffffffda06df98,a0.w:4)
loc_19a80 3f 9e b7 8e a3 54                move.w  (a6)+,@0)@(ffffffffffffa354,a3.w:8)
loc_19a86 ab aa                            .short 0xabaa
loc_19a88 aa ea                            .short 0xaaea
loc_19a8a ba a9 c8 f2                      cmp.l (a1)(-14094),d5
loc_19a8e 39 fd                            .short 0x39fd
loc_19a90 77 a8                            .short 0x77a8
loc_19a92 84 d4                            divu.w (a4),d2
loc_19a94 19 d5                            .short 0x19d5
loc_19a96 57 4a                            subq.w  #3,a2
loc_19a98 a1 77                            .short 0xa177
loc_19a9a 22 21                            move.l  (a1)-,d1
loc_19a9c 22 7f                            .short 0x227f
loc_19a9e be 1e                            cmp.b (a6)+,d7
loc_19aa0 40 8f                            .short 0x408f
loc_19aa2 39 ef                            .short 0x39ef
loc_19aa4 6d f4                            blt.s   loc_19a9a
loc_19aa6 d5 0a                            addxb (a2)-,(a2)-
loc_19aa8 6a 20                            bpl.s   loc_19aca
loc_19aaa 1f 43 1a 78                      move.b  d3,(sp)(6776)
loc_19aae ea 35                            roxrb d5,d5
loc_19ab0 4a ba                            .short 0x4aba
loc_19ab2 aa ae                            .short 0xaaae
loc_19ab4 ab aa                            .short 0xabaa
loc_19ab6 9c 8f                            sub.l sp,d6
loc_19ab8 23 9f d7 7a 88 4d 41 9d 55 74    move.l  (sp)+,(a1)(ffffffff884d419d)@(0000000000005574)
loc_19ac2 aa 17                            .short 0xaa17
loc_19ac4 72 22                            moveq   #34,d1
loc_19ac6 12 27                            move.b -(sp),d1
loc_19ac8 fb e1                            .short 0xfbe1
loc_19aca e4 08                            lsr.b #2,d0
loc_19acc f3 9e                            .short 0xf39e
loc_19ace f6 de                            .short 0xf6de
loc_19ad0 db cc                            adda.l a4,a5
loc_19ad2 8d dd                            divsw (a5)+,d6
loc_19ad4 00 fa                            .short 0x00fa
loc_19ad6 18 d3                            move.b  (a3),(a4)+
loc_19ad8 c7 51                            and.w d3,(a1)
loc_19ada aa 55                            .short 0xaa55
loc_19adc d5 55                            add.w   d2,(a5)
loc_19ade 75 5d                            .short 0x755d
loc_19ae0 54 e4                            scc (a4)-
loc_19ae2 79 1c                            .short 0x791c
loc_19ae4 fe bb                            .short 0xfebb
loc_19ae6 d4 42                            add.w   d2,d2
loc_19ae8 6a 0c                            bpl.s   loc_19af6
loc_19aea ea ab                            lsrl d5,d3
loc_19aec a5 50                            .short 0xa550
loc_19aee bb 91                            eor.l d5,(a1)
loc_19af0 10 91                            move.b  (a1),(a0)
loc_19af2 3f df                            .short 0x3fdf
loc_19af4 0f 20                            btst d7,(a0)-
loc_19af6 47 9e                            chkw (a6)+,d3
loc_19af8 75 ce                            .short 0x75ce
loc_19afa b3 de                            cmpal (a6)+,a1
loc_19afc 64 6e                            bcc.s   loc_19b6c
loc_19afe e8 07                            asrb #4,d7
loc_19b00 d0 c6                            adda.w d6,a0
loc_19b02 9e 3a 8d 52                      sub.b (pc)(loc_12856),d7
loc_19b06 ae aa                            .short 0xaeaa
loc_19b08 ab aa                            .short 0xabaa
loc_19b0a ea a7                            asr.l d5,d7
loc_19b0c 23 c8 e7 f5 de a2                move.l  a0,0xe7f5dea2
loc_19b12 13 50 67 55                      move.b  (a0),(a1)(26453)
loc_19b16 5d 2a 85 dc                      subq.b  #6,(a2)(-31268)
loc_19b1a 88 84                            orl d4,d4
loc_19b1c fe 72                            .short 0xfe72
loc_19b1e aa ad                            .short 0xaaad
loc_19b20 8b 6c e2 fe                      or.w d5,(a4)(-7426)
loc_19b24 bc 10                            cmp.b (a0),d6
loc_19b26 5f 2e ba 75                      subq.b  #7,(a6)(-17803)
loc_19b2a 0f 05                            btst d7,d5
loc_19b2c f5 90                            .short 0xf590
loc_19b2e ab dd                            .short 0xabdd
loc_19b30 2a 89                            move.l  a1,(a5)
loc_19b32 56 74 90 a8                      addq.w  #3,(a4)(ffffffffffffffa8,a1.w)
loc_19b36 2f a2 51 e9 77 f4                move.l  (a2)-,@(00000000000077f4)@0)
loc_19b3c 78 ea                            moveq   #-22,d4
loc_19b3e 2a 7f                            .short 0x2a7f
loc_19b40 3c 6e 9e f3                      movea.w (a6)(-24845),a6
loc_19b44 c6 8d                            .short 0xc68d
loc_19b46 ef a1                            asl.l d7,d1
loc_19b48 b1 7e                            .short 0xb17e
loc_19b4a 48 78 84 3f                      pea ($FFFF843f
loc_19b4e a2 11                            .short 0xa211
loc_19b50 b0 bc ff 5e 2f 8b                cmp.l #-10604661,d0
loc_19b56 51 3f                            .short 0x513f
loc_19b58 9f d8                            suba.l (a0)+,sp
loc_19b5a fe 8b                            .short 0xfe8b
loc_19b5c 05 2e 94 93                      btst d2,(a6)(-27501)
loc_19b60 d2 fd                            .short 0xd2fd
loc_19b62 2a 85                            move.l  d5,(a5)
loc_19b64 38 14                            move.w  (a4),d4
loc_19b66 79 0f                            .short 0x790f
loc_19b68 47 c1                            .short 0x47c1
loc_19b6a 48 22                            nbcd (a2)-
loc_19b6c 93 60                            sub.w   d1,(a0)-
loc_19b6e 68 ce                            bvcs loc_19b3e
loc_19b70 64 2c                            bcc.s   loc_19b9e
loc_19b72 8d 96                            orl d6,(a6)
loc_19b74 14 9f                            move.b  (sp)+,(a2)
loc_19b76 62 f9                            bhi.s   loc_19b71
loc_19b78 b1 0f                            cmpmb (sp)+,(a0)+
loc_19b7a 99 e6                            suba.l (a6)-,a4
loc_19b7c f1 00                            .short 0xf100
loc_19b7e be 4e                            cmp.w a6,d7
loc_19b80 82 38 c7 54                      or.b ($FFFFC754,d1
loc_19b84 f5 ec                            .short 0xf5ec
loc_19b86 18 34 ce 3b                      move.b  (a4)(000000000000003b,a4:l:8),d4
loc_19b8a e3 c0                            .short 0xe3c0
loc_19b8c a5 d2                            .short 0xa5d2
loc_19b8e 92 79 17 e9 5c f0                sub.w 0x17e95cf0,d1
loc_19b94 28 f2 eb f0 50 a5 0e 71          move.l @(0000000050a50e71),(a4)+
loc_19b9c 63 d9                            bls.s   loc_19b77
loc_19b9e cd 96                            and.l   d6,(a6)
loc_19ba0 14 9f                            move.b  (sp)+,(a2)
loc_19ba2 62 f9                            bhi.s   loc_19b9d
loc_19ba4 b1 b1 7d de 20 17                eor.l d0,@0)@(0000000000002017)
loc_19baa 5c 41                            addq.w  #6,d1
loc_19bac 47 df                            .short 0x47df
loc_19bae 09 b0 fc a2                      bclr d4,(a0)(ffffffffffffffa2,sp:l:4)
loc_19bb2 30 63                            movea.w (a3)-,a0
loc_19bb4 fa b3                            .short 0xfab3
loc_19bb6 8e f8 f7 29                      divu.w ($FFFFf729,d7
loc_19bba 74 a0                            moveq   #-96,d2
loc_19bbc 79 1f                            .short 0x791f
loc_19bbe a3 ac                            .short 0xa3ac
loc_19bc0 9d c0                            suba.l d0,a6
loc_19bc2 7d 5e                            .short 0x7d5e
loc_19bc4 52 fd                            .short 0x52fd
loc_19bc6 44 14                            negb (a4)
loc_19bc8 23 07                            move.l  d7,(a1)-
loc_19bca 3f 9d 54 3d                      move.w  (a5)+,(sp)(000000000000003d,d5.w:4)
loc_19bce ad 47                            .short 0xad47
loc_19bd0 7e bc                            moveq   #-68,d7
loc_19bd2 5f 02                            subq.b  #7,d2
loc_19bd4 36 7d                            .short 0x367d
loc_19bd6 dd 09                            addxb (a1)-,(a6)-
loc_19bd8 12 e7                            move.b -(sp),(a1)+
loc_19bda 98 e2                            subaw (a2)-,a4
loc_19bdc d0 b0 c8 59                      add.l (a0)(0000000000000059,a4:l),d0
loc_19be0 cc 0d                            .short 0xcc0d
loc_19be2 19 d0                            .short 0x19d0
loc_19be4 45 26                            chkl (a6)-,d2
loc_19be6 f4 7c                            .short 0xf47c
loc_19be8 4f 81                            chkw d1,d7
loc_19bea 48 4b                            .short 0x484b
loc_19bec f4 a8                            .short 0xf4a8
loc_19bee 84 92                            orl (a2),d2
loc_19bf0 52 4e                            addq.w  #1,a6
loc_19bf2 8f d1                            divsw (a1),d7
loc_19bf4 78 4f                            moveq   #79,d4
loc_19bf6 f5 f6                            .short 0xf5f6
loc_19bf8 f5 ec                            .short 0xf5ec
loc_19bfa 20 8e                            move.l  a6,(a0)
loc_19bfc 31 d4 40 22                      move.w  (a4),loc_4022
loc_19c00 56 89                            addq.l #3,a1
loc_19c02 5d f3 68 e2                      slt (a3)(ffffffffffffffe2,d6:l)
loc_19c06 7d a2                            .short 0x7da2
loc_19c08 cc 3a 83 d9                      and.b (pc)(loc_11fe3),d6
loc_19c0c cc 98                            and.l (a0)+,d6
loc_19c0e c9 4a                            exg a4,a2
loc_19c10 1c df                            move.b  (sp)+,(a6)+
loc_19c12 82 ee 05 1e                      divu.w (a6)(1310),d1
loc_19c16 97 e9 51 09                      suba.l (a1)(20745),a3
loc_19c1a 24 a4                            move.l  (a4)-,(a2)
loc_19c1c 9d 18                            sub.b d6,(a0)+
loc_19c1e ef 8f                            lsl.l #7,d7
loc_19c20 09 b0 63 fa b4 d8 7e 51 20 a3    bclr d4,@(ffffffffb4d87e51)@(00000000000020a3)
loc_19c2a ef 81                            asl.l #7,d1
loc_19c2c 00 bd                            .short 0x00bd
loc_19c2e 2f 38 17 7c                      move.l loc_177c,-(sp)
loc_19c32 da 1f                            add.b (sp)+,d5
loc_19c34 9e d1                            subaw (a1),sp
loc_19c36 66 1d                            bne.s   loc_19c55
loc_19c38 74 61                            moveq   #97,d2
loc_19c3a f9 dc                            .short 0xf9dc
loc_19c3c 91 83                            subxl d3,d0
loc_19c3e 9b f5 10 ee                      suba.l (a5)(ffffffffffffffee,d1.w),a5
loc_19c42 03 eb 09 fa                      bset d1,(a3)(2554)
loc_19c46 3a ca                            move.w  a2,(a5)+
loc_19c48 12 49                            .short 0x1249
loc_19c4a 49 c6                            .short 0x49c6
loc_19c4c 3b e3                            .short 0x3be3
loc_19c4e de 6c 19 74                      add.w (a4)(6516),d7
loc_19c52 8c f8 7b d2                      divu.w loc_7bd2,d6
loc_19c56 11 8d                            .short 0x118d
loc_19c58 25 40 5a 89                      move.l  d0,(a2)(23177)
loc_19c5c 40 f1 43 62 0c 83 c3 c3          move.w sr,(a1)(0000000000000c83)@(ffffffffffffc3c3)
loc_19c64 24 85                            move.l  d5,(a2)
loc_19c66 e4 c9                            .short 0xe4c9
loc_19c68 13 a3 a1 e2 e2 8e 89 0d          move.b  (a3)-,@(ffffffffffffe28e)@(ffffffffffff890d)
loc_19c70 a7 0b                            .short 0xa70b
loc_19c72 a4 1b                            .short 0xa41b
loc_19c74 42 ad a0 cf                      clr.l (a5)(-24369)
loc_19c78 c3 de                            mulsw (a6)+,d1
loc_19c7a 8f 28 d4 95                      or.b d7,(a0)(-11115)
loc_19c7e 13 f5 62 81 f7 c0 69 f3          move.b  (a5)(ffffffffffffff81,d6.w:2),0xf7c069f3
loc_19c86 a3 48                            .short 0xa348
loc_19c88 3d 36 61 21 c3 06                move.w  (a6)(ffffffffffffc306,d6.w)@0),(a6)-
loc_19c8e 84 e8 e6 87                      divu.w (a0)(-6521),d2
loc_19c92 89 51                            or.w d4,(a1)
loc_19c94 3b 44 b2 c2                      move.w  d4,(a5)(-19774)
loc_19c98 1f a1 d2 0d                      move.b  (a1)-,(sp)d,a5.w:2)
loc_19c9c a1 55                            .short 0xa155
loc_19c9e 55 cc 36 9b                      dbcs d4,loc_1d33b
loc_19ca2 1e 65                            .short 0x1e65
loc_19ca4 c7 1b                            and.b d3,(a3)+
loc_19ca6 dc 86                            add.l d6,d6
loc_19ca8 15 e9                            .short 0x15e9
loc_19caa 44 64                            neg.w (a4)-
loc_19cac df 01                            addxb d1,d7
loc_19cae 92 41                            sub.w   d1,d1
loc_19cb0 ee 23                            asrb d7,d3
loc_19cb2 a7 39                            .short 0xa739
loc_19cb4 bc 74 0c 1f                      cmp.w (a4)(000000000000001f,d0:l:4),d6
loc_19cb8 cf 84                            .short 0xcf84
loc_19cba 7c 83                            moveq   #-125,d6
loc_19cbc d0 87                            add.l d7,d0
loc_19cbe df 1d                            add.b d7,(a5)+
loc_19cc0 41 4d                            .short 0x414d
loc_19cc2 92 99                            sub.l (a1)+,d1
loc_19cc4 fd 5a                            .short 0xfd5a
loc_19cc6 a3 68                            .short 0xa368
loc_19cc8 d6 6d 18 ad                      add.w (a5)(6317),d3
loc_19ccc 98 d9                            subaw (a1)+,a4
loc_19cce 97 4d                            subxw (a5)-,(a3)-
loc_19cd0 b2 6f 89 9b                      cmp.w (sp)(-30309),d1
loc_19cd4 d5 72 6f 2a cd 8e 1f 36          add.w   d2,(a2)(ffffffffffffcd8e,d6:l:8)@(0000000000001f36)
loc_19cdc 06 87 b4 d8 7e 53                addi.l  #-1260880301,d7
loc_19ce2 6c dd                            bge.s   loc_19cc1
loc_19ce4 e0 a3                            asr.l d0,d3
loc_19ce6 f2 58                            .short 0xf258
loc_19ce8 3c 48                            movea.w a0,a6
loc_19cea 3e 89                            move.w  a1,(sp)
loc_19cec d3 9c                            add.l d1,(a4)+
loc_19cee 91 f7 78 90                      suba.l (sp)(ffffffffffffff90,d7:l),a0
loc_19cf2 a3 6c                            .short 0xa36c
loc_19cf4 8f 93                            orl d7,(a3)
loc_19cf6 9b 60                            sub.w   d5,(a0)-
loc_19cf8 f2 8c 1b 66                      fbult loc_1b860
loc_19cfc 9b 23                            sub.b d5,(a3)-
loc_19cfe 2a aa ac ff                      move.l  (a2)(-21249),(a5)
loc_19d02 57 9a                            subql #3,(a2)+
loc_19d04 26 c8                            move.l  a0,(a3)+
loc_19d06 47 5c                            .short 0x475c
loc_19d08 5d e0                            slt (a0)-
loc_19d0a a3 c4                            .short 0xa3c4
loc_19d0c 9e 9c                            sub.l (a4)+,d7
loc_19d0e 73 78                            .short 0x7378
loc_19d10 61 d0                            bsr.s   loc_19ce2
loc_19d12 3e 7c fa 02                      movea.w #-1534,sp
loc_19d16 e7 89                            lsl.l #3,d1
loc_19d18 23 6d fa e2 8d 62                move.l  (a5)(-1310),(a1)(-29342)
loc_19d1e cb 62                            and.w d5,(a2)-
loc_19d20 da 35 9b 46 55 55                add.b (a5)@(0000000000005555),d5
loc_19d26 55 56                            subq.w  #2,(a6)
loc_19d28 46 9b                            notl (a3)+
loc_19d2a 6c c1                            bge.s   loc_19ced
loc_19d2c 90 bc 6c ce 93 d3                sub.l #1825477587,d0
loc_19d32 66 a0                            bne.s   loc_19cd4
loc_19d34 90 7d                            .short 0x907d
loc_19d36 de 92                            add.l (a2),d7
loc_19d38 e7 d1                            rol.w (a1)
loc_19d3a 28 f1 20 f0                      move.l  (a1)(fffffffffffffff0,d2.w),(a4)+
loc_19d3e c7 2f 42 1f                      and.b d3,(sp)(16927)
loc_19d42 7c ed                            moveq   #-19,d6
loc_19d44 fa 47                            .short 0xfa47
loc_19d46 14 69                            .short 0x1469
loc_19d48 91 43                            subxw d3,d0
loc_19d4a 47 6c                            .short 0x476c
loc_19d4c 1f 77 14 7c a6 69                move.b  (sp)(000000000000007c,d1.w:4),(sp)(-22935)
loc_19d52 c2 e5                            mulu.w (a5)-,d1
loc_19d54 ba 9b                            cmp.l (a3)+,d5
loc_19d56 33 99 19 20 d3 66                move.w  (a1)+,(a1)(ffffffffffffd366,d1:l)
loc_19d5c 49 3d                            .short 0x493d
loc_19d5e c5 2e f1 c2                      and.b d2,(a6)(-3646)
loc_19d62 32 3c 4a e5                      move.w  #19173,d1
loc_19d66 94 bb a0 62                      sub.l (pc)(loc_19dca,a2.w),d2
loc_19d6a 1f a8 67 91 d0 11                move.b  (a0)(26513),(sp)(0000000000000011,a5.w)
loc_19d70 d4 1f                            add.b (sp)+,d2
loc_19d72 ca f8 23 26                      mulu.w loc_2326,d5
loc_19d76 ca aa aa aa                      and.l (a2)(-21846),d5
loc_19d7a aa 41                            .short 0xaa41
loc_19d7c 99 42                            subxw d2,d4
loc_19d7e 9d 90                            sub.l d6,(a0)
loc_19d80 b0 6f ca 87                      cmp.w (sp)(-13689),d0
loc_19d84 86 0d                            .short 0x860d
loc_19d86 fa 19                            .short 0xfa19
loc_19d88 06 2e 78 7b 02 e9                addi.b #123,(a6)(745)
loc_19d8e 3d 3f                            .short 0x3d3f
loc_19d90 42 1e                            clr.b (a6)+
loc_19d92 1b 0e                            .short 0x1b0e
loc_19d94 7a 32                            moveq   #50,d5
loc_19d96 74 57                            moveq   #87,d2
loc_19d98 82 d8                            divu.w (a0)+,d1
loc_19d9a 7f 3d                            .short 0x7f3d
loc_19d9c 83 1a                            or.b d1,(a2)+
loc_19d9e 6c d3                            bge.s   loc_19d73
loc_19da0 64 60                            bcc.s   loc_19e02
loc_19da2 d1 66                            add.w   d0,(a6)-
loc_19da4 8d 0d                            sbcd (a5)-,(a6)-
loc_19da6 8f 55                            or.w d7,(a5)
loc_19da8 b1 96                            eor.l d0,(a6)
loc_19daa 9e 0a                            .short 0x9e0a
loc_19dac e6 46                            asrw #3,d6
loc_19dae 9b 6d 42 c3                      sub.w   d5,(a5)(17091)
loc_19db2 6e 6f                            bgt.s   loc_19e23
loc_19db4 c3 10                            and.b d1,(a0)
loc_19db6 f5 e8                            .short 0xf5e8
loc_19db8 8c 8f                            .short 0x8c8f
loc_19dba 76 18                            moveq   #$18d3
loc_19dbc 3c 7e                            .short 0x3c7e
loc_19dbe 85 1f                            or.b d2,(sp)+
loc_19dc0 27 14                            move.l  (a4),(a3)-
loc_19dc2 8e ff                            .short 0x8eff
loc_19dc4 af 05                            .short 0xaf05
loc_19dc6 7c 34                            moveq   #$34,d6
loc_19dc8 91 5b                            sub.w   d0,(a3)+
loc_19dca 75 36                            .short 0x7536
loc_19dcc 3a 43                            movea.w d3,a5
loc_19dce 5a 19                            addq.b  #5,(a1)+
loc_19dd0 46 d9                            move.w  (a1)+,sr
loc_19dd2 3c 17                            move.w  (sp),d6
loc_19dd4 1c 74                            .short 0x1c74
loc_19dd6 c1 0c                            abcd (a4)-,(a0)-
loc_19dd8 f9 24                            .short 0xf924
loc_19dda 9e c1                            subaw d1,sp
loc_19ddc f4 4a                            .short 0xf44a
loc_19dde 3f 0c                            move.w  a4,-(sp)
loc_19de0 9d 12                            sub.b d6,(a2)
loc_19de2 4e 97                            jsr     (sp)
loc_19de4 54 81                            addq.l #2,d1
loc_19de6 41 2c 65 e8                      chkl (a4)(26088),d0
loc_19dea f2 8c 98 d3                      fbult loc_136bf
loc_19dee 19 2f c5 8d                      move.b  (sp)(-14963),(a4)-
loc_19df2 0d 8b 68 ca                      movepw d6,(a3)(26826)
loc_19df6 aa aa                            .short 0xaaaa
loc_19df8 b3 2d b3 88                      eor.b d1,(a5)(-19576)
loc_19dfc c5 c1                            mulsw d1,d2
loc_19dfe 73 f1                            .short 0x73f1
loc_19e00 27 cd                            .short 0x27cd
loc_19e02 f4 e1                            .short 0xf4e1
loc_19e04 08 7d                            .short 0x087d
loc_19e06 38 04                            move.w  d4,d4
loc_19e08 3c 62                            movea.w (a2)-,a6
loc_19e0a 41 ee 96 04                      lea     (a6)(-27132),a0
loc_19e0e a7 2c                            .short 0xa72c
loc_19e10 09 21                            btst d4,(a1)-
loc_19e12 78 c4                            moveq   #-60,d4
loc_19e14 83 cb                            .short 0x83cb
loc_19e16 51 f4 e2 9f                      sf (a4)(ffffffffffffff9f,a6.w:2)
loc_19e1a ab f5                            .short 0xabf5
loc_19e1c ec a3                            asr.l d6,d3
loc_19e1e f8 c9                            .short 0xf8c9
loc_19e20 8c e0                            divu.w (a0)-,d6
loc_19e22 63 f8                            bls.s   loc_19e1c
loc_19e24 98 4b                            sub.w a3,d4
loc_19e26 ba f3 b8 bd                      cmpa.w (a3)(ffffffffffffffbd,a3:l),a5
loc_19e2a ae aa                            .short 0xaeaa
loc_19e2c eb e7                            .short 0xebe7
loc_19e2e 9c f9 af e9 92 e3                subaw 0xafe992e3,a6
loc_19e34 1a 61                            .short 0x1a61
loc_19e36 e6 c6                            .short 0xe6c6
loc_19e38 2c 41                            movea.l d1,a6
loc_19e3a cc 84                            and.l   d4,d6
loc_19e3c 66 91                            bne.s   loc_19dcf
loc_19e3e 29 ef                            .short 0x29ef
loc_19e40 13 a4 92 49                      move.b  (a4)-,(a1)(0000000000000049,a1.w:2)
loc_19e44 49 52                            .short 0x4952
loc_19e46 27 24                            move.l  (a4)-,(a3)-
loc_19e48 ef 39                            rol.b d7,d1
loc_19e4a 24 a7                            move.l -(sp),(a2)
loc_19e4c 49 37 e3 38 99 b5 24 7f          chkl (sp)(ffffffff99b5247f,a6.w:2),d4
loc_19e54 3b 99 7e 32                      move.w  (a1)+,(a5)(0000000000000032,d7:l:8)
loc_19e58 eb 3a                            rol.b d5,d2
loc_19e5a db 9f                            add.l d5,(sp)+
loc_19e5c e5 59                            rol.w #2,d1
loc_19e5e 2e b9 ba f3 5e 6e                move.l 0xbaf35e6e,(sp)
loc_19e64 c2 e1                            mulu.w (a1)-,d1
loc_19e66 d7 9e                            add.l d3,(a6)+
loc_19e68 17 1a                            move.b  (a2)+,(a3)-
loc_19e6a 7e 59                            moveq   #89,d7
loc_19e6c c5 3f                            .short 0xc53f
loc_19e6e 2d a6 1d de e7 4e                move.l  (a6)-,@0)@(ffffffffffffe74e)
loc_19e74 f7 c3                            .short 0xf7c3
loc_19e76 a5 df                            .short 0xa5df
loc_19e78 a5 27                            .short 0xa527
loc_19e7a e1 5b                            rol.w #8,d3
loc_19e7c 56 cf fc 65                      dbne d7,loc_19ae3
loc_19e80 25 47 77 32                      move.l  d7,(a2)(30514)
loc_19e84 c9 e9 49 c9                      mulsw (a1)(18889),d4
loc_19e88 54 53                            addq.w  #2,(a3)
loc_19e8a 3f 95 fd 12 dd 54                move.w  (a5),(sp,sp:l:4)@(ffffffffffffdd54)
loc_19e90 5f 3c                            .short 0x5f3c
loc_19e92 e7 cd                            .short 0xe7cd
loc_19e94 7f 4c                            .short 0x7f4c
loc_19e96 97 18                            sub.b d3,(a0)+
loc_19e98 d3 0f                            addxb -(sp),(a1)-
loc_19e9a bd 8e                            cmpm.l (a6)+,(a6)+
loc_19e9c 87 4e                            .short 0x874e
loc_19e9e 87 34 8e f3                      or.b d3,(a4)(fffffffffffffff3,a0:l:8)
loc_19ea2 fc a4                            .short 0xfca4
loc_19ea4 4b 32 cd 25 19 90                chkl (a2)(0000000000001990)@0,a4:l:4),d5
loc_19eaa f0 5c                            .short 0xf05c
loc_19eac d6 54                            add.w (a4),d3
loc_19eae fc 63                            .short 0xfc63
loc_19eb0 e7 49                            lsl.w   #3,d1
loc_19eb2 1e f6 91 d2 4b 9a                move.b @0)@(0000000000004b9a),(sp)+
loc_19eb8 e7 f4 5f 95                      rol.w @0)@0,d5:l:8)
loc_19ebc 4b ae 6e bc                      chkw (a6)(28348),d5
loc_19ec0 d7 9b                            add.l d3,(a3)+
loc_19ec2 b0 b8 75 d6                      cmp.l loc_75d6,d0
loc_19ec6 78 d3                            moveq   #-45,d4
loc_19ec8 f2 d6 fd 33 8a 7e                fbgll 0xfffffffffd352948
loc_19ece 59 d1                            svs (a1)
loc_19ed0 7d 25                            .short 0x7d25
loc_19ed2 cf 31 49 56 7d f4                and.b d7,(a1)@(0000000000007df4)
loc_19ed8 92 49                            sub.w a1,d1
loc_19eda dc 37 e3 29 63 3f                add.b (sp)(000000000000633f,a6.w:2)@0),d6
loc_19ee0 ce 9c                            and.l (a4)+,d7
loc_19ee2 fe 32                            .short 0xfe32
loc_19ee4 f2 55                            .short 0xf255
loc_19ee6 a4 fa                            .short 0xa4fa
loc_19ee8 b7 5e                            eor.w d3,(a6)+
loc_19eea 6b 74                            bmi.s   loc_19f60
loc_19eec 00 00

; FLICKY TITLE SCREEN FONT

loc_19EEE:
80 39                      ori.b #57,d0
loc_19ef0 80 03                            or.b d3,d0
loc_19ef2 03 14                            btst d1,(a4)
loc_19ef4 0a 25 17 35                      eori.b #53,(a5)-
loc_19ef8 16 45                            .short 0x1645
loc_19efa 19 55 1a 65                      move.b  (a5),(a4)(6757)
loc_19efe 1b 73 00 81 03 02                move.b  (a3)(ffffffffffffff81,d0.w),(a5)(770)
loc_19f04 17 79 27 7b 82 04 08 83          move.b 0x277b8204,(a3)(2179)
loc_19f0c 05 18                            btst d2,(a0)+
loc_19f0e 17 78 84 03 01 16                move.b  ($FFFF8403,(a3)(278)
loc_19f14 3a 27                            move.w -(sp),d5
loc_19f16 7a 85                            moveq   #-123,d5
loc_19f18 06 3b                            .short 0x063b
loc_19f1a 86 04                            or.b d4,d3
loc_19f1c 09 87                            bclr d4,d7
loc_19f1e 05 1c                            btst d2,(a4)+
loc_19f20 ff bf                            .short 0xffbf
loc_19f22 f1 28 e8 b5                      psave (a0)(-5963)
loc_19f26 cf d3                            mulsw (a3),d7
loc_19f28 16 a5                            move.b  (a5)-,(a3)
loc_19f2a 56 1a                            addq.b  #3,(a2)+
loc_19f2c 95 7c                            .short 0x957c
loc_19f2e 01 9c                            bclr d0,(a4)+
loc_19f30 07 3b 80 00                      btst d3,(pc)(loc_19f32,a0.w)
loc_19f34 03 67                            bchg d1,-(sp)
loc_19f36 3e 37 e3 78 19 c3 20 00          move.w  (sp)(0000000019c32000),d7
loc_19f3e 05 f1 95 30 f1 30 5a 9e          bset d2,(a1)(fffffffff1305a9e,a1.w:4)
loc_19f46 4d fa f2 ff                      lea     (pc)(loc_19247),a6
loc_19f4a 89 7e                            .short 0x897e
loc_19f4c 87 fd                            .short 0x87fd
loc_19f4e bf e7                            cmpal -(sp),sp
loc_19f50 fe 31                            .short 0xfe31
loc_19f52 81 ff                            .short 0x81ff
loc_19f54 61 7f                            bsr.s   loc_19fd5
loc_19f56 e2 3e                            ror.b d1,d6
loc_19f58 80 1a                            or.b (a2)+,d0
loc_19f5a 23 fa 91 a8 3f d6 8f f1          move.l  (pc)(loc_13104),0x3fd68ff1
loc_19f62 cf f8 ff ed                      mulsw ($FFFFFFed,d7
loc_19f66 1b 87 fe 40                      move.b  d7,(a5)(0000000000000040,sp:l:8)
loc_19f6a 00 00 11 bf                      ori.b #-65,d0
loc_19f6e 40 da                            move.w sr,(a2)+
loc_19f70 62 8d                            bhi.s   loc_19eff
loc_19f72 8c 67                            or.w -(sp),d6
loc_19f74 1b c6                            .short 0x1bc6
loc_19f76 fa 8c                            .short 0xfa8c
loc_19f78 fe 4a                            .short 0xfe4a
loc_19f7a 8e 8d                            .short 0x8e8d
loc_19f7c bd 00                            eor.b d6,d0
loc_19f7e 00 c9                            .short 0x00c9
loc_19f80 07 50                            bchg d3,(a0)
loc_19f82 06 e0                            .short 0x06e0
loc_19f84 1d 10                            move.b  (a0),(a6)-
loc_19f86 00 00 00 2b                      ori.b #43,d0
loc_19f8a d5 fa bf ab                      adda.l (pc)(loc_15f37),a2
loc_19f8e fe 5a                            .short 0xfe5a
loc_19f90 29 72 7c 18 b6 00                move.l  (a2)(0000000000000018,d7:l:4),(a4)(-18944)
loc_19f96 00 00 00 00                      ori.b #0,d0
loc_19f9a 0f 07                            btst d7,d7
loc_19f9c 78 6a                            moveq   #106,d4
loc_19f9e 55 78 2d 4a                      subq.w  #2,loc_2d4a
loc_19fa2 b1 6b 9f a6                      eor.w d0,(a3)(-24666)
loc_19fa6 ae 87                            .short 0xae87
loc_19fa8 ed 01                            aslb #6,d1
loc_19faa 00 00 00 00                      ori.b #0,d0
loc_19fae 00 08                            .short loc_8
loc_19fb0 fe a5                            .short 0xfea5
loc_19fb2 7e 89                            moveq   #-119,d7
loc_19fb4 c3 ee 7d 49                      mulsw (a6)(32073),d1
loc_19fb8 8f f1 97 fc 36 7f 8c 79          divsw @(00000000367f8c79)@0),d7
loc_19fc0 19 fc                            .short 0x19fc
loc_19fc2 93 ff                            .short 0x93ff
loc_19fc4 a0 00                            .short 0xa000
loc_19fc6 00 00 00 00                      ori.b #0,d0
loc_19fca 00 20 ea 37                      ori.b #55,(a0)-
loc_19fce 00 e8                            .short 0x00e8
loc_19fd0 87 fc 4a 37                      divsw #18999,d3
loc_19fd4 87 d3                            divsw (a3),d3
loc_19fd6 5c 93                            addq.l #6,(a3)
loc_19fd8 14 a5                            move.b  (a5)-,(a2)
loc_19fda 61 98                            bsr.s   loc_19f74
loc_19fdc b7 80                            eor.l d3,d0
loc_19fde 00 00 00 06                      ori.b #6,d0
loc_19fe2 f0 00                            .short 0xf000
loc_19fe4 17 52 a8 c1                      move.b  (a2),(a3)(-22335)
loc_19fe8 6b 92                            bmi.s   loc_19f7c
loc_19fea 62 8d                            bhi.s   loc_19f79
loc_19fec e1 9a                            roll #8,d2
loc_19fee fe 20                            .short 0xfe20
loc_19ff0 64 00 00 00                      bccw loc_19ff2
loc_19ff4 00 00 00 01                      ori.b #1,d0
loc_19ff8 b2 06                            cmp.b d6,d1
loc_19ffa 8e 7a 56 2d                      or.w (pc)(loc_1f629),d7
loc_19ffe 4d ca                            .short 0x4dca
loc_1a000 fc ba                            .short 0xfcba
loc_1a002 a2 a5                            .short 0xa2a5
loc_1a004 5c b9 59 56 45 ca                addq.l #6,0x595645ca
loc_1a00a bf 6d 58 c0                      eor.w d7,(a5)(22720)
loc_1a00e 00 00 d0 b1                      ori.b #-79,d0
loc_1a012 82 e5                            divu.w (a5)-,d1
loc_1a014 5f ba                            .short 0x5fba
loc_1a016 56 4c                            addq.w  #3,a4
loc_1a018 b9 59                            eor.w d4,(a1)+
loc_1a01a 2a 56                            movea.l (a6),a5
loc_1a01c 4a fc                            illegal
loc_1a01e ba b1 6a 73                      cmp.l (a1)(0000000000000073,d6:l:2),d5
loc_1a022 d2 fe                            .short 0xd2fe
loc_1a024 a3 2b                            .short 0xa32b
loc_1a026 f4 f0                            .short 0xf4f0
loc_1a028 fa e7                            .short 0xfae7
loc_1a02a b3 c8                            cmpal a0,a1
loc_1a02c ce 23                            and.b (a3)-,d7
loc_1a02e b8 b7 88 ed                      cmp.l (sp)(ffffffffffffffed,a0:l),d4
loc_1a032 a9 e5                            .short 0xa9e5
loc_1a034 62 27                            bhi.s   loc_1a05d
loc_1a036 8d 73 6b 8a bf 68                or.w d6,@0,d6:l:2)@(ffffffffffffbf68)
loc_1a03c a7 ab                            .short 0xa7ab
loc_1a03e 1f 3a e8 01                      move.b  (pc)(loc_18841),-(sp)
loc_1a042 a3 d9                            .short 0xa3d9
loc_1a044 b1 bf                            .short 0xb1bf
loc_1a046 ed 17                            roxlb #6,d7
loc_1a048 0d bf                            .short 0x0dbf
loc_1a04a 2e 9c                            move.l  (a4)+,(sp)
loc_1a04c f1 f1                            .short 0xf1f1
loc_1a04e 59 4a                            subq.w  #4,a2
loc_1a050 ac 45                            .short 0xac45
loc_1a052 bc 47                            cmp.w   d7,d6
loc_1a054 76 c4                            moveq   #-60,d3
loc_1a056 77 1e                            .short 0x771e
loc_1a058 7f 2e                            .short 0x7f2e
loc_1a05a 79 0f                            .short 0x790f
loc_1a05c f2 fe                            .short 0xf2fe
loc_1a05e 62 bf                            bhi.s   loc_1a01f
loc_1a060 e8 19                            ror.b #4,d1
loc_1a062 07 50                            bchg d3,(a0)
loc_1a064 ce 7b 8d 2d a8 d7                and.w (pc)(loc_1493d)@0,a0:l:4),d7
loc_1a06a 03 39 e8 01 ae b4                btst d1,0xe801aeb4
loc_1a070 99 cc                            suba.l a4,a4
loc_1a072 ed 46                            asl.w #6,d6
loc_1a074 96 fb 8d 43 3a 3a 20 5f          subaw (pc)(loc_1a076)@(000000003a3a205f),a3
loc_1a07c f6 95                            .short 0xf695
loc_1a07e d7 9b                            add.l d3,(a3)+
loc_1a080 96 a4                            sub.l (a4)-,d3
loc_1a082 f7 75                            .short 0xf775
loc_1a084 2f 0e                            move.l  a6,-(sp)
loc_1a086 6c 80                            bge.s   loc_1a008
loc_1a088 00 07 80 00                      ori.b #0,d7
loc_1a08c 1b c0                            .short 0x1bc0
loc_1a08e 00 5d 4a c3                      ori.w #19139,(a5)+
loc_1a092 96 5a                            sub.w (a2)+,d3
loc_1a094 93 dd                            suba.l (a5)+,a1
loc_1a096 cb f3 9f ea 68 b3 62 a2          mulsw @(00000000000068b3)@(00000000000062a2),d5
loc_1a09e c5 4d                            exg a2,a5
loc_1a0a0 8a 95                            orl (a5),d5
loc_1a0a2 72 a5                            moveq   #-91,d1
loc_1a0a4 5c a9 56 52                      addq.l #6,(a1)(22098)
loc_1a0a8 ab 0d                            .short 0xab0d
loc_1a0aa 4a af 0e 55                      tst.l (sp)(3669)
loc_1a0ae f1 d2                            .short 0xf1d2
loc_1a0b0 b1 8c                            cmpm.l (a4)+,(a0)+
loc_1a0b2 98 1a                            sub.b (a2)+,d4
loc_1a0b4 30 ca                            move.w  a2,(a0)+
loc_1a0b6 b1 87                            eor.l d0,d7
loc_1a0b8 2a f8 2d 4a                      move.l loc_2d4a,(a5)+
loc_1a0bc af 14                            .short 0xaf14
loc_1a0be a5 56                            .short 0xa556
loc_1a0c0 28 a9 59 2a                      move.l  (a1)(22826),(a4)
loc_1a0c4 56 4a                            addq.w  #3,a2
loc_1a0c6 95 16                            sub.b d2,(a6)
loc_1a0c8 2a 59                            movea.l (a1)+,a5
loc_1a0ca b1 47                            eor.w d0,d7
loc_1a0cc 45 f5 93 5d                      lea     (a5)@0),a2
loc_1a0d0 5f cc 67 f4                      dble d4,loc_208c6
loc_1a0d4 f0 c8 bf 8a 35 e0                pbws 0xffffffffbf8bd6b6
loc_1a0da c5 b0 61 9b 98 66 d0 ce          and.l   d2,@0,d6.w)@(ffffffff9866d0ce)
loc_1a0e2 8e 88                            .short 0x8e88
loc_1a0e4 d9 07                            addxb d7,d4
loc_1a0e6 50 ce 4c 33                      dbt d6,loc_1ed1b
loc_1a0ea 6c 18                            bge.s   loc_1a104
loc_1a0ec 66 fe                            bne.s   loc_1a0ec
loc_1a0ee 0c 67 c5 11                      cmpi.w  #-15087,-(sp)
loc_1a0f2 49 e3                            .short 0x49e3
loc_1a0f4 33 c3 0c d7 6a 19                move.w  d3,0x0cd76a19
loc_1a0fa b7 a0                            eor.l d3,(a0)-
loc_1a0fc 1f ab 17 e6 e5 a9 36 53          move.b  (a3)(6118),@(0000000000003653,a6.w:4)@0)
loc_1a104 03 78 03 02                      bchg d1,loc_302
loc_1a108 ca 55                            and.w (a5),d5
loc_1a10a 88 6a 55 88                      or.w (a2)(21896),d4
loc_1a10e 6a 72                            bpl.s   loc_1a182
loc_1a110 5a d1                            spl (a1)
loc_1a112 04 00 06 7d                      subi.b #125,d0
loc_1a116 5f af 74 5a                      subql #7,(sp)(29786)
loc_1a11a fd 35                            .short 0xfd35
loc_1a11c d4 fb 17 53 cf 34 5a 7f          adda.w (pc)(loc_1a11e)@(ffffffffcf345a7f),a2
loc_1a124 96 bf                            .short 0x96bf
loc_1a126 5e f3 eb 7e 81 b9 73 46 e9 cc    sgt (a3)(ffffffff81b97346)@(ffffffffffffe9cc)
loc_1a130 00 03 39 8d                      ori.b #-115,d3
loc_1a134 cc 33 98 dc                      and.b (a3)(ffffffffffffffdc,a1:l),d6
loc_1a138 b8 d4                            cmpa.w (a4),a4
loc_1a13a 94 d6                            subaw (a6),a2
loc_1a13c 7f 2f                            .short 0x7f2f
loc_1a13e 2b 4a 56 94                      move.l  a2,(a5)(22164)
loc_1a142 f1 5c                            prestore (a4)+
loc_1a144 bf 33 e6 ba                      eor.b d7,(a3)(ffffffffffffffba,a6.w:8)
loc_1a148 6a 40                            bpl.s   loc_1a18a
loc_1a14a 55 d3                            scs (a3)
loc_1a14c 53 47                            subq.w  #1,d7
loc_1a14e dc aa 5f 96                      add.l (a2)(24470),d6
loc_1a152 e2 ac                            lsrl d1,d4
loc_1a154 73 cd                            .short 0x73cd
loc_1a156 f1 bc                            .short 0xf1bc
loc_1a158 45 bd                            .short 0x45bd
loc_1a15a f7 fb                            .short 0xf7fb
loc_1a15c 17 f9                            .short 0x17f9
loc_1a15e 58 fd                            .short 0x58fd
loc_1a160 37 e5                            .short 0x37e5
loc_1a162 7f 24                            .short 0x7f24
loc_1a164 7d fe                            .short 0x7dfe
loc_1a166 4b a6                            chkw (a6)-,d5
loc_1a168 76 6d                            moveq   #109,d3
loc_1a16a d5 7b                            .short 0xd57b
loc_1a16c b2 9e                            cmp.l (a6)+,d1
loc_1a16e 1e 43                            .short 0x1e43
loc_1a170 32 aa 3b 81                      move.w  (a2)(15233),(a1)
loc_1a174 6c 00 00 18                      bgew loc_1a18e
loc_1a178 17 40 01 58                      move.b  d0,(a3)(344)
loc_1a17c 43 b8 22 b1                      chkw loc_22b1,d1
loc_1a180 19 c5                            .short 0x19c5
loc_1a182 77 06                            .short 0x7706
loc_1a184 f1 9c                            .short 0xf19c
loc_1a186 57 70 6f 1a 87 dc                subq.w  #3,(a0,d6:l:8)@(ffffffffffff87dc)
loc_1a18c 1b 77 06 dd c1 cc                move.b  (sp)(ffffffffffffffdd,d0.w:8),(a5)(-15924)
loc_1a192 1d 11                            move.b  (a1),(a6)-
loc_1a194 b0 00                            cmp.b d0,d0

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
                dc.w    $2278
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
62 a7                            bhi.s   loc_1a21d
loc_1a276 62 a8                            bhi.s   loc_1a220
loc_1a278 62 a9                            bhi.s   loc_1a223
loc_1a27a 62 aa                            bhi.s   loc_1a226
loc_1a27c 62 ab                            bhi.s   loc_1a229
loc_1a27e 62 ac                            bhi.s   loc_1a22c
loc_1a280 62 ad                            bhi.s   loc_1a22f
loc_1a282 62 ae                            bhi.s   loc_1a232
loc_1a284 62 af                            bhi.s   loc_1a235



loc_1a286: 62 b0                            bhi.s   loc_1a238
loc_1a288 62 b1                            bhi.s   loc_1a23b
loc_1a28a 62 b2                            bhi.s   loc_1a23e
loc_1a28c 62 b3                            bhi.s   loc_1a241
loc_1a28e 62 b4                            bhi.s   loc_1a244
loc_1a290 62 b5                            bhi.s   loc_1a247



loc_1a292: 62 9a                            bhi.s   loc_1a22e
loc_1a294 62 9b                            bhi.s   loc_1a231
loc_1a296 62 9c                            bhi.s   loc_1a234
loc_1a298 62 9d                            bhi.s   loc_1a237
loc_1a29a 62 7c                            bhi.s   loc_1a318
loc_1a29c 62 7d                            bhi.s   loc_1a31b
loc_1a29e 62 7e                            bhi.s   loc_1a31e
loc_1a2a0 62 7f                            bhi.s   loc_1a321
loc_1a2a2 62 80                            bhi.s   loc_1a224
loc_1a2a4 62 81                            bhi.s   loc_1a227
loc_1a2a6 62 82                            bhi.s   loc_1a22a
loc_1a2a8 62 83                            bhi.s   loc_1a22d
loc_1a2aa 62 84                            bhi.s   loc_1a230
loc_1a2ac 62 85                            bhi.s   loc_1a233
loc_1a2ae 62 86                            bhi.s   loc_1a236
loc_1a2b0 62 87                            bhi.s   loc_1a239
loc_1a2b2 62 88                            bhi.s   loc_1a23c
loc_1a2b4 62 89                            bhi.s   loc_1a23f
loc_1a2b6 62 8a                            bhi.s   loc_1a242
loc_1a2b8 62 8b                            bhi.s   loc_1a245
loc_1a2ba 62 8c                            bhi.s   loc_1a248
loc_1a2bc 62 8d                            bhi.s   loc_1a24b
loc_1a2be 62 8e                            bhi.s   loc_1a24e
loc_1a2c0 62 8f                            bhi.s   loc_1a251
loc_1a2c2 62 90                            bhi.s   loc_1a254
loc_1a2c4 62 91                            bhi.s   loc_1a257
loc_1a2c6 62 92                            bhi.s   loc_1a25a
loc_1a2c8 62 93                            bhi.s   loc_1a25d
loc_1a2ca 62 94                            bhi.s   loc_1a260
loc_1a2cc 62 95                            bhi.s   loc_1a263
loc_1a2ce 62 96                            bhi.s   loc_1a266
loc_1a2d0 62 97                            bhi.s   loc_1a269
loc_1a2d2 62 98                            bhi.s   loc_1a26c
loc_1a2d4 62 99                            bhi.s   loc_1a26f

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
WallpaperTiles1:           ; $1A336

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

WallPaperTiles2:

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
                dc.w    $032A

WallpaperTiles5
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
63 2b                      ori.b #43,d0
loc_1a46e 63 2c                            bls.s   loc_1a49c
loc_1a470 63 2d                            bls.s   loc_1a49f
loc_1a472 63 2e                            bls.s   loc_1a4a2
loc_1a474 63 2f                            bls.s   loc_1a4a5
loc_1a476 63 30                            bls.s   loc_1a4a8
loc_1a478 63 31                            bls.s   loc_1a4ab
loc_1a47a 63 32                            bls.s   loc_1a4ae
loc_1a47c 63 33                            bls.s   loc_1a4b1


loc_1a47e: 63 34                            bls.s   OpenDoorMaps
loc_1a480 63 35                            bls.s   loc_1a4b7
loc_1a482 63 36                            bls.s   loc_1a4ba
loc_1a484 63 37                            bls.s   loc_1a4bd
loc_1a486 63 35                            bls.s   loc_1a4bd
loc_1a488 63 38                            bls.s   loc_1a4c2
loc_1a48a 63 39                            bls.s   loc_1a4c5
loc_1a48c 63 35                            bls.s   loc_1a4c3
loc_1a48e 63 3a                            bls.s Map_1Player



loc_1a490: 63 3b                            bls.s   loc_1a4cd
loc_1a492 62 05                            bhi.s   loc_1a499
loc_1a494 63 3c                            bls.s Map_TopIcon
loc_1a496 63 3d                            bls.s   loc_1a4d5
loc_1a498 62 05                            bhi.s   loc_1a49f
loc_1a49a 63 3e                            bls.s   loc_1a4da
loc_1a49c 63 3f                            bls.s   loc_1a4dd
loc_1a49e 62 05                            bhi.s   loc_1a4a5
loc_1a4a0 63 40                            bls.s   loc_1a4e2


loc_1a4a2: 63 41                            bls.s   loc_1a4e5
loc_1a4a4 62 05                            bhi.s   loc_1a4ab
loc_1a4a6 63 42                            bls.s   loc_1a4ea
loc_1a4a8 63 43                            bls.s   loc_1a4ed
loc_1a4aa 62 05                            bhi.s   loc_1a4b1
loc_1a4ac 63 44                            bls.s   loc_1a4f2
loc_1a4ae 63 45                            bls.s   loc_1a4f5
loc_1a4b0 62 05                            bhi.s   loc_1a4b7
loc_1a4b2 63 46                            bls.s   loc_1a4fa


; ======================================================================

OpenDoorMaps:                                    ; $1A4B4
                dc.w    $0347, $0348, $0349
                dc.w    $034A, $034B, $034C
                dc.w    $034D, $034E, $034F

; ----------------------------------------------------------------------

loc_1a4c6 03 51                            bchg d1,(a1)
loc_1a4c8 43 50                            .short 0x4350

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
                
loc_1a4d8 00 00 00 00                      ori.b #0,d0
loc_1a4dc 00 2a 00 f8 00 00                ori.b #-8,(a2)(0)
loc_1a4e2 00 00 03 00                      ori.b #0,d0
loc_1a4e6 00 f8                            .short 0x00f8

; ======================================================================

loc_1a4e8: 00 04 f8 04                      ori.b #4,d4
loc_1a4ec 64 56                            bcc.s   loc_1a544
loc_1a4ee f8 f8                            .short 0xf8f8
loc_1a4f0 00 04 f8 04                      ori.b #4,d4
loc_1a4f4 74 56                            moveq   #86,d2
loc_1a4f6 f8 f8                            .short 0xf8f8
loc_1a4f8 00 04 f4 01                      ori.b #1,d4
loc_1a4fc 64 58                            bcc.s   loc_1a556
loc_1a4fe fc fc                            .short 0xfcfc
loc_1a500 00 04 f4 01                      ori.b #1,d4
loc_1a504 6c 58                            bge.s   loc_1a55e
loc_1a506 fc fc                            .short 0xfcfc
loc_1a508 00 04 f4 01                      ori.b #1,d4
loc_1a50c 74 58                            moveq   #$58,d2
loc_1a50e fc fc                            .short 0xfcfc
loc_1a510 00 04 f4 01                      ori.b #1,d4
loc_1a514 7c 58                            moveq   #$58,d6
loc_1a516 fc fc                            .short 0xfcfc
loc_1a518 00 04 f8 04                      ori.b #4,d4
loc_1a51c 64 5a                            bcc.s   loc_1a578
loc_1a51e f8 f8                            .short 0xf8f8
loc_1a520 00 04 f8 04                      ori.b #4,d4
loc_1a524 74 5a                            moveq   #90,d2
loc_1a526 f8 f8                            .short 0xf8f8
loc_1a528 00 04 f4 01                      ori.b #1,d4
loc_1a52c 64 5c                            bcc.s   loc_1a58a
loc_1a52e fc fc                            .short 0xfcfc
loc_1a530 00 04 f4 01                      ori.b #1,d4
loc_1a534 6c 5c                            bge.s   loc_1a592
loc_1a536 fc fc                            .short 0xfcfc
loc_1a538 00 04 f4 01                      ori.b #1,d4
loc_1a53c 74 5c                            moveq   #92,d2
loc_1a53e fc fc                            .short 0xfcfc
loc_1a540 00 04 f4 01                      ori.b #1,d4
loc_1a544 7c 5c                            moveq   #92,d6
loc_1a546 fc fc                            .short 0xfcfc
loc_1a548 00 04 f8 04                      ori.b #4,d4
loc_1a54c 64 5e                            bcc.s   loc_1a5ac
loc_1a54e f8 f8                            .short 0xf8f8
loc_1a550 00 04 f8 04                      ori.b #4,d4
loc_1a554 74 5e                            moveq   #94,d2
loc_1a556 f8 f8                            .short 0xf8f8
loc_1a558 00 04 f4 01                      ori.b #1,d4
loc_1a55c 64 60                            bcc.s   loc_1a5be
loc_1a55e fc fc                            .short 0xfcfc
loc_1a560 00 04 f4 01                      ori.b #1,d4
loc_1a564 6c 60                            bge.s   loc_1a5c6
loc_1a566 fc fc                            .short 0xfcfc
loc_1a568 00 04 f4 01                      ori.b #1,d4
loc_1a56c 74 60                            moveq   #$60,d2
loc_1a56e fc fc                            .short 0xfcfc
loc_1a570 00 04 f4 01                      ori.b #1,d4
loc_1a574 7c 60                            moveq   #$60,d6
loc_1a576 fc fc                            .short 0xfcfc
loc_1a578 00 04 f8 04                      ori.b #4,d4
loc_1a57c 64 62                            bcc.s   loc_1a5e0
loc_1a57e f8 f8                            .short 0xf8f8
loc_1a580 00 04 f8 04                      ori.b #4,d4
loc_1a584 74 62                            moveq   #98,d2
loc_1a586 f8 f8                            .short 0xf8f8
loc_1a588 00 04 f4 01                      ori.b #1,d4
loc_1a58c 64 64                            bcc.s   loc_1a5f2
loc_1a58e fc fc                            .short 0xfcfc
loc_1a590 00 04 f4 01                      ori.b #1,d4
loc_1a594 6c 64                            bge.s   loc_1a5fa
loc_1a596 fc fc                            .short 0xfcfc
loc_1a598 00 04 f4 01                      ori.b #1,d4
loc_1a59c 74 64                            moveq   #100,d2
loc_1a59e fc fc                            .short 0xfcfc
loc_1a5a0 00 04 f4 01                      ori.b #1,d4
loc_1a5a4 7c 64                            moveq   #100,d6
loc_1a5a6 fc fc                            .short 0xfcfc
loc_1a5a8 00 04 f8 04                      ori.b #4,d4
loc_1a5ac 64 66                            bcc.s   loc_1a614
loc_1a5ae f8 f8                            .short 0xf8f8
loc_1a5b0 00 04 f8 04                      ori.b #4,d4
loc_1a5b4 74 66                            moveq   #102,d2
loc_1a5b6 f8 f8                            .short 0xf8f8
loc_1a5b8 00 04 f4 01                      ori.b #1,d4
loc_1a5bc 64 68                            bcc.s   loc_1a626
loc_1a5be fc fc                            .short 0xfcfc
loc_1a5c0 00 04 f4 01                      ori.b #1,d4
loc_1a5c4 6c 68                            bge.s   loc_1a62e
loc_1a5c6 fc fc                            .short 0xfcfc
loc_1a5c8 00 04 f4 01                      ori.b #1,d4
loc_1a5cc 74 68                            moveq   #104,d2
loc_1a5ce fc fc                            .short 0xfcfc
loc_1a5d0 00 04 f4 01                      ori.b #1,d4
loc_1a5d4 7c 68                            moveq   #104,d6
loc_1a5d6 fc fc                            .short 0xfcfc
loc_1a5d8 00 04 f8 04                      ori.b #4,d4
loc_1a5dc 64 6a                            bcc.s   loc_1a648
loc_1a5de f8 f8                            .short 0xf8f8
loc_1a5e0 00 04 f8 04                      ori.b #4,d4
loc_1a5e4 74 6a                            moveq   #106,d2
loc_1a5e6 f8 f8                            .short 0xf8f8
loc_1a5e8 00 04 f4 01                      ori.b #1,d4
loc_1a5ec 64 6c                            bcc.s   loc_1a65a
loc_1a5ee fc fc                            .short 0xfcfc
loc_1a5f0 00 04 f4 01                      ori.b #1,d4
loc_1a5f4 6c 6c                            bge.s   loc_1a662
loc_1a5f6 fc fc                            .short 0xfcfc
loc_1a5f8 00 04 f4 01                      ori.b #1,d4
loc_1a5fc 74 6c                            moveq   #108,d2
loc_1a5fe fc fc                            .short 0xfcfc
loc_1a600 00 04 f4 01                      ori.b #1,d4
loc_1a604 7c 6c                            moveq   #108,d6
loc_1a606 fc fc                            .short 0xfcfc
loc_1a608 00 04 f8 04                      ori.b #4,d4
loc_1a60c 64 6e                            bcc.s   loc_1a67c
loc_1a60e f8 f8                            .short 0xf8f8
loc_1a610 00 04 f8 04                      ori.b #4,d4
loc_1a614 74 6e                            moveq   #110,d2
loc_1a616 f8 f8                            .short 0xf8f8
loc_1a618 00 04 f4 01                      ori.b #1,d4
loc_1a61c 64 70                            bcc.s   loc_1a68e
loc_1a61e fc fc                            .short 0xfcfc
loc_1a620 00 04 f4 01                      ori.b #1,d4
loc_1a624 6c 70                            bge.s   loc_1a696
loc_1a626 fc fc                            .short 0xfcfc
loc_1a628 00 04 f4 01                      ori.b #1,d4
loc_1a62c 74 70                            moveq   #112,d2
loc_1a62e fc fc                            .short 0xfcfc
loc_1a630 00 04 f4 01                      ori.b #1,d4
loc_1a634 7c 70                            moveq   #112,d6
loc_1a636 fc fc                            .short 0xfcfc
loc_1a638 00 04 f8 04                      ori.b #4,d4
loc_1a63c 64 72                            bcc.s   loc_1a6b0
loc_1a63e f8 f8                            .short 0xf8f8
loc_1a640 00 04 f8 04                      ori.b #4,d4
loc_1a644 74 72                            moveq   #114,d2
loc_1a646 f8 f8                            .short 0xf8f8
loc_1a648 00 04 f4 01                      ori.b #1,d4
loc_1a64c 64 74                            bcc.s   loc_1a6c2
loc_1a64e fc fc                            .short 0xfcfc
loc_1a650 00 04 f4 01                      ori.b #1,d4
loc_1a654 6c 74                            bge.s   loc_1a6ca
loc_1a656 fc fc                            .short 0xfcfc
loc_1a658 00 04 f4 01                      ori.b #1,d4
loc_1a65c 74 74                            moveq   #116,d2
loc_1a65e fc fc                            .short 0xfcfc
loc_1a660 00 04 f4 01                      ori.b #1,d4
loc_1a664 7c 74                            moveq   #116,d6
loc_1a666 fc fc                            .short 0xfcfc
loc_1a668 00 04 f8 04                      ori.b #4,d4
loc_1a66c 64 76                            bcc.s   loc_1a6e4
loc_1a66e f8 f8                            .short 0xf8f8
loc_1a670 00 04 f8 04                      ori.b #4,d4
loc_1a674 74 76                            moveq   #118,d2
loc_1a676 f8 f8                            .short 0xf8f8
loc_1a678 00 04 f4 01                      ori.b #1,d4
loc_1a67c 64 78                            bcc.s   loc_1a6f6
loc_1a67e fc fc                            .short 0xfcfc
loc_1a680 00 04 f4 01                      ori.b #1,d4
loc_1a684 6c 78                            bge.s   loc_1a6fe
loc_1a686 fc fc                            .short 0xfcfc
loc_1a688 00 04 f4 01                      ori.b #1,d4
loc_1a68c 74 78                            moveq   #120,d2
loc_1a68e fc fc                            .short 0xfcfc
loc_1a690 00 04 f4 01                      ori.b #1,d4
loc_1a694 7c 78                            moveq   #120,d6
loc_1a696 fc fc                            .short 0xfcfc
loc_1a698 00 04 f8 04                      ori.b #4,d4
loc_1a69c 64 7a                            bcc.s   loc_1a718
loc_1a69e f8 f8                            .short 0xf8f8
loc_1a6a0 00 04 f8 04                      ori.b #4,d4
loc_1a6a4 74 7a                            moveq   #122,d2
loc_1a6a6 f8 f8                            .short 0xf8f8
loc_1a6a8 00 04 f4 01                      ori.b #1,d4
loc_1a6ac 64 7c                            bcc.s   loc_1a72a
loc_1a6ae fc fc                            .short 0xfcfc
loc_1a6b0 00 04 f4 01                      ori.b #1,d4
loc_1a6b4 6c 7c                            bge.s   loc_1a732
loc_1a6b6 fc fc                            .short 0xfcfc
loc_1a6b8 00 04 f4 01                      ori.b #1,d4
loc_1a6bc 74 7c                            moveq   #$7C,d2
loc_1a6be fc fc                            .short 0xfcfc
loc_1a6c0 00 04 f4 01                      ori.b #1,d4
loc_1a6c4 7c 7c                            moveq   #$7C,d6
loc_1a6c6 fc fc                            .short 0xfcfc
loc_1a6c8 00 04 f8 04                      ori.b #4,d4
loc_1a6cc 64 7e                            bcc.s   loc_1a74c
loc_1a6ce f8 f8                            .short 0xf8f8
loc_1a6d0 00 04 f8 04                      ori.b #4,d4
loc_1a6d4 74 7e                            moveq   #126,d2
loc_1a6d6 f8 f8                            .short 0xf8f8
loc_1a6d8 00 04 f4 01                      ori.b #1,d4
loc_1a6dc 64 80                            bcc.s   loc_1a65e
loc_1a6de fc fc                            .short 0xfcfc
loc_1a6e0 00 04 f4 01                      ori.b #1,d4
loc_1a6e4 6c 80                            bge.s   loc_1a666
loc_1a6e6 fc fc                            .short 0xfcfc
loc_1a6e8 00 04 f4 01                      ori.b #1,d4
loc_1a6ec 74 80                            moveq   #-128,d2
loc_1a6ee fc fc                            .short 0xfcfc
loc_1a6f0 00 04 f4 01                      ori.b #1,d4
loc_1a6f4 7c 80                            moveq   #-128,d6
loc_1a6f6 fc fc                            .short 0xfcfc
loc_1a6f8 00 04 f8 04                      ori.b #4,d4
loc_1a6fc 64 82                            bcc.s   loc_1a680
loc_1a6fe f8 f8                            .short 0xf8f8
loc_1a700 00 04 f8 04                      ori.b #4,d4
loc_1a704 74 82                            moveq   #-126,d2
loc_1a706 f8 f8                            .short 0xf8f8
loc_1a708 00 04 f4 01                      ori.b #1,d4
loc_1a70c 64 84                            bcc.s   loc_1a692
loc_1a70e fc fc                            .short 0xfcfc
loc_1a710 00 04 f4 01                      ori.b #1,d4
loc_1a714 6c 84                            bge.s   loc_1a69a
loc_1a716 fc fc                            .short 0xfcfc
loc_1a718 00 04 f4 01                      ori.b #1,d4
loc_1a71c 74 84                            moveq   #-124,d2
loc_1a71e fc fc                            .short 0xfcfc
loc_1a720 00 04 f4 01                      ori.b #1,d4
loc_1a724 7c 84                            moveq   #-124,d6
loc_1a726 fc fc                            .short 0xfcfc
loc_1a728 00 04 f8 04                      ori.b #4,d4
loc_1a72c 64 86                            bcc.s   loc_1a6b4
loc_1a72e f8 f8                            .short 0xf8f8
loc_1a730 00 04 f8 04                      ori.b #4,d4
loc_1a734 74 86                            moveq   #-122,d2
loc_1a736 f8 f8                            .short 0xf8f8
loc_1a738 00 04 f4 01                      ori.b #1,d4
loc_1a73c 64 88                            bcc.s   loc_1a6c6
loc_1a73e fc fc                            .short 0xfcfc
loc_1a740 00 04 f4 01                      ori.b #1,d4
loc_1a744 6c 88                            bge.s   loc_1a6ce
loc_1a746 fc fc                            .short 0xfcfc
loc_1a748 00 04 f4 01                      ori.b #1,d4
loc_1a74c 74 88                            moveq   #-120,d2
loc_1a74e fc fc                            .short 0xfcfc
loc_1a750 00 04 f4 01                      ori.b #1,d4
loc_1a754 7c 88                            moveq   #-120,d6
loc_1a756 fc fc                            .short 0xfcfc
loc_1a758 00 04 f8 04                      ori.b #4,d4
loc_1a75c 64 8a                            bcc.s   loc_1a6e8
loc_1a75e f8 f8                            .short 0xf8f8
loc_1a760 00 04 f8 04                      ori.b #4,d4
loc_1a764 74 8a                            moveq   #-118,d2
loc_1a766 f8 f8                            .short 0xf8f8
loc_1a768 00 04 f4 01                      ori.b #1,d4
loc_1a76c 64 8c                            bcc.s   loc_1a6fa
loc_1a76e fc fc                            .short 0xfcfc
loc_1a770 00 04 f4 01                      ori.b #1,d4
loc_1a774 6c 8c                            bge.s   loc_1a702
loc_1a776 fc fc                            .short 0xfcfc
loc_1a778 00 04 f4 01                      ori.b #1,d4
loc_1a77c 74 8c                            moveq   #-116,d2
loc_1a77e fc fc                            .short 0xfcfc
loc_1a780 00 04 f4 01                      ori.b #1,d4
loc_1a784 7c 8c                            moveq   #-116,d6
loc_1a786 fc fc                            .short 0xfcfc
loc_1a788 00 04 f8 04                      ori.b #4,d4
loc_1a78c 64 8e                            bcc.s   loc_1a71c
loc_1a78e f8 f8                            .short 0xf8f8
loc_1a790 00 04 f8 04                      ori.b #4,d4
loc_1a794 74 8e                            moveq   #-114,d2
loc_1a796 f8 f8                            .short 0xf8f8
loc_1a798 00 04 f4 01                      ori.b #1,d4
loc_1a79c 64 90                            bcc.s   loc_1a72e
loc_1a79e fc fc                            .short 0xfcfc
loc_1a7a0 00 04 f4 01                      ori.b #1,d4
loc_1a7a4 6c 90                            bge.s   loc_1a736
loc_1a7a6 fc fc                            .short 0xfcfc
loc_1a7a8 00 04 f4 01                      ori.b #1,d4
loc_1a7ac 74 90                            moveq   #-112,d2
loc_1a7ae fc fc                            .short 0xfcfc
loc_1a7b0 00 04 f4 01                      ori.b #1,d4
loc_1a7b4 7c 90                            moveq   #-112,d6
loc_1a7b6 fc fc                            .short 0xfcfc
loc_1a7b8 00 03 f0 05                      ori.b #5,d3
loc_1a7bc 44 36 f8 f8                      negb (a6)(fffffffffffffff8,sp:l)
loc_1a7c0 00 03 f0 05                      ori.b #5,d3
loc_1a7c4 44 3a                            .short 0x443a
loc_1a7c6 f8 f8                            .short 0xf8f8
loc_1a7c8 00 03 f0 05                      ori.b #5,d3
loc_1a7cc 4c 36                            .short 0x4c36
loc_1a7ce f8 f8                            .short 0xf8f8
loc_1a7d0 00 03 f0 05                      ori.b #5,d3
loc_1a7d4 4c 3a                            .short 0x4c3a
loc_1a7d6 f8 f8                            .short 0xf8f8
loc_1a7d8 00 06 f0 05                      ori.b #5,d6
loc_1a7dc 44 3e                            .short 0x443e
loc_1a7de f8 f8                            .short 0xf8f8
loc_1a7e0 00 06 f0 05                      ori.b #5,d6
loc_1a7e4 44 42                            neg.w   d2
loc_1a7e6 f8 f8                            .short 0xf8f8
loc_1a7e8 00 06 f0 05                      ori.b #5,d6
loc_1a7ec 44 46                            neg.w   d6
loc_1a7ee f8 f8                            .short 0xf8f8
loc_1a7f0 00 06 f0 05                      ori.b #5,d6
loc_1a7f4 44 4a                            .short 0x444a
loc_1a7f6 f8 f8                            .short 0xf8f8
loc_1a7f8 00 06 f0 05                      ori.b #5,d6
loc_1a7fc 44 4e                            .short 0x444e
loc_1a7fe f8 f8                            .short 0xf8f8
loc_1a800 00 06 f0 01                      ori.b #1,d6
loc_1a804 44 52                            neg.w (a2)
loc_1a806 fc fc                            .short 0xfcfc
loc_1a808 00 06 f0 01                      ori.b #1,d6
loc_1a80c 44 54                            neg.w (a4)
loc_1a80e fc fc                            .short 0xfcfc
loc_1a810 00 06 f0 01                      ori.b #1,d6
loc_1a814 4c 52                            .short 0x4c52
loc_1a816 fc fc                            .short 0xfcfc
loc_1a818 00 03 f0 05                      ori.b #5,d3
loc_1a81c 44 92                            neg.l (a2)
loc_1a81e f8 f8                            .short 0xf8f8
loc_1a820 00 03 f0 05                      ori.b #5,d3
loc_1a824 44 96                            neg.l (a6)
loc_1a826 f8 f8                            .short 0xf8f8
loc_1a828 00 03 f0 05                      ori.b #5,d3
loc_1a82c 4c 92 f8 f8                      movem.w (a2),d3-d7/a3-sp
loc_1a830 00 03 f0 05                      ori.b #5,d3
loc_1a834 4c 96 f8 f8                      movem.w (a6),d3-d7/a3-sp
loc_1a838 00 06 f0 05                      ori.b #5,d6
loc_1a83c 44 9a                            neg.l (a2)+
loc_1a83e f8 f8                            .short 0xf8f8
loc_1a840 00 06 f0 05                      ori.b #5,d6
loc_1a844 44 9e                            neg.l (a6)+
loc_1a846 f8 f8                            .short 0xf8f8
loc_1a848 00 06 f0 05                      ori.b #5,d6
loc_1a84c 44 a2                            neg.l (a2)-
loc_1a84e f8 f8                            .short 0xf8f8
loc_1a850 00 06 f0 05                      ori.b #5,d6
loc_1a854 44 a6                            neg.l (a6)-
loc_1a856 f8 f8                            .short 0xf8f8
loc_1a858 00 06 f0 05                      ori.b #5,d6
loc_1a85c 44 aa f8 f8                      neg.l (a2)(-1800)
loc_1a860 00 06 f0 01                      ori.b #1,d6
loc_1a864 44 ae fc fc                      neg.l (a6)(-772)
loc_1a868 00 06 f0 01                      ori.b #1,d6
loc_1a86c 44 b0 fc fc                      neg.l (a0)(fffffffffffffffc,sp:l:4)
loc_1a870 00 06 f0 01                      ori.b #1,d6
loc_1a874 4c ae fc fc 00 ff                movem.w (a6)(255),d2-d7/a2-sp
loc_1a87a f0 05 44 00                      pmove d5,%drp
loc_1a87e f8 f8                            .short 0xf8f8
loc_1a880 00 ff                            .short 0x00ff
loc_1a882 f0 05                            .short 0xf005
loc_1a884 44 04                            negb d4
loc_1a886 f8 f8                            .short 0xf8f8
loc_1a888 00 ff                            .short 0x00ff
loc_1a88a f0 05                            .short 0xf005
loc_1a88c 44 08                            .short 0x4408
loc_1a88e f8 f8                            .short 0xf8f8
loc_1a890 00 ff                            .short 0x00ff
loc_1a892 f0 05                            .short 0xf005
loc_1a894 44 0c                            .short 0x440c
loc_1a896 f8 f8                            .short 0xf8f8
loc_1a898 00 00 e8 06                      ori.b #6,d0
loc_1a89c 44 10                            negb (a0)
loc_1a89e f8 f8                            .short 0xf8f8
loc_1a8a0 00 01 f0 05                      ori.b #5,d1
loc_1a8a4 44 16                            negb (a6)
loc_1a8a6 f8 f8                            .short 0xf8f8

; ======================================================================

loc_1a8a8: 00 00 e8 06                      ori.b #6,d0
loc_1a8ac 44 1a                            negb (a2)+
loc_1a8ae f8 f8                            .short 0xf8f8
loc_1a8b0: 00 00 e8 06                      ori.b #6,d0
loc_1a8b4 44 20                            negb (a0)-
loc_1a8b6 f8 f8                            .short 0xf8f8

; ===========================================================================

loc_1a8b8 00 01 f0 05                      ori.b #5,d1
loc_1a8bc 44 26                            negb (a6)-
loc_1a8be f8 f8                            .short 0xf8f8
loc_1a8c0 00 01 f0 05                      ori.b #5,d1
loc_1a8c4 44 2a f8 f8                      negb (a2)(-1800)
loc_1a8c8 00 02 f0 05                      ori.b #5,d2
loc_1a8cc 44 2e f8 f8                      negb (a6)(-1800)
loc_1a8d0 00 02 f0 05                      ori.b #5,d2
loc_1a8d4 44 32 f8 f8                      negb (a2)(fffffffffffffff8,sp:l)
loc_1a8d8 00 07 f8 00                      ori.b #0,d7
loc_1a8dc 04 b2 fc fc 00 07 f8 00          subi.l #-50593785,(a2,sp:l)
loc_1a8e4 04 b3 fc fc 00 07 f8 00          subi.l #-50593785,(a3,sp:l)
loc_1a8ec 04 b4 fc fc 00 07 f8 00          subi.l #-50593785,(a4,sp:l)
loc_1a8f4 06 86 fc fc 00 08                addi.l  #-50593784,d6
loc_1a8fa f0 05                            .short 0xf005
loc_1a8fc 44 b5 f8 f8                      neg.l (a5)(fffffffffffffff8,sp:l)
loc_1a900 00 08                            .short loc_8
loc_1a902 f0 05                            .short 0xf005
loc_1a904 44 b9 f8 f8 00 08                neg.l 0xf8f80008
loc_1a90a f0 05                            .short 0xf005
loc_1a90c 44 bd                            .short 0x44bd
loc_1a90e f8 f8                            .short 0xf8f8
loc_1a910 00 08                            .short loc_8
loc_1a912 f0 05                            .short 0xf005
loc_1a914 44 c1                            move.w  d1,ccr
loc_1a916 f8 f8                            .short 0xf8f8



loc_1a918: 01 05                            btst d0,d5
loc_1a91a e8 02                            asrb #4,d2
loc_1a91c 44 c5                            move.w  d5,ccr
loc_1a91e fc fc                            .short 0xfcfc
loc_1a920 f0 01                            .short 0xf001
loc_1a922 44 c8                            .short 0x44c8
loc_1a924 f4 04                            .short 0xf404
loc_1a926 02 05 e8 02                      andi.b  #2,d5
loc_1a92a 44 ca                            .short 0x44ca
loc_1a92c fc fc                            .short 0xfcfc
loc_1a92e f0 01                            .short 0xf001
loc_1a930 44 cd                            .short 0x44cd
loc_1a932 f4 04                            .short 0xf404
loc_1a934 f0 00                            .short 0xf000
loc_1a936 44 cf                            .short 0x44cf
loc_1a938 04 f4                            .short 0x04f4
loc_1a93a 02 05 e8 02                      andi.b  #2,d5
loc_1a93e 44 d0                            move.w  (a0),ccr
loc_1a940 fc fc                            .short 0xfcfc
loc_1a942 f0 00                            .short 0xf000
loc_1a944 44 d3                            move.w  (a3),ccr
loc_1a946 04 f4                            .short 0x04f4
loc_1a948 f8 00                            .short 0xf800
loc_1a94a 44 d4                            move.w  (a4),ccr
loc_1a94c f4 04                            .short 0xf404
loc_1a94e 01 05                            btst d0,d5
loc_1a950 e8 06                            asrb #4,d6
loc_1a952 44 d5                            move.w  (a5),ccr
loc_1a954 fc f4                            .short 0xfcf4
loc_1a956 f8 00                            .short 0xf800
loc_1a958 44 db                            move.w  (a3)+,ccr
loc_1a95a f4 04                            .short 0xf404
loc_1a95c 02 05 e8 02                      andi.b  #2,d5
loc_1a960 44 dc                            move.w  (a4)+,ccr
loc_1a962 fc fc                            .short 0xfcfc
loc_1a964 f0 01                            .short 0xf001
loc_1a966 44 df                            move.w  (sp)+,ccr
loc_1a968 04 f4                            .short 0x04f4
loc_1a96a f8 00                            .short 0xf800
loc_1a96c 44 e1                            move.w  (a1)-,ccr
loc_1a96e f4 04                            .short 0xf404



loc_1a970: 01 12                            btst d0,(a2)
loc_1a972 eb 06                            aslb #5,d6
loc_1a974 44 e2                            move.w  (a2)-,ccr
loc_1a976 fc f4                            .short 0xfcf4
loc_1a978 fb 00                            .short 0xfb00
loc_1a97a 44 e8 f4 04                      move.w  (a0)(-3068),ccr


loc_1a97e: 02 12 eb 05                      andi.b  #5,(a2)
loc_1a982 44 e9 fc f4                      move.w  (a1)(-780),ccr
loc_1a986 f3 01                            .short 0xf301
loc_1a988 44 ed f4 04                      move.w  (a5)(-3068),ccr
loc_1a98c fb 00                            .short 0xfb00
loc_1a98e 44 ef fc fc                      move.w  (sp)(-772),ccr
loc_1a992 00 ff                            .short 0x00ff
loc_1a994 e8 06                            asrb #4,d6
loc_1a996 44 f0 f8 f8                      move.w  (a0)(fffffffffffffff8,sp:l),ccr
loc_1a99a 02 ff                            .short 0x02ff
loc_1a99c ee 05                            asrb #7,d5
loc_1a99e 44 f6 fa f6                      move.w  (a6)(fffffffffffffff6,sp:l:2),ccr
loc_1a9a2 f6 00                            .short 0xf600
loc_1a9a4 44 fa f2 06                      move.w  (pc)(loc_19bac),ccr
loc_1a9a8 fe 00                            .short 0xfe00
loc_1a9aa 44 fb fa fe                      move.w  (pc)(loc_1a9aa,sp:l:2),ccr
loc_1a9ae 00 ff                            .short 0x00ff
loc_1a9b0 f4 09                            .short 0xf409
loc_1a9b2 44 fc f4 f4                      move.w  #-2828,ccr
loc_1a9b6 02 ff                            .short 0x02ff
loc_1a9b8 e8 02                            asrb #4,d2
loc_1a9ba 45 02                            chkl d2,d2
loc_1a9bc fa fe                            .short 0xfafe
loc_1a9be f0 00                            .short 0xf000
loc_1a9c0 54 fa                            .short 0x54fa
loc_1a9c2 f2 06                            .short 0xf206
loc_1a9c4 f0 01                            .short 0xf001
loc_1a9c6 54 f8 02 f6                      scc loc_2f6
loc_1a9ca 00 ff                            .short 0x00ff
loc_1a9cc eb 06                            aslb #5,d6
loc_1a9ce 54 f0 f8 f8                      scc (a0)(fffffffffffffff8,sp:l)
loc_1a9d2 02 ff                            .short 0x02ff
loc_1a9d4 e8 02                            asrb #4,d2
loc_1a9d6 4d 02                            chkl d2,d6
loc_1a9d8 fe fa                            .short 0xfefa
loc_1a9da f0 01                            .short 0xf001
loc_1a9dc 5c f8 f6 02                      sge ($FFFFf602
loc_1a9e0 f0 00                            .short 0xf000
loc_1a9e2 5c fa                            .short 0x5cfa
loc_1a9e4 06 f2                            .short 0x06f2
loc_1a9e6 00 ff                            .short 0x00ff
loc_1a9e8 f4 09                            .short 0xf409
loc_1a9ea 4c fc                            .short 0x4cfc
loc_1a9ec f4 f4                            .short 0xf4f4
loc_1a9ee 02 ff                            .short 0x02ff
loc_1a9f0 ee 05                            asrb #7,d5
loc_1a9f2 4c f6 f6 fa f6 00                movem.l (a6,sp.w:8),d1/d3-d7/a1-a2/a4-sp
loc_1a9f8 4c fa 06 f2 fe 00                movem.l (pc)(loc_1a7fc),d1/d4-d7/a1-a2
loc_1a9fe 4c fb fe fa 00 05                movem.l (pc)(loc_1aa07,d0.w),d1/d3-d7/a1-sp
loc_1aa04 e8 06                            asrb #4,d6
loc_1aa06 45 05                            chkl d5,d2
loc_1aa08 f8 f8                            .short 0xf8f8
loc_1aa0a 00 05 e8 06                      ori.b #6,d5
loc_1aa0e 44 f0 f8 f8                      move.w  (a0)(fffffffffffffff8,sp:l),ccr
loc_1aa12 00 05 e8 06                      ori.b #6,d5
loc_1aa16 4d 05                            chkl d5,d6
loc_1aa18 f8 f8                            .short 0xf8f8
loc_1aa1a 02 05 dc 02                      andi.b  #2,d5
loc_1aa1e 44 ca                            .short 0x44ca
loc_1aa20 fc fc                            .short 0xfcfc
loc_1aa22 e4 01                            asrb #2,d1
loc_1aa24 44 cd                            .short 0x44cd
loc_1aa26 f4 04                            .short 0xf404
loc_1aa28 e4 00                            asrb #2,d0
loc_1aa2a 44 cf                            .short 0x44cf
loc_1aa2c 04 f4                            .short 0x04f4
loc_1aa2e 02 05 de 02                      andi.b  #2,d5
loc_1aa32 44 ca                            .short 0x44ca
loc_1aa34 fc fc                            .short 0xfcfc
loc_1aa36 e6 01                            asrb #3,d1
loc_1aa38 44 cd                            .short 0x44cd
loc_1aa3a f4 04                            .short 0xf404
loc_1aa3c e6 00                            asrb #3,d0
loc_1aa3e 44 cf                            .short 0x44cf
loc_1aa40 04 f4                            .short 0x04f4
loc_1aa42 02 05 e4 02                      andi.b  #2,d5
loc_1aa46 44 ca                            .short 0x44ca
loc_1aa48 fc fc                            .short 0xfcfc
loc_1aa4a ec 01                            asrb #6,d1
loc_1aa4c 44 cd                            .short 0x44cd
loc_1aa4e f4 04                            .short 0xf404
loc_1aa50 ec 00                            asrb #6,d0
loc_1aa52 44 cf                            .short 0x44cf
loc_1aa54 04 f4                            .short 0x04f4
loc_1aa56 02 05 e8 02                      andi.b  #2,d5
loc_1aa5a 44 d0                            move.w  (a0),ccr
loc_1aa5c fc fc                            .short 0xfcfc
loc_1aa5e f0 00                            .short 0xf000
loc_1aa60 44 d3                            move.w  (a3),ccr
loc_1aa62 04 f4                            .short 0x04f4
loc_1aa64 f8 00                            .short 0xf800
loc_1aa66 44 d4                            move.w  (a4),ccr
loc_1aa68 f4 04                            .short 0xf404
loc_1aa6a 02 05 ea 02                      andi.b  #2,d5
loc_1aa6e 44 d0                            move.w  (a0),ccr
loc_1aa70 fc fc                            .short 0xfcfc
loc_1aa72 f2 00                            .short 0xf200
loc_1aa74 44 d3                            move.w  (a3),ccr
loc_1aa76 04 f4                            .short 0x04f4
loc_1aa78 fa 00                            .short 0xfa00
loc_1aa7a 44 d4                            move.w  (a4),ccr
loc_1aa7c f4 04                            .short 0xf404
loc_1aa7e 00 ff                            .short 0x00ff
loc_1aa80 f8 00                            .short 0xf800
loc_1aa82 45 0b                            .short 0x450b
loc_1aa84 fc fc                            .short 0xfcfc
loc_1aa86 00 ff                            .short 0x00ff
loc_1aa88 f8 00                            .short 0xf800
loc_1aa8a 45 0c                            .short 0x450c
loc_1aa8c fc fc                            .short 0xfcfc
loc_1aa8e 00 ff                            .short 0x00ff
loc_1aa90 f8 00                            .short 0xf800
loc_1aa92 45 0d                            .short 0x450d
loc_1aa94 fc fc                            .short 0xfcfc
loc_1aa96 01 10                            btst d0,(a0)
loc_1aa98 f0 08                            .short 0xf008
loc_1aa9a 65 0e                            bcs.s   loc_1aaaa
loc_1aa9c f0 f8                            .short 0xf0f8
loc_1aa9e f8 08                            .short 0xf808
loc_1aaa0 65 11                            bcs.s   loc_1aab3
loc_1aaa2 f8 f0                            .short 0xf8f0
loc_1aaa4 01 10                            btst d0,(a0)
loc_1aaa6 f0 08                            .short 0xf008
loc_1aaa8 65 14                            bcs.s   loc_1aabe
loc_1aaaa f0 f8                            .short 0xf0f8
loc_1aaac f8 08                            .short 0xf808
loc_1aaae 65 17                            bcs.s   loc_1aac7
loc_1aab0 f8 f0                            .short 0xf8f0
loc_1aab2 00 10 f0 0d                      ori.b #$D,(a0)
loc_1aab6 65 1a                            bcs.s   loc_1aad2
loc_1aab8 f0 f0                            .short 0xf0f0
loc_1aaba 01 10                            btst d0,(a0)
loc_1aabc f0 08                            .short 0xf008
loc_1aabe 6d 14                            blt.s   loc_1aad4
loc_1aac0 f8 f0                            .short 0xf8f0
loc_1aac2 f8 08                            .short 0xf808
loc_1aac4 6d 17                            blt.s   loc_1aadd
loc_1aac6 f0 f8                            .short 0xf0f8
loc_1aac8 01 10                            btst d0,(a0)
loc_1aaca f0 08                            .short 0xf008
loc_1aacc 6d 0e                            blt.s   loc_1aadc
loc_1aace f8 f0                            .short 0xf8f0
loc_1aad0 f8 08                            .short 0xf808
loc_1aad2 6d 11                            blt.s   loc_1aae5
loc_1aad4 f0 f8                            .short 0xf0f8
loc_1aad6 01 11                            btst d0,(a1)
loc_1aad8 f0 04                            .short 0xf004
loc_1aada 05 22                            btst d2,(a2)-
loc_1aadc f8 f8                            .short 0xf8f8
loc_1aade f8 00                            .short 0xf800
loc_1aae0 05 24                            btst d2,(a4)-
loc_1aae2 f8 00                            .short 0xf800
loc_1aae4 00 11 f0 05                      ori.b #5,(a1)
loc_1aae8 05 25                            btst d2,(a5)-
loc_1aaea f8 f8                            .short 0xf8f8
loc_1aaec 00 00 f3 00                      ori.b #0,d0
loc_1aaf0 05 29 fd fb                      btst d2,(a1)(-517)
loc_1aaf4 00 00 f3 00                      ori.b #0,d0
loc_1aaf8 05 2a fd fb                      btst d2,(a2)(-517)
loc_1aafc 00 00 f3 00                      ori.b #0,d0
loc_1ab00 05 2b fd fb                      btst d2,(a3)(-517)
loc_1ab04 00 00 f3 00                      ori.b #0,d0
loc_1ab08 05 2b fd fb                      btst d2,(a3)(-517)
loc_1ab0c 00 00 f3 00                      ori.b #0,d0
loc_1ab10 05 2c fd fb                      btst d2,(a4)(-517)
loc_1ab14 00 00 f3 00                      ori.b #0,d0
loc_1ab18 05 2d fd fb                      btst d2,(a5)(-517)
loc_1ab1c 00 00 f3 00                      ori.b #0,d0
loc_1ab20 05 2e fd fb                      btst d2,(a6)(-517)



loc_1ab24: 00 ff                            .short 0x00ff
loc_1ab26 f8 08                            .short 0xf808
loc_1ab28 06 40 f4 f4                      addi.w  #-2828,d0


loc_1ab2c: 00 ff                            .short 0x00ff
loc_1ab2e f8 08                            .short 0xf808
loc_1ab30 06 43 f4 f4                      addi.w  #-2828,d3



loc_1ab34: 00 ff                            .short 0x00ff
loc_1ab36 f8 08                            .short 0xf808
loc_1ab38 06 46 f4 f4                      addi.w  #-2828,d6


loc_1ab3c: 00 ff                            .short 0x00ff
loc_1ab3e f8 08                            .short 0xf808
loc_1ab40 06 49                            .short 0x0649
loc_1ab42 f4 f4                            .short 0xf4f4


loc_1ab44: 00 ff                            .short 0x00ff
loc_1ab46 f8 08                            .short 0xf808
loc_1ab48 06 4c                            .short 0x064c
loc_1ab4a f4 f4                            .short 0xf4f4


loc_1ab4c: 00 ff                            .short 0x00ff
loc_1ab4e f8 08                            .short 0xf808
loc_1ab50 06 4f                            .short 0x064f
loc_1ab52 f4 f4                            .short 0xf4f4


loc_1ab54: 00 ff                            .short 0x00ff
loc_1ab56 f8 08                            .short 0xf808
loc_1ab58 06 52 f2 f6                      addi.w  #-3338,(a2)



loc_1ab5c: 00 ff                            .short 0x00ff
loc_1ab5e f8 08                            .short 0xf808
loc_1ab60 06 55 f2 f6                      addi.w  #-3338,(a5)
loc_1ab64 00 ff                            .short 0x00ff
loc_1ab66 f8 08                            .short 0xf808
loc_1ab68 06 58 f2 f6                      addi.w  #-3338,(a0)+

loc_1ab6c: 00 ff                            .short 0x00ff
loc_1ab6e f8 08                            .short 0xf808
loc_1ab70 06 5b f2 f6                      addi.w  #-3338,(a3)+



loc_1ab74: 00 09                            .short loc_9
loc_1ab76 f0 01                            .short 0xf001
loc_1ab78 46 5e                            notw (a6)+
loc_1ab7a fc fc                            .short 0xfcfc
loc_1ab7c 00 0a                            .short loc_a
loc_1ab7e f8 04                            .short 0xf804
loc_1ab80 46 60                            notw (a0)-
loc_1ab82 f8 f8                            .short 0xf8f8
loc_1ab84 00 0a                            .short loc_a
loc_1ab86 f8 04                            .short 0xf804
loc_1ab88 46 62                            notw (a2)-
loc_1ab8a f8 f8                            .short 0xf8f8
loc_1ab8c 00 0a                            .short loc_a
loc_1ab8e f8 04                            .short 0xf804
loc_1ab90 46 64                            notw (a4)-
loc_1ab92 f8 f8                            .short 0xf8f8
loc_1ab94 00 0b                            .short loc_b
loc_1ab96 00 04 46 66                      ori.b #102,d4
loc_1ab9a f8 f8                            .short 0xf8f8
loc_1ab9c 00 0b                            .short loc_b
loc_1ab9e 00 04 46 68                      ori.b #104,d4
loc_1aba2 f8 f8                            .short 0xf8f8
loc_1aba4 00 0b                            .short loc_b
loc_1aba6 00 04 46 6a                      ori.b #106,d4
loc_1abaa f8 f8                            .short 0xf8f8
loc_1abac 00 0c                            .short loc_c
loc_1abae f8 01                            .short 0xf801
loc_1abb0 46 6c f8 00                      notw (a4)(-2048)
loc_1abb4 00 0c                            .short loc_c
loc_1abb6 f8 01                            .short 0xf801
loc_1abb8 46 6e f8 00                      notw (a6)(-2048)
loc_1abbc 00 0d                            .short loc_d
loc_1abbe f8 01                            .short 0xf801
loc_1abc0 56 6c f8 00                      addq.w  #3,(a4)(-2048)
loc_1abc4 00 0d                            .short loc_d
loc_1abc6 f8 01                            .short 0xf801
loc_1abc8 56 6e f8 00                      addq.w  #3,(a6)(-2048)



loc_1abcc: 01 ff                            .short 0x01ff
loc_1abce f0 01                            .short 0xf001
loc_1abd0 46 70 f8 00                      notw (a0,sp:l)
loc_1abd4 f8 00                            .short 0xf800
loc_1abd6 46 72 f0 08                      notw (a2)8,sp.w)



loc_1abda: 01 ff                            .short 0x01ff
loc_1abdc 00 04 46 73                      ori.b #115,d4
loc_1abe0 f0 00                            .short 0xf000
loc_1abe2 08 00 46 75                      btst    #117,d0
loc_1abe6 f8 00                            .short 0xf800



loc_1abe8: 01 ff                            .short 0x01ff
loc_1abea 00 04 46 76                      ori.b #118,d4
loc_1abee 00 f0                            .short 0x00f0
loc_1abf0 08 00 5e 70                      btst    #112,d0
loc_1abf4 00 f8                            .short 0x00f8
loc_1abf6 01 ff                            .short 0x01ff
loc_1abf8 f0 01                            .short 0xf001
loc_1abfa 46 78 00 f8                      notw loc_0f8
loc_1abfe f8 00                            .short 0xf800
loc_1ac00 5e 73 08 f0                      addq.w  #7,(a3)(fffffffffffffff0,d0:l)



loc_1ac04: 01 ff                            .short 0x01ff
loc_1ac06 f8 04                            .short 0xf804
loc_1ac08 46 7a                            .short 0x467a
loc_1ac0a f8 f8                            .short 0xf8f8
loc_1ac0c 00 00 46 7c                      ori.b #$7C,d0
loc_1ac10 00 f8                            .short 0x00f8


loc_1ac12: 01 ff                            .short 0x01ff
loc_1ac14 f8 01                            .short 0xf801
loc_1ac16 46 7d                            .short 0x467d
loc_1ac18 00 f8                            .short 0x00f8
loc_1ac1a 00 00 46 7f                      ori.b #$7F,d0
loc_1ac1e f8 00                            .short 0xf800



loc_1ac20: 01 ff                            .short 0x01ff
loc_1ac22 f8 01                            .short 0xf801
loc_1ac24 5e 7b                            .short 0x5e7b
loc_1ac26 f8 00                            .short 0xf800
loc_1ac28 00 00 5e 7a                      ori.b #122,d0
loc_1ac2c 00 f8                            .short 0x00f8



loc_1ac2e: 01 ff                            .short 0x01ff
loc_1ac30 f8 04                            .short 0xf804
loc_1ac32 46 80                            notl d0
loc_1ac34 f8 f8                            .short 0xf8f8
loc_1ac36 00 00 5e 7d                      ori.b #125,d0
loc_1ac3a f8 00                            .short 0xf800
loc_1ac3c 00 0e                            .short loc_e
loc_1ac3e f8 01                            .short 0xf801
loc_1ac40 46 82                            notl d2
loc_1ac42 fc fc                            .short 0xfcfc
loc_1ac44 00 0e                            .short loc_e
loc_1ac46 f8 01                            .short 0xf801
loc_1ac48 4e 82                            .short 0x4e82
loc_1ac4a fc fc                            .short 0xfcfc


loc_1ac4c: 00 09                            .short loc_9
loc_1ac4e f0 01                            .short 0xf001
loc_1ac50 46 84                            notl d4
loc_1ac52 fc fc                            .short 0xfcfc
loc_1ac54 00 0e                            .short loc_e
loc_1ac56 f8 01                            .short 0xf801
loc_1ac58 56 82                            addq.l #3,d2
loc_1ac5a fc fc                            .short 0xfcfc
loc_1ac5c 00 0e                            .short loc_e
loc_1ac5e f8 01                            .short 0xf801
loc_1ac60 5e 82                            addq.l #7,d2
loc_1ac62 fc fc                            .short 0xfcfc



loc_1ac64: 00 0f                            .short loc_f
loc_1ac66 00 01 56 84                      ori.b #-124,d1
loc_1ac6a fc fc                            .short 0xfcfc
loc_1ac6c 01 ff                            .short 0x01ff
loc_1ac6e f6 04                            .short 0xf604
loc_1ac70 46 7a                            .short 0x467a
loc_1ac72 f6 fa                            .short 0xf6fa
loc_1ac74 fe 00                            .short 0xfe00
loc_1ac76 46 7c                            .short 0x467c
loc_1ac78 fe fa                            .short 0xfefa
loc_1ac7a 01 ff                            .short 0x01ff
loc_1ac7c f0 01                            .short 0xf001
loc_1ac7e 46 7d                            .short 0x467d
loc_1ac80 fc fc                            .short 0xfcfc
loc_1ac82 f8 00                            .short 0xf800
loc_1ac84 46 7f                            .short 0x467f
loc_1ac86 f4 04                            .short 0xf404
loc_1ac88 01 ff                            .short 0x01ff
loc_1ac8a f0 01                            .short 0xf001
loc_1ac8c 5e 7b                            .short 0x5e7b
loc_1ac8e fc fc                            .short 0xfcfc
loc_1ac90 f8 00                            .short 0xf800
loc_1ac92 5e 7a                            .short 0x5e7a
loc_1ac94 04 f4                            .short 0x04f4
loc_1ac96 01 ff                            .short 0x01ff
loc_1ac98 f3 04                            .short 0xf304
loc_1ac9a 46 80                            notl d0
loc_1ac9c fb f5                            .short 0xfbf5
loc_1ac9e fb 00                            .short 0xfb00
loc_1aca0 5e 7d                            .short 0x5e7d
loc_1aca2 fb fd                            .short 0xfbfd
loc_1aca4 08 ff                            .short 0x08ff
loc_1aca6 00 00 80 47                      ori.b #71,d0
loc_1acaa 00 f8                            .short 0x00f8
loc_1acac 00 00 80 41                      ori.b #65,d0
loc_1acb0 08 f0 00 00 80 4d                bset    #0,(a0)(000000000000004d,a0.w)
loc_1acb6 10 e8 00 00                      move.b  (a0),(a0)+
loc_1acba 80 45                            or.w d5,d0
loc_1acbc 18 e0                            move.b  (a0)-,(a4)+
loc_1acbe 00 00 80 20                      ori.b #$20,d0
loc_1acc2 20 d8                            move.l  (a0)+,(a0)+
loc_1acc4 00 00 80 4f                      ori.b #79,d0
loc_1acc8 28 d0                            move.l  (a0),(a4)+
loc_1acca 00 00 80 56                      ori.b #86,d0
loc_1acce 30 c8                            move.w  a0,(a0)+
loc_1acd0 00 00 80 45                      ori.b #69,d0
loc_1acd4 38 c0                            move.w  d0,(a4)+
loc_1acd6 00 00 80 52                      ori.b #82,d0
loc_1acda 40 b8



loc_1ACDC:
0d ff                      negxl loc_dff
loc_1acde 00 00 80 50                      ori.b #$50,d0
loc_1ace2 c8 30 00 00                      and.b (a0,d0.w),d4
loc_1ace6 80 55                            or.w (a5),d0
loc_1ace8 d0 28 00 00                      add.b (a0),d0
loc_1acec 80 53                            or.w (a3),d0
loc_1acee d8 20                            add.b (a0)-,d4
loc_1acf0 00 00 80 48                      ori.b #72,d0
loc_1acf4 e0 18                            ror.b #8,d0
loc_1acf6 00 04 80 53                      ori.b #83,d4
loc_1acfa f0 00                            .short 0xf000
loc_1acfc 00 00 80 41                      ori.b #65,d0
loc_1ad00 00 f8                            .short 0x00f8
loc_1ad02 00 00 80 52                      ori.b #82,d0
loc_1ad06 08 f0 00 00 80 54                bset    #0,(a0)(0000000000000054,a0.w)
loc_1ad0c 10 e8 00 00                      move.b  (a0),(a0)+
loc_1ad10 80 42                            or.w d2,d0
loc_1ad12 20 d8                            move.l  (a0)+,(a0)+
loc_1ad14 00 00 80 55                      ori.b #85,d0
loc_1ad18 28 d0                            move.l  (a0),(a4)+
loc_1ad1a 00 00 80 54                      ori.b #84,d0
loc_1ad1e 30 c8                            move.w  a0,(a0)+
loc_1ad20 00 00 80 54                      ori.b #84,d0
loc_1ad24 38 c0                            move.w  d0,(a4)+
loc_1ad26 00 00 80 4f                      ori.b #79,d0
loc_1ad2a 40 b8 00 00                      negxl loc_000
loc_1ad2e 80 4e                            .short 0x804e
loc_1ad30 48 b0 04 ff 00 00                movem.w d0-d7/a2,(a0,d0.w)
loc_1ad36 80 50                            or.w (a0),d0
loc_1ad38 00 f8                            .short 0x00f8
loc_1ad3a 00 00 80 41                      ori.b #65,d0
loc_1ad3e 08 f0 00 00 80 55                bset    #0,(a0)(0000000000000055,a0.w)
loc_1ad44 10 e8 00 00                      move.b  (a0),(a0)+
loc_1ad48 80 53                            or.w (a3),d0
loc_1ad4a 18 e0                            move.b  (a0)-,(a4)+
loc_1ad4c 00 00 80 45                      ori.b #69,d0
loc_1ad50 20 d8                            move.l  (a0)+,(a0)+

loc_1ad52: 00 ff                            .short 0x00ff
loc_1ad54 e0 0b                            lsr.b #8,d3
loc_1ad56 67 40                            beq.s   loc_1ad98
loc_1ad58 f4 f4                            .short 0xf4f4

loc_1ad5a: 00 ff                            .short 0x00ff
loc_1ad5c e8 0a                            lsr.b #4,d2
loc_1ad5e 67 4c                            beq.s   loc_1adac
loc_1ad60 f4 f4                            .short 0xf4f4

loc_1ad62: 00 ff                            .short 0x00ff
loc_1ad64 e8 06                            asrb #4,d6
loc_1ad66 67 55                            beq.s   loc_1adbd
loc_1ad68 f8 f8                            .short 0xf8f8


loc_1ad6a: 00 ff                            .short 0x00ff
loc_1ad6c e8 0a                            lsr.b #4,d2
loc_1ad6e 67 5b                            beq.s   loc_1adcb
loc_1ad70 f4 f4                            .short 0xf4f4


loc_1ad72: 00 ff                            .short 0x00ff
loc_1ad74 e8 0a                            lsr.b #4,d2
loc_1ad76 67 64                            beq.s   loc_1addc
loc_1ad78 f4 f4                            .short 0xf4f4

loc_1ad7a: 00 ff                            .short 0x00ff
loc_1ad7c e0 0b                            lsr.b #8,d3
loc_1ad7e 67 6d                            beq.s   loc_1aded
loc_1ad80 f4 f4                            .short 0xf4f4


loc_1ad82 00 ff                            .short 0x00ff
loc_1ad84 e8 06                            asrb #4,d6
loc_1ad86 46 87                            notl d7
loc_1ad88 f8 f8                            .short 0xf8f8
loc_1ad8a 00 ff                            .short 0x00ff
loc_1ad8c e8 06                            asrb #4,d6
loc_1ad8e 46 8d                            .short 0x468d
loc_1ad90 f8 f8                            .short 0xf8f8

; TODO IMPORTANT - RAM Table!

loc_1ad92: ad f2                            .short 0xadf2
loc_1ad94 ae 40                            .short 0xae40
loc_1ad96 ae 40                            .short 0xae40
loc_1ad98 ae 7c                            .short 0xae7c
loc_1ad9a ae dc                            .short 0xaedc
loc_1ad9c af 20                            .short 0xaf20
loc_1ad9e af 20                            .short 0xaf20
loc_1ada0 af 6c                            .short 0xaf6c
loc_1ada2 af be                            .short 0xafbe
loc_1ada4 b0 12                            cmp.b (a2),d0
loc_1ada6 b0 12                            cmp.b (a2),d0
loc_1ada8 b0 70 b0 b0                      cmp.w (a0)(ffffffffffffffb0,a3.w),d0
loc_1adac b1 08                            cmpmb (a0)+,(a0)+
loc_1adae b1 08                            cmpmb (a0)+,(a0)+
loc_1adb0 b1 52                            eor.w d0,(a2)
loc_1adb2 b1 a0                            eor.l d0,(a0)-
loc_1adb4 b1 f8 b1 f8                      cmpal ($FFFFb1f8,a0
loc_1adb8 b2 42                            cmp.w   d2,d1
loc_1adba b2 a4                            cmp.l (a4)-,d1
loc_1adbc b2 e8 b2 e8                      cmpa.w (a0)(-19736),a1
loc_1adc0 b3 46                            eor.w d1,d6
loc_1adc2 b3 a2                            eor.l d1,(a2)-
loc_1adc4 b3 ee b3 ee                      cmpal (a6)(-19474),a1
loc_1adc8 b4 3c b4 86                      cmp.b #-122,d2
loc_1adcc b4 c8                            cmpa.w a0,a2
loc_1adce b4 c8                            cmpa.w a0,a2
loc_1add0 b5 22                            eor.b d2,(a2)-
loc_1add2 b5 6c b5 ae                      eor.w d2,(a4)(-19026)
loc_1add6 b5 ae b6 02                      eor.l d2,(a6)(-18942)
loc_1adda b6 6c b6 c0                      cmp.w (a4)(-18752),d3
loc_1adde b6 c0                            cmpa.w d0,a3
loc_1ade0 b7 00                            eor.b d3,d0
loc_1ade2 b7 4e                            cmpmw (a6)+,(a3)+
loc_1ade4 b7 b4 b7 b4 b8 1c b8 5e          eor.l d3,@(ffffffffb81cb85e)@0,a3.w:8)
loc_1adec b8 c8                            cmpa.w a0,a4
loc_1adee b8 c8                            cmpa.w a0,a4
loc_1adf0 b9 1c                            eor.b d4,(a4)+
loc_1adf2 40 86                            negxl d6
loc_1adf4 14 86                            move.b  d6,(a2)
loc_1adf6 4a 8c                            .short 0x4a8c
loc_1adf8 4a 86                            tst.l   d6
loc_1adfa 14 86                            move.b  d6,(a2)
loc_1adfc 4a 8c                            .short 0x4a8c
loc_1adfe 4a 86                            tst.l   d6
loc_1ae00 14 86                            move.b  d6,(a2)
loc_1ae02 4a 8c                            .short 0x4a8c
loc_1ae04 4a 86                            tst.l   d6
loc_1ae06 14 86                            move.b  d6,(a2)
loc_1ae08 00 0f                            .short loc_f
loc_1ae0a 17 0f                            .short 0x170f
loc_1ae0c 0b 0f 05 13                      movepw (sp)(1299),d5
loc_1ae10 03 08 1e 06                      movepw (a0)(7686),d1
loc_1ae14 1e 0c                            .short 0x1e0c
loc_1ae16 1e 12                            move.b  (a2),d7
loc_1ae18 00 12 00 0c                      ori.b #$C,(a2)
loc_1ae1c 00 06 0e 0f                      ori.b #$F,d6
loc_1ae20 10 0f                            .short 0x100f
loc_1ae22 01 07                            btst d0,d7
loc_1ae24 03 00                            btst d1,d0
loc_1ae26 0b 06                            btst d5,d6
loc_1ae28 0b 0c 0b 12                      movepw (a4)(2834),d5
loc_1ae2c 13 12                            move.b  (a2),(a1)-
loc_1ae2e 13 0c                            .short 0x130c
loc_1ae30 13 06                            move.b  d6,(a1)-
loc_1ae32 06 0f                            .short 0x060f
loc_1ae34 0f 13                            btst d7,(a3)
loc_1ae36 15 1f                            move.b  (sp)+,(a2)-
loc_1ae38 12 1f                            move.b  (sp)+,d1
loc_1ae3a 0c 0c                            .short 0x0c0c
loc_1ae3c 09 12                            btst d4,(a2)
loc_1ae3e 09 00                            btst d4,d0
loc_1ae40 7f 44                            .short 0x7f44
loc_1ae42 9a 7f                            .short 0x9a7f
loc_1ae44 24 8d                            move.l  a5,(a2)
loc_1ae46 06 8d                            .short 0x068d
loc_1ae48 7f 24                            .short 0x7f24
loc_1ae4a 9a 7f                            .short 0x9a7f
loc_1ae4c 00 0f                            .short loc_f
loc_1ae4e 05 07                            btst d2,d7
loc_1ae50 06 16 12 06                      addi.b #6,(a6)
loc_1ae54 10 04                            move.b  d4,d0
loc_1ae56 09 0a 09 16                      movepw (a2)(2326),d4
loc_1ae5a 18 16                            move.b  (a6),d4
loc_1ae5c 1c 0a                            .short 0x1c0a
loc_1ae5e 00 01 0e 0a                      ori.b #$A,d1
loc_1ae62 09 07                            btst d4,d7
loc_1ae64 09 0d 09 13                      movepw (a5)(2323),d4
loc_1ae68 17 13                            move.b  (a3),(a3)-
loc_1ae6a 17 0d                            .short 0x170d
loc_1ae6c 17 07                            move.b  d7,(a3)-
loc_1ae6e 06 00 06 06                      addi.b #6,d0
loc_1ae72 0a 00 15 0f                      eori.b #$F,d0
loc_1ae76 16 19                            move.b  (a1)+,d3
loc_1ae78 0a 17 03 00                      eori.b #0,(sp)
loc_1ae7c 7f 41                            .short 0x7f41
loc_1ae7e 8d 06                            sbcd d6,d6
loc_1ae80 8d 7f                            .short 0x8d7f
loc_1ae82 21 8d 06 8d                      move.l  a5,(a0)(ffffffffffffff8d,d0.w:8)
loc_1ae86 7f 21                            .short 0x7f21
loc_1ae88 8d 06                            sbcd d6,d6
loc_1ae8a 8d 7f                            .short 0x8d7f
loc_1ae8c 00 0f                            .short loc_f
loc_1ae8e 17 1b                            move.b  (a3)+,(a3)-
loc_1ae90 06 16 18 14                      addi.b #$14,(a6)
loc_1ae94 03 13                            btst d1,(a3)
loc_1ae96 01 04                            btst d0,d4
loc_1ae98 03 04                            btst d1,d4
loc_1ae9a 07 04                            btst d3,d4
loc_1ae9c 1d 04                            move.b  d4,(a6)-
loc_1ae9e 15 0a                            .short 0x150a
loc_1aea0 17 0a                            .short 0x170a
loc_1aea2 1b 0a                            .short 0x1b0a
loc_1aea4 1d 0a                            .short 0x1d0a
loc_1aea6 07 0a 09 0a                      movepw (a2)(2314),d3
loc_1aeaa 07 10                            btst d3,(a0)
loc_1aeac 01 10                            btst d0,(a0)
loc_1aeae 03 10                            btst d1,(a0)
loc_1aeb0 15 10                            move.b  (a0),(a2)-
loc_1aeb2 1b 16                            move.b  (a6),(a5)-
loc_1aeb4 1d 16                            move.b  (a6),(a6)-
loc_1aeb6 00 16 03 16                      ori.b #22,(a6)
loc_1aeba 05 16                            btst d2,(a6)
loc_1aebc 00 00 05 07                      ori.b #7,d0
loc_1aec0 05 0d 05 13                      movepw (a5)(1299),d2
loc_1aec4 19 13                            move.b  (a3),(a4)-
loc_1aec6 19 0d                            .short 0x190d
loc_1aec8 19 07                            move.b  d7,(a4)-
loc_1aeca 08 07 03 06                      btst    #6,d7
loc_1aece 0a 07 10 07                      eori.b #7,d7
loc_1aed2 16 19                            move.b  (a1)+,d3
loc_1aed4 16 19                            move.b  (a1)+,d3
loc_1aed6 10 1a                            move.b  (a2)+,d0
loc_1aed8 0a 17 03 00                      eori.b #0,(sp)
loc_1aedc 7f 0d                            .short 0x7f0d
loc_1aede 88 70 88 08                      or.w (a0)8,a0:l),d4
loc_1aee2 88 64                            or.w (a4)-,d4
loc_1aee4 84 18                            or.b (a0)+,d2
loc_1aee6 84 64                            or.w (a4)-,d2
loc_1aee8 88 08                            .short 0x8808
loc_1aeea 88 70 88 00                      or.w (a0,a0:l),d4
loc_1aeee 0f 03                            btst d7,d3
loc_1aef0 07 08 17 10                      movepw (a0)(5904),d3
loc_1aef4 01 16                            btst d0,(a6)
loc_1aef6 04 06 0e 08                      subi.b #8,d6
loc_1aefa 0e 0e                            .short 0x0e0e
loc_1aefc 12 10                            move.b  (a0),d1
loc_1aefe 12 00                            move.b  d0,d1
loc_1af00 00 09                            .short loc_9
loc_1af02 09 09 11 0f                      movepw (a1)(4367),d4
loc_1af06 15 15                            move.b  (a5),(a2)-
loc_1af08 11 15                            move.b  (a5),(a0)-
loc_1af0a 09 1f                            btst d4,(sp)+
loc_1af0c 0d 06                            btst d6,d6
loc_1af0e 07 03                            btst d3,d3
loc_1af10 00 09                            .short loc_9
loc_1af12 07 0d 0f 10                      movepw (a5)(3856),d3
loc_1af16 0f 0a 05 14                      movepw (a2)(1300),d7
loc_1af1a 02 17 05 19                      andi.b  #25,(sp)
loc_1af1e 15 00                            move.b  d0,(a2)-
loc_1af20 06 c7                            .short 0x06c7
loc_1af22 7f 3a                            .short 0x7f3a
loc_1af24 86 05                            or.b d5,d3
loc_1af26 c7 8a                            exg d3,a2
loc_1af28 05 c7                            bset d2,d7
loc_1af2a 84 7f                            .short 0x847f
loc_1af2c 21 c7 8a 05                      move.l  d7,($FFFF8a05
loc_1af30 c7 8a                            exg d3,a2
loc_1af32 7f 2b                            .short 0x7f2b
loc_1af34 c6 8a                            .short 0xc68a
loc_1af36 05 8b 7f 00                      movepw d2,(a3)(32512)
loc_1af3a 0f 05                            btst d7,d5
loc_1af3c 1d 06                            move.b  d6,(a6)-
loc_1af3e 15 18                            move.b  (a0)+,(a2)-
loc_1af40 0c 16 04 0c                      cmpi.b  #$C,(a6)
loc_1af44 04 13 04 07                      subi.b #7,(a3)
loc_1af48 10 09                            .short 0x1009
loc_1af4a 10 00                            move.b  d0,d0
loc_1af4c 00 1b 07 03                      ori.b #3,(a3)+
loc_1af50 07 05                            btst d3,d5
loc_1af52 0d 05                            btst d6,d5
loc_1af54 13 19                            move.b  (a1)+,(a1)-
loc_1af56 13 18                            move.b  (a0)+,(a1)-
loc_1af58 0d 06                            btst d6,d6
loc_1af5a 0a 04 03 0a                      eori.b #$A,d4
loc_1af5e 09 16                            btst d4,(a6)
loc_1af60 12 10                            move.b  (a0),d1
loc_1af62 12 0a                            .short 0x120a
loc_1af64 18 04                            move.b  d4,d4
loc_1af66 02 1d 10 1a                      andi.b  #26,(a5)+
loc_1af6a 16 00                            move.b  d0,d3
loc_1af6c 57 c5                            seq d5
loc_1af6e 86 6d 8c 01                      or.w (a5)(-29695),d3
loc_1af72 87 1f                            or.b d3,(sp)+
loc_1af74 c4 41                            and.w d1,d2
loc_1af76 85 1a                            or.b d2,(a2)+
loc_1af78 81 04                            sbcd d4,d0
loc_1af7a c4 26                            and.b (a6)-,d2
loc_1af7c c7 8b                            exg d3,a3
loc_1af7e 29 84 17 85                      move.l  d4,@0)@0,d1.w:8)
loc_1af82 60 87                            bra.s   loc_1af0b
loc_1af84 05 86                            bclr d2,d6
loc_1af86 04 8a                            .short 0x048a
loc_1af88 06 c5                            .short 0x06c5
loc_1af8a 7f 00                            .short 0x7f00
loc_1af8c 0f 05                            btst d7,d5
loc_1af8e 1a 02                            move.b  d2,d5
loc_1af90 1a 18                            move.b  (a0)+,d5
loc_1af92 01 08 03 0d                      movepw (a0)(781),d0
loc_1af96 0a 0f                            .short 0x0a0f
loc_1af98 0a 16 16 01                      eori.b #1,(a6)
loc_1af9c 02 05 00 0c                      andi.b  #$C,d5
loc_1afa0 07 0c 0d 0c                      movepw (a4)(3340),d3
loc_1afa4 13 0c                            .short 0x130c
loc_1afa6 19 18                            move.b  (a0)+,(a4)-
loc_1afa8 19 18                            move.b  (a0)+,(a4)-
loc_1afaa 13 06                            move.b  d6,(a1)-
loc_1afac 04 03 00 16                      subi.b #22,d3
loc_1afb0 07 0a 07 0f                      movepw (a2)(1807),d3
loc_1afb4 0e 10                            .short 0x0e10
loc_1afb6 0d 16                            btst d6,(a6)
loc_1afb8 02 18 0b 13                      andi.b  #$13,(a0)+
loc_1afbc 03 00                            btst d1,d0
loc_1afbe 7f 03                            .short 0x7f03
loc_1afc0 cb 8b                            exg d5,a3
loc_1afc2 04 8c                            .short 0x048c
loc_1afc4 1f ca                            .short 0x1fca
loc_1afc6 6a 86                            bpl.s   loc_1af4e
loc_1afc8 04 cb                            .short 0x04cb
loc_1afca 85 15                            or.b d2,(a5)
loc_1afcc ca 75 85 10                      and.w (a5,a0.w:4),d5
loc_1afd0 85 7f                            .short 0x857f
loc_1afd2 06 8b                            .short 0x068b
loc_1afd4 06 8b                            .short 0x068b
loc_1afd6 7f 00                            .short 0x7f00
loc_1afd8 0f 17                            btst d7,(sp)
loc_1afda 1a 04                            move.b  d4,d5
loc_1afdc 07 18                            btst d3,(a0)+
loc_1afde 04 02 06 09                      subi.b #9,d2
loc_1afe2 02 0b                            .short 0x020b
loc_1afe4 02 04 0c 0a                      andi.b  #$A,d4
loc_1afe8 11 15                            move.b  (a5),(a0)-
loc_1afea 11 1a                            move.b  (a2)+,(a0)-
loc_1afec 0c 02 06 08                      cmpi.b  #8,d2
loc_1aff0 17 17                            move.b  (sp),(a3)-
loc_1aff2 00 09                            .short loc_9
loc_1aff4 05 09 0a 09                      movepw (a1)(2569),d2
loc_1aff8 14 15                            move.b  (a5),d2
loc_1affa 14 15                            move.b  (a5),d2
loc_1affc 0a 15 05 04                      eori.b #4,(a5)
loc_1b000 07 02                            btst d3,d2
loc_1b002 17 02                            move.b  d2,(a3)-
loc_1b004 09 08 1f 0b                      movepw (a0)(7947),d4
loc_1b008 04 15 08 15                      subi.b #21,(a5)
loc_1b00c 0e 09                            .short 0x0e09
loc_1b00e 0e 0f                            .short 0x0e0f
loc_1b010 0c 00 40 84                      cmpi.b  #-124,d0
loc_1b014 18 c7                            move.b  d7,(a4)+
loc_1b016 83 03                            sbcd d3,d1
loc_1b018 c2 20                            and.b (a0)-,d1
loc_1b01a 84 24                            or.b (a4)-,d2
loc_1b01c 88 25                            or.b (a5)-,d4
loc_1b01e 83 24                            or.b d1,(a4)-
loc_1b020 84 19                            or.b (a1)+,d2
loc_1b022 83 03                            sbcd d3,d1
loc_1b024 c2 20                            and.b (a0)-,d1
loc_1b026 84 24                            or.b (a4)-,d2
loc_1b028 88 24                            or.b (a4)-,d4
loc_1b02a 84 1f                            or.b (sp)+,d2
loc_1b02c c8 04                            and.b d4,d4
loc_1b02e 84 18                            or.b (a0)+,d2
loc_1b030 84 03                            or.b d3,d2
loc_1b032 c2 20                            and.b (a0)-,d1
loc_1b034 84 24                            or.b (a4)-,d2
loc_1b036 88 24                            or.b (a4)-,d4
loc_1b038 83 25                            or.b d1,(a5)-
loc_1b03a 84 18                            or.b (a0)+,d2
loc_1b03c 84 00                            or.b d0,d2
loc_1b03e 0f 04                            btst d7,d4
loc_1b040 00 08                            .short loc_8
loc_1b042 11 18                            move.b  (a0)+,(a0)-
loc_1b044 0d 16                            btst d6,(a6)
loc_1b046 03 05                            btst d1,d5
loc_1b048 0e 0f                            .short 0x0e0f
loc_1b04a 0f 18                            btst d7,(a0)+
loc_1b04c 10 00                            move.b  d0,d0
loc_1b04e 01 07                            btst d0,d7
loc_1b050 16 0f                            .short 0x160f
loc_1b052 12 0f                            .short 0x120f
loc_1b054 19 1d                            move.b  (a5)+,(a4)-
loc_1b056 15 1d                            move.b  (a5)+,(a2)-
loc_1b058 0f 1d                            btst d7,(a5)+
loc_1b05a 09 1d                            btst d4,(a5)+
loc_1b05c 03 04                            btst d1,d4
loc_1b05e 06 02 05 08                      addi.b #8,d2
loc_1b062 05 0e 19 02                      movepw (a6)(6402),d2
loc_1b066 04 19 0a 15                      subi.b #21,(a1)+
loc_1b06a 0f 0f 16 0f                      movepw (sp)(5647),d7
loc_1b06e 09 00                            btst d4,d0
loc_1b070 43 9a                            chkw (a2)+,d1
loc_1b072 7f 04                            .short 0x7f04
loc_1b074 8e 04                            or.b d4,d7
loc_1b076 8e 6e 84 7a                      or.w (a6)(-31622),d7
loc_1b07a 88 7f                            .short 0x887f
loc_1b07c 17 8c                            .short 0x178c
loc_1b07e 00 0f                            .short loc_f
loc_1b080 13 02                            move.b  d2,(a1)-
loc_1b082 18 19                            move.b  (a1)+,d4
loc_1b084 07 1c                            btst d3,(a4)+
loc_1b086 0e 01                            .short 0x0e01
loc_1b088 1a 16                            move.b  (a6),d5
loc_1b08a 01 18                            btst d0,(a0)+
loc_1b08c 13 02                            move.b  d2,(a1)-
loc_1b08e 00 10 05 0d                      ori.b #$D,(a0)
loc_1b092 05 03                            btst d2,d3
loc_1b094 09 03                            btst d4,d3
loc_1b096 0d 03                            btst d6,d3
loc_1b098 11 03                            move.b  d3,(a0)-
loc_1b09a 15 03                            move.b  d3,(a2)-
loc_1b09c 19 03                            move.b  d3,(a4)-
loc_1b09e 04 0f                            .short 0x040f
loc_1b0a0 01 09 05 15                      movepw (a1)(1301),d0
loc_1b0a4 05 0f 09 04                      movepw (sp)(2308),d2
loc_1b0a8 06 0f                            .short 0x060f
loc_1b0aa 02 13 1a 14                      andi.b  #$14,(a3)
loc_1b0ae 18 0e                            .short 0x180e
loc_1b0b0 6a c3                            bpl.s   loc_1b075
loc_1b0b2 87 1f                            or.b d3,(sp)+
loc_1b0b4 c4 0e                            .short 0xc40e
loc_1b0b6 82 04                            or.b d4,d1
loc_1b0b8 84 12                            or.b (a2),d2
loc_1b0ba 84 32 84 70                      or.b (a2)(0000000000000070,a0.w:4),d2
loc_1b0be 84 0c                            .short 0x840c
loc_1b0c0 c5 83                            .short 0xc583
loc_1b0c2 0f c4                            bset d7,d4
loc_1b0c4 58 84                            addq.l #4,d4
loc_1b0c6 04 84 04 84 04 84                subi.l #75760772,d4
loc_1b0cc 62 82                            bhi.s   loc_1b050
loc_1b0ce 1c 82                            move.b  d2,(a6)
loc_1b0d0 0a 8c                            .short 0x0a8c
loc_1b0d2 00 0f                            .short loc_f
loc_1b0d4 13 14                            move.b  (a4),(a1)-
loc_1b0d6 07 04                            btst d3,d4
loc_1b0d8 18 1b                            move.b  (a3)+,d4
loc_1b0da 16 03                            move.b  d3,d3
loc_1b0dc 1b 0d                            .short 0x1b0d
loc_1b0de 13 0d                            .short 0x130d
loc_1b0e0 0b 0d 01 04                      movepw (a5)(260),d5
loc_1b0e4 15 02                            move.b  d2,(a2)-
loc_1b0e6 00 0b                            .short loc_b
loc_1b0e8 18 03                            move.b  d3,d4
loc_1b0ea 0b 04                            btst d5,d4
loc_1b0ec 13 08                            .short 0x1308
loc_1b0ee 13 10                            move.b  (a0),(a1)-
loc_1b0f0 13 15                            move.b  (a5),(a1)-
loc_1b0f2 0b 15                            btst d5,(a5)
loc_1b0f4 0b 10                            btst d5,(a0)
loc_1b0f6 04 03 02 0d                      subi.b #$D,d3
loc_1b0fa 02 1d 03 18                      andi.b  #$18(a5)+
loc_1b0fe 06 04 02 0b                      addi.b #11,d4
loc_1b102 0c 0b                            .short 0x0c0b
loc_1b104 12 0d                            .short 0x120d
loc_1b106 19 15                            move.b  (a5),(a4)-
loc_1b108 6c 88                            bge.s   loc_1b092
loc_1b10a 7f 14                            .short 0x7f14
loc_1b10c 86 06                            or.b d6,d3
loc_1b10e 86 7f                            .short 0x867f
loc_1b110 2a 86                            move.l  d6,(a5)
loc_1b112 10 86                            move.b  d6,(a0)
loc_1b114 7f 23                            .short 0x7f23
loc_1b116 83 1a                            or.b d1,(a2)+
loc_1b118 83 00                            sbcd d0,d1
loc_1b11a 0f 17                            btst d7,(sp)
loc_1b11c 09 08 1b 0e                      movepw (a0)(6926),d4
loc_1b120 10 11                            move.b  (a1),d0
loc_1b122 02 16 06 04                      andi.b  #4,(a6)
loc_1b126 0c 02 06 17                      cmpi.b  #23,d2
loc_1b12a 15 15                            move.b  (a5),(a2)-
loc_1b12c 03 19                            btst d1,(a1)+
loc_1b12e 04 1b 0a 00                      subi.b #0,(a3)+
loc_1b132 04 0b                            .short 0x040b
loc_1b134 09 06                            btst d4,d6
loc_1b136 0f 01                            btst d7,d1
loc_1b138 15 1d                            move.b  (a5)+,(a2)-
loc_1b13a 15 18                            move.b  (a0)+,(a2)-
loc_1b13c 0f 13                            btst d7,(a3)
loc_1b13e 09 04                            btst d4,d4
loc_1b140 00 06 04 0c                      ori.b #$C,d6
loc_1b144 01 12                            btst d0,(a2)
loc_1b146 0c 11 04 13                      cmpi.b  #$13,(a1)
loc_1b14a 11 1d                            move.b  (a5)+,(a0)-
loc_1b14c 12 1c                            move.b  (a4)+,d1
loc_1b14e 07 15                            btst d3,(a5)
loc_1b150 06 00 68 85                      addi.b #-123,d0
loc_1b154 0b c3                            bset d5,d3
loc_1b156 83 10                            or.b d1,(a0)
loc_1b158 c2 20                            and.b (a0)-,d1
loc_1b15a 8b 68 84 08                      or.w d5,(a0)(-31736)
loc_1b15e 89 07                            sbcd d7,d4
loc_1b160 84 14                            or.b (a4),d2
loc_1b162 ca 7f                            .short 0xca7f
loc_1b164 14 c6                            move.b  d6,(a2)+
loc_1b166 87 05                            sbcd d5,d3
loc_1b168 87 72 86 0c                      or.w d3,(a2)c,a0.w:8)
loc_1b16c 88 00                            or.b d0,d4
loc_1b16e 0f 04                            btst d7,d4
loc_1b170 1a 03                            move.b  d3,d5
loc_1b172 0c 0f                            .short 0x0c0f
loc_1b174 1b 16                            move.b  (a6),(a5)-
loc_1b176 03 02                            btst d1,d2
loc_1b178 12 17                            move.b  (sp),d1
loc_1b17a 0d 19                            btst d6,(a1)+
loc_1b17c 0d 00                            btst d6,d0
loc_1b17e 01 05                            btst d0,d5
loc_1b180 0a 0a                            .short 0x0a0a
loc_1b182 04 0c                            .short 0x040c
loc_1b184 0a 0e                            .short 0x0a0e
loc_1b186 14 06                            move.b  d6,d2
loc_1b188 15 15                            move.b  (a5),(a2)-
loc_1b18a 10 19                            move.b  (a1)+,d0
loc_1b18c 04 04 04 05                      subi.b #5,d4
loc_1b190 03 11                            btst d1,(a1)
loc_1b192 09 08 17 09                      movepw (a0)(5897),d4
loc_1b196 04 11 0e 10                      subi.b #$10,(a1)
loc_1b19a 17 17                            move.b  (sp),(a3)-
loc_1b19c 14 0a                            .short 0x140a
loc_1b19e 14 00                            move.b  d0,d2
loc_1b1a0 7f 01                            .short 0x7f01
loc_1b1a2 82 0c                            .short 0x820c
loc_1b1a4 84 0c                            .short 0x840c
loc_1b1a6 82 62                            or.w (a2)-,d1
loc_1b1a8 84 04                            or.b d4,d2
loc_1b1aa 84 04                            or.b d4,d2
loc_1b1ac 84 04                            or.b d4,d2
loc_1b1ae 84 68 84 0c                      or.w (a0)(-31732),d2
loc_1b1b2 84 68 84 04                      or.w (a0)(-31740),d2
loc_1b1b6 84 04                            or.b d4,d2
loc_1b1b8 84 04                            or.b d4,d2
loc_1b1ba 84 62                            or.w (a2)-,d2
loc_1b1bc 82 0c                            .short 0x820c
loc_1b1be 84 0c                            .short 0x840c
loc_1b1c0 82 00                            or.b d0,d1
loc_1b1c2 0f 03                            btst d7,d3
loc_1b1c4 03 08 17 18                      movepw (a0)(5912),d1
loc_1b1c8 09 16                            btst d4,(a6)
loc_1b1ca 04 0b                            .short 0x040b
loc_1b1cc 0e 0b                            .short 0x0e0b
loc_1b1ce 06 13 06 13                      addi.b #$13,(a3)
loc_1b1d2 0e 00                            .short 0x0e00
loc_1b1d4 02 16 04 00                      andi.b  #0,(a6)
loc_1b1d8 0c 0c                            .short 0x0c0c
loc_1b1da 09 0a 11 00                      movepw (a2)(4352),d4
loc_1b1de 15 1e                            move.b  (a6)+,(a2)-
loc_1b1e0 15 14                            move.b  (a4),(a2)-
loc_1b1e2 11 12                            move.b  (a2),(a0)-
loc_1b1e4 09 04                            btst d4,d4
loc_1b1e6 08 05 07 0a                      btst    #$A,d5
loc_1b1ea 06 15 0f 0b                      addi.b #11,(a5)
loc_1b1ee 04 13 15 17                      subi.b #23,(a3)
loc_1b1f2 09 1b                            btst d4,(a3)+
loc_1b1f4 05 1d                            btst d2,(a5)+
loc_1b1f6 0f 00                            btst d7,d0
loc_1b1f8 47 c7                            .short 0x47c7
loc_1b1fa 85 06                            sbcd d6,d2
loc_1b1fc 86 1f                            or.b (sp)+,d3
loc_1b1fe c6 55                            and.w (a5),d3
loc_1b200 84 30 85 12 85 7f                or.b (a0,a0.w:4)@(ffffffffffff857f),d2
loc_1b206 25 86 10 c7                      move.l  d6,(a2)(ffffffffffffffc7,d1.w)
loc_1b20a 85 09                            sbcd (a1)-,(a2)-
loc_1b20c c6 7f                            .short 0xc67f
loc_1b20e 21 85 06 85                      move.l  d5,(a0)(ffffffffffffff85,d0.w:8)
loc_1b212 00 0f                            .short loc_f
loc_1b214 05 0a 02 14                      movepw (a2)(532),d2
loc_1b218 18 1c                            move.b  (a4)+,d4
loc_1b21a 16 02                            move.b  d2,d3
loc_1b21c 1a 06                            move.b  d6,d5
loc_1b21e 04 06 00 01                      subi.b #1,d6
loc_1b222 00 13 07 03                      ori.b #3,(a3)
loc_1b226 09 03                            btst d4,d3
loc_1b228 0b 03                            btst d5,d3
loc_1b22a 13 03                            move.b  d3,(a1)-
loc_1b22c 15 03                            move.b  d3,(a2)-
loc_1b22e 17 03                            move.b  d3,(a3)-
loc_1b230 04 00 0c 03                      subi.b #3,d0
loc_1b234 06 0a                            .short 0x060a
loc_1b236 0f 02                            btst d7,d2
loc_1b238 14 04                            move.b  d4,d2
loc_1b23a 0f 0d 14 0f                      movepw (a5)(5135),d7
loc_1b23e 1a 15                            move.b  (a5),d5
loc_1b240 1b 05                            move.b  d5,(a5)-
loc_1b242 7f 01                            .short 0x7f01
loc_1b244 8d 06                            sbcd d6,d6
loc_1b246 87 05                            sbcd d5,d3
loc_1b248 81 7f                            .short 0x817f
loc_1b24a 21 9a 05 81                      move.l  (a2)+,@0,d0.w:4)@0)
loc_1b24e 0c ca                            .short 0x0cca
loc_1b250 7f 14                            .short 0x7f14
loc_1b252 86 07                            or.b d7,d3
loc_1b254 8d 05                            sbcd d5,d6
loc_1b256 81 60                            or.w d0,(a0)-
loc_1b258 8c 12                            or.b (a2),d6
loc_1b25a 82 32 c2 c2                      or.b (a2)(ffffffffffffffc2,a4.w:2),d1
loc_1b25e c2 c2                            mulu.w d2,d1
loc_1b260 00 0f                            .short loc_f
loc_1b262 09 04                            btst d4,d4
loc_1b264 04 0f                            .short 0x040f
loc_1b266 18 13                            move.b  (a3),d4
loc_1b268 14 00                            move.b  d0,d2
loc_1b26a 08 08                            .short 0x0808
loc_1b26c 03 0e 03 18                      movepw (a6)(792),d1
loc_1b270 03 1a                            btst d1,(a2)+
loc_1b272 08 11 0f 17                      btst    #23,(a1)
loc_1b276 15 05                            move.b  d5,(a2)-
loc_1b278 0e 04                            .short 0x0e04
loc_1b27a 08 05 0a 08                      btst    #8,d5
loc_1b27e 07 11                            btst d3,(a1)
loc_1b280 1b 0b                            .short 0x1b0b
loc_1b282 17 0e                            .short 0x170e
loc_1b284 00 02 03 11                      ori.b #$11,d2
loc_1b288 05 15                            btst d2,(a5)
loc_1b28a 05 05                            btst d2,d5
loc_1b28c 17 05                            move.b  d5,(a3)-
loc_1b28e 17 0b                            .short 0x170b
loc_1b290 17 11                            move.b  (a1),(a3)-
loc_1b292 04 0a                            .short 0x040a
loc_1b294 02 04 08 08                      andi.b  #8,d4
loc_1b298 10 0e                            .short 0x100e
loc_1b29a 14 04                            move.b  d4,d2
loc_1b29c 1b 15                            move.b  (a5),(a5)-
loc_1b29e 0f 0e 15 08                      movepw (a6)(5384),d7
loc_1b2a2 1c 03                            move.b  d3,d6
loc_1b2a4 4e 84                            .short 0x4e84
loc_1b2a6 7a 88                            moveq   #-120,d5
loc_1b2a8 75 8e                            .short 0x758e
loc_1b2aa 6f 94                            ble.s   loc_1b240
loc_1b2ac 7f 0a                            .short 0x7f0a
loc_1b2ae 9a 7f                            .short 0x9a7f
loc_1b2b0 00 0f                            .short loc_f
loc_1b2b2 17 0f                            .short 0x170f
loc_1b2b4 06 17 18 00                      addi.b #0,(sp)
loc_1b2b8 0b 00                            btst d5,d0
loc_1b2ba 04 02 0b 07                      subi.b #7,d2
loc_1b2be 03 15                            btst d1,(a5)
loc_1b2c0 04 17 07 03                      subi.b #3,(sp)
loc_1b2c4 01 07                            btst d0,d7
loc_1b2c6 05 06                            btst d2,d6
loc_1b2c8 1c 0d                            .short 0x1c0d
loc_1b2ca 0f 07                            btst d7,d7
loc_1b2cc 0f 0b 0d 0f                      movepw (a3)(3343),d7
loc_1b2d0 11 0f                            .short 0x110f
loc_1b2d2 13 14                            move.b  (a4),(a1)-
loc_1b2d4 0b 14                            btst d5,(a4)
loc_1b2d6 04 04 0a 0a                      subi.b #$A,d4
loc_1b2da 04 0c                            .short 0x040c
loc_1b2dc 12 08                            .short 0x1208
loc_1b2de 17 04                            move.b  d4,(a3)-
loc_1b2e0 15 17                            move.b  (sp),(a2)-
loc_1b2e2 12 12                            move.b  (a2),d1
loc_1b2e4 15 05                            move.b  d5,(a2)-
loc_1b2e6 1d 09                            .short 0x1d09
loc_1b2e8 48 85                            ext.w d5
loc_1b2ea 06 c6                            .short 0x06c6
loc_1b2ec 84 08                            .short 0x8408
loc_1b2ee 82 0a                            .short 0x820a
loc_1b2f0 c5 11                            and.b d2,(a1)
loc_1b2f2 82 7f                            .short 0x827f
loc_1b2f4 04 85 10 85 7f 2c                subi.l #277184300,d5
loc_1b2fa 85 06                            sbcd d6,d2
loc_1b2fc c6 84                            and.l   d4,d3
loc_1b2fe 08 84 08 c5                      bclr    #-59,d4
loc_1b302 0f c6                            bset d7,d6
loc_1b304 83 03                            sbcd d3,d1
loc_1b306 c5 69 86 11                      and.w d2,(a1)(-31215)
loc_1b30a 84 10                            or.b (a0),d2
loc_1b30c 84 00                            or.b d0,d2
loc_1b30e 0f 17                            btst d7,(sp)
loc_1b310 1e 03                            move.b  d3,d7
loc_1b312 05 18                            btst d2,(a0)+
loc_1b314 1c 0d                            .short 0x1c0d
loc_1b316 00 05 00 0c                      ori.b #$C,d5
loc_1b31a 06 0c                            .short 0x060c
loc_1b31c 05 13                            btst d2,(a3)
loc_1b31e 09 17                            btst d4,(sp)
loc_1b320 13 0d                            .short 0x130d
loc_1b322 02 0f                            .short 0x020f
loc_1b324 0e 0e                            .short 0x0e0e
loc_1b326 03 09 03 09                      movepw (a1)(777),d1
loc_1b32a 0f 15                            btst d7,(a5)
loc_1b32c 03 15                            btst d1,(a5)
loc_1b32e 0f 1e                            btst d7,(a6)+
loc_1b330 10 1f                            move.b  (sp)+,d0
loc_1b332 04 04 0f 03                      subi.b #3,d4
loc_1b336 05 04                            btst d2,d4
loc_1b338 09 0a 07 12                      movepw (a2)(1810),d4
loc_1b33c 04 15 0b 19                      subi.b #25,(a5)
loc_1b340 05 17                            btst d2,(sp)
loc_1b342 13 1f                            move.b  (sp)+,(a1)-
loc_1b344 0d 00                            btst d6,d0
loc_1b346 6b c6                            bmi.s   loc_1b30e
loc_1b348 82 04                            or.b d4,d1
loc_1b34a d2 82                            add.l d2,d1
loc_1b34c 18 d1                            move.b  (a1),(a4)+
loc_1b34e 06 c5                            .short 0x06c5
loc_1b350 73 c6                            .short 0x73c6
loc_1b352 82 0a                            .short 0x820a
loc_1b354 83 1f                            or.b d1,(sp)+
loc_1b356 c5 6d c6 82                      and.w d2,(a5)(-14718)
loc_1b35a 10 83                            move.b  d3,(a0)
loc_1b35c 1f c5                            .short 0x1fc5
loc_1b35e 67 83                            beq.s   loc_1b2e3
loc_1b360 16 83                            move.b  d3,(a3)
loc_1b362 2c 83                            move.l  d3,(a6)
loc_1b364 06 83 00 0f 17 13                addi.l  #988947,d3
loc_1b36a 03 03                            btst d1,d3
loc_1b36c 18 1e                            move.b  (a6)+,d4
loc_1b36e 04 08                            .short 0x0408
loc_1b370 08 06 05 0b                      btst    #11,d6
loc_1b374 02 10 1c 10                      andi.b  #$10,(a0)
loc_1b378 19 0a                            .short 0x190a
loc_1b37a 16 06                            move.b  d6,d3
loc_1b37c 14 12                            move.b  (a2),d2
loc_1b37e 0a 12 01 01                      eori.b #1,(a2)
loc_1b382 05 00                            btst d2,d0
loc_1b384 0c 04 09 09                      cmpi.b  #9,d4
loc_1b388 06 0e                            .short 0x060e
loc_1b38a 18 0e                            .short 0x180e
loc_1b38c 15 09                            .short 0x1509
loc_1b38e 12 04                            move.b  d4,d1
loc_1b390 04 08                            .short 0x0408
loc_1b392 03 04                            btst d1,d4
loc_1b394 08 0a                            .short 0x080a
loc_1b396 0e 1f                            .short 0x0e1f
loc_1b398 0e 04                            .short 0x0e04
loc_1b39a 14 0e                            .short 0x140e
loc_1b39c 0f 0b 16 03                      movepw (a3)(5635),d7
loc_1b3a0 1a 08                            .short 0x1a08
loc_1b3a2 62 94                            bhi.s   loc_1b338
loc_1b3a4 1f c4                            .short 0x1fc4
loc_1b3a6 4a 8a                            .short 0x4a8a
loc_1b3a8 0c 84 04 82 19 c4                cmpi.l #75635140,d4
loc_1b3ae 4c c5                            .short 0x4cc5
loc_1b3b0 92 68 85 0a                      sub.w (a0)(-31478),d1
loc_1b3b4 8c 06                            or.b d6,d6
loc_1b3b6 c4 60                            and.w (a0)-,d2
loc_1b3b8 9b 7f                            .short 0x9b7f
loc_1b3ba 00 0f                            .short loc_f
loc_1b3bc 02 0f                            .short 0x020f
loc_1b3be 0b 0f 18 1e                      movepw (sp)(6174),d5
loc_1b3c2 10 04                            move.b  d4,d0
loc_1b3c4 12 09                            .short 0x1209
loc_1b3c6 0a 11 0c 11                      eori.b #$11,(a1)
loc_1b3ca 0c 09                            .short 0x0c09
loc_1b3cc 00 01 1c 0b                      ori.b #11,d1
loc_1b3d0 14 0c                            .short 0x140c
loc_1b3d2 15 0c                            .short 0x150c
loc_1b3d4 16 0c                            .short 0x160c
loc_1b3d6 03 14                            btst d1,(a4)
loc_1b3d8 04 14 05 14                      subi.b #$14,(a4)
loc_1b3dc 04 02 0c 08                      subi.b #8,d2
loc_1b3e0 02 09                            .short 0x0209
loc_1b3e2 10 09                            .short 0x1009
loc_1b3e4 16 04                            move.b  d4,d3
loc_1b3e6 0d 08 1c 0c                      movepw (a0)(7180),d6
loc_1b3ea 1c 04                            move.b  d4,d6
loc_1b3ec 14 16                            move.b  (a6),d2
loc_1b3ee d8 60                            add.w (a0)-,d4
loc_1b3f0 91 04                            subxb d4,d0
loc_1b3f2 86 1f                            or.b (sp)+,d3
loc_1b3f4 d0 55                            add.w (a5),d0
loc_1b3f6 c5 85                            .short 0xc585
loc_1b3f8 1f c8                            .short 0x1fc8
loc_1b3fa 56 c5                            sne d5
loc_1b3fc 83 78 c5 83                      or.w d1,($FFFFC583
loc_1b400 05 84                            bclr d2,d4
loc_1b402 6f 84                            ble.s   loc_1b388
loc_1b404 01 8d 7f 00                      movepw d0,(a5)(32512)
loc_1b408 0f 17                            btst d7,(sp)
loc_1b40a 08 03 06 18                      btst    #$18d3
loc_1b40e 02 0d                            .short 0x020d
loc_1b410 04 0a                            .short 0x040a
loc_1b412 0d 06                            btst d6,d6
loc_1b414 11 0e                            .short 0x110e
loc_1b416 09 13                            btst d4,(a3)
loc_1b418 05 01                            btst d2,d1
loc_1b41a 03 09 00 01                      movepw 1(a1),d1
loc_1b41e 04 0a                            .short 0x040a
loc_1b420 14 0b                            .short 0x140b
loc_1b422 14 12                            move.b  (a2),d2
loc_1b424 10 13                            move.b  (a3),d0
loc_1b426 10 14                            move.b  (a4),d0
loc_1b428 10 04                            move.b  d4,d0
loc_1b42a 0b 09 05 0d                      movepw (a1)(1293),d5
loc_1b42e 02 15 0f 10                      andi.b  #$10,(a5)
loc_1b432 04 13 0c 18                      subi.b #$18(a3)
loc_1b436 0b 1d                            btst d5,(a5)+
loc_1b438 0b 19                            btst d5,(a1)+
loc_1b43a 02 00 64 98                      andi.b  #-104,d0
loc_1b43e 64 8d                            bcc.s   loc_1b3cd
loc_1b440 06 8d                            .short 0x068d
loc_1b442 64 98                            bcc.s   loc_1b3dc
loc_1b444 64 8d                            bcc.s   loc_1b3d3
loc_1b446 06 8d                            .short 0x068d
loc_1b448 64 98                            bcc.s   loc_1b3e2
loc_1b44a 7f 00                            .short 0x7f00
loc_1b44c 0f 02                            btst d7,d2
loc_1b44e 0f 0b 0f 18                      movepw (a3)(3864),d7
loc_1b452 1c 16                            move.b  (a6),d6
loc_1b454 08 1e 16 00                      btst    #0,(a6)+
loc_1b458 16 00                            move.b  d0,d3
loc_1b45a 0d 00                            btst d6,d0
loc_1b45c 05 1e                            btst d2,(a6)+
loc_1b45e 05 1e                            btst d2,(a6)+
loc_1b460 0d 0e 11 10                      movepw (a6)(4368),d6
loc_1b464 11 00                            move.b  d0,(a0)-
loc_1b466 00 09                            .short loc_9
loc_1b468 08 09                            .short 0x0809
loc_1b46a 10 15                            move.b  (a5),d0
loc_1b46c 10 14                            move.b  (a4),d0
loc_1b46e 08 0f                            .short 0x080f
loc_1b470 0c 0f                            .short 0x0c0f
loc_1b472 14 04                            move.b  d4,d2
loc_1b474 0b 02                            btst d5,d2
loc_1b476 09 16                            btst d4,(a6)
loc_1b478 0f 08 0f 10                      movepw (a0)(3856),d7
loc_1b47c 04 15 16 1f                      subi.b #$1F,(a5)
loc_1b480 14 1f                            move.b  (sp)+,d2
loc_1b482 0c 1f 02 00                      cmpi.b  #0,(sp)+
loc_1b486 63 d1                            bls.s   loc_1b459
loc_1b488 97 7f                            .short 0x977f
loc_1b48a 12 94                            move.b  (a4),(a1)
loc_1b48c 7f 09                            .short 0x7f09
loc_1b48e 91 7f                            .short 0x917f
loc_1b490 2c 99                            move.l  (a1)+,(a6)
loc_1b492 7f 00                            .short 0x7f00
loc_1b494 0f 02                            btst d7,d2
loc_1b496 15 08                            .short 0x1508
loc_1b498 0d 18                            btst d6,(a0)+
loc_1b49a 1a 0c                            .short 0x1a0c
loc_1b49c 05 09 0b 0b                      movepw (a1)(2827),d2
loc_1b4a0 11 0d                            .short 0x110d
loc_1b4a2 11 12                            move.b  (a2),(a0)-
loc_1b4a4 11 14                            move.b  (a4),(a0)-
loc_1b4a6 11 00                            move.b  d0,(a0)-
loc_1b4a8 00 0c                            .short loc_c
loc_1b4aa 09 0c 0e 0c                      movepw (a4)(3596),d4
loc_1b4ae 14 17                            move.b  (sp),d2
loc_1b4b0 14 17                            move.b  (sp),d2
loc_1b4b2 0e 17                            .short 0x0e17
loc_1b4b4 09 04                            btst d4,d4
loc_1b4b6 11 0c                            .short 0x110c
loc_1b4b8 07 09 05 0f                      movepw (a1)(1295),d3
loc_1b4bc 1f 14                            move.b  (a4),-(sp)
loc_1b4be 04 11 11 13                      subi.b #$13,(a1)
loc_1b4c2 17 1c                            move.b  (a4)+,(a3)-
loc_1b4c4 0f 1d                            btst d7,(a5)+
loc_1b4c6 04 00 46 c6                      subi.b #-58,d0
loc_1b4ca 85 0a                            sbcd (a2)-,(a2)-
loc_1b4cc c6 85                            and.l   d5,d3
loc_1b4ce 7f 05                            .short 0x7f05
loc_1b4d0 c7 85                            .short 0xc785
loc_1b4d2 0a c7                            .short 0x0ac7
loc_1b4d4 85 7f                            .short 0x857f
loc_1b4d6 35 c6                            .short 0x35c6
loc_1b4d8 85 0a                            sbcd (a2)-,(a2)-
loc_1b4da c6 85                            and.l   d5,d3
loc_1b4dc 7f 05                            .short 0x7f05
loc_1b4de c6 85                            and.l   d5,d3
loc_1b4e0 0a c6                            .short 0x0ac6
loc_1b4e2 85 7f                            .short 0x857f
loc_1b4e4 00 0f                            .short loc_f
loc_1b4e6 17 08                            .short 0x1708
loc_1b4e8 02 18 02 1e                      andi.b  #$1E,(a0)+
loc_1b4ec 16 0a                            .short 0x160a
loc_1b4ee 15 10                            move.b  (a0),(a2)-
loc_1b4f0 17 10                            move.b  (a0),(a3)-
loc_1b4f2 1c 0b                            .short 0x1c0b
loc_1b4f4 1e 0b                            .short 0x1e0b
loc_1b4f6 05 10                            btst d2,(a0)
loc_1b4f8 07 10                            btst d3,(a0)
loc_1b4fa 0b 0b 0d 0b                      movepw (a3)(3339),d5
loc_1b4fe 11 05                            move.b  d5,(a0)-
loc_1b500 13 05                            move.b  d5,(a1)-
loc_1b502 00 00 04 08                      ori.b #8,d0
loc_1b506 0e 0e                            .short 0x0e0e
loc_1b508 05 19                            btst d2,(a1)+
loc_1b50a 15 19                            move.b  (a1)+,(a2)-
loc_1b50c 14 08                            .short 0x1408
loc_1b50e 1e 0e                            .short 0x1e0e
loc_1b510 04 01 03 05                      subi.b #5,d1
loc_1b514 0d 0b 08 06                      movepw (a3)(2054),d6
loc_1b518 16 04                            move.b  d4,d3
loc_1b51a 0e 13                            .short 0x0e13
loc_1b51c 15 0e                            .short 0x150e
loc_1b51e 12 02                            move.b  d2,d1
loc_1b520 18 16                            move.b  (a6),d4
loc_1b522 1f d8                            .short 0x1fd8
loc_1b524 43 cc                            .short 0x43cc
loc_1b526 88 07                            or.b d7,d4
loc_1b528 89 1f                            or.b d4,(sp)+
loc_1b52a cb 68 89 05                      and.w d5,(a0)(-30459)
loc_1b52e 89 7f                            .short 0x897f
loc_1b530 2a 89                            move.l  a1,(a5)
loc_1b532 05 89 7f 0e                      movepw d2,(a1)(32526)
loc_1b536 8f 7f                            .short 0x8f7f
loc_1b538 00 0f                            .short loc_f
loc_1b53a 17 07                            move.b  d7,(a3)-
loc_1b53c 03 0f 13 01                      movepw (sp)(4865),d1
loc_1b540 12 04                            move.b  d4,d1
loc_1b542 04 15 0a 0c                      subi.b #$C,(a5)
loc_1b546 13 0c                            .short 0x130c
loc_1b548 19 15                            move.b  (a5),(a4)-
loc_1b54a 01 14                            btst d0,(a4)
loc_1b54c 07 00                            btst d3,d0
loc_1b54e 09 09 09 0f                      movepw (a1)(2319),d4
loc_1b552 09 14                            btst d4,(a4)
loc_1b554 13 14                            move.b  (a4),(a1)-
loc_1b556 13 0f                            .short 0x130f
loc_1b558 13 09                            .short 0x1309
loc_1b55a 04 0f                            .short 0x040f
loc_1b55c 03 00                            btst d1,d0
loc_1b55e 08 03 12 05                      btst    #5,d3
loc_1b562 0c 04 0f 0d                      cmpi.b  #$D,d4
loc_1b566 18 0c                            .short 0x180c
loc_1b568 1a 14                            move.b  (a4),d5
loc_1b56a 1d 09                            .short 0x1d09
loc_1b56c 60 8e                            bra.s   loc_1b4fc
loc_1b56e 04 8e                            .short 0x048e
loc_1b570 7f 4f                            .short 0x7f4f
loc_1b572 84 7f                            .short 0x847f
loc_1b574 4f 8e                            .short 0x4f8e
loc_1b576 04 8e                            .short 0x048e
loc_1b578 7f 00                            .short 0x7f00
loc_1b57a 0f 09 1a 03                      movepw (a1)(6659),d7
loc_1b57e 04 11 01 0b                      subi.b #11,(a1)
loc_1b582 04 0b                            .short 0x040b
loc_1b584 0f 09 0f 13                      movepw (a1)(3859),d7
loc_1b588 0f 15                            btst d7,(a5)
loc_1b58a 0f 01                            btst d7,d1
loc_1b58c 04 16 00 02                      subi.b #2,(a6)
loc_1b590 19 02                            move.b  d2,(a4)-
loc_1b592 12 02                            move.b  d2,d1
loc_1b594 04 1d 04 1d                      subi.b #29,(a5)+
loc_1b598 12 1d                            move.b  (a5)+,d1
loc_1b59a 19 04                            move.b  d4,(a4)-
loc_1b59c 06 02 02 0e                      addi.b #$E,d2
loc_1b5a0 09 09 06 15                      movepw (a1)(1557),d4
loc_1b5a4 04 18 02 14                      subi.b #$14,(a0)+
loc_1b5a8 09 1c                            btst d4,(a4)+
loc_1b5aa 0f 18                            btst d7,(a0)+
loc_1b5ac 15 00                            move.b  d0,(a2)-
loc_1b5ae 4a 85                            tst.l   d5
loc_1b5b0 03 d3                            bset d1,(a3)
loc_1b5b2 84 17                            or.b (sp),d2
loc_1b5b4 d2 33 cd 84                      add.b @0)@0,a4:l:4),d1
loc_1b5b8 13 85 1f cc                      move.b  d5,@0)@0)
loc_1b5bc 2b 84 05 84                      move.l  d4,@0)@0,d0.w:4)
loc_1b5c0 4c 84                            .short 0x4c84
loc_1b5c2 13 84 4c 84                      move.b  d4,(a1)(ffffffffffffff84,d4:l:4)
loc_1b5c6 05 84                            bclr d2,d4
loc_1b5c8 4c 84                            .short 0x4c84
loc_1b5ca 13 84 4c 84                      move.b  d4,(a1)(ffffffffffffff84,d4:l:4)
loc_1b5ce 05 84                            bclr d2,d4
loc_1b5d0 00 0f                            .short loc_f
loc_1b5d2 17 1b                            move.b  (a3)+,(a3)-
loc_1b5d4 05 03                            btst d2,d3
loc_1b5d6 18 10                            move.b  (a0),d4
loc_1b5d8 0d 04                            btst d6,d4
loc_1b5da 04 09                            .short 0x0409
loc_1b5dc 04 0f                            .short 0x040f
loc_1b5de 1b 0f                            .short 0x1b0f
loc_1b5e0 1b 09                            .short 0x1b09
loc_1b5e2 00 00 0b 03                      ori.b #3,d0
loc_1b5e6 0b 09 0b 0f                      movepw (a1)(2831),d5
loc_1b5ea 12 0f                            .short 0x120f
loc_1b5ec 12 09                            .short 0x1209
loc_1b5ee 12 03                            move.b  d3,d1
loc_1b5f0 04 0b                            .short 0x040b
loc_1b5f2 06 0b                            .short 0x060b
loc_1b5f4 12 08                            .short 0x1208
loc_1b5f6 0c 1f 0c 04                      cmpi.b  #4,(sp)+
loc_1b5fa 15 06                            move.b  d6,(a2)-
loc_1b5fc 14 12                            move.b  (a2),d2
loc_1b5fe 17 0c                            .short 0x170c
loc_1b600 10 0a                            .short 0x100a
loc_1b602 60 cf                            bra.s   loc_1b5d3
loc_1b604 8e 03                            or.b d3,d7
loc_1b606 8e 67                            or.w -(sp),d7
loc_1b608 c4 83                            and.l   d3,d2
loc_1b60a 0b c4                            bset d5,d4
loc_1b60c 83 10                            or.b d1,(a0)
loc_1b60e c3 0e                            abcd (a6)-,(a1)-
loc_1b610 c3 27                            and.b d1,-(sp)
loc_1b612 86 01                            or.b d1,d3
loc_1b614 82 01                            or.b d1,d1
loc_1b616 84 03                            or.b d3,d2
loc_1b618 84 01                            or.b d1,d2
loc_1b61a 82 01                            or.b d1,d1
loc_1b61c 86 67                            or.w -(sp),d3
loc_1b61e c4 83                            and.l   d3,d2
loc_1b620 0b c4                            bset d5,d4
loc_1b622 83 10                            or.b d1,(a0)
loc_1b624 c3 0e                            abcd (a6)-,(a1)-
loc_1b626 c3 27                            and.b d1,-(sp)
loc_1b628 86 01                            or.b d1,d3
loc_1b62a 82 01                            or.b d1,d1
loc_1b62c 84 03                            or.b d3,d2
loc_1b62e 84 01                            or.b d1,d2
loc_1b630 82 01                            or.b d1,d1
loc_1b632 86 60                            or.w (a0)-,d3
loc_1b634 87 13                            or.b d3,(a3)
loc_1b636 c3 85                            .short 0xc385
loc_1b638 06 c2                            .short 0x06c2
loc_1b63a 00 0f                            .short loc_f
loc_1b63c 17 1c                            move.b  (a4)+,(a3)-
loc_1b63e 03 08 18 02                      movepw (a0)(6146),d1
loc_1b642 08 04 0c 08                      btst    #8,d4
loc_1b646 0c 0f                            .short 0x0c0f
loc_1b648 13 0f                            .short 0x130f
loc_1b64a 13 08                            .short 0x1308
loc_1b64c 00 00 0c 04                      ori.b #4,d0
loc_1b650 0c 0b                            .short 0x0c0b
loc_1b652 0c 12 13 12                      cmpi.b  #18,(a2)
loc_1b656 13 0b                            .short 0x130b
loc_1b658 13 04                            move.b  d4,(a1)-
loc_1b65a 04 10 07 03                      subi.b #3,(a0)
loc_1b65e 08 03 0f 09                      btst    #9,d3
loc_1b662 15 04                            move.b  d4,(a2)-
loc_1b664 10 0f                            .short 0x100f
loc_1b666 15 15                            move.b  (a5),(a2)-
loc_1b668 1d 0f                            .short 0x1d0f
loc_1b66a 1d 07                            move.b  d7,(a6)-
loc_1b66c 4c 89                            .short 0x4c89
loc_1b66e 1f c4                            .short 0x1fc4
loc_1b670 51 cc 89 05                      dbf     d4,loc_13f77
loc_1b674 85 1f                            or.b d2,(sp)+
loc_1b676 cb 49                            exg a5,a1
loc_1b678 83 0a                            sbcd (a2)-,(a1)-
loc_1b67a 84 06                            or.b d6,d2
loc_1b67c 85 7f                            .short 0x857f
loc_1b67e 43 85                            chkw d5,d1
loc_1b680 01 85                            bclr d0,d5
loc_1b682 08 c4 84 01                      bset    #1,d4
loc_1b686 83 0e                            sbcd (a6)-,(a1)-
loc_1b688 c3 40                            exg d1,d0
loc_1b68a 88 00                            or.b d0,d4
loc_1b68c 0f 13                            btst d7,(a3)
loc_1b68e 10 02                            move.b  d2,d0
loc_1b690 1e 18                            move.b  (a0)+,d7
loc_1b692 0f 17                            btst d7,(sp)
loc_1b694 04 08                            .short 0x0408
loc_1b696 0f 0a 0f 14                      movepw (a2)(3860),d7
loc_1b69a 0f 16                            btst d7,(a6)
loc_1b69c 0f 01                            btst d7,d1
loc_1b69e 00 16 00 07                      ori.b #7,(a6)
loc_1b6a2 07 04                            btst d3,d4
loc_1b6a4 12 08                            .short 0x1208
loc_1b6a6 12 12                            move.b  (a2),d1
loc_1b6a8 03 1b                            btst d1,(a3)+
loc_1b6aa 0b 16                            btst d5,(a6)
loc_1b6ac 12 04                            move.b  d4,d1
loc_1b6ae 09 03                            btst d4,d3
loc_1b6b0 00 07 00 0f                      ori.b #$F,d7
loc_1b6b4 06 16 04 0b                      addi.b #11,(a6)
loc_1b6b8 0d 16                            btst d6,(a6)
loc_1b6ba 0d 19                            btst d6,(a1)+
loc_1b6bc 16 1b                            move.b  (a3)+,d3
loc_1b6be 03 00                            btst d1,d0
loc_1b6c0 7f 7f                            .short 0x7f7f
loc_1b6c2 70 84                            moveq   #-124,d0
loc_1b6c4 7f 4f                            .short 0x7f4f
loc_1b6c6 82 06                            or.b d6,d1
loc_1b6c8 84 08                            .short 0x8408
loc_1b6ca 84 06                            or.b d6,d2
loc_1b6cc 82 7f                            .short 0x827f
loc_1b6ce 00 0f                            .short loc_f
loc_1b6d0 0a 09                            .short 0x0a09
loc_1b6d2 18 15                            move.b  (a5),d4
loc_1b6d4 12 0f                            .short 0x120f
loc_1b6d6 10 04                            move.b  d4,d0
loc_1b6d8 03 0a 05 0a                      movepw (a2)(1290),d1
loc_1b6dc 19 0a                            .short 0x190a
loc_1b6de 1b 0a                            .short 0x1b0a
loc_1b6e0 00 00 09 13                      ori.b #$13,d0
loc_1b6e4 15 13                            move.b  (a3),(a2)-
loc_1b6e6 1f 13                            move.b  (a3),-(sp)
loc_1b6e8 04 19 0f 19                      subi.b #25,(a1)+
loc_1b6ec 1a 19                            move.b  (a1)+,d5
loc_1b6ee 04 03 10 07                      subi.b #7,d3
loc_1b6f2 09 0b 07 1f                      movepw (a3)(1823),d4
loc_1b6f6 09 04                            btst d4,d4
loc_1b6f8 14 07                            move.b  d7,d2
loc_1b6fa 0f 13                            btst d7,(a3)
loc_1b6fc 18 09                            .short 0x1809
loc_1b6fe 1a 10                            move.b  (a0),d5
loc_1b700 40 89                            .short 0x4089
loc_1b702 05 92                            bclr d2,(a2)
loc_1b704 12 d2                            move.b  (a2),(a1)+
loc_1b706 4d 8e                            .short 0x4d8e
loc_1b708 08 8a                            .short 0x088a
loc_1b70a 0d c4                            bset d6,d4
loc_1b70c 72 8a                            moveq   #-118,d1
loc_1b70e 09 8d 60 8e                      movepw d4,(a5)(24718)
loc_1b712 09 89 0d c8                      movepw d4,(a1)(3528)
loc_1b716 72 89                            moveq   #-119,d1
loc_1b718 0a 8d                            .short 0x0a8d
loc_1b71a 00 0f                            .short loc_f
loc_1b71c 17 0b                            .short 0x170b
loc_1b71e 06 0b                            .short 0x060b
loc_1b720 0f 0f 0e 04                      movepw (sp)(3588),d7
loc_1b724 17 09                            .short 0x1709
loc_1b726 19 09                            .short 0x1909
loc_1b728 17 12                            move.b  (a2),(a3)-
loc_1b72a 19 12                            move.b  (a2),(a4)-
loc_1b72c 01 03                            btst d0,d3
loc_1b72e 13 00                            move.b  d0,(a1)-
loc_1b730 1a 19                            move.b  (a1)+,d5
loc_1b732 1a 15                            move.b  (a5),d5
loc_1b734 1a 10                            move.b  (a0),d5
loc_1b736 1a 0c                            .short 0x1a0c
loc_1b738 1a 07                            move.b  d7,d5
loc_1b73a 1a 03                            move.b  d3,d5
loc_1b73c 04 06 02 0a                      subi.b #$A,d6
loc_1b740 0a 0f                            .short 0x0a0f
loc_1b742 0a 14 0a 04                      eori.b #4,(a4)
loc_1b746 0e 02                            .short 0x0e02
loc_1b748 0a 14 0f 13                      eori.b #$13,(a4)
loc_1b74c 14 13                            move.b  (a3),d2
loc_1b74e 40 83                            negxl d3
loc_1b750 03 85                            bclr d1,d5
loc_1b752 03 85                            bclr d1,d5
loc_1b754 03 85                            bclr d1,d5
loc_1b756 03 82                            bclr d1,d2
loc_1b758 62 85                            bhi.s   loc_1b6df
loc_1b75a 03 85                            bclr d1,d5
loc_1b75c 03 85                            bclr d1,d5
loc_1b75e 03 85                            bclr d1,d5
loc_1b760 61 83                            bsr.s   loc_1b6e5
loc_1b762 03 85                            bclr d1,d5
loc_1b764 03 85                            bclr d1,d5
loc_1b766 03 85                            bclr d1,d5
loc_1b768 03 82                            bclr d1,d2
loc_1b76a 62 85                            bhi.s   loc_1b6f1
loc_1b76c 03 85                            bclr d1,d5
loc_1b76e 03 85                            bclr d1,d5
loc_1b770 03 85                            bclr d1,d5
loc_1b772 61 83                            bsr.s   loc_1b6f7
loc_1b774 03 85                            bclr d1,d5
loc_1b776 03 85                            bclr d1,d5
loc_1b778 03 85                            bclr d1,d5
loc_1b77a 03 82                            bclr d1,d2
loc_1b77c 7f 00                            .short 0x7f00
loc_1b77e 0f 17                            btst d7,(sp)
loc_1b780 07 0a 17 0a                      movepw (a2)(5898),d3
loc_1b784 0f 09 04 03                      movepw (a1)(1027),d7
loc_1b788 16 05                            move.b  d5,d3
loc_1b78a 16 19                            move.b  (a1)+,d3
loc_1b78c 16 1b                            move.b  (a3)+,d3
loc_1b78e 16 02                            move.b  d2,d3
loc_1b790 08 17 12 17                      btst    #23,(sp)
loc_1b794 00 0b                            .short loc_b
loc_1b796 07 14                            btst d3,(a4)
loc_1b798 07 17                            btst d3,(sp)
loc_1b79a 0b 07                            btst d5,d7
loc_1b79c 0b 0f 0b 0f                      movepw (sp)(2831),d5
loc_1b7a0 13 04                            move.b  d4,(a1)-
loc_1b7a2 07 02                            btst d3,d2
loc_1b7a4 07 0d 07 16                      movepw (a5)(1814),d3
loc_1b7a8 0c 0b                            .short 0x0c0b
loc_1b7aa 04 14 0b 17                      subi.b #23,(a4)
loc_1b7ae 02 18 0e 17                      andi.b  #23,(a0)+
loc_1b7b2 17 00                            move.b  d0,(a3)-
loc_1b7b4 63 84                            bls.s   loc_1b73a
loc_1b7b6 04 84 04 84 04 84                subi.l #75760772,d4
loc_1b7bc 07 c7                            bset d3,d7
loc_1b7be 07 c7                            bset d3,d7
loc_1b7c0 07 c7                            bset d3,d7
loc_1b7c2 07 c7                            bset d3,d7
loc_1b7c4 7f 22                            .short 0x7f22
loc_1b7c6 82 05                            or.b d5,d1
loc_1b7c8 83 05                            sbcd d5,d1
loc_1b7ca 83 05                            sbcd d5,d1
loc_1b7cc 83 05                            sbcd d5,d1
loc_1b7ce 81 01                            sbcd d1,d0
loc_1b7d0 c7 07                            abcd d7,d3
loc_1b7d2 c7 07                            abcd d7,d3
loc_1b7d4 c7 07                            abcd d7,d3
loc_1b7d6 c7 7f                            .short 0xc77f
loc_1b7d8 29 83 05 83 05 83 05 83          move.l  d3,@0,d0.w:4)@(0000000005830583)
loc_1b7e0 07 c6                            bset d3,d6
loc_1b7e2 07 c6                            bset d3,d6
loc_1b7e4 07 c6                            bset d3,d6
loc_1b7e6 07 c6                            bset d3,d6
loc_1b7e8 7f 00                            .short 0x7f00
loc_1b7ea 0f 17                            btst d7,(sp)
loc_1b7ec 0c 03 1c 03                      cmpi.b  #3,d3
loc_1b7f0 0b 0a 04 00                      movepw (a2)(1024),d5
loc_1b7f4 08 02 08 10                      btst    #$10,d2
loc_1b7f8 08 12 08 00                      btst    #0,(a2)
loc_1b7fc 00 04 04 0c                      ori.b #$C,d4
loc_1b800 04 14 04 1c                      subi.b #$1C,(a4)
loc_1b804 04 18 19 07                      subi.b #7,(a0)+
loc_1b808 19 04                            move.b  d4,(a4)-
loc_1b80a 01 15                            btst d0,(a5)
loc_1b80c 06 0f                            .short 0x060f
loc_1b80e 0b 08 09 16                      movepw (a0)(2326),d5
loc_1b812 04 0e                            .short 0x040e
loc_1b814 0e 16                            .short 0x0e16
loc_1b816 0e 1e                            .short 0x0e1e
loc_1b818 0e 19                            .short 0x0e19
loc_1b81a 15 00                            move.b  d0,(a2)-
loc_1b81c 6e 84                            bgt.s   loc_1b7a2
loc_1b81e 7f 65                            .short 0x7f65
loc_1b820 86 7f                            .short 0x867f
loc_1b822 45 88                            .short 0x4588
loc_1b824 7f 00                            .short 0x7f00
loc_1b826 0f 02                            btst d7,d2
loc_1b828 03 11                            btst d1,(a1)
loc_1b82a 13 18                            move.b  (a0)+,(a1)-
loc_1b82c 00 06 00 07                      ori.b #7,d6
loc_1b830 04 0e                            .short 0x040e
loc_1b832 07 0b 09 08                      movepw (a3)(2312),d3
loc_1b836 16 04                            move.b  d4,d3
loc_1b838 19 0e                            .short 0x190e
loc_1b83a 19 17                            move.b  (sp),(a4)-
loc_1b83c 0b 13                            btst d5,(a3)
loc_1b83e 00 0d                            .short loc_d
loc_1b840 04 0d                            .short 0x040d
loc_1b842 04 0d                            .short 0x040d
loc_1b844 04 0d                            .short 0x040d
loc_1b846 04 0d                            .short 0x040d
loc_1b848 04 0d                            .short 0x040d
loc_1b84a 04 04 06 0f                      subi.b #$F,d4
loc_1b84e 06 06 0f 07                      addi.b #7,d6
loc_1b852 0f 0d 04 0f                      movepw (a5)(1039),d7
loc_1b856 14 1b                            move.b  (a3)+,d2
loc_1b858 0f 17                            btst d7,(sp)
loc_1b85a 06 1e 06 00                      addi.b #0,(a6)+
loc_1b85e 60 82                            bra.s   loc_1b7e2
loc_1b860 0d c4                            bset d6,d4
loc_1b862 82 0d                            .short 0x820d
loc_1b864 c4 01                            and.b d1,d2
loc_1b866 c3 0f                            abcd -(sp),(a1)-
loc_1b868 c3 2e 81 0f                      and.b d1,(a6)(-32497)
loc_1b86c 81 56                            or.w d0,(a6)
loc_1b86e c4 82                            and.l   d2,d2
loc_1b870 0d c4                            bset d6,d4
loc_1b872 82 0f                            .short 0x820f
loc_1b874 c3 0f                            abcd -(sp),(a1)-
loc_1b876 c3 2e 81 0f                      and.b d1,(a6)(-32497)
loc_1b87a 81 35 85 0d                      or.b d0,(a5)@0,a0.w:4)
loc_1b87e 82 1d                            or.b (a5)+,d1
loc_1b880 c4 01                            and.b d1,d2
loc_1b882 c3 3e                            .short 0xc33e
loc_1b884 81 49                            .short 0x8149
loc_1b886 c4 82                            and.l   d2,d2
loc_1b888 07 c4                            bset d3,d4
loc_1b88a 82 15                            or.b (a5),d1
loc_1b88c c3 09                            abcd (a1)-,(a1)-
loc_1b88e c3 34 81 09                      and.b d1,(a4,a0.w)@0)
loc_1b892 81 00                            sbcd d0,d0
loc_1b894 0f 0d 08 09                      movepw (a5)(2057),d7
loc_1b898 1b 18                            move.b  (a0)+,(a5)-
loc_1b89a 1b 04                            move.b  d4,(a5)-
loc_1b89c 00 05 02 0b                      ori.b #11,d5
loc_1b8a0 04 16 0a 06                      subi.b #6,(a6)
loc_1b8a4 13 03                            move.b  d3,(a1)-
loc_1b8a6 19 07                            move.b  d7,(a4)-
loc_1b8a8 00 07 0a 1f                      ori.b #$1F,d7
loc_1b8ac 04 1f 10 0e                      subi.b #$E,(sp)+
loc_1b8b0 0f 11                            btst d7,(a1)
loc_1b8b2 0f 17                            btst d7,(sp)
loc_1b8b4 0a 04 07 05                      eori.b #5,d4
loc_1b8b8 0a 14 1f 0c                      eori.b #$C,(a4)
loc_1b8bc 1f 17                            move.b  (sp),-(sp)
loc_1b8be 04 15 14 10                      subi.b #$10,(a5)
loc_1b8c2 16 0f                            .short 0x160f
loc_1b8c4 02 18 06 00                      andi.b  #0,(a0)+
loc_1b8c8 68 c8                            bvcs loc_1b892
loc_1b8ca 8f 1f                            or.b d7,(sp)+
loc_1b8cc c7 77 c6 c6                      and.w d3,(sp)(ffffffffffffffc6,a4.w:8)
loc_1b8d0 34 c8                            move.w  a0,(a2)+
loc_1b8d2 82 10                            or.b (a0),d1
loc_1b8d4 83 1f                            or.b d1,(sp)+
loc_1b8d6 c7 31 c8 82                      and.b d3,(a1)(ffffffffffffff82,a4:l)
loc_1b8da 02 83 1f c7 4e c4                andi.l #533155524,d3
loc_1b8e0 82 16                            or.b (a6),d1
loc_1b8e2 83 1f                            or.b d1,(sp)+
loc_1b8e4 c6 2b c4 82                      and.b (a3)(-15230),d3
loc_1b8e8 04 83 01 83 00 0f                subi.l #25362447,d3
loc_1b8ee 02 05 0a 19                      andi.b  #25,d5
loc_1b8f2 18 0f                            .short 0x180f
loc_1b8f4 07 00                            btst d3,d0
loc_1b8f6 03 02                            btst d1,d2
loc_1b8f8 07 19                            btst d3,(a1)+
loc_1b8fa 03 1a                            btst d1,(a2)+
loc_1b8fc 06 00 0f 09                      addi.b #9,d0
loc_1b900 0d 0e 11 0e                      movepw (a6)(4366),d6
loc_1b904 11 15                            move.b  (a5),(a0)-
loc_1b906 14 15                            move.b  (a5),d2
loc_1b908 0a 19 04 04                      eori.b #4,(a1)+
loc_1b90c 03 0c 07 0f                      movepw (a4)(1807),d1
loc_1b910 12 08                            .short 0x1208
loc_1b912 11 04                            move.b  d4,(a0)-
loc_1b914 13 07                            move.b  d7,(a1)-
loc_1b916 17 11                            move.b  (a1),(a3)-
loc_1b918 1b 03                            move.b  d3,(a5)-
loc_1b91a 1f 0b                            .short 0x1f0b
loc_1b91c 05 c4                            bset d2,d4
loc_1b91e 05 c4                            bset d2,d4
loc_1b920 09 c4                            bset d4,d4
loc_1b922 05 c4                            bset d2,d4
loc_1b924 47 c4                            .short 0x47c4
loc_1b926 81 07                            sbcd d7,d0
loc_1b928 82 05                            or.b d5,d1
loc_1b92a c4 81                            and.l   d1,d2
loc_1b92c 07 82                            bclr d3,d2
loc_1b92e 0f c3                            bset d7,d3
loc_1b930 0f c3                            bset d7,d3
loc_1b932 26 89                            move.l  a1,(a3)
loc_1b934 07 89 63 85                      movepw d3,(a1)(25477)
loc_1b938 05 c4                            bset d2,d4
loc_1b93a 8c 05                            or.b d5,d6
loc_1b93c c4 83                            and.l   d3,d2
loc_1b93e 04 c3                            .short 0x04c3
loc_1b940 11 c3 29 84                      move.b  d3,loc_2984
loc_1b944 07 8b 07 83                      movepw d3,(a3)(1923)
loc_1b948 60 8a                            bra.s   loc_1b8d4
loc_1b94a 05 c3                            bset d2,d3
loc_1b94c 82 05                            or.b d5,d1
loc_1b94e c7 88                            exg d3,a0
loc_1b950 09 c6                            bset d4,d6
loc_1b952 07 c2                            bset d3,d2
loc_1b954 0f c5                            bset d7,d5
loc_1b956 82 01                            or.b d1,d1
loc_1b958 c5 82                            .short 0xc582
loc_1b95a 08 81 08 c3                      bclr    #-61,d1
loc_1b95e 82 01                            or.b d1,d1
loc_1b960 c5 82                            .short 0xc582
loc_1b962 07 c4                            bset d3,d4
loc_1b964 1b c3                            .short 0x1bc3
loc_1b966 02 81 13 82 02 82                andi.l #327287426,d1
loc_1b96c 1b c2                            .short 0x1bc2
loc_1b96e 06 81 16 82 03 82                addi.l  #377619330,d1
loc_1b974 00 0f                            .short loc_f
loc_1b976 17 10                            move.b  (a0),(a3)-
loc_1b978 0a 00 11 10                      eori.b #$10,d0
loc_1b97c 04 00 00 00                      subi.b #0,d0
loc_1b980 0b 0b 14 0b                      movepw (a3)(5131),d5
loc_1b984 1e 0b                            .short 0x1e0b
loc_1b986 1d 12                            move.b  (a2),(a6)-
loc_1b988 02 12 00 0b                      andi.b  #11,(a2)
loc_1b98c 04 03 03 0c                      subi.b #$C,d3
loc_1b990 03 07                            btst d1,d7
loc_1b992 0b 0e 11 04                      movepw (a6)(4356),d5
loc_1b996 11 11                            move.b  (a1),(a0)-
loc_1b998 18 0b                            .short 0x180b
loc_1b99a 13 03                            move.b  d3,(a1)-
loc_1b99c 1c 03                            move.b  d3,d6
loc_1b99e 00 00

Padding2:
                alignFF $20000                   ; Pad to 128KB.

EndofROM


                END








