#!/bin/bash

# sandbox.bio: custom "curl" command to make network request

USAGE="Usage: curl https://url.com"
URL=${1?$USAGE}

OUTPUT="/root/tmp_$(cat /proc/sys/kernel/random/uuid)"
echo '{"type": "fetch", "params": { "url": "'$URL'", "output": "'$OUTPUT'" } }' > /dev/ttyS1
sleep 1
cat $OUTPUT
rm $OUTPUT
