#!/bin/bash

# sandbox.bio: custom "download" command to download a file to the local computer

USAGE="Usage: download path/to/file"
FILE=${1?$USAGE}
[[ ! -e $FILE ]] && echo $USAGE && exit

touch $FILE # otherwise emulator.read_file() doesn't find the file
echo '{"type": "download", "params": { "path": "'$(realpath $FILE)'" } }' > /dev/ttyS1
