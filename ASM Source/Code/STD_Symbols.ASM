PPUCTRL = $2000
; 7  bit  0
; ---- ----
; VPHB SINN
; |||| ||||
; |||| ||++- Base nametable address
; |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
; |||| |+--- VRAM address increment per CPU read/write of PPUDATA
; |||| |     (0: add 1, going across; 1: add 32, going down)
; |||| +---- Sprite pattern table address for 8x8 sprites
; ||||       (0: $0000; 1: $1000; ignored in 8x16 mode.  in 8x16 mode, even tile values at pattern table 0.  odd values at pattern table 2)
; |||+------ Background pattern table address (0: $0000; 1: $1000)
; ||+------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels)
; |+-------- PPU master/slave select
; |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
; +--------- Generate an NMI at the start of the
           ; vertical blanking interval (0: off; 1: on)
		   
PPUMASK = $2001
; 7  bit  0
; ---- ----
; BGRs bMmG
; |||| ||||
; |||| |||+- Greyscale (0: normal color, 1: produce a greyscale display)
; |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
; |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
; |||| +---- 1: Show background
; |||+------ 1: Show sprites
; ||+------- Emphasize red (green on PAL/Dendy)
; |+-------- Emphasize green (red on PAL/Dendy)
; +--------- Emphasize blue

PPUSTATUS = $2002
; 7  bit  0
; ---- ----
; VSO. ....
; |||| ||||
; |||+-++++- Least significant bits previously written into a PPU register
; |||        (due to register not being updated for this address)
; ||+------- Sprite overflow. The intent was for this flag to be set
; ||         whenever more than eight sprites appear on a scanline, but a
; ||         hardware bug causes the actual behavior to be more complicated
; ||         and generate false positives as well as false negatives; see
; ||         PPU sprite evaluation. This flag is set during sprite
; ||         evaluation and cleared at dot 1 (the second dot) of the
; ||         pre-render line.
; |+-------- Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
; |          a nonzero background pixel; cleared at dot 1 of the pre-render
; |          line.  Used for raster timing.
; +--------- Vertical blank has started (0: not in vblank; 1: in vblank).
           ; Set at dot 1 of line 241 (the line *after* the post-render
           ; line); cleared after reading $2002 and at dot 1 of the
           ; pre-render line.
		   

;Graphics Attributes (Normal PPU sprite attributes)
;76543210
;||||||||
;||||||++- Palette of sprite
;|||+++--- Unimplemented
;||+------ Priority (0: in front of background; 1: behind background)
;|+------- Flip sprite horizontally
;+-------- Flip sprite vertically

OAMADDR = $2003
OAMDATA = $2004
PPUSCROLL = $2005
;SAMPLE
; bit PPUSTATUS
; ; possibly other code goes here
; lda cam_position_x
; sta PPUSCROLL
; lda cam_position_y
; sta PPUSCROLL
 
PPUADDR = $2006
PPUDATA = $2007

;Pulse 1
APU_PULSE_DDLCVVVV = $4000 ;Duty (D), envelope loop / length counter halt (L), constant volume (C), volume/envelope (V)
APU_PULSE_EPPPNSSS = $4001 ;Sweep unit: enabled (E), period (P), negate (N), shift (S)
APU_PULSE_TTTTTTTT = $4002 ;Timer Low (T)
APU_PULSE_LLLLLTTT = $4003 ;Length counter load (L), timer high (T)

;Pulse 2
APU_PULSE2_DDLCVVVV = $4004 ;Duty (D), envelope loop / length counter halt (L), constant volume (C), volume/envelope (V)
APU_PULSE2_EPPPNSSS = $4005 ;Sweep unit: enabled (E), period (P), negate (N), shift (S)
APU_PULSE2_TTTTTTTT = $4006 ;Timer Low (T)
APU_PULSE2_LLLLLTTT = $4007 ;Length counter load (L), timer high (T)

;Triangle
APU_TRIANGLE_CRRRRRRR = $4008 ;Length counter halt / linear counter control (C), linear counter load (R)
APU_TRIANGLE_UNUSED = $4009
APU_TRIANGLE_TTTTTTTT = $400A ;Timer Low (T)
APU_TRIANGLE_LLLLLTTT = $400B ;Length counter load (L), timer high (T)

;Noise
APU_NOISE_XXLCVVVV = $400C ;Envelope loop / length counter halt (L), constant volume (C), volume/envelope (V)
APU_NOISE_UNUSED = $400D 
APU_NOISE_LXXXPPPP = $400E ;Loop noise (L), noise period (P)
APU_NOISE_LLLLLXXX = $400F  ;Length counter load (L)

;DMC
APU_DMC = $4010 ;duplicate for ease of reading code
APU_DMC_ILXXRRRR = $4010 ;IRQ enable (I), loop (L), frequency (R)
APU_DMC_XDDDDDDD = $4011 ;Load counter (D)
APU_DMC_AAAAAAAA = $4012 ;Sample address (A)
APU_DMC_LLLLLLLL = $4013 ;Sample length (L)

OAMDMA = $4014

APUSTATUS = $4015
;APU Status Write Data:
;76543210
;|||||||+- Pulse 1 On/Off
;||||||+-- Pulse 2 On/Off
;|||||+--- Triangle On/Off
;||||+---- Noise On/Off
;|||+----- DMC On/Off
;+++------ Unimplemented
APUCOUNTERIRQ = $4017

JOYPAD1INPUT = $4016
JOYPAD2INPUT = $4017
;Controller Read Data:
;76543210
;|||||||+- Right
;||||||+-- Left
;|||||+--- Down
;||||+---- Up
;|||+----- Start
;||+------ Select
;|+------- B
;+-------- A