; ROM0 cannot vary between language pages. These stable bank-1 trampolines are
; linked once per language so home-bank text references still reach the local
; text-bank addresses even when translated strings change size.

LocalizedTextIDErrorText::
	text_far _TextIDErrorText
	text_end
LocalizedContCharText::
	text_far _ContCharText
	text_end
LocalizedTrainerNameText::
	text_far _TrainerNameText
	text_end
LocalizedPokemartGreetingText::
	text_far _PokemartGreetingText
	text_end
LocalizedPokemonFaintedText::
	text_far _PokemonFaintedText
	text_end
LocalizedPlayerBlackedOutText::
	text_far _PlayerBlackedOutText
	text_end
LocalizedRepelWoreOffText::
	text_far _RepelWoreOffText
	text_end
LocalizedExclamationText::
	text_far _ExclamationText
	text_end
LocalizedGroundRoseText::
	text_far _GroundRoseText
	text_end
LocalizedBoulderText::
	text_far _BoulderText
	text_end
LocalizedMartSignText::
	text_far _MartSignText
	text_end
LocalizedPokeCenterSignText::
	text_far _PokeCenterSignText
	text_end
