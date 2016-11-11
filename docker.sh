#!/bin/bash

# Example for the Docker Hub V2 API
# Returns all imagas and tags associated with a Docker Hub user account.
# Requires 'jq': https://stedolan.github.io/jq/

# set username and password
UNAME="nmishin"
UPASS=""
REPO="jagger-jaas"
# -------

set -e
echo

contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

# aquire token
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'${UNAME}'", "password": "'${UPASS}'"}' https://hub.docker.com/v2/users/login/ | jq -r .token)

# get tags for repo
IMAGE_TAGS=$(curl -s -H "Authorization: JWT ${TOKEN}" https://hub.docker.com/v2/repositories/${UNAME}/${REPO}/tags/?page_size=100 | jq -r '.results|.[]|.name')

# build a list of images from tags
jagger_jaas=()
for j in ${IMAGE_TAGS}
do
  if contains ${j} "SNAPSHOT"
  then
      jagger_jaas+=" ${j%%-SNAPSHOT}"
  fi
done

min=0 max=0
for i in ${jagger_jaas[@]}; do
   if version_gt $i $max
   then
     max=$i
   fi
done

echo "max=$max"
