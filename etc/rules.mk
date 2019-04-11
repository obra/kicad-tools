ROOT_DIR := $(shell pwd)/..
OUTPUT_DIR := $(shell pwd)/out/$(BOARD)-`git describe`
all: 
	@echo "This project does not have an 'all' target. You probably want 'fabrication-outputs'"


fabrication-outputs: dirs bom interactive-bom schematic gerbers archive
	@echo "Done. You can find your outputs in "
	@echo "out/$(BOARD)-"`git describe`



archive:
	cd out && zip -r $(BOARD)-`git describe`.zip $(BOARD)-`git describe`

gerbers: dirs
	kiplot -b $(BOARD).kicad_pcb  -c ../etc/generic_plot.kiplot.yaml -d out/$(BOARD)-`git describe`

dirs:
	mkdir -p $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)/layout
	mkdir -p $(OUTPUT_DIR)/bom/interactive
	mkdir -p $(OUTPUT_DIR)/schematic

schematic: schematic-svg schematic-pdf


schematic-svg-docker: dirs


schematic-svg: dirs
	perl ../bin/plot-schematic $(BOARD) svg out/$(BOARD)-`git describe`/schematic/svg

schematic-pdf: dirs
	perl ../bin/plot-schematic $(BOARD) pdf out/$(BOARD)-`git describe`/schematic/pdf

bom: dirs
	perl ../bin/generate-bom $(BOARD) out/$(BOARD)-`git describe`/bom

interactive-bom: dirs
	sudo docker run --rm --interactive --tty  --volume $(ROOT_DIR):/kicad-project --volume $(OUTPUT_DIR)/bom/interactive:/output: kicad-automation sh /opt/InteractiveHtmlBom/make-interactive-bom /kicad-project/$(BOARD)/$(BOARD).kicad_pcb

schematic-pdf-docker:
	sudo docker run --rm --interactive --tty --volume $(ROOT_DIR):/kicad-project: --volume $(OUTPUT_DIR)/schematic/pdf:/output: kicad-automation python -m kicad-automation.eeschema.schematic export --all_pages  -f pdf /kicad-project/$(BOARD)/$(BOARD).sch /output/

schematic-svg-docker:
	sudo docker run --rm --interactive --tty --volume $(ROOT_DIR):/kicad-project: --volume $(OUTPUT_DIR)/schematic/svg:/output: kicad-automation python -m kicad-automation.eeschema.schematic export --all_pages  -f svg /kicad-project/$(BOARD)/$(BOARD).sch /output/
