; Runtime language IDs. The order is part of the ROM bank layout.
	const_def
	const LANG_ENGLISH
	const LANG_GERMAN
	const LANG_SPANISH
	const LANG_FRENCH
	const LANG_ITALIAN
DEF NUM_LANGUAGES EQU const_value

; Each language owns one 64-bank (1 MiB) page in the MBC5 ROM.
DEF LANGUAGE_BANK_SHIFT  EQU 6
DEF LANGUAGE_BANK_STRIDE EQU 1 << LANGUAGE_BANK_SHIFT
