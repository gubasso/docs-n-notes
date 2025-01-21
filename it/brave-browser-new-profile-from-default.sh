#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <new_profile_dir> <new_profile_name>"
  exit 1
fi

new_profile_dir="$1"
new_profile_name="$2"

cp -r "Default/Extensions"   "$new_profile_dir"
cp    "Default/Preferences"  "$new_profile_dir"
cp    "Default/Bookmarks"    "$new_profile_dir"
cp    "Default/Favicons"     "$new_profile_dir"
cp    "Default/Top Sites"    "$new_profile_dir"

chmod -R 700 "$new_profile_dir"

jq --arg name "$new_profile_name" \
  '.profile.name = $name' \
  "$new_profile_dir/Preferences" > "$new_profile_dir/Preferences.tmp" \
  && mv "$new_profile_dir/Preferences.tmp" "$new_profile_dir/Preferences"

echo "Profile successfully duplicated to: $new_profile_dir"
