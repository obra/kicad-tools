ROOT_DIR := $(shell pwd)/..
OUTPUT_DIR := $(shell pwd)/out/$(BOARD)-`git describe`

DOCKER_RUN :=  sudo docker run --rm --interactive --tty  --volume $(ROOT_DIR):/kicad-project:   --volume $(OUTPUT_DIR):/output: kicad-automation

all: 
	@echo "This project does not have an 'all' target. You probably want 'fabrication-outputs'"


fabrication-outputs: dirs bom interactive-bom schematic gerbers archive
	@echo "Done. You can find your outputs in "
	@echo "out/$(BOARD)-"`git describe`



archive:
	cd out && zip -r $(BOARD)-`git describe`.zip $(BOARD)-`git describe`

gerbers: dirs
	$(DOCKER_RUN) kiplot -b /kicad-project/$(BOARD)/$(BOARD).kicad_pcb  -c /opt/etc/kiplot/generic_plot.kiplot.yaml -v -d /output/

dirs:
	mkdir -p $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)/layout
	mkdir -p $(OUTPUT_DIR)/bom/interactive
	mkdir -p $(OUTPUT_DIR)/schematic

schematic: schematic-svg schematic-pdf



interactive-bom: dirs
	$(DOCKER_RUN) sh /opt/InteractiveHtmlBom/make-interactive-bom /kicad-project/$(BOARD)/$(BOARD).kicad_pcb


bom: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.export_bom export /kicad-project/$(BOARD)/$(BOARD).sch /output/bom/

schematic-pdf: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic export --all_pages  -f pdf /kicad-project/$(BOARD)/$(BOARD).sch /output/schematic/pdf

schematic-svg: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic export --all_pages  -f svg /kicad-project/$(BOARD)/$(BOARD).sch /output/schematic/svg

docker-shell:
	$(DOCKER_RUN) bash
