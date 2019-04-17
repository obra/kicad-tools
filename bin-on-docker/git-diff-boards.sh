#!/usr/bin/env bash
# Takes one or two git ref's as arguments and generates visual diffs between them
# If only one ref specified, generates a diff from that file
# If no refs specified, assumes HEAD

BOARD_CACHE_DIR="$(mktemp -d)"
    DIFF_DIR="$(mktemp -d)"

PLOT_BOARD_PATH=${PLOT_BOARD_PATH:-/opt/diff-boards/plot_board.py}
PYTHON_PATH=${PYTHON_PATH:-python}

CHECKOUT_ROOT=$(git rev-parse --show-toplevel)
mkdir -p $BOARD_CACHE_DIR



file1=$1
file2=$2

mkdir $BOARD_CACHE_DIR/1
cp $file1 $BOARD_CACHE_DIR/1/board.kicad_pcb
mkdir $BOARD_CACHE_DIR/2
cp $file2 $BOARD_CACHE_DIR/2/board.kicad_pcb



        $PYTHON_PATH $PLOT_BOARD_PATH  $BOARD_CACHE_DIR/1/board.kicad_pcb  "$BOARD_CACHE_DIR/1" pdf 
        $PYTHON_PATH $PLOT_BOARD_PATH  $BOARD_CACHE_DIR/2/board.kicad_pcb  "$BOARD_CACHE_DIR/2" pdf 
    

find $BOARD_CACHE_DIR/1/ -name \*.pdf |xargs -n 1 basename -s .pdf | xargs -n 1 -P 0 -I % composite -stereo 0 -density 300 $BOARD_CACHE_DIR/1/%.pdf $BOARD_CACHE_DIR/2/%.pdf $DIFF_DIR/%.png 
    find $DIFF_DIR -name \*png |xargs -n 1 -P 0 -I % convert -trim % %


    DIFF_FILES=$(ls -a $DIFF_DIR/*.png)
    montage -mode concatenate -tile 1x $DIFF_DIR/*-Bottom.png $DIFF_DIR/*-CuBottom.png $DIFF_DIR/*-CuTop.png $DIFF_DIR/*-Top.png $DIFF_DIR/montage.png
xdg-open $DIFF_DIR/montage.png
