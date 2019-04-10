
fabrication-outputs: dirs bom interactive-bom schematic gerbers archive
	@echo "Done. You can find your outputs in "
	@echo "out/$(BOARD)-"`git describe`



archive:
	cd out && zip -r $(BOARD)-`git describe`.zip $(BOARD)-`git describe`

gerbers: dirs
	kiplot -b $(BOARD).kicad_pcb  -c ../etc/generic_plot.kiplot.yaml -d out/$(BOARD)-`git describe`

dirs:
	mkdir -p out/$(BOARD)-`git describe`/layout
	mkdir -p out/$(BOARD)-`git describe`/bom/interactive
	mkdir -p out/$(BOARD)-`git describe`/schematic

schematic: schematic-svg schematic-pdf

schematic-svg: dirs
	perl ../bin/plot-schematic $(BOARD) svg out/$(BOARD)-`git describe`/schematic/svg

schematic-pdf: dirs
	perl ../bin/plot-schematic $(BOARD) pdf out/$(BOARD)-`git describe`/schematic/pdf

bom: dirs
	perl ../bin/generate-bom $(BOARD) out/$(BOARD)-`git describe`/bom

interactive-bom: dirs
	python3 ~/git/kicad/InteractiveHtmlBom/InteractiveHtmlBom/generate_interactive_bom.py $(BOARD).kicad_pcb --highlight-pin1 --no-browser --dest-dir=out/$(BOARD)-`git describe`/bom/interactive
