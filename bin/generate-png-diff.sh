#!/usr/bin/env bash
# Takes one or two git ref's as arguments and generates visual diffs between them
# If only one ref specified, generates a diff from that file
# If no refs specified, assumes HEAD

OUTPUT_DIR="./plot"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# Find .kicad_files that differ between commits
###############################################

## Look at number of arguments provided set different variables based on number of git refs
## User provided no git references, compare against last git commit
if [ $# -eq 0 ]; then
    DIFF_1="current"
    DIFF_2="$(git rev-parse --short HEAD)"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_2" | grep '.kicad_pcb')
    if [[ -z "$CHANGED_KICAD_FILES" ]]; then echo "No .kicad_pcb files differ" && exit 0; fi
    # Copy all modified kicad_file to $OUTPUT_DIR/current
    for k in $CHANGED_KICAD_FILES; do
        mkdir -p "$OUTPUT_DIR/$DIFF_1"
        cp "$k" $OUTPUT_DIR/current
    done
    # Copy the specified git commit kicad_file to $OUTPUT_DIR/$(git ref)
    for k in $CHANGED_KICAD_FILES; do
        mkdir -p "$OUTPUT_DIR/$DIFF_2"
        echo "Copying $DIFF_2:$k to $OUTPUT_DIR/$DIFF_2/"
        git show "$DIFF_2:$k" > "$OUTPUT_DIR/$DIFF_2/$(basename $k)"
    done
## User provided 1 git reference to compare against current files
elif [ $# -eq 1 ]; then
    DIFF_1="current"
    DIFF_2="$1"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_2" | grep '.kicad_pcb')
    if [[ -z "$CHANGED_KICAD_FILES" ]]; then echo "No .kicad_pcb files differ" && exit 0; fi
    # Copy all modified kicad_file to $OUTPUT_DIR/current
    for k in $CHANGED_KICAD_FILES; do
        mkdir -p "$OUTPUT_DIR/$DIFF_1"
        cp "$k" $OUTPUT_DIR/current
    done
    # Copy the specified git commit kicad_file to $OUTPUT_DIR/$(git ref)
    for k in $CHANGED_KICAD_FILES; do
        mkdir -p "$OUTPUT_DIR/$DIFF_2"
        echo "Copying $DIFF_2:$k to $OUTPUT_DIR/$DIFF_2/$k"
        git show "$DIFF_2:$k" > "$OUTPUT_DIR/$DIFF_2/$(basename $k)"
    done
## User provided 2 git references to compare
elif [ $# -eq 2 ]; then
    DIFF_1="$1"
    DIFF_2="$2"
    CHANGED_KICAD_FILES=$(git diff --name-only "$DIFF_1" "$DIFF_2" | grep '.kicad_pcb')
    if [[ -z "$CHANGED_KICAD_FILES" ]]; then echo "No .kicad_pcb files differ" && exit 0; fi
    # Copy all modified kicad_file to $OUTPUT_DIR/current
    for k in $CHANGED_KICAD_FILES; do
        mkdir -p "$OUTPUT_DIR/$DIFF_1"
        git show "$DIFF_1:$k" > "$OUTPUT_DIR/$DIFF_1/$(basename $k)"
    done
    # Copy the specified git commit kicad_file to $OUTPUT_DIR/$(git ref)
    for k in $CHANGED_KICAD_FILES; do
        mkdir -p "$OUTPUT_DIR/$DIFF_2"
        echo "Copying $DIFF_2:$k to $OUTPUT_DIR/$DIFF_2/$k"
        git show "$DIFF_2:$k" > "$OUTPUT_DIR/$DIFF_2/$(basename $k)"
    done
## User provided too many git referencess
else
    echo "Please only provide 1 or 2 arguments: not $#"
    exit 2
fi

echo "Kicad files saved to:  '$OUTPUT_DIR/$DIFF_1' and '$OUTPUT_DIR/$DIFF_2'"

# Generate png files from kicad output
#######################################
mkdir -p /tmp/pdf/$DIFF_1
for f in $OUTPUT_DIR/$DIFF_1/*.kicad_pcb; do
    echo "Converting $f to .pdf:  Files will be saved to /tmp/pdf"
    python $SCRIPT_DIR/plot_board.py "$f" "/tmp/pdf/$DIFF_1"
done

mkdir -p /tmp/pdf/$DIFF_2
for f in $OUTPUT_DIR/$DIFF_2/*.kicad_pcb; do
    echo "Converting $f to .pdf's Files will be saved to /tmp/pdf"
    python $SCRIPT_DIR/plot_board.py "$f" "/tmp/pdf/$DIFF_2"
done

# Generate png diffs
####################

export DIFF_DIR="$OUTPUT_DIR/diff-$DIFF_1-$DIFF_2" 
mkdir -p $DIFF_DIR

echo "Generating visual diffs"
echo "Output will be in $DIFF_DIR"
find /tmp/pdf/$DIFF_1/ -name \*.pdf |xargs -n 1 basename -s .pdf | xargs -n 1 -P 0 -I % composite -stereo 0 -density 300 /tmp/pdf/$DIFF_1/%.pdf /tmp/pdf/$DIFF_2/%.pdf $DIFF_DIR/%.png
