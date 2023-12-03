#!/usr/bin/env bash

source functions.sh
set -e

FOLDER_OUTPUT_BASE="/Users/frederic.koeberl/Documents/imports"
GOOGLE_PHOTOS_CONFIG_PATH="/Users/frederic.koeberl/IdeaProjects/tinker/photo-backup/"
GOOGLE_PHOTOS_TOKEN_STORE_KEY=""
FOLDER_LATEST="$FOLDER_OUTPUT_BASE/latest"
rm -rf "$FOLDER_LATEST"
mkdir $FOLDER_LATEST

google_photos_check_auth "$GOOGLE_PHOTOS_CONFIG_PATH" "$GOOGLE_PHOTOS_TOKEN_STORE_KEY"

echo "Read Input Folder"
FOLDER_INPUT="$(readFolder "Input Folder")"
FOLDER_OUTPUT="$FOLDER_OUTPUT_BASE/$(date '+%Y-%m-%d %H-%M-%S')"
mkdir -p "$FOLDER_OUTPUT"

#               input extension     output suffix       output extension      quality     folder output
convertFolder   "JPG"               "with filter"       "jpeg"                95          "$FOLDER_OUTPUT"
convertFolder   "DNG"               "original"          "jpeg"                95          "$FOLDER_OUTPUT"
cp -rp "$FOLDER_OUTPUT" "$FOLDER_LATEST"

FOLDER_INPUT_SIZE=$(du -sh "$FOLDER_INPUT" | awk '{print $1}')
FOLDER_OUTPUT_SIZE=$(du -sh "$FOLDER_OUTPUT" | awk '{print $1}')

echo ""
echo "Size Savings:"
echo "$FOLDER_INPUT_SIZE -> $FOLDER_OUTPUT_SIZE"
echo ""

google_photos_upload "$GOOGLE_PHOTOS_CONFIG_PATH" "$GOOGLE_PHOTOS_TOKEN_STORE_KEY"