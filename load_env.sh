#!/bin/bash
# shellcheck disable=2002
if [ -f .env ]; then
  export "$(cmd "$(cat .env | sed 's/#.*//g'| xargs)" | envsubst)"
fi