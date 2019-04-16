#!/usr/bin/env bash
# Takes one or two git ref's as arguments and generates visual diffs between them
# If only one ref specified, generates a diff from that file
# If no refs specified, assumes HEAD

OUTPUT_DIR="./plot"
PLOT_BOARD_PATH=${PLOT_BOARD_PATH:-/opt/diff-boards/plot_board.py}
PYTHON_PATH=${PYTHON_PATH:-python}

CHECKOUT_ROOT=$(git rev-parse --show-toplevel)

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
    
    mkdir -p $output_dir/$DIFF_1
    for f in $input_dir/$rev_id/*.kicad_pcb; do
        echo "Converting $f to .pdf:  Files will be saved to $output_dir"
        $PYTHON_PATH $PLOT_BOARD_PATH "$f" "$output_dir/$rev_id" pdf
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
    echo "Output will be in $DIFF_DIR"
    find /tmp/pdf/$DIFF_1/ -name \*.pdf |xargs -n 1 basename -s .pdf | xargs -n 1 -P 0 -I % composite -stereo 0 -density 300 /tmp/pdf/$DIFF_1/%.pdf /tmp/pdf/$DIFF_2/%.pdf $DIFF_DIR/%.png 
    find $DIFF_DIR -name \*png |xargs -n 1 -P 0 -I % convert -trim % %

    
}

export_one_git_file () {
    diff_1=$1
    diff_2=$2
    file=$3
    if [ $diff_1 == "current" ]; then
        export_checkout_file_to_dir $file $diff_1 $OUTPUT_DIR
    else
        export_git_file_to_dir $file $diff_1 $OUTPUT_DIR
    fi

    export_git_file_to_dir $file $diff_2 $OUTPUT_DIR
}


# Find .kicad_files that differ between commits
###############################################

## Look at number of arguments provided set different variables based on number of git refs
## User provided no git references, compare against last git commit
if [ $# -eq 0 ]; then
    DIFF_1="current"
    DIFF_2="$(git rev-parse --short HEAD)"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_2" | grep '.kicad_pcb')
elif [ $# -eq 1 ]; then
    DIFF_1="current"
    DIFF_2="$(git rev-parse --short $1)"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_2" | grep '.kicad_pcb')
elif [ $# -eq 2 ]; then
    DIFF_1="$(git rev-parse --short $1)"
    DIFF_2="$(git rev-parse --short $2)"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_1" "$DIFF_2" | grep '.kicad_pcb')
## User provided too many git references
else
    echo "Please only provide 1 or 2 arguments: not $#"
    exit 2
fi

if [[ -z "$CHANGED_KICAD_FILES" ]]; then echo "No .kicad_pcb files differ" && exit 0; fi



for k in $CHANGED_KICAD_FILES; do
 export_one_git_file $DIFF_1 $DIFF_2 $k
done

echo "Kicad files saved to:  '$OUTPUT_DIR/$DIFF_1' and '$OUTPUT_DIR/$DIFF_2'"

board_to_pdf $DIFF_1 $OUTPUT_DIR "/tmp/pdf"
board_to_pdf $DIFF_2 $OUTPUT_DIR "/tmp/pdf"

pdf_to_png_diffs
make_montage
