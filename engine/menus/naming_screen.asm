AskName:
	call SaveScreenTilesToBuffer1
	call GetPredefRegisters
	push hl
	ld a, [wIsInBattle]
	dec a
	hlcoord 0, 0
	ld b, 4
	ld c, 11
	call z, ClearScreenArea ; only if in wild battle
	ld a, [wCurPartySpecies]
	ld [wNamedObjectIndex], a
	call GetMonName
	ld hl, DoYouWantToNicknameText
	call PrintText
	hlcoord 14, 7
	lb bc, 8, 15
	ld a, TWO_OPTION_MENU
	ld [wTextBoxID], a
	call DisplayTextBoxID
	pop hl
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .declinedNickname
	ld a, [wUpdateSpritesEnabled]
	push af
	xor a
	ld [wUpdateSpritesEnabled], a
	push hl
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	ld a, [wIsInBattle]
	and a
	jr nz, .inBattle
	call ReloadMapSpriteTilePatterns
.inBattle
	call LoadScreenTilesFromBuffer1
	pop hl
	pop af
	ld [wUpdateSpritesEnabled], a
	ld a, [wStringBuffer]
	cp '@'
	ret nz
.declinedNickname
	ld d, h
	ld e, l
	ld hl, wNameBuffer
	ld bc, NAME_LENGTH
	jp CopyData

DoYouWantToNicknameText:
	text_far _DoYouWantToNicknameText
	text_end

DisplayNameRaterScreen::
	ld hl, wBuffer
	xor a
	ld [wUpdateSpritesEnabled], a
	ld a, NAME_MON_SCREEN
	ld [wNamingScreenType], a
	call DisplayNamingScreen
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	ld a, [wStringBuffer]
	cp '@'
	jr z, .playerCancelled
	ld hl, wPartyMonNicks
	ld bc, NAME_LENGTH
	ld a, [wWhichPokemon]
	call AddNTimes
	ld e, l
	ld d, h
	ld hl, wBuffer
	ld bc, NAME_LENGTH
	call CopyData
	and a
	ret
.playerCancelled
	scf
	ret

DisplayNamingScreen:
	push hl
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites
	ld b, SET_PAL_GENERIC
	call RunPaletteCommand
	call LoadHpBarAndStatusTilePatterns
	call LoadEDTile
	farcall LoadMonPartySpriteGfx
	hlcoord 0, 5
	ld b, 9
	ld c, 18
	call TextBoxBorder
	call PrintNamingText
	ld a, 4
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	ld [wLastMenuItem], a
	ld [wCurrentMenuItem], a
	ld a, $ff
	ld [wMenuWatchedKeys], a
	ld a, 7
	ld [wMaxMenuItem], a
	ld a, '@'
	ld [wStringBuffer], a
	xor a
	ld hl, wNamingScreenSubmitName
	ld [hli], a
	ld [hli], a
	ld [wAnimCounter], a
.selectReturnPoint
	call PrintAlphabet
	call GBPalNormal
.ABStartReturnPoint
	ld a, [wNamingScreenSubmitName]
	and a
	jr nz, .submitNickname
	call PrintNicknameAndUnderscores
.dPadReturnPoint
	call PlaceMenuCursor
.inputLoop
	ld a, [wCurrentMenuItem]
	push af
	farcall AnimatePartyMon_ForceSpeed1
	pop af
	ld [wCurrentMenuItem], a
	call JoypadLowSensitivity
	ldh a, [hJoyPressed]
	and a
	jr z, .inputLoop
	ld hl, .namingScreenButtonFunctions
.checkForPressedButton
	sla a
	jr c, .foundPressedButton
	inc hl
	inc hl
	inc hl
	inc hl
	jr .checkForPressedButton
.foundPressedButton
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push de
	jp hl

.submitNickname
	pop de
	ld hl, wStringBuffer
	ld bc, NAME_LENGTH
	call CopyData
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call ClearSprites
	call RunDefaultPaletteCommand
	call GBPalNormal
	xor a
	ld [wAnimCounter], a
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	ld a, [wIsInBattle]
	and a
	jp z, LoadTextBoxTilePatterns
	jpfar LoadHudTilePatterns

.namingScreenButtonFunctions
	dw .dPadReturnPoint
	dw .pressedDown
	dw .dPadReturnPoint
	dw .pressedUp
	dw .dPadReturnPoint
	dw .pressedLeft
	dw .dPadReturnPoint
	dw .pressedRight
	dw .ABStartReturnPoint
	dw .pressedStart
	dw .selectReturnPoint
	dw .pressedSelect
	dw .ABStartReturnPoint
	dw .pressedB
	dw .ABStartReturnPoint
	dw .pressedA

.pressedA_changedPage
	pop de
	ld de, .selectReturnPoint
	push de
.pressedSelect
	ld a, [wNamingScreenPage]
	inc a
	cp 3
	jr c, .storePage
	xor a
.storePage
	ld [wNamingScreenPage], a
	ret

.pressedStart
	call CalcStringLength
	ld a, b
	and a
	jr z, .submitName
	dec hl
	ld a, [hl]
	cp '^'
	jr c, .submitName
	cp '¨' + 1
	ret c ; don't submit an incomplete diacritic sequence
.submitName
	ld a, 1
	ld [wNamingScreenSubmitName], a
	ret

.pressedA
	ld a, [wCurrentMenuItem]
	cp $5 ; "ED" row
	jr nz, .didNotPressED
	ld a, [wTopMenuItemX]
	cp $11 ; "ED" column
	jr z, .pressedStart
.didNotPressED
	ld a, [wCurrentMenuItem]
	cp $6 ; page switch row
	jr nz, .didNotPressCaseSwitch
	ld a, [wTopMenuItemX]
	cp $1 ; page switch column
	jr z, .pressedA_changedPage
.didNotPressCaseSwitch
	ld hl, wMenuCursorLocation
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	ld [wNamingScreenLetter], a
	call CalcStringLength
	ld a, [wNamingScreenLetter]
	cp '^'
	jr c, .notDiacritic
	cp '¨' + 1
	jr nc, .notDiacritic
	; A second dead key replaces the first one instead of consuming space.
	ld a, b
	and a
	jr z, .checkDiacriticLength
	dec hl
	ld a, [hl]
	cp '^'
	jr c, .restoreHLAndCheckDiacriticLength
	cp '¨' + 1
	jr nc, .restoreHLAndCheckDiacriticLength
	ld a, [wNamingScreenLetter]
	ld [hl], a
	jr .playedSound
.restoreHLAndCheckDiacriticLength
	inc hl
.checkDiacriticLength
	; A dead key must leave room for its base letter and the terminator.
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	ld a, b
	jr nc, .checkMonDiacriticLength
	cp PLAYER_NAME_LENGTH - 2
	jr .checkNameLength
.checkMonDiacriticLength
	cp NAME_LENGTH - 2
	jr .checkNameLength
.notDiacritic
	; If a dead key is pending, only accept one of its supported letters.
	ld a, b
	and a
	jr z, .checkRegularLength
	dec hl
	ld a, [hl]
	inc hl
	cp '^'
	jr c, .checkRegularLength
	cp '¨' + 1
	jr nc, .checkRegularLength
	push hl
	push bc
	call CanApplyNamingScreenDiacritic
	pop bc
	pop hl
	ret nc
.checkRegularLength
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	ld a, b
	jr nc, .checkMonNameLength
	cp PLAYER_NAME_LENGTH - 1
	jr .checkNameLength
.checkMonNameLength
	cp NAME_LENGTH - 1
.checkNameLength
	jr c, .addLetter
	ret
.addLetter
	ld a, [wNamingScreenLetter]
	ld [hli], a
	ld [hl], '@'
.playedSound
	ld a, SFX_PRESS_AB
	call PlaySound
	ret
.pressedB
	call CalcStringLength
	ld a, b
	and a
	ret z
	dec hl
	ld [hl], '@'
	; Delete a complete accented character (dead key + base) in one press.
	ld a, b
	cp 2
	ret c
	dec hl
	ld a, [hl]
	cp '^'
	jr c, .keepPreviousCharacter
	cp '¨' + 1
	jr nc, .keepPreviousCharacter
	ld [hl], '@'
	ret
.keepPreviousCharacter
	inc hl
	ret
.pressedRight
	ld a, [wCurrentMenuItem]
	cp $6
	ret z ; can't scroll right on bottom row
	ld a, [wTopMenuItemX]
	cp $11 ; max
	jp z, .wrapToFirstColumn
	inc a
	inc a
	jr .done
.wrapToFirstColumn
	ld a, $1
	jr .done
.pressedLeft
	ld a, [wCurrentMenuItem]
	cp $6
	ret z ; can't scroll right on bottom row
	ld a, [wTopMenuItemX]
	dec a
	jp z, .wrapToLastColumn
	dec a
	jr .done
.wrapToLastColumn
	ld a, $11 ; max
	jr .done
.pressedUp
	ld a, [wCurrentMenuItem]
	dec a
	ld [wCurrentMenuItem], a
	and a
	ret nz
	ld a, $6 ; wrap to bottom row
	ld [wCurrentMenuItem], a
	ld a, $1 ; force left column
	jr .done
.pressedDown
	ld a, [wCurrentMenuItem]
	inc a
	ld [wCurrentMenuItem], a
	cp $7
	jr nz, .wrapToTopRow
	ld a, $1
	ld [wCurrentMenuItem], a
	jr .done
.wrapToTopRow
	cp $6
	ret nz
	ld a, $1
.done
	ld [wTopMenuItemX], a
	jp EraseMenuCursor

LoadEDTile:
	ld de, ED_Tile
	ld hl, vFont tile $70
	lb bc, BANK(ED_Tile), (ED_TileEnd - ED_Tile) / TILE_1BPP_SIZE
	jp CopyVideoDataDouble

ED_Tile:
	INCBIN "gfx/font/ED.1bpp"
ED_TileEnd:

PrintAlphabet:
	xor a
	ldh [hAutoBGTransferEnabled], a
	ld a, [wNamingScreenPage]
	and a
	ld de, UpperCaseAlphabet
	jr z, .gotAlphabet
	dec a
	ld de, LowerCaseAlphabet
	jr z, .gotAlphabet
	ld de, SymbolAlphabet
.gotAlphabet
	hlcoord 2, 6
	lb bc, 5, 9 ; 5 rows, 9 columns
.outerLoop
	push bc
.innerLoop
	ld a, [de]
	ld [hli], a
	inc hl
	inc de
	dec c
	jr nz, .innerLoop
	ld bc, SCREEN_WIDTH + 2
	add hl, bc
	pop bc
	dec b
	jr nz, .outerLoop
	call PlaceString
	ld a, $1
	ldh [hAutoBGTransferEnabled], a
	jp Delay3

INCLUDE "data/text/alphabets.asm"

PrintNicknameAndUnderscores:
	call CalcStringLength
	ld a, b
	ld [wNamingScreenByteLength], a
	ld a, c
	ld [wNamingScreenNameLength], a
	hlcoord 10, 2
	lb bc, 2, 10
	call ClearScreenArea
	hlcoord 10, 3
	ld de, wStringBuffer
	call PlaceString
	hlcoord 10, 4
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	jr nc, .pokemon
; player or rival
	ld b, PLAYER_NAME_LENGTH - 1
	jr .gotUnderscoreCount
.pokemon
	ld b, NAME_LENGTH - 1
.gotUnderscoreCount
	ld a, $76 ; underscore tile id
.placeUnderscoreLoop
	ld [hli], a
	dec b
	jr nz, .placeUnderscoreLoop
	ld a, [wNamingScreenType]
	cp NAME_MON_SCREEN
	ld a, [wNamingScreenByteLength]
	jr nc, .pokemon2
; player or rival
	cp PLAYER_NAME_LENGTH - 1
	jr z, .nameIsFull
	ld a, [wNamingScreenNameLength]
	cp PLAYER_NAME_LENGTH - 1
	jr .checkEmptySpaces
.pokemon2
	cp NAME_LENGTH - 1
	jr z, .nameIsFull
	ld a, [wNamingScreenNameLength]
	cp NAME_LENGTH - 1
.checkEmptySpaces
	jr nz, .placeRaisedUnderscore ; jump if empty spaces remain
.nameIsFull
	; when all spaces are filled, force the cursor onto the ED tile,
	; and keep the last underscore raised
	call EraseMenuCursor
	ld a, $11 ; "ED" x coord
	ld [wTopMenuItemX], a
	ld a, $5 ; "ED" y coord
	ld [wCurrentMenuItem], a
	ld a, [wNamingScreenNameLength]
	dec a
.placeRaisedUnderscore
	ld c, a
	ld b, $0
	hlcoord 10, 4
	add hl, bc
	ld [hl], $77 ; raised underscore tile id
	ret

; Input: a = pending diacritic. Return carry if the selected letter supports it.
CanApplyNamingScreenDiacritic:
	cp '~'
	ld hl, NamingScreenVowels
	jr nz, .search
	ld hl, NamingScreenTildeLetters
.search
	ld a, [wNamingScreenLetter]
	ld de, 1
	jp IsInArray

NamingScreenVowels:
	db "AEIOUaeiou", -1

NamingScreenTildeLetters:
	db "Nn", -1

; Calculate the byte length in b and the displayed character length in c.
; Diacritics are stored as dead-key bytes and do not advance the text cursor.
CalcStringLength:
	ld hl, wStringBuffer
	ld b, $0
	ld c, $0
.loop
	ld a, [hl]
	cp '@'
	ret z
	inc hl
	inc b
	cp '^'
	jr c, .countCharacter
	cp '¨' + 1
	jr c, .loop
.countCharacter
	inc c
	jr .loop

PrintNamingText:
	hlcoord 0, 1
	ld a, [wNamingScreenType]
	ld de, YourTextString
	and a
	jr z, .notNickname
	ld de, RivalsTextString
	dec a
	jr z, .notNickname
	ld a, [wCurPartySpecies]
	ld [wMonPartySpriteSpecies], a
	push af
	farcall WriteMonPartySpriteOAMBySpecies
	pop af
	ld [wNamedObjectIndex], a
	call GetMonName
	hlcoord 4, 1
	call PlaceString
	ld hl, $1
	add hl, bc
	ld [hl], 'の' ; leftover from Japanese version; blank tile $c9 in English
	hlcoord 1, 3
	ld de, NicknameTextString
	jr .placeString
.notNickname
	call PlaceString
	ld l, c
	ld h, b
	ld de, NameTextString
.placeString
	jp PlaceString

YourTextString:
	db "YOUR @"

RivalsTextString:
	db "RIVAL's @"

NameTextString:
	db "NAME?@"

NicknameTextString:
	db "NICKNAME?@"
