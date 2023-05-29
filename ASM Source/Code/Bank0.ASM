;Bank 00
	.BASE $8000
	
	;Bank table
	db $00,$01,$02,$03,$04,$05,$06,$07
	
subPlaySound_Music:
	;The intro music plays at a slower tempo
	LDA TriangleMusicIndex ;this is pretty much always the same as Pulse1 and Pulse2 primary music indices
	CMP #GameStartedIntroSoundClip
	BNE +
	DEC AudioTempo
	BNE ++
	LDA #$09
	STA AudioTempo
	RTS
	
	;The End of Game music plays at a slightly slower tempo
+:	CMP #GameCompleteMusic
	BNE ++
	DEC AudioTempo
	BNE ++
	LDA #$15
	STA AudioTempo
	RTS
	
	;Play game paused sound and stop music
++:	LDA GamePaused
	BEQ +
	;Game paused
	CMP GamePaused_Previous
	BEQ ++
	;Game Paused - 1st frame
	JSR subTurnOffAllAudio ;Game was just paused, turn off the music
	JMP ++
	;Game NOT paused
+:	CMP GamePaused_Previous
	BEQ ++
	;Game has been unpaused - 1st frame.  Continue music
	;But, if the game was paused and unpaused quickly, the pause sound clip will
	;;still be playing.  if it is, we should not update the music as it can have
	;;a very bad audio sound if the music mixes with the pause sound.
	LDA Pulse1SoundEffectIndex_MusicOverride
	CMP #PauseGameSoundClip
	BEQ ++
	;No pause sound playing
	JSR subUpdatePulseChannel1
	JSR subUpdatePulseChannel2
	;Pause sound clip is still playing
++:	LDA GamePaused
	STA GamePaused_Previous
	
	;**************************
	;Process the sound channels
	;**************************
	LDX #$00
	LDY #$00
-:	TXA
	ASL
	ASL ;Multiply by 4 because each channel has 4 registers associated with it
	STA AudioChannel_OffsetFrom4000 ;use wraps around after noise channel
	LDA CurrentSound_MusicIndex,X
	BEQ + ;No sound to play
	JSR subProcessSoundChannel
+:	INX ;Go to the next sound register/channel
	;7 registers are tracked.  registers 0-3 are the normal PPTN, 4-5 are used
	;;to override the music to play sound effects on P1/P2.  register 6 is for DMC
	CPX #$07
	BNE -
	RTS
	
subProcessSoundChannel:
	JSR subResetY_MoveAudioDataAddressToE6
	LDA GamePaused
	BEQ +
	;Game Paused
	LDA CurrentSound_MusicIndex,X
	CMP #PauseGameSoundClip
	BEQ +
	;Pause sound clip complete
-:	RTS
+:	DEC NoteDuration_DelayUntilNextSound,X
	BNE +
	JMP subProcessAudioCommand
	;Only update the pulse channels?
+:	CPX #$06
	BEQ -
	CPX #$02
	BEQ -
	CPX #$03
	BEQ -
	
	LDA $013C,X
	LSR
	BCC -
	LDA $01B0,X
	AND #$0F
	BNE +
	RTS
+:	LDA NoteDuration_DelayUntilNextSound,X
	CMP $019E,X
	BCC +++++
	LDA $013C,X
	AND #$10
	BEQ +
	LDA $01AA,X
	BEQ +++
	DEC $01AA,X
	JMP ++++++
+:	LDA $0192,X
	ASL
	TAY
	LDA tblPulseNoteFade,Y
	STA $E0
	LDA (tblPulseNoteFade + 1),Y
	STA $E1
-:	LDA $01AA,X
	INC $01AA,X
	TAY
	LDA ($E0),Y
	CMP #$FE
	BCC +
	BEQ ++
	DEC $01AA,X ;The end of the 'note data' was reached.  reverse the INC above to wait at this index until time for the next note
	JMP +++
++:	INY
	LDA ($E0),Y
	STA $01AA,X
	BNE -
+:	LDA ($E0),Y
	BEQ ++++
	STA $01B0,X
	JMP +++
+++++:	LDA $01A4,X
	BEQ +
	DEC $01A4,X
	BNE ++
+:	LDA $0198,X
	LSR
	LSR
	LSR
	LSR
	STA $01A4,X
++++++:	LDA $01B0,X
	CMP #$01
	BEQ +++
	DEC $01B0,X
+++:	LDA $01B0,X
	SEC
	SBC $01B6,X
	BEQ +
	BCS ++++
+:	LDA #$01
++++	ORA $0186,X
	JSR fctCheckForPulse1_2SoundOverride
	BCS ++
	JMP Label28
++:	RTS

subProcessNextAudioCommand:
	INY
subProcessAudioCommand:
	LDA ($E6),Y
	CMP #$FB
	BCS +
	JMP Label30
+:	SEC
	SBC #$FB
	JSR subExecuteCodeViaIndirectJump_Music
	
	dw Process_FB_Command ;FB
	dw Process_FC_Command ;FC
	dw Process_FD_Command ;FD
	dw Process_FE_Command ;FE
	dw Process_FF_Command ;FF

Process_FB_Command:
Process_FC_Command:
	JSR Label32
	LDA AudioDataAddressLB,X
	STA AudioDataBaseAddressLB,X
	LDA AudioDataAddressUB,X
	STA AudioDataBaseAddressUB,X
	JSR subResetY_MoveAudioDataAddressToE6
	JMP subProcessAudioCommand

Process_FD_Command:
	LDA $013C,X
	ORA #$02
	STA $013C,X
	JSR Label33
	JSR Label34
	JSR subResetY_MoveAudioDataAddressToE6
	JMP subProcessAudioCommand

Process_FE_Command:
	INY
	LDA ($E6),Y
	CMP #$FF
	BEQ +++
	LDA $0158,X
	CLC
	ADC #$01
	CMP ($E6),Y
	BEQ ++
	BMI +
	SEC
	SBC #$01
+:	STA $0158,X
	LDA AudioDataBaseAddressLB,X
	STA AudioDataAddressLB,X
	LDA AudioDataBaseAddressUB,X
	STA AudioDataAddressUB,X
	JSR subResetY_MoveAudioDataAddressToE6
	JMP subProcessAudioCommand
+++:	JSR Label33
	JSR subResetY_MoveAudioDataAddressToE6
	JMP subProcessAudioCommand
++:	LDA #$00
	STA $0158,X
	INY
	TYA
	CLC
	ADC $E6
	STA AudioDataAddressLB,X
	LDA #$00
	ADC $E7
	STA AudioDataAddressUB,X
	JSR subResetY_MoveAudioDataAddressToE6
	JMP subProcessAudioCommand
	
Process_FF_Command:
	LDA $013C,X
	AND #$02
	BEQ +
	LDA $013C,X
	AND #$FD
	STA $013C,X
	LDA $014A,X
	STA AudioDataAddressLB,X
	LDA $0151,X
	STA AudioDataAddressUB,X
	JSR subResetY_MoveAudioDataAddressToE6
	JMP subProcessAudioCommand

+:	LDA CurrentSound_MusicIndex,X
	STA $E0 ;Preserve A
	LDA #$00
	STA CurrentSound_MusicIndex,X
	STA $0174,X
	STA $013C,X
	LDA $E0 ;Restore A
	CMP #GameStartedIntroSoundClip
	BNE +
	LDA #Level1Music ;hard-coded for intro
	JMP Label40
+:	CMP #$23
	BNE +
	LDA #EMPTYSoundClip
	JSR Label40
	LDA #BossMusicSoundClip
	JMP Label40
+:	CPX #$06
	BEQ +++ ;RTS
	CPX #$04
	BNE +
	LDA Pulse1MusicIndex
	BEQ ++
	LDA $0194
	BNE ++
	JMP subUpdatePulseChannel1
+:	CPX #$05
	BNE ++
	LDA Pulse2MusicIndex
	BEQ ++
	LDA $0194
	BNE ++
	JMP subUpdatePulseChannel2
	
++:	LDA #$00
	STA $0174,X
	STA $013C,X
	
	CPX #$02
	BEQ +
	LDA #$30
+:	JSR fctCheckForPulse1_2SoundOverride
	BCS +++
	JMP Label28
+++:	RTS

Label30:
	LDA $013C,X
	AND #$01
	BEQ Label46
	JMP subProcessAudioCommandData
Label46:	LDA AudioChannel_OffsetFrom4000
	LSR
	LSR
	AND #$03 ;AudioChannel_OffsetFrom4000 values 4 and 5 override music on Pulse1/Pulse2 with sound effects
	STA $E0 ;Preserve A
	LDA ($E6),Y
	AND #$F0
	BNE +
	LDA $E0 ;Restore A
	JSR subExecuteCodeViaIndirectJump_Music

	dw ProcessPulseChannel ;(Pulse 1)
	dw ProcessPulseChannel ;(Pulse 2)
	dw ProcessTriangleChannel
	dw ProcessNoiseChannel

+:	LDA $0143,X
	STA NoteDuration_DelayUntilNextSound,X
	CPX #$03 ;Noise channel
	BNE Label49 ;all other channels processing
	JMP Label50 ;noise channel processing

ProcessPulseChannel:
	LDA ($E6),Y
	BNE +
	INY
	LDA ($E6),Y
+:	STA $0143,X
	INY
	LDA ($E6),Y
	AND #$F0
	STA $0186,X
	INY
	LDA $013C,X
	ORA #$08
	STA $013C,X
	LDA ($E6),Y
	CMP #$88
	BNE +
	LDA $013C,X
	AND #$F7
	STA $013C,X
+:
-:	LDA ($E6),Y
	JSR fctCheckForPulse1_2SoundOverride
	BCS +
	JSR Label54
+:	JMP subProcessNextAudioCommand

ProcessTriangleChannel:
	LDA ($E6),Y
	STA $0143,X
	INY
	JMP -

ProcessNoiseChannel:
	LDA ($E6),Y
	BEQ +
	STA $0143,X
	LDA #$30
	STA $0186,X
	JMP -
+:	INY
	JMP Label46
	
Label49:
	LDA ($E6),Y
	CMP #$F8
	BNE +
	INY
	LDA ($E6),Y
	STA $015F,X
	LDA #$04
	ORA $013C,X
	STA $013C,X
	JMP subProcessNextAudioCommand
+:	LSR
	LSR
	LSR
	LSR
	ORA $0186,X
	JSR fctCheckForPulse1_2SoundOverride
	BCS Label58
	JSR Label28
Label58:
	LDA ($E6),Y
	AND #$07
	STA $E0
	INY
	LDA ($E6),Y
	STA $E1
-:	JSR Label59
	JMP Label32
Label50:
	LDA ($E6),Y
	LSR
	LSR
	LSR
	LSR
	ORA $0186,X
	JSR Label28
	LDA ($E6),Y
	AND #$07
	STA $E0
	LDA ($E6),Y
	AND #$0F
	STA $E1
	JMP -
	
subProcessAudioCommandData:
	LDA ($E6),Y
	AND #$F0
	CMP #$D0
	BEQ +
	JMP Label62
	;D# Command
+:	LDA ($E6),Y
	AND #$0F
	STA $0143,X
	INY
	CPX #$06 ;Pulse 2 override sound effect channel
	BNE +
	JMP subProcessAudioCommand
+:	LDA ($E6),Y
	STA $0180,X
	CPX #$02 ;Triangle channel
	BNE +
	JMP subProcessNextAudioCommand
+:	AND #$F0
	STA $0186,X
	LDA $0180,X
	AND #$0F
	STA $01B6,X
	INY
	CPX #$02 ;Triangle channel
	BNE +
	JMP Label62
+:	LDA ($E6),Y
	STA $0192,X
	AND #$80
	BEQ +
	LDA ($E6),Y
	AND #$0F
	STA $01AA,X
	LDA #$00
	STA $01B6,X
	LDA $013C,X
	ORA #$10
	BNE ++
+:	LDA $013C,X
	AND #$EF
++:	STA $013C,X
	INY
	LDA ($E6),Y
	STA $0198,X
	JMP subProcessNextAudioCommand

Label62:
	LDA ($E6),Y
	CMP #$E8
	BNE +
	;E8 Command
	LDA $013C,X
	EOR #$04
	STA $013C,X
	JMP subProcessNextAudioCommand
+:	AND #$F0
	;All other E# commands
	CMP #$E0
	BNE +
	LDA ($E6),Y
	AND #$0F ;get lower nibble (#) of E# command
	STA $018C,X
	JMP subProcessNextAudioCommand
+:	CMP #$F0
	BNE Label70
	;F# Command (AND'd above with F0)
	LDA ($E6),Y
	AND #$0F  ;get lower nibble (#) of F# command
	STA $01B6,X
	JMP subProcessNextAudioCommand
	
Label83:
	LDA ($E6),Y
	LSR
	LSR
	LSR
	LSR
	CMP #$03
	BNE +
	LDA #$0B
	BNE ++
+:	CMP #$04
	BNE +
	LDA #$0A
++:	JSR WriteDMCData
	LDA #$03
+:	CMP #$0C
	BEQ ++
	TAX
	CMP #$09
	BEQ +
	BCS WriteDMCData
+:	LDA table4,X
	JSR Label40
	JSR subWAIT_RestoreAudioIndexToX
++:	RTS

WriteDMCData:
	SEC
	SBC #$0A
	ASL
	ASL
	CLC
	ADC #$03 ;This moves the pointer to the last byte, so the data can be read last to first
	TAX
	LDA #$0F ;disable DMC while it is being updated
	STA APUSTATUS
	TYA
	PHA
	LDY #$03 ;Writes DMC registers backwards, last to first
-:	LDA tblMusicDPCMData,X
	STA APU_DMC ,Y
	DEX
	DEY
	BPL -
	PLA
	TAY
	LDA #$1F ;Turn DMC back on
	STA APUSTATUS
	JMP subWAIT_RestoreAudioIndexToX

;Affects Pulse1 and Noise channels
;The music/sound index to play
table4:
	db $04,$05,$03,$06,$06,$06,$07,$07,$17,$25
	
Label70:
	JSR Label32
+:	DEY
	LDA ($E6),Y
	AND #$0F
	STA $E0
	BEQ ++
	LDA $0143,X
	CLC
-:	ADC $0143,X
	DEC $E0
	BNE -
	BEQ +
++:	LDA $0143,X
+:	STA NoteDuration_DelayUntilNextSound,X
	CPX #$06
	BNE +
	JMP Label83
+:	LDA ($E6),Y
	AND #$F0
	CMP #$C0
	BNE +++
	LDA #$00
	STA $01B0,X
	CPX #$02
	BEQ +
	LDA #$30
	ORA $0186,X
	JSR fctCheckForPulse1_2SoundOverride
	BCS ++
+:	JMP Label28
++:	RTS
+++:	LDA $0180,X
	CPX #$02
	BEQ Label87
	LDA $0198,X
	AND #$0F
	STA $E0
	BEQ ++
	LDA #$00
	STA $E1
-:	CLC
	ADC NoteDuration_DelayUntilNextSound,X
	BCC +
	INC $E1
+:	DEC $E0
	BNE -
	STA $E0
	LDA #$04
	STA $E9
-:	LSR $E1
	ROR $E0
	DEC $E9
	BNE -
	LDA $E0
++:	STA $019E,X
	LDA $013C,X
	AND #$10
	BNE ++
	TYA
	PHA ;Preserve Y
	LDA $0192,X
	ASL
	TAY
	LDA tblPulseNoteFade,Y
	STA $E0
	LDA (tblPulseNoteFade + 1),Y
	STA $E1
	LDY #$00
	LDA ($E0),Y
	ORA $0186,X
	STA $0180,X
	LDA #$01
	STA $01AA,X
	PLA
	TAY ;Restore Y
	JMP +
++:	LDA $0192,X
	AND #$0F
	STA $01AA,X
+:	LDA $0180,X
	AND #$0F
	STA $01B0,X
	SEC
	SBC $01B6,X
	BCS +
	LDA #$00
+:	ORA $0186,X
	JSR fctCheckForPulse1_2SoundOverride
	BCS Label95
Label87:	JSR Label28
Label95:	LDA ($E6),Y
	LSR
	LSR
	LSR
	LSR
	ASL
	TAY
	LDA table3,Y
	STA $E0
	LDA (table3 + 1),Y
	STA $E1
	LDY $018C,X
-:	TYA
	CMP #$04
	BEQ Label59
	LSR $E0
	ROR $E1
	INY
	JMP -
Label59:	LDA $013C,X
	AND #$04
	BEQ +
	INC $E1
	BNE +
	INC $E0
+:	LDA $E0
	ORA #$08
	STA $E0
	CPX #$02
	BEQ +++
	CMP $0174,X
	BNE +
	CPX #$03
	BEQ ++
	LDA $0186,X
	AND #$10
	BEQ +++
	LDA $013C,X
	AND #$08
	BNE +++
	BEQ ++
+:	STA $0174,X
+++:	LDA $E0
	JSR fctCheckForPulse1_2SoundOverride
	BCS ++
	JSR Label101
++:	LDA $E1
	STA $017A,X
	JSR fctCheckForPulse1_2SoundOverride
	BCS +
	JSR Label103
+:	RTS

table3:
	db $06,$AE,$06,$4E,$05,$F4,$05,$9E,$05,$4E,$05,$01,$04,$B9,$04,$76
	db $04,$36,$03,$F9,$03,$C0,$03,$8A

;I assume this is a exists due to a timing concern
subConsumeCPUCycles_8NOP:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RTS
	
subResetY_MoveAudioDataAddressToE6:	
	LDY #$00
	LDA AudioDataAddressLB,X
	STA $E6
	LDA AudioDataAddressUB,X
	STA $E7
	RTS

Label32:
	INY
	TYA
	CLC
	ADC $E6
	STA AudioDataAddressLB,X
	BCC +
	LDA $E7
	ADC #$00
	STA AudioDataAddressUB,X
+:	RTS

Label33:
	INY
	LDA ($E6),Y
	STA AudioDataAddressLB,X
	INY
	LDA ($E6),Y
	STA AudioDataAddressUB,X
	RTS

Label34:
	INY
	TYA
	CLC
	ADC $E6
	STA $014A,X
	LDA $E7
	ADC #$00
	STA $0151,X
	RTS
	
Label28:
	JSR fctGetAudioChannel_MaskFromOffset_X
	STA APU_PULSE_DDLCVVVV ,X
	JMP subWAIT_RestoreAudioIndexToX

Label54:
	JSR fctGetAudioChannel_MaskFromOffset_X
	STA APU_PULSE_EPPPNSSS ,X
	JMP subWAIT_RestoreAudioIndexToX
	
Label103:
	JSR fctGetAudioChannel_MaskFromOffset_X
	STA APU_PULSE_TTTTTTTT ,X
	JMP subWAIT_RestoreAudioIndexToX
	
Label101:
	JSR fctGetAudioChannel_MaskFromOffset_X
	STA APU_PULSE_LLLLLTTT ,X
	JMP subWAIT_RestoreAudioIndexToX
	
fctGetAudioChannel_MaskFromOffset_X:
	STA $E0 ;Preserve A
	LDA AudioChannel_OffsetFrom4000
	AND #$0F
	TAX
	LDA $E0 ;Restore A
	RTS

subWAIT_RestoreAudioIndexToX:
	JSR subConsumeCPUCycles_8NOP
	LDA AudioChannel_OffsetFrom4000
	LSR
	LSR
	TAX
	RTS
	
fctCheckForPulse1_2SoundOverride:
	PHA ;Preserve A
	CPX #$00
	BNE +++
	;X=0, pulse 1 channel
	LDA Pulse1SoundEffectIndex_MusicOverride
	BEQ ++
	BNE + ;override exists
+++:	CPX #$01
	BNE ++
	;X=1, pulse 2 channel
	LDA Pulse2SoundEffectIndex_MusicOverride
	BEQ ++
	;override exists
+:	SEC
	PLA ;Restore A
	RTS
++:	CLC
	PLA ;Restore A
	RTS

subTurnOffAllAudio:	
	LDA #$30 ;set volume to 0
	STA APU_PULSE_DDLCVVVV
	JSR subConsumeCPUCycles_8NOP
	STA APU_PULSE2_DDLCVVVV
	JSR subConsumeCPUCycles_8NOP
	STA APU_NOISE_XXLCVVVV
	JSR subConsumeCPUCycles_8NOP
	LDA #$00 ;set counter to 0
	STA APU_TRIANGLE_CRRRRRRR
	RTS
	
subUpdatePulseChannel1:
	TXA
	PHA ;Perserve X
	TYA
	PHA ;Preserve Y
	LDY #$00
	LDX #$00
	JSR subUpdatePulseChannel
	PLA
	TAY ;Restore Y
	PLA
	TAX ;Restore X
	RTS
	
subUpdatePulseChannel2:
	TXA
	PHA ;Preserve X
	TYA
	PHA ;Preserve Y
	LDY #$04
	LDX #$01
	JSR subUpdatePulseChannel
	PLA
	TAY ;Restore Y
	PLA
	TAX ;Restore X
	RTS
	
subUpdatePulseChannel:
	LDA #$7F
	STA APU_PULSE_EPPPNSSS ,Y
	JSR subConsumeCPUCycles_8NOP
	LDA $017A,X
	STA APU_PULSE_TTTTTTTT ,Y
	JSR subConsumeCPUCycles_8NOP
	LDA $0174,X
	STA APU_PULSE_LLLLLTTT ,Y
	JSR subConsumeCPUCycles_8NOP
	LDA GamePaused
	BNE ++++
	LDA CurrentSound_MusicIndex,X
	BEQ ++++
	LDA $013C,X
	AND #$01
	BEQ +++
	LDA $01B0,X
	SEC
	SBC $01B6,X
	BEQ ++
	BCS +
++:	LDA #$01
+:
-:	ORA $0186,X
	JMP +
+++:	LDA $01B0,X
	JMP -
++++	LDA $0186,X
+:	STA APU_PULSE_DDLCVVVV ,Y
	JSR subConsumeCPUCycles_8NOP
	RTS

	;a duplicate of the code in bank 7.  performs the same function.
subExecuteCodeViaIndirectJump_Music:	
	ASL ;*2 for 16 bit addresses
	STX $EA
	STY $E9 ;Preserve Y
	TAY
	INY ;This is done because JSR pushes the PC of the next memory location - 1.
	
	;Pull the address of the table from the stack
	PLA
	STA $E0
	PLA
	STA $E1
	
	;Get the table data/address
	LDA ($E0),Y
	TAX
	INY
	LDA ($E0),Y
	STA $E1
	STX $E0
	LDY $E9 ;Restore Y
	LDX $EA
	JMP ($E0)
	
tblStartOfMusicData:
	;minus 3 because each sound index is 3 bytes and this is 1-based
	dw (tblSound_MusicData - 3)
	
Label40:
	STA NextMusic_SoundIndexToPlay
	CMP #GameStartedIntroSoundClip
	BNE +
	LDA #$01
	STA AudioTempo
+:	CMP #Level6FinalBossBuildingBlowingUpSoundClip
	BNE +
	JSR ++
	LDA #Level6FinalBossBuildingBlowingUpSoundClip
	JMP +++
+:	CMP #EMPTYSoundClip
	BNE +++
++:	LDA #$01
	STA AudioTempo
	TXA
	PHA ;Preserve X
	LDA #$00
	LDX #$07
-:	DEX
	STA CurrentSound_MusicIndex,X
	STA $0174,X
	STA $013C,X
	BNE -
	PLA
	TAX;Restore X
	
	JMP subTurnOffAllAudio
	LDA #$01
	BNE +
	LDA #$00
+:	STA $0194
+++:	TXA
	PHA ;Preserve X
	TYA
	PHA ;Preserve Y

	;Load the default starting address for the music data.
	;;The index will be added to this to find the correct data
	LDX #$03 ;Each music/sound entry is 3 bytes
	LDA tblStartOfMusicData
	STA $EC
	LDA (tblStartOfMusicData + 1)
	STA $ED
	;Multiply the index by 3 to get the correct address
-:	LDA NextMusic_SoundIndexToPlay
	CLC
	ADC $EC
	STA $EC
	LDA #$00
	ADC $ED
	STA $ED
	DEX
	BNE -
	
	LDY #$00
	STY tblSoundOffsetFromBase ;Tracks the index in tblSound_MusicData
	LDA ($EC),Y
	;Roll through Carry.  put top 2 bits in lower 2 bits
	ROL
	ROL
	ROL
	AND #$03 ;mask these bits off
	STA tblSoundClipIndexCount ;Read the number of additional simultaneous sound clips to play
	JMP Label123
	JMP Label124 ;CODE IS NEVER REACHED
-:	JMP subClearED_RestoreXY

Label123:
	LDY tblSoundOffsetFromBase
	LDA ($EC),Y
	AND #$1F
	STA $01BF
	LSR
	LSR
	TAX
	LDA NextMusic_SoundIndexToPlay
	BEQ +
	CMP CurrentSound_MusicIndex,X
	BCC -
+:	LDA #$00
	STA CurrentSound_MusicIndex,X
	LDY tblSoundOffsetFromBase
	INY
	LDA ($EC),Y
	STA AudioDataAddressLB,X
	STA AudioDataBaseAddressLB,X
	STA $E2
	INY
	LDA ($EC),Y
	STA AudioDataAddressUB,X
	STA AudioDataBaseAddressUB,X
	STA $E3
	LDA #$01 ;Set the duration to 1 so the next frame will decrement to 0 and get the next sound
	STA NoteDuration_DelayUntilNextSound,X
	LDA #$00
	STA $0158,X
	CPX #$02 ;Triangle channel
	BEQ +
	CPX #$05 ;Pulse 2 channel sound effect override
	BEQ +
	STA $0174,X
	CPX #$03 ;Noise channel
	BEQ ++
+:	LDY #$00
	LDA ($E2),Y
	BNE +
	STA NextMusic_SoundIndexToPlay
	CPX #$03 ;Noise channel
	BEQ ++
+:	AND #$F0
	CMP #$00
	BEQ +++
	LDA #$01
	BNE +
+++:	LDA #$00
+:	STA $013C,X
++:	LDA $01BF
	AND #$0F
	TAY
	CPX #$00
	BNE +
	LDA Pulse1SoundEffectIndex_MusicOverride
	BNE ++
+:	CPX #$01
	BNE +
	LDA Pulse2SoundEffectIndex_MusicOverride
	BNE ++
+:	LDA #$00
	CPX #$02
	BNE +
	JMP ++
+:	LDA #$30
	STA APU_PULSE_DDLCVVVV ,Y
	JSR subConsumeCPUCycles_8NOP	
	LDA #$7F
	STA APU_PULSE_EPPPNSSS ,Y
	JSR subConsumeCPUCycles_8NOP
++:	LDA NextMusic_SoundIndexToPlay
	STA CurrentSound_MusicIndex,X
Label124:	DEC tblSoundClipIndexCount
	BMI subClearED_RestoreXY ;If there are more sounds to play along with the main one, then loop again
	LDY tblSoundOffsetFromBase
	INY
	INY
	INY
	STY tblSoundOffsetFromBase
	JMP Label123
	
subClearED_RestoreXY:
	LDA #$00
	STA $ED
	PLA
	TAY ;Restore Y
	PLA
	TAX ;Restore X
	RTS

;****************
;Sounds and Music
;****************

;Sound Header:
;76543210
;|||+++++	Sound Channel
;||+		NOT USED
;++		How many subsequent/consecutive sound clips to play simultaneously with the current sound clip

tblSound_MusicData:
	;(see Macros.asm)
	;    Clip Count  Chnl  Clip Address
	;       ----|     |     |----
	;           ----| | |----
	SoundDefinition 1,4,tblSound1Definition ;1 NOT USED
	SoundDefinition 0,3,tblSound1_2Definition ;NOT USED
	
	SoundDefinition 0,3,tblSound3Definition ;3
	SoundDefinition 0,3,tblSound4_5Definition ;4
	SoundDefinition 0,3,tblSound4_5Definition ;5
	SoundDefinition 0,3,tblSound_MusicPercussion_SymbolInstrumentDefinition ;6
	SoundDefinition 0,3,tblSound7Definition ;7
	SoundDefinition 0,3,tblSound_WaterSplashDefinition ;8
	SoundDefinition 0,3,tblSound_BulletFiringDefinition ;9
	SoundDefinition 0,5,tblSound_BomberPlaneRoarDefinition ;A
	SoundDefinition 0,4,tblSound_LaserBlastDefinition ;B
	SoundDefinition 1,4,tblSound_HelicopterBladesWhirringDefinition ;C
	SoundDefinition 0,3,tblSound_HelicopterBladesWhirring2Definition
	;Not Used?? this is the same as above but on Pulse Channel 2.  never seems to play
	SoundDefinition 1,5,tblSound_HelicopterBladesWhirring3Definition ;E
	SoundDefinition 0,3,tblSound_HelicopterBladesWhirring4Definition
	;******************************************************************************
	SoundDefinition 0,4,tblSound_BulletHitTinkDefinition ;10
	SoundDefinition 0,4,tblSound_GrenadeThrow_BombDefinition ;11
	SoundDefinition 0,4,tblSound_InfantrySquishDefinition ;12
	SoundDefinition 1,4,tblSound_BazookaLaunchDefinition ;13
	SoundDefinition 0,3,tblSound_BazookaLaunch2Definition
	SoundDefinition 0,3,tblSound_BlackAndWhite_SmallMissile_Bomb_LaserBlastHitsGroundDefinition ;15
	SoundDefinition 0,3,tblSound_BazookaHitsGroundDefinition ;16
	SoundDefinition 1,4,tblSound_MainWeaponExplosionOnEnemyDefinition ;17
	SoundDefinition 0,3,tblSound_MainWeaponExplosionOnEnemy2Definition
	SoundDefinition 1,4,tblSound_Level6FinalBossTankFlameShotDefinition ;19
	SoundDefinition 0,3,tblSound_Level6FinalBossTankFlameShot2Definition
	SoundDefinition 1,4,tblSound_POWBuildingOpeningDefinition ;1B
	SoundDefinition 0,3,tblSound_POWBuildingOpening2Definition
	SoundDefinition 1,4,tblSound_POWPickedUpDefinition ;1D
	SoundDefinition 0,5,tblSound_POWPickedUp2Definition
	SoundDefinition 1,4,tblSound_POWEnteringHeliDefinition ;1F
	SoundDefinition 0,5,tblSound_POWEnteringHeli2Definition
	SoundDefinition 1,4,tblSound_WeaponUpgradeDefinition ;21
	SoundDefinition 0,5,tblSound_WeaponUpgrade2Definition
	SoundDefinition 1,4,tblSound_WeepWeepBossMusic_F0Definition ;23
	SoundDefinition 0,5,tblSound_WeepWeepBossMusic_F02Definition
	SoundDefinition 0,3,tblSound_JeepDeathDefinition ;25
	SoundDefinition 0,4,tblSound_ExtraLifeDefinition ;26
	SoundDefinition 0,6,tblSound_Level6BossBuildingBlowingUpDefinition ;27
	SoundDefinition 1,0,tblSound_EndOfGameHelicopterDefinition ;28
	SoundDefinition 0,1,tblSound_EndOfGameHelicopter2Definition
	SoundDefinition 2,4,tblSound_POWPortraitScrollIntoPlace_ShingDefinition ;2A
	SoundDefinition 0,5,tblSound_POWPortraitScrollIntoPlace_Shing2Definition
	SoundDefinition 0,3,tblSound_POWPortraitScrollIntoPlace_Shing3Definition
	SoundDefinition 0,4,tblSound_POWPortraitTextPrintDefinition ;2D
	SoundDefinition 1,4,tblSound_Level6BossDefeated_MissionAccomplishedTextDefinition ;2E
	SoundDefinition 0,3,tblSound_Level6BossDefeated_MissionAccomplishedText2Definition
	SoundDefinition 3,0,tblSound_TitleScreenStory_POWPortraitsDefinition ;30
	SoundDefinition 0,1,tblSound_TitleScreenStory_POWPortraits2Definition
	SoundDefinition 0,2,tblSound_TitleScreenStory_POWPortraits3Definition
	SoundDefinition 0,6,tblSound_TitleScreenStory_POWPortraits4Definition
	SoundDefinition 3,0,tblSound_GameStartedIntroDefinition ;34
	SoundDefinition 0,1,tblSound_GameStartedIntro2Definition
	SoundDefinition 0,2,tblSound_GameStartedIntro3Definition
	SoundDefinition 0,6,tblSound_GameStartedIntro4Definition
	SoundDefinition 3,0,tblSound_Level1MusicDefinition ;38
	SoundDefinition 0,1,tblSound_Level1Music2Definition
	SoundDefinition 0,2,tblSound_Level1Music3Definition
	SoundDefinition 0,6,tblSound_Level1Music4Definition
	SoundDefinition 3,0,tblSound_Level2MusicDefinition ;3C
	SoundDefinition 0,1,tblSound_Level2Music2Definition
	SoundDefinition 0,2,tblSound_Level2Music3Definition
	SoundDefinition 0,6,tblSound_Level2Music4Definition
	SoundDefinition 3,0,tblSound_Level3MusicDefinition ;40
	SoundDefinition 0,1,tblSound_Level3Music2Definition
	SoundDefinition 0,2,tblSound_Level3Music3Definition
	SoundDefinition 0,6,tblSound_Level3Music4Definition
	SoundDefinition 3,0,tblSound_BossMusicDefinition ;44
	SoundDefinition 0,1,tblSound_BossMusic2Definition
	SoundDefinition 0,2,tblSound_BossMusic3Definition
	SoundDefinition 0,6,tblSound_BossMusic4Definition
	SoundDefinition 3,0,tblSound_FinalBossMusicDefinition ;48
	SoundDefinition 0,1,tblSound_FinalBossMusic2Definition
	SoundDefinition 0,2,tblSound_FinalBossMusic3Definition
	SoundDefinition 0,6,tblSound_FinalBossMusic4Definition
	SoundDefinition 3,0,tblSound_StageCompleteSegueDefinition ;4C
	SoundDefinition 0,1,tblSound_StageCompleteSegue2Definition
	SoundDefinition 0,2,tblSound_StageCompleteSegue3Definition
	SoundDefinition 0,6,tblSound_StageCompleteSegue4Definition
	SoundDefinition 3,0,tblSound_GameOverContinueDefinition ;50
	SoundDefinition 0,1,tblSound_GameOverContinue2Definition
	SoundDefinition 0,2,tblSound_GameOverContinue3Definition
	SoundDefinition 0,6,tblSound_GameOverContinue4Definition
	SoundDefinition 3,0,tblSound_EndOfGameDefinition ;54
	SoundDefinition 0,1,tblSound_EndOfGame2Definition
	SoundDefinition 0,2,tblSound_EndOfGame3Definition
	SoundDefinition 0,6,tblSound_EndOfGame4Definition
	SoundDefinition 0,4,tblSound_PauseDefinition ;59


;***************
;Pulse Note Fade
;***************
tblPulseNoteFade:
	dw tblPulseNoteFade00
	dw tblPulseNoteFade01
	dw tblPulseNoteFade02
	dw tblPulseNoteFade03
	dw tblPulseNoteFade04
	dw tblPulseNoteFade05
	dw tblPulseNoteFade06
	dw tblPulseNoteFade07
	dw tblPulseNoteFade08
	dw tblPulseNoteFade09
	dw tblPulseNoteFade0A
	dw tblPulseNoteFade0B
	dw tblPulseNoteFade0C
	dw tblPulseNoteFade0D
	dw tblPulseNoteFade0E
	dw tblPulseNoteFade0F
	dw tblPulseNoteFade10
	dw tblPulseNoteFade11
	dw tblPulseNoteFade12
	dw tblPulseNoteFade13
	dw tblPulseNoteFade14
	dw tblPulseNoteFade15
	dw tblPulseNoteFade16
	dw tblPulseNoteFade17
	dw tblPulseNoteFade18
	dw tblPulseNoteFade19
	dw tblPulseNoteFade1A
	dw tblPulseNoteFade1B
	dw tblPulseNoteFade1C
	dw tblPulseNoteFade1D
	dw tblPulseNoteFade1E
	dw tblPulseNoteFade1F
	dw tblPulseNoteFade20
	dw tblPulseNoteFade21
	dw tblPulseNoteFade22
	dw tblPulseNoteFade23
	

tblPulseNoteFade00:
	db $0D,$0C,$0C,$0B,$0A,$09,$07,$00,$05,$04,$FF
	
tblPulseNoteFade01:
	db $0C,$0B,$0B,$0A,$09,$08,$08,$07,$FF
	
tblPulseNoteFade02:
	db $0D,$0C,$0C,$0B,$0B,$0A,$0A,$09,$FF

tblPulseNoteFade03:
	db $0D,$0C,$0B,$0B,$0A,$0A,$09,$FF
	
tblPulseNoteFade04:
	db $0C,$0A,$09,$08,$07,$06,$06,$06,$05,$05,$00,$05,$FF

tblPulseNoteFade05:
	db $0B,$0C,$0B,$0A,$09,$08,$FF

tblPulseNoteFade06:
	db $0B,$0C,$0B,$0A,$09,$08,$07,$00,$05,$FF
	
tblPulseNoteFade07:
	db $0B,$0B,$0A,$09,$08,$07,$07,$FF
	
tblPulseNoteFade08:
	db $0B,$0B,$0A,$0A,$09,$07,$07,$FF
	
tblPulseNoteFade09:
	db $0B,$0B,$0A,$09,$09,$08,$08,$08,$07,$07,$07,$07,$06,$FF
	
tblPulseNoteFade0A:
	db $0B,$0B,$0A,$09,$08,$07,$06,$01,$04,$FF
	
tblPulseNoteFade0B:
	db $0C,$0B,$0A,$09,$08,$07,$00,$00,$04,$FF
	
tblPulseNoteFade0C:
	db $0D,$0C,$0C,$0B,$0A,$08,$FF
	
tblPulseNoteFade0D:
	db $0A,$0B,$0B,$0A,$0A,$09,$09,$08,$08,$08,$07,$FF
	
tblPulseNoteFade0E:
	db $0D,$0B,$0A,$0A,$09,$08,$07,$00,$05,$FF
	
tblPulseNoteFade0F:
	db $0A,$0B,$0B,$0A,$0A,$09,$08,$08,$07,$FF
	
tblPulseNoteFade10:
	db $05,$06,$06,$07,$07,$08,$08,$09,$FF
	
tblPulseNoteFade11:
	db $0D,$0C,$0A,$0A,$FF
	
tblPulseNoteFade12:
	db $0C,$0D,$0D,$0C,$0C,$0B,$0B,$0B,$0A,$09,$FF
	
tblPulseNoteFade13:
	db $08,$09,$0A,$0A,$09,$09,$08,$08,$07,$FF
	
tblPulseNoteFade14:
	db $0A,$0B,$0A,$0A,$09,$08,$FF
	
tblPulseNoteFade15:
	db $06,$07,$08,$09,$09,$09,$08,$FF
	
tblPulseNoteFade16:
	db $0B,$0A,$09,$09,$08,$07,$06,$06,$FF
	
tblPulseNoteFade17:
	db $0E,$0C,$0A,$0A,$09,$07,$06,$FF
	
tblPulseNoteFade18:
	db $0B,$0A,$09,$09,$08,$08,$07,$FF

tblPulseNoteFade1A:
	db $04,$04
tblPulseNoteFade19:
	db $04,$05,$05,$06,$06,$07,$07,$08,$08,$08,$08,$08,$09,$09,$09,$09
	db $09,$08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$08,$08,$08,$08,$08
	db $09,$09,$09,$09,$09,$08,$08,$08,$08,$09,$09,$09,$09,$08,$FF
	
tblPulseNoteFade1C:
	db $08,$08
tblPulseNoteFade1B
	db $08,$09,$0A,$0A,$09,$09,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
	db $08,$08,$08,$09,$09,$09,$09,$09,$08,$08,$08,$08,$08,$09,$09,$09
	db $09,$09,$08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$08,$08,$08,$08
	db $09,$09,$09,$09,$08,$08,$08,$08,$FF

tblPulseNoteFade1E:	
	db $09,$09
tblPulseNoteFade1D:
	db $09,$0A,$0A,$09,$09,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
	db $08,$09,$09,$09,$09,$09,$08,$08,$08,$08,$08,$09,$09,$09,$09,$09
	db $08,$08,$08,$08,$08,$09,$09,$09,$09,$09,$08,$08,$08,$08,$09,$09
	db $09,$09,$08,$08,$08,$08,$09,$09,$09,$09,$08,$08,$08,$08,$09,$09
	db $09,$09,$08,$08,$08,$08,$FF

tblPulseNoteFade1F:	
	db $0D,$0C,$0B,$0A,$09,$07,$FF

tblPulseNoteFade20:	
	db $0C,$0B,$09,$08,$07,$07,$FF
	
tblPulseNoteFade21:
	db $0C,$0B,$0A,$0A,$09,$08,$01,$05,$FF
	
tblPulseNoteFade22:
	db $0B,$0A,$0A,$0A,$09,$09,$09,$09,$08,$FF
	
tblPulseNoteFade23:
	db $0F,$0E,$0D,$0B,$0A,$09,$08,$06,$FF

;Pulse 1 override
tblSound_PauseDefinition:
	db $05,$82,$88,$10,$D5,$10,$8E,$10,$A9,$02,$B0,$88,$E0,$6A,$D0,$6A
	db $B0,$6A,$A0,$6A,$90,$6A,$70,$6A,$50,$6A,$40,$6A,$FF
	
;Unused byte
	db $00
	
;Pulse 1 override
tblSound1Definition: ;NOT USED?
	db $FF
	
;Unused bytes
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	
tblSound1_2Definition:
	db $FF

;Unused bytes
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;DMC
tblSound_Level6BossBuildingBlowingUpDefinition:
	db $D6,$94,$92,$96,$93,$92,$94,$91,$93,$92,$FF

;Pulse 1 override
tblSound_Level6BossDefeated_MissionAccomplishedTextDefinition:	
	db $01,$30,$88,$90,$0A,$60,$0B,$50,$08,$30,$0A,$10,$09,$FF

;Noise
tblSound_Level6BossDefeated_MissionAccomplishedText2Definition:
	db $01,$BA,$5B,$88,$5A,$19,$FF

;Pulse 1 override
tblSound_POWPortraitTextPrintDefinition:
	db $02,$B0,$83,$80,$24,$03,$70,$8C,$40,$20,$FF
	
;Pulse 1 override
tblSound_POWPortraitScrollIntoPlace_ShingDefinition:	
	db $03,$B0,$88,$B0,$12,$B0,$16,$B0,$20,$B0,$17,$02,$B0,$88,$A0,$12
	db $03,$B0,$88,$B0,$18,$A0,$18,$90,$18,$80,$18,$70,$18,$60,$18,$50
	db $18,$40,$18,$30,$18,$20,$18,$10,$18,$FF

;Pulse 2 override
tblSound_POWPortraitScrollIntoPlace_Shing2Definition:
	db $03,$B0,$88,$B0,$11,$B0,$15,$B0,$1F,$B0,$16,$02,$B0,$88,$A0,$11
	db $03,$B0,$88,$B0,$17,$A0,$17,$90,$17,$80,$17,$70,$17,$60,$17,$50
	db $17,$40,$17,$30,$17,$20,$17,$10,$17,$FF

;Noise
tblSound_POWPortraitScrollIntoPlace_Shing3Definition:	
	db $03,$F8,$A8,$F5,$54,$FF

;Pulse 1
tblSound_EndOfGameHelicopterDefinition:	
	db $01,$B0,$82,$10,$00,$02,$70,$82,$FB,$10,$00,$10,$00,$10,$00,$FE
	db $18,$FE,$FF
	dw tblSound_EndofGameHelicopterDefinitionRepeat

;Pulse 2
tblSound_EndOfGameHelicopter2Definition:
	db $02,$30,$82,$FB,$33,$65,$33,$55,$83,$45,$FE,$04,$FB,$43,$65,$33
	db $55,$73,$45,$FE,$04,$FB,$53,$65,$33,$55,$63,$45,$FE,$04,$FB,$63
	db $65,$33,$55,$53,$45,$FE,$04
tblSound_EndofGameHelicopterDefinitionRepeat:
	db $FB,$73,$65,$33,$55,$43,$45,$FE,$04,$FB,$83,$65,$33,$55,$43,$45
	db $FE,$04,$FB,$93,$65,$33,$55,$43,$45,$FE,$04,$FB,$A3,$65,$33,$55
	db $43,$45,$FE,$04,$FB,$B3,$65,$33,$55,$43,$45,$FE,$04,$FB,$C3,$65
	db $33,$55,$43,$45,$FE,$04,$FB,$D3,$65,$33,$55,$43,$45,$FE,$04,$FB
	db $E3,$65,$33,$55,$43,$45,$FE,$04,$FB,$F3,$65,$33,$55,$43,$45,$FE
	db $EF,$FF
	
;Noise
tblSound_WaterSplashDefinition:	
	db $02,$13,$45,$23,$34,$44,$13,$25,$13,$13,$FF
	
;Pulse 1 override
tblSound_Level6FinalBossTankFlameShotDefinition:
	db $01,$B0,$88,$53,$55,$54,$22,$51,$44,$01,$B0,$88,$53,$AA,$53,$BB
	db $52,$A8,$54,$CC,$53,$AA,$54,$DD,$51,$AA,$53,$CC,$FF

;Noise
tblSound_Level6FinalBossTankFlameShot2Definition:	
	db $01,$DF,$F2,$F4,$05,$FA,$DB,$FA,$CC,$FA,$BD,$7A,$3C,$FF
	
;Pulse 1 override
tblSound_LaserBlastDefinition:	
	db $04,$30,$8B,$FB,$80,$7F,$FE,$06,$40,$FD,$30,$FD,$20,$FD,$10,$FD
	db $FF
	
;Pulse 1 override
tblSound_ExtraLifeDefinition:
	db $02,$B0,$88,$90,$24,$01,$B0,$88,$30,$24,$02,$B0,$88,$F0,$24,$01
	db $B0,$88,$F0,$47,$C0,$47,$30,$47,$10,$6F,$20,$6F,$10,$6F,$50,$24
	db $90,$48,$60,$48,$50,$48,$10,$6F,$02,$B0,$88,$10,$6F,$40,$48,$40
	db $24,$20,$48,$30,$24,$10,$6F,$20,$48,$20,$24,$10,$48,$10,$24,$FF

tblSound_HelicopterBladesWhirringDefinition: ;Pulse 1 override
tblSound_HelicopterBladesWhirring3Definition: ;Pulse 2 override
	db $01,$70,$8A,$F5,$33,$08,$70,$83,$33,$33,$FF

tblSound_HelicopterBladesWhirring2Definition: ;Noise
tblSound_HelicopterBladesWhirring4Definition: ;Noise
	db $01,$FC,$03,$4E,$FF

;Pulse 2 override
tblSound_BomberPlaneRoarDefinition:
	db $01,$30,$82,$C2,$8D,$C3,$8F,$C2,$89,$C2,$8C,$FF
	
;Pulse 1 override
tblSound_BulletHitTinkDefinition:
	db $01,$70,$88,$F0,$44,$F0,$22,$F0,$21,$03,$70,$88,$90,$22,$70,$23
	db $50,$22,$30,$22,$04,$70,$88,$20,$22,$10,$22,$10,$22,$FF
	
;Noise
tblSound_JeepDeathDefinition:	
	db $01,$FB,$00,$FD,$DE,$FE,$04,$02,$00,$FF,$00,$F7,$00,$FF,$05,$00
	db $FA,$00,$FB,$00,$FB,$00,$FD,$EB,$DB,$CB,$BB,$AB,$9C,$8B,$7A,$6B
	db $5B,$4B,$3B,$FF
	

;Pulse 1 override
tblSound_WeaponUpgradeDefinition:	
	db $01,$30,$88,$FB,$91,$1D,$61,$1D,$51,$1D,$80,$8E,$70,$8E,$60,$8E
	db $FE,$04,$81,$1D,$71,$1D,$61,$1D,$05,$30,$88,$21,$1D,$11,$1D,$FF

;Pulse 2 override
tblSound_WeaponUpgrade2Definition:
	db $01,$30,$88,$FB,$91,$7D,$61,$7D,$51,$7D,$80,$BE,$70,$BE,$60,$BE
	db $FE,$04,$81,$7D,$71,$8D,$61,$7D,$05,$30,$88,$21,$7D,$11,$7D,$FF

;Pulse 1 override
tblSound_POWPickedUpDefinition:	
	db $05,$B0,$8B,$70,$D5,$05,$B0,$8D,$60,$71,$10,$71,$FF

;Pulse 2 override
tblSound_POWPickedUp2Definition:
	db $05,$B0,$8B,$81,$1D,$05,$B0,$8D,$60,$A0,$10,$A0,$FF

;Pulse 1 override
tblSound_POWEnteringHeliDefinition:
	db $02,$30,$88,$80,$8E,$60,$8E,$50,$8E,$80,$5F,$60,$5F,$50,$5F,$10
	db $5F,$FF

;Pulse 2 override
tblSound_POWEnteringHeli2Definition:
	db $02,$30,$88,$80,$BE,$60,$BE,$50,$BE,$80,$8E,$60,$8E,$50,$8E,$10
	db $8E,$FF

;Pulse 1 override
tblSound_GrenadeThrow_BombDefinition:	
	db $0F,$B0,$C4,$20,$20,$50,$28,$30,$2F,$FF
	
;Noise
tblSound_BlackAndWhite_SmallMissile_Bomb_LaserBlastHitsGroundDefinition:
	db $01,$00,$FF,$00,$F8,$00,$FC,$05,$00,$FF,$00,$F8,$E4,$EA,$8F,$88
	db $64,$6A,$26,$14,$FF

;Noise
tblSound_BazookaHitsGroundDefinition:
	db $01,$00,$FF,$00,$F8,$00,$FC,$05,$00,$FF,$00,$FC,$E6,$E9,$5F,$5C
	db $46,$39,$29,$09,$10,$04,$FF

;Pulse 1 override
tblSound_MainWeaponExplosionOnEnemyDefinition:
	db $09,$B0,$81,$F0,$88,$60,$88,$FF

;Noise
tblSound_MainWeaponExplosionOnEnemy2Definition:
	db $01,$00,$F8,$00,$FF,$00,$FC,$03,$00,$F8,$00,$F7,$47,$06,$C7,$CA
	db $BB,$AA,$99,$68,$4A,$FF,$01,$30,$88,$97,$A0,$10,$00,$10,$00,$54
	db $50,$FF
	
;Noise
tblSound_BulletFiringDefinition:
	db $01,$00,$FD,$3B,$00,$F9,$3D,$00,$FE,$3F,$00,$FA,$3F,$01,$5C,$4D
	db $3D,$3E,$2E,$03,$2F,$1F,$FF

;Pulse 1 override
tblSound_BazookaLaunchDefinition:	
	db $01,$30,$88,$97,$00,$37,$00,$17,$00,$36,$00,$FF

;Noise
tblSound_BazookaLaunch2Definition:
	db $01,$00,$FE,$7E,$5E,$00,$FD,$03,$7E,$8D,$9C,$AB,$BA,$99,$78,$0A
	db $67,$17,$FF

;Pulse 1 override
tblSound_POWBuildingOpeningDefinition:	
	db $01,$B0,$88,$A3,$50,$94,$50,$95,$50,$96,$50,$97,$50,$B3,$70,$A4
	db $70,$A5,$70,$A6,$70,$A7,$70,$C3,$90,$B4,$90,$B5,$90,$B6,$90,$B7
	db $90,$57,$90,$37,$90,$94,$80,$C5,$80,$C6,$80,$36,$80,$74,$D0,$65
	db $D0,$66,$D0,$26,$D0,$54,$F0,$45,$F0,$46,$F0,$16,$F0,$35,$10,$26
	db $10,$27,$10,$10,$00,$25,$30,$26,$30,$27,$30,$10,$00,$15,$50,$FF

;Noise
tblSound_POWBuildingOpening2Definition:	
	db $01,$00,$F9,$00,$F8,$00,$F7,$00,$FA,$CB,$AC,$8D,$6E,$00,$FB,$CC
	db $AD,$8E,$6F,$00,$FB,$CC,$AD,$8E,$6F,$6F,$3F,$CA,$CB,$CC,$3C,$AA
	db $9B,$9C,$3C,$5A,$5B,$4C,$1C,$3A,$3B,$2C,$1C,$2A,$2B,$2C,$1C,$1A
	db $FF
	
;Pulse 1 override
tblSound_InfantrySquishDefinition:	
	db $01,$30,$88,$C1,$20,$B2,$20,$A4,$20,$04,$30,$8A,$92,$20,$81,$C0
	db $71,$80,$41,$40,$11,$40,$FF
	
;Pulse 1 override
tblSound_WeepWeepBossMusic_F0Definition:	
	db $01,$30,$88,$40,$D5,$50,$DD,$60,$D5,$60,$CD,$70,$C5,$70,$BD,$70
	db $B5,$80,$B0,$03,$30,$88,$80,$A9,$60,$A9,$40,$A9,$FE,$04,$05,$30
	db $88,$10,$A9,$FF

;Pulse 2 override
tblSound_WeepWeepBossMusic_F02Definition:
	db $01,$30,$88,$40,$D8,$50,$E0,$60,$D8,$60,$D0,$70,$C8,$70,$C0,$70
	db $B8,$80,$B3,$03,$30,$88,$80,$AB,$60,$AB,$40,$AB,$FE,$04,$05,$30
	db $88,$10,$AB,$FF
	
;Noise
;long small puff sound like a brass symbol being hit
tblSound3Definition:
	db $01,$A2,$A1,$71,$61,$61,$50,$51,$50,$51,$50,$41,$30,$20,$20,$06
	db $10,$FF

;Noise
;small tink-like sound
tblSound4_5Definition:
	db $01,$65,$24,$21,$11,$FF

;Noise
;short small puff sound like a brass symbol being hit
tblSound_MusicPercussion_SymbolInstrumentDefinition:	
	db $01,$77,$56,$35,$24,$14,$FF

;Noise
;Drum hit like sound
tblSound7Definition:	
	db $01,$CE,$56,$14,$23,$13,$12,$10,$FF
	
	
;************************
;Game Started Intro Music
;************************
;Pulse 1
tblSound_GameStartedIntroDefinition:	
	db $FB,$D3,$B4,$0E,$00,$E1,$23,$D6,$B4,$01,$76,$20,$28,$D3,$B4,$0E
	db $00,$23,$D3,$B4,$01,$00,$21,$05,$D6,$B4,$01,$76,$E2,$B5,$72,$FB
	db $D3,$B4,$0E,$00,$E2,$93,$D3,$B4,$01,$00,$21,$21,$21,$21,$D3,$74
	db $0E,$00,$53,$D3,$74,$01,$00,$51,$51,$51,$51,$D3,$34,$0E,$00,$A3
	db $D3,$34,$01,$00,$A1,$A1,$A1,$A1,$D3,$34,$0E,$00,$E1,$33,$D3,$34
	db $01,$00,$31,$D3,$B4,$01,$55,$31,$71,$A1,$E0,$15,$D3,$B3,$01,$55
	db $E2,$91,$91,$91,$D3,$B9,$86,$00,$95,$D3,$B3,$82,$00,$92,$C7,$FF

;Pulse 2
tblSound_GameStartedIntro2Definition:	
	db $FB,$D3,$B5,$0E,$00,$E2,$93,$D3,$B5,$01,$00,$91,$95,$D3,$78,$85
	db $00,$91,$21,$91,$E1,$E8,$25,$D3,$B5,$0E,$00,$E2,$93,$D3,$B5,$01
	db $96,$91,$75,$2B,$25,$FB,$D3,$B5,$0E,$00,$E2,$53,$D3,$B5,$01,$00
	db $E3,$91,$91,$91,$91,$D3,$75,$0E,$00,$E2,$23,$D3,$75,$01,$00,$21
	db $21,$21,$21,$D3,$35,$0E,$00,$53,$D3,$35,$01,$00,$51,$51,$51,$51
	db $D3,$35,$0E,$00,$A3,$D3,$35,$01,$00,$A1,$D3,$B5,$01,$55,$A1,$E1
	db $21,$51,$75,$E2,$41,$41,$41,$D3,$B6,$84,$00,$44,$D3,$B2,$81,$00
	db $42,$C7,$FF

;Triangle
tblSound_GameStartedIntro3Definition:
	db $FB,$D3,$12,$E2,$C5,$21,$E3,$21,$91,$E2,$21,$E2,$21,$91,$D3,$90
	db $E1,$25,$D3,$12,$E2,$C5,$21,$E3,$21,$91,$E2,$21,$21,$91,$D3,$45
	db $E1,$25,$D3,$17,$E2,$73,$D3,$11,$71,$D3,$17,$E2,$93,$D3,$11,$21
	db $21,$21,$21,$FB,$D3,$17,$23,$D3,$11,$21,$21,$21,$21,$FE,$02,$23
	db $21,$21,$31,$31,$D3,$36,$45,$D3,$11,$E3,$91,$91,$91,$D3,$90,$96
	db $C7,$FF

;DMC
tblSound_GameStartedIntro4Definition:	
	db $D3,$33,$31,$B5,$31,$31,$31,$35,$33,$31,$B3,$30,$30,$31,$31,$31
	db $35,$35,$FB,$B3,$B1,$31,$31,$31,$FE,$03,$B3,$30,$30,$31,$31,$31
	db $B3,$B1,$31,$31,$31,$35,$C7,$FF
	

;*************
;Level 1 Music
;*************

;Pulse 1
tblSound_Level1MusicDefinition:
	db $FB,$D3,$B3,$00,$0F,$E3,$10,$10,$13,$11,$13,$11,$13,$11,$13,$11
	db $13,$11,$13,$11,$13,$11,$13,$FE,$02,$10,$10
tblSound_Level1MusicRepeatDefinition:
	db $FB,$D3,$75,$0E,$00
	db $E2,$63,$B1,$D3,$75,$0D,$B7,$E1,$6B,$D3,$75,$01,$00,$31,$11,$E2
	db $B1,$D3,$74,$0E,$00,$93,$E1,$11,$D3,$75,$0D,$B7,$E2,$BB,$D3,$B5
	db $0E,$00,$E3,$93,$E2,$11,$D3,$B5,$0D,$93,$E3,$B5,$E2,$65,$D3,$77
	db $83,$00,$F3,$91,$41,$F2,$91,$E1,$41,$F1,$E2,$91,$F0,$E1,$41,$D9
	db $75,$01,$B7,$15,$D3,$B6,$84,$00,$E3,$F1,$B1,$B1,$B1,$F0,$AF,$D3
	db $B1,$80,$00,$A7,$FB,$D3,$B5,$00,$0F,$E3,$33,$31,$D3,$75,$0F,$72
	db $E2,$85,$67,$D3,$75,$1F,$00,$31,$E3,$B1,$D3,$75,$01,$47,$E2,$15
	db $D3,$75,$1F,$00,$11,$11,$11,$D3,$75,$01,$47,$35,$D3,$75,$1F,$00
	db $31,$31,$31,$D3,$B5,$00,$0F,$E3,$33,$31,$D3,$75,$0F,$73,$E2,$85
	db $67,$31,$E3,$B1,$D3,$74,$82,$00,$E2,$45,$65,$D3,$77,$85,$00,$85
	db $A5,$D3,$75,$01,$73,$95,$D3,$75,$1F,$00,$41,$41,$41,$E8,$D3,$76
	db $02,$00,$41,$11,$41,$91,$41,$91,$E1,$15,$D3,$77,$1F,$00,$E2,$11
	db $11,$11,$F6,$41,$41,$41,$F5,$91,$91,$91,$D3,$74,$01,$95,$B5,$61
	db $61,$61,$D3,$76,$02,$00,$61,$41,$61,$B1,$61,$B1,$E1,$35,$D3,$78
	db $84,$00,$F7,$E3,$B1,$F6,$61,$F5,$B1,$E2,$F4,$31,$F3,$E3,$B1,$E2
	db $F2,$31,$F1,$61,$F0,$61,$61,$E8,$FB,$D3,$75,$01,$22,$E1,$13,$D3
	db $B3,$00,$0F,$E8,$E3,$11,$11,$11,$11,$FB,$13,$11,$11,$11,$11,$FE
	db $03,$D3,$35,$0F,$00,$E2,$B3,$A1,$C5,$D3,$75,$0F,$00,$E3,$B3,$A1
	db $D3,$B5,$0F,$00,$E4,$B3,$A1,$C5,$D3,$76,$84,$00,$E2,$B3,$B1,$B1
	db $A1,$81,$61,$11,$61,$45,$D3,$B6,$84,$00,$E8,$E2,$41,$E3,$B1,$E2
	db $41,$81,$41,$81,$B1,$81,$B1,$D3,$76,$84,$00,$E2,$45,$D3,$B6,$84
	db $00,$E2,$81,$41,$81,$B1,$81,$B1,$E1,$41,$61,$81,$FB,$D3,$35,$0F
	db $00,$E2,$B3,$A1,$C5,$D3,$75,$0F,$00,$E3,$B3,$A1,$D3,$B5,$0F,$00
	db $E4,$B3,$A1,$C5,$E2,$D3,$76,$84,$00,$B3,$B1,$B1,$A1,$81,$61,$11
	db $61,$E2,$45,$D3,$B6,$84,$00,$E8,$E2,$41,$E3,$B1,$E2,$41,$81,$41
	db $81,$B1,$81,$B1,$D3,$77,$85,$00,$E1,$23,$21,$E2,$91,$91,$91,$E1
	db $03,$01,$E2,$71,$71,$71,$FB,$D6,$75,$01,$34,$E2,$9B,$D3,$B4,$02
	db $18,$E4,$53,$53,$53,$03,$03,$03,$D3,$B4,$03,$0F,$FB,$23,$21,$FE
	db $04,$D3,$B4,$02,$18,$53,$53,$53,$73,$73,$73,$D3,$B4,$03,$0F,$FB
	db $93,$91,$93,$91,$93,$91,$71,$71,$71,$FE,$03,$93,$CB,$CF,$CF,$E8
	db $FE,$FF
	dw tblSound_Level1MusicRepeatDefinition
	
;Pulse 2
tblSound_Level1Music2Definition:	
	db $D3,$B2,$00,$0F,$E4,$60,$60,$63,$61,$63,$61,$63,$61,$63,$61,$63
	db $61,$63,$61,$63,$61,$63,$FE,$02,$60,$60
tblSound_Level1MusicRepeat2Definition:
	db $FB,$D3,$74,$0E,$00,$E2
	db $B3,$E1,$61,$D3,$74,$0D,$97,$BB,$D3,$74,$01,$00,$91,$81,$61,$D3
	db $74,$0E,$00,$43,$81,$D3,$74,$0D,$77,$6B,$D3,$74,$0E,$00,$E2,$43
	db $81,$D3,$74,$0D,$94,$65,$B5,$D3,$7A,$85,$00,$F3,$E1,$41,$E2,$B1
	db $F2,$E1,$41,$91,$F1,$41,$F0,$91,$D9,$74,$01,$77,$65,$D3,$78,$85
	db $00,$E2,$41,$41,$41,$D6,$74,$01,$77,$6B,$FB,$D3,$B4,$00,$0F,$E4
	db $83,$81,$D3,$74,$0F,$73,$E2,$B5,$D3,$74,$1E,$00,$A7,$81,$61,$D3
	db $74,$01,$38,$85,$D3,$74,$1E,$00,$81,$81,$81,$D3,$74,$01,$38,$A5
	db $D3,$74,$1E,$00,$A1,$A1,$A1,$D3,$B4,$00,$0F,$E4,$83,$81,$D3,$74
	db $0F,$74,$E2,$B5,$A7,$81,$61,$D3,$76,$83,$43,$85,$D3,$77,$84,$02
	db $A5,$D3,$79,$86,$22,$B5,$D3,$7A,$87,$42,$E1,$15,$D3,$7B,$88,$33
	db $15,$D3,$74,$1F,$00,$E2,$91,$91,$91,$D6,$74,$01,$96,$48,$D3,$76
	db $1F,$64,$41,$41,$41,$F5,$91,$91,$91,$F4,$E1,$11,$11,$11,$D6,$74
	db $01,$95,$32,$E2,$B0,$B0,$B0,$E2,$68,$D3,$7B,$85,$00,$F7,$61,$F6
	db $61,$F5,$F4,$61,$F3,$E2,$B1,$F2,$B1,$F1,$B1,$E1,$31,$F0,$41,$61
	db $FB,$D3,$74,$01,$22,$E1,$83,$D3,$B2,$00,$0F,$E4,$11,$11,$11,$11
	db $FB,$13,$11,$11,$11,$11,$FE,$03,$D3,$33,$0F,$00,$E1,$43,$61,$D1
	db $32,$80,$00,$C2,$45,$C0,$66,$C0,$D3,$74,$0F,$00,$E2,$43,$61,$D3
	db $B4,$0F,$00,$E3,$43,$61,$D1,$B1,$80,$00,$C2,$45,$C0,$56,$C0,$D3
	db $79,$86,$00,$E1,$63,$61,$61,$61,$11,$E2,$A1,$61,$A1,$D6,$74,$01
	db $B6,$8B,$B5,$E1,$15,$FB,$D3,$33,$0F,$00,$E1,$43,$61,$D1,$32,$80
	db $00,$C2,$45,$C0,$66,$C0,$D3,$74,$0F,$00,$E2,$43,$61,$D3,$B4,$0F
	db $00,$E3,$43,$61,$D1,$B1,$80,$00,$C2,$45,$C0,$56,$C0,$D3,$79,$86
	db $00,$E1,$63,$61,$61,$61,$11,$E2,$D6,$74,$01,$B7,$A0,$60,$A0,$8B
	db $D3,$7A,$87,$00,$E1,$73,$71,$61,$41,$21,$53,$51,$41,$21,$01,$FB
	db $D6,$74,$01,$34,$E1,$2B,$D3,$76,$02,$44,$E2,$53,$53,$53,$03,$03
	db $03,$D3,$76,$03,$1A,$FB,$23,$21,$FE,$04,$D3,$76,$02,$44,$53,$53
	db $53,$73,$73,$73,$D3,$76,$03,$1A,$FB,$93,$91,$93,$91,$93,$91,$71
	db $71,$71,$FE,$03,$93,$CB,$CF,$CF,$FE,$FF
	dw tblSound_Level1MusicRepeat2Definition

;Triangle
tblSound_Level1Music3Definition:
	db $D3,$08,$E2,$60,$60,$FB,$D3,$19,$63,$D3,$12,$61,$FE,$07,$D3,$19
	db $63,$D3,$08,$60,$60,$FB,$D3,$19,$63,$D3,$12,$61,$FE,$07,$D3,$19
	db $63,$60,$60
tblSound_Level1MusicRepeat3Definition:
	db $FB,$D3,$19,$E3,$B3,$D3,$11,$B1,$FE,$03,$B1,$61,$B1
	db $D3,$19,$B3,$D3,$11,$B1,$B1,$61,$B1,$FB,$D3,$19,$B3,$D3,$11,$B1
	db $FE,$03,$E4,$B1,$E3,$61,$B1,$E4,$91,$E3,$41,$91,$E2,$41,$41,$41
	db $FB,$D3,$19,$63,$D3,$11,$61,$FE,$03,$41,$41,$41,$FB,$D3,$19,$63
	db $D3,$11,$61,$FE,$03,$E3,$61,$B1,$E2,$61,$FB,$D3,$19,$E3,$83,$D3
	db $11,$81,$E2,$81,$E3,$81,$81,$FE,$02,$D3,$19,$E2,$43,$D3,$11,$41
	db $41,$41,$41,$D3,$19,$63,$D3,$11,$61,$61,$61,$61,$FB,$D3,$19,$E3
	db $83,$D3,$11,$81,$E2,$81,$E3,$81,$81,$FE,$02,$D3,$1C,$E2,$43,$D3
	db $12,$41,$D3,$1C,$E3,$63,$D3,$12,$61,$D3,$1C,$83,$D3,$12,$81,$D3
	db $1C,$A3,$D3,$12,$A1,$FB,$D3,$19,$93,$D3,$11,$91,$E2,$91,$E3,$91
	db $91,$FE,$04,$FB,$E3,$D3,$19,$B3,$D3,$11,$B1,$E2,$B1,$E3,$B1,$B1
	db $FE,$02,$B3,$B1,$FB,$B1,$FE,$09,$FB,$D3,$19,$E2,$13,$D3,$11,$11
	db $11,$11,$11,$FE,$04,$FB,$E3,$D3,$18,$63,$D3,$11,$61,$E2,$61,$E3
	db $61,$61,$FE,$04,$FB,$D3,$19,$E2,$43,$D3,$11,$41,$FE,$06,$43,$E3
	db $41,$81,$B1,$E2,$41,$FB,$D3,$18,$E3,$63,$D3,$11,$61,$E2,$61,$E3
	db $61,$61,$FE,$04,$FB,$D3,$19,$E2,$43,$D3,$11,$41,$FE,$04,$D3,$37
	db $E2,$75,$25,$55,$E2,$05,$FB,$D3,$1B,$E2,$23,$D3,$11,$21,$FE,$04
	db $D3,$25,$E2,$53,$53,$53,$03,$03,$03,$FB,$D3,$21,$23,$D3,$11,$21
	db $FE,$04,$D3,$25,$53,$53,$53,$73,$73,$73,$FB,$D3,$21,$93,$D3,$11
	db $91,$D3,$21,$93,$D3,$11,$91,$D3,$21,$93,$D3,$11,$91,$71,$71,$71
	db $FE,$03,$D3,$90,$93,$CB,$CF,$CF,$FE,$FF
	dw tblSound_Level1MusicRepeat3Definition

;DMC
tblSound_Level1Music4Definition:	
	db $D3,$C1,$FB,$B3,$B1,$33,$B1,$FE,$03,$B3,$B1,$35,$FB,$B3,$B1,$33
	db $B1,$FE,$03,$31,$31,$31,$31,$31,$31
tblSound_Level1MusicRepeat4Definition:
	db $FB,$D3,$B3,$B1,$33,$B1,$FE
	db $03,$B3,$B1,$35,$FB,$B3,$B1,$33,$B1,$FE,$05,$FB,$31,$FE,$06,$FB
	db $FB,$D3,$B3,$B1,$33,$B1,$FE,$03,$B3,$B1,$35,$FB,$B3,$B1,$33,$B1
	db $FE,$03,$FB,$31,$FE,$06,$FB,$B3,$B1,$33,$B1,$FE,$07,$FB,$31,$FE
	db $06,$FB,$FB,$D3,$B3,$31,$31,$31,$31,$33,$31,$31,$31,$31,$B3,$31
	db $31,$31,$31,$33,$33,$33,$FB,$B3,$B1,$33,$B1,$FE,$03,$B3,$B1,$35
	db $FB,$B3,$B1,$33,$B1,$FE,$03,$B3,$B1,$31,$31,$31,$FB,$B3,$B1,$33
	db $B1,$FE,$03,$B3,$B1,$35,$FB,$B3,$B1,$33,$B1,$FE,$02,$FB,$B3,$B1
	db $31,$31,$B1,$FE,$02,$FB,$D3,$FB,$B3,$B1,$33,$B1,$FE,$02,$33,$33
	db $31,$B1,$31,$31,$31,$B1,$B1,$B1,$FB,$B3,$B1,$33,$B1,$FE,$02,$33
	db $33,$31,$B1,$31,$31,$31,$B1,$B1,$B1,$FB,$B3,$B1,$33,$31,$31,$31
	db $31,$B3,$B1,$FE,$03,$B3,$31,$31,$31,$31,$FB,$33,$31,$31,$31,$31
	db $FE,$03,$FE,$FF
	dw tblSound_Level1MusicRepeat4Definition
	
;*************
;Level 2 Music
;*************
;Pulse 2
tblSound_Level2Music2Definition:
	db $FB,$D6,$73,$09,$00,$E2,$01,$D6,$B1,$0A,$0F,$E4,$00,$00,$FB,$01
	db $00,$00,$FE,$02,$D6,$74,$05,$05,$E2,$02,$D6,$74,$09,$00,$E3,$A2
	db $D6,$B1,$0A,$0F,$E4,$00,$00,$FB,$01,$00,$00,$FE,$03,$D6,$74,$09
	db $00,$E2,$01,$D6,$B1,$0A,$0F,$E4,$00,$00,$FB,$01,$00,$00,$FE,$02
	db $D6,$74,$05,$05,$E2,$02,$D6,$74,$09,$00,$E3,$A2,$D6,$B1,$0A,$0F
	db $E4,$00,$00,$FB,$01,$00,$00,$FE,$02,$E4,$A0,$B2
tblSound_Level2MusicRepeat2Definition:
	db $FB,$D6,$75,$05
	db $84,$E1,$0F,$E2,$AF,$7F,$5F,$3F,$57,$23,$33,$D6,$74,$09,$00,$E2
	db $21,$D6,$B1,$0A,$0F,$E4,$00,$00,$01,$00,$00,$01,$00,$00,$D6,$75
	db $05,$04,$E2,$22,$D6,$74,$09,$00,$02,$D6,$B1,$0A,$0F,$E4,$00,$00
	db $01,$00,$00,$01,$00,$00,$A0,$B2,$FE,$02,$FB,$D6,$75,$05,$06,$E2
	db $32,$D6,$75,$05,$54,$58,$D6,$74,$04,$00,$20,$20,$20,$30,$D6,$75
	db $05,$09,$22,$D6,$75,$05,$85,$0C,$D6,$75,$05,$06,$E1,$32,$D6,$75
	db $05,$54,$58,$D4,$74,$04,$00,$21,$21,$31,$D6,$75,$05,$09,$22,$D6
	db $75,$05,$54,$0C,$D6,$75,$05,$08,$E2,$32,$D6,$75,$05,$54,$58,$D6
	db $74,$04,$00,$20,$20,$20,$30,$D6,$75,$05,$09,$22,$D6,$75,$05,$85
	db $0C,$D6,$75,$05,$06,$E1,$32,$D6,$75,$05,$54,$58,$D4,$74,$04,$00
	db $21,$21,$31,$D6,$75,$05,$09,$22,$D6,$75,$05,$54,$06,$D1,$76,$81
	db $00,$E2,$04,$14,$23,$33,$42,$52,$D1,$75,$80,$00,$61,$71,$81,$91
	db $A1,$B1,$FB,$D6,$74,$07,$00,$E1,$01,$00,$D6,$74,$06,$00,$01,$D6
	db $74,$07,$00,$00,$01,$E2,$A1,$A1,$91,$90,$D6,$74,$06,$00,$91,$D6
	db $74,$07,$00,$90,$91,$71,$51,$51,$50,$D6,$74,$06,$00,$51,$D6,$74
	db $07,$00,$50,$51,$71,$71,$51,$50,$D6,$74,$06,$00,$51,$D6,$74,$07
	db $00,$50,$51,$41,$41,$FE,$02,$FB,$D6,$33,$07,$00,$E2,$30,$30,$30
	db $D6,$33,$07,$36,$55,$D6,$33,$0B,$00,$E1,$30,$30,$51,$E0,$30,$51
	db $E2,$A0,$90,$80,$D6,$33,$07,$35,$75,$D6,$33,$0B,$00,$E1,$A0,$90
	db $81,$E0,$A0,$91,$FE,$02,$FB,$D6,$34,$05,$32,$E2,$00,$50,$E1,$00
	db $70,$00,$50,$00,$30,$E2,$50,$E1,$00,$E2,$00,$E2,$30,$FE,$08,$FB
	db $D4,$74,$07,$0F,$E1,$31,$21,$31,$D6,$74,$07,$35,$55,$D6,$74,$0A
	db $00,$31,$30,$D6,$74,$07,$00,$22,$D4,$74,$07,$0F,$31,$21,$31,$D6
	db $74,$07,$35,$05,$D6,$B4,$07,$13,$E2,$31,$30,$52,$D4,$74,$07,$0F
	db $E1,$31,$21,$31,$D6,$74,$07,$35,$55,$31,$D4,$74,$07,$0F,$71,$51
	db $31,$31,$21,$31,$D6,$74,$07,$35,$05,$D6,$B4,$07,$00,$E2,$A1,$A0
	db $92,$FB,$D6,$74,$08,$00,$E2,$72,$72,$71,$D6,$74,$20,$00,$70,$70
	db $70,$70,$D6,$74,$08,$00,$82,$82,$81,$D6,$74,$20,$00,$80,$80,$80
	db $80,$D6,$74,$08,$00,$52,$52,$51,$D6,$74,$20,$00,$50,$50,$50,$50
	db $D6,$74,$08,$85,$52,$48,$D6,$74,$08,$00,$72,$72,$71,$D6,$74,$20
	db $00,$70,$70,$70,$70,$D6,$74,$08,$00,$82,$82,$81,$D6,$74,$20,$00
	db $80,$80,$80,$80,$D6,$74,$08,$00,$A2,$A2,$A1,$D6,$74,$20,$00,$A0
	db $A0,$A0,$A0,$E1,$00,$00,$00,$00,$00,$00,$00,$00,$D6,$74,$07,$85
	db $03,$FE,$FF
	dw tblSound_Level2MusicRepeat2Definition
	
;Pulse 1
tblSound_Level2MusicDefinition:	
	db $FB,$E8,$D6,$75,$09,$00,$E3,$31,$D6,$B5,$0A,$0F,$E3,$00,$00,$FB
	db $01,$00,$00,$FE,$02,$D6,$74,$05,$15,$E3,$32,$D6,$75,$09,$00,$22
	db $D6,$B5,$0A,$0F,$E3,$00,$00,$FB,$01,$00,$00,$FE,$03,$D6,$75,$09
	db $00,$E3,$31,$D6,$B5,$0A,$0F,$E3,$00,$00,$FB,$01,$00,$00,$FE,$02
	db $D6,$74,$05,$15,$E3,$32,$D6,$75,$09,$00,$22,$D6,$B5,$0A,$0F,$E3
	db $00,$00,$FB,$01,$00,$00,$FE,$02,$D6,$75,$0A,$00,$E3,$A0,$B2,$E8
tblSound_Level2MusicRepeatDefinition:
	db $FB,$D6,$B6,$05,$83,$E2,$3F,$2F,$3F,$2F,$E3,$8F,$A7,$57,$D6,$75
	db $09,$00,$E3,$51,$D6,$B4,$0A,$00,$E3,$00,$00,$01,$00,$00,$01,$00
	db $00,$D6,$76,$05,$05,$E3,$52,$D6,$76,$09,$00,$42,$D6,$B4,$0A,$0F
	db $E3,$00,$00,$01,$00,$00,$01,$00,$00,$D6,$75,$0A,$00,$E3,$A0,$B2
	db $FE,$02,$FB,$D6,$75,$09,$04,$E3,$A2,$D6,$75,$05,$54,$98,$93,$7F
	db $D6,$75,$05,$07,$E2,$A2,$D6,$75,$05,$54,$98,$D4,$74,$04,$00,$91
	db $91,$A1,$D6,$75,$05,$09,$92,$D6,$75,$05,$54,$7C,$D6,$75,$05,$05
	db $E3,$A2,$D6,$75,$05,$54,$98,$93,$7F,$D6,$75,$05,$07,$E2,$A2,$D6
	db $75,$05,$54,$98,$D4,$74,$04,$00,$91,$91,$A1,$D6,$75,$05,$09,$92
	db $D6,$75,$05,$54,$76,$D1,$76,$81,$00,$E3,$74,$84,$93,$A3,$B2,$E2
	db $02,$D1,$75,$80,$00,$11,$21,$31,$41,$51,$61,$FB,$D6,$75,$07,$00
	db $E2,$71,$70,$D6,$75,$06,$00,$71,$D6,$75,$07,$00,$70,$71,$51,$51
	db $01,$00,$D6,$75,$06,$00,$01,$D6,$75,$07,$00,$00,$01,$01,$01,$01
	db $00,$D6,$75,$06,$00,$01,$D6,$75,$07,$00,$00,$01,$21,$21,$01,$00
	db $D6,$75,$06,$00,$01,$D6,$75,$07,$00,$00,$01,$01,$01,$FE,$02,$FB
	db $D6,$76,$84,$06,$E3,$A0,$A0,$A0,$95,$D6,$76,$0B,$00,$E2,$A0,$A0
	db $E1,$01,$A0,$E0,$01,$D6,$76,$84,$00,$E2,$50,$40,$30,$25,$D6,$76
	db $0B,$00,$E1,$50,$40,$31,$E0,$50,$41,$FE,$02,$FB,$E8,$D6,$33,$80
	db $32,$E2,$02,$50,$E1,$00,$70,$00,$50,$00,$30,$E2,$50,$E1,$00,$E2
	db $E8,$FE,$08,$FB,$D4,$75,$07,$0F,$E2,$A1,$91,$A1,$D6,$75,$07,$35
	db $E1,$05,$D6,$75,$0A,$00,$E2,$A1,$A0,$D6,$75,$07,$00,$92,$D4,$75
	db $07,$0F,$A1,$91,$A1,$D6,$75,$07,$35,$75,$D6,$B5,$07,$00,$E3,$A1
	db $A0,$E2,$02,$D4,$75,$07,$0F,$E2,$A1,$91,$A1,$D6,$75,$07,$00,$E1
	db $05,$D6,$75,$0A,$00,$E2,$A1,$D4,$75,$07,$0F,$E1,$21,$01,$E2,$A1
	db $A1,$91,$A1,$D6,$75,$07,$35,$75,$D6,$B5,$07,$10,$E2,$51,$50,$02
	db $FB,$D6,$75,$08,$00,$E2,$32,$32,$31,$D6,$75,$20,$00,$30,$30,$30
	db $30,$D6,$75,$08,$00,$52,$52,$D6,$75,$08,$00,$51,$D6,$75,$20,$00
	db $50,$50,$50,$50,$D6,$75,$08,$00,$22,$22,$21,$D6,$75,$20,$00,$20
	db $20,$20,$20,$D6,$75,$08,$85,$02,$E3,$78,$D6,$75,$08,$00,$E2,$32
	db $32,$31,$D6,$75,$20,$00,$30,$30,$30,$30,$D6,$75,$08,$00,$52,$52
	db $51,$D6,$75,$20,$00,$50,$50,$50,$50,$D6,$75,$08,$00,$22,$22,$21
	db $D6,$75,$20,$00,$20,$20,$20,$20,$50,$50,$50,$50,$50,$50,$50,$50
	db $D6,$75,$08,$85,$43,$FE,$FF
	dw tblSound_Level2MusicRepeatDefinition


	
;Triangle
tblSound_Level2Music3Definition:
	db $FB,$D6,$18,$E2,$01,$D6,$11,$00,$00,$D6,$18,$01,$D6,$11,$00,$00
	db $D6,$18,$01,$D6,$11,$00,$00,$D6,$18,$01,$D6,$11,$00,$00,$FE,$03
	db $D6,$18,$01,$D6,$11,$00,$00,$D6,$18,$01,$D6,$11,$00,$00,$D6,$18
	db $01,$D6,$11,$00,$00,$E3,$A0,$D6,$29,$B2
tblSound_Level2MusicRepeat3Definition:
	db $FB,$D6,$20,$E3,$01,$D6
	db $11,$E2,$00,$00,$01,$00,$00,$01,$00,$00,$40,$D6,$29,$52,$D6,$20
	db $E3,$01,$D6,$11,$E2,$00,$00,$01,$00,$00,$01,$00,$00,$E3,$A0,$D6
	db $29,$B2,$FE,$08,$FB,$D6,$18,$E3,$01,$01,$01,$D6,$11,$70,$A0,$D6
	db $15,$91,$91,$81,$D6,$11,$80,$80,$D6,$18,$71,$71,$91,$D6,$11,$90
	db $90,$D6,$18,$A1,$A1,$B1,$D6,$11,$B0,$B0,$FE,$04,$FB,$D6,$1D,$E3
	db $01,$D6,$11,$E2,$00,$01,$00,$D6,$1D,$01,$E3,$31,$D6,$11,$E2,$30
	db $E3,$30,$D6,$1D,$51,$D6,$11,$E2,$50,$51,$50,$D6,$1D,$51,$D6,$11
	db $E3,$50,$40,$50,$70,$D6,$1D,$E3,$81,$D6,$11,$80,$81,$80,$D6,$1C
	db $81,$A1,$A1,$E3,$01,$D6,$11,$E2,$00,$01,$00,$D6,$1D,$01,$D6,$11
	db $E2,$00,$E3,$50,$60,$70,$FE,$02,$FB,$D6,$1C,$E3,$01,$E2,$01,$01
	db $D6,$10,$00,$D6,$20,$D6,$27,$02,$D6,$1C,$01,$01,$D6,$10,$E2,$00
	db $D6,$27,$02,$D6,$1C,$01,$01,$D6,$10,$00,$D6,$27,$02,$D6,$1C,$E3
	db $31,$D6,$11,$50,$60,$70,$70,$FE,$02,$FB,$D1,$90,$E4,$90,$A0,$B0
	db $90,$E3,$01,$D6,$90,$0A,$D1,$90,$10,$20,$10,$32,$D6,$90,$3A,$D1
	db $90,$30,$40,$30,$52,$D6,$90,$5A,$D1,$90,$60,$70,$60,$82,$D6,$90
	db $8A,$D1,$90,$E3,$90,$A0,$B0,$90,$E2,$01,$D6,$90,$0A,$D1,$90,$10
	db $20,$10,$32,$D6,$90,$3A,$D1,$90,$30,$40,$30,$52,$D6,$90,$5A,$D1
	db $90,$70,$80,$90,$70,$A1,$D6,$90,$A3,$D1,$90,$A7,$93,$83,$73,$62
	db $52,$42,$31,$21,$11,$01,$E3,$B0,$A0,$90,$80,$70,$FB,$D6,$29,$E3
	db $02,$D6,$13,$E2,$02,$D6,$20,$01,$FB,$D6,$29,$02,$D6,$13,$E2,$02
	db $D6,$20,$01,$FE,$02,$D6,$29,$02,$D6,$13,$D6,$20,$E3,$52,$71,$D6
	db $29,$E3,$02,$D6,$13,$E2,$02,$D6,$20,$01,$FB,$D6,$29,$02,$D6,$13
	db $E2,$02,$D6,$20,$01,$FE,$02,$D6,$21,$01,$01,$D6,$0D,$E3,$90,$D6
	db $29,$72,$FB,$D6,$11,$E3,$01,$E2,$00,$00,$01,$00,$00,$00,$00,$00
	db $00,$11,$10,$10,$11,$10,$10,$10,$10,$10,$10,$E3,$A1,$A0,$A0,$A1
	db $A0,$A0,$A0,$A0,$A0,$A0,$E2,$01,$00,$00,$01,$00,$00,$00,$00,$00
	db $00,$E3,$01,$E2,$00,$00,$01,$00,$00,$00,$00,$00,$00,$11,$10,$10
	db $11,$10,$10,$10,$10,$10,$10,$E3,$71,$70,$70,$71,$70,$70,$70,$70
	db $70,$70,$E2,$00,$00,$00,$00,$00,$00,$00,$00,$01,$C0,$C0,$FE,$FF
	dw tblSound_Level2MusicRepeat3Definition

;DMC
tblSound_Level2Music4Definition:
	db $FB,$D6,$B1,$B0,$B0,$31,$B0,$B0,$FE,$07,$31,$31,$30,$32
tblSound_Level2MusicRepeat4Definition:
	db $FB,$D6
	db $B1,$B0,$B0,$31,$B0,$B0,$FE,$07,$B1,$B0,$B0,$30,$B1,$B0,$FB,$B1
	db $B0,$B0,$31,$B0,$B0,$FE,$07,$31,$31,$30,$31,$B0,$FB,$B1,$B0,$B0
	db $31,$B0,$B0,$FE,$07,$B1,$B0,$B0,$30,$B1,$B0,$FB,$B1,$B0,$B0,$31
	db $B0,$B0,$FE,$07,$31,$31,$30,$B1,$B0,$FB,$D6,$B1,$B1,$31,$00,$00
	db $FE,$07,$B1,$B1,$31,$30,$30,$FB,$B1,$B1,$31,$00,$00,$FE,$06,$B1
	db $B1,$FB,$31,$30,$30,$FE,$03,$FB,$D6,$B1,$B0,$B0,$31,$B0,$B0,$31
	db $31,$B1,$B0,$B0,$30,$B0,$B0,$B0,$30,$30,$30,$30,$D6,$B1,$B0,$B0
	db $31,$B0,$B0,$31,$31,$B1,$B0,$B0,$30,$B0,$B0,$B0,$31,$30,$30,$FE
	db $02,$FB,$D6,$B1,$FB,$B1,$31,$10,$B2,$FE,$03,$B1,$31,$30,$30,$B1
	db $FB,$B1,$31,$10,$B2,$FE,$03,$B1,$FB,$30,$FE,$04,$FB,$D6,$B0,$31
	db $B0,$31,$B0,$B0,$31,$31,$FE,$03,$B0,$31,$B0,$31,$B0,$B0,$30,$30
	db $30,$30,$FB,$B0,$31,$B0,$31,$B0,$B0,$31,$31,$FE,$03,$B0,$31,$B0
	db $31,$30,$30,$30,$30,$30,$30,$FB,$D6,$B2,$10,$31,$B1,$B1,$11,$31
	db $B1,$FE,$03,$B2,$10,$31,$B1,$31,$31,$30,$32,$FB,$D6,$B1,$B0,$B0
	db $31,$B1,$B1,$B1,$FE,$03,$B1,$B0,$B0,$31,$B1,$30,$30,$30,$30,$FB
	db $B1,$B0,$B0,$31,$B1,$B1,$B1,$FE,$03,$FB,$30,$FE,$08,$D4,$30,$30
	db $30,$D6,$B1,$FE,$FF
	dw tblSound_Level2MusicRepeat4Definition


;*************
;Level 3 Music
;*************	
;Pulse 2
tblSound_Level3MusicRepeat2Definition:	
tblSound_Level3Music2Definition:
	db $FB,$D3,$73,$01,$75,$E2,$43,$D3,$B2,$00,$0F,$E4,$91,$91,$91,$91
	db $D3,$73,$01,$75,$E2,$63,$D3,$B2,$00,$0F,$E4,$91,$91,$91,$91,$D3
	db $73,$01,$75,$E2,$73,$D3,$B2,$00,$0F,$E4,$91,$91,$91,$91,$D3,$73
	db $01,$75,$E2,$63,$D3,$B2,$00,$0F,$E4,$91,$91,$91,$91,$FE,$02,$FB
	db $D3,$74,$01,$00,$E2,$41,$21,$41,$D3,$74,$0D,$97,$07,$E3,$D3,$74
	db $1F,$00,$91,$E2,$01,$41,$91,$71,$D3,$74,$01,$00,$E2,$61,$41,$61
	db $D3,$74,$0D,$97,$29,$D3,$74,$01,$00,$21,$61,$91,$E1,$21,$47,$D1
	db $71,$80,$00,$C0,$44,$D3,$74,$01,$00,$41,$D3,$74,$1F,$00,$E1,$01
	db $41,$E2,$91,$E1,$01,$E2,$71,$91,$D3,$74,$0E,$00,$63,$D3,$74,$1F
	db $00,$61,$21,$61,$21,$91,$61,$91,$E1,$21,$E2,$91,$61,$D3,$74,$01
	db $00,$41,$21,$41,$D3,$74,$0D,$97,$07,$D3,$74,$1F,$00,$E3,$91,$E2
	db $01,$41,$91,$71,$D3,$74,$01,$00,$61,$41,$61,$D3,$74,$0D,$97,$29
	db $D3,$74,$01,$00,$21,$61,$91,$E1,$21,$47,$D1,$71,$80,$00,$C0,$44
	db $D3,$74,$01,$00,$41,$D3,$74,$1F,$00,$E1,$01,$41,$E2,$91,$E1,$01
	db $E2,$71,$91,$D3,$74,$01,$97,$69,$61,$75,$95,$FB,$D3,$74,$01,$37
	db $E2,$71,$61,$71,$4B,$21,$41,$21,$D3,$B2,$00,$0F,$E3,$03,$01,$D3
	db $33,$1F,$00,$E2,$01,$41,$71,$D3,$B2,$00,$0F,$E3,$23,$21,$D3,$33
	db $1F,$00,$E2,$41,$61,$91,$D3,$74,$01,$37,$71,$61,$71,$49,$41,$21
	db $41,$21,$D3,$B2,$00,$0F,$E3,$03,$01,$D3,$33,$1F,$00,$E2,$71,$41
	db $71,$D3,$B2,$00,$0F,$E3,$23,$21,$D3,$33,$1F,$00,$E2,$91,$61,$91
	db $FB,$D3,$74,$01,$57,$E2,$71,$61,$71,$4B,$21,$41,$21,$D3,$B2,$00
	db $0F,$E3,$03,$01,$D3,$33,$1F,$00,$E2,$71,$71,$71,$D3,$B2,$00,$0F
	db $E3,$23,$21,$D3,$33,$1F,$00,$E2,$91,$91,$91,$D3,$74,$01,$A7,$E2
	db $71,$61,$71,$49,$61,$71,$61,$71,$45,$95,$75,$65,$FB,$D3,$74,$0E
	db $00,$E2,$43,$41,$D3,$74,$0D,$66,$6B,$D3,$74,$0E,$00,$63,$61,$D3
	db $74,$0D,$65,$75,$9B,$D3,$74,$0E,$00,$23,$21,$D3,$74,$0D,$93,$45
	db $6B,$D3,$74,$0E,$00,$63,$D3,$74,$0D,$93,$71,$91,$61,$91,$E1,$2B
	db $D3,$74,$0E,$00,$E1,$23,$21,$D3,$74,$01,$93,$E1,$45,$6B,$D3,$74
	db $0E,$00,$63,$61,$D3,$74,$01,$93,$75,$97,$D1,$71,$80,$00,$C0,$94
	db $D3,$74,$01,$00,$91,$21,$41,$61,$D3,$74,$0F,$00,$91,$61,$21,$E2
	db $91,$61,$21,$E3,$91,$E2,$21,$61,$E1,$21,$E1,$61,$E1,$21,$81,$41
	db $E2,$B1,$81,$41,$E3,$B1,$81,$B1,$E2,$41,$E2,$81,$B1,$61,$FE,$FF
	dw tblSound_Level3MusicRepeat2Definition

;Pulse 1
tblSound_Level3MusicRepeatDefinition:	
tblSound_Level3MusicDefinition:		
	db $FB,$D3,$74,$01,$85,$E2,$03,$D3,$B4,$00,$0F,$E3,$41,$41,$41,$41
	db $D3,$75,$01,$85,$E2,$23,$D3,$B4,$00,$0F,$E3,$41,$41,$41,$41,$D3
	db $75,$01,$85,$E2,$43,$D3,$B4,$00,$0F,$E3,$41,$41,$41,$41,$D3,$75
	db $01,$85,$E2,$23,$D3,$B4,$00,$0F,$E3,$41,$41,$41,$41,$FE,$02,$FB
	db $D3,$75,$01,$00,$E2,$01,$E3,$B1,$E2,$01,$D3,$75,$0D,$94,$E3,$97
	db $D3,$74,$81,$00,$E8,$E3,$93,$E2,$01,$41,$91,$E8,$D3,$75,$01,$00
	db $E2,$21,$01,$21,$D3,$75,$0D,$94,$E3,$99,$D3,$75,$01,$00,$E3,$91
	db $E2,$21,$61,$91,$E1,$07,$D1,$71,$80,$00,$C0,$04,$D3,$74,$01,$00
	db $01,$E8,$D3,$74,$81,$00,$E1,$03,$41,$E2,$91,$E1,$01,$E2,$71,$91
	db $63,$61,$21,$61,$21,$91,$61,$91,$E1,$21,$E2,$91,$E8,$D3,$75,$01
	db $00,$01,$E3,$B1,$E2,$01,$E3,$D3,$75,$0D,$94,$97,$E8,$D3,$74,$81
	db $00,$E3,$93,$E2,$01,$41,$91,$E8,$D3,$75,$01,$95,$21,$01,$21,$D3
	db $75,$0D,$94,$E3,$99,$D3,$75,$01,$00,$E3,$91,$E2,$21,$61,$91,$E1
	db $07,$D1,$71,$80,$00,$C0,$04,$D3,$74,$01,$00,$01,$E8,$D3,$74,$81
	db $00,$E1,$03,$41,$E2,$91,$E1,$01,$E2,$71,$D3,$75,$01,$95,$29,$21
	db $45,$65,$E8,$FB,$D3,$75,$01,$77,$E2,$41,$21,$41,$E3,$BB,$91,$E2
	db $01,$E3,$91,$D3,$B3,$00,$0F,$E8,$E3,$73,$71,$D3,$74,$82,$00,$E2
	db $03,$41,$D3,$B3,$00,$0F,$E3,$93,$91,$D3,$74,$82,$00,$E2,$43,$61
	db $D3,$75,$01,$77,$41,$21,$41,$E3,$B9,$B1,$91,$E2,$01,$E3,$91,$D3
	db $B3,$00,$0F,$E3,$73,$71,$D3,$74,$82,$00,$E2,$73,$41,$D3,$B3,$00
	db $0F,$E3,$93,$91,$D3,$74,$82,$00,$E2,$93,$61,$E8,$FB,$D3,$75,$01
	db $77,$E2,$41,$21,$41,$E3,$BB,$E3,$91,$E2,$01,$E3,$91,$D3,$B3,$00
	db $0F,$E3,$73,$71,$D3,$74,$82,$00,$E8,$E2,$73,$71,$D3,$B3,$00,$0F
	db $E3,$93,$91,$D3,$74,$82,$00,$E2,$93,$91,$E8,$D3,$75,$01,$A5,$41
	db $21,$41,$E3,$B9,$E2,$21,$41,$21,$41,$05,$65,$45,$25,$FB,$D3,$75
	db $0E,$00,$E2,$03,$01,$D3,$75,$0D,$86,$2B,$D3,$75,$0E,$00,$23,$21
	db $D3,$75,$0D,$85,$45,$6B,$D3,$75,$0E,$00,$E3,$93,$D3,$75,$0D,$A3
	db $91,$E2,$05,$2B,$D3,$75,$0E,$00,$23,$41,$D3,$75,$0D,$86,$61,$21
	db $61,$9B,$D3,$75,$0E,$00,$93,$91,$D3,$75,$0D,$86,$E1,$05,$2B,$23
	db $21,$D3,$75,$0D,$86,$45,$67,$D1,$71,$80,$00,$C0,$64,$D3,$74,$01
	db $00,$61,$E2,$91,$E1,$01,$21,$E8,$D3,$B2,$80,$00,$94,$61,$21,$E2
	db $91,$61,$21,$E3,$91,$E2,$21,$61,$E1,$21,$61,$21,$81,$41,$E2,$B1
	db $81,$41,$E3,$B1,$81,$B1,$E2,$41,$81,$B0,$E8,$FE,$FF
	dw tblSound_Level3MusicRepeatDefinition
	
;Triangle
tblSound_Level3MusicRepeat3Definition:
tblSound_Level3Music3Definition:
	db $FB,$D3,$21,$E3,$93,$D3,$0F,$91,$91,$91,$91,$FE,$08,$FB,$D3,$19
	db $E3,$93,$D3,$12,$91,$FE,$04,$FB,$D3,$19,$E2,$23,$D3,$12,$21,$FE
	db $04,$FB,$D3,$19,$03,$D3,$12,$01,$FE,$04,$FB,$D3,$19,$23,$D3,$12
	db $21,$FE,$04,$FB,$E3,$D3,$19,$93,$D3,$12,$91,$FE,$04,$FB,$E2,$D3
	db $19,$23,$D3,$12,$21,$FE,$04,$FB,$D3,$19,$03,$D3,$12,$01,$FE,$04
	db $FB,$D3,$19,$23,$D3,$12,$21,$FE,$02,$D3,$19,$03,$D3,$12,$01,$21
	db $21,$21,$FB,$D3,$18,$E2,$43,$D3,$12,$41,$D3,$18,$43,$D3,$12,$41
	db $D3,$18,$43,$D3,$12,$41,$21,$21,$21,$E3,$03,$E2,$01,$03,$01,$E3
	db $23,$E2,$21,$23,$21,$FE,$03,$FB,$D3,$18,$43,$D3,$12,$41,$FE,$03
	db $21,$21,$21,$D3,$3A,$E2,$05,$E3,$75,$E2,$25,$E3,$95,$FB,$D3,$18
	db $E2,$03,$D3,$12,$01,$FE,$06,$03,$E3,$01,$41,$71,$E2,$01,$FB,$D3
	db $18,$23,$D3,$12,$21,$FE,$06,$23,$E3,$21,$61,$91,$B1,$FB,$D3,$18
	db $E2,$03,$D3,$12,$01,$FE,$07,$01,$01,$21,$FB,$D3,$19,$43,$D3,$12
	db $41,$FE,$03,$41,$E3,$91,$E2,$41,$FB,$D3,$18,$43,$D3,$12,$41,$FE
	db $02,$43,$E3,$41,$81,$B1,$E2,$21,$FE,$FF
	dw tblSound_Level3MusicRepeat3Definition	

;DMC
tblSound_Level3MusicRepeat4Definition:
tblSound_Level3Music4Definition:
	db $FB,$D3,$B3,$B1,$41,$B1,$B1,$FE,$07,$FB,$41,$FE,$06,$FB,$D3,$B3
	db $B1,$43,$B1,$FE,$0F,$B3,$B1,$41,$31,$31,$FB,$D3,$B3,$B1,$43,$B1
	db $B3,$B1,$41,$31,$31,$B3,$B1,$43,$B1,$B3,$B1,$41,$B1,$B1,$FE,$03
	db $B3,$B1,$43,$B1,$B3,$B1,$41,$31,$31,$B3,$B1,$43,$B1,$41,$31,$31
	db $41,$31,$31,$FB,$D3,$B3,$B1,$41,$B1,$B1,$B3,$B1,$43,$B1,$FE,$03
	db $B3,$B1,$41,$B1,$B1,$B3,$B1,$41,$31,$31,$B3,$B1,$41,$B1,$B1,$B3
	db $B1,$43,$B1,$B3,$B1,$41,$B1,$B1,$B3,$B1,$41,$31,$31,$FB,$41,$B1
	db $B1,$FE,$05,$41,$31,$31,$FB,$41,$FE,$06,$FE,$FF
	dw tblSound_Level3MusicRepeat4Definition
	


;**********
;Boss Music
;**********
;Pulse 1
tblSound_FinalBossMusicDefinition:
	db $FB,$E8,$D6,$B6,$12,$00,$E4,$03,$F4,$13,$F2,$23,$F0,$33,$D6,$75
	db $01,$00,$E2,$B0,$40,$E3,$B0,$D6,$B3,$00,$0F,$E3,$41,$40,$D6,$74
	db $01,$00,$E4,$40,$B0,$E3,$40,$E1,$00,$E2,$50,$E2,$00,$D6,$B3,$00
	db $0F,$E3,$51,$50,$D6,$74,$01,$00,$E4,$50,$E3,$00,$50,$E1,$10,$E2
	db $60,$10,$D6,$B3,$00,$0F,$E3,$61,$60,$D6,$74,$01,$00,$E3,$10,$60
	db $E2,$10,$D4,$74,$80,$00,$E3,$72,$80,$A0,$B0,$E2,$10,$20,$40,$50
	db $70,$80,$E8
	;final boss music continues into the normal boss music
tblSound_BossMusicDefinition:
	db $FB,$D6,$B5,$0C,$0F,$E4,$90,$90,$D6,$75,$01,$00,$E3,$90,$D6,$B5
	db $0C,$0F,$E4,$90,$90,$D6,$75,$01,$00,$E3,$90,$D6,$B5,$0C,$0F,$E4
	db $90,$90,$D6,$75,$01,$00,$E3,$90,$D6,$B5,$0C,$0F,$E4,$90,$90,$D6
	db $75,$01,$00,$E3,$90,$D6,$B5,$0C,$0F,$E4,$90,$90,$D6,$75,$01,$00
	db $E3,$90,$D6,$B5,$0C,$0F,$E4,$90,$FE,$04
tblSound_BossMusicRepeatDefinition:
	db $FB,$E8,$D6,$B5,$01,$76
	db $E2,$02,$02,$D6,$B5,$0D,$00,$04,$E3,$D6,$F5,$80,$00,$41,$70,$90
	db $E2,$00,$D6,$B5,$01,$76,$E2,$22,$22,$D6,$B5,$0D,$00,$24,$D6,$F5
	db $80,$00,$E3,$22,$60,$90,$E2,$D6,$B5,$01,$76,$52,$52,$D6,$B5,$0D
	db $00,$54,$D6,$F5,$80,$00,$E3,$52,$90,$E2,$00,$D6,$B5,$01,$76,$72
	db $72,$D6,$B5,$0D,$75,$79,$FB,$D6,$B5,$10,$00,$E3,$94,$D6,$B5,$01
	db $00,$00,$20,$E2,$05,$E3,$00,$20,$B5,$00,$20,$A5,$00,$20,$D6,$B5
	db $10,$00,$95,$D6,$B5,$01,$00,$E3,$00,$20,$E2,$05,$E3,$00,$20,$B5
	db $00,$20,$A5,$00,$20,$E2,$00,$E8,$FB,$D6,$B3,$01,$35,$E4,$72,$62
	db $52,$42,$31,$21,$1F,$FE,$FF
	dw tblSound_BossMusicRepeatDefinition

;Pulse 2
tblSound_FinalBossMusic2Definition:
	db $FB,$D6,$79,$12,$00,$E2,$03,$F7,$13,$F4,$23,$F2,$33,$D6,$74,$01
	db $00,$E1,$40,$E2,$B0,$40,$D6,$B2,$00,$0F,$E4,$41,$40,$40,$D6,$74
	db $01,$00,$B0,$E3,$40,$E1,$50,$00,$E2,$50,$D6,$B2,$00,$0F,$E4,$51
	db $50,$50,$D6,$74,$01,$00,$E3,$00,$E2,$50,$E1,$60,$10,$E2,$60,$D6
	db $B2,$01,$0F,$E4,$61,$60,$D6,$74,$01,$00,$E3,$60,$E2,$10,$60,$D4
	db $74,$11,$00,$E3,$70,$80,$A0,$B0,$E2,$10,$20,$40,$50,$70,$80,$A0
	db $B0
	;final boss music continues into the normal boss music
tblSound_BossMusic2Definition:
	db $FB,$D6,$B4,$0C,$0F,$E3,$40,$40,$D6,$74,$01,$00,$E2,$00,$D6,$B4
	db $0C,$0F,$E3,$40,$40,$D6,$74,$01,$00,$E2,$20,$D6,$B4,$0C,$0F,$E3
	db $40,$40,$D6,$74,$01,$00,$E2,$00,$D6,$B4,$0C,$0F,$E3,$40,$40,$D6
	db $74,$01,$00,$E2,$20,$D6,$B4,$0C,$0F,$E3,$40,$40,$D6,$74,$01,$00
	db $E2,$00,$D6,$B4,$0C,$0F,$E3,$40,$40,$40,$D6,$74,$01,$00,$E2,$00
	db $D6,$B4,$0C,$0F,$E3,$40,$40,$D6,$74,$01,$00,$E2,$20,$D6,$B4,$0C
	db $0F,$E3,$40,$40,$D6,$74,$01,$00,$E2,$20,$D6,$B4,$0C,$0F,$E3,$40
	db $40,$D6,$74,$01,$00,$E2,$20,$D6,$B4,$0C,$0F,$E3,$40,$40,$D6,$74
	db $01,$00,$E3,$B0,$D6,$B4,$0C,$0F,$E3,$40,$FE,$02
tblSound_BossMusicRepeat2Definition:
	db $FB,$D6,$74,$01
	db $46,$E2,$42,$42,$D6,$74,$0D,$75,$44,$D6,$F4,$1F,$00,$E3,$40,$70
	db $90,$E2,$00,$40,$D6,$74,$01,$46,$62,$62,$D6,$74,$0D,$75,$64,$D6
	db $74,$1F,$00,$E3,$20,$60,$90,$E2,$20,$60,$D6,$74,$01,$46,$92,$92
	db $D6,$74,$0D,$75,$94,$D6,$74,$1F,$00,$E3,$50,$90,$E2,$00,$50,$90
	db $D6,$74,$01,$46,$B2,$B2,$D6,$74,$0D,$75,$B9,$FB,$D6,$74,$10,$00
	db $E2,$44,$D6,$74,$01,$00,$E3,$90,$E2,$00,$75,$E3,$90,$E2,$00,$65
	db $E3,$90,$E2,$00,$55,$E3,$90,$E2,$00,$D6,$74,$10,$00,$45,$D6,$74
	db $01,$00,$E3,$90,$E2,$00,$75,$E3,$90,$E2,$00,$65,$E3,$90,$E2,$00
	db $55,$E3,$90,$E2,$00,$40,$FB,$D6,$34,$01,$32,$E2,$72,$62,$52,$42
	db $31,$21,$1F,$FE,$FF
	dw tblSound_BossMusicRepeat2Definition

;Triangle
tblSound_FinalBossMusic3Definition:
	db $FB,$D6,$90,$E3,$73,$83,$93,$A3,$FB,$D6,$35,$E3,$42,$D6,$22,$E3
	db $41,$E3,$41,$D6,$10,$40,$FE,$03,$D6,$90,$46,$50,$60,$70,$80
	;final boss music continues into the normal boss music
tblSound_BossMusic3Definition:
	db $FB,$D6,$90,$E3,$9F,$D1,$90,$A0,$B0,$E2,$00,$20,$30,$40,$D6,$90
	db $E2,$56,$D6,$35,$42,$42,$41,$FE,$02
tblSound_BossMusicRepeat3Definition:
	db $FB,$D6,$20,$E3,$91,$D6,$12
	db $E2,$90,$D6,$20,$E3,$91,$D6,$12,$90,$E2,$90,$E3,$90,$FE,$02,$FB
	db $D6,$20,$E2,$21,$D6,$12,$E1,$20,$D6,$20,$E2,$21,$D6,$12,$20,$E1
	db $20,$E2,$20,$FE,$02,$FB,$D6,$20,$E2,$51,$D6,$12,$E1,$50,$D6,$20
	db $E2,$51,$D6,$12,$50,$E1,$50,$E2,$50,$FE,$02,$FB,$D6,$20,$E3,$71
	db $D6,$12,$E2,$70,$D6,$20,$E3,$71,$D6,$12,$70,$E2,$70,$E3,$70,$FE
	db $02,$FB,$D6,$20,$E3,$91,$D6,$10,$90,$90,$E2,$90,$E3,$90,$90,$90
	db $FE,$08,$FB,$D6,$11,$E2,$70,$70,$70,$60,$60,$60,$50,$50,$50,$40
	db $40,$40,$30,$30,$20,$20,$D6,$90,$1F,$FE,$FF
	dw tblSound_BossMusicRepeat3Definition

;DMC
tblSound_FinalBossMusic4Definition:
	db $FB,$D6,$33,$33,$FB,$30,$FE,$04,$D4,$FB,$30,$FE,$06,$D6,$FB,$B0
	db $B0,$40,$FE,$09,$D4,$FB,$30,$FE,$06,$FB,$40,$FE,$06
	;final boss music continues into the normal boss music
tblSound_BossMusic4Definition:
	db $FB,$D6,$B1,$40,$B1,$B0,$40,$B0,$B1,$40,$B0,$B0,$B0,$40,$B0,$B1
	db $40,$B1,$B0,$40,$B0,$B1,$40,$B0,$40,$40,$40,$40,$B1,$40,$B1,$B0
	db $40,$B0,$B1,$40,$B0,$B0,$B0,$40,$B0,$B1,$40,$B1,$B0,$40,$B0,$FB
	db $40,$FE,$08
tblSound_BossMusicRepeat4Definition:
	db $FB,$B0,$B0,$40,$B0,$FE,$0E,$B0,$FB,$40,$FE,$07,$FB
	db $B0,$B0,$40,$B0,$FE,$0E,$B0,$FB,$40,$FE,$07,$FB,$40,$B0,$B0,$FE
	db $04,$40,$B0,$40,$B0,$B0,$FB,$40,$B0,$B0,$FE,$03,$40,$40,$40,$40
	db $40,$40,$FE,$FF
	dw tblSound_BossMusicRepeat4Definition

;**************************
;Stage Complete/Segue Music
;**************************
;Pulse 1
tblSound_StageCompleteSegueDefinition:
	db $FB,$D5,$75,$0E,$00,$E3,$93,$D5,$76,$84,$00,$91,$D5,$75,$01,$00
	db $B5,$B1,$D5,$76,$84,$00,$91,$71,$D5,$75,$01,$00,$E2,$05,$D5,$75
	db $0E,$00,$03,$D5,$76,$84,$00,$01,$43,$41,$43,$41,$25,$D5,$75,$01
	db $00,$E3,$91,$91,$91,$FB,$D5,$75,$01,$00,$E3,$B5,$D5,$76,$84,$00
	db $E2,$23,$E3,$B1,$E2,$05,$D5,$75,$01,$00,$43,$D5,$76,$84,$00,$41
	db $23,$D1,$76,$84,$00,$2A,$D2,$76,$84,$00,$2A,$D1,$76,$84,$00,$0D
	db $D6,$75,$01,$32,$E3,$BF,$FF

;Pulse 2
tblSound_StageCompleteSegue2Definition:	
	db $FB,$D5,$74,$0E,$00,$E2,$23
	db $D5,$79,$86,$00,$21,$D5,$74,$01,$25,$75,$D5,$74,$01,$00,$71,$D5
	db $79,$86,$00,$61,$21,$D5,$74,$01,$25,$45,$D5,$74,$0E,$00,$43,$D5
	db $79,$86,$00,$41,$93,$71,$63,$71,$64,$D5,$71,$80,$00,$60,$D5,$74
	db $01,$00,$21,$21,$21,$FB,$D5,$74,$01,$25,$E2,$75,$D5,$79,$86,$00
	db $B3,$71,$44,$D5,$71,$80,$00,$40,$D5,$74,$01,$00,$E1,$03,$D5,$79
	db $86,$00,$E2,$B1,$B3,$D1,$79,$86,$00,$9A,$D2,$79,$86,$00,$7A,$D1
	db $79,$86,$00,$6D,$D6,$74,$01,$32,$7F,$FF

;Triangle
tblSound_StageCompleteSegue3Definition:
	db $FB,$D5,$55,$E3,$C5,$75,$75,$E2,$05,$05,$15,$15,$25,$D5,$1C,$21
	db $21,$21,$FB,$D5,$36,$E3,$73,$D5,$1A,$71,$71,$91,$B1,$D5,$36,$E2
	db $03,$D5,$1A,$01,$D5,$36,$03,$D5,$1A,$11,$D5,$36,$23,$D1,$1A,$2A
	db $D3,$36,$26,$D6,$1A,$21,$D6,$90,$E3,$7B,$72,$FF

;DMC
tblSound_StageCompleteSegue4Definition:	
	db $FB,$D5,$C5,$FB,$B3,$11,$31,$C1,$B1,$FE,$02,$B3,$11,$33,$11,$43
	db $D1,$C2,$32,$43,$D5,$41,$31,$31,$FB,$D5,$FB,$B3,$11,$41,$11,$11
	db $FE,$02,$45,$D1,$C0,$42,$FB,$32,$FE,$0A,$10,$4F,$FF

;***************
;Game Over Music
;***************
;Pulse 1
tblSound_GameOverContinueDefinition:	
	db $FB,$D4,$74,$01,$00,$E1,$01,$D4,$79,$86,$00,$E2,$B1,$E1,$01,$D4
	db $74,$01,$31,$E2,$B5,$D4,$79,$86,$32,$75,$D4,$74,$01,$33,$23,$D4
	db $79,$86,$00,$71,$D4,$74,$01,$00,$51,$D4,$79,$86,$00,$41,$01,$D4
	db $74,$01,$31,$25,$D4,$79,$86,$32,$B5,$D4,$74,$01,$00,$A1,$D4,$79
	db $86,$00,$51,$A1,$E1,$01,$E2,$71,$E1,$01,$E1,$D8,$79,$86,$21,$2B
	db $D4,$7A,$87,$00,$C5,$E2,$21,$21,$21,$25,$D4,$72,$81,$00,$21,$FF

;Pulse 2
tblSound_GameOverContinue2Definition:	
	db $FB,$D4,$75,$01,$00,$E2,$91,$D4,$76,$84,$00,$71,$91,$D4,$75,$01
	db $00,$75,$D4,$76,$84,$00,$25,$D4,$75,$01,$00,$E3,$B3,$D4,$76,$84
	db $00,$E2,$21,$D4,$75,$01,$00,$21,$D4,$76,$84,$00,$01,$E3,$91,$D4
	db $75,$01,$00,$B5,$D4,$76,$84,$00,$E2,$75,$D4,$75,$01,$00,$51,$D4
	db $76,$84,$00,$01,$51,$E2,$71,$41,$71,$D8,$76,$84,$00,$9A,$D8,$71
	db $80,$00,$90,$D4,$B6,$84,$00,$E3,$C5,$61,$61,$61,$65,$D4,$B2,$81
	db $00,$60,$FF

;Triangle
tblSound_GameOverContinue3Definition:
	db $FB,$D4,$44,$C5,$E3,$75,$75,$D4,$2C,$73,$D4,$16,$71,$E2,$01,$01
	db $01,$D4,$44,$E3,$75,$75,$D4,$2D,$A3,$D4,$16,$A1,$E2,$01,$01,$01
	db $D6,$90,$2A,$C0,$D4,$15,$21,$61,$91,$21,$C3,$D4,$17,$21,$21,$21
	db $D4,$90,$25,$FF

;DMC
tblSound_GameOverContinue4Definition:	
	db $FB,$D4,$C5,$FB,$B1,$11,$11,$FE,$02,$B1,$11,$D1,$C0,$32,$33,$D4
	db $31,$31,$31,$FB,$B1,$11,$11,$FE,$02,$FB,$31,$FE,$06,$FB,$B1,$11
	db $11,$FE,$02,$B1,$11,$D1,$C0,$32,$33,$D4,$31,$31,$31,$33,$D1,$C0
	db $32,$33,$D4,$31,$31,$31,$35,$FF

;*****************
;End Of Game Music
;*****************
;Pulse 2
tblSound_EndOfGame2Definition:	
	db $FB,$D7,$74,$19,$31,$E2,$78,$D1,$71,$80,$00,$C0,$75,$D7,$74,$13
	db $00,$01,$72,$E1,$00,$D7,$74,$1B,$32,$E2,$9C,$D1,$71,$80,$00,$C0
	db $95,$D7,$74,$13,$00,$90,$E1,$00,$D7,$74,$19,$31,$E1,$5A,$D1,$71
	db $80,$00,$C0,$55,$D7,$74,$13,$00,$42,$20,$40,$D1,$71,$80,$00,$C0
	db $45,$D7,$74,$1B,$31,$0C,$D1,$71,$80,$00,$C0,$05,$FE,$02
tblSound_EndOfGameRepeat2Definition:
	db $FB,$D7
	db $74,$15,$34,$E1,$35,$D7,$74,$14,$25,$30,$30,$32,$22,$31,$51,$D1
	db $71,$80,$00,$C0,$55,$D7,$74,$14,$53,$E2,$A0,$D7,$74,$1D,$00,$A8
	db $D1,$71,$80,$00,$C0,$A5,$D7,$74,$14,$00,$A0,$E1,$50,$D7,$74,$15
	db $35,$85,$D7,$74,$14,$25,$80,$80,$72,$52,$31,$D7,$74,$1B,$32,$5F
	db $FB,$D7,$74,$15,$34,$E1,$35,$D7,$74,$14,$25,$30,$30,$32,$22,$31
	db $51,$D1,$71,$80,$00,$C0,$55,$D7,$74,$14,$53,$E2,$A0,$D7,$74,$1D
	db $00,$A8,$D1,$71,$80,$00,$C0,$A5,$D7,$74,$14,$00,$70,$A0,$D7,$74
	db $14,$25,$E1,$02,$D1,$71,$80,$00,$C0,$05,$D7,$74,$14,$25,$E2,$82
	db $70,$53,$A3,$D7,$74,$14,$35,$E1,$05,$D7,$74,$16,$00,$E2,$00,$00
	db $01,$01,$01,$01,$FB,$D7,$74,$1B,$31,$E2,$78,$D1,$71,$80,$00,$C0
	db $75,$D7,$74,$13,$00,$01,$72,$E1,$00,$D7,$74,$1B,$32,$E2,$99,$D7
	db $73,$18,$00,$50,$40,$50,$70,$90,$E1,$00,$D7,$74,$1B,$31,$E1,$5A
	db $D1,$71,$80,$00,$C0,$55,$D7,$74,$13,$00,$42,$20,$40,$D1,$71,$80
	db $00,$C0,$45,$D7,$74,$1B,$31,$0C,$D1,$71,$80,$00,$C0,$05,$FE,$02
	db $FE,$FF
	dw tblSound_EndOfGameRepeat2Definition

;Pulse 1
tblSound_EndOfGameDefinition:
	db $FB,$D7,$74,$1A,$31,$E2,$48,$D1,$71,$80,$00,$C0,$45,$D7,$74,$13
	db $00,$E3,$71,$E2,$02,$70,$D7,$74,$1C,$32,$5C,$D1,$71,$80,$00,$C0
	db $55,$D7,$74,$13,$00,$50,$50,$D7,$74,$19,$31,$8A,$D1,$71,$80,$00
	db $C0,$85,$D7,$74,$13,$00,$82,$50,$70,$D1,$71,$80,$00,$C0,$75,$D7
	db $74,$1C,$31,$4C,$D1,$71,$80,$00,$C0,$45,$FE,$02
tblSound_EndOfGameRepeatDefinition:
	db $FB,$D7,$74,$15
	db $44,$E2,$75,$D7,$74,$14,$25,$70,$70,$72,$72,$71,$A1,$D1,$71,$80
	db $00,$C0,$A5,$D7,$74,$14,$53,$50,$D7,$74,$1E,$00,$58,$D1,$71,$80
	db $00,$C0,$55,$D7,$74,$14,$00,$50,$E1,$00,$D7,$74,$15,$44,$05,$D7
	db $74,$14,$25,$00,$00,$E2,$A2,$82,$71,$D7,$B2,$17,$00,$E4,$A1,$A0
	db $A0,$81,$80,$80,$71,$70,$70,$51,$50,$50,$FB,$D7,$73,$15,$44,$E2
	db $75,$D7,$74,$14,$25,$70,$70,$72,$72,$71,$A1,$D1,$71,$80,$00,$C0
	db $A5,$D7,$74,$14,$53,$50,$D7,$74,$1E,$00,$58,$D1,$71,$80,$00,$C0
	db $55,$D7,$74,$14,$00,$20,$50,$D7,$74,$14,$25,$82,$D1,$71,$80,$00
	db $C0,$85,$D7,$74,$14,$25,$52,$30,$23,$53,$D7,$74,$14,$35,$45,$D7
	db $B4,$16,$00,$E3,$40,$40,$41,$41,$41,$41,$FB,$D7,$74,$14,$31,$E2
	db $48,$D1,$71,$80,$00,$C0,$45,$D7,$74,$13,$00,$E3,$71,$E2,$02,$70
	db $D7,$74,$13,$32,$59,$D1,$72,$80,$00,$E8,$5C,$46,$56,$76,$90,$E1
	db $06,$E2,$D7,$74,$14,$31,$8A,$D1,$71,$80,$00,$C0,$85,$D7,$74,$13
	db $00,$82,$50,$70,$D1,$71,$80,$00,$C0,$75,$D7,$74,$1C,$31,$4C,$D1
	db $71,$80,$00,$C0,$45,$FE,$02,$FE,$FF
	dw tblSound_EndOfGameRepeatDefinition
	
;Triangle
tblSound_EndOfGame3Definition:
	db $FB,$D7,$30,$E2,$02,$D7,$13,$E3,$00,$00,$E2,$00,$00,$00,$D7,$25
	db $E3,$01,$D7,$40,$E2,$05,$FE,$07,$D7,$28,$E2,$02,$D7,$12,$E3,$00
	db $00,$E2,$00,$00,$00,$D7,$22,$E3,$01,$E2,$01,$E3,$21,$D7,$13,$E2
	db $20,$20
tblSound_EndOfGameRepeat3Definition:
	db $FB,$D7,$15,$E3,$31,$E2,$30,$E2,$30,$FE,$03,$E3,$70,$60
	db $70,$80,$FB,$E3,$A1,$E2,$A0,$E3,$A0,$FE,$04,$FB,$81,$E2,$80,$E3
	db $80,$FE,$02,$E2,$31,$E1,$30,$E2,$30,$31,$E3,$70,$80,$E3,$E8,$A1
	db $E2,$A0,$E3,$A0,$81,$E2,$80,$E3,$80,$71,$E2,$70,$E3,$70,$51,$E2
	db $50,$E3,$50,$FB,$D7,$14,$FB,$E3,$31,$E2,$30,$30,$FE,$03,$E3,$70
	db $60,$70,$80,$FB,$E3,$A1,$E2,$A0,$E3,$A0,$FE,$03,$A1,$E2,$50,$70
	db $D7,$90,$83,$C1,$D7,$1C,$E3,$81,$D7,$90,$A5,$C1,$E2,$03,$C1,$D7
	db $14,$00,$00,$01,$01,$01,$01,$FB,$D7,$15,$E2,$01,$00,$00,$41,$40
	db $40,$71,$70,$70,$41,$40,$40,$51,$50,$50,$01,$00,$00,$E3,$91,$90
	db $90,$51,$50,$50,$81,$80,$80,$E2,$01,$00,$00,$51,$50,$50,$01,$00
	db $00,$01,$00,$00,$E3,$71,$70,$70,$E2,$01,$00,$00,$21,$20,$20,$FE
	db $02,$FE,$FF
	dw tblSound_EndOfGameRepeat3Definition

;DMC
tblSound_EndOfGame4Definition:
	db $FB,$D7,$B2,$10,$30,$10,$B0,$10,$B1,$B1,$33,$FE,$03,$B2,$10,$30
	db $10,$B0,$10,$B1,$31,$31,$30,$30,$FB,$B2,$10,$30,$10,$B0,$10,$B1
	db $B1,$31,$10,$10,$FE,$03,$B2,$10,$30,$10,$B0,$10,$B1,$B1,$31,$30
	db $30
tblSound_EndOfGameRepeat4Definition:
	db $FB,$D7,$B1,$B0,$10,$31,$B0,$10,$FE,$06,$FB,$31,$B0,$B0,$FE
	db $03,$30,$30,$30,$30,$FB,$D7,$FB,$B1,$B0,$10,$31,$B0,$10,$FE,$03
	db $B1,$B0,$10,$31,$30,$30,$B2,$10,$31,$B1,$B2,$10,$31,$31,$B3,$31
	db $B0,$B0,$B1,$B1,$31,$30,$30,$FB,$D7,$FB,$B1,$10,$B0,$31,$B0,$10
	db $FE,$07,$B1,$10,$B0,$31,$30,$30,$FB,$B1,$10,$B0,$31,$B0,$10,$FE
	db $07,$B1,$10,$B0,$30,$30,$30,$30,$FE,$FF
	dw tblSound_EndOfGameRepeat4Definition





	
	
	
	
	
	
;********************************
;Title Screen POW Portraits music
;********************************	
;Pulse 2
tblSound_TitleScreenStory_POWPortraits2Definition:
	db $FB,$D6,$B0,$22,$00,$C1,$E4,$07,$D4,$F8,$84,$00,$E3,$70,$60,$70
	db $90,$A0,$E2,$00,$20,$30,$50,$D6,$F3,$21,$00,$71,$71,$71,$91,$91
	db $91,$D6,$F3,$22,$53,$E1,$08,$D1,$F1,$80,$00,$C0,$05,$D6,$F3,$22
	db $53,$20,$00,$E2,$BB,$D6,$F0,$21,$00,$E4,$0B,$0B,$3B,$3B,$E4,$5B
	db $7B,$8B,$AB,$DC,$F0,$21,$00,$0B,$D6,$F0,$23,$00,$0C,$FF
	
;Pulse 1
tblSound_TitleScreenStory_POWPortraitsDefinition:
	db $FB,$D6,$B1,$22,$00,$C1,$E4,$77,$D4,$F8,$84,$00,$E3,$00,$E4,$B0
	db $E3,$00,$20,$30,$50,$70,$90,$A0,$D6,$F4,$21,$00,$E2,$31,$31,$31
	db $51,$51,$51,$D6,$F4,$22,$53,$7B,$E2,$7B,$E8,$D6,$B1,$23,$00,$E3
	db $05,$E4,$75,$E3,$05,$E4,$71,$E3,$01,$21,$35,$E4,$A5,$E3,$35,$E4
	db $31,$A1,$E3,$31,$55,$E4,$51,$E3,$01,$51,$75,$E4,$71,$E3,$21,$71
	db $85,$E4,$81,$71,$81,$A1,$91,$A1,$E3,$21,$51,$A1,$E2,$01,$E3,$B1
	db $E2,$01,$E3,$71,$61,$71,$31,$21,$31,$01,$E4,$71,$31,$0B,$FF
	
;Triangle
tblSound_TitleScreenStory_POWPortraits3Definition:	
	db $FB,$D6,$90,$E2,$C1,$0C,$C0,$D6,$23,$E3,$31,$A1,$E2,$31,$E3,$51
	db $E2,$01,$51,$E3,$71,$61,$71,$E2,$21,$11,$21,$D6,$60,$75,$E3,$75
	db $D1,$90,$E3,$91,$A1,$B1,$D6,$95,$E2,$04,$E3,$75,$E2,$05,$D6,$24
	db $E3,$71,$E2,$01,$21,$D1,$90,$01,$11,$21,$D6,$90,$34,$E3,$A5,$E2
	db $35,$D6,$24,$E3,$31,$A1,$E2,$31,$D1,$90,$21,$31,$41,$D6,$90,$54
	db $D6,$24,$E3,$51,$E2,$01,$51,$D1,$90,$41,$51,$61,$D6,$90,$74,$D6
	db $24,$E3,$71,$E2,$21,$71,$D1,$90,$51,$61,$71,$D6,$90,$84,$D6,$24
	db $E3,$81,$71,$81,$A1,$91,$A1,$E2,$21,$51,$A1,$E1,$01,$E2,$B1,$E1
	db $01,$E2,$71,$61,$71,$31,$21,$31,$01,$E3,$71,$31,$D6,$90,$0C,$FF

;DMC
tblSound_TitleScreenStory_POWPortraits4Definition:
	db $FB,$D3,$C1,$60,$60,$D6,$63,$63,$D4,$FB,$60,$FE,$09,$D6,$FB,$61
	db $FE,$05,$D3,$60,$60,$60,$60,$D6,$61,$61,$61,$61,$61,$61,$D3,$FB
	db $60,$FE,$17,$C0,$FB,$D6,$63,$61,$61,$61,$D4,$60,$60,$60,$D6,$61
	db $61,$61,$63,$D3,$60,$60,$60,$60,$FE,$02,$FB,$D6,$63,$61,$61,$61
	db $D4,$60,$60,$60,$FE,$03,$D6,$FB,$61,$FE,$05,$D3,$FB,$60,$FE,$04
	db $D6,$63,$61,$61,$61,$D4,$60,$60,$60,$D6,$61,$61,$61,$63,$61,$D3
	db $FB,$60,$FE,$18,$C0,$61,$FF
	


;***********
;END OF GAME
;***********
subProcessEndOfGameLogic:	
	LDA ControlSubState ;End of Game State
	JSR subExecuteCodeViaIndirectJump
	
	dw EndOfGameState0
	dw EndOfGameState1
	dw EndOfGameState2
	dw EndOfGameState3
	dw EndOfGameState4
	dw EndOfGameState5
	dw EndOfGameState6
	dw EndOfGameState7
	dw EndOfGameState8
	dw EndOfGameState9
	dw EndOfGameState10
	dw EndOfGameState11

EndOfGameState0: ;Initialize
	JSR subEraseInGameJeepData
	;A is zero coming out of this JSR
	LDA #$00
	STA Jeep1TypeIndex ;No jeep visual manifestation for either player
	STA Jeep2TypeIndex
	LDA #StageComplete_LevelSegue_SoundClip
	JSR subInitiateSoundClip
	LDA #$F0
	STA $066F
	;Get Game Beat 'Accomplished' Message
	LDX #$00
	JSR fctGetEndOfGameTextHeaderAddress
	LDA tblLevel6BossBeatCongratsMessage,X
	STA $56
	INX
	LDA tblLevel6BossBeatCongratsMessage,X
	STA $58
	INX
	STX $5A
	LDA #$33 ;Green pallet for triangular symbol
	STA $5E
	LDA #$00
	STA $60
	LDA #$60
	STA $54
--:	JMP subIncrementSubGameState

EndOfGameState1:
	JSR subEndOfGame_FinalBossTank_CheckForScroll_FlashComplete
	;The expectation is that the above JSR never completes.  It returns A=1 if
	;;the timer is not finished, but there is no check here at all..
	;;the JSR still counts down the time though, which is necessary
	LDY #$00
	LDA ScreenHorizontalScrollPosition_PPU
	CMP #$80
	BEQ ++ ;Scrolling is complete
	BCC +
	DEC ScreenHorizontalScrollPosition_PPU
	DEC ScreenHorizontalScrollPosition_PPU ;for simplicity, with no JMP or branches, this just cancels out the next line of code
+:	INC ScreenHorizontalScrollPosition_PPU
	JMP +++
++:	INY
+++:	LDA Level6BossTankScroll_Next
	CMP #$80
	BEQ ++
	BCC +
	DEC Level6BossTankScroll_Next
	DEC Level6BossTankScroll_Next ;for simplicity, with no JMP or branches, this just cancels out the next line of code
+:	INC Level6BossTankScroll_Next
	;Find the sprite slot containing the Final Boss tank
	LDY #$0F
-:	LDA SpriteObjectID,Y
	CMP #$4B ;Final Boss Large Tank object ID
	BEQ +
	DEY
	BPL -
	;Y now contains the sprite slot containing the Final Boss tank
+:	LDA Level6BossTankScroll_Next
	STA SpriteHorizScreenPosition,Y
-:	RTS
++:	CPY #$00
	BEQ -
	LDA $60
	BMI ++
	INC $60
	AND #$03
	BNE - ;RTS
	LDY #$31 ;Palette 1 for triangular symbol flash
	LDA $60
	AND #$04
	BNE +
	LDY #$32 ;Palette 2 for triangular symbol flash
+:	TYA
	JSR Label152 ;update palette
	RTS
++:	LDA RNG_INCEveryFrame
	AND #$1F
	BNE - ;RTS
	LDA $5E
	CMP #$35
	BCS -- ;Goto next sub game state
	JSR Label152 ;final updates to palette.  Green and then back to gray
	INC $5E
-:	RTS

EndOfGameState2: ;Write the congrats message to the screen
	JSR subEndOfGame_FinalBossTank_CheckForScroll_FlashComplete
	BNE - ;Timer not finished, RTS
	;Scroll is complete and the large triangular symbol has flashed.
	;;Now write the text to the screen
	JSR EndOfGameState8 ;Write congrats text to the screen
	;State8 will send ControlSubState to $0A if the text writing is all complete
	;;This must be caught here and forced to state $03
	LDA ControlSubState
	CMP #$0A
	BNE + ;RTS
	
	LDA #$C0
	STA ScreenTimerLB
	LDA #$03 ;Force to the next state, 3 (it is $0A from the State8 code)
	STA ControlSubState
	RTS
	
EndOfGameState3: ;Idle - allow player to read text
	JSR fctCountDownScreenTimer ;simple timer
	BNE + ;RTS
	JMP subIncrementSubGameState

EndOfGameState4: ;Back screen transition, EOG nametable, EOG sprite spawn
	JSR subStopMusic
	JSR Label159 ;Load black screen
	JSR subEraseAllSpriteData
	JSR subEraseInGameJeepData
	JSR Label161 ;Load EOG nametable
	LDA #EndOfGameHelicopterSoundClip
	JSR subInitiateSoundClip
	
	;Spawn the shimmering sunset
	LDA #$C4
	STA Sprite1TypeIndex
	LDA #$80
	STA Sprite1HorizScreenPosition
	LDA #$6F
	STA Sprite1VertScreenPosition
	
	;Spawn the lone soldier sprite
	LDA #$C8
	STA Sprite2TypeIndex
	LDA #$62
	STA Sprite2HorizScreenPosition
	LDA #$9E
	STA Sprite2VertScreenPosition
	LDA #$F0
	JMP subIncrementSubGameState_SetScreenTimeLB

EndOfGameState5: ;Sun shimmer + Idle waiting for heli
	JSR subEndOfGameSunShimmer
	JSR fctCountDownScreenTimer
	BNE + ;RTS
	LDA #$BA ;end of game heli 1
	STA SpriteTypeIndex
	;Initial heli position
	LDA #$78
	STA SpriteHorizScreenPosition
	LDA #$6A
	STA SpriteVertScreenPosition
	INC ControlSubState ;Go to the next state
-:
+:	RTS

EndOfGameState6: ;heli approaching
	JSR subEndOfGameSunShimmer
	LDA RNG_INCEveryFrame
	AND #$02 ;show blade rotation every 2 frame
	LSR
	STA $10
	LDA SpriteTypeIndex
	AND #$FE
	ORA $10
	STA SpriteTypeIndex
	LDA RNG_INCEveryFrame
	AND #$07
	BNE - ;RTS
	;move heli every 8 frames
	INC SpriteHorizScreenPosition
	DEC SpriteVertScreenPosition
	LDA SpriteHorizScreenPosition
	;These positions define when the heli is close enough to make it bigger on the screen
	CMP #$90
	BEQ +
	CMP #$9E
	BEQ +
	CMP #$A8
	BEQ +
	CMP #$B2
	BEQ +
	CMP #$B6
	BCC - ;RTS
	;heli movement complete
	LDA #$C2
	STA $0660
	LDA #$F0
	JMP subIncrementSubGameState_SetScreenTimeLB
+:	LDA SpriteTypeIndex
	AND #$FE
	CLC
	ADC #$02 ;every sprite type is accompanied by a blade rotation version (2 sprites)
	STA SpriteTypeIndex ;get the next larger heli version
	RTS

EndOfGameState7: ;Initialize credits
	LDX #$02 ;Get Credits Header Address
	JSR fctGetEndOfGameTextHeaderAddress
	LDX #$00
	LDA tblEndingCreditsText,X
	STA $56
	INX
	LDA tblEndingCreditsText,X
	STA $58
	INX
	STX $5A
	LDA #$F0
	STA $54
	LDA #GameCompleteMusic
	JSR subInitiateSoundClip
	JMP subIncrementSubGameState

EndOfGameState8: ;Write text to the screen
	DEC $54
	BNE - ;RTS
	LDA #$05
	STA $54
	LDX $21
	LDA #$01
	STA $0770,X ;insert PPU update info
	INX
	LDA $56
	STA $0770,X
	INX
	LDA $58
	INC $58
	STA $0770,X
	LDA $58
	AND #$1F
	BNE +
	LDA $56
	CLC
	ADC #$04
	STA $56
	LDA $58
	SEC
	SBC #$20
	STA $58
+:	INX
	LDY $5A
	INC $5A
	BNE +
	INC $52
+:	LDA $50
	STA $00
	LDA $52
	STA $01
	LDA ($00),Y
	CMP #$FD ;Check for end of text write (final end) byte
	BCS ++
	STA $0770,X ;Queue the tile index for sending to the PPU to update the screen 
	CMP #$2A
	BEQ +
	CMP #$2D
	BEQ +
	LDA ControlSubState
	CMP #$02
	BNE +
	LDA #Level6BossDefeated_MissionAccomplishedTextSoundClip
	JSR subInitiateSoundClip
+:	INX
	LDA #$FF
	STA $0770,X
	INX
	LDA #$00
	STA $0770,X
	STX $21
	RTS
++:	CMP #$FF
	BEQ ++
	CMP #$FE
	BEQ +
	INC ControlSubState
	LDA #$A0
-:	STA $54
	LDY $5A
	LDA ($00),Y
	STA $56
	INY
	LDA ($00),Y
	STA $58
	INY
	STY $5A
	RTS
+:	LDA #$28
	BNE -
++:	LDA #$FF
	STA ScreenTimerLB
	;credits are all complete
	LDA #$0A
	STA ControlSubState
-:	RTS

EndOfGameState9: ;Let player read text.  delay before next credits
	DEC $54
	BNE -
	LDA #$10
	STA $54
	LDA #$35 ;Erase line 1 of credits text
	JSR Label152
	LDA #$36 ;Erase line 2 of credits text
	JSR Label152
	LDA #$08
	STA ControlSubState ;go write the next credits
	RTS

EndOfGameState10:
	LDA ScreenTimerLB
	CMP #$C0
	BNE +
	LDA #$35 ;Erase line 1 of credits text
	JSR Label152
	LDA #$36 ;Erase line 2 of credits text
	JSR Label152
+:	JSR fctCountDownScreenTimer
	BNE -
	LDA JeepControlsInput
	AND #StartButton ;Check for player 1 pressing start to play through again
	BEQ -
	;Playser 1 pressed start
	JSR subStopMusic
	LDA #MainWeaponExplosionOnEnemy
	JSR subInitiateSoundClip
	LDA #$0B
	STA ControlSubState
	LDA #$54 ;set time delay before restarting game
	STA $50
-:	RTS

EndOfGameState11: ;Delay before restarting game at level 1
	DEC $50
	BNE -
	JSR subEraseInGameJeepData
	LDA #$83 ;set to (-3).  This means you have no more continues, you beat the game, and everything is on HARD mode.
	STA ContinuesUsed
	JMP subTransitionFromEndOfGameToLevel1


fctGetEndOfGameTextHeaderAddress:
	LDA tblEndOfGameText,X
	STA $50
	LDA (tblEndOfGameText + 1),X
	STA $52
	RTS

subEndOfGameSunShimmer:
	LDA RNG_INCEveryFrame
	LSR
	BCC +
	INC Sprite1TypeIndex
	LDA Sprite1TypeIndex
	CMP #$C8
	BCC +
	LDA #$C4
	STA Sprite1TypeIndex
+:	RTS

subEndOfGame_FinalBossTank_CheckForScroll_FlashComplete:
	LDA $066F
	BEQ ++
	LDA RNG_INCEveryFrame
	AND #$01 ;count down every other frame
	BEQ +
	DEC $066F ;timer for this section
+:	LDA #$01
	RTS ;unnecessary RTS
++:	RTS ;A = $00, timing complete
	
	
;*******************
;Ending Credits Text
;*******************

tblEndOfGameText:
	dw tblLevel6BossBeatCongratsMessage
	dw tblEndingCreditsText
	
tblLevel6BossBeatCongratsMessage:
	;PPU BG Pattern table is updated, so the indices don't match the usual letters
	db $22,$BA ;PPU Address
	;  W   E   L   L   GRAPHIC  D   O   N   E   !
	db $C5,$C6,$C7,$C7,$2A,     $C8,$C9,$CA,$C6,$D6
	db $FE ;End of line marker
	
	db $22,$FA;PPU Address
	;  Y   O   U   R   GRAPHIC  M   I   S   S   I   O   N
	db $CB,$C9,$CC,$CD,$2D,     $CE,$CF,$D0,$D0,$CF,$C9,$CA
	db $FE ;End of line marker
	
	db $23,$3A ;PPU Address
	;  A   C   C   O   M   P   L   I   S   H   E   D   .
	db $D1,$D2,$D2,$C9,$CE,$D3,$C7,$CF,$D0,$D4,$C6,$C8,$D5
	db $FF ;End of section marker

tblEndingCreditsText:	
	db $20,$A4 ;PPU Address
	;  P   R   O   G   R   A   M   M   E   D   ''  B   Y
	db $20,$22,$1F,$17,$22,$11,$1D,$1D,$15,$14,$2C,$12,$29
	db $FE
	
	db $20,$EB ;PPU Address
	;  H   O   R   I
	db $18,$1F,$22,$19
	db $FD ;End of credit
	
	db $20,$A4 ;PPU Address
	;  C   H   A   R   A   C   T   E   R   ''  D   E   S   I   G   N
	db $13,$18,$11,$22,$11,$13,$24,$15,$22,$2C,$14,$15,$23,$19,$17,$1E
	db $FE
	
	db $20,$E8 ;PPU Address
	;  F   U   J   I   W   A   R   A
	db $16,$25,$1A,$19,$27,$11,$22,$11
	db $FD ;End of credit
	
	db $20,$A4 ;PPU Address
	;  C   H   A   R   A   C   T   E   R   ''  D   E   S   I   G   N
	db $13,$18,$11,$22,$11,$13,$24,$15,$22,$2C,$14,$15,$23,$19,$17,$1E
	db $FE ;End of line 
	
	db $20,$E8 ;PPU Address
	;  Y   O   S   H   I   M   O   T   O
	db $29,$1F,$23,$18,$19,$1D,$1F,$24,$1F
	db $FD ;End of credit
	
	db $20,$A4 ;PPU Address
	;  P   R   O   G   R   A   M   M   E   D   ''  B   Y
	db $20,$22,$1F,$17,$22,$11,$1D,$1D,$15,$14,$2C,$12,$29
	db $FE ;End of line
	
	db $20,$EA ;PPU Address
	;  Y   A   N   A   G   I   S   A   W   A
	db $29,$11,$1E,$11,$17,$19,$23,$11,$27,$11
	db $FD ;End of creit
	
	db $20,$A4 ;PPU Address
	;  C   H   A   R   A   C   T   E   R   ''  D   E   S   I   G   N
	db $13,$18,$11,$22,$11,$13,$24,$15,$22,$2C,$14,$15,$23,$19,$17,$1E
	db $FE ;End of line
	
	db $20,$E8 ;PPU Address
	;  M   A   R   U   O
	db $1D,$11,$22,$25,$1F
	db $FD ;End of credit
	
	db $20,$A4 ;PPU Address
	;  M   U   S   I   C   ''  B   Y
	db $1D,$25,$23,$19,$13,$2C,$12,$29
	db $FE ;End of line
	
	db $20,$E8 ;PPU Address
	;  S   A   K   A   M   O   T   O
	db $23,$11,$1B,$11,$1D,$1F,$24,$1F
	db $FD ;End of credit
	
	db $20,$A4 ;PPU Address
	;  M   U   S   I   C   ''  B   Y
	db $1D,$25,$23,$19,$13,$2C,$12,$29
	db $FE
	
	db $20,$E8 ;PPU Address
	;  F   U   J   I   O
	db $16,$25,$1A,$19,$1F
	db $FD ;End of credit
	
	db $20,$A4 ;PPU Address
	;  V   I   S   U   A   L   ''  D   E   S   I   G   N
	db $26,$19,$23,$25,$11,$1C,$2C,$14,$15,$23,$19,$17,$1E
	db $FE ;End of line
	
	db $20,$E8 ;PPU Address
	;  S   H   I   M   O   I   D   E
	db $23,$18,$19,$1D,$1F,$19,$14,$15
	db $FD ;End of credit
	
	db $20,$A4 ;PPU Address
	;  V   I   S   U   A   L   ''  D   E   S   I   G   N
	db $26,$19,$23,$25,$11,$1C,$2C,$14,$15,$23,$19,$17,$1E
	db $FE ;End of line
	
	db $20,$E9 ;PPU Address
	;  S   A   T   O   H
	db $23,$11,$24,$1F,$18
	db $FD ;End of credit
	
	db $20,$C2 ;PPU Address
	;  P   U   S   H   ''  S   T   A   R   T   ''  K   E   Y
	db $20,$25,$23,$18,$2C,$23,$24,$11,$22,$24,$2C,$1B,$15,$29
	db $FF ;end	
	

	.PAD $B480
	;FREE SPACE TO THE END OF THE BANK
		
	
	.PAD $C000
