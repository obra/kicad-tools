'''
Heavily borrowed from this location: https://github.com/blairbonnett-mirrors/kicad/blob/master/demos/python_scripts_examples/plot_board.py

Parameters

Takes 3 parameters
1. Path to kicad file
2. Location of where to save files
3  Plot format. can be either 'svg' or 'pdf'


    A python script example to create various plot files from a board:
    Fab files
    Doc files
    Gerber files

    Important note:
        this python script does not plot frame references.
        the reason is it is not yet possible from a python script because plotting
        plot frame references needs loading the corresponding page layout file
        (.wks file) or the default template.

        This info (the page layout template) is not stored in the board, and therefore
        not available.

        Do not try to change SetPlotFrameRef(False) to SetPlotFrameRef(true)
        the result is the pcbnew lib will crash if you try to plot
        the unknown frame references template.


Usage

    There are 4 main lines that generate a file. e.g..

    pctl.SetLayer(F_SilkS)
    pctl.OpenPlotfile("Silk", plot_format, "Assembly guide")
    pctl.PlotLayer()
    pctl.ClosePlot()


The first line takes the F.Silks layer
The second line takes 3 parameters (file-name-append, file type, unknown)
The third line actually plots the layer
The forth line reads the temp file and writes it out to a pdf

You can write to the following formats

PLOT_FORMAT_SVG
PLOT_FORMAT_PDF
PLOT_FORMAT_GERBER

    
'''
#!/usr/bin/env python
import sys

from pcbnew import *
filename=sys.argv[1] #e.g left-main/left-main.kicad_pcb

board = LoadBoard(filename)

pctl = PLOT_CONTROLLER(board)

popt = pctl.GetPlotOptions()


popt.SetOutputDirectory(sys.argv[2])

if sys.argv[3] == 'svg': 
	plot_format = PLOT_FORMAT_SVG
else:
	plot_format= PLOT_FORMAT_PDF
	

# Set some important plot options:
popt.SetPlotFrameRef(False)
popt.SetLineWidth(FromMM(0.35))

popt.SetAutoScale(False)
popt.SetScale(1)
popt.SetMirror(False)
popt.SetUseGerberAttributes(True)
popt.SetExcludeEdgeLayer(False);
popt.SetScale(1)
popt.SetUseAuxOrigin(False)
popt.SetSkipPlotNPTH_Pads(False)
popt.SetPlotViaOnMaskLayer(True)
popt.SetSubtractMaskFromSilk(True)
#popt.SetMode(LINE)

# This by gerbers only (also the name is truly horrid!)
popt.SetSubtractMaskFromSilk(False)

#########################
#### CuBottom.gbr    ####
#### CuTop.gbr       ####
#### EdgeCuts.gbr    ####
#### MaskBottom.gbr  ####
#### MaskTop.gbr     ####
#### PasteBottom.gbr ####
#### PasteTop.gbr    ####
#### SilkBottom.gbr  ####
#### SilkTop.gbr     ####
#########################

# Once the defaults are set it become pretty easy...
# I have a Turing-complete programming language here: I'll use it...
# param 0 is a string added to the file base name to identify the drawing
# param 1 is the layer ID
plot_plan = [
    ( "CuTop", F_Cu, "Top layer" ),
    ( "CuBottom", B_Cu, "Bottom layer" ),
]

bottom_layers = [
    ( "PasteBottom", B_Paste, "Paste Bottom" ),
    ( "SilkBottom", B_SilkS, "Silk top" ),
    ( "MaskBottom", B_Mask, "Mask bottom" ),
    ( "CrtYdBottom", B_CrtYd, "CrtYd bottom" ),
    ( "FabBottom", B_Fab, "Fab bottom" ),
]

top_layers = [
    ( "PasteTop", F_Paste, "Paste top" ),
    ( "SilkTop", F_SilkS, "Silk top" ),
    ( "MaskTop", F_Mask, "Mask top" ),
    ( "CrtYdTop", F_CrtYd, "CrtYd top" ),
    ( "FabTop", F_Fab, "Fab top" ),
]

for layer_info in plot_plan:
    pctl.SetLayer(layer_info[1])
    pctl.OpenPlotfile(layer_info[0], plot_format, layer_info[2])
    pctl.PlotLayer()
    pctl.SetLayer(Edge_Cuts)
    pctl.PlotLayer()



pctl.OpenPlotfile('Top', plot_format, 'Top side')
popt.SetPlotReference(True)
popt.SetPlotValue(True)
popt.SetPlotInvisibleText(False)
popt.SetDrillMarksType(PCB_PLOT_PARAMS.FULL_DRILL_SHAPE)
for layer_info in top_layers:
    pctl.SetLayer(layer_info[1])
    pctl.PlotLayer()

pctl.SetLayer(Edge_Cuts)
pctl.PlotLayer()


pctl.OpenPlotfile('Bottom', plot_format, 'Bottom side')
popt.SetPlotReference(True)
popt.SetPlotValue(True)
popt.SetPlotInvisibleText(False)
popt.SetDrillMarksType(PCB_PLOT_PARAMS.FULL_DRILL_SHAPE)
for layer_info in bottom_layers:
    pctl.SetLayer(layer_info[1])
    pctl.PlotLayer()
pctl.SetLayer(Edge_Cuts)
pctl.PlotLayer()


# At the end you have to close the last plot, otherwise you don't know when
# the object will be recycled!
pctl.ClosePlot()

