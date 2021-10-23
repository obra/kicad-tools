# Project-specific config
# 

# Detect OS/setup https://stackoverflow.com/questions/714100/os-detecting-makefile/52062069#52062069
ifeq '$(findstring ;,$(PATH))' ';'
    detected_OS := Windows
else
    detected_OS := $(shell uname 2>/dev/null || echo Unknown)
    detected_OS := $(patsubst CYGWIN%,Cygwin,$(detected_OS))
    detected_OS := $(patsubst MSYS%,MSYS,$(detected_OS))
    detected_OS := $(patsubst MINGW%,MSYS,$(detected_OS))
endif

MAKEFILE_PATH := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
DOCKER_VISIBLE_PATH := $(abspath $(MAKEFILE_PATH)/..)


# We should be using realpath(1) here)
PROJECT_PATH := $(notdir $(patsubst %/,%,$(dir $(MAKEFILE_PATH))))
PROJECT_ABS_PATH := $(DOCKER_VISIBLE_PATH)/$(PROJECT_PATH)

BOARD_RELATIVE_PATH := $(PROJECT_PATH)/$(BOARD).kicad_pcb
SCHEMATIC_RELATIVE_PATH := $(PROJECT_PATH)/$(BOARD).sch

# Output configuration

BOARD_SNAPSHOT_LABEL := $(BOARD)-$(shell git describe --all)
OUTPUT_BASEDIR := out/$(BOARD_SNAPSHOT_LABEL)
OUTPUT_PATH := $(PROJECT_ABS_PATH)/$(OUTPUT_BASEDIR)

ifeq ($(detected_OS),Cygwin)
  DOCKER_VISIBLE_PATH := $(shell cygpath -w $(DOCKER_VISIBLE_PATH))
  OUTPUT_PATH := $(shell cygpath -w $(OUTPUT_PATH))
endif

export DOCKER_VOLUMES := --volume $(DOCKER_VISIBLE_PATH):/kicad-project: \
   		  --volume $(OUTPUT_PATH):/output: 

# Infrastructure config

TOOLS_HOME := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
DOCKER_RUN := $(TOOLS_HOME)/bin/kicad-docker-run



# screencast option to help debug
ifeq ($(DO_SCREENCAST), 1)
	SCREENCAST_OPT=--screencast_dir /output
else
	SCREENCAST_OPT=
endif


all: 
	@echo "This project does not have an 'all' target. You probably want 'fabrication-outputs'"

.PHONY: help
help:
	@echo ""
	@echo "General production files"
	@echo "------------------------"
	@echo "make fabrication-outputs    - generate bom, schematics, gerbers"
	@echo "make clean                  - remove all output artifacts"
	@echo ""
	@echo "Generate specific production artifacts"
	@echo "--------------------------------------"
	@echo "make gerbers"
	@echo "make schematic-svg          - schematic in SVG format"
	@echo "make schematic-pdf          - schematic in PDF format"
	@echo "make schematic              - both formats"
	@echo "make bom                    - generate bom.csv file"
	@echo "make interactive-bom        - browser viewable BOM"
	@echo ""
	@echo "JLCPCB production files"
	@echo "-----------------------"
	@echo "make fabrication-outputs-jlcpcb - all required files for JLCPCB"
	@echo "make gerbers-jlcpcb             - zipped gerbers"
	@echo "make bom-jlcpcb                 - parts and placement files"
	@echo "make clean-jlcpcb               - remove jlcpcb artifacts"
	@echo ""
	@echo "Debugging"
	@echo "---------"
	@echo "make debug                  - print Makefile variables"
	@echo "make docker-shell           - shell into container"

debug:
	@echo "detected_OS=$(detected_OS)"
	@echo "BOARD=$(BOARD)"
	@echo "BOARD_SNAPSHOT_LABEL=$(BOARD_SNAPSHOT_LABEL)"
	@echo "MAKEFILE_PATH=$(MAKEFILE_PATH)"
	
	@echo "DOCKER_VISIBLE_PATH=$(DOCKER_VISIBLE_PATH)"
	@echo "PROJECT_PATH=$(PROJECT_PATH)"
	@echo "PROJECT_ABS_PATH=$(PROJECT_ABS_PATH)"
	@echo "OUTPUT_PATH=$(OUTPUT_PATH)"

fabrication-outputs: dirs bom interactive-bom schematic gerbers archive
	@echo "Done. You can find your outputs in "
	@echo $(OUTPUT_PATH)



archive:
	cd out && zip -r $(BOARD_SNAPSHOT_LABEL).zip $(BOARD_SNAPSHOT_LABEL)


gerbers: dirs
	$(DOCKER_RUN) kiplot -b /kicad-project/$(BOARD_RELATIVE_PATH)  -c /opt/etc/kiplot/generic_plot.kiplot.yaml -v -d /output/

dirs:
	mkdir -p $(OUTPUT_PATH)
	mkdir -p $(OUTPUT_PATH)/layout
	mkdir -p $(OUTPUT_PATH)/bom/interactive
	mkdir -p $(OUTPUT_PATH)/schematic

schematic: schematic-svg schematic-pdf



interactive-bom: dirs
	$(DOCKER_RUN) sh /opt/InteractiveHtmlBom/make-interactive-bom /kicad-project/$(BOARD_RELATIVE_PATH)

.PHONY: bom
bom: dirs
	rm -f "$(OUTPUT_PATH)/bom/bom.csv"
	$(DOCKER_RUN) python -m kicad-automation.eeschema.export_bom --schematic /kicad-project/$(SCHEMATIC_RELATIVE_PATH)  --output_dir /output/bom/ $(SCREENCAST_OPT) export

schematic-pdf: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic /kicad-project/$(SCHEMATIC_RELATIVE_PATH) --output_dir /output/schematic/pdf $(SCREENCAST_OPT) export --all_pages  -f pdf 
schematic-svg: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic /kicad-project/$(SCHEMATIC_RELATIVE_PATH) --output_dir /output/schematic/svg $(SCREENCAST_OPT) export --all_pages  -f svg

.PHONY: docker-shell
docker-shell:
	$(DOCKER_RUN) bash

.PHONY: clean
clean:
	rm -rf $(OUTPUT_PATH)

########
#
# JLCPCB specific targets
#

JLCPCB_DB_RELATIVE_PATH := $(PROJECT_PATH)/jlcpcb/cpl_rotations_db.csv

$(OUTPUT_PATH)/jlcpcb:
	mkdir -p $@

# give user a useful message if rotations file is missing
jlcpcb/cpl_rotations_db.csv:
	@echo ""
	@echo "Missing JLCPCB placement rotations file"
	@echo "$(PROJECT_ABS_PATH)/$@"
	@echo ""
	@echo "See the README for more info"
	@echo ""
	exit 1

# give user a useful message if position file is missing
$(BOARD)-all-pos.csv:
	@echo ""
	@echo "Missing position file $@"
	@echo "You must generate this file using pcbnew"
	@echo ""
	@echo "See the README for more information"
	@echo ""
	exit 1

.PHONY: gerbers-jlcpcb
gerbers-jlcpcb: gerbers $(OUTPUT_PATH)/jlcpcb
	rm -f $(OUTPUT_PATH)/jlcpcb/gerbers.zip
	$(DOCKER_RUN) zip -jr /output/jlcpcb/gerbers.zip /output/layout/gerber

.PHONY: bom-jlcpcb
bom-jlcpcb: $(OUTPUT_PATH)/jlcpcb jlcpcb/cpl_rotations_db.csv $(BOARD)-all-pos.csv bom
	$(DOCKER_RUN) jlc-kicad-tools -o /output/jlcpcb -d /kicad-project/$(JLCPCB_DB_RELATIVE_PATH) /kicad-project/$(BOARD)

.PHONY: fabrication-outputs-jlcpcb
fabrication-outputs-jlcpcb: gerbers-jlcpcb bom-jlcpcb
	@echo ""
	@echo "#### JLCPCB production files are located here: ####"
	@echo "$(OUTPUT_PATH)/jlcpcb"
	@echo ""

# clean jlcpcb intermediate and output products
.PHONY: clean-jlcpcb
clean-jlcpcb:
	rm -rf $(OUTPUT_PATH)/jlcpcb
	rm -f $(BOARD).xml
	rm -f $(BOARD)-all-pos.csv
