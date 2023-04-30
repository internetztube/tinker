#!/usr/bin/env bash

set -e

function checkFolder() {
  if ! [ -d "$1" ]; then
    echo ""
    echo "Folder not found."
    exit 1
  fi
}

function convertFolder() {
  INPUT_EXTENSION=$1
  OUTPUT_SUFFIX=$2
  OUTPUT_EXTENSION=$3
  QUALITY=$4

  cd $FOLDER_INPUT
  for FILE_PATH in *.$INPUT_EXTENSION; do
    DESTINATION=$FILE_PATH
    DESTINATION=`echo $DESTINATION | sed "s|.$INPUT_EXTENSION| $OUTPUT_SUFFIX.$OUTPUT_EXTENSION|g"`
    DESTINATION=$FOLDER_OUTPUT/$DESTINATION

    SOURCE=$FOLDER_INPUT/$FILE_PATH
    DATE_CREATED=`GetFileInfo -m "$SOURCE"`

    if  [ -f "$DESTINATION" ]; then
        echo "FILE EXISTS -> SKIP  -  $DATE_CREATED  -  $SOURCE -> $DESTINATION"
    else
        echo "CONVERT              -  $DATE_CREATED  -  $SOURCE -> $DESTINATION"
        (
          convert "$SOURCE" -quality $CONFIG_QUALITY% "$DESTINATION" &&
          SetFile -d "$DATE_CREATED" "$DESTINATION" &&
          SetFile -m "$DATE_CREATED" "$DESTINATION"
        ) &
        # Remove & to disable parallel processing.
    fi
  done
}

echo ""
echo "Input folder: "
read -r FOLDER_INPUT
checkFolder $FOLDER_INPUT

echo ""
echo "Output folder: "
read -r FOLDER_OUTPUT
checkFolder $FOLDER_OUTPUT

#               input extension     output suffix       output extension      quality
convertFolder   "JPG"               "with filter"       "jpeg"                98
convertFolder   "DNG"               "original"          "jpeg"                98
