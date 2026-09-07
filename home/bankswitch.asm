SetROMBank::
; Select logical ROM bank a from the page owned by wLanguage.
; Preserve all registers and flags so `rst BankSwitchRST` is a drop-in
; replacement for writing a directly to the mapper register.
	push af
	push bc
	ld b, a
	ld a, [wLanguage]
	ld c, a
	and %11
	rrca
	rrca
	or b
	ld [rROMB0], a
	ld a, c
	srl a
	srl a
	ld [rROMB1], a
	pop bc
	pop af
	ret

BankswitchHome::
; switches to bank # in a
; Only use this when in the home bank!
	ld [wBankswitchHomeTemp], a
	ldh a, [hLoadedROMBank]
	ld [wBankswitchHomeSavedROMBank], a
	ld a, [wBankswitchHomeTemp]
	ldh [hLoadedROMBank], a
	rst BankSwitchRST
	ret

BankswitchBack::
; returns from BankswitchHome
	ld a, [wBankswitchHomeSavedROMBank]
	ldh [hLoadedROMBank], a
	rst BankSwitchRST
	ret

Bankswitch::
; self-contained bankswitch, use this when not in the home bank
; switches to the bank in b
	ldh a, [hLoadedROMBank]
	push af
	ld a, b
	ldh [hLoadedROMBank], a
	rst BankSwitchRST
	ld bc, .Return
	push bc
	jp hl
.Return
	pop bc
	ld a, b
	ldh [hLoadedROMBank], a
	rst BankSwitchRST
	ret
