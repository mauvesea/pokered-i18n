# Pokémon Red and Blue International

This project extends the pret Pokémon Red/Blue disassembly with runtime support
for every official international language: English, German, Spanish, French,
and Italian.

`make` builds 8 MiB MBC5 versions of Red, Blue, and the Blue debug ROM. On boot,
the player chooses a language before the intro movie. Each language is assembled
independently and stored in its own 64-bank page:

- `0`: English (`text/en`, `data/text/en`)
- `1`: German (`text/de`, `data/text/de`)
- `2`: Spanish (`text/es`, `data/text/es`)
- `3`: French (`text/fr`, `data/text/fr`)
- `4`: Italian (`text/it`, `data/text/it`)

The language directories include map dialogue, shared messages, Pokédex entries,
move names, and localized data tables such as item, Pokémon, trainer, type, and
map names. Data tables keep their original category and add a language directory,
for example `data/items/en/names.asm`. The non-English directories initially
contain English copies and can be translated without changing symbol names. The
linker builds one normal ROM per language, and `tools/merge_locales.py` combines
them into the final MBC5 image.

Accented Unicode characters in source text are decomposed automatically. The
font's `^`, `~`, `` ` ``, `´`, and `¨` tiles are placed above the following base
glyph, using the restored Japanese dakuten-style text behavior.

An existing localized pokered disassembly can be imported by matching global
labels. For example, the German import can be refreshed with:

```console
python3 tools/import_locale_labels.py ../pokered-de de \
  --report reports/de_labels_not_found.txt --write
```

Blocks without an exact label match are left unchanged and listed in the report.

To set up the toolchain, see [**INSTALL.md**](INSTALL.md).


## See also

- [**Wiki**][wiki] (includes [tutorials][tutorials])
- [**Symbols**][symbols]
- [**Tools**][tools]

You can find us on [Discord (pret, #pokered)](https://discord.gg/d5dubZ3).

For other pret projects, see [pret.github.io](https://pret.github.io/).

[wiki]: https://github.com/pret/pokered/wiki
[tutorials]: https://github.com/pret/pokered/wiki/Tutorials
[symbols]: https://github.com/pret/pokered/tree/symbols
[tools]: https://github.com/pret/gb-asm-tools
[ci]: https://github.com/pret/pokered/actions
[ci-badge]: https://github.com/pret/pokered/actions/workflows/main.yml/badge.svg
