#!/bin/bash

set -e 

docker stack deploy -c scope.yml scope

echo "OK: SCOPE deployed."
