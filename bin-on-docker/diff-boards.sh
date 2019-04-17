#!/usr/bin/env bash
# Takes one or two git ref's as arguments and generates visual diffs between them
# If only one ref specified, generates a diff from that file
# If no refs specified, assumes HEAD

BOARD_CACHE_DIR=".cache/board"
OUTPUT_DIR="./plot"

PLOT_BOARD_PATH=${PLOT_BOARD_PATH:-/opt/diff-boards/plot_board.py}
PYTHON_PATH=${PYTHON_PATH:-python}

CHECKOUT_ROOT=$(git rev-parse --show-toplevel)
mkdir -p $BOARD_CACHE_DIR


export_git_file_to_dir () {
    file=$1
    rev_id=$2
    output=$3
        mkdir -p "$output/$rev_id"
        git show "$rev_id:$file" > "$output/$rev_id/$(basename $file)"
}

export_checkout_file_to_dir () {
    file=$1
    rev_id=$2
    output=$3
    mkdir -p "$output/$rev_id"
    cp "$CHECKOUT_ROOT/$file" "$output/$rev_id"
}

board_to_pdf() {
    rev_id=$1
    input_dir=$2
    output_dir=$3

    
    mkdir -p $output_dir/$rev_id
    for f in $input_dir/$rev_id/*.kicad_pcb; do
	echo "Exporting ${f} to ${output_dir}/${rev_id}"
    done


}

make_montage() {
    DIFF_FILES=$(ls -a $DIFF_DIR/*.png)
    montage -mode concatenate -tile 1x $DIFF_DIR/*-Bottom.png $DIFF_DIR/*-CuBottom.png $DIFF_DIR/*-CuTop.png $DIFF_DIR/*-Top.png $DIFF_DIR/montage.png
}


pdf_to_png_diffs() {
    export DIFF_DIR="$OUTPUT_DIR/diff-$DIFF_1-$DIFF_2" 
    mkdir -p $DIFF_DIR
    
    echo "Generating visual diffs"
    echo "Output will be in $DIFF_DIR/montage.png"
    find $BOARD_CACHE_DIR/$DIFF_1/ -name \*.pdf |xargs -n 1 basename -s .pdf | xargs -n 1 -P 0 -I % composite -stereo 0 -density 300 $BOARD_CACHE_DIR/$DIFF_1/%.pdf $BOARD_CACHE_DIR/$DIFF_2/%.pdf $DIFF_DIR/%.png 
    find $DIFF_DIR -name \*png |xargs -n 1 -P 0 -I % convert -trim % %

    
}

if [ $# -eq 3 ]; then
    FILENAME=$3
 	   DIFF_1="$(git rev-parse --short $1)"
    if [ "$2" == "current" ]; then
	DIFF_2="current"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_1" | grep $FILENAME)
    else 
    	DIFF_2="$(git rev-parse --short $2)"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_1" "$DIFF_2" | grep $FILENAME)
    fi



else
	echo "$0 takes three arguments: REV1, REV2, and a FILENAME\n"
	echo "\nTo compare against the current checkout, use the special REV2 'current'"
fi



prepare_one_file() {
	file=$1
	revision=$2
    if [ $revision == "current" ]; then
        export_checkout_file_to_dir $file $revision $BOARD_CACHE_DIR
    else
	if [ -f $BOARD_CACHE_DIR/$revision/$(basename $file) ]; then
		return
	fi
        export_git_file_to_dir $file $revision $BOARD_CACHE_DIR
    fi

        $PYTHON_PATH $PLOT_BOARD_PATH "$BOARD_CACHE_DIR/$revision/$(basename $file)" "." pdf #"$output_dir/$rev_id" pdf
}

for k in $CHANGED_KICAD_FILES; do
	prepare_one_file $k $DIFF_1
	prepare_one_file $k $DIFF_2
done

pdf_to_png_diffs
make_montage
rm -rf "$BOARD_CACHE_DIR/current"
