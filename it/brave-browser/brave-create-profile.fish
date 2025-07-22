#!/usr/bin/fish
if test (count $argv) -ne 1
    echo "Usage: $argv[0] <profile_number>" >&2
    exit 1
end

set -l profile_number $argv[1]
set -l base "$HOME/.config/BraveSoftware/Brave-Browser"
set -l origin "$base/Default"
set -l dest "$base/Profile $profile_number"

cp -r "$origin/Extensions" "$dest"/
cp "$origin/Preferences" "$dest"/
cp "$origin/Bookmarks" "$dest"/
cp "$origin/Favicons" "$dest"/
cp "$origin/Top Sites" "$dest"/

jq '.profile.name = "duplicated-profile"' \
  "$dest/Preferences" > "$dest/Preferences.tmp" \
  && mv "$dest/Preferences.tmp" "$dest/Preferences"
