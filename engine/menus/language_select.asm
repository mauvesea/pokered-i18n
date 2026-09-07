SelectLanguage::
; Let the player choose a language before the intro movie. wLanguage starts at
; zero because Init clears WRAM before calling this routine.
	call GBPalWhiteOut
	call ClearScreen
	call DisableLCD
	ld hl, vChars2
	ld bc, vBGMap0 - vChars2
	xor a
	call FillMemory
	call LoadFontTilePatterns
	call ClearBothBGMaps
	ld a, LCDC_DEFAULT
	ldh [rLCDC], a
	ld a, 1
	ldh [hAutoBGTransferEnabled], a
	call GBPalNormal
	hlcoord 2, 2
	ld de, .header
	call PlaceString
	hlcoord 4, 5
	ld de, .english
	call PlaceString
	hlcoord 4, 7
	ld de, .german
	call PlaceString
	hlcoord 4, 9
	ld de, .spanish
	call PlaceString
	hlcoord 4, 11
	ld de, .french
	call PlaceString
	hlcoord 4, 13
	ld de, .italian
	call PlaceString

	call .drawCursor
	call Delay3

.input
	call JoypadLowSensitivity
	ldh a, [hJoy5]
	bit B_PAD_A, a
	jr nz, .selected
	bit B_PAD_START, a
	jr nz, .selected
	bit B_PAD_DOWN, a
	jr nz, .down
	bit B_PAD_UP, a
	jr z, .input

	call .eraseCursor
	ld a, [wLanguage]
	and a
	jr nz, .decrement
	ld a, NUM_LANGUAGES
.decrement
	dec a
	jr .moved

.down
	call .eraseCursor
	ld a, [wLanguage]
	inc a
	cp NUM_LANGUAGES
	jr c, .moved
	xor a
.moved
	ld [wLanguage], a
	call .drawCursor
	ld a, SFX_PRESS_AB
	call PlaySound
	call Delay3
	jr .input

.selected
	ld a, SFX_TURN_ON_PC
	call PlaySound
	call GBPalWhiteOutWithDelay3
	jp ClearScreen

.eraseCursor
	ld c, ' '
	jr .updateCursor

.drawCursor
	ld c, '▶'
.updateCursor
	ld a, [wLanguage]
	ld hl, wTileMap + 5 * SCREEN_WIDTH + 2
	ld de, 2 * SCREEN_WIDTH
	and a
	jr z, .placeCursor
.cursorRow
	add hl, de
	dec a
	jr nz, .cursorRow
.placeCursor
	ld [hl], c
	ret

.header:  db "SELECT LANGUAGE@"
.english: db "ENGLISH@"
.german:  db "DEUTSCH@"
.spanish: db "ESPAÑOL@"
.french:  db "FRANCAIS@"
.italian: db "ITALIANO@"
