MaxLifeCount = $09
NumberOfLevels = $06		;The expanded ROM has 10 levels now
NormalPPUMaskValue = $1E ;Emphasis on color:red=OFF,green=OFF,blue=OFF, ShowSprites=ON, ShowBackground=ON, ShowSpritesOnLeftMost8Pixels=ON, ShowBackgroundOnLeftMost8Pixels=ON, Grayscale=OFF
NormalPPUCTRLValue = $A8 ;NMI=ON, PPU=Master, SpriteSize=8x16, BGPatternTable=0:$0000, SpritePatternTable=1:$1000 (ignored in 8x16 mode though), VRAM Address=0:Add 1, BaseNametableAddress=0:$2000

;*************************
;Title Screen/POW Portrait
;*************************
POWPortraitScrollEnd = #$FD
POWPortraitInitialScrollSpeed = $16


;*****************
;Controller Values
;*****************
RightDPad = $01
LeftDPad = $02
DownDPad = $04
UpDPad = $08
StartButton = $10
SelectButton = $20
BButton = $40
AButton = $80


;*******
;HELIPAD
;*******
HelipadLightFlashRate = $20 ;# Frames