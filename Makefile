roms := \
	pokered.gbc \
	pokeblue.gbc \
	pokeblue_debug.gbc
languages := en de es fr it
patches := \
	pokered.patch \
	pokeblue.patch

rom_obj := \
	audio.o \
	home.o \
	main.o \
	maps.o \
	ram.o \
	text.o \
	gfx/pics.o \
	gfx/sprites.o \
	gfx/tilesets.o

common_rom_obj := $(filter-out main.o maps.o text.o,$(rom_obj))
vc_rom_obj := $(rom_obj)

pokered_obj        := $(common_rom_obj:.o=_red.o)
pokeblue_obj       := $(common_rom_obj:.o=_blue.o)
pokeblue_debug_obj := $(common_rom_obj:.o=_blue_debug.o)
pokered_vc_obj     := $(vc_rom_obj:.o=_red_vc.o)
pokeblue_vc_obj    := $(vc_rom_obj:.o=_blue_vc.o)

pokered_main_obj        := $(languages:%=main_red_%.o)
pokeblue_main_obj       := $(languages:%=main_blue_%.o)
pokeblue_debug_main_obj := $(languages:%=main_blue_debug_%.o)

pokered_maps_obj        := $(languages:%=maps_red_%.o)
pokeblue_maps_obj       := $(languages:%=maps_blue_%.o)
pokeblue_debug_maps_obj := $(languages:%=maps_blue_debug_%.o)

pokered_text_obj        := $(languages:%=text_red_%.o)
pokeblue_text_obj       := $(languages:%=text_blue_%.o)
pokeblue_debug_text_obj := $(languages:%=text_blue_debug_%.o)

pokered_locale_roms        := $(languages:%=pokered_%.gbc)
pokeblue_locale_roms       := $(languages:%=pokeblue_%.gbc)
pokeblue_debug_locale_roms := $(languages:%=pokeblue_debug_%.gbc)


### Build tools

ifeq (,$(shell command -v sha1sum 2>/dev/null))
SHA1 := shasum
else
SHA1 := sha1sum
endif

RGBDS ?=
RGBASM  ?= $(RGBDS)rgbasm
RGBFIX  ?= $(RGBDS)rgbfix
RGBGFX  ?= $(RGBDS)rgbgfx
RGBLINK ?= $(RGBDS)rgblink

RGBASMFLAGS  ?= -Weverything -Wtruncation=1
RGBLINKFLAGS ?= -Weverything -Wtruncation=1
RGBFIXFLAGS  ?= -Weverything
RGBGFXFLAGS  ?= -Weverything


### Build targets

.SUFFIXES:
.SECONDEXPANSION:
.PRECIOUS:
.SECONDARY:
.PHONY: \
	all \
	red \
	blue \
	blue_debug \
	red_vc \
	blue_vc \
	clean \
	tidy \
	compare \
	tools

all: $(roms)
red:        pokered.gbc
blue:       pokeblue.gbc
blue_debug: pokeblue_debug.gbc
red_vc:     pokered.patch
blue_vc:    pokeblue.patch

clean: tidy
	find gfx \
	     \( -iname '*.1bpp' \
	        -o -iname '*.2bpp' \
	        -o -iname '*.pic' \) \
	     -delete

tidy:
	$(RM) $(roms) \
	      $(roms:.gbc=.sym) \
	      $(roms:.gbc=.map) \
	      $(patches) \
	      $(patches:.patch=_vc.gbc) \
	      $(patches:.patch=_vc.sym) \
	      $(patches:.patch=_vc.map) \
	      $(patches:%.patch=vc/%.constants.sym) \
	      $(pokered_obj) \
	      $(pokeblue_obj) \
	      $(pokered_vc_obj) \
	      $(pokeblue_vc_obj) \
	      $(pokeblue_debug_obj) \
	      $(pokered_main_obj) \
	      $(pokeblue_main_obj) \
	      $(pokeblue_debug_main_obj) \
	      $(pokered_maps_obj) \
	      $(pokeblue_maps_obj) \
	      $(pokeblue_debug_maps_obj) \
	      $(pokered_text_obj) \
	      $(pokeblue_text_obj) \
	      $(pokeblue_debug_text_obj) \
	      $(pokered_locale_roms) \
	      $(pokered_locale_roms:.gbc=.sym) \
	      $(pokered_locale_roms:.gbc=.map) \
	      $(pokeblue_locale_roms) \
	      $(pokeblue_locale_roms:.gbc=.sym) \
	      $(pokeblue_locale_roms:.gbc=.map) \
	      $(pokeblue_debug_locale_roms) \
	      $(pokeblue_debug_locale_roms:.gbc=.sym) \
	      $(pokeblue_debug_locale_roms:.gbc=.map) \
	      rgbdscheck.o
	$(MAKE) clean -C tools/

compare: $(roms)
	@for rom in $(roms); do \
		$(RGBFIX) -v $$rom || exit; \
	done

tools:
	$(MAKE) -C tools/


RGBASMFLAGS += -Q8 -P includes.asm
# Create a sym/map for debug purposes if `make` run with `DEBUG=1`
ifeq ($(DEBUG),1)
RGBASMFLAGS += -E
endif

$(pokered_obj):        RGBASMFLAGS += -D _RED
$(pokeblue_obj):       RGBASMFLAGS += -D _BLUE
$(pokeblue_debug_obj): RGBASMFLAGS += -D _BLUE -D _DEBUG
$(pokered_vc_obj):     RGBASMFLAGS += -D _RED -D _RED_VC
$(pokeblue_vc_obj):    RGBASMFLAGS += -D _BLUE -D _BLUE_VC

%.patch: %_vc.gbc %.gbc vc/%.patch.template
	tools/make_patch $*_vc.sym $^ $@

rgbdscheck.o: rgbdscheck.asm
	$(RGBASM) -o $@ $<

# Build tools when building the rom.
# This has to happen before the rules are processed, since that's when scan_includes is run.
ifeq (,$(filter clean tidy tools,$(MAKECMDGOALS)))

$(info $(shell $(MAKE) -C tools))

# The dep rules have to be explicit or else missing files won't be reported.
# As a side effect, they're evaluated immediately instead of when the rule is invoked.
# It doesn't look like $(shell) can be deferred so there might not be a better way.
preinclude_deps := includes.asm $(shell tools/scan_includes includes.asm)
define DEP
$1: $2 $$(shell tools/scan_includes $2) $(preinclude_deps) | rgbdscheck.o
	$$(RGBASM) $$(RGBASMFLAGS) -o $$@ $$<
endef

# Dependencies for objects (drop _red and _blue from asm file basenames)
$(foreach obj, $(pokered_obj), $(eval $(call DEP,$(obj),$(obj:_red.o=.asm))))
$(foreach obj, $(pokeblue_obj), $(eval $(call DEP,$(obj),$(obj:_blue.o=.asm))))
$(foreach obj, $(pokeblue_debug_obj), $(eval $(call DEP,$(obj),$(obj:_blue_debug.o=.asm))))
$(foreach obj, $(pokered_vc_obj), $(eval $(call DEP,$(obj),$(obj:_red_vc.o=.asm))))
$(foreach obj, $(pokeblue_vc_obj), $(eval $(call DEP,$(obj),$(obj:_blue_vc.o=.asm))))

endif

main_scanned_deps := $(shell tools/scan_includes main.asm)
main_common_deps := $(foreach dep,$(main_scanned_deps),$(if $(findstring {LANGUAGE},$(dep)),,$(dep)))
locale_main_deps = \
	engine/battle/$(1)/core.asm \
	engine/link/$(1)/cable_club.asm \
	engine/menus/$(1)/main_menu.asm \
	engine/menus/$(1)/draw_start_menu.asm \
	engine/menus/$(1)/text_box.asm \
	engine/pokemon/$(1)/status_screen.asm \
	engine/menus/$(1)/start_sub_menus.asm \
	engine/events/hidden_events/$(1)/bills_house_pc.asm \
	engine/pokemon/$(1)/bills_pc.asm \
	engine/menus/$(1)/pokedex.asm \
	engine/events/$(1)/vending_machine.asm \
	data/$(1)/text_boxes.asm \
	data/$(1)/yes_no_menu_strings.asm \
	data/battle/$(1)/stat_names.asm \
	data/battle/$(1)/stat_mod_names.asm \
	data/events/$(1)/trades.asm \
	data/items/$(1)/names.asm \
	data/maps/$(1)/names.asm \
	data/moves/$(1)/field_move_names.asm \
	data/player/$(1)/names.asm \
	data/player/$(1)/names_list.asm \
	data/pokemon/$(1)/dex_entries.asm \
	data/pokemon/$(1)/names.asm \
	data/trainers/$(1)/names.asm \
	data/types/$(1)/names.asm

main_red_%.o: main.asm $(main_common_deps) $$(call locale_main_deps,$$*) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _RED -D LANGUAGE=$* -o $@ $<

main_blue_%.o: main.asm $(main_common_deps) $$(call locale_main_deps,$$*) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _BLUE -D LANGUAGE=$* -o $@ $<

main_blue_debug_%.o: main.asm $(main_common_deps) $$(call locale_main_deps,$$*) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _BLUE -D _DEBUG -D LANGUAGE=$* -o $@ $<

maps_scanned_deps := $(shell tools/scan_includes maps.asm)
maps_common_deps := $(foreach dep,$(maps_scanned_deps),$(if $(findstring {LANGUAGE},$(dep)),,$(dep)))
locale_maps_deps = scripts/$(1)/BikeShop.asm

maps_red_%.o: maps.asm $(maps_common_deps) $$(call locale_maps_deps,$$*) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _RED -D LANGUAGE=$* -o $@ $<

maps_blue_%.o: maps.asm $(maps_common_deps) $$(call locale_maps_deps,$$*) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _BLUE -D LANGUAGE=$* -o $@ $<

maps_blue_debug_%.o: maps.asm $(maps_common_deps) $$(call locale_maps_deps,$$*) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _BLUE -D _DEBUG -D LANGUAGE=$* -o $@ $<

locale_text_deps := $(shell find text data/text -type f -name '*.asm')

text_red_%.o: text.asm $(locale_text_deps) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _RED -D LANGUAGE=$* -o $@ $<

text_blue_%.o: text.asm $(locale_text_deps) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _BLUE -D LANGUAGE=$* -o $@ $<

text_blue_debug_%.o: text.asm $(locale_text_deps) $(preinclude_deps) | rgbdscheck.o
	$(RGBASM) $(RGBASMFLAGS) -D _BLUE -D _DEBUG -D LANGUAGE=$* -o $@ $<


RGBLINKFLAGS += -d
pokered_vc.gbc:     RGBLINKFLAGS += -p 0x00
pokeblue_vc.gbc:    RGBLINKFLAGS += -p 0x00

RGBFIXFLAGS += -jsv -n 0 -k 01 -l 0x33 -m MBC5+RAM+BATTERY -r 03
pokered_vc.gbc:     RGBFIXFLAGS += -p 0x00 -t "POKEMON RED"
pokeblue_vc.gbc:    RGBFIXFLAGS += -p 0x00 -t "POKEMON BLUE"

pokered_vc.gbc: $(pokered_vc_obj) layout.link
	$(RGBLINK) $(RGBLINKFLAGS) -l layout.link -m $(@:.gbc=.map) -n $(@:.gbc=.sym) -o $@ $(filter %.o,$^)
	$(RGBFIX) $(RGBFIXFLAGS) $@

pokeblue_vc.gbc: $(pokeblue_vc_obj) layout.link
	$(RGBLINK) $(RGBLINKFLAGS) -l layout.link -m $(@:.gbc=.map) -n $(@:.gbc=.sym) -o $@ $(filter %.o,$^)
	$(RGBFIX) $(RGBFIXFLAGS) $@

pokered_%.gbc: $(pokered_obj) main_red_%.o maps_red_%.o text_red_%.o layout.link
	$(RGBLINK) $(RGBLINKFLAGS) -p 0x00 -l layout.link -m $(@:.gbc=.map) -n $(@:.gbc=.sym) -o $@ $(filter %.o,$^)
	$(RGBFIX) $(RGBFIXFLAGS) -p 0x00 -t "POKEMON RED" $@

pokeblue_%.gbc: $(pokeblue_obj) main_blue_%.o maps_blue_%.o text_blue_%.o layout.link
	$(RGBLINK) $(RGBLINKFLAGS) -p 0x00 -l layout.link -m $(@:.gbc=.map) -n $(@:.gbc=.sym) -o $@ $(filter %.o,$^)
	$(RGBFIX) $(RGBFIXFLAGS) -p 0x00 -t "POKEMON BLUE" $@

pokeblue_debug_%.gbc: $(pokeblue_debug_obj) main_blue_debug_%.o maps_blue_debug_%.o text_blue_debug_%.o layout.link
	$(RGBLINK) $(RGBLINKFLAGS) -p 0xff -l layout.link -m $(@:.gbc=.map) -n $(@:.gbc=.sym) -o $@ $(filter %.o,$^)
	$(RGBFIX) $(RGBFIXFLAGS) -p 0xff -t "POKEMON BLUE" $@

pokered.gbc: $(pokered_locale_roms) tools/merge_locales.py
	python3 tools/merge_locales.py $@ $(filter %.gbc,$^)
	$(RGBFIX) $(RGBFIXFLAGS) -p 0x00 -t "POKEMON RED" $@

pokeblue.gbc: $(pokeblue_locale_roms) tools/merge_locales.py
	python3 tools/merge_locales.py $@ $(filter %.gbc,$^)
	$(RGBFIX) $(RGBFIXFLAGS) -p 0x00 -t "POKEMON BLUE" $@

pokeblue_debug.gbc: $(pokeblue_debug_locale_roms) tools/merge_locales.py
	python3 tools/merge_locales.py $@ $(filter %.gbc,$^)
	$(RGBFIX) $(RGBFIXFLAGS) -p 0xff -t "POKEMON BLUE" $@


### Misc file-specific graphics rules

gfx/battle/move_anim_0.2bpp: tools/gfx += --trim-whitespace
gfx/battle/move_anim_1.2bpp: tools/gfx += --trim-whitespace

gfx/intro/blue_jigglypuff_1.2bpp: RGBGFXFLAGS += --columns
gfx/intro/blue_jigglypuff_2.2bpp: RGBGFXFLAGS += --columns
gfx/intro/blue_jigglypuff_3.2bpp: RGBGFXFLAGS += --columns
gfx/intro/red_nidorino_1.2bpp: RGBGFXFLAGS += --columns
gfx/intro/red_nidorino_2.2bpp: RGBGFXFLAGS += --columns
gfx/intro/red_nidorino_3.2bpp: RGBGFXFLAGS += --columns
gfx/intro/gengar.2bpp: RGBGFXFLAGS += --columns
gfx/intro/gengar.2bpp: tools/gfx += --remove-duplicates --preserve=0x19,0x76

gfx/credits/the_end.2bpp: tools/gfx += --interleave --png=$<

gfx/slots/red_slots_1.2bpp: tools/gfx += --trim-whitespace
gfx/slots/blue_slots_1.2bpp: tools/gfx += --trim-whitespace

gfx/tilesets/%.2bpp: tools/gfx += --trim-whitespace
gfx/tilesets/reds_house.2bpp: tools/gfx += --preserve=0x48

gfx/trade/game_boy.2bpp: tools/gfx += --remove-duplicates


### Catch-all graphics rules

%.2bpp: %.png
	$(RGBGFX) --colors dmg $(RGBGFXFLAGS) -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -o $@ $@ || $$($(RM) $@ && false))

%.1bpp: %.png
	$(RGBGFX) --colors dmg $(RGBGFXFLAGS) --depth 1 -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) --depth 1 -o $@ $@ || $$($(RM) $@ && false))

%.pic: %.2bpp
	tools/pkmncompress $< $@


### File extensions that are never generated and should be manually created

%.asm: ;
%.inc: ;
%.png: ;
%.pal: ;
%.bin: ;
%.blk: ;
%.bst: ;
%.rle: ;
