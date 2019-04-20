# Project-specific config

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


export DOCKER_VOLUMES := --volume $(DOCKER_VISIBLE_PATH):/kicad-project: \
   		  --volume $(OUTPUT_PATH):/output: 

# Infrastructure config

TOOLS_HOME := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
DOCKER_RUN := $(TOOLS_HOME)/bin/kicad-docker-run





all: 
	@echo "This project does not have an 'all' target. You probably want 'fabrication-outputs'"

debug:
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

bom: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.export_bom --schematic /kicad-project/$(SCHEMATIC_RELATIVE_PATH)  --output_dir /output/bom/ export

schematic-pdf: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic /kicad-project/$(SCHEMATIC_RELATIVE_PATH) --output_dir /output/schematic/pdf export --all_pages  -f pdf 
schematic-svg: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic /kicad-project/$(SCHEMATIC_RELATIVE_PATH) --output_dir /output/schematic/svg export --all_pages  -f svg

docker-shell:
	$(DOCKER_RUN) bash
