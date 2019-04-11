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
	$(DOCKER_RUN) python -m kicad-automation.eeschema.export_bom --schematic /kicad-project/$(BOARD)/$(BOARD).sch --output_dir /output/bom/ export

schematic-pdf: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic /kicad-project/$(BOARD)/$(BOARD).sch --output_dir /output/schematic/pdf export --all_pages  -f pdf 
schematic-svg: dirs
	$(DOCKER_RUN) python -m kicad-automation.eeschema.schematic --schematic /kicad-project/$(BOARD)/$(BOARD).sch --output_dir /output/schematic/pdf export --all_pages  -f svg

docker-shell:
	$(DOCKER_RUN) bash
