SOURCE = source
BUILD = build/html
PORT ?= 8000
export GODOT_BIN
GODOT ?= $(or $(GODOT_BIN),/Applications/Godot.app/Contents/MacOS/Godot)
EXAMPLES = projects/examples
DEMOS = $(SOURCE)/_static/godot
GODOT_VERSION = $(shell "$(GODOT)" --version 2>/dev/null | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?\.[a-z0-9]+).*/\1/')
GODOT_RELEASE = $(subst .stable,-stable,$(GODOT_VERSION))
TEMPLATES_DIR = $(HOME)/Library/Application Support/Godot/export_templates/$(GODOT_VERSION)
DEMO_SOURCES = $(shell find $(EXAMPLES) -type f -not -path '*/.godot/*' -not -name '*.out')
TEMPLATES_URL = https://github.com/godotengine/godot-builds/releases/download/$(GODOT_RELEASE)/Godot_v$(GODOT_RELEASE)_export_templates.tpz

.PHONY: html lint linkcheck test run demos templates

html:
	uv run sphinx-build -b html $(SOURCE) $(BUILD)

lint:
	uv run sphinx-lint $(SOURCE)

linkcheck:
	uv run sphinx-build -b linkcheck -q $(SOURCE) build/linkcheck

test: lint demos
	uv run pytest

run: demos
	@uv run sphinx-autobuild $(SOURCE) $(BUILD) --port $(PORT) -q

demos: $(DEMOS)/index.html

$(DEMOS)/index.html: $(DEMO_SOURCES) | templates
	mkdir -p $(DEMOS)
	"$(GODOT)" --headless --path $(EXAMPLES) --import
	"$(GODOT)" --headless --path $(EXAMPLES) --export-release "Web" $(CURDIR)/$(DEMOS)/index.html


templates:
	@if [ -f "$(TEMPLATES_DIR)/web_nothreads_release.zip" ]; then \
		echo "Шаблоны экспорта $(GODOT_VERSION) уже установлены"; \
	else \
		mkdir -p "$(TEMPLATES_DIR)" && \
		curl -fL -o /tmp/godot_templates.tpz "$(TEMPLATES_URL)" && \
		unzip -j -o /tmp/godot_templates.tpz "templates/version.txt" "templates/web_nothreads_*" -d "$(TEMPLATES_DIR)" && \
		rm /tmp/godot_templates.tpz; \
	fi
