#!/bin/sh

PLOT_BOARD_PATH=${PLOT_BOARD_PATH:-/opt/diff-boards/plot_board.py}
PYTHON_PATH=${PYTHON_PATH:-python3}

BOARD_CACHE_DIR=/board-cache
IPC_DIR=/ipc

DIFF_DIR=$(mktemp -d)

LEFT_SHA=$(shasum $IPC_DIR/left/board.kicad_pcb|cut -c 1-40)
RIGHT_SHA=$(shasum $IPC_DIR/right/board.kicad_pcb|cut -c 1-40)

LEFT_DIR=$BOARD_CACHE_DIR/$LEFT_SHA 
RIGHT_DIR=$BOARD_CACHE_DIR/$RIGHT_SHA

if [ ! -d $LEFT_DIR ]; then
 mkdir $LEFT_DIR
fi

if [ ! -d $RIGHT_DIR ]; then 
 mkdir $RIGHT_DIR
fi

LEFT_BOARD_FILE=$LEFT_DIR/board.kicad_pcb
RIGHT_BOARD_FILE=$RIGHT_DIR/board.kicad_pcb


cp $IPC_DIR/left/board.kicad_pcb $LEFT_BOARD_FILE
cp $IPC_DIR/right/board.kicad_pcb $RIGHT_BOARD_FILE

$PYTHON_PATH $PLOT_BOARD_PATH  $LEFT_BOARD_FILE $LEFT_DIR pdf
$PYTHON_PATH $PLOT_BOARD_PATH  $RIGHT_BOARD_FILE $RIGHT_DIR pdf

find $LEFT_DIR -name \*.pdf |xargs -n 1 basename -s .pdf | xargs -n 1 -P 0 -I % composite -stereo 0 -density 300 $LEFT_DIR/%.pdf $RIGHT_DIR/%.pdf $DIFF_DIR/%.png

find $DIFF_DIR -name \*png |xargs -n 1 -P 0 -I % convert -trim % %
DIFF_FILES=$(ls -a $DIFF_DIR/*.png)
montage -mode concatenate -tile 1x $DIFF_DIR/*-Bottom.png $DIFF_DIR/*-CuBottom.png $DIFF_DIR/*-CuTop.png $DIFF_DIR/*-Top.png $IPC_DIR/montage.png

exit;
