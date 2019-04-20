#!/bin/sh

PLOT_BOARD_PATH=${PLOT_BOARD_PATH:-/opt/diff-boards/plot_board.py}
PYTHON_PATH=${PYTHON_PATH:-python3}

BOARD_CACHE_DIR=/board-cache
IPC_DIR=/ipc

DIFF_DIR=/tmp/diff
mkdir -p $DIFF_DIR

plot_board() {
	sha=$1
	dir=$2
	input_path=$3

	# If we've run this processing before, we don't need to do it again	
	if [ -f $dir/board-Top.png ]; then
		return
	fi

	if [ ! -d $dir ]; then
	 	mkdir -p $dir
	fi

	board_file=$dir/board.kicad_pcb
	cp $input_path $board_file
	$PYTHON_PATH $PLOT_BOARD_PATH  $board_file $dir pdf
	find $dir -name \*.pdf |xargs -n 1 basename -s .pdf | xargs -n 1 -P 0 -I % convert +profile "icc" -density 150 $dir/%.pdf $dir/%.png
}


LEFT_INPUT=$IPC_DIR/left/board.kicad_pcb
LEFT_SHA=$(shasum $LEFT_INPUT |cut -c 1-40)
LEFT_DIR=$BOARD_CACHE_DIR/$LEFT_SHA 

RIGHT_INPUT=$IPC_DIR/right/board.kicad_pcb
RIGHT_SHA=$(shasum $RIGHT_INPUT |cut -c 1-40)
RIGHT_DIR=$BOARD_CACHE_DIR/$RIGHT_SHA


plot_board $LEFT_SHA $LEFT_DIR $LEFT_INPUT
plot_board $RIGHT_SHA $RIGHT_DIR $RIGHT_INPUT


# This recipe is from https://gist.github.com/brechtm/891de9f72516c1b2cbc1
# It does not work at all for differently sized images

#find $LEFT_DIR -name \*.png |xargs -n 1 basename -s .png | xargs -n 1 -P 0 -I % convert $LEFT_DIR/%.png $RIGHT_DIR/%.png '(' -clone 0-1 -compose darken -composite ')' -channel RGB -combine $DIFF_DIR/%-2.png

find $LEFT_DIR -name \*.png |xargs -n 1 basename -s .png | xargs -n 1 -P 0 -I % composite -stereo 0 $LEFT_DIR/%.png $RIGHT_DIR/%.png $DIFF_DIR/%.png

find $DIFF_DIR -name \*png |xargs -n 1 -P 0 -I % convert -trim % %
DIFF_FILES=$(ls -a $DIFF_DIR/*.png)


montage -mode concatenate -tile 1x $DIFF_DIR/*-Bottom.png $DIFF_DIR/*-CuBottom.png $DIFF_DIR/*-CuTop.png $DIFF_DIR/*-Top.png $IPC_DIR/montage.png

exit;



## Try for a left - diff - right montage. not happy yet
#  montage -mode concatenate -tile 3x  \
#  $LEFT_DIR/*-Bottom.png \
#  $DIFF_DIR/*-Bottom.png \
#  $RIGHT_DIR/*-Bottom.png \
#  $LEFT_DIR/*-CuBottom.png \
#  $DIFF_DIR/*-CuBottom.png \
#  $RIGHT_DIR/*-CuBottom.png \
#  $LEFT_DIR/*-CuTop.png \
#  $DIFF_DIR/*-CuTop.png \
#  $RIGHT_DIR/*-CuTop.png \
#  $LEFT_DIR/*-Top.png \
#  $DIFF_DIR/*-Top.png \
#  $RIGHT_DIR/*-Top.png \
#  $IPC_DIR/montage.png


