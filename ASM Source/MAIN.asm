	;iNES Header for Jackal
	
	db $4E,$45,$53,$1A ;NES (EOF)
	db $08 ;PRG ROM Size in 16kB chunks 
	db $00 ;CHR ROM Size in 8kB chunks
	;Mapper lower nibble      Do NOT ignore mirroring    No Trainer     No Battery     Vertical Mirroring
	db ($20 +                 $00 +                      $00 +          $00 +          $01)
	;Mapper upper nibble    Not NES 2.0 format    No PlayChoice   No VS Unisystem
	db ($00 +               $00 +                 $00 +           $00)
	db $00 ;PRG RAM size
	db $00 ;TV System = NTSC
	db $00 ;UNUSED
	db $00,$00,$00,$00,$00 ;UNUSED padding
	
	.INCSRC Code\Macro.ASM ;Global macros
	.INCSRC Code\RAM_Symbols.ASM ;Defines all RAM ($000-$700) data
	.INCSRC Code\STD_Symbols.ASM ;Defines CPU/PPU critical address (Scroll, Joypad, etc.)
	.INCSRC Code\Sound.ASM ;Definitions for all sounds clips and music
	.INCSRC Code\JeepAttributes.ASM ;Global variables related to the jeep
	.INCSRC Code\Global.ASM ;Global variables, misc
	.INCSRC Code\Bank0.ASM ;Audio and End of Game logic
	.INCSRC Code\Bank1.ASM ;Score display and Sprite management and visualization
	.INCSRC Code\Bank2.ASM ;Graphics
	.INCSRC Code\Bank3.ASM ;Graphics
	.INCSRC Code\Bank4.ASM ;Level 1,2,4,5 Layouts,metatiles,etc.
	.INCSRC Code\Bank5.ASM ;Level 3,6 Layouts,metatiles,etc. and some graphics
	.INCSRC Code\Bank6.ASM ;All enemy AI Logic
	.INCSRC Code\Bank7.ASM ;Main game code/static bank