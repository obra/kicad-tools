# Project-specific config

MAKEFILE_PATH := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
DOCKER_VISIBLE_PATH := $(abspath $(MAKEFILE_PATH)/..)
PROJECT_PATH := $(BOARD)/ 
PROJECT_ABS_PATH := $(abspath $(BOARD))

BOARD_RELATIVE_PATH := $(PROJECT_PATH)/$(BOARD).kicad_pcb
SCHEMATIC_RELATIVE_PATH := $(PROJECT_PATH)/$(BOARD).sch


# Output configuration

BOARD_SNAPSHOT_LABEL := $(BOARD)-`git describe`
OUTPUT_BASEDIR := out/$(BOARD_SNAPSHOT_LABEL)
OUTPUT_PATH := $(PROJECT_ABS_PATH)/$(OUTPUT_BASEDIR)



# Docker config
ifdef DOCKER_NEEDS_SUDO
	DOCKER_SUDO=sudo
endif

DOCKER_CMD_PATH := docker
DOCKER_CONTAINER := kicad-automation

DOCKER_RUN :=  $(DOCKER_SUDO) $(DOCKER_CMD_PATH) \
 	run \
	--rm \
	--interactive --tty \
	--volume $(DOCKER_VISIBLE_PATH):/kicad-project: \
	--volume $(OUTPUT_PATH):/output: \
	$(DOCKER_CONTAINER)


all: 
	@echo "This project does not have an 'all' target. You probably want 'fabrication-outputs'"

debug:
	@echo "BOARD=$(BOARD)"
	@echo "MAKEFILE_PATH=$(MAKEFILE_PATH)"
	
	@echo "DOCKER_VISIBLE_PATH=$(DOCKER_VISIBLE_PATH)"
	@echo "PROJECT_ABS_PATH=$(PROJECT_ABS_PATH)"

fabrication-outputs: dirs bom interactive-bom schematic gerbers archive
	@echo "Done. You can find your outputs in "
	@echo $(OUTPUT_PATH)



archive:
	cd out && zip -r $(BOARD_SNAPSHOT_LABEL).zip $(BOARD_SNAPSHOT_LABEL)


gerbers: dirs
	$(DOCKER_RUN) kiplot -b /kicad-project/$(BOARD_RELATIVE_PATH)  -c /opt/etc/kiplot/generic_plot.kiplot.yaml -v -d /output/

dirs:
	mkdir -p $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)/layout
	mkdir -p $(OUTPUT_DIR)/bom/interactive
	mkdir -p $(OUTPUT_DIR)/schematic

schematic: schematic-svg schematic-pdf



interactive-bom: dirs
	$(DOCKER_RUN) sh /opt/InteractiveHtmlBom/make-interactive-bom /kicad-project/$(BOARD_RELATIVE_PATH)

bom: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.export_bom --schematic $(SCHEMATIC_RELATIVE_PATH)  --output_dir /output/bom/ export

schematic-pdf: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic $(SCHEMATIC_RELATIVE_PATH) --output_dir /output/schematic/pdf export --all_pages  -f pdf 
schematic-svg: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic $(SCHEMATIC_RELATIVE_PATH) --output_dir /output/schematic/pdf export --all_pages  -f svg

docker-shell:
	$(DOCKER_RUN) bash
