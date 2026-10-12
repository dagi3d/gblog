#!/bin/sh -e

# Add any container initialization steps here
echo ${1}

if [ "${1}" == "deno" ]; then
  deno run -A entry.mjs sync
fi


exec "${@}"
