#!/usr/bin/env bash

FOLDER_OUTPUT_BASE="/Users/frederic.koeberl/Documents/imports"

set -e

function checkFolder() {
  if ! [ -d "$1" ]; then
    echo ""
    echo "Folder not found."
    exit 1
  fi
}

function readFolder() {
  PROMPT_TITLE="$1"
  FOLDER="$(osascript -l JavaScript -e "a=Application.currentApplication();a.includeStandardAdditions=true;a.chooseFolder({withPrompt:\"$PROMPT_TITLE\"}).toString()")"
  checkFolder "$FOLDER"
  echo $FOLDER
}

function alert() {
  PROMPT_TITLE="$1"
  PROMPT_BODY="$2"
  osascript -e "tell app \"System Events\" to display alert \"$PROMPT_TITLE\" message \"$PROMPT_BODY\" as warning"
}

function convertFolder() {
  INPUT_EXTENSION="$1"
  OUTPUT_SUFFIX="$2"
  OUTPUT_EXTENSION="$3"
  QUALITY="$4"

  cd "$FOLDER_INPUT"
  for FILE_PATH in *.$INPUT_EXTENSION; do
    if ! [ -f "$FILE_PATH" ]; then
      continue
    fi

    DESTINATION="$FILE_PATH"
    DESTINATION=`echo $DESTINATION | sed "s|.$INPUT_EXTENSION| $OUTPUT_SUFFIX.$OUTPUT_EXTENSION|g"`
    DESTINATION="$FOLDER_OUTPUT/$DESTINATION"

    SOURCE="$FOLDER_INPUT/$FILE_PATH"
    DATE_CREATED="$(GetFileInfo -m "$SOURCE")"

    if  [ -f "$DESTINATION" ]; then
        echo "FILE EXISTS -> SKIP  -  $DATE_CREATED  -  $SOURCE -> $DESTINATION"
    else
        echo "CONVERT              -  $DATE_CREATED  -  $SOURCE -> $DESTINATION"
        (
          convert \
            -auto-orient \
            -define dng:use-camera-wb=true \
            -quality $CONFIG_QUALITY% \
            "$SOURCE" \
            "$DESTINATION" &&
          SetFile -d "$DATE_CREATED" "$DESTINATION" &&
          SetFile -m "$DATE_CREATED" "$DESTINATION"
        ) &
        # Remove & to disable parallel processing.
    fi
  done
}

echo "Read Input Folder"
FOLDER_INPUT="$(readFolder "Input Folder")"
FOLDER_OUTPUT="$FOLDER_OUTPUT_BASE/$(date '+%Y-%m-%d %H-%M-%S')"
mkdir -p "$FOLDER_OUTPUT"

#               input extension     output suffix       output extension      quality
convertFolder   "JPG"               "with filter"       "jpeg"                95
convertFolder   "DNG"               "original"          "jpeg"                95
convertFolder   "CR3"               "original"          "jpeg"                95

FOLDER_INPUT_SIZE=$(du -sh "$FOLDER_INPUT" | awk '{print $1}')
FOLDER_OUTPUT_SIZE=$(du -sh "$FOLDER_OUTPUT" | awk '{print $1}')

echo ""
echo "Size Savings:"
echo "$FOLDER_INPUT_SIZE -> $FOLDER_OUTPUT_SIZE"
echo ""

alert "Image Processing done!" "Size Savings: $FOLDER_INPUT_SIZE -> $FOLDER_OUTPUT_SIZE"
open "$FOLDER_OUTPUT"
open "https://photos.google.com"