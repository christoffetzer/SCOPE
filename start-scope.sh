#!/bin/bash
#
# - Generates a stack file to start a SCOPE on each node of the swarm
#   - each instance is available at a different port
# - Starts this swarm
#
# (C) Christof Fetzer, 2017

set -e 

# todo: maybe, provide some options instead

verbose_on=${VERBOSE:-false}
outputfile=${OUTPUTFILE:-"scope-generated.yml"}

function verbose
{
    if [[ $verbose_on = true ]] ; then
        echo $@
    fi
}


# create stack file:

function create_yml
{
    no=`docker node ls -q | wc -l`
    export NODENO=1
    export PORT=4040
    cp scope-stack.yml $outputfile
    for NODENO in `seq 1 $no` ; do
        verbose  "Adding config for node $NODENO "
        envsubst < scope-template.yml >> $outputfile
        let PORT++
    done
}

create_yml
docker stack deploy -c $outputfile SCOPE

echo "OK: SCOPE deployed."

