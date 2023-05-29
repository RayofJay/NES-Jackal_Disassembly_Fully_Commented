;Bank 6
	.BASE $8000	
;***********************
;BLACK AND WHITE MISSILE - Also handles the small rockets from the statue heads
;
; SpriteData1 - Count down to direction change
; SpriteData2 - Initial direction change countdown value (forces the projectile to travle straight for X frames)
; SpriteData3 - Number of turns that equals a full circle
; SpriteData4 - Projectile lifetime, as a count of direction turns
; SpriteData5 - Missile type, e.g. Black and White ($70), or small missile ($4B)
; SpriteData6 - Determines the missile flight parameters in the 4 tables below
; SpriteData8 - Tracks the number of travel path turns ($20 for a full circle)
; All sprites that explode use SpriteData8 for the timer
;***********************
;***********************

	;Bank Table
	db $00,$01,$02,$03,$04,$05,$06,$07
	
BlackAndWhite_SmallMissileSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw BlackAndWhiteMissileState0
	dw BlackAndWhiteMissileState1
	dw BlackAndWhiteMissileState2
	dw subSpriteDeath
	dw subSpriteExplosion

BlackAndWhiteMissileState0: ;Spawn
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
	LDA #$02
	STA SpriteGraphicsAttributes,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpriteForDirectionChange
	JSR subUpdateSpritePositionForScrolling
	LDY SpriteData6,X
	LDA tblBlackAndWhiteMissileTurningRadius,Y ;How many frames to check for direction change/turn
	STA SpriteData2,X
	LDA tblBlackAndWhiteMissileInitialTurningRadius,Y ;How many frames to go straight before turning
	STA SpriteData1,X
	LDA #$1F ;this could be hard coded instead of using SpriteData3
	STA SpriteData3,X
	LDA tblBlackAndWhiteMissileLifetime,Y
	STA SpriteData4,X
	LDA #$00
	STA SpriteData8,X
	LDA tblBlackAndWhiteMissileSpeedMultiplier,Y
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JSR subCheckWhichJeepToAttack
	JMP subMoveSpriteToNextState

;Index:
;0 is Straight small missile from normal status head (explodes after a time)
;1 is Homing small missile from Level 2 boss statue head
;2 is submerged launcher, cliff launcher, L6 launcher bay
;3 is submarine missile.  never detonates (goes off screen to despawn)
tblBlackAndWhiteMissileSpeedMultiplier:
	db $40,$30,$40,$70 ;LB speed multiplier
tblBlackAndWhiteMissileTurningRadius:
	db $10,$0C,$06,$10
tblBlackAndWhiteMissileInitialTurningRadius:
	db $38,$0C,$10,$00
tblBlackAndWhiteMissileLifetime:
	db $01,$28,$40,$01

BlackAndWhiteMissileState1: ;Fly towards jeep
	JSR subCountDownForJeepTargetBy1
	DEC SpriteData1,X
	BNE +++
	INC SpriteData8,X
	LDA SpriteData8,X
	AND SpriteData3,X ;see if the missile traveled a full circle
	BNE +
	DEC SpriteData2,X ;Decreases the flight radius every full circle of travel
+:	LDA SpriteData2,X
	STA SpriteData1,X
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	
	;Calculate which way to turn to attack jeep
	JSR subCalculateDirectionTowardJeep
	SEC
	SBC SpriteWhatDirectionToShoot,X
	STA $00
	BEQ ++
	LDA $00
	AND #$10
	BNE +
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC #$01
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
	JMP ++
+:	LDA SpriteWhatDirectionToShoot,X
	SEC
	SBC #$01
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
	
	;Adjust sprite type based on the direction the missile is pointing
++:	LDA SpriteData5,X
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpriteForDirectionChange ;Updates SpriteTypeIndex
	
	LDY SpriteData6,X
	LDA tblBlackAndWhiteMissileSpeedMultiplier,Y
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
+++:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	CMP SpriteData4,X ;Check for missile end of life
	BNE +
	LDA #$10 ;explosion timer
	STA SpriteData1,X
	LDA #$74 ;player cannot harm missile since it is dead, but the explosion can still kill you
	STA SpriteHitboxShapeIndex,X
	LDA #$03 ;use the yellow/red palette
	STA SpriteGraphicsAttributes,X
	LDA #$19 ;1st explosion animation
	STA SpriteTypeIndex,X
	JSR subClearSpriteSpeed
	LDA #BlackAndWhiteMissile_Bomb_LaserBlastHitsGroundSoundClip ;also pillar breaking Level2
	JSR subInitiateSoundClip
	JMP subMoveSpriteToNextState
+:	RTS

BlackAndWhiteMissileState2: ;Explosion animation
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	;a critical check is missing here to see if the object was despawned off screen or otherwise
	DEC SpriteData1,X
	LDA SpriteData1,X
	BEQ ++
	AND #$07 ;increment explosion every 8 frames
	BNE +
	INC SpriteTypeIndex,X
+:	RTS
++:	JMP subDespawnSprite

;***************
;RED MEDIUM TANK
;
; SpriteData1 - Counts down the number of frames to move
; SpriteData2 - used to count down the frames between firing bullets
; SpriteData3 - The default timing for # of frames between firing bullets
; SpriteData4 - Turn Left or Right depending on sprite slot index, when collision with other sprites is detected
; SpriteData5 - Mask for stationary frame count
; SpriteData6 - The base sprite render index.  The logic here is used by all the tank types
; SpriteData8 - Counts down the number of frames to be stationary
;***************
;***************
RedMediumTankSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw RedMediumTankState0
	dw RedMediumTankState1
	dw RedMediumTankState2
	dw RedMediumTankState3
	dw subSpriteDeath
	dw subSpriteExplosion

RedMediumTankState0:
	LDA #$22
	STA SpriteTypeIndex,X
	STA SpriteData6,X
	LDA #$20
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$1F
	STA SpriteData5,X
Label315:
	JSR subCheckWhichJeepToAttack
	JSR subCalculateDirectionTowardJeep
	JSR subUpdateSpriteForDirectionChange
	TYA
	ASL
	ASL
	STA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpritePositionForScrolling
Label299:
	LDY #$04
	TXA
	AND #$01
	BEQ +
	LDY #$FC
+:	TYA
	STA SpriteData4,X
	JMP subMoveSpriteToNextState

RedMediumTankState1:
	JSR Label228
	BCS +
	;Tank stationary/turning
	RTS
+:	LDA #$50
	STA SpriteData1,X
	LDA #$12 ;speed multiplier
lblCalculateTank_JeepSpeed:
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState
	
RedMediumTankState2:	
	JSR subTurnTankTowardsJeep
	LDA #$12
lblCalculateTank_JeepSpeed_CheckforCollision:
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA $D7
	BEQ +
	RTS
+:	JMP subMoveSpriteToNextState

;Both normal tanks and Level 5 boss tanks use this state logic
RedMediumTankState3:
	JSR Label232
	LDA $D7
	BNE ++
	DEC SpriteData2,X
	BNE +
	LDA SpriteData3,X
	STA SpriteData2,X
	LDA SpriteState,X
	BMI + ;RTS - Don't spawn a bullet if the tank is off screen
	LDY #$01
	JMP SpawnEnemyRoundBullet_Shell
+:	RTS
++:	LDA #$01
	LDY SpriteObjectID,X
	CPY #$07 ;Normal red tank (not level 5 boss tank)
	BEQ +
	LDA #$02
+:	JMP subSetSpriteState

Label228:	;check if tank/jeep needs to turn
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	JSR subCalculateDirectionTowardJeep
	SEC
	SBC SpriteWhatDirectionToShoot,X
	STA $00
	BNE ++
	JSR fctGetCollision_WithSpeed_NearLookAhead_BG
	BEQ +
++:	DEC SpriteData8,X
	LDA SpriteData8,X
	AND SpriteData5,X
	BNE ++++
	LDA $00
	AND #$10
	BNE +++
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC #$04
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
	JMP + ;bpl would work here because A AND #$1F is always >= 0
+++:	LDA SpriteWhatDirectionToShoot,X
	SEC
	SBC #$04
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
+:	JSR ++
	SEC
	RTS
++++	JSR ++
	CLC
	RTS
++:	LDA SpriteData6,X
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpriteForDirectionChange
	JMP Label244
	
subTurnTankTowardsJeep: ;turn tank towards jeep
	LDA SpriteData6,X
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpriteForDirectionChange
	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	BNE ++
	JSR Label247
	BCC +
	LDA #$01
	STA $D7
++:	JSR subClearSpriteSpeed
+:	JSR Label244
	LDA $D7
	BEQ +
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND SpriteData5,X
	BNE +
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC SpriteData4,X
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
+:	RTS

Label232:
	DEC SpriteData1,X
	BEQ +++
	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	BNE +
	JSR Label247
	BCC ++
+++:	LDA #$01
	STA $D7
+:	JSR subClearSpriteSpeed
++:	JMP Label244

;***************
;MOBILE INFANTRY
;
; SpriteData1 - Tracks target position to walk towards around jeep.  0=right of jeep, 2=beneath jeep, 4=left of jeep, 6=above jeep
; SpriteData2 - 01 = clockwise, FF = counter clockwise
; SpriteData3 - Horizontal LB position to walk towards
; SpriteData4 - Horizontal UB position to walk towards
; SpriteData5 - Vertical LB position to walk towards
; SpriteData6 - Vertical UB position to walk towards
; SpriteData8 - Timer for walking animation, flashing, firing, etc
;***************
MobileInfantrySpriteLogic:
	LDA SpriteState,X ;01 Mobile Infantry code
	AND #$7F
	JSR subExecuteCodeViaIndirectJump ;this JSR has no RTS.  The next address is pulled into A and used to read the data that follows as an address
	
	dw MobileInfantryState0
	dw MobileInfantryState1
	dw MobileInfantryState2
	dw MobileInfantryState3
	dw MobileInfantryState4
	dw MobileInfantryState5
	dw MobileInfantryState6
	dw subInfantryDeath
	dw subInfantryDeathAnimation

MobileInfantryState0: ;Spawn
	LDA #$12
	STA SpriteTypeIndex,X
	LDA #$01
	STA SpriteGraphicsAttributes,X
	LDA RNG_INCEveryFrame
	AND #$07
	STA SpriteData1,X
	LDY #$01
	AND #$01
	BEQ +
	LDY #$FF
+:	TYA
	STA SpriteData2,X
	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

MobileInfantryState1:
	JSR Label244
	JSR Label254
	LDA DifficultyBasedOnWeapon
	CLC
	ADC CurrentLevel
	LSR
	TAY
	LDA tblMobileInfantryInitialMeanderingTimerValue,Y
	STA SpriteData8,X
	JMP subMoveSpriteToNextState
	
tblMobileInfantryInitialMeanderingTimerValue:
	db $00,$C0,$80,$40,$20,$10
	
MobileInfantryState2:
	LDA #$12
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	JSR fctGetCollision_WithSpeed_NearLookAhead_BG
Label543:
	BEQ Label256
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC SpriteData2,X
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
	JSR subClearSpriteSpeed
Label256:	JSR Label244
	LDA $D7
	BEQ Label257
	LDA #$01
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JMP subCalculateObjectSpeed
Label257:	JMP subMoveSpriteToNextState

MobileInfantryState3:
MobileInfantryState4:
	LDA #$12
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	LDA SpriteData8,X
	AND #$08
	BEQ +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	LDA #$01
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JSR fctGetCollision_WithSpeed_NearLookAhead_BG
Label547:	BEQ +
	JSR subClearSpriteSpeed
+:	JSR Label244
	DEC SpriteData8,X
	BNE ++
-:	LDA #$80
	STA SpriteData8,X
	LDA SpriteState,X
	AND #$7F
	CMP #$04
	BNE +
	LDA #$40
	STA SpriteData8,X
	JSR subClearSpriteSpeed
+:	JMP subMoveSpriteToNextState
++:	LDA $D7
	BEQ +
	LDA #$01
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA #$02
	JMP subSetSpriteState
+:	LDA SpriteData8,X
	LSR
	BEQ ++ ;RTS
	LDA SpriteData3,X
	CMP SpriteAbsoluteHorizPositionLB,X
	BNE +
	LDA SpriteData4,X
	CMP SpriteAbsoluteHorizPositionUB,X
	BNE +
	LDA SpriteWhatDirectionToShoot,X
	AND #$0F
	BEQ -
	LDA SpriteWhatDirectionToShoot,X
	AND #$10
	ORA #$08
	STA SpriteWhatDirectionToShoot,X
+:	LDA SpriteData5,X
	CMP SpriteVertScreenPosition,X
	BNE ++ ;RTS
	LDA SpriteData6,X
	CMP SpriteAbsoluteVertPositionUB,X
	BNE ++ ;RTS
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC #$08
	STA $00
	AND #$0F
	BEQ -
	LDA $00
	AND #$10
	STA SpriteWhatDirectionToShoot,X
++:	RTS

MobileInfantryState5:
	LDA #$12
	STA SpriteTypeIndex,X
Label550:	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	JSR Label244
	DEC SpriteData8,X
	BEQ +
	RTS
+:	LDA DifficultyBasedOnWeapon
	CLC
	ADC CurrentLevel
	LSR
	TAY
	LDA tblStationaryInfantryPreShootFlashFrames,Y
	STA SpriteData8,X
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	BCS +++
	LDA SpriteState,X
	BMI +++
	JSR fctGetDistanceBetweenEnemyAndJeep
	STA $00
	LDA DifficultyBasedOnWeapon
	CLC
	ADC CurrentLevel
	LSR
	TAY
	LDA $00
	CMP tblMobileInfantryNoShootRadiusFromJeep,Y
	BCC +++
	JMP subMoveSpriteToNextState

tblMobileInfantryNoShootRadiusFromJeep:
	db $50,$40,$30,$20,$10,$00
	
tblStationaryInfantryPreShootFlashFrames:
	db $08,$08,$10,$09,$18,$11

MobileInfantryState6:
	LDA #$12 ;01 Mobile Infantry State 6
	STA SpriteTypeIndex,X
Label553:	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	JSR Label244
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$07
	BEQ ++
	LDA SpriteData8,X
	BPL +
	CMP #$F9
	BEQ +++
	RTS
+:	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
	RTS
++:	LDY #$00
	JMP SpawnEnemyRoundBullet_Shell
+++:	LDA #$01
	STA SpriteGraphicsAttributes,X
	LDA #$01
	JMP subSetSpriteState
	
	
Label254:	LDA SpriteData1,X
	CLC
	ADC SpriteData2,X
	AND #$07
	STA SpriteData1,X
	LDA SpriteWhichJeeptoAttack,X
	ASL
	LDA #$00
	ROL
	TAY
	LDA #$00
	STA $01
	STA $03
	LDA $05B0,Y
	CLC
	ADC $40
	STA $00
	ROL $01
	LDA $0570,Y
	STA $02
	LDY SpriteData1,X
	LDA tblMobileInfantryWalkAroundJeepPath,Y
	STA $04
	ASL
	LDA #$00
	ROL
	JSR fctInvertA
	STA $05
	LDA $00
	CLC
	ADC $04
	STA SpriteData3,X
	LDA $01
	ADC $05
	STA SpriteData4,X
	CMP #$02
	BNE +
	LDA #$FF
	STA SpriteData3,X
	DEC SpriteData4,X
+:	LDA SpriteData4,X
	BPL +
	LDA #$00
	STA SpriteData3,X
	STA SpriteData4,X
+:	TYA
	CLC
	ADC #$06
	AND #$07
	TAY
	LDA tblMobileInfantryWalkAroundJeepPath,Y
	STA $04
	ASL
	LDA #$00
	ROL
	JSR fctInvertA
	STA $05
	LDA $02
	CLC
	ADC $04
	STA SpriteData5,X
	LDA $03
	ADC $05
	STA SpriteData6,X
	LDA #$00
	STA $10
	STA $13
	LDA SpriteData3,X
	STA $11
	LDA SpriteData4,X
	STA $12
	LDA SpriteData5,X
	STA $14
	LDA SpriteData6,X
	STA $15
	LDA #$01
	STA $08
	JSR subCalculateDirectionWithPresets
	JSR subCalculateObjectSpeed
	LDA $09
	STA SpriteWhatDirectionToShoot,X
	RTS

;Defines the horizontal position key points for an infantry to circle
;;the players jeep shooting
tblMobileInfantryWalkAroundJeepPath:
	db $50,$39,$00,$C7,$B0,$C7,$00,$39 ;points 1 - 8

;*******************
;STATIONARY INFANTRY (Flame thrower infantry also use this logic)
;
; SpriteData1 - Timer, countdown to shooting
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - direction to jeep (0-7).  used to define the sprite to display
; SpriteData8 - flashing/firing timer
;*******************
StationaryInfantrySpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw StationaryInfantryState0
	dw StationaryInfantryState1
	dw StationaryInfantryState2
	dw subInfantryDeath
	dw subInfantryDeathAnimation
	
StationaryInfantryState0:
	LDA #$12
	STA SpriteTypeIndex,X
	LDA #$01
	STA SpriteGraphicsAttributes,X
	TXA ;'randomize' initial firing delay by using sprite slot
	ASL
	ASL
	ASL
	STA SpriteData1,X
	LDA SpriteObjectID,X
	CMP #$02 ;normal stationary infantry (assumed not prioroity - MSB)
	BEQ +
	LDA #$03 ;Load alternate palette for flame thrower infantry
	STA SpriteGraphicsAttributes,X
+:	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState
	
StationaryInfantryState1:
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	LDA #$12
	STA SpriteTypeIndex,X
	;Face the attacked jeep
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	TYA ;Y comes from a nested JSR within the JSR above
	STA SpriteData6,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE ++
	;Adjust infantry behvaior for skilled players
	LDA DifficultyBasedOnWeapon
	CLC
	ADC CurrentLevel
	LSR
	TAY
	LDA SpriteObjectID,X
	CMP #$02
	BEQ +
	;Flame infantry uses a fixed index
	LDY #$00
+:	LDA tblStationaryInfantryShootDelay,Y
	STA SpriteData1,X
	LDA SpriteState,X
	BMI ++
	;sprite is on screen
	LDA tblStationaryInfantryPreShootFlashFrames,Y
	STA SpriteData8,X
	JSR fctGetDistanceBetweenEnemyAndJeep
	;minimum distance from jeep the infantry must be in order to fire
	;;This is likely a concern because the player would not have enough
	;;reaction time if the infantry were too close when firing
	CMP #$40
	BCC ++
	JMP subMoveSpriteToNextState
++:	RTS

;Level max is 5, Difficulty max is 3.  so max is 8/2 = 4.  that means index 5 is never used..
tblStationaryInfantryShootDelay:
;(Level + Difficulty)/2
	db $80,$70,$60,$50,$40,$30

StationaryInfantryState2:
	LDA #$12
	STA SpriteTypeIndex,X
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	TYA ;Y comes from a nested JSR within the JSR above
	STA SpriteData6,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData8,X
	LDA SpriteData8,X
	CMP #$F9
	BEQ ++
	AND #$07
	BEQ +
	;flash palette to indicate firing is about to commence
	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
	RTS
+:	LDA SpriteObjectID,X
	CMP #$02 ;Stationary Infantry ID
	BNE +
	;normal infantry
	LDY #$05
	JMP SpawnEnemyRoundBullet_Shell
	;flame infantry
+:	JMP subSpawnFlame ;Flame thrower code

++:	LDA #$01 ;Reload normal palette after flashing, then shoot
	STA SpriteGraphicsAttributes,X
	LDA SpriteObjectID,X
	CMP #$02 ;Normal stationary infantry ID
	BEQ +
	LDA #$03 ;Load flame thrower palette
	STA SpriteGraphicsAttributes,X
+:	LDA #$01
	JMP subSetSpriteState


;46
;******************
;END OF LEVEL CHECK
;
; SpriteData1 - NOT USED
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;******************
EndofLevelCheckSpriteLogic
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw EndofLevelState0
	dw subDespawnSprite

EndofLevelState0: ;Count the number of boss entities remaining alive
	TXA
	CLC
	ADC RNG_INCEveryFrame ;Looks some a mechanism to not check every frame..
	AND #$0F
	BNE +
	;Loop through all sprites, checking for boss entities
	LDY CurrentLevel
	LDX #$0F
-:	LDA SpriteObjectID,X
	CMP tblEndofLevelCheckBossID,Y
	BEQ +
	DEX
	BPL -
	LDA #$00 ;indicates the level is complete
	STA LevelBossEntitiesRemaining
+:	LDX $35
	RTS

;Level boss entities
tblEndofLevelCheckBossID:
	db $0A ;Level 1 = Boss Tank
	db $18 ;Level 2 = Boss Statue Heads
	db $92 ;Level 3 = Boss Spread Turrets
	db $C0 ;Level 4 = Boss Large Heli
	db $26 ;Level 5 = Electrified Gate
	db $4B ;Level 6 = Final Boss Huge Tank
	
	.PAD $85F4	
tblLevel1ObjectSpawn: ;header addresses
;a list of level spawns by screen number
	
	.PAD $860C
;Level 1 object spawns
;Each spawn consumes 3 bytes (except F0,F1,F2 objects - see Label978)
;Byte 1 = Vertical screen position at which to spawn the object
;Byte 2 = Horizontal screen position at which to spawn the object (is every 4 pixels [2 screens wide is $00 - $80)
;;	MSB on byte 2 indicates the object spawns at the bottom of the screen, not the top
;Byte 3 - Sprite Object ID

;F0,F1,F2 objects use 2 bytes:
;Byte 1 - Sprite Object ID (F0,F1,F2 only)
;Byte 2 - vertical Vertical screen position at which to spawn the object

	.PAD $86FB
	
;*******************
;LEVEL 1 ATTACK BOAT
;
; SpriteData1 - Timer controlling how long the boat travels after spawning before stopping
; SpriteData2 - Second sprite type for animation of water wake
; SpriteData3 - Timer countdown to firing
; SpriteData4 - Timer countdown to firing default/reload value
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Timer controlling the animation/water splash (sprite disaply id swap)
;*******************
Level1AttackBoatSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level1AttackBoatState0
	dw Level1AttackBoatState1
	dw subSpriteDeath
	dw subSpriteExplosion

Level1AttackBoatState0:
	LDA #$3A ;Initial sprite graphic
	STA SpriteTypeIndex,X
	LDA #$3B ;Second sprite graphic with different water wake
	STA SpriteData2,X
	LDA #$60 ;Time boat travels before stopping
	STA SpriteData1,X
	LDA #$30 ;time between firing bullets
	STA SpriteData3,X
	STA SpriteData4,X
	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	LDA #$10 ;speed multiplier
	STA $08
	LDA #$0C ;direction - always down-left
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState

Level1AttackBoatState1:
	LDA #$3A
	STA SpriteTypeIndex,X
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$08
	BEQ +
	LDA SpriteData2,X ;animate every 8 frames
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	DEC SpriteData1,X
	BNE +
	JSR subClearSpriteSpeed
+:	DEC SpriteData3,X
	BNE +
	LDA SpriteData4,X
	STA SpriteData3,X
	LDA SpriteState,X
	BMI +
	;sprite is on screen
	JSR subCalculateDirectionTowardJeep
	JSR fctGetSpriteOrientationIndex
	TYA
	ASL
	ASL
	STA SpriteWhatDirectionToShoot,X
	LDY #$01 ;bullet type
	JMP SpawnEnemyRoundBullet_Shell
+:	RTS


;09
;************
;Level 1 Boss
;
; SpriteData1 - Total number of tanks to spawn
; SpriteData2 - Tank spawn delay
; SpriteData3 - Tank spawn delay default/reload value
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;************
Level1BossSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level1BossState0
	dw Level1BossState1
	dw subDespawnSprite

Level1BossState0:
	LDA #$04
	STA SpriteData1,X
	STA LevelBossEntitiesRemaining
	LDY DifficultyBasedOnWeapon
	LDA tblLevel1BossTankSpawnDelay,Y
	STA SpriteData2,X ;Initial spawn delay
	STA SpriteData3,X ;Used to reload the spawn countdown timer
	;Arrived at boss.  stop scrolling and lock screen
	LDA #$00
	STA ScreenScrollingForF0ToBoss
	LDA #$01
	STA ScreenVerticalScrollLockForBossFight
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

tblLevel1BossTankSpawnDelay:	
	db $F0 ;Spawn delay with grande only
	db $D0 ;Spawn delay with bazooka 1
	db $B0 ;Spawn delay with bazooka 2
	db $90 ;Spawn delay with bazooka 3
	
Level1BossState1:	
	DEC SpriteData2,X ;count down to spawn
	BNE ++
	LDA SpriteData3,X ;Reset the spawn timer
	STA SpriteData2,X
	DEC SpriteData1,X  ;Decrement the spawn count
	BMI +++
	;set this invisible objects position so its easier to spawn the tanks
	LDA #$00
	STA SpriteAbsoluteHorizPositionLB,X
	STA SpriteAbsoluteHorizPositionUB,X
	STA SpriteVertScreenPosition,X
	STA SpriteAbsoluteVertPositionUB,X
	LDA SpriteData1,X
	AND #$01
	BEQ + ;alternate tank spawns top to bottom
	LDA #$EF ;bottom spawn
	STA SpriteVertScreenPosition,X
+:	LDA RNG_INCEveryFrame
	CMP #$50
	BCS +
	LDA #$50 ;ALL values $00 - $50 are bumped up to $50
+:	CMP #$B0
	BCC +
	LDA #$B0 ;ALL values $B0 - $FF are bumped down to $B0
+:	ASL ;the game is 2 screens wide ($00 - $1FF)
	STA $00
	LDA #$00
	ROL
	STA $01 ;get screen (left = 0, right = 1)
	LDA #$00 ;no vertical offset
	STA $02
	STA $03
	LDA #$0A ;Level 1 boss tank object ID
	STA $08
	LDA #$02 ;palette set
	STA $0F
	JSR subSpawnObjectFromParent_WithOffset
	TYA ;Y contains the sprite slot index
	BPL ++
	;Unable to spawn necessary object.
	INC SpriteData1,X ;Inc up from 0 to try again next frame
++:	RTS
+++:	LDA #$46 ;End of level check object ID
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA ;Y contains the sprite slot index
	BPL +
	;Unable to spawn necessary object.
	INC SpriteData1,X ;Inc up from 0 to try again next frame
	INC SpriteData2,X
	RTS
+:	JMP subMoveSpriteToNextState


;0A
;*****************
;LEVEL 1 BOSS TANK
;
; SpriteData1 - State machine/movement/firing control
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - Turn Left or Right depending on sprite slot index, when collision with other sprites is detected
; SpriteData5 - Mask for stationary frame count
; SpriteData6 - Base sprite type index
; SpriteData8 - Counts down the number of frames to be stationary
;*****************
Level1BossTankSpriteLogic:

	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level1BossTankState0
	dw Level1BossTankState1
	dw Level1BossTankState2
	dw Level1BossTankState3
	dw Level1BossTankState4
	dw subCheckForBossDeath_MultipleBossEnemies
	dw subSpriteDeath
	dw Level1BossTankState7

Level1BossTankState0: ;Spawn
	LDA #$33 ;Level 1 Boss Tank Right/Left
	STA SpriteTypeIndex,X
	STA SpriteData6,X
	JSR subCheckWhichJeepToAttack
	LDA #$30
	STA SpriteData1,X
	LDA #$08 ;default to facing down
	LDY SpriteVertScreenPosition,X
	BPL +
	;Tank spawned at the bottom of the screen
	LDA #$18 ;face up if spawning at the bottom of the screen
	STA SpriteData1,X
	LDA #$18 ;up direction
+:	STA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpriteForDirectionChange
	JSR subLevel1BossTankUpdatePalette_LowHealth
	JSR subUpdateSpritePositionForScrolling
	LDA #$00
	STA SpriteData8,X
	LDA #$0F
	STA SpriteData5,X
	LDA #$20
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JMP Label299

Level1BossTankState1:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE ++
	JSR fctGetCollision_WithSpeed_FarLookAhead_BG ;check for collision perpendicular?
	BNE +
	JSR Label247 ;check for collision with other sprites?
	BCC +++
+:	LDA #$08
	STA SpriteData1,X
++:	RTS
+++:	JMP subMoveSpriteToNextState

Level1BossTankState2:
	JSR Label228 ;check if tank needs to turn
	LDA #$00
	ROR
	STA $08
	LDA SpriteObjectID,X
	BEQ + ;Ignore NULL objects
	JSR subLevel1BossTankUpdatePalette_LowHealth
+:	LDA $08
	BMI +
	RTS
	
+:	LDA #$28 ;28 frames or movement, Level 1 boss tank
	STA SpriteData1,X
	LDA #$20
	JMP lblCalculateTank_JeepSpeed

Level1BossTankState3:
	JSR subTurnTankTowardsJeep
	LDA SpriteObjectID,X
	BEQ + ;Ignore NULL objects
	JSR subLevel1BossTankUpdatePalette_LowHealth
+:	LDA #$20
	JMP lblCalculateTank_JeepSpeed_CheckforCollision

Level1BossTankState4:
	LDA SpriteData6,X
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpriteForDirectionChange
	JSR subLevel1BossTankUpdatePalette_LowHealth
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$08
	BEQ +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	INC SpriteData1,X
	JSR Label232
	LDA $D7
	BNE ++
	LDA SpriteData1,X
	AND #$0F
	BNE +
	LDA SpriteState,X
	BMI +
	LDY #$02
	JMP SpawnEnemyRoundBullet_Shell
+:	RTS
++:	LDA SpriteData6,X
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpriteForDirectionChange
	LDA #$02
	JMP subSetSpriteState

Level1BossTankState7:
	JSR subSpriteExplosion
	LDA SpriteObjectID,X
	BNE +
	DEC LevelBossEntitiesRemaining ;One tank died.  keep count
+:	RTS

subLevel1BossTankUpdatePalette_LowHealth:
	LDA SpriteHealthHP,X
	AND #$3F
	CMP #$06
	BCS +
	LDA #$01
	STA SpriteGraphicsAttributes,X
+:	LDA SpriteTypeIndex,X
	SEC
	SBC #$33
	CMP #$01
	BNE +
	LDA SpriteAttributes,X
	BPL +
	AND #$7F
	STA SpriteAttributes,X
	LDA SpriteTypeIndex,X
	CLC
	ADC #$05
	STA SpriteTypeIndex,X
+:	RTS


	.PAD $8941
tblLevel2ObjectSpawn: ;header addresses
;a list of level spawns by screen number

	.PAD $8959
;Level 2 object spawns
;Each spawn consumes 3 bytes (except F0,F1,F2 objects - see Label978)
;Byte 1 = Vertical screen position at which to spawn the object
;Byte 2 = Horizontal screen position at which to spawn the object (is every 4 pixels [2 screens wide is $00 - $80)
;;	MSB on byte 2 indicates the object spawns at the bottom of the screen, not the top
;Byte 3 - Sprite Object ID

;F0,F1,F2 objects use 2 bytes:
;Byte 1 - Sprite Object ID (F0,F1,F2 only)
;Byte 2 - vertical Vertical screen position at which to spawn the object


	.PAD $8AAA
;*****************
;SILVER LARGE TANK
;
; SpriteData1 - Movement timer
; SpriteData2 - Timer controlling fire rate
; SpriteData3 - Firing timer mask
; SpriteData4 - Turn Left or Right depending on sprite slot index, when collision with other sprites is detected
; SpriteData5 - Mask for stationary frame count
; SpriteData6 - Base sprite display ID
; SpriteData8 - Stationary frame timer
;*****************
SilverLargeTankSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw SilverLargeTankState0
	dw SilverLargeTankState1
	dw SilverLargeTankState2
	dw SilverLargeTankState3
	dw subSpriteDeath
	dw subSpriteExplosion

SilverLargeTankState0:
	LDA #$44
	STA SpriteTypeIndex,X
	STA SpriteData6,X
	LDA #$02
	STA SpriteGraphicsAttributes,X
	LDA #$20 ;time between shots
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$0F
	STA SpriteData5,X
	JMP Label315

SilverLargeTankState1:
	JSR Label228
	BCS +
	RTS
+:	LDA #$50 ;travel time in frames
	STA SpriteData1,X
	LDA #$11 ;speed multiplier
	JMP lblCalculateTank_JeepSpeed

SilverLargeTankState2:
	JSR subTurnTankTowardsJeep
	LDA #$11 ;speed multiplier
	JMP lblCalculateTank_JeepSpeed_CheckforCollision

SilverLargeTankState3:
	JSR Label232
	LDA $D7
	BNE ++
	DEC SpriteData2,X
	BNE +
	LDA SpriteData3,X
	STA SpriteData2,X
	LDA SpriteState,X
	BMI +
	LDY #$03
	JMP SpawnEnemyRoundBullet_Shell
+:	RTS
++:	LDA #$01
	LDY SpriteObjectID,X
	CPY #$0B ;Normal Silver Tank
	BEQ +
	LDA #$02 ;handle Level 5 boss silver tank
+:	JMP subSetSpriteState


;3A,3B
;************
;ATTACK PLANE
;
; SpriteData1 - Counter for playing sound clip, cycling sprite w/shadow, and bomb drop
; SpriteData2 - NOT USEd
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - Travel direction
; SpriteData8 - NOT USED
;************
AttackPlaneSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw AttackPlaneState0
	dw AttackPlaneState1
	dw subSpriteDeath
	dw subSpriteExplosion

AttackPlaneState0:
	JSR subCheckWhichJeepToAttack
	LDA SpriteObjectID,X
	CMP #$3A ;Specific spawn location bomber
	BEQ +
	JSR subSpawnPlane_HeliPositionRelativeToJeep
+:	LDA #$4E ;initial sprite value, attack plane
	STA SpriteTypeIndex,X
	LDA #$08 ;dirction - down
	STA SpriteData6,X
	LDA SpriteVertScreenPosition,X
	BPL +
	;spawns at the bottom of the scren
	LDA #$80
	STA SpriteAttributes,X
	LDA #$18 ;direction - up
	STA SpriteData6,X
+:	LDA #$40 ;number of loops for attack planes vertical speed (upper nibble)
	STA $08
	LDA SpriteData6,X
	JSR subCalculateObjectSpeed
	JSR subUpdateSpritePositionForScrolling
	LDA SpriteState,X
	BPL +
	JMP subDespawnSprite
+:	JMP subMoveSpriteToNextState

AttackPlaneState1:
	LDA SpriteData1,X
	AND #$03
	BNE +
	LDA #BomberPlaneRoarSoundClip
	JSR subInitiateSoundClip
+:	LDA #$4E ;attack plane with shadow sprite value
	STA SpriteTypeIndex,X
	INC SpriteData1,X
	LDA SpriteData1,X
	AND #$01
	BEQ +
	INC SpriteTypeIndex,X ;alternate every other frame with the plane without a shadow to give the shadow a flickering appearance
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X ;check the attack plane timer
	CMP #$10 ;drop a bomb at #10
	BEQ +
	CMP #$30 ;drop a bomb at #30
	BEQ +
	CMP #$50 ;drop a bomb at #50
	BEQ +
	CMP #$70
	BNE ++
+:	JMP subSpawnJeep_BomberBomb
++:	RTS


;************
;FALLING BOMB
;
; SpriteData1 -
; SpriteData2 -
; SpriteData3 -
; SpriteData4 - 1 if an anywhere plane dopped the bomb.  0 if a specific planet dropped it.  other vehicles like the enemy jeep are other values (ID - #$3A)
; SpriteData5 -
; SpriteData6 -
; SpriteData8 -
;************
FallingBombSpriteLogic:
	LDA SpriteState,X ;load the sprite state.  If 00, code will initialize it
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw FallingBombState0
	dw FallingBombState1
	dw FallingBombState2
	dw subSpriteDeath
	dw subSpriteExplosion

FallingBombState0:
	LDA #$41
	STA SpriteTypeIndex,X
	LDA #GrenadeThrow_BombSoundClip
	JSR subInitiateSoundClip
	LDA #$30 ;Attack plane's bomb.  Time to fall before exploding
	STA SpriteData1,X
	LDA SpriteData4,X
	BEQ +
	;enemy jeep or anywhere plane
	DEC SpriteTypeIndex,X
	LDA #$40
	STA SpriteData1,X
+:	LDA RNG_INCEveryFrame
	AND #$C0 ;get random sprite mirroring
	STA SpriteAttributes,X
	LDA #$11 ;speed multiplier
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

FallingBombState1:
	DEC SpriteData1,X ;decrement object timer
	LDA SpriteData1,X
	BEQ + ;timer is 0, do something
	AND #$0F
	BNE + ;A is 1-F
	INC SpriteTypeIndex,X
	LDA SpriteAttributes,X
	CLC
	ADC #$40
	STA SpriteAttributes,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BEQ +
	RTS
+:	LDA #$18 ;Load the timer value to show explosions (&H18 = 24.  3 explosion graphics, &H8 each)
	STA SpriteData1,X
	LDA #$74 ;enable collision once the bomb lands
	STA SpriteHitboxShapeIndex,X
	LDA #$03 ;object graphic attributes
	STA SpriteGraphicsAttributes,X
	LDA #$19 ;load explosion graphic, Attack plane bomb explodes
	STA SpriteTypeIndex,X
	JSR subClearSpriteSpeed ;20
	LDA #BlackAndWhiteMissile_Bomb_LaserBlastHitsGroundSoundClip
	JSR subInitiateSoundClip
	JMP subMoveSpriteToNextState

FallingBombState2:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	LDA SpriteData1,X
	BEQ ++
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:
-:	RTS
++:	JMP subDespawnSprite


subSpawnJeep_BomberBomb:
	LDA SpriteState,X
	BMI - ;RTS - abort child spawn if parent object is offscreen
	LDA #$37 ;Bomber/Jeep bomb object ID
	STA $08
	LDA SpriteObjectID,X
	SEC
	SBC #$3A ;this doesnt account for the anywhere plane #$3B..it makes it look like the #$3B plane tosses the bomb instead of dropping it
	STA $09
	JSR subCalculateDirectionTowardJeep
	STA $0C
	LDA SpriteWhichJeeptoAttack,X
	AND #$80
	STA $0E
	LDA #$01
	STA $0F
	JMP subSpawnObjectFromParent_NoOffset


;0F
;**********
;ENEMY JEEP
;
; SpriteData1 - Timer for movement frames
; SpriteData2 - Timer for bomb throw
; SpriteData3 - Timer for bomb throw default/reload
; SpriteData4 - Turn Left or Right depending on sprite slot index, when collision with other sprites is detected
; SpriteData5 - Mask for stationary frame count
; SpriteData6 - Base sprite display ID index
; SpriteData8 - direction travelling
;**********
EnemyJeepSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw EnemyJeepState0
	dw EnemyJeepState1
	dw EnemyJeepState2
	dw EnemyJeepState3
	dw subSpriteDeath
	dw subSpriteExplosion

EnemyJeepState0:
	LDA #$3D ;Normal enemy jeep Sprite Type
	LDY CurrentLevel
	CPY #$05 ;Level 6
	BNE +
	LDA #$B5 ;Level 6 specific sprite type
+:	STA SpriteTypeIndex,X
	STA SpriteData6,X
	LDA #$40
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$07
	STA SpriteData5,X
	JMP Label315

EnemyJeepState1:
	JSR Label228
	BCS +
	;Jeep does not need to turn
	RTS
+:	LDA #$20
	STA SpriteData1,X
	LDA #$30
	JMP lblCalculateTank_JeepSpeed

EnemyJeepState2:
	JSR subTurnTankTowardsJeep
	LDA #$30
	JMP lblCalculateTank_JeepSpeed_CheckforCollision

EnemyJeepState3:
	JSR fctGetDistanceBetweenEnemyAndJeep
	CMP #$20
	BCS +
	LDA #$20
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
+:	JSR Label232
	LDA $D7
	BNE ++
	DEC SpriteData2,X
	BNE +
	LDA SpriteData3,X
	STA SpriteData2,X
	LDA SpriteState,X
	BMI + ;Dont spawn thrown bomb if off screen
	JMP subSpawnJeep_BomberBomb
+:	RTS
++:	LDA #$01
	JMP subSetSpriteState


;**************
;LEVEL 2 PILLAR
;
; SpriteData1 - BG graphics update index
; SpriteData2 - Used, but has no purpose
; SpriteData3 - NOT USED
; SpriteData4 - Used, but has no purpose
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Explosion Timer
;**************
Level2PillarSpriteLogic:

	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level2PillarState0
	dw Level2PillarState1
	dw subPlayMissileHittingGroundSound_LoadHoleInGroundBGGraphics ;Plays pillar breaking sound
	dw subProcessExplosionAnimation
	dw Level2PillarState4
	dw subScrollSprite_CheckForDespawn_UpdateBG

Level2PillarState0: ;initialize
	JSR subUpdateSpritePositionForScrolling
	LDA #$05 ;BG graphics update index
	STA SpriteData1,X
	LDA #$80 ;this does not appear to do anything
	STA SpriteData2,X
	LDA #$06 ;direction - default to falling down-right
	STA SpriteWhatDirectionToShoot,X
	LDA SpriteObjectID,X
	CMP #$1F ;Pillar falls right object ID
	BEQ +
	LDA #$0A ;direction - fall down-left
	STA SpriteWhatDirectionToShoot,X
+:	LDA #$49 ;this does not appear to do anything
	STA SpriteData4,X
	JMP subMoveSpriteToNextState

Level2PillarState1: ;wait for player to approach
	;check for player near
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA RNG_INCEveryFrame ;check for players every 4th frame
	AND #$03
	BNE +++
	LDA SpriteState,X
	BMI +++
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	;check player is between angle 6 and B (down-right to down-left)
	JSR subCalculateDirectionTowardJeep
	CMP #$06
	BCC +
	CMP #$0B
	BCC ++
	;change to other player
+:	LDA SpriteWhichJeeptoAttack,X
	CLC
	ADC #$80
	STA SpriteWhichJeeptoAttack,X
	;check for other player near
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	BCS +++ ;Avoid checking other player if they are dead
	;check player is between angle 6 and B (down-right to down-left)
	JSR subCalculateDirectionTowardJeep
	CMP #$06
	BCC +++
	CMP #$0B
	BCC ++
+++:
-:	RTS
	;also check that the player is near enough
++:	JSR fctGetDistanceBetweenEnemyAndJeep
	CMP #$70
	BCS -
	JMP subMoveSpriteToNextState ;Break and fall at the player

Level2PillarState4: ;Explosion complete, spawn falling pillar top
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA #$1E ;Pillar top object ID
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	STA $0C
	LDA #$01 ;palette
	STA $0F
	LDA $0C
	AND #$08
	BEQ +
	;falling left
	LDA #$41 ;mirror sprite
	STA $0F
+:	JSR subSpawnObjectFromParent_NoOffset
	JMP subMoveSpriteToNextState ;stay resident to update the BG graphics if missed


;****************************
;LEVEL 2 PILLAR TOP (Falling)
;
; SpriteData1 - Timer for falling at an angle
; SpriteData2 - Timer for rolling downwards
; SpriteData3 - NOT USED
; SpriteData4 - Base sprite type index
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Explosion Timer
;****************************
Level2PillarTopSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level2PillarTopState0
	dw Level2PillarTopState1
	dw Level2PillarTopState2
	dw subSpriteDeath
	dw subSpriteExplosion

Level2PillarTopState0: ;Initialization
	LDA #$47 ;Angled falling sprite type index
	STA SpriteTypeIndex,X
	JSR subUpdateSpritePositionForScrolling
	LDA #$20
	STA SpriteData1,X
	LDA #$30
	STA SpriteData2,X
	LDA #$31 ;speed multiplier
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA #$49
	STA SpriteData4,X
	JMP subMoveSpriteToNextState

Level2PillarTopState1: ;Falling at an angle
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$03
	BNE +
	JSR subInvertSpriteVertSpeed ;gives the top a sort of zigzag/sawtooth type motion as it falls
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BEQ +
	AND #$03
	BNE ++ ;RTS
	JMP subInvertSpriteVertSpeed
	;Angled fall is complete
+:	JSR subClearSpriteHorizSpeed
	;Set speed for rolling on the ground
	LDA #$C0
	STA SpriteVertSpeedLB,X
	LDA #$01
	STA SpriteVertSpeedUB,X
	LDA #$08
	STA SpriteWhatDirectionToShoot,X
	INC SpriteTypeIndex,X
	JMP subMoveSpriteToNextState
-:
++:	RTS

Level2PillarTopState2:
	LDA #$48
	STA SpriteTypeIndex,X
	DEC SpriteData2,X
	LDA SpriteData2,X
	AND #$08
	BNE +
	;Alternate the sprite visualization to simulate rolling
	LDA SpriteData4,X
	STA SpriteTypeIndex,X
+:	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	BEQ + ;$D7 test.  0=no collision
	JSR subClearSpriteSpeed
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA $D7
	BNE +
	LDA SpriteData2,X
	BNE - ;RTS
+:	LDA #$48
	STA SpriteData4,X
	JSR subClearSpriteVertSpeed
	JSR Label247
	BCC +
	LDA #$00
	STA EnemyPoints,X
	JMP subMoveSpriteToNextState
+:	RTS


;18
;************************
;LEVEL 2 BOSS STATUE HEAD
;
; SpriteData1 - Destroyed BG Graphics update index
; SpriteData2 - State machine count down timer
; SpriteData3 - Reload timer value for 
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Explosion Timer
;************************
Level2BossStatueHeadSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level2BossStatueHeadState0
	dw Level2BossStatueHeadState1
	dw Level2BossStatueHeadState2
	dw Level2BossStatueHeadState3
	dw subCheckForBossDeath_MultipleBossEnemies
	dw subPlayExplosionSound_LoadNewBGGraphics
	dw subProcessExplosionAnimation
	dw Level2BossStatueHeadState7
	dw subScrollSprite_CheckForDespawn_UpdateBG

Level2BossStatueHeadState0: ;initialize
	LDA #$C0 ;Frames for idle state
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$06
	STA SpriteData1,X
	LDA #$08
	STA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level2BossStatueHeadState1: ;Idle
	LDA SpriteVertScreenPosition,X
	CMP #$E0
	BCS + ;dont update BG if near off screen
	LDA #$0B ;mouth closed BG update index
	JSR subUpdateBGGraphicsFromSprite
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
lblLevel2StatueStateTimer:
	DEC SpriteData2,X ;count timer between states, Statue Head
	BNE +
	LDA #$18 ;the time to flash eyes before firing, Statue Head
	STA SpriteData2,X
	JMP subMoveSpriteToNextState
+:
-:	RTS

Level2BossStatueHeadState2: ;Flash eyes
	DEC SpriteData2,X
	LDA SpriteVertScreenPosition,X
	CMP #$E0
	BCS +
	LDA #$09 ;Normal eyes BG update index
	JSR subUpdateBGGraphicsFromSprite
	LDA SpriteData2,X
	AND #$02
	BEQ +
	LDA #$08 ;Glowing eyes BG update index
	JSR subUpdateBGGraphicsFromSprite
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData2,X
	BNE -
	LDA #$18 ;Time to show mouth opening, Statue Head
	STA SpriteData2,X
	JMP subMoveSpriteToNextState

Level2BossStatueHeadState3: ;Open mouth and fire missile
	LDA SpriteVertScreenPosition,X
	CMP #$E0
	BCS +
	LDA #$0A ;Mouth open BG update index
	JSR subUpdateBGGraphicsFromSprite
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X
	BNE -
	LDA SpriteData3,X
	STA SpriteData2,X
	LDA SpriteState,X
	BMI +
	;Spawn the missile
	LDA #$39
	STA $08 ;Sprite ID
	LDA #$4B
	STA $0A ;Sprite Type
	LDA #$01
	STA $0B ;Missile type
	LDA SpriteWhatDirectionToShoot,X
	STA $0C
	LDA #$00 ;palette
	STA $0F
	;Set spawn offset
	LDA #$00
	STA $00
	STA $01
	STA $03
	LDA #$10
	STA $02
	JSR subSpawnObjectFromParent_WithOffset
+:	LDA #$01 ;reset back to state 1
	JMP subSetSpriteState

Level2BossStatueHeadState7:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC LevelBossEntitiesRemaining
	JMP subMoveSpriteToNextState


;21,22
;*******************
;LEVEL 2 STATUE HEAD
;
; SpriteData1 - BG Graphics update index
; SpriteData2 - State machine count down timer
; SpriteData3 - Default/reload timer value for idle time
; SpriteData4 - 0 = Statue shoots.  1 = Statue is idle but blows up
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;*******************
Level2StatueHeadSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level2StatueHeadState0
	dw Level2StatueHeadState1
	dw Level2BossStatueHeadState2
	dw Level2StatueHeadState3
	dw subPlayExplosionSound_LoadNewBGGraphics
	dw subProcessExplosionAnimation
	dw subScrollSprite_CheckForDespawn_UpdateBG

Level2StatueHeadState0:
	TXA ;Set the initial timer delay
	ASL ;this is based on the sprite slot
	ASL
	STA SpriteData2,X
	LDA #$40 ;time for missile firing animation
	STA SpriteData3,X
	LDA SpriteObjectID,X
	SEC
	SBC #$A1 ;assumption that the priority bit is set (MSB)
	STA SpriteData4,X
	LDA #$07 ;BG update index for destroyed statue head
	STA SpriteData1,X
	LDA #$04 ;Default to shooting down-right
	STA SpriteWhatDirectionToShoot,X
	LDA SpriteAbsoluteHorizPositionUB,X
	BEQ +
	;If the statue is on the right screen, shoot down-left
	LDA #$0C
	STA SpriteWhatDirectionToShoot,X
+:	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState
	
Level2StatueHeadState1:
	LDA SpriteVertScreenPosition,X
	CMP #$E0
	BCS +
	LDA #$0B ;Mouth closed (normal) BG graphics update
	JSR subUpdateBGGraphicsFromSprite
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData4,X
	BEQ + ;Statue always shoots
	;Statue is idle by default
	LDA DifficultyBasedOnWeapon
	CMP #$02
	BCC ++ ;If players have upgraded main weapons, the idle statue shoots
+:	JMP lblLevel2StatueStateTimer ;decrements SpriteData2
++:	
-:	RTS

Level2StatueHeadState3:
	LDA SpriteVertScreenPosition,X
	CMP #$E0
	BCS +
	;avoid flashing eyes if the head is close to off screen
	LDA #$0A ;Mouth open BG graphics
	JSR subUpdateBGGraphicsFromSprite
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X ;State machine timer
	BNE -
	LDA SpriteData3,X ;Reload default timer value for idle state
	STA SpriteData2,X
	LDA SpriteState,X
	BMI + ;Avoid spawning a missile off screen
	;spawn missile
	LDA #$39 ;missile object ID
	STA $08
	LDA #$4B ;sprite type index
	STA $0A
	LDA #$00 ;this determines if the missile fires straight or is homing, Statue Head
	STA $0B
	LDA SpriteWhatDirectionToShoot,X
	STA $0C
	LDA #$00 ;palette
	STA $0F
	;Set spawn offset
	LDA #$00
	STA $00
	STA $01
	STA $03
	LDA #$10
	STA $02
	JSR subSpawnObjectFromParent_WithOffset
+:	LDA #$01 ;reset to state 1
	JMP subSetSpriteState


;************
;LEVEL 2 BOSS
;
; SpriteData1 - Number of heads to spawn
; SpriteData2 - Head spawn rate
; SpriteData3 - Default/reload head spawn rate
; SpriteData4 - Red Medium Tank spawn counter LB
; SpriteData5 - Red Medium Tank spawn counter UB
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;************
Level2BossSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level2BossState0
	dw Level2BossState1
	dw Level2BossState2
	dw subDespawnSprite

Level2BossState0: ;initialize
	LDA #$00 ;this object is just for control.  no visualization
	STA SpriteTypeIndex,X
	LDA #$04 ;spawn 4 statue heads
	STA SpriteData1,X
	STA LevelBossEntitiesRemaining ;init counter for end of boss fight
	LDA #$18
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$00 ;stop scroll
	STA ScreenScrollingForF0ToBoss
	LDA #$01 ;lock scroll
	STA ScreenVerticalScrollLockForBossFight
	LDA #$1C ;All heads spawn at the same Y coordinate
	STA SpriteVertScreenPosition,X ;move this invisible object to the desired Y coordinate for spawning
	JMP subMoveSpriteToNextState

Level2BossState1: ;Spawn statue heads
	DEC SpriteData2,X
	BNE +
	LDA SpriteData3,X
	STA SpriteData2,X
	DEC SpriteData1,X
	BMI ++
	LDY SpriteData1,X
	;Move this object around so the head can spawn without an offset below
	LDA tblLevel2BossStatueHeadHorizontalSpawnPositionLB,Y
	STA SpriteAbsoluteHorizPositionLB,X
	LDA tblLevel2BossStatueHeadHorizontalSpawnPositionUB,Y
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$18 ;Boss statue object ID
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL +
	;If the head was unable to spawn, INC to try again next frame
	INC SpriteData1,X
+:
--:	RTS
++:	LDA #$46 ;After all heads are spawn, spawn the End of Level object
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL +
	;If this was unable to spawn, INC to try again next frame
	INC SpriteData1,X
	LDA #$01 ;Reduce try again timer for quicker spawns of this
	STA SpriteData2,X
	RTS
+:
-:	JMP subMoveSpriteToNextState

tblLevel2BossStatueHeadHorizontalSpawnPositionLB:
	db $BC,$0C,$E4,$34

;This defines which screen to spawn on (1 = Right screen)
tblLevel2BossStatueHeadHorizontalSpawnPositionUB:
	db $00,$01,$00,$01
	
Level2BossState2: ;Spawn red medium tanks to annoy the player(s)
	LDA DifficultyBasedOnWeapon
	CMP #$02
	BCC - ;RTS.  no tanks if players lose weapon upgrades
	DEC SpriteData4,X
	BNE -- ;RTS
	INC SpriteData5,X
	LDA SpriteData5,X
	AND #$01
	BNE -- ;RTS
	;spawn tanks every $200 frames
	LDA #$00
	STA SpriteAbsoluteHorizPositionLB,X
	STA SpriteAbsoluteHorizPositionUB,X
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$EF ;Spawns the tank at the bottom of the screen
	STA SpriteVertScreenPosition,X
	;Spawn the tanks between $50 and $B0 on the screen
	LDA RNG_INCEveryFrame
	CMP #$50
	BCS +
	LDA #$50
+:	CMP #$B0
	BCC +
	LDA #$B0
+:	ASL ;There are 2 screens, so we need 00-1FF
	STA $00	;Spawning red tank data
	LDA #$00
	ROL
	STA $01 ;Left screen = 0, Right Screen = 1
	LDA #$00 ;no vertical offset
	STA $02
	STA $03
	LDA #$07 ;Red medium tank object ID
	STA $08
	LDA #$01 ;palette
	STA $0F
	JSR subSpawnObjectFromParent_WithOffset
	;These tanks spawn to add difficulty and spawn forever
	;;If they gave points, the player could farm forever, so these tanks award no points
	LDA #$00
	STA EnemyPoints,Y
	RTS
	

	.PAD $9064	
tblLevel3ObjectSpawn: ;header addresses
;a list of level spawns by screen number

	.PAD $907C
;Level 3 object spawns
;Each spawn consumes 3 bytes (except F0,F1,F2 objects - see Label978)
;Byte 1 = Vertical screen position at which to spawn the object
;Byte 2 = Horizontal screen position at which to spawn the object (is every 4 pixels [2 screens wide is $00 - $80)
;;	MSB on byte 2 indicates the object spawns at the bottom of the screen, not the top
;Byte 3 - Sprite Object ID

;F0,F1,F2 objects use 2 bytes:
;Byte 1 - Sprite Object ID (F0,F1,F2 only)
;Byte 2 - vertical Vertical screen position at which to spawn the object


	.PAD $921B


;11
;**************
;INFANTRY TRUCK
;
; SpriteData1 - State machine/movement timer
; SpriteData2 - infantry spawn timer default/reload
; SpriteData3 - Number of infantry to spawn
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;**************
InfantryTruckSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw InfantryTruckState0
	dw InfantryTruckState1
	dw InfantryTruckState2
	dw InfantryTruckState3
	dw subSpriteDeath
	dw subSpriteExplosion

InfantryTruckState0: ;initialize
	LDA #$54
	STA SpriteTypeIndex,X
	JSR subUpdateSpritePositionForScrolling
	LDA #$20 ;# frames to wait before moving initially
	STA SpriteData1,X
	LDA #$81 ;# Frames to wait between spawning infantry
	STA SpriteData2,X
	LDA #$08 ;# of infantry total to spawn
	STA SpriteData3,X
	JMP subMoveSpriteToNextState

InfantryTruckState1: ;Wait before driving to the right
	JSR Label244
	DEC SpriteData1,X
	BNE +
	LDA #$A0
	STA SpriteHorizSpeedLB,X
	LDA #$90 ;# frames to move to the right
	STA SpriteData1,X
	JMP subMoveSpriteToNextState
+:
-:	RTS

InfantryTruckState2: ;Driving to the right
	JSR Label244
	DEC SpriteData1,X
	BEQ +
	LDA SpriteData1,X
	CMP #$F0
	BEQ ++
	RTS
+:	JMP subClearSpriteHorizSpeed
++:	LDA SpriteData2,X
	STA SpriteData1,X
	INC SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

InfantryTruckState3: ;Deploying infantry
	JSR Label244
	DEC SpriteData1,X
	BNE -
	LDA SpriteData2,X ;reload the timer for the next infantry spawn
	STA SpriteData1,X
	LDA SpriteData3,X ;check if more infantry should spawn
	BEQ -
	DEC SpriteData3,X
	LDA #$00 ;no vertical offset
	STA $02
	STA $03
	LDA #$EC ;offset to the left
	STA $00
	LDA #$FF
	STA $01
	LDA #$01 ;This is the sprite index to spawn (01 is the standard mobile infantry)
	STA $08
	LDA #$01 ;Spawned sprite palette info
	STA $0F
	JMP subSpawnObjectFromParent_WithOffset


;29
;*********
;SUBMARINE
;
; SpriteData1 - State timer
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - Tracks the number of times the sub moves upwards
; SpriteData5 - Base sprite render index
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;*********
SubmarineSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw SubmarineState0
	dw SubmarineState1
	dw SubmarineState2
	dw SubmarineState3
	dw SubmarineState4
	dw SubmarineState5
	dw SubmarineState6
	dw subSpriteDeath
	dw subSpriteExplosion

SubmarineState0:
	LDA #$5E ;Submerged submarine render index
	STA SpriteTypeIndex,X
	LDA #$20 ;Initial delay before rising
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
	JSR subCheckWhichJeepToAttack
	JMP subMoveSpriteToNextState

SubmarineState1:
	LDA #$5E ;submerged submarine render index
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$01
	BNE +
	LDA #$00 ;flash submerged sub
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE +
	LDA #$20 ;rising 1 state time
	STA SpriteData1,X
	LDA #$58 ;rising 1 sub render index
	STA SpriteTypeIndex,X
	STA SpriteData5,X
	LDA #$04 ;turn on hitbox
	STA SpriteHitboxShapeIndex,X
	JMP subMoveSpriteToNextState
+:
-:	RTS

SubmarineState2: ;Rising
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$0F ;Rise sub a little further every $10 frames
	BNE +
	INC SpriteData5,X
+:	LDA SpriteData1,X
	AND #$01
	BEQ +
	;Flash the part of the sub that's underwater
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BNE -
	;Rise complete
	LDA #$20
	STA SpriteData1,X
	JMP subMoveSpriteToNextState

SubmarineState3: ;Pause and fire missile
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$01
	BEQ +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE -
	LDA #$40
	STA SpriteData1,X
	LDA SpriteState,X
	BMI +
	;Spawn missile
	LDA #$39
	STA $08
	LDA #$4B
	STA $0A
	LDA #$03
	STA $0B
	JSR subCalculateDirectionTowardJeep
	JSR fctGetSpriteOrientationIndex
	TYA
	ASL
	ASL
	STA $0C
	LDA #$00
	STA $0F
	JSR subSpawnObjectFromParent_NoOffset
+:	JMP subMoveSpriteToNextState

SubmarineState4: ;Pause after firing missile
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$01
	BEQ +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE + ;RTS
	LDA #$30
	STA SpriteData1,X
	JMP subMoveSpriteToNextState
-:
+:	RTS

SubmarineState5: ;Go under
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
	DEC SpriteData1,X
	BEQ ++
	LDA SpriteData1,X
	AND #$0F
	BNE +
	DEC SpriteData5,X
+:	LDA SpriteData1,X
	AND #$01
	BEQ ++
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
++:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BNE - ;RTS
	LDA #$F0
	STA SpriteHitboxShapeIndex,X
	LDA #$5E
	STA SpriteTypeIndex,X
	LDA SpriteData4,X
	CMP #$03 ;move up only 3 times
	BEQ +
	LDA SpriteAbsoluteVertPositionUB,X
	BMI +
	INC SpriteData4,X
	LDA #$80
	STA SpriteData1,X
	LDA #$10
	STA $08
	LDA #$18
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState
+:	LDA #$60
	STA SpriteData1,X
	LDA #$01
	JMP subSetSpriteState

SubmarineState6: ;Move up
	LDA #$5E
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$01
	BNE +
	LDA #$00
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BEQ +
	RTS
+:	LDA #$60 ;movement timer
	STA SpriteData1,X
	JSR subClearSpriteSpeed
	LDA #$01
	JMP subSetSpriteState


;38
;*************
;LEVEL 3 LASER
;
; SpriteData1 - lazing and flashing timer
; SpriteData2 - Indicates if this is a long or short laser.  does not appear to be used
; SpriteData3 - Base sprite type index
; SpriteData4 - Horizontal offset for flashing sprites
; SpriteData5 - which laser is active (0,1,2)
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;*************
Level3LaserSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level3LaserState0
	dw Level3LaserState1
	dw Level3LaserState2
	dw Level3LaserState3

Level3LaserState0: ;Initialize
	LDA RNG_INCEveryFrame ;get RNG for laser start position
	AND #$03
	CMP #$03
	BNE +
	LDA #$00 ;start with 1st laser
+:	STA SpriteData5,X
	LDA #$5F ;Base sprite index for long laser
	STA SpriteData3,X
	LDA #$40
	STA SpriteData4,X
	LDA CurrentLevelScreen
	CMP #$07
	BEQ + ;long laser is on screen 7
	;short laser is on screen 8
	INC SpriteData2,X
	INC SpriteData3,X ;short laser
	LDA #$38 ;shorter laser has a shorter vert offset
	STA SpriteData4,X
+:	JSR subUpdateSpritePositionForScrolling
	LDA #$10 ;#frames to (wait for) flashing sprite
	STA SpriteData1,X 
	JMP subMoveSpriteToNextState

Level3LaserState1: ;Spawn flashing sprites
	LDY SpriteData5,X
	INC SpriteData5,X ;3 laser positions.  This value increments
	LDA SpriteData5,X
	CMP #$03 ;roll over (mod arith) after 3 lasers
	BNE +
	LDA #$00  ;Roll over to laser 1
	STA SpriteData5,X
+:	LDA tblLaserX_LB,Y ;Load laser horiz start position
	STA SpriteAbsoluteHorizPositionLB,X
	LDA tblLaserX_UB,Y ;Load laser screen to spawn
	STA SpriteAbsoluteHorizPositionUB,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteState,X
	BMI + ;If the laser is off screen, do nothing
	LDA #$00
	STA $00
	STA $01
	STA $03
	LDA SpriteData4,X
	STA $02
	LDA #$0D ;Load the object value for the charging flash
	STA $08
	LDA #$03
	STA $0F
	JSR subSpawnObjectFromParent_WithOffset
	LDA #$00
	STA $00
	STA $01
	LDA #$FF
	STA $03
	LDA SpriteData4,X
	JSR fctInvertA ;spawn on the other side
	STA $02
	LDA #$0D
	STA $08
	LDA #$03
	STA $0F
	JSR subSpawnObjectFromParent_WithOffset
	LDA #$20 ;# frames to display flashes before laser is on, Level 3 Laser code
	STA SpriteData1,X
	JMP subMoveSpriteToNextState
-:
+:	RTS 

tblLaserX_LB: ;Positions are relative to the far left screen edge (0)
	db $F0 ;Laser 1 X Start Position
	db $30 ;Laser 2 X Start Position
	db $70 ;Laser 3 X Start Position
	
tblLaserX_UB:
	db $00 ;Laser 1 on left screen
	db $01 ;Laser 2 on right screen
	db $01 ;Laser 3 on right screen

Level3LaserState2: ;Flashing (preparing to fire)
	DEC SpriteData1,X
	BNE +
	;Flashing complete, turn on the laser
	LDA #$7A ;laser now hurts the jeep and cant be killed
	STA SpriteHitboxShapeIndex,X
	LDA SpriteData3,X
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BNE -
	LDA #$18 ;# frames to have laser active
	STA SpriteData1,X 
	LDA #LaserBlastSoundClip 
	JSR subInitiateSoundClip 
	JMP subMoveSpriteToNextState 

Level3LaserState3: ;Lazing/Firing
	;Cycle through the palettes/flash the laser beam
	INC SpriteGraphicsAttributes,X 
	LDA SpriteGraphicsAttributes,X 
	AND #$03 
	STA SpriteGraphicsAttributes,X 
	
	DEC SpriteData1,X ;Count down how long to laze
	BNE +
	;Lazing complete
	LDA #$00 ;Erase visible aspect of laser beam
	STA SpriteTypeIndex,X 
	LDA #$F0 ;disable harm to jeep
	STA SpriteHitboxShapeIndex,X 
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn 
	LDA SpriteData1,X 
	BNE + 
	LDA #$10 ;this is loaded when a laser position is off screen
	STA SpriteData1,X 
	LDA #$01 
	JMP subSetSpriteState 
+:	RTS 


;0D
;******************************
;LEVEL 3 LASER CHARGING FLASHES
;
; SpriteData1 - Flashing timer
; SpriteData2 - Base sprite type index
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;******************************
Level3LaserChargingFlashesSpriteLogic:
	LDA SpriteState,X 
	AND #$7F 
	JSR subExecuteCodeViaIndirectJump 
	
	dw Level3LaserChargingFlashesState0
	dw Level3LaserChargingFlashesState1
	dw subDespawnSprite
	
Level3LaserChargingFlashesState0: ;Initialize
	LDA #$61
	STA SpriteData2,X
	LDA #$10 ;# frames total to flash
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
-:	JMP subMoveSpriteToNextState

Level3LaserChargingFlashesState1:
	LDA SpriteData2,X
	STA SpriteTypeIndex,X
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$01
	BEQ +
	LDA #$00 ;Alternate visibility to flash
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BEQ -
	CMP #$08 ;After half the time is up, flash a different pattern
	BNE +
	INC SpriteData2,X ;Go to the next flash sprite visualization
+:	RTS


;*************
;SPREAD TURRET
;
; SpriteData1 - Rise/Lower timer
; SpriteData2 - Fire delay timer
; SpriteData3 - Fire delay timer default/reload
; SpriteData4 - 0 = normal turret, 1 = L3 boss
; SpriteData5 - Tracks the number of bullets to fire
; SpriteData6 - Tracks the direction each bullet is fired
; SpriteData8 - Explosion timer
;*************
SpreadTurretSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw SpreadTurretState0
	dw SpreadTurretState1
	dw SpreadTurretState2
	dw SpreadTurretState3
	dw subCheckForBossDeath_MultipleBossEnemies
	dw subSpriteDeath
	dw SpreadTurretState6

SpreadTurretState0:
	LDA #$50
	LDY CurrentLevel
	CPY #$05
	BNE +
	LDA #$A1 ;Load a different sprite manifestation for level 6 spread turrets
+:	STA SpriteTypeIndex,X
	LDA #$02 ;palette
	STA SpriteGraphicsAttributes,X
	LDA #$08 ;Initial state machine timer value
	STA SpriteData1,X
	TXA
	ASL ;Time delay to start firing depends on the sprite slot
	ASL
	STA SpriteData2,X
	LDA #$18 ;fire timer reload value for normal turrets
	STA SpriteData3,X
	LDY SpriteData4,X 
	BEQ +
	;Turret is boss type
	TXA
	ASL
	ADC #$10 ;Offset each boss turret so they dont all fire at once
	STA SpriteData3,X
	LDA #$63 ;Boss spread turret render type
	STA SpriteTypeIndex,X
	LDA #$86 ;L3 Boss Turret Health
	STA SpriteHealthHP,X
+:	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	LDA SpriteData4,X
	BEQ +
	LDA #$86 ;normal turret health.  probably meant to separate boss and normal turret health, but they ended up the same
	STA SpriteHealthHP,X
+:	JMP subMoveSpriteToNextState

SpreadTurretState1: ;Rise up
	LDA SpriteData4,X
	BNE +
	;Normal turret
	LDA CurrentLevelScreen
	CMP #$0B ;Last screen
	BNE +
	LDA CurrentLevelScreenSubPosition
	CMP #$E0 ;At boss
	BCC +
	;At the boss.  Any normal turrets are despawned
	JMP subDespawnSprite
+:	DEC SpriteData1,X
	LDA SpriteData1,X
	BPL +
	CMP #$C0
	BEQ +
	AND #$0F
	BNE +
	LDA #$04
	STA SpriteHitboxShapeIndex,X
	INC SpriteTypeIndex,X ;increment sprite graphic
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	CMP #$C0
	BEQ +
	RTS
+:	JMP subMoveSpriteToNextState

SpreadTurretState2: ;pause/flash/fire bullets
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	DEC SpriteData2,X
	BEQ ++
	LDA SpriteData2,X
	CMP #$09
	BCS +
	INC SpriteGraphicsAttributes,X ;flash turret
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
-:
+::	RTS
++:	LDA #$02 ;reset palette
	STA SpriteGraphicsAttributes,X
	LDA SpriteData3,X
	STA SpriteData2,X
	LDA SpriteState,X
	BMI - ;Avoid firing bullets offscreen
	;Fire bullets
	JSR subCalculateDirectionTowardJeep
	SEC
	SBC #$04 ;begin with the 1st bullet  CCW from the jeep
	AND #$1F ;max direction is 1F
	STA SpriteData6,X
	LDA #$05 ;number of bullets
	STA SpriteData5,X
-:	LDA SpriteData6,X
	STA SpriteWhatDirectionToShoot,X
	LDA SpriteData4,X ;adjust bullet type for normal vs Boss turret
	ASL
	CLC
	ADC #$04
	TAY
	JSR SpawnEnemyRoundBullet_Shell
	LDA SpriteData6,X ;move to the next bullet direction
	CLC
	ADC #$02
	AND #$1F ;max direction is 1F
	STA SpriteData6,X
	DEC SpriteData5,X
	BNE - ;Goto fire next bullet
	LDA #$10 ;10 decrements down to C0
	STA SpriteData1,X
	JMP subMoveSpriteToNextState

SpreadTurretState3: ;Lower back down
	DEC SpriteData1,X
	LDA SpriteData1,X
	BPL +
	CMP #$C0
	BEQ +
	AND #$0F
	BNE +
	DEC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	CMP #$C0
	BEQ +
	RTS
+:	LDA #$F0
	STA SpriteHitboxShapeIndex,X
	LDA #$50 ;initial time.  Decrements down to C0, Turret Spread Code
	STA SpriteData1,X
	LDA LevelBossEntitiesRemaining
	CMP #$02
	BCS +
	;Last boss spread turret fires quickly
	LDA #$01
	STA SpriteData1,X
	LDA #$09
	STA SpriteData2,X
+:	LDA #$01
	JMP subSetSpriteState

SpreadTurretState6: ;Exploding
	DEC SpriteData8,X
	LDA SpriteData8,X
	BEQ +
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BEQ +
	RTS
+:	LDA SpriteData4,X
	BEQ +
	;Boss turret
	LDA #$66
	STA SpriteTypeIndex,X
	LDA #$0E ;Load destroyed graphics on Boss battleship
	JSR subUpdateBGGraphicsFromSprite
	DEC LevelBossEntitiesRemaining ;count turrests destroyed
+:	JMP subDespawnSprite


;1A
;*************************
;LEVEL 3 LARGE ATTACK BOAT
;
; SpriteData1 - Timer for ship movement and water splash sprite update
; SpriteData2 - Sprite type index 2, for water wake
; SpriteData3 - Firing timer
; SpriteData4 - Firing timer default/reload value
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Animation and Explosion timer
;*************************
Level3LargeAttackBoatSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level3LargeAttackBoatState0
	dw Level3LargeAttackBoatState1
	dw subSpriteDeath
	dw subSpriteExplosion

Level3LargeAttackBoatState0:
	LDA #$56
	STA SpriteTypeIndex,X
	LDA #$57 ;second sprite type index for water animation
	STA SpriteData2,X
	LDA #$60 ;# frames to move downward
	STA SpriteData1,X
	LDA #$30 ;#frames between shots
	STA SpriteData3,X
	STA SpriteData4,X
	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	LDA #$11 ;speed multiplier
	STA $08
	LDA #$08
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState

Level3LargeAttackBoatState1:
	LDA #$56
	STA SpriteTypeIndex,X
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$08
	BEQ +
	LDA SpriteData2,X
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	DEC SpriteData1,X
	BNE +
	JSR subClearSpriteSpeed
+:	DEC SpriteData3,X
	BNE +
	LDA SpriteData4,X
	STA SpriteData3,X ;rest firing timer
	LDA SpriteState,X
	BMI + ;avoid firing if off screen
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	LDY #$01 ;bullet type
	JMP SpawnEnemyRoundBullet_Shell
+:	RTS


;25
;************
;LEVEL 3 BOSS
;
; SpriteData1 - Number of turrets to spawn (counter)
; SpriteData2 - Time between spawns
; SpriteData3 - Time between spawns default/reload value
; SpriteData4 - Red Medium tank spawn LB timer
; SpriteData5 - Red Medium tank spawn UB timer
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;************
Level3BossSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level3BossState0
	dw Level3BossState1
	dw Level3BossState2
	dw subDespawnSprite

Level3BossState0: ;Initialize
	LDA #$00 ;Controlling boss object has no visual manifestations
	STA SpriteTypeIndex,X
	LDA #$06 ;turret count
	STA SpriteData1,X
	STA LevelBossEntitiesRemaining
	LDA #$18
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$00 ;stop the auto scroll
	STA ScreenScrollingForF0ToBoss
	LDA #$01 ;vertical scroll lock for boss
	STA ScreenVerticalScrollLockForBossFight
	JMP subMoveSpriteToNextState

Level3BossState1:
	DEC SpriteData2,X ;count down to spawn turrets
	BNE +
	LDA SpriteData3,X ;reload timer
	STA SpriteData2,X
	DEC SpriteData1,X ;count spawns
	BMI ++
	;spawn turret
	LDY SpriteData1,X
	;move this invisible controlling object to the spawn location so an offset is not required
	LDA tblLevel3BossSpreadTurretHorizontalSpawnLocationLB,Y
	STA SpriteAbsoluteHorizPositionLB,X
	LDA tblLevel3BossSpreadTurretHorizontalSpawnLocationUB,Y
	STA SpriteAbsoluteHorizPositionUB,X
	LDA tblLevel3BossSpreadTurretVerticalSpawnLocation,Y
	STA SpriteVertScreenPosition,X
	LDA #$00 ;on screen
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$92 ;object ID ($12 + priority)
	STA $08
	LDA #$01 ;this turret is a boss turret
	STA $09
	LDA #$02 ;palette
	STA $0F
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL + ;If the object correclty spawned, move on
	;Reset parameters to fire again next frame if unable to spawn object
	INC SpriteData1,X
+:
--:	RTS
++:
-:	LDA #$46 ;End of level check
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL + ;If the object correclty spawned, move on
	;Reset parameters to fire again next frame if unable to spawn object
	INC SpriteData1,X
	LDA #$01
	STA SpriteData2,X
	RTS
+:	JMP subMoveSpriteToNextState

;Turrets are defined below, left to right, top to botom
tblLevel3BossSpreadTurretHorizontalSpawnLocationLB:
	db $70,$B8,$B8,$E8,$E8,$28
	
;This determines which screen to spawn on (1 - Right screen)
tblLevel3BossSpreadTurretHorizontalSpawnLocationUB:
	db $00,$00,$00,$00,$00,$01
	
tblLevel3BossSpreadTurretVerticalSpawnLocation:
	db $46,$36,$56,$36,$56,$46

Level3BossState2:
	LDA DifficultyBasedOnWeapon
	CMP #$02 ;Add difficulty for main weapon high (survival)
	BCC -
	DEC SpriteData4,X
	BNE -- ;RTS
	DEC SpriteData5,X
	LDA SpriteData5,X
	AND #$01
	BNE -- ;RTS
	;Spawn a red medium tank every $200 frames if the player has an upgraded main weapon
	LDA #$00
	STA SpriteAbsoluteHorizPositionLB,X
	STA SpriteAbsoluteHorizPositionUB,X
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$EF
	STA SpriteVertScreenPosition,X
	LDA RNG_INCEveryFrame
	CMP #$40
	BCS +
	LDA #$40
+:	CMP #$C0
	BCC +
	LDA #$C0
+:	ASL
	STA $00
	LDA #$00
	ROL
	STA $01
	LDA #$00
	STA $02
	STA $03
	LDA #$07 ;Red medium tank object ID
	STA $08
	LDA #$01
	STA $0F
	JMP subSpawnObjectFromParent_WithOffset

POWBuildingState4:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	;In case of PPU update overload, try this update once more
	;;if this isnt done, the tank/POWs may spawn without the buliding BG being udpated
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	
	LDA #$04 ;default number of POWs
	STA SpriteData4,X
	LDA SpriteObjectID,X
	CMP #$9D ;POW (4) Left Entrance object ID
	BEQ +
	CMP #$9C ;POW (4) Right Entrance object ID
	BEQ +
	LSR SpriteData4,X ;Change to 2 POW spawns
+:	LDA #$00 ;POW type - 0=standing/waving POW
	STA SpriteData5,X
	LDA #$FF ;FF means this is the first POW walking out
	STA SpriteData6,X
	LDA #$40 ;load the timer value for flashing HELP for POW building opened, 20
	STA SpriteData8,X
	LDA #$F0 ;no initial interaction with any other objects or BG
	STA SpriteHitboxShapeIndex,X
	LDA #$00 ;green palette, same as jeep
	STA SpriteGraphicsAttributes,X
	JMP subMoveSpriteToNextState
	
POWBuildingState5:
	LDA #$2D ;POW HELP text object
	STA SpriteTypeIndex,X
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$08
	BNE +
	LDA #$00
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	LDA SpriteData8,X
	BEQ + ;check if HELP timer complete
	RTS
+:	LDA #$00 ;object no longer has visual manifestations
	STA SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

POWBuildingState6:	
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	JSR subSpawnPOW
	BMI + ;If POW was unable to spawn due to no available sprite slot, do not move on
	JMP subMoveSpriteToNextState
+:	RTS

POWBuildingState7:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	LDA SpriteData6,X
	BMI + ;check sprite slot of last POW
	TAX
	LDA SpriteObjectID,X
	CMP #$96 ;POW object ID
	BNE +
	LDA SpriteState,X
	AND #$7F
	CMP #$02
	BCC ++
+:	LDX $35 ;Restore X
	DEC SpriteData4,X ;count POWs spawned
	BEQ +
	JMP subSpawnPOW
++:	LDX $35 ;Restore X
	RTS
+:	JMP subMoveSpriteToNextState

POWPowerUpBuildingState4:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame ;Update BG Graphics
	LDA #$01 ;Set POW to walk around instead of stand still
	STA SpriteData5,X
	JSR subSpawnPOW
	BMI + ;If POW was unable to spawn due to no available sprite slot, do not move on
	JMP subMoveSpriteToNextState
+:	RTS

subSpawnPOW:
	LDA #$96 ;POW sprite with priority (MSB)
	STA $08
	LDA SpriteData5,X
	STA $0A
	LDA SpriteData6,X
	STA $0B
	LDA SpriteWhatDirectionToShoot,X
	STA $0C
	LDA #$00 ;palette
	STA $0F
	JSR subSpawnObjectFromParent_NoOffset
	TYA ;sprite slot
	STA SpriteData6,X
	RTS

;!!!!
;16
;***********
;POW WALKING
;
; SpriteData1 -
; SpriteData2 - Randomize walking new direction, 0 = CW ,1 = CCW
; SpriteData3 -
; SpriteData4 -
; SpriteData5 -
; SpriteData6 -
; SpriteData8 - Walking/Waving timer
;***********
POWWalkingSpriteLogic:

	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw POWWalkingState0
	dw POWWalkingState1
	dw POWWalkingState2
	dw POWWalkingState3
	dw POWWalkingState4
	dw subDespawnSprite

POWWalkingState0: ;Initialize
	LDA #$00 ;not sure why the POW is invisible on the first frame
	STA SpriteTypeIndex,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA RNG_INCEveryFrame
	AND #$01
	STA SpriteData2,X
	JMP subMoveSpriteToNextState

POWWalkingState1:
	LDA #$2B ;POW waving sprite
	STA SpriteTypeIndex,X
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$08
	BNE +
	INC SpriteTypeIndex,X ;alternate walking animation
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData5,X ;This controls if the POW is a power up, or a normal POW
	BNE ++
	LDA SpriteData6,X
	BMI +
	TAX
	LDA SpriteObjectID,X
	CMP #$96 ;POW Walking object ID (with priority)
	BEQ +++
	LDX $35
+:	LDA #$48 ;number of frames POW walks out of barracks, 24
	STA SpriteData8,X
	LDA #$10 ;POW walking speed multiplier 
	STA $08
	JMP +
++:	LDA SpriteData5,X
	AND #$02
	BNE ++
	LDA #$1C
	STA SpriteData8,X
	LDA #$20 ;speed multiplier for Power Up POW exiting building
	STA $08
+:	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState
-:
+++:	LDX $35
	RTS
++:	JSR subMoveSpriteToNextState
	LDA #$10
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JMP ++

POWWalkingState2:
	LDA SpriteData5,X
	BEQ +
	;Power Up POWs flash
	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
+:	LDA #$25 ;POW walking sprite
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$08 ;number of frames to swap POW walking out of building sprite animation
	BNE +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BNE -
	LDA #$10
	STA $08
	LDA RNG_INCEveryFrame
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
++:	JSR subCalculateObjectSpeed
	LDA #$80
	STA SpriteData8,X
	LDA #$73
	STA SpriteHitboxShapeIndex,X
	LDA SpriteData5,X
	BNE +
	JSR subClearSpriteSpeed
	LDA #$01
	STA SpriteData8,X
+:	JMP subMoveSpriteToNextState

POWWalkingState3:
	LDA SpriteData5,X
	AND #$01
	BEQ +
	;Power Up POWs flash
	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
+:	LDA #$25
	STA SpriteTypeIndex,X
	LDA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$08
	BEQ +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	JSR fctGetCollision_WithSpeed_NearLookAhead_BG
	BEQ +
	JSR subClearSpriteSpeed
+:	JSR Label244
	LDA $D7
	BNE +
	LDA SpriteData8,X
	BNE ++ ;RTS
+:	LDA #$63
	STA SpriteData8,X
	JSR subClearSpriteSpeed
	JMP subMoveSpriteToNextState
++:	RTS
	
POWWalkingState4:
	LDA SpriteData5,X
	AND #$01
	BEQ +
	;Power Up POWs flash
	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
+:	LDA #$2B
	STA SpriteTypeIndex,X
	DEC SpriteData8,X
	LDA SpriteData8,X
	AND #$08
	BNE +
	INC SpriteTypeIndex,X
+:	JSR Label244
	LDA SpriteData8,X
	BEQ +
	RTS
+:	LDA #$80
	STA SpriteData8,X
	LDA #$10
	STA $08
	TXA
	LDY SpriteData2,X
	BNE ++
	CLC
	ADC RNG_INCEveryFrame
	JMP +
++:	SEC
	SBC RNG_INCEveryFrame
+:	AND #$1F
	STA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA SpriteData5,X
	BNE +
	;POW is normal
	JMP subClearSpriteSpeed
+:	JMP subMoveSpriteToPreviousState


;27
;***************************
;POW LOADING INTO HELICOPTER
; object that unloads POWs and sends them to the heli (this object turns into a POW)
; SpriteData1 - Frame timer for walking to the heli
; SpriteData2 - Base Sprite Type index
; SpriteData3 - POW count
; SpriteData4 - Player 1/2
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;***************************
POWLoadingIntoHeliSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw POWLoadingIntoHeliState0
	dw POWLoadingIntoHeliState1
	dw subDespawnSprite

POWLoadingIntoHeliState0:
	LDA #$25 ;POW sprite
	STA SpriteTypeIndex,X
	LDA #$00 ;palette
	STA SpriteGraphicsAttributes,X
	STA SpriteAbsoluteVertPositionUB,X
	LDA SpriteData4,X
	TAY ;why not LDY?
	LDA JeepVertScreenPosition,Y
	STA SpriteVertScreenPosition,X
	LDA JeepHorizScreenPosition,Y
	CLC
	ADC ScreenLeftScrollPosition
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$00
	ROL
	STA SpriteAbsoluteHorizPositionUB,X
	LDA JeepPOWCount,Y
	STA SpriteData3,X
	LDA #$10 ;direction, walk left by default
	LDY POWDropOffWalkDirection
	BPL +
	LDA #$00 ;direction, walk right
+:	STA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	LDA SpriteTypeIndex,X
	STA SpriteData2,X
	LDA #JeepPOWWalkToHeliValue
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
	LDA #JeepPOWDropoffSpeedMultiplier
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState

POWLoadingIntoHeliState1:
	LDA SpriteData3,X
	BNE +
	;Last POW flashes
	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
+:	LDA SpriteData2,X
	STA SpriteTypeIndex,X
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$08 ;Alternate POW walking to heli sprite every N frames
	BEQ +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BNE +
	LDA #POWEnteringHeliSoundClip
	JSR subInitiateSoundClip
	LDA SpriteData4,X
	TAY ;why not LDY?
	JSR subGetObjectPointsValue_AddToPlayerScore
	LDX $35
	JMP subDespawnSprite
+:	RTS


;*******************
;POW SPAWN FROM JEEP
;
; SpriteData1 - Number of POWs to spawn
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - Player 1 or 2
; SpriteData5 - POW type (0=standing,2=normal walking,3=power up walking)
; SpriteData6 - The POW on board count from the jeep that died
; SpriteData8 - NOT USED
;*******************
POWSpawnOnJeepDeathSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw POWSpawnOnJeepDeathState0
	dw POWSpawnOnJeepDeathState1
	dw subDespawnSprite

POWSpawnOnJeepDeathState0: ;Initialize
	LDA #$00 ;No visualization
	STA SpriteTypeIndex,X
	STA SpriteAbsoluteVertPositionUB,X
	LDA SpriteData4,X ;Player 1/2
	TAY ;why not LDY?
	;Spawn the POWS on top of where the jeep died
	LDA JeepVertScreenPosition,Y
	STA SpriteVertScreenPosition,X
	LDA JeepHorizScreenPosition,Y
	CLC
	ADC ScreenLeftScrollPosition
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$00
	ROL
	STA SpriteAbsoluteHorizPositionUB,X
	LDA SpriteData6,X
	BEQ ++ ;No POWs in the jeep
	;Jeep has POWs
	SEC
	SBC #$01 ;convert to zero-based count
	BEQ ++
	CMP #$05
	BCC +
	LDA #$04 ;cap the POW spawn to 4
+:	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState
++:	LDA #$00	;Remove all POWs from the jeep
	STA JeepPOWCount,Y
	JMP subDespawnSprite

POWSpawnOnJeepDeathState1: ;Spawn POWs
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BMI ++ ;Check if there are no more POWs to spawn
	;More POWs to spawn
	LDA #$02 ;POW type - walk around
	STA SpriteData5,X
	;Randomize walking direction
	LDA SpriteData1,X
	ASL
	ASL
	ASL
	ADC RNG_INCEveryFrame
	AND #$1F ;max direction is 1F
	STA SpriteWhatDirectionToShoot,X
	BNE +
	;1/32 chance for a POW to be a main weapon power up
	INC SpriteData5,X ;change POW to power up
+:	JMP subSpawnPOW
++:	JMP subMoveSpriteToNextState


;49
;***************************************
;LEVEL 6 BOSS LASER TURRET GRAPHICS LOAD
;
; SpriteData1 - NOT USED
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;***************************************
Level6BossLaserTurretGraphicsLoadSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6BossLaserTurretGraphicsLoadState0
	dw subDespawnSprite

Level6BossLaserTurretGraphicsLoadState0:
	LDA #$00 ;Clear the PPU graphics update complete flag
	STA PPUGraphicsUpdateComplete
	LDA #$10 ;Load the index for tblInGamePalette_GraphicsUpdateActionAddress
	STA PPUGraphicsUpdateTableIndex
	JMP subMoveSpriteToNextState

;!!!!
;4B
;***********************
;LEVEL 6 FINAL BOSS TANK
;
; SpriteData1 -
; SpriteData2 -
; SpriteData3 -
; SpriteData4 -
; SpriteData5 -
; SpriteData6 -
; SpriteData8 -
;***********************
;***********************
Level6FinalBossTankSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6FinalBossTankState0
	dw Level6FinalBossTankState1
	dw Level6FinalBossTankState2
	dw Level6FinalBossTankState3
	dw Level6FinalBossTankState4
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn

Level6FinalBossTankState0:
	LDA #$01
	STA LevelBossEntitiesRemaining
	LDA #$D3
	STA SpriteTypeIndex,X
	LDA #$01
	STA $D5
	LDA #$00
	STA SpriteData2,X
	LDA #$4F
	STA $08
	LDA #$00
	STA $0F
	JSR subSpawnObjectFromParent_NoOffset
	JSR Label462
	LDA Level6BossTankScroll_Next
	STA Level6BossTankScroll_Current
	LDA #$00
	STA SpriteData6,X
	TAY
	LDA tblLevel6BossTankHealthTriggersForChangingPalettes,Y
	STA SpriteData5,X
	JMP subMoveSpriteToNextState

Level6FinalBossTankState1:
	JSR Level6BossTank_CheckForPaletteUpdateOnLowHealth
	;Randomize action based on player position
	LDA RNG_INCEveryFrame
	ADC Jeep1HorizScreenPosition
	ADC Jeep2HorizScreenPosition
	AND #$7F
	CMP #$20
	BCS +
	ORA #$20
+:	STA SpriteData1,X
	JSR Label462
	BCC +
	LDA #$70
	STA SpriteData1,X
+:	LDA #$40
	STA SpriteHorizSpeedLB,X
	LDA #$01
	STA SpriteHorizSpeedUB,X
	LDA #$FF
	STA SpriteData3,X
	LDA SpriteHorizScreenPosition,X
	BPL +
	JSR subInvertSpriteHorizSpeed
	LDA #$01
	STA SpriteData3,X
+:	JMP subMoveSpriteToNextState

Level6FinalBossTankState2:
	JSR Level6BossTank_CheckForPaletteUpdateOnLowHealth
	DEC SpriteData1,X
	BEQ +
	LDA PPUGraphicsUpdateTableIndex
	BNE +
	LDA #$00
	STA PPUGraphicsUpdateComplete
	LDY SpriteData2,X
	LDA tblLevel6BossTankTreadPPUGraphicsUpdateIndex,Y
	STA PPUGraphicsUpdateTableIndex
	LDA SpriteData2,X
	CLC
	ADC SpriteData3,X
	AND #$03
	STA SpriteData2,X
+:	JSR Label462
	BCS Label469
	LDA SpriteData1,X
	BEQ +
	RTS
+:	JSR subClearSpriteSpeed
	;Spawn flame shot controlling object
	LDA #$4C
	STA $08
	LDA #$FC
	STA $00
	LDA #$FF
	STA $01
	LDA #$2E
	STA $02
	LDA #$00
	STA $03
	LDA #$00
	STA $0F
	JSR subSpawnObjectFromParent_WithOffset
	TYA
	BPL +
	INC SpriteData1,X
	RTS
+:	LDA #$00
	STA SpriteData1,X
	STA SpriteData4,X
	JMP subMoveSpriteToNextState
	
;As the tank rolls (scrolls), the tread BG tile are updated to
;;simulate the tread rotating and the tank moving
tblLevel6BossTankTreadPPUGraphicsUpdateIndex:
	db $0A,$0B,$0C,$0D

Level6FinalBossTankState3:
	JSR Level6BossTank_CheckForPaletteUpdateOnLowHealth
	JSR Label462
	BCS Label469
	LDA SpriteData1,X
	AND #$0F
	BNE ++
	INC SpriteData4,X ;count the flame tip spawns (times the flame shot sequence)
	LDA SpriteData4,X
	CMP #$03 ;only spawn a tip at the beginning and end of the flame shot
	BEQ Label469
	;Spawn the flame tip.  this just provides collision for the flame shot
	LDA #$4D
	STA $08
	LDA #$FC
	STA $00
	LDA #$FF
	STA $01
	LDA #$2E
	STA $02
	LDA #$00
	STA $03
	JSR subSpawnObjectFromParent_WithOffset
	TYA
	BMI +
++:	INC SpriteData1,X
+:	RTS

Label469:	JSR subClearSpriteSpeed
	LDA #$01
	JMP subSetSpriteState

Level6FinalBossTankState4:
	JSR subClearSpriteSpeed
	LDA #$F0
	STA SpriteHitboxShapeIndex,X
	LDA #$00
	STA $D5
	JSR Label474
	BEQ +
	RTS
+:	LDA #$00
	STA LevelBossEntitiesRemaining
	INC SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

;Check for Level 6 boss tank at edge of screen
Label462:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteHorizScreenPosition,X
	STA Level6BossTankScroll_Next
	CMP #$30
	BCC ++
	CMP #$D0
	BCS +
-:	CLC
	RTS
++:	LDA SpriteHorizSpeedUB,X
	BEQ ++
	BPL -
	BMI ++
+:	LDA SpriteHorizSpeedUB,X
	BMI -
++:	SEC
	RTS
	
Level6BossTank_CheckForPaletteUpdateOnLowHealth:
	LDA SpriteHealthHP,X
	CMP SpriteData5,X
	BCS +
	LDY SpriteData6,X
	INC SpriteData6,X
	LDA tblLevel6FinalBossTankPaletteUpdateIndex,Y
	JSR Label152 ;some kind of PPU init for in-game updates
	LDX $35
	LDY SpriteData6,X
	LDA tblLevel6BossTankHealthTriggersForChangingPalettes,Y
	STA SpriteData5,X
	LDA #$81 ;Indicate that the turret should change palettes (low health)
	STA $D5
+:	RTS

;Index in the tblPPUGraphics_PalleteUpdateAddress table
;;for updating the PPU palettes as the tank reaches low health
tblLevel6FinalBossTankPaletteUpdateIndex:
	db $30,$31,$00
	
tblLevel6BossTankHealthTriggersForChangingPalettes:
	db $AA,$95,$00


;4C
;**********************************
;LEVEL 6 FINAL BOSS TANK FLAME SHOT
;This generates the graphics and animation for the flame shot
; SpriteData1 - Base sprite type index
; SpriteData2 - Base mirrored sprite type index
; SpriteData3 - Flag indicating flame shot has fully emerged
; SpriteData4 -
; SpriteData5 -
; SpriteData6 -
; SpriteData8 - Number of animations for the long flame (different sprite visualizations)
; $06E0 (SpriteData9) - Flame shot emerge timer (also mirrors sprite)
;**********************************
Level6FinalBossTankFlameShotSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6FinalBossTankFlameShotState0
	dw Level6FinalBossTankFlameShotState1

Level6FinalBossTankFlameShotState0: ;Initialize
	LDA #$00 ;default to not mirrored
	STA $06E0,X
	LDA #$10
	STA SpriteData8,X
	LDA #$D5
	STA SpriteData1,X
	LDA #$E5
	STA SpriteData2,X
	LDA #$00
	STA SpriteData3,X
	JSR subUpdateSpritePositionForScrolling
	LDA #Level6FinalBossTankFlameShotSoundClip
	JSR subInitiateSoundClip
	JMP subMoveSpriteToNextState

Level6FinalBossTankFlameShotState1:
	LDA SpriteData1,X ;start with the base sprite
	STA SpriteTypeIndex,X
	INC $06E0,X
	LDA $06E0,X
	AND #$01
	BEQ +
	;Load mirrored base sprite
	LDA SpriteData2,X
	STA SpriteTypeIndex,X
+:	LDA $06E0,X
	CMP SpriteData8,X
	BNE +
	;Flame shot has fully emerged
	;The flame shot has no speed initially, the sprite render just grows
	;;Once emerged, the flame shot moves downward at half speed
	;;(because the sprite manifestation is made tiles of 8x8 pixels, so 4 = 8/2)
	LDA #$04 ;this should maybe be $08, as the flame tips move at 8.
	STA SpriteVertSpeedUB,X
	LDA #$01 ;emerge complete
	STA SpriteData3,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	;Despawn the flame if the player scrolls the screen to far either way
	LDA SpriteHorizScreenPosition,X
	CMP #$20
	BCC ++
	CMP #$E0
	BCS ++
	LDA SpriteData3,X
	BNE +
	;flame shot is growing
	INC SpriteData1,X ;Go to next sprite rendering - makes flame shot longer
	INC SpriteData2,X ;do the same for the mirrored version
+:	RTS
++:	JMP subDespawnSprite


;**************************************
;LEVEL 6 FINAL BOSS TANK FLAME SHOT TIP
;
; SpriteData1 - NOT USED
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
Level6FinalBossTankFlameShotTipSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6FinalBossTankFlameShotTipState0
	dw Level6FinalBossTankFlameShotTipState1

Level6FinalBossTankFlameShotTipState0:
	;flame shot graphics move at $4
	;;this is an error - the hitbox here doesn't move along with the flame shot
	;;this is not perceivable by the player though.  the flame moves quickly enough
	;;that the player may not notice the variable hitbox location.
	;;especially since the flame is only encounterable over half the screen
	LDA #$08
	STA SpriteVertSpeedUB,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState
	
Level6FinalBossTankFlameShotTipState1:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	;despawn the hitboxes here along with the flame animation
	;;if the player scrolls the screen far enough either way
	LDA SpriteHorizScreenPosition,X
	CMP #$20
	BCC +
	CMP #$E0
	BCS +
	RTS
+:	JMP subDespawnSprite
	

;!!!!
;4F
;************************
;LEVEL 6 BOSS TANK TURRET
;
; SpriteData1 -
; SpriteData2 -
; SpriteData3 -
; SpriteData4 -
; SpriteData5 -
; SpriteData6 -
; SpriteData8 -
;************************
Level6BossTankTurretSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6BossTankTurretState0
	dw Level6BossTankTurretState1
	dw Level6BossTankTurretState2
	dw Level6BossTankTurretState3
	dw Level6BossTankTurretState4
	dw subSpriteDeath
	dw subSpriteExplosion

Level6BossTankTurretState0:	
	LDA #$FC
	STA SpriteTypeIndex,X
	LDA #$08
	STA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	TYA ;Does nothing...
	LDA SpriteData6,X
	LDA #$02
	STA SpriteData3,X
	STA SpriteData2,X
	JSR subCheckWhichJeepToAttack
	LDA #$20
	STA SpriteVertScreenPosition,X
	JSR Label486
	JMP subMoveSpriteToNextState

Level6BossTankTurretState1:
	LDA #$FC
	STA SpriteTypeIndex,X
	LDA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	TYA
	STA SpriteData6,X
	JSR Label486
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	JSR subCalculateDirectionTowardJeep
	SEC
	SBC SpriteData5,X
	BEQ +++
	DEC SpriteData2,X
	BNE ++
	TAY
	LDA SpriteData3,X
	STA SpriteData2,X
	TYA
	AND #$10
	BNE +
	LDA SpriteData5,X
	CLC
	ADC #$01
	AND #$1F
	STA SpriteData5,X
	RTS
+:	LDA SpriteData5,X
	SEC
	SBC #$01
	AND #$1F
	STA SpriteData5,X
++:
-:	RTS
+++:	LDA SpriteState,X
	BMI -
	LDA #$40
	STA SpriteData1,X
	JSR Label490
	JMP subMoveSpriteToNextState

Level6BossTankTurretState2:
	JSR Label486
	DEC SpriteData1,X
	LDA SpriteData1,X
	BEQ +
	AND #$0F
	BNE -
	LDA #$03 ;Number of frames for turret to recoil
	STA SpriteData8,X
	JSR SpawnTurretProjectile
	JSR Label493
	JMP subMoveSpriteToNextState
+:	LDA #$01
	JMP subSetSpriteState

Level6BossTankTurretState3:
	JSR Label486
	DEC SpriteData8,X
	BNE + ;RTS
	LDA #$03
	STA SpriteData8,X
	JSR subInvertSpriteVertAndHorizSpeed
	JMP subMoveSpriteToNextState
+:	RTS

Level6BossTankTurretState4:
	DEC SpriteData8,X
	BNE +
+:	JSR Label486
	LDA SpriteData8,X
	BNE +
	JSR subClearSpriteSpeed
	LDY $D5
	BEQ ++
	LDA #$02
	JMP subSetSpriteState
+:	RTS
++:	JMP subMoveSpriteToNextState

Label486:
	LDA Level6BossTankScroll_Next
	CLC
	ADC $40
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$00
	ROL
	STA SpriteAbsoluteHorizPositionUB,X
	LDA SpriteAbsoluteHorizPositionLB,X
	CLC
	ADC #$07
	STA SpriteAbsoluteHorizPositionLB,X
	LDA SpriteAbsoluteHorizPositionUB,X
	ADC #$00
	STA SpriteAbsoluteHorizPositionUB,X
	LDA $D5
	BPL +
	LDA #$01
	STA SpriteGraphicsAttributes,X
+:	JMP subUpdateSpritePositionForScrolling_Speed_CheckForDespawn

;Check for infantry collision?
Label247:
	LDA #$00
	LDY SpriteHorizSpeedUB,X
	BPL +
	LDA #$FF
+:	STA $14
	LDA SpriteHorizSpeedLB,X
	ASL
	STA $10
	LDA SpriteHorizSpeedUB,X
	ROL
	STA $11
	LDA $05C0,X
	CLC
	ADC $10
	LDA SpriteAbsoluteHorizPositionLB,X
	ADC $11
	STA $10
	LDA SpriteAbsoluteHorizPositionUB,X
	ADC $14
	STA $11
	LDA #$00
	LDY SpriteVertSpeedUB,X
	BPL +
	LDA #$FF
+:	STA $14
	LDA SpriteVertSpeedLB,X
	ASL
	STA $12
	LDA SpriteVertSpeedUB,X
	ROL
	STA $13
	LDA SpriteVertScreenPositionSubPixel,X
	CLC
	ADC $12
	LDA SpriteVertScreenPosition,X
	ADC $13
	STA $12
	LDA SpriteAbsoluteVertPositionUB,X
	ADC $14
	STA $13
	;Check all other sprites for collision?
	LDX #$0F
-:	LDA SpriteObjectID,X
	BEQ +++ ;Check next sprite - Ignore NULL objects
	CMP #$34	;Flame object ID
	BCS +++ ;Check next sprite
	CPX $35
	BEQ +++ ;Check next sprite
	LDA SpriteAbsoluteHorizPositionLB,X
	SEC
	SBC $10
	STA $15
	LDA SpriteAbsoluteHorizPositionUB,X
	SBC $11
	BNE +
	LDA $15
	CMP #$10
	BCC ++
	BCS +++ ;Check next sprite
+:	CMP #$FF
	BNE +++ ;Check next sprite
	LDA $15
	CMP #$F0
	BCC +++ ;Check next sprite
++:	LDA SpriteVertScreenPosition,X
	SEC
	SBC $12
	STA $15
	LDA SpriteAbsoluteVertPositionUB,X
	SBC $13
	BNE +
	LDA $15
	CMP #$10
	BCC ++
	BCS +++ ;Check next sprite
+:	CMP #$FF
	BNE +++ ;Check next sprite
	LDA $15
	CMP #$F0
	BCC +++ ;Check next sprite
++:	SEC
	JMP +

+++:
	DEX ;Go to the next sprite slot
	BPL - ;Process another sprite slot
	CLC
+:	LDX $35
	RTS

fctGetCollision_WithSpeed_NearLookAhead_BG:	
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC #$08
	AND #$1F
	STA $03
	AND #$0F
	TAY
	LDA tblCollisionCheckBGOffsetNearLB,Y
	STA $00
	LDA tblCollisionCheckBGOffsetNearUB,Y
	STA $01
	LDA #$00
	STA $02
	LDA $03
	AND #$10
	BEQ +
	JSR fctInvert24Bit
+:	JSR fctAddToSpriteHorizPosition_24bit
	LDA SpriteWhatDirectionToShoot,X
	AND #$1F
	STA $03
	AND #$0F
	TAY
	LDA tblCollisionCheckBGOffsetNearLB,Y
	STA $01 ;should be $00?  almost certainly a coding error and oversight.  but this looks to be subpixel so not a big issue
	LDA tblCollisionCheckBGOffsetNearUB,Y
	STA $01
	LDA #$00
	STA $02
	LDA $03
	AND #$10
	BEQ +
	JSR fctInvert24Bit
+:	JMP fctAddToSpriteVertPosition_24bit_TestCollision

fctGetCollisionType_SwampInfantry:
	LDA #$00
	STA $00
	STA $01
	STA $02
	JSR fctAddToSpriteHorizPosition_24bit
	JMP fctAddToSpriteVertPosition_24bit_TestCollision
	
fctGetCollision_WithSpeed_FarLookAhead_BG:
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC #$08
	AND #$1F
	STA $03
	AND #$0F
	TAY
	LDA tblCollisionCheckBGOffsetFarLB,Y
	STA $00
	LDA tblCollisionCheckBGOffsetFarUB,Y
	STA $01
	LDA #$00
	STA $02
	LDA $03
	AND #$10
	BEQ +
	JSR fctInvert24Bit
+:	JSR fctAddToSpriteHorizPosition_24bit
	LDA SpriteWhatDirectionToShoot,X
	AND #$1F
	STA $03
	AND #$0F
	TAY
	LDA tblCollisionCheckBGOffsetFarLB,Y
	STA $01 ;should be $00?  almost certainly a coding error and oversight.  but this looks to be subpixel so not a big issue
	LDA tblCollisionCheckBGOffsetFarUB,Y
	STA $01
	LDA #$00
	STA $02
	LDA $03
	AND #$10
	BEQ fctAddToSpriteVertPosition_24bit_TestCollision
	JSR fctInvert24Bit
	
	;Looks like this is looking ahead, calculating a new vertical position
	;;based on the speed to see if collision is an issue next frame
fctAddToSpriteVertPosition_24bit_TestCollision:
	LDA SpriteVertScreenPositionSubPixel,X
	CLC
	ADC $00
	STA $13
	LDA SpriteVertScreenPosition,X
	ADC $01
	STA $14
	LDA SpriteAbsoluteVertPositionUB,X
	ADC $02
	STA $15
	JSR fctTestForMovementCollision
	STA $D7
	RTS
	
	;Looks like this is looking ahead, calculating a new horizontal position
	;;based on the speed to see if collision is an issue next frame
fctAddToSpriteHorizPosition_24bit:
	LDA SpriteHorizScreenPositionSubPixel,X
	CLC
	ADC $00
	STA $10
	LDA SpriteAbsoluteHorizPositionLB,X
	ADC $01
	STA $11
	LDA SpriteAbsoluteHorizPositionUB,X
	ADC $02
	STA $12
	RTS

;These tables seem to allow the moving enemies to check in front of their
;;movement direction for collision with BG tiles
tblCollisionCheckBGOffsetFarUB:
	db $00,$03,$06,$08,$0B,$0D,$0E,$0F,$10,$0F,$0E,$0D,$0B,$08,$06,$03
tblCollisionCheckBGOffsetFarLB:
	db $00,$1F,$1F,$E3,$50,$4D,$C8,$B1,$00,$B1,$C8,$4D,$50,$E3,$1F,$1F
	
tblCollisionCheckBGOffsetNearUB:	
	db $00,$01,$03,$04,$05,$06,$07,$07,$08,$07,$07,$06,$05,$04,$03,$01
tblCollisionCheckBGOffsetNearLB:
	db $00,$8F,$0F,$71,$A8,$A6,$64,$D8,$00,$D8,$64,$A6,$A8,$71,$0F,$8F
	

;4E,53
;****************
;PARKED JEEP/TANK
;
; SpriteData1 - BG update table index
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Explosion timer
;****************
ParkedJeepTankSpriteLogic:
	
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw ParkedJeepTankState0
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	dw subPlayExplosionSound_LoadNewBGGraphics
	dw ParkedJeepTankState3
	dw subScrollSprite_CheckForDespawn_UpdateBG

ParkedJeepTankState0:
	;Jeep/Tank is displayed as part of BG.  this sprite has no SpriteType or visual manifestation
	JSR subUpdateSpritePositionForScrolling
	LDA #$1C
	STA SpriteData1,X ;BG to load on jeep explosion
	LDA CurrentLevel
	CMP #$02 ;Level 3
	BEQ +
	LDA #$18 ;BG to load on tank explosion
	STA SpriteData1,X
+:	JMP subMoveSpriteToNextState

;State 1 just scrolls the sprite around waiting for the player to shoot it
;;If scrolled off screen, code in Bank 7 will despawn this (all sprites do this)

ParkedJeepTankState3:
	DEC SpriteData8,X ;Frames to display explosion animation or such.  occurs after dying
	LDA SpriteData8,X
	BEQ +
	AND #$07 ;Number of frames to display each explosion graphic
	BNE +
	INC SpriteTypeIndex,X ;Go to the next explosion graphic
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	LDA SpriteData8,X
	BNE ++ ;RTS
	LDA #$00 ;unnecessary because the sprite has no visual aspect
	STA SpriteTypeIndex,X
	STA $0F ;Set graphics/attributes for star spawn
	LDA SpriteObjectID,X
	CMP #$D3 ;Parked jeep/tank object ID with star under it(assumed priority - MSB)
	BNE +
	LDA #$D1 ;Spawn mas weapon star underneath jeep/tank
	STA $08
	STA $09
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL +
	INC SpriteData8,X
++:	RTS
+:	JMP subMoveSpriteToNextState

	.PAD $A151	
tblLevel4ObjectSpawn: ;header addresses
;a list of level spawns by screen number

	.PAD $A169
;Level 4 object spawns
;Each spawn consumes 3 bytes (except F0,F1,F2 objects - see Label978)
;Byte 1 = Vertical screen position at which to spawn the object
;Byte 2 = Horizontal screen position at which to spawn the object (is every 4 pixels [2 screens wide is $00 - $80)
;;	MSB on byte 2 indicates the object spawns at the bottom of the screen, not the top
;Byte 3 - Sprite Object ID

;F0,F1,F2 objects use 2 bytes:
;Byte 1 - Sprite Object ID (F0,F1,F2 only)
;Byte 2 - vertical Vertical screen position at which to spawn the object


	.PAD $A28D	
;********************
;LEVEL 4 SPREAD TRUCK
;
; SpriteData1 - State machine timer.  firing, wait, and time between bullets
; SpriteData2 - Counts sets of bullets fired (direction spread of next bullets)
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - Direction to shoot (1st bullet)
; SpriteData8 - NOT USED
;********************
Level4SpreadTruckSpriteLogic:

	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level4SpreadTruckState0
	dw Level4SpreadTruckState1
	dw Level4SpreadTruckState2
	dw Level4SpreadTruckState3
	dw Level4SpreadTruckState4 ;same as state 3
	dw subSpriteDeath
	dw subSpriteExplosion

Level4SpreadTruckState0:
LDA #$67
	STA SpriteTypeIndex,X
	LDA #$04 ;Initial wait delay
	STA SpriteData1,X
	LDA #$04 ;Load DOWN-RIGHT direction to shoot
	LDY SpriteObjectID,X
	CPY #$2A ;Right Facing Spread Truck
	BEQ +
	;Handle Left Facing Spread Truck
	LDA #$40 ;Mirror the Spread Truck facing the opposite direction
	STA SpriteAttributes,X
	LDA #$0C ;Load DOWN-LEFT direction to shoot
+:	STA SpriteData6,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level4SpreadTruckState1: ;waiting
	LDA #$67 ;Sprite rendering without recoil
	STA SpriteTypeIndex,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE +
	LDA #$05
	STA SpriteData1,X
	JMP subMoveSpriteToNextState
+:	RTS

Level4SpreadTruckState2: ;Fire bullet 1
	LDA #$67
	STA SpriteTypeIndex,X
	DEC SpriteData1,X
	LDA SpriteData1,X
	BPL +
	INC SpriteTypeIndex,X ;Recoil animation
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BNE +
	LDA SpriteData6,X
	STA SpriteWhatDirectionToShoot,X
	JMP lblLevel4SpreadTruckFire
+:	CMP #$FC
	BNE +
	LDA #$05 ;time between firing bullets
	STA SpriteData1,X
	LDA #$01 ;first bullet
	STA SpriteData2,X
	JMP subMoveSpriteToNextState
-:
+::	RTS

Level4SpreadTruckState3:
Level4SpreadTruckState4:
	LDA #$67
	STA SpriteTypeIndex,X
	DEC SpriteData1,X ;bullet fire timer
	LDA SpriteData1,X
	BPL +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BNE +
	LDA SpriteData6,X
	CLC
	ADC SpriteData2,X ;Add bullet CW
	STA SpriteWhatDirectionToShoot,X
	JSR lblLevel4SpreadTruckFire
	LDA SpriteData6,X
	SEC
	SBC SpriteData2,X ;Add bullet CCW
	STA SpriteWhatDirectionToShoot,X
	JMP lblLevel4SpreadTruckFire
+:	CMP #$FC
	BNE - ;RTS
	LDA #$05 ;reset bullet timer
	STA SpriteData1,X
	INC SpriteData2,X
	JSR subMoveSpriteToNextState
	LDA SpriteState,X
	AND #$7F
	CMP #$04
	BEQ +
	LDA #$30 ;reset idle timer
	STA SpriteData1,X
	LDA #$01
	JMP subSetSpriteState
+:
-:	RTS

lblLevel4SpreadTruckFire:
	LDA SpriteState,X
	BMI - ;Check if truck is offscreen
	LDY #$08
	JMP SpawnEnemyRoundBullet_Shell


;********************
;LEVEL 4 FALLING ROCK
;
; SpriteData1 - Movement timer (used to pull speed values too)
; SpriteData2 - State in the movement sequence (0 - 5)
; SpriteData3 - direction offset for speed
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - 1/8 circle passed jeep CW
; SpriteData8 - Explosion timer
;********************
Level4FallingRockSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level4FallingRockState0
	dw Level4FallingRockState1
	dw Level4FallingRockState2
	dw Level4FallingRockState3
	dw subSpriteDeath
	dw subSpriteExplosion

Level4FallingRockState0:
	LDA #$7C
	STA SpriteTypeIndex,X
	LDA RNG_INCEveryFrame
	AND #$C0 ;mirroring
	STA SpriteAttributes,X
	LDA #$60 ;total movement frames
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level4FallingRockState1:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteState,X
	BMI + ;Avoid reacting when off screen
	LDA RNG_INCEveryFrame
	AND #$03 ;I assume this is for lag reduction - only check player every 4 frames
	BNE +
	;Check player 2
	LDA #$00
	STA SpriteWhichJeeptoAttack,X
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	BCS ++
	;Player 1 alive, check
	LDA Jeep1VertScreenPosition
	SEC
	SBC SpriteVertScreenPosition,X
	CMP #$40
	BCC +++
	;Check player 2
	LDA #$80
	STA SpriteWhichJeeptoAttack,X
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	BCS +
	;Player 2 alive, check
++:	LDA Jeep2VertScreenPosition
	SEC
	SBC SpriteVertScreenPosition,X
	CMP #$40
	BCC +++
-:	;Neither jeep is close enough
+:	RTS
	
	;Player is near enough
+++:	;The rock always rolls in front of the player
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	CLC
	ADC #$04
	AND #$1F
	STA SpriteData6,X
	AND #$08
	BEQ +
	;3rd quadrant
	LDA SpriteData6,X
	AND #$07
	BNE -
	;Upper half of 3rd quadrant, closest to the horizontal
+:	LDA SpriteData6,X
	LDY SpriteObjectID,X
	CPY #$2F ;Left Rolling Rock
	BNE +
	AND #$10
	BEQ ++
	BNE +++
+:	AND #$10
	BEQ +++
	;This code mirrors the direction around the vertical
	;;1st quadrant is mirrored into the 2nd qudrant and vice versa
	;;3rd quadrant is mirrored into the 4th quadrant and vice versa
	;;forces right falling rocks to fall right, and left to the left
++:	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC #$10
	JSR fctInvertA
	AND #$1F
	STA SpriteWhatDirectionToShoot,X
+++:	JMP subMoveSpriteToNextState

Level4FallingRockState2: ;Rolling/falling
	LDA #$02 ;Default to CW by 2 angles
	STA SpriteData3,X
	DEC SpriteData1,X ;count down movement
	LDA SpriteData1,X
	AND #$01
	BEQ + ;alternate every other frame
	LDA #$FE ;Change speed CCW by 2 angles
	STA SpriteData3,X
	LDA SpriteAttributes,X
	CLC
	ADC #$40 ;mirror horiz, then vert, then both, then neither (rotation)
	STA SpriteAttributes,X
+:	LDY SpriteData2,X
	LDA tblFallingRockSpeedList,Y
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	CLC
	ADC SpriteData3,X
	JSR subCalculateObjectSpeed
	LDA SpriteData1,X
	CMP #$30
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BEQ ++
	AND #$0F
	BNE +
	INC SpriteData2,X
+:
-:	RTS
++:	JSR subClearSpriteSpeed
	JMP subMoveSpriteToNextState
	
tblFallingRockSpeedList: ;defines the movement of the rock - simulates accel/decel
	db $10,$20,$50,$40,$20,$10
	
Level4FallingRockState3: ;Idle after fall
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR Label247 ;This seems to only detect collision with infantry/walking units?
	BCC -
	LDA #$00 ;If this object needs to be destoryed due to this collision, the player gets no points
	STA EnemyPoints,X
	JMP subMoveSpriteToNextState

;*********************
;MOBILE SWAMP INFANTRY
;
; SpriteData1 - Tracks target position to walk towards around jeep.  0=right of jeep, 2=beneath jeep, 4=left of jeep, 6=above jeep
; SpriteData2 - 01 = clockwise, FF = counter clockwise
; SpriteData3 - Horizontal LB position to walk towards
; SpriteData4 - Horizontal UB position to walk towards
; SpriteData5 - Vertical LB position to walk towards
; SpriteData6 - Vertical UB position to walk towards
; SpriteData8 - Timer for walking animation, flashing, firing, etc
;***************
MobileSwampInfantrySpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw MobileInfantryState0
	dw MobileInfantryState1
	dw MobileSwampInfantryState2
	dw MobileSwampInfantryState3
	dw MobileSwampInfantryState4
	dw MobileSwampInfantryState5
	dw MobileSwampInfantryState6
	dw subInfantryDeath
	dw subInfantryDeathAnimation

MobileSwampInfantryState2:
	LDA #$12 ;normal walking infantry
	STA SpriteTypeIndex,X
	JSR fctGetCollisionType_SwampInfantry ;uses a speed of 0 (gets current tile collision value)
	CMP #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$74 ;swamp infantry
	STA SpriteTypeIndex,X
+:	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	CMP #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$00
	STA $D7
+:	LDA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	LDA $D7
	JMP Label543 ;normal infantry code
	
MobileSwampInfantryState3:
MobileSwampInfantryState4:
	LDA #$12
	STA SpriteTypeIndex,X
	JSR fctGetCollisionType_SwampInfantry ;uses a speed of 0 (gets current tile collision value)
	CMP #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$74
	STA SpriteTypeIndex,X
+:	LDA SpriteWhatDirectionToShoot,X
	JSR subProcessWalkingAnimation
	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	LDA #$01
	LDY $D7
	CPY #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$00
	STA $D7
	LDA #$02 ;speed  multiplier
+:	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA SpriteData8,X
	AND #$08
	BEQ +
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
+:	LDA $D7
	JMP Label547 ;normal infantry code

MobileSwampInfantryState5:
	LDA #$12
	STA SpriteTypeIndex,X
	JSR fctGetCollisionType_SwampInfantry ;uses a speed of 0 (gets current tile collision value)
	CMP #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$74
	STA SpriteTypeIndex,X
+:	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	CMP #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$00
	STA $D7
+:	JMP Label550 ;normal infantry code

MobileSwampInfantryState6:
	LDA #$12
	STA SpriteTypeIndex,X
	JSR fctGetCollisionType_SwampInfantry ;uses a speed of 0 (gets current tile collision value)
	CMP #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$74
	STA SpriteTypeIndex,X
+:	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	CMP #$03 ;in Level 4, this collision is with a swamp tile
	BNE +
	LDA #$00
	STA $D7
+:	JMP Label553 ;normal infantry code


;2D
;*******************************
;LEVEL 4 SUNKEN MISSILE LAUNCHER
;
; SpriteData1 - NOT USED
; SpriteData2 - State timer
; SpriteData3 - Idle timer default/reload value
; SpriteData4 - Animation state counter
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Explosion/animation timer value
;*******************************
Level4SunkenMissileLauncherSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level4SunkenMissileLauncherState0
	dw Level4SunkenMissileLauncherState1
	dw Level4SunkenMissileLauncherState2
	dw Level4SunkenMissileLauncherState3
	dw subSpriteDeath
	dw subSpriteExplosion

Level4SunkenMissileLauncherState0: ;Initialize
	LDA #$6C
	STA SpriteTypeIndex,X
	LDA #$04 ;Time in frames to show each launch animation for submerged launcher
	STA SpriteData8,X
	LDA #$80 ;time between missile launches
	STA SpriteData2,X
	STA SpriteData3,X ;Store missile launch count down timer for reloading later
	LDA #$18 ;Always shoot upwards (not necessary?  the missile spawn code sets the missile to #$18 explicitly..)
	STA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level4SunkenMissileLauncherState1: ;Idle
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X
	LDA SpriteData2,X ;DEC sets the Z flag.  this LDA is unnecessary
	BEQ ++
	AND #$03
	BEQ +
	;Mirrors graphics 3 out of 4 frames
	;;The sunnken launcher is drawn with about half of the image somewhat absent
	;;This code mirrors this sprite back and forth to make the launcher
	;;look hidden, half visible
	;;A better way would be to use EOR
	LDA SpriteAttributes,X
	CLC
	ADC #$40 ;change horiz mirroring
	AND #$40 ;this forces palette 0 and no vertical mirroring
	STA SpriteAttributes,X
+:
-:	RTS
	;Idle time is over
++:	LDA SpriteData8,X
	STA SpriteData2,X
	LDA #$03
	STA SpriteData4,X
	JMP subMoveSpriteToNextState

Level4SunkenMissileLauncherState2: ;Animate up and fire missile
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X ;count individual animation time
	BNE -
	DEC SpriteData4,X ;count animations
	BEQ +
	LDA SpriteData8,X ;Reload the animation frame length
	STA SpriteData2,X
	INC SpriteTypeIndex,X ;next animation
	RTS
+:	LDA SpriteState,X
	BMI ++
	;Launch missile
	LDA #$39 ;B/W Missile ID
	STA $08
	LDA #$70 ;missile sprite type index (BW missile)
	STA $0A
	LDA #$02 ;targetting style.  03 and 04 are fast downward.  02 is normal circular missle motion (probalby level 2 missles as well)
	STA $0B
	LDA #$18 ;Always shoot up
	STA $0C
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BMI +
	;Missile spawned successfully
++:	LDA SpriteData8,X
	STA SpriteData2,X
	LDA #$03
	STA SpriteData4,X
	JMP subMoveSpriteToNextState
	;Missile failed to spawn
+:	INC SpriteData2,X ;try again next frame
	INC SpriteData4,X
	RTS

Level4SunkenMissileLauncherState3: ;Animate down
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X ;individual animation time
	BNE ++ ;RTS
	DEC SpriteData4,X ;count animations
	BEQ +
	LDA SpriteData8,X ;reload time for next animation
	STA SpriteData2,X
	DEC SpriteTypeIndex,X ;animate backwards
++:	RTS
+:	LDA SpriteData3,X ;reload idle time
	STA SpriteData2,X
	LDA #$01
	JMP subSetSpriteState


;2C
;************************
;LEVEL 4 MISSILE LAUNCHER -cliff tops
;
; SpriteData1 - NOT USED
; SpriteData2 - State machine timer
; SpriteData3 - Idle time value
; SpriteData4 - Animation count
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Explosion/Animation timer value
;****************
Level4MissileLauncherSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level4MissileLauncherState0
	dw Level4MissileLauncherState1
	dw Level4MissileLauncherState2
	dw subSpriteDeath
	dw subSpriteExplosion

Level4MissileLauncherState0: ;Initialize
	LDA #$69
	STA SpriteTypeIndex,X
	LDA #$08 ;Missile launch animation frames
	STA SpriteData8,X 
	LDA #$80 ;#frames between missile launches
	STA SpriteData2,X ;Load the initial count down timer
	STA SpriteData3,X ;Store the timer reload value
	LDA #$18 ;Always shoot up (unnecessary)
	STA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level4MissileLauncherState1: ;Waiting to launch missile
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X ;Count down to missile launch
	BNE + ;RTS
	LDA SpriteData8,X ;Load the number of frames to show the missile launch animation
	STA SpriteData2,X
	LDA #$02 ;Animation count (show missile launch, then back to normal)
	STA SpriteData4,X
	JMP subMoveSpriteToNextState
-:
+:	RTS

Level4MissileLauncherState2:	;Launching missile animation/Launch Missile
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X ;Timing for displaying launch animation
	BNE - ;RTS
	DEC SpriteData4,X
	BEQ +
	LDA SpriteData8,X ;Load the animation timer again for second animation
	STA SpriteData2,X
	INC SpriteTypeIndex,X ;Get the next missile launch animation
	RTS
+:	LDA SpriteState,X
	BMI +
	;Spawn BW missile
	LDA #$39 ;BW Missile object ID
	STA $08
	LDA #$70 ;BW Missile sprite type index
	STA $0A
	LDA #$02 ;Missile type
	STA $0B
	LDA #$18 ;ALways shoot up to start
	STA $0C
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BMI ++
	;Missile spawned successfully
+:	LDA #$69
	STA SpriteTypeIndex,X
	LDA SpriteData3,X ;Reload idle time
	STA SpriteData2,X
	LDA #$01
	JMP subSetSpriteState
	;Missile failed to spawn
++:	INC SpriteData2,X ;Try again next frame
	INC SpriteData4,X
	RTS


;32
;*************
;LEVEL 4 TRAIN - controlling object
;This object must spawn at the bottom of the screen
; SpriteData1 - Time between engine/car spawns
; SpriteData2 -
; SpriteData3 -
; SpriteData4 -
; SpriteData5 -
; SpriteData6 -
; SpriteData8 -
;****************
Level4TrainSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level4TrainState0
	dw Level4TrainState1
	dw Level4TrainState2
	dw subDespawnSprite

Level4TrainState0: ;Enitialize
	LDA #$80
	STA SpriteData4,X
	LDA #$FF
	STA $D4
	LDA #$18
	STA SpriteData1,X
	STA SpriteData2,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level4TrainState1: ;Spawn engine
	JSR Label244
	;Spawn engine
	LDA #$33 ;Engine/Car Object ID
	STA $08
	LDA SpriteData4,X
	STA $09 ;Train car type (engine/car)
	LDA #$02 ;palette
	STA $0F
	;engine spawns on top of this invisible controlling object
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BMI +
	;Engine spawned successfully
	LSR SpriteData4,X ;Shift bit to spawn next vehicle (1st car)
--:	JMP subMoveSpriteToNextState
-:	;Engine failed to spawn.  try again next frame
+::	RTS

Level4TrainState2: ;Spawn cars
	JSR Label244
	DEC SpriteData1,X ;time delay between spawns
	BNE - ;RTS
	LDA SpriteData2,X ;reload spawn timer
	STA SpriteData1,X
	;Spawn car
	LDA #$33 ;Engine/Car Object ID
	STA $08
	LDA SpriteData4,X
	STA $09 ;Train car type (engine/car)
	LDA #$01
	STA $0F ;palette
	;No offset is required because this object is at the bottom of the screen and does not move
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BMI -- ;If a car fails to spawn, simply despawn this object and stop trying
	LSR SpriteData4,X ;shift bit to get next car
	BEQ -- ;Can spawn a max of 1 engine and 7 cars (because SpriteData4 starts out at $80)
	RTS


;33
;*****************
;LEVEL 4 TRAIN CAR
;
; SpriteData1 -
; SpriteData2 -
; SpriteData3 -
; SpriteData4 - Engine/Car type
; SpriteData5 - Frame counter
; SpriteData6 - Alternating frame counter
; SpriteData8 - Explostion timer
;****************
Level4TrainCarSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level4TrainCarState0
	dw Level4TrainCarState1
	dw subSpriteDeath
	dw Level4TrainCarState3

Level4TrainCarState0:
	LDA #$A5
	LDY SpriteData4,X ;MSB=1 is engine.  each bit represents a car position
	BMI +
	LDA #$A8 ;Car sprite
+:	STA SpriteTypeIndex,X
	LDA #$FF ;never shoots
	STA SpriteData2,X
	LDA SpriteData4,X
	AND #$55 ;every other train car shoots bullets
	BEQ +
	LDA #$1F ;shoots every $20 frames
	STA SpriteData2,X
+:	JSR subUpdateSpritePositionForScrolling
	LDA #$30 ;speed multiplier
	STA $08
	LDA #$18 ;Always travel upwards
	JSR subCalculateObjectSpeed
	JSR subCheckWhichJeepToAttack
	LDA #$00
	STA SpriteData5,X
	STA SpriteData6,X
	JMP subMoveSpriteToNextState

Level4TrainCarState1:
	INC SpriteData5,X ;Allows SpriteData6 to count every other frame.  pointless
	LDA SpriteData5,X
	AND #$01
	BEQ +
	INC SpriteData6,X
	LDA SpriteData6,X
	CMP #$73 ;entering tunnel
	BEQ ++
	CMP #$78 ;disappeared into tunnel (behind BG layer 1)
	BNE +
++:	INC SpriteTypeIndex,X ;Alter sprite layer properties
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData6,X
	CMP #$80
	BEQ ++ ;journey has ended/tunnel reached
	AND SpriteData2,X
	BNE +++
	LDA SpriteState,X
	BMI +++ ;Avoid shooting bullets if off screen
	;car is on screen
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	JSR subCalculateDirectionTowardJeep
	CLC
	;Doing this rotates the direction circle so that the circle is divided
	;;vertically into 2 halves on each side, instead of along the horizontal
	;;This code works, but the player will almost never be on the left side of the train..
	ADC #$08
	AND #$10 ;Now this defines left/right instead of up/down
	STA SpriteWhatDirectionToShoot,X
	LDY #$06 ;Bullet type
	JSR SpawnEnemyRoundBullet_Shell
+++:	LDA $D4
	AND SpriteData4,X ;probably check if the leading cars in the train are gone
	;;if so, this car should die
	BEQ +
	RTS
++:	JMP subDespawnSprite
+:	JMP subMoveSpriteToNextState

Level4TrainCarState3: ;Exploding
	DEC SpriteData8,X
	LDA SpriteData8,X
	BEQ +
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BEQ +
	RTS
+:	LDA SpriteData4,X
	LSR
	EOR #$FF
	STA $D4 ;Mark this car as dead for the other card
	JMP subDespawnSprite


;************
;LEVEL 4 BOSS
;
; SpriteData1 - State machine timer and extra explosion counter
; SpriteData2 - Paratrooper counter
; SpriteData3 - Motion sub state control
; SpriteData4 - Previous health value.  used to flash helicopter palette when hit
; SpriteData5 - NOT USED
; SpriteData6 - Defines the direction the paratroopers exit the helicopter (left or right)
; SpriteData8 - Explosion animation timer
;************
Level4BossSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level4BossState0
	dw Level4BossState1
	dw Level4BossState2
	dw Level4BossState3
	dw Level4BossState4
	dw Level4BossState5
	dw Level4BossState6

Level4BossState0: ;Initialize
	LDA #$02 ;palette
	STA SpriteGraphicsAttributes,X
	LDA #$00 ;stop boss forced scroll
	STA ScreenScrollingForF0ToBoss
	LDA #$01 ;lock vertical scroll
	STA ScreenVerticalScrollLockForBossFight
	STA LevelBossEntitiesRemaining ;just the 1 heli boss entity
	JSR subCheckWhichJeepToAttack
	LDA #$80 ;initial delay before coming into the screen
	STA SpriteData1,X
	LDA SpriteHealthHP,X
	STA SpriteData4,X
	JSR subUpdateSpritePositionForScrolling
	LDA #HelicopterBladesWhirringSoundClip
	JSR subInitiateSoundClip
	JMP subMoveSpriteToNextState

Level4BossState1: ;Wait off screen
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X ;waiting for idle time completion off screen
	BEQ +
	RTS
+:	JSR subSpawnPlane_HeliPositionRelativeToJeep
	;start just off the screen (probably because the sprite is so big)
	LDA #$E0
	STA SpriteVertScreenPosition,X
	LDA #$FF
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$90 ;travel time into the screen
	STA SpriteData1,X
	LDA #$00 ;initialize accel/decel state control
	STA SpriteData3,X
	TAY
	LDA Level4BossEntrance_ExitSpeedProgression,Y
	STA $08 ;speed multiplier
	LDA #$08 ;moves downward
	JSR subCalculateObjectSpeed
	LDA #$02 ;palette
	STA SpriteGraphicsAttributes,X
	JMP subMoveSpriteToNextState

Level4BossState2: ;Entering Screen/Moving In
	JSR Level4BossFlashHelicopterPalletOnDamage
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$0F
	BNE +
	INC SpriteData3,X ;move at set speed for $10 frames, then decel
	LDY SpriteData3,X
	LDA Level4BossEntrance_ExitSpeedProgression,Y
	STA $08 ;speed multiplier
	LDA #$08 ;downward direction
	JSR subCalculateObjectSpeed
+:	LDA #$7E ;Base sprite index
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;rotate blades every other frame
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BEQ ++
	AND #$1F
	BNE +
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	LDY #$09
	JMP SpawnEnemyRoundBullet_Shell
+:	RTS
	;movement complete
++:	LDA #$40 ;time duration for deploying paratroopers
	STA SpriteData1,X
	LDA #$00 ;initialize paratrooper counter
	STA SpriteData2,X
	LDA #$40 ;simulate the heli hovering (slight horiz movement)
	STA SpriteHorizSpeedLB,X
	LDA #$00
	LDY SpriteAbsoluteHorizPositionUB,X
	BEQ +
	LDA #$10 ;if on the right screen, send paratroopers left
+:	STA SpriteData6,X
	JMP subMoveSpriteToNextState
	
	;Speed multiplier table
	;Defines the speed of the helicopter in and out of the screen
Level4BossEntrance_ExitSpeedProgression:
	db $50,$40,$30,$21,$20,$11,$10,$01,$02,$00
	
Level4BossState3: ;Stationary - deploying paratroopers
	JSR Level4BossFlashHelicopterPalletOnDamage
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$03
	BNE +
	JSR subInvertSpriteHorizSpeed ;hover back and forth
+:	LDA #$7E
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;rotate blades
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BEQ +++
	AND #$1F
	BNE +
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	LDY #$09
	JSR SpawnEnemyRoundBullet_Shell
+:	LDA SpriteData1,X
	AND #$0F
	BNE ++ ;RTS
	LDA #$42
	STA $08
	LDA #$00
	STA $01
	STA $02
	STA $03
	LDA #$10
	STA $00
	LDY SpriteData6,X
	STY $0C
	BEQ +
	JSR fctInvertA
	STA $00
	LDA #$FF
	STA $01
+:	LDA #$02
	STA $0F
	LDA SpriteData2,X
	STA $09
	INC SpriteData2,X
	JMP subSpawnObjectFromParent_WithOffset
++:	RTS
	;paratrooper drop complete.  begin leaving
+++:	DEC SpriteData3,X
	LDY SpriteData3,X
	LDA Level4BossEntrance_ExitSpeedProgression,Y
	STA $08 ;speed multiplier
	LDA #$18 ;move upward
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState

Level4BossState4: ;Exiting Screen/Moving Out
	JSR Level4BossFlashHelicopterPalletOnDamage
	DEC SpriteData1,X
	LDA SpriteData1,X
	AND #$0F
	BNE +
	DEC SpriteData3,X ;accel upward every $10 frames
	LDY SpriteData3,X
	LDA Level4BossEntrance_ExitSpeedProgression,Y
	STA $08 ;speed multiplier
	LDA #$18 ;upwards
	JSR subCalculateObjectSpeed
+:	LDA #$7E
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;rotate blades
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteState,X
	BMI ++ ;Avoid shooting off screen
	LDA SpriteData1,X
	AND #$1F
	BNE +
	;Fire bullets every $20 frames
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	LDY #$09 ;bullet type
	JMP SpawnEnemyRoundBullet_Shell
+:	RTS
	;upward movement complete
++:	JSR subClearSpriteSpeed
	LDA #$80 ;off screen idle time
	STA SpriteData1,X
	LDA #$01
	JMP subSetSpriteState

Level4BossState5: ;Defeated - Health reached 0
	JSR subStopMusic
	LDA #$02 ;palette reset to normal
	STA SpriteGraphicsAttributes,X
	JSR subClearSpriteSpeed ;stop motion if moving in/out
	LDA #$F0 ;stop interacting to everything
	STA SpriteHitboxShapeIndex,X
	LDA #$01 ;number of explosions
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	;This section loads 2 extra explosion animations on top of the helicopter, upon death
	;;before the helicopter sprite disappears
	;;usually, an enemy sprite is replaced with an explosion
-:	LDA #$00
	STA $00 ;no horiz offest
	STA $01
	STA $03
	LDY SpriteData1,X
	LDA tblLevel4BossHelicopterExplosions_YOffset,Y
	STA $02 ;set vertical offset
	BPL +
	DEC $03
+:	LDA #$41 ;Extra explosion object ID
	STA $08
	JSR subSpawnObjectFromParent_WithOffset
	DEC SpriteData1,X
	BPL - ;Generate the other explosion
	LDA #$18
	STA SpriteData8,X
	JMP subMoveSpriteToNextState

Level4BossState6: ;Exploding
	DEC SpriteData8,X ;Count down to despawn
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BEQ +
	RTS
+:	LDA #$00
	STA LevelBossEntitiesRemaining
	JMP subDespawnSprite

tblLevel4BossHelicopterExplosions_YOffset:
	db $E0,$00
	
Level4BossFlashHelicopterPalletOnDamage:
	LDA SpriteHealthHP,X
	CMP SpriteData4,X ;Stored previous health
	BCS +
	INC SpriteGraphicsAttributes,X ;Flash the helicopter sprite on damage
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
	DEC SpriteData4,X ;Stored Previous health.  decrements 1/frame down to new health
	RTS
+:	LDA #$02 ;Use palette 2 if the heli is not being damaged
	STA SpriteGraphicsAttributes,X
	RTS


;*********************************
;LEVEL 4 BOSS PARACHUTING INFANTRY
;
; SpriteData1 - Number of frames to move away from helicopter
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - Paratrooper number
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;*********************************
Level4BossParachutingInfantrySpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump

	dw Level4BossParachutingInfantryState0
	dw Level4BossParachutingInfantryState1
	dw Level4BossParachutingInfantryState2
	dw subInfantryDeath
	dw subInfantryDeathAnimation

Level4BossParachutingInfantryState0:
	LDA #$AB
	STA SpriteTypeIndex,X
	LDY SpriteData4,X
	LDA tblLevel4BossParatroopersMovementAwayFromHeli,Y
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
	LDA #$20 ;speed multiplier
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState
	
;Defines the number of frames the parachute moves away from the heli before falling
tblLevel4BossParatroopersMovementAwayFromHeli:
	db $08,$19,$2A,$3B ;there are only 3 paratroopers though...
	
Level4BossParachutingInfantryState1:	
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE +
	INC SpriteTypeIndex,X ;next parachute graphic
	LDA #$10
	STA $08
	LDA RNG_INCEveryFrame
	AND #$03
	CLC
	ADC #$06
	JSR subCalculateObjectSpeed
	LDA #$60
	STA SpriteData1,X
	JMP subMoveSpriteToNextState
+:	RTS

Level4BossParachutingInfantryState2:
	DEC SpriteData1,X
	BEQ +
	LDA SpriteData1,X
	AND #$1F
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	BEQ +
	RTS
+:	JSR subClearSpriteSpeed
	LDA #$01 ;object loaded when paratooper hits the ground (01 is normal infantry)
	STA $08
	LDA #$01
	STA $0F
	LDA #$00
	STA SpriteObjectID,X
	STA SpriteTypeIndex,X
	JSR subSpawnObjectFromParent_NoOffset
	LDA #$0F
	STA EnemyPoints,Y
	RTS


	.PAD $AA5C
tblLevel5ObjectSpawn: ;header addresses
;a list of level spawns by screen number

	.PAD $AA74
;Level 5 object spawns
;Each spawn consumes 3 bytes (except F0,F1,F2 objects - see Label978)
;Byte 1 = Vertical screen position at which to spawn the object
;Byte 2 = Horizontal screen position at which to spawn the object (is every 4 pixels [2 screens wide is $00 - $80)
;;	MSB on byte 2 indicates the object spawns at the bottom of the screen, not the top
;Byte 3 - Sprite Object ID

;F0,F1,F2 objects use 2 bytes:
;Byte 1 - Sprite Object ID (F0,F1,F2 only)
;Byte 2 - vertical Vertical screen position at which to spawn the object

	.PAD $AC22	
;**********************
;LEVEL 5 MOUNTED TURRET
;
; SpriteData1 - State/firing timer.  controls firing and hiding/coming out
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Recoil frames.  Explosion animation timing
;**********************
Level5MountedTurretSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level5MountedTurretState0
	dw Level5MountedTurretState1
	dw Level5MountedTurretState2
	dw Level5MountedTurretState3
	dw Level5MountedTurretState4
	dw Level5MountedTurretState5
	dw subSpriteDeath
	dw subSpriteExplosion

Level5MountedTurretState0:
	LDA #$81
	STA SpriteTypeIndex,X
	LDA #$10 ;initial hidden timer
	STA SpriteData1,X
	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level5MountedTurretState1:
Level5MountedTurretState4:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BNE +
	LDA #$07 ;hitbox
	STA SpriteHitboxShapeIndex,X
	LDA #$18
	STA SpriteData1,X
	JMP subMoveSpriteToNextState
+:	RTS

Level5MountedTurretState2:
	LDA SpriteData1,X
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BEQ +
	RTS
+:	LDY DifficultyBasedOnWeapon
	LDA tblLevel5MountedTurretFiringFrames,Y
	STA SpriteData1,X
	LDA #$00
	STA SpriteData8,X
	JMP subMoveSpriteToNextState
	
tblLevel5MountedTurretFiringFrames: ;The number of frames to shoot at the jeeps
	db $40,$48,$50,$58 ;Based on weapon level/difficulty
	
Level5MountedTurretState3:
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	LDA #$84
	STA SpriteTypeIndex,X
	LDA SpriteData8,X
	BEQ +
	INC SpriteTypeIndex,X
	DEC SpriteData8,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	LDA SpriteData1,X
	BEQ +
	AND #$0F
	BNE ++
	LDA SpriteState,X
	BMI ++
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	SEC
	SBC #$02
	CMP #$0E
	BCS ++
	LDA #$04
	STA SpriteData8,X
	LDY #$07
	JMP SpawnEnemyRoundBullet_Shell
++:	RTS
+:	LDA #$08
	STA SpriteData1,X
	LDA #$84
	STA SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

Level5MountedTurretState5:
	LDA SpriteData1,X
	AND #$07
	BNE +
	DEC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BEQ +
	RTS
+:	LDA #$F0
	STA SpriteHitboxShapeIndex,X
	LDA #$20
	STA SpriteData1,X
	LDA #$01
	JMP subSetSpriteState


;35
;***********
;HIDDEN MINE
;
; SpriteData1 - NOT USED
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Flash/Explosion timer
;***********
HiddenMineSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw HiddenMineState0
	dw HiddenMineState1
	dw subSpriteDeath
	dw subSpriteExplosion

HiddenMineState0: ;Initialize
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

HiddenMineState1:
	DEC SpriteData8,X
	LDA #$00 ;usually hidden
	STA SpriteTypeIndex,X
	LDA #$00 ;Check player 1
	STA SpriteWhichJeeptoAttack,X
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	BCS +
	;Player 1 alive, check
	JSR fctGetDistanceBetweenEnemyAndJeep
	CMP #$50 ;distance from hidden mine to show the mine visibly
	BCS +
	BCC ++
+:	LDA #$80
	STA SpriteWhichJeeptoAttack,X
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	BCS +
	;Player 2 alive, check
	JSR fctGetDistanceBetweenEnemyAndJeep
	CMP #$50 ;distance from hidden mine to show the mine visibly
	BCS +
	;Either player is close enough.  show mine
++:	LDA #$73
	STA SpriteTypeIndex,X
	;flash palette
	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
+:	JMP subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	

;0E
;**********
;FLAME TANK
;
; SpriteData1 - NOT USED
; SpriteData2 - Written to ($08), but never used.  maybe was an initial downward direction?
; SpriteData3 - NOT USED 
; SpriteData4 - NOT USED
; SpriteData5 - Mask for stationary frame count
; SpriteData6 - The base sprite render index.
; SpriteData8 - Counts down the number of frames to be stationary
;*****************************
FlameTankSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw FlameTankState0
	dw FlameTankState1
	dw FlameTankState2
	dw FlameTankState3
	dw subSpriteDeath
	dw subSpriteExplosion

FlameTankState0:
	LDA #$44
	STA SpriteTypeIndex,X
	STA SpriteData6,X
	LDA #$01 ;palette
	STA SpriteGraphicsAttributes,X
	LDA #$08
	STA SpriteData2,X
	LDA #$7F ;# of frames to be idle before moving
	STA SpriteData5,X
	JMP Label315

FlameTankState1:
	JSR Label228 ;run global tank code
	BCS +
	RTS
+:	LDA #$30 ;# of frames to move
	STA SpriteData1,X
	LDA #$10
	JMP lblCalculateTank_JeepSpeed

FlameTankState2:
	JSR subTurnTankTowardsJeep
	LDA #$10
	JMP lblCalculateTank_JeepSpeed_CheckforCollision

FlameTankState3:
	LDA #$08
	STA SpriteData2,X
	JSR Label232 ;run global tank code
	LDA $D7 ;collision check
	BEQ ++
	LDA SpriteState,X
	BMI +
	;tank is on screen, spawn the flame
	JSR subSpawnFlame
+:	LDA #$01
	JMP subSetSpriteState
++:	RTS


;19
;*****************************
;POW BUILDING WITH TANK INSIDE
;
; SpriteData1 - BG graphics update index
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;*****************************
POWBuildingWithTankInsideSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump

	dw POWBuildingWithTankInsideState0
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	dw subPlayBarracksOpeningSound_LoadNewBuildingBGGraphics
	dw subProcessExplosionAnimation
	dw POWBuildingWithTankInsideState4
	dw subScrollSprite_CheckForDespawn_UpdateBG

POWBuildingWithTankInsideState0: ;Initialize
	LDY CurrentLevel ;pointless
	LDA #$10 ;BG update index
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JMP subMoveSpriteToNextState

POWBuildingWithTankInsideState4: ;Update opened barracks BG
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	LDA #$23 ;Object ID for Level 5 boss silver tank (moves forward on spawn some, which happens to work for the barracks too)
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BMI +
	;Tank spawned successfully
	JMP subMoveSpriteToNextState
+:	RTS ;tank failed to spawn.  try again next frame


;23
;******************************
;LEVEL 5 BOSS LARGE SILVER TANK
;
; SpriteData1 - Movement timer
; SpriteData2 - # frames to move downward initially
; SpriteData3 - looks like reload timer for SpriteData2 (not used)
; SpriteData4 - NOT USED
; SpriteData5 - Mask for stationary frame count
; SpriteData6 - The base sprite render index.
; SpriteData8 - Counts down the number of frames to be stationary
;******************************
Level5BossSilverLargeTankSpriteLogic:

	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level5BossSilverLargeTankState0
	dw Level5BossSilverLargeTankState1
	dw SilverLargeTankState1
	dw SilverLargeTankState2
	dw SilverLargeTankState3
	dw subSpriteDeath
	dw Level5BossTankState6
	
Level5BossSilverLargeTankState0:
	LDA #$46 ;spawn facing downward sprite
	STA SpriteTypeIndex,X
	LDA #$44 ;Base sprite index
	STA SpriteData6,X
	LDA #$20
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$0F
	STA SpriteData5,X
	JSR subCheckWhichJeepToAttack
	LDA #$11 ;speed multiplier
	STA $08
	LDA #$08 ;move downward initially
	STA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA #$38
	STA SpriteData1,X
	LDA #$02
	STA SpriteGraphicsAttributes,X
	JSR subUpdateSpritePositionForScrolling
	JMP Label299

Level5BossSilverLargeTankState1:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BEQ +
	LDA SpriteData1,X
	AND #$0F
	BNE ++ ;RTS
	LDA SpriteState,X
	BMI ++ ;RTS
	LDY #$03
	JMP SpawnEnemyRoundBullet_Shell
+:	JSR Label247 ;run global tank code
	BCC +
-:	LDA #$10
	STA SpriteData1,X
++:	RTS
+:	JSR fctGetCollision_WithSpeed_FarLookAhead_BG
	BNE -
	JMP subMoveSpriteToNextState

Level5BossTankState6: ;Exploding
	DEC SpriteData8,X
	LDA SpriteData8,X
	BEQ +
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BEQ +
	RTS
+:	DEC $D5 ;Track the number of L5 boss tanks
	JMP subDespawnSprite


;24
;****************************
;LEVEL 5 BOSS RED MEDIUM TANK
;
; SpriteData1 - Movement timer
; SpriteData2 - used to count down the frames between firing bullets
; SpriteData3 - The default timing for # of frames between firing bullets
; SpriteData4 - NOT USED
; SpriteData5 - Mask for stationary frame count
; SpriteData6 - The base sprite render index.
; SpriteData8 - Counts down the number of frames to be stationary
;******************************
Level5BossRedMediumTankSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level5BossRedMediumTankState0
	dw Level5BossRedMediumTankState1
	dw RedMediumTankState1
	dw RedMediumTankState2
	dw RedMediumTankState3
	dw subSpriteDeath
	dw Level5BossTankState6 ;something to do with the boss

Level5BossRedMediumTankState0:
	LDA #$24
	STA SpriteTypeIndex,X
	LDA #$22
	STA SpriteData6,X
	LDA #$20 ;bullet firing delay
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$1F ;movement mask
	STA SpriteData5,X
	JSR subCheckWhichJeepToAttack
	LDA #$12 ;speed multiplier
	STA $08
	LDA #$08
	STA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA #$40 ;movement frames initially downward
	STA SpriteData1,X
	LDA #$01 ;palette
	STA SpriteGraphicsAttributes,X
	JSR subUpdateSpritePositionForScrolling
	JMP Label299 ;run global tank code

Level5BossRedMediumTankState1:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	BEQ +
	LDA SpriteData1,X
	AND #$0F
	BNE ++ ;RTS
	LDA SpriteState,X
	BMI ++ ;RTS
	LDY #$01 ;bullet type
	JMP SpawnEnemyRoundBullet_Shell
+:	JSR Label247 ;run global tank code
	BCC +
	LDA #$10
	STA SpriteData1,X
++:	RTS
+:	JMP subMoveSpriteToNextState


;17
;************
;LEVEL 5 BOSS
;
; SpriteData1 - Door number
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;************
Level5BossSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level5BossState0
	dw Level5BossState1
	dw Level5BossState2
	dw subDespawnSprite

Level5BossState0:
	LDA #$04 ;number of enemy tank doors, LEVEL 5 Boss code
	STA SpriteData1,X
	CLC
	ADC #$01 ;1 boss entity (the electric gate)
	STA LevelBossEntitiesRemaining
	LDA #$00 ;stop auto boss scroll
	STA ScreenScrollingForF0ToBoss
	STA $D5 ;clear L5 boss tank spawn count
	LDA #$01 ;lock vertical scroll for boss
	STA ScreenVerticalScrollLockForBossFight
-:	JMP subMoveSpriteToNextState

Level5BossState1:
	;Spawn the electric gate
	LDA #$18
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$01
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$40
	STA SpriteVertScreenPosition,X
	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$26 ;Object ID
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL - ;Go to next stat
	;Gate failed to spawn.  try again next frame
	RTS

Level5BossState2:
	DEC SpriteData1,X ;count the doors spawned
	BMI ++
	;spawn another door
	LDY SpriteData1,X ;The door number
	LDA tblLevel5BossTankDoorHorizontalSpawnPosition,Y ;Y has the door index
	STA SpriteAbsoluteHorizPositionLB,X
	LDA tblLevel5BossTankDoorVerticalSpawnPosition,Y
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$48
	STA SpriteVertScreenPosition,X
	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$31 ;L5 boss door object ID
	STA $08
	LDA SpriteData1,X
	STA $09
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL +
	INC SpriteData1,X
+:	RTS
	;door spawns complete
++:	LDA #$46 ;End of level check object ID
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL +
	;door spawn failed.  try again next frame
	INC SpriteData1,X
	RTS
	;door spawned, this object is done
+:	JMP subMoveSpriteToNextState

tblLevel5BossTankDoorHorizontalSpawnPosition:
	db $80
	db $B0
	db $80
	db $B0

tblLevel5BossTankDoorVerticalSpawnPosition:
	db $00
	db $00
	db $01
	db $01
	

;*****************************
;LEVEL 5 BOSS ELECTRIFIED GATE
;
; SpriteData1 - written to but not used
; SpriteData2 - Electrification sub state
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - Direction to travel
; SpriteData8 - Animation timer
;*************************
;*****************************
Level5BossElectrifiedGateSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level5BossElectrifiedGateState0
	dw Level5BossElectrifiedGateState1
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	dw subCheckForBossDeath_MultipleBossEnemies
	dw subSpriteDeath
	dw Level5BossDoorState6

Level5BossElectrifiedGateState0:
	LDA #$00
	STA SpriteData1,X
	LDA #$03 ;palette
	STA SpriteGraphicsAttributes,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level5BossElectrifiedGateState1:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA LevelBossEntitiesRemaining
	CMP #$01
	BEQ ++
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$03 ;change animation every 4 frames
	BNE  +
	INC SpriteData2,X
	LDA SpriteData2,X
	AND #$07 ;there are 8 animations, roll over
	STA SpriteData2,X
	LDA #$93 ;base sprite type index
	CLC
	ADC SpriteData2,X
	STA SpriteTypeIndex,X
+:	RTS
++:	LDA #$00 ;hide any animation
	STA SpriteTypeIndex,X
	LDA #$C5 ;enable collision so the player can destroy the gate
	STA SpriteHitboxShapeIndex,X
	JMP subMoveSpriteToNextState


;31
;*****************
;LEVEL 5 BOSS DOOR
;This is the shutter that opens and tanks come out
; SpriteData1 - Final/destroyed BG graphics update index
; SpriteData2 - door open delay
; SpriteData3 - NOT USED
; SpriteData4 - Door closed/opening/open BG graphics update index
; SpriteData5 - Door index (which one of the doors is this)
; SpriteData6 - Counts the number of times the door has opened
; $06C0 (SpriteData7) - Counts the number of tanks spawned
; SpriteData8 - door opening graphics timing
;*****************
Level5BossDoorSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level5BossDoorState0
	dw Level5BossDoorState1
	dw Level5BossDoorState2
	dw Level5BossDoorState3
	dw Level5BossDoorState4
	dw subSpriteDeath
	dw Level5BossDoorState6

Level5BossDoorState0:
	LDA #$1B
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
	LDY SpriteData4,X ;Door index comes in on Data4 but is moved to Data5
	LDA tblLevel5BossDoorInitialOpenDelay,Y
	STA SpriteData2,X
	TYA
	STA SpriteData5,X
	LDA #$14
	STA SpriteData4,X
	LDA #$00
	STA SpriteData6,X
	LDA #$04
	STA $06C0,X
	JMP subMoveSpriteToNextState
	
;This offsets each door so they open in sequence and not all at the same time
;Once this time expires, the doors open, then continue counting down from $FF (just keep DEC)
tblLevel5BossDoorInitialOpenDelay:
	db $30,$60,$90,$C0

Level5BossDoorState1: ;Idle
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData4,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	DEC SpriteData2,X ;door closed/idle timer
	BNE ++
	LDA #$00
	STA SpriteData8,X
	INC SpriteData6,X ;count door openings
	LDA SpriteData6,X
	AND #$3F ;not sure why this is here.  opening 64 times is almost never reached during normal gameplay
	BNE +
	INC $06C0,X
+:	JMP subMoveSpriteToNextState
++:	RTS

Level5BossDoorState2: ;Opening door
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$07
	BNE +
	LDA SpriteData4,X ;update the door opening/closing graphics
	JSR subUpdateBGGraphicsFromSprite
	DEC SpriteData4,X
	LDA SpriteData4,X
	CMP #$11
	BCC ++
-:
+:	RTS
++:	LDA #$8C ;door open, enable damage/interactions
	STA SpriteHitboxShapeIndex,X
	LDA #$00
	STA SpriteData8,X
	INC SpriteData4,X
	LDA #$FF
	STA SpriteTypeIndex,X
	LDA #$83 ;Load Level 5 boss tank door health
	STA SpriteHealthHP,X
	JMP subMoveSpriteToNextState

Level5BossDoorState3: ;Spawn tank/flash door lights
	LDA #$83 ;Load Level 5 boss tank door health
	STA SpriteHealthHP,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	INC SpriteGraphicsAttributes,X ;flash the door lights
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
	INC SpriteData8,X
	LDA SpriteData8,X
	CMP #$20
	BCC - ;RTS
	LDA SpriteData4,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	LDA SpriteState,X
	BMI +
	LDA $D5
	CMP $06C0,X
	BCS +
	;Spawn tank from door
	LDY SpriteData5,X
	LDA tblLevel5BossTankSpawnOrder,Y ;get which tank to spawn
	STA $08
	INC SpriteData5,X
	LDA SpriteData5,X
	AND #$03
	STA SpriteData5,X
	LDA #$00
	STA $00
	STA $01
	STA $03
	LDA #$10
	STA $02
	JSR subSpawnObjectFromParent_WithOffset
	TYA
	BMI +
	;tank failed to spawn
	INC $D5 ;revert tanks spawned count
+:	LDA #$00
	STA SpriteData8,X
	LDA #$F0 ;shutter is closing.  disable interactions
	STA SpriteHitboxShapeIndex,X
	LDA #$00 ;stop flashing lights over door
	STA SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

;23 = Silver Large Tank, 24 - Red Medium Tank
;The doors cycle through this table spawning the tanks in successive order
;;and looping (modular) back to the beginning of this table
tblLevel5BossTankSpawnOrder:	
	db $23,$24,$24,$23

Level5BossDoorState4: ;Close door
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$07 ;try to update the BG every 7 frames (there is another JSR that does this..)
	BNE +
	LDA SpriteData4,X
	JSR subUpdateBGGraphicsFromSprite
	INC SpriteData4,X ;progress backwards through BG updates
	LDA SpriteData4,X
	CMP #$15
	BCS ++
	;BG updates not done
+:	RTS
	;BG updates are done for closing door
++:	DEC SpriteData4,X
	LDA #$01
	JMP subSetSpriteState

Level5BossDoorState6: ;Exploding
	DEC SpriteData8,X
	LDA SpriteData8,X
	BEQ +
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BEQ +
	RTS
+:	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite
	DEC LevelBossEntitiesRemaining
	JMP subDespawnSprite
	
	.PAD $B128
tblLevel6ObjectSpawn: ;Header Addresses
;a list of level spawns by screen number

	.PAD $B144
;Level 6 object spawns
;Each spawn consumes 3 bytes (except F0,F1,F2 objects - see Label978)
;Byte 1 = Vertical screen position at which to spawn the object
;Byte 2 = Horizontal screen position at which to spawn the object (is every 4 pixels [2 screens wide is $00 - $80)
;;	MSB on byte 2 indicates the object spawns at the bottom of the screen, not the top
;Byte 3 - Sprite Object ID

;F0,F1,F2 objects use 2 bytes:
;Byte 1 - Sprite Object ID (F0,F1,F2 only)
;Byte 2 - vertical Vertical screen position at which to spawn the object

	.PAD $B305
	
	
;43
;*************************
;LEVEL 6 ATTACK HELICOPTER
;
; SpriteData1 - Blade whirring sound timer
; SpriteData2 - Decel sub state counter
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - Direction to travel
; SpriteData8 - NOT USED
;*************************
Level6AttackHelicopterSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6AttackHelicopterState0
	dw Level6AttackHelicopterState1
	dw Level6AttackHelicopterState2
	dw subSpriteDeath
	dw subSpriteExplosion

Level6AttackHelicopterState0: ;initialize
	JSR subCheckWhichJeepToAttack
	JSR subSpawnPlane_HeliPositionRelativeToJeep
	LDA #$9B
	STA SpriteTypeIndex,X
	LDA #$08 ;travel downwards initially
	STA SpriteData6,X
	LDA #$80 ;mirrored vertically, for downward travel
	STA SpriteAttributes,X
	LDA SpriteVertScreenPosition,X
	BPL +
	;heli spawned at the bottom of the screen
	LDA #$00 ;no mirroring for upwards travel
	STA SpriteAttributes,X
	LDA #$18 ;direction - upwards
	STA SpriteData6,X
+:	LDA #$00 ;init
	STA SpriteData2,X
	TAY
	LDA tblLevel6AttackHelicopterEnterScreenSpeedFactors,Y ;get first speed muliplier
	STA $08
	LDA SpriteData6,X
	JSR subCalculateObjectSpeed
	JSR subUpdateSpritePositionForScrolling
	LDA #$00 ;palette
	STA SpriteGraphicsAttributes,X
	JMP subMoveSpriteToNextState
	
	;Speed offset table for the helicopter entering the screen
tblLevel6AttackHelicopterEnterScreenSpeedFactors:
	db $50,$40,$30,$20,$10,$00,$00
	
Level6AttackHelicopterState1:
	INC SpriteData1,X
	LDA SpriteData1,X
	AND #$03
	BNE +
	LDA #HelicopterBladesWhirringSoundClip ;play blade whirring sound every 4 frames
	JSR subInitiateSoundClip
+:	LDA #$9B
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;animate blade rotation every other frame
+:	LDA SpriteData1,X
	AND #$0F ;process new speed/decel every $10 frames
	BNE +
	INC SpriteData2,X
	LDY SpriteData2,X
	LDA tblLevel6AttackHelicopterEnterScreenSpeedFactors,Y
	STA $08
	LDA SpriteData6,X
	JSR subCalculateObjectSpeed
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	AND #$1F ;fire a bullet every $20 frames
	BNE +
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	LDY #$0A ;bullet type
	JSR SpawnEnemyRoundBullet_Shell
+:	LDA SpriteData2,X
	CMP #$06
	BNE ++
	LDA #$04 ;default to down-right direction
	LDY SpriteHorizScreenPosition,X
	BPL + ;heli is on the left half of the visible screen, no mirroring required
	;heli is on the right half of the visible screen
	LDA SpriteAttributes,X
	ORA #$40 ;Mirror to travel to the right
	STA SpriteAttributes,X
	LDA #$0C ;down-left direction
+:	STA $00
	LDA SpriteData6,X
	AND #$10
	BEQ +
	;heli was travelling upwards
	JSR fctInvert24Bit ;this is expensive compared to fctInvertA with some $00 LDA/STA
+:	LDA #$31 ;speed multiplier for diagonal motion
	STA $08
	LDA $00
	AND #$1F ;direction comes from 24bit inversion
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState
-:
++:	RTS

Level6AttackHelicopterState2: ;flying off diagonally
	INC SpriteData1,X
	LDA SpriteData1,X
	AND #$03
	BNE +
	LDA #HelicopterBladesWhirringSoundClip ;play blade whirring sound every 4 frames
	JSR subInitiateSoundClip
+:	LDA #$9D
	STA SpriteTypeIndex,X
	LDA SpriteData1,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;animate blade rotation
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	AND #$1F ;shoot a bullet every $20 frames
	BNE -
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	LDY #$0A ;bullet type
	JMP SpawnEnemyRoundBullet_Shell


;2E
;************************
;LEVEL 6 MISSILE LAUNCHER
;
; SpriteData1 - NOT USED
; SpriteData2 - State machine timer
; SpriteData3 - default idle timer value
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Explosion and missile launch delay timer
;************************
Level6MissileLauncherSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6MissileLauncherState0
	dw Level6MissileLauncherState1
	dw Level6MissileLauncherState2
	dw Level6MissileLauncherState3
	dw subSpriteDeath
	dw subSpriteExplosion

Level6MissileLauncherState0: ;Initialize
	LDA #$9F
	STA SpriteTypeIndex,X
	LDA #$10 ;missile launch delay
	STA SpriteData8,X
	LDA #$80 ;idle delay
	STA SpriteData2,X
	STA SpriteData3,X
	LDA #$18 ;Always shoot up (unnecessary since the missile is given $18 explicitly when spawned)
	STA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level6MissileLauncherState1: ;Idle
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X
	BNE +
	LDA SpriteData8,X ;load missile delay
	STA SpriteData2,X
	LDA #$47 ;become vulnerable
	STA SpriteHitboxShapeIndex,X
	INC SpriteTypeIndex,X ;open door sprite
	JMP subMoveSpriteToNextState
+:	RTS

Level6MissileLauncherState2: ;Launch Missile
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X
	BEQ +
	RTS
+:	LDA SpriteState,X
	BMI ++ ;Avoid launching missile if off screen
	;Spawn missile
	LDA #$39 ;Missile object ID
	STA $08
	LDA #$70 ;Missile Sprite Type (BW Missile)
	STA $0A
	LDA #$02 ;missile type
	STA $0B
	LDA #$18 ;Always shoot up
	STA $0C
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BMI +
	;Missile spawned successfully
++:	LDA #$08
	STA SpriteData2,X
	JMP subMoveSpriteToNextState
	;Missile failed to spawn.  try again next frame
+:	INC SpriteData2,X
	RTS

Level6MissileLauncherState3: ;Delay before closing
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X
	BNE +
	DEC SpriteTypeIndex,X
	LDA SpriteData3,X ;Reload idle timer value
	STA SpriteData2,X
	LDA #$F0 ;door closed, disable vulnerability
	STA SpriteHitboxShapeIndex,X
	LDA #$01
	JMP subSetSpriteState
+:	RTS


;47
;*************************
;LEVEL 6 BOSS LASER TURRET
;!!!!
; SpriteData1 - Flashing timer
; SpriteData2 - State machine timer
; SpriteData3 - State machine timer default/reload value
; SpriteData4 - ;Laser blast flight time
; SpriteData5 - Facing direction
; SpriteData6 -
; SpriteData8 -
;*************************
Level6BossLaserTurretSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6BossLaserTurretState0
	dw Level6BossLaserTurretState1
	dw Level6BossLaserTurretState2
	dw Level6BossLaserTurretState3
	dw subSpriteDeath
	dw Level6BossLaserTurretState5
	dw Level6BossLaserTurretState6
	dw subSpriteDeath
	dw subSpriteExplosion

Level6BossLaserTurretState0: ;Initialize
	LDA #$CA
	STA SpriteTypeIndex,X
	LDA #$08 ;Start facing down
	STA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	LDA #$07
	STA SpriteData3,X
	STA SpriteData2,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

Level6BossLaserTurretState1: ;Randomize starting pattern
	LDA #$CA
	STA SpriteTypeIndex,X
	LDA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	
	;Sufficiently randomize the index Y
	LDA RNG_INCEveryFrame
	LSR
	LSR
	LSR
	LSR
	ADC RNG_INCEveryFrame
	ADC Jeep1HorizScreenPosition
	ADC Jeep2HorizScreenPosition
	AND #$07
	TAY
	LDA tblLevel6FinalBossLaserTurretDirectionFiringPattern,Y
	STA SpriteWhatDirectionToShoot,X
	LDA tblLevel6FinalBossLasterTurretBlastFlightTime,Y
	STA SpriteData4,X
	JSR subCheckForBothTurretsDead
	JMP subMoveSpriteToNextState

tblLevel6FinalBossLaserTurretDirectionFiringPattern:	
	db $0C,$04,$0C,$08,$0C,$04,$04,$08
tblLevel6FinalBossLasterTurretBlastFlightTime:
	db $38,$54,$54,$44,$54,$38,$54,$44
	
Level6BossLaserTurretState2:
	LDA #$CA
	STA SpriteTypeIndex,X
	LDA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCheckForBothTurretsDead
	LDA SpriteWhatDirectionToShoot,X
	SEC
	SBC SpriteData5,X
	BEQ +++
	DEC SpriteData2,X
	BNE ++ ;RTS
	TAY
	LDA SpriteData3,X
	STA SpriteData2,X
	TYA
	AND #$10
	BNE +
	LDA SpriteData5,X
	CLC
	ADC #$01
	AND #$1F
	STA SpriteData5,X
	RTS
+:	LDA SpriteData5,X
	SEC
	SBC #$01
	AND #$1F
	STA SpriteData5,X
++:	RTS
+++:	LDA #$07
	STA SpriteData1,X
	INC SpriteTypeIndex,X
	INC SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

Level6BossLaserTurretState3:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCheckForBothTurretsDead
	DEC SpriteData1,X
	LDA SpriteData1,X
	BNE + ;RTS
	LDA #$48
	STA $08
	LDA SpriteData4,X
	STA $09
	LDA SpriteWhatDirectionToShoot,X
	STA $0C
	LDA #$00
	STA $0F
	JSR subSpawnObjectFromParent_NoOffset
	LDA #$01
	JMP subSetSpriteState
+:	RTS

Level6BossLaserTurretState5:
	DEC SpriteData8,X
	LDA SpriteData8,X
	BEQ +
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCheckForBothTurretsDead
	LDA SpriteData8,X
	BEQ +
-:	RTS
+:	LDA #$D2
	STA SpriteTypeIndex,X
	LDA #$00
	STA SpriteGraphicsAttributes,X
	JMP subMoveSpriteToNextState

Level6BossLaserTurretState6:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JMP subCheckForBothTurretsDead ;not needed.  jumps to next line
subCheckForBothTurretsDead:
	LDA $D5 ;Check to see if both Laser Turrets are dead
	BNE - ;RTS
	JMP subDespawnSprite


;*******************************
;LEVEL 6 BOSS LASER TURRET BLAST
;!!!!
; SpriteData1 -
; SpriteData2 -
; SpriteData3 -
; SpriteData4 -
; SpriteData5 -
; SpriteData6 -
; SpriteData8 -
;*************************
Level6BossLaserTurretBlastSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6BossLaserTurretBlastState0
	dw Level6BossLaserTurretBlastState1
	dw subPlayMissileHittingGroundSound_LoadHoleInGroundBGGraphics
	dw subProcessExplosionAnimation
	dw subDespawnSprite

Level6BossLaserTurretBlastState0:
	LDA #$1A
	STA SpriteData1,X
	LDA #$CF
	STA SpriteData5,X
	LDA SpriteWhatDirectionToShoot,X
	AND #$04
	BEQ ++
	LDA SpriteWhatDirectionToShoot,X
	AND #$08
	BEQ +
	LDA #$40
	STA SpriteAttributes,X
	BNE +
++:	INC SpriteData5,X
+:	LDA #$08
	STA SpriteData8,X
	LDA #$51
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JSR subUpdateSpritePositionForScrolling
	JSR subCheckForBothTurretsDead
	LDA SpriteState,X
	BMI +
	LDA #LaserBlastSoundClip
	JSR subInitiateSoundClip
+:	JMP subMoveSpriteToNextState

Level6BossLaserTurretBlastState1:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCheckForBothTurretsDead
	DEC SpriteData4,X
	LDA SpriteData4,X
	BEQ ++
	LSR
	BCC +
+:	DEC SpriteData8,X
	BNE +
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
+:	RTS
++:	JMP subMoveSpriteToNextState


;************************
;LEVEL 6 BOSS LOAD OBJECT
;!!!!
; SpriteData1 -
; SpriteData2 -
; SpriteData3 -
; SpriteData4 -
; SpriteData5 -
; SpriteData6 -
; SpriteData8 -
;*************************
Level6BossLoadSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6BossLoadState0
	dw Level6BossLoadState1
	dw Level6BossLoadState2
	dw subDespawnSprite

Level6BossLoadState0:
	LDA #$02
	STA SpriteData1,X
	;Boss Reached
	LDA #$00
	STA ScreenScrollingForF0ToBoss
	LDA #$01
	STA ScreenVerticalScrollLockForBossFight
-:	JMP subMoveSpriteToNextState

Level6BossLoadState1:
	;Initialize the Tank Boss location?
	LDA #$00
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$01
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$2E
	STA SpriteVertScreenPosition,X
	
	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$4A ;spawn 4A object (governs all of the final boss logic)
	STA $08
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL -
	RTS

Level6BossLoadState2:
	DEC SpriteData1,X
	BMI ++
	LDY SpriteData1,X
	LDA tblLevel6BossTurretHorizontalSpawnLocationLB,Y
	STA SpriteAbsoluteHorizPositionLB,X
	LDA tblLevel6BossTurretHorizontalSpawnLocationUB,Y
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$29
	STA SpriteVertScreenPosition,X
	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$47
	STA $08
	LDA #$00
	STA $0F
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL +
	INC SpriteData1,X
+:	RTS
++:	JMP subMoveSpriteToNextState
	
tblLevel6BossTurretHorizontalSpawnLocationLB:
	db $D2,$2E

;Determines left or right screen
tblLevel6BossTurretHorizontalSpawnLocationUB:
	db $00,$01


;******************
;LEVEL 6 FINAL BOSS - Present throughout phase 1 (building)
;******************
Level6FinalBossSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw Level6FinalBossState0
	dw Level6FinalBossState1
	dw subSpriteDeath
	dw Level6FinalBossState3
	dw Level6FinalBossState4
	dw Level6FinalBossState5
	dw Level6FinalBossState6

Level6FinalBossState0:
	LDA #$00
	STA SpriteData8,X
	LDA #$00
	STA SpriteGraphicsAttributes,X
	LDA SpriteHealthHP,X
	AND #$3F
	STA SpriteData2,X
	JSR subUpdateSpritePositionForScrolling
	LDA #$00
	STA PPUGraphicsUpdateComplete
	LDA #$0E
	STA PPUGraphicsUpdateTableIndex
	LDA #$01
	STA $D5 ;Set the Final Boss Turret to alive, normal palette
	LDA RNG_INCEveryFrame
	ORA #$C0
	STA SpriteData3,X
	STA SpriteData4,X
	JMP subMoveSpriteToNextState

Level6FinalBossState1:
	DEC SpriteData3,X
	BNE +
	LDA SpriteData4,X
	STA SpriteData3,X
	JSR Label672
+:	LDA #$00
	STA SpriteTypeIndex,X
	LDA SpriteData2,X
	BEQ +
	DEC SpriteData2,X
	JMP ++
+:	LDA #$D1
	STA SpriteTypeIndex,X
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$07
	BNE +
	LDA SpriteHealthHP,X
	AND #$3F
	STA SpriteData2,X
+:	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
++:	JMP subUpdateSpritePositionForScrolling_Speed_CheckForDespawn

Level6FinalBossState3: ;Building HQ Destroyed
	DEC SpriteData8,X
	LDA SpriteData8,X
	BEQ +
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BEQ +
	RTS
+:	LDA #$00
	STA SpriteTypeIndex,X
	STA $D5 ;Indicate that both turrets are dead when building is destroyed
	JSR subStopMusic
	JSR subDespawnAllObjectsExceptFinalBoss
	JMP subMoveSpriteToNextState

Level6FinalBossState4: ;Building exploding
	JSR subFinalBossBuildingTransitionToFinalBossTank
	BEQ +
	RTS
+:	JSR subEraseLevel6BossFlags
	LDA #$01
	STA $3A
	JMP subMoveSpriteToNextState

Level6FinalBossState5:
	LDA #$00
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$01
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$30
	STA SpriteVertScreenPosition,X
	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$4B ;Spawn final boss tank
	STA $08
	LDA #$00
	STA $0F
	JSR subSpawnObjectFromParent_NoOffset
	TYA
	BPL +
	RTS
+:	LDA #$60
	STA SpriteData1,X
	JMP subMoveSpriteToNextState

Level6FinalBossState6:
	DEC SpriteData1,X
	BEQ +
	RTS
+:	JMP subDespawnSprite

Label672:	
	LDA #$00
	STA $03
	LDA #$EF
	SEC
	SBC SpriteVertScreenPosition,X
	STA $02
	LDA RNG_INCEveryFrame
	ADC SpriteData4,X
	ADC $0570
	ADC $0571
	LSR
	STA $00
	LDA #$00
	ROL
	SEC
	SBC #$01
	STA $01
	LDA #$07
	STA $08
	LDA #$01
	STA $0F
	JSR subSpawnObjectFromParent_WithOffset
	LDA #$00
	STA EnemyPoints,Y
	RTS

;*********************************
;LARGE GRAY TURRET - WHITE BULLETS
;
; SpriteData1 - Lock-on timer
; SpriteData2 - Number of frames for turret turning rate
; SpriteData3 - Fire timer
; SpriteData4 - NOT USED
; SpriteData5 - Firing direction (0-1F)
; SpriteData6 - Facing direction (0-7)
; SpriteData8 - Recoil timing
;*********************************
LargeGrayTurretWhiteBulletsSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw LargeGrayTurretWhiteBulletsState0
	dw LargeGrayTurretWhiteBulletsState1
	dw LargeGrayTurretWhiteBulletsState2
	dw LargeGrayTurretWhiteBulletsState3
	dw LargeGrayTurretWhiteBulletsState4
	dw LargeGrayTurretWhiteBulletsState5
	dw subSpriteExplosion
	
LargeGrayTurretWhiteBulletsState0:
	;This removes the priority for this object
	;;This means the turret can be despawned by other higher priority
	;;objects, but it makes sense that these should be priority in the beginning
	;;, to spawn.  otherwise their base would be empty and it would look weird.
	LDA SpriteObjectID,X
	AND #$7F
	STA SpriteObjectID,X
	LDA #$1C
	STA SpriteTypeIndex,X
	LDA #$08 ;start facing down
	STA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	TYA
	LDA SpriteData6,X
	LDA #$0D ;default fire/turn rate
	STA SpriteData3,X
	SEC
	SBC DifficultyBasedOnWeapon
	SBC CurrentLevel
	LSR
	;The turret turns faster based on difficulty and level
	STA SpriteData2,X ;#$0D - Level - Difficulty = #frames for direction rotation
	LDA #$02
	STA SpriteGraphicsAttributes,X
	LDA CurrentLevel
	CMP #$05
	BNE +
	LDA #$00 ;Level 6 different palette
	STA SpriteGraphicsAttributes,X
+:	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

LargeGrayTurretWhiteBulletsState1:
	LDA #$1C
	STA SpriteTypeIndex,X
	LDA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	TYA
	STA SpriteData6,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	JSR subCalculateDirectionTowardJeep
	SEC
	SBC SpriteData5,X
	BEQ +++
	DEC SpriteData2,X
	BNE ++
	TAY
	;Recalculate turn rate in case players lost their main weapon/difficulty
	LDA SpriteData3,X
	SEC
	SBC DifficultyBasedOnWeapon
	SBC CurrentLevel
	LSR
	STA SpriteData2,X
	TYA
	AND #$10
	BNE +
	LDA SpriteData5,X
	CLC
	ADC #$01
	AND #$1F
	STA SpriteData5,X
	RTS
+:	LDA SpriteData5,X
	SEC
	SBC #$01
	AND #$1F
	STA SpriteData5,X
++:
-:	RTS
+++:	LDA SpriteState,X
	BMI -
	;Get the time the turret is focused on your last position while firing
	LDA DifficultyBasedOnWeapon
	CLC
	ADC CurrentLevel
	LSR
	TAY
	LDA tblGrayTurretLockOnTime,Y
	STA SpriteData1,X
	JSR Label490
	JMP subMoveSpriteToNextState
 

;This is the length of the time the turret will fire at your previous position
;;before reacquiring a lock on your new position.
;;A higher time means the turret is firing at your old position
;;for longer, which is easier
tblGrayTurretLockOnTime:
	db $40,$38,$30,$28,$20,$18
	
LargeGrayTurretWhiteBulletsState2:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData1,X
	LDA SpriteData1,X
	BEQ +
	AND #$0F
	BNE -
	LDA #$03 ;# of recoil frame
	STA SpriteData8,X
	LDA SpriteTypeIndex,X
	CLC
	ADC #$03
	STA SpriteTypeIndex,X
	JSR SpawnTurretProjectile
	JSR Label493
	JMP subMoveSpriteToNextState
+:	LDA #$01
	JMP subSetSpriteState

LargeGrayTurretWhiteBulletsState3:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData8,X
	BNE +
	LDA #$03 ;# of return from recoil frames
	STA SpriteData8,X
	JSR subInvertSpriteVertAndHorizSpeed
	JMP subMoveSpriteToNextState
+:	RTS

LargeGrayTurretWhiteBulletsState4:
	DEC SpriteData8,X
	BNE +
	LDA SpriteTypeIndex,X
	SEC
	SBC #$03
	STA SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	BNE +
	JSR subClearSpriteSpeed
	LDA #$02
	JMP subSetSpriteState
+:	RTS

LargeGrayTurretWhiteBulletsState5:
	JSR subClearSpriteSpeed
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA #$18 ;explosion timing
	STA SpriteData8,X
	LDA #$19 ;explostion sprite type
	STA SpriteTypeIndex,X
	LDA #$03	;explosions use the yellow/red palette
	STA SpriteGraphicsAttributes,X
	LDA #$F0 ;dont interact with anything
	STA SpriteHitboxShapeIndex,X
	;This check was probably intended to be used for the laser turrets
	;;or for the turret on the huge tank, but neither of those objects
	;;call this state 5.  and there are no normal turrets on that screen
	;;so this check does nothing
	LDA CurrentLevel
	CMP #$05 ;Level 6
	BNE +
	LDA CurrentLevelScreen
	CMP #$0D ;At final boss
	BEQ ++
+:	LDA #MainWeaponExplosionOnEnemy
	JSR subInitiateSoundClip
++:	JMP subMoveSpriteToNextState


;**********************************
;LARGE GRAY TURRET - YELLOW BULLETS
;
; SpriteData1 - Lock-on timer
; SpriteData2 - Number of frames for turret turning rate
; SpriteData3 - Fire timer
; SpriteData4 - NOT USED
; SpriteData5 - Firing direction (0-1F)
; SpriteData6 - Facing direction (0-7)
; SpriteData8 - Recoil timing
;**********************************
LargeGrayTurretYellowBulletSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw LargeGrayTurretYellowBulletState0
	dw LargeGrayTurretYellowBulletState1
	dw LargeGrayTurretWhiteBulletsState2
	dw LargeGrayTurretWhiteBulletsState3
	dw LargeGrayTurretWhiteBulletsState4
	dw subSpriteDeath
	dw subSpriteExplosion

LargeGrayTurretYellowBulletState0:
	LDA SpriteObjectID,X
	AND #$7F
	STA SpriteObjectID,X
	LDA #$1C
	STA SpriteTypeIndex,X
	LDA #$08
	STA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	TYA
	STA SpriteData6,X
	LDA #$0D
	STA SpriteData3,X
	SEC
	SBC DifficultyBasedOnWeapon
	SBC CurrentLevel
	LSR
	;The turret turns faster based on difficulty and level
	STA SpriteData2,X ;#$0D - Level - Difficulty = #frames for direction rotation
	LDA #$02
	STA SpriteGraphicsAttributes,X
	LDA CurrentLevel
	CMP #$05
	BNE +
	LDA #$01 ;Level 6 different palette
	STA SpriteGraphicsAttributes,X
+:	JSR subCheckWhichJeepToAttack
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

LargeGrayTurretYellowBulletState1:
	LDA #$1C
	STA SpriteTypeIndex,X
	LDA SpriteData5,X
	JSR subUpdateSpriteForDirectionChange
	TYA
	STA SpriteData6,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JSR subCountDownForJeepTargetBy1
	JSR subCheckEnemyTarget_AttackOtherJeepIfDead
	JSR subCalculateDirectionTowardJeep
	SEC
	SBC SpriteData5,X
	BEQ +++
	DEC SpriteData2,X
	BNE +
	TAY
	;Recalculate turn rate in case players lost their main weapon/difficulty
	LDA SpriteData3,X
	SEC
	SBC DifficultyBasedOnWeapon
	SBC CurrentLevel
	LSR
	STA SpriteData2,X
	TYA
	AND #$10
	BNE ++
	LDA SpriteData5,X
	CLC
	ADC #$01
	AND #$1F
	JSR fctGetSpriteOrientationIndex
	CPY #$04
	BCS + ;this turret can only turn so far
	INC SpriteData5,X
+:
-:	RTS

++:	LDA SpriteData5,X
	SEC
	SBC #$01
	AND #$1F
	JSR fctGetSpriteOrientationIndex
	TYA
	BEQ - ;this turret can only turn so far
	DEC SpriteData5,X
	RTS
+++:	LDA SpriteState,X
	BMI -
	LDA DifficultyBasedOnWeapon
	CLC
	ADC CurrentLevel
	LSR
	TAY
	LDA tblGrayTurretLockOnTime,Y
	STA SpriteData1,X
	JSR Label490
	JMP subMoveSpriteToNextState
	
Label490:
	LDA SpriteObjectID,X
	ORA #$80
	CMP #$86 ;Gray Turret yellow bullets
	BEQ Label698
	LDA SpriteAbsoluteHorizPositionLB,X
	STA $08
	LDA SpriteAbsoluteHorizPositionUB,X
	STA $09
	LDA SpriteVertScreenPosition,X
	STA $0A
	LDA SpriteAbsoluteVertPositionUB,X
	STA $0B
	LDA #$00
	STA $01
	STA $03
	LDY SpriteData6,X
	LDA tblTurretBulletSpawnHorizSpawnLocationOffset,Y
	STA $00
	BPL +
	DEC $01
+:	LDA $08
	CLC
	ADC $00
	STA SpriteAbsoluteHorizPositionLB,X
	LDA $09
	ADC $01
	STA SpriteAbsoluteHorizPositionUB,X
	LDA tblTurretBulletSpawnVertSpawnLocationOffset,Y
	STA $02
	BPL +
	DEC $03
+:	LDA $0A
	CLC
	ADC $02
	STA SpriteVertScreenPosition,X
	LDA $0B
	ADC $03
	STA SpriteAbsoluteVertPositionUB,X
	JSR subCalculateDirectionTowardJeep
	STA SpriteWhatDirectionToShoot,X
	LDA $08
	STA SpriteAbsoluteHorizPositionLB,X
	LDA $09
	STA SpriteAbsoluteHorizPositionUB,X
	LDA $0A
	STA SpriteVertScreenPosition,X
	LDA $0B
	STA SpriteAbsoluteVertPositionUB,X
	JMP +
Label698:	LDA SpriteData6,X
	ASL
	ASL
	STA SpriteWhatDirectionToShoot,X
+:	RTS

Label493:
	LDA SpriteData6,X
	AND #$03
	TAY
	LDA tblTurretHorizontalRecoilSpeedLB,Y
	STA SpriteHorizSpeedLB,X
	BPL +
	LDA #$FF
	STA SpriteHorizSpeedUB,X
+:	LDA tblTurretVerticalRecoilSpeedLB,Y
	STA SpriteVertSpeedLB,X
	BPL +
	LDA #$FF
	STA SpriteVertSpeedUB,X
+:	LDA SpriteData6,X
	AND #$04
	BEQ +
	JSR subInvertSpriteVertAndHorizSpeed
+:	RTS

tblTurretHorizontalRecoilSpeedLB:
	db $A0,$A0,$00,$60
tblTurretVerticalRecoilSpeedLB:
	db $00,$A0,$A0,$A0


;13,14,1C,1D
;************
;POW BUILDING
;
; SpriteData1 - BG Update index
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - Number of POWs to spawn
; SpriteData5 - POW Type (stand still or walk around)
; SpriteData6 - The slot index of the previous POW.  This allows the waiting POW to know when its time to walk out
; SpriteData8 - HELP text display and flash timer
;************
POWBuildingSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw POWBuildingState0
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	dw subPlayBarracksOpeningSound_LoadNewBuildingBGGraphics
	dw subProcessExplosionAnimation
	dw POWBuildingState4
	dw POWBuildingState5
	dw POWBuildingState6
	dw POWBuildingState7
	dw subScrollSprite_CheckForDespawn_UpdateBG

POWBuildingState0:
	JSR subUpdateSpritePositionForScrolling
	LDY CurrentLevel
	LDA tblLeftFacingPOWBuildingBGGraphicsUpdateIndex,Y ;Default value for Right facing buildings
	STA SpriteData1,X
	LDA #$10 ;direction - exit POWs left
	STA SpriteWhatDirectionToShoot,X
	LDA SpriteObjectID,X
	CMP #$94 ;Left facing 2 POW building
	BEQ +
	CMP #$9D ;Left Facing 4 POW building
	BEQ +
	LDA tblRightFacingPOWBuildingBGGraphicsUpdateIndex,Y
	STA SpriteData1,X
	LDA #$00 ;direction - exit POWs right
	STA SpriteWhatDirectionToShoot,X
+:	JMP subMoveSpriteToNextState

;These tables are indices for the tables
;;tblGraphicsUpdateHorizontalOffset,
;;tblGraphicsUpdateVerticalOffset, and
;;tblObjectControlledGraphicsUpdate
tblLeftFacingPOWBuildingBGGraphicsUpdateIndex:
	db $01 ;Level 1
	db $01 ;Level 2
	db $0C ;Level 3
	db $01 ;Level 4
	db $01 ;Level 5
	db $19 ;Level 6

tblRightFacingPOWBuildingBGGraphicsUpdateIndex:
	db $02 ;Level 1
	db $02 ;Level 2
	db $0D ;Level 3
	db $15 ;Level 4
	db $0F ;Level 5
	db $17 ;Level 6
	

;15
;*********************
;POW POWER UP BUILDING
;
; SpriteData1 - BG Update index
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - Gives the walking POW a #$01, to indicate it should walk around
; SpriteData6 - The sprite slot into which the Power Up POW was spawned
; SpriteData8 - All sprites that explode use SpriteData8 for the timer
;*********************
POWPowerUpBuildingSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw POWPowerUpBuildingState0
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	dw subPlayBarracksOpeningSound_LoadNewBuildingBGGraphics
	dw subProcessExplosionAnimation
	dw POWPowerUpBuildingState4
	dw subScrollSprite_CheckForDespawn_UpdateBG
	
POWPowerUpBuildingState0:
	LDY CurrentLevel
	LDA tblPOWPowerUpBuildingBGUpdateIndex,Y
	STA SpriteData1,X
	LDA #$08
	STA SpriteWhatDirectionToShoot,X
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	JMP subMoveSpriteToNextState
	
	;Index used to retrieve the X,Y offset for the new BG graphic, and the graphics itself
tblPOWPowerUpBuildingBGUpdateIndex	
	db $03,$04,$03,$16,$10,$03


;3C
;***********************************
;FLYING OVERHEAD HELICOPTER - RESCUE
;
; SpriteData1 - NOT USED
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - Rotor blade animation and audio timer
; All sprites that explode use SpriteData8 for the timer
;***********************************
FlyingOverheadHeliSpriteLogic

	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw FlyingOverheadHeliState0
	dw FlyingOverheadHeliState1

FlyingOverheadHeliState0: ;Intialize
	LDA #$31
	STA SpriteTypeIndex,X
	;get random horiz position (center of screen +/- (1/4) screen.  so the middle half
	LDA RNG_INCEveryFrame
	AND #$7F ;(0 to a quarter screen width)
	CLC
	ADC #$40 ;horiz middle of screen
	ADC ScreenLeftScrollPosition
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$00
	ROL
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$50 ;speed multiplier
	STA $08
	LDA #$18 ;direction - upward
	JSR subCalculateObjectSpeed
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

FlyingOverheadHeliState1:
	LDA SpriteData8,X
	AND #$03
	BNE +
	LDA #HelicopterBladesWhirringSoundClip
	JSR subInitiateSoundClip
+:	LDA #$31 ;default heli flying sprite
	STA SpriteTypeIndex,X
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;heli blades rotated
+:	JMP subUpdateSpritePositionForScrolling_Speed_CheckForDespawn

;3D,3E
;**************************
;LANDED HELICOPTER - RESCUE
;
; SpriteData1 - Count down for take off after last POW on board
; SpriteData2 - Timer for length of time heli initially waits to check if players have any POWs before leaving
; SpriteData3 - Original sprite type index (blades not rotated)
; SpriteData4 - Delay timer when the jeeps have 0 POWs onboard - gives the players time to gather spawned POWs on death before the heli leaves
; SpriteData5 - Used to ramp the rotor blade whirring sound on lift off
; SpriteData6 - NOT USED
; SpriteData8 - Rotor blade animation and audio timer
; All sprites that explode use SpriteData8 for the timer
;**************************
LandedHeliSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw LandedHeliState0
	dw LandedHeliState1
	dw LandedHeliState2
	dw LandedHeliState3
	dw LandedHeliState4
	dw LandedHeliState5
	
LandedHeliState0: ;Initialize
	LDA #$2F
	STA SpriteTypeIndex,X
	STA SpriteData3,X
	LDA #$40
	STA SpriteData1,X
	LDA #$80
	STA SpriteData2,X
	LDA #$FF
	STA SpriteData5,X
	LDA #$18
	STA SpriteWhatDirectionToShoot,X
	LDA #$80
	STA SpriteWhichJeeptoAttack,X
	LDA #$01
	LDY SpriteObjectID,X
	CPY #$BD ;Landed heli loads from the right
	BEQ +
	LDA #$FF
+:	STA POWDropOffWalkDirection
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState

LandedHeliState1: ;Initial delay plus check for players have no POWs left, or heli is just bypassed and goes off screen
	LDA #$2F ;landed heli sprite
	STA SpriteTypeIndex,X
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$04
	BEQ +
	INC SpriteTypeIndex,X ;rotate blased
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData2,X
	BPL +++
	INC SpriteData2,X ;keeps SpriteData2 at 0 so this code keeps running
	LDA Jeep1POWCount
	CLC
	ADC Jeep2POWCount
	BNE +
	BEQ ++ ;players have no POWS left
+:	;Check if players have left the heli behind and it went off screen
	LDA SpriteAbsoluteVertPositionUB,X
	CMP #$01 ;off screen below
	BNE +++
	LDA SpriteVertScreenPosition,X
	CMP #$30 ;pixel count
	BCC +++
--:
++:	JMP subMoveSpriteToNextState
-:
+++:	RTS

LandedHeliState2:
	LDA #$2F ;landed heli sprite
	STA SpriteTypeIndex,X
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$04
	BEQ +
	INC SpriteTypeIndex,X ;rotate blades
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteAbsoluteVertPositionUB,X
	CMP #$01
	BNE +
	LDA SpriteVertScreenPosition,X
	CMP #$30
	BCC +
	JSR subMoveSpriteToNextState
	JMP ++
+:	DEC SpriteData4,X
	BNE -
	LDA Jeep1POWCount
	CLC
	ADC Jeep2POWCount
	BEQ --
	JMP subMoveSpriteToPreviousState ;players picked up a POW.  go back to previous state to pick them up

LandedHeliState3:
	LDA #$00
	STA POWDropOffWalkDirection
	LDA SpriteData8,X
	AND SpriteData5,X
	BNE +
	LDA #HelicopterBladesWhirringSoundClip
	JSR subInitiateSoundClip
+:	LDA SpriteData3,X
	STA SpriteTypeIndex,X
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;Blades spinning
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData8,X
	AND #$0F
	BNE +
	LSR SpriteData5,X
+:	DEC SpriteData1,X
	LDA SpriteData1,X
	CMP #$01
	BEQ ++
	CMP #$20
	BNE +
	LDA #$31 ;update to heli sprite in the air, not on ground
	STA SpriteData3,X
+:	LDA SpriteAbsoluteVertPositionUB,X
	CMP #$01
	BNE +
	LDA SpriteVertScreenPosition,X
	CMP #$30
	BCC +
++:	;heli moving in the air
	LDA #$41 ;speed multiplier
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	LDA #$00
	STA POWDropOffWalkDirection
	JMP subMoveSpriteToNextState
-:
+:	RTS

LandedHeliState4: ;heli leaving upward/downward
	LDA SpriteData8,X
	AND #$03
	BNE +
	LDA #HelicopterBladesWhirringSoundClip
	JSR subInitiateSoundClip
+:	LDA #$31 ;heli in air sprite
	STA SpriteTypeIndex,X
	INC SpriteData8,X
	LDA SpriteData8,X
	AND #$02
	BEQ +
	INC SpriteTypeIndex,X ;rotated blade sprite
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteAbsoluteVertPositionUB,X
	;when moving down, this will just always be true, so the heli will continue downward and despawn itself via code in bank 7
	BPL - ;heli is offscreen above
	LDA SpriteVertScreenPosition,X
	CMP #$F0 ;off screen 10 pixels above
	BCC -
	JSR subClearSpriteSpeed
	LDA #$00 ;make heli invisible
	STA SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

LandedHeliState5: ;heli off screen, pause before leaving
	LDA SpriteData8,X
	AND #$03
	BNE +
	LDA #HelicopterBladesWhirringSoundClip
	JSR subInitiateSoundClip
+:	JSR subUpdateSpritePositionForScrolling
	INC SpriteData8,X ;just used as a timer to rotate blades
	DEC $06E0,X ;timer for delay off screen before flying back
	BNE -
	LDA #$00 ;put heli at the top of the screen
	STA SpriteVertScreenPosition,X
	STA SpriteAbsoluteVertPositionUB,X
	LDA RNG_INCEveryFrame
	AND #$7F
	CLC
	ADC #$40 ;horiz middle of the screen + RNG
	ADC ScreenLeftScrollPosition
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$00 ;puts heli on the left or right screen
	ROL
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$50 ;speed multiplier
	STA $08
	LDA #$08 ; direction - downward
	JSR subCalculateObjectSpeed
	LDA #$80 ;mirror sprite to point downward
	STA SpriteAttributes,X
	JMP subMoveSpriteToPreviousState


;3F
;************
;POW DROP OFF
;
; SpriteData1 - Enemy spawn timer LB
; SpriteData2 - Enemy spawn timer UB
; SpriteData3 - Counts the number of enemies spawned at the helipad
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;
;NOTE: jeep(s) collision with this object is used, in Bank 7, to spawn the POWs
;;walking to the heli on the helipad
;************
POWDropOffSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw POWDropOffState0
	dw POWDropOffState1
	dw subDespawnSprite

POWDropOffState0: ;Initialize
	JSR subUpdateSpritePositionForScrolling
-:	JMP subMoveSpriteToNextState

POWDropOffState1: ;Spawn harassing enemies
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	INC SpriteData1,X ;count towards spawning harassing enemies
	BNE +
	INC SpriteData2,X
	LDA SpriteData2,X
	AND #$01
	BNE +
	;Spawn an enemy every $200 frames
	LDA SpriteData3,X ;spawn as many enemies as the current level number
	CMP CurrentLevel
	BEQ +
	INC SpriteData3,X ;count enemy spawns
	LDY CurrentLevel
	LDA tblHelipadSpawnHarassmentEnemies,Y
	STA $08
	BEQ +
	;spawn harassing enemy
	LDA tblHelipadSpawnHarassmentEnemiesPalette,Y
	STA $0F
	;Load parameters for the Invert routine
	;This code effectively gets (X,-Y) and adds it to the (X,Y) of this object
	;;thus spawning the harassing enemy at (X,0).
	;In this case, X doesn't matter as all spawning enemies spawn relative to the player jeep
	LDA SpriteVertScreenPosition,X
	STA $00
	LDA SpriteAbsoluteVertPositionUB,X
	STA $01
	JSR fctInvert24Bit
	LDA $00
	STA $02
	LDA $01
	STA $03
	JSR subSpawnObjectFromParent_WithOffset
+:	LDA POWDropOffWalkDirection
	BEQ -
	RTS

;This table spawns enemies on the given level with the helipad on screen
;;to harass the player while unloading POWs
tblHelipadSpawnHarassmentEnemies:
	db $00 ;Level 1 - no spawn
	db $3B ;Level 2 - spawn bomber plane
	db $00 ;Level 3 - no  spawn
	db $00 ;Level 4 - no  spawn
	db $3B ;Level 5 - spawn bomber plane
	db $43 ;Level 6 - Spawn attack heli

tblHelipadSpawnHarassmentEnemiesPalette:
	db $00,$01,$00,$00,$01,$02
	

;****
;GATE
;
; SpriteData1 - BG update table index
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;****
GateSpriteLogic:

	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw GateState0
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	dw subInitiateExplosionAnimation_LoadReplacementBackgroundTiles_Collision
	dw subProcessExplosionAnimation
	dw subScrollSprite_CheckForDespawn_UpdateBG
	
GateState0: ;Initialize
	LDA #$00
	STA SpriteData1,X
	JSR subUpdateSpritePositionForScrolling
	JMP subMoveSpriteToNextState


;************
;ENEMY BULLET
;
; SpriteData1 - Bullet Type index
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - Sprite Type index for hitting the ground
; SpriteData5 - Sprite Type index for the bullet
; SpriteData6 - Bullet speed multiplier
; SpriteData8 - Time bullet is invisible after spawn (to make it look like the bullet is existing the barrel/not spawning on top of enemy)
;************
EnemyBulletSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw EnemyBulletState0
	dw EnemyBulletState1
	dw EnemyBulletState2
	dw subDespawnSprite

EnemyBulletState0: ;Initialize
	LDA SpriteWhatDirectionToShoot,X
	AND #$1F ;valid directions are 00-1F
	STA SpriteWhatDirectionToShoot,X
	LDA SpriteData6,X
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JSR subUpdateSpritePositionForScrolling
	;Adjust bullet distance/lifetime for player skill/difficulty
	LDA DifficultyBasedOnWeapon
	CLC
	ADC CurrentLevel
	LSR
	TAY
	LDA SpriteWhichJeeptoAttack,X
	CLC
	ADC tblEnemyBulletAdditionalLifetimeForDifficulty,Y
	STA $06E0,X ;bullet lifetime
	LDA CurrentLevel
	CMP #$04 ;Level 5
	BNE +
	LDA CurrentLevelScreen
	CMP #$0B ;Boss screen
	BNE +
	LDA CurrentLevelScreenSubPosition
	CMP #$C0 ;At the boss
	BCC +
	;changes the enemy bullet type.
	;;reference tables around tblBullet_ShellSpriteDisplayIndex for the effect of this
	INC SpriteData1,X
	INC SpriteData1,X
+:	JMP subMoveSpriteToNextState

	;This table contains additional existence frames for enemy bullets
	;The index selected is (Level + Difficulty)/2
	;looks like last index cannot be loaded as max is (5+3)/2 = 4
tblEnemyBulletAdditionalLifetimeForDifficulty:
	db $00,$08,$10,$18,$20,$28
	
EnemyBulletState1:	
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA #$00 ;?  why would the bullet logic clear this?
	STA $D7
	DEC $06E0,X
	LDA $06E0,X ;Check for bullet death (hitting the ground)
	BEQ ++
	;Bullet alive
	LSR
	BCC +
	LDA SpriteData1,X
	CMP #$0E ;Types 0E and 0F do not collide with the BG?
	BCS +
	JSR fctGetCollision_WithSpeed_NearLookAhead_BG ;check for collision
	CMP #$01
	BEQ ++
	LDY CurrentLevel
	CPY #$05 ;Level 6
	BNE +
	LDY SpriteData1,X
	CPY #$0A
	BCS +
	CMP #$03
	BEQ ++
	;Looks to deal with making the bullet visible after it was invisible after spawn
+:	DEC SpriteData8,X
	BNE +
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
+:
-:	RTS
	;Bullet hit the ground
++:	LDA SpriteData4,X
	STA SpriteTypeIndex,X
	LDA #$08 ;Time to display the bullet hitting the ground
	STA SpriteData8,X
	LDA #$F0 ;do not interact with anything any more
	STA SpriteHitboxShapeIndex,X
	JSR subClearSpriteSpeed
	JMP subMoveSpriteToNextState

EnemyBulletState2:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData8,X
	BNE -
	JMP subDespawnSprite
	
SpawnEnemyRoundBullet_Shell:	
	LDA #$36 ;Goes to $072X ;Object ID.  $36 = bullet
	STA $08
	LDA #$11 ;Goes to SpriteData4
	STA $09
	LDA tblBullet_ShellSpriteDisplayIndex,Y ;Goes to SpriteData5
	STA $0A
	LDA tblBullet_ShellTravelSpeed,Y ;Goes to SpriteData6
	STA $0B
	LDA SpriteWhatDirectionToShoot,X ;Goes to $06CX
	STA $0C
	LDA tblBullet_ShellInvisibilityFrameCountAfterSpawn,Y ;Goes to SpriteData8
	CLC
	ADC #$01 ;STA $0D then INC $0D would be better
	STA $0D
	LDA tblBullet_ShellLifetimeInFrames,Y ;Goes to $06EX
	STA $0E
	LDA tblBullet_ShellGraphicsAttributes,Y ;Goes to $054X
	STA $0F
	TYA
	STA $10 ;Goes to SpriteData1
	CPY #$0B
	BCS +	
	JMP subSpawnObjectFromParent_NoOffset
+:	JMP subSpawnObjectFromParent_WithOffset

;$10 is the normal round bullet.  $4A is the large black shell
tblBullet_ShellSpriteDisplayIndex:
	db $10,$10,$10,$4A,$10,$10,$10,$4A,$4A,$10,$10,$10,$10,$10,$10,$10

tblBullet_ShellTravelSpeed:	
	db $20,$22,$31,$30,$31,$20,$31,$31,$40,$31,$40,$41,$20,$21,$20,$21
	
;These invisiblity frames give the projectile time to clear the originating sprite so it doesn't overlap
tblBullet_ShellInvisibilityFrameCountAfterSpawn
	db $08,$10,$0C,$0C,$06,$08,$06,$00,$08,$08,$04,$00,$00,$00,$00,$00
	
;The total number of frames that the projectile will travel before dying/hitting the ground
tblBullet_ShellLifetimeInFrames:
	db $30 ;00 mobile Infantry Bullet
	db $60 ;01 Red Medium Tank/Level 1 Attack Boat/Level 3 Large Attack Boat Bullet
	db $40 ;02 Level 1 Boss Tank
	db $40 ;03 Silver Large Tank
	db $60 ;04 Spread Turret Bullets
	db $40 ;05 Stationary Infantry Bullet 
	db $88 ;06 Level 4 Train Car Bullet and L3 boss spread turret
	db $50 ;07 Level 5 Mounted Turret Shell
	db $40 ;08 L4 Spread Truck Shell
	db $30 ;09 level 4 Boss Helicopter Bullet
	db $18 ;0A Level 6 Attack Helicopter Bullet
	db $24 ;0B Level 6 Boss Tank Turret Bullet
	db $60 ;0C Gray Turret White Bullet
	db $60 ;0D Gray Turret Yellow Bullet
	db $60 ;0E NOT USED?
	db $60 ;0F NOT USED?
	
;used by the same enemies as above
tblBullet_ShellGraphicsAttributes:
	db $02,$02,$03,$02,$02,$02,$03,$02,$02,$02,$02,$03,$02,$03,$02,$03
	
SpawnTurretProjectile:
	;Set spawn offset
	LDA #$00
	STA $01
	STA $03
	LDY SpriteData6,X
	LDA tblTurretBulletSpawnHorizSpawnLocationOffset,Y
	STA $00
	BPL +
	DEC $01
+:	LDA tblTurretBulletSpawnVertSpawnLocationOffset,Y
	STA $02
	BPL +
	DEC $03
	
+:	LDA SpriteObjectID,X
	;Level 6 Boss Tank Turret
	CMP #$4F 
	BNE +
	LDY #$0B ;bullet type
	JMP SpawnEnemyRoundBullet_Shell
	;This is just a fancy way to set the turret bullet typ
+:	ORA #$80
	SEC
	SBC #$85 ;gray turret is 5, yellow bullet turret is 6
	CLC
	ADC #$0C ;gray turret uses bullet C, yellow bullet turret uses D
	TAY ;bullet type
	JMP SpawnEnemyRoundBullet_Shell

;As the turret turns, the bullet needs to spawn at the end of the barrel
tblTurretBulletSpawnHorizSpawnLocationOffset:
	db $14,$0C,$00,$F4,$EC,$F4,$00,$0C
	
tblTurretBulletSpawnVertSpawnLocationOffset:
	db $00,$0C,$14,$0C,$00,$F4,$EC,$F4


;50,51,52
;*************
;POWER UP STAR
;
; SpriteData1 - $40 is written, but is never used
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;*************
PowerUpStarSpriteLogic:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump
	
	dw PowerUpStarState0
	dw subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	dw PowerUpStarState2
	dw PowerUpStarState3
	
PowerUpStarState0: ;Initialize
	LDA ContinuesUsed
	BPL + 
	;Game was been beaten at least once
	JMP subDespawnSprite ;Don't spawn any stars after game is beaten - makes it harder
	
	;Game has not been beaten
+:	JSR subUpdateSpritePositionForScrolling
	LDA #$40
	STA SpriteData1,X
	;For level 3, when the full bazooka power up is spawned underneath the parked jeep,
	;;the power up object state is set to 2, which makes it instantly visible.
	;Note that you cannot place this power up star normally on the level, for
	;;It would always be visible...
	LDA CurrentLevel
	CMP #$02
	BNE +
	LDA SpriteObjectID,X
	CMP #$D1 ;Full bazooka Star ID
	BNE +
	LDA #$02
	JMP subSetSpriteState
+:	JMP subMoveSpriteToNextState

PowerUpStarState2: ;Death state (jeep player hit the star revealing it)
	LDA #$2E ;show star visible
	STA SpriteTypeIndex,X
	LDA #$74
	STA SpriteHitboxShapeIndex,X
	LDA #$01 ;I guess a non-zero health is requied to not have the star 'die'?
	STA SpriteHealthHP,X
	LDA #$00 ;Default to green palette
	STA SpriteGraphicsAttributes,X
	STA EnemyPoints,X
	LDA SpriteObjectID,X
	CMP #$D2 ;Extra Life Star ID
	BEQ +
	LDA #$01 ;Load the brown palette (player 2 jeep) for the Kill All Enemies Star
	STA SpriteGraphicsAttributes,X
+:	JMP subMoveSpriteToNextState

PowerUpStarState3: ;Persist and flash
	LDA SpriteObjectID,X
	CMP #$D1  ;Full bazooka Star ID
	BNE +
	;Only flash the Full Bazooka Star
	INC SpriteGraphicsAttributes,X
	LDA SpriteGraphicsAttributes,X
	AND #$03
	STA SpriteGraphicsAttributes,X
+:	JMP subUpdateSpritePositionForScrolling_Speed_CheckForDespawn


;Free space to the end of the bank
	
	
	.PAD $C000 ;End of Bank
	