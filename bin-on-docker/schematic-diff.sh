#!/bin/sh

SCHEMATIC_DIR=$1
SCHEMATIC_FILE=$2

PLOT_SCHEMATIC_PATH=${PLOT_BOARD_PATH:-/opt/diff-boards/plot_schematic.py}
PYTHON_PATH=${PYTHON_PATH:-python3}

SCHEMATIC_CACHE_DIR=/schematic-cache

IPC_DIR=/ipc

DIFF_DIR=/ipc/diff

mkdir -p $DIFF_DIR

plot_schematic() {
	input_path=$1
	output_path=$2

	if [ -f $output_path/.generated ]; then
		return
	fi

	if [ ! -d $output_path ]; then
	 	mkdir -p $output_path
	fi

        python -m kicad-automation.eeschema.schematic --schematic $input_path --output_dir $output_path export --all_pages  -f pdf && \
	find $output_path -name \*.pdf |xargs -n 1 basename -s .pdf | xargs -n 1 -P 0 -I % convert +profile "icc" -density 150 $output_path/%.pdf $output_path/%.png && \
	touch $output_path/.generated
}



LEFT_INPUT=$IPC_DIR/left/$SCHEMATIC_DIR/$SCHEMATIC_FILE
RIGHT_INPUT=$IPC_DIR/right/$SCHEMATIC_DIR/$SCHEMATIC_FILE

LEFT_SHA=$(cat $IPC_DIR/left-sha)
LEFT_CACHE_DIR=$SCHEMATIC_CACHE_DIR/$LEFT_SHA 

RIGHT_SHA=$(cat $IPC_DIR/right-sha)

# Try to get a stable sha for an unchanged checkout, but also a fresh one for a changed checkout
if [ "$RIGHT_SHA"=="current_checkout" ]; then
	RIGHT_SHA=`find $RIGHT_INPUT -type f -print0 2>/dev/null |xargs -0 cat 2> /dev/null |shasum |cut -c 1-40`
fi

RIGHT_CACHE_DIR=$SCHEMATIC_CACHE_DIR/$RIGHT_SHA


plot_schematic $LEFT_INPUT $LEFT_CACHE_DIR
plot_schematic $RIGHT_INPUT $RIGHT_CACHE_DIR 


find $LEFT_CACHE_DIR -name \*.png |xargs -n 1 basename -s .png | xargs -n 1 -P 0 -I % composite -stereo 0 $LEFT_CACHE_DIR/%.png $RIGHT_CACHE_DIR/%.png $DIFF_DIR/%.png

find $DIFF_DIR -name \*png |xargs -n 1 -P 0 -I % convert -trim % %

montage -mode concatenate -tile 1x $DIFF_DIR/*.png $IPC_DIR/montage.png

exit;
