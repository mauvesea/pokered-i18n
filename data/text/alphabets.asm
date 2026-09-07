LowerCaseAlphabet:
	db "abcdefghi"
	db "jklmnopqr"
	db "stuvwxyz "
	db "012345678"
	db "9´`^¨~ .<ED>"
LowerCaseAlphabetKeysEnd:
	db "symbols   @"
LowerCaseAlphabetEnd:

UpperCaseAlphabet:
	db "ABCDEFGHI"
	db "JKLMNOPQR"
	db "STUVWXYZ "
	db "012345678"
	db "9´`^¨~ .<ED>"
UpperCaseAlphabetKeysEnd:
	db "lower case@"
UpperCaseAlphabetEnd:

SymbolAlphabet:
	db "×():;[]<PK><MN>"
	db "-?!♂♀/<DOT>, "
	db "'&¿¡     "
	db "         "
	db "        <ED>"
SymbolAlphabetKeysEnd:
	db "UPPER CASE@"
SymbolAlphabetEnd:

	assert LowerCaseAlphabetKeysEnd - LowerCaseAlphabet == 5 * 9
	assert UpperCaseAlphabetKeysEnd - UpperCaseAlphabet == 5 * 9
	assert SymbolAlphabetKeysEnd - SymbolAlphabet == 5 * 9
	assert LowerCaseAlphabetEnd - LowerCaseAlphabetKeysEnd == UpperCaseAlphabetEnd - UpperCaseAlphabetKeysEnd
	assert UpperCaseAlphabetEnd - UpperCaseAlphabetKeysEnd == SymbolAlphabetEnd - SymbolAlphabetKeysEnd
