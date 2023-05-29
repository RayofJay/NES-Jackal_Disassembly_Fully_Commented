MACRO PUSHALL
	PHP
	PHA 
	TXA
	PHA
	TYA
	PHA
ENDM

MACRO PULLALL
	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
ENDM


;Sound Channel
;= #$00 - Pulse Channel 1
;= #$04 - Pulse Channel 2
;= #$08 - Triangle Channel
;= #$10 - Noise Channel
;= #$14 - Pulse Channel 1 Override for game sounds
;= #$18 - Pulse Channel 2 Override for game sounds
;= #$1C - DMC

MACRO SoundDefinition ClipCount,SoundChannel,Address
	db ((ClipCount * 64) + (SoundChannel * 4))
	dw Address
ENDM
