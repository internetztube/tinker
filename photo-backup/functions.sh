#!/usr/bin/env bash

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
  FOLDER_OUTPUT="$5"

  cd "$FOLDER_INPUT"
  for FILE_PATH in *.$INPUT_EXTENSION; do
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
  wait $(jobs -p)
}

function google_photos_check_auth() {
  CONFIG_PATH="$1"
  TOKEN_STORE_KEY="$2"
  set +e
  TEST=$(GPHOTOS_CLI_TOKENSTORE_KEY="$TOKEN_STORE_KEY" gphotos-uploader-cli list albums --config "$CONFIG_PATH")
  set -e

  if [[ "$TEST" == *"Token is valid"* ]]; then
    echo "Token is valid!"
  else
    echo "Token is invalid! Now reauth!"
    google_photos_auth "$CONFIG_PATH" "$TOKEN_STORE_KEY"
    google_photos_check_auth "$CONFIG_PATH" "$TOKEN_STORE_KEY"
  fi
}

function google_photos_auth() {
  CONFIG_PATH="$1"
  TOKEN_STORE_KEY="$2"
  GPHOTOS_CLI_TOKENSTORE_KEY="$TOKEN_STORE_KEY" gphotos-uploader-cli auth --config "$CONFIG_PATH"
}

function google_photos_upload() {
  CONFIG_PATH="$1"
  TOKEN_STORE_KEY="$2"
  GPHOTOS_CLI_TOKENSTORE_KEY="$TOKEN_STORE_KEY" gphotos-uploader-cli push --config "$CONFIG_PATH"
}