#!/bin/bash

# sandbox.bio: custom "curl" command to make network request

# Warn users!
COLOR_YELLOW="\033[1;33m"
COLOR_RESET="\033[0m"
echo -ne "$COLOR_YELLOW" > /dev/stderr
echo "---------------------------------------------------" > /dev/stderr
echo "Warning: curl is not fully supported on sandbox.bio" > /dev/stderr
echo "Only the following commands are supported:" > /dev/stderr
echo "   curl -O url" > /dev/stderr
echo "   curl -o filename url" > /dev/stderr
echo "URLs must be CORS-enabled to be downloadable." > /dev/stderr
echo "---------------------------------------------------" > /dev/stderr
echo -ne "$COLOR_RESET" > /dev/stderr

# Parse arguments
URL="${@: -1}"
OUTPUT="-"
UUID=$(cat /proc/sys/kernel/random/uuid)
while getopts "Oo:hv" opt; do
  case "$opt" in
    O) OUTPUT=$(basename $URL);;
    o) OUTPUT="$OPTARG";;
    h|v|?)
      echo "Usage: curl [-O] [-o output] https://..."
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

# Support curl to stdin
IS_STDIN=0
if [[ "$OUTPUT" == "-" ]]; then
    IS_STDIN=1
    OUTPUT="tmp_$UUID"
fi
SENTINEL="/root/tmp_${UUID}.done"

# Send message to front-end to start downloading the file
echo '{"type": "fetch", "params": { "url": "'$URL'", "output": "'$(pwd)/$OUTPUT'", "sentinel": "'$SENTINEL'" } }' > /dev/ttyS1
echo 'Fetching "'$URL'"...' > /dev/stderr
echo -e "---------------------------------------------------\n" > /dev/stderr

# Wait until download is done (front-end will create this file once fetch completes)
until [ -f "$SENTINEL" ]; do
    sleep 1
done

# Cleanup temp files if output to stdin
if [[ "$IS_STDIN" == "1" ]]; then
    cat $OUTPUT
    rm $OUTPUT
fi
