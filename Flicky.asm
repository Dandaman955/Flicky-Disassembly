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
                ; TODO IMPORTANT WHERE THE FUCK IS SRAM?
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

RandomNumber:                                    ; $F4A
                move.l  ($FFFFFFCA).w,d1         ; Move the current random number into d1.
                bne.s   loc_f56                  ; If it already has a number, branch.
                move.l  #$2A6D365A,d1            ; Generate a random seed.
loc_f56:
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
                move.w  #$101,($FFFFD82C).w).w      ; Set the BCD and hex level round value to 0101.
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
                move.b  ($FFFFD82E).w,d7         ; Load the door's X coordinate position.
                move.b  ($FFFFD82F).w,d6         ; Load the door's Y coordinate position.
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
                lea     ($FFFFD82C).w).w,a6
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
                move.w  #$101,($FFFFD82C).w).w      ; Set the BCD and hex level round to 0101.
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
                dc.l    loc_154AE
                dc.l    loc_162BC


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
                bsr.w   loc_10fc0                ; Dump onto the screen.
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
                dc.w    $0100

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
                move.b  ($FFFFD82C).w).w,d1         ; Load the BCD level number value to d1.
                move.b  #1,d2                    ; Set addition value to 1.
                move.b  ($FFFFFF8F).w,d0         ; Load the buttons pressed into d0.
                btst    #0,d0                    ; Is up being pressed?
                beq.s   loc_1261a                ; If it isn't, branch.
                cmpi.b  #36,d1                   ; Has the round hit 36?
                beq.s   loc_12642                ; If it has, don't add anymore.
                addi.b  #0,d0                    ; Clear the extend CCR bit.
                abcd    d2,d1                    ; Add by 1 (decimal).
                addq.b  #1,($FFFFD82D).w         ; Add to the hex round value.
                move.b  d1,($FFFFD82C).w).w         ; Copy the decimal add to the BCD address.
                bra.s   loc_12642                ; Skip the down button check.

loc_1261a:
                btst    #1,d0                    ; Is down being pressed?
                beq.s   loc_12636                ; If it isn't, branch.
                cmpi.b  #1,d1                    ; Has the round hit 1?
                beq.s   loc_12642                ; If it is, branch.
                addi.b  #0,d0                    ; Clear the extend CCR bit.
                sbcd    d2,d1                    ; Subtract by 1.
                addq.b  #1,($FFFFD82D).w         ; Subtract from the hex round value.
                move.b  d1,($FFFFD82C).w).w         ; Copy the decimal subtract from the BCD address.
                bra.s   loc_12642                ; Skip the start button check.

loc_12636:
                btst    #7,d0                    ; Is start being pressed?
                beq.s   loc_12642                ; If it isn't, branch.
                move.w  #$18,($FFFFFFC0).w       ; Load the level game mode.
loc_12642:
                lea     ($FFFFD82C).w).w,a6         ; Load the level number address to a6.
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

WallpaperTileTable2:                             ; $127D0
                dc.l    WallpaperScenery1
                dc.l    WallpaperScenery1
                dc.l    WallpaperScenery2
                dc.l    WallpaperScenery3
                dc.l    WallpaperScenery4
                dc.l    WallpaperScenery5

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

loc_129be:
                dc.w    $0000, $0EAE, $0E6E, $0E48
                dc.w    $0C06, $004A, $008A, $004E
                dc.w    $0000, $0044, $0000, $00AA
                dc.w    $06CC, $00CC, $0066, $00A8

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
                jsr     loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
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
                beq.s   loc_12b5e                ; If it isn't, branch.
                bsr.w   PauseGame                ; Pause the game.
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
                move.b  ($FFFFD82C).w).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,($FFFFD82C).w
                move.w  #$18,($FFFFFFC0).w
                cmpi.b  #$49,d0
                bne.s   loc_12d82
                move.w  #$30,($FFFFFFC0).w
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
                move.w  ($FFFFD2A6).w).w,d0
                andi.w  #$7FFC,d0
                jsr     loc_13000(pc,d0.w)
                btst    #7,($FFFFFF8F).w
                beq.s   loc_12ff4
                bsr.w   PauseGame                ; Pause the game
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

loc_130ee:
                addq.b  #1,($FFFFD82D).w
                bne.s   loc_130f8
                addq.b  #1,($FFFFD82D).w
loc_130f8:
                move.b  ($FFFFD82C).w).w,d0
                moveq   #1,d1
                addi.b  #0,d0
                abcd    d1,d0
                move.b  d0,($FFFFD82C).w
                move.w  #$18,($FFFFFFC0).w
                rts

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
                move.w  #loc_135E8_End-loc_135E8,d0 ; Data length.
                move.w  #$125B,d1                ; Relative address in Z80 RAM.
                lea     loc_135e8,a0             ; Data location.
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
                cmpi.w  #78,$24(a0)
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

loc_135e8:
                include "loc_135E8.bin"
loc_135E8_End:

; ======================================================================

loc_139a2:
                bsr.w   loc_100d4                ; Clear some variables, load some compressed art, set to load next game mode.
                lea     Pal_Main,a5              ; Load the main palette's address into a5.
                jsr     ($FFFFFBBA).w            ; Decode it and write it into the palette buffer.
                move.w  ($FFFFD890).w,d0
                andi.w  #3,d0
                move.b  loc_13a08(pc,d0.w),($FFFFD82D).w
                move.b  loc_13a0c(pc,d0.w),($FFFFD82C).w).w
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
                move.b  #$90,d0
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
                cmpi.l  #$FFFE2000,d0
                bge.s   loc_14168
                move.l  #$FFFE2000,d0
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
                bne.s   loc_141bc
                btst    #0,d4
                beq.s   loc_14212
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
                move.l  (a1),(a2)
                move.l  (a3),(a4)
loc_14284:
                subq.l  #8,a1
                subq.l  #8,a2
                subq.l  #8,a3
                subq.l  #8,a4
                dbf     d0,loc_14284
                lea     ($FFFFD24E).w,a2
                lea     ($FFFFD24D).w,a1
                moveq   #$3F,d0
loc_1429e:
                move.b  (a1)-,(a2)-
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
                bpl.s   loc_1437a
                bset    #7,2(a0)
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
                bra.s   loc_144aa

loc_144a2:
                lea     $40(a1),a1
                dbf     d1,loc_1447c
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
                dc.b    $18, $04
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
                dc.b    $02, $03
                dc.w    loc_1A7D8&$FFFF
                dc.w    loc_1A7E0&$FFFF
                
; ----------------------------------------------------------------------

loc_14e9c:
                dc.b    $02, $03
                dc.w    loc_1A838&$FFFF
                dc.w    loc_1A840&$FFFF
                
; ----------------------------------------------------------------------

loc_14ea2:
                dc.b    $03, $04
                dc.w    loc_1A7E8&$FFFF
                dc.w    loc_1A7F0&$FFFF
                dc.w    loc_1A7F8&$FFFF

; ----------------------------------------------------------------------

loc_14eaa:

                dc.b    $03, $04
                dc.w    loc_1A848&$FFFF
                dc.w    loc_1A850&$FFFF
                dc.w    loc_1A858&$FFFF
                
; ----------------------------------------------------------------------

loc_14eb2:
                dc.b    $04, $0A
                dc.w    loc_1A800&$FFFF 
                dc.w    loc_1A800&$FFFF
                dc.w    loc_1A808&$FFFF
                dc.w    loc_1A810&$FFFF
                
; ----------------------------------------------------------------------

loc_14ebc:
                dc.b    $04, $0A
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
                dc.b    $04, $01
                dc.w    loc_1ABAC&$FFFF
                dc.w    loc_1ABB4&$FFFF
                
; ---------------------------------------------------------------------- bookmark

loc_162f6: 02 01 ab bc                      andi.b  #-68,d1
loc_162fa ab c4                            .short 0xabc4

loc_162fc: 02 01 ac 3c                      andi.b  #$3C,d1
loc_16300 ac 44                            .short 0xac44

loc_16302: 02 01 ac 54                      andi.b  #84,d1
loc_16306 ac 5c                            .short 0xac5c

loc_16308: 04 01 ac 6c                      subi.b #108,d1
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
loc_163e0:
                dc.l    loc_163E4

; ----------------------------------------------------------------------

loc_163e4:
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
                bne.s   loc_166ec
                bset    #1,2(a0)
                move.l  #loc_14E12,8(a0)
                movea.l ($FFFFD282).w,a1
                moveq   #0,d0
                move.b  $38(a0),d0
                lsl.w   #1,d0
loc_166e6:
                move.w  (a1,d0.w),$3A(a0)
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
                bsr.w   loc_1105c
                lea     ($FFFFC640).w,a1
                tst.b   $39(a0)
                bne.s   loc_16768
                lea     $40(a1),a1
loc_16768:
                bsr.w   loc_117c0
                tst.b   d0
                beq.s   loc_16776
                move.w  #4,$3C(a0)
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
                dc.w    'PTS.'                   ; Mappings text.
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
                abcd    (a2)-,(a1)-
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
                move.w  #$5100,($C00000).l
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
                dc.l    loc_16BCC
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


loc_16bcc:
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

loc_16d18: 00 01 6d 3c                      ori.b #$3C,d1
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
                bne.s   loc_16de6                ; If it's already been loaded, skip initialisation.
                move.l  #Map_Pause,$C(a0)        ; Load the 'PAUSE' mappings into the SST.
                move.w  #$F0,$20(a0)             ; Set the horizontal screen position.
                move.w  #$108,$24(a0)            ; Set the vertical screen position.
                rts                              ; Return.

; ======================================================================

; TODO - End of code?

Pal_Main:                                        ; $16DE8
                incbin  "Palettes\Main.bin"

; ======================================================================


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
loc_16ea8 ec 8b                            lsr.l #6,d3
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
loc_16f9c 5b a5                            subq.l #5,(a5)-
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
loc_171f0 e0 aa                            lsr.l d0,d2
loc_171f2 31 c2 df a4                      move.w  d2,($FFFFdfa4
loc_171f6 ae a5                            .short 0xaea5
loc_171f8 51 8e                            subq.l #8,a6
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
loc_17384 55 8b                            subq.l #2,a3
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
loc_175b8 51 b1 0f e9 9f 71                subq.l #8,@(ffffffffffff9f71)@0)
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
loc_175fe 55 aa 64 8d                      subq.l #2,(a2)(25741)
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
loc_17724 59 94                            subq.l #4,(a4)
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
loc_1774e 53 88                            subq.l #1,a0
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
loc_1779c 55 af 3a aa                      subq.l #2,(sp)(15018)
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
loc_178f2 e8 ad                            lsr.l d4,d5
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
loc_17aa2 e8 8f                            lsr.l #4,d7
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
loc_17b7e 59 aa a8 d0                      subq.l #4,(a2)(-22320)
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
loc_17c58 5f af ae db                      subq.l #7,(sp)(-20773)
loc_17c5c 9c 20                            sub.b (a0)-,d6
loc_17c5e 49 b8 47 41                      chkw loc_4741,d4
loc_17c62 78 e9                            moveq   #-23,d4
loc_17c64 46 bd                            .short 0x46bd
loc_17c66 43 de                            .short 0x43de
loc_17c68 ec 83                            asr.l #6,d3
loc_17c6a 50 e9 46 bc                      st (a1)(18108)
loc_17c6e e9 a8                            lsl.l   d4,d0
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
loc_17e5c e8 ad                            lsr.l d4,d5
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
loc_18038 53 91                            subq.l #1,(a1)
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
loc_180f0 e4 aa                            lsr.l d2,d2
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
loc_18310 5f 92                            subq.l #7,(a2)
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

; ======================================================================

loc_185fc:
                include "Art\BtP\ASCII2.bin"

; ======================================================================

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
loc_188bc e3 aa                            lsl.l   d1,d2
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
loc_18972 5f 85                            subq.l #7,d5
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
loc_18bb2 e7 aa                            lsl.l   d3,d2
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
loc_18be0 5b b1 b7 a6 3d 7c 2e d7          subq.l #5,@(0000000000003d7c)@(0000000000002ed7,a3.w:8)
loc_18be8 f4 76                            .short 0xf476
loc_18bea 85 de                            divsw (a6)+,d2
loc_18bec 9d 76 85 da f9 eb                sub.w   d6,@0)@(fffffffffffff9eb)
loc_18bf2 1a 6b                            .short 0x1a6b
loc_18bf4 e7 a9                            lsl.l   d3,d1
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
loc_18dd6 5f 8a                            subq.l #7,a2
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
loc_18df6 ea ad                            lsr.l d5,d5
loc_18df8 55 80                            subq.l #2,d0
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
loc_18e78 53 aa a6 59                      subq.l #1,(a2)(-22951)
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
loc_18ec4 57 93                            subq.l #3,(a3)
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
loc_18eea 5f 9d                            subq.l #7,(a5)+
loc_18eec 57 ef ab 6f                      seq (sp)(-21649)
loc_18ef0 df 80                            addxl d0,d7
loc_18ef2 bf ce                            cmpal a6,sp
loc_18ef4 af 37                            .short 0xaf37
loc_18ef6 66 99                            bne.s   loc_18e91
loc_18ef8 d3 35 7e 76                      add.b d1,(a5)(0000000000000076,d7:l:8)
loc_18efc a5 67                            .short 0xa567
loc_18efe b3 65                            eor.w d1,(a5)-
loc_18f00 4c fa 3a bc b3 fd                movem.l (pc)(loc_14301),d2-d5/d7/a1/a3-a5
loc_18f06 e3 ab                            lsl.l   d1,d3
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
loc_18f5c 5d 8a                            subq.l #6,a2
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
loc_18fe0 ea af                            lsr.l d5,d7
loc_18fe2 25 57 92 ab                      move.l  (sp),(a2)(-27989)
loc_18fe6 c9 55                            and.w d4,(a5)
loc_18fe8 e4 ad                            lsr.l d2,d5
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
loc_1918e ea 8b                            lsr.l #5,d3
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
loc_193da 53 91                            subq.l #1,(a1)
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
loc_19400 e6 ad                            lsr.l d3,d5
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
loc_194c8 5b a4                            subq.l #5,(a4)-
loc_194ca 52 74 e9 e5 81 53                addq.w  #1,@(ffffffffffff8153)@0)
loc_194d0 bc ca                            cmpa.w a2,a6
loc_194d2 85 e1                            divsw (a1)-,d2
loc_194d4 b9 de                            cmpal (a6)+,a4
loc_194d6 14 dc                            move.b  (a4)+,(a2)+
loc_194d8 a9 12                            .short 0xa912
loc_194da a4 40                            .short 0xa440
loc_194dc 00 00 71 de                      ori.b #-34,d0
loc_194e0 77 cd                            .short 0x77cd
loc_194e2 5b 97                            subq.l #5,(sp)
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
loc_1951e 59 a5                            subq.l #4,(a5)-
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
loc_19620 53 92                            subq.l #1,(a2)
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
loc_19800 ea ad                            lsr.l d5,d5
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
loc_198dc 5f a3                            subq.l #7,(a3)-
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
loc_19922 e4 8b                            lsr.l #2,d3
loc_19924 f4 7b                            .short 0xf47b
loc_19926 7f 49                            .short 0x7f49
loc_19928 d1 7e                            .short 0xd17e
loc_1992a 8f 6f e2 00                      or.w d7,(sp)(-7680)
loc_1992e 13 b9 23 db a7 6b 7f 5d          move.b 0x23dba76b,(a1)@0)
loc_19936 d1 ed d3 b5                      adda.l (a5)(-11339),a0
loc_1993a bf 88                            cmpm.l (a0)+,(sp)+
loc_1993c c0 00                            and.b d0,d0


; ======================================================================
; Points, Iggy, diamond and bonus points model graphics.

loc_1993e:
                incbin  "Art\Nem\VariousArt.bin"
; ======================================================================
; FLICKY TITLE SCREEN FONT

loc_19EEE:
                incbin  "Art\Nem\TitleFontArt.bin"

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
                dc.w    $627C
                dc.w    $627D
                dc.w    $627E
                dc.w    $627F
                dc.w    $6280
                dc.w    $6281
                dc.w    $6282
                dc.w    $6283
                dc.w    $6284
                dc.w    $6285
                dc.w    $6286
                dc.w    $6287
                dc.w    $6288
                dc.w    $6289
                dc.w    $628A
                dc.w    $628B
                dc.w    $628C
                dc.w    $628D
                dc.w    $628E
                dc.w    $628F
                dc.w    $6290
                dc.w    $6291
                dc.w    $6292
                dc.w    $6293
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
                dc.w    $02C5
WallpaperScenery1:                               ; $1A354
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
                dc.w    $647C
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
                dc.w    $44AE                    ; Art tile.
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
                dc.b    $06

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

                dc.b    $00                      ; Number of sprites to load, -1.
                dc.b    $06

                dc.b    $F0                      ; Relative Y-axis positioning.
                dc.b    $01                      ; Set sprite size.
                dc.w    $4CAE                    ; Art tile.
                dc.b    $FC                      ; Relative X axis positioning.
                dc.b    $FC                      ; Flipped relative X axis positioning.

; ----------------------------------------------------------------------

loc_1A876:
00 ff                movem.w (a6)(255),d2-d7/a2-sp
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

; ======================================================================

loc_1a898: 00 00 e8 06                      ori.b #6,d0
loc_1a89c 44 10                            negb (a0)
loc_1a89e f8 f8                            .short 0xf8f8

; ======================================================================

loc_1a8a0: 00 01 f0 05                      ori.b #5,d1
loc_1a8a4 44 16                            negb (a6)
loc_1a8a6 f8 f8                            .short 0xf8f8

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

loc_1a8b8 00 01 f0 05                      ori.b #5,d1
loc_1a8bc 44 26                            negb (a6)-
loc_1a8be f8 f8                            .short 0xf8f8
loc_1a8c0 00 01 f0 05                      ori.b #5,d1
loc_1a8c4 44 2a f8 f8                      negb (a2)(-1800)
loc_1a8c8 00 02 f0 05                      ori.b #5,d2
loc_1a8cc 44 2e f8 f8                      negb (a6)(-1800)
loc_1a8d0 00 02 f0 05                      ori.b #5,d2
loc_1a8d4 44 32 f8 f8                      negb (a2)(fffffffffffffff8,sp:l)

; ======================================================================

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

                dc.b    $E6
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
                dc.w    $440D
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
loc_1ad30 48 b0

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

; ----------------------------------------------------------------------

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

loc_1ad82: 00 ff                            .short 0x00ff
loc_1ad84 e8 06                            asrb #4,d6
loc_1ad86 46 87                            notl d7
loc_1ad88 f8 f8                            .short 0xf8f8

; ----------------------------------------------------------------------

loc_1ad8a: 00 ff                            .short 0x00ff
loc_1ad8c e8 06                            asrb #4,d6
loc_1ad8e 46 8d                            .short 0x468d
loc_1ad90 f8 f8                            .short 0xf8f8

; ======================================================================
LevelLayouts:                                    ; $1AD92
                dc.l    loc_1ADF2&$FFFF          ; Round 1.
                dc.l    loc_1AE40&$FFFF          ; Round 2.
                dc.l    loc_1AE40&$FFFF          ; Bonus stage filler.
                dc.l    loc_1AE7C&$FFFF          ; Round 4.
                dc.l    loc_1AEDC&$FFFF          ; Round 5.
                dc.l    loc_1AF20&$FFFF          ; Round 6.
                dc.l    loc_1AF20&$FFFF          ; Bonus stage filler.
                dc.l    loc_1AF6C&$FFFF          ; Round 8.
                dc.l    loc_1AFBE&$FFFF          ; Round 9.
                dc.l    loc_1B012&$FFFF          ; Round 10.
                dc.l    loc_1B012&$FFFF          ; Bonus stage filler.
                dc.l    loc_1B070&$FFFF          ; Round 12.
                dc.l    loc_1B0B0&$FFFF          ; Round 13.
                dc.l    loc_1B108&$FFFF          ; Round 14.
                dc.l    loc_1B108&$FFFF          ; Bonus stage filler.
                dc.l    loc_1B152&$FFFF          ; Round 16.
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

; ----------------------------------------------------------------------
loc_1AEF2:
                incbin  "Misc\Level Layout\Round1.bin"

loc_1ae40:
                incbin  "Misc\Level Layout\Round2.bin"

loc_1ae7c:
                incbin  "Misc\Level Layout\Round4.bin"

loc_1aedc:
                incbin  "Misc\Level Layout\Round5.bin"

loc_1af20:
                incbin  "Misc\Level Layout\Round6.bin"

loc_1af6c:
                incbin  "Misc\Level Layout\Round8.bin"

loc_1afbe:
                incbin  "Misc\Level Layout\Round9.bin"

loc_1B012:
                incbin  "Misc\Level Layout\Round10.bin"

loc_1b070:
                incbin  "Misc\Level Layout\Round12.bin"

loc_1b0b0:
                incbin  "Misc\Level Layout\Round13.bin"

loc_1b108:
                incbin  "Misc\Level Layout\Round14.bin"

loc_1b1a0:
                incbin  "Misc\Level Layout\Round16.bin"

loc_1b1f8:
                incbin  "Misc\Level Layout\Round17.bin"

loc_1b242: 7f 01                            .short 0x7f01
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








