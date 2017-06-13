#!/bin/bash

set -e 

docker stack deploy -c scope.yml SCOPE

echo "OK: SCOPE deployed."

