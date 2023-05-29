;Bank 3
	.BASE $8000
	
	;Bank Table
	db $00,$01,$02,$03,$04,$05,$06,$07
	
tblTitleScreenBGGraphics:
	db $02,$B0 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $8BE1
tblLevel1BGGraphics:
	db $07,$30 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $937C
tblLevel2BGGraphics:
	db $07,$30 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $9B36
tblLevel3BGGraphics:
	db $02,$60 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $A590
tblLevel4BGGraphics:
	db $07,$30 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $AD28
tblLevel5BGGraphics:
	db $07,$30 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $B4CD
tblLevel6BGGraphics:
	db $02,$60 ;PPU Address
	;RLE COMPRESSED DATA
	

	.PAD $BFD9
	;FREE SPACE TO THE END OF THE BANK


	.PAD $C000