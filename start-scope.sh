#!/bin/bash
# generate stack file for SCOPEs.
# Problem: scopes provide different information and hence, we need to put them on different 
# (C) Christof Fetzer
set -e 

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
        ((PORT++))
    done
}

create_yml
docker stack deploy -c $outputfile SCOPE

echo "OK: SCOPE deployed."

