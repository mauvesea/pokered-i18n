TextScriptEndingText::
	text_end

TextScriptEnd::
	ld hl, TextScriptEndingText
	ret

ExclamationText::
	text_far LocalizedExclamationText
	text_end

GroundRoseText::
	text_far LocalizedGroundRoseText
	text_end

BoulderText::
	text_far LocalizedBoulderText
	text_end

MartSignText::
	text_far LocalizedMartSignText
	text_end

PokeCenterSignText::
	text_far LocalizedPokeCenterSignText
	text_end

PickUpItemText::
	text_asm
	predef PickUpItem
	jp TextScriptEnd
