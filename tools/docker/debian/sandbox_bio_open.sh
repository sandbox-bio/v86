#!/bin/bash

# sandbox.bio: custom "open" command to open a file in a new browser tab

USAGE="Usage: open path/to/file"
FILE=${1?$USAGE}
[[ ! -e $FILE ]] && echo $USAGE && exit

touch $FILE # otherwise emulator.read_file() doesn't find the file
echo '{"type": "open", "params": { "path": "'$(realpath $FILE)'" } }' > /dev/ttyS1
