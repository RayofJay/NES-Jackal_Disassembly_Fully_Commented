;Bank 1
	.BASE $8000
	
	;Bank Table
	db $00,$01,$02,$03,$04,$05,$06,$07

	.PAD $8008
subProcessSpriteUpdates:
	LDA #$40 ;64 total sprite slots in PPU internal memory.  All sprites are always rendered.  Must provide some data.
	STA $17  ;0017 is primarily used for this 64 sprite counter
	LDA #$1F ;32 total in-game sprites (jeeps, bazookas, enemies, bullets, etc.).  Loads a pointer to start processing sprites from the last one (Jeep stuff first)
	STA $05  ;0005 is primarily used to track the in-game sprites
	
	;Increment the sprite base slot.
	;This allows the sprites to be shuffled around in memory to avoid any one sprite being completely hidden due to the 8 sprite per scan line limit
	LDA SpriteSlotRotation
	CLC
	ADC #$44
	STA SpriteSlotRotation
	
	STA $04
-:	LDX $05
	LDA SpriteTypeIndex,X ;Read the Sprite Type Index.  This is used for the rendering table at a minimum
	BEQ +++ ;if no sprite exists in this slot, move on to the next
	LDA SpriteState,X ;Load the sprite state
	BMI +++ ;Ignore this sprite if the state is invalid
	LDA SpriteAttributes,X
	STA $10
	LDA SpriteGraphicsAttributes,X
	STA $00
	LDA SpriteVertScreenPosition,X
	STA $01
	LDA SpriteHorizScreenPosition,X
	STA $02
	LDA SpriteTypeIndex,X
	ASL ;Multiply by 2 (because the table has 16 byte addresses in it)
	TAY
	BCC + ;Branch if the sprite value was <=$7F.  carry is set for all IDs >=$80
	LDA tblSpriteConstructionHeaderAddress2,Y
	STA $08
	LDA (tblSpriteConstructionHeaderAddress2 + 1),Y
	JMP ++
+:	LDA tblSpriteConstructionHeaderAddress,Y
	STA $08
	LDA (tblSpriteConstructionHeaderAddress + 1),Y
++:	STA $09
	JSR subDrawObjectSprites

+++:	;This object is despawned or has no visual component to display.  Move the pointer to the next sprite slot
	DEC $05 
	BPL - ;if there are more slots to check, process them
	
	LDX $04
	LDA GameControlState
	CMP #$05 ;State 5 is normal game play including black screen transitions and the chinook
	BNE +
	LDA GamePlayMode
	CMP #$03 ;State 3 is normal game play mode
	BEQ ++	
+:	JMP No_More_Sprites
;Display player score
++:	LDA #$01 ;Default to player 2
	LDY Player2Active
	BNE +
	LDA #$00 ;Player 1
	BEQ ++
+:	LDA RNG_INCEveryFrame
	AND #$80 ;Alternate every $80 frames
	CLC
	ROL
	ROL
++:	STA $08
	ASL
	TAY
	LDA tblScoreDisplayCoordinates,Y ;X coordinate
	STA $09
	LDA (tblScoreDisplayCoordinates + 1),Y ;Y coordinate
	STA $0C
	LDA #$03
	STA $0B
	LDY #$00
	LDA $08 ;0=Player1,1=Player2
	ASL
	ASL ;2 ASLs because score is 24bit (3 bytes)
	TAX
-:	LDA JeepScore,X
	AND #$0F ;Score first digit
	ASL
	CLC
	ADC #$02
	STA $D8,Y
	INY
	LDA Jeep1Score,X
	AND #$F0 ;Score second digit
	LSR
	LSR
	LSR
	CLC
	ADC #$02
	STA $D8,Y
	INX
	INY
	DEC $0B
	BNE -
	LDA #$20 ;The 'P' in 1P (for score)
	STA $D8,Y
	INY
	LDA #$04 ;Loads a '1' or a '2' for 1P or 2P (for score)
	STA $D8,Y
	LDA $08
	BEQ +
	LDA #$06
	STA $D8,Y
+:	LDA #$08
	STA $0A
	LDX $04
	LDY #$07
-:	LDA $0C
	STA OAMDMA_Y,X
	LDA $D8,Y
	STA OAMDMA_PatternTableTileIndex,X
	DEY
	LDA #$00
	STA OAMDMA_Attributes,X
	LDA $09
	STA OAMDMA_X,X
	CLC
	ADC #$08
	STA $09
	LDA $0A
	CMP #$07
	BNE +
	LDA $09
	CLC
	ADC #$08
	STA $09
+:	TXA
	CLC
	ADC #$C4
	TAX
	DEC $17
	BEQ +
	DEC $0A
	BNE -
	LDY $08
	LDA JeepLifeCount,Y
	BEQ No_More_Sprites
	LDA $09 ;, code for displaying player score
	SEC
	SBC #$2C
	STA $09
	LDA $0C
	CLC
	ADC #$10 ;go two rows down to display life count
	STA $0C
	STA OAMDMA_Y,X
	
	;Player life count
	LDA #$20
	STA OAMDMA_PatternTableTileIndex,X
	LDA $08
	STA OAMDMA_Attributes,X
	LDA $09
	STA OAMDMA_X,X
	TXA
	CLC
	ADC #$C4
	TAX
	DEC $17
	BEQ +
	LDA $0C
	STA $0200,X
	LDY $08
	LDA JeepLifeCount,Y
	SEC
	SBC #$01
	AND #$0F
	ASL
	CLC
	ADC #$02
	STA OAMDMA_PatternTableTileIndex,X
	LDA #$00
	STA OAMDMA_Attributes,X
	LDA $09
	CLC
	ADC #$0A
	STA OAMDMA_X,X
	TXA
	CLC
	ADC #$C4
	TAX
	DEC $17
	BEQ +

;There are no more sprites to display on screen.  This code files the remaining sprite slots in OAMDMA with Y coordinates that are off screen so they are not visible
No_More_Sprites: 
	LDA #$F4 ;Load a Y coordinate that is off screen
	STA OAMDMA_Y,X ;loop through all the remaining sprites
	TXA
	CLC
	ADC #$C4	;rotate through the sprite order
	TAX
	DEC $17	;dec sprite count
	BNE No_More_Sprites
+:	RTS

;In-Game XP display location
tblScoreDisplayCoordinates:
	db $10 ;Player 1 score X coord
	db $C8 ;Player 1 score Y coord
	db $A0 ;Player 2 score X coord
	db $C8 ;Player 2 score Y coord
	
subDrawObjectSprites:
	LDY #$00
	LDA ($08),Y ;Load the number of sprite tiles to render for this object
	BEQ +++++	;RTS Exit if there are no sprites to render
	INY 	;Move Y to the first sprite tile data
	STA $03
	LDX $04
-:	LDA $10
	BPL ++
	LDA ($08),Y
	EOR #$FF
	CLC
	ADC #$01
	SEC
	SBC #$10
	JMP +
++:	LDA ($08),Y
+:	BPL ++
	CLC
	ADC $01
	BCC +
	BCS +++
++:	CLC
	ADC $01
	BCC +++
+:	INY ;Sprite would be off screen. 
	INY ;;so increment to the next sprite to load
	INY
	JMP ++++
+++:	STA OAMDMA_Y,X
	INY
	LDA ($08),Y
	STA OAMDMA_PatternTableTileIndex,X
	INY
	LDA ($08),Y
	EOR $10
	ORA $00
	STA OAMDMA_Attributes,X
	INY
	LDA $10
	AND #$40
	BEQ +
	LDA ($08),Y
	EOR #$FF
	CLC
	ADC #$01
	SEC
	SBC #$08
	JMP ++
+:	LDA ($08),Y
++:	BPL +
	CLC
	ADC $02
	BCC ++++
	BCS ++
+:	CLC
	ADC $02
	BCS ++++
++:	STA $0203,X
	DEC $17
	BNE +
	PLA
	PLA
	RTS
+:	TXA
	CLC
	ADC #$C4
	TAX
++++:	INY
	DEC $03 ;Decrement sprite count to process
	BNE -   ;If there are more sprites to process, go process them
	STX $04
+++++:	RTS
	
	
	.PAD $81F7
tblSpriteConstructionHeaderAddress:
	dw tblNullObject 				;0
	dw tblJeepUpDown 				;1
	dw tblJeepUpDown_WaterSplash_ 	;2
	dw tblJeepDiagonal 				;3
	dw tblJeepDiagonal_WaterSplash_ 	;4
	dw tblJeepLeftRight 			;5
	dw tblJeepLeftRight_WaterSplash_ 	;6
	dw tblGrenadeLowAltitude 		;7
	dw tblGrenadeHighAltitude 		;8
	dw tblBazookaSplashLarge 		;9
	dw tblBazookaSplashMedium 		;A
	dw tblBazookaSplashSmall 		;B
	dw tblGAMEOVERText 				;C
	dw tblBazookaRocketUp_Down 		;D
	dw tblBazookaRocketDiagonal 		;E
	dw tblBazookaRocketLeft_Right 	;F
	dw tblBullet 					;10
	dw tblBulletCollision 			;11
	dw tblInfantryWalkingLeft_Right 	;12
	dw tblInfantryWalkingDown_LeftFootForward 	;13
	dw tblInfantryWalkingUp_RightFootForward 	;14
	dw tblInfantryStandingLeft_Right 			;15
	dw tblInfantryWalkingDown_RightFootForward 	;16
	dw tblInfantryWalkingUp_LeftFootForward 	;17
	dw tblCrushedInfantry 			;18
	dw tblSmallExplosion 			;19
	dw tblMediumExplosion 			;1A
	dw tblLargeExplosion 			;1B
	dw tblLargeGrayTurretLeft_Right 	;1C
	dw tblLargeGrayTurretDiagonal 	;1D
	dw tblLargeGrayTurretUp_Down 		;1E
	dw tblLargeGrayTurretLeft_RightRecoil 	;1F
	dw tblLargeGrayTurretDiagonalRecoil 	;20
	dw tblLargeGrayTurretUp_DownRecoil ;21
	dw tblMediumRedTankLeft_Right 	;22
	dw tblMediumRedTankDiagonal 		;23
	dw tblMediumRedTankUp_Down 		;24
	dw tblPOWWalkingLeft_RightFeetTogether 	;25 
	dw tblPOWWalkingDownRightFootForward 	;26
	dw tblPOWWalkingUpLeftFootForward 	;27
	dw tblPOWWalkingLeft_RightInStride ;28
	dw tblPOWWalkingDownLeftFootForward ;29
	dw tblPOWWalkingUpRightFootForward ;2A
	dw tblPOWWaving1 			;2B
	dw tblPOWWaving2 			;2C
	dw tblPOWBuildingHELPText 	;2D
	dw tblPowerUpStar 			;2E
	dw tblHelicopterOnHelipad1 	;2F
	dw tblHelicopterOnHelipad2 	;30
	dw tblHelicopterInAir1 		;31
	dw tblHelicopterInAir2 		;32
	dw tblLevel1BossTankRight_Left ;33
	dw tblLevel1BossTankDiagonal 	;34
	dw tblLevel1BossTankUp_Down 	;35
	dw tblLevel1BossTankRight_LeftRecoil 	;36
	dw tblLevel1BossTankDiagonalRecoil 	;37
	dw tblLevel1BossTankUp_DownRecoil 		;38
	dw tblLevel1BossTankDiagonalUpsideDown 	;39
	dw tblLevel1AttackBoatWake1 			;3A
	dw tblLevel1AttackBoatWake2 			;3B
	dw tblLevel1BossTankDiagonalUpsideDownRecoil ;3C
	dw tblEnemyJeepRight_Left 	;3D
	dw tblEnemyJeepDiagonal 		;3E
	dw tblEnemyJeepUp_Down 		;3F
	
	;The bomb seems to be rotated randomly based on the frame.  Maybe like the grenade??
	dw tblPlane_JeepBombUpLeftSmall 	;40
	dw tblPlane_JeepBombDownRightLarge ;41
	dw tblPlane_JeepBombDownRightLarge ;42
	dw tblPlane_JeepBombUpLeftSmall 	;43
	
	dw tblSilverLargeTank_FlameTankRightLeft 	;44
	dw tblSilverLargeTank_FlameTankDiagonal 	;45
	dw tblSilverLargeTankUpDown 				;46
	dw tblBrokenPillarFallingDiagonal 			;47
	dw tblBrokenPillarRollingRightLeft 		;48
	dw tblBrokenPillarRollingRightLeft2 		;49 (used to simulate rolling)
	dw tblBlackShell 				;4A (e.g. Silver Large Tank)
	dw tblSmallMissileLeftRight 		;4B (e.g. Level 2 statue head)
	dw tblSmallMissileDiagonal 		;4C (e.g. Level 2 statue head)
	dw tblSmallMissileUpDown 		;4D (e.g. Level 2 statue head)
	dw tblBomberPlaneWithShadow 		;4E
	dw tblBomberPlane 				;4F
	dw tblSpreadTurretHidden 		;50
	dw tblSpreadTurretRising1 		;51
	dw tblSpreadTurretRising2 		;52
	dw tblSpreadTurretUp 			;53
	dw tblInfantryTruck				;54
	dw tblInfantryTruckWithDoorOpen 	;55
	dw tblLevel3LargeAttackBoatWake1 	;56
	dw tblLevel3LargeAttackBoatWake2 	;57
	dw tblSubmarineRising1 			;58
	dw tblSubmarineRising2 			;59
	dw tblSubmarineUp 				;5A
	dw tblSubmarineRising1WithShadow 	;5B
	dw tblSubmarineRising2WithShadow 	;5C
	dw tblSubmarineUpWithShadow 		;5D
	dw tblSubmarineShadowOnly 		;5E
	dw tblLevel3LaserBeamLong 		;5F
	dw tblLevel3LaserBeamShort		;60
	dw tblLevel3LaserChargingFlash1 	;61
	dw tblLevel3LaserChargingFlash2 	;62
	dw tblNullObject 				;63 Spread Boss Turret Hidden (must use BG tiles)
	dw tblSpreadBossTurretRising1		;64
	dw tblSpreadBossTurretRising2 	;65
	dw tblSpreadBossTurretUp 		;66
	dw tblSpreadTruck 				;67
	dw tblSpreadTruckFiring 			;68
	dw tblLevel4CliffMissileLauncher 	;69
	dw tblLevel4CliffMissileLauncherMissileEmerging ;6A
	dw tbl6B_UNKNOWN 				;6B
	dw tblSubmergedMissileLauncher 	;6C
	dw tblSubmergedMissileLauncherOpening 			;6D
	dw tblSubmergedMissileLauncherSplash 			;6E
	dw tblSubmergedMissileLauncherMissileEmerging 	;6F
	dw tblBlackAndWhiteMissileRight_Left 			;70
	dw tblBlackAndWhiteMissileDiagonal 	;71
	dw tblBlackAndWhiteMissileUp_Down 		;72
	dw tblHiddenMineVisible 				;73
	dw tblSwampInfantryLeft_Right1 		;74
	dw tblSwampInfantryDown1 			;75
	dw tblSwampInfantryUp1 				;76
	dw tblSwampInfantryLeft_Right2 		;77
	dw tblSwampInfantryDown2 			;78
	dw tblSwampInfantryUp2 				;79
	dw tblLevel1Chinook 				;7A
	dw tblLevel1ChinookBladesRotated 		;7B
	dw tblLevel4FallingRockResting 		;7C
	dw tblLevel4FallingRockFallen 		;7D
	dw tblLevel4BossHelicopterBladesCardinal ;7E
	dw tblLevel4BossHelicopterBladesDiagonal ;7F

	
	;****************
	;Sprite Rendering
	;The following data mimics the OADDMA structure:
	;(Y,Table ID,Attributes,X)
	;However, the X,Y coordinates are offsets from the anchor of the sprite
	;***********************

;00
tblNullObject:
	db $00 ;Number of sprites

;01
tblJeepUpDown:
	db $04 ;Number of sprites
	db $F0,$03,$00,$F8
	db $00,$05,$00,$F8
	db $F0,$03,$40,$00
	db $00,$05,$40,$00

;02
tblJeepUpDown_WaterSplash_:
	db $06 ;Number of sprites
	db $F8,$E5,$00,$F0 ;Splash tiles - Left
	db $F0,$03,$00,$F8
	db $00,$05,$00,$F8
	db $F0,$03,$40,$00
	db $00,$05,$40,$00
	db $F8,$E5,$40,$08 ;Splash tiles - Right

;03
tblJeepDiagonal:
	db $05 ;Number of sprites
	db $F0,$07,$00,$F4 ;Column 1 row 2
	db $00,$09,$00,$F4 ;Column 1 row 3
	db $F0,$0B,$00,$FC ;Column 2 row 2
	db $00,$0D,$00,$FC ;Column 2 row 3
	db $F5,$0F,$00,$04 ;Column 3 row 1 & 2

;04
tblJeepDiagonal_WaterSplash_:	
	db $06 ;Number of sprites
	db $F0,$E7,$00,$F4 ;Splash tiles - top left
	db $00,$09,$00,$F4
	db $F0,$0B,$00,$FC
	db $00,$0D,$00,$FC
	db $F0,$E9,$00,$04 ;Splash tiles - top right
	db $00,$EB,$00,$04 ;Splash tiles - bottom right

;05
tblJeepLeftRight:
	db $03 ;Number of sprites
	db $F8,$11,$00,$F4
	db $F8,$13,$00,$FC
	db $F8,$15,$00,$04

;06
tblJeepLeftRight_WaterSplash_:
	db $06 ;Number of sprites
	db $E8,$ED,$00,$F9 ;Splash tiles - top
	db $F8,$11,$00,$F4
	db $F8,$13,$00,$FC
	db $F8,$15,$00,$04
	db $08,$EF,$00,$F7 ;Splash tiles - bottom
	db $08,$F1,$00,$FF ;Splash tiles - bottom right

;07
tblGrenadeLowAltitude:	
	db $01 ;Number of sprites
	db $F8,$1F,$00,$FC

;08
tblGrenadeHighAltitude:
	db $02 ;Number of sprites
	db $F8,$21,$00,$F8
	db $F8,$23,$00,$00

;09
tblBazookaSplashLarge:
	db $02 ;Number of sprites
	db $F8,$2F,$00,$F8
	db $F8,$2F,$C0,$00

;0A
tblBazookaSplashMedium:
	db $01 ;Number of sprites
	db $F8,$65,$01,$FC

;0B
tblBazookaSplashSmall:
	db $01 ;Number of sprites
	db $F8,$67,$01,$FC

;0C
tblGAMEOVERText:
	db $04 ;Number of sprites
	db $F8,$16,$00,$F0
	db $F8,$18,$00,$F8
	db $F8,$1A,$00,$00
	db $F8,$1C,$00,$08

;0D
tblBazookaRocketUp_Down:
	db $01 ;Number of sprites
	db $F8,$25,$00,$FC

;0E
tblBazookaRocketDiagonal:
	db $02 ;Number of sprites
	db $F8,$27,$00,$F8
	db $F8,$29,$00,$00

;0F
tblBazookaRocketLeft_Right:
	db $02 ;Number of sprites
	db $F8,$2B,$00,$F8
	db $F8,$2D,$00,$00

;10
tblBullet:
	db $01 ;Number of sprites
	db $F8,$5B,$02,$FC

;11
tblBulletCollision:
	db $01 ;Number of sprites
	db $F8,$5D,$02,$FC

;12
tblInfantryWalkingLeft_Right:	
	db $01 ;Number of sprites
	db $F8,$4F,$01,$FC

;13
tblInfantryWalkingDown_LeftFootForward:
	db $01 ;Number of sprites
	db $F8,$55,$01,$FC

;14
tblInfantryWalkingUp_RightFootForward:
	db $01 ;Number of sprites
	db $F8,$4B,$01,$FC

;15
tblInfantryStandingLeft_Right:
	db $01 ;Number of sprites
	db $F8,$51,$01,$FC

;16
tblInfantryWalkingDown_RightFootForward:
	db $01 ;Number of sprites
	db $F8,$57,$01,$FD

;17
tblInfantryWalkingUp_LeftFootForward:
	db $01 ;Number of sprites
	db $F8,$4D,$01,$FD

;18
tblCrushedInfantry:
	db $01 ;Number of sprites
	db $F8,$59,$00,$FC

;19
tblSmallExplosion:
	db $01 ;Number of sprites
	db $F8,$65,$03,$FC

;1A
tblMediumExplosion:
	db $02 ;Number of sprites
	db $F8,$2F,$03,$F8
	db $F8,$2F,$C3,$00

;1B
tblLargeExplosion:
	db $08 ;Number of sprites
	db $F0,$31,$03,$F0
	db $00,$33,$03,$F0
	db $F0,$35,$03,$F8
	db $00,$37,$03,$F8
	db $EF,$37,$C3,$00
	db $FF,$35,$C3,$00
	db $EF,$33,$C3,$08
	db $FF,$31,$C3,$08

;1C
tblLargeGrayTurretLeft_Right:	
	db $03 ;Number of sprites
	db $F8,$85,$00,$F8
	db $F8,$87,$00,$00
	db $F8,$89,$00,$08

;1D
tblLargeGrayTurretDiagonal:
	db $03 ;Number of sprites
	db $F8,$7F,$80,$F6
	db $F8,$81,$80,$FE
	db $FC,$83,$80,$06

;1E
tblLargeGrayTurretUp_Down:
	db $04 ;Number of sprites
	db $F0,$7D,$80,$F8
	db $00,$7B,$80,$F8
	db $F0,$7D,$C0,$00
	db $00,$7B,$C0,$00

;1F
tblLargeGrayTurretLeft_RightRecoil:
	db $03 ;Number of sprites
	db $F8,$85,$00,$F8
	db $F8,$87,$00,$00
	db $F8,$8F,$00,$08

;20
tblLargeGrayTurretDiagonalRecoil:
	db $03 ;Number of sprites
	db $F8,$7F,$80,$F6
	db $F8,$81,$80,$FE
	db $FC,$8D,$80,$06

;21
tblLargeGrayTurretUp_DownRecoil:
	db $04 ;Number of sprites
	db $F0,$7D,$80,$F8
	db $00,$8B,$80,$F8
	db $F0,$7D,$C0,$00
	db $00,$8B,$C0,$00

;22
tblMediumRedTankLeft_Right:
	db $03 ;Number of sprites
	db $F8,$9D,$01,$F4
	db $F8,$53,$01,$FC
	db $F8,$69,$01,$04

;23
tblMediumRedTankDiagonal:
	db $04 ;Number of sprites
	db $F8,$95,$81,$F4
	db $F0,$99,$81,$FC
	db $00,$97,$81,$FC
	db $F8,$9B,$81,$04

;24
tblMediumRedTankUp_Down:
	db $04 ;Number of sprites
	db $F0,$93,$81,$F8
	db $00,$91,$81,$F8
	db $F0,$93,$C1,$00
	db $00,$91,$C1,$00

;25
tblPOWWalkingLeft_RightFeetTogether:
	db $01 ;Number of sprites
	db $F9,$3F,$00,$FC

;26
tblPOWWalkingDownRightFootForward:
	db $01 ;Number of sprites
	db $F8,$43,$00,$FC

;27
tblPOWWalkingUpLeftFootForward:
	db $01 ;Number of sprites
	db $F8,$3B,$00,$FC

;28
tblPOWWalkingLeft_RightInStride:
	db $01 ;Number of sprites
	db $F8,$3D,$00,$FC

;29
tblPOWWalkingDownLeftFootForward:
	db $01 ;Number of sprites
	db $F8,$43,$40,$FD

;2A
tblPOWWalkingUpRightFootForward:
	db $01 ;Number of sprites
	db $F8,$3B,$40,$FD

;2B
tblPOWWaving1:
	db $02 ;Number of sprites
	db $F8,$45,$00,$F8
	db $F8,$47,$00,$00

;2C
tblPOWWaving2:
	db $02 ;Number of sprites
	db $F8,$49,$00,$F8
	db $F8,$47,$00,$00

;2D
tblPOWBuildingHELPText:
	db $03 ;Number of sprites
	db $F8,$5F,$02,$F4
	db $F8,$61,$02,$FC
	db $F8,$63,$02,$04

;2E
tblPowerUpStar:	
	db $02 ;Number of sprites
	db $F8,$39,$00,$F8
	db $F8,$39,$40,$00

;2F
tblHelicopterOnHelipad1:
	db $04 ;Number of sprites
	db $F0,$6B,$00,$F8
	db $00,$6D,$00,$F8
	db $F0,$6B,$40,$00
	db $00,$6D,$40,$00

;30
tblHelicopterOnHelipad2:
	db $06 ;Number of sprites
	db $F0,$1D,$00,$F0
	db $F0,$6F,$00,$F8
	db $00,$71,$00,$F8
	db $F0,$6F,$40,$00
	db $00,$71,$40,$00
	db $F0,$1D,$40,$08

;31
tblHelicopterInAir1:
	db $06 ;Number of sprites
	db $F0,$17,$00,$F4
	db $00,$19,$00,$F4
	db $F0,$73,$00,$FC
	db $00,$75,$00,$FC
	db $F0,$17,$40,$04
	db $00,$19,$40,$04

;32
tblHelicopterInAir2:
	db $05 ;Number of sprites
	db $F0,$1B,$00,$F4
	db $F0,$77,$00,$FC
	db $00,$79,$00,$FC
	db $F0,$1B,$40,$04
	db $00,$41,$00,$04

;3A
tblLevel1AttackBoatWake1:
	db $07 ;Number of sprites
	db $00,$A7,$00,$F0
	db $F0,$A9,$00,$F8
	db $00,$AB,$00,$F8
	db $F0,$AD,$00,$00
	db $00,$AF,$00,$00
	db $F0,$B1,$00,$08
	db $00,$B3,$00,$08

;3B
tblLevel1AttackBoatWake2:
	db $07 ;Number of sprites
	db $00,$A7,$00,$F0
	db $F0,$A9,$00,$F8
	db $00,$AB,$00,$F8
	db $F0,$AD,$00,$00
	db $00,$B5,$00,$00
	db $F0,$B7,$00,$08
	db $00,$B9,$00,$08

;33
tblLevel1BossTankRight_Left:
	db $06 ;Number of sprites
	db $F4,$CF,$00,$F4
	db $04,$D1,$00,$F4
	db $F4,$D3,$00,$FC
	db $04,$D5,$00,$FC
	db $F4,$D7,$00,$04
	db $04,$D9,$00,$04

;34
tblLevel1BossTankDiagonal:
	db $06 ;Number of sprites
	db $F8,$E1,$00,$F0
	db $F0,$E3,$00,$F8
	db $00,$E5,$00,$F8
	db $F0,$E7,$00,$00
	db $00,$9F,$00,$00
	db $F8,$A1,$00,$08

;35
tblLevel1BossTankUp_Down:
	db $06 ;Number of sprites
	db $F0,$BD,$80,$F4
	db $00,$BB,$80,$F4
	db $F0,$C1,$80,$FC
	db $00,$BF,$80,$FC
	db $F0,$BD,$C0,$04
	db $00,$BB,$C0,$04

;39
tblLevel1BossTankDiagonalUpsideDown:
	db $06 ;Number of sprites
	db $F8,$C3,$00,$F0
	db $F0,$C5,$00,$F8
	db $00,$C7,$00,$F8
	db $F0,$C9,$00,$00
	db $00,$CB,$00,$00
	db $F8,$CD,$00,$08

;36
tblLevel1BossTankRight_LeftRecoil:
	db $06 ;Number of sprites
	db $F4,$CF,$00,$F4
	db $04,$D1,$00,$F4
	db $F4,$D3,$00,$FC
	db $04,$D5,$00,$FC
	db $F4,$DF,$00,$04
	db $04,$D9,$00,$04
	
;37
tblLevel1BossTankDiagonalRecoil:
	db $06 ;Number of sprites
	db $F8,$E1,$00,$F0
	db $F0,$E3,$00,$F8
	db $00,$E5,$00,$F8
	db $F0,$E7,$00,$00
	db $00,$A3,$00,$00
	db $F8,$A5,$00,$08

;38
tblLevel1BossTankUp_DownRecoil:
	db $06 ;Number of sprites
	db $F0,$BD,$80,$F4
	db $00,$BB,$80,$F4
	db $F0,$C1,$80,$FC
	db $00,$DB,$80,$FC
	db $F0,$BD,$C0,$04
	db $00,$BB,$C0,$04

;3C
tblLevel1BossTankDiagonalUpsideDownRecoil:
	db $06 ;Number of sprites
	db $F8,$C3,$00,$F0
	db $F0,$C5,$00,$F8
	db $00,$C7,$00,$F8
	db $F0,$DD,$00,$00
	db $00,$CB,$00,$00
	db $F8,$CD,$00,$08

;3D
tblEnemyJeepRight_Left:	
	db $03 ;Number of sprites
	db $F8,$AD,$02,$F4
	db $F8,$13,$02,$FC
	db $F8,$15,$02,$04

;3E
tblEnemyJeepDiagonal:
	db $05 ;Number of sprites
	db $F0,$A9,$82,$F4
	db $00,$07,$82,$F4
	db $F0,$AB,$82,$FC
	db $00,$0B,$82,$FC
	db $FC,$0F,$82,$04

;3F
tblEnemyJeepUp_Down:
	db $04 ;Number of sprites
	db $F0,$A7,$82,$F8
	db $00,$03,$82,$F8
	db $F0,$A7,$C2,$00
	db $00,$03,$C2,$00

;40 and 43
tblPlane_JeepBombUpLeftSmall:
	db $01 ;Number of sprites
	db $F8,$B7,$01,$FC

;41 and 42
tblPlane_JeepBombDownRightLarge:
	db $02 ;Number of sprites
	db $F8,$B9,$01,$F8
	db $F8,$BB,$01,$00

;44
tblSilverLargeTank_FlameTankRightLeft:	
	db $06 ;Number of sprites
	db $F0,$D3,$00,$F4
	db $00,$D5,$00,$F4
	db $F0,$D7,$00,$FC
	db $00,$D9,$00,$FC
	db $F0,$DB,$00,$04
	db $00,$DD,$00,$04
	
;45
tblSilverLargeTank_FlameTankDiagonal:
	db $06 ;Number of sprites
	db $F8,$C7,$80,$F0
	db $F0,$CB,$80,$F8
	db $00,$C9,$80,$F8
	db $F0,$CF,$80,$00
	db $00,$CD,$80,$00
	db $F8,$D1,$80,$08

;46
tblSilverLargeTankUpDown:
	db $06 ;Number of sprites
	db $F0,$C1,$80,$F4
	db $00,$BF,$80,$F4
	db $F0,$C5,$80,$FC
	db $00,$C3,$80,$FC
	db $F0,$C1,$C0,$04
	db $00,$BF,$C0,$04

;47
tblBrokenPillarFallingDiagonal:
	db $04 ;Number of sprites
	db $F8,$DF,$01,$F4
	db $F4,$E1,$01,$FC
	db $04,$E3,$01,$FC
	db $F4,$E5,$01,$04

;48
tblBrokenPillarRollingRightLeft:
	db $03 ;Number of sprites
	db $F8,$E7,$01,$F4
	db $F8,$E9,$01,$FC
	db $F8,$ED,$01,$04

;49
tblBrokenPillarRollingRightLeft2:
	db $03 ;Number of sprites
	db $F8,$E7,$81,$F4
	db $F8,$E9,$81,$FC
	db $F8,$ED,$81,$04

;4A
tblBlackShell:
	db $01 ;Number of sprites
	db $F8,$BD,$02,$FC

;4B
tblSmallMissileLeftRight:
	db $02 ;Number of sprites
	db $F8,$A1,$00,$F8
	db $F8,$A3,$00,$00

;4C
tblSmallMissileDiagonal:
	db $02 ;Number of sprites
	db $F8,$9F,$80,$F8
	db $F8,$A5,$80,$00

;4D
tblSmallMissileUpDown:
	db $01 ;Number of sprites
	db $F8,$EB,$80,$FC

;4E
tblBomberPlaneWithShadow:
	db $06 ;Number of sprites
	db $F8,$AF,$81,$F0
	db $F0,$B3,$81,$F8
	db $00,$B1,$81,$F8
	db $F0,$B3,$C1,$00
	db $00,$B1,$C1,$00
	db $F3,$B5,$81,$08	

;4F
tblBomberPlane:
	db $06 ;Number of sprites
	db $F8,$AF,$81,$F0
	db $F0,$B3,$81,$F8
	db $00,$B1,$81,$F8
	db $F0,$B3,$C1,$00
	db $00,$B1,$C1,$00
	db $F8,$AF,$C1,$08

;50
tblSpreadTurretHidden:
	db $02 ;Number of sprites
	db $F8,$A7,$00,$F8
	db $F8,$A9,$00,$00

;51
tblSpreadTurretRising1:
	db $02 ;Number of sprites
	db $F8,$AB,$00,$F8
	db $F8,$AD,$00,$00

;52
tblSpreadTurretRising2:
	db $02 ;Number of sprites
	db $F8,$ED,$00,$F8
	db $F8,$EF,$00,$00

;53
tblSpreadTurretUp:
	db $02 ;Number of sprites
	db $F8,$BF,$00,$F8
	db $F8,$BF,$40,$00

;54
tblInfantryTruck:
	db $08 ;Number of sprites
	db $F2,$B1,$01,$F0
	db $02,$B3,$01,$F0
	db $F2,$B5,$01,$F8
	db $02,$B3,$01,$F8
	db $F2,$B7,$01,$00
	db $02,$B9,$01,$00
	db $F2,$E5,$01,$08
	db $02,$F7,$01,$08

;55
tblInfantryTruckWithDoorOpen:
	db $08 ;Number of sprites
	db $F2,$BB,$01,$F0
	db $02,$B3,$01,$F0
	db $F2,$B5,$01,$F8
	db $02,$B3,$01,$F8
	db $F2,$B7,$01,$00
	db $02,$B9,$01,$00
	db $F2,$E5,$01,$08
	db $02,$F7,$01,$08

;56
tblLevel3LargeAttackBoatWake1:
	db $06 ;Number of sprites
	db $E8,$BD,$02,$F8
	db $F8,$AF,$02,$F8
	db $08,$C1,$02,$F8
	db $E8,$BD,$42,$00
	db $F8,$C3,$02,$00
	db $08,$C5,$02,$00

;57
tblLevel3LargeAttackBoatWake2:
	db $06 ;Number of sprites
	db $E8,$C7,$02,$F8
	db $F8,$C9,$02,$F8
	db $08,$CB,$02,$F8
	db $E8,$C7,$42,$00
	db $F8,$CD,$02,$00
	db $08,$CF,$02,$00

;58
tblSubmarineRising1:
	db $02 ;Number of sprites
	db $FB,$D1,$02,$F8
	db $FB,$E3,$02,$00

;59
tblSubmarineRising2:
	db $04 ;Number of sprites
	db $F0,$D3,$02,$F8
	db $00,$D5,$02,$F8
	db $F0,$D7,$02,$00
	db $00,$D9,$02,$00

;5A
tblSubmarineUp:
	db $04 ;Number of sprites
	db $F0,$DB,$02,$F8
	db $00,$DD,$02,$F8
	db $F0,$DF,$02,$00
	db $00,$E1,$02,$00

;5B
tblSubmarineRising1WithShadow:	
	db $06 ;Number of sprites
	db $E0,$F3,$02,$F8
	db $E0,$F3,$42,$00
	db $FB,$D1,$02,$F8
	db $FB,$E3,$02,$00
	db $10,$F3,$82,$F8
	db $10,$F3,$C2,$00

;5C
tblSubmarineRising2WithShadow:
	db $08 ;Number of sprites
	db $E0,$F3,$02,$F8
	db $E0,$F3,$42,$00
	db $F0,$D3,$02,$F8
	db $00,$D5,$02,$F8
	db $F0,$D7,$02,$00
	db $00,$D9,$02,$00
	db $10,$F3,$82,$F8
	db $10,$F3,$C2,$00

;5D
tblSubmarineUpWithShadow:
	db $08 ;Number of sprites
	db $E0,$F3,$02,$F8
	db $E0,$F3,$42,$00
	db $F0,$DB,$02,$F8
	db $00,$DD,$02,$F8
	db $F0,$DF,$02,$00
	db $00,$E1,$02,$00
	db $10,$F3,$82,$F8
	db $10,$F3,$C2,$00

;5E
tblSubmarineShadowOnly:
	db $08 ;Number of sprites
	db $E0,$F3,$02,$F8
	db $E0,$F3,$42,$00
	db $F0,$F5,$02,$F8
	db $F0,$F5,$42,$00
	db $00,$F5,$02,$F8
	db $00,$F5,$42,$00
	db $10,$F3,$82,$F8
	db $10,$F3,$C2,$00

;5F
tblLevel3LaserBeamLong:
	db $06 ;Number of sprites
	db $D0,$E7,$00,$FC
	db $E0,$E7,$00,$FC
	db $F0,$E7,$00,$FC
	db $00,$E7,$00,$FC
	db $10,$E7,$00,$FC
	db $20,$E7,$00,$FC

;60
tblLevel3LaserBeamShort:
	db $05 ;Number of sprites
	db $D8,$E7,$00,$FC
	db $E8,$E7,$00,$FC
	db $F8,$E7,$00,$FC
	db $08,$E7,$00,$FC
	db $18,$E7,$00,$FC

;61
tblLevel3LaserChargingFlash1:
	db $02 ;Number of sprites
	db $F7,$F9,$00,$F0
	db $F7,$F9,$40,$08

;62
tblLevel3LaserChargingFlash2:
	db $02 ;Number of sprites
	db $F7,$FB,$00,$F8
	db $F7,$FB,$40,$00

;64
tblSpreadBossTurretRising1:
	db $02 ;Number of sprites
	db $F8,$E9,$00,$F8
	db $F8,$E9,$40,$00

;65
tblSpreadBossTurretRising2:
	db $02 ;Number of sprites
	db $F8,$FD,$00,$F8
	db $F8,$FD,$40,$00

;66
tblSpreadBossTurretUp:
	db $02 ;Number of sprites
	db $F8,$BF,$00,$F8
	db $F8,$BF,$40,$00

;67
tblSpreadTruck:
	db $05 ;Number of sprites
	db $F0,$CF,$01,$F4
	db $00,$A9,$01,$F4
	db $F0,$AB,$01,$FC
	db $00,$AD,$01,$FC
	db $F8,$AF,$01,$04

;68
tblSpreadTruckFiring:
	db $05 ;Number of sprites
	db $F0,$B1,$01,$F4
	db $00,$A9,$01,$F4
	db $F0,$B3,$01,$FC
	db $00,$AD,$01,$FC
	db $F8,$AF,$01,$04

;69
tblLevel4CliffMissileLauncher:
	db $06 ;Number of sprites
	db $F0,$DB,$02,$F4
	db $00,$DD,$02,$F4
	db $F0,$DF,$02,$FC
	db $00,$E1,$02,$FC
	db $F0,$DB,$42,$04
	db $00,$DD,$42,$04

;6A
tblLevel4CliffMissileLauncherMissileEmerging:
	db $06 ;Number of sprites
	db $F0,$DB,$02,$F4
	db $00,$DD,$02,$F4
	db $F0,$DF,$02,$FC
	db $00,$E3,$02,$FC
	db $F0,$DB,$42,$04
	db $00,$DD,$42,$04

;6B
tbl6B_UNKNOWN:
	db $06 ;Number of sprites
	db $F0,$DB,$02,$F4
	db $00,$DD,$02,$FC
	db $F0,$D1,$42,$04
	db $00,$9F,$02,$F4
	db $F0,$DB,$02,$FC
	db $F0,$DD,$02,$F4

;6C
tblSubmergedMissileLauncher:
	db $01 ;Number of sprites
	db $F8,$D5,$00,$FE

;6D
tblSubmergedMissileLauncherOpening:	
	db $01 ;Number of sprites
	db $F8,$B5,$00,$FC

;6E
tblSubmergedMissileLauncherSplash:
	db $02 ;Number of sprites
	db $F8,$B7,$00,$F8
	db $F8,$B9,$00,$00

;6F
tblSubmergedMissileLauncherMissileEmerging:
	db $02 ;Number of sprites
	db $F8,$BB,$00,$F8
	db $F8,$BF,$00,$00

;70
tblBlackAndWhiteMissileRight_Left:
	db $02 ;Number of sprites
	db $F8,$C7,$02,$F8
	db $F8,$C9,$02,$00

;71
tblBlackAndWhiteMissileDiagonal:
	db $02 ;Number of sprites
	db $F8,$C3,$82,$F8
	db $F8,$C5,$82,$00

;72
tblBlackAndWhiteMissileUp_Down:
	db $01 ;Number of sprites
	db $F8,$C1,$82,$FC

;73
tblHiddenMineVisible:
	db $01 ;Number of sprites
	db $F8,$A7,$00,$FC

;74
tblSwampInfantryLeft_Right1:
	db $01
	db $F8,$F7,$00,$FC

;75
tblSwampInfantryDown1:
	db $01
	db $F8,$FB,$00,$FC

;76
tblSwampInfantryUp1:
	db $01
	db $F8,$F5,$00,$FC

;77
tblSwampInfantryLeft_Right2:
	db $01
	db $F8,$F9,$00,$FC

;78
tblSwampInfantryDown2:
	db $01
	db $F8,$FD,$00,$FD

;79
tblSwampInfantryUp2:
	db $01
	db $F8,$F3,$00,$FD

;7A
tblLevel1Chinook:	
	db $22 ;Number of sprites
	db $D8,$D1,$00,$E0
	db $D8,$D3,$00,$E8
	db $F0,$D9,$00,$E8
	db $00,$DF,$00,$E8
	db $18,$E9,$00,$E8
	db $D0,$CD,$00,$F0
	db $E0,$D5,$00,$F0
	db $F0,$DB,$00,$F0
	db $00,$E1,$00,$F0
	db $10,$E5,$00,$F0
	db $20,$EB,$00,$F0
	db $C0,$CB,$00,$F8
	db $D0,$CF,$00,$F8
	db $E0,$D7,$00,$F8
	db $F0,$DD,$00,$F8
	db $00,$E3,$00,$F8
	db $10,$E7,$00,$F8
	db $C0,$CB,$40,$00
	db $D0,$CF,$40,$00
	db $E0,$D7,$40,$00
	db $F0,$DD,$40,$00
	db $00,$E3,$40,$00
	db $10,$E7,$40,$00
	db $D0,$CD,$40,$08
	db $E0,$D5,$40,$08
	db $F0,$DB,$40,$08
	db $00,$E1,$40,$08
	db $10,$E5,$40,$08
	db $20,$EB,$40,$08
	db $D8,$D3,$40,$10
	db $F0,$D9,$40,$10
	db $00,$DF,$40,$10
	db $18,$E9,$40,$10
	db $D8,$D1,$40,$18

;7B
tblLevel1ChinookBladesRotated:
	db $22 ;Number of sprites
	db $08,$D1,$00,$E0
	db $C8,$E9,$80,$E8
	db $E8,$E9,$00,$E8
	db $F8,$F9,$00,$E8
	db $08,$FB,$00,$E8
	db $C0,$EB,$80,$F0
	db $D0,$ED,$00,$F0
	db $E0,$F1,$00,$F0
	db $F0,$F5,$00,$F0
	db $00,$FD,$00,$F0
	db $10,$FC,$00,$F0
	db $D0,$EF,$00,$F8
	db $E0,$F3,$00,$F8
	db $F0,$F7,$00,$F8
	db $00,$FA,$00,$F8
	db $10,$FE,$00,$F8
	db $20,$CB,$80,$F8
	db $D0,$EF,$40,$00
	db $E0,$F3,$40,$00
	db $F0,$F7,$40,$00
	db $00,$FA,$40,$00
	db $10,$FE,$40,$00
	db $20,$CB,$C0,$00
	db $C0,$EB,$C0,$08
	db $D0,$ED,$40,$08
	db $E0,$F1,$40,$08
	db $F0,$F5,$40,$08
	db $00,$FD,$40,$08
	db $10,$FC,$40,$08
	db $C8,$E9,$C0,$10
	db $E8,$E9,$40,$10
	db $F8,$F9,$40,$10
	db $08,$FB,$40,$10
	db $08,$D1,$40,$18

;7C
tblLevel4FallingRockResting:
	db $02
	db $F8,$CB,$01,$F8
	db $F8,$CD,$01,$00

;7D
tblLevel4FallingRockFallen
	db $02
	db $F8,$D7,$01,$F8
	db $F8,$D9,$01,$00

;7E
tblLevel4BossHelicopterBladesCardinal:
	db $10 ;Number of sprites
	db $F8,$9F,$00,$EC
	db $E8,$A1,$00,$F4
	db $F8,$A3,$00,$F4
	db $08,$A5,$00,$F4
	db $E8,$A7,$00,$FC
	db $F8,$A9,$00,$FC
	db $08,$AB,$00,$FC
	db $E8,$A1,$40,$04
	db $F8,$A3,$40,$04
	db $08,$A5,$40,$04
	db $F8,$9F,$40,$0C
	db $08,$AD,$00,$0C
	db $C8,$D3,$00,$F4
	db $C8,$D5,$00,$FC
	db $C8,$D3,$40,$04
	db $D8,$D7,$00,$FC

;7F
tblLevel4BossHelicopterBladesDiagonal:
	db $13 ;Number of sprites
	db $E8,$AF,$00,$EC
	db $F8,$B1,$00,$EC
	db $08,$B3,$00,$EC
	db $E8,$B5,$00,$F4
	db $F8,$B7,$00,$F4
	db $08,$B9,$00,$F4
	db $E8,$BB,$00,$FC
	db $F8,$BD,$00,$FC
	db $08,$BF,$00,$FC
	db $E8,$B5,$40,$04
	db $F8,$B7,$40,$04
	db $08,$B9,$40,$04
	db $E8,$AF,$40,$0C
	db $F8,$B1,$40,$0C
	db $08,$B3,$40,$0C
	db $C8,$D3,$00,$F4
	db $C8,$D9,$00,$FC
	db $C8,$D3,$40,$04
	db $D8,$D7,$00,$FC

	
	;********************
	;All sprite IDs >=$80
	;********************
tblSpriteConstructionHeaderAddress2:
	dw tblNullObject2 ;80 EMPTY sprite
	dw Level5MountedTurretReceeded 	;81
	dw Level5MountedTurretOpening1 	;82
	dw Level5MountedTurretOpening2 	;83
	dw Level5MountedTurretOpen 		;84
	dw Level5MountedTurretRecoil 		;85
	dw FlameThrowerLeft_Right1 		;86
	dw FlameThrowerLeft_Right2 		;87
	dw FlameThrowerLeft_Right3 		;88
	dw FlameThrowerLeft_Right4 		;89
	dw FlameThrowerDiagonal1 		;8A
	dw FlameThrowerDiagonal2 		;8B
	dw FlameThrowerDiagonal3 		;8C
	dw FlameThrowerDiagonal4 		;8D
	dw FlameThrowerUp_Down1 			;8E
	dw FlameThrowerUp_Down2 			;8F
	dw FlameThrowerUp_Down3 			;90
	dw FlameThrowerUp_Down4 			;91
	dw FlameThrowerHittingGround 		;92
	
	dw tblNullObject2 ;93 Level 5 Boss Gate Electricy 1 (no graphic - null sprite)
	
	dw Level5BossGateElectricity2 ;94
	dw Level5BossGateElectricity3 ;95
	dw Level5BossGateElectricity4 ;96
	dw Level5BossGateElectricity5 ;97
	dw Level5BossGateElectricity6 ;98
	dw Level5BossGateElectricity7 ;99
	dw Level5BossGateElectricity8 ;9A
	dw Level6AttackHelicopter_DiagonalBlades ;9B
	dw Level6AttackHelicopter_CardinalBlades ;9C
	dw Level6AttackHelicopterDiagonal_DiagonalBlades ;9D
	dw Level6AttackHelicopterDiagonal_CardinalBlades ;9E
	dw Level6MissileLauncherClosed 	;9F
	dw Level6MissileLauncherOpen 		;A0
	dw Level6SpreadTurretClosed 		;A1
	dw Level6SpreadTurretOpening1 	;A2
	dw Level6SpreadTurretOpening2 	;A3
	dw Level6SpreadTurretOpen 		;A4
	dw Level4TrainEngine1 			;A5
	dw Level4TrainEngine2 			;A6
	dw Level4TrainEngine3 			;A7
	dw Level4TrainCar1 				;A8
	dw Level4TrainCar2 				;A9
	dw Level4TrainCar3 				;AA
	dw Level4BossParatrooper4 		;AB
	dw Level4BossParatrooper1 		;AC
	dw Level4BossParatrooper2 		;AD
	dw Level4BossParatrooper3 		;AE
	dw AF_UNKNOWN 					;AF
	dw LevelSegueGameMapDiagram 		;B0
	dw B1_UNKNOWN 					;B1
	dw LevelSegueLittleJeep 			;B2
	dw LevelSegueYEAHGraphics 		;B3
	dw B4_UNKNOWN 					;B4
	dw Level6EnemyJeepLeft_Right 		;B5
	dw Level6EnemyJeepDiagonal 		;B6
	dw Level6EnemyJeepUp_Down 		;B7
	dw LevelSeguePOWWaving 			;B8
	dw LevelSeguePOWWaving2 			;B9
	dw EndofGameTinyHeliInDistance1 	;BA
	dw EndofGameTinyHeliInDistance2 	;BB
	dw EndofGameSmallHeliInDistance1 	;BC
	dw EndofGameSmallHeliInDistance2 	;BD
	dw EndofGameMediumHeliInDistance1 ;BE
	dw EndofGameMediumHeliInDistance2 ;BF
	dw EndofGameLargeHeliInDistance1 	;C0
	dw EndofGameLargeHeliInDistance2 	;C1
	dw EndofGameVeryLargeHeliInDistance1 ;C2
	dw EndofGameVeryLargeHeliInDistance2 ;C3
	dw EndofGameSunsetShimmering1 	;C4
	dw EndofGameSunsetShimmering2 	;C5
	dw EndofGameSunsetShimmering3 	;C6
	dw EndofGameSunsetShimmering4		;C7
	dw EndofGameGraphics 			;C8
	
	dw LevelSegueWeMadeItTextGraphics 	;C9
	dw LevelSegueYEAHGraphics2 		;CA
	
	dw Level6BossLaserTurretDiagonal 	;CB
	dw Level6BossLaserTurretDown 		;CC
	dw Level6BossLaserTurretDiagonalFlash ;CD
	dw Level6BossLaserTurretDownFlash ;CE
	dw Level6BossLaserTurretBlastDiagonal ;CF
	dw BlastExplosionsMakingHoles1 	;D0
	dw BlastExplosionsMakingHoles2 	;D1
	dw Level6BossLaserTurretDestroyed 	;D2
	dw Level6FinalBossTank 			;D3
	dw D4_UNKNOWN 					;D4
	dw Level6FinalBossTankFlameShot1 	;D5
	dw Level6FinalBossTankFlameShot2 	;D6
	dw Level6FinalBossTankFlameShot3 	;D7
	dw Level6FinalBossTankFlameShot4 	;D8
	dw Level6FinalBossTankFlameShot5 	;D9
	dw Level6FinalBossTankFlameShot6 	;DA
	dw Level6FinalBossTankFlameShot7 	;DB
	dw Level6FinalBossTankFlameShot8 	;DC
	dw Level6FinalBossTankFlameShot9 	;DD
	dw Level6FinalBossTankFlameShot10 	;DE
	dw Level6FinalBossTankFlameShot11 	;DF
	dw Level6FinalBossTankFlameShot12 	;E0
	dw Level6FinalBossTankFlameShot13 	;E1
	dw Level6FinalBossTankFlameShot14 	;E2
	dw Level6FinalBossTankFlameShot15 	;E3
	dw Level6FinalBossTankFlameShot16 	;E4
	dw Level6FinalBossTankFlameShot1Mirrored 	;E5
	dw Level6FinalBossTankFlameShot2Mirrored 	;E6
	dw Level6FinalBossTankFlameShot3Mirrored 	;E7
	dw Level6FinalBossTankFlameShot4Mirrored 	;E8
	dw Level6FinalBossTankFlameShot5Mirrored 	;E9
	dw Level6FinalBossTankFlameShot6Mirrored 	;EA
	dw Level6FinalBossTankFlameShot7Mirrored 	;EB
	dw Level6FinalBossTankFlameShot8Mirrored 	;EC
	dw Level6FinalBossTankFlameShot9Mirrored 	;ED
	dw Level6FinalBossTankFlameShot10Mirrored 	;EE
	dw Level6FinalBossTankFlameShot11Mirrored 	;EF
	dw Level6FinalBossTankFlameShot12Mirrored 	;F0
	dw Level6FinalBossTankFlameShot13Mirrored 	;F1
	dw Level6FinalBossTankFlameShot14Mirrored 	;F2
	dw Level6FinalBossTankFlameShot15Mirrored 	;F3
	dw Level6FinalBossTankFlameShot16Mirrored 	;F4
	dw Level6FinalBossTankTurretDiagonal 		;F5 NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;F6 NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;F7 NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;F8 NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;F9 NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;FA NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;FB NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;FC NOT USED!!
	dw Level6FinalBossTankTurretDiagonal 		;FD
	dw Level6FinalBossTankTurretUp_Down 		;FE
	dw Level5BossShutterDoorOpen 				;FF
	
	
	;****************
	;Sprite Rendering
	;The following data mimics the OADDMA structure:
	;(Y,Table ID,Attributes,X)
	;However, the X,Y coordinates are offsets from the anchor of the sprite
	;***********************

;80
tblNullObject2:	
	db $00 ;Number of sprites

;81
Level5MountedTurretReceeded:	
	db $03 ;Number of sprites
	db $F8,$ED,$02,$F4
	db $F8,$EF,$02,$FC
	db $F8,$ED,$42,$04

;82
Level5MountedTurretOpening1:
	db $03 ;Number of sprites
	db $F8,$F1,$02,$F4
	db $F8,$F3,$02,$FC
	db $F8,$F1,$42,$04

;83
Level5MountedTurretOpening2:
	db $03 ;Number of sprites
	db $F8,$F5,$02,$F4
	db $F8,$9F,$02,$FC
	db $F8,$F5,$42,$04

;84
Level5MountedTurretOpen:
	db $03 ;Number of sprites
	db $F8,$A1,$02,$F4
	db $F6,$A3,$02,$FC
	db $F8,$A1,$42,$04

;85
Level5MountedTurretRecoil:
	db $03 ;Number of sprites
	db $F8,$A1,$02,$F4
	db $F6,$A5,$02,$FC
	db $F8,$A1,$42,$04

;86
FlameThrowerLeft_Right1:
	db $02 ;Number of sprites
	db $F8,$E3,$03,$F8
	db $F8,$E5,$03,$00

;87
FlameThrowerLeft_Right2:
	db $04 ;Number of sprites
	db $F8,$E3,$83,$E8
	db $F8,$E7,$03,$F0
	db $F8,$E7,$83,$F8
	db $F8,$E5,$83,$00

;88
FlameThrowerLeft_Right3:
	db $04 ;Number of sprites
	db $F8,$E3,$43,$E8
	db $F8,$E7,$43,$F0
	db $F8,$E7,$C3,$F8
	db $F8,$E5,$43,$00

;89
FlameThrowerLeft_Right4:
	db $02 ;Number of sprites
	db $F8,$E5,$C3,$F8
	db $F8,$E3,$C3,$00

;8A
FlameThrowerDiagonal1:
	db $01 ;Number of sprites
	db $F8,$E9,$43,$FC

;8B
FlameThrowerDiagonal2:
	db $03 ;Number of sprites
	db $E8,$E1,$43,$EC
	db $F0,$DF,$43,$F4
	db $F8,$E9,$43,$FC

;8C
FlameThrowerDiagonal3:
	db $03 ;Number of sprites
	db $E8,$E9,$83,$EC
	db $F0,$DF,$83,$F4
	db $F8,$E1,$83,$FC

;8D
FlameThrowerDiagonal4:
	db $01 ;Number of sprites
	db $F8,$E9,$83,$FC

;8E
FlameThrowerUp_Down1:
	db $01 ;Number of sprites
	db $F8,$A9,$03,$FC

;8F
FlameThrowerUp_Down2:
	db $02 ;Number of sprites
	db $E8,$AB,$03,$FC
	db $F8,$AD,$03,$FC

;90
FlameThrowerUp_Down3:
	db $02 ;Number of sprites
	db $E8,$AD,$C3,$FC
	db $F8,$AB,$C3,$FC

;91
FlameThrowerUp_Down4:
	db $01 ;Number of sprites
	db $F8,$A9,$C3,$FC

;92
FlameThrowerHittingGround:
	db $01 ;Number of sprites
	db $F8,$EB,$03,$FC

;94
Level5BossGateElectricity2:
	db $02 ;Number of sprites
	db $F0,$F9,$00,$E0
	db $00,$F9,$40,$18

;95
Level5BossGateElectricity3:
	db $08 ;Number of sprites
	db $F0,$FB,$00,$E0
	db $F0,$F7,$00,$E8
	db $F0,$F7,$40,$10
	db $F0,$FB,$40,$18
	db $00,$FB,$00,$E0
	db $00,$F7,$00,$E8
	db $00,$F7,$40,$10
	db $00,$FB,$40,$18

;96
Level5BossGateElectricity4:
	db $0C ;Number of sprites
	db $F0,$F7,$40,$E0
	db $F0,$F9,$00,$E8
	db $F0,$FB,$40,$F0
	db $F0,$FB,$00,$08
	db $F0,$F9,$40,$10
	db $F0,$F7,$00,$18
	db $00,$F7,$40,$E0
	db $00,$F9,$00,$E8
	db $00,$FB,$40,$F0
	db $00,$FB,$00,$08
	db $00,$F9,$40,$10
	db $00,$F7,$00,$18

;97
Level5BossGateElectricity5:
	db $10 ;Number of sprites
	db $F0,$F9,$C0,$E0
	db $F0,$F7,$80,$E8
	db $F0,$F7,$40,$F0
	db $F0,$FD,$00,$F8
	db $F0,$FD,$C0,$00
	db $F0,$F7,$00,$08
	db $F0,$F7,$C0,$10
	db $F0,$F9,$C0,$18
	db $00,$F9,$C0,$E0
	db $00,$F7,$80,$E8
	db $00,$F7,$40,$F0
	db $00,$FD,$00,$F8
	db $00,$FD,$C0,$00
	db $00,$F7,$00,$08
	db $00,$F7,$C0,$10
	db $00,$F9,$C0,$18

;98
Level5BossGateElectricity6:
	db $0C ;Number of sprites
	db $F0,$F7,$40,$E8
	db $F0,$FB,$40,$F0
	db $F0,$F9,$80,$F8
	db $F0,$F9,$C0,$00
	db $F0,$FB,$00,$08
	db $F0,$F7,$00,$10
	db $00,$F7,$40,$E8
	db $00,$FB,$40,$F0
	db $00,$F9,$80,$F8
	db $00,$F9,$C0,$00
	db $00,$FB,$00,$08
	db $00,$F7,$00,$10

;99
Level5BossGateElectricity7:
	db $08 ;Number of sprites
	db $F0,$F9,$00,$F0
	db $F0,$F7,$40,$F8
	db $F0,$F7,$00,$00
	db $F0,$F9,$40,$08
	db $00,$F9,$00,$F0
	db $00,$F7,$40,$F8
	db $00,$F7,$00,$00
	db $00,$F9,$40,$08

;9A
Level5BossGateElectricity8:
	db $04 ;Number of sprites
	db $F0,$F7,$00,$F8
	db $F0,$F9,$00,$00
	db $00,$F7,$00,$F8
	db $00,$F9,$00,$00

;9B
Level6AttackHelicopter_DiagonalBlades:
	db $06 ;Number of sprites
	db $F0,$F1,$01,$F4
	db $00,$F7,$01,$F4
	db $F0,$E7,$01,$FC
	db $00,$E9,$01,$FC
	db $F0,$F1,$41,$04
	db $00,$F7,$41,$04

;9C
Level6AttackHelicopter_CardinalBlades:
	db $05 ;Number of sprites
	db $F0,$EB,$01,$F4
	db $F0,$ED,$01,$FC
	db $00,$D3,$01,$FC
	db $F0,$EB,$41,$04
	db $00,$D5,$01,$04

;9D
Level6AttackHelicopterDiagonal_DiagonalBlades:
	db $05 ;Number of sprites
	db $F0,$D7,$01,$F4
	db $00,$D9,$01,$F4
	db $F8,$DB,$01,$FC
	db $F0,$DD,$01,$04
	db $00,$DF,$01,$04

;9E
Level6AttackHelicopterDiagonal_CardinalBlades:
	db $06 ;Number of sprites
	db $F0,$E1,$01,$F4
	db $00,$E3,$01,$F4
	db $F0,$E5,$01,$FC
	db $00,$EF,$01,$FC
	db $F0,$F3,$01,$04
	db $00,$F5,$01,$04

;9F
Level6MissileLauncherClosed:
	db $03 ;Number of sprites
	db $F8,$CB,$02,$F4
	db $F8,$CD,$02,$FC
	db $F8,$CB,$42,$04

;A0
Level6MissileLauncherOpen:
	db $03 ;Number of sprites
	db $F8,$CF,$02,$F4
	db $F8,$A9,$02,$FC
	db $F8,$CF,$42,$04

;A1
Level6SpreadTurretClosed:
	db $02 ;Number of sprites
	db $F8,$A7,$00,$F8
	db $F8,$A7,$40,$00

;A2
Level6SpreadTurretOpening1:
	db $02 ;Number of sprites
	db $F8,$AB,$00,$F8
	db $F8,$AB,$40,$00

;A3
Level6SpreadTurretOpening2:
	db $02 ;Number of sprites
	db $F8,$D1,$00,$F8
	db $F8,$D1,$40,$00

;A4
Level6SpreadTurretOpen:
	db $02 ;Number of sprites
	db $F8,$BF,$00,$F8
	db $F8,$BF,$40,$00

;A5
Level4TrainEngine1:
	db $04 ;Number of sprites
	db $F0,$D3,$02,$F8
	db $00,$A1,$02,$F8
	db $F0,$D3,$42,$00
	db $00,$A1,$42,$00

;A6
Level4TrainEngine2: ;Half invisible, going through tunnel
	db $04 ;Number of sprites
	db $F0,$D3,$22,$F8
	db $00,$A1,$02,$F8
	db $F0,$D3,$62,$00
	db $00,$A1,$42,$00

;A7
Level4TrainEngine3: ;Fully behind BG layer, going through tunnel
	db $04 ;Number of sprites
	db $F0,$D3,$22,$F8
	db $00,$A1,$22,$F8
	db $F0,$D3,$62,$00
	db $00,$A1,$62,$00

;A8
Level4TrainCar1:
	db $04 ;Number of sprites
	db $F0,$A3,$01,$F8
	db $00,$A5,$01,$F8
	db $F0,$A3,$41,$00
	db $00,$A5,$41,$00

;A9
Level4TrainCar2: ;Half invisible, going through tunnel
	db $04 ;Number of sprites
	db $F0,$A3,$21,$F8
	db $00,$A5,$01,$F8
	db $F0,$A3,$61,$00
	db $00,$A5,$41,$00

;AA
Level4TrainCar3: ;Fully behind BG layer, going through tunnel
	db $04 ;Number of sprites
	db $F0,$A3,$21,$F8
	db $00,$A5,$21,$F8
	db $F0,$A3,$61,$00
	db $00,$A5,$61,$00

;AB
Level4BossParatrooper4:
	db $01 ;Number of sprites
	db $F8,$C1,$00,$FC

;AC
Level4BossParatrooper1:
	db $02
	db $F8,$C3,$00,$F8
	db $F8,$C5,$00,$00

;AD
Level4BossParatrooper2:
	db $04
	db $F0,$C7,$00,$F8
	db $00,$C9,$00,$F8
	db $F0,$CB,$00,$00
	db $00,$CD,$00,$00

;AE
Level4BossParatrooper3:
	db $02
	db $F8,$CF,$00,$F8
	db $F8,$D1,$00,$00

;AF
AF_UNKNOWN:
	db $01 ;Number of sprites
	db $F8,$D3,$00,$FC

;B4
Level6EnemyJeepLeft_Right:	
	db $03 ;Number of sprites
	db $F8,$FD,$02,$F4
	db $F8,$13,$02,$FC
	db $F8,$15,$02,$04

;B6
Level6EnemyJeepDiagonal:
	db $05 ;Number of sprites
	db $F0,$F9,$82,$F4
	db $00,$07,$82,$F4
	db $F0,$FB,$82,$FC
	db $00,$0B,$82,$FC
	db $FB,$0F,$82,$04

;B7
Level6EnemyJeepUp_Down:
	db $04 ;Number of sprites
	db $F0,$AD,$82,$F8
	db $00,$03,$82,$F8
	db $F0,$AD,$C2,$00
	db $00,$03,$C2,$00

;B0
LevelSegueGameMapDiagram:
	db $24 ;Number of sprites
	db $90,$33,$03,$E8
	db $60,$33,$83,$E8
	db $90,$35,$03,$F0
	db $C0,$03,$00,$F0
	db $D0,$05,$00,$F0
	db $00,$13,$01,$F0
	db $10,$15,$01,$F0
	db $40,$23,$02,$F0
	db $50,$25,$02,$F0
	db $60,$35,$83,$F0
	db $90,$35,$03,$F8
	db $C0,$07,$00,$F8
	db $D0,$09,$00,$F8
	db $00,$17,$01,$F8
	db $10,$19,$01,$F8
	db $40,$27,$02,$F8
	db $50,$29,$02,$F8
	db $60,$35,$83,$F8
	db $90,$35,$03,$00
	db $C0,$0B,$00,$00
	db $D0,$0D,$00,$00
	db $00,$1B,$01,$00
	db $10,$1D,$01,$00
	db $40,$2B,$02,$00
	db $50,$2D,$02,$00
	db $60,$35,$83,$00
	db $90,$35,$03,$08
	db $C0,$0F,$00,$08
	db $D0,$11,$00,$08
	db $00,$1F,$01,$08
	db $10,$21,$01,$08
	db $40,$2F,$02,$08
	db $50,$31,$02,$08
	db $60,$35,$83,$08
	db $90,$33,$43,$10
	db $60,$33,$C3,$10
	
B1_UNKNOWN:
	db $01 ;Number of sprites
	db $FC,$3B,$03,$FC

;B2
LevelSegueLittleJeep:
	db $02 ;Number of sprites
	db $FC,$37,$03,$F8
	db $FC,$39,$03,$00

;B3
LevelSegueYEAHGraphics:
	db $20 ;Number of sprites
	db $00,$47,$03,$90
	db $10,$91,$03,$90
	db $00,$93,$03,$98
	db $10,$95,$03,$98
	db $00,$55,$03,$A0
	db $10,$5D,$03,$A0
	db $00,$41,$03,$A8
	db $10,$43,$03,$A8
	db $E0,$49,$01,$C0
	db $F0,$4B,$01,$C0
	db $E0,$4F,$01,$C8
	db $F0,$51,$01,$C8
	db $D0,$53,$02,$D0
	db $F0,$57,$02,$D0
	db $C0,$59,$02,$D8
	db $D0,$5B,$02,$D8
	db $F0,$5F,$02,$D8
	db $B0,$65,$03,$E0
	db $D0,$77,$00,$E0
	db $E0,$79,$01,$E0
	db $D0,$7B,$00,$E8
	db $E0,$7D,$01,$E8
	db $E0,$7F,$01,$F0
	db $D8,$45,$01,$F8
	db $F0,$81,$02,$28
	db $E8,$83,$02,$30
	db $F8,$85,$02,$30
	db $E8,$87,$02,$38
	db $F8,$89,$01,$38
	db $E0,$8D,$03,$40
	db $F8,$8B,$01,$40
	db $D8,$8F,$03,$48

;B4
B4_UNKNOWN:
	db $04 ;Number of sprites
	db $B0,$67,$02,$E0
	db $F8,$97,$02,$F0
	db $F8,$61,$02,$F8
	db $F8,$63,$02,$08
	
;Garbage data
	db $F8,$4D,$02,$10

;B8
LevelSeguePOWWaving:
	db $02 ;Number of sprites
	db $FC,$99,$03,$F8
	db $FC,$3F,$03,$00

;B9
LevelSeguePOWWaving2:
	db $02 ;Number of sprites
	db $FC,$3D,$03,$F8
	db $FC,$3F,$03,$00

;C9
LevelSegueWeMadeItTextGraphics:
	db $06 ;Number of sprites
	db $FC,$9B,$03,$E8
	db $FC,$9D,$03,$F0
	db $FC,$9F,$03,$F8
	db $FC,$A1,$03,$00
	db $FC,$A3,$03,$08
	db $FC,$A5,$03,$10

;CA
LevelSegueYEAHGraphics2:
	db $05 ;Number of sprites
	db $FC,$A7,$03,$EC
	db $FC,$A9,$03,$F4
	db $FC,$AB,$03,$FC
	db $FC,$AD,$03,$04
	db $FC,$AF,$03,$0C

;BA
EndofGameTinyHeliInDistance1:
	db $01 ;Number of sprites
	db $F8,$1B,$00,$FC

;BB
EndofGameTinyHeliInDistance2:
	db $01 ;Number of sprites
	db $F8,$1D,$00,$FC

;BC
EndofGameSmallHeliInDistance1:
	db $02 ;Number of sprites
	db $F8,$1F,$00,$F8
	db $F8,$21,$00,$00

;BD
EndofGameSmallHeliInDistance2:
	db $02 ;Number of sprites
	db $F8,$23,$00,$F8
	db $F8,$25,$00,$00

;BE
EndofGameMediumHeliInDistance1:
	db $04 ;Number of sprites
	db $F8,$27,$00,$F0
	db $F8,$29,$00,$F8
	db $F8,$2B,$00,$00
	db $F8,$2D,$00,$08

;BF
EndofGameMediumHeliInDistance2:
	db $02 ;Number of sprites
	db $F8,$2F,$00,$F8
	db $F8,$31,$00,$00

;C0
EndofGameLargeHeliInDistance1:
	db $06 ;Number of sprites
	db $F0,$33,$00,$F0
	db $F0,$35,$00,$F8
	db $F0,$37,$00,$00
	db $F0,$39,$00,$08
	db $00,$3B,$00,$F8
	db $00,$3D,$00,$00

;C1
EndofGameLargeHeliInDistance2:
	db $04 ;Number of sprites
	db $F0,$3F,$00,$F8
	db $F0,$41,$00,$00
	db $00,$43,$00,$F8
	db $00,$45,$00,$00

;C2
EndofGameVeryLargeHeliInDistance1:
	db $09 ;Number of sprites
	db $F0,$47,$00,$E8
	db $F0,$49,$00,$F0
	db $F0,$4B,$00,$F8
	db $F0,$4D,$00,$00
	db $F0,$4F,$00,$08
	db $F0,$51,$00,$10
	db $00,$53,$00,$F0
	db $00,$55,$00,$F8
	db $00,$57,$00,$00

;C3
EndofGameVeryLargeHeliInDistance2:
	db $05 ;Number of sprites
	db $F8,$5D,$00,$F0
	db $F0,$59,$00,$F8
	db $F0,$5B,$00,$00
	db $00,$5F,$00,$F8
	db $00,$61,$00,$00

;C4
EndofGameSunsetShimmering1:
	db $10 ;Number of sprites
	db $E0,$63,$01,$F0
	db $E0,$65,$01,$F8
	db $E0,$67,$01,$00
	db $E0,$69,$01,$08
	db $F0,$6B,$01,$E8
	db $F0,$6D,$01,$F0
	db $F0,$6F,$01,$F8
	db $F0,$6F,$01,$00
	db $F0,$71,$01,$08
	db $F0,$73,$01,$10
	db $00,$75,$01,$E8
	db $00,$77,$01,$F0
	db $00,$79,$01,$F8
	db $00,$77,$01,$00
	db $00,$79,$01,$08
	db $00,$7B,$01,$10

;C5
EndofGameSunsetShimmering2:
	db $10 ;Number of sprites
	db $E0,$7D,$01,$F0
	db $E0,$7F,$01,$F8
	db $E0,$81,$01,$00
	db $E0,$83,$01,$08
	db $F0,$85,$01,$E8
	db $F0,$87,$01,$F0
	db $F0,$6F,$01,$F8
	db $F0,$6F,$01,$00
	db $F0,$89,$01,$08
	db $F0,$8B,$01,$10
	db $00,$75,$01,$E8
	db $00,$77,$01,$F0
	db $00,$79,$01,$F8
	db $00,$77,$01,$00
	db $00,$79,$01,$08
	db $00,$7B,$01,$10

;C6
EndofGameSunsetShimmering3:
	db $10 ;Number of sprites
	db $E0,$7D,$01,$F0
	db $E0,$7F,$01,$F8
	db $E0,$81,$01,$00
	db $E0,$83,$01,$08
	db $F0,$85,$01,$E8
	db $F0,$87,$01,$F0
	db $F0,$6F,$01,$F8
	db $F0,$6F,$01,$00
	db $F0,$89,$01,$08
	db $F0,$8B,$01,$10
	db $00,$8D,$01,$E8
	db $00,$79,$01,$F0
	db $00,$77,$01,$F8
	db $00,$79,$01,$00
	db $00,$77,$01,$08
	db $00,$8F,$01,$10

;C7
EndofGameSunsetShimmering4:
	db $10 ;Number of sprites
	db $E0,$63,$01,$F0
	db $E0,$65,$01,$F8
	db $E0,$67,$01,$00
	db $E0,$69,$01,$08
	db $F0,$6B,$01,$E8
	db $F0,$6D,$01,$F0
	db $F0,$6F,$01,$F8
	db $F0,$6F,$01,$00
	db $F0,$71,$01,$08
	db $F0,$73,$01,$10
	db $00,$8D,$01,$E8
	db $00,$79,$01,$F0
	db $00,$77,$01,$F8
	db $00,$79,$01,$00
	db $00,$77,$01,$08
	db $00,$8F,$01,$10

;C8
EndofGameGraphics:
	db $0C ;Number of sprites
	db $E0,$03,$02,$F0
	db $E0,$05,$02,$F8
	db $E0,$07,$02,$00
	db $F0,$09,$02,$F0
	db $F0,$0B,$02,$F8
	db $F0,$0D,$02,$00
	db $00,$0F,$02,$F0
	db $00,$11,$02,$F8
	db $00,$13,$02,$00
	db $10,$15,$02,$F0
	db $10,$17,$02,$F8
	db $10,$19,$02,$00

;CB
Level6BossLaserTurretDiagonal:	
	db $06 ;Number of sprites
	db $F0,$A7,$02,$F4
	db $00,$A9,$02,$F4
	db $F0,$AB,$02,$FC
	db $00,$AD,$02,$FC
	db $F0,$AF,$02,$04
	db $00,$B1,$02,$04

;CC
Level6BossLaserTurretDown:
	db $06 ;Number of sprites
	db $F0,$9F,$02,$F4
	db $00,$A1,$02,$F4
	db $F0,$A3,$02,$FC
	db $00,$A5,$02,$FC
	db $F0,$9F,$42,$04
	db $00,$A1,$42,$04

;CD
Level6BossLaserTurretDiagonalFlash:
	db $07 ;Number of sprites
	db $F0,$A7,$02,$F4
	db $00,$A9,$02,$F4
	db $F0,$B7,$02,$FC
	db $00,$B9,$02,$FC
	db $F0,$CB,$02,$04
	db $00,$CD,$02,$04
	db $FE,$B3,$03,$FE

;CE
Level6BossLaserTurretDownFlash:
	db $07 ;Number of sprites
	db $F0,$9F,$02,$F4
	db $00,$A1,$02,$F4
	db $F0,$A3,$02,$FC
	db $00,$B5,$03,$FC
	db $F0,$9F,$42,$04
	db $00,$A1,$42,$04
	db $00,$B3,$03,$FC

;CF
Level6BossLaserTurretBlastDiagonal:
	db $01 ;Number of sprites
	db $F8,$BD,$03,$FC

;D0
BlastExplosionsMakingHoles1:
	db $01 ;Number of sprites
	db $F8,$BB,$03,$FC

;D1
BlastExplosionsMakingHoles2:
	db $04 ;Number of sprites
	db $00,$CF,$01,$E8
	db $08,$CF,$01,$F8
	db $08,$CF,$01,$00
	db $00,$CF,$01,$10

;D2
Level6BossLaserTurretDestroyed:
	db $06 ;Number of sprites
	db $F0,$BF,$02,$F4
	db $00,$C1,$02,$F4
	db $F0,$C3,$02,$FC
	db $00,$C5,$02,$FC
	db $F0,$C7,$02,$04
	db $00,$C9,$02,$04

;D3
Level6FinalBossTank:
	db $01 ;Number of sprites
	db $15,$BD,$02,$F8

;D4
D4_UNKNOWN:
	db $01 ;Number of sprites
	db $15,$BF,$02,$F8

;D5
Level6FinalBossTankFlameShot1:
	db $01 ;Number of sprites
	db $F8,$9F,$03,$FC

;D6
Level6FinalBossTankFlameShot2:
	db $03 ;Number of sprites
	db $F0,$A1,$03,$F8
	db $F0,$A1,$43,$00
	db $00,$9F,$03,$FC

;D7
Level6FinalBossTankFlameShot3:
	db $07 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$A3,$83,$F4
	db $F8,$A7,$03,$FC
	db $00,$A3,$C3,$04
	db $08,$9F,$03,$FC

;D8
Level6FinalBossTankFlameShot4:
	db $09 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $F8,$A1,$03,$F4
	db $00,$A9,$03,$FC
	db $F8,$A1,$43,$04
	db $08,$A3,$83,$F4
	db $10,$9F,$03,$FC
	db $08,$A3,$C3,$04

;D9
Level6FinalBossTankFlameShot5:
	db $0A ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$A3,$83,$F4
	db $08,$A7,$03,$FC
	db $10,$A3,$C3,$04
	db $18,$9F,$03,$FC

;DA
Level6FinalBossTankFlameShot6:
	db $0C ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $08,$A1,$03,$F4
	db $10,$A9,$03,$FC
	db $08,$A1,$43,$04
	db $18,$A3,$83,$F4
	db $20,$9F,$03,$FC
	db $18,$A3,$C3,$04

;DB
Level6FinalBossTankFlameShot7:
	db $0D ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$A3,$83,$F4
	db $18,$A7,$03,$FC
	db $20,$A3,$C3,$04
	db $28,$9F,$03,$FC

;DC
Level6FinalBossTankFlameShot8:
	db $0F ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $18,$A1,$03,$F4
	db $20,$A9,$03,$FC
	db $18,$A1,$43,$04
	db $28,$A3,$83,$F4
	db $30,$9F,$03,$FC
	db $28,$A3,$C3,$04

;DD
Level6FinalBossTankFlameShot9:
	db $10 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $30,$A3,$83,$F4
	db $28,$A7,$03,$FC
	db $30,$A3,$C3,$04
	db $38,$9F,$03,$FC

;DE
Level6FinalBossTankFlameShot10:
	db $12 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $28,$A1,$03,$F4
	db $30,$A9,$03,$FC
	db $28,$A1,$43,$04
	db $38,$A3,$83,$F4
	db $40,$9F,$03,$FC
	db $38,$A3,$C3,$04

;DF
Level6FinalBossTankFlameShot11:
	db $13 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $30,$AB,$03,$F4
	db $30,$AD,$03,$FC
	db $30,$AB,$43,$04
	db $40,$A3,$83,$F4
	db $38,$A7,$03,$FC
	db $40,$A3,$C3,$04
	db $48,$9F,$03,$FC

;E0
Level6FinalBossTankFlameShot12:
	db $15 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $30,$AB,$03,$F4
	db $30,$AD,$03,$FC
	db $30,$AB,$43,$04
	db $38,$A1,$03,$F4
	db $40,$A9,$03,$FC
	db $38,$A1,$43,$04
	db $48,$A3,$83,$F4
	db $50,$9F,$03,$FC
	db $48,$A3,$C3,$04

;E1
Level6FinalBossTankFlameShot13:
	db $16 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $30,$AB,$03,$F4
	db $30,$AD,$03,$FC
	db $30,$AB,$43,$04
	db $40,$AB,$03,$F4
	db $40,$AD,$03,$FC
	db $40,$AB,$43,$04
	db $50,$A3,$83,$F4
	db $48,$A7,$03,$FC
	db $50,$A3,$C3,$04
	db $58,$9F,$03,$FC

;E2
Level6FinalBossTankFlameShot14:
	db $18 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $30,$AB,$03,$F4
	db $30,$AD,$03,$FC
	db $30,$AB,$43,$04
	db $40,$AB,$03,$F4
	db $40,$AD,$03,$FC
	db $40,$AB,$43,$04
	db $48,$A1,$03,$F4
	db $50,$A9,$03,$FC
	db $48,$A1,$43,$04
	db $58,$A3,$83,$F4
	db $60,$9F,$03,$FC
	db $58,$A3,$C3,$04

;E3
Level6FinalBossTankFlameShot15:
	db $19 ;Number of sprites
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $30,$AB,$03,$F4
	db $30,$AD,$03,$FC
	db $30,$AB,$43,$04
	db $40,$AB,$03,$F4
	db $40,$AD,$03,$FC
	db $40,$AB,$43,$04
	db $50,$AB,$03,$F4
	db $50,$AD,$03,$FC
	db $50,$AB,$43,$04
	db $60,$A3,$83,$F4
	db $58,$A7,$03,$FC
	db $60,$A3,$C3,$04
	db $68,$9F,$03,$FC

;E4
Level6FinalBossTankFlameShot16:
	db $1A ;Number of sprites
	db $E8,$9F,$83,$FC
	db $F0,$A3,$03,$F4
	db $F0,$A5,$03,$FC
	db $F0,$A3,$43,$04
	db $00,$AB,$03,$F4
	db $00,$AD,$03,$FC
	db $00,$AB,$43,$04
	db $10,$AB,$03,$F4
	db $10,$AD,$03,$FC
	db $10,$AB,$43,$04
	db $20,$AB,$03,$F4
	db $20,$AD,$03,$FC
	db $20,$AB,$43,$04
	db $30,$AB,$03,$F4
	db $30,$AD,$03,$FC
	db $30,$AB,$43,$04
	db $40,$AB,$03,$F4
	db $40,$AD,$03,$FC
	db $40,$AB,$43,$04
	db $50,$AB,$03,$F4
	db $50,$AD,$03,$FC
	db $50,$AB,$43,$04
	db $60,$A3,$83,$F4
	db $58,$A7,$03,$FC
	db $60,$A3,$C3,$04
	db $68,$9F,$03,$FC

;E5
Level6FinalBossTankFlameShot1Mirrored:
	db $01 ;Number of sprites
	db $F8,$9F,$43,$FC

;E6
Level6FinalBossTankFlameShot2Mirrored:
	db $03 ;Number of sprites
	db $F0,$AF,$03,$F8
	db $F0,$AF,$43,$00
	db $00,$9F,$43,$FC

;E7
Level6FinalBossTankFlameShot3Mirrored:
	db $07 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B1,$83,$F4
	db $F8,$B5,$03,$FC
	db $00,$B1,$C3,$04
	db $08,$9F,$43,$FC

;E8
Level6FinalBossTankFlameShot4Mirrored:
	db $09 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $F8,$AF,$03,$F4
	db $00,$B7,$03,$FC
	db $F8,$AF,$43,$04
	db $08,$B1,$83,$F4
	db $10,$9F,$43,$FC
	db $08,$B1,$C3,$04

;E9
Level6FinalBossTankFlameShot5Mirrored:
	db $0A ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B1,$83,$F4
	db $08,$B5,$03,$FC
	db $10,$B1,$C3,$04
	db $18,$9F,$43,$FC

;EA
Level6FinalBossTankFlameShot6Mirrored:
	db $0C ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $08,$AF,$03,$F4
	db $10,$B7,$03,$FC
	db $08,$AF,$43,$04
	db $18,$B1,$83,$F4
	db $20,$9F,$43,$FC
	db $18,$B1,$C3,$04

;EB
Level6FinalBossTankFlameShot7Mirrored:
	db $0D ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B1,$83,$F4
	db $18,$B5,$03,$FC
	db $20,$B1,$C3,$04
	db $28,$9F,$43,$FC

;EC
Level6FinalBossTankFlameShot8Mirrored:
	db $0F ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $18,$AF,$03,$F4
	db $20,$B7,$03,$FC
	db $18,$AF,$43,$04
	db $28,$B1,$83,$F4
	db $30,$9F,$43,$FC
	db $28,$B1,$C3,$04

;ED
Level6FinalBossTankFlameShot9Mirrored:
	db $10 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $30,$B1,$83,$F4
	db $28,$B5,$03,$FC
	db $30,$B1,$C3,$04
	db $38,$9F,$43,$FC

;EE
Level6FinalBossTankFlameShot10Mirrored:
	db $12 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $28,$AF,$03,$F4
	db $30,$B7,$03,$FC
	db $28,$AF,$43,$04
	db $38,$B1,$83,$F4
	db $40,$9F,$43,$FC
	db $38,$B1,$C3,$04

;EF
Level6FinalBossTankFlameShot11Mirrored:
	db $13 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $30,$B9,$03,$F4
	db $30,$BB,$03,$FC
	db $30,$B9,$43,$04
	db $40,$B1,$83,$F4
	db $38,$B5,$03,$FC
	db $40,$B1,$C3,$04
	db $48,$9F,$43,$FC

;F0
Level6FinalBossTankFlameShot12Mirrored:
	db $15 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $30,$B9,$03,$F4
	db $30,$BB,$03,$FC
	db $30,$B9,$43,$04
	db $38,$AF,$03,$F4
	db $40,$B7,$03,$FC
	db $38,$AF,$43,$04
	db $48,$B1,$83,$F4
	db $50,$9F,$43,$FC
	db $48,$B1,$C3,$04

;F1
Level6FinalBossTankFlameShot13Mirrored:
	db $16 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $30,$B9,$03,$F4
	db $30,$BB,$03,$FC
	db $30,$B9,$43,$04
	db $40,$B9,$03,$F4
	db $40,$BB,$03,$FC
	db $40,$B9,$43,$04
	db $50,$B1,$83,$F4
	db $48,$B5,$03,$FC
	db $50,$B1,$C3,$04
	db $58,$9F,$43,$FC

;F2
Level6FinalBossTankFlameShot14Mirrored:
	db $18 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $30,$B9,$03,$F4
	db $30,$BB,$03,$FC
	db $30,$B9,$43,$04
	db $40,$B9,$03,$F4
	db $40,$BB,$03,$FC
	db $40,$B9,$43,$04
	db $48,$AF,$03,$F4
	db $50,$B7,$03,$FC
	db $48,$AF,$43,$04
	db $58,$B1,$83,$F4
	db $60,$9F,$43,$FC
	db $58,$B1,$C3,$04

;F3
Level6FinalBossTankFlameShot15Mirrored:
	db $19 ;Number of sprites
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $30,$B9,$03,$F4
	db $30,$BB,$03,$FC
	db $30,$B9,$43,$04
	db $40,$B9,$03,$F4
	db $40,$BB,$03,$FC
	db $40,$B9,$43,$04
	db $50,$B9,$03,$F4
	db $50,$BB,$03,$FC
	db $50,$B9,$43,$04
	db $60,$B1,$83,$F4
	db $58,$B5,$03,$FC
	db $60,$B1,$C3,$04
	db $68,$9F,$43,$FC

;F4
Level6FinalBossTankFlameShot16Mirrored:
	db $1A ;Number of sprites
	db $E8,$9F,$C3,$FC
	db $F0,$B1,$03,$F4
	db $F0,$B3,$03,$FC
	db $F0,$B1,$43,$04
	db $00,$B9,$03,$F4
	db $00,$BB,$03,$FC
	db $00,$B9,$43,$04
	db $10,$B9,$03,$F4
	db $10,$BB,$03,$FC
	db $10,$B9,$43,$04
	db $20,$B9,$03,$F4
	db $20,$BB,$03,$FC
	db $20,$B9,$43,$04
	db $30,$B9,$03,$F4
	db $30,$BB,$03,$FC
	db $30,$B9,$43,$04
	db $40,$B9,$03,$F4
	db $40,$BB,$03,$FC
	db $40,$B9,$43,$04
	db $50,$B9,$03,$F4
	db $50,$BB,$03,$FC
	db $50,$B9,$43,$04
	db $60,$B1,$83,$F4
	db $58,$B5,$03,$FC
	db $60,$B1,$C3,$04
	db $68,$9F,$43,$FC

;FD
Level6FinalBossTankTurretDiagonal:
	db $05 ;Number of sprites
	db $F6,$D1,$80,$F3
	db $F3,$CD,$80,$FB
	db $03,$CF,$80,$FB
	db $F9,$CB,$80,$00
	db $FF,$C9,$80,$06

;FE
Level6FinalBossTankTurretUp_Down:
	db $04 ;Number of sprites
	db $F4,$C1,$00,$F9
	db $04,$C5,$00,$F9
	db $F4,$C3,$00,$01
	db $04,$C7,$00,$01

;FF
Level5BossShutterDoorOpen:
	db $01 ;Number of sprites
	db $FF,$01,$01,$FC	
	
	
	.PAD $9B37
tblLevelSegue_BGGraphics:
	db $00,$00 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $9DB4
tblLevelSegue_SpriteGraphics:
	db $10,$00 ;PPU Address
	;RLE COMPRESSED DATA
		
		
	.PAD $A61B
tblEndOfGameBGGraphics
	db $00,$00 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $B24F
tblEndOfGameSpriteGraphics:
	db $10,$00 ;PPU Address
	;RLE COMPRESSED DATA
	
	
	.PAD $B6E5
tblLevel6FinalBossTankGraphicsUpdate:
	db $01	 ;ROM Bank
	db $04,$40 ;PPU Address
	db $EC,$B6 ;ROM Address ($B6EC)
	db $05,$30 ;Total byte count ($530)
	;UNCOMPRESSED DATA
		
	
	.PAD $BC20
	;FREE SPACE TO THE END OF THE BANK


	.PAD $C000