;Bank 1F
	.BASE $C000
	
	;DPCM table 1
	db $AA,$AA,$AA,$AA,$AA,$AF,$F0,$9E,$9F,$F0,$06,$AE,$7C,$1B,$98,$F0 ;0
	db $00,$03,$00,$0C,$01,$CE,$01,$80,$00,$00,$00,$00,$00,$0F,$1F,$FF
	db $FB,$F3,$CF,$F3,$EF,$DE,$B8,$F9,$A6,$A2,$24,$39,$81,$43,$80,$86
	db $19,$02,$38,$51,$87,$86,$15,$39,$8C,$A6,$55,$4D,$16,$8C,$A3,$45
	db $45,$90,$CA,$56,$22,$52,$70,$D6,$53,$16,$D3,$54,$D7,$4B,$37,$4B ;1
	db $5B,$6B,$56,$CE,$B5,$5B,$5D,$59,$B6,$D5,$AB,$D6,$B5,$D7,$6B,$6D
	db $AD,$AE,$B6,$D6,$B5,$B5,$AA,$D6,$AA,$AC,$AA,$A9,$54,$A9,$94,$A4
	db $A9,$4A,$4A,$8A,$92,$54,$A5,$49,$29,$4A,$54,$A5,$29,$52,$A5,$4A
	db $A5,$54,$A9,$54,$AA,$95,$2A,$AA,$94,$95,$2A,$AA,$55,$55,$2A,$56 ;2
	db $66,$AA,$9A,$AA,$B5,$5A,$AD,$AB,$5A,$B5,$6B,$6B,$6B,$5A,$B5,$AA
	db $B5,$56,$AA,$D5,$55,$56,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$95,$55,$55
	db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	
	;DPCM table 0
	db $FE,$FF,$DE,$FF,$E3,$EF,$8C,$44,$40,$31,$37,$09,$80,$18,$60,$00 ;0
	db $C0,$20,$2F,$3A,$A3,$57,$EF,$9F,$AF,$FF,$DE,$BF,$9E,$C9,$24,$41
	db $09,$00,$04,$00,$18,$74,$9B,$BF,$76,$EB,$CF,$7B,$DF,$F3,$81,$E2
	db $68,$31,$1C,$31,$88,$6A,$C0,$8F,$06,$D4,$C5,$C7,$2F,$1D,$63,$A7
	db $D0,$FC,$63,$CF,$B8,$DC,$76,$33,$EE,$30,$E2,$D0,$08,$38,$84,$01 ;1
	db $42,$1E,$7D,$9E,$7F,$E7,$EF,$3F,$7F,$3F,$87,$DC,$63,$18,$88,$53
	db $11,$06,$0D,$62,$03,$3C,$33,$24,$E7,$1F,$F8,$F0,$F3,$CF,$71,$AE
	db $1C,$8E,$CF,$08,$CE,$C2,$40,$E1,$8E,$18,$2C,$D1,$91,$ED,$9F,$0F
	db $CF,$C7,$CC,$F5,$38,$39,$B8,$19,$47,$88,$46,$D6,$04,$58,$63,$9C ;2
	db $61,$79,$8C,$F3,$98,$F7,$78,$27,$C7,$0F,$8C,$F5,$86,$2F,$91,$8C
	db $71,$C7,$21,$E1,$C4,$07,$A6,$2E,$8A,$E7,$43,$CF,$9E,$1F,$9E,$71
	db $F3,$63,$C3,$18,$C3,$B0,$E0,$E3,$0F,$08,$E0,$71,$8C,$39,$39,$99
	db $F1,$BC,$74,$76,$E2,$F3,$C7,$97,$19,$C6,$37,$0F,$09,$C6,$71,$23
	db $88,$E0,$A9,$83,$8B,$8C,$EF,$0D,$DA,$F4,$73,$EE,$1C,$DB,$8E,$76
	db $1A,$2E,$31,$C3,$9C,$59,$07,$A1,$C0,$F1,$19,$9C,$58,$3C,$E3,$39
	db $E3,$8E,$B8,$E7,$1C,$E3,$A7,$0D,$8E,$C2,$39,$E6,$26,$36,$19,$8C
	db $74,$98,$CD,$47,$38,$B8,$F2,$6E,$AC,$B3,$B4,$E5,$71,$27,$8E,$8C
	db $8F,$8E,$1C,$6B,$29,$8E,$1C,$2C,$68,$D9,$31,$E3,$55,$97,$38,$D3
	db $B1,$CE,$38,$F1,$D4,$B3,$4E,$A9,$62,$C9,$A8,$AC,$A9,$18,$E6,$51
	db $9A,$73,$29,$9E,$39,$D3,$65,$9D,$58,$BA,$61,$DA,$46,$AA,$3C,$52
	db $B1,$31,$E0,$E5,$95,$2A,$CC,$B2,$9C,$AC,$AB,$39,$66,$6A,$CC,$AB
	db $8B,$55,$A6,$A6,$AA,$3C,$5A,$39,$38,$B9,$54,$AA,$95,$AA,$65,$5A
	db $9C,$C7,$59,$B2,$AE,$D4,$B1,$D4,$63,$C5,$34,$6A,$65,$69,$65,$4C
	db $E3,$54,$D6,$33,$4D,$71,$92,$EA,$9A,$AB,$56,$55,$5A
	
	.PAD $C23D
;***********
;***********
RESET_VECTOR:
;***********
;***********
	CLD 
	SEI
	
	;Loops here waiting for PPU
-:	LDA PPUSTATUS 
	BPL -
	
	;Loops here waiting for PPU
-:	LDA PPUSTATUS 
	BPL -
	JSR subSetPPUToBlackScreen ;Once the PPU has fully booted, now we can Init the PPU
	
	;Set the stack to 01FF
	LDX #$FF
	TXS
	
	INX ;Set X=0
	
	;Zeroes out MOST of RAM (000-7CF, MISSES $700!!)
	LDA #$07
	STA $01
	TXA ;Set A=0
	STX $00
	LDY #$CF 
-:	STA ($00),Y
	DEY ;7CF-701 are erased, then Y underflows to $FF, so then 6FF-000 are all erased as well
	BNE -
	DEC $01
	BPL -
	
	;This section checks 7F0-7FF for values F0-FF respectively.
	;I'm not sure why this is done.  These RAM locations don't seem to be read or written to elsewhere.
	;Perhaps it is some initialization for something?  maybe to eat some CPU cycles on power on??
	LDX #$F0
-:	TXA ;A will get $F0 through $FF as X is incremented
	CMP SpriteAbsoluteVertPositionUB,X
	BNE + ;if $07F# <> $F#
	INX
	BNE -
	BEQ ++
	
	;Writes #$00-#$FF to $0700-$07FF
+:	TYA
-:	STA SpriteAbsoluteVertPositionUB,Y
	INY
	BNE -
	
	;Writes #$F0-#$FF to $07F0-$07FF
	LDX #$F0
-:	TXA
	STA SpriteAbsoluteVertPositionUB,X
	INX
	BNE -
	
	;Sets initial high score to 5,000 points
	;;High score is not used in Jackal like other Konami games
	;;This just seems to be default or left over code from a template or other game
	LDA #$50
	STA HighScore_xx99xx
	
++:	LDA #$00
	STA SpriteAbsoluteVertPositionUB
	JSR subInitAPUAndPPU
	JSR subStopMusic
WAIT: JMP WAIT ;program hangs here waiting for the next NMI
	;**********************
	;**********************
	
	
;**************************************
;NMI VECTOR - ALL main code exists here
;**************************************

;*********
;*********
NMI_VECTOR:
;*********
;*********
	PUSHALL
	
	;**************************************
	;Write OAMDMA values for all 64 sprites
	;**************************************
	LDA PPUSTATUS ;Do this to clear the PPUADDR inputs
	;Previous frame was not done processing updates
	LDY GameFrameLogicInProgress ;The game is lagging.  Wait to process the main game logic until next frame
	BNE subProcessMinimalLogicDuringLagFrame ;Only process screen scrolling and sound/music
	
	LDA PPUSTATUS ;Do this to reset the PPUADDR inputs
	LDA #$00
	STA PPUADDR
	STA PPUADDR
	STA PPUMASK
	STA OAMADDR
	LDY #$02 ;writes 256 bytes of RAM data to the PPU internal memory via OAMDMA from $200 to $2FF(object attribute memory direct memory access)
	STY OAMDMA
	JSR subInGamePPUUpdates
	LDA NormalPPUMASK
	LDX ScreenTransitionTimer
	BEQ +
	DEC ScreenTransitionTimer
	BEQ +
	LDA #$00 ;Disable all graphics (no sprites, no BG, etc), if the blank screen count down is not finished
+:	STA PPUMASK
	JSR subProcessScreenScrolling
	INC GameFrameLogicInProgress
	JSR subProcessSound_Music
	JSR subProcessControllerInputs
	
	;Change to Bank 1
	LDY #$01
	JSR subChangeBank_YhasBank
	JSR subProcessSpriteUpdates
	JSR subProcessGameControl
	JSR Label757 ;writes a 0 at the end of the PPU update buffer
	LDA #$00
	STA GameFrameLogicInProgress
	
END_NMI:	
	PULLALL
	
;*************
;*************
IRQ_BRK_VECTOR:
;*************
;*************
	RTI ;This will always go back to the WAIT label
	
subProcessMinimalLogicDuringLagFrame:	
	JSR subProcessScreenScrolling
	JSR subProcessSound_Music
	JMP END_NMI
	
	;Called once on RESET/Power on
subInitAPUAndPPU: ;ROUTINE - Initializes the APU  (---D NT21)
	;Status write - DMC=OFF, NoiseChannel=ON, TriangleChannel=ON, PulseChannel2=ON, PulseChannel1=ON
	LDA #$0F
	STA APUSTATUS
	;Frame Counter write - Mode=1, IRQInhibit=ON  (MI-- ----)
	LDA #$C0
	STA APUCOUNTERIRQ
InitPPU:	
;This seems to be a very redundant call
;;No other location calls here, and the code is ran anyway a few bytes later...
	JSR +
	
	;Write the normal PPUCTRL value
	LDA #NormalPPUCTRLValue
	STA NormalPPUCTRL
	STA PPUCTRL
+:	LDA #$05 ;5 screens of blank/all black.  Probably has to do with PPU initialization
	STA ScreenTransitionTimer
	RTS
	
subProcessScreenScrolling:
	LDA Level6BossTankScroll_Next
	BEQ +
	;Level 6 boss screen scrolling
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR	
	LDA PPUSTATUS ;This resets the PPUADDR lines
	LDY Level6BossTankScroll_Current
	LDA Level6BossTankScroll_Next
	STA Level6BossTankScroll_Current
	TYA
	EOR #$FF
	CLC
	ADC #$01
	STA PPUSCROLL
	LDA ScreenVerticalScrollPosition_PPU
	STA PPUSCROLL
	;Big delay here
	LDY #$09
	LDX #$01
-:	DEX
	BNE -
	DEY
	BNE -
	
+:	LDA PPUSTATUS
	LDA ScreenHorizontalScrollPosition_PPU ;Load the current horizontal screen scroll position
	STA PPUSCROLL ;write to PPU
	LDA ScreenVerticalScrollPosition_PPU ;Load the current vertical screen scroll position
	STA PPUSCROLL ;write to PPU
	LDA NormalPPUCTRL
	STA PPUCTRL ;write to PPU
	RTS
	
subSetPPUToBlackScreen: ;ROUTINE - Initialize PPU
	LDA NormalPPUCTRL ;Load the nominal PPU control value (#$A8)
	AND #$7F ;This disables NMI on the PPU
	STA PPUCTRL
	LDA PPUSTATUS ;Do this to clear the 2006 address 'first/second' so a fresh 16byte VRAM address can be fed in to the PPU
	LDA #$00
	STA PPUADDR ;Set the VRAM address to $0000
	STA PPUADDR
	STA PPUMASK ;Disable all graphics (no sprites, no BG, etc)
	RTS
	
subStopMusic:
	LDA #EMPTYSoundClip 
subInitiateSoundClip:
	PHA ;Preserve A
	LDA SoundUpdateInProgress
	BNE ++
	STX $06 ;Preserve X
	STY $07 ;Preserve Y
	LDA #$01
	STA SoundUpdateInProgress
	LDY #$00
	JSR subChangeBank_YhasBank_BypassCurrentBank
	PLA ;Restore A
	JSR Label40
	JSR subChangeBank_UseCurrentBank
	LDX $06 ;Restore X
	LDY $07 ;Restore Y
	LDA #$00
	STA SoundUpdateInProgress
	RTS
	
subProcessSound_Music:
	LDA SoundUpdateInProgress
	BNE + ;RTS - abort if something else is updating/initiating a sound
	LDA #$01
	STA SoundUpdateInProgress ;Set Flag indicating something is updating/initiating a sound
	TYA
	PHA ;Preserve Y
	TXA
	PHA ;Preserve X
	LDY #$00 ;Bank 0 for audio
	JSR subChangeBank_YhasBank_BypassCurrentBank
	JSR subPlaySound_Music ;Jump to Bank 0 code to begin updating the APU
	JSR subChangeBank_UseCurrentBank ;Return the bank to its previous value
	PLA
	TAX ;Restore X
	PLA
	TAY ;Restore Y
	LDA #$00
	STA SoundUpdateInProgress ;Clear flag
	RTS
++:	PLA
+:	RTS
	
;ROUTINE - Loads a new bank using the value in Y
subChangeBank_YhasBank:	
	STY CurrentBank 
;ROUTINE - Loads a new bank using the value in CurrentBank
subChangeBank_UseCurrentBank:	
--:	LDY CurrentBank
;ROUTINE - Loads a new bank using the value in Y.  Bypasses updating CurrentBank
subChangeBank_YhasBank_BypassCurrentBank:
-:	LDA $8000,Y
	STA $8000,Y
	STA $8000,Y
	RTS

subLoadNewPatternTable:
	PHA ;Preserve A
-:	LDA PPUSTATUS
	BPL -
	JSR subSetPPUToBlackScreen ;A is ZERO from this jsr
	STA PPUGraphicsUpdateTableIndex
	STA PPUGraphicsUpdateComplete
	LDA #$20
	STA $09
	LDA #$03
	STA $08
	PLA ;Restore A
	ASL ;* 2 for 2 bytes per address
	TAY
	LDA tblLevel_ScenePPUPatternTableHeaderAddress,Y
	STA $00
	LDA (tblLevel_ScenePPUPatternTableHeaderAddress + 1),Y
	STA $01
---:	LDY #$00
	LDA ($00),Y ;Read the next byte (bank or #$FF end of table)
	CMP #$FF
	BNE +
	LDA $0A
	STA CurrentBank
	JSR subChangeBank_UseCurrentBank
	JMP InitPPU
+:	TAX
	LDA $8000,X
	STA $8000,X ;Changes the active bank to the value in X
	STA $8000,X
	LDA CurrentBank
	STA $0A
	STX CurrentBank
	INY ;Increment to PPU Address
		
	LDA ($00),Y
	STA $02
	INY
	LDA ($00),Y
	STA $03
	LDA PPUSTATUS
	LDY #$00
	LDA ($02),Y
	STA PPUADDR
	INY
	LDA ($02),Y
	STA PPUADDR
--:	INY
	BNE +
	INC $03
+:	LDA ($02),Y
	CMP #$FF
	BEQ ++++
	BPL +++
	AND #$7F
	STA $04
-:	INY
	BNE +
	INC $03

+:	LDA ($02),Y
	STA PPUDATA
	DEC $09
	BNE +
	DEC $08
	BNE +
	LDA #$03
	STA $08
	LDA #$20
	STA $09
	JSR subProcessSound_Music
+:	DEC $04
	BNE -
	BEQ --
+++:	AND #$7F
	STA $04
	INY
	BNE +
	INC $03
+:	LDA ($02),Y
-:	STA PPUDATA
	DEC $04
	BNE -
	BEQ --
++++	LDA #$03
	LDX #$00
	JSR fctAdd_A_To16BitValueIn_00_01_OffsetX_RAM
	JMP ---

tblLevel_ScenePPUPatternTableHeaderAddress:
	dw tblLevel1PPULoadData ;0
	dw tblLevel2PPULoadData ;1
	dw tblLevel3PPULoadData ;2
	dw tblLevel4PPULoadData ;2
	dw tblLevel5PPULoadData ;4
	dw tblLevel6PPULoadData ;5
	dw tblTitle_POWPortrait_GameOverScreenPPULoadData ;A Title Screen
	dw tblTitle_POWPortrait_GameOverScreenPPULoadData ;B POW/Game Over Screen
	dw tblYEAHHH_WeMadeItPPULoadData ;C YEAHHHH!/We Made It! Screen
	dw tblEndOfGamePPULoadData ;D End of Game
	dw tblHERE_ScreenPPULoadData ;E HERE? screen

	;***********************************
	;Level 1 PPU Pattern Table Load Data
	;***********************************
tblLevel1PPULoadData:
	;Level 1 Common Text Tiles
	db $02  ;Bank
	dw tblCommonTextBGGraphics ;ROM Address
	
	;Level 1 Common BG Tiles
	db $02   ;Bank
	dw tblCommonBGGraphics ;ROM Address
	
	;Level 1 Specific BG Tiles
	db $03   ;Bank
	dw tblLevel1BGGraphics ;ROM Address
	
	;Level 1 Common Sprite Tiles
	db $02   ;Bank
	dw tblCommonSpriteGraphics ;ROM Address
	
	;Level 1 Specific Sprite Tiles
	db $02   ;Bank
	dw tblLevel1SpriteGraphics ;ROM Address
	db $FF ;End of section marker
	
	
	;***********************************
	;Level 2 PPU Pattern Table Load Data
	;***********************************
tblLevel2PPULoadData:
	;Level 2 Common Text Tiles
	db $02  ;Bank
	dw tblCommonTextBGGraphics ;ROM Address
	
	;Level 2 Common BG Tiles
	db $02   ;Bank
	dw tblCommonBGGraphics ;ROM Address
	
	;Level 2 Specific BG Tiles
	db $03   ;Bank
	dw tblLevel2BGGraphics ;ROM Address
	
	;Level 2 Common Sprite Tiles
	db $02   ;Bank
	dw tblCommonSpriteGraphics ;ROM Address
	
	;Level 2 Specific Sprite Tiles
	db $02   ;Bank
	dw tblLevel2SpriteGraphics ;ROM Address
	db $FF ;End of section marker


	;***********************************
	;Level 3 PPU Pattern Table Load Data
	;***********************************
tblLevel3PPULoadData:
	;Level 3 Common Text Tiles
	db $02  ;Bank
	dw tblCommonTextBGGraphics ;ROM Address
	
	;Level 3 Specific BG Tiles
	db $03   ;Bank
	dw tblLevel3BGGraphics ;ROM Address
	
	;Level 3 Common Sprite Tiles
	db $02   ;Bank
	dw tblCommonSpriteGraphics ;ROM Address
	
	;Level 3 Specific Sprite Tiles
	db $02   ;Bank
	dw tblLevel3SpriteGraphics ;ROM Address
	db $FF ;End of section marker
	

	;***********************************
	;Level 4 PPU Pattern Table Load Data
	;***********************************
tblLevel4PPULoadData:
	;Level 4 Common Text Tiles
	db $02  ;Bank
	dw tblCommonTextBGGraphics ;ROM Address
	
	;Level 4 Common BG Tiles
	db $02   ;Bank
	dw tblCommonBGGraphics ;ROM Address
	
	;Level 4 Specific BG Tiles
	db $03   ;Bank
	dw tblLevel4BGGraphics ;ROM Address
	
	;Level 4 Common Sprite Tiles
	db $02   ;Bank
	dw tblCommonSpriteGraphics ;ROM Address
	
	;Level 4 Specific Sprite Tiles
	db $02   ;Bank
	dw tblLevel4SpriteGraphics ;ROM Address
	db $FF ;End of section marker


	;***********************************
	;Level 5 PPU Pattern Table Load Data
	;***********************************
tblLevel5PPULoadData:
	;Level 5 Common Text Tiles
	db $02  ;Bank
	dw tblCommonTextBGGraphics ;ROM Address
	
	;Level 5 Common BG Tiles
	db $02   ;Bank
	dw tblCommonBGGraphics ;ROM Address
	
	;Level 5 Specific BG Tiles
	db $03   ;Bank
	dw tblLevel5BGGraphics ;ROM Address
	
	;Level 5 Common Sprite Tiles
	db $02   ;Bank
	dw tblCommonSpriteGraphics ;ROM Address
	
	;Level 5 Specific Sprite Tiles
	db $02   ;Bank
	dw tblLevel5SpriteGraphics ;ROM Address
	db $FF ;End of section marker
	

	;***********************************
	;Level 6 PPU Pattern Table Load Data
	;***********************************
tblLevel6PPULoadData:
	;Level 6 Common Text Tiles
	db $02  ;Bank
	dw tblCommonTextBGGraphics ;ROM Address
	
	;Level 6 Specific BG Tiles
	db $03   ;Bank
	dw tblLevel6BGGraphics ;ROM Address
	
	;Level 6 Common Sprite Tiles
	db $02   ;Bank
	dw tblCommonSpriteGraphics ;ROM Address
	
	;Level 6 Specific Sprite Tiles
	db $02   ;Bank
	dw tblLevel6SpriteGraphics ;ROM Address
	db $FF ;End of section marker

	
	;**************************************************
	;Level Segue (YEAHHHH!) PPU Pattern Table Load Data
	;**************************************************
tblYEAHHH_WeMadeItPPULoadData:
	;BG Tiles
	db $01   ;Bank
	dw tblLevelSegue_BGGraphics ;ROM Address

	;YEAH BG Graphics
	db $05   ;Bank
	dw tblYEAH_BGGraphics ;ROM Address
	
	;Sprite Tiles
	db $01   ;Bank
	dw tblLevelSegue_SpriteGraphics ;ROM Address
	db $FF ;End of section marker
	
	
	;************************************************
	;Level Segue (HERE??) PPU Pattern Table Load Data
	;************************************************
tblHERE_ScreenPPULoadData:
	;BG Tiles
	db $01   ;Bank
	dw tblLevelSegue_BGGraphics ;ROM Address

	;HERE BG Graphics
	db $05   ;Bank
	dw tblLevelComplete_HEREScreen ;ROM Address
	
	;Sprite Tiles
	db $01   ;Bank
	dw tblLevelSegue_SpriteGraphics ;ROM Address
	db $FF ;End of section marker
	
	
	;**********************************************
	;End of Game Screen PPU Pattern Table Load Data
	;**********************************************
tblEndOfGamePPULoadData:
	;BG Tiles
	db $01   ;Bank
	dw tblEndOfGameBGGraphics ;ROM Address
	
	;Sprite Tiles
	db $01   ;Bank
	dw tblEndOfGameSpriteGraphics ;ROM Address
	db $FF ;End of section marker
	
	
	;******************************************************
	;Title Screen/POW Portraits PPU Pattern Table Load Data
	;******************************************************
tblTitle_POWPortrait_GameOverScreenPPULoadData:
	;BG Tiles
	db $01   ;Bank
	dw tblLevelSegue_BGGraphics ;ROM Address
	
	db $03   ;Bank
	dw tblTitleScreenBGGraphics ;ROM Address
	
	;Common Level sprite tiles (Jeep, POWs, Grenade, Bazooka, etc)
	db $02   ;Bank
	dw tblCommonSpriteGraphics ;ROM Address
	db $FF ;End of section marker
	;*************************************
	
subProcessGameControl:	
	INC RNG_INCEveryFrame
	LDA GameControlState
	CMP #$03
	BCS +
	JSR Label774 ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
+:	LDA GameControlState
	JSR subExecuteCodeViaIndirectJump
	
	dw GameControlState0
	dw GameControlState1
	dw GameControlState2
	dw GameControlState3
	dw GameControlState4
	dw GameControlState5
	dw GameControlState6
	dw GameControlState7
	dw GameControlState8
	dw GameControlState9

GameControlState0:	;Starting at title screen
	LDA #$01 ;We are at the title screen
	STA TitleScreenMode
	JSR subTitleScreenInitialization
	LDA #$02 ;title screen delays before changing/shifting - upper byte
	STA ScreenTimerUB
	LDA #$80
	JMP subSetScreeTimeLB_NextGameControlState

;The vertical positions where the jeep is displayed for selected 1 or 2 players
tblTitleScreenJeepSpriteVerticalPosition_1_2Player:
	db $9A,$AA
	
GameControlState1:	;Waiting for player input.  Counting down to scrolling to story
	LDA #$58 ;Jeep Sprite Horizontal position
	STA SpriteHorizScreenPosition
	LDA #$05 ;Right facing jeep
	STA SpriteTypeIndex
	LDX Player2Active
	LDA tblTitleScreenJeepSpriteVerticalPosition_1_2Player,X
	STA SpriteVertScreenPosition
	JSR fctCountDownScreenTimer
	BNE + ;RTS
	JSR subEraseAllSpriteData
	LDA #TitleScreenStory_POWPortraitsSoundClip
	JSR subInitiateSoundClip
	JMP subSetScreeTimeLBTo80_NextGameControlState
+:
-:	RTS

;**************************************
;Title Screen Scroll/POW Portrait Logic
;**************************************
GameControlState2:
	LDA $19
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	dw TitleScreenState0
	dw TitleScreenState1
	dw TitleScreenState2
	dw TitleScreenState3
	dw TitleScreenState4

TitleScreenState0: ;Scrolls the screen to the right (story text)
	INC ScreenHorizontalScrollPosition_PPU ;Scroll the screen right - story text
	LDA ScreenHorizontalScrollPosition_PPU
	CMP #$FF ;Stop value
	BNE -
	JSR subEraseAllSpriteData
	JSR subEraseInGameJeepData
	LDA #$02
	STA ScreenTimerUB
	LDA #$14
	JMP subIncrementSubGameState_SetScreenTimeLB
	
TitleScreenState1: ;Delay for the player to read the text
	JSR fctCountDownScreenTimer
	BNE -
	JSR Label159
	;Init variables for next state
	LDA #$00
	STA $50
	LDA POWPortraitTextIndex
	BNE +
	JSR Label780
	JMP subIncrementSubGameState
+:	JSR Label781
	JMP subIncrementSubGameState
	
TitleScreenState2: ;Scroll portraits onto the screen
	JSR subCheckForPOWPortraitShift_BottomHalfOfScreen
	LDA $50
	CMP #$F8
	BCC ++ ;RTS
	LDA POWPortraitTextIndex
	AND #$01
	BNE + ;Only play the shing sound once per portrait screen
	LDA #POWPortraitScrollIntoPlace_Shing_SoundClip
	JSR subInitiateSoundClip
+:	LDA POWPortraitTextIndex
	ASL ;Multiply by 2 because the addresses in the table ar 2 bytes
	TAX
	LDA tblPOWPortraitPPUUpdateAddresses,X ;POW 1/3
	STA $56
	STA $00
	LDA (tblPOWPortraitPPUUpdateAddresses + 1),X ;POW 2/4
	STA $58
	STA $01
	LDY #$00
	LDA ($00),Y
	STA $5A
	INY
	LDA ($00),Y
	STA $5C
	INY
	STY $5E
	LDA #$20
	STA $54
	INC $19 ;Go to the next state
-:
++:	RTS

TitleScreenState3:
	JSR subCheckForPOWPortraitShift_BottomHalfOfScreen
	DEC $54
	BNE -
	LDA #POWPortraitTextPrintSoundClip
	JSR subInitiateSoundClip
	LDA #$06
	STA $54
	LDX PPUGraphicsUpdateByteLength
	LDA #$01
	STA $0770,X
	INX
	LDA $5A
	STA $0770,X
	INX
	LDA $5C
	INC $5C
	STA $0770,X
	INX
	LDA $56
	STA $00
	LDA $58
	STA $01
	LDY $5E
	LDA ($00),Y
	STA $0770,X
	INX
	LDA #$FF
	STA $0770,X
	INX
	LDA #$00
	STA $0770,X
	STX PPUGraphicsUpdateByteLength
	INY
	STY $5E
	LDA ($00),Y
	CMP #$FE
	BCC -
	CMP #$FF
	BEQ +
	LDA #$10
	STA $54
	INY
	LDA ($00),Y
	STA $5A
	INY
	LDA ($00),Y
	STA $5C
	INY
	STY $5E
-:	RTS
+:	INC POWPortraitTextIndex
	LDA POWPortraitTextIndex
	CMP #$04
	BCS +
	CMP #$02
	BNE ++
+:	LDA #$50
	JMP subIncrementSubGameState_SetScreenTimeLB
++:	LDA #$02
	JMP Label788

TitleScreenState4:
	JSR subCheckForPOWPortraitShift_BottomHalfOfScreen
	JSR fctCountDownScreenTimer
	BNE -
	LDA POWPortraitTextIndex
	CMP #$04
	BCS +
	LDA #$01
	JMP Label788
+:	LDA #$00
	STA GameControlState
	RTS
	
Label801:	LDA #$00
	JMP subWrite_A_ToGameControlState_SetScreenTimer_ClearTitleScreenState

GameControlState3:
	LDX $19
	BNE + ;Player pushed a button during Title Screen Scroll/POW Portraits.
	LDA #MainWeaponExplosionOnEnemy ;Play explosion sound for title screen start press
	JSR subInitiateSoundClip
	LDA #$00 ;Set Game Play Mode
	STA TitleScreenMode
	LDA #$50 ;time to flash the play selection (Title Screen)
	JMP subIncrementSubGameState_SetScreenTimeLB
+:	DEX
	BNE ++
	DEC ScreenTimerLB
	BNE +
	JMP subIncrementSubGameState
+:	LDA #$01
	CLC
	ADC Player2Active
	STA $00
	LDA #$08 ;this defines how often the play selection flashes (Title Screen)
	AND ScreenTimerLB
	ASL
	ASL
	ASL
	ASL
	ORA $00
	JMP Label152
++:	JSR Label795
	JMP subNextGameControlState

GameControlState4:
	JSR subEraseAllSpriteData
	LDA #$00
	STA GamePlayMode	
	JMP subNextGameControlState

GameControlState6:
	LDA $19
	BNE Label797
	LDA #$07 ;End of Game index
	JSR subLoadNewPatternTable
	JSR Label159
	JSR subEraseAllSpriteData
	JSR subEraseInGameJeepData
	LDA #$06
	JSR Label152
	LDA #GameOver_Continue_SoundClip
	JSR subInitiateSoundClip
	LDA ContinuesUsed
	CMP #NumberOfContinues
	BCS +
	LDA #$08 ;There are no more continues
	STA GameControlState
	LDA #$07
	JSR Label152
	LDA #$09
	JSR Label152
	LDA #$0A
	JMP Label152
+:	LDA #$05
	JSR Label152
	LDA #$02
	STA ScreenTimerUB
	LDA #$C0
	JMP subIncrementSubGameState_SetScreenTimeLB

Label797:	
	JSR fctCountDownScreenTimer
	BNE +
	JMP Label801
-:
+:	RTS

GameControlState7:
	LDA CurrentLevel ;Check for end of game
	CMP #$05
	BNE +
	LDA #$09
	STA GameControlState
	RTS
	
+:	LDA $19
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	dw StageTransitionState0 ;End stage_BlackScreen
	dw StageTransitionState1 ;Show HERE_YEAHHHH!
	dw StageTransitionState2 ;Display Level Segue
	dw StageTransitionState3 ;Move Little Jeep
	dw StageTransitionState4

StageTransitionState0:	
	JSR Label159
	JSR subEraseAllSpriteData
	LDA $50
	BNE +
	JSR Label804
	JMP ++
+:	JSR Label806
	LDA #$80
	STA $05A1
	LDA #$7F
	STA $0561
	LDA #$B3
	STA $0501
	LDA #$C9
	LDY $50
	CPY #$02
	BCC +
	LDA #$CA
+:	STA $0502
	LDA #$88
	STA $05A2
	LDA #$28
	STA $0562
++:	JSR subStopMusic
	LDA #StageComplete_LevelSegue_SoundClip
	JSR subInitiateSoundClip
	LDA #$88
	JMP subIncrementSubGameState_SetScreenTimeLB

StageTransitionState1:
	JSR fctCountDownScreenTimer
	BNE - ;RTS (screen counter not finished)
	JSR Label808
	
	;Load the 2 POW Icons, 1 for each player, during the level segue screen
	LDA #$B8
	STA SpriteTypeIndex
	STA (SpriteTypeIndex + 1)
	
	LDA #$00
	STA SpriteGraphicsAttributes
	STA (SpriteGraphicsAttributes + 1)
	
	LDA #$90
	STA SpriteHorizScreenPosition
	STA (SpriteHorizScreenPosition + 1)
	
	LDA #$58
	STA SpriteVertScreenPosition
	
	LDA #$A0
	STA (SpriteVertScreenPosition + 1)
	
	;Load the Little Jeep in the level segue screen
	LDA #$B2
	STA (SpriteTypeIndex + 2)
	LDA #$49
	STA (SpriteHorizScreenPosition + 2)
	LDA #$D8
	STA (SpriteVertScreenPosition + 2)
	
	;Load the sprite data for the Level Layout in the segue screen
	LDA #$30
	STA (SpriteHorizScreenPosition + 3)
	LDA #$77
	STA (SpriteVertScreenPosition + 3)
	LDA #$B0
	STA (SpriteTypeIndex + 3)
	LDA #$48
	
	JMP subIncrementSubGameState_SetScreenTimeLB

StageTransitionState2:
	JSR subDisplayPlayersScore_LevelSegue
	JSR subDisplayPlayersPOWSavedCount_LevelSegue
	JSR fctCountDownScreenTimer
	BNE +
	LDA #$D0
	JMP subIncrementSubGameState_SetScreenTimeLB
+:	RTS

tblLittleJeepStopPoints: ;How far up the screen the little jeep travels - Level Segue
	db $C0,$A0,$80,$60,$40,$20

StageTransitionState3:
	LDY CurrentLevel
	LDA $0562 ;Little jeep is in sprite slot 2
	CMP tblLittleJeepStopPoints,Y ;Check if the little jeep is at the desired location
	BCC +
	DEC $0562 ;move the little jeep up one pixel per frame
+:	JSR subDisplayPlayersScore_LevelSegue
	JSR subDisplayPlayersPOWSavedCount_LevelSegue
	LDA $60
	ORA $61
	BEQ Label813
	JSR fctCountDownScreenTimer
	LDA RNG_INCEveryFrame
	AND #$07
	BNE +++
	LDX #$01
-:	LDA JeepPOWHeliDropOffCount,X
	BEQ ++
	SEC
	SBC #$01
	STA JeepPOWHeliDropOffCount,X
	AND #$0F
	CMP #$0A
	BCC +
	LDA JeepPOWHeliDropOffCount,X
	SEC
	SBC #$06
	STA JeepPOWHeliDropOffCount,X
+:	LDA #$20
	STA $02
	LDA #$00
	STA $01
	TXA
	TAY
	STX $10
	JSR subAddToPlayerScore
	LDX $10
++:	DEX
	BPL -
	LDA $60
	ORA $61
	BNE +++
	LDA ScreenTimerLB
	BNE +++
	LDA #$60
	STA ScreenTimerLB
+++:	RTS

Label813:	
	JSR fctCountDownScreenTimer
	BNE ++ ; RTS (screen counter is not finished)
	LDA #$94
	JMP subIncrementSubGameState_SetScreenTimeLB

StageTransitionState4:
	JSR fctCountDownScreenTimer
	BNE ++ ; RTS (screen counter is not finished)

	;$C82f
;Screen Timer is complete.  Time to move on to the next stage
subTransitionFromEndOfGameToLevel1:
	INC CurrentLevel
	LDA CurrentLevel
	CMP #$06
	BCC +
	LDA #$00 ;Reset to Level 1 on game completion
	STA CurrentLevel
--:
+:	LDA #$05
	STA GameControlState
	LDA #$01
	STA GamePlayMode
++:	RTS

GameControlState8:
	LDA $19
	BNE Label821
	LDA #$08
	STA Jeep1TypeIndex
	LDA #$68
	STA JeepHorizScreenPosition
	LDA Jeep1ControlsInput1Frame
	AND #StartButton ;Accept selection during continue screen
	BEQ ++
	;$50 is used here (usually the Jeep 1 main weapon) to indicate YES/NO for continuing
	;1 means DONT continue
	LDA $50 
	BEQ +
	JMP Label801
+:	INC ContinuesUsed
	JSR Label824
	LDA #$01
	STA $19
	JSR subStopMusic
	LDA #MainWeaponExplosionOnEnemy ;Play explosion sound for Continue Selection
	JSR subInitiateSoundClip
	JSR +
	JMP +++
++:	LDA Jeep1ControlsInput1Frame
	AND #SelectButton ;Continue screen - toggle between YES and NO
	BEQ +
	LDA $50 ;reused RAM
	EOR #$01 ;Toggle the YES/NO selection on the continue screen
	STA $50
+:	LDY $50
	LDA tblContinueScreenGrenadeVerticalPosition,Y
	STA JeepVertScreenPosition
-:	RTS
Label821:	
	JSR fctCountDownScreenTimer
	BNE -
	BEQ --
	
tblContinueScreenGrenadeVerticalPosition:
	db $84 ;YES selection
	db $94 ;NO selection
	
GameControlState9:
	LDY #$00
	JSR subChangeBank_YhasBank
	JMP subProcessEndOfGameLogic

+++:	LDA #$80
subIncrementSubGameState_SetScreenTimeLB:
	STA ScreenTimerLB
subIncrementSubGameState:
	INC ControlSubState
	RTS
	
subSetScreeTimeLBTo80_NextGameControlState:
	LDA #$80
subSetScreeTimeLB_NextGameControlState:
	STA ScreenTimerLB
subNextGameControlState:
	INC GameControlState
-:	LDA #$00
	STA $1F ;$1F is written to but not used anywhere?
Label788:
	STA ControlSubState
	RTS
	
subWrite_A_ToGameControlState_SetScreenTimer_ClearTitleScreenState:
	STA GameControlState
	LDA #$50 ;time for the play selection to flash (Title Screen), seems to be overwritten at 1C680
	STA ScreenTimerLB
	BNE -
	
fctCountDownScreenTimer:	
	LDA ScreenTimerLB
	ORA ScreenTimerUB
	BEQ ++ ;If there is NO time left, exit (A will have $00)
	DEC ScreenTimerLB ;Count a tick of the timer
	BNE ++
	LDA ScreenTimerUB
	BEQ +
	DEC ScreenTimerUB
+:	LDA #$01 ;indicate there's still time left
++:	RTS

subCheckForPOWPortraitShift_BottomHalfOfScreen:
	LDA $50 ;reused RAM location for POW screen.  Scroll position
	CMP #$F8 ;POW scroll end
	BCS + ;Test for scrolling complete
	LDA $50
	CLC
	ADC #$0C
	STA $50
+:	STA ScreenHorizontalScrollPosition_PPU
	;Very large delay here decrements from #$0834 down to #$00.
	;;This is to arrive at the middle of the screen rendering to scroll
	;;the second portrait in reverse
	LDX #$34
	LDY #$08
-:	INX
	BNE -
	DEY
	BNE -


	LDA PPUSTATUS ;Clear PPU state
	LDA $50 ;Reused RAM location for POW screen.  Calculate the reverse scroll position
	EOR #$FF
	CLC
	ADC #$01 ;Set the new scroll position for the bottom POW portrait
	STA PPUSCROLL
	LDA #$00
	STA PPUSCROLL
	LDA NormalPPUCTRL
	ORA #$01 ;Switches to nametable 1 (PPU VRAM $2400)
	STA PPUCTRL
	RTS

	;$C8FE
tblPOWPortraitPPUUpdateAddresses:
	dw tblPOW1NameText
	dw tblPOW2NameText
	dw tblPOW3NameText
	dw tblPOW4NameText
	
	;*****************
	;POW Portrait Text
	;*****************
	
	;NOTE: The text has been updated, but is labelled with the Vanilla names

tblPOW1NameText:	
	;Colonel Decker
	db $24,$90 ;PPU Address
	;  C   O   L   O   N   E   L
	db $13,$1F,$1C,$1F,$1E,$15,$1C ;Colonel
	db $FE  ;End of line marker
	db $24,$D3 ;PPU Address
	;  D   E   C   K   E   R
	db $14,$15,$13,$1B,$15,$22 ;Decker
	db $FF ;End of name marker

tblPOW2NameText:	
	;Lieut. Bob
	db $26,$88 ;PPU Address
	;  L   I   E   U   T   .
	db $1C,$19,$15,$25,$24,$0E ;Lieut.
	db $FE ;End of line marker
	db $26,$EA ;PPU Address
	;  B   O   B
	db $12,$1F,$12 ;Bob
	db $FF ;End of name marker

tblPOW3NameText:	
	;Sgt. Quint
	db $24,$90 ;PPU Address
	;  P   V   T   .
	db $23,$17,$24,$0E ;Sgt.
	db $FE ;End of line marker
	db $24,$D3 ;PPU Address
	;  Q   U   I   N   T
	db $21,$25,$19,$1E,$24 ;Quint
	db $FF ;End of name marker

tblPOW4NameText:	
	;Corporal Grey
	db $26,$88 ;PPU Address
	;  C   O   R   P   O   R   A   L
	db #$13,$1F,$22,$20,$1F,$22,$11,$1C ;Corporal
	db $FE ;End of line marker
	db $26,$EA ;PPU Address
	;  G   R   E   Y
	db $17,$22,$15,$29 ;Grey
	db $FF ;End of name marker
	
subProcessControllerInputs:
	LDX #$00
	JSR subReadPlayersControllerInputs ;reads players' controller inputs
	LDA $04 ;Save player 1 inputs to 0008
	STA $08
	LDA $05 ;Save player 2 inputs to 0009
	STA $09
	JSR subReadPlayersControllerInputs ;reads players' controller inputs AGAIN
	LDA $08 ;load first read of player 1's inputs
	CMP $04 ;compare with new read
	BNE + ;branch on NG read values
	LDA $09 ;load first read of player 2's inputs
	CMP $05 ;compare with new read
	BEQ ControllerReadOK ;branch on OK read values
+:	LDA #$00 ;, If we are here, then one or both players' controller inputs was bad
	STA JeepControlsInput1Frame,X ;store no button press (last controller input)
	RTS
	
subReadPlayersControllerInputs:
	LDX #$01	;Used to set the controller reset high
	STX JOYPAD1INPUT ;X=1, Bringing 4016 high then low forces the controller to capture the current button states
	DEX ;just to get a #$00 in X
	STX JOYPAD1INPUT ;X=0
	LDY #$08 ;Y=8 for 8 buttons
-:	LDA JOYPAD1INPUT ;Read the input from controller 1
	STA $07 ;Expansion controller support
	LSR
	ORA $07
	LSR ;Shifts bit 0 (the 0 or 1 from the controller) in the carry bit
	ROL $04 ;rotates the carry into bit 0 (next button input) for player 1
	LDA JOYPAD2INPUT ;Read the input from controller 2
	STA $07 ;Expansion controller support
	LSR
	ORA $07
	LSR ;Shifts bit 0 (the 0 or 1 from the controller) in the carry bit
	ROL $05 ;rotates the carry into bit 0 of $05 (PLAYER 2)
	DEY ;decrement Y to count the number of inputs received
	BNE - ;read again if there are more buttons left to read
	RTS

ControllerReadOK:	
	LDA PlayerMode_1or2 ;read 1 or 2 player mode, OK contrller input read jumps to here
	AND #$04
	BEQ ++ ;branches if 1 player
	LDA $04
	JSR + ;JSR on $04 - player 1
	INX ;Contains the Player index (0 = Player1, 1 = Player2)
	LDA $04,X
	;Run the code again on $05 - player 2
+:
-:	TAY
	EOR $F1,X ;XOR with existing jeep control.  XOR only operates the controller input for 1 frame
	AND $04,X ;AND's with the original inputs again.  This will not cause a previously existing jeep control to be fired again.  Only the new inputs
	STA JeepControlsInput1Frame,X ;store the 1-frame inSput (used to fire actual commands)
	STY $F1,X ;Store last valid input received from the controller
	RTS
++:	LDA #$FF
	BNE +
	LDA #$30
+:	AND $04 ;This is for 1 player mode only.  Allows either controller to operate Jeep 1
	ORA $05
	STA $04 ;Combine both inputs into player 1's input location
	JMP -

Label774:	LDA JeepControlsInput1Frame
	AND #(StartButton + SelectButton)
	BEQ ++++ ;RTS - no button pressed
	JSR subSetScreenTimerTo100
	LDX GameControlState
	CPX #$01
	BNE ++
	AND #$20
	BNE +
	LDA #$03
	JMP subWrite_A_ToGameControlState_SetScreenTimer_ClearTitleScreenState
+:	INC Player2Active
	LDA #$02
	SEC
	SBC Player2Active
	BNE ++++
	STA Player2Active
++++	RTS
++:	JSR subTitleScreenInitialization
	JSR subSetScreenTimerTo100
	LDX #$01
	STX GameControlState
	RTS
	
subSetScreenTimerTo100:
	LDX #$00
	STX ScreenTimerLB
	INX
	STX ScreenTimerUB
	RTS

;unused code
	LDA PlayerMode_1or2
	PHA
	JSR Label844
	PLA
	STA PlayerMode_1or2
	INC Jeep1LifeCount
	RTS
	
Label795:	
	JSR Label844
	;Clear both Players' scores (clears 7EF down through 7E4)
Label824:
	LDX #$0B
	LDA #$00
-:	STA JeepScore,X
	DEX
	BPL -
STA TitleScreenMode
	LDY Player2Active
	LDA tblPlayerMode,Y ;gets player mode
	STA PlayerMode_1or2 ;Stores player mode (1 or 2 players)
	
	;Initialize 1UP score level
	LDA #Initial1UPScore ;Initial score for getting a 1Up
	STA Jeep1Next1Up ;Player 1
	STA Jeep2Next1Up ;Player 2
	
	;Initialize Player Life Count
	LDA #$00 ;1 player mode.  00 lives for jeep 2
	STA Jeep2LifeCount
	LDA #InitialLifeCount ;5 lives for jeep 1
	STA Jeep1LifeCount
	;If player 2 is playing, give them lives too
	LDY Player2Active
	BEQ +
	STA Jeep2LifeCount ;If player two is active, give them the same number of starting lives
+:	RTS

	;$CA24
tblPlayerMode:
	db $01 ;1 player mode
	db $07 ;2 player mode

Label844:
	LDX #$23
	JSR subSetPPUToBlackScreen
	;Zeroes out RAM $23 to $DF
-:	STA $00,X ;A is $00 coming from the above sub
	INX
	CPX #$E0
	BNE -
	
	LDX #$07 ;stop at $0700
	LDY #$03
	STY $01 ;= #$03
	STA $00 ;= #$00
	LDY #$00
	;Zeroes out RAM $0300 to $06FF
-:	STA ($00),Y
	INY
	BNE -
	INC $01 ;Get the next UB of the RAM location to zero
	CPX $01
	BNE -
	
	JMP InitPPU
	STX $00
	STY $01
	LDA #$00
	STA $02
	LDA $03
	BPL +
	LSR $00
	ROR $01
	ROR $02
	LSR $03
+:	LDA #$00
	LDX #$11
	CLC
-:	ROL $02
	ROL $01
	ROL $00
	DEX
	BEQ +
	ROL
	CMP $03
	BCC -
	SBC $03
	BCS -
+:	RTS
	STX $05
	STY $06
	LDA #$00
	STA $00
	STA $01
	LDX #$10
-:	ROR $05
	ROR $06
	BCC +
	CLC
	ADC $03
+:	ROR
	ROR $01
	ROR $02
	DEX
	BNE -
	STA $00
	RTS
	
;A has the index for the below table
;;routine pulls the stack into $00 and $01 for a JMP ($00)
;;which resumes code execution at one of the below addresses:
;;ASL - Multiply by 2 because we are dealing with 16 bit values (incement by 2 bytes at a time)
subExecuteCodeViaIndirectJump: 		
	ASL ;Multiply by 2 because we are dealing with 16bit values (increment by 2 bytes at a time)
	STX $03 ;Preserve X
	STY $02 ;Preserve Y
	TAY
	INY ;Add 1 to Y because of how the JSR pushes the PC to the stack : it is always the next position - 1.
	;Pull the address of the table from the stack
	PLA
	STA $00
	PLA
	STA $01
	;Get the address from the table
	LDA ($00),Y
	TAX
	INY
	LDA ($00),Y
	STA $01
	STX $00
	LDY $02 ;Restore Y
	LDX $03 ;Restore X
	JMP ($00)	
	
fctAdd_A_To16BitValueIn_00_01_OffsetX_RAM:	
	;Add A to $00,X
	CLC
	ADC $00,X
	STA $00,X
	BCC +
	INC $01,X
+:	RTS

;unused code
	EOR #$FF
	SEC
	ADC $00,X
	STA $00,X
	BCS +
	DEC $01,X
+:	RTS

subEraseAllSpriteData:
	LDA #$00
	LDX #$1F
-:	STA SpriteAttributes,X
	DEX
	BPL -
	LDX #$05
	LDY #$FF 	;Erase RAM 500-5FF
	JSR ++
	INX 		;Erase RAM 600-6FF
	JSR ++
	LDY #$6B 	;Erase RAM 700-76B
	INX
	JMP ++

subEraseInGameJeepData:
	LDA #$50 ;Erase RAM 50-C1
	LDY #$71 ;Length-1
	BNE +

subEraseGameControlData:
	LDA #$35 ;Erase RAM 35-4F
	LDY #$1A ;Length
+:	LDX #$00
++:	STA $00
	STX $01
	LDA #$00
-:	STA ($00),Y
	DEY
	CPY #$FF
	BNE -
	RTS
	
subEraseLevel6BossFlags:
	LDY #$07
	LDA #$00
-:	STA $0112,Y  ;Erase RAM 113-119
	DEY
	BNE -
	RTS
	RTS ;unused RTS
	
subAddToPlayerScore:
	STY $08
	LDA #$00
	STA $03
	LDA TitleScreenMode
	BEQ +
	RTS
+:	LDA #$E4 ;Player 1 XP address ($0734)
	CPY #$00
	BEQ +
	LDA #$E8 ;Player 2 XP address ($07E8)
+:	STA $04
	LDY #$07
	STY $05
	LDX #$01 ;1,2,3 are the byte locations, not 0-based
	LDY #$00
	LDA #$03
	STA $00
	CLC
-:	LDA ($04),Y	
	JSR subAddToPlayerScore_1Byte
	STA ($04),Y
	INY
	INX ;go to next score byte location
	DEC $00
	BNE -
	BCC Label865 ;check score gain for 1UP
	LDX #$02
	LDA #$99
-:	STA HighScore,X
	DEX
	BPL -
	RTS

Label871:
	STX $00
	LDX #$00
subAddToPlayerScore_1Byte:	
	STA $07	;Put the current score value in a temp location
	AND #$F0
	STA $06
	EOR $07	;This is the same as LDA $07, AND #$0F, STA $07, it just saves 2 bytes
	STA $07
	LDA $00,X	;$01 has Low byte addition.  $02 as the middle byte addition,  $03 has the Upper byte addition
	AND #$0F
	ADC $07
	
	;Track points in decimal, not hex
	CMP #$0A
	BCC +
	ADC #$05
	
+:	ADC $06
	STA $06
	LDA $00,X	;$01 has Low byte addition.  $02 as the middle byte addition,  $03 has the Upper byte addition
	AND #$F0
	ADC $06
	BCS ++
	
	;Track points in decimal, not hex
	CMP #$A0
	BCC +
++:	SBC #$A0
	SEC
+:	RTS

Label865:	LDY #$02
	LDA ($04),Y
	LDX $08
	CMP JeepNext1Up,X
	BCC ++
	LDX #$05 ;get a 1Up after this many ( times 10000) points more are scored, 02
	LDY $08
	LDA JeepNext1Up,Y ;Y here contains the player that scored points (0=player 1,1=player 2)
	CLC
	JSR Label871
	BCC +
	LDA #$FF
+:	LDX $08
	STA JeepNext1Up,X
	LDA JeepLifeCount,X
	CMP #$09 ;Max live count for score 1Up
	BCS ++
	INC JeepLifeCount,X ;add 1 life
	LDA #ExtraLifeSoundClip
	JSR subInitiateSoundClip
++:	LDY #$02
--:	LDA HighScore,Y ;high score is unused in jackal
	CMP ($04),Y
	BCC +
	BNE ++
	DEY
	BPL --
+:	LDY #$02
-:	LDA ($04),Y
	STA HighScore,Y
	DEY
	BPL -
++:	RTS

subUpdateSpritePositionForScrolling:
	LDA #$01
	STA $00
	LDA ScreenTransitionTimer
	BEQ +
	LDA #$08
	STA $00
+:	LDA CurrentLevelScreenSubPosition
	SEC
	SBC PreviousLevelScreenSubposition
	BEQ + ;Screen didn't scroll
	LDA ScreenScrolledUp_Down
	BNE ++
	LDA SpriteVertScreenPosition,X
	CLC
	ADC $00
	STA SpriteVertScreenPosition,X
	LDA SpriteAbsoluteVertPositionUB,X
	ADC #$00
	STA SpriteAbsoluteVertPositionUB,X
	JMP +
++:	LDA SpriteVertScreenPosition,X
	SEC
	SBC #$01
	STA SpriteVertScreenPosition,X
	LDA SpriteAbsoluteVertPositionUB,X
	SBC #$00
	STA SpriteAbsoluteVertPositionUB,X
+:	LDA SpriteAbsoluteVertPositionUB,X
	BNE ++
	LDA SpriteAbsoluteHorizPositionUB,X
	CMP #$02
	BCS ++
	LDA SpriteAbsoluteHorizPositionLB,X
	SEC
	SBC ScreenLeftScrollPosition
	STA $00
	LDA SpriteAbsoluteHorizPositionUB,X
	SBC #$00
	BNE ++
	LDA $00
	STA SpriteHorizScreenPosition,X
	LDA SpriteState,X
	AND #$7F
	JMP +
++:	LDA SpriteState,X
	ORA #$80
+:	STA SpriteState,X
	RTS
	
subUpdateGrenade_Bazooka_BulletPositionForScroll:
	STX $00 ;Preserve X
	LDX $39
	LDA ScreenHorizontalScrollPosition_PPU
	SEC
	SBC ScreenLeftScrollPosition
	CLC
	ADC SpriteHorizScreenPosition,X
	STA SpriteHorizScreenPosition,X
	LDA CurrentLevelScreenSubPosition
	SEC
	SBC PreviousLevelScreenSubposition
	CMP #$10
	BCC +
	CMP #$F0
	BCS +
	EOR #$10
+:	CLC
	ADC SpriteVertScreenPosition,X
	STA SpriteVertScreenPosition,X
	LDX $00 ;Restore X
	RTS
	
subUpdateGrenade_Bazooka_BulletPositionForSpeed:	
	STX $00 ;Preserve X
	LDX $39 ;Load the enemy sprite index
	
	LDA SpriteHorizSpeedLB,X
	CLC
	ADC SpriteHorizScreenPositionSubPixel,X
	STA SpriteHorizScreenPositionSubPixel,X
	
	LDA SpriteHorizSpeedUB,X
	;Important not to clear carry here, so the LB can roll over to the UB
	ADC SpriteHorizScreenPosition,X
	STA SpriteHorizScreenPosition,X
	
	LDA SpriteVertSpeedLB,X
	CLC
	ADC SpriteVertScreenPositionSubPixel,X
	STA SpriteVertScreenPositionSubPixel,X
	
	LDA SpriteVertSpeedUB,X
	;Important not to clear carry here, so the LB can roll over to the UB
	ADC SpriteVertScreenPosition,X
	STA SpriteVertScreenPosition,X
	LDX $00 ;Restore X
	RTS

;Resets all 4 bytes of vertical and horizontal speed (upper and lower bytes of each)
subZeroOutSpriteSpeed:	 
	STX $00  ;Preserve X
	LDX $39 ;Load the Enemy Sprite Index
	LDA #$00
	STA SpriteHorizSpeedUB,X
	STA SpriteHorizSpeedLB,X
	STA SpriteVertSpeedUB,X
	STA SpriteVertSpeedLB,X
	LDX $00 ;Restore X
	RTS
	
Label1055:
	STX $00 ;Preserve X
	LDX $39
	LDA #$00
	STA SpriteState,X
	STA SpriteTypeIndex,X
	LDX $00 ;Restore X
	RTS
	
Label886:
	AND #$07
	BEQ ++
-:	RTS

Label975:
	LDA ScreenLeftScrollPosition
	STA ScreenHorizontalScrollPosition_PPU
	LDA CurrentLevelScreenSubPosition
	CMP PreviousLevelScreenSubposition ;compare to the current screen position
	BEQ - ;RTS - if the screens are the same (no jeep movement/scrolling), then branch to RTS
	LDA CurrentLevelScreenSubPosition ;Check to see if this is a brand new screen
	BEQ +
	;CurrentLevelScreenSubPosition  counts up from 00, but the screen Y value is
	;;inverted.  The below code calculates
	;;(100-CurrentLevelScreenSubPosition) - #$0F to get the actual screen scroll
	;;value from the current level screen position
	EOR #$FF ;If we are here, screen needs updated, but isn't a brand new screen
	SEC
	SBC #$0F
+:	STA ScreenVerticalScrollPosition_PPU
	LDA CurrentLevelScreenSubPosition ;Update the current screen with the next screen
	STA PreviousLevelScreenSubposition
	LDX ScreenScrolledUp_Down
	BEQ Label886 ;Scrolled Up
	AND #$07 ;For scrolling down, check BG load at top of pixel count (7 not 0)
	CMP #$07
	BNE - ;RTS
++:	LDA #$00
	STA $10
	LDA #$03
	STA $11
	LDA ScreenScrolledUp_Down
	BEQ ++
	LDA $4F
	CLC
	ADC #$08
	STA $4F
	CLC
	ADC #$E8
	STA $05
	DEC $4B
	JSR Label888
	LDA CurrentLevelScreenSubPosition
	AND #$1F
	CMP #$0F
	BNE +
	LDA $4A
	CLC
	ADC #$08
	STA $4A
	BNE +
	LDA #$C0
	STA $4A
+:	INC $4B
	LDA $48
	CLC
	ADC #$20
	STA $48
	BCC +++
	INC $47
	JMP +
+++:	CMP #$C0
	BNE +
	LDA $47
	CMP #$23
	BNE +
	LDA #$00
	STA $48
	LDA #$20
	STA $47
+:	LDA $4D
	CMP #$02
	BNE +
	LDA $4C
	BNE +
	LDA #$03
	STA $4D
	LDA #$07
	STA $4C
	DEC $4B
	JMP Label893
+:	DEC $4D
	BPL +
	LDA #$03
	STA $4D
	DEC $4C
+:	JMP Label893
++:	LDA $4F
	SEC
	SBC #$08
	STA $4F
	STA $05
	LDA CurrentLevelScreenSubPosition
	BEQ ++
	SEC
	SBC #$10
	AND #$1F
	BNE +
++:	LDA $4A
	SEC
	SBC #$08
	STA $4A
	CMP #$C0
	BCS +
	LDA #$F8
	STA $4A
+:	LDA $48
	SEC
	SBC #$20
	STA $48
	BCS +
	DEC $47
	LDA $47
	CMP #$1F
	BNE +
	LDA #$23 ;Iniitalize
	STA $47
	LDA #$A0
	STA $48
+:	INC $4D
	LDA $4D
	CMP #$04
	BNE ++
	LDA $4C
	CMP #$07
	BNE +
	INC $4B
	LDA #$02
	STA $4D
	LDA #$00
	STA $4C
-:
++:	JSR Label888
	JMP Label893
+:	INC $4C
	LDA #$00
	STA $4D
	BEQ -
	
Label888:	LDA $47
	STA $08
	LDA $48
	STA $09
	LDA $4B
	STA $0A
	STA $DA
	LDA $4C
	ASL
	ASL
	ASL
	ASL
	STA $0B
	STA $DB
	LDA $4D
	STA $0C
	STA $DC
	LDA $49
	STA $0D
	LDA $4A
	STA $0E
	RTS
	
Label893:
	LDA CurrentLevel
	ASL
	TAY
	LDA tblLevelLayoutScreenLoadIndex,Y
	STA $C8
	LDA (tblLevelLayoutScreenLoadIndex + 1),Y
	STA $C9
	LDA tblLevelLayoutData,Y
	STA $CA
	LDA (tblLevelLayoutData + 1),Y
	STA $CB
	LDA tblLevelLayoutLargeTilePaletteData,Y
	STA $CE
	LDA (tblLevelLayoutLargeTilePaletteData + 1),Y
	STA $CF
	LDA #$10
	STA $0F
	LDX PPUGraphicsUpdateByteLength
	LDA #$01
	STA $0770,X
	INX
	LDA $08 ;get the VRAM address for the next tile data to write
	STA $0770,X
	INX
	LDA $09
	STA $0770,X
	INX
	STX PPUGraphicsUpdateByteLength
	LDY $0A
	LDA ($C8),Y
	LDY #$00
	STY $02
	LDY #$07
	CLC
-:	ASL
	ROL $02
	DEY
	BNE -
	CLC
	ADC $CA
	STA $00
	LDA $02
	ADC $CB
	STA $01
Label913:	LDA #$00 ;Erase the previous sprite address info
	STA $02
	STA $03
	LDY $0B
	LDA ($00),Y ;Load the next 32x32 Tile definition, NOTE: 32x32 tiles are defined, yet the data must be loaded in to the PPU row by row.
	PHA ;, all the way to the edge of the screen.  The it starts over with the first 32x32 tile and sends
	LDY #$00 ;, the next row.  Once all for rows of each tile have been sent, the code goes to the next
	
	LDX CurrentLevel ;Load the current level
	CMP tblLevelBGTileOffset,X
	BCC +
	PLA
	SEC
	SBC tblLevelBGTileOffset,X
	PHA
	LDA CurrentLevel
	ASL ;Multiply by 2 (for 2 bytes)
	TAY ;Y is used to select the level's table.  If this code is skipped, Y is 0, which uses the common tiles in level 1s data)
	
+:	LDA tblLevelLayout32x32Definition,Y ;store the header address for the 8x8 tile definitions in 00CC-CD
	STA $CC
	LDA (tblLevelLayout32x32Definition + 1),Y
	STA $CD
	PLA
	LDX #$04
	CLC
-:	ROL ;Rotates bits in A into the carry position
	ROL $03 ;which are then rotated into 0003
	DEX
	BNE -
	STA $02 ;In the end here, A's lower byte has shifted into the upper byte (LB = 0) 
	LDA $CC
	CLC
	ADC $02
	STA $02
	LDA $CD
	ADC $03
	STA $03
	LDA $0C
	ASL
	ASL
	TAY
	LDA #$04
	STA $04
	LDX PPUGraphicsUpdateByteLength
Label910:	LDA ($02),Y ;Load the next 8x8 Tile definition
	STA $0770,X
	INX
	STX PPUGraphicsUpdateByteLength
	STA $06
	STY $07
	LDA CurrentLevel
	ASL
	ASL
	ASL
	TAY
	LDA $06
	
	CMP LevelCollision_CommonTiles_None,Y ;NO COLLISION
	BCC +++
	CMP LevelCollision_CommonTiles_All_ButGrenade,Y ;ALL COLLISION EXCEPT GRENADE
	BCC ++
	CMP LevelCollision_CommonTiles_JeepOnly,Y ;JEEP COLLISION
	BCC ++++
	CMP LevelCollision_LevelSpecificTiles_None,Y ;NO COLLISION
	BCC +++
	CMP LevelCollision_LevelSpecificTiles_All_ButGrenade,Y ;ALL COLLISION EXCEPT GRENADE
	BCC ++
	CMP LevelCollision_LevelSpecificTiles_JeepOnly,Y ;JEEP COLLISION
	BCC ++++
	
	LDA #$03 ;Load ALL Collision (ENEMY BULLETS GO THROUGH), This id the default value.  This loads if all other values fail to match
	BNE +
++++:
	LDA #$02 ;Load JEEP collision (can shoot through this tile)
	BNE +
++:
	LDA #$01 ;Load ALL collision (BLOCKS ENEMY BULLETS)
	BNE +
+++:
	LDA #$00 ;Load NO collision
	
+:	LDY $05 ;0005 here contains the offset for the collision data location (e.g. FF for 03FF, 50 for 0350, etc)
	CLC
	LDX $04 ;X (and 0004) here contains the count for the collision/sprite byte being read.  4 are read in total.
	DEX ;Pushing the 2 collision bits up to the upper half of the upper nibble.
	BEQ +++ ;as x is decremented through the loops, the code branches sooner and sooner, executing fewer ASLs.
	DEX
	BEQ ++
	DEX
	BEQ +
	PHA ;if no branches occur, then this is the first execution
	LDA #$00 ;if so, we need to clear the collision data initially since the process continually builds on the existing data with ORA commands
	STA ($10),Y
	PLA
	ASL ;Shift the collision bits to the appropriate position
	ASL
+:	ASL
	ASL
++:	ASL
	ASL
+++:	ORA ($10),Y ;Add the new collision bits to the existing data (build the 4 half nibbles)
	STA ($10),Y ;write the data back to the collision location
	LDY $07
	LDX PPUGraphicsUpdateByteLength
	INY
	DEC $04
	BNE Label910
	INC $05
	DEC $0F
	BEQ Label911
	LDA $0F
	CMP #$08
	BNE +
	LDA $05
	SEC
	SBC #$08
	STA $05
	LDA #$04
	STA $11
	LDA #$FF
	STA $0770,X
	INX
	LDA #$01
	STA $0770,X
	INX
	LDA $08
	CLC
	ADC #$04
	STA $0770,X
	INX
	LDA $09
	STA $0770,X
	INX
+:	STX PPUGraphicsUpdateByteLength
	INC $0B
	JMP Label913
Label911:	LDA $DC
	AND #$01
	BNE +
	JMP ++++
	LDA $DC
	AND #$01
	BNE +
	JMP ++++
+:	LDA #$10
	STA $11
--:	LDA #$FF
	STA $0770,X
	INX
	LDA #$03
	STA $0770,X
	INX
	LDA $0D
	STA $0770,X
	INX
	LDA $0E
	STA $0770,X
	INX
	LDA #$08 ;Store an #08 in a temp (0770+) location to control writing data to the PPU.  In this instance, the 8 means 8 bytes total to write
	STA $0770,X
	INX
	STX PPUGraphicsUpdateByteLength
-:	LDY $DB
	LDA ($00),Y
	TAY
	LDA ($CE),Y
	LDX $DC
	AND tblLoadLevelBGRow1_2,X
	STA $10
	LDA ScreenScrolledUp_Down
	BNE +++
	LDA $00
	CPX #$02
	BCC ++
	CLC
	BCC +
++:	ADC #$80
+:	STA $12
	LDA $01
	ADC #$00
	STA $13
---:	LDY $DB
	LDA ($12),Y
	TAY
	LDA ($CE),Y
	AND tblLoadLevelBGRow3_4,X
	ORA $10
	LDX PPUGraphicsUpdateByteLength
	STA $0770,X
	INX
	STX PPUGraphicsUpdateByteLength
	INC $DB
	DEC $11
	BEQ +
	LDA $11
	CMP #$08
	BNE -
	LDA $0D
	CLC
	ADC #$04
	STA $0D
	JMP --
+++:	LDA $00
	CPX #$02
	BCS ++
	SEC
	BCS +++
++:	SBC #$80
+++:	STA $12
	LDA $01
	SBC #$00
	STA $13
	JMP ---
+:	LDX PPUGraphicsUpdateByteLength
++++	LDA #$FF ;Load the end maker
	STA $0770,X
	INX
	LDA #$00
	STA $0770,X
	STX PPUGraphicsUpdateByteLength
	RTS
	
	;has to do with loading the level as the screen scrolls up
	;$CFB6
tblLoadLevelBGRow1_2:
	db $F0,$F0,$0F,$0F
tblLoadLevelBGRow3_4:
	db $0F,$0F,$F0,$F0
	
	;**************************************************
	;**************************************************
	;The Collision data is editable in the Level Editor
	;**************************************************
	;**************************************************
	
	;All of these addresses must remain static - they are read by the level editor
	.PAD $CFBE
LevelCollision_CommonTiles_None:
	
	.PAD $CFBF
LevelCollision_CommonTiles_All_ButGrenade:	
	
	.PAD $CFC0
LevelCollision_CommonTiles_JeepOnly:
	
	.PAD $CFC1
LevelCollision_LevelSpecificTiles_None:
	
	.PAD $CFC2
LevelCollision_LevelSpecificTiles_All_ButGrenade:
	
	.PAD $CFC3
LevelCollision_LevelSpecificTiles_JeepOnly:


;Editable in Level Editor
; db $00 ;Unused placeholders (need 8 bytes for 3-ASLs
; db $00 ;Unused placeholders (need 8 bytes for 3-ASLs

;The level collision is broken up into 6 sections
;;the first 3 values are relevant to the common BG tiles.
;;tiles with indices less than the first value have collision type 0
;;tiles with indices less than the second value have collision type 1
;;tiles with indices less than the third value have collision type 2
;The next 3 values are relevant to the level-specific BG tiles
;;tiles with indices less than the fourth value have collision type 0
;;tiles with indices less than the fifth value have collision type 1
;;tiles with indices less than the sixth value have collision type 2
;;tiles with indices greater than the sixth value have collision type 3 (water splash, barricades)
;Level 1 Collision: 1CFBE - 1CFC5
;Level 2 Collision: 1CFC6 - 1CFCD
;Level 3 Collision: 1CFCE - 1CFD5
;Level 4 Collision: 1CFD6 - 1CFDD
;Level 5 Collision: 1CFDE - 1CFE5
;Level 6 Collision: 1CFE6 - 1CFED

	
	.PAD $CFEE
tblLevelBGTileOffset:
	db $00
	db $11 ;First 17 tiles are common
	db $00 ;Level 3 has it's own BG tile set
	db $11 ;First 17 tiles are common
	db $11 ;First 17 tiles are common
	db $00 ;Level 6 has it's own BG tile set
	
tblLevelLayoutScreenLoadIndex:
	dw tblLevel1LayoutScreenLoadIndex
	dw tblLevel2LayoutScreenLoadIndex
	dw tblLevel3LayoutScreenLoadIndex
	dw tblLevel4LayoutScreenLoadIndex
	dw tblLevel5LayoutScreenLoadIndex
	dw tblLevel6LayoutScreenLoadIndex
	
tblLevelLayoutData:	
	dw tblLevel1ScreenLayout
	dw tblLevel2ScreenLayout
	dw tblLevel3ScreenLayout
	dw tblLevel4ScreenLayout
	dw tblLevel5ScreenLayout
	dw tblLevel6ScreenLayout
	
	.PAD $D00C
;This table defines the locations for the tiles that make up the 32x32 large tiles
;;Jackal uses blocks of 4x4 (of 8x8 pixel) tiles from the pattern table to define 'large tiles
;;that make storage easier.  These large 32x32 pixel tiles are used to define the level layout
;;They are editable in the Level Editor
tblLevelLayout32x32Definition:
	dw tblLevel1Layout32x32Definition
	dw tblLevel2Layout32x32Definition
	dw tblLevel3Layout32x32Definition
	dw tblLevel4Layout32x32Definition
	dw tblLevel5Layout32x32Definition
	dw tblLevel6Layout32x32Definition
	
tblLevelLayoutLargeTilePaletteData:
	dw tblLevel1Layout32x32DefinitionPalette
	dw tblLevel2Layout32x32DefinitionPalette
	dw tblLevel3Layout32x32DefinitionPalette
	dw tblLevel4Layout32x32DefinitionPalette
	dw tblLevel5Layout32x32DefinitionPalette
	dw tblLevel6Layout32x32DefinitionPalette

subTitleScreenInitialization:
	JSR subStopMusic
	JSR Label159
	JSR subEraseAllSpriteData
	LDA #$06 ;Title screen index
	JSR subLoadNewPatternTable
	LDA #NormalPPUMaskValue
	STA NormalPPUMASK
	LDY #$04 ;bank for title name tables
	JSR subChangeBank_YhasBank
	LDX #$02
	JSR Label925
	LDX #$04
	JSR Label925
	LDA #$06
	JMP Label152
	
Label780:
	LDY #$04
	JSR subChangeBank_YhasBank
	LDX #$06
	JSR Label925
	LDA #$3C
	JMP Label152
	
Label781:
	LDY #$04
	JSR subChangeBank_YhasBank
	LDX #$08
	JSR Label925
	LDA #$3C
	JMP Label152
	
Label971:
	LDY #$05
	JSR subChangeBank_YhasBank
	LDX #$0A
	JSR Label925
	LDA #$3A
	JSR Label152
	LDA #$E8
	STA ScreenVerticalScrollPosition_PPU
	RTS
	
Label806:
	LDA #$08 ;YEAHHHH!/We Made It! index
	JSR subLoadNewPatternTable
	LDY #$04
	JSR subChangeBank_YhasBank
	LDX #$0E
	JSR Label925
	LDA #$39
	JMP Label152
	
Label804:
	LDA #$0A ;Segue screen index
	JSR subLoadNewPatternTable
	LDY #$05
	JSR subChangeBank_YhasBank
	LDX #$12
	JSR Label925
	LDA #$65
	JMP Label152
	
Label808:
	LDY #$05
	JSR subChangeBank_YhasBank
	LDX #$0C
	JSR Label925
	LDA #$3A
	JSR Label152
	LDA #$E8 ;edge of screen
	STA ScreenVerticalScrollPosition_PPU
	RTS
	
Label161:
	LDA CurrentBank
	PHA
	LDA #$09 ;End of game index
	JSR subLoadNewPatternTable
	LDY #$04 ;bank for end of game nametable data
	JSR subChangeBank_YhasBank
	LDX #$10
	JSR Label925
	PLA
	TAY
	JSR subChangeBank_YhasBank
	LDA #$3B
	JMP Label152
	
Label159:
	LDX #$00
Label925:	
	LDA tblSceneNametableData,X
	STA $00
	LDA (tblSceneNametableData + 1),X
	STA $01
	
-:	;Loops here until PPU is ready
	LDA PPUSTATUS 
	BPL -
	
	JSR subSetPPUToBlackScreen
	;A is $00 after the above JSR
	STA PPUGraphicsUpdateByteLength
	STA ScreenVerticalScrollPosition_PPU
	STA ScreenHorizontalScrollPosition_PPU
	STA Level6BossTankScroll_Next
	STA Level6BossTankScroll_Current
Label935:	
	LDA PPUSTATUS ;Reset the PPUADDR lines
	LDY #$01
	LDA ($00),Y ;Get PPU Address upper byte
	STA PPUADDR ;write to PPU
	DEY
	LDA ($00),Y ;Get PPU Address lower byte
	STA PPUADDR ;write to PPU
	LDX #$00
	LDA #$02
	JSR fctAdd_A_To16BitValueIn_00_01_OffsetX_RAM ;this routine increments the pointer passed the PPU address in the table
---:	LDY #$00 ;The only indirect opcode uses + Y.  Here, we don't need Y, but we want to use the indirect function  so set Y=0
	LDA ($00),Y
	
	;RLE decompression routine
	CMP #$FF ;End of section marker value
	BEQ ++++
	CMP #$7F ;End of subsection marker value
	BEQ +++
	TAY
	BPL ++
	AND #$7F
	STA $02
	LDY #$01
-:	LDA ($00),Y
	STA PPUDATA
	CPY $02
	BEQ +
	INY
	BNE -
+:	LDA #$01
	CLC
	ADC $02
--:	JSR fctAdd_A_To16BitValueIn_00_01_OffsetX_RAM
	JMP ---
++:	LDY #$01
	STA $02
	LDA ($00),Y
	LDY $02
-:	STA PPUDATA
	DEY
	BNE -
	LDA #$02
	BNE --
+++:	STX $10 ;Preserve X
	STY $11 ;Preserve Y
	JSR subProcessSound_Music
	LDX $10 ;Restore X
	LDY $11 ;Restore Y
	LDA #$01
	JSR fctAdd_A_To16BitValueIn_00_01_OffsetX_RAM
	JMP Label935
++++:	JMP InitPPU

tblSceneNametableData:
	dw tblBlackScreenNametable
	dw tblMainTitleScreenNametable
	dw tblMainTitleScreenStoryTextNametable
	dw tblPOWPortraitScreen1Nametable
	dw tblPOWPortraitScreen2Nametable
	dw tblGameStarted_BloodBoilScreen
	dw tblLevelComplete_SegueScreen
	dw tblLevelComplete_YEAHScreenNametable
	dw tblEndOfGameScreen_SunsetNametable
	dw tblLevelComplete_HEREScreenNametable
	
	;These nametable blanking routines use Konami's RLE compression
	;;because the table is nothing but ZEROES, which saves quite a lot of space
tblBlackScreenNametable:
	dw $2000 ;Nametable 0
	db $78,$00 ;$78 total zeroes
	db $78,$00 ;$F0 total zeroes
	db $78,$00 ;$168 total zeroes
	db $78,$00 ;$1E0 total zeroes
	db $78,$00 ;$258 total zeroes
	db $78,$00 ;$2D0 total zeroes
	db $78,$00 ;$348 total zeroes
	db $78,$00 ;$3C0 total zeroes
	db $40,$00 ;$400 total zeroes
	db $7F ;End of nametable data marker
	
	dw $2400	;Nametable 1
	db $78,$00 ;$78 total zeroes
	db $78,$00 ;$F0 total zeroes
	db $78,$00 ;$168 total zeroes
	db $78,$00 ;$1E0 total zeroes
	db $78,$00 ;$258 total zeroes
	db $78,$00 ;$2D0 total zeroes
	db $78,$00 ;$348 total zeroes
	db $78,$00 ;$3C0 total zeroes
	db $40,$00 ;$400 total zeroes
	db $FF ;End of section marker
	
subInsertPPUUpdateTerminator:
	LDA #$FF
	STA $0770,X
	INX
	LDA #$00
	STA $0770,X
	STX PPUGraphicsUpdateByteLength
	RTS
	
subAdd2DigitTextToPPUUpdate:
	STA $00
	LSR
	LSR
	LSR
	LSR
	CLC
	ADC #$01
	STA $0770,X
	INX
	LDA $00
	AND #$0F
	CLC
	ADC #$01
	STA $0770,X
	INX
	RTS
	
subDisplayPlayersPOWSavedCount_LevelSegue:
	LDA RNG_INCEveryFrame
	AND #$01
	CLC
	ADC #$37
	JSR Label152
	LDA RNG_INCEveryFrame
	LSR
	BCC + ;Alternates updating player 1/2 POW count during level segue on alternate frames
	LDA Jeep2POWHeliDropOffCount
	JMP ++
+:	LDA Jeep1POWHeliDropOffCount
++:	JSR subAdd2DigitTextToPPUUpdate ;Display the POW offloaded count total
	JMP subInsertPPUUpdateTerminator
	
subDisplayPlayersScore_LevelSegue:
	LDA RNG_INCEveryFrame
	AND #$01
	CLC
	ADC #$0B
	JSR Label152
	LDY #$02
-:	LDA RNG_INCEveryFrame
	LSR
	BCC + ;Alternates updating player 1/2 Score during level segue on alternate frames
	LDA Jeep2Score,Y
	JMP ++
+:	LDA Jeep1Score,Y
++:	JSR subAdd2DigitTextToPPUUpdate
	DEY
	BPL - ;Loop through all 3 sets (6 total digits) of the players' score
	BMI subInsertPPUUpdateTerminator
	STX $04
	JSR Label152
	LDA $04
	BNE +
Label152:	PHA ;PPUGraphics Update Init?
	LDA #$02
	STA $03
	LDA #$01
	JSR +++++
	PLA
+:	STA $02
	ASL
	TAX
	LDA tblPPUGraphics_PalleteUpdateAddress,X ;Reads the address for the begin of PPU update data
	STA $00
	LDA (tblPPUGraphics_PalleteUpdateAddress + 1),X
	STA $01
	LDX PPUGraphicsUpdateByteLength
	LDY #$00
-:	LDA ($00),Y
	INY
	CMP #$FF
	BEQ ++++
	CMP #$FE
	BEQ +++
	STA $0770,X
	LDA $02 ;check if the Player 1 (Solo) text is to be shown or hidden
	BPL ++
	LDA $03
	BNE +
	STA $0770,X
	BEQ ++
+:	DEC $03
++:	INX
	BNE -
+++:	LDA #$FF
	BNE +
	LDA #$FF
	BNE +++++
Label757:	
	LDA #$00
	BEQ +++++ ;unnecessary branch
+++++:	LDX PPUGraphicsUpdateByteLength
+:	STA $0770,X
	INX
++++:	STX PPUGraphicsUpdateByteLength
	RTS
	
tblPPUGraphics_PalleteUpdateAddress:	
	dw tblTitleScreenFlash1PlayerTextGraphicsUpdate	;00
	dw tblTitleScreenFlash1PlayerTextGraphicsUpdate	;01
	dw tblTitleScreenFlash2PlayerTextGraphicsUpdate	;02
	dw tblTitleScreenFlash1PlayerTextGraphicsUpdate	;03
	dw tblTitleScreenFlash1PlayerTextGraphicsUpdate	;04
	dw tblGameOverTextGraphicsUpdate				;05
	dw tblTitleScreenPalette						;06
	dw tblContinueTextGraphicsUpdate				;07
	dw tblContinueTextGraphicsUpdate				;08
	dw tblContinueYesTextGraphicsUpdate			;09
	dw tblContinueNoTextGraphicsUpdate				;0A
	dw tblSegueScreen1P_ScoreText					;0B
	dw tblSegueScreen2P_ScoreText					;0C
	
	dw Level1DefaultPalette						;0D
	dw Level2DefaultPalette						;0E
	dw Level3DefaultPalette						;0F
	dw Level4DefaultPalette						;10
	dw Level5DefaultPalette						;11
	dw Level6DefaultPalette						;12
	
	;Helipid flashing light addresses
	dw tblLevel1HelipadLightFlashPaletteUpdate		;13
	dw (tblLevel1HelipadLightFlashPaletteUpdate + 19)	;14
	dw (tblLevel1HelipadLightFlashPaletteUpdate + 38)	;15
	dw (tblLevel1HelipadLightFlashPaletteUpdate + 19)	;16
	dw tblLevel2HelipadLightFlashPaletteUpdate		;17
	dw (tblLevel2HelipadLightFlashPaletteUpdate + 19)	;18
	dw (tblLevel2HelipadLightFlashPaletteUpdate + 38)	;19
	dw (tblLevel2HelipadLightFlashPaletteUpdate + 19)	;1A
	dw tblLevel3HelipadLightFlashPaletteUpdate		;1B
	dw (tblLevel3HelipadLightFlashPaletteUpdate + 19)	;1C
	dw (tblLevel3HelipadLightFlashPaletteUpdate + 38)	;1D
	dw (tblLevel3HelipadLightFlashPaletteUpdate + 19)	;1E
	dw tblLevel4HelipadLightFlashPaletteUpdate 		;1F
	dw (tblLevel4HelipadLightFlashPaletteUpdate + 19)	;20
	dw (tblLevel4HelipadLightFlashPaletteUpdate + 38)	;21
	dw (tblLevel4HelipadLightFlashPaletteUpdate + 19)	;22
	dw tblLevel5HelipadLightFlashPaletteUpdate		;23
	dw (tblLevel5HelipadLightFlashPaletteUpdate + 19)	;24
	dw (tblLevel5HelipadLightFlashPaletteUpdate + 38)	;25
	dw (tblLevel5HelipadLightFlashPaletteUpdate + 19)	;26
	dw tblLevel6HelipadLightFlashPaletteUpdate		;27
	dw (tblLevel6HelipadLightFlashPaletteUpdate + 19)	;28
	dw (tblLevel6HelipadLightFlashPaletteUpdate + 38)	;29
	dw (tblLevel6HelipadLightFlashPaletteUpdate + 19)	;2A
	
	dw tblLevel3BossBGPaletteUpdate				;2B
	dw tblLevel5BossPaletteUpdate					;2C
	dw tblLevel1BossSpritePaletteUpdate			;2D
	dw tblLevel6BuildingBossBGPaletteUpdate			;2E
	dw tblLevel6FinalBossTankDefaultPalette			;2F
	dw tblLevel6FinalBossTankInjuredColorPalette		;30
	dw tblLevel6FinalBossTankNearDeathColorPalette	;31
	dw tblLevel6FinalBossSkull_StripesOrangeBGPalette	;32
	dw tblLevel6FinalBossSkull_StripesGreenBGPalette	;33
	dw tblLevel6FinalBossSkull_StripesGrayBGPalette	;34
	dw tblEndOfGame_EraseCreditsLineOfText1			;35
	dw tblEndOfGame_EraseCreditsLineOfText2			;36
	dw tblLevelSeguePOWCountPosition_Player1 ;Blank - only has a PPU address; no data
	dw tblLevelSeguePOWCountPosition_Player2 ;Blank - only has a PPU address; no data
	dw tblLevelSegue_YEAH_Palette
	dw tblLevelSeguePalette
	dw tblEndOfGamePalette
	dw tblPOWPortraitBGPalette
	dw tblLevel6FinalBossTankRow1LeftGraphics
	dw tblLevel6FinalBossTankRow1RightGraphics 
	dw tblLevel6FinalBossTankRow2LeftGraphics
	dw tblLevel6FinalBossTankRow2RightGraphics
	dw tblLevel6FinalBossTankRow3LeftGraphics
	dw tblLevel6FinalBossTankRow3RightGraphics
	dw tblLevel6FinalBossTankRow4LeftGraphics
	dw tblLevel6FinalBossTankRow4RightGraphics
	dw tblLevel6FinalBossTankRow5LeftGraphics
	dw tblLevel6FinalBossTankRow5RightGraphics
	dw tblLevel6FinalBossTankRow6LeftGraphics
	dw tblLevel6FinalBossTankRow6RightGraphics
	dw tblLevel6FinalBossTankRow7LeftGraphics
	dw tblLevel6FinalBossTankRow7RightGraphics
	dw tblLevel6FinalBossTankRow8LeftGraphics
	dw tblLevel6FinalBossTankRow8RightGraphics
	dw tblLevel6FinalBossTankRow9LeftGraphics
	dw tblLevel6FinalBossTankRow9RightGraphics
	dw tblLevel6FinalBossTankRow10LeftGraphics
	dw tblLevel6FinalBossTankRow10RightGraphics
	dw tblLevel6FinalBossTankRow11LeftGraphics
	dw tblLevel6FinalBossTankRow11RightGraphics
	dw tblLevel6FinalBossTankRow12LeftGraphics
	dw tblLevel6FinalBossTankRow12RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow1LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow1RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow2LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow2RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow3LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow3RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow4LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow4RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow5LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow5RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow6LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow6RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow7LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow7RightGraphics
	dw tblLevel6FinalBossTankDefeatedRow8LeftGraphics
	dw tblLevel6FinalBossTankDefeatedRow8RightGraphics
	dw tblLevelSegue_HERE_BGPalette
	
	
	.PAD $D329	

tblSegueScreen1P_ScoreText:	
	;***Level Segue Screen - '1P SCORE' text
	db $20,$ED ;PPU Address
	;  1   P   ''  S   C   O   R   E   ''
	db $02,$20,$00,$23,$13,$1F,$22,$15,$00
	db $FF ;End of subsection marker

tblLevelSeguePOWCountPosition_Player1:
	db $21,$53 ;PPU Address
	db $FF ;End of subsection marker
	
tblSegueScreen2P_ScoreText:
	;***Level Segue Screen - '2P SCORE' text
	db $22,$0D ;PPU Address
	;  2   P   ''  S   C   O   R   E   ''
	db $03,$20,$00,$23,$13,$1F,$22,$15,$00
	db $FF ;End of subsection marker
	
tblLevelSeguePOWCountPosition_Player2:
	db $22,$73 ;PPU Address
	db $FF ;End of subsection marker
	
tblGameOverTextGraphicsUpdate:	
	;***GAME OVER screen text
	db $21,$EB ;PPU Address
	;  G   A   M   E   ''  O   V   E   R
	db $17,$11,$1D,$15,$00,$1F,$26,$15,$22
	db $FE ;End of section marker
	
tblEndOfGame_EraseCreditsLineOfText1:	
	;***End of Game screen - used to erase Credits : 1st line of text
	db $20,$A0 ;PPU Address
	db $2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C
	db $2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C
	db $FE ;End of section marker
	
tblEndOfGame_EraseCreditsLineOfText2:	
	;***End of Game screen - used to erase Credits : 2nd line of text
	db $20,$E0 ;PPU Address
	db $2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C
	db $2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C,$2C
	db $FE ;End of section marker

tblTitleScreenFlash1PlayerTextGraphicsUpdate:
	;***Start Menu - Text that flashes when 1Player is select
	db $22,$6D ;PPU Address
	;  1   ''  P   L   A   Y   E   R
	db $02,$00,$20,$1C,$11,$29,$15,$22
	db $FE ;End of section marker
	
tblTitleScreenFlash2PlayerTextGraphicsUpdate:
	;***Start Menu - Text that flashes when 1Player is select
	db $22,$AD ;PPU Address
	;  2   ''  P   L   A   Y   E   R   S
	db $03,$00,$20,$1C,$11,$29,$15,$22,$23
	db $FE ;End of section marker

tblContinueTextGraphicsUpdate:	
	;***Continue Screen - CONTINUE text
	db $21,$8C ;PPU Address
	;  C   O   N   T   I   N   U   E
	db $13,$1F,$1E,$24,$19,$1E,$25,$15
	db $FE ;End of section marker
	
tblContinueYesTextGraphicsUpdate:
	;***Continue Screen - YES text
	db $22,$0F ;PPU Address
	;  Y   E   S
	db $29,$15,$23
	db $FE ;End of section marker
	
tblContinueNoTextGraphicsUpdate:	
	;***Continue Screen - NO text
	db $22,$4F ;PPU Address
	;  N   O
	db $1E,$1F
	db $FE ;End of section marker

	
	;************************
	;FINAL BOSS TANK GRAPHICS
	;************************
tblLevel6FinalBossTankRow1LeftGraphics:	
	;***Row 1 (Left Side)
	db $23,$BE ;PPU Address (bottom right of top left screen)
	db $51,$54
	db $FE ;End of section marker

tblLevel6FinalBossTankRow1RightGraphics:	
	;***Row 1 (Right Side)
	db $27,$A0 ;PPU Address (bottom left of top right screen)
	db $55
	db $FE ;End of section marker

tblLevel6FinalBossTankRow2LeftGraphics:	
	;***Row 2 (Left side)
	db $20,$19 ;PPU Address
	db $56,$57,$58,$59,$5A,$5B,$5C
	db $FE ;End of section marker 
	
tblLevel6FinalBossTankRow2RightGraphics:
	;***Row 2 (Right side)
	db $24,$00 ;PPU Address
	db $5D,$5E,$5F,$60,$60,$61,$62
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow3LeftGraphics:
	;***Row 3 (Left side)
	db $20,$39 ;PPU Address
	db $63,$64,$65,$66,$67,$68,$69
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow3RightGraphics:
	;***Row 3 (Right side)
	db $24,$20 ;PPU Address
	db $6A,$6B,$6C,$6D,$6E,$6E,$6F
	db $FE ;End of section marker

tblLevel6FinalBossTankRow4LeftGraphics:
	;***Row 4 (Left side)
	db $20,$57 ;PPU Address
	db $A0,$A0,$70,$71,$72,$73,$74,$44,$45
	db $FE ;End of section marker

tblLevel6FinalBossTankRow4RightGraphics:
	;***Row 4 (Right side)
	db $24,$40 ;PPU Address
	db $75,$76,$77,$78,$79,$79,$7A,$A0
	db $A0,$FE ;End of section marker
	
tblLevel6FinalBossTankRow5LeftGraphics:
	;***Row 5 (Left side)
	db $20,$76 ;PPU Address
	db $A0,$A0,$A0,$70,$46,$47,$48,$49,$4A,$4B
	db $FE ;End of section marker

tblLevel6FinalBossTankRow5RightGraphics:
	;***Row 5 (Right side)
	db $24,$60 ;PPU Address
	db $4C,$4D,$4E,$4F,$50,$50,$7B,$A0,$A0,$A0
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow6LeftGraphics:
	;***Row 6 (Left side)
	db $20,$94 ;PPU Address
	db $A0,$A0,$A0,$A0,$A0,$7E,$7F,$80,$81,$82,$83,$84
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow6RightGraphics:
	;***Row 6 (Right side)
	db $24,$80 ;PPU Address
	db $85,$86,$87,$82,$82,$88,$89,$A0,$A0,$A0,$A0
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow7LeftGraphics:
	;***Row 7 (Left side)
	db $20,$A0 ;PPU Address
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$8A,$8B,$8C,$8D,$8E,$8D,$7C
	db $FE ;End of section marker	
	
tblLevel6FinalBossTankRow7RightGraphics:
	;***Row 7 (Right side)
	db $24,$A0 ;PPU Address
	db $8D,$8E,$8D,$8E,$8D,$8C,$8F,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow8LeftGraphics:
	;***Row 8 (Left side)
	db $20,$C0 ;PPU Address
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$90,$91,$92,$93,$92,$93,$7D
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow8RightGraphics:
	;***Row 8 (Right side)
	db $24,$C0 ;PPU Address
	db $93,$92,$93,$92,$93,$94,$95,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $FE ;End of section marker

tblLevel6FinalBossTankRow9LeftGraphics:
	;***Row 9 (Left side)
	db $20,$E0 ;PPU Address
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $FE ;End of section marker

tblLevel6FinalBossTankRow9RightGraphics:
	;***Row 9 (Right side)
	db $24,$E0 ;PPU Address
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow10LeftGraphics:
	;***Row 10 (Left side)
	db $21,$00 ;PPU Address
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$96,$A0,$96,$A0 ;$96 is the top of the broken pillars
	db $A0,$A0,$A0,$A0
	db $FE ;End of section marker
	
tblLevel6FinalBossTankRow10RightGraphics:
	;***Row 10 (Right side)
	db $25,$00 ;PPU Address
	db $A0,$A0,$A0,$A0,$A0,$96,$A0,$96,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0 ;$96 is the top of the broken pillars, $A0 is black
	db $A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
	db $FE ;End of section marker

tblLevel6FinalBossTankRow11LeftGraphics:
	;***Row 11 (Left side)
	db $21,$20 ;PPU Address
	db $A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96
	db $A0,$96,$A0,$96,$A0,$96,$B5,$BA,$B8,$BA,$B8,$B4,$A0,$A0,$A0,$A0
	db $FE ;End of section marker

tblLevel6FinalBossTankRow11RightGraphics:
	;***Row 11 (Right side)
	db $25,$20 ;PPU Address
	db $A0,$A0,$A0,$A0,$B5,$B8,$BA,$B8,$BA,$B4,$A0,$96,$A0,$96,$A0,$96
	db $A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96,$A0,$96
	db $FE ;End of section marker

tblLevel6FinalBossTankRow12LeftGraphics:
	;***Row 12 (Left side)
	db $21,$5C ;PPU Address
	db $B4,$96,$96,$A0
	db $FE ;End of section marker

tblLevel6FinalBossTankRow12RightGraphics:
	;***Row 12 (Right side)
	db $25,$40 ;PPU Address
	db $A0,$96,$96,$B5
	db $FE ;End of section marker
	
	
	;*********************************
	;FINAL BOSS TANK DEFEATED GRAPHICS
	;*********************************
	
	;$D5B2

tblLevel6FinalBossTankDefeatedRow1LeftGraphics:		
	;***Row 1 (Left side)
	db $23,$BE ;PPU Address
	db $E0,$E1
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow1RightGraphics:
	;***Row 1 (Right side)
	db $27,$A0 ;PPU Address
	db $D7
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow2LeftGraphics:
	;***Row 2 (Left side)
	db $20,$1D ;PPU Address
	db $D9,$DA,$DB
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow2RightGraphics:
	;***Row 2 (Right side)
	db $24,$00 ;PPU Address
	db $DC,$DD,$5F,$EC,$60,$E8
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow3LeftGraphics:
	;***Row 3 (Left side)
	db $20,$3B ;PPU Address
	db $EA,$E9,$E9,$EA,$EB
	db $FE ;End of section marker
	
tblLevel6FinalBossTankDefeatedRow3RightGraphics:
	;***Row 3 (Right side)
	db $24,$20 ;PPU Address
	db $EC,$DB,$6C,$D8,$DB
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow4LeftGraphics:
	;***Row 4 (Left side)
	db $20,$59 ;PPU Address
	db $E8,$EA,$73,$E2,$E3,$E4
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow4RightGraphics:
	;***Row 4 (Right side)
	db $24,$40 ;PPU Address
	db $DB,$EC,$77,$E8,$E8,$EC
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow5LeftGraphics:
	;***Row 5 (Left side)
	db $20,$7E ;PPU Address
	db $E5,$E6
	db $FE ;End of section marker
	
tblLevel6FinalBossTankDefeatedRow5RightGraphics:
	;***Row 5 (Right side)
	db $24,$60 ;PPU Address
	db $E7,$4D,$4E,$4F,$DB
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow6LeftGraphics:
	;***Row 6 (Left side)
	db $20,$9A ;PPU Address
	db $E3,$DB,$81,$EC,$DB,$DE
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow6RightGraphics:
	;***Row 6 (Right side)
	db $24,$81 ;PPU Address
	db $E3,$87,$DB,$EC,$DB
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow7LeftGraphics:
	;***Row 7 (Left side)
	db $20,$B9 ;PPU Address
	db $8A,$8B,$8C,$8D,$8E,$8D,$7C
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow7RightGraphics:
	;***Row 7 (Right side)
	db $24,$A0 ;PPU Address
	db $8D,$8E,$8D,$8E,$8D,$8C,$8F
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow8LeftGraphics:
	;***Row 8 (Left side)
	db $20,$DF ;PPU Address
	db $DF
	db $FE ;End of section marker

tblLevel6FinalBossTankDefeatedRow8RightGraphics:
	;***Row 8 (Right side)
	db $24,$C0 ;PPU Address
	db $93,$92,$93,$92,$93,$94,$95
	db $FE ;End of section marker
	
	
	;This address must remain static - It is read by the level editor
	.PAD $D62C
Level1DefaultPalette:
	;********************
	;Level 1 Palette Data
	;********************

	
	
	;This address must remain static - It is read by the level editor
	.PAD $D64F
Level2DefaultPalette:
	;********************
	;Level 2 Palette Data
	;********************

	
	;This address must remain static - It is read by the level editor
	.PAD $D672
Level3DefaultPalette:
	;********************
	;Level 3 Palette Data
	;********************

	
	;This address must remain static - It is read by the level editor
	.PAD $D695
Level4DefaultPalette:
	;********************
	;Level 4 Palette Data
	;********************

	;This address must remain static - It is read by the level editor
	.PAD $D6B8
Level5DefaultPalette:
	;********************
	;Level 5 Palette Data
	;********************

	
	;This address must remain static - It is read by the level editor
	.PAD $D6DB
Level6DefaultPalette:
	;********************
	;Level 6 Palette Data
	;********************


;***************************
;Helipad Light Flashing Data
;***************************
	.PAD $D6FE
tblLevel1HelipadLightFlashPaletteUpdate:

	
	.PAD $D737
tblLevel2HelipadLightFlashPaletteUpdate:	

	
	.PAD $D770
tblLevel3HelipadLightFlashPaletteUpdate:

	
	.PAD $D7A9
tblLevel4HelipadLightFlashPaletteUpdate:	

	
	.PAD $D7E2
tblLevel5HelipadLightFlashPaletteUpdate:	
	;Level 5 uses palette index 1 instead of index 0 for some reason

	
	.PAD $D81B
tblLevel6HelipadLightFlashPaletteUpdate:	
	
	
	;*************************************
	;F2 Object In-Game Update Palette Data
	;The commented-out palette entries are editable in the Level Editor EX
	;*********************************************************************
	
	;This address must remain static - It is read by the level editor
	.PAD $D854
tblLevel1BossSpritePaletteUpdate:

	
	;This address must remain static - It is read by the level editor
	.PAD $D867
tblLevel3BossBGPaletteUpdate:

	
	;This address must remain static - It is read by the level editor
	.PAD $D87A
tblLevel5BossPaletteUpdate:

	
	;This address must remain static - It is read by the level editor
	.PAD $D89D
tblLevel6BuildingBossBGPaletteUpdate:

	
	;****************************************************************************************
	;Other In-Game Palette Updates - Typically enemy AI logic or screen transition controlled
	;****************************************************************************************
	.PAD $D8B0
tblLevel6FinalBossTankDefaultPalette:

	
	.PAD $D8D3
tblLevel6FinalBossTankInjuredColorPalette	

	
	.PAD $D8F6
tblLevel6FinalBossTankNearDeathColorPalette:	

	
	.PAD $D919
tblLevel6FinalBossSkull_StripesOrangeBGPalette:	
	;Level 6 Final Boss Skull/Stripes Flash 
	;db $3F,$00 ;PPU Address
	;db $0F,$06,$16,$26
	;db $0F,$00,$10,$27
	;db $0F,$00,$10,$37
	;db $0F,$0B,$1B,$2B
	;db $FE ;End of section marker
	
	.PAD $D92C
tblLevel6FinalBossSkull_StripesGreenBGPalette:

	
	.PAD $D93F
tblLevel6FinalBossSkull_StripesGrayBGPalette:

	
	.PAD $D952
tblLevelSegue_YEAH_Palette:


	.PAD $D975
tblLevelSeguePalette:

	
	.PAD $D998
tblLevelSegue_HERE_BGPalette:

	
	.PAD $D9AB
tblEndOfGamePalette	

	
	.PAD $D9CE
tblTitleScreenPalette:

	
	.PAD $D9F1
tblPOWPortraitBGPalette:

	
	.PAD $DA04
tblPPUUpdate_VRAMIncrementSetting:
	;horiz vert horiz
	db $00,$04,$00

;Data format:
;$01,(PPU ADDRESS HIGH),(PPU ADDRESS LOW),...(DATA)...,$FF
;OR;
;$03,(PPU ADDRESS HIGH),(PPU ADDRESS LOW),(BYTE COUNT),...(DATA with length = byte count)...
subInGamePPUUpdates:	;write data to the PPU
	LDY #$00 
	STY $08
--:	LDA $08
	CMP #$3F ;$08 is 3F if the palette is being updated.  Should only happen during F2 objects
	BNE +
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	STA PPUADDR
	STA PPUADDR
+:	LDX $0770,Y
	BEQ ++
	LDA NormalPPUCTRL
	AND #$18
	ORA (tblPPUUpdate_VRAMIncrementSetting - 1),X ;minus 1 because X is 1-based
	STA PPUCTRL
	INY
	LDA PPUSTATUS
	LDA $0770,Y
	STA $08 ;write address to write to PPU
	STA PPUADDR
	INY
	LDA $0770,Y
	STA PPUADDR
	INY
	CPX #$03 ;X contains the PPU update type.  Mode 3 uses byte count
	BNE +
	LDX $0770,Y ;now X counts the byte count
	INY
-:	LDA $0770,Y
	STA PPUDATA
	INY
	DEX ;If X counts the byte count, it will remain here and load the data
	BNE - ;If X contained a 1 (mode 1), it will jump out immediately
	BEQ +
++:	LDA #$00
	STA $0770 ;clear the PPU update type, so it wont be processed again
	STA PPUGraphicsUpdateByteLength
	LDA NormalPPUCTRL
	STA PPUCTRL
	RTS
-:	STA PPUDATA
+:	LDA $0770,Y
	INY
	CMP #$FF
	BNE -
	BEQ --
NA:	JSR NA ;Weird infinite loop.  never reached...

GameControlState5:
	LDA GamePlayMode
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	dw GamePlayModeState0 ;Title Screen
	dw GamePlayModeState1 ;Loading Black Screen before level loads
	dw GamePlayModeState2 ;Loading Level data
	dw GamePlayModeState3 ;Normal Level Game Play
	dw GamePlayModeState4 ;Load Chinook
	dw GamePlayModeState5 ;Move Chinook to top of screen
	dw GamePlayModeState6 ;Move Chinook Down-Right (landing)
	dw GamePlayModeState7 ;Stop Chinook
	dw GamePlayModeState8 ;Spawn Player Jeeps
	dw GamePlayModeState9 ;Move Chinook Up-Left (taking off)
	dw GamePlayModeState10 ;Move Chinook Up, of screen (leaving)
	
GamePlayModeState4:
	;Chinook Spawn Data
	LDA #$7A
	STA SpriteTypeIndex
	LDA #$78
	STA SpriteHorizScreenPosition
	LDA #$F8
	STA SpriteVertScreenPosition
--:	INC GamePlayMode
-:	RTS

GamePlayModeState5:
	JSR lblUpdateChinookPropellerPosition
	DEC SpriteVertScreenPosition ;Move Chinook to top of screen 1 pixel per frame
	LDA SpriteVertScreenPosition
	CMP #$30
	BCC --
	RTS

GamePlayModeState6:
	JSR lblUpdateChinookPropellerPosition
	LDA RNG_INCEveryFrame
	AND #$04
	BNE - ;RTS
	INC SpriteVertScreenPosition
	LDA RNG_INCEveryFrame
	LSR
	BCC - ;RTS
	INC SpriteHorizScreenPosition
	LDA SpriteVertScreenPosition
	CMP #$40
	BCS --
	RTS

GamePlayModeState7:	
	;Initialize jeep position
	LDA #$80
	STA JeepHorizScreenPosition
	STA Jeep2HorizScreenPosition
	LDA #$50
	STA JeepVertScreenPosition
	STA Jeep2VertScreenPosition
	
	LDY #$00
	STY Jeep1GraphicsAttributes ;Jeep 1 green palette
	INY
	STY Jeep2GraphicsAttributes ;Jeep 2 brown palette
	LDA #$03 ;Set jeep 1 direction
	STA JeepTypeIndex
	LDA #$C0
	STA JeepAttributes
-:	INC GamePlayMode
--:	RTS

GamePlayModeState8: ;Deploy jeep(s)
	JSR lblUpdateChinookPropellerPosition
	LDA JeepVertScreenPosition
	CMP #$80 ;Vertical position to stop jeep movement
	BEQ +
	INC JeepVertScreenPosition ;deployment motion for jeep 1
	DEC JeepHorizScreenPosition
	JMP ++
+:	LDA #$00 ;Set the mirroring, and green palette for jeep 1
	STA Jeep1Attributes
	LDA #$01 ;Jeep facing up
	STA JeepTypeIndex
	LDA Player2Active
	BEQ -
++:	LDA Player2Active
	BEQ -- ;RTS
	LDA JeepHorizScreenPosition
	CMP #$70 ;Spawn Jeep 2 a little later than jeep 1
	BCS -- ;RTS
	LDA #$03 ;Jeep faces down-right, getting out of chinook
	STA Jeep2TypeIndex
	LDA #$80 ;set the mirroring and palette
	STA Jeep2Attributes
	LDA Jeep2VertScreenPosition
	CMP #$80
	BEQ +
	INC Jeep2VertScreenPosition ;deployment motion for jeep 2
	INC Jeep2HorizScreenPosition
	RTS
+:	LDA #$00 ;Jeep facing up
	STA Jeep2Attributes
	LDA #$01
	STA Jeep2TypeIndex
	BNE -

GamePlayModeState9: ;Chinook lift off
	JSR lblUpdateChinookPropellerPosition
	LDA RNG_INCEveryFrame
	AND #$04
	BNE -- ;RTS
	DEC SpriteVertScreenPosition
	LDA RNG_INCEveryFrame
	LSR
	BCC -- ;RTS
	DEC SpriteHorizScreenPosition
	LDA SpriteVertScreenPosition
	CMP #$30 ;End veritcal position value for end of lift off state
	BCC -
	RTS
	
GamePlayModeState10:
	JSR lblUpdateChinookPropellerPosition
	DEC SpriteVertScreenPosition
	BPL -- ;RTS
	LDA #$00
	STA SpriteTypeIndex
	JMP InitializeLevel
	
;Update Chinook Propeller Position
lblUpdateChinookPropellerPosition:
	LDA RNG_INCEveryFrame
	AND #$03 ;Rotate propellers (update sprite) every 4 frames
	BNE ++ ;RTS
	LDA #$7B
	LDY SpriteTypeIndex
	CPY #$7A
	BEQ +
	LDA #$7A
+:	STA SpriteTypeIndex
++:	RTS

GamePlayModeState0:	
++:	LDA TitleScreenMode
	BNE ++
	LDA CurrentLevel
	BNE ++
	LDA $0660
	BNE +
+++:	JSR Label159
	LDA #$08 ;YEAHHHH!/We Made It! index
	JSR subLoadNewPatternTable
	JSR Label971
	LDA #GameStartedIntroSoundClip ;slow tempo for Level 1 game start intro riff
	JSR subInitiateSoundClip
	LDA #$30 ;30 Segue map/diagram vertical offset
	STA $05A1
	LDA #$77 ;77 Segue map/diagram vertical offset
	STA $0561
	LDA #$B0 ;sprite type index
	STA $0501
	LDA #$90
	STA $0670
	INC $0660
-:	RTS
+:	DEC $0670
	BNE -
++:	INC GamePlayMode
	RTS

GamePlayModeState1:
	JSR Label159
	JSR subEraseAllSpriteData
	JSR subEraseGameControlData
	INC GamePlayMode
	LDA #$23
	STA $47
	STA $49
	LDA #$A0
	STA $48
	LDA #$F8
	STA $4A
	
	LDA #$00
	STA $4B
	STA $4C
	STA PPUGraphicsUpdateTableIndex
	STA PPUGraphicsUpdateComplete
	
	LDA #$02
	STA $4D
	LDA CurrentLevel
	JSR subLoadNewPatternTable
	JSR subLoadLevelDefaultPalette
	LDA #$25
	STA ScreenTransitionTimer
	RTS

;The bank where the level design is located (what tiles go where on the level BG)
tblLevelLayoutBank:
;Level  1   2   3   4   5   6
	db $04,$04,$05,$04,$04,$05
	
GamePlayModeState2:
	LDX CurrentLevel
	LDY tblLevelLayoutBank,X ;The bank where the lavel 32x32 tiles are located
	JSR subChangeBank_YhasBank
	JSR Label975
	LDA CurrentLevelScreen
	BNE ++
	LDA CurrentLevelScreenSubPosition
	CLC
	;Most likely this adds 8 for each tile is 8x8 pixels.  
	;;..loads the next row of BG tiles to the level
	ADC #$08 
	STA CurrentLevelScreenSubPosition
	CMP #$F0
	BNE +
	
	;Initialize to beginning of level (first screen has just been rendered)
	LDA #$01
	STA CurrentLevelScreen
	LDA #$00
	STA CurrentLevelScreenSubPosition
	STA $36
	STA Level6BossTankScroll_Next
	
+:	LDY #$06 ;Load the bank for ALL level event spawns
	JSR subChangeBank_YhasBank
	JSR Label978
	JMP Label979
++:	LDA TitleScreenMode
	BNE InitializeLevel
	LDA CurrentLevel
	BNE InitializeLevel
	LDA ContinuesUsed
	BNE InitializeLevel
	;Go through chinook sequence
	LDA #$04
	STA GamePlayMode
	RTS
	
InitializeLevel:	
	LDX #$01 ;initialize X (index for player 1/2)
-:	LDA #$80 ;initial upper vertical byte value, starts in the center of the screen (chinook unload)
	STA JeepVertScreenPosition,X
	STA JeepVertPosition,X
	LDA tblBeginLevelJeepHorizontalSpawnLocation,X
	STA JeepHorizScreenPosition,X
	STA JeepHorizPosition,X
	DEX
	BPL -
	JSR subEraseLevel6BossFlags
	LDY CurrentLevel
	BNE + ;Only do this for Level 1 (Loads new sprite data after Chinook leaves)
	STY PPUGraphicsUpdateComplete ;Y is 0 here
	LDA #$05 ;New Level 1 sprite data index
	STA PPUGraphicsUpdateTableIndex
+:	LDA tblInitialLevelHorizontalScrollPosition,Y
	STA ScreenLeftScrollPosition
	LDA #$FF ;Default to FF to not end level, but not at boss yet
	STA LevelBossEntitiesRemaining
	LDA #$07 ;Helipad Light Flash Rate
	STA LevelHelipadLightFlashTimer
	LDA #$03
	STA GamePlayMode ;Level has loaded, proceed to normal game play
	LDA CurrentLevel
	BNE +
	LDA ContinuesUsed
	BNE +
	RTS
+:	JSR subStopMusic
	LDY CurrentLevel
	LDA tblLevelBGMusicIndex,Y ;Get the music index to play
	JMP subInitiateSoundClip

subDisablePaletteFlash_LoadDefaultPalette:
	LDA #$FF
	STA LevelHelipadLightFlashTimer
subLoadLevelDefaultPalette:
	STX $0E ;Preserve X
	STY $0F ;Preserve Y
	LDA #$0D
	CLC
	ADC CurrentLevel
	JSR Label152
	LDX $0E ;Restore X
	LDY $0F ;Restore Y
	RTS
	
tblInitialLevelHorizontalScrollPosition: ;How far right do you load into the level
;Level  1   2   3   4   5   6  
	db $00,$80,$44,$00,$90,$CD
	
tblBeginLevelJeepHorizontalSpawnLocation: ;where (on screen) you spawn
	db $50 ;Jeep 1 Horizontal Spawn Position
	db $B0 ;Jeep 2 Horizontal Spawn Position

tblLevelBGMusicIndex: ;Which level music to play
;Level  1   2   3   4   5   6 
	db $38,$3C,$40,$38,$3C,$40
	
GamePlayModeState3: ;Normal Level Game Play
	LDA ContinuesUsed
	BPL +
	LDA #$03
	STA DifficultyBasedOnWeapon ;Force max difficulty on subsequent play throughs
+:	JSR Label984
	LDA GamePaused
	BNE ++ ;RTS - do nothing if paused here
	LDA Jeep1LifeCount
	CLC
	ADC Jeep2LifeCount
	BNE +
	;Both jeeps are dead here..
	LDA #$06
	STA GameControlState
	LDA #$00
	STA ControlSubState
++:	RTS
+:	LDA LevelBossEntitiesRemaining
	BNE ++
	LDA EndofLevelDelayAfterBossDeath
	BNE +
	LDX #$10
-:	DEX
	BMI +
	LDA SpriteHealthHP,X
	BMI -
	LDA SpriteObjectID,X
	AND #$7F ;MSB = air strike/despawn immunity
	BEQ -
	TAY
	LDA tblEnemyPoints_DeathState,Y
	AND #$0F
	STA SpriteState,X
	JMP -
+:	LDA CurrentLevel
	BEQ + ;unnecessary branch
	CMP #$03 ;unnecessary compare
	BEQ + ;unnecessary branch
+:	LDA EndofLevelDelayAfterBossDeath
	CLC
	ADC #$02
	STA EndofLevelDelayAfterBossDeath
	BCC ++
	LDA #$07
	STA GameControlState
	LDA #$00
	STA ControlSubState
	RTS
	
++:	LDX CurrentLevel
	LDY tblLevelLayoutBank,X ;The bank where the level 32x32 tiles are located
	JSR subChangeBank_YhasBank
	JSR Label975
	LDY #$06 ;set bank for enemy spawning information
	JSR subChangeBank_YhasBank
	JSR Label978
	LDA ScreenVerticalScrollLockForBossFight
	BNE + ;is this a necessary check???
	LDA ScreenScrollingForF0ToBoss
	BEQ +
	
	;F0 scrolling.  Increment screen position
	LDA #$01
	CLC
	ADC CurrentLevelScreenSubPosition
	STA CurrentLevelScreenSubPosition
	CMP #$F0
	BCC +
	;If the F0 scrolling crosses a screen boundary, handle it here
	LDA #$00
	STA CurrentLevelScreenSubPosition
	INC CurrentLevelScreen
+:	LDA ScreenScrollingForF0ToBoss
	BEQ ++
	;F0 scrolling.
	;is it easier to use ,X here for each player?
	LDA Jeep1VertScreenPosition
	CMP #$D0 ;Bottom of screen where jeep is pulled forward
	BCS +
	LDA Jeep1LifeCount ;Make sure player 1 is alive
	BEQ +
	;Drag player 1 jeep forward
	INC Jeep1VertScreenPosition
	INC Jeep1VertPosition
+:	LDA Player2Active ;Check for solo mode
	BEQ +
	LDA Jeep2VertScreenPosition
	CMP #$D0 ;Bottom of screen where jeep is pulled forward
	BCS +
	LDA Jeep2LifeCount ;Make sure player 2 is alive
	BEQ +
	;Drag player 2 jeep forward
	INC Jeep2VertScreenPosition
	INC Jeep2VertPosition
	JMP +
	;NO F0 scrolling
++:	LDA Level6FinalBossFreezePlayerJeep_InvulnerableWhileExploding
	BNE +
	LDX #$10
	STX $39
	JSR Label995
	LDA #$00
	STA Jeep1EscalatorEffectActive
	STA Jeep2EscalatorEffectActive
	STA Level6FinalBossFreezePlayerJeep_InvulnerableWhileExploding
+:	LDA #$1F
	STA $39
	LDX #$07
-:	JSR Label996
	JSR subProcessJeepMainWeapon
	DEC $39
	DEX
	BPL -
	LDA #$17
	STA $39
	LDX #$05
-:	JSR subProcessJeepBullet
	LDA RNG_INCEveryFrame
	LSR
	BCS +
	JSR Label1001
+:	DEC $39
	DEX
	BPL -
	LDY #$06
	JSR subChangeBank_YhasBank
	LDA #$00
	STA $5A
	STA $5B
Label979:
	LDX #$0F
-:	STX $35
	STX $39
	JSR subProcessObjectLogic
	LDA RNG_INCEveryFrame
	LSR
	BCC +
	JSR Label1005
+:	DEX
	BPL -
	LDA LevelHelipadLightFlashTimer
	BEQ Label1007
	BMI +
	DEC LevelHelipadLightFlashTimer
	;Process Animated Tile updates for each level
+:
ProcessLevelBGAnimation:
	LDA CurrentLevel
	CMP #$02
	BNE ++
	LDA PPUGraphicsUpdateTableIndex
	BNE ++ ;Avoid overwriting any existing PPU Graphics Update
	DEC LevelBGAnimatedTileUpdateTimer
	BNE ++
	LDA #$10
	STA LevelBGAnimatedTileUpdateTimer
	LDX #$03
	LDA LevelBGAnimatedTileUpdateIndex
	BEQ +
	INX
+:	STX PPUGraphicsUpdateTableIndex
	LDA #$00
	STA PPUGraphicsUpdateComplete
	LDA LevelBGAnimatedTileUpdateIndex
	EOR #$01
	STA LevelBGAnimatedTileUpdateIndex
++:	JSR Label1011 ;process the PPU update
-:	RTS

Label1007:
	LDA PPUGraphicsUpdateByteLength
	CMP #$21 ;See if there's room left in the PPU graphics update for the helipad light flash update
	BCS - ;RTS, no room to update this
	LDA #HelipadLightFlashRate ;time delay between palette updates (for heli lights)
	STA LevelHelipadLightFlashTimer
	LDA CurrentLevel
	ASL
	TAX
	LDA CurrentLevelScreen
	CMP tblScreenToStartHelipadLightFlashing,X
	BCC ProcessLevelBGAnimation
	CMP tblScreenToStopHelipadLightFlashing,X
	BCS ProcessLevelBGAnimation
	LDA CurrentLevel
	ASL
	ASL
	CLC
	ADC HelipadLightFlashPalette
	CLC
	ADC #$13
	JSR Label152
	INC HelipadLightFlashPalette
	LDA HelipadLightFlashPalette
	CMP #$04
	BCC ProcessLevelBGAnimation
	LDA #$00
	STA HelipadLightFlashPalette
	BEQ ProcessLevelBGAnimation ;will always branch
	
	.PAD $DE1B
tblScreenToStartHelipadLightFlashing:

	;This address must remain static - It is read by the level editor
	.PAD $DE1C
tblScreenToStopHelipadLightFlashing:
	;Helipad light flashing Start (first number) and Stop (second number) screen numbers
	;When the screen scrolls upward into the screen identified by the first value, the helipad palette values start cycling
	;When the screen scrolls upward into the screen identified by the second value, the palette cycling stops
	;db $09,$0B ;Level 1
	;db $07,$09 ;Level 2
	;db $08,$0A ;Level 3
	;db $09,$0B ;Level 4
	;db $09,$0B ;Level 5
	;db $04,$06 ;Level 6
	;db $07,$09 ;Level 7
	;db $07,$09 ;Level 8
	;db $07,$09 ;Level 9
	;db $07,$09 ;Level 10

	.PAD $DE27
Label984:
	LDA TitleScreenMode
	ORA $26 ;this is never written to, so this does nothing
	ORA ScreenTransitionTimer
	BNE ++
	LDA JeepControlsInput1Frame
	LDY GamePaused
	BNE +
	AND #StartButton
	BEQ ++
	LDA #$01
	STA GamePaused ;Pause Game
	LDA #PauseGameSoundClip
	JMP subInitiateSoundClip
+:	LDA JeepControlsInput1Frame
	AND #StartButton
	BEQ ++
	LDA #$00
	STA GamePaused ;Unpause Game
++:	RTS

tblPPUGraphicsUpdateBytesToLoad:
	db $20 ;EMPTY PPU Update
	db $20 ;Level 3 F2
	db $20 ;Level 5 F2
	db $20 ;Level 3 Water Tile 1
	db $20 ;Level 3 Water Tile 2
	db $20 ;Level 1 Boss Tank & Water splash graphics for jeep
	db $20 ;Level 6 F2
	db $20 ;Level 4 F2
	db $10 ;Level 6 Escalator 1
	db $10 ;Level 6 Escalator 2
	db $20 ;Level 6 Large Boss Tank Tread 1
	db $20 ;Level 6 Large Boss Tank Tread 2
	db $20 ;Level 6 Large Boss Tank Tread 3
	db $20 ;Level 6 Large Boss Tank Tread 4
	db $40 ;Level 6 Large Boss Tank Graphics
	db $40 ;Level 6 Large Boss Tank Defeated Graphics
	db $40 ;Level 6 Boss Building & Laser Turret Graphics
	db $20 ;Level 6 Boss Sprite Graphics

;PPU Update
Label1011:	
	LDA PPUGraphicsUpdateTableIndex
	BEQ ++ ;RTS - there's no PPU data to update
	LDY PPUGraphicsUpdateComplete ;Make sure the update isn't complete yet
	BNE +
	INC PPUGraphicsUpdateComplete ;Mark the PPU update as complete
	ASL
	TAY
	LDA tblInGamePalette_GraphicsUpdateActionAddress,Y
	STA $00
	LDA (tblInGamePalette_GraphicsUpdateActionAddress + 1),Y
	STA $01
	LDY PPUGraphicsUpdateTableIndex
	LDA tblPPUGraphicsUpdateBank,Y
	TAY
	JSR subChangeBank_YhasBank
	LDY #$00
	LDA ($00),Y
	STA $C0
	INY
	LDA ($00),Y
	STA $BE
	INY
	LDA ($00),Y
	STA $BF
	INY
	LDA ($00),Y
	STA $BC
	INY
	LDA ($00),Y
	STA $BD
	INY
	LDA ($00),Y
	STA $C1
	INY
	LDA ($00),Y
	STA $C2
++:
-:	RTS

+:	LDX PPUGraphicsUpdateByteLength
	CPX #$18
	BCS - ;RTS
	LDY PPUGraphicsUpdateTableIndex
	LDA tblPPUGraphicsUpdateBytesToLoad,Y
	STA $10
	LDA #$03
	STA $0770,X
	INX
	LDY $C0
	JSR subChangeBank_YhasBank
	LDA $BE
	STA $0770,X
	INX
	LDA $BF
	STA $0770,X
	INX
	LDA $C2
	CMP $10
	BCS ++
	LDY $C1
	BEQ +
++:	LDA $10
+:	STA $0770,X
	STA $00
	INX
	LDY #$00
-:	LDA ($BC),Y
	STA $0770,X
	INY
	INX
	LDA $C2
	SEC
	SBC #$01
	STA $C2
	BNE +
	LDA $C1
	BEQ ++
+:	DEC $00
	BEQ +
	LDA $C1
	SBC #$00
	STA $C1
	JMP -
+:	LDA $BC
	CLC
	ADC $10
	STA $BC
	LDA $BD
	ADC #$00
	STA $BD
	LDA $BF
	CLC
	ADC $10
	STA $BF
	LDA $BE
	ADC #$00
	STA $BE
	JMP +
++:	LDA #$00
	STA PPUGraphicsUpdateTableIndex
	STA PPUGraphicsUpdateComplete
+:	LDA #$FF
	STA $0770,X
	INX
	LDA #$00
	STA $0770,X
	STX PPUGraphicsUpdateByteLength
EMPTYPPUUpdateObject_RTS:
	RTS

;Defines the bank for the source data for PPU in-game graphics updates
tblPPUGraphicsUpdateBank:
	db $07 ;00 EMPTY PPU Update
	db $02 ;01 Level 3 F2
	db $02 ;02 Level 5 F2
	db $02 ;03 Level 3 Water Tile 1
	db $02 ;04 Level 3 Water Tile 2
	db $02 ;05 Level 1 Boss Tank & Water splash graphics for jeep
	db $02 ;06 Level 6 F2
	db $02 ;07 Level 4 F2
	db $02 ;08 Level 6 Escalator 1
	db $02 ;09 Level 6 Escalator 2
	db $02 ;0A Level 6 Large Boss Tank Tread 1
	db $02 ;0B Level 6 Large Boss Tank Tread 2
	db $02 ;0C Level 6 Large Boss Tank Tread 3
	db $02 ;0D Level 6 Large Boss Tank Tread 4
	db $01 ;0E Level 6 Large Boss Tank Graphics
	db $04 ;0F Level 6 Large Boss Tank Defeated Graphics
	db $02 ;10 Level 6 Boss Building & Laser Turret Graphics
	db $05 ;11 Level 6 Boss Sprite Graphics

tblInGamePalette_GraphicsUpdateActionAddress:
	dw EMPTYPPUUpdateObject_RTS 		;00 RTS.  does nothing.  Used as a default for no action
	dw tblLevel3F2PatternTableUpdate 	;01
	dw tblLevel5F2PatternTableUpdate 	;02
	dw tblLevel3WaterTileUpdate1 		;03
	dw tblLevel3WaterTileUpdate2 		;04
	dw tblLevel1BossTankSpriteGraphics ;05
	dw tblLevel6F2PatternTableUpdate 		;06
	dw tblLevel4F2PatternTableUpdate 		;07
	dw tblLevel6EscalatorBGGraphicsUpdate1 	;08
	dw tblLevel6EscalatorBGGraphicsUpdate2 	;09
	dw tblLevel6FinalBossTankTreadBGGraphicsUpdate1 	;0A
	dw tblLevel6FinalBossTankTreadBGGraphicsUpdate2 	;0B
	dw tblLevel6FinalBossTankTreadBGGraphicsUpdate3 	;0C
	dw tblLevel6FinalBossTankTreadBGGraphicsUpdate4 	;0D
	dw tblLevel6FinalBossTankGraphicsUpdate 		;0E
	dw tblLevel6FinalBossDefeatedBGGraphicsUpdate	 ;0F
	dw tblLevel6FinalBossBuilding_LaserTurretGraphicsUpdate ;10
	dw tblLevel6FinalBossSpriteGraphicsUpdate		;11
	
Label1281:
	LDA #$01 ;1x1 tile index
	BNE +
Label1282:
	LDA #$02 ;2x2 tile index
	BNE +
-:	LDX $35
	RTS
Label1280:
	LDA #$00 ;4x4 tile index
+:	STA $D8
	LDA SpriteState,X
	BMI -
	LDX PPUGraphicsUpdateByteLength
	CPX #$30 ;See if there's room left in the PPU update for the below update
	BCS -
	LDA $02
	CMP #$E8
	BCS -
	LDA $03
	ASL
	TAY
	LDA tblObjectControlledGraphicsUpdate,Y
	STA $10
	LDA (tblObjectControlledGraphicsUpdate + 1),Y
	STA $11
	LDY $D8
	LDA tblPPUGraphicsUpdateBytesToLoad2,Y
	TAY
	LDA ($10),Y
	STA $16
	LDA $00
	STA $12
	LDA #$00
	STA $10
	LDA $D8
	ASL
	TAY
	LDA tblAddressForMatrixForUpdating_NxN_BGTilePPUGraphicsUpdate,Y
	STA $DE
	LDA (tblAddressForMatrixForUpdating_NxN_BGTilePPUGraphicsUpdate + 1),Y
	STA $DF
-:	LDY $10
	LDA ($DE),Y
	BMI +
	CLC
	ADC $01
	STA $11
	LDA $02
	INY
	CLC
	ADC ($DE),Y
	DEY
	CMP #$E8 ;would be offscreen
	BCS +
	STA $14
	JSR Label1028
	INC $10
	INC $10
	JMP -

tblPPUGraphicsUpdateBytesToLoad2:
	db $10,$01,$04
table12: ;probably 4x4, 1x1, and 2x2?
	db $04,$01,$02
	
+:	LDA #$00
	STA $04
	LDY $D8
	LDA table12,Y
	STA $0E
Label1037:	LDY $D8
	LDA table12,Y
	STA $0F
	LDA #$20
	LDY $00
	BEQ +
	LDA #$24
+:	STA $08
	LDA #$00
	STA $09
	STA $0A
	LDA CurrentLevelScreenSubPosition
	BEQ +
	EOR #$FF
	SEC
	SBC #$0F
+:	CLC
	ADC $02
	BCS +
	CMP #$F0
	BCC ++
+:	CLC
	ADC #$10
++:	AND #$F8
	ASL
	ROL $0A
	ASL
	ROL $0A
	STA $09
	LDA $01
	LSR
	LSR
	LSR
	CLC
	ADC $09
	STA $09
	LDA $0A
	CLC
	ADC $08
	STA $08
	LDX PPUGraphicsUpdateByteLength
	LDY $D8
	LDA $0E
	CMP table12,Y
	BNE +
	LDA #$01
	STA $0770,X
	INX
+:	LDA $08
	STA $0770,X
	INX
	LDA $09
	STA $0770,X
	INX
	STX PPUGraphicsUpdateByteLength
	LDA $03
	ASL
	TAY
	;This is updating the tiles
	LDA tblObjectControlledGraphicsUpdate,Y
	STA $0C
	LDA (tblObjectControlledGraphicsUpdate + 1),Y
	STA $0D
	LDX PPUGraphicsUpdateByteLength
	LDY $04
-:	LDA ($0C),Y
	STA $0770,X
	INC $04
	INX
	INY
	DEC $0F
	BNE -
	DEC $0E
	BEQ +
	LDA $02
	CLC
	ADC #$08
	STA $02
	CMP #$E8
	BCS +
	LDA #$FF
	STA $0770,X
	INX
	LDA #$01
	STA $0770,X
	INX
	STX PPUGraphicsUpdateByteLength
	JMP Label1037
+:	LDA #$FF
	STA $0770,X
	INX
	LDA #$00
	STA $0770,X
	STX PPUGraphicsUpdateByteLength
	LDX $35
	RTS
	
	.PAD $E099
tblObjectControlledGraphicsUpdate:	
	dw tblGateOpenedGraphicsUpdate 						;00
	dw tblLevel1_2_4_5POWBuildingExitLeftOpenedGraphicsUpdate	;01
	dw tblLevel1_2_4_5POWBuildingExitRightOpenedGraphicsUpdate	;02
	dw tblLevel1_3_6PowerUpPOWBuildingOpenedGraphicsUpdate		;03
	dw tblLevel2PowerUpPOWBuildingOpenedGraphicsUpdate		;04
	dw tblLevel2BrokenPillarGraphicsUpdate					;05
	dw tblLevel2StatueHeadBossDestroyedGraphicsUpdate			;06
	dw tblLevel2StatueHeadDestroyedGraphicsUpdate			;07
	dw tblLevel2StatueHeadFlashingEyesGraphicsUpdate			;08
	dw tblLevel2StatueHeadNormalEyesGraphicsUpdate			;09
	dw tblLevel2StatueHeadMouthOpenGraphicsUpdate			;0A
	dw tblLevel2StatueHeadMouthClosedGraphicsUpdate			;0B
	dw tblLevel3POWBuildingExitLeftOpenedGraphicsUpdate		;0C
	dw tblLevel3POWBuildingExitRightOpenedGraphicsUpdate		;0D
	dw tblLevel3SpreadTurretBossDestroyedGraphicsUpdate		;0E
	dw tblLevel1_2_4_5POWBuildingExitRightOpenedGraphicsUpdate	;0F redundant
	dw tblLevel5PowerUpPOWBuildingOpenedGraphicsUpdate		;10
	dw tblLevel5BossShutterDoorOpenGraphicsUpdate			;11
	dw tblLevel5BossShutterDoorOpen2_3GraphicsUpdate			;12
	dw tblLevel5BossShutterDoorOpen1_3GraphicsUpdate			;13
	dw tblLevel5BossShutterDoorClosedGraphicsUpdate			;14
	dw tblLevel1_2_4_5POWBuildingExitRightOpenedGraphicsUpdate	;15 redundant
	dw tblLevel4PowerUpPOWBuildingOpenedGraphicsUpdate		;16
	dw tblLevel6POWBuildingExitRightOpenedGraphicsUpdate		;17
	dw tblLevel6ParkedTankExplodedGraphicsUpdate				;18
	dw tblLevel6POWBuildingExitLeftOpenedGraphicsUpdate		;19
	dw tblLevel6BossLasterTurretHoleInGroundGraphicsUpdate		;1A
	dw tblLevel5BossShutterDoorDestroyedGraphicsUpdate		;1B
	dw tblLevel3ParkedJeepExplodedGraphicsUpdate				;1C

tblGateOpenedGraphicsUpdate:	
	db $22,$22,$22,$22
	db $24,$22,$22,$25
	db $24,$22,$22,$25
	db $23,$23,$23,$23	
	db $00 ;New Collision Type

tblLevel1_2_4_5POWBuildingExitLeftOpenedGraphicsUpdate:
	db $63,$48,$48,$53
	db $64,$51,$50,$4E
	db $22,$52,$52,$4F
	db $64,$48,$48,$4A
	db $01 ;New Collision Type
	
tblLevel1_3_6PowerUpPOWBuildingOpenedGraphicsUpdate:
	db $9D,$9E,$9F,$A0
	db $A1,$A2,$A3,$93
	db $94,$A2,$A3,$94
	db $C0,$A4,$A4,$C0
	db $01 ;New Collision Type

tblLevel2PowerUpPOWBuildingOpenedGraphicsUpdate:	
	db $97,$97,$4E,$97
	db $4B,$4D,$4F,$4B
	db $4B,$61,$4F,$4B
	db $C1,$4F,$51,$BB
	db $01 ;New Collision Type
	
tblLevel2BrokenPillarGraphicsUpdate:
	db $22,$73,$22,$74
	db $73,$75,$73,$75
	db $22,$A2,$A3,$22
	db $F1,$9B,$9C,$F2
	db $00 ;New Collision Type

tblLevel2StatueHeadBossDestroyedGraphicsUpdate:
	db $CF,$CF,$CF,$CF
	db $CD,$CD,$CD,$CD
	db $B1,$B1,$B2,$FD
	db $A2,$9C,$BF,$D3
	db $01 ;New Collision Type

tblLevel2StatueHeadDestroyedGraphicsUpdate:
	db $C5,$C5,$C5,$C5
	db $C5,$C5,$C5,$C5
	db $A2,$A2,$A3,$CA
	db $BD,$9C,$BF,$CF
	db $01 ;New Collision Type
	
tblLevel2StatueHeadFlashingEyesGraphicsUpdate:
	db $98
	db $01 
	
tblLevel2StatueHeadNormalEyesGraphicsUpdate:
	db $AE
	db $01
	
tblLevel2StatueHeadMouthOpenGraphicsUpdate:
	db $99
	db $02
	
tblLevel2StatueHeadMouthClosedGraphicsUpdate:
	db $BE
	db $02
	
tblLevel3POWBuildingExitLeftOpenedGraphicsUpdate:
	db $B2,$86,$86,$93
	db $B3,$91,$90,$99
	db $22,$92,$92,$98
	db $B3,$86,$86,$88
	db $01

tblLevel3POWBuildingExitRightOpenedGraphicsUpdate:
	db $97,$89,$C0,$B2
	db $99,$90,$94,$B3
	db $98,$92,$22,$22
	db $89,$89,$95,$B3
	db $01

tblLevel3ParkedJeepExplodedGraphicsUpdate:
	db $22,$22,$22,$3B
	db $22,$22,$22,$3B
	db $22,$22,$22,$3B
	db $3A,$3A,$3A,$47
	db $00 ;New Collision Type

tblLevel3SpreadTurretBossDestroyedGraphicsUpdate:	
	db $A0,$A1,$AC,$AD
	db $00

tblLevel4PowerUpPOWBuildingOpenedGraphicsUpdate:	
	db $A9,$A9,$A9,$A9
	db $4E,$AA,$AA,$4E
	db $4D,$B3,$B3,$4F
	db $60,$B3,$B3,$4B
	db $01

tblLevel1_2_4_5POWBuildingExitRightOpenedGraphicsUpdate:
	db $4D,$4B,$60,$63
	db $4E,$50,$55,$64
	db $4F,$22,$22,$22
	db $4B,$4B,$56,$64
	db $01 ;New Collision Type

tblLevel5PowerUpPOWBuildingOpenedGraphicsUpdate:
	db $48,$53,$4D,$4B
	db $48,$4E,$4E,$4B
	db $53,$4F,$4F,$4B
	db $85,$22,$51,$5E
	db $01

tblLevel5BossShutterDoorOpenGraphicsUpdate:
	db $8F,$8F,$8F,$8F
	db $CA,$CB,$CC,$CA
	db $00,$00,$00,$00
	db $B6,$B6,$B6,$B6
	db $02

tblLevel5BossShutterDoorOpen2_3GraphicsUpdate:
	db $8F,$8F,$8F,$8F
	db $90,$91,$91,$90
	db $00,$00,$00,$00
	db $B6,$B6,$B6,$B6
	db $01

tblLevel5BossShutterDoorOpen1_3GraphicsUpdate:
	db $8F,$8F,$8F,$8F
	db $90,$91,$91,$90
	db $90,$91,$91,$90
	db $B6,$B6,$B6,$B6
	db $01

tblLevel5BossShutterDoorClosedGraphicsUpdate:
	db $8F,$8F,$8F,$8F
	db $90,$91,$91,$90
	db $90,$91,$91,$90
	db $BA,$BB,$BB,$BA
	db $01
	
tblLevel5BossShutterDoorDestroyedGraphicsUpdate:
	db $8F,$A9,$A9,$8F
	db $AA,$C8,$C9,$AA
	db $AA,$00,$00,$AA
	db $B6,$B6,$B6,$B6
	db $02
	
tblLevel6POWBuildingExitRightOpenedGraphicsUpdate:
	db $78,$70,$B0,$B2
	db $7A,$71,$75,$B3
	db $79,$22,$22,$22
	db $70,$70,$76,$B3
	db $01

tblLevel6ParkedTankExplodedGraphicsUpdate:	
	db $26,$26,$26,$26
	db $4C,$22,$22,$22
	db $4C,$22,$22,$22
	db $4C,$22,$22,$22
	db $00

tblLevel6POWBuildingExitLeftOpenedGraphicsUpdate:	
	db $B2,$6D,$6D,$74
	db $B3,$72,$71,$7A
	db $22,$73,$73,$79
	db $B3,$6D,$6D,$6F
	db $01

tblLevel6BossLasterTurretHoleInGroundGraphicsUpdate:	
	db $AD,$AE,$AF,$B0
	db $02
	
tblAddressForMatrixForUpdating_NxN_BGTilePPUGraphicsUpdate:
	dw tblMatrixForUpdating4x4BGTilePPUGraphicsUpdate
	dw tblMatrixForUpdating1x1BGTilePPUGraphicsUpdate
	dw tblMatrixForUpdating2x2BGTilePPUGraphicsUpdate

;Matrix for building a 32x32 (16 tiles) BG tile replacement PPU Update
tblMatrixForUpdating4x4BGTilePPUGraphicsUpdate:
	;MSB = 1 means update collision?
	;Row 1
	db $00,$00 ;(X,Y) Offset for tile 1
	db $08,$00 ;(X,Y) Offset for tile 2
	db $10,$00 ;(X,Y) Offset for tile 3
	db $18,$00 ;(X,Y) Offset for tile 4
	;Row 2
	db $00,$08 ;(X,Y) Offset for tile 5
	db $08,$08 ;(X,Y) Offset for tile 6
	db $10,$08 ;(X,Y) Offset for tile 7
	db $18,$08 ;(X,Y) Offset for tile 8
	;Row 3
	db $00,$10 ;(X,Y) Offset for tile 9
	db $08,$10 ;(X,Y) Offset for tile 10
	db $10,$10 ;(X,Y) Offset for tile 11
	db $18,$10 ;(X,Y) Offset for tile 12
	;Row 4
	db $00,$18 ;(X,Y) Offset for tile 13
	db $08,$18 ;(X,Y) Offset for tile 14
	db $10,$18 ;(X,Y) Offset for tile 15
	db $18,$18 ;(X,Y) Offset for tile 16
	db $80 ;End of table

;Matrix for building a 16x16 (4 tiles) BG tile replacement PPU Update
tblMatrixForUpdating2x2BGTilePPUGraphicsUpdate:
	db $00,$00 ;(X,Y) Offset for tile 1
	db $08,$00 ;(X,Y) Offset for tile 2
	db $00,$08 ;(X,Y) Offset for tile 3
	db $08,$08 ;(X,Y) Offset for tile 4
	db $80 ;End of table
	
;Matrix for building single 8x8 BG tile replacement PPU Update
tblMatrixForUpdating1x1BGTilePPUGraphicsUpdate:
	db $00,$00 ;(X,Y) Offset for tile 1
	db $80 ;End of table

;Updating BG and collision for object controlled updates?
Label1028:	
	LDA #$00
	STA $08
	LDY #$03
	LDA $12
	BEQ +
	INY
+:	STY $09
	LDA CurrentLevelScreenSubPosition
	AND #$07
	STA $0A
	LDA $14
	SEC
	SBC $0A
	AND #$F8
	CLC
	ADC $4F
	CLC
	ADC #$08
	STA $14
	LDA $11
	AND #$E0
	LSR
	LSR
	LSR
	LSR
	LSR
	CLC
	ADC $14
	TAY
	LDA ($08),Y ;Load the current collision values for this 16x16 section
	STA $17
	LDA $11
	AND #$1F
	LSR
	LSR
	LSR
	TAX
	LDA table10,X
	AND $17
	STA $17
	LDA $16
	DEX
	BMI ++++
	DEX
	BMI +
	DEX
	BMI ++
	BPL +++
++++	ASL
	ASL
+:	ASL
	ASL
++:	ASL
	ASL
+++:	ORA $17
	STA ($08),Y
	RTS

table10:;collision mask
	db $3F,$CF,$F3,$FC
	
Label1210:	
	LDA #$00
	STA $16
	STA $17
	STX $0F
	LDX $39
	JMP +
	
fctGetCollisionTypeFromRAM300_4FF:
	STX $0F ;Preserve X
	TXA
	CLC
	ADC $39
	TAX
	;Start at address $0300.  The map collision is stored in $0300-$04FF
+:	LDA #$00
	STA $08
	LDA #$03
	STA $09
	
	LDA SpriteHorizScreenPositionSubPixel,X
	CLC
	ADC SpriteHorizSpeedLB,X
	LDA SpriteHorizScreenPosition,X
	ADC SpriteHorizSpeedUB,X
	CLC
	ADC $16
	CLC
	ADC ScreenLeftScrollPosition
	STA $00
	BCC + ;Left side of the map
	INC $09 ;We are on the right side of the map.  Start with address $0400
+:	LDA CurrentLevelScreenSubPosition
	AND #$07
	STA $0A
	LDA SpriteVertScreenPositionSubPixel,X
	CLC
	ADC SpriteVertSpeedLB,X
	LDA SpriteVertScreenPosition,X
	ADC SpriteVertSpeedUB,X
-:	SEC
	SBC $0A
	CLC
	ADC $17
	AND #$F8
	CLC
	ADC $4F
	CLC
	ADC #$08
	STA $01
	LDA $00
	AND #$E0
	LSR
	LSR
	LSR
	LSR
	LSR
	CLC
	ADC $01
	TAY
	LDA ($08),Y ;Get the level (1x4) tile collision data
	STA $02
	LDA $00
	AND #$1F
	LSR
	LSR
	LSR
	TAY
	LDX $0F ;Restore X
	;Mask down to the specific 1x1 (8x8 pixel) tile collision data
	LDA tblSprite_BG_CollisionMask,Y 
	AND $02
	
	DEY
	BMI +
	DEY
	BMI ++
	DEY
	BMI +++
	LSR
	ROL
	RTS
+:	LSR
	LSR
++:	LSR
	LSR
+++:	LSR
	LSR
	RTS
	
fctTestForMovementCollision:	
	LDA SpriteAbsoluteVertPositionUB,X
	BNE ++
	;Sprite is on screen
	STX $0F
	LDA #$00
	STA $08
	STA $16
	STA $17
	LDY #$03
	LDA $12
	BEQ +
	INY
+:	STY $09
	LDA $11
	STA $00
	LDA CurrentLevelScreenSubPosition
	AND #$07
	STA $0A
	LDA $14
	JMP -
++:	LDA #$00
-:	RTS
	
;For 32x32 large tiles
tblSprite_BG_CollisionMask:
	db $C0 ;Collision for Left most column of 4 tiles
	db $30 ;Collision for 2nd column of 4 tiles
	db $0C ;Collision for 3rd column of 4 tiles
	db $03 ;Collision for Right most column of 4 tiles
	
Label1001: ;Bullet collision (and Homing Missile) with enemy sprites/objects
	STX $17 ;Preserve X
	LDY #$0F
	LDA JeepBulletState,X
	BEQ ++++ ;RTS
-:	LDA SpriteObjectID,Y
	AND #$7F
	BEQ ++ ;Ignore NULL sprites.  Go to the next one
	LDA SpriteState,Y
	BMI ++ ;Ignore offscreen sprites
	AND #$7F
	BEQ ++ ;Ignore sprites that are just spawning in (state 0)
	LDA SpriteHitboxShapeIndex,Y
	AND #$5F
	CMP #$40
	BCS ++
	AND #$0F
	ASL
	TAX
	LDA tblEnemyHitBoxDimension,X
	STA $08
	LDA (tblEnemyHitBoxDimension + 1),X
	STA $09
	LDX $17 ;Restore X
	LDA JeepBulletHorizScreenPosition,X
	SEC
	SBC SpriteHorizScreenPosition,Y
	BCS +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP $08
	BCS ++
	LDA JeepBulletVertScreenPosition,X
	SEC
	SBC SpriteVertScreenPosition,Y
	BCS +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP $09
	BCS ++
	JSR Label1055 ;despawn bullet on contact
	LDA SpriteHealthHP,Y
	SEC
	SBC #$01 ;bullet damage
	STA SpriteHealthHP,Y
	AND #$7F
	BEQ +++
	LDA #BulletHitTinkSoundClip
	JSR subInitiateSoundClip
++:	DEY
	BPL -

-:
++++	RTS
+++:	STX $10
	STY $11
	LDY #$00
	CPX #$03
	BCC +
	INY
+:	JMP Label1059
--:	JMP Label1060

Label996:
	STX $17 ;Preserve X
	LDY #$0F
---: ;Main weapon collision
	LDA JeepMainWeaponState,X
	BEQ - 	;RTS
	CMP #$09 	;bazooka splashes
	BCS +
	LDA SpriteHealthHP,Y
	BPL +
	LDA JeepMainWeaponState,X
	CMP #$07 	;Bazooka collision detected already - explosion triggered
	BCS - 	;RTS
	CMP #$03 	;Grenade collision detected already - explosion triggered
	BEQ - 	;RTS
	CMP #$04 	;Grenade exploding
	BEQ - 	;RTS
+:	LDA SpriteObjectID,Y
	AND #$7F
	BEQ -- 	;Ignore NULL sprites
	LDA SpriteState,Y
	BMI -- 	;Ignore offscreen sprites
	AND #$7F
	BEQ -- 	;Ignore sprites just spawning in (state 0)
	LDA SpriteHitboxShapeIndex,Y
	AND #$2F
	CMP #$20
	BCS Label1060
	AND #$0F
	ASL
	TAX
	LDA tblEnemyHitBoxDimension,X
	CLC
	ADC #$04
	STA $08
	LDA (tblEnemyHitBoxDimension + 1),X
	CLC
	ADC #$04
	STA $09
	LDX $17 ;Restore X
	LDA JeepMainWeaponHorizScreenPosition,X
	SEC
	SBC SpriteHorizScreenPosition,Y
	BCS +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP $08
	BCS Label1060
	LDA JeepMainWeaponVertScreenPosition,X
	SEC
	SBC SpriteVertScreenPosition,Y
	BCS +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP $09
	BCS Label1060
	CPX #$02
	BCC +
	LDA SpriteHealthHP,Y
	BMI Label1060
+:	LDA SpriteHitboxShapeIndex,Y
	AND #$10
	BNE ++
	CPX #$02
	BCS ++
	LDA JeepMainWeaponState,X
	LDX #$07 ;Bazooka collision state
	CMP #$05 ;Compares A, not X.  A<5 is grenade
	BCS +
	LDX #$03 ;Grenade collision state
+:	TXA
	LDX $17 ;Restore X
	STA JeepMainWeaponState,X
	LDA #MainWeaponExplosionOnEnemy
	JSR subInitiateSoundClip
++:	LDA SpriteHealthHP,Y
	BPL + ;Branch if a grenade/bazooka is an instant kill
	AND #$7F ;Here MSB is set, meaning health must be depleted for death
	SEC
	SBC #$05 ;grenade/bazooka damage
	BEQ + ;Branch on death
	BMI +
	;The enemy is still alive at this point
	STA $10 ;Temporarily store the remaining health
	LDA SpriteHealthHP,Y
	AND #$80 ;Get the MSB of the enemy's health.  At this point, it should always be #$80
	ORA $10  ;Add the new damaged health
	STA SpriteHealthHP,Y ;Update the enemy's health after damage
Label1060:	
	DEY
	BMI ++
	JMP ---
+:	STX $10
	STY $11
	TXA
	AND #$01
	TAY
Label1059:	LDX $11
	JSR subGetObjectPointsValue_AddToPlayerScore
	LDX $10
	LDY $11
	LDA SpriteObjectID,Y
	AND #$7F
	TAX
	LDA tblEnemyPoints_DeathState,X
	AND #$0F ;Get the enemy death state
	STA SpriteState,Y ;Begin death animation
	LDX $17 ;Restore X
++:
-:	RTS

;Jeep Collision Detection with other sprites
Label1005:
	LDA SpriteObjectID,X
	AND #$7F
	BEQ - ;RTS - Ignore NULL sprites
	LDA SpriteState,X
	BMI - ;RTS - Ignore offscreen sprites
	AND #$7F
	BEQ - ;RTS - Ignore sprites just spawning in (state 0)
	LDY #$01
---:	LDA JeepState,Y
	BEQ ++
	CMP #$02 ;player jeep sprite state check
	BCS ++
	LDA SpriteHitboxShapeIndex,X
	BMI - ;RTS - MSB=1 means no jeep collision for this sprite
	AND #$0F
	ASL
	TAX
	LDA tblEnemyHitBoxDimension,X
	STA $08
	LDA (tblEnemyHitBoxDimension + 1),X
	STA $09
	LDX $35
	LDA JeepHorizScreenPosition,Y
	SEC
	SBC SpriteHorizScreenPosition,X
	BCS +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP $08
	BCS ++
	LDA JeepVertScreenPosition,Y
	SEC
	SBC SpriteVertScreenPosition,X
	BCS +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP $09
	BCS ++
	LDA SpriteObjectID,X
	AND #$7F
	CMP #$05 ;IDs 1-4 are all of the infantry
	BCC Label1074
+:	CMP #$16 ;Walking POW ID
	BEQ POWPickedUp
	CMP #$3F ;POW drop off object at helipad ID
	BEQ ++++
	CMP #$52 ;Power Up Star - Extra Lives ID
	BNE +
	JMP PowerUpStar_ExtraLivesPickedUp
+:	CMP #$50
	BNE +
	JMP PowerUpStar_KillAllEnemiesPickedup
+:	CMP #$51
	BEQ PowerUpStar_MaxWeaponPickedUp
	CMP #$44 ;Escalator Object ID
	BNE lblJeepDeathByCollision
	LDA #$01
	STA JeepEscalatorEffectActive,Y
	BNE ++
++++	LDA #$01
	STA JeepAtHelipadDropoff,Y
++:
--:	DEY
	BMI ++++ ;RTS
	JMP ---

POWPickedUp:
	;POW was picked up - add 1 to the onboard POW count
	;unfortunately there is no INC ADDR,Y opcode...
	LDA JeepPOWCount,Y
	CLC
	ADC #$01
	STA JeepPOWCount,Y
	
	;Play POW pick up sound
	;could be coded better...if POW is a power up, this is not needed, but runs anyway
	LDA #POWPickedUpSoundClip
	JSR subInitiateSoundClip
	
	;If Power up, play special sound
	LDA SpriteData5,X
	LSR
	BCC +++
	LDA #WeaponUpgradeSoundClip
	JSR subInitiateSoundClip
	;Upgrade main weapon on flashing POW pick up
	LDA JeepMainWeapon,Y
	CMP #$03
	BCS +
	CLC
	ADC #$01
	STA JeepMainWeapon,Y
+:	LDA Jeep1MainWeapon
	CLC
	ADC Jeep2MainWeapon
	CMP #$03
	BCC ++
	LDA #$03
++:	STA DifficultyBasedOnWeapon
+++:	JMP subDespawnSprite
	
lblJeepDeathByCollision:
	LDA JeepIFrameTimer,Y
	BNE --	
	LDA #$02
	STA JeepState,Y
	LDA SpriteHealthHP,X
	BMI --
Label1074:	LDA SpriteObjectID,X
	AND #$7F
	TAX
	LDA tblEnemyPoints_DeathState,X
	AND #$0F
	LDX $35
	STA SpriteState,X
	STY $11
	JSR subGetObjectPointsValue_AddToPlayerScore
	LDX $35
	LDY $11
++++	RTS

PowerUpStar_MaxWeaponPickedUp:
	JSR subDespawnSprite
	LDA #$03
	STA JeepMainWeapon,Y
	LDA #$03 ;unnecessary here
	STA DifficultyBasedOnWeapon
	LDA #WeaponUpgradeSoundClip
	JSR subInitiateSoundClip
-:	JMP --
	
PowerUpStar_ExtraLivesPickedUp:
	JSR subDespawnSprite
	LDA JeepLifeCount,Y
	CMP #MaxLifeCount ;caps the number of lives to 9 (when getting 1Up), Extra life star code
	BCS - ;, Extra life star code
	LDA #$01 ;Number of Lives to add when getting the, Extra life star code
	CLC ;, Extra life star code
	ADC JeepLifeCount,Y
	STA JeepLifeCount,Y
	LDA #ExtraLifeSoundClip
	JSR subInitiateSoundClip
	JMP -

PowerUpStar_KillAllEnemiesPickedup:
	JSR subDespawnSprite
	STY $05 ;Preserve Y
	LDX #$0F
-:	LDA SpriteObjectID,X
	BMI +
	TAY
	LDA tblEnemyPoints_DeathState,Y
	AND #$0F
	STA $06
	LDA SpriteState,X
	AND #$80
	ORA $06
	STA SpriteState,X

+:	DEX
	BPL -
	LDX $35 ;Restore X
	LDY $05 ;Restore Y
	JMP --

subGetObjectPointsValue_AddToPlayerScore:	
	LDA EnemyPoints,X
	ASL
	TAX
	LDA tblPointValues,X
	STA $02
	LDA (tblPointValues + 1),X
	STA $01
	JMP subAddToPlayerScore

tblPointValues:
	db $00,$00 ;0 - 0 Points
	db $00,$50 ;1 - 50 Points
	db $01,$00 ;2 - 100 Points
	db $02,$00 ;3 - 200 Points
	db $03,$00 ;4 - 300 Points
	db $05,$00 ;5 - 500 Points
	db $08,$00 ;6 - 800 Points
	db $10,$00 ;7 - 1000 Points
	db $15,$00 ;8 - 1500 Points
	db $20,$00 ;9 - 2000 Points
	db $30,$00 ;A - 3000 Points
	db $50,$00 ;B - 5000 Points
	db $80,$00 ;C - 8000 Points
	db $90,$00 ;D - 9000 Points
	db $99,$90 ;E - 9990 Points
	db $00,$10 ;F - 10 Points

--::	
	LDA Jeep2VertPosition
	CMP #$61
	BCC +
	JMP Label1092
+:	JMP Label1093
Label995:
	LDX #$00
	JSR subProcessDeadJeep_StealTeammateLives
	LDA Player2Active
	BNE +
	JMP Label1096
+:	LDX #$01
	JSR subProcessDeadJeep_StealTeammateLives
	LDA Jeep1VisibleFrameTimer
	AND #$02
	BEQ Label1097
	LDA Jeep1HorizPosition
	CMP #$40
	BCC +
	JMP Label1099
+:	LDA ScreenLeftScrollPosition
	BEQ Label1100
	LDA Jeep2HorizPosition
	CMP #$C0
	BCS Label1100
	JSR subAdjustJeepPositionOnScrollLeft
Label1109:	LDA Jeep1VisibleFrameTimer
	AND #$01
	BEQ ++
	LDA PreviousScreenDataScrollTracking
	BEQ +
	LDA ScreenVerticalScrollLockForBossFight
	BNE +
	LDA Jeep1VertPosition
	CMP #$B1
	BCS --
+:	JMP Label1105
Label1113:	LDA #$F0
	BNE +
Label1114:	LDA #$10
+:	STA Jeep1HorizPosition
	BNE +++
Label1115:	LDA #$F0
	BNE +
Label1116:	LDA #$10
+:	STA Jeep2HorizPosition
	BNE Label1109
-:	JMP Label1099
Label1097:	LDA Jeep1HorizPosition
	CMP #$C1
	BCC -
	LDA ScreenLeftScrollPosition
	CMP #$FF
	BCS Label1100
	LDA Jeep2HorizPosition
	CMP #$41
	BCC Label1100
	JSR subAdjustJeepPositionOnScrollRight
	JMP Label1109
++:	LDA ScreenVerticalScrollLockForBossFight
	BNE Label1105
	LDA Jeep1VertPosition
	CMP #$60
	BCS Label1105
	LDA Jeep2VertPosition
	CMP #$B0
	BCS Label1093
	JSR Label1112
Label1124:	RTS
Label1100:	LDA Jeep1HorizPosition
	CMP #$F1
	BCS Label1113
	CMP #$10
	BCC Label1114
+++:	LDA Jeep2HorizPosition
	CMP #$F1
	BCS Label1115
	CMP #$10
	BCC Label1116
	JMP Label1109
----	LDA #$E0
	BNE +
---:	LDA #$30
+:	STA Jeep1VertPosition
	BNE Label1118
--:	LDA #$E0
	BNE +
-:	LDA #$30
+:	STA Jeep2VertPosition
	RTS
Label1093:	LDA Jeep1VertPosition
	CMP #$E1
	BCS ----
	CMP #$30
	BCC ---
Label1118:	LDA Jeep2VertPosition
	CMP #$E1
	BCS --
	CMP #$30
	BCC -
	BCS Label1124
Label1105:	LDA Jeep2VisibleFrameTimer
	AND #$01
	BEQ +++
	LDA PreviousScreenDataScrollTracking
	BEQ Label1093
	LDA ScreenVerticalScrollLockForBossFight
	BNE Label1093
	LDA Jeep2VertPosition
	CMP #$B1
	BCC Label1093
	LDA Jeep1VertPosition
	CMP #$61
	BCC Label1093
	JMP Label1092
Label1099:	LDA Jeep2VisibleFrameTimer
	AND #$02
	BEQ Label1126
	LDA Jeep2HorizPosition
	CMP #$40
	BCS Label1100
	LDA ScreenLeftScrollPosition
	BEQ Label1100
	LDA Jeep1HorizPosition
	CMP #$C0
	BCS Label1100
	JSR subAdjustJeepPositionOnScrollLeft
	JMP Label1109
-:	JMP Label1100
Label1126:	LDA Jeep2HorizPosition
	CMP #$C1
	BCC -
	LDA ScreenLeftScrollPosition
	CMP #$FF
	BCS -
	LDA Jeep1HorizPosition
	CMP #$41
	BCC -
	JSR subAdjustJeepPositionOnScrollRight
	JMP Label1109
-:	JMP Label1093
+++:	LDA ScreenVerticalScrollLockForBossFight
	BNE Label1093
	LDA Jeep2VertPosition
	CMP #$60
	BCS -
	LDA Jeep1VertPosition
	CMP #$B0
	BCS -
Label1112:
	;Limited how far the player can travel backwards
	LDA PreviousScreenDataScrollTracking
	CMP #$40
	BCS +
	INC PreviousScreenDataScrollTracking
+:	LDA #$00
	STA ScreenScrolledUp_Down
	INC Jeep1VertPosition
	INC Jeep2VertPosition
	INC CurrentLevelScreenSubPosition
	LDA CurrentLevelScreenSubPosition
	CMP #$F0
	BCC +
	LDA #$00
	STA CurrentLevelScreenSubPosition
	INC CurrentLevelScreen
+:	RTS

Label1092:
	DEC PreviousScreenDataScrollTracking
	LDA #$01
	STA ScreenScrolledUp_Down
	DEC Jeep1VertPosition
	DEC Jeep2VertPosition
	DEC CurrentLevelScreenSubPosition
	LDA CurrentLevelScreenSubPosition
	CMP #$F0
	BCC +
	LDA #$EF
	STA CurrentLevelScreenSubPosition
	DEC CurrentLevelScreen
+:	RTS

subAdjustJeepPositionOnScrollRight:
	DEC Jeep1HorizPosition
	DEC Jeep2HorizPosition
	INC ScreenLeftScrollPosition
	RTS

subAdjustJeepPositionOnScrollLeft:
	INC Jeep1HorizPosition
	INC Jeep2HorizPosition
	DEC ScreenLeftScrollPosition
	RTS

;Screen scrolling when a jeep nears the edge of the screen
;1 Player ONLY
Label1096:
	LDX #$00 ;Start with Jeep 1
	LDA JeepHorizPosition,X
	TAY
	SEC
	SBC #JeepMinimumHorizontalPositionForScrolling
	BCC Label1132
	SBC #(JeepMaximumHorizontalPositionForScrolling - JeepMinimumHorizontalPositionForScrolling + 1)
	BCS ++
-:	LDA JeepVertPosition,X
	SEC
	SBC #JeepMinimumVerticalPositionForScrolling
	BCC Label1134
	SBC #(JeepMaximumVerticalPositionForScrolling - JeepMinimumVerticalPositionForScrolling + 1)
	BCS Label1135
--:	RTS



Label1132:	LDA $40
	BNE Label1136
	CPY #$10
	BCS -
	LDA #$10
	STA JeepHorizPosition,X
	BNE -
Label1136:	DEC $40
	LDA #$40
	BNE +
++:	LDA $40
	CMP #$FF
	BNE ++
	CPY #$F1
	BCC -
	LDA #$F0
+:	
---:	STA JeepHorizPosition,X
	BNE -
++:	INC ScreenLeftScrollPosition
	LDA #$BF
	BNE ---
Label1134:	LDA $3A
	BEQ Label1140
	LDA JeepVertPosition
	CMP #$30
	BCS -- ;RTS
	LDA #$30
	STA Jeep1VertPosition
	RTS
Label1140:	LDA $3D
	CMP #$40
	BCS +
	INC $3D
+:	LDA #$60
	STA JeepVertPosition,X
	LDA #$00
	STA $4E
	INC CurrentLevelScreenSubPosition
	LDA CurrentLevelScreenSubPosition
	CMP #$F0 ;Roll over to the next screen at &HF0 = 240 (NES resolution)
	BCC -- ;RTS
	LDA #$00
	STA CurrentLevelScreenSubPosition
	INC CurrentLevelScreen ;increment to the next screen
-:	RTS

Label1135:
	LDA $3A
	BNE ++
	LDA $3D
	BNE +
++:	LDA Jeep1VertPosition
	CMP #$E0
	BCC -- ;RTS
	LDA #$E0
	STA Jeep1VertPosition
	RTS
+:	DEC $3D
	LDA #$BF
	STA JeepVertPosition,X
	LDA #$01
	STA $4E
	DEC CurrentLevelScreenSubPosition
	LDA CurrentLevelScreenSubPosition
	CMP #$F0
	BCC - ;RTS
	LDA #$EF
	STA CurrentLevelScreenSubPosition
	DEC CurrentLevelScreen
	RTS

tblJeepLevelSpawnLocation: ;The location where the jeeps spawn when a level starts
	db $30 ;Player 1 X position
	db $D0 ;Player 2 X position
	db $E0 ;Player 1 Y position
	db $E0 ;Player 2 Y position

subProcessDeadJeep_StealTeammateLives:	
	LDA JeepLifeCount,X
	BNE ++++ ;player is alive
	;Jeep is dead - reset it's properties
	STA JeepAttributes,X ;A is zero here from the BNE
	LDA #$80
	STA JeepHorizPosition,X
	STA JeepVertPosition,X
	LDA tblJeepLevelSpawnLocation,X
	STA JeepHorizScreenPosition,X
	LDA (tblJeepLevelSpawnLocation + 2),X
	STA JeepVertScreenPosition,X
	LDY #$0C ;GAME OVER text sprite render
	LDA RNG_INCEveryFrame
	AND #$80
	BPL +
	CPX #$01
	BEQ +++
	BNE ++
+:	CPX #$00
	BEQ +++
++:	LDY #$00
+++:	TYA
	STA JeepTypeIndex,X
	LDA Player2Active
	BEQ +
	;A Player is dead, but 2 Player mode was selected at the Title Screen
	LDA JeepControlsInput,X
	CMP #(BButton + AButton) ;Button combo to steal comrade's lives if dead
	BNE +
	;Player has pressed the button combination to steal a life from the other player
	STX $10 
	;Whichever play pressed the button combination, this switches to the other player to steal their life;Preserve X
	TXA
	EOR #$01
	TAX
	;The dead player will respawn on top of the player that is alive
	;;this will avoid all kinds of issues (off screen, collision, etc)
	LDA JeepHorizScreenPosition,X
	STA $11
	LDA JeepVertScreenPosition,X
	STA $12
	LDA JeepLifeCount,X
	CMP #$02 ;Only steal a life if the only player has enough lives left
	BCC +
	DEC JeepLifeCount,X ;Remove life from player that is alive
	LDX $10 ;Restore X (get the dead player's index)
	;Set dead player's spawn
	LDA $11
	STA JeepHorizScreenPosition,X
	STA JeepHorizPosition,X
	LDA $12
	STA JeepVertScreenPosition,X
	STA JeepVertPosition,X
	;Give them the life stolen from the other player
	INC JeepLifeCount,X
	LDA #$00
	STA JeepState,X
+:	RTS

++++	LDA JeepState,X
	CMP #$02 ;Indicates any state other than normal (and dead = 00)
	BCS subProcessJeepState
	;Process player fire buttons
	LDA JeepControlsInput1Frame,X ;Load players control pulse input
	AND #BButton ;check for button B pulse
	BNE + ;branch if button just pressed
	LDA JeepControlsInput,X ;Load players control direct buttons
	AND #BButton ;see if button B is being held down
	BEQ ++ ;Branch on not held

	LDA RNG_INCEveryFrame
	AND #$1F
	BNE ++
+:	LDY #$02
	CPX #$00
	BEQ +
	LDY #$05
-:
+:	LDA JeepBulletState,Y
	BEQ +
	DEY
	BMI ++
+++:	CPY #$02
	BEQ ++
	BNE -
	;Spawn Jeep Bullet
+:	LDA #$01
	STA JeepBulletState,Y
	LDA Jeep1HorizScreenPosition,X
	STA JeepBulletHorizScreenPosition,Y
	LDA JeepVertScreenPosition,X
	STA JeepBulletVertScreenPosition,Y
++:	LDA JeepControlsInput1Frame,X ;Load players control pulse input
	AND #AButton ;check for button A pulse
	BEQ subProcessJeepState

	;Grenade/bazooka launch
+:	LDA JeepMainWeaponState,X
	BNE subProcessJeepState
	LDA #$05 ;bazooka
	LDY JeepMainWeapon,X
	BNE +
	LDA #$01 ;Grenade
+:	STA JeepMainWeaponState,X
	LDA JeepHorizScreenPosition,X
	STA JeepMainWeaponHorizScreenPosition,X
	LDA JeepVertScreenPosition,X
	STA JeepMainWeaponVertScreenPosition,X
	
;X contains the player (00 = player 1, 01 = Player 2)
subProcessJeepState:
	LDA JeepState,X
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses

	dw JeepDeadState ;Jeep State 00 - Dead
	dw JeepNormalState ;Jeep State 01 - Normal
	dw JeepCollisionState ;Jeep State 02 - Collision is detected that results in death
	dw JeepExplodingState ;Jeep State 03 - Explosion animation is occurring
	dw JeepWaitingToRespawn ;Jeep State 04 - Respawn delay 
	
JeepDeadState:
	;This code runs on respawn
	LDA #JeepIFrameValueAfterDeath ;I-Frame count after death (for both jeeps)
	STA JeepIFrameTimer,X ;the only location (in vanilla game) where the I-Frame timer is set
	LDA #$01
	STA JeepFacingDirection,X
	LDA #JeepPOWDropoffDelayNextValue ;Load Default wait for next POW to unload from the jeep to the heli
	STA JeepPOWDropoffDelay,X
	LDA #$01
	STA JeepTypeIndex,X
	LDA #$00
	STA JeepAttributes,X
	LDA tblJeepPalette,X
	STA JeepGraphicsAttributes,X	
	INC JeepState,X ;Set the state to 01 = normal
	RTS
	
tblJeepPalette:
	db $00 ;Jeep 1 Palette
	db $01 ;Jeep 2 Palette
	
tblJeepTendencyDirectionValue_DPadPressed:
	db $01 ;00 Should never occur (value of 0 means no Dpad is pressed, but we're here..)
	db $03 ;01 Right only
	db $07 ;02 Left only
	db $00 ;03 INVALID - Right/Left simultaneously
	db $05 ;04 Down only
	db $04 ;05 Down + Right
	db $06 ;06 Down + Left
	db $00 ;07 INVALID Down + Right/Left simultaneously
	db $01 ;08 Up only
	db $02 ;09 Up + Right
	db $08 ;0A Up + Left
	db $00 ;0B INVALID Up + Right/Left simultaneously
	db $00 ;0C INVALID Up/Down simultaneously
	db $00 ;0D INVALID Up/Down simultaneously + Right
	db $00 ;0E INVALID Up/Down simultaneously + Left
	db $00 ;0F INVALID Up/Down simultaneously + Right/Left simultaneously

JeepNormalState:
	;********************
	;POW Drop off Section
	;********************
	LDA JeepAtHelipadDropoff,X
	BEQ ++
	;A jeep is at the helipad to drop off POWs
	LDA JeepPOWCount,X
	BEQ ++
	;A Jeep has at least 1 POW to unload
	DEC JeepPOWDropoffDelay,X 
	BNE ++
	;It is time to unload a POW
	LDA #$A7 ;POW Loading Into Heli ID
	STA $08
	STX $09
	STX $35
	JSR subSpawnObjectFromParent_NoOffset ;Spawn POW walking to heli on pad
	CPY #$FF ;Indicates no available sprite slot
	BEQ +++ ;Skip the below if the POW never spawned
	DEC JeepPOWCount,X
	INC JeepPOWHeliDropOffCount,X
	;Get an extra life for X POWs dropped off
	LDA JeepPOWHeliDropOffCount,X
	AND #$0F
	CMP #$0A
	BCC +
	LDA JeepPOWHeliDropOffCount,X
	
-:	CLC
	ADC #$06
	STA JeepPOWHeliDropOffCount,X
+:	CMP #$04
	BEQ +
	CMP #$09
	BEQ +
	CMP #$15
	BNE +++
+:	LDA JeepMainWeapon,X
	CMP #$03
	BCS +++
	INC JeepMainWeapon,X
	LDA #WeaponUpgradeSoundClip
	JSR subInitiateSoundClip
	
+++:	LDA #JeepPOWDropoffDelayInitValue
	STA JeepPOWDropoffDelay,X
++:	LDA JeepIFrameTimer,X
	BEQ +
	DEC JeepIFrameTimer,X	
	BNE ++
	LDA tblJeepPalette,X ;Reset to the default palette after invulnerability gone
	STA JeepGraphicsAttributes,X
	JMP +
++:	INC JeepGraphicsAttributes,X ;Flash the jeep while invulnerable
	LDA JeepGraphicsAttributes,X
	CMP #$04 ;wrap around to use palettes 0-3
	BNE +
	LDA #$00
	STA JeepGraphicsAttributes,X
+:	JSR subSetJeepSpeedToZero
	LDA JeepHorizPosition,X
	STA JeepHorizScreenPosition,X
	LDA JeepVertPosition,X
	STA JeepVertScreenPosition,X
	LDA JeepControlsInput,X
	AND #(UpDPad + LeftDPad + RightDPad + DownDPad)
	BEQ +++ ;No DPad pressed at all
	TAY ;At least one DPad pressed
	LDA tblJeepTendencyDirectionValue_DPadPressed,Y
	CMP JeepFacingDirection,X
	BEQ ++
	STA JeepDirectionTendency,X ;Pushing a direction that the jeep is not currently facing
	JMP +
++:	STA JeepDirectionTendency,X
	STA JeepFacingDirection,X
+:	TYA
+++:	
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	dw NoDPad_Invalid
	dw RightDPad_Pressed
	dw LeftDPad_Pressed
	dw NoDPad_Invalid ;Right and Left simultaneously
	dw DownDPad_Pressed
	dw DownRightDPad_Pressed
	dw DownLeftDPad_Pressed
	dw NoDPad_Invalid ;Right and Left simultaneously
	dw UpDPad_Pressed
	dw UpRightDPad_Pressed
	dw UpLeftDPad_Pressed
	dw NoDPad_Invalid ;Right and Left simultaneously
	dw NoDPad_Invalid 
	dw NoDPad_Invalid
	dw NoDPad_Invalid
	dw NoDPad_Invalid

subSetJeepSpeedToZero:	LDA #$00
	STA JeepVertSpeedUB,X
	STA JeepVertSpeedLB,X
subSetJeepVerticalSpeedToZero_Escalator:
	LDA #$00
	STA JeepHorizSpeedUB,X
	STA JeepHorizSpeedLB,X
	RTS

table11: ;some kind of collision offsets
	db $FC,$F8,$04,$F8 ;Moving Up
	db $00,$FA,$06,$00 ;Moving Up-Right
	db $08,$FC,$08,$04 ;Moving Right
	db $06,$00,$00,$06 ;Moving Down-Right
	db $FC,$08,$04,$08 ;Moving Down
	db $FA,$00,$00,$06 ;Moving Down-Left
	db $F8,$FC,$F8,$04 ;Moving Left
	db $FA,$00,$00,$FA ;Moving Up-Left
	
Label1186:	
	LDA JeepDirectionTendency,X ;01 = UP, 08 = Up Left (increments clockwise)
	SEC
	SBC #01 ;Convert 1-8 to 0-7
	ASL A
	ASL A
	TAY
	STY $D8
	LDA #$00
	STA JeepMovementState ;Set flag, jeep is moving normally

	LDA CurrentLevel
	CMP #$03
	BNE ++
	INC JeepMovementState ;Set jeep movment speed to half - in water
	LDA #$00
	STA $16
	STA $17
	JSR fctGetCollisionTypeFromRAM300_4FF
	CMP #$03 ;This is the last collision group
	BNE ++ ;This section is only concerned with the last collision group for splashing in water
	LDA JeepState,X
	CMP #$02
	BCS +
	LDA RNG_INCEveryFrame
	AND #$07
	BNE +
	INC JeepTypeIndex,X ;This displays the water splash graphic during movement
	LDA RNG_INCEveryFrame
	AND #$0F
	BNE +
	LDA #WaterSplashSoundClip
	JSR subInitiateSoundClip
+:	LDA JeepHorizSpeedUB,X
	BPL +++
	LDA #JeepSpeedLeft_RightInWaterLB
	STA JeepHorizSpeedLB,X
	BNE +
+++:	LSR JeepHorizSpeedUB,X
	ROR JeepHorizSpeedLB,X
+:	LDA JeepVertSpeedUB,X
	BPL +
	LDA #JeepSpeedUp_DownInWaterLB
	STA JeepVertSpeedLB,X
	BNE ++
+:	LSR JeepVertSpeedUB,X
	ROR JeepVertSpeedLB,X
++:	LDY JeepMovementDirection
	LDA table11,Y
	STA $16
	LDA (table11 + 1),Y
	STA $17
	JSR fctGetCollisionTypeFromRAM300_4FF
	BEQ +
	LDY JeepMovementState
	BEQ ++
	CMP #$03
	BNE ++
+:	LDY JeepMovementDirection
	LDA (table11 + 2),Y
	STA $16
	LDA (table11 + 3),Y
	STA $17
	JSR fctGetCollisionTypeFromRAM300_4FF
	BEQ +++
	LDY JeepMovementState
	BEQ ++
	CMP #$03
	BEQ +++
++:	LDA JeepEscalatorEffectActive,X
	BEQ +
	JSR subSetJeepVerticalSpeedToZero_Escalator
	JMP ++
+:	JSR subSetJeepSpeedToZero
+++:	LDA JeepEscalatorEffectActive,X
	BNE ++
--:
	LDA JeepHorizScreenPositionSubPixel,X
	CLC
	ADC JeepHorizSpeedLB,X
	STA JeepHorizScreenPositionSubPixel,X
	LDA JeepHorizPosition,X
	ADC JeepHorizSpeedUB,X
	STA JeepHorizScreenPosition,X
	STA JeepHorizPosition,X
	
	LDA JeepVertScreenPositionSubPixel,X
	CLC
	ADC JeepVertSpeedLB,X
	STA JeepVertScreenPositionSubPixel,X
	LDA JeepVertPosition,X
	ADC JeepVertSpeedUB,X
	STA JeepVertScreenPosition,X
	STA JeepVertPosition,X
	LDA JeepState,X
	CMP #$02
	BCS +
	LDA RNG_INCEveryFrame
	AND #$04
	BNE +
	INC JeepVertScreenPosition,X ;move jeep down on escalator, Level 6 Escalator
+:	RTS 
++:	LDA JeepVertSpeedUB,X 
	BMI + 
	BNE -- 
-:	LDA #$80 ;your speed is set to half pixel per frame downard when you die on an escalator, Level 6 Escalator
	STA JeepVertSpeedLB,X
	BNE --
+:	LDA #$80
	BNE -
NoDPad_Invalid:
	LDA JeepFacingDirection,X
	STA JeepDirectionTendency,X
	LDA JeepEscalatorEffectActive,X
	BEQ ++ 
	LDA RNG_INCEveryFrame
	LSR 
	BCS + 
	INC JeepVertScreenPosition,X ;escalator causes your jeep to move downard, Level 6 Escalator
	INC JeepVertPosition,X ;escalator causes your jeep to move downard, Level 6 Escalator
	RTS
	;Jeep sitting motionless in water splash graphic
++:	LDA CurrentLevel
	CMP #$03 ;Level 4 has water splahes tiles on all screens
	BNE +
++:	LDA #$00
	STA $16
	STA $17
	JSR fctGetCollisionTypeFromRAM300_4FF
	CMP #$03 
	BNE + 
	LDA RNG_INCEveryFrame
	AND #$07
	BNE +
	LDA JeepTypeIndex,X
	INC JeepTypeIndex,X 
	LSR
	BCS +
	DEC JeepTypeIndex,X
	DEC JeepTypeIndex,X
+:	RTS

LeftDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #$02
	STA JeepVisibleFrameTimer,X
	LDA #JeepSpeedLeft
-:	STA JeepHorizSpeedUB,X
	JMP Label1186
	
RightDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #$00
	STA JeepVisibleFrameTimer,X
	LDA #$01
	BNE -

UpDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #$00
	STA JeepVisibleFrameTimer,X
--:	LDA #JeepSpeedUp
---:	STA JeepVertSpeedUB,X
	JMP Label1186

DownDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #JeepSpeedDown
	STA JeepVisibleFrameTimer,X
-:	LDA #JeepSpeedDown
	BNE ---

DownRightDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #$01
	STA JeepVisibleFrameTimer,X
	LDA #JeepSpeedRight
	STA JeepHorizSpeedUB,X
	BNE - ;process Down press

DownLeftDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #$03
	STA JeepVisibleFrameTimer,X
	LDA #JeepSpeedLeft
	STA JeepHorizSpeedUB,X
	BNE - ;process Down press

UpRightDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #$00
	STA JeepVisibleFrameTimer,X
	LDA #JeepSpeedRight
	STA JeepHorizSpeedUB,X
	BNE -- ;process Up press

UpLeftDPad_Pressed:
	JSR subRotateJeepTowardsDirectionOfMotion
	LDA #$02
	STA JeepVisibleFrameTimer,X
	LDA #JeepSpeedLeft
	STA JeepHorizSpeedUB,X
	BNE -- ;process Up press

;This routine slowly turns the jeep towards the direction it is moving.
;;For instance, if the jeep is facing up, but you press right,
;;the jeep moves, turns to up-right, moves, then faces right
subRotateJeepTowardsDirectionOfMotion:
	LDA RNG_INCEveryFrame
	AND #$03
	BNE ++++++ ;RTS
	LDA JeepFacingDirection,X
	SEC
	SBC JeepDirectionTendency,X
	BEQ ++
	STA $00
	BCC +++
	LDA $00
	BPL +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP #$04
	BCS +++++
	BCC ++++
+++:	LDA $00
	BPL +
	EOR #$FF
	CLC
	ADC #$01
+:	CMP #$04
	BCS ++++
+++++:	INC JeepFacingDirection,X
	LDA JeepFacingDirection,X
	CMP #$09
	BCC ++
	LDA #$01
	BNE +
++++:	DEC JeepFacingDirection,X
	LDA JeepFacingDirection,X
	BNE ++
	LDA #$08
+:	STA JeepFacingDirection,X
++:	LDY JeepFacingDirection,X
	DEY
	TYA
	ASL
	TAY
	LDA tblJeepSpriteDirectionalDrawing,Y
	STA JeepTypeIndex,X
	LDA (tblJeepSpriteDirectionalDrawing + 1),Y
	STA JeepAttributes,X
++++++:	RTS
	JSR subSetJeepSpeedToZero
	LDA #$03
	STA JeepVisibleFrameTimer,X
	LDA #$00
	STA JeepFacingDirection,X
	INC JeepState,X
--:	JMP Label1186
	DEC JeepVisibleFrameTimer,X
	BNE --
	LDA #$03
	STA JeepVisibleFrameTimer,X
	LDA JeepFacingDirection,X
	AND #$0F
	TAY
	LDA tblJeepSpriteDirectionalDrawing,Y
	STA JeepTypeIndex,X
	INY
	LDA tblJeepSpriteDirectionalDrawing,Y
	STA JeepAttributes,X
	LDA JeepFacingDirection,X
	CLC
	ADC #$02
	STA JeepFacingDirection,X
	CMP #$40
	BCC --
Label1202:	INC JeepState,X
	JMP Label1186
	
JeepCollisionState:
	LDA #$00 ;Reset the main weapon to the grenade for the player that died
	STA JeepMainWeapon,X
	;Recalculate difficulty
	LDA Jeep1MainWeapon
	CLC
	ADC Jeep2MainWeapon
	CMP #$03
	BCC +
	LDA #$03
+:	STA DifficultyBasedOnWeapon
	;Check for both players dead
	LDA Jeep1LifeCount
	CLC
	ADC Jeep2LifeCount
	CMP #$01 ;Only 1 jeep alive with 1 life left, so this death means game over
	BNE +
	;This actually causes a glitch where the player can throw a grenade, die,
	;;and have the grenade give the player enough points to get an extra life.
	;;This means the music for the level stops, but the game is not over
	JSR subStopMusic 
+:	LDA #JeepDeathSoundClip
	JSR subInitiateSoundClip
	JSR subSetJeepSpeedToZero
	LDA #$A8 ;Walking POW object ID
	STA $08
	TXA
	STA $09
	LDA JeepPOWCount,X
	STA $0B
	STX $35
	JSR subSpawnObjectFromParent_NoOffset ;Spawns POWs, if the jeep carries any, on death
	LDA #$00
	STA JeepPOWCount,X
	LDA #$19 ;small explosion graphic
	STA JeepTypeIndex,X
	LDA #$03
	STA JeepGraphicsAttributes,X
	LDA #$06 ;number of frames to display jeep explosion step 1 graphic
	STA JeepVisibleFrameTimer,X
	BNE Label1202

JeepExplodingState:	
	DEC JeepVisibleFrameTimer,X
	BNE --
	LDA #$06 ;number of frames to display subsequent explosion graphics
	STA JeepVisibleFrameTimer,X
	INC JeepTypeIndex,X
	LDA JeepTypeIndex,X
	CMP #$1C ;The last explosion (large) graphics is 1B.  1C means it's done exploding
	BCC +
	LDA #$00 ;after explosion show nothing until respawn of jeep
	STA JeepTypeIndex,X
	LDA #$60 ;number of frames to displaly nothing before jeep respawns after being blown up
	STA JeepVisibleFrameTimer,X
	BNE Label1202
+:
-:	JMP --

JeepWaitingToRespawn:
	DEC JeepVisibleFrameTimer,X
	BNE -
	LDA #$00
	STA JeepState,X
	DEC JeepLifeCount,X
	LDA #$01
	STA $1F
	RTS

tblJeepSpriteDirectionalDrawing:	
	;Up
	db $01 ;Sprite manifestation index
	db $00 ;Sprite attributes (mirroring)
	
	;Up-Right
	db $03 ;Sprite manifestation index
	db $00 ;Sprite attributes (mirroring)
	
	;Right
	db $05 ;Sprite manifestation index
	db $00 ;Sprite attributes (mirroring)
	
	;Down-Right
	db $03 ;Sprite manifestation index
	db $80 ;Sprite attributes (mirroring)
	
	;Down
	db $01 ;Sprite manifestation index
	db $80 ;Sprite attributes (mirroring)
	
	;Down-Left
	db $03 ;Sprite manifestation index
	db $C0 ;Sprite attributes (mirroring)
	
	;Left
	db $05 ;Sprite manifestation index
	db $40 ;Sprite attributes (mirroring)
	
	;Up-Left
	db $03 ;Sprite manifestation index
	db $40 ;Sprite attributes (mirroring)
	
subProcessJeepBullet:
	;This code must remain here as the sound clip routine changes the bank
	LDA JeepBulletState,X
	BEQ +
	CMP #$03
	BEQ JeepBulletState3
	CMP #$02
	BEQ JeepBulletState2
	LDA #BulletBeingFiredSoundClip
	JSR subInitiateSoundClip
	LDA #$10
	STA JeepBulletTypeIndex,X
	LDA #$01
	STA JeepBulletGraphicsAttributes,X
	JSR subZeroOutSpriteSpeed
	LDA #$FA
	STA JeepBulletVertSpeedUB,X
	LDA #$10
+++:	STA JeepBulletDisplayFrames,X
	INC JeepBulletState,X
+:	RTS

JeepBulletState2:
	LDA CurrentLevel
	CMP #$05
	BNE +
	LDA CurrentLevelScreen
	CMP #$0D
	BCS ++
+:	JSR Label1210
	LDY CurrentLevel
	CPY #$03
	BNE +
	CMP #$03
	BEQ ++
+:	LSR
	BCS +
++:	DEC JeepBulletDisplayFrames,X
	BNE ++
+:	LDA #JeepBulletHitGroundFrameCount ;Load the #frames to show the bullet hitting the ground graphic
	STA JeepBulletDisplayFrames,X
	INC JeepBulletTypeIndex,X
	INC JeepBulletState,X
	JSR subZeroOutSpriteSpeed
++:	JSR subUpdateGrenade_Bazooka_BulletPositionForSpeed
-:	LDA JeepBulletHorizScreenPosition,X
	CMP #$FA
	BCS +
	LDA JeepBulletVertScreenPosition,X
	CMP #$FA
	BCS +
	JMP subUpdateGrenade_Bazooka_BulletPositionForScroll

JeepBulletState3:
	DEC JeepBulletDisplayFrames,X
	BNE -
+:	JMP Label1055 ;despawn bullet on end of life

subProcessJeepMainWeapon:
	LDA JeepMainWeaponState,X ;Load main weapon state
	BEQ JeepMainWeaponState0 ;RTS
	JSR subExecuteCodeViaIndirectJump ;A has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	dw JeepMainWeaponState0 ;RTS
	
	dw JeepGrenadeState0 ;1 Init
	dw JeepGrenadeState1 ;2 In flight
	dw JeepGrenadeState2 ;3 collision detected
	dw JeepGrenadeState3 ;4 exploding
	
	dw JeepBazookaState0 ;5 Init
	dw JeepBazookaState1 ;6 In flight
	dw JeepBazookaState2 ;7 collision detected
	dw JeepBazookaState3 ;8 exploding
	
	dw JeepBazookaSplashState0 ;9 Init
	dw JeepBazookaSplashState1 ;A Splash in flight
	dw JeepBazookaSplashState2 ;B Despawn

tblGrenadeSpeed:
	;NULL direction 
	db $00 ;horiz speed UB
	db $00 ;horiz speed LB
	db $00 ;Vert speed UB
	db $00 ;Vert speed LB
	;Up direction 
	db $00 ;horiz speed UB
	db $00 ;horiz speed LB
	db $FE ;Vert speed UB
	db $00 ;Vert speed LB
	;Up Right direction 
	db $01 ;horiz speed UB
	db $80 ;horiz speed LB
	db $FE ;Vert speed UB
	db $80 ;Vert speed LB
	;Right direction 
	db $02 ;horiz speed UB
	db $00 ;horiz speed LB
	db $00 ;Vert speed UB
	db $00 ;Vert speed LB
	;Down Right direction 
	db $01 ;horiz speed UB
	db $80 ;horiz speed LB
	db $01 ;Vert speed UB
	db $80 ;Vert speed LB
	;Down direction 
	db $00 ;horiz speed UB
	db $00 ;horiz speed LB
	db $02 ;Vert speed UB
	db $00 ;Vert speed LB
	;Down Left direction 
	db $FE ;horiz speed UB
	db $80 ;horiz speed LB
	db $01 ;Vert speed UB
	db $80 ;Vert speed LB
	;Left direction 
	db $FE ;horiz speed UB
	db $00 ;horiz speed LB
	db $00 ;Vert speed UB
	db $00 ;Vert speed LB
	;Up left direction 
	db $FE ;horiz speed UB
	db $80 ;horiz speed LB
	db $FE ;Vert speed UB
	db $80 ;Vert speed LB

JeepGrenadeState0:
	LDA #GrenadeThrow_BombSoundClip
	JSR subInitiateSoundClip
	LDA #$07 ;base grenade render index
	STA JeepMainWeaponTypeIndex,X
	LDA #$00 ;green grenade
	STA JeepMainWeaponGraphicsAttributes,X	
	LDA JeepDirectionTendency,X
	ASL
	ASL
	TAY
	LDA tblGrenadeSpeed,Y
	STA JeepMainWeaponHorizSpeedUB,X
	LDA (tblGrenadeSpeed + 1),Y
	STA JeepMainWeaponHorizSpeedLB,X
	LDA (tblGrenadeSpeed + 2),Y
	STA JeepMainWeaponVertSpeedUB,X
	LDA (tblGrenadeSpeed + 3),Y
	STA JeepMainWeaponVertSpeedLB,X
	LDA #$28
	LDY ScreenVerticalScrollLockForBossFight
	BEQ +
	LDY CurrentLevel
	CPY #$05 ;Level 6
	BNE +
	LDA #$32 ;Increase the range of your grenade to reach the huge tank
+:	STA JeepMainWeaponTimer,X
	INC JeepMainWeaponState,X ;increase main weapon object state

JeepMainWeaponState0:
+++:	RTS

JeepBazookaSplashState1:
	LDY #$0A
	LDA JeepMainWeaponTimer,X
	CMP #$18
	BCS ++
	CMP #$08
	BCS +
	INY
+:	TYA
	STA JeepMainWeaponTypeIndex,X
++:	LDA RNG_INCEveryFrame
	AND #$03
	BNE +
	LDA JeepMainWeaponAttributes,X
	EOR #$80
	STA JeepMainWeaponAttributes,X
+:	LDY #$01
	LDA CurrentLevelScreenSubPosition
	SEC
	SBC PreviousLevelScreenSubposition
	BEQ +
	BCS ++
	LDY #$00
+:	DEY
++:	STY $10
	LDY #$01
	LDA ScreenLeftScrollPosition
	SEC
	SBC ScreenHorizontalScrollPosition_PPU
	BEQ +
	BCC ++
	LDY #$00
+:	DEY
++:	STY $11
	LDA (JeepHorizBazookaSplashHorizOffset - 2),X ;minus 2 due to the offset of X
	CLC
	ADC $11
	STA (JeepHorizBazookaSplashHorizOffset - 2),X ;minus 2 due to the offset of X
	STA JeepMainWeaponHorizScreenPosition,X
	LDA (JeepHorizBazookaSplashVertOffset - 2),X ;minus 2 due to the offset of X
	CLC
	ADC $10
	STA (JeepHorizBazookaSplashVertOffset - 2),X ;minus 2 due to the offset of X
	STA JeepMainWeaponVertScreenPosition,X
	LDA #$00
	STA $10
	STA $11
	LDA JeepMainWeaponHorizSpeedUB,X
	BEQ +++
	CLC
	ADC #$02
	STA $10
	LDY $9A,X
	BEQ ++
	LDY #$00
	EOR #$FF
	CLC
	ADC #$01
	JMP +
++:	LDY #$01
+:	STY $9A,X
	STA JeepMainWeaponHorizSpeedUB,X
+++:	LDA JeepMainWeaponVertSpeedUB,X
	BEQ +++
	CLC
	ADC #$02
	STA $11
	LDY $A2,X
	BEQ ++
	LDY #$00
	EOR #$FF
	CLC
	ADC #$01
	JMP +
++:	LDY #$01
+:	STY $A2,X
	STA JeepMainWeaponVertSpeedUB,X
+++:	JSR subUpdateGrenade_Bazooka_BulletPositionForSpeed
	LDA $10
	STA JeepMainWeaponHorizSpeedUB,X
	LDA $11
	STA JeepMainWeaponVertSpeedUB,X
	JMP Label1233
	
JeepBazookaState1:
	LDA CurrentLevel
	CMP #$04 ;Level 5
	BNE +
	LDA ScreenVerticalScrollLockForBossFight
	BNE Label1235
	BEQ ++
+:	CMP #$05 ;Level 6
	BNE ++
	;level = 6
	LDA CurrentLevelScreen
	CMP #$0D ;Level 6 has 14 screens.  the other levels have 12
	BCS Label1235
++:	JSR Label1210 ;Get Collision Type
	LDY CurrentLevel
	CPY #$03 ;Level 4
	BEQ +++
	CPY #$05 ;Level 6
	BNE ++
+++:	CMP #$03 ;Special collision type
	BEQ Label1235
++:	LSR ;Collide on type 01 and 03
	BCC Label1235
	INC JeepMainWeaponState,X
-:	RTS
	
;Used to make the grenade change shape/mirroring (vert/horiz)
;;to make it look like it was thrown
tblGrenadeThrowMirroringAnimation:
	db $00,$80,$40,$C0

JeepGrenadeState1:
	LDA RNG_INCEveryFrame
	AND #$0F ;Change grenade mirroring every 4 random frames
	LSR
	LSR
	TAY
	LDA tblGrenadeThrowMirroringAnimation,Y
	STA JeepMainWeaponAttributes,X
	LDA #$07
	LDY JeepMainWeaponTimer,X
	CPY #$1A
	BCS +
	CPY #$0E
	BCC +
	LDA #$08
+:	STA JeepMainWeaponTypeIndex,X
Label1235:	JSR subUpdateGrenade_Bazooka_BulletPositionForSpeed
Label1233:	JSR subUpdateGrenade_Bazooka_BulletPositionForScroll
	LDA JeepMainWeaponHorizScreenPosition,X
	CMP #MainWeaponXMin
	BCC ++
	CMP #MainWeaponXMax
	BCS ++
	LDA JeepMainWeaponVertScreenPosition,X
	CMP #MainWeaponYMin
	BCC ++
	CMP #MainWeaponYMax
	BCS ++
	DEC JeepMainWeaponTimer,X ;Decrement lifetime for main weapon flight
	BNE +++ ;RTS
	BEQ ++
	
JeepBazookaState2:
	LDA #BazookaHitGroundSoundClip
	JSR subInitiateSoundClip
	LDY JeepMainWeapon,X
	CPY #$02 ;0=grenade, 1=bazooka, 2=baz + horiz splash, 3=baz + horiz/vert splash
	BCC + ;no splash
	;Bazooka Splash
	DEY ;Y is a 1 for horiz splash only.  2 for both splashes
	STY $10 ;why need $10 here?  why can't use Y only?
	LDA #$09
	STA JeepHorizBazookaSplashState,X
	
	;Spawn the horizontal splash where the bazooka exploded
	LDA JeepMainWeaponHorizScreenPosition,X
	STA JeepHorizBazookaSplashHorizScreenPosition,X
	LDA JeepMainWeaponVertScreenPosition,X
	STA JeepHorizBazookaSplashVertScreenPosition,X
	
	LDA #$00
	STA $0766,X
	DEC $10
	BEQ +
	LDA #$09
	STA JeepVerticalBazookaSplashState,X
	
	;Spawn the vertical splash where the bazooka exploded
	LDA JeepMainWeaponHorizScreenPosition,X
	STA JeepVertBazookaSplashHorizScreenPosition,X
	LDA JeepMainWeaponVertScreenPosition,X
	STA JeepVertBazookaSplashVertScreenPosition,X
	
	LDA #$01
	STA $0768,X
	BNE +
	
JeepGrenadeState2:
	LDA #BlackAndWhiteMissile_Bomb_LaserBlastHitsGroundSoundClip
	JSR subInitiateSoundClip
+:	JSR subUpdateGrenade_Bazooka_BulletPositionForScroll
	JSR subZeroOutSpriteSpeed
	LDA #$19 ;1st explosion graphic
	STA JeepMainWeaponTypeIndex,X
	LDA #$03 ;Choose explosion palette
	STA JeepMainWeaponGraphicsAttributes,X
	LDA #$08
	STA JeepMainWeaponTimer,X
++:	INC JeepMainWeaponState,X
+++:
-:	RTS

JeepBazookaState3:
JeepGrenadeState3:
	JSR subUpdateGrenade_Bazooka_BulletPositionForScroll
	DEC JeepMainWeaponTimer,X
	BNE - ;RTS
	LDA #$08
	STA JeepMainWeaponTimer,X
	INC JeepMainWeaponTypeIndex,X
	LDA JeepMainWeaponTypeIndex,X
	CMP #$1C ;The last explosion (large) graphics is 1B.  1C means its done exploding
	BNE - ;RTS
	
JeepBazookaSplashState2:	
	JMP Label1055 ;despawn bullet
	
JeepBazookaState0:
	LDA JeepDirectionTendency,X
	ASL
	TAY
	LDA (tblBazookaDirections - 2),Y ;-2 and -1 because direction is 1-8 not 0-7.
	STA JeepMainWeaponTypeIndex,X
	LDA (tblBazookaDirections - 1),Y
	STA JeepMainWeaponAttributes,X
	LDA #BazookaLaunchSoundClip
	JSR subInitiateSoundClip
	LDA #$01
	STA JeepMainWeaponGraphicsAttributes,X
	LDA JeepDirectionTendency,X
	ASL
	ASL
	TAY
	LDA tblBazookaSpeed,Y
	STA JeepMainWeaponHorizSpeedUB,X
	LDA (tblBazookaSpeed + 1),Y
	STA JeepMainWeaponHorizSpeedLB,X
	LDA (tblBazookaSpeed + 2),Y
	STA JeepMainWeaponVertSpeedUB,X
	LDA (tblBazookaSpeed + 3),Y
	STA JeepMainWeaponVertSpeedLB,X
	LDA #$16
	LDY ScreenVerticalScrollLockForBossFight
	BEQ +
	LDY CurrentLevel
	CPY #$05 ;level 6
	BNE +
	LDA #$20 ;increase the bazooka range to fight the huge tank
+:	STA JeepMainWeaponTimer,X
	INC JeepMainWeaponState,X
	RTS

tblBazookaDirections:	
	;Up
	db $0D ;Veritcal bazooka sprite
	db $00 ;no mirroring
	
	;Up-Right
	db $0E ;Diagonal bazooka sprite
	db $00 ;no mirroring
	
	;Right
	db $0F ;Horizontal bazooka sprite
	db $00 ;no mirroring
	
	;Down-Right
	db $0E ;Diagonal bazooka sprite
	db $80 ;mirror vertically
	
	;Down
	db $0D ;Veritcal bazooka sprite
	db $80 ;mirror vertically
	
	;Down-Left
	db $0E ;Diagonal bazooka sprite
	db $C0 ;mirror vertically and horizontally
	
	;Left
	db $0F ;Horizontal bazooka sprite
	db $40 ;mirror horizontally
	
	;Up-Left
	db $0E ;Diagonal bazooka sprite
	db $40 ;mirror horizontally
	
tblBazookaSpeed:
	;NULL direction 
	db $00 ;horiz speed UB
	db $00 ;horiz speed LB
	db $00 ;Vert speed UB
	db $00 ;Vert speed LB
	;Up direction 
	db $00 ;horiz speed UB
	db $00 ;horiz speed LB
	db $FC ;Vert speed UB
	db $00 ;Vert speed LB
	;Up Right direction 
	db $02 ;horiz speed UB
	db $C0 ;horiz speed LB
	db $FD ;Vert speed UB
	db $40 ;Vert speed LB
	;Right direction 
	db $04 ;horiz speed UB
	db $00 ;horiz speed LB
	db $00 ;Vert speed UB
	db $00 ;Vert speed LB
	;Down Right direction 
	db $02 ;horiz speed UB
	db $C0 ;horiz speed LB
	db $02 ;Vert speed UB
	db $C0 ;Vert speed LB
	;Down direction 
	db $00 ;horiz speed UB
	db $00 ;horiz speed LB
	db $04 ;Vert speed UB
	db $00 ;Vert speed LB
	;Down Left direction 
	db $FD ;horiz speed UB
	db $40 ;horiz speed LB
	db $02 ;Vert speed UB
	db $C0 ;Vert speed LB
	;Left direction 
	db $FC ;horiz speed UB
	db $00 ;horiz speed LB
	db $00 ;Vert speed UB
	db $00 ;Vert speed LB
	;Up left direction 
	db $FD ;horiz speed UB
	db $40 ;horiz speed LB
	db $FD ;Vert speed UB
	db $40 ;Vert speed LB

JeepBazookaSplashState0:
	LDA #$03
	STA JeepMainWeaponGraphicsAttributes,X
	LDA #$09
	STA JeepMainWeaponTypeIndex,X
	LDA #$28 ;# frames before bazooka horiz/vert splash disappears, bazooka splash lifetime
	STA JeepMainWeaponTimer,X
	LDA #$00
	STA JeepMainWeaponHorizSpeedUB,X
	STA JeepMainWeaponHorizSpeedLB,X
	STA JeepMainWeaponVertSpeedUB,X
	STA JeepMainWeaponVertSpeedLB,X
	LDA JeepMainWeaponHorizScreenPosition,X
	STA (JeepHorizBazookaSplashHorizOffset - 2),X ;minus 2 due to the offset of X
	LDA JeepMainWeaponVertScreenPosition,X
	STA (JeepHorizBazookaSplashVertOffset - 2),X ;minus 2 due to the offset of X
	LDA $0764,X ;(accesses 0766 - 0769)
	BNE +
	LDA #$02
	STA JeepMainWeaponHorizSpeedUB,X
	LDA #$00
	STA JeepMainWeaponHorizSpeedLB,X
	INC JeepMainWeaponState,X
	RTS
+:	LDA #$02
	STA JeepMainWeaponVertSpeedUB,X
	LDA #$00
	STA JeepMainWeaponVertSpeedLB,X
	INC JeepMainWeaponState,X
	RTS
	
Label978:
	LDA CurrentLevelScreen ;Load the vertical screen position (upper byte)
	CMP LastSpawnedEnemyY_HB ;Compare with the last vertical spawn position (upper byte)
	BCC +++  ;RTS - good coding: don’t check for new spawns if last spawn is greater than the current vertical position
	BNE + ;if the vertical screen position has crossed a full screen boundary and no spawns have occurred yet, branch
	LDA CurrentLevelScreenSubPosition ;Load the vertical screen position (lower byte), getting there means last spawn and current vertical screen are the same upper byte
	CMP LastSpawnedEnemyY_LB ;Compare with the last vertical spawn position (lower byte)
	BCC +++  ;RTS - good coding: don’t check for new spawns if last spawn is greater than the current vertical position
+:	LDA CurrentLevel ;Load the current level
	ASL ;Multiply by 2 for 16 bit values
	TAY
	LDA tblLevelObjectSpawnAddress,Y ;Load the beginning address for enemy spawn header addresses
	STA $02
	LDA (tblLevelObjectSpawnAddress + 1),Y
	STA $03
	LDA CurrentLevelScreen ;Load the vertical screen position (upper byte)
	ASL
	TAY
	LDA ($02),Y
	STA $00
	INY
	LDA ($02),Y
	STA $01
	LDY $36
	LDA ($00),Y ;Load vertical spawn position of sprite
	CMP #$EF ;Check for end of screen spawn table.  #$EE is the highest Y value on which a sprite can spawn.  
	BEQ EF_LastObjectLoadedForThisScreen
	CMP #$F0 ;Check for end of stage screen scroll (and then vertical scroll lock) effect
	BEQ F0_EndOfLevelScreenScrollObject ;one is ?
	CMP #$F1 ;Check for reloading default stage palette.  This is usually done after the helipad screens (which modifies the stages palette)
	BEQ F1_ReloadDefaultLevelPallete
	CMP #$F2 ;Check for loading new palettes and graphics.  Usually performed right before the level boss
	BEQ F2_LoadNewPalette_Graphics
	CMP CurrentLevelScreenSubPosition
	BNE +++ ;RTS ;Avoid re-spawning objects if the player scrolls downward
+:	STY $08
	INY ;Normal object spawns consume 3 bytes (x,y and object ID)
	INY	
+:	INY
	STY $36
	JSR fctGetNextOpenSpriteSlot
	BEQ ++ ;JSR returns FF if there are no sprites.  00 an open slot was found (00 returned from sprite init routine)
	LDY $08
	INY
	INY
	LDA ($00),Y
	BPL +
	JSR subDespawnLesserObjects_Offscreen_ForHighPriorityObjects
	BEQ ++
+:	LDY $36
-:	LDA ($00),Y
	CMP CurrentLevelScreenSubPosition
	BNE +
	INY
	INY
	INY
	JMP -
+:	STY $36
-:
+++:	RTS
++:	JMP Label1257

EF_LastObjectLoadedForThisScreen:	
	CMP CurrentLevelScreenSubPosition
	BNE - ;RTS
	LDA #$00
	STA $36
	RTS
	
F0_EndOfLevelScreenScrollObject: ;F0 Object
	INY
	LDA ($00),Y
	CMP CurrentLevelScreenSubPosition
	BNE - ;RTS
	JSR subStopMusic
	LDA #WeepWeepBossMusic_F0SoundClip
	JSR subInitiateSoundClip
	LDA #$01
	STA ScreenScrollingForF0ToBoss
	INY
	STY $36
	LDA CurrentLevelScreenSubPosition
	STA LastSpawnedEnemyY_LB
	LDA CurrentLevelScreen
	STA LastSpawnedEnemyY_HB
	JMP Label978
	
F1_ReloadDefaultLevelPallete:
	INY
	LDA ($00),Y
	CMP CurrentLevelScreenSubPosition
	BNE - ;RTS
	JSR subDisablePaletteFlash_LoadDefaultPalette
	INY
	STY $36
	LDA CurrentLevelScreenSubPosition
	STA LastSpawnedEnemyY_LB
	LDA CurrentLevelScreen
	STA LastSpawnedEnemyY_HB
	JMP Label978
	
F2_LoadNewPalette_Graphics:
	INY
	LDA ($00),Y
	CMP CurrentLevelScreenSubPosition
	BNE - ;RTS
	TYA
	PHA
	LDA #$00 ;F2 object overrides other updates?
	STA PPUGraphicsUpdateComplete
	LDY CurrentLevel
	LDA tblF2LevelIndex,Y
	STA PPUGraphicsUpdateTableIndex
	LDA tblLevelIndexForPPUGraphics_PalleteUpdateAddress,Y
	BEQ + ;No F2 object for this level
	JSR Label152
+:	PLA
	TAY
	INY
	STY $36
	LDA CurrentLevelScreenSubPosition
	STA LastSpawnedEnemyY_LB
	LDA CurrentLevelScreen
	STA LastSpawnedEnemyY_HB
	JMP Label978
	
	;$F15D
	
	;F2 Indices for the F2 header address table
	;This table selects an address from tblInGamePalette_GraphicsUpdateActionAddress
tblF2LevelIndex:
;Level  1   2   3   4   5   6
	db $00,$00,$01,$07,$02,$06

;This table makes it easier to grab the level update addresses
;;from the table above: tblPPUGraphics_PalleteUpdateAddress
tblLevelIndexForPPUGraphics_PalleteUpdateAddress:
;Level  1   2   3   4   5   6
	db $2D,$00,$2B,$00,$2C,$2E
	
Label1257:	;looks like this is where enemies spawn as the screen scrolls up in each level
	LDA CurrentLevelScreenSubPosition
	STA LastSpawnedEnemyY_LB
	LDA CurrentLevelScreen
	STA LastSpawnedEnemyY_HB
	LDY $08
	INY
	LDA ($00),Y ;Load the object horizontal position from the level's spawn table
	STA $08 ;store the data in the parameters for the object spawn routine
	BMI ++ ;branching here would indicate the object will spawn at the bottom of the screen instead of the top
	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	STA SpriteVertScreenPosition,X ;Set initial vertical position to the top of the screen
	JMP +
++:	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	LDA #$EF ;Set initial vertical position to the bottom of the screen
	STA SpriteVertScreenPosition,X
+:	LDA $08
	ASL
	ASL
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$00
	ADC #$00
	STA SpriteAbsoluteHorizPositionUB,X
	INY
	LDA ($00),Y ;Load the object's sprite value from level's spawn table
	STA SpriteObjectID,X
	LDA CurrentLevelScreenSubPosition ;Load the NEXT vertical screen scroll position (lower byte)(jeep is moving up)
	AND #$01 ;All ODD vertical position values only spawn when the players have upgraded weapons totally > 3 (HARD difficulty)
	BEQ +
	;Erase loaded sprite for odd Y values(make it easier on the player).  
	LDA DifficultyBasedOnWeapon
	CMP #$03
	BCS +
	LDA #$00 
	STA SpriteObjectID,X
+:	LDA SpriteObjectID,X
	AND #$7F
	TAY
	LDA tblEnemyHitBoxIndex,Y
	STA SpriteHitboxShapeIndex,X	
	LDA tblEnemyHealth,Y
	STA SpriteHealthHP,X
	LDA tblEnemyPoints_DeathState,Y
	LSR
	LSR
	LSR
	LSR
	STA EnemyPoints,X
	BEQ +
	;If both jeeps are alive, increase the value of each enemy, to offset
	;;the game play and Score gain for 2 players.
	LDA Jeep1State
	BEQ +
	LDA Jeep2State
	BEQ +
	INC EnemyPoints,X
+:	JMP Label978

;These are in Bank 6.  These tables define the spawn order, position and
;;Object ID for each object spawn on each level.
;;As the screen scrolls up, these tables spawn the objects at the appropriate Y coord
tblLevelObjectSpawnAddress:	
	dw tblLevel1ObjectSpawn
	dw tblLevel2ObjectSpawn
	dw tblLevel3ObjectSpawn
	dw tblLevel4ObjectSpawn
	dw tblLevel5ObjectSpawn
	dw tblLevel6ObjectSpawn
	
;This routine despawns an existing object, if all sprite slots are full,
;;to make from for high priority objects, like bosses or gates
;;Order of despawning:
;;1. Normal white/yellow bullets, and B/W or small missiles
;;2. ANY low priority object that is off screen
;;3. ANY low priority object
;;4. Slot 0 is chosen as a last resort if still no slot was found
subDespawnLesserObjects_Offscreen_ForHighPriorityObjects:
	LDX #$0F
-:	LDA SpriteObjectID,X
	BMI ++ ;MSB in object ID prevents despawning
	CMP #$36 ;Normal small bullet
	BEQ +
	CMP #$34 ;Flame
	BEQ +
	CMP #$39 ;B/W Missile and small missile
	BEQ +
	LDA SpriteState,X
	BMI + ;Object is offscreen, so it can be despawned
++:	DEX ;check next object
	BPL -
	;At this point, no slot has been found, so look for ANY low priority object to despawn
	LDX #$0F
-:	LDA SpriteObjectID,X
	BPL +
	DEX
	BPL -
	;At this point, no slot has been found, so we MUST have a slot.  Chosen 0 as default
	LDX #$00
+:	JSR subDespawnSprite

subInitSpriteDataZERO:
	LDA #$00
	STA SpriteState,X ;clear sprite state
	LDA #$00
	;All SpriteData values
	STA SpriteData1,X
	STA SpriteData2,X
	STA SpriteData3,X
	STA SpriteData4,X
	STA SpriteData5,X
	STA SpriteData6,X
	STA SpriteWhatDirectionToShoot,X
	STA SpriteData8,X
	STA SpriteWhichJeeptoAttack,X
	STA SpriteTypeIndex,X
	STA SpriteGraphicsAttributes,X
	STA SpriteAttributes,X ;$006A,X
	;I assume 5A0 is left out because the position is set on spawn??
	STA SpriteHorizScreenPositionSubPixel,X
	;I assume 560 is left out because the position is set on spawn??
	STA SpriteVertScreenPositionSubPixel,X
	;I assume 5E0,600,620,640 are left out because the position is set on spawn??

subClearSpriteSpeed:
	JSR subClearSpriteVertSpeed ;call sprite vertical speed reset.  Horiz reset is ran next as-is
	
subClearSpriteHorizSpeed:	
	LDA #$00 ;Part of sprite termination
	STA SpriteHorizSpeedLB,X ;Erase sprite horizontal speed lower byte
	STA SpriteHorizSpeedUB,X ;Erase sprite horizontal speed upper byte
	RTS

subClearSpriteVertSpeed:
	LDA #$00 ;Part of sprite termination
	STA SpriteVertSpeedLB,X ;Erase sprite vertical speed lower byte
	STA SpriteVertSpeedUB,X ;Erase sprite vertical speed upper byte
	RTS

;Looks for an open sprite slot to use
;;Returns the zero-based index if one exists, or #$FF if none
fctGetNextOpenSpriteSlot:
	LDX #$0F
-:	LDA SpriteObjectID,X
	BEQ subInitSpriteDataZERO ;if sprite slot isn't used
	DEX
	BPL -
	RTS
	
;spawn object from an existing object
subSpawnObjectFromParent_NoOffset:
	LDA #$00
	STA $00
	STA $01
	STA $02
	STA $03
subSpawnObjectFromParent_WithOffset:
	;Get the new horizontal spawn location given an offset from the parent
	LDA SpriteAbsoluteHorizPositionLB,X
	CLC
	ADC $00
	STA $04
	LDA SpriteAbsoluteHorizPositionUB,X
	ADC $01 ;Very important NOT to CLC here
	STA $05
	;Get the new vertical spawn location given an offset from the parent
	LDA SpriteVertScreenPosition,X
	CLC
	ADC $02
	STA $06
	LDA SpriteAbsoluteVertPositionUB,X
	ADC $03
	STA $07
	
	JSR fctGetNextOpenSpriteSlot
	BMI lblNoAvailableSpriteSlotsFound ;X will underflow to #$FF is no slot is found
	;X now contains the sprite slot
	LDA $04
	STA SpriteAbsoluteHorizPositionLB,X
	LDA $05
	STA SpriteAbsoluteHorizPositionUB,X
	LDA $06
	STA SpriteVertScreenPosition,X
	LDA $07
	STA SpriteAbsoluteVertPositionUB,X
	LDA $08
	STA SpriteObjectID,X
	AND #$7F
	TAY
	LDA tblEnemyHitBoxIndex,Y
	STA SpriteHitboxShapeIndex,X
	LDA tblEnemyHealth,Y
	STA SpriteHealthHP,X
	
	LDA tblEnemyPoints_DeathState,Y
	LSR
	LSR
	LSR
	LSR
	STA EnemyPoints,X
	BEQ +
	;If both jeeps are alive, increase the points value of each enemy, to offset
	;;the game play and Score gain for 2 players.
	LDA Jeep1State
	BEQ +
	LDA Jeep2State
	BEQ +
	INC EnemyPoints,X
	
+:	LDA $09
	STA SpriteData4,X
	LDA $0A
	STA SpriteData5,X
	LDA $0B
	STA SpriteData6,X
	LDA $0C
	STA SpriteWhatDirectionToShoot,X
	LDA $0D
	STA SpriteData8,X
	LDA $0E
	STA SpriteWhichJeeptoAttack,X
	LDA $0F
	AND #$0F
	STA SpriteGraphicsAttributes,X
	LDA $0F
	AND #$F0
	STA SpriteAttributes,X
	LDA $10
	STA SpriteData1,X
	LDA $11
	STA SpriteData2,X
	LDA $12
	STA SpriteData3,X
lblNoAvailableSpriteSlotsFound:
	TXA
	TAY
	LDX $35
	RTS		
	
	;L6 attack chopper, bomber, and L4 boss call this
subSpawnPlane_HeliPositionRelativeToJeep:
	;MSB means attack player 2.  Bits 0-6 are a timer to change which jeep is attacked
	LDA SpriteWhichJeeptoAttack,X
	ASL ;Sets carry if player 2 is attacked
	LDA #$00
	ROL ;A = 1 if player 2 is attacked
	TAY ;Y = 1 if player 2 is attacked
+:	LDA #$00 ;Init to Left Screen
	STA SpriteAbsoluteHorizPositionUB,X
	LDA #$20
	STA $00
	LDA JeepHorizScreenPosition,Y
	BPL +
	LDA #$E0
	STA $00
+:	LDA JeepHorizScreenPosition,Y
	CLC
	ADC $00
	CLC
	ADC $40
	STA SpriteAbsoluteHorizPositionLB,X
	BCC +
	INC SpriteAbsoluteHorizPositionUB,X
+:	RTS

subUpdateBGGraphicsFromSprite:
	STA $03 ;A contains the index in the table that determines what new BG tiles are to be loaded
	TAY
	JMP +
	;I believe the purpose here is that a BG update is not guraunteed from subUpdateBGGraphicsFromSprite
	;;So, this code is called to update the BG every 8 frames just in case it failed
subUpdateBGGraphicsFromSprite_Every7thRNGFrame: 
	STA $03
	TAY
	TXA
	AND #$07
	CLC
	ADC RNG_INCEveryFrame
	AND #$07
	BNE +++ ;RTS
+:	LDA SpriteObjectID,X
	BEQ +++ ;RTS - Ignore NULL objects
	LDA tblGraphicsUpdateVerticalOffset,Y
	CLC
	ADC SpriteVertScreenPosition,X
	STA $02
	LDA #$00
	STA $00
	LDA tblGraphicsUpdateHorizontalOffset,Y
	STA $01
	BPL +
	DEC $00
+:	LDA $01
	CLC
	ADC SpriteAbsoluteHorizPositionLB,X
	STA $01
	LDA $00
	ADC SpriteAbsoluteHorizPositionUB,X
	STA $00
	CPY #$08
	BCC +
	CPY #$0C
	BCC ++
	CPY #$0E
	BEQ ++++
	CPY #$1A
	BEQ ++++
+:	JMP Label1280 ;4x4 BG Tile Update
++:	JMP Label1281 ;1x1 BG Tile Update
++++	JMP Label1282 ;2x2 BG Tile Update
+++:	RTS

;These table values must be in increments of 8 pixels (for the 8x8 NES tiles)
	;If they are not, the are rounded down to the nearest 8
	;This table is used to provide offsets for updated BG tiles from objects
	;(e.g. exploding a gate or POW building)
	;Used in conjunction with the tblObjectControlledGraphicsUpdate table
	;F394

tblGraphicsUpdateHorizontalOffset:
	;4x4 tiles
	db $F0 ;00 Gate opened
	db $E0 ;01 Level 1,2,4,5 POW building exit left
	db $00 ;02 Level 1,2,4,5 POW building exit right
	db $F0 ;03 Level 1,3,6 POW Power up building
	db $F0 ;04 Level 2 POW Power up building
	db $F0 ;05 Level 2 broken pillar
	db $F8 ;06 Level 2 Boss Statue destroyed
	db $F8 ;07 Level 2 Statue destroyed
	
	;1x1 tiles
	db $00 ;08 Level 2 Statue eyes flash
	db $00 ;09 Level 2 Statue normal eyes
	db $00 ;0A Level 2 Statue mouth open
	db $00 ;0B Level 2 statue mouth closed
	
	;4x4 tiles
	db $E0 ;0C Level 3 POW building exit left	
	db $00 ;0D Level 3 POW building exit right
	
	;2x2 tile
	db $F8 ;0E Level 3 spread turret boss destroyed
	
	;4x4 tiles
	db $00 ;0F Level 1,2,4,5 POW building exit right (REDUNDANT)
	db $F0 ;10 Level 5 POW Power up building (also the one with the tank inside)
	db $F0 ;11 Level 5 Boss shutter door open
	db $F0 ;12 Level 5 Boss shutter door opening 2/3 open
	db $F0 ;13 Level 5 Boss shutter door opening 1/3 open
	db $F0 ;14 Level 5 Boss shutter door closed
	db $00 ;15 Level 1,2,4,5 POW building exit right (REDUNDANT)
	db $F0 ;16 Level 4 POW Power up building
	db $00 ;17 Level 6 POW building exit right
	db $F0 ;18 Level 6 Parked Tank
	db $E0 ;19 level POW building exit left
	
	;2x2 tile
	db $FC ;1A Level 6 final boss laser turret hole blast
	
	;4x4 tiles
	db $F0 ;1B Level 5 boss shutter door destroyed
	db $F8 ;1C Level 3 Parked Jeep

tblGraphicsUpdateVerticalOffset:
	;4x4 tiles
	db $F0 ;00 Gate opened
	db $F4 ;01 Level 1,2,4,5 POW building exit left
	db $F4 ;02 Level 1,2,4,5 POW building exit right
	db $F8 ;03 Level 1,3,6 POW Power up building
	db $F8 ;04 Level 2 POW Power up building
	db $F0 ;05 Level 2 broken pillar
	db $F8 ;06 Level 2 Boss Statue destroyed
	db $F8 ;07 Level 2 Statue destroyed
	
	;1x1 tiles
	db $08 ;08 Level 2 Statue eyes flash
	db $08 ;09 Level 2 Statue normal eyes
	db $10 ;0A Level 2 Statue mouth open
	db $10 ;0B Level 2 statue mouth closed
	
	;4x4 tiles
	db $F4 ;0C Level 3 POW building exit left	
	db $F4 ;0D Level 3 POW building exit right
	
	;2x2 tile
	db $00 ;0E Level 3 spread turret boss destroyed
	
	;4x4 tiles
	db $F4 ;0F Level 1,2,4,5 POW building exit right (REDUNDANT)
	db $F0 ;10 Level 5 POW Power up building (also the one with the tank inside)
	db $F8 ;11 Level 5 Boss shutter door open
	db $F8 ;12 Level 5 Boss shutter door opening 2/3 open
	db $F8 ;13 Level 5 Boss shutter door opening 1/3 open
	db $F8 ;14 Level 5 Boss shutter door closed
	db $F8 ;15 Level 1,2,4,5 POW building exit right (REDUNDANT)
	db $F0 ;16 Level 4 POW Power up building
	db $F0 ;17 Level 6 POW building exit right
	db $F0 ;18 Level 6 Parked Tank
	db $F0 ;19 level POW building exit left
	
	;2x2 tile
	db $FC ;1A Level 6 final boss laser turret hole blast
	
	;4x4 tiles
	db $F8 ;1B Level 5 boss shutter door destroyed
	db $F0 ;1C Level 3 Parked Jeep

Label1329:
	JSR Label1283
	JMP fctGetSpriteOrientationIndex

Label1283:
	LDA #$00
	STA $06
	STA $00
	STA $03
	LDA SpriteVertSpeedLB,X
	STA $01
	LDA SpriteVertSpeedUB,X
	STA $02
	BPL +
	INC $06
	JSR fctInvert24Bit
+:	LDA $00
	STA $03
	LDA $01
	STA $04
	LDA $02
	STA $05
	LDA SpriteHorizSpeedLB,X
	STA $01
	LDA SpriteHorizSpeedUB,X
	STA $02
	BPL +
	LDA $06
	ORA #$02
	STA $06
	JSR fctInvert24Bit
+:	JMP Label1286

fctGetSpriteOrientationIndex:    
	LDY #$00
	CLC
	ADC #$01
	AND #$1F
-:	SEC
	SBC #$04
	BCC +
	INY ;Y is essentially A/4 here
	JMP - ;could be bcs.  also, could go to SBC not SEC
+:	RTS

subProcessObjectSpeed_UpdatePosition:
	LDA SpriteObjectID,X
	CMP #$BE ;Landed Heli on pad, loads from right
	BEQ +
	CMP #$BD ;Landed Heli on pad, loads from left
	BEQ +
	LDA ScreenScrollingForF0ToBoss
	BNE ++
	
+:	LDA #$00
	STA $00
	LDA SpriteHorizSpeedUB,X
	BPL +
	DEC $00
	;Update Horiztonal subpixel position
+:	LDA SpriteHorizScreenPositionSubPixel,X
	CLC
	ADC SpriteHorizSpeedLB,X
	STA SpriteHorizScreenPositionSubPixel,X
	;Update Horizontal position
	LDA SpriteAbsoluteHorizPositionLB,X
	ADC SpriteHorizSpeedUB,X
	STA SpriteAbsoluteHorizPositionLB,X
	;Update screen location
	LDA SpriteAbsoluteHorizPositionUB,X
	ADC $00
	STA SpriteAbsoluteHorizPositionUB,X
	
	LDA #$00
	STA $00
	LDA SpriteVertSpeedUB,X
	BPL +
	DEC $00
	;Update Vertical subpixel position
+:	LDA SpriteVertScreenPositionSubPixel,X
	CLC
	ADC SpriteVertSpeedLB,X
	STA SpriteVertScreenPositionSubPixel,X
	;Update Vertical position
	LDA SpriteVertScreenPosition,X
	ADC SpriteVertSpeedUB,X
	STA SpriteVertScreenPosition,X
	;Update screen location
	LDA SpriteAbsoluteVertPositionUB,X
	ADC $00
	STA SpriteAbsoluteVertPositionUB,X
++:	RTS

subUpdateSpritePositionForScrolling_Speed_CheckForDespawn:	
	JSR subProcessObjectSpeed_UpdatePosition
	JSR subUpdateSpritePositionForScrolling
	JMP +
	
Label244:
	JSR subProcessObjectSpeed_UpdatePosition
	JSR subUpdateSpritePositionForScrolling
	LDA SpriteHorizScreenPositionSubPixel,X
	STA $10
	LDA SpriteAbsoluteHorizPositionLB,X
	STA $11
	LDA SpriteAbsoluteHorizPositionUB,X
	STA $12
	LDA SpriteVertScreenPositionSubPixel,X
	STA $13
	LDA SpriteVertScreenPosition,X
	STA $14
	LDA SpriteAbsoluteVertPositionUB,X
	STA $15
	BNE +
	;Sprite is on screen
	JSR fctTestForMovementCollision
	BEQ +
	LDA SpriteVertScreenPosition,X
	CMP #$08
	BCC +++
	CMP #$E8
	BCS +++
	;Check for Sprite offscreen for despawn
+:	LDA SpriteAbsoluteHorizPositionUB,X
	BMI +++
	CMP #$02
	BCS +++
	LDA SpriteAbsoluteVertPositionUB,X
	BEQ ++
	BMI +
	;Sprite is off screen below
	LDA SpriteVertScreenPosition,X ;See if the sprite is REALLY far down.  If so, go despawn it
	CMP #$40 ;despawn beyond a certain point off screen
	BCS +++
	BCC ++
+:	;Sprite is off screen above
	LDA SpriteVertScreenPosition,X
	CMP #$C0 ;despawn beyond a certain point off screen
	BCC +++
++:	RTS
+++:	JMP subDespawnSprite

	;play testing showed this table to be unused
	db $03,$00,$FD,$00,$00,$03,$00,$FD

subDespawnSprite:	
	LDA #$00
	STA SpriteObjectID,X ;clear sprite ID
	STA SpriteState,X ;clear sprite state
	STA SpriteTypeIndex,X ;clear sprite graphic
	STA SpriteHitboxShapeIndex,X ;clear hitbox
	STA SpriteHealthHP,X ;clear health
	STA SpriteGraphicsAttributes,X ;clear sprite attributes
	RTS
	
subMoveSpriteToNextState:
	LDA #$01
	BNE +
subMoveSpriteToPreviousState:
	LDA #$FF
+:	CLC
	ADC SpriteState,X
	JMP +
subSetSpriteState:	
	STA $00 ;Set the new sprite state.  Avoid overwriting the MSB (offscreen)
	LDA SpriteState,X
	AND #$80 
	ORA $00
+:	STA SpriteState,X
	LDA SpriteObjectID,X
	BNE +
	JMP subDespawnSprite
+:	RTS

;IN:
;X contains the enemy index
;
;OUT:
;A contains the distance from jeep to enemy (taxi cab metric)
;
;Y is used as the Player index, depending on which jeep is being targeted by the enemy
fctGetDistanceBetweenEnemyAndJeep:	
	LDA #$00
	STA $01
	LDY #$00 ;Player 1
	LDA SpriteWhichJeeptoAttack,X
	BPL +
	INY ;Player 2
+:	LDA JeepHorizScreenPosition,Y
	CLC
	ADC ScreenLeftScrollPosition
	BCC +
	INC $01
+:	SEC
	SBC SpriteAbsoluteHorizPositionLB,X
	STA $00
	LDA $01
	SBC SpriteAbsoluteHorizPositionUB,X
	STA $01
	BPL +
	JSR fctInvert24Bit
+:	LDA $00
	STA $03
	LDA $01
	BNE ++
	LDA JeepVertScreenPosition,Y
	SEC
	SBC SpriteVertScreenPosition,X
	STA $00
	LDA #$00
	SBC SpriteAbsoluteVertPositionUB,X
	STA $01
	BPL +
	JSR fctInvert24Bit
+:	LDA $01
	BNE ++
	LDA $00
	CLC
	ADC $03
	BCS ++
	RTS
++:	LDA #$FF
	RTS
	
subCountDownForJeepTargetBy1:
	LDA SpriteWhichJeeptoAttack,X
	AND #$7F
	SEC
	SBC #$01
	BCS +
	LDA SpriteWhichJeeptoAttack,X
	CLC
	ADC #$FF
	STA SpriteWhichJeeptoAttack,X
	SEC
	RTS

subCountDownForJeepTarget:	
+:	DEC SpriteWhichJeeptoAttack,X
	CLC
	RTS
	
subCheckWhichJeepToAttack:	
	TXA
	LSR
	BCS + ;Odd sprite slot found
	LDA SpriteWhichJeeptoAttack,X
	AND #$7F
	STA SpriteWhichJeeptoAttack,X
	JMP subCheckEnemyTarget_AttackOtherJeepIfDead
+:	LDA SpriteWhichJeeptoAttack,X
	ORA #$80
	STA SpriteWhichJeeptoAttack,X
	
subCheckEnemyTarget_AttackOtherJeepIfDead:	
	LDY #$00 ;Player 1
	LDA SpriteWhichJeeptoAttack,X
	BPL +
	INY ;Player 1 is dead, check player 2
+:	LDA JeepState,Y	;Enemy is attacking the player in Y - check player Y state
	CLC
	BNE + ;RTS - if player Y is still alive, do nothing
	LDA SpriteWhichJeeptoAttack,X ;If the current player being attacked is dead, attack the other player
	ADC #$80 ;This will force the enemy to attack the other player
	STA SpriteWhichJeeptoAttack,X
	SEC
+:	RTS


;unused code
	STA $08
	JSR subCalculateDirectionTowardJeep
	JMP subCalculateObjectSpeed
	
subCalculateDirectionTowardJeep:
	LDY #$00
	LDA SpriteWhichJeeptoAttack,X
	BPL +
	INY ;Y=0 Attacking Jeep 1, Y=1 Attacking Jeep 2
+:	LDA JeepHorizScreenPositionSubPixel,Y
	STA $10
	LDA JeepHorizScreenPosition,Y
	CLC
	ADC ScreenLeftScrollPosition
	STA $11
	LDA #$00
	ADC #$00
	STA $12
	LDA JeepVertScreenPositionSubPixel,Y
	STA $13
	LDA JeepVertScreenPosition,Y
	STA $14
	LDA #$00
	STA $15
subCalculateDirectionWithPresets:
	LDA #$00
	STA $06
	LDA $13
	SEC
	SBC SpriteVertScreenPositionSubPixel,X
	STA $00
	LDA $14
	SBC SpriteVertScreenPosition,X
	STA $01
	LDA $15
	SBC SpriteAbsoluteVertPositionUB,X
	STA $02
	BPL +
	INC $06
	JSR fctInvert24Bit
+:	LDA $00
	STA $03
	LDA $01
	STA $04
	LDA $02
	STA $05
	LDA $10
	SEC
	SBC SpriteHorizScreenPositionSubPixel,X
	STA $00
	LDA $11
	SBC SpriteAbsoluteHorizPositionLB,X
	STA $01
	LDA $12
	SBC SpriteAbsoluteHorizPositionUB,X
	STA $02
	BCS +
	LDA $06
	CLC
	ADC #$02
	STA $06
	JSR fctInvert24Bit
-:
Label1286:
+:	LDA $02
	BNE ++
	LDA $01
	CMP #$07
	BCS ++
	LDA $05
	BNE ++
	LDA $04
	CMP #$07
	BCC +
++:	LSR $02
	ROR $01
	ROR $00
	LSR $05
	ROR $04
	ROR $03
	JMP -
+:	LDA $00
	BPL +
	INC $01
+:	LDA $00 ;Same exact check??  LDA $03??
	BPL +
	INC $04
+:	ASL $04
	ASL $04
	ASL $04
	LDA $04
	CLC
	ADC $01
	STA $07
	LSR
	TAY
	LDA table1,Y
	LSR $07
	BCC ++
	AND #$0F
	JMP +
++:	LSR
	LSR
	LSR
	LSR
+:	LSR $06
	BCC +
	JSR fctInvertA
+:	LSR $06
	BCC +
	JSR fctInvertA
	CLC
	ADC #$10
+:	AND #$1F
	RTS
	
;has to do with calculating the angle between enemies and the jeep being attacked
table1:
	db $40,$00,$00,$00,$84,$22,$11,$11,$86,$43,$22,$21,$86,$54,$33,$22
	db $87,$65,$43,$33,$87,$65,$54,$43,$87,$66,$54,$44,$87,$76,$55,$44

;Value in $00-$02 is inverted
fctInvert24Bit:
	LDA $00
	JSR fctInvertA
	STA $00
	LDA $01
	EOR #$FF
	ADC #$00 ;Carry comes from fctInvertA
	STA $01
	LDA $02
	EOR #$FF
	ADC #$00 ;Carry comes from $01 above
	STA $02
	RTS

;A = $100-A;  Returns 0 if A=0
fctInvertA:
	EOR #$FF
	CLC
	ADC #$01
	RTS


	
subInvertSpriteVertAndHorizSpeed:
	JSR subInvertSpriteVertSpeed
subInvertSpriteHorizSpeed:	
	LDA SpriteHorizSpeedLB,X
	JSR fctInvertA
	STA SpriteHorizSpeedLB,X
	LDA SpriteHorizSpeedUB,X
	EOR #$FF
	ADC #$00
	STA SpriteHorizSpeedUB,X
	RTS
	
subInvertSpriteVertSpeed:	
	LDA SpriteVertSpeedLB,X
	JSR fctInvertA
	STA SpriteVertSpeedLB,X
	LDA SpriteVertSpeedUB,X
	EOR #$FF
	ADC #$00
	STA SpriteVertSpeedUB,X
	RTS

;For $08	
;Upper byte is speed multiplier	
;Lower byte is an additional fine-tuned offset	
	
;00	+0%
;01	+50%
;02	+25%
;03	+12.5%
;04	+6.25%
;05	+3.125%
;06	+1.5625%
;07	+0.78125%
;08	+0.390625%
subCalculateObjectSpeed:
	STA $09
	JSR subGetHorizontalSpeed_DirectionOnCircle
	JSR Label1321 ;Multiplier for speed value
	LDA $00
	STA SpriteHorizSpeedLB,X
	LDA $01
	STA SpriteHorizSpeedUB,X
	JSR subGetVerticalSpeed_DirectionOnCircle
	JSR Label1321 ;Multiplier for speed value
	LDA $00
	STA SpriteVertSpeedLB,X
	LDA $01
	STA SpriteVertSpeedUB,X
	RTS
	
subGetHorizontalSpeed_DirectionOnCircle:
	LDA $09 ;unnecessary since A was just stored in $09.  A still has the same value
	AND #$0F
	TAY
	LDA tblCosineValuesForDirectionalTargetting,Y
	STA $00
	LDA #$00
	STA $01
	LDA $09
	CMP #$08
	BCC +
	CMP #$18
	BCS +
	JMP fctInvert24Bit
+:
-:	RTS

subGetVerticalSpeed_DirectionOnCircle:
	LDA $09 ;upper nibble = 0:, lower nibble is direction in 3rd and 4th quadrant.  
	CLC ;upper nibble > 1, direction is mirrored vertically
	ADC #$08 ;Convert Cosine table to Sine
	AND #$0F
	TAY
	LDA tblCosineValuesForDirectionalTargetting,Y ;read speed lower byte
	STA $00 ;store for later
	LDA #$00
	STA $01
	LDA $09
	CMP #$10
	BCC -
	JMP fctInvert24Bit

;Used to calculate speeds at a certain angle
tblCosineValuesForDirectionalTargetting:
	db $80,$7D,$76,$6A,$5A,$47,$30,$18,$00,$18,$30,$47,$5A,$6A,$76,$7D

;The routine that calculates the vertical and horizontal speed
Label1321:	
	LDA #$00
	STA $02 ;0008 (upper nibble) contains the number of loops
	STA $03 ;e.g. if 0000=80 and 0008=40, then
	LDA $08 ;$80*4 = 200, or a high byte speed of 2
	LSR
	LSR
	LSR
	LSR
	TAY
	BEQ +
	;compute multiplier in the UB of $08
-:	LDA $02
	CLC
	ADC $00
	STA $02
	LDA $03
	ADC $01
	STA $03
	DEY
	BNE -
+:	LDA $08
	AND #$0F
	TAY
	BEQ ++
	LDA #$00
	STA $04
	LDA $01
	BPL +
	DEC $04
+:
-:	LSR $04
	ROR $01
	ROR $00
	DEY
	BNE -
	BEQ +
++:	LDA #$00
	STA $00
	STA $01
+:	LDA $00
	CLC
	ADC $02
	STA $00
	LDA $01
	ADC $03
	STA $01
	RTS
-:	STA SpriteTypeIndex,X
	JSR Label1329
	JMP +
	
subUpdateSpriteForDirectionChange:
	JSR fctGetSpriteOrientationIndex 
	;Y contains the Direction to shoot / 4.  00 is right, increasing counterclockwise
+:	LDA tblSpriteMirroringAndIndexForDirection,Y
	AND #$F0
	STA SpriteAttributes,X
	LDA tblSpriteMirroringAndIndexForDirection,Y
	AND #$0F
	CLC
	ADC SpriteTypeIndex,X
	STA SpriteTypeIndex,X
	RTS
	
	;$F7E0
;Mirroring here seems to be based on direction, not on PPU tile orientation
tblSpriteMirroringAndIndexForDirection:	
	;Right
	db $00 ;no mirroring, base sprite index
	;Down-Right
	db $01 ;no mirroring, 2nd sprite graphic
	;Down
	db $02 ;no mirroring, 3rd sprite graphic
	;Down-Left
	db $41 ;mirror horizontally, 2nd sprite graphic
	;Left
	db $40 ;mirror horizontally, base sprite index
	;Up-Left
	db $C1 ;mirror horizontally and vertically, 2nd sprite graphic
	;Up
	db $82 ;mirror vertically, 3rd sprite graphic
	;Up-Right
	db $81 ;mirror vertically, 2nd sprite graphic
	
	;unused code
	JSR -
	JMP +
	
subProcessWalkingAnimation:
	JSR subUpdateSpriteForDirectionChange
	;Y contains the Direction to shoot / 4.  00 is right, increasing counterclockwise
+:	LDA tblWalkingAnimationAttributes_SpriteIndex,Y
	AND #$F0
	STA SpriteAttributes,X
	LDA tblWalkingAnimationAttributes_SpriteIndex,Y
	AND #$0F
	BEQ +
	CMP #$0F
	BEQ ++
	INC SpriteTypeIndex,X
+:	RTS
++:	DEC SpriteTypeIndex,X
	RTS
	
	;F80B
tblWalkingAnimationAttributes_SpriteIndex
	;Right
	db $00 ;no mirroring.  no sprite index shift
	;Up-Right
	db $0F ;no mirroring.  decrement sprite index
	;Up
	db $0F ;no mirroring.  decrement sprite index
	;Up-Left
	db $00 ;no mirroring.  no sprite index shift
	;Left
	db $40 ;mirror horizontally.  no sprite index shift
	;Down-Left
	db $4F ;mirror horizontally.  decrement sprite index
	;Down
	db $00 ;no mirroring.  no sprite index shift
	;Down-Right
	db $01 ;no mirroring.  increment sprite index
	
subInfantryDeath:
	LDA #$01 ;Sets the palette
	STA SpriteGraphicsAttributes,X
	JSR subClearSpriteSpeed
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA #$20	;Sets the frame counter for animation sequencing
	STA SpriteData8,X
	LDA #$18	;Sets the sprite type for the dead infantryman
	STA SpriteTypeIndex,X
	LDA #$F0
	STA SpriteHitboxShapeIndex,X
	LDA #InfantrySquishSoundClip
	JSR subInitiateSoundClip
	JMP subMoveSpriteToNextState
	
subInfantryDeathAnimation:	
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteData8,X
	BNE +
	JMP subDespawnSprite
+:	RTS


;41
;*******************************
;LEVEL 4 BOSS - EXTRA EXPLOSIONS
;just creates explosions.  does nothing else
; SpriteData1 - NOT USED
; SpriteData2 - NOT USED
; SpriteData3 - NOT USED
; SpriteData4 - NOT USED
; SpriteData5 - NOT USED
; SpriteData6 - NOT USED
; SpriteData8 - NOT USED
;*********************************
Level4BossExtraExplosionsOnDeath:
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	dw subSpriteDeath
	dw subSpriteExplosion
	dw subDespawnSprite
	
subCheckForBossDeath_MultipleBossEnemies:
	JSR subClearSpriteSpeed
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA #$F0
	STA SpriteHitboxShapeIndex,X
	LDA LevelBossEntitiesRemaining
	CMP #$01 ;Last enemy to die
	BNE +
	JSR subStopMusic
+:	JMP subMoveSpriteToNextState

subSpriteDeath:
	JSR subClearSpriteSpeed
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA #$18
	STA SpriteData8,X
	LDA #$19 ;first small explosion object ID
	STA SpriteTypeIndex,X
	LDA #$03 ;Set palette for explosion color
	STA SpriteGraphicsAttributes,X
	LDA #$F0 ;Set explosion hitbox to no interaction at all
	STA SpriteHitboxShapeIndex,X
	LDA SpriteState,X
	BMI +
	LDA #MainWeaponExplosionOnEnemy
	JSR subInitiateSoundClip
+:	JMP subMoveSpriteToNextState

subSpriteExplosion:
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
+:	JMP subDespawnSprite
	
subPlayBarracksOpeningSound_LoadNewBuildingBGGraphics:
	LDA #POWBuildingOpeningSoundClip
	JSR subInitiateSoundClip
	JMP subInitiateExplosionAnimation_LoadReplacementBackgroundTiles_Collision

subPlayMissileHittingGroundSound_LoadHoleInGroundBGGraphics: ;End of blast life - hit the ground, creates crater/hole in the ground
	LDA #BlackAndWhiteMissile_Bomb_LaserBlastHitsGroundSoundClip ;Also for Moai snapping
	JSR subInitiateSoundClip
	JMP subInitiateExplosionAnimation_LoadReplacementBackgroundTiles_Collision
	
subPlayExplosionSound_LoadNewBGGraphics:
	LDA SpriteState,X ;Avoid playing sound if the object is offscreen
	BMI subInitiateExplosionAnimation_LoadReplacementBackgroundTiles_Collision
	LDA #MainWeaponExplosionOnEnemy 
	JSR subInitiateSoundClip

subInitiateExplosionAnimation_LoadReplacementBackgroundTiles_Collision:
	JSR subClearSpriteSpeed
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn ;updates position as screens scrolls
	LDA #$18 ;load the explosion animation timer value
	STA SpriteData8,X
	LDA #$19 ;First explosion graphic
	STA SpriteTypeIndex,X
	LDA #$03 ;Load Explosion palette
	STA SpriteGraphicsAttributes,X
	LDA #$F0 ;set the hitbox to no interaction at all
	STA SpriteHitboxShapeIndex,X
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite
	JMP subMoveSpriteToNextState

subProcessExplosionAnimation:	
	DEC SpriteData8,X
	LDA SpriteData8,X
	BEQ +
	AND #$07
	BNE +
	INC SpriteTypeIndex,X
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteData1,X
	JSR subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	LDA SpriteData8,X
	BEQ +
	RTS
+:	LDA #$00
	STA SpriteTypeIndex,X
	JMP subMoveSpriteToNextState

;No object that uses this routine has a speed.  no need to waste calculation time on this
subScrollSprite_CheckForDespawn_UpdateBG:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn ;update on-screen position
	LDA SpriteData1,X
	JMP subUpdateBGGraphicsFromSprite_Every7thRNGFrame
	
EMPTYSprite_RTS:
	RTS
	
subProcessObjectLogic:
	LDA SpriteObjectID,X
	AND #$7F
	BEQ EMPTYSprite_RTS ;RTS ;Avoid wasting time for NULL objects
	;Check if this is an enemy bullet
	CMP #$36 
	BNE +
	JMP EnemyBulletSpriteLogic ;There are SO many bullets compared to other objects, this saves a lot of time
	;Process all other objects
+:	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	;.PAD $F926
	;These are all bank 6 (or 15)
	dw EMPTYSprite_RTS 						;00 - This is never called due to the AND 7F and BEQ above
	dw MobileInfantrySpriteLogic				;01
	dw StationaryInfantrySpriteLogic			;02
	dw StationaryInfantrySpriteLogic 			;03 - Flame Thrower
	dw MobileSwampInfantrySpriteLogic			;04
	dw LargeGrayTurretWhiteBulletsSpriteLogic	;05
	dw LargeGrayTurretYellowBulletSpriteLogic	;06
	dw RedMediumTankSpriteLogic				;07
	dw Level1AttackBoatSpriteLogic 			;08
	dw Level1BossSpriteLogic					;09
	dw Level1BossTankSpriteLogic				;0A
	dw SilverLargeTankSpriteLogic				;0B
	dw Level5MountedTurretSpriteLogic			;0C
	dw Level3LaserChargingFlashesSpriteLogic	;0D
	dw FlameTankSpriteLogic					;0E
	dw EnemyJeepSpriteLogic					;0F
	dw Level2PillarSpriteLogic 				;10 - Falls Left
	dw InfantryTruckSpriteLogic				;11
	dw SpreadTurretSpriteLogic				;12
	dw POWBuildingSpriteLogic 				;13 - 2 POWs, exit out the right
	dw POWBuildingSpriteLogic 				;14 - 2 POWs, exit out the left
	dw POWPowerUpBuildingSpriteLogic			;15
	dw POWWalkingSpriteLogic					;16
	dw Level5BossSpriteLogic					;17
	dw Level2BossStatueHeadSpriteLogic 		;18
	dw POWBuildingWithTankInsideSpriteLogic		;19
	dw Level3LargeAttackBoatSpriteLogic		;1A
	dw GateSpriteLogic						;1B
	dw POWBuildingSpriteLogic 				;1C - 4 POWs, exit out the right
	dw POWBuildingSpriteLogic 				;1D - 4 POWs, exit out the left
	dw Level2PillarTopSpriteLogic				;1E
	dw Level2PillarSpriteLogic 				;1F - Falls Right
	dw Level2BossSpriteLogic 				;20
	dw Level2StatueHeadSpriteLogic 			;21 - Always shoots
	dw Level2StatueHeadSpriteLogic 			;22 - Idle
	dw Level5BossSilverLargeTankSpriteLogic		;23
	dw Level5BossRedMediumTankSpriteLogic		;24
	dw Level3BossSpriteLogic					;25
	dw Level5BossElectrifiedGateSpriteLogic		;26
	dw POWLoadingIntoHeliSpriteLogic			;27
	dw POWSpawnOnJeepDeathSpriteLogic 			;28 - Only spawns POWs if the jeep has them onboard
	dw SubmarineSpriteLogic					;29
	dw Level4SpreadTruckSpriteLogic 			;2A - Right Facing
	dw Level4SpreadTruckSpriteLogic 			;2B - Left Facing
	dw Level4MissileLauncherSpriteLogic		;2C
	dw Level4SunkenMissileLauncherSpriteLogic	;2D
	dw Level6MissileLauncherSpriteLogic		;2E
	dw Level4FallingRockSpriteLogic 			;2F - Left direction
	dw Level4FallingRockSpriteLogic 			;30 - Right direction
	dw Level5BossDoorSpriteLogic				;31
	dw Level4TrainSpriteLogic				;32
	dw Level4TrainCarSpriteLogic				;33
	dw FlameThrowerSpriteLogic				;34
	dw HiddenMineSpriteLogic					;35
	dw EnemyBulletSpriteLogic 				;36 - This is never called due to the CMP #$36 above
	dw FallingBombSpriteLogic				;37
	dw Level3LaserSpriteLogic 				;38
	dw BlackAndWhite_SmallMissileSpriteLogic	;39
	dw AttackPlaneSpriteLogic 				;3A - Specific location
	dw AttackPlaneSpriteLogic 				;3B - Anywhere
	dw FlyingOverheadHeliSpriteLogic 			;3C - POW Rescue chopper
	dw LandedHeliSpriteLogic 				;3D - Loads from the right
	dw LandedHeliSpriteLogic 				;3E - Loads from the left
	dw POWDropOffSpriteLogic 				;3F - At the helipad
	dw Level4BossSpriteLogic 				;40
	dw Level4BossExtraExplosionsOnDeath		;41
	dw Level4BossParachutingInfantrySpriteLogic	;42
	dw Level6AttackHelicopterSpriteLogic		;43
	dw EscalatorSpriteLogic					;44
	dw Level6BossLoadSpriteLogic				;45
	dw EndofLevelCheckSpriteLogic				;46
	dw Level6BossLaserTurretSpriteLogic		;47
	dw Level6BossLaserTurretBlastSpriteLogic 	;48
	dw Level6BossLaserTurretGraphicsLoadSpriteLogic ;49
	dw Level6FinalBossSpriteLogic 			;4A
	dw Level6FinalBossTankSpriteLogic			;4B
	dw Level6FinalBossTankFlameShotSpriteLogic 	;4C
	dw Level6FinalBossTankFlameShotTipSpriteLogic ;4D
	dw ParkedJeepTankSpriteLogic 				;4E
	dw Level6BossTankTurretSpriteLogic			;4F
	dw PowerUpStarSpriteLogic 				;50 - Destroys all enemies on screen
	dw PowerUpStarSpriteLogic 				;51 - Max main weapon
	dw PowerUpStarSpriteLogic 				;52 - Extra life
	dw ParkedJeepTankSpriteLogic 				;53 - Contains a power up star underneath

	;HitBoxIndex Definition:
	;Bit
	;7 Set: No collision with jeep
	;6 Set: No collision with bullets
	;5 Set: No collision with main weapon
	;4 Set: Main Weapon kills the object but it itself is not destroyed:
	;3-0: Defines the shape of the hit box ($0 - $F) in tblEnemyHitBoxDimension
tblEnemyHitBoxIndex:
	db $00 ;00 NOTHING
	db $19 ;01 mobile soldier
	db $19 ;02 stationary soldier
	db $19 ;03 flame thrower infantry
	db $19 ;04 Mobile soldier - can walk in swamp
	db $04 ;05 platform tank white bullets
	db $04 ;06 platform tank yellow bullets
	db $05 ;07 small red tank
	db $06 ;08 attack boat (diagonal)
	db $F0 ;09 Level 1 boss
	db $06 ;0A Level 1 boss tank
	db $06 ;0B Silver tank shoots black balls
	db $F0 ;0C Level 5 mounted gun.  Shoots black balls at end of bridge
	db $F0 ;0D Level 3 laser charging flashes
	db $06 ;0E Flame Tank
	db $05 ;0F Enemy Jeep
	db $45 ;10 Pilla - Falls Left
	db $0C ;11 Infantry Truck (Level 3)
	db $F0 ;12 Spread Turret (rises out of ground)
	db $C2 ;13 POW Right Entrance (2)
	db $C2 ;14 POW Left Entrance (2)
	db $C2 ;15 POW Power up Building
	db $F3 ;16 POW Walking around
	db $F0 ;17 Level 5 Boss
	db $45 ;18 Level 2 boss - head sprite fires attractive missiles
	db $C2 ;19 Barracks with tank in it
	db $08 ;1A Large attack boat
	db $C1 ;1B Gate
	db $C2 ;1C POW Right Entrance (4)
	db $C2 ;1D POW Left Entrance (4)
	db $07 ;1E Pillar Top (broken off.  Both left and right.  Mirrored graphics)
	db $45 ;1F Pillar - Falls Right
	db $F0 ;20 Level 2 boss - 4 status heads
	db $45 ;21 Head Statue - Always Shoots
	db $45 ;22 Head Statue - Idle
	db $06 ;23 Silver tank shoots black balls (spawns from Level 5 boss)
	db $05 ;24 Red Tank (spawns from Level 5 boss)
	db $F0 ;25 Level 3 Boss - multiple spread turrets
	db $E1 ;26 Level 5 electrified gate graphic
	db $F0 ;27 POW loading onto heli
	db $F3 ;28 POW Spawns on Jeep Death
	db $F4 ;29 Attack sub
	db $05 ;2A Right facing spread truck (level 4)
	db $05 ;2B Left facing spread truck (level 4)
	db $04 ;2C Missile Launcher (level 4 on cliffs)
	db $44 ;2D Sunken missile launcher (level 4)
	db $F0 ;2E Missile launcher with door (level 6)
	db $04 ;2F Left rolling rock
	db $04 ;30 Right rolling rock
	db $F0 ;31 Level 5 boss door (spawns tanks)
	db $F0 ;32 Train (level 4)
	db $04 ;33 Train cars
	db $79 ;34 flame tank/infantry flame 
	db $74 ;35 Hidden mine (level 4/5)
	db $74 ;36 enemy round bullet
	db $F4 ;37 bomber/jeep bomb
	db $F0 ;38 Laser (level 3)
	db $04 ;39 White/Black missile
	db $C5 ;3A Attack Plane - Specific
	db $C5 ;3B Attack Plane - Anywhere
	db $F0 ;3C Flying overhead heli
	db $F0 ;3D Landed heli - loads from right
	db $F0 ;3E Landed heli - loads from left
	db $73 ;3F Drop off for POWs
	db $CD ;40 Level 4 boss - spawns giant heli
	db $F0 ;41 Level 4 boss - extra explosion for defeated heli
	db $F0 ;42 parachuting infantry
	db $C5 ;43 Level 6 attack helicopter
	db $7E ;44 Escalator object that oscillates tread pattern tile
	db $F0 ;45 Final Boss Load Object
	db $F0 ;46 End of Level Check
	db $46 ;47 Level 6 Boss Laser Turret
	db $74 ;48 Level 6 Boss Laser Turret laser blasts
	db $F0 ;49 Triggers the loading of the L6 boss laser turret sprite graphics
	db $C7 ;4A Level 6 Final Boss
	db $01 ;4B Level 6 Final Boss large tank
	db $76 ;4C Level 6 Boss Tank Flame Shot
	db $76 ;4D Level 6 Boss Tank Tip of Flame Shot
	db $85 ;4E pArked jeep or tank
	db $0B ;4F Level 6 Boss Tank Mounted Gun
	db $C4 ;50 Power up - destroys enemies
	db $C4 ;51 Power up - full bazooka
	db $C4 ;52 Power up - extra life
	db $85 ;53 parked jeep or tank - with bazooka star under it??
	
	;.PAD $FA22
;This table defines the X,Y bounds of the object.
;e.g. for $10,$10, collision occurs +/-8 in the X direction
;;and +/-8 in the Y direction
tblEnemyHitBoxDimension:
	;  X   Y
	db $00,$00 ;00 NULL
	db $1F,$0F ;01 Gate
	db $19,$19 ;02 POW buildings
	db $10,$10 ;03 Walking POW
	db $0A,$0A ;04 missiles, hidden mine, bullets, power up stars, etc.
	db $0A,$12 ;05 parked jeep/tank, attack heli, bomber plane, etc.
	db $0D,$12 ;06 Silver/Flame tanks, boss tanks, etc
	db $0D,$0A ;07 broken pillar, Final boss tank
	db $0A,$19 ;08 Level 3 attack boat, Level 6 missile launcher
	db $0D,$0D ;09 infantry, flame, Level 5 mounted cliff turret
	db $0C,$36 ;0A Level 3 laser
	db $0A,$20 ;0B Final boss tank mounted turret
	db $13,$11 ;0C infantry truck, Level 5 boss door
	db $0D,$19 ;0D Level 4 boss heli
	db $0C,$41 ;0E Level 6 short escalator
	db $0C,$59 ;0F Level 6 long escalator
	
	;.PAD $FA42

tblEnemyHealth:
	db $00 ;00 NOTHING
	db $01 ;mobile soldier
	db $01 ;stationary soldier
	db $01 ;flame thrower infantry
	db $01 ;Mobile soldier - can walk in swamp
	db $03 ;platform tank white bullets
	db $04 ;platform tank yellow bullets
	db $04 ;small red tank
	db $06 ;08 attack boat (diagonal)
	db $00 ;Level 1 boss
	db $8A ;Level 1 boss tank
	db $06 ;Silver tank shoots black balls
	db $04 ;Level 5 mounted gun.  Shoots black balls at end of bridge
	db $00 ;Level 3 laser charging flashes
	db $06 ;Flame Tank
	db $02 ;Enemy Jeep
	db $01 ;10 Pillar - Falls Left
	db $04 ;Infantry Truck (Level 3)
	db $04 ;Spread Turret (rises out of ground)
	db $01 ;POW Right Entrance (2)
	db $01 ;POW Left Entrance (2)
	db $01 ;POW Power up Building
	db $00 ;POW Walking around
	db $00 ;Level 5 Boss
	db $8F ;18 Level 2 boss - head sprite fires attractive missiles
	db $01 ;Barracks with tank in it
	db $0A ;Large attack boat
	db $01 ;Gate
	db $01 ;POW Right Entrance (4)
	db $01 ;POW Left Entrance (4)
	db $07 ;Pillar Top (broken off.  Both left and right.  Mirrored graphics)
	db $01 ;Pillar - Falls Right
	db $00 ;20 Level 2 boss - 4 status heads
	db $01 ;Head Statue - Always Shoots
	db $01 ;Head Statue - Idle
	db $06 ;Silver tank shoots black balls (spawns from Level 5 boss)
	db $04 ;Red Tank (spawns from Level 5 boss)
	db $00 ;Level 3 Boss - multiple spread turrets
	db $81 ;Level 5 electrified gate graphic
	db $00 ;POW loading onto heli
	db $00 ;28 POW Spawns on Jeep Death
	db $40 ;Attack sub
	db $08 ;Right facing spread truck (level 4)
	db $08 ;Left facing spread truck (level 4)
	db $06 ;Missile Launcher (level 4 on cliffs)
	db $01 ;Sunken missile launcher (level 4)
	db $40 ;Missile launcher with door (level 6)
	db $07 ;Left rolling rock
	db $07 ;30 Right rolling rock
	db $83 ;Level 5 boss door (spawns tanks)
	db $00 ;Train (level 4)
	db $04 ;Train cars
	db $01 ;flame tank/infantry flame 
	db $01 ;Hidden mine (level 4/5)
	db $00 ;enemy round bullet
	db $00 ;bomber/jeep bomb
	db $00 ;38 Laser (level 3)
	db $01 ;White/Black missile
	db $01 ;Attack Plane - Specific
	db $01 ;Attack Plane - Anywhere
	db $00 ;Flying overhead heli
	db $00 ;Landed heli - loads from right
	db $00 ;Landed heli - loads from left
	db $00 ;Drop off for POWs
	db $A0 ;40 Level 4 boss - spawns giant heli
	db $00 ;Level 4 boss - extra explosion for defeated heli
	db $00 ;parachuting infantry
	db $01 ;Level 6 attack helicopter
	db $00 ;Escalator object that oscillates tread pattern tile
	db $00 ;Final Boss Load Object
	db $00 ;End of Level Check
	db $8F ;Level 6 Boss Laser Turret
	db $00 ;48 Level 6 Boss Laser Turret laser blasts
	db $00 ;Triggers the loading of the L6 boss laser turret sprite graphics
	db $BF ;Level 6 Final Boss
	db $FF ;Level 6 Final Boss large tank
	db $00 ;Level 6 Boss Tank Flame Shot
	db $00 ;Level 6 Boss Tank Tip of Flame Shot
	db $03 ;parked jeep or tank
	db $C0 ;Level 6 Boss Tank Mounted Gun
	db $01 ;50 Power up - destroys enemies
	db $01 ;Power up - full bazooka
	db $01 ;Power up - extra life
	db $03 ;parked jeep or tank - with bazooka star under it??
	;.PAD $FA96

;FOR REFERENCE ONLY.  tblPointValues is the real table and may be different
	;0 - 0 XP
	;1 - 50 XP
	;2 - 100 XP
	;3 - 200 XP
	;4 - 300 XP
	;5 - 500 XP
	;6 - 800 XP
	;7 - 1000 XP
	;8 - 1500 XP
	;9 - 2000 XP
	;A - 3000 XP
	;B - 5000 XP
	;C - 8000 XP
	;D - 9000 XP
	;E - 9990 XP
	;F - 10 XP
	
tblEnemyPoints_DeathState:
	db $00 ;00 NOTHING
	db $27 ;mobile soldier
	db $23 ;stationary soldier
	db $23 ;flame thrower infantry
	db $27 ;Mobile soldier - can walk in swamp
	db $55 ;platform tank white bullets
	db $55 ;platform tank yellow bullets
	db $54 ;small red tank
	db $62 ;08 attack boat (diagonal)
	db $02 ;Level 1 boss
	db $65 ;Level 1 boss tank
	db $64 ;Silver tank shoots black balls
	db $76 ;Level 5 mounted gun.  Shoots black balls at end of bridge
	db $02 ;Level 3 laser charging flashes
	db $64 ;Flame Tank
	db $64 ;Enemy Jeep
	db $02 ;10 Pillar - Falls Left
	db $54 ;Infantry Truck (Level 3)
	db $74 ;Spread Turret (rises out of ground)
	db $62 ;POW Right Entrance (2)
	db $62 ;POW Left Entrance (2)
	db $42 ;POW Power up Building
	db $05 ;POW Walking around
	db $03 ;Level 5 Boss
	db $64 ;18 Level 2 boss - head sprite fires attractive missiles
	db $52 ;Barracks with tank in it
	db $62 ;Large attack boat
	db $02 ;Gate
	db $62 ;POW Right Entrance (4)
	db $62 ;POW Left Entrance (4)
	db $53 ;Pillar Top (broken off.  Both left and right.  Mirrored graphics)
	db $02 ;Pillar - Falls Right
	db $03 ;20 Level 2 boss - 4 status heads
	db $64 ;Head Statue - Always Shoots
	db $64 ;Head Statue - Idle
	db $05 ;Silver tank shoots black balls (spawns from Level 5 boss)
	db $05 ;Red Tank (spawns from Level 5 boss)
	db $03 ;Level 3 Boss - multiple spread turrets
	db $83 ;Level 5 electrified gate graphic
	db $52 ;POW loading onto heli
	db $02 ;28 POW Spawns on Jeep Death
	db $77 ;Attack sub
	db $85 ;Right facing spread truck (level 4)
	db $85 ;Left facing spread truck (level 4)
	db $93 ;Missile Launcher (level 4 on cliffs)
	db $94 ;Sunken missile launcher (level 4)
	db $94 ;Missile launcher with door (level 6)
	db $64 ;Left rolling rock
	db $64 ;30 Right rolling rock
	db $75 ;Level 5 boss door (spawns tanks)
	db $03 ;Train (level 4)
	db $82 ;Train cars
	db $05 ;flame tank/infantry flame 
	db $02 ;Hidden mine (level 4/5)
	db $03 ;enemy round bullet
	db $03 ;bomber/jeep bomb
	db $03 ;38 Laser (level 3)
	db $03 ;White/Black missile
	db $72 ;Attack Plane - Specific
	db $72 ;Attack Plane - Anywhere
	db $01 ;Flying overhead heli
	db $04 ;Landed heli - loads from right
	db $04 ;Landed heli - loads from left
	db $02 ;Drop off for POWs
	db $B5 ;40 Level 4 boss - spawns giant heli
	db $02 ;Level 4 boss - extra explosion for defeated heli
	db $03 ;parachuting infantry
	db $93 ;Level 6 attack helicopter
	db $02 ;Escalator object that oscillates tread pattern tile
	db $01 ;Final Boss Load Object
	db $01 ;End of Level Check
	db $A4 ;Level 6 Boss Laser Turret
	db $04 ;48 Level 6 Boss Laser Turret laser blasts
	db $01 ;Triggers the loading of the L6 boss laser turret sprite graphics
	db $B2 ;Level 6 Final Boss
	db $D4 ;Level 6 Final Boss large tank
	db $01 ;Level 6 Boss Tank Flame Shot
	db $01 ;Level 6 Boss Tank Tip of Flame Shot
	db $12 ;parked jeep or tank
	db $A5 ;Level 6 Boss Tank Mounted Gun
	db $B2 ;50 Power up - destroys enemies
	db $B2 ;Power up - full bazooka
	db $B2 ;52 Power up - extra life
	db $12 ;Parked jeep or tank - with $52 star under it

;*****************
;LEVEL 6 ESCALATOR
;*****************
EscalatorSpriteLogic:	
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	dw EscalatorState0
	dw EscalatorState1
	dw subDespawnSprite

EscalatorState0:
	LDA CurrentLevelScreen
	CMP #$0A ;very cheese.  Below screen 10, the escalator has a smaller hitbox...
	BCC +
	LDA #$7F
	STA SpriteHitboxShapeIndex,X
+:	JSR subUpdateSpritePositionForScrolling
	LDA PPUGraphicsUpdateTableIndex ;Make sure we aren't overwriting another PPU Update
	BNE +
	LDA #$00 ;Clear the PPU Update complete flag
	STA PPUGraphicsUpdateComplete
	LDA #$08
	STA PPUGraphicsUpdateTableIndex
+:	JMP subMoveSpriteToNextState

EscalatorState1:
	INC SpriteData8,X ;Frame Counter.  Used to know when to cycle the graphics
	LDA SpriteData8,X
	AND #$07 ;Every 8 frames, cycle graphics
	BNE +
	LDA SpriteData1,X ;Graphics Index Counter
	AND #$01
	TAY
	LDA PPUGraphicsUpdateTableIndex
	BNE + ;Make sure we are not overwriting another PPU update
	LDA tblLevel6EscalatorPPUGraphicsUpdateIndex,Y ;Get the PPU update index
	STA PPUGraphicsUpdateTableIndex
	LDA #$00 ;Clear the PPU update complete flag
	STA PPUGraphicsUpdateComplete
	INC SpriteData1,X
+:	JMP subUpdateSpritePositionForScrolling_Speed_CheckForDespawn

tblLevel6EscalatorPPUGraphicsUpdateIndex:
	db $08,$09

;*************
;FLAME THROWER
;*************
FlameThrowerSpriteLogic:	
	LDA SpriteState,X
	AND #$7F
	JSR subExecuteCodeViaIndirectJump ;Acc has the index for the below table.  routine pulls the stack into $00 and $01 for a JMP ($00) which resumes code execution at one of the below addresses
	
	dw FlameThrowerState0
	dw FlameThrowerState1
	dw FlameThrowerState2
	dw FlameThrowerState3
	dw FlameThrowerState4
	dw subDespawnSprite

FlameThrowerState0:
	JSR subUpdateSpritePositionForScrolling
	LDA $06A0,X
	CLC
	ADC #$03
	STA SpriteData6,X
	LDA #$20 ;Multiply speed by 2, Flame Tank Code
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR subCalculateObjectSpeed
	JMP subMoveSpriteToNextState

FlameThrowerState1:
	LDA #$00
	STA $D7
	LDA SpriteWhichJeeptoAttack,X
	LSR
	BCC +
	JSR fctGetCollision_WithSpeed_NearLookAhead_BG
+:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteWhichJeeptoAttack,X
	BEQ +
	LDA $D7
	CMP #$01
	BEQ Label1350
	RTS
+:	LDA #$30
	STA SpriteWhichJeeptoAttack,X
	LDA SpriteData5,X
	STA SpriteTypeIndex,X
	JMP subMoveSpriteToNextState
Label1350:	JMP subDespawnSprite

FlameThrowerState2:
	LDA #$00
	STA $D7
	DEC SpriteWhichJeeptoAttack,X
	LDA SpriteWhichJeeptoAttack,X
	BEQ ++
	AND #$0F
	BNE +
	INC SpriteTypeIndex,X
+:	LDA SpriteWhichJeeptoAttack,X
	LSR
	BCC ++
	JSR fctGetCollision_WithSpeed_NearLookAhead_BG
++:	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	LDA SpriteWhichJeeptoAttack,X
	BEQ +
	LDA $D7
	CMP #$01
	BEQ +
	RTS
+:	LDA SpriteData6,X
	STA SpriteTypeIndex,X
	LDA #$10
	STA SpriteWhichJeeptoAttack,X
	JMP subMoveSpriteToNextState

FlameThrowerState3:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteWhichJeeptoAttack,X
	BEQ +
	RTS
+:	LDA #$92
	STA SpriteTypeIndex,X
	LDA #$00
	STA SpriteAttributes,X
	LDA #$20
	STA SpriteWhichJeeptoAttack,X
	LDA #$F0
	STA SpriteHitboxShapeIndex,X
	JSR subClearSpriteSpeed
-:	JMP subMoveSpriteToNextState

FlameThrowerState4:
	JSR subUpdateSpritePositionForScrolling_Speed_CheckForDespawn
	DEC SpriteWhichJeeptoAttack,X
	LDA SpriteWhichJeeptoAttack,X
	BEQ -
	AND #$07
	BNE +
	LDA SpriteAttributes,X
	CLC
	ADC #$40
	AND #$40
	STA SpriteAttributes,X
+:	RTS

subSpawnFlame:
	LDA #$34 ;Flame Object ID
	STA $08
	LDA SpriteWhatDirectionToShoot,X
	JSR fctGetSpriteOrientationIndex
	TYA ;Y contains the Direction to shoot / 4.  00 is right, increasing counterclockwise
	ASL ;Y is /4 then *4 probably to round to the lowest mutliple of 4
	ASL
	STA $0C
	JSR fctGetSpriteOrientationIndex
	LDA tblFlameSpriteMirroring_SpritIndex,Y
	AND #$F0
	STA $0F
	LDA tblFlameSpriteMirroring_SpritIndex,Y
	AND #$0F
	CLC
	ADC #$86
	STA $0A
	LDA #$08 ;Flame Infantry Projectile Invisibility Frames After Spawn
	STA $0E
	LDA SpriteObjectID,X
	CMP #$03 ;Flame thrower infantry ID
	BEQ +
	LDA #$10 ;Flame Tank Projectile Invisibility Frames After Spawn
	STA $0E
+:	JMP subSpawnObjectFromParent_NoOffset

tblFlameSpriteMirroring_SpritIndex:
	;Right
	db $00 ;No mirroring, base sprite index
	;Up-Right
	db $04 ;No mirroring, 2nd sprite tile set
	;Up
	db $08 ;No mirroring, 3rd sprite tile set
	;Up-Left
	db $44 ;Mirror horizontally, 2nd sprite tile set
	;Left
	db $40 ;Mirror horizontally, base sprite index
	;Down-Left
	db $C4 ;Mirror horizontally and vertically, 2nd sprite tile set
	;Down
	db $88 ;Mirror vertically, 3rd sprite tile set
	;Down-Right
	db $84 ;Mirror vertically, 2nd sprite tile set

Label474:
	;when the very large final boss tank is exploding
	LDA #$01
	STA Level6FinalBossFreezePlayerJeep_InvulnerableWhileExploding
	LDA Level6FinalBossDefeated_PPUUpdate_SoundClipInitiated ;for tank
	BNE ++
	;Pattern table is updated on death.  nametable is updated when explosions finish
	STA PPUGraphicsUpdateComplete ;A must be 0 here
	LDA #$0F ;Level 6 Final Boss Tank graphics update (defeated), plus mission accomplished text
	STA PPUGraphicsUpdateTableIndex
	LDA #Level6FinalBossBuildingBlowingUpSoundClip
	JSR subInitiateSoundClip
	LDA #$C0
	STA Level6FinalBossBuildingBlowingUpTimeUntilTankSpawns
	INC Level6FinalBossDefeated_PPUUpdate_SoundClipInitiated ;Set flag
	LDA #$55
	STA Level6FinalBossCurrentGraphics_PaletteUpdateIndex
	LDA #$65
	STA Level6FinalBossEndingGraphics_PaletteUpdateIndex
	RTS

;Handles all the explosions on the building when it is defeated.
;;Start Final Boss Tank Music.  Loads Tank Graphics
subFinalBossBuildingTransitionToFinalBossTank:
	LDA Level6FinalBossBuildingBlowingUpTimeUntilFinalBossMusicStarts
	CMP #$C0
	BEQ +
	INC Level6FinalBossBuildingBlowingUpTimeUntilFinalBossMusicStarts
	LDA Level6FinalBossBuildingBlowingUpTimeUntilFinalBossMusicStarts
	CMP #$C0 ;is this lda and cmp really necessary?
	BNE +
	LDA #Level6FinalBossMusic
	JSR subInitiateSoundClip
	;when the building is exploding
+:	LDA #$01 ;Lock player controls while the building explodes
	STA Level6FinalBossFreezePlayerJeep_InvulnerableWhileExploding
	LDA PPUGraphicsUpdateTableIndex
	BNE +
	STA PPUGraphicsUpdateComplete
	LDA #$11
	STA PPUGraphicsUpdateTableIndex
+:	LDA Level6FinalBossDefeated_PPUUpdate_SoundClipInitiated ;for building
	BNE ++
	STA ScreenVerticalScrollLockForBossFight ;A must be 0 here
	LDA #Level6FinalBossBuildingBlowingUpSoundClip
	JSR subInitiateSoundClip
	LDA #$2F
	JSR Label152
	LDX $35
	LDA #$3D ;first PPU update index
	STA Level6FinalBossCurrentGraphics_PaletteUpdateIndex
	LDA #$55 ;last PPU update index + 1
	STA Level6FinalBossEndingGraphics_PaletteUpdateIndex
	INC Level6FinalBossDefeated_PPUUpdate_SoundClipInitiated ;set flag
	RTS
++:	LDA RNG_INCEveryFrame
	AND #$0F
	BNE ++
	LDA #$03
	STA $00
	LDX #$10
-:	LDA $01
	ADC #$08
	CMP #$48
	BCC +
	LDA #$00
+:	STA $01
	DEX
	BPL +
++:	JMP Label1364
+:	LDA SpriteObjectID,X
	BNE - ;Looks like this is finding open object slots to generate the explosions
	LDY Level6FinalBossExplosionTableIndex
	LDA tblLevel6FinalBossBuilding_Random_ExplosionSpawnLocations,Y
	STA SpriteAbsoluteHorizPositionUB,X
	INY
	LDA tblLevel6FinalBossBuilding_Random_ExplosionSpawnLocations,Y
	STA SpriteAbsoluteHorizPositionLB,X
	LDA Level6BossTankScroll_Next
	BEQ ++
	LDA Level6BossTankScroll_Next
	CLC
	ADC $40
	STA SpriteAbsoluteHorizPositionLB,X
	BCC +
	LDA #$01
	STA SpriteAbsoluteHorizPositionUB,X
+:	LDA RNG_INCEveryFrame
	AND #$10
	BEQ +++
	CLC
	LDA SpriteAbsoluteHorizPositionLB,X
	ADC $01
	STA SpriteAbsoluteHorizPositionLB,X
	LDA #$00
	ADC SpriteAbsoluteHorizPositionUB,X
	JMP +
+++:	SEC
	LDA SpriteAbsoluteHorizPositionLB,X
	SBC $01
	STA SpriteAbsoluteHorizPositionLB,X
	LDA SpriteAbsoluteHorizPositionUB,X
	SBC #$00
+:	STA SpriteAbsoluteHorizPositionUB,X
++:	INY
	LDA #$00
	STA SpriteAbsoluteVertPositionUB,X
	LDA tblLevel6FinalBossBuilding_Random_ExplosionSpawnLocations,Y
	STA SpriteVertScreenPosition,X
	INY
	STY Level6FinalBossExplosionTableIndex
	LDA tblLevel6FinalBossBuilding_Random_ExplosionSpawnLocations,Y
	BPL + ;Check for the end of the table
	LDY #$00
	STY Level6FinalBossExplosionTableIndex
	;Haha, this is the gray turret object ID.  Any object would do here - 
	;;Any object that blows up when destoryed that is.  The state is immediately
	;;set to death, so all we see is the explosion..
+:	LDA #$85
	STA SpriteObjectID,X
	AND #$7F
	TAY
	LDA tblEnemyPoints_DeathState,Y
	AND #$0F ;Get the death state
	STA SpriteState,X ;Set the sprite to instant death
	DEC $00
	BEQ Label1364
	JMP -
Label1364:
	LDA Level6FinalBossBuildingBlowingUpTimeUntilTankSpawns
	SEC ;why not DEC Level6FinalBossBuildingBlowingUpTimeUntilTankSpawns?
	SBC #$01
	BEQ +
	STA Level6FinalBossBuildingBlowingUpTimeUntilTankSpawns
	LDX $35
	LDA #$01
	RTS

	;Structure is:
;;Horiz Position UB (Left/Right Screen), Horiz Position LB, Vert Position
tblLevel6FinalBossBuilding_Random_ExplosionSpawnLocations:
	db $00,$C0,$20
	db $01,$00,$30
	db $00,$E0,$40
	db $01,$40,$30
	db $00,$F0,$20
	db $01,$50,$30
	db $00,$B0,$40
	db $01,$20,$40
	db $00,$F0,$20
	db $01,$00,$30
	db $00,$C0,$20
	db $01,$20,$40
	db $00,$D0,$40
	
	db $FF ;End of table marker
	
+:	JSR subDespawnAllObjectsExceptFinalBoss
	LDA Level6FinalBossCurrentGraphics_PaletteUpdateIndex
	CMP Level6FinalBossEndingGraphics_PaletteUpdateIndex
	BCS +
	LDA Level6FinalBossCurrentGraphics_PaletteUpdateIndex
	JSR Label152
	LDX $35
	INC Level6FinalBossCurrentGraphics_PaletteUpdateIndex
	LDA Level6FinalBossCurrentGraphics_PaletteUpdateIndex
	CMP Level6FinalBossEndingGraphics_PaletteUpdateIndex ;is this lda and cmp really needed?
	BCC ++
+:	LDA #$00
	RTS
++:	LDA #$01
	RTS
	
subDespawnAllObjectsExceptFinalBoss:
	LDY #$0F
-:	LDA SpriteObjectID,Y
	CMP #$4A ;Level 6 Final Boss ID
	BEQ +
	CMP #$4B ;Level 6 Final Boss Tank ID
	BEQ +
	LDA #$00
	STA SpriteObjectID,Y
	STA SpriteTypeIndex,Y
+:	DEY
	BPL -
	RTS		

	.PAD $FDC9

tblMusicDPCMData:
;      LPFQ CNTR ADDR LEN
	db $0E,$00,$03,$18 ;DMC 0
	db $0F,$00,$00,$0C ;DMC 1
	db $FF
	
	
	.PAD $FDD2
	;***************
	;Free space here
	;***************
	
	
	.PAD $FFFA
	
	;Vector Table
	dw NMI_VECTOR
	dw RESET_VECTOR
	dw IRQ_BRK_VECTOR

	;END OF ROM*************