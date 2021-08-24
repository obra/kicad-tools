#!/bin/bash
export HOME=/root

if [ -n "$SAVE_SCREENCAST" ]; then
  SCREENCAST_ARG="--screencast_dir /output"
else
  echo "SAVE_SCREENCAST env not set... not saving screencast"
fi

case $1 in
  bom)
    python \
        -m kicad-automation.eeschema.export_bom \
        --schematic $2 \
        --output_dir $3 \
        ${SCREENCAST_ARG} \
        export
    ;;

  *)
    echo -n "unknown cmd"
    ;;
esac