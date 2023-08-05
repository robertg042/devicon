#!/bin/bash

main() {
  local file_w file_h directory filename_base
  local BACKGROUND_OPTION_NAME="--bg"
  local BACKGROUND_COLOR_OPTION_NAME="--bg-color"
  local OUTPUT_PATH=output
  local MIN_SIZE=512
  local half_size=$((MIN_SIZE / 2))

  local BACKGROUND_FILENAME=png-background.png
  local OVERLAY_FILENAME=png-overlay.png

  local files=($(filter_options "$@"))
  local background_option_value=$(get_background_option_value "$@")
  local background_color_option_value=$(get_background_color_option_value "$@")

  mkdir -p "$OUTPUT_PATH"

  for file in "$files"; do
    directory=$(dirname "$file")
    filename_base=$(basename -- "${file%.*}")
    file_w=$(identify -format "%w" "$file")
    file_h=$(identify -format "%h" "$file")

    if [[ "$background_option_value" = circle ]]; then
      magick convert -background none "$file" -resize "$MIN_SIZE"x"$MIN_SIZE"^ "$OVERLAY_FILENAME"
      magick -size "$MIN_SIZE"x"$MIN_SIZE" xc:none -fill "$background_color_option_value" -draw 'circle '"$half_size"' '"$half_size"' '"$half_size"' 0' "$BACKGROUND_FILENAME"
      magick "$OVERLAY_FILENAME" -gravity center "$BACKGROUND_FILENAME" -colorspace sRGB +swap -compose over -composite "$OUTPUT_PATH"/"$filename_base".png
    elif [[ "$background_option_value" = rounded ]]; then
      magick convert -background none "$file" -resize "$MIN_SIZE"x"$MIN_SIZE"^ "$OVERLAY_FILENAME"
      local resized_w=$(identify -format "%w" "$OVERLAY_FILENAME")
      local resized_h=$(identify -format "%h" "$OVERLAY_FILENAME")
      local radius=$((MIN_SIZE / 10))

      magick -size "$resized_w"x"$resized_h" xc:none -fill "$background_color_option_value" -draw 'roundrectangle 0,0 %[fx:w-1],%[fx:h-1] '"$radius","$radius" "$BACKGROUND_FILENAME"
      magick "$OVERLAY_FILENAME" -gravity center "$BACKGROUND_FILENAME" -colorspace sRGB +swap -compose over -composite "$OUTPUT_PATH"/"$filename_base".png

    else
      magick convert -background none "$file" -resize "$MIN_SIZE"x"$MIN_SIZE"^ "$OUTPUT_PATH"/"$filename_base".png
    fi
  done

  rm "$BACKGROUND_FILENAME"
  rm "$OVERLAY_FILENAME"
}

filter_options() {
  local args=("$@")
  local filtered_args=()
  local current_arg="${1:-}"
  for current_arg in "${args[@]}"; do
    case "$current_arg" in
    "$BACKGROUND_OPTION_NAME"*) ;;
    --*) ;;
    *)
      filtered_args+=("$current_arg")
      ;;
    esac
  done

  echo "${filtered_args[@]}"
}

get_background_color_option_value() {
  local args=("$@")
  local current_arg="${1:-}"
  local value=white

  for current_arg in "${args[@]}"; do
    if [[ "$current_arg" =~ ^"$BACKGROUND_COLOR_OPTION_NAME"= ]]; then
      value="${current_arg#*=}"
    fi
  done

  echo "$value"
}

get_background_option_value() {
  local args=("$@")
  local current_arg="${1:-}"
  local value=none

  for current_arg in "${args[@]}"; do
    if [[ "$current_arg" =~ ^"$BACKGROUND_OPTION_NAME"= ]]; then
      value="${current_arg#*=}"
    fi
  done

  echo "$value"
}

main "$@"
