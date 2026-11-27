SOURCE = source
BUILD = build/html
DOCTREES = build/doctrees
DIST = build/dist
DEPLOY_HOST ?=
DEPLOY_PATH ?= /var/www/godot-zero
PORT ?= 8000
export GODOT_BIN
GODOT ?= $(or $(GODOT_BIN),/Applications/Godot.app/Contents/MacOS/Godot)
EXAMPLES = projects/examples
DEMOS = $(SOURCE)/_static/godot
GODOT_VERSION = $(shell "$(GODOT)" --version 2>/dev/null | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?\.[a-z0-9]+).*/\1/')
GODOT_RELEASE = $(subst .stable,-stable,$(GODOT_VERSION))
ifeq ($(shell uname),Darwin)
TEMPLATES_DIR = $(HOME)/Library/Application Support/Godot/export_templates/$(GODOT_VERSION)
else
TEMPLATES_DIR = $(HOME)/.local/share/godot/export_templates/$(GODOT_VERSION)
endif
GD_FILES = $(shell find projects -name '*.gd' -not -path '*/.godot/*')
PY_PATHS = source/_ext source/conf.py tests deploy
GAME_PROJECTS = $(patsubst %/project.godot,%,$(wildcard projects/maze/*/project.godot projects/defense/*/project.godot projects/showcase/project.godot))
DEMO_SOURCES = $(shell find $(EXAMPLES) -type f -not -path '*/.godot/*' -not -name '*.out')
TEMPLATES_URL = https://github.com/godotengine/godot-builds/releases/download/$(GODOT_RELEASE)/Godot_v$(GODOT_RELEASE)_export_templates.tpz

.PHONY: html lint format linkcheck test run demos packs templates dist deploy

html:
	uv run sphinx-build -b html -d $(DOCTREES) $(SOURCE) $(BUILD)

lint:
	uv run sphinx-lint $(SOURCE)
	uv run ruff check $(PY_PATHS)
	uv run ruff format --check $(PY_PATHS)
	uv run gdlint $(GD_FILES)
	uv run gdformat --check --line-length 120 $(GD_FILES)

format:
	uv run ruff check --fix $(PY_PATHS)
	uv run ruff format $(PY_PATHS)
	uv run gdformat --line-length 120 $(GD_FILES)

linkcheck:
	uv run sphinx-build -b linkcheck -q $(SOURCE) build/linkcheck

test: lint demos
	uv run pytest

dist: demos
	rm -rf $(DIST)
	uv run sphinx-build -b html -E -W --keep-going -d $(DOCTREES) $(SOURCE) $(DIST)

deploy: dist
	@test -n "$(DEPLOY_HOST)" || { echo "Set DEPLOY_HOST, for example: make deploy DEPLOY_HOST=user@server"; exit 1; }
	uv run python deploy/compress.py $(DIST)
	rsync -az --delete --exclude .buildinfo $(DIST)/ $(DEPLOY_HOST):$(DEPLOY_PATH)/

run: demos
	@uv run sphinx-autobuild $(SOURCE) $(BUILD) -d $(DOCTREES) --port $(PORT) -q

demos: $(DEMOS)/index.html packs

packs: $(DEMOS)/index.html
	@for project in $(GAME_PROJECTS); do \
		pack="$(DEMOS)/$$(echo "$$project" | sed 's|^projects/||' | tr / -).pck"; \
		if [ ! -f "$$pack" ] || [ -n "$$(find "$$project" -type f -newer "$$pack" -not -path '*/.godot/*' | head -1)" ]; then \
			echo "Exporting $$project"; \
			"$(GODOT)" --headless --path "$$project" --import && \
			{ [ -f "$$project/.godot/global_script_class_cache.cfg" ] || "$(GODOT)" --headless --path "$$project" --import; } && \
			"$(GODOT)" --headless --path "$$project" --export-pack "Web" "$(CURDIR)/$$pack" || exit 1; \
		fi; \
	done

$(DEMOS)/index.html: $(DEMO_SOURCES) Makefile | templates
	mkdir -p $(DEMOS)
	"$(GODOT)" --headless --path $(EXAMPLES) --import
	"$(GODOT)" --headless --path $(EXAMPLES) --export-release "Web" $(CURDIR)/$(DEMOS)/index.html
	perl -0pi -e 's/const engine = new Engine\(GODOT_CONFIG\);/GODOT_CONFIG.mainPack = new URLSearchParams(window.location.search).get("pack") || "index.pck";\nconst engine = new Engine(GODOT_CONFIG);/' $(DEMOS)/index.html


templates:
	@if [ -f "$(TEMPLATES_DIR)/web_nothreads_release.zip" ]; then \
		echo "Export templates $(GODOT_VERSION) are already installed"; \
	else \
		mkdir -p "$(TEMPLATES_DIR)" && \
		curl -fL -o /tmp/godot_templates.tpz "$(TEMPLATES_URL)" && \
		unzip -j -o /tmp/godot_templates.tpz "templates/version.txt" "templates/web_nothreads_*" -d "$(TEMPLATES_DIR)" && \
		rm /tmp/godot_templates.tpz; \
	fi
