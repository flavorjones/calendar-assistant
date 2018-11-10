#! /usr/bin/env bash

set -e -u

file=${PR_INPUT_PATH}/.git/resource/metadata.json

cat $file

pr=`jq -r '.[] | select(.name == "pr") | .value' $file`
sha=`jq -r '.[] | select(.name == "head_sha") | .value' $file | cut -c1-7`
author=`jq -r '.[] | select(.name == "author") | .value' $file`
message=`jq -r '.[] | select(.name == "message") | .value' $file | head -n1`

echo <<EOM > ${PR_OUTPUT_PATH}/message.log
PR ${pr} from ${author}: [${sha}] ${message}
Commits: https://github.com/flavorjones/calendar-assistant/pull/${pr}
Build details: $ATC_EXTERNAL_URL/builds/$BUILD_ID
EOM

cat ${PR_OUTPUT_PATH}/message.log
