; ; ID:01 - 
; db $50 ;Sound Header (Channel)
; dw $8AEE
; ; ID:02 - 
; db $0C ;Sound Header (Channel)
; dw $8B39
; ; ID:03 - 
; db $0C ;Sound Header (Channel)
; dw $8F70
; ; ID:04 - 
; db $0C ;Sound Header (Channel)
; dw $8F82
; ; ID:05 - 
; db $0C ;Sound Header (Channel)
; dw $8F82
MusicPercussion_SymbolInstrumentSoundClip = $06
; ; ID:07 - 
; db $0C ;Sound Header (Channel)
; dw $8F8F
WaterSplashSoundClip = $08
BulletBeingFiredSoundClip = $09
BomberPlaneRoarSoundClip = $0A
LaserBlastSoundClip = $0B
HelicopterBladesWhirringSoundClip = $0C
HelicopterBladesWhirringSoundClip_2 = $0D ;played with 0C
HelicopterBladesWhirringSoundClip_3 = $0E ;played with 0C
HelicopterBladesWhirringSoundClip_4 = $0F ;played with 0C
BulletHitTinkSoundClip = $10
GrenadeThrow_BombSoundClip = $11
InfantrySquishSoundClip = $12
BazookaLaunchSoundClip = $13
BazookaLaunchSoundClip_2 = $14 ;played with 13
BlackAndWhiteMissile_Bomb_LaserBlastHitsGroundSoundClip = $15
BazookaHitGroundSoundClip = $16
MainWeaponExplosionOnEnemy = $17
MainWeaponExplosionOnEnemy_2 = $18 ;played with 17
Level6FinalBossTankFlameShotSoundClip = $19
Level6FinalBossTankFlameShotSoundClip_2 = $1A ;played with 19
POWBuildingOpeningSoundClip = $1B
POWBuildingOpeningSoundClip_2 = $1C ;played with 1B
POWPickedUpSoundClip = $1D
POWPickedUpSoundClip_2 = $1E ;played with 1D
POWEnteringHeliSoundClip = $1F
POWEnteringHeliSoundClip_2 = $20 ;played with 1F
WeaponUpgradeSoundClip = $21
WeaponUpgradeSoundClip_2 = $22 ; played with 21
WeepWeepBossMusic_F0SoundClip = $23
WeepWeepBossMusic_F0SoundClip_2 = $24 ;played with 23
JeepDeathSoundClip = $25
ExtraLifeSoundClip = $26
Level6FinalBossBuildingBlowingUpSoundClip = $27 ; final boss blow up
EndOfGameHelicopterSoundClip = $28
EndOfGameHelicopterSoundClip_2 = $29 ;played with 28
POWPortraitScrollIntoPlace_Shing_SoundClip = $2A
POWPortraitScrollIntoPlace_Shing_SoundClip_2 = $2B ;played with 2A
POWPortraitScrollIntoPlace_Shing_SoundClip_3 = $2C ;played with 2A
POWPortraitTextPrintSoundClip = $2D
Level6BossDefeated_MissionAccomplishedTextSoundClip = #$2E
Level6BossDefeated_MissionAccomplishedTextSoundClip_2 = $2F ;played with 2E
TitleScreenStory_POWPortraitsSoundClip = $30
TitleScreenStory_POWPortraitsSoundClip_2 = $31 ;played with 30
TitleScreenStory_POWPortraitsSoundClip_3 = $32 ;played with 30
TitleScreenStory_POWPortraitsSoundClip_4 = $33 ;played with 30
GameStartedIntroSoundClip = $34
GameStartedIntroSoundClip_2 = $35 ;played with 34
GameStartedIntroSoundClip_3 = $36 ;played with 34
GameStartedIntroSoundClip_4 = $37 ;played with 34

;These aren't explicitly used, instead an array (tblLevelBGMusicIndex) is used
Level1Music = $38
Level1Music_2 = $39 ;played with 38
Level1Music_3 = $3A ;played with 38
Level1Music_4 = $3B ;played with 38
Level2Music = $3C
Level2Music_2 = $3D ;played with 3C
Level2Music_3 = $3E ;played with 3C
Level2Music_4 = $3F ;played with 3C
Level3Music = $40
Level3Music_2 = $41 ;played with 40
Level3Music_3 = $42 ;played with 40
Level3Music_4 = $43 ;played with 40

;These are called after $23 plays
BossMusicSoundClip = $44
BossMusicSoundClip_2 = $45
BossMusicSoundClip_3 = $46
BossMusicSoundClip_4 = $47

Level6FinalBossMusic = $48
Level6FinalBossMusic_2 = $49
Level6FinalBossMusic_3 = $4A
Level6FinalBossMusic_4 = $4B
StageComplete_LevelSegue_SoundClip = $4C
StageComplete_LevelSegue_SoundClip_2 = $4D
StageComplete_LevelSegue_SoundClip_3 = $4E
StageComplete_LevelSegue_SoundClip_4 = $4F
GameOver_Continue_SoundClip = $50
GameOver_Continue_SoundClip_2 = $51
GameOver_Continue_SoundClip_3 = $52
GameOver_Continue_SoundClip_4 = $53
GameCompleteMusic = $54
GameCompleteMusic_2 = $55
GameCompleteMusic_3 = $56
GameCompleteMusic_4 = $57
PauseGameSoundClip = $58
EMPTYSoundClip = $59