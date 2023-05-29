;Bank 02
	.BASE $8000
	
	;Bank Table
	db $00,$01,$02,$03,$04,$05,$06,$07
	
tblCommonTextBGGraphics:
	db $00,$00 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $818A
tblCommonBGGraphics:
	db $02,$60 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $853D
tblCommonSpriteGraphics:
	db $10,$00 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $8D6A
tblLevel1SpriteGraphics:
	db $19,$E0 ;PPU Address
	;RLE COMPRESSED DATA


	.PAD $923E
tblLevel2SpriteGraphics:
	db $19,$E0 ;PPU Address
	;RLE COMPRESSED DATA
	

	.PAD $9655
tblLevel3SpriteGraphics:
	db $19,$E0 ;PPU Address
	;RLE COMPRESSED DATA
	

	.PAD $9B6C
tblLevel4SpriteGraphics:
	db $19,$E0 ;PPU Address
	;RLE COMPRESSED DATA
	

	.PAD $A069
tblLevel5SpriteGraphics:
	db $19,$E0 ;PPU Address
	;RLE COMPRESSED DATA
	

	.PAD $A53A
tblLevel6SpriteGraphics:
	db $19,$E0 ;PPU Address
	;RLE COMPRESSED DATA


;****************
;These tables have 7 byte headers, which contains a hard coded address
;; be weary when relocating these
;****************


	.PAD $A9F8
tblLevel3WaterTileUpdate1:
	db $02	 ;ROM Bank
	db $0D,$E0 ;PPU Address
	db $FF,$A9 ;ROM Address ($A9FF)
	db $00,$C0 ;Total byte count ($C0)
	;UNCOMPRESSED DATA
	
	
	.PAD $AABF
tblLevel3WaterTileUpdate2:
	db $02	 ;ROM Bank
	db $0D,$E0 ;PPU Address
	db $C6,$AA ;ROM Address ($AAC6)
	db $00,$C0 ;Total byte count ($C0)
	;UNCOMPRESSED DATA
	
	
	.PAD $AB86
tblLevel3F2PatternTableUpdate:
	db $02	 ;ROM Bank
	db $0A,$C0 ;PPU Address
	db $8D,$AB ;ROM Address ($AB8D)
	db $03,$20 ;Total byte count ($320)
	;UNCOMPRESSED DATA
	
	
	.PAD $AEAD
tblLevel5F2PatternTableUpdate:
	db $02	 ;ROM Bank
	db $08,$90 ;PPU Address
	db $B4,$AE ;ROM Address ($AEB4)
	db $04,$40 ;Total byte count ($440)
	;UNCOMPRESSED DATA
	
	
	.PAD $B2F4 ;This is loaded after the chinook leaves
tblLevel1BossTankSpriteGraphics:
	db $02	 ;ROM Bank
	db $1C,$A0 ;PPU Address
	db $FB,$B2 ;ROM Address ($B2FB)
	db $01,$E0 ;Total byte count ($1E0)
	;UNCOMPRESSED DATA
	
	
	.PAD $B4DB
tblLevel6F2PatternTableUpdate:
	db $02	 ;ROM Bank
	db $0A,$D0 ;PPU Address
	db $E2,$B4 ;ROM Address ($B4E2)
	db $01,$70 ;Total byte count ($170)
	;UNCOMPRESSED DATA
	
	
	.PAD $B652
tblLevel4F2PatternTableUpdate:
	db $02	 ;ROM Bank
	db $19,$E0 ;PPU Address
	db $59,$B6 ;ROM Address ($B659)
	db $03,$C0 ;Total byte count ($3C0)
	;UNCOMPRESSED DATA
	
	
	.PAD $BA19
tblLevel6EscalatorBGGraphicsUpdate1:
	db $02	 ;ROM Bank
	db $05,$00 ;PPU Address
	db $20,$BA ;ROM Address ($BA20)
	db $00,$10 ;Total byte count ($10)
	;UNCOMPRESSED DATA
	
	
	.PAD $BA30
tblLevel6EscalatorBGGraphicsUpdate2:
	db $02	 ;ROM Bank
	db $05,$00 ;PPU Address
	db $37,$BA ;ROM Address ($BA37)
	db $00,$10 ;Total byte count ($10)
	;UNCOMPRESSED DATA
	
	
	.PAD $BA47
tblLevel6FinalBossTankTreadBGGraphicsUpdate1:
	db $02	 ;ROM Bank
	db $09,$00 ;PPU Address
	db $4E,$BA ;ROM Address ($BA4E)
	db $00,$60 ;Total byte count ($60)
	;UNCOMPRESSED DATA
	
	
	.PAD $BAAE
tblLevel6FinalBossTankTreadBGGraphicsUpdate2:
	db $02	 ;ROM Bank
	db $09,$00 ;PPU Address
	db $B5,$BA ;ROM Address ($BAB5)
	db $00,$60 ;Total byte count ($60)
	;UNCOMPRESSED DATA
	
	
	.PAD $BB15
tblLevel6FinalBossTankTreadBGGraphicsUpdate3:
	db $02	 ;ROM Bank
	db $09,$00 ;PPU Address
	db $1C,$BB ;ROM Address ($BB1C)
	db $00,$60 ;Total byte count ($60)
	;UNCOMPRESSED DATA
	
	
	.PAD $BB7C
tblLevel6FinalBossTankTreadBGGraphicsUpdate4:
	db $02	 ;ROM Bank
	db $09,$00 ;PPU Address
	db $83,$BB ;ROM Address ($BB83)
	db $00,$60 ;Total byte count ($60)
	;UNCOMPRESSED DATA
	
	
	.PAD $BBE3
tblLevel6FinalBossBuilding_LaserTurretGraphicsUpdate
	db $02	 ;ROM Bank
	db $19,$E0 ;PPU Address
	db $EA,$BB ;ROM Address ($BA20)
	db $03,$20 ;Total byte count ($320)
	;UNCOMPRESSED DATA
	

	.PAD $BF0A
	;FREE SPACE TO THE END OF THE BANK
	
	
	.PAD $C000 ;End of Bank