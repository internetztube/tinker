#!/usr/bin/env bash

set -e

CAMERA_MAKES="
  Ricoh-GR-II
  Ricoh-GR-IIx
"

function checkFolder() {
  if ! [ -d "$1" ]; then
    echo ""
    echo "Folder not found."
    exit 1
  fi
}

function convertFolder() {
  INPUT_EXTENSION=$1
  OUTPUT_EXTENSION=$2
  QUALITY=$3
  FOLDER_OUTPUT_TEMP=$4
  cd $FOLDER_OUTPUT_TEMP

  for FILE_PATH in *.$INPUT_EXTENSION; do
    DESTINATION_FILE_NAME=`echo $FILE_PATH | sed "s|.$INPUT_EXTENSION|.$OUTPUT_EXTENSION|g"`
    DESTINATION=$FOLDER_OUTPUT_TEMP/$DESTINATION_FILE_NAME
    SOURCE=$FOLDER_OUTPUT_TEMP/$FILE_PATH
    mv $SOURCE $DESTINATION

    if [ $QUALITY -eq 100 ]
    then
      echo "RENAME            - $FILE_PATH -> $DESTINATION_FILE_NAME"
    else
      echo "RENAME & CONVERT  - $FILE_PATH -> $DESTINATION_FILE_NAME"
      convert \
        -quality $QUALITY% \
        "$DESTINATION" \
        "$DESTINATION"
    fi
  done
}

function makeStructure() {
  CAMERA_MAKE=$1
  FOLDER_INPUT_LOCAL=$2
  FOLDER_OUTPUT_LOCAL=$3

  cd $FOLDER_INPUT_LOCAL
  for FILE_NAME in *; do
    SOURCE=$FOLDER_INPUT_LOCAL/$FILE_NAME

    DATE=`GetFileInfo -d $SOURCE`
    MONTH=`node -e "console.log('$DATE'.split('/')[0])"`
    DAY=`node -e "console.log('$DATE'.split('/')[1])"`
    YEAR=`node -e "console.log('$DATE'.split('/')[2].split(' ')[0])"`

    # KAMERA/YYYY/MM/YYYY_MM_DD-KAMERA-ORIGINAL_TITLE.EXT
    DESTINATION_FOLDER="$FOLDER_OUTPUT_LOCAL/$CAMERA_MAKE/$YEAR/$MONTH"
    DESTINATION="$DESTINATION_FOLDER/${YEAR}_${MONTH}_${DAY}-$CAMERA_MAKE-$FILE_NAME"

    [ -d $DESTINATION_FOLDER ] || mkdir -p $DESTINATION_FOLDER
    mv $SOURCE $DESTINATION
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

echo "\nWhich Camera Model?"
select CAMERA_MAKE in $CAMERA_MAKES
do
  FOLDER_OUTPUT_TEMP="$FOLDER_OUTPUT/temp"
  rm -rf $FOLDER_OUTPUT_TEMP
  mkdir $FOLDER_OUTPUT_TEMP

  cp -p $FOLDER_INPUT/* $FOLDER_OUTPUT_TEMP

  convertFolder "JPG" "jpg" 95 $FOLDER_OUTPUT_TEMP
  convertFolder "RAF" "raf" 100 $FOLDER_OUTPUT_TEMP
  convertFolder "DNG" "dng" 100 $FOLDER_OUTPUT_TEMP

  makeStructure $CAMERA_MAKE $FOLDER_OUTPUT_TEMP $FOLDER_OUTPUT

  rm -rf $FOLDER_OUTPUT_TEMP

  FOLDER_INPUT_SIZE=`du -sh $FOLDER_INPUT | awk '{print $1}'`
  FOLDER_OUTPUT_SIZE=`du -sh $FOLDER_OUTPUT | awk '{print $1}'`

  echo ""
  echo "Size Savings:"
  echo "$FOLDER_INPUT_SIZE -> $FOLDER_OUTPUT_SIZE"
  echo ""
  exit 0
done



